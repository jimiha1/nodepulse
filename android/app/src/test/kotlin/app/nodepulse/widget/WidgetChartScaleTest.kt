package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetChartScaleTest {

    private fun series(
        values: List<Double?>,
        isPercent: Boolean = false,
        fitToData: Boolean = false,
    ) = WidgetChart.Series(
        label = "x",
        lines = listOf(WidgetChart.Line(values, 0, filled = true)),
        isPercent = isPercent,
        valueText = "--",
        valueShort = "--",
        fitToData = fitToData,
    )

    @Test
    fun aPercentageAxisIsAlwaysZeroToHundred() {
        val scale = WidgetChart.scaleFor(series(listOf(40.0, 45.0), isPercent = true))
        assertEquals(0.0, scale.lo, 0.0001)
        assertEquals(100.0, scale.hi, 0.0001)
    }

    @Test
    fun aRateAxisKeepsItsZeroBaseline() {
        val scale = WidgetChart.scaleFor(series(listOf(1000.0, 5000.0)))
        assertEquals(0.0, scale.lo, 0.0001)
        assertEquals(5000.0, scale.hi, 0.0001)
    }

    @Test
    fun aFittedAxisHugsTheDataOnBothSides() {
        // 24..31ms: the 7ms of movement is the whole story, and a 0..31 axis
        // would flatten it into the top fifth of the panel. The padding is the
        // 1ms floor here — 8% of 7ms is only 0.56 — so the axis is 23..32.
        val scale = WidgetChart.scaleFor(series(listOf(24.0, 31.0), fitToData = true))
        assertEquals(23.0, scale.lo, 0.0001)
        assertEquals(32.0, scale.hi, 0.0001)
    }

    @Test
    fun aWideWindowPadsProportionallyRatherThanByTheFloor() {
        // 100..300ms: 8% of the 200ms range is 16ms, well past the floor.
        val scale = WidgetChart.scaleFor(series(listOf(100.0, 300.0), fitToData = true))
        assertEquals(84.0, scale.lo, 0.0001)
        assertEquals(316.0, scale.hi, 0.0001)
    }

    @Test
    fun aFlatWindowGetsAFloorRatherThanAnEmptySpan() {
        // A dead-flat link has no range to take a percentage of. The 1ms floor
        // keeps the padding finite, and the axis still has a usable span.
        val scale = WidgetChart.scaleFor(series(listOf(25.0, 25.0), fitToData = true))
        assertEquals(24.0, scale.lo, 0.0001)
        assertEquals(26.0, scale.hi, 0.0001)
    }

    @Test
    fun aFittedAxisNeverDipsBelowZero() {
        // 1..3ms pads by the 1ms floor to 0..4, so the lower bound is already
        // legal. A window closer to zero is where the clamp has to act.
        val scale = WidgetChart.scaleFor(series(listOf(0.5, 0.6), fitToData = true))
        assertEquals(0.0, scale.lo, 0.0001)
        assertEquals(1.6, scale.hi, 0.0001)
    }

    @Test
    fun aFlatLineLandsInTheMiddleOfThePanel() {
        val scale = WidgetChart.Scale(10.0, 10.0)
        assertEquals(50.0f, scale.y(10.0, top = 0f, height = 100f), 0.001f)
    }

    @Test
    fun yMapsTheLowEndToTheBottomAndTheHighEndToTheTop() {
        val scale = WidgetChart.Scale(20.0, 40.0)
        assertEquals(100.0f, scale.y(20.0, top = 0f, height = 100f), 0.001f)
        assertEquals(0.0f, scale.y(40.0, top = 0f, height = 100f), 0.001f)
        assertEquals(50.0f, scale.y(30.0, top = 0f, height = 100f), 0.001f)
    }

    @Test
    fun aMissingSampleDoesNotCountTowardsTheAxis() {
        val scale = WidgetChart.scaleFor(series(listOf(24.0, null, 31.0), fitToData = true))
        assertEquals(23.0, scale.lo, 0.0001)
        assertEquals(32.0, scale.hi, 0.0001)
    }
}
