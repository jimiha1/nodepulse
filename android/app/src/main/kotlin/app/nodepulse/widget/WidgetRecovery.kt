package app.nodepulse.widget

import android.content.Context
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

/**
 * How one placed widget gets itself back to showing data after a failed fetch.
 *
 * The widget has exactly one automatic update: the launcher's
 * `updatePeriodMillis` broadcast. Android will not deliver that more often
 * than every 30 minutes, and a vendor build may defer it further — Honor's
 * alarm dump shows a 22.5-minute flex window and a battery manager that gates
 * the job behind `iaware`. So one failed fetch used to leave the error on
 * screen for at least half an hour, and on this device for much longer.
 *
 * WorkManager rather than a plain delayed retry: it survives the process
 * being killed between attempts, and its network constraint is what makes
 * "the network came back" a trigger by itself.
 *
 * Per widget, not per app: two widgets can be pointed at two nodes, and one
 * of them coming back says nothing about the other.
 */
object WidgetRetry {
    private const val TAG = "WidgetRetry"

    private const val WORK_NAME = "app.nodepulse.widget.WidgetRetry"

    internal const val KEY_APP_WIDGET_ID = "appWidgetId"

    /** The unique work name for one widget, so siblings cannot cancel it. */
    internal fun workName(appWidgetId: Int) = "$WORK_NAME/$appWidgetId"

    fun schedule(context: Context, appWidgetId: Int) {
        val request = OneTimeWorkRequestBuilder<WidgetRetryWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .setInputData(workDataOf(KEY_APP_WIDGET_ID to appWidgetId))
            .build()
        // KEEP, not REPLACE: this is called from every failed attempt, and
        // replacing the work would reset the attempt count each time and make
        // the budget meaningless.
        WorkManager.getInstance(context)
            .enqueueUniqueWork(workName(appWidgetId), ExistingWorkPolicy.KEEP, request)
        Log.d(TAG, "Retry scheduled for widget $appWidgetId")
    }

    /**
     * Called once this widget has data on screen again: whatever the retry was
     * going to fix is already fixed, and leaving it queued would only put the
     * widget through a fetch it does not need.
     */
    fun cancel(context: Context, appWidgetId: Int) {
        WorkManager.getInstance(context).cancelUniqueWork(workName(appWidgetId))
    }
}

/**
 * The retry policy, apart from the WorkManager plumbing so it can be tested
 * without an Android runtime.
 */
internal object WidgetRetryPolicy {
    /**
     * Runs before giving up, the first of them immediately.
     *
     * With the 30-second exponential backoff that spans about a quarter of an
     * hour — long enough to ride out a dropped radio, a reboot or a tunnel
     * being re-established, and still inside the gap before the launcher's own
     * half-hourly update is due. A site that is down for longer than that is
     * not served by a widget polling it harder.
     */
    const val MAX_ATTEMPTS = 6

    /** [attempt] is WorkManager's `runAttemptCount`, zero on the first run. */
    fun shouldRetry(attempt: Int): Boolean = attempt < MAX_ATTEMPTS

    /**
     * Whether another attempt could plausibly produce a reading.
     *
     * A rejected credential, a missing site URL or a cleartext endpoint are
     * all things only the user can change: retrying them spends the budget on
     * an answer that is already known. Everything else — a timeout, an
     * `IOException`, a truncated body — is worth another try, including the
     * failures this does not recognise, where giving up would leave the error
     * on screen for half an hour.
     */
    fun isTransient(e: Throwable): Boolean = when (e) {
        is WidgetApi.MissingTokenException,
        is WidgetApi.RejectedTokenException,
        is WidgetApi.InsecureException,
        is WidgetApi.MissingSiteUrlException,
            -> false
        else -> true
    }
}

/**
 * Re-runs one placed widget, and asks for another attempt until either that
 * widget has data again — which cancels this work — or the budget runs out.
 */
class WidgetRetryWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val appWidgetId = inputData.getInt(WidgetRetry.KEY_APP_WIDGET_ID, -1)
        if (appWidgetId < 0) return Result.success()
        if (!WidgetRetryPolicy.shouldRetry(runAttemptCount)) {
            Log.d(TAG, "Giving up on widget $appWidgetId after $runAttemptCount attempts")
            return Result.success()
        }
        // A widget dragged off the home screen has nothing left to update, and
        // retrying it would only keep this work alive for no one.
        if (!HomeWidget.requestUpdate(applicationContext, appWidgetId)) {
            Log.d(TAG, "Widget $appWidgetId is gone, stopping")
            return Result.success()
        }
        return Result.retry()
    }

    private companion object {
        const val TAG = "WidgetRetry"
    }
}

/**
 * Which widgets have an update in flight, and since when.
 *
 * A plain "in flight" flag is not enough. The update runs in a coroutine on
 * a scope with no lifecycle, and a vendor's process freezer can suspend the
 * process mid-flight — Honor's `SWAP_SCENE` does exactly that the moment a
 * broadcast is delivered. The `finally` that would clear the flag then does
 * not run until the process is unfrozen, and if it is never unfrozen the
 * widget stays marked as updating and every later update is skipped. On
 * screen that is indistinguishable from a widget that never recovers.
 * Recording the start time lets a claim left behind like that expire.
 */
internal class UpdateGuard(private val staleMs: Long) {
    private val started = ConcurrentHashMap<Int, Long>()

    /** True when this caller may update [appWidgetId] now. */
    fun begin(appWidgetId: Int, now: Long): Boolean {
        var acquired = false
        started.compute(appWidgetId) { _, since ->
            // A negative age means the clock moved backwards; treat that as
            // stale rather than as a claim that never expires.
            if (since != null && (now - since) in 0 until staleMs) {
                since
            } else {
                acquired = true
                now
            }
        }
        return acquired
    }

    fun release(appWidgetId: Int) {
        started.remove(appWidgetId)
    }
}
