package tech.lolli.toolbox.alert

import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * The user's resource rules, and the comparison that turns a window of history
 * samples into an alert.
 *
 * Nothing here touches the network, the clock or SharedPreferences: the worker
 * supplies the servers, the history and "now", which is what makes the window
 * arithmetic testable without a device.
 *
 * A rule is authored in the app and reaches this file as one JSON object per
 * rule inside the alert settings payload — see `cf_resource_alert.dart`, whose
 * field names are the ones parsed here.
 */
object ResourceAlertEvaluator {

    /** What a rule watches. The wire names match the Dart enum's case names. */
    enum class Metric(val wire: String, val unit: String) {
        CPU("cpu", "%"),
        RAM("ram", "%"),
        DISK("disk", "%"),
        NET_IN("netIn", "Mbps"),
        NET_OUT("netOut", "Mbps");

        val isPercent: Boolean get() = unit == "%"

        companion object {
            fun parse(raw: String?): Metric? = values().firstOrNull { it.wire == raw }
        }
    }

    /** How a window is judged. */
    enum class Trigger(val wire: String) {
        /** The mean of the window is over the threshold. */
        AVG("avg"),

        /** Every sample in the window is over the threshold. */
        ALL("all");

        companion object {
            fun parse(raw: String?): Trigger? = values().firstOrNull { it.wire == raw }
        }
    }

    /**
     * One rule as the app wrote it.
     *
     * [serverId] null means every node the site reports. A rule naming a node
     * the site no longer carries is kept in the app but is not evaluated here:
     * the node it watches is not in the server list, so there is no history to
     * ask for.
     */
    data class Rule(
        val id: String,
        val name: String,
        val metric: Metric,
        val threshold: Double,
        val serverId: String?,
        val windowMinutes: Int,
        val trigger: Trigger,
        val enabled: Boolean,
    )

    /** One node, as far as evaluation is concerned. */
    data class Server(val id: String, val name: String)

    /**
     * One history row, with the metric columns already reduced to the numbers a
     * threshold is compared against. A column the row did not carry is null,
     * and a null never counts as a sample.
     */
    data class Row(
        val timestamp: Long,
        val cpu: Double?,
        val ramPct: Double?,
        val diskPct: Double?,
        val netInMbps: Double?,
        val netOutMbps: Double?,
    )

    data class Alert(
        val ruleId: String,
        val serverId: String,
        val title: String,
        val text: String,
    )

    /**
     * A window needs at least this many samples to be judged.
     *
     * The site samples about every two minutes, so the smallest window the UI
     * offers holds several. One sample is a point reading rather than a window —
     * it cannot tell "the average is over" apart from "every sample is over",
     * which is the whole difference between the two triggers — and a node that
     * just started reporting would otherwise alert on its first row.
     */
    const val MIN_SAMPLES = 2

    private const val FIRING = "1"

    /**
     * The `hours` query parameter that covers [windowMinutes].
     *
     * The site accepts only the ranges its own chart picker offers (0.167, 0.5,
     * 1, 6, 12, 24, 48, 96, 168) and rejects anything else, so the mapping has
     * to land on one of them.
     *
     * Which one is not simply "the smallest that is at least the window": the
     * endpoint caps its answer at about 120 rows and downsamples to fit, so a
     * range's rows do not reach all the way back to the range it names.
     * Measured against the live site, `hours=1` returns a 58-minute span — less
     * than the hour it was asked for. The steps below therefore sit one rung
     * above the window, which costs a larger response and never a wrong answer:
     * rows outside the window are discarded by [evaluate], not by the request.
     */
    fun windowHours(windowMinutes: Int): Double = when {
        windowMinutes <= 5 -> 0.167
        windowMinutes <= 15 -> 0.5
        windowMinutes <= 30 -> 1.0
        windowMinutes <= 60 -> 6.0
        windowMinutes <= 360 -> 12.0
        windowMinutes <= 720 -> 24.0
        windowMinutes <= 1440 -> 48.0
        windowMinutes <= 2880 -> 96.0
        else -> 168.0
    }

    /** [windowHours] as the query string spells it: `1`, not `1.0`. */
    fun windowHoursParam(windowMinutes: Int): String {
        val hours = windowHours(windowMinutes)
        val asInt = hours.toInt()
        return if (asInt.toDouble() == hours) asInt.toString() else hours.toString()
    }

    fun value(row: Row, metric: Metric): Double? = when (metric) {
        Metric.CPU -> row.cpu
        Metric.RAM -> row.ramPct
        Metric.DISK -> row.diskPct
        Metric.NET_IN -> row.netInMbps
        Metric.NET_OUT -> row.netOutMbps
    }

    /**
     * The rules carried by an alert settings payload, dropping any that do not
     * parse.
     *
     * A rule the evaluator cannot name is one it cannot report on, and a
     * defaulted metric would alert about something nobody asked for, so an
     * unreadable rule is skipped rather than guessed at. One bad rule is not a
     * reason to lose the rest.
     */
    fun parseRules(array: JSONArray?): List<Rule> {
        if (array == null) return emptyList()
        val rules = ArrayList<Rule>(array.length())
        for (i in 0 until array.length()) {
            val o = array.optJSONObject(i) ?: continue
            val id = o.optString("id").takeIf { it.isNotEmpty() } ?: continue
            val metric = Metric.parse(o.optString("metric")) ?: continue
            val trigger = Trigger.parse(o.optString("trigger")) ?: continue
            val threshold = o.optDoubleOrNull("threshold") ?: continue
            val window = o.optInt("windowMinutes", 0)
            if (window <= 0) continue
            rules += Rule(
                id = id,
                name = o.optString("name").trim().ifEmpty { metric.wire },
                metric = metric,
                threshold = threshold,
                serverId = o.optString("serverId").takeIf { it.isNotEmpty() },
                windowMinutes = window,
                trigger = trigger,
                // Absent means enabled: a rule the payload did not mention the
                // state of is one the app means to run.
                enabled = o.optBoolean("enabled", true),
            )
        }
        return rules
    }

    /** [parseRules] over the raw JSON text the settings store holds. */
    fun parseStoredRules(raw: String?): List<Rule> {
        if (raw.isNullOrEmpty()) return emptyList()
        return try {
            parseRules(JSONArray(raw))
        } catch (_: Exception) {
            emptyList()
        }
    }

    /**
     * `GET /api/history/all`'s body as rows.
     *
     * A row without a usable timestamp is dropped: the window is a time range,
     * and a row that cannot be placed in time cannot be placed in a window.
     */
    fun parseRows(body: String): List<Row> {
        val array = try {
            JSONArray(body)
        } catch (_: Exception) {
            return emptyList()
        }
        val rows = ArrayList<Row>(array.length())
        for (i in 0 until array.length()) {
            val o = array.optJSONObject(i) ?: continue
            val timestamp = o.optLong("timestamp", 0L)
            if (timestamp <= 0L) continue
            rows += Row(
                timestamp = timestamp,
                cpu = o.optDoubleOrNull("cpu"),
                ramPct = percent(o.optDoubleOrNull("ram_used"), o.optDoubleOrNull("ram_total")),
                diskPct = percent(o.optDoubleOrNull("disk_used"), o.optDoubleOrNull("disk_total")),
                netInMbps = mbps(o.optDoubleOrNull("net_in_speed")),
                netOutMbps = mbps(o.optDoubleOrNull("net_out_speed")),
            )
        }
        return rows
    }

    /**
     * Runs every enabled rule over the history collected for it, and returns
     * the alerts that have just started firing.
     *
     * [state] is the worker's persisted dedup map and is edited in place: a key
     * is written when a rule starts firing and removed when it stops, so the
     * alert is edge-triggered — one notification per episode, not one per
     * 15-minute run. A window that cannot be judged (no history, too few
     * samples) leaves the state alone rather than reading as "recovered": a
     * node that goes offline mid-episode should not re-alert the moment it
     * comes back.
     *
     * [histories] is keyed by server id; a server with no entry is skipped.
     */
    fun evaluate(
        rules: List<Rule>,
        servers: List<Server>,
        histories: Map<String, List<Row>>,
        state: MutableMap<String, String>,
        now: Long = System.currentTimeMillis(),
    ): List<Alert> {
        val byId = servers.associateBy { it.id }
        val alerts = mutableListOf<Alert>()

        for (rule in rules) {
            if (!rule.enabled) continue
            // A rule naming a node the site no longer reports has nothing to
            // watch; one naming no node watches them all.
            val targets = rule.serverId?.let { listOfNotNull(byId[it]) } ?: servers
            for (server in targets) {
                val rows = histories[server.id] ?: continue
                val windowStart = now - rule.windowMinutes * 60_000L
                val values = rows
                    .filter { it.timestamp >= windowStart }
                    .mapNotNull { value(it, rule.metric) }
                if (values.size < MIN_SAMPLES) continue

                val mean = values.average()
                val firing = when (rule.trigger) {
                    Trigger.AVG -> mean > rule.threshold
                    Trigger.ALL -> values.all { it > rule.threshold }
                }

                val key = stateKey(rule.id, server.id)
                if (firing && state[key] != FIRING) {
                    state[key] = FIRING
                    alerts += alert(rule, server, values.size, mean)
                } else if (!firing) {
                    state.remove(key)
                }
            }
        }
        return alerts
    }

    /**
     * Drops dedup keys whose rule is gone from [rules], so deleting a rule does
     * not leave its state behind forever.
     *
     * Only rules that no longer exist are cleared. A disabled rule keeps its
     * state, because "disabled" is not "recovered": the rule is not being
     * evaluated, so nothing has been observed that could clear it.
     */
    fun pruneState(rules: List<Rule>, state: MutableMap<String, String>) {
        val alive = rules.map { it.id }.toSet()
        state.keys.removeAll { key ->
            key.startsWith(PREFIX) && ruleIdOf(key)?.let { it !in alive } == true
        }
    }

    /** The dedup key for one rule on one node. */
    fun stateKey(ruleId: String, serverId: String): String = "$PREFIX${ruleId}_$serverId"

    private const val PREFIX = "res_"

    /**
     * The rule id inside a [stateKey], or null when the key is not one.
     *
     * A rule id is minted without underscores (`r` + base-36 microseconds), so
     * the last underscore separates it from the node id — which is a UUID and
     * has none of its own.
     */
    private fun ruleIdOf(key: String): String? {
        val body = key.removePrefix(PREFIX)
        val cut = body.lastIndexOf('_')
        if (cut <= 0) return null
        return body.substring(0, cut)
    }

    private fun alert(rule: Rule, server: Server, samples: Int, mean: Double): Alert {
        val unit = rule.metric.unit
        val threshold = format(rule.threshold)
        val text = when (rule.trigger) {
            Trigger.AVG ->
                "最近 ${rule.windowMinutes} 分钟均值 ${format(mean)}$unit，" +
                    "超过阈值 $threshold$unit（$samples 个采样）"
            Trigger.ALL ->
                "最近 ${rule.windowMinutes} 分钟 $samples 个采样全部超过 $threshold$unit" +
                    "（均值 ${format(mean)}$unit）"
        }
        return Alert(
            ruleId = rule.id,
            serverId = server.id,
            title = "${server.name} ${rule.name}",
            text = text,
        )
    }

    /** One decimal, and never a trailing `.0` — the unit carries the rest. */
    private fun format(v: Double): String {
        val s = String.format(Locale.US, "%.1f", v)
        return if (s.endsWith(".0")) s.dropLast(2) else s
    }

    /** Used over total as a percentage, or null when there is no total. */
    private fun percent(used: Double?, total: Double?): Double? {
        if (used == null || total == null || total <= 0.0) return null
        return used / total * 100.0
    }

    /** The site reports speeds in bytes per second; the threshold is in Mbps. */
    private fun mbps(bytesPerSecond: Double?): Double? =
        bytesPerSecond?.let { it * 8.0 / 1_000_000.0 }

    private fun JSONObject.optDoubleOrNull(key: String): Double? =
        if (has(key) && !isNull(key)) {
            when (val v = opt(key)) {
                is Number -> v.toDouble()
                is String -> v.toDoubleOrNull()
                else -> null
            }
        } else null
}
