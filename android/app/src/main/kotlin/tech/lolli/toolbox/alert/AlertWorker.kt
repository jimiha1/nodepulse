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
import org.json.JSONObject
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

        /**
         * Resource rules get their own channel: they are the user's own
         * thresholds rather than the site's traffic/expiry warnings, and
         * "CPU over 80%" is a different kind of noise to mute than "the node
         * expired".
         */
        const val CHANNEL_RESOURCE_ID = "server_resource_alerts"
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
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Server Alerts",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply {
                        description = "Notifications for traffic threshold and server expiration"
                    }
                )
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_RESOURCE_ID,
                        "Resource Alerts",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply {
                        description = "Notifications for custom CPU / memory / disk / network rules"
                    }
                )
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

        // Resource rules are evaluated from history, which is a second request
        // per node and only needed when there is a rule to judge. A failure
        // here is not the run's failure: the traffic and expiry checks above
        // have already been decided and are still worth notifying.
        val resourceAlerts = try {
            checkResourceRules(settings, json, stateMap)
        } catch (e: Exception) {
            Log.w(TAG, "Resource rule check failed: ${e.message}")
            emptyList()
        }

        // Save updated dedup state. Cleared first rather than only written:
        // the evaluator drops a key when a rule stops firing, and writing what
        // is left over the old rows would leave the dropped ones behind.
        val editor = dedupPrefs.edit().clear()
        for ((k, v) in stateMap) {
            editor.putString(k, v)
        }
        editor.apply()

        if (alerts.isNotEmpty() || resourceAlerts.isNotEmpty()) {
            createNotificationChannel(applicationContext)
        }
        for (alert in alerts) {
            notify(
                channelId = CHANNEL_ID,
                notifId = (alert.nodeId + "_" + alert.kind.name).hashCode(),
                title = alert.title,
                text = alert.text,
            )
        }
        for (alert in resourceAlerts) {
            notify(
                channelId = CHANNEL_RESOURCE_ID,
                // Keyed on the rule and the node: two rules on one node are two
                // separate notifications, and the id is stable across runs so a
                // later episode replaces the previous notification rather than
                // stacking beside it.
                notifId = (alert.ruleId + "_" + alert.serverId).hashCode(),
                title = alert.title,
                text = alert.text,
            )
        }

        return Result.success()
    }

    private fun notify(channelId: String, notifId: Int, title: String, text: String) {
        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
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

        val builder = NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        nm.notify(notifId, builder.build())
    }

    /**
     * Runs the user's resource rules over the site's history.
     *
     * Only nodes some enabled rule actually watches are asked for history: the
     * endpoint returns up to a week of rows per node, and a rule that names one
     * node should not cost a request per node.
     */
    private fun checkResourceRules(
        settings: AlertSettings.Settings,
        serversJson: String,
        state: MutableMap<String, String>,
    ): List<ResourceAlertEvaluator.Alert> {
        val allRules = ResourceAlertEvaluator.parseStoredRules(settings.resourceRules)
        // Pruned against every rule, not just the enabled ones: a disabled rule
        // is not a deleted one, and its state is what stops it re-alerting when
        // it is switched back on.
        ResourceAlertEvaluator.pruneState(allRules, state)

        val rules = allRules.filter { it.enabled }
        if (rules.isEmpty()) return emptyList()

        val servers = parseServers(serversJson)
        if (servers.isEmpty()) return emptyList()

        val wanted = servers.filter { server ->
            rules.any { it.serverId == null || it.serverId == server.id }
        }

        // One request per node, covering the longest window any of its rules
        // asks for: three rules over the same 5-minute window are one fetch,
        // and the rows a shorter window does not want are dropped by the
        // evaluator.
        val histories = mutableMapOf<String, List<ResourceAlertEvaluator.Row>>()
        for (server in wanted) {
            val minutes = rules
                .filter { it.serverId == null || it.serverId == server.id }
                .maxOf { it.windowMinutes }
            histories[server.id] = try {
                val body = fetchHistory(
                    siteUrl = settings.siteUrl,
                    token = settings.token,
                    id = server.id,
                    hoursParam = ResourceAlertEvaluator.windowHoursParam(minutes),
                )
                ResourceAlertEvaluator.parseRows(body)
            } catch (e: Exception) {
                // One node's history failing is that node's problem: the other
                // rules still get judged, and this node is skipped this run
                // rather than the whole check being abandoned.
                Log.w(TAG, "History fetch failed for ${server.id}: ${e.message}")
                emptyList()
            }
        }

        return ResourceAlertEvaluator.evaluate(
            rules = rules,
            servers = servers,
            histories = histories,
            state = state,
        )
    }

    /** The nodes the site reports, as the evaluator wants them. */
    private fun parseServers(body: String): List<ResourceAlertEvaluator.Server> {
        val root = try {
            JSONObject(body)
        } catch (_: Exception) {
            return emptyList()
        }
        val array = root.optJSONArray("servers") ?: return emptyList()
        val servers = ArrayList<ResourceAlertEvaluator.Server>(array.length())
        for (i in 0 until array.length()) {
            val o = array.optJSONObject(i) ?: continue
            val id = o.optString("id").takeIf { it.isNotEmpty() } ?: continue
            servers += ResourceAlertEvaluator.Server(
                id = id,
                name = o.optString("name").ifEmpty { id },
            )
        }
        return servers
    }

    private fun fetchHistory(
        siteUrl: String,
        token: String?,
        id: String,
        hoursParam: String,
    ): String {
        val base = siteUrl.trimEnd('/')
        val url = URL("$base/api/history/all?id=$id&hours=$hoursParam")
        if (url.protocol != "https") throw IOException("HTTPS required")

        return try {
            CfHttp.shared.get(
                url = url.toString(),
                userAgent = "ServerBox-Alert/1",
                token = token,
                timeoutMs = TIMEOUT_MS,
            )
        } catch (e: CfHttp.HttpStatusException) {
            if (e.code == 401 || e.code == 403) {
                Log.w(TAG, "Authorization failed with HTTP ${e.code}, skipping history fetch")
                return ""
            }
            throw IOException("HTTP ${e.code}", e)
        }
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
