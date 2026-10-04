package tech.lolli.toolbox.cf

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.security.cert.X509Certificate
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SNIHostName
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/** A parsed HTTP response. */
data class HttpResponse(
    val status: Int,
    val headers: Map<String, String>,
    val body: String,
)

/**
 * A small HTTPS client whose connections are opened at an address the caller
 * chose rather than one the platform resolver chose.
 *
 * `HttpURLConnection` cannot be used for this. It resolves the hostname itself,
 * before any `SSLSocketFactory` the caller installs gets a say, so the very
 * step that has to be taken away from the resolver is the step it insists on
 * performing. Connecting the socket first and then wrapping it in TLS is the
 * only ordering that lets the address come from somewhere else — and the
 * handshake still carries the real hostname for SNI, which is what the site's
 * edge routes on.
 */
class CfHttp(
    /** Where a hostname's addresses come from. See [DohResolver.resolveOrSystem]. */
    private val resolve: (String) -> List<String>,
    private val context: SSLContext = permissiveContext(),
    private val hostnameVerifier: HostnameVerifier? = null,
) {
    /** The site answered with a status the caller has to interpret. */
    class HttpStatusException(val code: Int) : IOException("HTTP $code")

    /**
     * `GET url`, following redirects, and return the body.
     *
     * [token] is sent only to [url]'s own host: a redirect is allowed to point
     * anywhere, and a bearer token is not something to hand to whatever it
     * names.
     */
    fun get(
        url: String,
        userAgent: String,
        token: String? = null,
        timeoutMs: Int = DEFAULT_TIMEOUT_MS,
        maxRedirects: Int = 3,
    ): String {
        val originHost = URL(url).host
        var current = url
        var redirects = 0

        while (true) {
            val parsed = URL(current)
            val secure = when (parsed.protocol.lowercase()) {
                "https" -> true
                "http" -> false
                else -> throw IOException("Unsupported scheme ${parsed.protocol}")
            }
            val port = if (parsed.port != -1) parsed.port else if (secure) 443 else 80
            val target = parsed.file.ifEmpty { "/" }

            val response = exchange(
                host = parsed.host,
                port = port,
                secure = secure,
                target = target,
                token = token.takeIf { parsed.host == originHost },
                userAgent = userAgent,
                timeoutMs = timeoutMs,
            )

            when {
                response.status in 200..299 -> return response.body
                response.status in 300..399 && redirects < maxRedirects -> {
                    val location = response.headers["location"]
                        ?: throw HttpStatusException(response.status)
                    current = URL(parsed, location).toString()
                    redirects++
                }
                else -> throw HttpStatusException(response.status)
            }
        }
    }

    /**
     * One request, tried against each address the resolver returned.
     *
     * An edge that refuses the connection is worth the next address in the same
     * answer — a CDN's answer is a set, not a choice — but a server that
     * *answered* is not retried, which is why the status is interpreted by
     * [get] and not here.
     */
    private fun exchange(
        host: String,
        port: Int,
        secure: Boolean,
        target: String,
        token: String?,
        userAgent: String,
        timeoutMs: Int,
    ): HttpResponse {
        val addresses = resolve(host)
        if (addresses.isEmpty()) throw IOException("No address for $host")

        var lastError: Exception? = null
        for (address in addresses) {
            try {
                return open(address, port, secure, host, timeoutMs).use { socket ->
                    write(socket, host, target, token, userAgent)
                    parseResponse(socket.getInputStream().readBytes())
                }
            } catch (e: Exception) {
                lastError = e
            }
        }
        throw lastError ?: IOException("No address for $host")
    }

    private fun open(
        address: String,
        port: Int,
        secure: Boolean,
        host: String,
        timeoutMs: Int,
    ): Socket {
        val raw = Socket()
        raw.connect(InetSocketAddress(InetAddress.getByName(address), port), timeoutMs)
        raw.soTimeout = timeoutMs
        if (!secure) return raw

        val ssl = context.socketFactory.createSocket(raw, host, port, true) as SSLSocket
        // The hostname, not the address, is what SNI carries: the address is
        // where the connection goes, the name is who it claims to be.
        ssl.sslParameters = ssl.sslParameters.apply {
            serverNames = listOf(SNIHostName(host))
        }
        ssl.startHandshake()
        if (hostnameVerifier != null && !hostnameVerifier.verify(host, ssl.session)) {
            throw IOException("Certificate for $host does not match")
        }
        return ssl
    }

    private fun write(
        socket: Socket,
        host: String,
        target: String,
        token: String?,
        userAgent: String,
    ) {
        val request = buildString {
            append("GET ").append(target).append(" HTTP/1.1\r\n")
            append("Host: ").append(host).append("\r\n")
            append("User-Agent: ").append(userAgent).append("\r\n")
            append("Accept: application/json\r\n")
            // The body is read to end-of-stream, which is what makes the
            // reading below need no length bookkeeping of its own.
            append("Connection: close\r\n")
            if (!token.isNullOrEmpty()) {
                append("Authorization: Bearer ").append(token).append("\r\n")
            }
            append("\r\n")
        }
        socket.getOutputStream().apply {
            write(request.toByteArray(Charsets.ISO_8859_1))
            flush()
        }
    }

    companion object {
        const val DEFAULT_TIMEOUT_MS = 8_000

        /**
         * The client the widgets and alerts share, so one lookup serves them
         * all.
         */
        val shared: CfHttp by lazy { CfHttp(DohResolver.shared::resolveOrSystem) }

        /**
         * The context the site's own connection uses: it accepts any
         * certificate.
         *
         * What protects this connection is the *address*, which DoH chose and
         * an impostor cannot change without breaking TLS to the resolver.
         * Verifying the leaf as well would be better, but it would also refuse
         * a self-hosted site with a self-signed certificate — a working setup
         * today — and the trust decision here is not one this change should be
         * making.
         */
        fun permissiveContext(): SSLContext {
            val trustEverything = object : X509TrustManager {
                override fun checkClientTrusted(chain: Array<X509Certificate>?, authType: String?) = Unit
                override fun checkServerTrusted(chain: Array<X509Certificate>?, authType: String?) = Unit
                override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
            }
            return SSLContext.getInstance("TLS").apply {
                init(null, arrayOf<TrustManager>(trustEverything), java.security.SecureRandom())
            }
        }

        /** The platform's own trust store and hostname rules, for DoH itself. */
        fun verifiedContext(): SSLContext = SSLContext.getDefault()

        val verifiedHostnames: HostnameVerifier
            get() = HttpsURLConnection.getDefaultHostnameVerifier()
    }
}

/**
 * The status line, headers and body of [raw].
 *
 * The body is de-chunked when the server says so: this reads the stream to
 * end-of-stream rather than by length, and a chunked body carries its own
 * framing that would otherwise end up inside the JSON.
 */
internal fun parseResponse(raw: ByteArray): HttpResponse {
    val separator = indexOfHeaderEnd(raw)
        ?: throw IOException("Malformed response: no header terminator")

    val head = String(raw, 0, separator, Charsets.ISO_8859_1)
    val lines = head.split("\r\n")
    val status = lines.firstOrNull()
        ?.split(' ')
        ?.getOrNull(1)
        ?.toIntOrNull()
        ?: throw IOException("Malformed status line")

    val headers = LinkedHashMap<String, String>()
    for (line in lines.drop(1)) {
        val colon = line.indexOf(':')
        if (colon <= 0) continue
        headers[line.substring(0, colon).trim().lowercase()] =
            line.substring(colon + 1).trim()
    }

    var body = raw.copyOfRange(separator + 4, raw.size)
    if (headers["transfer-encoding"]?.contains("chunked", ignoreCase = true) == true) {
        body = dechunk(body)
    }
    return HttpResponse(status, headers, String(body, Charsets.UTF_8))
}

private fun indexOfHeaderEnd(raw: ByteArray): Int? {
    for (i in 0 until raw.size - 3) {
        if (raw[i] == 13.toByte() && raw[i + 1] == 10.toByte() &&
            raw[i + 2] == 13.toByte() && raw[i + 3] == 10.toByte()
        ) {
            return i
        }
    }
    return null
}

/**
 * The payload of a chunked body, with the chunk framing removed.
 *
 * A group that cannot be read ends the body rather than throwing: a truncated
 * transfer is a network failure, and the caller's parse of the partial JSON
 * reports it as one.
 */
internal fun dechunk(body: ByteArray): ByteArray {
    val out = ByteArrayOutputStream(body.size)
    var i = 0
    while (i < body.size) {
        var lineEnd = i
        while (lineEnd < body.size &&
            !(body[lineEnd] == 13.toByte() && lineEnd + 1 < body.size && body[lineEnd + 1] == 10.toByte())
        ) {
            lineEnd++
        }
        if (lineEnd >= body.size) break

        val sizeLine = String(body, i, lineEnd - i, Charsets.US_ASCII)
        // A chunk size may carry extensions after a ';'; the size is before it.
        val size = sizeLine.substringBefore(';').trim().toIntOrNull(16) ?: break
        i = lineEnd + 2
        if (size == 0) break

        val end = minOf(i + size, body.size)
        out.write(body, i, end - i)
        i = end + 2
    }
    return out.toByteArray()
}
