package net.pixpark.fbexample;

import android.content.Context;
import android.util.Log;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

/** Loads filters and stickers from assets. */
public final class BeautyResourceLoader {
  private static final String TAG = "BeautyResourceLoader";
  private static final Map<String, byte[]> FILTER_CACHE = new HashMap<>();
  private static final Map<String, byte[]> STICKER_CACHE = new HashMap<>();

  public static byte[] loadFilter(Context context, String filterId) {
    if (context == null || filterId == null || filterId.isEmpty()) {
      return null;
    }
    byte[] cached = FILTER_CACHE.get(filterId);
    if (cached != null) {
      return cached;
    }
    String path = "filters/portrait/" + filterId + "/" + filterId + ".fbd";
    try (InputStream is = context.getAssets().open(path)) {
      int size = is.available();
      byte[] buffer = new byte[size];
      int read = is.read(buffer);
      if (read != size) {
        Log.w(TAG, "Filter read short: " + path + " " + read + "/" + size);
      }
      FILTER_CACHE.put(filterId, buffer);
      Log.d(TAG, "Loaded filter: " + filterId + " from " + path);
      return buffer;
    } catch (Exception e) {
      Log.e(TAG, "Failed to load filter from assets: " + filterId, e);
      return null;
    }
  }

  public static byte[] loadSticker(Context context, String stickerId) {
    if (context == null || stickerId == null || stickerId.isEmpty()) {
      return null;
    }
    byte[] cached = STICKER_CACHE.get(stickerId);
    if (cached != null) {
      return cached;
    }
    String[] candidates = {
        "stickers/face/" + stickerId + "/" + stickerId + ".fbd",
        "stickers/face/" + stickerId + ".fbd"
    };
    for (String path : candidates) {
      try (InputStream is = context.getAssets().open(path)) {
        int size = is.available();
        byte[] buffer = new byte[size];
        int read = is.read(buffer);
        if (read != size) {
          Log.w(TAG, "Sticker read short: " + path + " " + read + "/" + size);
        }
        STICKER_CACHE.put(stickerId, buffer);
        Log.d(TAG, "Loaded sticker: " + stickerId + " from " + path);
        return buffer;
      } catch (Exception ignored) {
        // try next candidate
      }
    }
    Log.e(TAG, "Failed to load sticker from assets: " + stickerId);
    return null;
  }

  private BeautyResourceLoader() {}
}
