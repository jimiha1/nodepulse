package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetAverageTest {

    private val now = 1_800_000_000_000L
    private val minute = 60_000L

    private fun point(
        atMinutesAgo: Long,
        cpu: Double = 10.0,
        memory: Double = 20.0,
    ) = WidgetApi.HistoryPoint(
        cpu = cpu,
        memory = memory,
        disk = 0.0,
        netRx = 0.0,
        netTx = 0.0,
        timestamp = now - atMinutesAgo * minute,
    )

    @Test
    fun theMeanCoversOnlyTheLastHalfHour() {
        val points = listOf(
            point(atMinutesAgo = 50, cpu = 100.0, memory = 100.0),
            point(atMinutesAgo = 20, cpu = 10.0, memory = 30.0),
            point(atMinutesAgo = 10, cpu = 20.0, memory = 50.0),
            point(atMinutesAgo = 0, cpu = 30.0, memory = 70.0),
        )
        // The 50-minute-old row is outside the window and must not drag the
        // mean: 100 would turn 20 into 40.
        assertEquals(20.0, WidgetAverage.cpu(points, now)!!, 0.001)
        assertEquals(50.0, WidgetAverage.memory(points, now)!!, 0.001)
    }

    @Test
    fun theWindowBoundaryIsInclusive() {
        val points = listOf(
            point(atMinutesAgo = 30, cpu = 40.0),
            point(atMinutesAgo = 31, cpu = 100.0),
        )
        // Exactly thirty minutes old still counts; a minute more does not.
        assertEquals(40.0, WidgetAverage.cpu(points, now)!!, 0.001)
    }

    @Test
    fun aSnapshotWithoutTimestampsYieldsNoMean() {
        // Every row of an older snapshot reads back with timestamp 0. There is
        // no honest way to call any of them "the last half hour", so the
        // caller falls back to the instantaneous reading.
        val points = listOf(
            point(atMinutesAgo = 0).copy(timestamp = 0L),
            point(atMinutesAgo = 0).copy(timestamp = 0L),
        )
        assertNull(WidgetAverage.cpu(points, now))
        assertNull(WidgetAverage.memory(points, now))
    }

    @Test
    fun anUndatedRowIsDroppedEvenWhenOthersCarryTimes() {
        val points = listOf(
            point(atMinutesAgo = 10, cpu = 10.0),
            point(atMinutesAgo = 10, cpu = 90.0).copy(timestamp = 0L),
        )
        assertEquals(10.0, WidgetAverage.cpu(points, now)!!, 0.001)
    }

    @Test
    fun anEmptyWindowYieldsNoMean() {
        val points = listOf(point(atMinutesAgo = 90, cpu = 55.0))
        assertNull(WidgetAverage.cpu(points, now))
        assertNull(WidgetAverage.cpu(emptyList(), now))
    }

    @Test
    fun meanIgnoresMissingSamples() {
        assertNull(WidgetAverage.mean(emptyList()))
        assertNull(WidgetAverage.mean(listOf(null, null)))
        assertEquals(15.0, WidgetAverage.mean(listOf(10.0, null, 20.0))!!, 0.001)
    }
}
