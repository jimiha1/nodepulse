package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetStabilityTest {
    private fun point(
        pingCt: Double? = null, pingCu: Double? = null, pingCm: Double? = null,
        lossCt: Double? = null, lossCu: Double? = null, lossCm: Double? = null,
    ) = WidgetApi.HistoryPoint(
        cpu = 0.0, memory = 0.0, disk = 0.0, netRx = 0.0, netTx = 0.0,
        pingCt = pingCt, pingCu = pingCu, pingCm = pingCm,
        lossCt = lossCt, lossCu = lossCu, lossCm = lossCm,
    )

    @Test fun emptyHistoryHasNoScore() {
        val s = WidgetStability.compute(emptyList())
        assertNull(s.score); assertNull(s.lossPct); assertNull(s.jitterMs)
        assertEquals(0, s.spikes); assertEquals(0, s.samples)
    }

    @Test fun rowsWithoutPingAreNotSamples() {
        val s = WidgetStability.compute(listOf(point(), point(lossCt = 10.0)))
        assertEquals(0, s.samples); assertNull(s.score)
    }

    @Test fun cleanWindowScoresOneHundred() {
        val rows = (0 until 90).map { point(10.0, 10.0, 10.0, 0.2, 0.2, 0.2) }
        val s = WidgetStability.compute(rows)
        assertEquals(90, s.samples)
        assertEquals(0.2, s.lossPct!!, 0.001)
        assertEquals(0.0, s.jitterMs!!, 0.001)
        assertEquals(0, s.spikes); assertEquals(100, s.score)
    }

    @Test fun jitterIsMeanAbsoluteDeltaPerCarrier() {
        // CT |20-10|=10, CU |30-10|=20, CM 0 -> mean 10
        val s = WidgetStability.compute(listOf(point(10.0, 10.0, 10.0), point(20.0, 30.0, 10.0)))
        assertEquals(10.0, s.jitterMs!!, 0.001)
    }

    @Test fun jitterSkipsPairsWithAMissingEnd() {
        assertNull(WidgetStability.compute(listOf(point(10.0), point(null), point(30.0))).jitterMs)
    }

    @Test fun aSpikeNeedsTwiceTheMedianAnd50ms() {
        val calm = (0 until 9).map { point(10.0, 10.0, 10.0) }
        assertEquals(1, WidgetStability.compute(calm + point(60.0, 60.0, 60.0)).spikes)
        assertEquals(0, WidgetStability.compute(calm + point(49.0, 49.0, 49.0)).spikes)
    }

    @Test fun scoreIsClampedToZero() {
        val rows = (0 until 10).map { point(10.0, 10.0, 10.0, 100.0, 100.0, 100.0) }
        assertEquals(0, WidgetStability.compute(rows).score)
    }

    @Test fun allNullPingsLeaveEverythingEmpty() {
        val s = WidgetStability.compute((0 until 5).map { point() })
        assertNull(s.score); assertNull(s.jitterMs); assertNull(s.lossPct)
        assertEquals(0, s.spikes)
    }
}
