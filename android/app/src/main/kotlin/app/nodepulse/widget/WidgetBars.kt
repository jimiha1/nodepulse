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

    private const val SEGMENTS = 20
    private const val SEGMENT_GAP_DP = 1f

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
     * Twenty separate blocks, the way the reference design draws a ping bar.
     * Blocks up to the fraction are filled; the rest stay a faint track.
     */
    fun segmented(fraction: Double?, w: Int, h: Int, density: Float): Bitmap? {
        if (w <= 0 || h <= 0) return null
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val gap = SEGMENT_GAP_DP * density
        val segW = (w - gap * (SEGMENTS - 1)) / SEGMENTS
        if (segW <= 0) {
            // Too narrow for twenty gaps: one solid bar is better than nothing.
            return continuous(fraction, w, h, density)
        }
        val radius = minOf(h / 2f, segW / 2f)
        val filled = ((fraction ?: 0.0) * SEGMENTS).toInt().coerceIn(0, SEGMENTS)
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorFor(fraction) }
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TRACK_COLOR }
        for (i in 0 until SEGMENTS) {
            val left = i * (segW + gap)
            val rect = RectF(left, 0f, left + segW, h.toFloat())
            canvas.drawRoundRect(rect, radius, radius, if (i < filled) fill else track)
        }
        return bitmap
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
