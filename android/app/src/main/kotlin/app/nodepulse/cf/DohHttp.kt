package app.nodepulse.cf

/**
 * The HTTPS side of [DohResolver]: one JSON answer per provider.
 *
 * A provider is reached by address, because asking the resolver to find the
 * resolver is circular — and the handshake still carries the provider's real
 * name for SNI and for the certificate check, so an address that has been
 * taken over cannot answer in the provider's place. That combination is what
 * makes the lookup trustworthy on a network whose resolver is not.
 *
 * This goes through [CfHttp] rather than `HttpsURLConnection` for the same
 * reason the site's own requests do: that class resolves the hostname itself,
 * which is the one step that must not be left to the resolver here.
 */
object DohHttp {
    private val client by lazy {
        CfHttp(
            // The providers' own names are the one lookup that cannot be
            // bootstrapped: asking the resolver to find the resolver is
            // circular. Each is pinned to its published address instead, and
            // the certificate is still checked against the name, so a
            // hijacked address cannot answer in the provider's place.
            resolve = { host ->
                DohProviders.pinned(host)?.let { listOf(it) }
                    ?: DohResolver.systemAddresses(host)
            },
            context = CfHttp.verifiedContext(),
            hostnameVerifier = CfHttp.verifiedHostnames,
        )
    }

    fun fetch(provider: DohProvider, host: String): String {
        // `type=A` only: an AAAA answer is not something this can connect to,
        // and asking for it would waste the provider's patience.
        val query = "name=${encode(host)}&type=A"
        return client.get(
            url = "https://${provider.name}${provider.path}?$query",
            userAgent = "ServerBox-DoH/1",
            timeoutMs = TIMEOUT_MS,
        )
    }

    private const val TIMEOUT_MS = 5_000

    private fun encode(value: String): String =
        java.net.URLEncoder.encode(value, "UTF-8")
}
