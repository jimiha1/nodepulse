package app.nodepulse.cf

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException

/**
 * The HTTP reading the site's requests depend on.
 *
 * Hand-rolled because `HttpURLConnection` insists on resolving the hostname
 * itself, which is the one step that must not be left to the platform
 * resolver. Hand-rolled parsers are also where silent corruption lives, so the
 * shapes a real server sends are pinned here.
 */
class CfHttpParseTest {

    private fun bytes(value: String) = value.toByteArray(Charsets.ISO_8859_1)

    @Test
    fun readsTheStatusHeadersAndBody() {
        val response = parseResponse(
            bytes(
                "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: application/json\r\n" +
                    "Server: cloudflare\r\n" +
                    "\r\n" +
                    """{"servers":[]}""",
            ),
        )
        assertEquals(200, response.status)
        assertEquals("application/json", response.headers["content-type"])
        assertEquals("cloudflare", response.headers["server"])
        assertEquals("""{"servers":[]}""", response.body)
    }

    @Test
    fun readsTheStatusCodeOfAFailure() {
        val response = parseResponse(bytes("HTTP/1.1 401 Unauthorized\r\n\r\n"))
        assertEquals(401, response.status)
        assertEquals("", response.body)
    }

    @Test
    fun keepsABodyThatContainsHeaderLikeText() {
        // The split has to happen at the terminator, not at the first blank
        // line anywhere in the payload.
        val body = "line one\r\n\r\nline two"
        val response = parseResponse(
            bytes("HTTP/1.1 200 OK\r\nContent-Length: 20\r\n\r\n$body"),
        )
        assertEquals(body, response.body)
    }

    @Test
    fun dechunksAChunkedBody() {
        // Cloudflare sends this for responses it streams, and leaving the
        // framing in would put hex lengths inside the JSON.
        val response = parseResponse(
            bytes(
                "HTTP/1.1 200 OK\r\n" +
                    "Transfer-Encoding: chunked\r\n" +
                    "\r\n" +
                    "6\r\n{\"serv\r\n" +
                    "8\r\ners\":[]}\r\n" +
                    "0\r\n\r\n",
            ),
        )
        assertEquals("""{"servers":[]}""", response.body)
    }

    @Test
    fun dechunksWhenTheHeaderIsCasedDifferently() {
        val response = parseResponse(
            bytes(
                "HTTP/1.1 200 OK\r\n" +
                    "transfer-encoding: CHUNKED\r\n" +
                    "\r\n" +
                    "5\r\nhello\r\n0\r\n\r\n",
            ),
        )
        assertEquals("hello", response.body)
    }

    @Test
    fun aTruncatedChunkedBodyKeepsWhatArrived() {
        // A transfer cut mid-flight is a network failure; the partial body is
        // what the caller's parse reports as one.
        val response = parseResponse(
            bytes(
                "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" +
                    "5\r\nhello\r\n99\r\nwor",
            ),
        )
        assertEquals("hellowor", response.body)
    }

    @Test
    fun rejectsAResponseWithNoHeaderTerminator() {
        assertThrows(IOException::class.java) {
            parseResponse(bytes("HTTP/1.1 200 OK\r\nContent-Type: text/html"))
        }
    }

    @Test
    fun rejectsAResponseWithNoStatusLine() {
        assertThrows(IOException::class.java) {
            parseResponse(bytes("garbage\r\n\r\nbody"))
        }
    }

    @Test
    fun anEmptyChunkedBodyReadsAsEmpty() {
        val response = parseResponse(
            bytes("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n"),
        )
        assertEquals("", response.body)
    }

    @Test
    fun parsesAChunkSizeWithAnExtension() {
        val response = parseResponse(
            bytes(
                "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" +
                    "5;ext=1\r\nhello\r\n0\r\n\r\n",
            ),
        )
        assertTrue(response.body == "hello")
    }
}
