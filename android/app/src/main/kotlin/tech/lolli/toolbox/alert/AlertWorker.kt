package tech.lolli.toolbox.alert

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import tech.lolli.toolbox.MainActivity
import tech.lolli.toolbox.cf.CfHttp
import java.io.IOException
import java.net.URL
import java.util.concurrent.TimeUnit

class AlertWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        private const val TAG = "AlertWorker"
        const val WORK_NAME = "tech.lolli.toolbox.alert.AlertWorker"
        const val CHANNEL_ID = "server_alerts"
        private const val PREFS_DEDUP = "sbm_alerts_dedup"
        private const val TIMEOUT_MS = 15_000

        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<AlertWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
            Log.i(TAG, "AlertWorker scheduled (UPDATE, 15 min)")
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.i(TAG, "AlertWorker cancelled")
        }

        fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val name = "Server Alerts"
                val descriptionText = "Notifications for traffic threshold and server expiration"
                val importance = NotificationManager.IMPORTANCE_DEFAULT
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                }
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    override suspend fun doWork(): Result {
        val settings = AlertSettings.load(applicationContext)
        if (!settings.enabled || settings.siteUrl.isEmpty()) {
            return Result.success()
        }

        val json = try {
            fetchServers(settings.siteUrl, settings.token)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to fetch servers for alert check: ${e.message}")
            return Result.retry()
        }

        if (json.isEmpty()) return Result.success()

        val dedupPrefs = applicationContext.getSharedPreferences(PREFS_DEDUP, Context.MODE_PRIVATE)
        val stateMap = mutableMapOf<String, String>()
        for ((k, v) in dedupPrefs.all) {
            if (v != null) stateMap[k] = v.toString()
        }

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = settings.trafficPct,
            expiryDays = settings.expiryDays,
            state = stateMap,
        )

        // Save updated dedup state
        val editor = dedupPrefs.edit()
        for ((k, v) in stateMap) {
            editor.putString(k, v)
        }
        editor.apply()

        if (alerts.isNotEmpty()) {
            createNotificationChannel(applicationContext)
            val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            for (alert in alerts) {
                val notifId = (alert.nodeId + "_" + alert.kind.name).hashCode()
                val intent = Intent(applicationContext, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    applicationContext,
                    notifId,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
                )

                // Use android's standard ic_dialog_alert or app icon
                val smallIcon = applicationContext.applicationInfo.icon

                val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
                    .setSmallIcon(smallIcon)
                    .setContentTitle(alert.title)
                    .setContentText(alert.text)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(alert.text))
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)

                nm.notify(notifId, builder.build())
            }
        }

        return Result.success()
    }

    private fun fetchServers(siteUrl: String, token: String?): String {
        val base = siteUrl.trimEnd('/')
        val url = URL("$base/api/servers")
        if (url.protocol != "https") throw IOException("HTTPS required")

        // See [WidgetApi.get]: the address has to come from DoH, because the
        // platform resolver is what a tampered network rewrites.
        return try {
            CfHttp.shared.get(
                url = url.toString(),
                userAgent = "ServerBox-Alert/1",
                token = token,
                timeoutMs = TIMEOUT_MS,
            )
        } catch (e: CfHttp.HttpStatusException) {
            if (e.code == 401 || e.code == 403) {
                Log.w(TAG, "Authorization failed with HTTP ${e.code}, skipping alert check")
                return ""
            }
            throw IOException("HTTP ${e.code}", e)
        }
    }
}
