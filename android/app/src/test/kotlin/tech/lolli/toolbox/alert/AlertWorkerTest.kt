package tech.lolli.toolbox.alert

import androidx.work.ListenableWorker.Result
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The one piece of [AlertWorker] a JVM test can reach.
 *
 * `runCheck` needs a `Context` and this module has no Robolectric, so what is
 * covered here is the count it reports back. That count is not decoration: it
 * is the difference between "checked 3 nodes, nothing to alert" and "checked
 * 0 nodes", and the second reads as a check that silently did nothing.
 */
class AlertWorkerTest {

    @Test
    fun countsEveryServerInTheAnswer() {
        val json = """
        {
          "servers": [
            {"id": "a", "name": "Osaka"},
            {"id": "b", "name": "LAX"},
            {"id": "c", "name": "Tokyo"}
          ]
        }
        """.trimIndent()

        assertEquals(3, AlertWorker.nodeCount(json))
    }

    @Test
    fun anEmptyFleetCountsZero() {
        assertEquals(0, AlertWorker.nodeCount("""{"servers": []}"""))
    }

    @Test
    fun aMissingServersKeyCountsZero() {
        // A site that answers with something other than the documented shape
        // is a site to say nothing about, not one to crash on.
        assertEquals(0, AlertWorker.nodeCount("""{"ok": true}"""))
    }

    @Test
    fun malformedJsonCountsZero() {
        // The fetch is a string from the network; `nodeCount` runs after the
        // parse that guards it, but a second parse here must not throw either.
        assertEquals(0, AlertWorker.nodeCount("not json at all"))
        assertEquals(0, AlertWorker.nodeCount(""))
    }

    @Test
    fun aNetworkFailureIsRetried() {
        assertEquals(
            Result.retry(),
            AlertWorker.retryPolicy(
                AlertWorker.CheckOutcome.Failed(AlertWorker.REASON_NETWORK),
            ),
        )
    }

    @Test
    fun aRejectedCredentialIsNotRetried() {
        // The token comes from the app, so asking the site again cannot mint
        // one. Retrying here would be a loop that never succeeds.
        assertEquals(
            Result.success(),
            AlertWorker.retryPolicy(
                AlertWorker.CheckOutcome.Failed(AlertWorker.REASON_AUTH),
            ),
        )
    }

    @Test
    fun aMissingCredentialIsNotRetried() {
        assertEquals(
            Result.success(),
            AlertWorker.retryPolicy(
                AlertWorker.CheckOutcome.Failed(AlertWorker.REASON_NO_TOKEN),
            ),
        )
    }

    @Test
    fun aMissingSiteIsNotRetried() {
        assertEquals(
            Result.success(),
            AlertWorker.retryPolicy(
                AlertWorker.CheckOutcome.Failed(AlertWorker.REASON_NO_SITE),
            ),
        )
    }

    @Test
    fun aCompletedCheckSucceeds() {
        assertEquals(
            Result.success(),
            AlertWorker.retryPolicy(AlertWorker.CheckOutcome.Done(checked = 2, notified = 0)),
        )
    }

    @Test
    fun anAnsweredFetchIsNeverARefusal() {
        // A site with no nodes answers `{"servers": []}`, which is not empty
        // text and not a failure: it is a fleet of none.
        assertEquals(null, AlertWorker.refusalReason("""{"servers": []}""", hasToken = true))
        assertEquals(null, AlertWorker.refusalReason("""{"servers": []}""", hasToken = false))
    }

    @Test
    fun anEmptyAnswerWithACredentialIsARejection() {
        // fetchServers turns 401/403 into "": the site was asked and said no.
        assertEquals(
            AlertWorker.REASON_AUTH,
            AlertWorker.refusalReason("", hasToken = true),
        )
    }

    @Test
    fun anEmptyAnswerWithoutACredentialIsNotARejection() {
        // A site that needs no login has no token by design, so this is the
        // same "log in" the button would say to someone who never had one.
        assertEquals(
            AlertWorker.REASON_NO_TOKEN,
            AlertWorker.refusalReason("", hasToken = false),
        )
    }
}
