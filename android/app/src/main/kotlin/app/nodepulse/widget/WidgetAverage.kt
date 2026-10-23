package app.nodepulse.widget

/**
 * The half-hour means the 4x2's reading mode shows for CPU and memory.
 *
 * A widget refreshes every thirty minutes, so the instantaneous figure it
 * would otherwise print is a single sample of a window nobody was watching.
 * The mean is what actually describes the half hour the card is up for.
 *
 * Pure arithmetic with no Android types, so the window rule below is testable
 * on a plain JVM.
 */
internal object WidgetAverage {

    /** The window the means describe, in minutes. */
    const val WINDOW_MINUTES = 30

    private const val WINDOW_MS = WINDOW_MINUTES * 60_000L

    /**
     * The samples [now] can honestly call the last half hour.
     *
     * Two cases return nothing rather than a mean:
     *
     * - **No timestamps at all.** A snapshot written before the timestamp
     *   column existed, or a site that omits it, leaves every row at zero.
     *   Those rows could be five minutes old or a day old, and averaging them
     *   would put a number under a label that claims half an hour. The caller
     *   falls back to the instantaneous reading instead, which is at least
     *   true about *something*.
     * - **Nothing inside the window.** Same answer for the same reason: the
     *   card would otherwise show yesterday's mean as this half hour's.
     *
     * Rows stamped zero are dropped even when other rows carry times, so a
     * partially migrated snapshot cannot smuggle an undated sample in.
     */
    fun withinWindow(
        points: List<WidgetApi.HistoryPoint>,
        now: Long = System.currentTimeMillis(),
    ): List<WidgetApi.HistoryPoint> {
        if (points.none { it.timestamp > 0L }) return emptyList()
        val cutoff = now - WINDOW_MS
        return points.filter { it.timestamp > 0L && it.timestamp >= cutoff }
    }

    /** The mean of the values that are present; null when none are. */
    fun mean(values: List<Double?>): Double? {
        val present = values.filterNotNull()
        return if (present.isEmpty()) null else present.average()
    }

    fun cpu(
        points: List<WidgetApi.HistoryPoint>,
        now: Long = System.currentTimeMillis(),
    ): Double? = mean(withinWindow(points, now).map { it.cpu })

    fun memory(
        points: List<WidgetApi.HistoryPoint>,
        now: Long = System.currentTimeMillis(),
    ): Double? = mean(withinWindow(points, now).map { it.memory })
}
