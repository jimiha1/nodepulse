package tech.lolli.toolbox.widget

import android.content.Context
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/**
 * Fetches CF-Server-Monitor endpoints directly for home widgets.
 */
object WidgetApi {
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
    )

    private const val TIMEOUT_MS = 8_000

    suspend fun load(
        context: Context,
        server: WidgetStore.WidgetServer,
    ): Pair<Reading, List<HistoryPoint>> = withContext(Dispatchers.IO) {
        val siteUrl = WidgetStore.siteUrl(context) ?: throw MissingSiteUrlException()
        val token = WidgetStore.token(context)
        val reading = try {
            val serversBody = get(siteUrl, "/api/servers", token)
            parseCfMetrics(server, serversBody)
        } catch (e: RejectedTokenException) {
            WidgetStore.setToken(context, null)
            throw e
        }

        // History failing is not fatal: e.g. history disabled or empty
        val history = try {
            val historyBody = get(siteUrl, "/api/history/all?id=${server.id}&hours=24", token)
            parseCfHistory(historyBody)
        } catch (_: Exception) {
            emptyList()
        }

        reading to history
    }

    private fun get(
        siteUrl: String,
        path: String,
        token: String?,
    ): String {
        val base = siteUrl.trimEnd('/')
        val url = URL(base + path)

        var connection: HttpURLConnection? = null
        try {
            connection = (url.openConnection() as HttpURLConnection).apply {
                if (this is HttpsURLConnection) {
                    sslSocketFactory = permissiveSslContext().socketFactory
                    hostnameVerifier = HostnameVerifier { _, _ -> true }
                }
                requestMethod = "GET"
                connectTimeout = TIMEOUT_MS
                readTimeout = TIMEOUT_MS
                if (!token.isNullOrEmpty()) {
                    setRequestProperty("Authorization", "Bearer $token")
                }
                setRequestProperty("Accept", "application/json")
                setRequestProperty("User-Agent", "ServerBox-Widget/2")
            }
            val code = connection.responseCode
            if (code == 401 || code == 403) throw RejectedTokenException()
            if (code !in 200..299) throw IOException("HTTP $code")
            return connection.inputStream.bufferedReader().use { it.readText() }
        } finally {
            connection?.disconnect()
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

        // Ping
        val pingCt = o.optDoubleOrNull("ping_ct")
        val pingCu = o.optDoubleOrNull("ping_cu")
        val pingCm = o.optDoubleOrNull("ping_cm")
        val pingText = if (pingCt != null || pingCu != null || pingCm != null) {
            val ct = pingCt?.let { "${it.toInt()}" } ?: "-"
            val cu = pingCu?.let { "${it.toInt()}" } ?: "-"
            val cm = pingCm?.let { "${it.toInt()}" } ?: "-"
            "电$ct 联$cu 移$cm"
        } else "--"

        // Loss
        val lossCt = o.optDoubleOrNull("loss_ct")
        val lossCu = o.optDoubleOrNull("loss_cu")
        val lossCm = o.optDoubleOrNull("loss_cm")
        val lossText = if (lossCt != null || lossCu != null || lossCm != null) {
            fun fmtLoss(v: Double?): String = v?.let { "${it.toInt()}%" } ?: "-"
            "电${fmtLoss(lossCt)} 联${fmtLoss(lossCu)} 移${fmtLoss(lossCm)}"
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

    private fun permissiveSslContext(): SSLContext {
        val trustEverything = object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<X509Certificate>?, authType: String?) = Unit
            override fun checkServerTrusted(chain: Array<X509Certificate>?, authType: String?) = Unit
            override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
        }
        return SSLContext.getInstance("TLS").apply {
            init(null, arrayOf<TrustManager>(trustEverything), java.security.SecureRandom())
        }
    }

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
            String.format(Locale.US, "%.1f%s", value, units[idx])
        }
    }

    fun displayHost(addr: String): String =
        runCatching { Uri.parse(addr).host ?: addr }.getOrDefault(addr)
}
