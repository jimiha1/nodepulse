package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetBarsTest {
    @Test fun pingFractionFallsFromOneToZero() {
        assertEquals(1.0, WidgetBars.pingFraction(0.0)!!, 0.001)
        assertEquals(0.5, WidgetBars.pingFraction(150.0)!!, 0.001)
        assertEquals(0.0, WidgetBars.pingFraction(300.0)!!, 0.001)
        assertEquals(0.0, WidgetBars.pingFraction(900.0)!!, 0.001)
    }

    @Test fun aMissingPingHasNoFraction() {
        assertNull(WidgetBars.pingFraction(null))
    }

    @Test fun colourBandsSplitAtTwoThirdsAndOneThird() {
        assertEquals(0xFF34C759.toInt(), WidgetBars.colorFor(1.0))
        assertEquals(0xFF34C759.toInt(), WidgetBars.colorFor(0.66))
        assertEquals(0xFFFF9F0A.toInt(), WidgetBars.colorFor(0.65))
        assertEquals(0xFFFF9F0A.toInt(), WidgetBars.colorFor(0.33))
        assertEquals(0xFFFF453A.toInt(), WidgetBars.colorFor(0.32))
        assertEquals(0xFF888888.toInt(), WidgetBars.colorFor(null))
    }

    @Test fun colourForPingUsesTheSameBandsAsALiveReading() {
        // 40ms is a full bar and 280ms is nearly empty; both sides of the
        // threshold have to agree with the live reading's own colouring, or
        // the strip and the number beside it would disagree.
        assertEquals(WidgetBars.colorFor(WidgetBars.pingFraction(40.0)), WidgetBars.colorForPing(40.0))
        assertEquals(0xFF34C759.toInt(), WidgetBars.colorForPing(40.0))
        assertEquals(0xFFFF9F0A.toInt(), WidgetBars.colorForPing(200.0))
        assertEquals(0xFFFF453A.toInt(), WidgetBars.colorForPing(280.0))
        assertEquals(0xFF888888.toInt(), WidgetBars.colorForPing(null))
    }

    @Test fun bucketKeepsTheWorstSampleInEachColumn() {
        // A spike must survive its bucket: averaging 900ms with three quiet
        // samples would hide exactly the event the strip exists to show.
        val bucketed = WidgetBars.bucket(listOf(10.0, 20.0, 30.0, 900.0, 40.0, 50.0, 60.0, 70.0), 4)
        assertEquals(listOf(20.0, 900.0, 50.0, 70.0), bucketed)
    }

    @Test fun bucketSpreadsFewerSamplesThanColumnsWithoutRepeatingThem() {
        // Three samples in twelve columns: three columns on the right, nine
        // empty. Repeating a sample to fill the width would claim observations
        // the window does not contain.
        val bucketed = WidgetBars.bucket(listOf(10.0, 20.0, 30.0), 5)
        assertEquals(listOf(null, null, 10.0, 20.0, 30.0), bucketed)
    }

    @Test fun bucketKeepsAGapInTheHistoryEmpty() {
        // A carrier that reported nothing for a stretch leaves empty columns,
        // not green ones: green there would claim a latency nothing measured.
        val bucketed = WidgetBars.bucket(listOf(10.0, null, null, 40.0), 4)
        assertEquals(listOf(10.0, null, null, 40.0), bucketed)
    }

    @Test fun bucketOfNothingIsAllEmpty() {
        assertEquals(listOf(null, null, null), WidgetBars.bucket(emptyList(), 3))
    }
}
