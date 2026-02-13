package net.pixpark.fbexample.beautypanel;

import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.constraintlayout.widget.ConstraintLayout;
import net.pixpark.fbexample.R;

public class BeautyPanelController {
  private static final String TAG = "BeautyPanelController";

  public interface OnBeautyParamChange {
    void onBeautyParamChanged(String tab, String function, float value);
  }

  public interface OnBeautyReset {
    void onBeautyReset();
  }

  public interface OnBeautyTabReset {
    void onBeautyTabReset(String tab);
  }

  public interface OnImageSelectionRequest {
    void onImageSelectionRequested(String tab, String function);
  }

  public interface OnCaptureRequest {
    void onCaptureRequested();
  }

  /** Single callback or separate listeners. */
  public interface BeautyParamCallback extends OnBeautyParamChange, OnBeautyReset,
      OnBeautyTabReset, OnImageSelectionRequest, OnCaptureRequest {}

  private BeautyParamCallback mBeautyParamCallback;
  private OnBeautyParamChange mOnParamChange;
  private OnBeautyReset mOnReset;
  private OnBeautyTabReset mOnTabReset;
  private OnImageSelectionRequest mOnImageRequest;
  private OnCaptureRequest mOnCaptureRequest;

  private View mRootView;
  private android.content.Context mContext;
  private BeautyPanelVisibility mVisibility;

  // Beauty panel
  private ConstraintLayout mBeautyPanelRoot;
  private BeautyPanelTabSwitcher mTabSwitcher;

  // Function buttons
  private LinearLayout mFunctionButtonContainer;
  private LinearLayout mBtnBeautyOff;
  private LinearLayout mBtnBeautyWhite;
  private LinearLayout mBtnBeautyDark;
  private LinearLayout mBtnBeautySmooth;
  private LinearLayout mBtnBeautyAi;
  private View mIndicatorBeautyWhite;

  private BeautyPanelSliderSubOption mSliderSubOption;

  // Bottom buttons
  private LinearLayout mBottomButtonContainer;
  private LinearLayout mBtnResetBeauty;
  private ImageButton mBtnCapturePanel;
  private LinearLayout mBtnHidePanel;


  // State
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

    mTabSwitcher = new BeautyPanelTabSwitcher(mBeautyPanelRoot);

    // Function buttons
    mFunctionButtonContainer = beautyPanelLayout.findViewById(R.id.function_button_container);
    mBtnBeautyOff = beautyPanelLayout.findViewById(R.id.btn_beauty_off);
    mBtnBeautyWhite = beautyPanelLayout.findViewById(R.id.btn_beauty_white);
    mBtnBeautyDark = beautyPanelLayout.findViewById(R.id.btn_beauty_dark);
    mBtnBeautySmooth = beautyPanelLayout.findViewById(R.id.btn_beauty_smooth);
    mBtnBeautyAi = beautyPanelLayout.findViewById(R.id.btn_beauty_ai);
    mIndicatorBeautyWhite = beautyPanelLayout.findViewById(R.id.indicator_beauty_white);

    mSliderSubOption = new BeautyPanelSliderSubOption(mRootView, mBeautyPanelRoot);

    // Bottom buttons
    mBottomButtonContainer = beautyPanelLayout.findViewById(R.id.bottom_button_container);
    mBtnResetBeauty = beautyPanelLayout.findViewById(R.id.btn_reset_beauty);
    mBtnCapturePanel = beautyPanelLayout.findViewById(R.id.btn_capture_panel);
    mBtnHidePanel = beautyPanelLayout.findViewById(R.id.btn_hide_panel);

    View bottomControlPanel = mRootView.findViewById(R.id.bottom_panel);
    mVisibility = new BeautyPanelVisibility(mBeautyPanelRoot, bottomControlPanel);
  }

  private void setupListeners() {
    if (mTabSwitcher != null) {
      mTabSwitcher.setOnTabSelectedListener(this::switchTab);
    }

    // Function buttons
    if (mBtnBeautyOff != null)
      mBtnBeautyOff.setOnClickListener(v -> onBeautyOffClicked());
    // Function buttons are config-driven; clicks handled in handleFunctionClick()

    if (mSliderSubOption != null) {
      mSliderSubOption.setSubOptionClickListener(this::onSubOptionClicked);
      mSliderSubOption.setSeekBarListener(createSeekBarListener());
    }

    // Bottom buttons
    if (mBtnResetBeauty != null)
      mBtnResetBeauty.setOnClickListener(v -> onResetBeautyClicked());
    if (mBtnCapturePanel != null)
      mBtnCapturePanel.setOnClickListener(v -> onCaptureClicked());
    if (mBtnHidePanel != null)
      mBtnHidePanel.setOnClickListener(v -> onHidePanelClicked());

  }

  private SeekBar.OnSeekBarChangeListener createSeekBarListener() {
    return new SeekBar.OnSeekBarChangeListener() {
      @Override
      public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        TextView valueText = mSliderSubOption != null ? mSliderSubOption.getValueText() : null;
        if (valueText != null) {
          valueText.setText(String.valueOf(progress));
          valueText.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
          int textWidth = valueText.getMeasuredWidth();
          int seekBarWidth = seekBar.getWidth() - seekBar.getPaddingLeft() - seekBar.getPaddingRight();
          float thumbPos = (float) progress / seekBar.getMax() * seekBarWidth;
          android.widget.FrameLayout.LayoutParams params =
              (android.widget.FrameLayout.LayoutParams) valueText.getLayoutParams();
          if (params != null) {
            params.leftMargin = (int) (thumbPos + seekBar.getLeft() - textWidth / 2);
            valueText.setLayoutParams(params);
          }
        }
        if (fromUser && mCurrentFunction != null) {
          mFunctionProgress.put(buildFunctionKey(mCurrentTab, mCurrentFunction), progress);
        }
        if (fromUser && mCurrentFunction != null) {
          dispatchParamChange(mCurrentTab, mCurrentFunction, progress / 100.0f);
        }
      }

      @Override
      public void onStartTrackingTouch(SeekBar seekBar) {
        if (mSliderSubOption != null && mSliderSubOption.getValueText() != null) {
          mSliderSubOption.getValueText().setVisibility(View.VISIBLE);
        }
      }

      @Override
      public void onStopTrackingTouch(SeekBar seekBar) {
        if (mSliderSubOption != null && mSliderSubOption.getValueText() != null) {
          TextView vt = mSliderSubOption.getValueText();
          vt.postDelayed(() -> {
            if (vt != null) vt.setVisibility(View.GONE);
          }, 500);
        }
      }
    };
  }

  private void switchTab(String tab) {
    mCurrentTab = tab;
    mCurrentFunction = null;
    mCurrentSubOption = null;

    if (mTabSwitcher != null) {
      mTabSwitcher.setTab(tab);
    }
    hideSubOptions();
    hideSlider();
    updateFunctionButtons();
    updateSelectionIndicators();
  }

  private void handleFunctionClick(BeautyPanelConfig.FunctionConfig config) {
    if (config == null)
      return;

    mCurrentFunction = config.key;

    // Special handling for filters: they are mutually exclusive
    if ("filter".equals(mCurrentTab)) {
      BeautyPanelConfig.FunctionConfig[] filters = BeautyPanelConfig.getFunctionsForTab("filter", mContext);
      for (BeautyPanelConfig.FunctionConfig f : filters) {
        String key = buildFunctionKey("filter", f.key);
        if (!f.key.equals(config.key)) {
          // Reset progress of other filters to 0
          mFunctionProgress.put(key, 0);
          // Notify engine to turn off other filters
          dispatchParamChange("filter", f.key, 0.0f);
        } else {
          // For the clicked filter, if it's currently 0, set to default 0.8 (80)
          if (mFunctionProgress.getOrDefault(key, 0) == 0) {
            mFunctionProgress.put(key, 80);
          }
        }
      }
    }

    switch (config.type) {
      case BeautyPanelConfig.TYPE_TOGGLE:
        handleToggleFunction(config);
        break;

      case BeautyPanelConfig.TYPE_SLIDER:
        // Slider type
        if (config.subOptions != null && config.subOptions.length > 0) {
          if (mSliderSubOption != null) {
            mSliderSubOption.updateSubOptionButtons(config.subOptions, mCurrentFunction);
            mSliderSubOption.showSubOptionsView();
            mSliderSubOption.hideSliderView();
          }
        } else {
          if (mSliderSubOption != null) {
            mSliderSubOption.hideSubOptionsView();
            mSliderSubOption.showSliderView();
          }
          afterSliderShown();
        }
        break;
    }
  }

  private void handleToggleFunction(BeautyPanelConfig.FunctionConfig config) {
    if ("image".equals(config.key) && mCurrentTab != null && "virtual_bg".equals(mCurrentTab)) {
      dispatchImageRequest(mCurrentTab, config.key);
      return;
    }

    String functionKey = buildFunctionKey(mCurrentTab, config.key);
    boolean currentState = mToggleStates.getOrDefault(functionKey, false);
    boolean newState = !currentState;

    if ("filter".equals(mCurrentTab) && newState) {
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

    mToggleStates.put(functionKey, newState);

    dispatchParamChange(mCurrentTab, config.key, newState ? 1.0f : 0.0f);
    updateToggleButtonVisual(config.key, newState);

    if (mSliderSubOption != null) {
      mSliderSubOption.hideSubOptionsView();
      mSliderSubOption.hideSliderView();
    }
  }

  private void updateToggleButtonVisual(String functionKey, boolean isOn) {
    View buttonView = mFunctionButtonViews.get(buildFunctionKey(mCurrentTab, functionKey));
    if (buttonView == null)
      return;

    // Icon container: first FrameLayout
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
      // ImageView
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
          // On: warm white
          android.graphics.PorterDuffColorFilter filter =
              new android.graphics.PorterDuffColorFilter(0xFFFFEEEE, // Slightly warm white
                  android.graphics.PorterDuff.Mode.SRC_ATOP);
          imageView.setColorFilter(filter);
        } else {
          // Off: default white
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
        new BeautyPanelConfig.FunctionConfig("off", mContext.getString(R.string.beauty_off), R.drawable.disable, true, BeautyPanelConfig.TYPE_SLIDER),
        v -> onBeautyOffClicked());
    mFunctionButtonContainer.addView(offButton);

    // Get configuration array based on Tab
    BeautyPanelConfig.FunctionConfig[] functions = BeautyPanelConfig.getFunctionsForTab(mCurrentTab, mContext);

    // Create buttons uniformly
    for (BeautyPanelConfig.FunctionConfig config : functions) {
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
  private View createFunctionButtonFromConfig(BeautyPanelConfig.FunctionConfig config, View.OnClickListener onClick) {
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
        dispatchParamChange(mCurrentTab, "none", 0.0f);
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
            dispatchParamChange(mCurrentTab, functionKey, 0.0f);
            // Update visual state
            updateToggleButtonVisual(functionKey, false);
          }
        }
        dispatchTabReset(mCurrentTab);
        break;
    }
  }

  // Clicks: handleFunctionClick() / handleToggleFunction(); config in getFunctionsForTab()

  private void onSubOptionClicked(int option, String name) {
    mCurrentSubOption = "style" + option;
    if (mSliderSubOption != null) {
      mSliderSubOption.hideSubOptionsView();
      mSliderSubOption.showSliderView();
    }
    afterSliderShown();
    // TODO: Apply specific style (e.g.: lipstick style 1, blush style 2, etc.)
    if ("eyebrow".equals(mCurrentFunction) || "eyeshadow".equals(mCurrentFunction)) {
      android.widget.Toast
          .makeText(mRootView.getContext(), name + " Coming Soon",
              android.widget.Toast.LENGTH_SHORT)
          .show();
    } else {
      android.widget.Toast
          .makeText(mRootView.getContext(), mCurrentFunction + " - " + name,
              android.widget.Toast.LENGTH_SHORT)
          .show();
    }
  }

  private void onResetBeautyClicked() {
    if (mSliderSubOption != null && mSliderSubOption.getSeekBar() != null) {
      mSliderSubOption.getSeekBar().setProgress(50);
    }
    mCurrentFunction = null;
    if (mSliderSubOption != null) {
      mSliderSubOption.hideSubOptionsView();
      mSliderSubOption.hideSliderView();
    }
    if (mIndicatorBeautyWhite != null) {
      mIndicatorBeautyWhite.setVisibility(View.GONE);
    }
    dispatchReset();
    mFunctionProgress.clear();
  }

  public void setBeautyParamCallback(BeautyParamCallback callback) {
    mBeautyParamCallback = callback;
  }

  public void setOnBeautyParamChange(OnBeautyParamChange listener) {
    mOnParamChange = listener;
  }

  public void setOnBeautyReset(OnBeautyReset listener) {
    mOnReset = listener;
  }

  public void setOnBeautyTabReset(OnBeautyTabReset listener) {
    mOnTabReset = listener;
  }

  public void setOnImageSelectionRequest(OnImageSelectionRequest listener) {
    mOnImageRequest = listener;
  }

  public void setOnCaptureRequest(OnCaptureRequest listener) {
    mOnCaptureRequest = listener;
  }

  private void dispatchParamChange(String tab, String function, float value) {
    if (mOnParamChange != null) {
      mOnParamChange.onBeautyParamChanged(tab, function, value);
    } else if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onBeautyParamChanged(tab, function, value);
    }
  }

  private void dispatchReset() {
    if (mOnReset != null) {
      mOnReset.onBeautyReset();
    } else if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onBeautyReset();
    }
  }

  private void dispatchTabReset(String tab) {
    if (mOnTabReset != null) {
      mOnTabReset.onBeautyTabReset(tab);
    } else if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onBeautyTabReset(tab);
    }
  }

  private void dispatchImageRequest(String tab, String function) {
    if (mOnImageRequest != null) {
      mOnImageRequest.onImageSelectionRequested(tab, function);
    } else if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onImageSelectionRequested(tab, function);
    }
  }

  private void dispatchCaptureRequest() {
    if (mOnCaptureRequest != null) {
      mOnCaptureRequest.onCaptureRequested();
    } else if (mBeautyParamCallback != null) {
      mBeautyParamCallback.onCaptureRequested();
    }
  }

  private void onCaptureClicked() {
    dispatchCaptureRequest();
  }

  private void onHidePanelClicked() {
    if (mSliderSubOption != null) {
      mSliderSubOption.hideSubOptionsView();
      mSliderSubOption.hideSliderView();
    }
    hidePanel();
  }

  private void afterSliderShown() {
    SeekBar seekBar = mSliderSubOption != null ? mSliderSubOption.getSeekBar() : null;
    if (seekBar == null || mCurrentFunction == null) return;
    String key = buildFunctionKey(mCurrentTab, mCurrentFunction);
    int defaultProgress = "filter".equals(mCurrentTab) ? 80 : 0;
    int saved = mFunctionProgress.getOrDefault(key, defaultProgress);
    if (seekBar.getProgress() != saved) {
      seekBar.setProgress(saved);
    }
    if (!mFunctionProgress.containsKey(key)) {
      mFunctionProgress.put(key, saved);
    }
    float paramValue = seekBar.getProgress() / 100.0f;
    dispatchParamChange(mCurrentTab, mCurrentFunction, paramValue);
  }

  private void showSubOptions() {
    mIsSubOptionVisible = true;
    if (mSliderSubOption != null) mSliderSubOption.showSubOptionsView();
  }

  private void hideSubOptions() {
    mIsSubOptionVisible = false;
    if (mSliderSubOption != null) mSliderSubOption.hideSubOptionsView();
  }

  private void showSlider() {
    if (mSliderSubOption != null) mSliderSubOption.showSliderView();
    afterSliderShown();
  }

  private void hideSlider() {
    if (mSliderSubOption != null) mSliderSubOption.hideSliderView();
  }

  public void showPanel() {
    if (mVisibility != null) mVisibility.showPanel();
  }

  public void hidePanel() {
    hideSubOptions();
    hideSlider();
    if (mVisibility != null) mVisibility.hidePanel();
  }

  public boolean isPanelVisible() {
    return mVisibility != null && mVisibility.isPanelVisible();
  }

  public void togglePanel() {
    if (isPanelVisible()) {
      hidePanel();
    } else {
      showPanel();
    }
  }

  public void switchToTab(String tab) {
    if (tab != null) {
      switchTab(tab);
    }
  }
}
