package tech.lolli.toolbox.widget

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject
import java.util.Locale

/**
 * The last reading a widget put on screen, kept so a refresh that fails can
 * leave it there.
 *
 * The widget's own view tree already holds the numbers, but the time beside
 * them has to be redrawn on every attempt — its colour is what says how old
 * the reading is — and a redraw needs the reading it belongs to. Keeping the
 * whole reading, history included, also means a held widget survives the
 * launcher rebuilding its view tree, which a header-only redraw would not.
 *
 * In preferences rather than in memory: the app process is killed between
 * updates on this platform, and the widget outlives it.
 */
object WidgetSnapshot {
    private const val TAG = "WidgetSnapshot"

    private const val PREFS = "sbm_widget_shown"
    private const val KEY_SERVER = "server"
    private const val KEY_READING = "reading"
    private const val KEY_HISTORY = "history"

    data class Shown(
        val serverId: String,
        val reading: WidgetApi.Reading,
        val history: List<WidgetApi.HistoryPoint>,
    )

    /**
     * What this widget last showed, or null when it has never shown anything —
     * or when what it showed belongs to another server, which happens when a
     * widget is repointed and must not keep the old server's numbers up.
     */
    fun load(context: Context, appWidgetId: Int, serverId: String): Shown? =
        loadFromPrefs(
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE),
            appWidgetId,
            serverId,
        )

    fun loadFromPrefs(
        prefs: SharedPreferences,
        appWidgetId: Int,
        serverId: String,
    ): Shown? {
        if (prefs.getString(key(appWidgetId, KEY_SERVER), null) != serverId) return null
        val raw = prefs.getString(key(appWidgetId, KEY_READING), null) ?: return null
        return try {
            Shown(
                serverId = serverId,
                reading = readingFrom(JSONObject(raw)),
                history = historyFrom(prefs.getString(key(appWidgetId, KEY_HISTORY), null)),
            )
        } catch (e: Exception) {
            // A snapshot that cannot be read is worth no more than none: the
            // widget falls back to the loading state, and the next successful
            // fetch writes a fresh one.
            Log.w(TAG, "Dropping an unreadable widget snapshot: ${e.message}")
            null
        }
    }

    fun save(context: Context, appWidgetId: Int, shown: Shown) =
        saveToPrefs(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE), appWidgetId, shown)

    fun saveToPrefs(prefs: SharedPreferences, appWidgetId: Int, shown: Shown) {
        prefs.edit()
            .putString(key(appWidgetId, KEY_SERVER), shown.serverId)
            .putString(key(appWidgetId, KEY_READING), readingTo(shown.reading).toString())
            .putString(key(appWidgetId, KEY_HISTORY), historyTo(shown.history))
            .apply()
    }

    fun forget(context: Context, appWidgetId: Int) =
        forgetFromPrefs(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE), appWidgetId)

    fun forgetFromPrefs(prefs: SharedPreferences, appWidgetId: Int) {
        prefs.edit()
            .remove(key(appWidgetId, KEY_SERVER))
            .remove(key(appWidgetId, KEY_READING))
            .remove(key(appWidgetId, KEY_HISTORY))
            .apply()
    }

    private fun key(id: Int, field: String) = "widget_${id}_$field"

    // MARK: - Reading

    private fun readingTo(r: WidgetApi.Reading): JSONObject = JSONObject()
        .put("name", r.name)
        .put("cpu", r.cpu.json())
        .put("mem", r.mem.json())
        .put("disk", r.disk.json())
        .put("memText", r.memText)
        .put("diskText", r.diskText)
        .put("netText", r.netText)
        .put("loadText", r.loadText)
        .put("netTotalText", r.netTotalText)
        .put("trafficLeftText", r.trafficLeftText)
        .put("connText", r.connText)
        .put("pingText", r.pingText)
        .put("lossText", r.lossText)
        .put("uptimeText", r.uptimeText)
        .put("expireText", r.expireText)
        .put("load1", r.load1)
        .put("diskIoText", r.diskIoText)
        .put("procText", r.procText)
        .put("avgLoss", r.avgLoss.json())
        .put("lastUpdated", r.lastUpdated.json())

    private fun readingFrom(o: JSONObject): WidgetApi.Reading = WidgetApi.Reading(
        name = o.optString("name"),
        cpu = o.doubleOrNull("cpu"),
        mem = o.doubleOrNull("mem"),
        disk = o.doubleOrNull("disk"),
        memText = o.optString("memText"),
        diskText = o.optString("diskText"),
        netText = o.optString("netText"),
        loadText = o.optString("loadText"),
        netTotalText = o.optString("netTotalText"),
        trafficLeftText = o.optString("trafficLeftText"),
        connText = o.optString("connText"),
        pingText = o.optString("pingText"),
        lossText = o.optString("lossText"),
        uptimeText = o.optString("uptimeText"),
        expireText = o.optString("expireText"),
        load1 = o.optDouble("load1", 0.0),
        diskIoText = o.optString("diskIoText"),
        procText = o.optString("procText"),
        avgLoss = o.doubleOrNull("avgLoss"),
        lastUpdated = o.longOrNull("lastUpdated"),
    )

    private fun Double?.json(): Any = this ?: JSONObject.NULL

    private fun Long?.json(): Any = this ?: JSONObject.NULL

    private fun JSONObject.doubleOrNull(key: String): Double? =
        if (!has(key) || isNull(key)) null else optDouble(key)

    private fun JSONObject.longOrNull(key: String): Long? =
        if (!has(key) || isNull(key)) null else optLong(key)

    // MARK: - History

    private const val POINT_SEP = ";"
    private const val FIELD_SEP = ","

    /**
     * The chart history as text: one point per `;`-separated group, its ten
     * numbers `,`-separated to two decimals.
     *
     * Two decimals is all a chart can show, and it keeps a full day of history
     * — 120 points — near five kilobytes, which is a reasonable thing to hold
     * in preferences beside the reading itself.
     */
    fun historyTo(points: List<WidgetApi.HistoryPoint>): String =
        points.joinToString(POINT_SEP) { p ->
            listOf(p.cpu, p.memory, p.disk, p.netRx, p.netTx, p.load, p.io, p.conn, p.proc, p.loss)
                .joinToString(FIELD_SEP) { String.format(Locale.US, "%.2f", it) }
        }

    fun historyFrom(raw: String?): List<WidgetApi.HistoryPoint> {
        if (raw.isNullOrEmpty()) return emptyList()
        return raw.split(POINT_SEP).mapNotNull { group ->
            val fields = group.split(FIELD_SEP).map { it.toDoubleOrNull() }
            if (fields.size < 10 || fields.any { it == null }) return@mapNotNull null
            WidgetApi.HistoryPoint(
                cpu = fields[0]!!,
                memory = fields[1]!!,
                disk = fields[2]!!,
                netRx = fields[3]!!,
                netTx = fields[4]!!,
                load = fields[5]!!,
                io = fields[6]!!,
                conn = fields[7]!!,
                proc = fields[8]!!,
                loss = fields[9]!!,
            )
        }
    }
}
