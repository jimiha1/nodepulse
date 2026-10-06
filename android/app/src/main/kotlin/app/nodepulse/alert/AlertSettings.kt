package app.nodepulse.alert

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object AlertSettings {
    private const val TAG = "AlertSettings"

    private const val PREFS = "sbm_alerts_config"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_TRAFFIC_PCT = "traffic_pct"
    private const val KEY_EXPIRY_DAYS = "expiry_days"
    private const val KEY_SITE_URL = "site_url"
    private const val KEY_TOKEN_EXPIRES_AT = "token_expires_at"
    private const val KEY_RESOURCE_RULES = "resource_rules"

    private const val TOKEN_PREFS = "sbm_alert_tokens"
    private const val KEY_TOKEN = "global_token"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "sbm_alert_token_key"

    private const val IV_BYTES = 12
    private const val TAG_BITS = 128

    data class Settings(
        val enabled: Boolean,
        val trafficPct: Int,
        val expiryDays: Int,
        val siteUrl: String,
        val token: String?,
        val tokenExpiresAt: Long,
        /**
         * The user's resource rules, still in the payload's own JSON: the
         * worker parses them through [ResourceAlertEvaluator], and keeping the
         * text means a rule this build cannot read is not silently rewritten
         * to something it can.
         */
        val resourceRules: String,
    )

    fun load(context: Context): Settings {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return Settings(
            enabled = prefs.getBoolean(KEY_ENABLED, false),
            trafficPct = prefs.getInt(KEY_TRAFFIC_PCT, 90),
            expiryDays = prefs.getInt(KEY_EXPIRY_DAYS, 7),
            siteUrl = prefs.getString(KEY_SITE_URL, "") ?: "",
            token = token(context),
            tokenExpiresAt = prefs.getLong(KEY_TOKEN_EXPIRES_AT, 0L),
            resourceRules = prefs.getString(KEY_RESOURCE_RULES, "") ?: "",
        )
    }

    fun save(context: Context, settings: Settings) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ENABLED, settings.enabled)
            .putInt(KEY_TRAFFIC_PCT, settings.trafficPct)
            .putInt(KEY_EXPIRY_DAYS, settings.expiryDays)
            .putString(KEY_SITE_URL, settings.siteUrl)
            .putLong(KEY_TOKEN_EXPIRES_AT, settings.tokenExpiresAt)
            .putString(KEY_RESOURCE_RULES, settings.resourceRules)
            .apply()

        setToken(context, settings.token)
    }

    fun parsePayload(payload: String): Settings? {
        return try {
            val root = JSONObject(payload)
            Settings(
                enabled = root.optBoolean("enabled", false),
                trafficPct = root.optInt("trafficPct", 90),
                expiryDays = root.optInt("expiryDays", 7),
                siteUrl = root.optString("siteUrl", ""),
                token = root.optString("token").takeIf { it.isNotEmpty() },
                tokenExpiresAt = root.optLong("tokenExpiresAt", 0L),
                // Kept as text rather than parsed here: this runs on the
                // platform thread, and the rules are only ever read by the
                // worker. An empty array is stored as an empty string, which
                // [ResourceAlertEvaluator.parseRules] reads as "no rules".
                resourceRules = root.optJSONArray("resourceRules")
                    ?.toString()
                    ?.takeIf { it != "[]" }
                    ?: "",
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse alert settings payload: ${e.message}")
            null
        }
    }

    private fun token(context: Context): String? {
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
            Log.w(TAG, "Dropping undecryptable alert token: ${e.message}")
            setToken(context, null)
            null
        }
    }

    private fun setToken(context: Context, token: String?) {
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
            Log.w(TAG, "Could not store alert token: ${e.message}")
            prefs.edit().remove(KEY_TOKEN).apply()
        }
    }

    @Synchronized
    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        try {
            (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        } catch (e: Exception) {
            Log.w(TAG, "Replacing unusable alert key: ${e.message}")
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
}
