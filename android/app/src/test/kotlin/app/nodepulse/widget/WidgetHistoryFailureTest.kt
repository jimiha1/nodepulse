package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * What a widget does when the history half of a refresh fails but the reading
 * half succeeds.
 *
 * That split is what the "暂无历史" report was. The reading and the history are
 * two separate requests, the history one is the slow one, and its failure used
 * to be swallowed into an empty list — which read as "this node has no
 * history", replaced whatever chart was already on screen, and cancelled the
 * retry that would have brought it back.
 */
class WidgetHistoryFailureTest {

    private fun points(vararg cpu: Double) = cpu.map {
        WidgetApi.HistoryPoint(cpu = it, memory = 0.0, disk = 0.0, netRx = 0.0, netTx = 0.0)
    }

    @Test
    fun aFailedHistoryLeavesTheChartShowingWhatItHad() {
        // The whole point: a slow history request must not blank a chart that
        // is already drawn. Those points are the last thing the node reported
        // and are still the best answer on screen.
        val held = points(1.0, 2.0, 3.0)
        val plan = WidgetRefresh.plan(
            fetched = emptyList(),
            failed = true,
            held = held,
        )
        assertEquals(held, plan.history)
    }

    @Test
    fun aFailedHistoryAsksForAnotherAttempt() {
        // Nothing else will retry: the launcher's own update is half an hour
        // away at best, and on this device's vendor build much further.
        val plan = WidgetRefresh.plan(
            fetched = emptyList(),
            failed = true,
            held = points(1.0, 2.0),
        )
        assertTrue(plan.retry)
    }

    @Test
    fun aFirstEverFailureRetriesWithNothingToShow() {
        // No chart to keep, so the widget draws the empty state — but the
        // fetch that would fill it is still owed.
        val plan = WidgetRefresh.plan(
            fetched = emptyList(),
            failed = true,
            held = emptyList(),
        )
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), plan.history)
        assertTrue(plan.retry)
    }

    @Test
    fun aSuccessfulHistoryReplacesWhatWasOnScreen() {
        val fetched = points(9.0, 8.0)
        val plan = WidgetRefresh.plan(
            fetched = fetched,
            failed = false,
            held = points(1.0, 2.0, 3.0),
        )
        assertEquals(fetched, plan.history)
    }

    @Test
    fun aSuccessfulHistoryNeedsNoRetry() {
        val plan = WidgetRefresh.plan(
            fetched = points(9.0),
            failed = false,
            held = points(1.0),
        )
        assertFalse(plan.retry)
    }

    @Test
    fun aSuccessfulButEmptyHistoryIsTakenAsTheAnswer() {
        // A site with history turned off answers with an empty array, and that
        // is an answer rather than a failure. Retrying it would poll forever
        // for something that is not coming, and holding the old points would
        // show a chart the site has stopped producing.
        val plan = WidgetRefresh.plan(
            fetched = emptyList(),
            failed = false,
            held = points(1.0, 2.0),
        )
        assertEquals(emptyList<WidgetApi.HistoryPoint>(), plan.history)
        assertFalse(plan.retry)
    }

    @Test
    fun theUpdateBudgetOutlastsBothRequests() {
        // The two requests run in sequence inside one `withTimeoutOrNull`, so a
        // budget that is not larger than their sum can only ever fire while the
        // history request is still legitimately in flight — which is the
        // failure this whole change is about, arriving from the other side.
        val bothRequests =
            WidgetApi.SERVERS_TIMEOUT_MS + WidgetApi.HISTORY_TIMEOUT_MS
        assertTrue(
            "coroutine budget $bothRequests must fit inside ${HomeWidget.COROUTINE_TIMEOUT}",
            HomeWidget.COROUTINE_TIMEOUT > bothRequests,
        )
    }

    @Test
    fun aStrandedClaimStillExpiresWellBeforeTheNextUpdate() {
        // Raising the budget must not raise this past the launcher's own
        // half-hourly tick, or a process frozen mid-update would stay wedged
        // into the next one.
        assertTrue(HomeWidget.UPDATE_CLAIM_STALE_MS > HomeWidget.COROUTINE_TIMEOUT)
        assertTrue(HomeWidget.UPDATE_CLAIM_STALE_MS < 30 * 60 * 1000L)
    }
}
