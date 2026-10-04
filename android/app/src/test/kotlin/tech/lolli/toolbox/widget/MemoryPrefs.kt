package tech.lolli.toolbox.widget

import android.content.SharedPreferences
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy

/**
 * An in-memory [SharedPreferences] for the widget tests.
 *
 * This module has no Robolectric and no androidx.test — only JUnit and
 * org.json — so the preferences the widget persists through are faked at the
 * interface and backed by [store].
 */
fun memoryPrefs(store: MutableMap<String, String>): SharedPreferences {
    val editor = object : InvocationHandler {
        override fun invoke(proxy: Any?, method: Method, args: Array<out Any>?): Any? {
            when (method.name) {
                "putString" -> store[args!![0] as String] = args[1] as String
                "putInt" -> store[args!![0] as String] = (args[1] as Int).toString()
                "putLong" -> store[args!![0] as String] = (args[1] as Long).toString()
                "putBoolean" -> store[args!![0] as String] = (args[1] as Boolean).toString()
                "remove" -> store.remove(args!![0] as String)
                "clear" -> store.clear()
                "apply" -> return Unit
                "commit" -> return true
                else -> return null
            }
            return proxy
        }
    }
    val mockEditor = Proxy.newProxyInstance(
        SharedPreferences.Editor::class.java.classLoader,
        arrayOf(SharedPreferences.Editor::class.java),
        editor,
    ) as SharedPreferences.Editor

    val prefs = object : InvocationHandler {
        override fun invoke(proxy: Any?, method: Method, args: Array<out Any>?): Any? {
            when (method.name) {
                "edit" -> return mockEditor
                "getString" -> return store[args!![0] as String] ?: args[1]
                "getInt" -> return store[args!![0] as String]?.toIntOrNull() ?: args[1]
                "getLong" -> return store[args!![0] as String]?.toLongOrNull() ?: args[1]
                "getBoolean" ->
                    return store[args!![0] as String]?.toBooleanStrictOrNull() ?: args[1]
                "contains" -> return store.containsKey(args!![0] as String)
                "getAll" -> return store.toMap()
            }
            return null
        }
    }
    return Proxy.newProxyInstance(
        SharedPreferences::class.java.classLoader,
        arrayOf(SharedPreferences::class.java),
        prefs,
    ) as SharedPreferences
}
