package tech.lolli.toolbox.widget

import android.content.Context
import android.content.SharedPreferences

/**
 * Field available for display in a widget reading row.
 * [key] matches SharedPreferences persistence.
 */
enum class WidgetField(val key: String) {
    CPU("cpu"),
    MEM("mem"),
    DISK("disk"),
    LOAD("load"),
    NET_SPEED("net"),
    NET_TOTAL("total"),
    TRAFFIC_LEFT("quota"),
    CONN("conn"),
    PING("ping"),
    LOSS("loss"),
    UPTIME("uptime"),
    EXPIRE("expire");

    companion object {
        fun fromKey(key: String): WidgetField? = entries.firstOrNull { it.key == key }
    }
}

/**
 * Display mode for a 4x2 MEDIUM widget.
 */
enum class MediumMode(val key: String) {
    CHART("chart"),
    READING("reading"),
    COMBINED("combined");

    companion object {
        fun fromKey(key: String?): MediumMode =
            entries.firstOrNull { it.key == key } ?: CHART
    }
}

/**
 * How old the widget's data may get before the header time starts warning.
 *
 * The ladder is anchored to Android's floor on `updatePeriodMillis`: the
 * periodic update cannot arrive more often than every 30 minutes, so a
 * shorter threshold would leave an otherwise healthy widget in warning until
 * the user refreshed it by hand.
 */
enum class WidgetExpiry(val minutes: Int, val key: String) {
    M10(10, "10m"),
    M30(30, "30m"),
    H1(60, "1h"),
    H2(120, "2h"),

    /** Never warn: the time keeps the plain summary colour. */
    NEVER(0, "never");

    companion object {
        val DEFAULT = M30

        fun fromKey(key: String?): WidgetExpiry =
            entries.firstOrNull { it.key == key } ?: DEFAULT
    }
}

/**
 * What one placed widget was configured to show.
 *
 * Keyed by `appWidgetId`, which is the system's identity for a widget instance
 * and survives a reboot but not a removal — so a widget dragged off the home
 * screen and back is a new one with nothing to inherit, which is correct.
 */
data class WidgetConfig(
    /** [WidgetStore.WidgetServer.id], or empty when nothing is picked yet. */
    val serverId: String,
    val metric: WidgetMetric = WidgetMetric.CPU,
    val kind: WidgetKind = WidgetKind.SMALL,
    val mode: MediumMode = MediumMode.CHART,
    val fields: List<WidgetField> = emptyList(),
    val chartCount: Int = 1,
    val chart: String = DEFAULT_CHART,
    val chart2: String = DEFAULT_CHART2,
    val chart3: String = DEFAULT_CHART3,
    val chart4: String = DEFAULT_CHART4,
    val expiry: WidgetExpiry = WidgetExpiry.DEFAULT,
) {
    companion object {
        private const val PREFS = "sbm_widget_config"

        const val CAP_SMALL_FIELDS = 4
        const val CAP_MEDIUM_READING_FIELDS = 8
        const val CAP_COMBINED_FIELDS = 4

        const val DEFAULT_CHART = "net"
        const val DEFAULT_CHART2 = "cpu"
        const val DEFAULT_CHART3 = "mem"
        const val DEFAULT_CHART4 = "disk"

        val DEFAULT_SMALL_FIELDS = listOf(
            WidgetField.CPU,
            WidgetField.MEM,
            WidgetField.DISK,
            WidgetField.NET_SPEED,
        )

        fun load(context: Context, appWidgetId: Int, kind: WidgetKind = WidgetKind.SMALL): WidgetConfig {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return loadFromPrefs(prefs, appWidgetId, kind)
        }

        fun loadFromPrefs(prefs: SharedPreferences, appWidgetId: Int, kind: WidgetKind = WidgetKind.SMALL): WidgetConfig {
            val serverId = prefs.getString(key(appWidgetId, "server"), "") ?: ""
            val metric = WidgetMetric.from(prefs.getString(key(appWidgetId, "metric"), null))

            val mode = MediumMode.fromKey(prefs.getString(key(appWidgetId, "mode"), null))
            val chartCount = prefs.getInt(key(appWidgetId, "chart_count"), 1)
            val chart = prefs.getString(key(appWidgetId, "chart"), null) ?: DEFAULT_CHART
            val chart2 = prefs.getString(key(appWidgetId, "chart2"), null) ?: DEFAULT_CHART2
            val chart3 = prefs.getString(key(appWidgetId, "chart3"), null) ?: DEFAULT_CHART3
            val chart4 = prefs.getString(key(appWidgetId, "chart4"), null) ?: DEFAULT_CHART4
            val expiry = WidgetExpiry.fromKey(prefs.getString(key(appWidgetId, "expiry"), null))

            val rawFields = prefs.getString(key(appWidgetId, "fields"), null)
            val cap = when {
                kind == WidgetKind.SMALL -> CAP_SMALL_FIELDS
                mode == MediumMode.READING -> CAP_MEDIUM_READING_FIELDS
                mode == MediumMode.COMBINED -> CAP_COMBINED_FIELDS
                else -> 0
            }

            val fields = if (rawFields != null) {
                rawFields.split(",")
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }
                    .mapNotNull { WidgetField.fromKey(it) }
                    .take(cap)
            } else {
                if (kind == WidgetKind.SMALL) {
                    DEFAULT_SMALL_FIELDS.take(CAP_SMALL_FIELDS)
                } else if (mode == MediumMode.READING) {
                    DEFAULT_SMALL_FIELDS.take(CAP_MEDIUM_READING_FIELDS)
                } else {
                    emptyList()
                }
            }

            return WidgetConfig(
                serverId = serverId,
                metric = metric,
                kind = kind,
                mode = mode,
                fields = fields,
                chartCount = chartCount,
                chart = chart,
                chart2 = chart2,
                chart3 = chart3,
                chart4 = chart4,
                expiry = expiry,
            )
        }

        fun save(context: Context, appWidgetId: Int, config: WidgetConfig) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            saveToPrefs(prefs, appWidgetId, config)
        }

        fun saveToPrefs(prefs: SharedPreferences, appWidgetId: Int, config: WidgetConfig) {
            val cap = when {
                config.kind == WidgetKind.SMALL -> CAP_SMALL_FIELDS
                config.mode == MediumMode.READING -> CAP_MEDIUM_READING_FIELDS
                config.mode == MediumMode.COMBINED -> CAP_COMBINED_FIELDS
                else -> 0
            }
            val fieldKeys = config.fields.take(cap).joinToString(",") { it.key }

            prefs.edit()
                .putString(key(appWidgetId, "server"), config.serverId)
                .putString(key(appWidgetId, "metric"), config.metric.name)
                .putString(key(appWidgetId, "mode"), config.mode.key)
                .putString(key(appWidgetId, "fields"), fieldKeys)
                .putInt(key(appWidgetId, "chart_count"), config.chartCount)
                .putString(key(appWidgetId, "chart"), config.chart)
                .putString(key(appWidgetId, "chart2"), config.chart2)
                .putString(key(appWidgetId, "chart3"), config.chart3)
                .putString(key(appWidgetId, "chart4"), config.chart4)
                .putString(key(appWidgetId, "expiry"), config.expiry.key)
                .apply()
        }

        fun forget(context: Context, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            forgetFromPrefs(prefs, appWidgetId)
        }

        fun forgetFromPrefs(prefs: SharedPreferences, appWidgetId: Int) {
            prefs.edit()
                .remove(key(appWidgetId, "server"))
                .remove(key(appWidgetId, "metric"))
                .remove(key(appWidgetId, "mode"))
                .remove(key(appWidgetId, "fields"))
                .remove(key(appWidgetId, "chart_count"))
                .remove(key(appWidgetId, "chart"))
                .remove(key(appWidgetId, "chart2"))
                .remove(key(appWidgetId, "chart3"))
                .remove(key(appWidgetId, "chart4"))
                .remove(key(appWidgetId, "expiry"))
                .apply()
        }

        private fun key(id: Int, field: String) = "widget_${id}_$field"
    }
}

/** One reading a widget can lead with. */
enum class WidgetMetric {
    CPU,
    MEMORY,
    DISK,
    NETWORK;

    companion object {
        fun from(name: String?): WidgetMetric =
            entries.firstOrNull { it.name == name } ?: CPU

        val rotation = listOf(CPU, MEMORY, DISK, NETWORK)
    }

    fun following(count: Int): List<WidgetMetric> {
        val start = rotation.indexOf(this).coerceAtLeast(0)
        return (0 until minOf(count, rotation.size)).map {
            rotation[(start + it) % rotation.size]
        }
    }
}

/**
 * Which of the two widgets this is.
 */
enum class WidgetKind {
    /** 2x2, readings as text. Custom up to 4 fields. */
    SMALL,

    /** 4x2, chart, reading or combined mode. */
    MEDIUM;

    val drawsCharts: Boolean get() = this == MEDIUM

    companion object {
        const val CHART_COUNT = 4
    }
}
