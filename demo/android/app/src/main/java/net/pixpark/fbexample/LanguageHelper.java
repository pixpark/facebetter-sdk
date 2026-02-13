package net.pixpark.fbexample;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;
import java.util.Locale;

/**
 * Language settings helper class
 * Supports saving and reading user-selected language, defaults to system language
 */
public class LanguageHelper {
  private static final String PREFS_NAME = "app_prefs";
  private static final String KEY_LANGUAGE = "selected_language";
  public static final String LANGUAGE_AUTO = "auto";  // Auto (use system language)
  public static final String LANGUAGE_EN = "en";       // English
  public static final String LANGUAGE_ZH = "zh";       // Chinese

  /**
   * Get current language code
   * @param context Context
   * @return Language code: "auto", "en", "zh"
   */
  public static String getLanguage(Context context) {
    SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    return prefs.getString(KEY_LANGUAGE, LANGUAGE_AUTO);
  }

  /**
   * Set language
   * @param context Context
   * @param languageCode Language code: "auto", "en", "zh"
   */
  public static void setLanguage(Context context, String languageCode) {
    SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    prefs.edit().putString(KEY_LANGUAGE, languageCode).apply();
  }

  /**
   * Apply language settings to Context
   * @param context Context
   */
  public static void applyLanguage(Context context) {
    String languageCode = getLanguage(context);
    Locale locale;

    if (LANGUAGE_AUTO.equals(languageCode)) {
      // Use system language
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        locale = context.getResources().getConfiguration().getLocales().get(0);
      } else {
        locale = context.getResources().getConfiguration().locale;
      }
    } else if (LANGUAGE_ZH.equals(languageCode)) {
      locale = new Locale("zh", "CN");
    } else {
      locale = Locale.ENGLISH;
    }

    updateResources(context, locale);
  }

  /**
   * Update Context language configuration
   */
  private static void updateResources(Context context, Locale locale) {
    Locale.setDefault(locale);
    Resources res = context.getResources();
    Configuration config = new Configuration(res.getConfiguration());

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      config.setLocale(locale);
      context.getResources().updateConfiguration(config, res.getDisplayMetrics());
    } else {
      config.locale = locale;
      res.updateConfiguration(config, res.getDisplayMetrics());
    }
  }

  /**
   * Get language display name
   */
  public static String getLanguageDisplayName(Context context, String languageCode) {
    if (LANGUAGE_AUTO.equals(languageCode)) {
      return context.getString(R.string.language_auto);
    } else if (LANGUAGE_ZH.equals(languageCode)) {
      return context.getString(R.string.language_chinese);
    } else {
      return context.getString(R.string.language_english);
    }
  }
}
