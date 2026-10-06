package app.nodepulse.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.json.JSONException
import app.nodepulse.MainActivity
import app.nodepulse.R
import java.io.IOException
import java.net.SocketTimeoutException
import kotlin.math.roundToInt

/**
 * The home-screen widget.
 */
abstract class HomeWidget(private val kind: WidgetKind) : AppWidgetProvider() {
    companion object {
        /** Both providers, for the callers that mean "every widget". */
        val providers = listOf(StatusWidgetSmall::class.java, StatusWidgetMedium::class.java)

        /** Asks every placed widget of either size to refresh. */
        fun broadcastUpdate(context: Context) {
            for (provider in providers) {
                context.sendBroadcast(
                    Intent(context, provider).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(
                            AppWidgetManager.EXTRA_APPWIDGET_IDS,
                            AppWidgetManager.getInstance(context)
                                .getAppWidgetIds(ComponentName(context, provider)),
                        )
                    }
                )
            }
        }

        /**
         * Updates one widget, when it still exists.
         *
         * Returns false for an id the system has forgotten — a widget the user
         * dragged off the home screen — so a retry loop can stop rather than
         * keep itself alive for nothing.
         */
        fun requestUpdate(context: Context, appWidgetId: Int): Boolean {
            val widget = when (kindOf(context, appWidgetId)) {
                WidgetKind.SMALL -> StatusWidgetSmall()
                WidgetKind.MEDIUM -> StatusWidgetMedium()
                null -> return false
            }
            widget.update(context, AppWidgetManager.getInstance(context), appWidgetId)
            return true
        }

        /** Which widget an id belongs to, or null when the system has forgotten it. */
        fun kindOf(context: Context, appWidgetId: Int): WidgetKind? {
            val provider = AppWidgetManager.getInstance(context)
                .getAppWidgetInfo(appWidgetId)?.provider?.className ?: return null
            return when (provider) {
                StatusWidgetSmall::class.java.name -> WidgetKind.SMALL
                StatusWidgetMedium::class.java.name -> WidgetKind.MEDIUM
                else -> null
            }
        }

        private const val TAG = "HomeWidget"

        private const val COROUTINE_TIMEOUT = 20_000L

        /**
         * How long an in-flight claim may stand before a later update takes it
         * over. Comfortably past [COROUTINE_TIMEOUT], so a slow-but-alive fetch
         * is never double-run, and short enough that a claim stranded by a
         * frozen process does not outlive the next periodic update.
         */
        private const val UPDATE_CLAIM_STALE_MS = 60_000L

        private val activeUpdates = UpdateGuard(UPDATE_CLAIM_STALE_MS)

        private const val CHART_PADDING_DP = 10f
        private const val CHART_MARGIN_DP = 6f
        private const val CHART_HEADER_SP = 14f

        private const val READINGS_PADDING_DP = 14f
        private const val READINGS_CHART_MARGIN_DP = 6f
        private const val READINGS_HEADER_SP = 13f

        private const val FOOTER_DP = 13f
        private const val HEADER_LINE_RATIO = 1.45f

        /**
         * Where the aging colour gives way to the stale one, as a multiple of
         * the configured threshold.
         *
         * One threshold would only ever say "old"; the second step separates
         * "the last poll missed" from "this node has been gone a while".
         */
        private const val AGING_MULTIPLIER = 4

        /**
         * The colour the header time should use for data of this age.
         *
         * Warning is off entirely under [WidgetExpiry.NEVER], and a missing
         * timestamp has no age to judge — both keep the plain summary colour
         * rather than claiming a freshness the widget cannot know.
         */
        fun resolveTimeColorRes(
            lastUpdated: Long?,
            expiry: WidgetExpiry,
            now: Long = System.currentTimeMillis(),
        ): Int {
            if (lastUpdated == null || lastUpdated <= 0 || expiry == WidgetExpiry.NEVER) {
                return R.color.widgetSummaryText
            }
            // A device clock that moved backwards would otherwise read as stale.
            val ageMs = (now - lastUpdated).coerceAtLeast(0)
            val thresholdMs = expiry.minutes * 60_000L
            return when {
                ageMs <= thresholdMs -> R.color.widgetSummaryText
                ageMs <= AGING_MULTIPLIER * thresholdMs -> R.color.widgetTimeAging
                else -> R.color.widgetTimeStale
            }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) update(context, manager, id)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        update(context, manager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            WidgetConfig.forget(context, id)
            WidgetSnapshot.forget(context, id)
            WidgetRetry.cancel(context, id)
        }
    }

    internal fun update(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        if (!activeUpdates.begin(appWidgetId, System.currentTimeMillis())) {
            Log.d(TAG, "Widget $appWidgetId is already updating, skipping")
            return
        }

        val views = RemoteViews(context.packageName, R.layout.home_widget)

        // Read first: which click target the container gets depends on whether
        // a server has been picked yet.
        val config = WidgetConfig.load(context, appWidgetId, kind)
        val server = config.serverId.takeIf { it.isNotEmpty() }
            ?.let { WidgetStore.server(context, it) }

        // The container's target follows whether a server *resolves*, not
        // whether an id is stored. A widget pointing at a server that has since
        // left the site falls into the same "pick a server" state below as one
        // that was never configured, and its tap has to lead to the same place
        // — otherwise the widget says "tap to pick a server" and then opens the
        // app instead.
        setupClickIntent(context, views, appWidgetId, server?.id)

        if (server == null) {
            showError(context, views, manager, appWidgetId, R.string.widget_err_not_configured)
            activeUpdates.release(appWidgetId)
            return
        }

        val bounds = boundsOf(context, manager, appWidgetId)
        views.setViewPadding(
            R.id.widget_container,
            bounds.paddingPx, bounds.paddingPx, bounds.paddingPx, bounds.paddingPx,
        )
        views.setTextViewTextSize(
            R.id.widget_name,
            TypedValue.COMPLEX_UNIT_SP,
            bounds.headerSp,
        )

        // What this widget last put on screen, redrawn rather than blanked to
        // the loading state: the numbers are still the last thing the node
        // reported, and the header time beside them already says how old they
        // are — its colour follows the configured expiry. A widget with
        // nothing to hold, or one just repointed at another server, still gets
        // the loading state.
        val held = WidgetSnapshot.load(context, appWidgetId, server.id)
        if (held != null) {
            showData(context, views, manager, appWidgetId, config, held.reading, held.history, bounds)
        } else {
            showLoading(context, views, manager, appWidgetId, server.name)
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeoutOrNull(COROUTINE_TIMEOUT) {
                    try {
                        val (reading, history) = WidgetApi.load(context, server)
                        // Data is on screen again: whatever the retry was going
                        // to fix is fixed, and leaving it queued would only put
                        // the widget through a fetch it does not need.
                        WidgetRetry.cancel(context, appWidgetId)
                        WidgetSnapshot.save(
                            context,
                            appWidgetId,
                            WidgetSnapshot.Shown(server.id, reading, history),
                        )
                        withContext(Dispatchers.Main) {
                            showData(context, views, manager, appWidgetId, config, reading, history, bounds)
                        }
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, "Widget $appWidgetId update failed: ${e.message}")
                        val message = when (e) {
                            is WidgetApi.MissingTokenException,
                            is WidgetApi.RejectedTokenException,
                                -> R.string.widget_err_no_token
                            is WidgetApi.InsecureException -> R.string.widget_err_insecure
                            is SocketTimeoutException -> R.string.widget_err_timeout
                            is JSONException -> R.string.widget_err_network
                            is IOException -> R.string.widget_err_network
                            else -> R.string.widget_err_network
                        }
                        // A failure only the user can fix — a rejected
                        // credential — is shown as an error and not retried:
                        // no retry produces a different answer, and keeping
                        // the old numbers up would hide the one thing that
                        // needs doing. A transient one keeps them, and is
                        // retried, because the periodic update is half an hour
                        // away at best and a vendor build may stretch that.
                        val transient = WidgetRetryPolicy.isTransient(e)
                        withContext(Dispatchers.Main) {
                            if (transient) {
                                showHeld(context, views, manager, appWidgetId, config, held, bounds, message, server.name)
                            } else {
                                showError(context, views, manager, appWidgetId, message, server.name)
                            }
                        }
                        if (transient) WidgetRetry.schedule(context, appWidgetId)
                    }
                } ?: run {
                    Log.w(TAG, "Widget $appWidgetId update timed out")
                    withContext(Dispatchers.Main) {
                        showHeld(
                            context, views, manager, appWidgetId, config, held, bounds,
                            R.string.widget_err_timeout, server.name,
                        )
                    }
                    WidgetRetry.schedule(context, appWidgetId)
                }
            } finally {
                activeUpdates.release(appWidgetId)
            }
        }
    }

    /**
     * After a failed fetch: the last reading back on screen when there is one,
     * so the numbers and the time beside them stay together and the age
     * colour carries the warning; the error when there is nothing to hold.
     */
    private fun showHeld(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        config: WidgetConfig,
        held: WidgetSnapshot.Shown?,
        bounds: Bounds,
        messageRes: Int,
        name: String?,
    ) {
        if (held == null) {
            showError(context, views, manager, appWidgetId, messageRes, name)
        } else {
            // Redrawn rather than left alone so the age colour is recomputed
            // now, which is the moment the data became one update older.
            showData(context, views, manager, appWidgetId, config, held.reading, held.history, bounds)
        }
    }

    private data class Bounds(
        val columns: Int,
        val rows: Int,
        val widthPx: Int,
        val heightPx: Int,
        val density: Float,
        val paddingPx: Int,
        val headerSp: Float,
    )

    private fun boundsOf(context: Context, manager: AppWidgetManager, appWidgetId: Int): Bounds {
        val options = manager.getAppWidgetOptions(appWidgetId)
        val portrait = context.resources.configuration.orientation ==
            Configuration.ORIENTATION_PORTRAIT
        val widthKey = if (portrait) {
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
        } else {
            AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
        }
        val heightKey = if (portrait) {
            AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
        } else {
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
        }
        val widthDp = options.getInt(widthKey, 0).takeIf { it > 0 }
            ?: options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
                .takeIf { it > 0 } ?: 110
        val heightDp = options.getInt(heightKey, 0).takeIf { it > 0 }
            ?: options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                .takeIf { it > 0 } ?: 110
        val density = context.resources.displayMetrics.density

        val columns = ((widthDp + 30) / 70).coerceAtLeast(1)
        val rows = ((heightDp + 30) / 70).coerceAtLeast(1)

        val charts = kind.drawsCharts
        val paddingDp = if (charts) CHART_PADDING_DP else READINGS_PADDING_DP
        val headerSp = if (charts) CHART_HEADER_SP else READINGS_HEADER_SP
        val marginDp = if (charts) CHART_MARGIN_DP else READINGS_CHART_MARGIN_DP

        val chartWidthDp = widthDp - paddingDp * 2
        val chartHeightDp =
            heightDp - paddingDp * 2 - headerSp * HEADER_LINE_RATIO - marginDp - FOOTER_DP

        return Bounds(
            columns = columns,
            rows = rows,
            widthPx = (chartWidthDp * density).roundToInt().coerceAtLeast(1),
            heightPx = (chartHeightDp * density).roundToInt().coerceAtLeast(1),
            density = density,
            paddingPx = (paddingDp * density).roundToInt(),
            headerSp = headerSp,
        )
    }

    /**
     * Wires the two ways into the widget.
     *
     * The whole widget opens the app on the server it is showing; the name in
     * the header opens the configuration panel instead. A child view's own
     * click binding overrides the container's, which is what keeps the two
     * apart — the refresh icon relies on the same thing.
     *
     * [serverId] null means no server resolves for this widget — nothing picked
     * yet, or a pick that has since left the site. There is no server page to
     * open, so the whole widget falls back to the configuration panel, the only
     * useful thing to do in that state.
     */
    private fun setupClickIntent(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int,
        serverId: String?,
    ) {
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val configure = Intent(context, WidgetConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = android.net.Uri.parse("sbm://widget/$appWidgetId")
        }
        views.setOnClickPendingIntent(
            R.id.widget_name,
            PendingIntent.getActivity(context, appWidgetId, configure, flag),
        )

        if (serverId == null) {
            // The name's own target, reached by tapping anywhere: a widget with
            // no server has no page to open.
            views.setOnClickPendingIntent(
                R.id.widget_container,
                PendingIntent.getActivity(context, appWidgetId, configure, flag),
            )
        } else {
            // A request code of its own so this is never the same
            // PendingIntent as the one above: FLAG_UPDATE_CURRENT rewrites the
            // extras of whichever it is asked for, and sharing one would let
            // the two targets overwrite each other.
            val open = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse("serverbox://server/$serverId")
                // The widget lives on the home screen, so the app is launched
                // from outside its own task; SINGLE_TOP then routes a second
                // tap into onNewIntent instead of stacking another copy.
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_container,
                PendingIntent.getActivity(context, appWidgetId + 1, open, flag),
            )
        }

        val refresh = Intent(context, javaClass).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            data = android.net.Uri.parse("sbm://widget/refresh/$appWidgetId")
        }
        views.setOnClickPendingIntent(
            R.id.widget_refresh,
            PendingIntent.getBroadcast(context, appWidgetId, refresh, flag),
        )
    }

    // MARK: - States

    private fun showLoading(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        name: String,
    ) {
        views.setTextViewText(R.id.widget_name, name)
        showTime(context, views, null, WidgetExpiry.NEVER, loading = true)
        views.setViewVisibility(R.id.error_message, View.GONE)
        manager.updateAppWidget(appWidgetId, views)
    }

    /**
     * The header time slot, which only the 4x2 widget uses.
     *
     * Every branch sets the visibility explicitly: RemoteViews applies its
     * actions to a view tree that outlives them, so a slot hidden once — by
     * [showError], before a new widget is configured — stays hidden until
     * something sets it back.
     *
     * [lastUpdated] of null renders `--`, except while [loading], which shows
     * `…` — the reading is not in yet, and that is not the same as a node
     * that reported no timestamp.
     */
    private fun showTime(
        context: Context,
        views: RemoteViews,
        lastUpdated: Long?,
        expiry: WidgetExpiry,
        loading: Boolean = false,
    ) {
        if (kind != WidgetKind.MEDIUM) {
            views.setViewVisibility(R.id.widget_time, View.GONE)
            return
        }
        views.setViewVisibility(R.id.widget_time, View.VISIBLE)
        val text = when {
            loading -> "…"
            lastUpdated == null || lastUpdated <= 0 -> "--"
            else -> android.text.format.DateFormat
                .format("HH:mm", java.util.Date(lastUpdated))
                .toString()
        }
        views.setTextViewText(R.id.widget_time, text)
        views.setTextColor(
            R.id.widget_time,
            ContextCompat.getColor(context, resolveTimeColorRes(lastUpdated, expiry)),
        )
    }

    private fun showData(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        config: WidgetConfig,
        reading: WidgetApi.Reading,
        history: List<WidgetApi.HistoryPoint>,
        bounds: Bounds,
    ) {
        views.setTextViewText(R.id.widget_name, reading.name)
        showTime(context, views, reading.lastUpdated, config.expiry)
        views.setViewVisibility(R.id.error_message, View.GONE)

        if (kind == WidgetKind.SMALL) {
            // SMALL: up to 4 fields
            views.setViewVisibility(R.id.widget_charts_container, View.GONE)
            views.setViewVisibility(R.id.widget_content, View.VISIBLE)
            showFieldCapsules(context, views, config.fields.take(WidgetConfig.CAP_SMALL_FIELDS), reading)
        } else {
            // MEDIUM: 3 modes (CHART, READING, COMBINED)
            when (config.mode) {
                MediumMode.CHART -> {
                    views.setViewVisibility(R.id.widget_content, View.GONE)
                    views.setViewVisibility(R.id.widget_charts_container, View.VISIBLE)

                    val count = config.chartCount
                    val charts = listOf(config.chart, config.chart2, config.chart3, config.chart4).take(count)

                    when (count) {
                        1 -> {
                            views.setViewVisibility(R.id.widget_chart_row_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_2, View.GONE)
                            views.setViewVisibility(R.id.widget_chart_row_2, View.GONE)

                            val s = listOf(seriesForNamedMetric(context, charts[0], reading, history))
                            val b = WidgetChart.render(context, s, bounds.widthPx, bounds.heightPx, bounds.density)
                            if (b != null) views.setImageViewBitmap(R.id.widget_chart_1, b)
                        }
                        2 -> {
                            views.setViewVisibility(R.id.widget_chart_row_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_2, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_row_2, View.GONE)

                            val halfW = ((bounds.widthPx - 8 * bounds.density) / 2).toInt().coerceAtLeast(1)
                            val s1 = listOf(seriesForNamedMetric(context, charts[0], reading, history))
                            val b1 = WidgetChart.render(context, s1, halfW, bounds.heightPx, bounds.density)
                            if (b1 != null) views.setImageViewBitmap(R.id.widget_chart_1, b1)

                            val s2 = listOf(seriesForNamedMetric(context, charts[1], reading, history))
                            val b2 = WidgetChart.render(context, s2, halfW, bounds.heightPx, bounds.density)
                            if (b2 != null) views.setImageViewBitmap(R.id.widget_chart_2, b2)
                        }
                        4 -> {
                            views.setViewVisibility(R.id.widget_chart_row_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_2, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_row_2, View.VISIBLE)

                            val halfW = ((bounds.widthPx - 8 * bounds.density) / 2).toInt().coerceAtLeast(1)
                            val halfH = ((bounds.heightPx - 8 * bounds.density) / 2).toInt().coerceAtLeast(1)

                            val s1 = listOf(seriesForNamedMetric(context, charts[0], reading, history))
                            val b1 = WidgetChart.render(context, s1, halfW, halfH, bounds.density)
                            if (b1 != null) views.setImageViewBitmap(R.id.widget_chart_1, b1)

                            val s2 = listOf(seriesForNamedMetric(context, charts[1], reading, history))
                            val b2 = WidgetChart.render(context, s2, halfW, halfH, bounds.density)
                            if (b2 != null) views.setImageViewBitmap(R.id.widget_chart_2, b2)

                            val s3 = listOf(seriesForNamedMetric(context, charts[2], reading, history))
                            val b3 = WidgetChart.render(context, s3, halfW, halfH, bounds.density)
                            if (b3 != null) views.setImageViewBitmap(R.id.widget_chart_3, b3)

                            val s4 = listOf(seriesForNamedMetric(context, charts[3], reading, history))
                            val b4 = WidgetChart.render(context, s4, halfW, halfH, bounds.density)
                            if (b4 != null) views.setImageViewBitmap(R.id.widget_chart_4, b4)
                        }
                        else -> {
                            // Default 1 chart fallback
                            views.setViewVisibility(R.id.widget_chart_row_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_1, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_chart_2, View.GONE)
                            views.setViewVisibility(R.id.widget_chart_row_2, View.GONE)
                            val s = listOf(seriesForNamedMetric(context, charts[0], reading, history))
                            val b = WidgetChart.render(context, s, bounds.widthPx, bounds.heightPx, bounds.density)
                            if (b != null) views.setImageViewBitmap(R.id.widget_chart_1, b)
                        }
                    }
                }
                MediumMode.READING -> {
                    views.setViewVisibility(R.id.widget_charts_container, View.GONE)
                    views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                    showFieldCapsules(context, views, config.fields.take(WidgetConfig.CAP_MEDIUM_READING_FIELDS), reading)
                }
                MediumMode.COMBINED -> {
                    views.setViewVisibility(R.id.widget_charts_container, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_chart_row_1, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_chart_1, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_chart_2, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_chart_row_2, View.GONE)
                    views.setViewVisibility(R.id.widget_content, View.VISIBLE)

                    // Render mini charts side by side
                    val halfWidth = ((bounds.widthPx - 8 * bounds.density) / 2).toInt().coerceAtLeast(1)
                    val chartHeight = (bounds.heightPx * 0.48f).roundToInt().coerceAtLeast(1)

                    val s1 = listOf(seriesForNamedMetric(context, config.chart, reading, history))
                    val b1 = WidgetChart.render(context, s1, halfWidth, chartHeight, bounds.density)
                    if (b1 != null) views.setImageViewBitmap(R.id.widget_chart_1, b1)

                    val s2 = listOf(seriesForNamedMetric(context, config.chart2, reading, history))
                    val b2 = WidgetChart.render(context, s2, halfWidth, chartHeight, bounds.density)
                    if (b2 != null) views.setImageViewBitmap(R.id.widget_chart_2, b2)

                    showFieldCapsules(context, views, config.fields.take(WidgetConfig.CAP_COMBINED_FIELDS), reading)
                }
            }
        }
        manager.updateAppWidget(appWidgetId, views)
    }

    private val cellRowLayoutIds = listOf(
        R.id.widget_cell_row_1,
        R.id.widget_cell_row_2,
        R.id.widget_cell_row_3,
        R.id.widget_cell_row_4,
    )

    private val cellLayoutIds = listOf(
        R.id.widget_cell_1,
        R.id.widget_cell_2,
        R.id.widget_cell_3,
        R.id.widget_cell_4,
        R.id.widget_cell_5,
        R.id.widget_cell_6,
        R.id.widget_cell_7,
        R.id.widget_cell_8,
    )
    private val cellLabelIds = listOf(
        R.id.widget_cell_1_label,
        R.id.widget_cell_2_label,
        R.id.widget_cell_3_label,
        R.id.widget_cell_4_label,
        R.id.widget_cell_5_label,
        R.id.widget_cell_6_label,
        R.id.widget_cell_7_label,
        R.id.widget_cell_8_label,
    )
    private val cellValueIds = listOf(
        R.id.widget_cell_1_value,
        R.id.widget_cell_2_value,
        R.id.widget_cell_3_value,
        R.id.widget_cell_4_value,
        R.id.widget_cell_5_value,
        R.id.widget_cell_6_value,
        R.id.widget_cell_7_value,
        R.id.widget_cell_8_value,
    )

    private fun showFieldCapsules(
        context: Context,
        views: RemoteViews,
        fields: List<WidgetField>,
        reading: WidgetApi.Reading,
    ) {
        val totalCells = minOf(fields.size, 8)
        val neededRows = (totalCells + 1) / 2

        for (r in 0 until 4) {
            val rowId = cellRowLayoutIds[r]
            if (r < neededRows) {
                views.setViewVisibility(rowId, View.VISIBLE)
            } else {
                views.setViewVisibility(rowId, View.GONE)
            }
        }

        for (i in 0 until 8) {
            val cellId = cellLayoutIds[i]
            val labelId = cellLabelIds[i]
            val valueId = cellValueIds[i]
            if (i < totalCells) {
                val field = fields[i]
                views.setTextViewText(labelId, fieldShortLabel(context, field))
                views.setTextViewText(valueId, fieldValueText(field, reading))
                views.setViewVisibility(cellId, View.VISIBLE)
            } else {
                views.setViewVisibility(cellId, View.GONE)
            }
        }
    }

    private fun fieldShortLabel(context: Context, field: WidgetField): String = when (field) {
        WidgetField.CPU -> "CPU"
        WidgetField.MEM -> "Mem"
        WidgetField.DISK -> "Disk"
        WidgetField.LOAD -> "Load"
        WidgetField.NET_SPEED -> "Net"
        WidgetField.NET_TOTAL -> "Total"
        WidgetField.TRAFFIC_LEFT -> "Quota"
        WidgetField.CONN -> "Conn"
        WidgetField.PING -> "Ping"
        WidgetField.LOSS -> "丢包"
        WidgetField.UPTIME -> "Uptime"
        WidgetField.EXPIRE -> "Expire"
    }

    private fun fieldValueText(field: WidgetField, reading: WidgetApi.Reading): String = when (field) {
        WidgetField.CPU -> percentText(reading.cpu)
        WidgetField.MEM -> percentText(reading.mem)
        WidgetField.DISK -> percentText(reading.disk)
        WidgetField.LOAD -> reading.loadText
        WidgetField.NET_SPEED -> shortNet(reading.netText)
        WidgetField.NET_TOTAL -> reading.netTotalText
        WidgetField.TRAFFIC_LEFT -> reading.trafficLeftText
        WidgetField.CONN -> reading.connText
        WidgetField.PING -> reading.pingText
        WidgetField.LOSS -> reading.lossText
        WidgetField.UPTIME -> reading.uptimeText
        WidgetField.EXPIRE -> reading.expireText
    }

    private fun shortNet(netText: String): String =
        netText.replace(" / ", "/").replace(Regex("\\.[0-9]"), "")

    private fun showError(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        messageRes: Int,
        name: String? = null,
    ) {
        views.setTextViewText(R.id.widget_name, name ?: context.getString(R.string.app_name))
        views.setTextViewText(R.id.error_message, context.getString(messageRes))
        views.setViewVisibility(R.id.error_message, View.VISIBLE)
        views.setViewVisibility(R.id.widget_content, View.GONE)
        views.setViewVisibility(R.id.widget_charts_container, View.GONE)
        views.setViewVisibility(R.id.widget_time, View.GONE)
        manager.updateAppWidget(appWidgetId, views)
    }

    // MARK: - Reading a metric

    private fun percentText(value: Double?): String =
        value?.let { String.format(java.util.Locale.US, "%.0f%%", it) } ?: "--"

    private fun seriesForNamedMetric(
        context: Context,
        metric: String,
        reading: WidgetApi.Reading,
        history: List<WidgetApi.HistoryPoint>,
    ): WidgetChart.Series = when (metric) {
        "cpu" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_cpu),
            values = history.map { it.cpu },
            secondary = emptyList(),
            isPercent = true,
            valueText = percentText(reading.cpu),
            valueShort = percentText(reading.cpu),
            color = Color.parseColor("#34C759"),
        )
        "mem" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_memory),
            values = history.map { it.memory },
            secondary = emptyList(),
            isPercent = true,
            valueText = percentText(reading.mem),
            valueShort = percentText(reading.mem),
            color = Color.parseColor("#0A84FF"),
        )
        "disk" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_disk),
            values = history.map { it.disk },
            secondary = emptyList(),
            isPercent = true,
            valueText = percentText(reading.disk),
            valueShort = percentText(reading.disk),
            color = Color.parseColor("#FF9F0A"),
        )
        "net" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_network),
            values = history.map { it.netRx },
            secondary = history.map { it.netTx },
            isPercent = false,
            valueText = reading.netText,
            valueShort = shortNet(reading.netText),
            color = Color.parseColor("#BF5AF2"),
        )
        "load" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_load),
            values = history.map { it.load },
            secondary = emptyList(),
            isPercent = false,
            valueText = reading.loadText,
            valueShort = String.format(java.util.Locale.US, "%.1f", reading.load1),
            color = Color.parseColor("#FF375F"),
        )
        "io" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_io),
            values = history.map { it.io },
            secondary = emptyList(),
            isPercent = false,
            valueText = reading.diskIoText,
            valueShort = reading.diskIoText,
            color = Color.parseColor("#64D2FF"),
        )
        "conn" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_conn),
            values = history.map { it.conn },
            secondary = emptyList(),
            isPercent = false,
            valueText = reading.connText,
            valueShort = reading.connText,
            color = Color.parseColor("#5E5CE6"),
        )
        "proc" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_proc),
            values = history.map { it.proc },
            secondary = emptyList(),
            isPercent = false,
            valueText = reading.procText,
            valueShort = reading.procText,
            color = Color.parseColor("#FFD60A"),
        )
        "loss" -> WidgetChart.Series(
            label = context.getString(R.string.widget_metric_loss),
            values = history.map { it.loss },
            secondary = emptyList(),
            isPercent = true,
            valueText = reading.lossText,
            valueShort = reading.avgLoss?.let { String.format(java.util.Locale.US, "%.0f%%", it) } ?: "--",
            color = Color.parseColor("#FF453A"),
        )
        else -> WidgetChart.Series(
            label = metric.uppercase(),
            values = history.map { it.cpu },
            secondary = emptyList(),
            isPercent = true,
            valueText = "--",
            valueShort = "--",
            color = Color.GRAY,
        )
    }
}

/** 2x2, readings as text. */
class StatusWidgetSmall : HomeWidget(WidgetKind.SMALL)

/** 4x2, charts. */
class StatusWidgetMedium : HomeWidget(WidgetKind.MEDIUM)
