package app.nodepulse.widget

import android.content.SharedPreferences
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy

class WidgetConfigTest {

    private lateinit var mockPrefs: SharedPreferences
    private val memoryStore = mutableMapOf<String, String>()

    @Before
    fun setUp() {
        memoryStore.clear()

        val editorHandler = object : InvocationHandler {
            override fun invoke(proxy: Any?, method: Method, args: Array<out Any>?): Any? {
                when (method.name) {
                    "putInt" -> {
                        val key = args?.get(0) as String
                        val value = args?.get(1) as Int
                        memoryStore[key] = value.toString()
                        return proxy
                    }
                    "putString" -> {
                        val key = args?.get(0) as String
                        val value = args?.get(1) as String
                        memoryStore[key] = value
                        return proxy
                    }
                    "remove" -> {
                        val key = args?.get(0) as String
                        memoryStore.remove(key)
                        return proxy
                    }
                    "apply", "commit" -> return Unit
                }
                return null
            }
        }
        val mockEditor = Proxy.newProxyInstance(
            SharedPreferences.Editor::class.java.classLoader,
            arrayOf(SharedPreferences.Editor::class.java),
            editorHandler,
        ) as SharedPreferences.Editor

        val prefsHandler = object : InvocationHandler {
            override fun invoke(proxy: Any?, method: Method, args: Array<out Any>?): Any? {
                when (method.name) {
                    "edit" -> return mockEditor
                    "getInt" -> {
                        val key = args?.get(0) as String
                        val defVal = args?.get(1) as? Int ?: 0
                        return memoryStore[key]?.toIntOrNull() ?: defVal
                    }
                    "getString" -> {
                        val key = args?.get(0) as String
                        val defVal = args?.get(1) as? String
                        return memoryStore[key] ?: defVal
                    }
                }
                return null
            }
        }
        mockPrefs = Proxy.newProxyInstance(
            SharedPreferences::class.java.classLoader,
            arrayOf(SharedPreferences::class.java),
            prefsHandler,
        ) as SharedPreferences
    }

    @Test
    fun roundTripSmallConfig() {
        val appWidgetId = 42
        val config = WidgetConfig(
            serverId = "srv-1",
            kind = WidgetKind.TALL,
            expiry = WidgetExpiry.H1,
        )

        WidgetConfig.saveToPrefs(mockPrefs, appWidgetId, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.TALL)

        assertEquals("srv-1", loaded.serverId)
        assertEquals(WidgetKind.TALL, loaded.kind)
        assertEquals(WidgetExpiry.H1, loaded.expiry)
    }

    @Test
    fun aTallWidgetKeepsNoFieldList() {
        val config = WidgetConfig(
            serverId = "srv-1",
            kind = WidgetKind.TALL,
            fields = listOf(WidgetField.CPU, WidgetField.MEM),
            expiry = WidgetExpiry.H1,
        )
        WidgetConfig.saveToPrefs(mockPrefs, 77, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, 77, WidgetKind.TALL)
        assertEquals(WidgetKind.TALL, loaded.kind)
        assertTrue(loaded.fields.isEmpty())
        assertEquals(WidgetExpiry.H1, loaded.expiry)
        // The rows are fixed, so nothing about them belongs in preferences.
        assertNull(memoryStore["widget_77_fields"])
    }

    @Test
    fun aMediumReadingStillGetsTheDefaultFields() {
        // Reading mode is the one 4x2 mode that shows a field list, so it is
        // the one that has to keep falling back to the defaults.
        memoryStore["widget_78_mode"] = "reading"
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, 78, WidgetKind.MEDIUM)
        assertEquals(WidgetConfig.DEFAULT_READING_FIELDS, loaded.fields)
    }

    @Test
    fun roundTripMediumChartConfig() {
        val appWidgetId = 43
        val config = WidgetConfig(
            serverId = "srv-2",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.CHART,
            chartCount = 4,
            chart = "net",
            chart2 = "cpu",
            chart3 = "mem",
            chart4 = "disk",
        )

        WidgetConfig.saveToPrefs(mockPrefs, appWidgetId, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM)

        assertEquals("srv-2", loaded.serverId)
        assertEquals(WidgetKind.MEDIUM, loaded.kind)
        assertEquals(MediumMode.CHART, loaded.mode)
        assertEquals(4, loaded.chartCount)
        assertEquals("net", loaded.chart)
        assertEquals("cpu", loaded.chart2)
        assertEquals("mem", loaded.chart3)
        assertEquals("disk", loaded.chart4)
    }

    @Test
    fun aLatencyChartSelectionSurvivesTheRoundTrip() {
        val config = WidgetConfig(
            serverId = "srv-ping",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.CHART,
            chartCount = 2,
            chart = "ping",
            chart2 = "cpu",
        )
        WidgetConfig.saveToPrefs(mockPrefs, 46, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, 46, WidgetKind.MEDIUM)
        assertEquals("ping", loaded.chart)
        assertEquals("cpu", loaded.chart2)
    }

    @Test
    fun roundTripMediumReadingConfig() {
        val appWidgetId = 44
        val config = WidgetConfig(
            serverId = "srv-3",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.READING,
            fields = listOf(
                WidgetField.CPU,
                WidgetField.MEM,
                WidgetField.DISK,
                WidgetField.NET_SPEED,
                WidgetField.CONN,
                WidgetField.UPTIME,
                WidgetField.EXPIRE,
                WidgetField.PING,
            ),
        )

        WidgetConfig.saveToPrefs(mockPrefs, appWidgetId, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM)

        assertEquals("srv-3", loaded.serverId)
        assertEquals(MediumMode.READING, loaded.mode)
        assertEquals(
            listOf(
                WidgetField.CPU,
                WidgetField.MEM,
                WidgetField.DISK,
                WidgetField.NET_SPEED,
                WidgetField.CONN,
                WidgetField.UPTIME,
                WidgetField.EXPIRE,
                WidgetField.PING,
            ),
            loaded.fields,
        )
    }

    @Test
    fun roundTripMediumCombinedConfig() {
        val appWidgetId = 45
        val config = WidgetConfig(
            serverId = "srv-4",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.COMBINED,
            chart = "cpu",
            chart2 = "mem",
            fields = listOf(WidgetField.DISK, WidgetField.NET_SPEED, WidgetField.PING, WidgetField.CONN),
        )

        WidgetConfig.saveToPrefs(mockPrefs, appWidgetId, config)
        val loaded = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM)

        assertEquals("srv-4", loaded.serverId)
        assertEquals(MediumMode.COMBINED, loaded.mode)
        assertEquals("cpu", loaded.chart)
        assertEquals("mem", loaded.chart2)
        assertEquals(
            listOf(WidgetField.DISK, WidgetField.NET_SPEED, WidgetField.PING, WidgetField.CONN),
            loaded.fields,
        )
    }

    @Test
    fun fieldSelectionTruncationAtCaps() {
        // Medium reading max is 8 fields
        val appWidgetIdMedReading = 47
        val configReading = WidgetConfig(
            serverId = "srv-reading",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.READING,
            fields = listOf(
                WidgetField.CPU,
                WidgetField.MEM,
                WidgetField.DISK,
                WidgetField.NET_SPEED,
                WidgetField.CONN,
                WidgetField.UPTIME,
                WidgetField.EXPIRE,
                WidgetField.PING,
                WidgetField.LOAD,
            ),
        )
        WidgetConfig.saveToPrefs(mockPrefs, appWidgetIdMedReading, configReading)
        val loadedReading = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetIdMedReading, WidgetKind.MEDIUM)
        assertEquals(8, loadedReading.fields.size)

        // Medium combined max is 4 fields
        val appWidgetIdCombined = 48
        val configCombined = WidgetConfig(
            serverId = "srv-comb",
            kind = WidgetKind.MEDIUM,
            mode = MediumMode.COMBINED,
            chart = "cpu",
            chart2 = "mem",
            fields = listOf(
                WidgetField.CPU,
                WidgetField.MEM,
                WidgetField.DISK,
                WidgetField.NET_SPEED,
                WidgetField.PING,
            ),
        )
        WidgetConfig.saveToPrefs(mockPrefs, appWidgetIdCombined, configCombined)
        val loadedCombined = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetIdCombined, WidgetKind.MEDIUM)
        assertEquals(4, loadedCombined.fields.size)
        assertEquals(
            listOf(WidgetField.CPU, WidgetField.MEM, WidgetField.DISK, WidgetField.NET_SPEED),
            loadedCombined.fields,
        )
    }

    @Test
    fun roundTripExpiryPresets() {
        for ((i, expiry) in WidgetExpiry.entries.withIndex()) {
            val appWidgetId = 60 + i
            WidgetConfig.saveToPrefs(
                mockPrefs,
                appWidgetId,
                WidgetConfig(serverId = "srv-exp", kind = WidgetKind.MEDIUM, expiry = expiry),
            )
            val loaded = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM)
            assertEquals(expiry, loaded.expiry)
        }
    }

    @Test
    fun expiryDefaultsToM30AndSurvivesForget() {
        val appWidgetId = 70
        val empty = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM)
        assertEquals(WidgetExpiry.M30, empty.expiry)

        WidgetConfig.saveToPrefs(
            mockPrefs,
            appWidgetId,
            WidgetConfig(serverId = "srv-exp", kind = WidgetKind.MEDIUM, expiry = WidgetExpiry.H2),
        )
        assertEquals(WidgetExpiry.H2, WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM).expiry)

        WidgetConfig.forgetFromPrefs(mockPrefs, appWidgetId)
        assertEquals(WidgetExpiry.M30, WidgetConfig.loadFromPrefs(mockPrefs, appWidgetId, WidgetKind.MEDIUM).expiry)
    }

    @Test
    fun fallbackToDefaultsWhenEmptyOrCorrupted() {
        val appWidgetIdTall = 49
        // Nothing stored
        val emptyTall = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetIdTall, WidgetKind.TALL)
        assertEquals("", emptyTall.serverId)
        assertTrue(emptyTall.fields.isEmpty())

        val appWidgetIdMed = 50
        val emptyMed = WidgetConfig.loadFromPrefs(mockPrefs, appWidgetIdMed, WidgetKind.MEDIUM)
        assertEquals("", emptyMed.serverId)
        assertEquals(MediumMode.CHART, emptyMed.mode)
        assertEquals("net", emptyMed.chart)

        // Corrupted prefs with unknown field keys and unknown mode
        memoryStore["widget_51_server"] = "srv-corrupt"
        memoryStore["widget_51_mode"] = "reading"
        memoryStore["widget_51_fields"] = "unknown_foo,cpu,invalid_bar,mem"
        memoryStore["widget_51_chart"] = "invalid_chart"
        val corruptedMed = WidgetConfig.loadFromPrefs(mockPrefs, 51, WidgetKind.MEDIUM)
        assertEquals(MediumMode.READING, corruptedMed.mode)
        // unknown keys ignored, valid keys kept
        assertEquals(listOf(WidgetField.CPU, WidgetField.MEM), corruptedMed.fields)
    }
}
