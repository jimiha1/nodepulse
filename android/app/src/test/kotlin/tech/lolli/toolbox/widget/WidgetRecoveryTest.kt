package tech.lolli.toolbox.widget

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.json.JSONException
import java.io.IOException
import java.net.SocketTimeoutException

/**
 * The two pieces that decide whether a failed widget can get itself back to
 * showing data: the in-flight claim, and the retry budget.
 *
 * Both are plain logic on purpose — the Android runtime they run under has no
 * test harness in this module, and the behaviour worth pinning down is the
 * arithmetic, not the plumbing.
 */
class WidgetRecoveryTest {

    // MARK: - UpdateGuard

    @Test
    fun aSecondUpdateIsRefusedWhileTheFirstIsInFlight() {
        val guard = UpdateGuard(staleMs = 60_000)
        assertTrue(guard.begin(7, now = 1_000))
        assertFalse(guard.begin(7, now = 1_100))
        assertFalse(guard.begin(7, now = 2_000))
    }

    @Test
    fun theClaimExpiresSoAFrozenUpdateCannotWedgeTheWidget() {
        // The failure this exists for: the process is frozen mid-update, the
        // `finally` that releases the claim never runs, and every later update
        // is skipped — which on screen is a widget that never recovers.
        val guard = UpdateGuard(staleMs = 60_000)
        assertTrue(guard.begin(7, now = 1_000))
        assertFalse(guard.begin(7, now = 60_999))
        assertTrue(guard.begin(7, now = 61_000))
    }

    @Test
    fun aReleasedClaimIsImmediatelyAvailableAgain() {
        val guard = UpdateGuard(staleMs = 60_000)
        assertTrue(guard.begin(7, now = 1_000))
        guard.release(7)
        assertTrue(guard.begin(7, now = 1_001))
    }

    @Test
    fun claimsAreTrackedPerWidget() {
        val guard = UpdateGuard(staleMs = 60_000)
        assertTrue(guard.begin(7, now = 1_000))
        assertTrue(guard.begin(8, now = 1_000))
        assertFalse(guard.begin(7, now = 1_000))
    }

    @Test
    fun aBackwardsClockDoesNotBlockForever() {
        // A device clock that jumped back would otherwise read as "just
        // started" for as long as the skew lasts.
        val guard = UpdateGuard(staleMs = 60_000)
        assertTrue(guard.begin(7, now = 100_000))
        assertTrue(guard.begin(7, now = 1_000))
    }

    // MARK: - Retry budget

    @Test
    fun retriesRunOutAfterTheBudget() {
        assertTrue(WidgetRetryPolicy.shouldRetry(0))
        assertTrue(WidgetRetryPolicy.shouldRetry(WidgetRetryPolicy.MAX_ATTEMPTS - 1))
        assertFalse(WidgetRetryPolicy.shouldRetry(WidgetRetryPolicy.MAX_ATTEMPTS))
        assertFalse(WidgetRetryPolicy.shouldRetry(WidgetRetryPolicy.MAX_ATTEMPTS + 3))
    }

    @Test
    fun transientFailuresAreWorthRetrying() {
        assertTrue(WidgetRetryPolicy.isTransient(SocketTimeoutException("read timed out")))
        assertTrue(WidgetRetryPolicy.isTransient(IOException("HTTP 502")))
        assertTrue(WidgetRetryPolicy.isTransient(JSONException("unexpected end of input")))
        // Unrecognised is retried: an unknown failure that is not retried is
        // an error left on screen for half an hour.
        assertTrue(WidgetRetryPolicy.isTransient(IllegalStateException("who knows")))
    }

    @Test
    fun failuresOnlyTheUserCanFixDoNotSpendTheBudget() {
        assertFalse(WidgetRetryPolicy.isTransient(WidgetApi.MissingTokenException()))
        assertFalse(WidgetRetryPolicy.isTransient(WidgetApi.RejectedTokenException()))
        assertFalse(WidgetRetryPolicy.isTransient(WidgetApi.InsecureException()))
        assertFalse(WidgetRetryPolicy.isTransient(WidgetApi.MissingSiteUrlException()))
    }

    @Test
    fun eachWidgetGetsItsOwnRetry() {
        // One widget recovering must not cancel its neighbour's pending retry:
        // they can be pointed at different nodes, and one coming back says
        // nothing about the other.
        val a = WidgetRetry.workName(4999)
        val b = WidgetRetry.workName(5014)
        assertFalse(a == b)
        assertTrue(a.contains("4999"))
        assertTrue(b.contains("5014"))
    }
}
