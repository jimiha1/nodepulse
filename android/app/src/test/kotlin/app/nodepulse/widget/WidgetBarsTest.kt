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
}
