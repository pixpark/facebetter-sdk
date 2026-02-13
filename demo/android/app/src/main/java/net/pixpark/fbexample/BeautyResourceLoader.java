package net.pixpark.fbexample;

import android.content.Context;
import android.util.Log;
import net.pixpark.facebetter.BeautyEffectEngine;
import java.io.InputStream;

/** Registers filters and stickers from assets to engine. */
public final class BeautyResourceLoader {
  private static final String TAG = "BeautyResourceLoader";

  private static final String[] PORTRAIT_FILTERS = {
      "confession", "cookie", "dawn", "extraordinary", "fair", "first_love",
      "initial_heart", "japanese", "lively", "milk_tea", "mousse", "natural",
      "plain", "pure", "rose", "snow", "tender", "tender_2", "vivid"
  };

  public static void registerFilters(BeautyEffectEngine engine, Context context) {
    if (engine == null || context == null) return;
    for (String filterId : PORTRAIT_FILTERS) {
      try {
        String path = "filters/portrait/" + filterId + "/" + filterId + ".fbd";
        InputStream is = context.getAssets().open(path);
        int size = is.available();
        byte[] buffer = new byte[size];
        is.read(buffer);
        is.close();

        int result = engine.registerFilter(filterId, buffer);
        if (result == 0) {
          Log.d(TAG, "Filter registered: " + filterId);
        } else {
          Log.e(TAG, "Failed to register filter: " + filterId + ", result: " + result);
        }
      } catch (Exception e) {
        Log.e(TAG, "Error registering filter: " + filterId, e);
      }
    }
  }

  public static void registerStickers(BeautyEffectEngine engine, Context context) {
    if (engine == null || context == null) return;
    try {
      InputStream is = context.getAssets().open("stickers/face/rabbit/rabbit.fbd");
      int size = is.available();
      byte[] buffer = new byte[size];
      is.read(buffer);
      is.close();

      int result = engine.registerSticker("rabbit", buffer);
      if (result == 0) {
        Log.d(TAG, "Sticker registered: rabbit");
      } else {
        Log.e(TAG, "Failed to register rabbit sticker, result: " + result);
      }
    } catch (Exception e) {
      Log.e(TAG, "Error registering rabbit sticker", e);
    }
  }

  private BeautyResourceLoader() {}
}
