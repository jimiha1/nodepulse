package app.nodepulse.cf

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The resolver that keeps a tampered network from answering for the site.
 *
 * Worth pinning down because every failure mode here is silent: an answer that
 * is merely wrong still connects, and the widget then shows numbers that never
 * came from the server. The rules that matter are which provider is believed,
 * when an answer is reused, and what happens when none of them answer.
 */
class DohResolverTest {

    private val alidns = DohProvider("223.5.5.5", "dns.alidns.com", "/resolve")
    private val dnspod = DohProvider("1.12.12.12", "doh.pub", "/dns-query")

    private fun answer(vararg records: Pair<Int, String>): String {
        val entries = records.joinToString(",") { (type, data) ->
            """{"name":"monitor.example.com.","type":$type,"TTL":300,"data":"$data"}"""
        }
        return """{"Status":0,"Answer":[$entries]}"""
    }

    // MARK: - parseDohAnswers

    @Test
    fun readsTheAddressesOutOfAnAnswer() {
        val body = answer(1 to "104.21.18.181", 1 to "172.67.183.26")
        assertEquals(listOf("104.21.18.181", "172.67.183.26"), parseDohAnswers(body))
    }

    @Test
    fun ignoresRecordsThatAreNotIpv4Addresses() {
        // An AAAA record and a CNAME chain are both normal in a real answer,
        // and neither is something a socket can be pointed at.
        val body = answer(
            28 to "2606:4700:3033::ac43:b71a",
            5 to "somewhere.else.example.",
            1 to "104.21.18.181",
            1 to "not-an-address",
            1 to "999.1.1.1",
        )
        assertEquals(listOf("104.21.18.181"), parseDohAnswers(body))
    }

    @Test
    fun answersWithNothingWhenTheResponseCarriesNoAnswers() {
        assertTrue(parseDohAnswers("""{"Status":3}""").isEmpty())
        assertTrue(parseDohAnswers("""{"Status":0,"Answer":[]}""").isEmpty())
        assertTrue(parseDohAnswers("not json at all").isEmpty())
    }

    @Test
    fun doesNotRepeatAnAddress() {
        val body = answer(1 to "104.21.18.181", 1 to "104.21.18.181")
        assertEquals(listOf("104.21.18.181"), parseDohAnswers(body))
    }

    // MARK: - resolve

    @Test
    fun asksTheFirstProviderAndKeepsItsAddresses() {
        val asked = mutableListOf<String>()
        val resolver = DohResolver(
            providers = listOf(alidns, dnspod),
            fetch = { provider, _ ->
                asked.add(provider.name)
                answer(1 to "104.21.18.181")
            },
            systemLookup = { emptyList() },
            clock = { 0L },
        )
        assertEquals(listOf("104.21.18.181"), resolver.resolve("monitor.example.com"))
        assertEquals(listOf("dns.alidns.com"), asked)
    }

    @Test
    fun movesOnToTheNextProviderWhenOneFails() {
        val asked = mutableListOf<String>()
        val resolver = DohResolver(
            providers = listOf(alidns, dnspod),
            fetch = { provider, _ ->
                asked.add(provider.name)
                if (provider.name == alidns.name) throw java.io.IOException("down")
                answer(1 to "172.67.183.26")
            },
            systemLookup = { emptyList() },
            clock = { 0L },
        )
        assertEquals(listOf("172.67.183.26"), resolver.resolve("monitor.example.com"))
        assertEquals(listOf("dns.alidns.com", "doh.pub"), asked)
    }

    @Test
    fun movesOnWhenAProviderAnswersWithNoUsableAddress() {
        val asked = mutableListOf<String>()
        val resolver = DohResolver(
            providers = listOf(alidns, dnspod),
            fetch = { provider, _ ->
                asked.add(provider.name)
                if (provider.name == alidns.name) """{"Status":3}"""
                else answer(1 to "172.67.183.26")
            },
            systemLookup = { emptyList() },
            clock = { 0L },
        )
        assertEquals(listOf("172.67.183.26"), resolver.resolve("monitor.example.com"))
        assertEquals(listOf("dns.alidns.com", "doh.pub"), asked)
    }

    @Test
    fun keepsAnAnswerForItsTtlAndAsksAgainAfter() {
        var now = 0L
        var fetches = 0
        val resolver = DohResolver(
            providers = listOf(alidns),
            fetch = { _, _ ->
                fetches++
                answer(1 to "104.21.18.181")
            },
            systemLookup = { emptyList() },
            clock = { now },
            ttlMs = 5 * 60_000L,
        )
        resolver.resolve("monitor.example.com")

        now = 4 * 60_000L
        resolver.resolve("monitor.example.com")
        assertEquals(1, fetches)

        // An address that moves must not be pinned forever: a CDN edge
        // changing is the normal case, not the exception.
        now = 6 * 60_000L
        resolver.resolve("monitor.example.com")
        assertEquals(2, fetches)
    }

    @Test
    fun doesNotRememberAFailure() {
        var fetches = 0
        val resolver = DohResolver(
            providers = listOf(alidns),
            fetch = { _, _ ->
                fetches++
                if (fetches == 1) throw java.io.IOException("down")
                answer(1 to "104.21.18.181")
            },
            systemLookup = { emptyList() },
            clock = { 0L },
        )
        assertTrue(resolver.resolve("monitor.example.com").isEmpty())
        assertEquals(listOf("104.21.18.181"), resolver.resolve("monitor.example.com"))
        assertEquals(2, fetches)
    }

    // MARK: - resolveOrSystem

    @Test
    fun prefersTheDohAnswerOverThePlatformResolver() {
        var lookedUp = false
        val resolver = DohResolver(
            providers = listOf(alidns),
            fetch = { _, _ -> answer(1 to "104.21.18.181") },
            systemLookup = {
                lookedUp = true
                listOf("182.16.61.117")
            },
            clock = { 0L },
        )
        assertEquals(
            listOf("104.21.18.181"),
            resolver.resolveOrSystem("monitor.example.com"),
        )
        assertFalse(lookedUp)
    }

    @Test
    fun fallsBackToThePlatformResolverWhenNoProviderAnswers() {
        val resolver = DohResolver(
            providers = listOf(alidns, dnspod),
            fetch = { _, _ -> throw java.io.IOException("down") },
            systemLookup = { listOf("10.0.0.9") },
            clock = { 0L },
        )
        assertEquals(
            listOf("10.0.0.9"),
            resolver.resolveOrSystem("monitor.example.com"),
        )
    }

    @Test
    fun pinsAProviderToItsOwnAddress() {
        // The bootstrap: asking the resolver to find the resolver is circular.
        val resolver = DohResolver(
            providers = listOf(alidns),
            fetch = { _, _ -> throw java.io.IOException("must not be called") },
            systemLookup = { throw java.io.IOException("must not be called") },
            clock = { 0L },
        )
        assertEquals(listOf("223.5.5.5"), resolver.resolveOrSystem("dns.alidns.com"))
    }

    @Test
    fun anUnreachableResolverAndNoFallbackResolvesToNothing() {
        val resolver = DohResolver(
            providers = listOf(alidns),
            fetch = { _, _ -> throw java.io.IOException("down") },
            systemLookup = { throw java.io.IOException("down too") },
            clock = { 0L },
        )
        assertTrue(resolver.resolveOrSystem("monitor.example.com").isEmpty())
    }
}
