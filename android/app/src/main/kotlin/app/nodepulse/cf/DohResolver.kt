package app.nodepulse.cf

import android.util.Log
import org.json.JSONObject
import java.net.InetAddress

/**
 * One DNS-over-HTTPS endpoint.
 *
 * [address] is an IP literal on purpose. Bootstrapping a resolver through the
 * resolver is circular, so each provider is reached by address — and the
 * certificate is still checked against [name], so an address that has been
 * taken over cannot answer in the provider's place.
 */
data class DohProvider(
    val address: String,
    val name: String,
    val path: String,
)

/**
 * The providers, in the order they are tried.
 *
 * AliDNS and DNSPod lead because they answer from inside mainland China, which
 * is where a phone whose resolver has been tampered with is most likely to be;
 * Cloudflare and Google follow as a last resort for everywhere else.
 */
object DohProviders {
    val all = listOf(
        DohProvider("223.5.5.5", "dns.alidns.com", "/resolve"),
        DohProvider("1.12.12.12", "doh.pub", "/dns-query"),
        DohProvider("1.1.1.1", "cloudflare-dns.com", "/dns-query"),
        DohProvider("8.8.8.8", "dns.google", "/resolve"),
    )

    /** The address [host] is reached at, when it is one of the providers. */
    fun pinned(host: String): String? = all.firstOrNull { it.name == host }?.address
}

/**
 * The A records in a DoH JSON answer.
 *
 * The shape differs by provider — AliDNS echoes `Question` as an object,
 * DNSPod as an array — but `Answer` is a list of `{type, data}` in both, and
 * only the `type == 1` entries are addresses a socket can be pointed at.
 * Anything unparseable is skipped rather than thrown over: a resolver that
 * answers with something unexpected should cost one provider, not the lookup.
 */
fun parseDohAnswers(body: String): List<String> {
    val answers = runCatching { JSONObject(body).optJSONArray("Answer") }.getOrNull()
        ?: return emptyList()

    val addresses = mutableListOf<String>()
    for (i in 0 until answers.length()) {
        val entry = answers.optJSONObject(i) ?: continue
        if (entry.optInt("type") != 1) continue
        val data = entry.optString("data")
        if (data.isEmpty()) continue
        if (isIpv4Literal(data) && !addresses.contains(data)) addresses.add(data)
    }
    return addresses
}

/**
 * Whether [value] is an IPv4 literal.
 *
 * [InetAddress] is not asked: on the JVM its parser is happy to resolve a name
 * through the system resolver, and going back to the resolver is the one thing
 * this file exists to avoid.
 */
internal fun isIpv4Literal(value: String): Boolean {
    val parts = value.split('.')
    if (parts.size != 4) return false
    return parts.all { part ->
        part.isNotEmpty() && part.length <= 3 && part.all { it.isDigit() } &&
            part.toInt() in 0..255
    }
}

/**
 * Resolves hostnames over HTTPS instead of the platform resolver.
 *
 * The platform resolver is what a poisoned router or a meddling middlebox gets
 * to rewrite, and a rewritten answer is worse than no answer: the connection
 * succeeds, against a server that is not the one that was asked for, and every
 * later failure looks like a site problem. A DoH answer arrives inside a TLS
 * session whose certificate is checked against a name reached by address, so
 * the same tampering yields a failed lookup instead of a wrong one.
 *
 * The logic here is deliberately free of Android and OkHttp types — the fetch
 * is a parameter — so the fallback and caching rules can be tested directly.
 */
class DohResolver(
    private val providers: List<DohProvider> = DohProviders.all,
    private val fetch: (DohProvider, String) -> String = DohHttp::fetch,
    private val systemLookup: (String) -> List<String> = ::systemLookup,
    private val clock: () -> Long = System::currentTimeMillis,
    /** How long an answer is reused. See [resolve]. */
    private val ttlMs: Long = TTL_MS,
) {
    private class Cached(val addresses: List<String>, val expiresAt: Long)

    private val cache = HashMap<String, Cached>()

    /**
     * The addresses [host] resolves to, or empty when no provider answered.
     *
     * An answer is kept for [ttlMs] so a burst of requests costs one lookup,
     * and no longer, because a CDN edge moving is the normal case here rather
     * than the exception. A *failure* is not kept: a resolver that was briefly
     * unreachable is worth asking again, and remembering the failure would
     * pin the host to the fallback for a whole ttl.
     */
    @Synchronized
    fun resolve(host: String): List<String> {
        val cached = cache[host]
        if (cached != null && clock() < cached.expiresAt) return cached.addresses

        for (provider in providers) {
            val body = runCatching { fetch(provider, host) }.getOrNull() ?: continue
            val addresses = parseDohAnswers(body)
            if (addresses.isEmpty()) continue
            Log.d(TAG, "Resolved $host via ${provider.name} to $addresses")
            cache[host] = Cached(addresses, clock() + ttlMs)
            return addresses
        }
        // Worth a line of its own: falling through to the platform resolver
        // means the answer is the one this class exists to distrust, and
        // nothing else on screen would say so.
        Log.w(TAG, "No DoH provider answered for $host; falling back")
        return emptyList()
    }

    /**
     * [resolve], falling back to the platform resolver.
     *
     * The fallback is deliberately last: it is the path being worked around,
     * and it is still better than failing outright on a network where DoH is
     * blocked but the resolver is honest. A provider's own name is pinned to
     * its address instead, because its certificate is the one thing that
     * cannot be checked through the resolver it is meant to replace.
     */
    fun resolveOrSystem(host: String): List<String> {
        DohProviders.pinned(host)?.let { return listOf(it) }

        val resolved = resolve(host)
        if (resolved.isNotEmpty()) return resolved

        return runCatching { systemLookup(host) }.getOrDefault(emptyList())
    }

    companion object {
        const val TTL_MS = 5 * 60_000L

        /**
         * The resolver the widgets and alerts share, so one lookup serves them
         * all — and so the cache actually caches: a per-call instance would
         * look up the site again for every widget on every refresh.
         */
        val shared: DohResolver by lazy { DohResolver() }

        /** The platform resolver, for the one lookup DoH cannot bootstrap. */
        internal fun systemAddresses(host: String): List<String> =
            runCatching {
                InetAddress.getAllByName(host)
                    .filter { it.address.size == 4 }
                    .mapNotNull { it.hostAddress }
            }.getOrDefault(emptyList())

        private fun systemLookup(host: String): List<String> = systemAddresses(host)

        private const val TAG = "DohResolver"
    }
}
