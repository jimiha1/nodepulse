package app.nodepulse.widget

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The widget's own refresh schedule, which exists because the launcher's
 * cannot be relied on.
 *
 * `updatePeriodMillis` is 30 minutes, and Android treats that as a floor
 * rather than a promise — a vendor build may defer it further. This device's
 * battery manager does: its log shows `job is prevent by HN_USER_EXPERIENCE`
 * against the app's own WorkManager jobs. So the widget keeps a schedule of
 * its own, and these are the two numbers that decide whether it works.
 *
 * Plain arithmetic on purpose: the Android runtime these run under has no
 * test harness in this module, and what is worth pinning down is the choice
 * of interval, not the plumbing that hands it to WorkManager.
 */
class WidgetPeriodicRefreshTest {

    @Test
    fun theIntervalIsLegalForPeriodicWork() {
        // WorkManager refuses a periodic request below its own floor by
        // throwing at enqueue time, which would leave the widget with no
        // schedule at all and nothing on screen to say so.
        assertTrue(
            "interval ${WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES}min is below " +
                "WorkManager's ${WidgetPeriodicRefreshPolicy.MIN_INTERVAL_MINUTES}min floor",
            WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES >=
                WidgetPeriodicRefreshPolicy.MIN_INTERVAL_MINUTES,
        )
    }

    @Test
    fun theIntervalBeatsTheLaunchersOwnBroadcast() {
        // The whole point of the schedule: 30 minutes is the launcher's best
        // case, so an interval at or above it would add a job that can only
        // ever arrive later than the broadcast it was meant to cover for.
        assertTrue(
            "interval ${WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES}min does not beat " +
                "the launcher's ${WidgetPeriodicRefreshPolicy.LAUNCHER_INTERVAL_MINUTES}min",
            WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES <
                WidgetPeriodicRefreshPolicy.LAUNCHER_INTERVAL_MINUTES,
        )
    }

    @Test
    fun nothingIsScheduledWhileNoWidgetIsPlaced() {
        // A job that refreshes nothing still wakes the process every fifteen
        // minutes, which is the battery cost this policy exists to avoid.
        assertFalse(WidgetPeriodicRefreshPolicy.shouldSchedule(placedWidgets = 0))
    }

    @Test
    fun oneWidgetIsEnoughToSchedule() {
        assertTrue(WidgetPeriodicRefreshPolicy.shouldSchedule(placedWidgets = 1))
        assertTrue(WidgetPeriodicRefreshPolicy.shouldSchedule(placedWidgets = 2))
        // Either size counts: the schedule covers both providers at once, and
        // a phone holding one small widget must refresh it just the same.
        assertTrue(WidgetPeriodicRefreshPolicy.shouldSchedule(placedWidgets = 5))
    }
}
