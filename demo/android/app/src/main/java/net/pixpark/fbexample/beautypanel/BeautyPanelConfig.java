package net.pixpark.fbexample.beautypanel;

import android.content.Context;
import net.pixpark.fbexample.R;

/** Tab + function list config; Controller builds views from this. */
public final class BeautyPanelConfig {

  public static final int TYPE_SLIDER = 0;
  public static final int TYPE_TOGGLE = 1;

  public static final class FunctionConfig {
    public final String key;
    public final String label;
    public final int iconRes;
    public final boolean enabled;
    public final int type;
    public final String[] subOptions;

    public FunctionConfig(String key, String label, int iconRes, boolean enabled, int type) {
      this.key = key;
      this.label = label;
      this.iconRes = iconRes;
      this.enabled = enabled;
      this.type = type;
      this.subOptions = null;
    }

    public FunctionConfig(String key, String label, int iconRes, boolean enabled, int type,
        String[] subOptions) {
      this.key = key;
      this.label = label;
      this.iconRes = iconRes;
      this.enabled = enabled;
      this.type = type;
      this.subOptions = subOptions;
    }
  }

  public static FunctionConfig[] getFunctionsForTab(String tab, Context context) {
    if (context == null) return new FunctionConfig[0];
    switch (tab) {
      case "beauty":
        return new FunctionConfig[] {
            new FunctionConfig("white", context.getString(R.string.beauty_whitening), R.drawable.meiyan, true, TYPE_SLIDER),
            new FunctionConfig("dark", context.getString(R.string.beauty_dark), R.drawable.huanfase, false, TYPE_SLIDER),
            new FunctionConfig("smooth", context.getString(R.string.beauty_smoothing), R.drawable.meiyan2, true, TYPE_SLIDER),
            new FunctionConfig("rosiness", context.getString(R.string.beauty_rosiness), R.drawable.meiyan, true, TYPE_SLIDER),
        };
      case "reshape":
        return new FunctionConfig[] {
            new FunctionConfig("thin_face", context.getString(R.string.reshape_thin_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("v_face", context.getString(R.string.reshape_v_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("narrow_face", context.getString(R.string.reshape_narrow_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("short_face", context.getString(R.string.reshape_short_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("cheekbone", context.getString(R.string.reshape_cheekbone), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("jawbone", context.getString(R.string.reshape_jawbone), R.drawable.jawbone, true, TYPE_SLIDER),
            new FunctionConfig("chin", context.getString(R.string.reshape_chin), R.drawable.chin, true, TYPE_SLIDER),
            new FunctionConfig("nose_slim", context.getString(R.string.reshape_nose_slim), R.drawable.nose, true, TYPE_SLIDER),
            new FunctionConfig("big_eye", context.getString(R.string.reshape_big_eye), R.drawable.eyes, true, TYPE_SLIDER),
            new FunctionConfig("eye_distance", context.getString(R.string.reshape_eye_distance), R.drawable.eyes, true, TYPE_SLIDER),
        };
      case "makeup":
        return new FunctionConfig[] {
            new FunctionConfig("lipstick", context.getString(R.string.makeup_lipstick), R.drawable.lipstick, true, TYPE_SLIDER,
                new String[] {
                    context.getString(R.string.makeup_lipstick_style_moist),
                    context.getString(R.string.makeup_lipstick_style_vitality),
                    context.getString(R.string.makeup_lipstick_style_retro)
                }),
            new FunctionConfig("blush", context.getString(R.string.makeup_blush), R.drawable.meizhuang, true, TYPE_SLIDER,
                new String[] {
                    context.getString(R.string.makeup_blush_style_japanese),
                    context.getString(R.string.makeup_blush_style_sector),
                    context.getString(R.string.makeup_blush_style_tipsy)
                }),
            new FunctionConfig("eyebrow", context.getString(R.string.makeup_eyebrow), R.drawable.eyebrow, true, TYPE_SLIDER,
                new String[] {
                    context.getString(R.string.makeup_eyebrow_style_standard),
                    context.getString(R.string.makeup_eyebrow_style_willow),
                    context.getString(R.string.makeup_eyebrow_style_classical)
                }),
            new FunctionConfig("eyeshadow", context.getString(R.string.makeup_eyeshadow), R.drawable.eyeshadow, true, TYPE_SLIDER,
                new String[] {
                    context.getString(R.string.makeup_eyeshadow_style_1),
                    context.getString(R.string.makeup_eyeshadow_style_2),
                    context.getString(R.string.makeup_eyeshadow_style_3)
                }),
        };
      case "filter":
        return new FunctionConfig[] {
            new FunctionConfig("initial_heart", context.getString(R.string.filter_initial_heart), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("first_love", context.getString(R.string.filter_first_love), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("vivid", context.getString(R.string.filter_vivid), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("confession", context.getString(R.string.filter_confession), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("milk_tea", context.getString(R.string.filter_milk_tea), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("mousse", context.getString(R.string.filter_mousse), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("japanese", context.getString(R.string.filter_japanese), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("dawn", context.getString(R.string.filter_dawn), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("cookie", context.getString(R.string.filter_cookie), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("lively", context.getString(R.string.filter_lively), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("pure", context.getString(R.string.filter_pure), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("fair", context.getString(R.string.filter_fair), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("snow", context.getString(R.string.filter_snow), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("plain", context.getString(R.string.filter_plain), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("natural", context.getString(R.string.filter_natural_portrait), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("rose", context.getString(R.string.filter_rose), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("extraordinary", context.getString(R.string.filter_extraordinary), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("tender", context.getString(R.string.filter_tender), R.drawable.lvjing, true, TYPE_SLIDER),
            new FunctionConfig("tender_2", context.getString(R.string.filter_tender_2), R.drawable.lvjing, true, TYPE_SLIDER),
        };
      case "sticker":
        return new FunctionConfig[] {
            new FunctionConfig("rabbit", context.getString(R.string.sticker_rabbit), R.drawable.rabbit, true, TYPE_TOGGLE),
        };
      case "body":
        return new FunctionConfig[] {
            new FunctionConfig("slim", context.getString(R.string.body_slim), R.drawable.meiti, false, TYPE_SLIDER),
        };
      case "virtual_bg":
        return new FunctionConfig[] {
            new FunctionConfig("blur", context.getString(R.string.virtual_bg_blur), R.drawable.blur, true, TYPE_TOGGLE),
            new FunctionConfig("preset", context.getString(R.string.virtual_bg_preset), R.drawable.back_preset, true, TYPE_TOGGLE),
            new FunctionConfig("image", context.getString(R.string.virtual_bg_image), R.drawable.gallery, true, TYPE_TOGGLE),
        };
      case "quality":
        return new FunctionConfig[] {
            new FunctionConfig("sharpen", context.getString(R.string.quality_sharpen), R.drawable.huazhitiaozheng2, false, TYPE_SLIDER),
        };
      default:
        return new FunctionConfig[0];
    }
  }

  private BeautyPanelConfig() {}
}
