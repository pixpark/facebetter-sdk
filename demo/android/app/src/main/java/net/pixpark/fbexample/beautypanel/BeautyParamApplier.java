package net.pixpark.fbexample.beautypanel;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import android.widget.Toast;
import net.pixpark.facebetter.BeautyEffectEngine;
import net.pixpark.facebetter.BeautyParams.*;
import net.pixpark.facebetter.ImageFrame;
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
        mEngine.setBeautyParam(BasicParam.WHITENING, value);
        Log.d(TAG, "Set WHITENING: " + value);
        break;
      case "smooth":
        mEngine.setBeautyParam(BasicParam.SMOOTHING, value);
        Log.d(TAG, "Set SMOOTHING: " + value);
        break;
      case "rosiness":
        mEngine.setBeautyParam(BasicParam.ROSINESS, value);
        Log.d(TAG, "Set ROSINESS: " + value);
        break;
      default:
        Log.w(TAG, "Unknown beauty function: " + function);
        break;
    }
  }

  private void applyReshape(String function, float value) {
    ReshapeParam param = mapToReshapeParam(function);
    if (param != null) {
      mEngine.setBeautyParam(param, value);
      Log.d(TAG, "Set " + param + ": " + value);
    } else {
      Log.w(TAG, "Unknown reshape function: " + function);
    }
  }

  private void applyMakeup(String function, float value) {
    MakeupParam param = mapToMakeupParam(function);
    if (param != null) {
      mEngine.setBeautyParam(param, value);
      Log.d(TAG, "Set " + param + ": " + value);
    } else {
      Log.w(TAG, "Unknown makeup function: " + function);
    }
  }

  private void applyVirtualBackground(String function, float value) {
    VirtualBackgroundOptions options = new VirtualBackgroundOptions();
    if ("none".equals(function)) {
      options.mode = BackgroundMode.NONE;
      mEngine.setVirtualBackground(options);
      Log.d(TAG, "Set virtual background: NONE");
    } else if ("blur".equals(function)) {
      options.mode = BackgroundMode.BLUR;
      mEngine.setVirtualBackground(options);
      Log.d(TAG, "Set virtual background: BLUR");
    } else if ("preset".equals(function)) {
      Bitmap presetBitmap = BitmapFactory.decodeResource(mContext.getResources(), R.drawable.back_mobile);
      if (presetBitmap != null) {
        ImageFrame imageFrame = ImageFrame.createWithBitmap(presetBitmap);
        if (imageFrame != null) {
          options.mode = BackgroundMode.IMAGE;
          options.backgroundImage = imageFrame;
          mEngine.setVirtualBackground(options);
          Log.d(TAG, "Preset background set: " + presetBitmap.getWidth() + "x" + presetBitmap.getHeight());
        } else {
          Log.e(TAG, "Failed to create ImageFrame from bitmap");
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
      mEngine.enableBeautyType(BeautyType.FILTER, false);
      mEngine.setFilter("");
      Log.d(TAG, "Filter disabled");
    } else {
      mEngine.enableBeautyType(BeautyType.FILTER, true);
      mEngine.setFilter(function);
      mEngine.setFilterIntensity(value);
      Log.d(TAG, "Set filter: " + function + ", intensity: " + value);
    }
  }

  private void applySticker(String function, float value) {
    if ("none".equals(function) || value == 0.0f) {
      mEngine.setSticker("");
      Log.d(TAG, "Sticker disabled");
    } else {
      mEngine.setSticker(function);
      Log.d(TAG, "Set sticker: " + function);
    }
  }

  private static ReshapeParam mapToReshapeParam(String function) {
    switch (function) {
      case "thin_face":
        return ReshapeParam.FACE_THIN;
      case "v_face":
        return ReshapeParam.FACE_V_SHAPE;
      case "narrow_face":
        return ReshapeParam.FACE_NARROW;
      case "short_face":
        return ReshapeParam.FACE_SHORT;
      case "cheekbone":
        return ReshapeParam.CHEEKBONE;
      case "jawbone":
        return ReshapeParam.JAWBONE;
      case "chin":
        return ReshapeParam.CHIN;
      case "nose_slim":
        return ReshapeParam.NOSE_SLIM;
      case "big_eye":
        return ReshapeParam.EYE_SIZE;
      case "eye_distance":
        return ReshapeParam.EYE_DISTANCE;
      default:
        return null;
    }
  }

  private static MakeupParam mapToMakeupParam(String function) {
    switch (function) {
      case "lipstick":
        return MakeupParam.LIPSTICK;
      case "blush":
        return MakeupParam.BLUSH;
      default:
        return null;
    }
  }

  public void resetAll() {
    if (mEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }
    try {
      mEngine.setBeautyParam(BasicParam.WHITENING, 0.0f);
      mEngine.setBeautyParam(BasicParam.SMOOTHING, 0.0f);
      mEngine.setBeautyParam(BasicParam.ROSINESS, 0.0f);

      mEngine.setBeautyParam(ReshapeParam.FACE_THIN, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.FACE_V_SHAPE, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.FACE_NARROW, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.FACE_SHORT, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.CHEEKBONE, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.JAWBONE, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.CHIN, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.NOSE_SLIM, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.EYE_SIZE, 0.0f);
      mEngine.setBeautyParam(ReshapeParam.EYE_DISTANCE, 0.0f);

      mEngine.setBeautyParam(MakeupParam.LIPSTICK, 0.0f);
      mEngine.setBeautyParam(MakeupParam.BLUSH, 0.0f);

      VirtualBackgroundOptions options = new VirtualBackgroundOptions();
      options.mode = BackgroundMode.NONE;
      mEngine.setVirtualBackground(options);

      mEngine.enableBeautyType(BeautyType.FILTER, false);
      mEngine.setFilter("");
      mEngine.setFilterIntensity(0.0f);

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
          mEngine.setBeautyParam(BasicParam.WHITENING, 0.0f);
          mEngine.setBeautyParam(BasicParam.SMOOTHING, 0.0f);
          mEngine.setBeautyParam(BasicParam.ROSINESS, 0.0f);
          break;
        case "reshape":
          mEngine.setBeautyParam(ReshapeParam.FACE_THIN, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.FACE_V_SHAPE, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.FACE_NARROW, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.FACE_SHORT, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.CHEEKBONE, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.JAWBONE, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.CHIN, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.NOSE_SLIM, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.EYE_SIZE, 0.0f);
          mEngine.setBeautyParam(ReshapeParam.EYE_DISTANCE, 0.0f);
          break;
        case "makeup":
          mEngine.setBeautyParam(MakeupParam.LIPSTICK, 0.0f);
          mEngine.setBeautyParam(MakeupParam.BLUSH, 0.0f);
          break;
        case "virtual_bg":
          VirtualBackgroundOptions options = new VirtualBackgroundOptions();
          options.mode = BackgroundMode.NONE;
          mEngine.setVirtualBackground(options);
          break;
        case "filter":
          mEngine.enableBeautyType(BeautyType.FILTER, false);
          mEngine.setFilter("");
          mEngine.setFilterIntensity(0.0f);
          break;
        case "sticker":
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
