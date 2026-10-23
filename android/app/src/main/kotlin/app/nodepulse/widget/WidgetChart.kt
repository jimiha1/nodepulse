package app.nodepulse.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import app.nodepulse.R

/**
 * Draws every chart panel into one bitmap.
 *
 * A `RemoteViews` cannot hold a custom view, so a trend line has to arrive as
 * an image. One image rather than one per panel: each bitmap crosses the
 * binder as part of the update, and the transaction has a hard size limit that
 * a widget cannot recover from — it simply stops updating, with a
 * `TransactionTooLargeException` in the log and nothing on screen to say so.
 *
 * The bitmap is sized from the space the launcher actually gave the widget
 * ([Bounds]), capped, and drawn at `ARGB_8888` because a gradient fill bands
 * visibly at anything less.
 */
object WidgetChart {
    /**
     * The most bitmap one update may carry, in bytes.
     *
     * The binding constraint is not a side length, it is the size of the whole
     * `RemoteViews` transaction — around a megabyte, shared with the layout
     * and with whatever else is in flight, and exceeding it throws
     * `TransactionTooLargeException` and stops the update reaching the
     * launcher at all. A per-side cap does not bound that: 900x900 at
     * `ARGB_8888` is 3.2 MiB, and even a 4x4 widget at 3x density
     * (about 750x465 after the header) is 1.4 MiB.
     *
     * So the budget is on area, and an image over it is drawn smaller and
     * stretched by the `ImageView` (`scaleType="fitXY"`). These are
     * antialiased line charts; a modest upscale costs a little softness, and a
     * widget that silently stops updating costs everything.
     */
    private const val MAX_BITMAP_BYTES = 640 * 1024

    /** `ARGB_8888`, chosen because a translucent fill bands visibly below it. */
    private const val BYTES_PER_PIXEL = 4

    private const val MAX_PIXELS = MAX_BITMAP_BYTES / BYTES_PER_PIXEL

    /**
     * One line of a panel.
     *
     * [values] holds nulls for a sample that was never taken — a ping probe
     * that timed out — and the line breaks there rather than diving to zero.
     * Zero is a real latency reading; a gap is not, and drawing the two the
     * same way would hide an outage behind a plausible-looking dip.
     */
    data class Line(
        val values: List<Double?>,
        val color: Int,
        /**
         * Whether this line is the panel's primary one: drawn solid, with the
         * translucent area under it. A secondary line is drawn thinner and
         * half-transparent, so two lines of one metric stay distinguishable
         * without a second colour.
         */
        val filled: Boolean = false,
    )

    data class Series(
        val label: String,
        val lines: List<Line>,
        /** Whether the vertical scale is a fixed 0..100. */
        val isPercent: Boolean,
        val valueText: String,
        /**
         * A shorter spelling of [valueText] for a panel too narrow for it.
         *
         * Only network has one worth having: its reading is two byte counts,
         * and on a one-column widget even the label-less full form is wider
         * than the panel. Everything else passes its own text through.
         */
        val valueShort: String,
        /**
         * Swatches drawn after the label, one per line, in the order the lines
         * are listed.
         *
         * Latency is the panel that needs this: its three lines are three
         * carriers, and nothing in a single-colour panel says which is which.
         * The names do not fit at 150dp, so the dots carry the mapping and the
         * value text — `24/31/58ms` — lists the carriers in the same order.
         */
        val legendColors: List<Int> = emptyList(),
        /**
         * Whether the vertical scale hugs the data instead of starting at 0.
         *
         * Latency needs it. A link that sits between 24 and 31ms has 7ms of
         * movement, which against a 0..300 axis is a flat line; fitted, those
         * 7ms fill the panel and the wobble is the whole point of the chart.
         * Percentages and byte rates keep their zero baseline — a CPU chart
         * that started at 40% would make an idle box look busy.
         */
        val fitToData: Boolean = false,
    ) {
        /**
         * The two-line form the other metrics are built with.
         *
         * [secondary] is the outbound half of network, or empty. Kept as a
         * constructor so the nine single-metric panels read exactly as they
         * did before latency needed a third line.
         */
        constructor(
            label: String,
            values: List<Double>,
            secondary: List<Double>,
            isPercent: Boolean,
            valueText: String,
            valueShort: String,
            color: Int,
        ) : this(
            label = label,
            lines = buildList {
                add(Line(values, color, filled = true))
                if (secondary.isNotEmpty()) add(Line(secondary, color, filled = false))
            },
            isPercent = isPercent,
            valueText = valueText,
            valueShort = valueShort,
        )
    }

    /**
     * [widthPx] x [heightPx] of panels laid out to match [count].
     *
     * Returns null when there is nothing to draw, so the caller hides the
     * image rather than showing an empty box.
     */
    /** Between panels, in dp. Wide enough that a right-aligned value and the
     *  next panel's label cannot run together, which at 3% of the smaller side
     *  they did. */
    private const val GAP_DP = 10f

    /** Label and value type sizes, in dp. */
    private const val LABEL_DP = 11f
    private const val VALUE_DP = 15f

    /** Kept clear between a panel's label and its value. */
    private const val LABEL_GAP_DP = 10f

    /** How small the value may get, relative to the label, before the label is
     *  dropped instead. A panel has room for one of them at that point, and the
     *  number is the one worth reading — the colour already says which metric
     *  it is. */
    private const val MIN_VALUE_RATIO = 1.0f

    fun render(
        context: Context,
        series: List<Series>,
        widthPx: Int,
        heightPx: Int,
        density: Float,
    ): Bitmap? {
        if (series.isEmpty()) return null
        // The scale comes back too, because everything drawn is sized in dp:
        // shrinking the bitmap for the transaction budget has to shrink the
        // type with it, or the text would be over-large once the `ImageView`
        // scales the image back up.
        val (w, h, scale) = withinBudget(
            widthPx.coerceAtLeast(1),
            heightPx.coerceAtLeast(1),
        )
        val px = density * scale

        val columns = if (series.size >= 4) 2 else if (series.size == 2) 2 else 1
        val rows = if (series.size >= 4) 2 else 1

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val gap = GAP_DP * px
        val cellW = (w - gap * (columns - 1)) / columns
        val cellH = (h - gap * (rows - 1)) / rows

        series.take(columns * rows).forEachIndexed { index, s ->
            val col = index % columns
            val row = index / columns
            drawPanel(
                context = context,
                canvas = canvas,
                series = s,
                left = col * (cellW + gap),
                top = row * (cellH + gap),
                width = cellW,
                height = cellH,
                px = px,
            )
        }
        return bitmap
    }

    /**
     * [width] x [height] shrunk to fit [MAX_PIXELS], keeping its shape.
     *
     * Proportional rather than clamped per side: the aspect ratio is what the
     * `ImageView` will stretch back to, and squashing one side alone would
     * make every chart lean.
     */
    private data class Sized(val width: Int, val height: Int, val scale: Float)

    private fun withinBudget(width: Int, height: Int): Sized {
        val pixels = width.toLong() * height.toLong()
        if (pixels <= MAX_PIXELS) return Sized(width, height, 1f)
        val scale = kotlin.math.sqrt(MAX_PIXELS.toDouble() / pixels.toDouble())
        return Sized(
            (width * scale).toInt().coerceAtLeast(1),
            (height * scale).toInt().coerceAtLeast(1),
            scale.toFloat(),
        )
    }

    private fun drawPanel(
        context: Context,
        canvas: Canvas,
        series: Series,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        px: Float,
    ) {
        // Sized in dp, not as a fraction of the panel. A fraction made the type
        // depend on the widget's shape — a tall 2x2 got huge letters, a wide
        // one got tiny ones — and on how far the bitmap had been scaled.
        // Capped by the panel so a very short one does not overflow its own
        // label row.
        val labelSize = (LABEL_DP * px).coerceAtMost(height * 0.22f)
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.MONOSPACE
            textSize = labelSize
            color = context.getColor(R.color.widgetSummaryText)
        }

        val value = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            textSize = (VALUE_DP * px).coerceAtMost(height * 0.28f)
            color = context.getColor(R.color.widgetText)
            textAlign = Paint.Align.RIGHT
        }

        // Shrunk to what is left after the label, rather than drawn at a fixed
        // size and allowed to run into it. Network is the case that forces
        // this: its reading is two byte counts ("92.9m / 71.2m"), which in a
        // four-panel grid is wider than the panel itself — and a right-aligned
        // string that does not fit grows leftwards, straight through the label.
        val full = value.textSize
        val floor = labelSize * MIN_VALUE_RATIO
        val beside = width - text.measureText(series.label) - LABEL_GAP_DP * px

        // The size at which [str] exactly fills [avail], unclamped — so what
        // follows is decided by measuring rather than by guessing how wide a
        // string will be. Guessing is what the first attempt at this did, and
        // it kept the label on a panel that had no room for it.
        fun sizeFor(str: String, avail: Float): Float {
            value.textSize = full
            val needed = value.measureText(str)
            return if (needed <= avail || needed <= 0f) full else full * (avail / needed)
        }

        // Swatches sit between the label and the value, so the value has that
        // much less room. Three dots and their gaps are about one glyph wide,
        // which is exactly the margin that decides whether a four-panel grid
        // keeps its label.
        val dotSize = labelSize * 0.62f
        val dotGap = 2.5f * px
        val legendWidth = if (series.legendColors.isEmpty()) {
            0f
        } else {
            series.legendColors.size * dotSize +
                (series.legendColors.size - 1) * dotGap +
                LABEL_GAP_DP * px * 0.5f
        }

        // In order of what is worth keeping: the label and the full reading,
        // then the label with a shorter one, then the reading alone. A
        // right-aligned string that does not fit grows leftwards — through the
        // label, and then out of the panel — so something has to give, and it
        // should be the least informative thing first.
        val options = listOf(
            Triple(true, series.valueText, beside - legendWidth),
            Triple(true, series.valueShort, beside - legendWidth),
            // Without a label the swatches still sit at the left edge, so the
            // reading is fitted beside them rather than over them.
            Triple(false, series.valueText, width - legendWidth),
            Triple(false, series.valueShort, width - legendWidth),
        )
        var showLabel = false
        var shown = series.valueShort
        var size = sizeFor(series.valueShort, width)
        for ((withLabel, str, avail) in options) {
            val fitted = sizeFor(str, avail)
            if (fitted >= floor) {
                showLabel = withLabel
                shown = str
                size = fitted
                break
            }
        }
        // Never clamped back up: a value that overflows its panel and runs into
        // the one beside it is worse than a small one.
        value.textSize = size

        val valueSize = value.textSize
        // Right-aligned to the panel, not to the bitmap: with four panels the
        // value of the left one and the label of the right one share a line,
        // and the gap between the cells is what keeps them apart.
        val baseline = top + maxOf(labelSize, valueSize)
        if (showLabel) {
            canvas.drawText(series.label, left, baseline, text)
        }
        // The swatches stay even when the label had to go: they are the only
        // thing that says which line is which, and a panel that dropped its
        // label is exactly the one with no room for the names instead.
        drawLegend(
            canvas = canvas,
            series = series,
            x = if (showLabel) {
                left + text.measureText(series.label) + LABEL_GAP_DP * px * 0.5f
            } else {
                left
            },
            baseline = baseline,
            labelSize = labelSize,
            dotSize = dotSize,
            dotGap = dotGap,
        )
        canvas.drawText(shown, left + width, baseline, value)

        val plotTop = baseline + valueSize * 0.4f
        val plotHeight = height - (plotTop - top)
        if (plotHeight <= 2f) return

        if (series.lines.all { line -> line.values.all { it == null } }) {
            val hint = Paint(text).apply {
                textAlign = Paint.Align.CENTER
                alpha = 140
            }
            canvas.drawText(
                context.getString(R.string.widget_no_history),
                left + width / 2,
                plotTop + plotHeight / 2 + labelSize / 3,
                hint,
            )
            return
        }

        // Every line in a panel shares one scale, so the three carriers are
        // comparable. Reading them against separate maxima would make the
        // quietest link look like the busiest one.
        val scale = scaleFor(series)
        val seenColors = mutableSetOf<Int>()
        series.lines.forEach { line ->
            // A line that repeats a colour already drawn is the second half of
            // one metric — network's upload — and is dimmed so the pair stays
            // tellable apart. Three carriers in three colours are all primary,
            // and dimming them would leave the panel fainter than its
            // neighbours for no reason.
            val dimmed = !seenColors.add(line.color)
            drawLine(canvas, line, left, plotTop, width, plotHeight, scale, dimmed)
        }
    }

    /**
     * The vertical span a panel is drawn against.
     *
     * Separate from the drawing so the rule can be asserted on a plain JVM:
     * a percentage is always 0..100, a byte rate or count starts at zero, and
     * only latency fits itself to the data.
     */
    internal data class Scale(val lo: Double, val hi: Double) {
        /** Where [v] lands between [top] and [top] + [height]. */
        fun y(v: Double, top: Float, height: Float): Float {
            val span = hi - lo
            // A perfectly flat window has no span to divide by; its line sits
            // in the middle of the panel rather than collapsing onto an edge.
            val t = if (span <= 0.0) 0.5 else ((v - lo) / span).coerceIn(0.0, 1.0)
            return top + height - (t * height).toFloat()
        }
    }

    /**
     * How much room [Scale] leaves above and below a fitted window, as a
     * fraction of the window's own height — with a floor in milliseconds so a
     * dead-flat link does not get its rounding noise blown up to full height.
     */
    private const val FIT_PADDING_RATIO = 0.08
    private const val FIT_PADDING_FLOOR = 1.0

    internal fun scaleFor(series: Series): Scale {
        if (series.isPercent) return Scale(0.0, 100.0)

        val all = series.lines.flatMap { line -> line.values.filterNotNull() }
        if (!series.fitToData) {
            return Scale(0.0, maxOf(all.maxOrNull() ?: 1.0, 1.0))
        }

        val lo = all.minOrNull() ?: return Scale(0.0, 1.0)
        val hi = all.maxOrNull() ?: return Scale(0.0, 1.0)
        val pad = maxOf((hi - lo) * FIT_PADDING_RATIO, FIT_PADDING_FLOOR)
        // Never below zero: a fitted latency axis dipping under it would draw
        // a baseline that cannot happen.
        return Scale(maxOf(lo - pad, 0.0), hi + pad)
    }

    /**
     * The carrier swatches, centred on the label's own line.
     *
     * Drawn rather than written because the names do not fit: three of them at
     * 11dp on a 150dp panel would push the reading out of the card. The value
     * text lists the carriers in this same order, so the mapping is recoverable
     * without a word.
     */
    private fun drawLegend(
        canvas: Canvas,
        series: Series,
        x: Float,
        baseline: Float,
        labelSize: Float,
        dotSize: Float,
        dotGap: Float,
    ) {
        if (series.legendColors.isEmpty()) return
        val centerY = baseline - labelSize * 0.32f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        var left = x
        for (color in series.legendColors) {
            paint.color = color
            canvas.drawCircle(left + dotSize / 2f, centerY, dotSize / 2f, paint)
            left += dotSize + dotGap
        }
    }

    private fun drawLine(
        canvas: Canvas,
        line: Line,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        scale: Scale,
        dimmed: Boolean,
    ) {
        val values = line.values
        if (values.size < 2) return
        val stepX = width / (values.size - 1)

        // Each run of present samples is its own path. A null is a probe that
        // never answered, and joining across it would draw a straight line
        // through an outage as if the link had been fine.
        //
        // Each run also remembers the x it started at, so its fill closes over
        // its own span: a run after a gap is a few samples wide, and closing it
        // to the panel edges would shade a stretch of time it has no data for.
        class Run(val path: Path, val startX: Float) {
            var endX = startX
        }

        val runs = mutableListOf<Run>()
        var current: Run? = null
        values.forEachIndexed { i, v ->
            if (v == null) {
                current = null
                return@forEachIndexed
            }
            val x = left + stepX * i
            val y = scale.y(v, top, height)
            val run = current
            if (run == null) {
                val path = Path().apply { moveTo(x, y) }
                current = Run(path, x).also { runs.add(it) }
            } else {
                run.path.lineTo(x, y)
                run.endX = x
            }
        }
        if (runs.isEmpty()) return

        val color = line.color
        if (line.filled) {
            val area = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                this.color = Color.argb(56, Color.red(color), Color.green(color), Color.blue(color))
            }
            runs.forEach { run ->
                // A lone sample has no line to fill, and closing it would put a
                // stray wedge on the panel.
                if (run.startX >= run.endX) return@forEach
                canvas.drawPath(
                    Path(run.path).apply {
                        lineTo(run.endX, top + height)
                        lineTo(run.startX, top + height)
                        close()
                    },
                    area,
                )
            }
        }

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = (height * 0.035f).coerceIn(1.5f, 4f)
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            this.color = if (dimmed) {
                Color.argb(150, Color.red(color), Color.green(color), Color.blue(color))
            } else {
                color
            }
        }
        runs.forEach { canvas.drawPath(it.path, stroke) }
    }
}
