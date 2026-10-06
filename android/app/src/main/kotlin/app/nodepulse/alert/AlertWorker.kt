package app.nodepulse.alert

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
import app.nodepulse.MainActivity
import app.nodepulse.cf.CfHttp
import java.io.IOException
import java.net.URL
import java.util.concurrent.TimeUnit

class AlertWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    /**
     * What one check ended in, so a caller can say something about it.
     *
     * [reason] is a short code, not a sentence: the strings a user reads
     * live in the Dart l10n files, and a message built here would be the
     * one piece of this app that could not be translated.
     */
    sealed interface CheckOutcome {
        val checked: Int

        /**
         * [suppressed] is the alerts that qualified but were held back as
         * already announced, as `title to text` pairs — the content the user
         * would have received. Empty for a check that had nothing held back,
         * and always empty for the periodic worker, which does not collect
         * them: only the "check now" button has anyone to tell.
         *
         * Traffic and expiry only. A resource rule that is still in the state
         * it alerted in reports nothing here, because its dedup is an edge
         * rather than a day — see [ResourceAlertEvaluator].
         */
        data class Done(
            override val checked: Int,
            val notified: Int,
            val suppressed: List<Pair<String, String>> = emptyList(),
        ) : CheckOutcome

        data class Failed(val reason: String) : CheckOutcome {
            override val checked: Int = 0
        }
    }

    override suspend fun doWork(): Result {
        val settings = AlertSettings.load(applicationContext)
        if (!settings.enabled || settings.siteUrl.isEmpty()) {
            return Result.success()
        }

        // Only a network failure is worth another attempt. A rejected
        // credential and a missing one are both answers a retry cannot change
        // — the token comes from the app, and no amount of asking again mints
        // one — so those end the run quietly rather than spending the battery
        // of a retry loop that cannot succeed.
        return retryPolicy(runCheck(applicationContext, settings))
    }

    companion object {
        private const val TAG = "AlertWorker"
        const val WORK_NAME = "app.nodepulse.alert.AlertWorker"
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

        /**
         * What [doWork] answers for one outcome.
         *
         * Split out from the run so the rule can be tested: it is a decision
         * about battery, and the difference between "retry" and "give up" is
         * invisible in a log until it has already cost something.
         */
        internal fun retryPolicy(outcome: CheckOutcome): Result =
            if (outcome is CheckOutcome.Failed && outcome.reason == REASON_NETWORK) {
                Result.retry()
            } else {
                Result.success()
            }

        /**
         * Why an empty fetch answer should be reported as it is.
         *
         * Split out from the run for the same reason [retryPolicy] is: it is a
         * decision about what the user is told, and the difference between
         * "log in" and "the site refused you" is not visible from the body.
         *
         * Null when there is nothing wrong — an empty body from a site that
         * answered is not a failure to report, it is a site with no nodes.
         */
        internal fun refusalReason(body: String, hasToken: Boolean): String? {
            if (body.isNotEmpty()) return null
            return if (hasToken) REASON_AUTH else REASON_NO_TOKEN
        }

        /**
         * The failure codes [CheckOutcome.Failed] carries, and the ones the
         * Dart side maps back to a sentence. Kept as constants because the
         * mapping lives in another language, where a typo would be silent.
         */
        const val REASON_NO_SITE = "no_site"
        const val REASON_NO_TOKEN = "no_token"
        const val REASON_AUTH = "auth"
        const val REASON_NETWORK = "network"

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

        /**
         * Runs the same check [doWork] runs, for the settings page's "check
         * now" button: a periodic worker can be up to fifteen minutes away,
         * and a user who just set a threshold has no way to tell a working
         * configuration from one that will never fire.
         *
         * Returns what happened rather than throwing, because the button
         * reports it and a silent failure is exactly the problem this exists
         * to fix. Nothing here is retried: the caller is a person, and they
         * can press it again.
         *
         * Unlike the worker it collects the alerts the dedup state held back:
         * pressing the button twice is meant to explain itself, and "already
         * sent today" is not the same answer as "nothing to send".
         */
        suspend fun runCheck(context: Context, settings: AlertSettings.Settings): CheckOutcome {
            if (settings.siteUrl.isEmpty()) return CheckOutcome.Failed(REASON_NO_SITE)

            val json = try {
                fetchServers(settings.siteUrl, settings.token)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to fetch servers for alert check: ${e.message}")
                return CheckOutcome.Failed(REASON_NETWORK)
            }

            // An empty answer is the site refusing the credential: fetchServers
            // turns 401/403 into "" rather than throwing. Which sentence that
            // deserves depends on whether there was a credential to refuse —
            // a site that needs no login has none, and telling that user to log
            // in would send them after a setting they do not need.
            //
            // Deliberately not guarded before the fetch: refusing to read a
            // site without a token would leave every public site with a check
            // that never runs.
            refusalReason(json, hasToken = !settings.token.isNullOrEmpty())
                ?.let { return CheckOutcome.Failed(it) }

            val dedupPrefs = context.getSharedPreferences(PREFS_DEDUP, Context.MODE_PRIVATE)
            val stateMap = mutableMapOf<String, String>()
            for ((k, v) in dedupPrefs.all) {
                if (v != null) stateMap[k] = v.toString()
            }

            val suppressed = mutableListOf<CfAlertParser.Suppressed>()
            val alerts = CfAlertParser.check(
                json = json,
                trafficThresholdPct = settings.trafficPct,
                expiryDays = settings.expiryDays,
                state = stateMap,
                suppressed = suppressed,
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
                createNotificationChannel(context)
            }
            for (alert in alerts) {
                notify(
                    context = context,
                    channelId = CHANNEL_ID,
                    notifId = (alert.nodeId + "_" + alert.kind.name).hashCode(),
                    title = alert.title,
                    text = alert.text,
                )
            }
            for (alert in resourceAlerts) {
                notify(
                    context = context,
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

            return CheckOutcome.Done(
                checked = nodeCount(json),
                // Both kinds count: the button reports what the user would
                // have received, and a resource rule is a notification too.
                notified = alerts.size + resourceAlerts.size,
                suppressed = suppressed.map { it.alert.title to it.alert.text },
            )
        }

        /**
         * How many nodes the answer carried, for the report. Not the alert
         * count: "checked 3, nothing to alert" is the reassuring answer a
         * user wants after setting a threshold, and zero alerts alone cannot
         * tell it apart from a check that read nothing.
         *
         * Internal rather than private so the unit tests can reach it: it is
         * pure, and it is the one number the settings page shows back.
         */
        internal fun nodeCount(json: String): Int = try {
            JSONObject(json).optJSONArray("servers")?.length() ?: 0
        } catch (_: Exception) {
            0
        }

        private fun notify(
            context: Context,
            channelId: String,
            notifId: Int,
            title: String,
            text: String,
        ) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                notifId,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )

            // Use android's standard ic_dialog_alert or app icon
            val smallIcon = context.applicationInfo.icon

            val builder = NotificationCompat.Builder(context, channelId)
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
                    userAgent = "NodePulse-Alert/1",
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
                    userAgent = "NodePulse-Alert/1",
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
}
