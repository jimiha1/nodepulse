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
import java.util.Locale
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/**
 * Fetches CF-Server-Monitor endpoints directly for home widgets.
 *
 * Calls:
 * - GET {siteUrl}/api/servers (find server matching server.id)
 * - GET {siteUrl}/api/history/all?id={id}&hours=24 (for 4x2 chart history)
 */
object WidgetApi {
    class InsecureException : IOException("HTTPS required")

    class MissingSiteUrlException : IOException("No site URL configured")

    class MissingTokenException : IOException("No credential")

    class RejectedTokenException : IOException("Credential rejected")

    /** One reading, reduced to what a widget shows. */
    data class Reading(
        val name: String,
        val cpu: Double?,
        val mem: Double?,
        val disk: Double?,
        val memText: String,
        val diskText: String,
        val netText: String,
    )

    /** One bucket of history, oldest first. */
    data class HistoryPoint(
        val cpu: Double,
        val memory: Double,
        val disk: Double,
        val netRx: Double,
        val netTx: Double,
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

        return Reading(
            name = o.optString("name").ifEmpty { server.name },
            cpu = cpu,
            mem = memPercent,
            disk = diskPercent,
            memText = "${formatBytes(ramUsedBytes)} / ${formatBytes(ramTotalBytes)}",
            diskText = "${formatBytes(diskUsedBytes)} / ${formatBytes(diskTotalBytes)}",
            netText = "${formatBytes(netInSpeed)}/s / ${formatBytes(netOutSpeed)}/s",
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

            HistoryPoint(
                cpu = o.optDouble("cpu", 0.0),
                memory = memPercent,
                disk = diskPercent,
                netRx = o.optDouble("net_in_speed", 0.0),
                netTx = o.optDouble("net_out_speed", 0.0),
            )
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
