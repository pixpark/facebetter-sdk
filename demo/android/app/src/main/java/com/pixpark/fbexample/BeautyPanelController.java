package com.pixpark.fbexample;

import android.app.Activity;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.constraintlayout.widget.ConstraintLayout;

public class BeautyPanelController {
  private static final String TAG = "BeautyPanelController";

  // Button type constants
  private static final int TYPE_SLIDER = 0; // Slider type: requires intensity adjustment
  private static final int TYPE_TOGGLE = 1; // Toggle type: click to switch on/off

  // Function configuration data structure
  private static class FunctionConfig {
    String key; // Function key: e.g. "blur", "white", "lipstick"
    String label; // Display text: e.g. "Blur", "Whitening", "Lipstick"
    int iconRes; // Icon resource
    boolean enabled; // Whether available
    int type; // Type: TYPE_SLIDER(0) or TYPE_TOGGLE(1)
    String[] subOptions; // Sub-options (needed for makeup functions, e.g. {"Style1","Style2","Style3"})

    FunctionConfig(String key, String label, int iconRes, boolean enabled, int type) {
      this.key = key;
      this.label = label;
      this.iconRes = iconRes;
      this.enabled = enabled;
      this.type = type;
    }

    FunctionConfig withSubOptions(String[] subOptions) {
      this.subOptions = subOptions;
      return this;
    }
  }

  // Beauty parameter change callback interface
  public interface BeautyParamCallback {
    /**
     * Beauty parameter change callback
     * @param tab Current Tab: "beauty", "reshape", "makeup", "virtual_bg", etc.
     * @param function Current function: "white", "smooth", "blur", etc.
     * @param value Parameter value:
     *              - Slider type function: 0.0 ~ 1.0 represents intensity
     *              - Toggle type function: 1.0 means on, 0.0 means off
     */
    void onBeautyParamChanged(String tab, String function, float value);

    /**
     * Reset all beauty parameters
     */
    void onBeautyReset();

    /**
     * Reset all parameters under specified Tab
     * @param tab Current Tab
     */
    void onBeautyTabReset(String tab);

    /**
     * Image selection callback (for functions that require image selection like virtual background)
     * @param tab Current Tab
     * @param function Current function (e.g. "image")
     */
    void onImageSelectionRequested(String tab, String function);
  }

  private BeautyParamCallback mBeautyParamCallback;

  private View mRootView;
  private android.content.Context mContext;
  private View mBottomControlPanel;

  // Beauty panel
  private ConstraintLayout mBeautyPanelRoot;
  private android.widget.HorizontalScrollView mTabScrollView;
  private TextView mTabBeauty;
  private TextView mTabReshape;
  private TextView mTabMakeup;
  private TextView mTabFilter;
  private TextView mTabSticker;
  private TextView mTabBody;
  private TextView mTabVirtualBg;
  private TextView mTabQuality;

  // Function buttons
  private LinearLayout mFunctionButtonContainer;
  private LinearLayout mBtnBeautyOff;
  private LinearLayout mBtnBeautyWhite;
  private LinearLayout mBtnBeautyDark;
  private LinearLayout mBtnBeautySmooth;
  private LinearLayout mBtnBeautyAi;
  private View mIndicatorBeautyWhite;

  // Sub-option area
  private View mSubOptionScrollView;
  private LinearLayout mBtnSubOption1;
  private LinearLayout mBtnSubOption2;
  private LinearLayout mBtnSubOption3;
  private LinearLayout mBtnSubOption4;

  // Bottom buttons
  private LinearLayout mBottomButtonContainer;
  private LinearLayout mBtnResetBeauty;
  private ImageButton mBtnCapturePanel;
  private LinearLayout mBtnHidePanel;

  // Slider
  private View mBeautySliderLayout;
  private SeekBar mBeautySeekBar;
  private TextView mBeautyValueText;

  // State
  private boolean mIsPanelVisible = false;
  private boolean mIsSubOptionVisible = false;
  private String mCurrentTab = "beauty"; // beauty, reshape, makeup
  private String mCurrentFunction =
      null; // Currently selected function (e.g.: white, dark, smooth, ai, lipstick, blush, etc.)
  // Record slider values (0-100) for each function under each Tab
  private final java.util.Map<String, Integer> mFunctionProgress = new java.util.HashMap<>();
  // Selected indicator views for each function
  private final java.util.Map<String, View> mFunctionIndicatorViews = new java.util.HashMap<>();
  // Record on/off state of toggle type functions
  private final java.util.Map<String, Boolean> mToggleStates = new java.util.HashMap<>();
  // Record button views (for updating toggle state visual feedback)
  private final java.util.Map<String, View> mFunctionButtonViews = new java.util.HashMap<>();
  private String mCurrentSubOption = null; // Currently selected sub-option (e.g.: style1, style2, style3)

  public BeautyPanelController(View rootView) {
    mRootView = rootView;
    mContext = rootView.getContext();
    initViews();
    setupListeners();
  }

  private void initViews() {
    // Beauty panel - Get root view through include ID
    // Note: The include tag itself is the root view of the included layout
    View beautyPanelLayout = mRootView.findViewById(R.id.beauty_panel_layout);
    if (beautyPanelLayout == null) {
      throw new RuntimeException("beauty_panel_layout not found!");
    }

    // The include View is the ConstraintLayout (beauty_panel_root)
    if (beautyPanelLayout instanceof ConstraintLayout) {
      mBeautyPanelRoot = (ConstraintLayout) beautyPanelLayout;
    } else {
      throw new RuntimeException("beauty_panel_layout is not ConstraintLayout!");
    }

    // Tab scroll view
    mTabScrollView = beautyPanelLayout.findViewById(R.id.tab_scroll_view);

    // Tab buttons
    mTabBeauty = beautyPanelLayout.findViewById(R.id.tab_beauty);
    mTabReshape = beautyPanelLayout.findViewById(R.id.tab_reshape);
    mTabMakeup = beautyPanelLayout.findViewById(R.id.tab_makeup);
    mTabFilter = beautyPanelLayout.findViewById(R.id.tab_filter);
    mTabSticker = beautyPanelLayout.findViewById(R.id.tab_sticker);
    mTabBody = beautyPanelLayout.findViewById(R.id.tab_body);
    mTabVirtualBg = beautyPanelLayout.findViewById(R.id.tab_virtual_bg);
    mTabQuality = beautyPanelLayout.findViewById(R.id.tab_quality);

    // Function buttons
    mFunctionButtonContainer = beautyPanelLayout.findViewById(R.id.function_button_container);
    mBtnBeautyOff = beautyPanelLayout.findViewById(R.id.btn_beauty_off);
    mBtnBeautyWhite = beautyPanelLayout.findViewById(R.id.btn_beauty_white);
    mBtnBeautyDark = beautyPanelLayout.findViewById(R.id.btn_beauty_dark);
    mBtnBeautySmooth = beautyPanelLayout.findViewById(R.id.btn_beauty_smooth);
    mBtnBeautyAi = beautyPanelLayout.findViewById(R.id.btn_beauty_ai);
    mIndicatorBeautyWhite = beautyPanelLayout.findViewById(R.id.indicator_beauty_white);

    // Sub-options
    mSubOptionScrollView = beautyPanelLayout.findViewById(R.id.sub_option_scroll_view);
    mBtnSubOption1 = beautyPanelLayout.findViewById(R.id.btn_sub_option_1);
    mBtnSubOption2 = beautyPanelLayout.findViewById(R.id.btn_sub_option_2);
    mBtnSubOption3 = beautyPanelLayout.findViewById(R.id.btn_sub_option_3);
    mBtnSubOption4 = beautyPanelLayout.findViewById(R.id.btn_sub_option_4);

    // Bottom buttons
    mBottomButtonContainer = beautyPanelLayout.findViewById(R.id.bottom_button_container);
    mBtnResetBeauty = beautyPanelLayout.findViewById(R.id.btn_reset_beauty);
    mBtnCapturePanel = beautyPanelLayout.findViewById(R.id.btn_capture_panel);
    mBtnHidePanel = beautyPanelLayout.findViewById(R.id.btn_hide_panel);

    // Slider
    mBeautySliderLayout = mRootView.findViewById(R.id.beauty_slider_layout);
    if (mBeautySliderLayout != null) {
      mBeautySeekBar = mBeautySliderLayout.findViewById(R.id.beauty_seekbar);
      mBeautyValueText = mBeautySliderLayout.findViewById(R.id.beauty_value_text);
    }

    // Bottom control panel (needs to be hidden when beauty panel is shown)
    mBottomControlPanel = mRootView.findViewById(R.id.bottom_panel);
  }

  private void setupListeners() {
    // Tab switching
    if (mTabBeauty != null)
      mTabBeauty.setOnClickListener(v -> switchTab("beauty"));
    if (mTabReshape != null)
      mTabReshape.setOnClickListener(v -> switchTab("reshape"));
    if (mTabMakeup != null)
      mTabMakeup.setOnClickListener(v -> switchTab("makeup"));
    if (mTabFilter != null)
      mTabFilter.setOnClickListener(v -> switchTab("filter"));
    if (mTabSticker != null)
      mTabSticker.setOnClickListener(v -> switchTab("sticker"));
    if (mTabBody != null)
      mTabBody.setOnClickListener(v -> switchTab("body"));
    if (mTabVirtualBg != null)
      mTabVirtualBg.setOnClickListener(v -> switchTab("virtual_bg"));
    if (mTabQuality != null)
      mTabQuality.setOnClickListener(v -> switchTab("quality"));

    // Function buttons
    if (mBtnBeautyOff != null)
      mBtnBeautyOff.setOnClickListener(v -> onBeautyOffClicked());
    // 旧的按钮监听器已移除，现在使用配置驱动方式动态创建按钮
    // 按钮点击事件在 updateFunctionButtons() 中通过 handleFunctionClick() 统一处理

    // Sub-options - 动态获取按钮文本
    if (mBtnSubOption1 != null) {
      mBtnSubOption1.setOnClickListener(v -> {
        String text = getButtonText(mBtnSubOption1);
        onSubOptionClicked(1, text);
      });
    }
    if (mBtnSubOption2 != null) {
      mBtnSubOption2.setOnClickListener(v -> {
        String text = getButtonText(mBtnSubOption2);
        onSubOptionClicked(2, text);
      });
    }
    if (mBtnSubOption3 != null) {
      mBtnSubOption3.setOnClickListener(v -> {
        String text = getButtonText(mBtnSubOption3);
        onSubOptionClicked(3, text);
      });
    }
    if (mBtnSubOption4 != null) {
      mBtnSubOption4.setOnClickListener(v -> {
        String text = getButtonText(mBtnSubOption4);
        onSubOptionClicked(4, text);
      });
    }

    // Bottom buttons
    if (mBtnResetBeauty != null)
      mBtnResetBeauty.setOnClickListener(v -> onResetBeautyClicked());
    if (mBtnCapturePanel != null)
      mBtnCapturePanel.setOnClickListener(v -> onCaptureClicked());
    if (mBtnHidePanel != null)
      mBtnHidePanel.setOnClickListener(v -> onHidePanelClicked());

    // Slider
    if (mBeautySeekBar != null) {
      mBeautySeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
          if (mBeautyValueText != null) {
            // 更新数值
            mBeautyValueText.setText(String.valueOf(progress));

            // 强制测量数值文本的宽度
            mBeautyValueText.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
            int textWidth = mBeautyValueText.getMeasuredWidth();

            // 计算数值显示位置（跟随滑块thumb位置）
            int seekBarWidth =
                seekBar.getWidth() - seekBar.getPaddingLeft() - seekBar.getPaddingRight();
            float thumbPos = (float) progress / seekBar.getMax() * seekBarWidth;

            // 设置数值位置（居中在thumb上方，考虑容器的padding）
            android.widget.FrameLayout.LayoutParams params =
                (android.widget.FrameLayout.LayoutParams) mBeautyValueText.getLayoutParams();

            // 计算左边距：thumb位置 + seekBar左边距 + 容器左边距 - 文本宽度的一半
            int containerPaddingStart = 16; // dp转px需要考虑，这里简化处理
            params.leftMargin = (int) (thumbPos + seekBar.getLeft() - textWidth / 2);

            mBeautyValueText.setLayoutParams(params);
          }
          // 应用美颜参数 - 将进度值(0-100)转换为参数值(0.0-1.0)
          if (fromUser && mCurrentFunction != null) {
            // 保存当前功能的进度（0-100）
            mFunctionProgress.put(buildFunctionKey(mCurrentTab, mCurrentFunction), progress);
          }
          if (fromUser && mCurrentFunction != null && mBeautyParamCallback != null) {
            float paramValue = progress / 100.0f;
            mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, mCurrentFunction, paramValue);
          }
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
          // 开始滑动时显示数值
          if (mBeautyValueText != null) {
            mBeautyValueText.setVisibility(View.VISIBLE);
          }
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
          // 停止滑动时隐藏数值
          if (mBeautyValueText != null) {
            mBeautyValueText.postDelayed(() -> {
              if (mBeautyValueText != null) {
                mBeautyValueText.setVisibility(View.GONE);
              }
            }, 500); // 延迟500ms隐藏
          }
        }
      });
    }
  }

  private void switchTab(String tab) {
    mCurrentTab = tab;
    mCurrentFunction = null;
    mCurrentSubOption = null;

    // 重置所有 Tab 样式
    resetTabStyle(mTabBeauty);
    resetTabStyle(mTabReshape);
    resetTabStyle(mTabMakeup);
    resetTabStyle(mTabFilter);
    resetTabStyle(mTabSticker);
    resetTabStyle(mTabBody);
    resetTabStyle(mTabVirtualBg);
    resetTabStyle(mTabQuality);

    // 设置选中 Tab 样式
    switch (tab) {
      case "beauty":
        setTabSelected(mTabBeauty);
        break;
      case "reshape":
        setTabSelected(mTabReshape);
        break;
      case "makeup":
        setTabSelected(mTabMakeup);
        break;
      case "filter":
        setTabSelected(mTabFilter);
        break;
      case "sticker":
        setTabSelected(mTabSticker);
        break;
      case "body":
        setTabSelected(mTabBody);
        break;
      case "virtual_bg":
        setTabSelected(mTabVirtualBg);
        break;
      case "quality":
        setTabSelected(mTabQuality);
        break;
    }

    // 隐藏子选项和滑块
    hideSubOptions();
    hideSlider();

    // 更新功能按钮显示
    updateFunctionButtons();
    // 刷新一次选中状态
    updateSelectionIndicators();

    // 滚动到选中的 Tab，确保其可见
    scrollToTab(tab);
  }

  /**
   * 滚动到指定的 Tab，确保其在可见区域内
   */
  private void scrollToTab(String tab) {
    if (mTabScrollView == null)
      return;

    TextView targetTab = null;
    switch (tab) {
      case "beauty":
        targetTab = mTabBeauty;
        break;
      case "reshape":
        targetTab = mTabReshape;
        break;
      case "makeup":
        targetTab = mTabMakeup;
        break;
      case "filter":
        targetTab = mTabFilter;
        break;
      case "sticker":
        targetTab = mTabSticker;
        break;
      case "body":
        targetTab = mTabBody;
        break;
      case "virtual_bg":
        targetTab = mTabVirtualBg;
        break;
      case "quality":
        targetTab = mTabQuality;
        break;
    }

    if (targetTab != null) {
      final TextView finalTab = targetTab;
      // 使用 post 确保布局完成后再滚动
      mTabScrollView.post(() -> {
        // 计算目标 Tab 的位置
        int tabLeft = finalTab.getLeft();
        int tabWidth = finalTab.getWidth();
        int scrollViewWidth = mTabScrollView.getWidth();

        // 计算滚动位置，让 Tab 居中显示
        int scrollX = tabLeft - (scrollViewWidth / 2) + (tabWidth / 2);

        // 平滑滚动到目标位置
        mTabScrollView.smoothScrollTo(scrollX, 0);
      });
    }
  }

  /**
   * 重置 Tab 样式为未选中状态
   */
  private void resetTabStyle(TextView tab) {
    if (tab != null) {
      tab.setTextColor(0xFFAAAAAA);
      tab.setTypeface(null, android.graphics.Typeface.NORMAL);
    }
  }

  /**
   * 设置 Tab 为选中状态
   */
  private void setTabSelected(TextView tab) {
    if (tab != null) {
      tab.setTextColor(0xFFFFFFFF);
      tab.setTypeface(null, android.graphics.Typeface.BOLD);
    }
  }

  /**
   * 根据当前 Tab 更新功能按钮的文本和图标
   */
  /**
   * 获取指定 Tab 的功能配置数组
   */
  private FunctionConfig[] getFunctionsForTab(String tab) {
    switch (tab) {
      case "beauty":
        return new FunctionConfig[] {
            new FunctionConfig("white", mContext.getString(R.string.beauty_whitening), R.drawable.meiyan, true, TYPE_SLIDER),
            new FunctionConfig("dark", mContext.getString(R.string.beauty_dark), R.drawable.huanfase, false, TYPE_SLIDER),
            new FunctionConfig("smooth", mContext.getString(R.string.beauty_smoothing), R.drawable.meiyan2, true, TYPE_SLIDER),
            new FunctionConfig("rosiness", mContext.getString(R.string.beauty_rosiness), R.drawable.meiyan, true, TYPE_SLIDER),
        };
      case "reshape":
        return new FunctionConfig[] {
            new FunctionConfig("thin_face", mContext.getString(R.string.reshape_thin_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("v_face", mContext.getString(R.string.reshape_v_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("narrow_face", mContext.getString(R.string.reshape_narrow_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("short_face", mContext.getString(R.string.reshape_short_face), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("cheekbone", mContext.getString(R.string.reshape_cheekbone), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("jawbone", mContext.getString(R.string.reshape_jawbone), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("chin", mContext.getString(R.string.reshape_chin), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("nose_slim", mContext.getString(R.string.reshape_nose_slim), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("big_eye", mContext.getString(R.string.reshape_big_eye), R.drawable.meixing2, true, TYPE_SLIDER),
            new FunctionConfig("eye_distance", mContext.getString(R.string.reshape_eye_distance), R.drawable.meixing2, true, TYPE_SLIDER),
        };
      case "makeup":
        return new FunctionConfig[] {
            new FunctionConfig("lipstick", mContext.getString(R.string.makeup_lipstick), R.drawable.meizhuang, true, TYPE_SLIDER)
                .withSubOptions(new String[] {
                    mContext.getString(R.string.makeup_style_1),
                    mContext.getString(R.string.makeup_style_2),
                    mContext.getString(R.string.makeup_style_3)
                }),
            new FunctionConfig("blush", mContext.getString(R.string.makeup_blush), R.drawable.meizhuang, true, TYPE_SLIDER)
                .withSubOptions(new String[] {
                    mContext.getString(R.string.makeup_style_1),
                    mContext.getString(R.string.makeup_style_2),
                    mContext.getString(R.string.makeup_style_3)
                }),
            new FunctionConfig("eyebrow", mContext.getString(R.string.makeup_eyebrow), R.drawable.meizhuang, true, TYPE_SLIDER)
                .withSubOptions(new String[] {
                    mContext.getString(R.string.makeup_style_1),
                    mContext.getString(R.string.makeup_style_2),
                    mContext.getString(R.string.makeup_style_3)
                }),
            new FunctionConfig("eyeshadow", mContext.getString(R.string.makeup_eyeshadow), R.drawable.meizhuang, true, TYPE_SLIDER)
                .withSubOptions(new String[] {
                    mContext.getString(R.string.makeup_style_1),
                    mContext.getString(R.string.makeup_style_2),
                    mContext.getString(R.string.makeup_style_3)
                }),
        };
      case "filter":
        return new FunctionConfig[] {
            new FunctionConfig("initial_heart", mContext.getString(R.string.filter_initial_heart), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("first_love", mContext.getString(R.string.filter_first_love), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("vivid", mContext.getString(R.string.filter_vivid), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("confession", mContext.getString(R.string.filter_confession), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("milk_tea", mContext.getString(R.string.filter_milk_tea), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("mousse", mContext.getString(R.string.filter_mousse), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("japanese", mContext.getString(R.string.filter_japanese), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("dawn", mContext.getString(R.string.filter_dawn), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("cookie", mContext.getString(R.string.filter_cookie), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("lively", mContext.getString(R.string.filter_lively), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("pure", mContext.getString(R.string.filter_pure), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("fair", mContext.getString(R.string.filter_fair), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("snow", mContext.getString(R.string.filter_snow), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("plain", mContext.getString(R.string.filter_plain), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("natural", mContext.getString(R.string.filter_natural_portrait), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("rose", mContext.getString(R.string.filter_rose), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("extraordinary", mContext.getString(R.string.filter_extraordinary), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("tender", mContext.getString(R.string.filter_tender), R.drawable.lvjing, true, TYPE_TOGGLE),
            new FunctionConfig("tender_2", mContext.getString(R.string.filter_tender_2), R.drawable.lvjing, true, TYPE_TOGGLE),
        };
      case "sticker":
        return new FunctionConfig[] {
            new FunctionConfig("rabbit", mContext.getString(R.string.sticker_rabbit), R.drawable.tiezhi2, true, TYPE_TOGGLE),
        };
      case "body":
        return new FunctionConfig[] {
            new FunctionConfig("slim", mContext.getString(R.string.body_slim), R.drawable.meiti, false, TYPE_SLIDER),
        };
      case "virtual_bg":
        return new FunctionConfig[] {
            new FunctionConfig("blur", mContext.getString(R.string.virtual_bg_blur), R.drawable.blur, true, TYPE_TOGGLE),
            new FunctionConfig("preset", mContext.getString(R.string.virtual_bg_preset), R.drawable.back_preset, true, TYPE_TOGGLE),
            new FunctionConfig("image", mContext.getString(R.string.virtual_bg_image), R.drawable.gallery, true, TYPE_TOGGLE),
        };
      case "quality":
        return new FunctionConfig[] {
            new FunctionConfig("sharpen", mContext.getString(R.string.quality_sharpen), R.drawable.huazhitiaozheng2, false, TYPE_SLIDER),
        };
      default:
        return new FunctionConfig[0];
    }
  }

  /**
   * 统一的按钮点击处理
   */
  private void handleFunctionClick(FunctionConfig config) {
    if (config == null)
      return;

    mCurrentFunction = config.key;

    switch (config.type) {
      case TYPE_TOGGLE:
        // 开关型：切换状态，立即生效
        handleToggleFunction(config);
        break;

      case TYPE_SLIDER:
        // 滑动条型
        if (config.subOptions != null && config.subOptions.length > 0) {
          // 有子选项：显示三级面板（美妆类）
          updateSubOptionButtons(config.subOptions);
          showSubOptions();
          hideSlider();
        } else {
          // 无子选项：直接显示滑动条
          hideSubOptions();
          showSlider();
        }
        break;
    }
  }

  /**
   * 处理开关型功能的点击
   */
  private void handleToggleFunction(FunctionConfig config) {
    // 特殊处理：图像按钮需要打开图片选择器
    if ("image".equals(config.key) && mCurrentTab != null && "virtual_bg".equals(mCurrentTab)) {
      // 图像按钮：打开图片选择器
      if (mBeautyParamCallback != null) {
        mBeautyParamCallback.onImageSelectionRequested(mCurrentTab, config.key);
      }
      // 不更新状态，等待图片选择完成后再更新
      return;
    }

    // 普通开关型功能：切换状态（包括模糊和预置背景）
    String functionKey = buildFunctionKey(mCurrentTab, config.key);
    boolean currentState = mToggleStates.getOrDefault(functionKey, false);
    boolean newState = !currentState;

    // 特殊处理：滤镜 Tab 下的开关是互斥的
    if ("filter".equals(mCurrentTab) && newState) {
      // 如果是开启一个新滤镜，先关闭当前 Tab 下的所有其他开关
      String prefix = mCurrentTab + ":";
      java.util.Iterator<java.util.Map.Entry<String, Boolean>> it = mToggleStates.entrySet().iterator();
      while (it.hasNext()) {
        java.util.Map.Entry<String, Boolean> entry = it.next();
        if (entry.getKey().startsWith(prefix) && !entry.getKey().equals(functionKey)) {
          String otherFunctionKey = entry.getKey().substring(prefix.length());
          entry.setValue(false);
          updateToggleButtonVisual(otherFunctionKey, false);
        }
      }
    }

    // 更新状态
    mToggleStates.put(functionKey, newState);

    // 立即调用回调（1.0 = 开启, 0.0 = 关闭）
    if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, config.key, newState ? 1.0f : 0.0f);
    }

    // 更新按钮视觉状态
    updateToggleButtonVisual(config.key, newState);

    // 不显示滑动条
    hideSubOptions();
    hideSlider();
  }

  /**
   * 更新开关型按钮的视觉状态
   */
  private void updateToggleButtonVisual(String functionKey, boolean isOn) {
    View buttonView = mFunctionButtonViews.get(buildFunctionKey(mCurrentTab, functionKey));
    if (buttonView == null)
      return;

    // 查找图标容器（第一个 FrameLayout）
    FrameLayout iconWrap = null;
    if (buttonView instanceof LinearLayout) {
      for (int i = 0; i < ((LinearLayout) buttonView).getChildCount(); i++) {
        View child = ((LinearLayout) buttonView).getChildAt(i);
        if (child instanceof FrameLayout) {
          iconWrap = (FrameLayout) child;
          break;
        }
      }
    }

    if (iconWrap != null) {
      // 查找 ImageView
      android.widget.ImageView imageView = null;
      for (int i = 0; i < iconWrap.getChildCount(); i++) {
        View child = iconWrap.getChildAt(i);
        if (child instanceof android.widget.ImageView) {
          imageView = (android.widget.ImageView) child;
          break;
        }
      }

      if (imageView != null) {
        // On state: icon highlighted (slightly warm white)
        // Off state: default white
        if (isOn) {
          // On: use slightly warm white to make icon more visible
          android.graphics.PorterDuffColorFilter filter =
              new android.graphics.PorterDuffColorFilter(0xFFFFEEEE, // Slightly warm white
                  android.graphics.PorterDuff.Mode.SRC_ATOP);
          imageView.setColorFilter(filter);
        } else {
          // Off: restore default white
          android.graphics.PorterDuffColorFilter whiteFilter =
              new android.graphics.PorterDuffColorFilter(
                  android.graphics.Color.WHITE, android.graphics.PorterDuff.Mode.SRC_ATOP);
          imageView.setColorFilter(whiteFilter);
        }
        iconWrap.setAlpha(1.0f);
      }
    }
  }

  private void updateFunctionButtons() {
    if (mFunctionButtonContainer == null)
      return;
    // Clear existing buttons to support any number of function items
    mFunctionButtonContainer.removeAllViews();

    // Clear indicator references and button view references
    mFunctionIndicatorViews.clear();
    mFunctionButtonViews.clear();

    // Common "Off" button always placed first
    View offButton = createFunctionButtonFromConfig(
        new FunctionConfig("off", mContext.getString(R.string.beauty_off), R.drawable.disable, true, TYPE_SLIDER),
        v -> onBeautyOffClicked());
    mFunctionButtonContainer.addView(offButton);

    // Get configuration array based on Tab
    FunctionConfig[] functions = getFunctionsForTab(mCurrentTab);

    // Create buttons uniformly
    for (FunctionConfig config : functions) {
      if (!config.enabled) {
        // Unavailable function: show Toast
        View button = createFunctionButtonFromConfig(config, v -> {
          android.widget.Toast
              .makeText(mRootView.getContext(), config.label + " Soon",
                  android.widget.Toast.LENGTH_SHORT)
              .show();
        });
        mFunctionButtonContainer.addView(button);
      } else {
        // Available function: handle uniformly
        View button = createFunctionButtonFromConfig(config, v -> handleFunctionClick(config));
        mFunctionButtonContainer.addView(button);
      }
    }

    // Restore toggle button visual states
    restoreToggleButtonStates();
  }

  /**
   * Create button from configuration
   */
  private View createFunctionButtonFromConfig(FunctionConfig config, View.OnClickListener onClick) {
    View button = createFunctionButton(
        config.key, config.label, config.iconRes, config.enabled, config.type, onClick);

    // Save button view reference (for updating toggle state)
    String fullKey = buildFunctionKey(mCurrentTab, config.key);
    mFunctionButtonViews.put(fullKey, button);

    return button;
  }

  /**
   * Restore toggle button visual states
   */
  private void restoreToggleButtonStates() {
    if (mCurrentTab == null)
      return;
    String prefix = mCurrentTab + ":";
    for (java.util.Map.Entry<String, Boolean> entry : mToggleStates.entrySet()) {
      if (entry.getKey().startsWith(prefix)) {
        String functionKey = entry.getKey().substring(prefix.length());
        updateToggleButtonVisual(functionKey, entry.getValue());
      }
    }
  }

  private View createFunctionButton(String key, String label, int iconRes, boolean enabled,
      int buttonType, View.OnClickListener onClick) {
    // Outer container: width 70dp, content vertically centered
    LinearLayout container = new LinearLayout(mRootView.getContext());
    LinearLayout.LayoutParams lp =
        new LinearLayout.LayoutParams(dp(70), LinearLayout.LayoutParams.WRAP_CONTENT);
    lp.setMarginEnd(dp(8));
    container.setLayoutParams(lp);
    container.setOrientation(LinearLayout.VERTICAL);
    container.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
    container.setPadding(dp(8), dp(8), dp(8), dp(8));

    // Use a FrameLayout to hold circular background + icon
    FrameLayout iconWrap = new FrameLayout(mRootView.getContext());
    FrameLayout.LayoutParams iconLp = new FrameLayout.LayoutParams(dp(50), dp(50));
    iconWrap.setLayoutParams(iconLp);
    iconWrap.setBackgroundResource(R.drawable.param_button_background);

    android.widget.ImageView iv = new android.widget.ImageView(mRootView.getContext());
    FrameLayout.LayoutParams ivLp = new FrameLayout.LayoutParams(dp(28), dp(28));
    ivLp.gravity = android.view.Gravity.CENTER;
    iv.setLayoutParams(ivLp);
    iv.setImageResource(iconRes);
    // Use PorterDuffColorFilter to set white color
    android.graphics.PorterDuffColorFilter whiteFilter = new android.graphics.PorterDuffColorFilter(
        android.graphics.Color.WHITE, android.graphics.PorterDuff.Mode.SRC_ATOP);
    iv.setColorFilter(whiteFilter);
    iconWrap.addView(iv);

    // Soon badge (shown when unavailable)
    if (!enabled) {
      android.widget.TextView soon = new android.widget.TextView(mRootView.getContext());
      FrameLayout.LayoutParams soonLp = new FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
      soonLp.gravity = android.view.Gravity.TOP | android.view.Gravity.END;
      soonLp.setMargins(0, dp(2), dp(2), 0);
      soon.setLayoutParams(soonLp);
      soon.setText("Soon");
      soon.setTextSize(8);
      soon.setTextColor(android.graphics.Color.WHITE);
      soon.setBackgroundResource(R.drawable.soon_badge);
      soon.setPadding(dp(3), dp(1), dp(3), dp(1));
      iconWrap.addView(soon);
    }

    container.addView(iconWrap);

    android.widget.TextView tv = new android.widget.TextView(mRootView.getContext());
    tv.setText(label);
    tv.setTextColor(0xFFFFFFFF);
    tv.setTextSize(12);
    LinearLayout.LayoutParams tvLp = new LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    tvLp.topMargin = dp(4);
    tv.setLayoutParams(tvLp);
    container.addView(tv);

    // Selection indicator: green short line, located below text
    View indicator = new View(mRootView.getContext());
    LinearLayout.LayoutParams indLp = new LinearLayout.LayoutParams(dp(14), dp(3));
    indLp.topMargin = dp(3);
    indicator.setLayoutParams(indLp);
    GradientDrawable bar = new GradientDrawable();
    bar.setShape(GradientDrawable.RECTANGLE);
    bar.setCornerRadius(dp(2));
    bar.setColor(0xFF00FF00); // Green
    indicator.setBackground(bar);
    indicator.setVisibility(View.GONE);
    container.addView(indicator);

    // Save indicator reference for this function (with tab prefix)
    String fullKey = buildFunctionKey(mCurrentTab, key);
    mFunctionIndicatorViews.put(fullKey, indicator);

    container.setAlpha(enabled ? 1.0f : 0.5f);
    // Wrap listener: execute business logic first, then refresh selection indicator
    container.setOnClickListener(v -> {
      if (onClick != null)
        onClick.onClick(v);
      updateSelectionIndicators();
    });
    return container;
  }

  private void updateSelectionIndicators() {
    String selectedKey = buildFunctionKey(mCurrentTab, mCurrentFunction);
    for (java.util.Map.Entry<String, View> e : mFunctionIndicatorViews.entrySet()) {
      View ind = e.getValue();
      if (ind == null)
        continue;
      ind.setVisibility(e.getKey().equals(selectedKey) ? View.VISIBLE : View.GONE);
    }
  }

  private int dp(int value) {
    float density = mRootView.getResources().getDisplayMetrics().density;
    return Math.round(value * density);
  }

  // Generate unique key for function progress storage: tab:function
  private String buildFunctionKey(String tab, String function) {
    if (tab == null)
      tab = "";
    if (function == null)
      function = "";
    return tab + ":" + function;
  }

  /**
   * Update button text
   */
  private void updateButtonText(LinearLayout button, String text) {
    if (button == null)
      return;
    // Find TextView inside button (last TextView is usually the text label)
    for (int i = button.getChildCount() - 1; i >= 0; i--) {
      View child = button.getChildAt(i);
      if (child instanceof TextView) {
        ((TextView) child).setText(text);
        break;
      }
    }
  }

  /**
   * Get button text
   */
  private String getButtonText(LinearLayout button) {
    if (button == null)
      return "";
    // Find TextView inside button (last TextView is usually the text label)
    for (int i = button.getChildCount() - 1; i >= 0; i--) {
      View child = button.getChildAt(i);
      if (child instanceof TextView) {
        return ((TextView) child).getText().toString();
      }
    }
    return "";
  }

  /**
   * Update sub-option button text
   */
  private void updateSubOptionButtons(String[] options) {
    LinearLayout[] buttons = {mBtnSubOption1, mBtnSubOption2, mBtnSubOption3, mBtnSubOption4};
    for (int i = 0; i < buttons.length && i < options.length; i++) {
      if (buttons[i] != null) {
        buttons[i].setVisibility(View.VISIBLE);
        updateButtonText(buttons[i], options[i]);
      }
    }
    // Hide extra buttons
    for (int i = options.length; i < buttons.length; i++) {
      if (buttons[i] != null) {
        buttons[i].setVisibility(View.GONE);
      }
    }
  }

  private void onBeautyOffClicked() {
    mCurrentFunction = null;
    hideSubOptions();
    hideSlider();

    if (mCurrentTab == null)
      return;

    // Clear all saved slider progress under current Tab
    java.util.Iterator<java.util.Map.Entry<String, Integer>> it =
        mFunctionProgress.entrySet().iterator();
    String prefix = mCurrentTab + ":";
    while (it.hasNext()) {
      java.util.Map.Entry<String, Integer> e = it.next();
      if (e.getKey().startsWith(prefix)) {
        it.remove();
      }
    }

    // Determine close logic based on Tab type
    switch (mCurrentTab) {
      case "virtual_bg":
        // Virtual background Tab: pass "none" as function when closing
        // Close all toggle type function states
        java.util.Iterator<java.util.Map.Entry<String, Boolean>> toggleIt =
            mToggleStates.entrySet().iterator();
        while (toggleIt.hasNext()) {
          java.util.Map.Entry<String, Boolean> e = toggleIt.next();
          if (e.getKey().startsWith(prefix) && e.getValue()) {
            String functionKey = e.getKey().substring(prefix.length());
            mToggleStates.put(e.getKey(), false);
            // Update visual state
            updateToggleButtonVisual(functionKey, false);
          }
        }
        // Call callback, pass "none" to indicate closing virtual background
        if (mBeautyParamCallback != null) {
          mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, "none", 0.0f);
        }
        break;

      default:
        // Other Tabs: close all enabled toggle type functions one by one
        toggleIt = mToggleStates.entrySet().iterator();
        while (toggleIt.hasNext()) {
          java.util.Map.Entry<String, Boolean> e = toggleIt.next();
          if (e.getKey().startsWith(prefix) && e.getValue()) {
            String functionKey = e.getKey().substring(prefix.length());
            mToggleStates.put(e.getKey(), false);
            // Call callback to close function
            if (mBeautyParamCallback != null) {
              mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, functionKey, 0.0f);
            }
            // Update visual state
            updateToggleButtonVisual(functionKey, false);
          }
        }
        // Notify host to reset current Tab (slider type functions)
        if (mBeautyParamCallback != null) {
          mBeautyParamCallback.onBeautyTabReset(mCurrentTab);
        }
        break;
    }
  }

  // Old click handling methods removed, now using configuration-driven approach:
  // - handleFunctionClick() handles all button clicks uniformly
  // - handleToggleFunction() handles toggle type functions
  // - Configuration defined in getFunctionsForTab()

  private void onSubOptionClicked(int option, String name) {
    mCurrentSubOption = "style" + option;
    hideSubOptions();
    showSlider();
    // TODO: Apply specific style (e.g.: lipstick style 1, blush style 2, etc.)
    android.widget.Toast
        .makeText(mRootView.getContext(), mCurrentFunction + " - " + name,
            android.widget.Toast.LENGTH_SHORT)
        .show();
  }

  private void onResetBeautyClicked() {
    // Reset all parameters
    if (mBeautySeekBar != null) {
      mBeautySeekBar.setProgress(50);
    }
    mCurrentFunction = null;
    hideSubOptions();
    hideSlider();
    if (mIndicatorBeautyWhite != null) {
      mIndicatorBeautyWhite.setVisibility(View.GONE);
    }
    // Notify callback to reset all beauty parameters
    if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onBeautyReset();
    }
    // Clear saved progress for all functions
    mFunctionProgress.clear();
  }

  /**
   * Set beauty parameter change callback
   */
  public void setBeautyParamCallback(BeautyParamCallback callback) {
    mBeautyParamCallback = callback;
  }

  private void onCaptureClicked() {
    // TODO: Capture photo function
  }

  private void onHidePanelClicked() {
    // Directly return to preview interface without panel
    hideSubOptions();
    hideSlider();
    hidePanel();
  }

  private void showSubOptions() {
    mIsSubOptionVisible = true;
    if (mSubOptionScrollView != null) {
      mSubOptionScrollView.setVisibility(View.VISIBLE);
    }
    // Bottom buttons container will automatically adjust position through constraint layout, no need to switch
  }

  private void hideSubOptions() {
    mIsSubOptionVisible = false;
    if (mSubOptionScrollView != null) {
      mSubOptionScrollView.setVisibility(View.GONE);
    }
    // Bottom buttons container will automatically adjust position through constraint layout, no need to switch
  }

  private void showSlider() {
    if (mBeautySliderLayout != null) {
      mBeautySliderLayout.setVisibility(View.VISIBLE);
    }
    // When switching to current function, first restore saved progress for this function; default 0
    if (mBeautySeekBar != null && mCurrentFunction != null) {
      int saved =
          mFunctionProgress.getOrDefault(buildFunctionKey(mCurrentTab, mCurrentFunction), 0);
      if (mBeautySeekBar.getProgress() != saved) {
        mBeautySeekBar.setProgress(saved);
      }
    }
    // Use current value to immediately apply parameter once, ensuring it takes effect immediately after switching function
    if (mBeautySeekBar != null && mCurrentFunction != null && mBeautyParamCallback != null) {
      int progress = mBeautySeekBar.getProgress();
      float paramValue = progress / 100.0f;
      mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, mCurrentFunction, paramValue);
    }
  }

  private void hideSlider() {
    if (mBeautySliderLayout != null) {
      mBeautySliderLayout.setVisibility(View.GONE);
    }
  }

  public void showPanel() {
    mIsPanelVisible = true;
    if (mBeautyPanelRoot != null) {
      mBeautyPanelRoot.setVisibility(View.VISIBLE);
    }
    // Hide bottom control panel
    if (mBottomControlPanel != null) {
      mBottomControlPanel.setVisibility(View.GONE);
    }
  }

  public void hidePanel() {
    mIsPanelVisible = false;
    if (mBeautyPanelRoot != null) {
      mBeautyPanelRoot.setVisibility(View.GONE);
    }
    hideSubOptions();
    hideSlider();
    // Show bottom control panel
    if (mBottomControlPanel != null) {
      mBottomControlPanel.setVisibility(View.VISIBLE);
    }
  }

  public boolean isPanelVisible() {
    return mIsPanelVisible;
  }

  public void togglePanel() {
    if (mIsPanelVisible) {
      hidePanel();
    } else {
      showPanel();
    }
  }

  /**
   * Switch to specified Tab
   * @param tab "beauty", "reshape", "makeup"
   */
  public void switchToTab(String tab) {
    if (tab != null) {
      switchTab(tab);
    }
  }
}
