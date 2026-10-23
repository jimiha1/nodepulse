package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The reading a widget keeps so a failed refresh can leave it on screen.
 *
 * Worth pinning down because the whole point is that the numbers and the time
 * beside them stay consistent: a snapshot that comes back subtly wrong would
 * show a plausible-looking but incorrect reading, which is worse than the
 * loading state it replaces.
 */
class WidgetSnapshotTest {

    private val store = mutableMapOf<String, String>()
    private val prefs = memoryPrefs(store)

    private fun reading(
        name: String = "Osaka",
        cpu: Double? = 6.5,
        lastUpdated: Long? = 1_791_091_038_256L,
    ) = WidgetApi.Reading(
        name = name,
        cpu = cpu,
        mem = 42.0,
        disk = 56.0,
        memText = "1.2g / 3.0g",
        diskText = "56g / 100g",
        netText = "↑1.2m/s ↓3.4m/s",
        loadText = "0.04 0.05 0.06",
        netTotalText = "12g / 34g",
        trafficLeftText = "4.2g / 9.8t",
        connText = "T:27 U:7",
        pingText = "165/78/310ms",
        lossText = "0/0/0%",
        uptimeText = "3d 4h",
        expireText = "2027-10-08",
        load1 = 0.04,
        diskIoText = "--",
        procText = "203",
        avgLoss = 0.0,
        lastUpdated = lastUpdated,
    )

    @Test
    fun roundTripsAReadingExactly() {
        val original = reading()
        WidgetSnapshot.saveToPrefs(prefs, 4999, WidgetSnapshot.Shown("srv-1", original, emptyList()))

        val loaded = WidgetSnapshot.loadFromPrefs(prefs, 4999, "srv-1")
        assertNotNull(loaded)
        assertEquals(original, loaded!!.reading)
    }

    @Test
    fun nullsSurviveTheRoundTrip() {
        // A node that never reported has no timestamp and no CPU, and that has
        // to come back as absent rather than as a zero the widget would draw.
        val original = reading(cpu = null, lastUpdated = null)
        WidgetSnapshot.saveToPrefs(prefs, 7, WidgetSnapshot.Shown("srv-1", original, emptyList()))

        val loaded = WidgetSnapshot.loadFromPrefs(prefs, 7, "srv-1")!!.reading
        assertNull(loaded.cpu)
        assertNull(loaded.lastUpdated)
        assertEquals(original, loaded)
    }

    @Test
    fun roundTripsHistory() {
        val points = listOf(
            WidgetApi.HistoryPoint(cpu = 1.5, memory = 42.0, disk = 56.0, netRx = 100.0, netTx = 200.0),
            WidgetApi.HistoryPoint(
                cpu = 2.25, memory = 43.5, disk = 56.5, netRx = 0.0, netTx = 0.0,
                load = 0.5, io = 12.0, conn = 34.0, proc = 203.0, loss = 1.0,
            ),
        )
        WidgetSnapshot.saveToPrefs(prefs, 8, WidgetSnapshot.Shown("srv-1", reading(), points))

        val loaded = WidgetSnapshot.loadFromPrefs(prefs, 8, "srv-1")!!.history
        assertEquals(2, loaded.size)
        assertEquals(points, loaded)
    }

    @Test
    fun historySurvivesAnEmptyAndACorruptPayload() {
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), WidgetSnapshot.historyFrom(null))
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), WidgetSnapshot.historyFrom(""))
        // A group that is not ten numbers is dropped rather than read as zeroes.
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), WidgetSnapshot.historyFrom("1,2,3"))
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), WidgetSnapshot.historyFrom("a,b,c,d,e,f,g,h,i,j"))
    }

    @Test
    fun aSnapshotBelongingToAnotherServerIsNotUsed() {
        // Repointing a widget at a different node must not keep the old node's
        // numbers on screen, which would read as the new node's.
        WidgetSnapshot.saveToPrefs(prefs, 9, WidgetSnapshot.Shown("srv-1", reading(), emptyList()))
        assertNull(WidgetSnapshot.loadFromPrefs(prefs, 9, "srv-2"))
        assertNotNull(WidgetSnapshot.loadFromPrefs(prefs, 9, "srv-1"))
    }

    @Test
    fun anUnreadableSnapshotIsIgnored() {
        store["widget_10_server"] = "srv-1"
        store["widget_10_reading"] = "{not json"
        assertNull(WidgetSnapshot.loadFromPrefs(prefs, 10, "srv-1"))
    }

    @Test
    fun forgettingClearsEverything() {
        WidgetSnapshot.saveToPrefs(prefs, 11, WidgetSnapshot.Shown("srv-1", reading(), emptyList()))
        WidgetSnapshot.forgetFromPrefs(prefs, 11)
        assertNull(WidgetSnapshot.loadFromPrefs(prefs, 11, "srv-1"))
        assertTrue(store.keys.none { it.startsWith("widget_11_") })
    }

    @Test
    fun snapshotsAreTrackedPerWidget() {
        WidgetSnapshot.saveToPrefs(prefs, 12, WidgetSnapshot.Shown("srv-1", reading(name = "A"), emptyList()))
        WidgetSnapshot.saveToPrefs(prefs, 13, WidgetSnapshot.Shown("srv-2", reading(name = "B"), emptyList()))

        assertEquals("A", WidgetSnapshot.loadFromPrefs(prefs, 12, "srv-1")!!.reading.name)
        assertEquals("B", WidgetSnapshot.loadFromPrefs(prefs, 13, "srv-2")!!.reading.name)
    }

    @Test
    fun historyRoundTripsThePingColumns() {
        val points = listOf(
            WidgetApi.HistoryPoint(
                cpu = 1.0, memory = 2.0, disk = 3.0, netRx = 4.0, netTx = 5.0,
                pingCt = 10.0, pingCu = null, pingCm = 30.0,
            ),
        )
        val back = WidgetSnapshot.historyFrom(WidgetSnapshot.historyTo(points)).single()
        assertEquals(10.0, back.pingCt!!, 0.001)
        assertNull(back.pingCu)
        assertEquals(30.0, back.pingCm!!, 0.001)
    }

    @Test
    fun historyRoundTripsThePerCarrierLoss() {
        val points = listOf(
            WidgetApi.HistoryPoint(
                cpu = 1.0, memory = 2.0, disk = 3.0, netRx = 4.0, netTx = 5.0,
                lossCt = 0.2, lossCu = null, lossCm = 1.5,
            ),
        )
        val back = WidgetSnapshot.historyFrom(WidgetSnapshot.historyTo(points)).single()
        assertEquals(0.2, back.lossCt!!, 0.001)
        assertNull(back.lossCu)
        assertEquals(1.5, back.lossCm!!, 0.001)
    }

    @Test
    fun theTallRowsRawBytesSurviveTheRoundTrip() {
        // The memory and disk rows put both numbers under one shared unit, so
        // they need the raw byte pair rather than the pre-formatted string —
        // and a snapshot that lost it would make those rows read `--` after
        // every failed refresh.
        val original = reading().copy(
            cpuCores = 2,
            region = "HK",
            ramUsedBytes = 232.65 * 1048576,
            ramTotalBytes = 431.0 * 1048576,
            diskUsedBytes = 412.0 * 1048576,
            diskTotalBytes = 1021.0 * 1048576,
            netIn = 14.11 * 1024,
            netOut = 13.19 * 1024,
            netRxMonthly = 317.0 * 1048576,
            netTxMonthly = 313.7 * 1048576,
            load5 = 0.10,
            load15 = 0.05,
            pingCt = 10.0,
            pingCu = 7.0,
            pingCm = 16.0,
            lossCt = 0.0,
            lossCu = 0.2,
            lossCm = 0.0,
        )
        WidgetSnapshot.saveToPrefs(prefs, 11, WidgetSnapshot.Shown("srv-1", original, emptyList()))

        val loaded = WidgetSnapshot.loadFromPrefs(prefs, 11, "srv-1")!!.reading
        assertEquals(original, loaded)
        assertEquals(2, loaded.cpuCores)
        assertEquals(232.65 * 1048576, loaded.ramUsedBytes, 1.0)
    }

    @Test
    fun aTenFieldSnapshotStillLoads() {
        // What the previous release wrote: ten numbers, no ping or loss columns.
        val legacy = "1.00,2.00,3.00,4.00,5.00,6.00,7.00,8.00,9.00,0.00"
        val back = WidgetSnapshot.historyFrom(legacy).single()
        assertEquals(1.0, back.cpu, 0.001)
        assertNull(back.pingCt)
        assertNull(back.pingCu)
        assertNull(back.pingCm)
        assertNull(back.lossCt)
        assertNull(back.lossCu)
        assertNull(back.lossCm)
        // No timestamp either: the mean falls back to the live reading rather
        // than pretending an undated row belongs to this half hour.
        assertEquals(0L, back.timestamp)
    }

    @Test
    fun historyRoundTripsTheTimestamp() {
        val points = listOf(
            WidgetApi.HistoryPoint(
                cpu = 1.0, memory = 2.0, disk = 3.0, netRx = 4.0, netTx = 5.0,
                pingCt = 10.0, pingCu = 11.0, pingCm = 12.0,
                timestamp = 1_790_927_096_022L,
            ),
        )
        val back = WidgetSnapshot.historyFrom(WidgetSnapshot.historyTo(points)).single()
        assertEquals(1_790_927_096_022L, back.timestamp)
    }

    @Test
    fun aSixteenFieldSnapshotFromTheLastReleaseStillLoads() {
        // Ten numbers plus the six ping/loss columns, no timestamp: the release
        // right before this one. It must keep its rows, with the timestamp
        // defaulted rather than shifting the loss columns into its place.
        val previous = "1.00,2.00,3.00,4.00,5.00,6.00,7.00,8.00,9.00,0.00," +
            "10.00,-,30.00,0.00,0.20,0.00"
        val back = WidgetSnapshot.historyFrom(previous).single()
        assertEquals(10.0, back.pingCt!!, 0.001)
        assertNull(back.pingCu)
        assertEquals(30.0, back.pingCm!!, 0.001)
        assertEquals(0.2, back.lossCu!!, 0.001)
        assertEquals(0L, back.timestamp)
    }
}
