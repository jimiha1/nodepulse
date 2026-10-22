package app.nodepulse.widget

import android.content.Context
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import app.nodepulse.cf.CfHttp
import java.io.IOException
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Fetches CF-Server-Monitor endpoints directly for home widgets.
 */
object WidgetApi {
    private const val TAG = "WidgetApi"

    class InsecureException : IOException("HTTPS required")

    class MissingSiteUrlException : IOException("No site URL configured")

    class MissingTokenException : IOException("No credential")

    class RejectedTokenException : IOException("Credential rejected")

    /** One reading, supporting all custom WidgetField options. */
    data class Reading(
        val name: String,
        val cpu: Double?,
        val mem: Double?,
        val disk: Double?,
        val memText: String,
        val diskText: String,
        val netText: String,
        val loadText: String = "",
        val netTotalText: String = "",
        val trafficLeftText: String = "",
        val connText: String = "",
        val pingText: String = "",
        val lossText: String = "",
        val uptimeText: String = "",
        val expireText: String = "",
        val load1: Double = 0.0,
        val diskIoText: String = "",
        val procText: String = "",
        val avgLoss: Double? = null,
        /** When the node last reported, epoch ms. Null when the site omits it. */
        val lastUpdated: Long? = null,
        // The raw values the 2x4 widget draws, kept beside the pre-formatted
        // strings above: its rows share a unit between two numbers, which a
        // string that has already been formatted cannot do.
        val cpuCores: Int? = null,
        val region: String? = null,
        // Bytes, not the MB the site reports: the memory and disk rows put
        // both numbers under one shared unit, which needs the raw pair.
        val ramUsedBytes: Double = 0.0,
        val ramTotalBytes: Double = 0.0,
        val diskUsedBytes: Double = 0.0,
        val diskTotalBytes: Double = 0.0,
        val netIn: Double = 0.0,
        val netOut: Double = 0.0,
        val netRxMonthly: Double = 0.0,
        val netTxMonthly: Double = 0.0,
        val load5: Double = 0.0,
        val load15: Double = 0.0,
        val pingCt: Double? = null,
        val pingCu: Double? = null,
        val pingCm: Double? = null,
        val lossCt: Double? = null,
        val lossCu: Double? = null,
        val lossCm: Double? = null,
    )

    /** One bucket of history, oldest first. */
    data class HistoryPoint(
        val cpu: Double,
        val memory: Double,
        val disk: Double,
        val netRx: Double,
        val netTx: Double,
        val load: Double = 0.0,
        val io: Double = 0.0,
        val conn: Double = 0.0,
        val proc: Double = 0.0,
        val loss: Double = 0.0,
        val pingCt: Double? = null,
        val pingCu: Double? = null,
        val pingCm: Double? = null,
        // Kept per carrier, not just as the `loss` average above: that average
        // is 0.0 when a site reports no loss at all, and a stability score
        // cannot tell that apart from a perfect link.
        val lossCt: Double? = null,
        val lossCu: Double? = null,
        val lossCm: Double? = null,
    )

    /**
     * How long `/api/servers` may take.
     *
     * The reading is the point of the widget, so this stays short: a node whose
     * metrics cannot be read is a failure worth showing.
     */
    const val SERVERS_TIMEOUT_MS = 8_000

    /**
     * How long `/api/history/all` may take.
     *
     * Longer than [SERVERS_TIMEOUT_MS] because this request is the slow one and
     * it is allowed to be. The site answers a warm query from memory in
     * milliseconds, but a cold one runs a sampling query over the history table
     * — measured at 9-16s against a real site — and its cache only holds a
     * `hours=24` answer for 15 minutes. At the reading's 8s this request was
     * cut off routinely, and because the caller could not tell a cut-off from
     * an empty answer, the chart it had already drawn was replaced by "暂无历史".
     */
    const val HISTORY_TIMEOUT_MS = 20_000

    /** What one refresh hands back: the reading, and how the history went. */
    data class Fetched(
        val reading: Reading,
        /**
         * The history rows, or empty when [historyFailed]. Callers must run
         * this through [WidgetRefresh.plan] rather than showing it directly:
         * empty is ambiguous here, and the two cases want opposite handling.
         */
        val history: List<HistoryPoint>,
        /** Whether the history request failed, as opposed to answering empty. */
        val historyFailed: Boolean,
    )

    /**
     * [historyHours] as the query string spells it: `24`, not `24.0`.
     *
     * The whole numbers are what this widget has always sent, and a `Double`
     * formatted straight into the URL would have changed the request for the
     * 4x2 too — a change nothing asked for and nothing would have caught
     * short of the site rejecting it. The fractional ranges keep their
     * decimal because that is the only way to spell them.
     */
    internal fun historyHoursParam(hours: Double): String {
        val asInt = hours.toInt()
        return if (asInt.toDouble() == hours) asInt.toString() else hours.toString()
    }

    /**
     * Fetches one server's reading and history.
     *
     * [historyHours] is the window the caller wants to plot. It is not free
     * to pick: the site accepts only the ranges `API.md` enumerates (0.167,
     * 0.5, 1, 6, 12, 24, 48, 96, 168) and rejects anything else. The 2x4 asks
     * for one hour because its stability section claims exactly that window;
     * the 4x2 keeps the day it always had.
     */
    suspend fun load(
        context: Context,
        server: WidgetStore.WidgetServer,
        historyHours: Double = 24.0,
    ): Fetched = withContext(Dispatchers.IO) {
        val siteUrl = WidgetStore.siteUrl(context) ?: throw MissingSiteUrlException()
        val token = WidgetStore.token(context)
        val reading = try {
            val serversBody = get(siteUrl, "/api/servers", token, SERVERS_TIMEOUT_MS)
            parseCfMetrics(server, serversBody)
        } catch (e: RejectedTokenException) {
            WidgetStore.setToken(context, null)
            throw e
        }

        // History is not fatal to the reading — but it is not the same as an
        // empty history either, and the difference is the whole of this call's
        // contract: an empty array is a site that has history turned off, and
        // must be shown as such; a failure is a request that has to be made
        // again, and must leave the chart that is already up alone until it
        // succeeds. Swallowing the failure into `emptyList()` here is what made
        // a slow history request look like a node with nothing to plot.
        val history = try {
            val historyBody = get(
                siteUrl,
                "/api/history/all?id=${server.id}&hours=${historyHoursParam(historyHours)}",
                token,
                HISTORY_TIMEOUT_MS,
            )
            parseCfHistory(historyBody) to false
        } catch (e: Exception) {
            Log.w(TAG, "History for ${server.id} failed: ${e.message}")
            emptyList<HistoryPoint>() to true
        }

        Fetched(reading = reading, history = history.first, historyFailed = history.second)
    }

    private fun get(
        siteUrl: String,
        path: String,
        token: String?,
        timeoutMs: Int = SERVERS_TIMEOUT_MS,
    ): String {
        val base = siteUrl.trimEnd('/')
        val url = URL(base + path)
        if (url.protocol != "https") throw InsecureException()

        // Through [CfHttp] rather than `HttpURLConnection`: that class asks
        // the platform resolver for the address itself, and a resolver that
        // has been tampered with answers with a server that is not the site —
        // which is what turned "the widget shows the wrong numbers" into a
        // certificate error from a self-signed impostor.
        return try {
            CfHttp.shared.get(
                url = url.toString(),
                userAgent = "NodePulse-Widget/2",
                token = token,
                timeoutMs = timeoutMs,
            )
        } catch (e: CfHttp.HttpStatusException) {
            if (e.code == 401 || e.code == 403) throw RejectedTokenException()
            throw IOException("HTTP ${e.code}", e)
        }
    }

    fun parseCfMetrics(server: WidgetStore.WidgetServer, body: String): Reading {
        val root = JSONObject(body)
        val arr = root.optJSONArray("servers") ?: JSONArray()
        var node: JSONObject? = null
        for (i in 0 until arr.length()) {
            val item = arr.optJSONObject(i) ?: continue
            if (item.optString("id") == server.id) {
                node = item
                break
            }
        }
        val o = node ?: JSONObject()

        val cpu = o.optDoubleOrNull("cpu")
        val ramTotal = o.optDoubleOrNull("ram_total") ?: 0.0 // in MB
        val ramUsed = o.optDoubleOrNull("ram_used") ?: 0.0 // in MB
        val memPercent = if (ramTotal > 0) (ramUsed / ramTotal * 100.0) else null

        val diskTotal = o.optDoubleOrNull("disk_total") ?: 0.0 // in MB
        val diskUsed = o.optDoubleOrNull("disk_used") ?: 0.0 // in MB
        val diskPercent = if (diskTotal > 0) (diskUsed / diskTotal * 100.0) else null

        val netInSpeed = o.optDoubleOrNull("net_in_speed") ?: 0.0 // B/s
        val netOutSpeed = o.optDoubleOrNull("net_out_speed") ?: 0.0 // B/s

        // ramTotal and ramUsed are in MB, convert to bytes for formatBytes
        val ramUsedBytes = ramUsed * 1024.0 * 1024.0
        val ramTotalBytes = ramTotal * 1024.0 * 1024.0
        val diskUsedBytes = diskUsed * 1024.0 * 1024.0
        val diskTotalBytes = diskTotal * 1024.0 * 1024.0

        // Parse load_avg
        val loadAvgRaw = o.opt("load_avg")
        val loads = parseLoads(loadAvgRaw)
        val loadText = if (loads.isNotEmpty()) {
            loads.joinToString(" ") { String.format(Locale.US, "%.2f", it) }
        } else "--"

        // Traffic totals and limits
        val netRx = o.optDoubleOrNull("net_rx") ?: 0.0
        val netTx = o.optDoubleOrNull("net_tx") ?: 0.0
        val netTotalText = "${formatBytes(netRx)} / ${formatBytes(netTx)}"

        val trafficLimit = o.opt("traffic_limit")
        val trafficCalcType = o.optString("traffic_calc_type")
        val netRxMonthly = o.optDoubleOrNull("net_rx_monthly") ?: 0.0
        val netTxMonthly = o.optDoubleOrNull("net_tx_monthly") ?: 0.0
        val limitBytes = parseTrafficLimitToBytes(trafficLimit)
        val usedMonthly = calcUsedMonthly(trafficCalcType, netRxMonthly, netTxMonthly)
        val trafficLeftText = if (limitBytes > 0) {
            "${formatBytes(usedMonthly)} / ${formatBytes(limitBytes.toDouble())}"
        } else {
            "${formatBytes(usedMonthly)} / ∞"
        }

        // Connections
        val tcpConn = o.optIntOrNull("tcp_conn")
        val udpConn = o.optIntOrNull("udp_conn")
        val connText = when {
            tcpConn != null && udpConn != null -> "T:$tcpConn U:$udpConn"
            tcpConn != null -> "$tcpConn"
            udpConn != null -> "$udpConn"
            else -> "--"
        }

        // Ping: compact slash format "165/78/310ms"
        val pingCt = o.optDoubleOrNull("ping_ct")
        val pingCu = o.optDoubleOrNull("ping_cu")
        val pingCm = o.optDoubleOrNull("ping_cm")
        val pingText = if (pingCt != null || pingCu != null || pingCm != null) {
            val ct = pingCt?.let { "${it.toInt()}" } ?: "-"
            val cu = pingCu?.let { "${it.toInt()}" } ?: "-"
            val cm = pingCm?.let { "${it.toInt()}" } ?: "-"
            "$ct/$cu/${cm}ms"
        } else "--"

        // Loss: compact slash format "0/0/0%"
        val lossCt = o.optDoubleOrNull("loss_ct")
        val lossCu = o.optDoubleOrNull("loss_cu")
        val lossCm = o.optDoubleOrNull("loss_cm")
        val lossText = if (lossCt != null || lossCu != null || lossCm != null) {
            val ct = lossCt?.let { "${it.toInt()}" } ?: "-"
            val cu = lossCu?.let { "${it.toInt()}" } ?: "-"
            val cm = lossCm?.let { "${it.toInt()}" } ?: "-"
            "$ct/$cu/$cm%"
        } else "--"

        val losses = listOfNotNull(lossCt, lossCu, lossCm)
        val avgLoss = if (losses.isNotEmpty()) losses.average() else null

        // Uptime
        val bootTime = o.optDoubleOrNull("boot_time")
        val uptimeText = if (bootTime != null && bootTime > 0) {
            val bootSec = if (bootTime >= 1e11) (bootTime / 1000).toLong() else bootTime.toLong()
            val nowSec = System.currentTimeMillis() / 1000
            val upSec = (nowSec - bootSec).coerceAtLeast(0)
            formatUptime(upSec)
        } else "--"

        // Expire
        val expireRaw = o.optString("expire_date")
        val expireText = if (expireRaw.isNotEmpty()) expireRaw else "--"

        val proc = o.optIntOrNull("processes")
        val procText = proc?.toString() ?: "--"

        val lastUpdatedRaw = o.optLong("last_updated", 0L)
        val lastUpdated = if (lastUpdatedRaw > 0) lastUpdatedRaw else null

        return Reading(
            name = o.optString("name").ifEmpty { server.name },
            cpu = cpu,
            mem = memPercent,
            disk = diskPercent,
            memText = "${formatBytes(ramUsedBytes)} / ${formatBytes(ramTotalBytes)}",
            diskText = "${formatBytes(diskUsedBytes)} / ${formatBytes(diskTotalBytes)}",
            netText = "↑${formatBytes(netOutSpeed)}/s ↓${formatBytes(netInSpeed)}/s",
            loadText = loadText,
            netTotalText = netTotalText,
            trafficLeftText = trafficLeftText,
            connText = connText,
            pingText = pingText,
            lossText = lossText,
            uptimeText = uptimeText,
            expireText = expireText,
            load1 = loads.firstOrNull() ?: 0.0,
            diskIoText = "--",
            procText = procText,
            avgLoss = avgLoss,
            lastUpdated = lastUpdated,
            cpuCores = o.optIntOrNull("cpu_cores"),
            region = o.optString("region").takeIf { it.isNotEmpty() } ?: server.region,
            ramUsedBytes = ramUsedBytes,
            ramTotalBytes = ramTotalBytes,
            diskUsedBytes = diskUsedBytes,
            diskTotalBytes = diskTotalBytes,
            netIn = netInSpeed,
            netOut = netOutSpeed,
            netRxMonthly = netRxMonthly,
            netTxMonthly = netTxMonthly,
            load5 = loads.getOrNull(1) ?: 0.0,
            load15 = loads.getOrNull(2) ?: 0.0,
            pingCt = pingCt,
            pingCu = pingCu,
            pingCm = pingCm,
            lossCt = lossCt,
            lossCu = lossCu,
            lossCm = lossCm,
        )
    }

    fun parseCfHistory(body: String): List<HistoryPoint> {
        val arr = JSONArray(body)
        return (0 until arr.length()).mapNotNull { i ->
            val o = arr.optJSONObject(i) ?: return@mapNotNull null
            val ramTotal = o.optDoubleOrNull("ram_total") ?: 0.0
            val ramUsed = o.optDoubleOrNull("ram_used") ?: 0.0
            val memPercent = if (ramTotal > 0) (ramUsed / ramTotal * 100.0) else 0.0

            val diskTotal = o.optDoubleOrNull("disk_total") ?: 0.0
            val diskUsed = o.optDoubleOrNull("disk_used") ?: 0.0
            val diskPercent = if (diskTotal > 0) (diskUsed / diskTotal * 100.0) else 0.0

            val loadAvg = parseLoads(o.opt("load_avg")).firstOrNull() ?: 0.0
            val diskR = o.optDoubleOrNull("disk_read_bps") ?: 0.0
            val diskW = o.optDoubleOrNull("disk_write_bps") ?: 0.0
            val tcpConn = o.optDoubleOrNull("tcp_conn") ?: 0.0
            val udpConn = o.optDoubleOrNull("udp_conn") ?: 0.0
            val proc = o.optDoubleOrNull("processes") ?: 0.0

            val lCt = o.optDoubleOrNull("loss_ct")
            val lCu = o.optDoubleOrNull("loss_cu")
            val lCm = o.optDoubleOrNull("loss_cm")
            val validLosses = listOfNotNull(lCt, lCu, lCm)
            val avgL = if (validLosses.isNotEmpty()) validLosses.average() else 0.0

            HistoryPoint(
                cpu = o.optDouble("cpu", 0.0),
                memory = memPercent,
                disk = diskPercent,
                netRx = o.optDouble("net_in_speed", 0.0),
                netTx = o.optDouble("net_out_speed", 0.0),
                load = loadAvg,
                io = diskR + diskW,
                conn = tcpConn + udpConn,
                proc = proc,
                loss = avgL,
                pingCt = o.optDoubleOrNull("ping_ct"),
                pingCu = o.optDoubleOrNull("ping_cu"),
                pingCm = o.optDoubleOrNull("ping_cm"),
                lossCt = lCt,
                lossCu = lCu,
                lossCm = lCm,
            )
        }
    }

    private fun parseLoads(v: Any?): List<Double> {
        if (v == null) return emptyList()
        val str = v.toString().trim()
        if (str.isEmpty()) return emptyList()
        return str.split(Regex("\\s+")).mapNotNull { it.toDoubleOrNull() }
    }

    private fun calcUsedMonthly(calcType: String?, rxMonthly: Double, txMonthly: Double): Double {
        return when ((calcType ?: "").trim().lowercase(Locale.ROOT)) {
            "ul", "up" -> txMonthly
            "dl", "down" -> rxMonthly
            "total", "sum" -> rxMonthly + txMonthly
            "min" -> if (rxMonthly < txMonthly) rxMonthly else txMonthly
            else -> if (rxMonthly > txMonthly) rxMonthly else txMonthly
        }
    }

    private fun parseTrafficLimitToBytes(v: Any?): Long {
        if (v == null) return 0L
        if (v is Number) return if (v.toDouble() > 0) (v.toDouble() * 1024 * 1024 * 1024).toLong() else 0L
        val str = v.toString().trim()
        if (str.isEmpty()) return 0L
        val match = Regex("""^([\d.]+)\s*(b|kb|mb|gb|tb|pb)?$""", RegexOption.IGNORE_CASE).find(str)
            ?: return (str.toDoubleOrNull() ?: 0.0).toLong()
        val num = match.groupValues[1].toDoubleOrNull() ?: return 0L
        val unit = match.groupValues.getOrNull(2)?.lowercase(Locale.ROOT) ?: "gb"
        val multiplier = when (unit) {
            "b" -> 1L
            "kb" -> 1024L
            "mb" -> 1024L * 1024
            "gb" -> 1024L * 1024 * 1024
            "tb" -> 1024L * 1024 * 1024 * 1024
            "pb" -> 1024L * 1024 * 1024 * 1024 * 1024
            else -> 1024L * 1024 * 1024
        }
        return (num * multiplier).toLong()
    }

    fun formatUptime(seconds: Long): String {
        val days = seconds / 86400
        val hours = (seconds % 86400) / 3600
        val mins = (seconds % 3600) / 60
        return when {
            days > 0 -> "${days}d ${hours}h"
            hours > 0 -> "${hours}h ${mins}m"
            else -> "${mins}m"
        }
    }

    private fun JSONObject.optDoubleOrNull(key: String): Double? =
        if (has(key) && !isNull(key)) {
            val v = opt(key)
            when (v) {
                is Number -> v.toDouble()
                is String -> v.toDoubleOrNull()
                else -> null
            }
        } else null

    private fun JSONObject.optIntOrNull(key: String): Int? =
        if (has(key) && !isNull(key)) {
            val v = opt(key)
            when (v) {
                is Number -> v.toInt()
                is String -> v.toIntOrNull()
                else -> null
            }
        } else null

    fun formatBytes(bytes: Double): String {
        val units = listOf("b", "k", "m", "g", "t", "p")
        var value = bytes.coerceAtLeast(0.0)
        var idx = 0
        while (value >= 1024 && idx < units.size - 1) {
            value /= 1024
            idx++
        }
        return if (idx == 0) {
            "${value.toInt()}${units[idx]}"
        } else {
            val formatted = String.format(Locale.US, "%.1f", value)
            val cleanValue = if (formatted.endsWith(".0")) formatted.dropLast(2) else formatted
            "$cleanValue${units[idx]}"
        }
    }

    private val SHARED_UNITS = listOf("B", "KiB", "MiB", "GiB", "TiB", "PiB")

    /**
     * A byte count in the largest unit it fills, and that unit's index.
     *
     * Binary units spelled the way the reference design spells them — the
     * lowercase `formatBytes` above stays as it is, because the 4x2 capsules
     * have their own look and this is not the place to change it.
     */
    private fun scaled(bytes: Double): Pair<Double, Int> {
        var value = bytes.coerceAtLeast(0.0)
        var idx = 0
        while (value >= 1024 && idx < SHARED_UNITS.size - 1) {
            value /= 1024
            idx++
        }
        return value to idx
    }

    /**
     * Three significant-ish digits, so a row's two numbers stay short enough
     * for two cells: `233`, `14.1`, `2`. Anything at or above 100 has no room
     * for a decimal; below that one is worth keeping.
     */
    private fun compact(value: Double): String =
        if (value >= 100.0) {
            String.format(Locale.US, "%.0f", value)
        } else {
            String.format(Locale.US, "%.1f", value).removeSuffix(".0")
        }

    /**
     * Two byte counts sharing one unit when they scale alike.
     *
     * `232.65 MiB / 431.00 MiB` does not fit a two-cell row; `233 / 431 MiB`
     * says the same thing in half the characters. A pair that lands in
     * different units keeps each of them, because collapsing those would
     * misstate one of the numbers.
     */
    fun formatSharedUnit(a: Double, b: Double): String {
        val (av, ai) = scaled(a)
        val (bv, bi) = scaled(b)
        return if (ai == bi) {
            "${compact(av)} / ${compact(bv)} ${SHARED_UNITS[ai]}"
        } else {
            "${compact(av)} ${SHARED_UNITS[ai]} / ${compact(bv)} ${SHARED_UNITS[bi]}"
        }
    }

    /** [formatSharedUnit] as a down/up pair, each side marked with its direction. */
    fun formatSharedPair(down: Double, up: Double, perSecond: Boolean = false): String {
        val (dv, di) = scaled(down)
        val (uv, ui) = scaled(up)
        val suffix = if (perSecond) "/s" else ""
        return if (di == ui) {
            "↓${compact(dv)} · ↑${compact(uv)} ${SHARED_UNITS[di]}$suffix"
        } else {
            "↓${compact(dv)} ${SHARED_UNITS[di]}$suffix · " +
                "↑${compact(uv)} ${SHARED_UNITS[ui]}$suffix"
        }
    }

    fun displayHost(addr: String): String =
        runCatching { Uri.parse(addr).host ?: addr }.getOrDefault(addr)
}

/**
 * What to draw for the history half of a refresh, and whether another attempt
 * is owed.
 *
 * Apart from [WidgetApi.load] so it can be tested without an Android runtime:
 * the decision is the part that was wrong — a failed history was stored as an
 * empty one, which blanked a chart that was already on screen and cancelled the
 * retry that would have refilled it.
 */
internal object WidgetRefresh {
    data class Plan(
        val history: List<WidgetApi.HistoryPoint>,
        val retry: Boolean,
    )

    /**
     * [fetched] is what this refresh got, [failed] says whether getting it went
     * wrong, and [held] is what the widget already had on screen.
     *
     * A failure keeps [held] — the last rows the node did report, which are
     * still the best answer available — and asks for another attempt, because
     * nothing else will: the launcher's own update is half an hour away at best
     * and this device's vendor build defers it further.
     *
     * A success is taken at its word, including an empty one. A site with
     * history turned off answers with `[]`, and that is an answer: retrying it
     * would poll forever for something that is not coming, and keeping the old
     * points would draw a chart the site has stopped producing.
     */
    fun plan(
        fetched: List<WidgetApi.HistoryPoint>,
        failed: Boolean,
        held: List<WidgetApi.HistoryPoint>,
    ): Plan = if (failed) {
        Plan(history = held, retry = true)
    } else {
        Plan(history = fetched, retry = false)
    }
}
