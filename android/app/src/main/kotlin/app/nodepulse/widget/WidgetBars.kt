package app.nodepulse.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF

/**
 * The small bitmaps the 2x4 widget draws its bars with.
 *
 * `RemoteViews` cannot host a custom view, so a bar has to arrive as an image.
 * These are tiny — a two-cell row is a few hundred pixels wide — and there are
 * at most four of them per update, far inside the transaction limit the 4x2
 * charts already live under.
 *
 * The arithmetic is separated from the drawing because `Bitmap` and `Canvas`
 * are stubs under a plain JVM unit test: [pingFraction] and [colorFor] are
 * asserted, and the draw calls are covered by compilation and the device pass.
 */
internal object WidgetBars {
    private const val TRACK_COLOR = 0x33888888
    private const val GREEN = 0xFF34C759.toInt()
    private const val AMBER = 0xFFFF9F0A.toInt()
    private const val RED = 0xFFFF453A.toInt()
    private const val GREY = 0xFF888888.toInt()

    /** The ping at which the bar is empty. */
    private const val WORST_PING_MS = 300.0

    /** Columns in a history strip, and the space between two of them. */
    private const val SEGMENTS = 12
    private const val SEGMENT_GAP_DP = 2f

    /**
     * How full the bar is for a ping: a perfect link fills it, 300ms or worse
     * empties it. A missing ping has no fraction at all, so the caller can
     * leave the track empty rather than draw a bar that claims zero latency.
     */
    fun pingFraction(pingMs: Double?): Double? =
        pingMs?.let { (1.0 - it / WORST_PING_MS).coerceIn(0.0, 1.0) }

    fun colorFor(fraction: Double?): Int = when {
        fraction == null -> GREY
        fraction >= 0.66 -> GREEN
        fraction >= 0.33 -> AMBER
        else -> RED
    }

    /**
     * The colour of one historical sample, which is the whole point of the
     * history strip: a latency that jumps for a few minutes shows up as a
     * differently coloured column even though nobody was looking at the phone
     * when it happened.
     *
     * Same bands as [colorFor], applied to the ping itself so a sample and a
     * live reading never disagree about what counts as slow.
     */
    fun colorForPing(pingMs: Double?): Int = colorFor(pingFraction(pingMs))

    /**
     * One column per sample of the window, coloured by that sample's latency.
     *
     * This replaced a bar that filled itself by the *current* ping. The widget
     * refreshes every thirty minutes, so a bar of the moment said almost
     * nothing about the half hour it was drawn for — by the time anyone looked
     * it was stale, and a spike between refreshes left no trace at all. Twelve
     * columns span the fetched window instead: a carrier that went bad at 3am
     * still shows red at 9am.
     *
     * Fewer, wider columns than the twenty the reference draws, because twelve
     * 2dp-separated blocks are what this card's ~78dp of bar can hold at a
     * glance; twenty thin ones read as a texture rather than as discrete
     * samples, and the point here is the outlier, not the texture.
     *
     * Samples are bucketed, not merely truncated: a window with more samples
     * than columns averages each bucket, so one bad sample in ten still colours
     * its column rather than being dropped by a `take(12)`.
     */
    fun history(columns: List<Double?>, w: Int, h: Int, density: Float): Bitmap? {
        if (w <= 0 || h <= 0) return null
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val gap = SEGMENT_GAP_DP * density
        val segW = (w - gap * (SEGMENTS - 1)) / SEGMENTS
        if (segW <= 0) {
            // Too narrow for the gaps: one solid strip is better than nothing.
            val worst = columns.filterNotNull().maxOrNull()
            return continuous(worst?.let { pingFraction(it) }, w, h, density)
        }
        val radius = minOf(h / 2f, segW / 2f)
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TRACK_COLOR }
        val buckets = bucket(columns, SEGMENTS)
        for (i in 0 until SEGMENTS) {
            val left = i * (segW + gap)
            val rect = RectF(left, 0f, left + segW, h.toFloat())
            // A bucket with no sample stays a bare track: a gap in the history
            // is not a good latency, and a green column there would claim one.
            val paint = buckets.getOrNull(i)?.let { sample ->
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorForPing(sample) }
            } ?: track
            canvas.drawRoundRect(rect, radius, radius, paint)
        }
        return bitmap
    }

    /**
     * [values] split into exactly [count] buckets, each one the worst sample it
     * contains — the worst, not the mean, because a column exists to make a
     * spike visible and averaging a spike with nine quiet samples hides it.
     *
     * Buckets with no samples come back null rather than absent, so the caller
     * can keep their column width and draw an empty track.
     */
    internal fun bucket(values: List<Double?>, count: Int): List<Double?> {
        if (count <= 0) return emptyList()
        if (values.isEmpty()) return List(count) { null }
        // Fewer samples than columns: one column per sample, newest on the
        // right, and the rest empty. Spreading three samples across twelve
        // columns would draw the same sample four times, which reads as four
        // observations where there was one.
        if (values.size < count) {
            return List(count - values.size) { null } + values
        }
        return (0 until count).map { i ->
            val from = i * values.size / count
            val to = (i + 1) * values.size / count
            values.subList(from, to.coerceAtLeast(from + 1).coerceAtMost(values.size))
                .filterNotNull()
                .maxOrNull()
        }
    }

    /** One rounded bar, used for the stability score. */
    fun continuous(fraction: Double?, w: Int, h: Int, density: Float): Bitmap? {
        if (w <= 0 || h <= 0) return null
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val radius = h / 2f
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TRACK_COLOR }
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), radius, radius, track)
        if (fraction != null) {
            val fillW = (w * fraction.coerceIn(0.0, 1.0)).toFloat()
            if (fillW > 0f) {
                val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorFor(fraction) }
                canvas.drawRoundRect(RectF(0f, 0f, fillW, h.toFloat()), radius, radius, fill)
            }
        }
        return bitmap
    }
}
