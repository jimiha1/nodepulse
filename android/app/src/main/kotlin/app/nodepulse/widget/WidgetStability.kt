package app.nodepulse.widget

import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * How steady the last hour was, in the four numbers the 2x4 widget shows.
 *
 * Pure arithmetic, no Android types: `RemoteViews` cannot be rendered in a JVM
 * test, so everything worth asserting lives here and the view code only copies
 * these numbers into rows.
 *
 * The window is whatever history the caller fetched — the tall widget asks for
 * one hour — so nothing here assumes a length.
 */
internal object WidgetStability {
    data class Stats(
        /** 0..100, or null when the window holds no ping at all. */
        val score: Int?,
        /** Mean of the non-null per-carrier loss values, percent. */
        val lossPct: Double?,
        /** Mean absolute change between adjacent samples, per carrier then averaged. */
        val jitterMs: Double?,
        val spikes: Int,
        val samples: Int,
    )

    private val EMPTY = Stats(score = null, lossPct = null, jitterMs = null, spikes = 0, samples = 0)

    /**
     * A sample is a row that reported at least one ping. Rows with no ping say
     * nothing about latency, and counting them would dilute the score toward a
     * perfect one the widget has no evidence for.
     */
    fun compute(history: List<WidgetApi.HistoryPoint>): Stats {
        val samples = history.filter { it.pingCt != null || it.pingCu != null || it.pingCm != null }
        if (samples.isEmpty()) return EMPTY

        val losses = samples.flatMap { listOfNotNull(it.lossCt, it.lossCu, it.lossCm) }
        val lossPct = if (losses.isEmpty()) null else losses.average()

        // Per carrier, then averaged: a carrier that reported twice as often
        // must not weigh twice as much in the combined figure. The pairs come
        // from adjacent rows of the whole window, not from adjacent samples —
        // a row that reported nothing for this carrier breaks the chain rather
        // than being stepped over, because a delta measured across a gap is a
        // delta over a longer interval and reads as jitter that never happened.
        val perCarrier = listOf<(WidgetApi.HistoryPoint) -> Double?>(
            { it.pingCt }, { it.pingCu }, { it.pingCm },
        ).mapNotNull { ping ->
            val deltas = history.zipWithNext().mapNotNull { (a, b) ->
                val x = ping(a)
                val y = ping(b)
                if (x == null || y == null) null else abs(y - x)
            }
            if (deltas.isEmpty()) null else deltas.average()
        }
        val jitterMs = if (perCarrier.isEmpty()) null else perCarrier.average()

        val allPings = samples.flatMap { listOfNotNull(it.pingCt, it.pingCu, it.pingCm) }
        val threshold = maxOf(2.0 * median(allPings), 50.0)
        val spikes = samples.count { row ->
            listOfNotNull(row.pingCt, row.pingCu, row.pingCm).any { it > threshold }
        }

        // Rounded loss and the share of samples that spiked, subtracted from a
        // perfect hundred. A 0.2% loss window is a 100, which is what the
        // reference design shows for exactly that figure.
        val penalty = (lossPct ?: 0.0).roundToInt() + (100.0 * spikes / samples.size).roundToInt()
        return Stats(
            score = (100 - penalty).coerceIn(0, 100),
            lossPct = lossPct,
            jitterMs = jitterMs,
            spikes = spikes,
            samples = samples.size,
        )
    }

    private fun median(values: List<Double>): Double {
        if (values.isEmpty()) return 0.0
        val sorted = values.sorted()
        val mid = sorted.size / 2
        return if (sorted.size % 2 == 0) (sorted[mid - 1] + sorted[mid]) / 2.0 else sorted[mid]
    }
}
