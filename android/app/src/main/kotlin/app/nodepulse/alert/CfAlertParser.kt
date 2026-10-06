package app.nodepulse.alert

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

object CfAlertParser {

    enum class AlertKind {
        TRAFFIC,
        EXPIRE,
        EXPIRED
    }

    data class Alert(
        val nodeId: String,
        val nodeName: String,
        val kind: AlertKind,
        val tierOrDays: Int,
        val title: String,
        val text: String,
    )

    /** Why an alert that qualifies was not sent. */
    enum class SuppressedReason {
        /**
         * Expiry, already sent once today. It comes back tomorrow — the
         * reminder is daily, not one-shot.
         */
        TODAY,

        /**
         * Traffic, at a tier already announced. Unlike expiry this does not
         * come back on its own: only crossing into a higher tier sends again.
         */
        TIER,
    }

    /** An alert the dedup state held back, and what held it. */
    data class Suppressed(
        val alert: Alert,
        val reason: SuppressedReason,
    )

    private val TIERS = listOf(80, 90, 95)

    /**
     * Reads the fleet and returns the alerts to send.
     *
     * [suppressed], when given, is filled with the alerts that qualified but
     * were held back by the dedup state. The periodic worker passes nothing —
     * a held-back alert is not news to it — but the settings page's "check
     * now" does, because "already sent today" and "nothing to send" are
     * different answers and the user is owed the right one.
     */
    fun check(
        json: String,
        trafficThresholdPct: Int,
        expiryDays: Int,
        state: MutableMap<String, String>,
        today: LocalDate = LocalDate.now(),
        suppressed: MutableList<Suppressed>? = null,
    ): List<Alert> {
        val root = try {
            JSONObject(json)
        } catch (_: Exception) {
            return emptyList()
        }

        val servers = root.optJSONArray("servers") ?: JSONArray()
        val alerts = mutableListOf<Alert>()
        val todayStr = today.toString()

        for (i in 0 until servers.length()) {
            val s = servers.optJSONObject(i) ?: continue
            val id = s.optString("id").ifEmpty { continue }
            val name = s.optString("name").ifEmpty { id }

            // 1. Traffic check
            val trafficLimitRaw = s.opt("traffic_limit")
            val limitBytes = parseTrafficLimitToBytes(trafficLimitRaw)
            if (limitBytes > 0) {
                val calcType = s.optString("traffic_calc_type")
                val rxMonthly = s.optDoubleOrNull("net_rx_monthly") ?: 0.0
                val txMonthly = s.optDoubleOrNull("net_tx_monthly") ?: 0.0
                val usedMonthly = calcUsedMonthly(calcType, rxMonthly, txMonthly)

                val ratio = usedMonthly / limitBytes.toDouble()
                val usedPct = (ratio * 100.0).toInt()

                // Find the highest tier reached that is >= configured trafficThresholdPct
                val qualifiedTiers = TIERS.filter { it in trafficThresholdPct..usedPct }
                val highestTier = qualifiedTiers.maxOrNull()

                if (highestTier != null) {
                    val key = "alert_${id}_traffic"
                    val lastTier = state[key]?.toIntOrNull() ?: 0
                    val alert = Alert(
                        nodeId = id,
                        nodeName = name,
                        kind = AlertKind.TRAFFIC,
                        tierOrDays = highestTier,
                        title = "$name 流量达到 ${highestTier}%",
                        text = "当月流量已用 ${(ratio * 100.0).formatOneDecimal()}%（限额: ${formatBytes(limitBytes.toDouble())}）",
                    )
                    if (highestTier > lastTier) {
                        state[key] = highestTier.toString()
                        alerts.add(alert)
                    } else {
                        suppressed?.add(Suppressed(alert, SuppressedReason.TIER))
                    }
                }
            }

            // 2. Expiry check
            val expireRaw = s.optString("expire_date").trim()
            if (expireRaw.isNotEmpty()) {
                val expireDate = parseDate(expireRaw)
                if (expireDate != null) {
                    val daysUntil = ChronoUnit.DAYS.between(today, expireDate).toInt()
                    val expireKey = "alert_${id}_expire"
                    val lastNotifiedDate = state[expireKey]

                    if (daysUntil < 0) {
                        // Expired
                        val alert = Alert(
                            nodeId = id,
                            nodeName = name,
                            kind = AlertKind.EXPIRED,
                            tierOrDays = daysUntil,
                            title = "$name 已过期",
                            text = "节点到期日为 $expireRaw，目前已过期 ${-daysUntil} 天",
                        )
                        if (lastNotifiedDate != todayStr) {
                            state[expireKey] = todayStr
                            alerts.add(alert)
                        } else {
                            suppressed?.add(Suppressed(alert, SuppressedReason.TODAY))
                        }
                    } else if (daysUntil <= expiryDays) {
                        // Expiring soon
                        val alert = Alert(
                            nodeId = id,
                            nodeName = name,
                            kind = AlertKind.EXPIRE,
                            tierOrDays = daysUntil,
                            title = "$name 即将到期",
                            text = "节点将于 $daysUntil 天后到期（$expireRaw）",
                        )
                        if (lastNotifiedDate != todayStr) {
                            state[expireKey] = todayStr
                            alerts.add(alert)
                        } else {
                            suppressed?.add(Suppressed(alert, SuppressedReason.TODAY))
                        }
                    }
                }
            }
        }

        return alerts
    }

    private fun parseDate(str: String): LocalDate? {
        val formats = listOf(
            DateTimeFormatter.ISO_LOCAL_DATE,
            DateTimeFormatter.ofPattern("yyyy/MM/dd"),
            DateTimeFormatter.ofPattern("yyyy.MM.dd"),
        )
        for (fmt in formats) {
            try {
                return LocalDate.parse(str, fmt)
            } catch (_: Exception) {}
        }
        return null
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

    private fun formatBytes(bytes: Double): String {
        val units = listOf("B", "KB", "MB", "GB", "TB", "PB")
        var value = bytes.coerceAtLeast(0.0)
        var idx = 0
        while (value >= 1024 && idx < units.size - 1) {
            value /= 1024
            idx++
        }
        return if (idx == 0) {
            "${value.toInt()} ${units[idx]}"
        } else {
            String.format(Locale.US, "%.1f %s", value, units[idx])
        }
    }

    private fun Double.formatOneDecimal(): String =
        String.format(Locale.US, "%.1f", this)

    private fun JSONObject.optDoubleOrNull(key: String): Double? =
        if (has(key) && !isNull(key)) {
            val v = opt(key)
            when (v) {
                is Number -> v.toDouble()
                is String -> v.toDoubleOrNull()
                else -> null
            }
        } else null
}
