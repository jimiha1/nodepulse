package app.nodepulse.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.joinAll
import java.util.concurrent.TimeUnit

/**
 * The numbers behind the widget's own refresh schedule.
 *
 * The schedule exists because the launcher's broadcast cannot be relied on.
 * `updatePeriodMillis` is 30 minutes and Android treats that as a floor rather
 * than a promise; a vendor build defers it further. This device does, and its
 * log says so — `job is prevent by HN_USER_EXPERIENCE` against the app's own
 * jobs, with the screen dozing and the app outside the idle whitelist. So the
 * widget keeps a schedule of its own, and these are the two numbers that
 * decide whether it works at all.
 *
 * Kept apart from the WorkManager plumbing for the same reason
 * [WidgetRetryPolicy] is: it is arithmetic, and the arithmetic is the part
 * worth pinning down.
 */
internal object WidgetPeriodicRefreshPolicy {
    /**
     * WorkManager's floor for periodic work. A request below it is refused at
     * enqueue time, which would leave the widget with no schedule at all and
     * nothing on screen to say why.
     */
    const val MIN_INTERVAL_MINUTES = 15

    /**
     * What the launcher promises, in its best case. Read here as the bar the
     * schedule has to beat: an interval at or above this would add a job that
     * can only ever arrive after the broadcast it was meant to cover for.
     */
    const val LAUNCHER_INTERVAL_MINUTES = 30

    /**
     * How often the widget refreshes itself.
     *
     * The floor, deliberately. The reading is the whole point of the widget,
     * and this device's launcher update has been observed arriving well past
     * an hour; at 15 minutes a stale reading is bounded by a quarter of an
     * hour instead. The cost is one short fetch per interval, which the
     * network constraint below keeps from running at all when there is
     * nothing to fetch from.
     */
    const val INTERVAL_MINUTES = 15

    /**
     * Whether the schedule is worth having.
     *
     * A job that refreshes nothing still wakes the process every fifteen
     * minutes, which is the battery cost this check exists to avoid — so the
     * worker stops its own schedule once the last widget is gone, and does not
     * start one before the first is placed.
     */
    fun shouldSchedule(placedWidgets: Int): Boolean = placedWidgets > 0
}

/**
 * Keeps the widget's own refresh schedule in place.
 *
 * Separate from [WidgetRetry] on purpose. That one is a bounded response to a
 * failure — six attempts and it stops. This one is unbounded and unconditional
 * while a widget is placed, because its job is not to fix anything but to
 * bound how old the numbers on screen can get.
 */
object WidgetPeriodicRefresh {
    private const val TAG = "WidgetSchedule"

    private const val WORK_NAME = "app.nodepulse.widget.WidgetRefresh"

    /**
     * Idempotent, and meant to be called on every update: `UPDATE` re-asserts
     * the same request rather than stacking a second one, so a schedule the
     * system dropped is put back by the next broadcast without the caller
     * having to know whether it was there.
     */
    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
            WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES.toLong(), TimeUnit.MINUTES
        )
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()
        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.UPDATE, request)
        Log.i(
            TAG,
            "Widget refresh scheduled (${WidgetPeriodicRefreshPolicy.INTERVAL_MINUTES} min)",
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        Log.i(TAG, "Widget refresh cancelled")
    }
}

/**
 * Refreshes every placed widget on a schedule of its own.
 *
 * Unlike [WidgetRetryWorker] this does not re-arm itself: the periodic request
 * is already the loop, and returning `retry` from inside one is what would
 * turn a fifteen-minute cadence into a backoff spiral.
 */
class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val placed = HomeWidget.placedCount(applicationContext)
        if (!WidgetPeriodicRefreshPolicy.shouldSchedule(placed)) {
            // The last widget was dragged off the home screen and `onDeleted`
            // did not get to cancel this — a reinstall, or a launcher that
            // cleared them without telling the provider. Stopping here is what
            // keeps a schedule that refreshes nothing from running forever.
            Log.i(TAG, "No widgets placed, stopping the schedule")
            WidgetPeriodicRefresh.cancel(applicationContext)
            return Result.success()
        }
        // Awaited, not fired and forgotten: `doWork` is what holds the wake
        // lock, so returning early would let the system freeze the process
        // with the fetches still in flight — and a widget that was refreshed
        // into a frozen process is a widget that did not refresh.
        val started = HomeWidget.refreshAll(applicationContext)
        started.joinAll()
        Log.i(TAG, "Refreshed ${started.size} of $placed placed widget(s)")
        return Result.success()
    }

    private companion object {
        const val TAG = "WidgetSchedule"
    }
}
