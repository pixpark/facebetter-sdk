package net.pixpark.fbexample.beauty

import android.content.Context
import net.pixpark.facebetter.BeautyParams.Reshape
import net.pixpark.fbexample.AppLocale
import org.json.JSONObject

interface BeautySession {
    val params: StudioParams
    var tab: BeautyTab
    var selectedSkin: SkinItem
    var selectedReshape: Reshape
    var selectedMakeup: MakeupItem
    var panelExpanded: Boolean
    val locale: AppLocale
    fun t(key: String): String
    fun updateParams(transform: StudioParams.() -> StudioParams)
    fun filterLabel(id: String): String
}

object StudioPrefs {
    const val PREFS = "fb.studio"
    const val LOCALE_KEY = "locale"
}

fun detectStudioLocale(context: Context): AppLocale {
    val saved = context.getSharedPreferences(StudioPrefs.PREFS, 0)
        .getString(StudioPrefs.LOCALE_KEY, null)
    if (saved != null) {
        return AppLocale.fromCode(saved)
    }
    val language = java.util.Locale.getDefault().language
    return if (language.startsWith("zh")) AppLocale.ZH else AppLocale.EN
}

fun persistStudioLocale(context: Context, locale: AppLocale) {
    context.getSharedPreferences(StudioPrefs.PREFS, 0)
        .edit()
        .putString(StudioPrefs.LOCALE_KEY, locale.name.lowercase())
        .apply()
}

fun loadFilterLabels(context: Context): Map<String, Pair<String, String>> {
    val json = runCatching {
        context.assets.open("facebetter/filter_mapping.json").use { it.bufferedReader().readText() }
    }.getOrNull() ?: return emptyMap()
    val filters = JSONObject(json).optJSONObject("filters") ?: return emptyMap()
    val labels = mutableMapOf<String, Pair<String, String>>()
    val keys = filters.keys()
    while (keys.hasNext()) {
        val id = keys.next()
        val row = filters.optJSONObject(id) ?: continue
        labels[id] = row.optString("zh", id) to row.optString("en", id)
    }
    return labels
}
