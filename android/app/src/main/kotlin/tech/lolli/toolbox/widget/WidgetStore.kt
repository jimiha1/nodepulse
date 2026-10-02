package tech.lolli.toolbox.widget

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Where the home-screen widget finds the server list and the credential to
 * fetch it with.
 *
 * For CF-Server-Monitor:
 * - siteUrl: base URL of the CF monitor site
 * - token: JWT credential (or null for public sites)
 * - tokenExpiresAt: expiry timestamp in ms
 * - nodes: list of nodes/servers (id, name, region)
 */
object WidgetStore {
    private const val TAG = "WidgetStore"

    private const val PREFS = "sbm_widget_servers"
    private const val KEY_SERVERS = "servers"
    private const val KEY_SITE_URL = "site_url"
    private const val KEY_TOKEN_EXPIRES_AT = "token_expires_at"

    private const val TOKEN_PREFS = "sbm_widget_tokens"
    private const val KEY_TOKEN = "global_token"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "sbm_widget_token_key"

    private const val IV_BYTES = 12
    private const val TAG_BITS = 128

    // MARK: - Servers / Nodes

    data class WidgetServer(
        val id: String,
        val name: String,
        val region: String? = null,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("id", id)
            .put("name", name)
            .apply {
                if (region != null) put("region", region)
            }

        companion object {
            fun fromJson(o: JSONObject): WidgetServer? {
                val id = o.optString("id").takeIf { it.isNotEmpty() } ?: return null
                val name = o.optString("name").takeIf { it.isNotEmpty() } ?: id
                val region = o.optString("region").takeIf { it.isNotEmpty() }
                return WidgetServer(
                    id = id,
                    name = name,
                    region = region,
                )
            }
        }
    }

    fun servers(context: Context): List<WidgetServer> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SERVERS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).mapNotNull { WidgetServer.fromJson(arr.getJSONObject(it)) }
        } catch (e: Exception) {
            Log.w(TAG, "Could not read the widget server list: ${e.message}")
            emptyList()
        }
    }

    fun server(context: Context, id: String): WidgetServer? =
        servers(context).firstOrNull { it.id == id }

    fun setServers(context: Context, servers: List<WidgetServer>) {
        val arr = JSONArray()
        servers.forEach { arr.put(it.toJson()) }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SERVERS, arr.toString())
            .apply()
    }

    fun siteUrl(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SITE_URL, null)

    fun tokenExpiresAt(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_TOKEN_EXPIRES_AT, 0L)

    // MARK: - Token

    fun token(context: Context): String? {
        val stored = context.getSharedPreferences(TOKEN_PREFS, Context.MODE_PRIVATE)
            .getString(KEY_TOKEN, null) ?: return null
        return try {
            val blob = Base64.decode(stored, Base64.NO_WRAP)
            if (blob.size <= IV_BYTES) return null
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(
                Cipher.DECRYPT_MODE,
                secretKey(),
                GCMParameterSpec(TAG_BITS, blob, 0, IV_BYTES),
            )
            String(cipher.doFinal(blob, IV_BYTES, blob.size - IV_BYTES), Charsets.UTF_8)
        } catch (e: Exception) {
            Log.w(TAG, "Dropping an undecryptable widget token: ${e.message}")
            setToken(context, null)
            null
        }
    }

    fun setToken(context: Context, token: String?) {
        val prefs = context.getSharedPreferences(TOKEN_PREFS, Context.MODE_PRIVATE)
        if (token.isNullOrEmpty()) {
            prefs.edit().remove(KEY_TOKEN).apply()
            return
        }
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey())
            val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
            val blob = cipher.iv + encrypted
            prefs.edit().putString(KEY_TOKEN, Base64.encodeToString(blob, Base64.NO_WRAP)).apply()
        } catch (e: Exception) {
            Log.w(TAG, "Could not store a widget token: ${e.message}")
            prefs.edit().remove(KEY_TOKEN).apply()
        }
    }

    @Synchronized
    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        try {
            (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        } catch (e: Exception) {
            Log.w(TAG, "Replacing an unusable widget key: ${e.message}")
            runCatching { keyStore.deleteEntry(KEY_ALIAS) }
        }

        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(false)
                .build()
        )
        return generator.generateKey()
    }

    // MARK: - The channel payload

    /**
     * Splits `WidgetSync`'s payload:
     * - siteUrl and tokenExpiresAt and nodes into preferences
     * - token into Keystore-backed preferences
     *
     * Expected JSON shape:
     * {
     *   "siteUrl": "https://monitor.example.com",
     *   "token": "jwt-or-null",
     *   "tokenExpiresAt": 1759410000000,
     *   "nodes": [
     *     {"id": "...", "name": "...", "region": "..."}
     *   ]
     * }
     */
    fun publish(context: Context, payload: String): Boolean {
        return try {
            val root = JSONObject(payload)
            val siteUrl = root.optString("siteUrl").takeIf { it.isNotEmpty() }
            val token = root.optString("token").takeIf { it.isNotEmpty() }
            val tokenExpiresAt = root.optLong("tokenExpiresAt", 0L)

            val rawNodes = root.optJSONArray("nodes") ?: JSONArray()
            val servers = ArrayList<WidgetServer>(rawNodes.length())
            for (i in 0 until rawNodes.length()) {
                val entry = rawNodes.optJSONObject(i) ?: continue
                val parsed = WidgetServer.fromJson(entry) ?: continue
                servers.add(parsed)
            }

            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_SITE_URL, siteUrl)
                .putLong(KEY_TOKEN_EXPIRES_AT, tokenExpiresAt)
                .apply()

            setServers(context, servers)

            if (token != null) {
                setToken(context, token)
            } else if (!root.has("token") || root.isNull("token")) {
                // If token explicitly null or missing, clear or keep?
                // When payload has "token": null or empty string, clear token
                if (root.has("token")) {
                    setToken(context, null)
                }
            }

            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not publish the widget server list: ${e.message}", e)
            false
        }
    }

    /**
     * What is actually held, as JSON — metadata only, never the secret token.
     */
    fun tokenState(context: Context): String {
        val root = JSONObject()
        val siteUrl = siteUrl(context)
        val hasToken = token(context) != null
        root.put("siteUrl", siteUrl ?: "")
        root.put("hasToken", hasToken)
        root.put("expiresAt", tokenExpiresAt(context))
        return root.toString()
    }
}
