package net.pixpark.fbexample.beautypanel;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import android.widget.Toast;
import java.io.ByteArrayOutputStream;
import net.pixpark.facebetter.BeautyEffectEngine;
import net.pixpark.facebetter.BeautyParams.*;
import net.pixpark.fbexample.BeautyResourceLoader;
import net.pixpark.fbexample.R;

/** Maps panel tab/function/value to engine API; applies params, reset, and virtual_bg preset. */
public class BeautyParamApplier {
  private static final String TAG = "BeautyParamApplier";

  private final BeautyEffectEngine mEngine;
  private final Context mContext;

  public BeautyParamApplier(Context context, BeautyEffectEngine engine) {
    mContext = context.getApplicationContext();
    mEngine = engine;
  }

  public void apply(String tab, String function, float value) {
    if (mEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }

    try {
      switch (tab) {
        case "beauty":
          applyBeautyBasic(function, value);
          break;
        case "reshape":
          applyReshape(function, value);
          break;
        case "makeup":
          applyMakeup(function, value);
          break;
        case "virtual_bg":
          applyVirtualBackground(function, value);
          break;
        case "filter":
          applyFilter(function, value);
          break;
        case "sticker":
          applySticker(function, value);
          break;
        default:
          Log.w(TAG, "Unknown tab: " + tab);
          break;
      }
    } catch (Exception e) {
      Log.e(TAG, "Error applying beauty param", e);
    }
  }

  private void applyBeautyBasic(String function, float value) {
    switch (function) {
      case "white":
        mEngine.setWhitening(value);
        Log.d(TAG, "Set WHITENING: " + value);
        break;
      case "smooth":
        mEngine.setSmoothing(value);
        Log.d(TAG, "Set SMOOTHING: " + value);
        break;
      case "rosiness":
        mEngine.setRosiness(value);
        Log.d(TAG, "Set ROSINESS: " + value);
        break;
      default:
        Log.w(TAG, "Unknown beauty function: " + function);
        break;
    }
  }

  private void applyReshape(String function, float value) {
    Reshape param = mapToReshape(function);
    if (param != null) {
      mEngine.setReshape(param, value);
      Log.d(TAG, "Set " + param + ": " + value);
    } else {
      Log.w(TAG, "Unknown reshape function: " + function);
    }
  }

  private void applyMakeup(String function, float value) {
    switch (function) {
      case "lipstick":
        mEngine.setLipstick(value);
        Log.d(TAG, "Set LIPSTICK: " + value);
        break;
      case "blush":
        mEngine.setBlush(value);
        Log.d(TAG, "Set BLUSH: " + value);
        break;
      default:
        Log.w(TAG, "Unknown makeup function: " + function);
        break;
    }
  }

  private void applyVirtualBackground(String function, float value) {
    if ("none".equals(function)) {
      mEngine.clearVirtualBackground();
      Log.d(TAG, "Set virtual background: NONE");
    } else if ("blur".equals(function)) {
      mEngine.setVirtualBackgroundBlur(value);
      Log.d(TAG, "Set virtual background: BLUR " + value);
    } else if ("preset".equals(function)) {
      Bitmap presetBitmap = BitmapFactory.decodeResource(mContext.getResources(), R.drawable.back_mobile);
      if (presetBitmap != null) {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        if (presetBitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)) {
          mEngine.setVirtualBackground(stream.toByteArray());
          Log.d(TAG, "Preset background set: " + presetBitmap.getWidth() + "x" + presetBitmap.getHeight());
        } else {
          Log.e(TAG, "Failed to encode preset background bitmap");
          Toast.makeText(mContext, mContext.getString(R.string.failed_to_load_preset_background), Toast.LENGTH_SHORT).show();
        }
      } else {
        Log.e(TAG, "Failed to load preset background bitmap");
        Toast.makeText(mContext, mContext.getString(R.string.failed_to_load_preset_background_image), Toast.LENGTH_SHORT).show();
      }
    } else if (function != null && function.startsWith("image")) {
      Log.w(TAG, "BACKGROUND_IMAGE not implemented, function=" + function);
    } else {
      Log.w(TAG, "Unknown virtual_bg function: " + function);
    }
  }

  private void applyFilter(String function, float value) {
    if ("none".equals(function) || value == 0.0f) {
      mEngine.clearFilter();
      Log.d(TAG, "Filter disabled");
    } else {
      byte[] data = BeautyResourceLoader.loadFilter(mContext, function);
      if (data == null) {
        Log.e(TAG, "Filter asset not found: " + function);
        return;
      }
      mEngine.setFilter(data);
      mEngine.setFilterIntensity(value);
      Log.d(TAG, "Set filter: " + function + ", intensity: " + value);
    }
  }

  private void applySticker(String function, float value) {
    if ("none".equals(function) || value == 0.0f) {
      mEngine.clearSticker();
      Log.d(TAG, "Sticker disabled");
    } else {
      byte[] data = BeautyResourceLoader.loadSticker(mContext, function);
      if (data == null) {
        Log.e(TAG, "Sticker asset not found: " + function);
        return;
      }
      mEngine.setSticker(data);
      Log.d(TAG, "Set sticker: " + function);
    }
  }

  private static Reshape mapToReshape(String function) {
    switch (function) {
      case "thin_face":
        return Reshape.FACE_THIN;
      case "v_face":
        return Reshape.FACE_V_SHAPE;
      case "narrow_face":
        return Reshape.FACE_NARROW;
      case "short_face":
        return Reshape.FACE_SHORT;
      case "cheekbone":
        return Reshape.CHEEKBONE;
      case "jawbone":
        return Reshape.JAWBONE;
      case "chin":
        return Reshape.CHIN;
      case "nose_slim":
        return Reshape.NOSE_SLIM;
      case "big_eye":
        return Reshape.EYE_SIZE;
      case "eye_distance":
        return Reshape.EYE_DISTANCE;
      case "face_small":
        return Reshape.FACE_SMALL;
      case "forehead":
        return Reshape.FOREHEAD;
      case "nose_long":
        return Reshape.NOSE_LONG;
      case "philtrum":
        return Reshape.PHILTRUM;
      case "mouth_size":
        return Reshape.MOUTH_SIZE;
      case "mouth_position":
        return Reshape.MOUTH_POSITION;
      case "mouth_smile":
        return Reshape.MOUTH_SMILE;
      case "lip_thickness":
        return Reshape.LIP_THICKNESS;
      case "eye_round":
        return Reshape.EYE_ROUND;
      case "eye_position":
        return Reshape.EYE_POSITION;
      case "eye_angle":
        return Reshape.EYE_ANGLE;
      case "eye_corner_open":
        return Reshape.EYE_CORNER_OPEN;
      case "lower_eyelid":
        return Reshape.LOWER_EYELID;
      case "brow_position":
        return Reshape.BROW_POSITION;
      case "brow_distance":
        return Reshape.BROW_DISTANCE;
      case "brow_thickness":
        return Reshape.BROW_THICKNESS;
      default:
        return null;
    }
  }

  private void resetAllReshape() {
    for (Reshape param : Reshape.values()) {
      mEngine.setReshape(param, 0.0f);
    }
  }

  public void resetAll() {
    if (mEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }
    try {
      mEngine.setWhitening(0.0f);
      mEngine.setSmoothing(0.0f);
      mEngine.setRosiness(0.0f);

      resetAllReshape();

      mEngine.setLipstick(0.0f);
      mEngine.setBlush(0.0f);

      mEngine.clearVirtualBackground();

      mEngine.clearFilter();
      mEngine.clearSticker();

      Log.d(TAG, "All beauty params reset to 0");
    } catch (Exception e) {
      Log.e(TAG, "Error resetting beauty params", e);
    }
  }

  public void resetTab(String tab) {
    if (mEngine == null) return;
    try {
      switch (tab) {
        case "beauty":
          mEngine.setWhitening(0.0f);
          mEngine.setSmoothing(0.0f);
          mEngine.setRosiness(0.0f);
          break;
        case "reshape":
          resetAllReshape();
          break;
        case "makeup":
          mEngine.setLipstick(0.0f);
          mEngine.setBlush(0.0f);
          break;
        case "virtual_bg":
          mEngine.clearVirtualBackground();
          break;
        case "filter":
          mEngine.clearFilter();
          break;
        case "sticker":
          mEngine.clearSticker();
          break;
        case "body":
        case "quality":
        default:
          break;
      }
    } catch (Exception e) {
      Log.e(TAG, "resetBeautyTab error", e);
    }
  }
}
