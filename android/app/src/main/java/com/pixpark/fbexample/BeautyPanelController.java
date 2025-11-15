package com.pixpark.fbexample;

import android.view.View;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.FrameLayout;
import android.graphics.drawable.GradientDrawable;
import android.app.Activity;
import androidx.constraintlayout.widget.ConstraintLayout;

public class BeautyPanelController {
    private static final String TAG = "BeautyPanelController";

    // 按钮类型常量
    private static final int TYPE_SLIDER = 0;  // 滑动条型：需要调节强度
    private static final int TYPE_TOGGLE = 1;  // 开关型：点击切换开启/关闭

    // 功能配置数据结构
    private static class FunctionConfig {
        String key;           // 功能键：如 "blur", "white", "lipstick"
        String label;         // 显示文本：如 "模糊", "美白", "口红"
        int iconRes;          // 图标资源
        boolean enabled;      // 是否可用
        int type;             // 类型：TYPE_SLIDER(0) 或 TYPE_TOGGLE(1)
        String[] subOptions;  // 子选项（美妆类功能需要，如 {"样式1","样式2","样式3"}）
        
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

    // 美颜参数变化回调接口
    public interface BeautyParamCallback {
        /**
         * 美颜参数变化回调
         * @param tab 当前Tab: "beauty", "reshape", "makeup", "virtual_bg" 等
         * @param function 当前功能: "white", "smooth", "blur" 等
         * @param value 参数值：
         *              - 滑动条型功能：0.0 ~ 1.0 表示强度
         *              - 开关型功能：1.0 表示开启，0.0 表示关闭
         */
        void onBeautyParamChanged(String tab, String function, float value);
        
        /**
         * 重置所有美颜参数
         */
        void onBeautyReset();

        /**
         * 重置指定 Tab 下的所有参数
         * @param tab 当前Tab
         */
        void onBeautyTabReset(String tab);
        
        /**
         * 图片选择回调（用于虚拟背景等需要选择图片的功能）
         * @param tab 当前Tab
         * @param function 当前功能（如 "image"）
         */
        void onImageSelectionRequested(String tab, String function);
    }
    
    private BeautyParamCallback mBeautyParamCallback;

    private View mRootView;
    private View mBottomControlPanel;
    
    // 美颜面板
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
    
    // 功能按钮
    private LinearLayout mFunctionButtonContainer;
    private LinearLayout mBtnBeautyOff;
    private LinearLayout mBtnBeautyWhite;
    private LinearLayout mBtnBeautyDark;
    private LinearLayout mBtnBeautySmooth;
    private LinearLayout mBtnBeautyAi;
    private View mIndicatorBeautyWhite;
    
    // 子选项区域
    private View mSubOptionScrollView;
    private LinearLayout mBtnSubOption1;
    private LinearLayout mBtnSubOption2;
    private LinearLayout mBtnSubOption3;
    private LinearLayout mBtnSubOption4;
    
    // 底部按钮
    private LinearLayout mBottomButtonContainer;
    private LinearLayout mBtnResetBeauty;
    private ImageButton mBtnCapturePanel;
    private LinearLayout mBtnHidePanel;
    
    // 滑块
    private View mBeautySliderLayout;
    private SeekBar mBeautySeekBar;
    private TextView mBeautyValueText;
    
    // 状态
    private boolean mIsPanelVisible = false;
    private boolean mIsSubOptionVisible = false;
    private String mCurrentTab = "beauty"; // beauty, reshape, makeup
    private String mCurrentFunction = null; // 当前选中的功能（如：white, dark, smooth, ai, lipstick, blush 等）
    // 记录每个 Tab 下各功能的滑动值（0-100）
    private final java.util.Map<String, Integer> mFunctionProgress = new java.util.HashMap<>();
    // 各功能的选中指示器视图
    private final java.util.Map<String, View> mFunctionIndicatorViews = new java.util.HashMap<>();
    // 记录开关型功能的开启/关闭状态
    private final java.util.Map<String, Boolean> mToggleStates = new java.util.HashMap<>();
    // 记录按钮视图（用于更新开关状态的视觉反馈）
    private final java.util.Map<String, View> mFunctionButtonViews = new java.util.HashMap<>();
    private String mCurrentSubOption = null; // 当前选中的子选项（如：style1, style2, style3）
    
    public BeautyPanelController(View rootView) {
        mRootView = rootView;
        initViews();
        setupListeners();
    }
    
    private void initViews() {
        // 美颜面板 - 通过 include 的 ID 获取根视图
        // 注意：include 标签本身就是被包含布局的根视图
        View beautyPanelLayout = mRootView.findViewById(R.id.beauty_panel_layout);
        if (beautyPanelLayout == null) {
            throw new RuntimeException("beauty_panel_layout not found!");
        }
        
        // include 的 View 就是 ConstraintLayout (beauty_panel_root)
        if (beautyPanelLayout instanceof ConstraintLayout) {
            mBeautyPanelRoot = (ConstraintLayout) beautyPanelLayout;
        } else {
            throw new RuntimeException("beauty_panel_layout is not ConstraintLayout!");
        }
        
        // Tab 滚动视图
        mTabScrollView = beautyPanelLayout.findViewById(R.id.tab_scroll_view);
        
        // Tab 按钮
        mTabBeauty = beautyPanelLayout.findViewById(R.id.tab_beauty);
        mTabReshape = beautyPanelLayout.findViewById(R.id.tab_reshape);
        mTabMakeup = beautyPanelLayout.findViewById(R.id.tab_makeup);
        mTabFilter = beautyPanelLayout.findViewById(R.id.tab_filter);
        mTabSticker = beautyPanelLayout.findViewById(R.id.tab_sticker);
        mTabBody = beautyPanelLayout.findViewById(R.id.tab_body);
        mTabVirtualBg = beautyPanelLayout.findViewById(R.id.tab_virtual_bg);
        mTabQuality = beautyPanelLayout.findViewById(R.id.tab_quality);
        
        // 功能按钮
        mFunctionButtonContainer = beautyPanelLayout.findViewById(R.id.function_button_container);
        mBtnBeautyOff = beautyPanelLayout.findViewById(R.id.btn_beauty_off);
        mBtnBeautyWhite = beautyPanelLayout.findViewById(R.id.btn_beauty_white);
        mBtnBeautyDark = beautyPanelLayout.findViewById(R.id.btn_beauty_dark);
        mBtnBeautySmooth = beautyPanelLayout.findViewById(R.id.btn_beauty_smooth);
        mBtnBeautyAi = beautyPanelLayout.findViewById(R.id.btn_beauty_ai);
        mIndicatorBeautyWhite = beautyPanelLayout.findViewById(R.id.indicator_beauty_white);
        
        // 子选项
        mSubOptionScrollView = beautyPanelLayout.findViewById(R.id.sub_option_scroll_view);
        mBtnSubOption1 = beautyPanelLayout.findViewById(R.id.btn_sub_option_1);
        mBtnSubOption2 = beautyPanelLayout.findViewById(R.id.btn_sub_option_2);
        mBtnSubOption3 = beautyPanelLayout.findViewById(R.id.btn_sub_option_3);
        mBtnSubOption4 = beautyPanelLayout.findViewById(R.id.btn_sub_option_4);
        
        // 底部按钮
        mBottomButtonContainer = beautyPanelLayout.findViewById(R.id.bottom_button_container);
        mBtnResetBeauty = beautyPanelLayout.findViewById(R.id.btn_reset_beauty);
        mBtnCapturePanel = beautyPanelLayout.findViewById(R.id.btn_capture_panel);
        mBtnHidePanel = beautyPanelLayout.findViewById(R.id.btn_hide_panel);
        
        // 滑块
        mBeautySliderLayout = mRootView.findViewById(R.id.beauty_slider_layout);
        if (mBeautySliderLayout != null) {
            mBeautySeekBar = mBeautySliderLayout.findViewById(R.id.beauty_seekbar);
            mBeautyValueText = mBeautySliderLayout.findViewById(R.id.beauty_value_text);
        }
        
        // 底部控制面板（需要在显示美颜面板时隐藏）
        mBottomControlPanel = mRootView.findViewById(R.id.bottom_panel);
    }
    
    private void setupListeners() {
        // Tab 切换
        if (mTabBeauty != null) mTabBeauty.setOnClickListener(v -> switchTab("beauty"));
        if (mTabReshape != null) mTabReshape.setOnClickListener(v -> switchTab("reshape"));
        if (mTabMakeup != null) mTabMakeup.setOnClickListener(v -> switchTab("makeup"));
        if (mTabFilter != null) mTabFilter.setOnClickListener(v -> switchTab("filter"));
        if (mTabSticker != null) mTabSticker.setOnClickListener(v -> switchTab("sticker"));
        if (mTabBody != null) mTabBody.setOnClickListener(v -> switchTab("body"));
        if (mTabVirtualBg != null) mTabVirtualBg.setOnClickListener(v -> switchTab("virtual_bg"));
        if (mTabQuality != null) mTabQuality.setOnClickListener(v -> switchTab("quality"));
        
        // 功能按钮
        if (mBtnBeautyOff != null) mBtnBeautyOff.setOnClickListener(v -> onBeautyOffClicked());
        // 旧的按钮监听器已移除，现在使用配置驱动方式动态创建按钮
        // 按钮点击事件在 updateFunctionButtons() 中通过 handleFunctionClick() 统一处理
        
        // 子选项 - 动态获取按钮文本
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
        
        // 底部按钮
        if (mBtnResetBeauty != null) mBtnResetBeauty.setOnClickListener(v -> onResetBeautyClicked());
        if (mBtnCapturePanel != null) mBtnCapturePanel.setOnClickListener(v -> onCaptureClicked());
        if (mBtnHidePanel != null) mBtnHidePanel.setOnClickListener(v -> onHidePanelClicked());
        
        // 滑块
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
                        int seekBarWidth = seekBar.getWidth() - seekBar.getPaddingLeft() - seekBar.getPaddingRight();
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
        if (mTabScrollView == null) return;
        
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
                return new FunctionConfig[]{
                    new FunctionConfig("white", "美白", R.drawable.meiyan, true, TYPE_SLIDER),
                    new FunctionConfig("dark", "美黑", R.drawable.huanfase, false, TYPE_SLIDER),
                    new FunctionConfig("smooth", "磨皮", R.drawable.meiyan2, true, TYPE_SLIDER),
                    new FunctionConfig("rosiness", "红润", R.drawable.meiyan, true, TYPE_SLIDER),
                };
            case "reshape":
                return new FunctionConfig[]{
                    new FunctionConfig("thin_face", "瘦脸", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("v_face", "V脸", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("narrow_face", "窄脸", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("short_face", "短脸", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("cheekbone", "颧骨", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("jawbone", "下颌", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("chin", "下巴", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("nose_slim", "瘦鼻", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("big_eye", "大眼", R.drawable.meixing2, true, TYPE_SLIDER),
                    new FunctionConfig("eye_distance", "眼距", R.drawable.meixing2, true, TYPE_SLIDER),
                };
            case "makeup":
                return new FunctionConfig[]{
                    new FunctionConfig("lipstick", "口红", R.drawable.meizhuang, true, TYPE_SLIDER)
                        .withSubOptions(new String[]{"样式1", "样式2", "样式3"}),
                    new FunctionConfig("blush", "腮红", R.drawable.meizhuang, true, TYPE_SLIDER)
                        .withSubOptions(new String[]{"样式1", "样式2", "样式3"}),
                    new FunctionConfig("eyebrow", "眉毛", R.drawable.meizhuang, true, TYPE_SLIDER)
                        .withSubOptions(new String[]{"样式1", "样式2", "样式3"}),
                    new FunctionConfig("eyeshadow", "眼影", R.drawable.meizhuang, true, TYPE_SLIDER)
                        .withSubOptions(new String[]{"样式1", "样式2", "样式3"}),
                };
            case "filter":
                return new FunctionConfig[]{
                    new FunctionConfig("natural", "自然", R.drawable.lvjing, true, TYPE_SLIDER),
                    new FunctionConfig("fresh", "清新", R.drawable.lvjing, true, TYPE_SLIDER),
                    new FunctionConfig("retro", "复古", R.drawable.lvjing, true, TYPE_SLIDER),
                    new FunctionConfig("bw", "黑白", R.drawable.lvjing, true, TYPE_SLIDER),
                };
            case "sticker":
                return new FunctionConfig[]{
                    new FunctionConfig("cute", "可爱", R.drawable.tiezhi2, false, TYPE_SLIDER),
                    new FunctionConfig("funny", "搞笑", R.drawable.tiezhi2, false, TYPE_SLIDER),
                };
            case "body":
                return new FunctionConfig[]{
                    new FunctionConfig("slim", "瘦身", R.drawable.meiti, false, TYPE_SLIDER),
                };
            case "virtual_bg":
                return new FunctionConfig[]{
                    new FunctionConfig("blur", "模糊", R.drawable.blur, true, TYPE_TOGGLE),
                    new FunctionConfig("preset", "预置", R.drawable.back_preset, true, TYPE_TOGGLE),
                    new FunctionConfig("image", "图像", R.drawable.gallery, true, TYPE_TOGGLE),
                };
            case "quality":
                return new FunctionConfig[]{
                    new FunctionConfig("sharpen", "锐化", R.drawable.huazhitiaozheng2, false, TYPE_SLIDER),
                };
            default:
                return new FunctionConfig[0];
        }
    }

    /**
     * 统一的按钮点击处理
     */
    private void handleFunctionClick(FunctionConfig config) {
        if (config == null) return;
        
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
        if (buttonView == null) return;
        
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
                // 开启状态：图标高亮（稍微偏暖的白色）
                // 关闭状态：默认白色
                if (isOn) {
                    // 开启：使用稍微偏暖的白色，让图标更明显
                    android.graphics.PorterDuffColorFilter filter = 
                        new android.graphics.PorterDuffColorFilter(
                            0xFFFFEEEE, // 稍微偏暖的白色
                            android.graphics.PorterDuff.Mode.SRC_ATOP);
                    imageView.setColorFilter(filter);
                } else {
                    // 关闭：恢复默认白色
                    android.graphics.PorterDuffColorFilter whiteFilter = 
                        new android.graphics.PorterDuffColorFilter(
                            android.graphics.Color.WHITE,
                            android.graphics.PorterDuff.Mode.SRC_ATOP);
                    imageView.setColorFilter(whiteFilter);
                }
                iconWrap.setAlpha(1.0f);
            }
        }
    }

    private void updateFunctionButtons() {
        if (mFunctionButtonContainer == null) return;
        // 清空原有按钮，支持任意数量的功能项
        mFunctionButtonContainer.removeAllViews();

        // 清空指示器引用和按钮视图引用
        mFunctionIndicatorViews.clear();
        mFunctionButtonViews.clear();

        // 公共的"关闭"按钮始终放在首位
        View offButton = createFunctionButtonFromConfig(
            new FunctionConfig("off", "关闭", R.drawable.disable, true, TYPE_SLIDER),
            v -> onBeautyOffClicked());
        mFunctionButtonContainer.addView(offButton);

        // 根据 Tab 获取配置数组
        FunctionConfig[] functions = getFunctionsForTab(mCurrentTab);
        
        // 统一创建按钮
        for (FunctionConfig config : functions) {
            if (!config.enabled) {
                // 不可用的功能：显示 Toast
                View button = createFunctionButtonFromConfig(config, v -> {
                    android.widget.Toast.makeText(mRootView.getContext(), 
                        config.label + "功能开发中，敬请期待 😊", 
                        android.widget.Toast.LENGTH_SHORT).show();
                });
                mFunctionButtonContainer.addView(button);
            } else {
                // 可用的功能：统一处理
                View button = createFunctionButtonFromConfig(config, v -> handleFunctionClick(config));
                mFunctionButtonContainer.addView(button);
            }
        }
        
        // 恢复开关型按钮的视觉状态
        restoreToggleButtonStates();
    }

    /**
     * 从配置创建按钮
     */
    private View createFunctionButtonFromConfig(FunctionConfig config, View.OnClickListener onClick) {
        View button = createFunctionButton(
            config.key, 
            config.label, 
            config.iconRes, 
            config.enabled, 
            config.type,
            onClick);
        
        // 保存按钮视图引用（用于更新开关状态）
        String fullKey = buildFunctionKey(mCurrentTab, config.key);
        mFunctionButtonViews.put(fullKey, button);
        
        return button;
    }

    /**
     * 恢复开关型按钮的视觉状态
     */
    private void restoreToggleButtonStates() {
        if (mCurrentTab == null) return;
        String prefix = mCurrentTab + ":";
        for (java.util.Map.Entry<String, Boolean> entry : mToggleStates.entrySet()) {
            if (entry.getKey().startsWith(prefix)) {
                String functionKey = entry.getKey().substring(prefix.length());
                updateToggleButtonVisual(functionKey, entry.getValue());
            }
        }
    }

    private View createFunctionButton(String key, String label, int iconRes,
                                      boolean enabled, int buttonType, View.OnClickListener onClick) {
        // 外层容器：宽70dp，内容垂直居中
        LinearLayout container = new LinearLayout(mRootView.getContext());
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(dp(70), LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.setMarginEnd(dp(8));
        container.setLayoutParams(lp);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        container.setPadding(dp(8), dp(8), dp(8), dp(8));

        // 用一个 FrameLayout 放圆形背景 + 图标
        FrameLayout iconWrap = new FrameLayout(mRootView.getContext());
        FrameLayout.LayoutParams iconLp = new FrameLayout.LayoutParams(dp(50), dp(50));
        iconWrap.setLayoutParams(iconLp);
        iconWrap.setBackgroundResource(R.drawable.param_button_background);

        android.widget.ImageView iv = new android.widget.ImageView(mRootView.getContext());
        FrameLayout.LayoutParams ivLp = new FrameLayout.LayoutParams(dp(28), dp(28));
        ivLp.gravity = android.view.Gravity.CENTER;
        iv.setLayoutParams(ivLp);
        iv.setImageResource(iconRes);
        // 使用 PorterDuffColorFilter 设置白色
        android.graphics.PorterDuffColorFilter whiteFilter = 
            new android.graphics.PorterDuffColorFilter(
                android.graphics.Color.WHITE,
                android.graphics.PorterDuff.Mode.SRC_ATOP);
        iv.setColorFilter(whiteFilter);
        iconWrap.addView(iv);

        // Soon 标签（不可用时显示）
        if (!enabled) {
            android.widget.TextView soon = new android.widget.TextView(mRootView.getContext());
            FrameLayout.LayoutParams soonLp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
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
        LinearLayout.LayoutParams tvLp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        tvLp.topMargin = dp(4);
        tv.setLayoutParams(tvLp);
        container.addView(tv);

        // 选中指示器：绿色短横线，位于文字下方
        View indicator = new View(mRootView.getContext());
        LinearLayout.LayoutParams indLp = new LinearLayout.LayoutParams(dp(14), dp(3));
        indLp.topMargin = dp(3);
        indicator.setLayoutParams(indLp);
        GradientDrawable bar = new GradientDrawable();
        bar.setShape(GradientDrawable.RECTANGLE);
        bar.setCornerRadius(dp(2));
        bar.setColor(0xFF00FF00); // 绿色
        indicator.setBackground(bar);
        indicator.setVisibility(View.GONE);
        container.addView(indicator);

        // 保存该功能的指示器引用（带 tab 前缀）
        String fullKey = buildFunctionKey(mCurrentTab, key);
        mFunctionIndicatorViews.put(fullKey, indicator);

        container.setAlpha(enabled ? 1.0f : 0.5f);
        // 包装监听：先执行业务，再刷新选中指示器
        container.setOnClickListener(v -> {
            if (onClick != null) onClick.onClick(v);
            updateSelectionIndicators();
        });
        return container;
    }

    private void updateSelectionIndicators() {
        String selectedKey = buildFunctionKey(mCurrentTab, mCurrentFunction);
        for (java.util.Map.Entry<String, View> e : mFunctionIndicatorViews.entrySet()) {
            View ind = e.getValue();
            if (ind == null) continue;
            ind.setVisibility(e.getKey().equals(selectedKey) ? View.VISIBLE : View.GONE);
        }
    }

    private int dp(int value) {
        float density = mRootView.getResources().getDisplayMetrics().density;
        return Math.round(value * density);
    }
    
    // 生成功能进度存储的唯一键：tab:function
    private String buildFunctionKey(String tab, String function) {
        if (tab == null) tab = "";
        if (function == null) function = "";
        return tab + ":" + function;
    }
    
    /**
     * 更新按钮的文本
     */
    private void updateButtonText(LinearLayout button, String text) {
        if (button == null) return;
        // 查找按钮内的 TextView（最后一个 TextView 通常是文本标签）
        for (int i = button.getChildCount() - 1; i >= 0; i--) {
            View child = button.getChildAt(i);
            if (child instanceof TextView) {
                ((TextView) child).setText(text);
                break;
            }
        }
    }
    
    /**
     * 获取按钮的文本
     */
    private String getButtonText(LinearLayout button) {
        if (button == null) return "";
        // 查找按钮内的 TextView（最后一个 TextView 通常是文本标签）
        for (int i = button.getChildCount() - 1; i >= 0; i--) {
            View child = button.getChildAt(i);
            if (child instanceof TextView) {
                return ((TextView) child).getText().toString();
            }
        }
        return "";
    }
    
    /**
     * 更新子选项按钮的文本
     */
    private void updateSubOptionButtons(String[] options) {
        LinearLayout[] buttons = {mBtnSubOption1, mBtnSubOption2, mBtnSubOption3, mBtnSubOption4};
        for (int i = 0; i < buttons.length && i < options.length; i++) {
            if (buttons[i] != null) {
                buttons[i].setVisibility(View.VISIBLE);
                updateButtonText(buttons[i], options[i]);
            }
        }
        // 隐藏多余的按钮
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
        
        if (mCurrentTab == null) return;
        
        // 清除当前 Tab 下所有已保存的滑动条进度
        java.util.Iterator<java.util.Map.Entry<String,Integer>> it = mFunctionProgress.entrySet().iterator();
        String prefix = mCurrentTab + ":";
        while (it.hasNext()) {
            java.util.Map.Entry<String,Integer> e = it.next();
            if (e.getKey().startsWith(prefix)) {
                it.remove();
            }
        }
        
        // 根据 Tab 类型决定关闭逻辑
        switch (mCurrentTab) {
            case "virtual_bg":
                // 虚拟背景 Tab：关闭时传递 "none" 作为 function
                // 关闭所有开关型功能的状态
                java.util.Iterator<java.util.Map.Entry<String, Boolean>> toggleIt = mToggleStates.entrySet().iterator();
                while (toggleIt.hasNext()) {
                    java.util.Map.Entry<String, Boolean> e = toggleIt.next();
                    if (e.getKey().startsWith(prefix) && e.getValue()) {
                        String functionKey = e.getKey().substring(prefix.length());
                        mToggleStates.put(e.getKey(), false);
                        // 更新视觉状态
                        updateToggleButtonVisual(functionKey, false);
                    }
                }
                // 调用回调，传递 "none" 表示关闭虚拟背景
                if (mBeautyParamCallback != null) {
                    mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, "none", 0.0f);
                }
                break;
                
            default:
                // 其他 Tab：逐个关闭所有开启的开关型功能
                toggleIt = mToggleStates.entrySet().iterator();
                while (toggleIt.hasNext()) {
                    java.util.Map.Entry<String, Boolean> e = toggleIt.next();
                    if (e.getKey().startsWith(prefix) && e.getValue()) {
                        String functionKey = e.getKey().substring(prefix.length());
                        mToggleStates.put(e.getKey(), false);
                        // 调用回调关闭功能
                        if (mBeautyParamCallback != null) {
                            mBeautyParamCallback.onBeautyParamChanged(mCurrentTab, functionKey, 0.0f);
                        }
                        // 更新视觉状态
                        updateToggleButtonVisual(functionKey, false);
                    }
                }
                // 通知宿主重置当前Tab（滑动条型功能）
                if (mBeautyParamCallback != null) {
                    mBeautyParamCallback.onBeautyTabReset(mCurrentTab);
                }
                break;
        }
    }
    
    // 旧的点击处理方法已移除，现在使用配置驱动方式：
    // - handleFunctionClick() 统一处理所有按钮点击
    // - handleToggleFunction() 处理开关型功能
    // - 配置在 getFunctionsForTab() 中定义
    
    private void onSubOptionClicked(int option, String name) {
        mCurrentSubOption = "style" + option;
        hideSubOptions();
        showSlider();
        // TODO: 应用具体的样式（如：口红样式1、腮红样式2等）
        android.widget.Toast.makeText(mRootView.getContext(), 
            mCurrentFunction + " - " + name, 
            android.widget.Toast.LENGTH_SHORT).show();
    }
    
    private void onResetBeautyClicked() {
        // 重置所有参数
        if (mBeautySeekBar != null) {
            mBeautySeekBar.setProgress(50);
        }
        mCurrentFunction = null;
        hideSubOptions();
        hideSlider();
        if (mIndicatorBeautyWhite != null) {
            mIndicatorBeautyWhite.setVisibility(View.GONE);
        }
        // 通知回调重置所有美颜参数
        if (mBeautyParamCallback != null) {
            mBeautyParamCallback.onBeautyReset();
        }
        // 清空已保存的各功能进度
        mFunctionProgress.clear();
    }
    
    /**
     * 设置美颜参数变化回调
     */
    public void setBeautyParamCallback(BeautyParamCallback callback) {
        mBeautyParamCallback = callback;
    }
    
    private void onCaptureClicked() {
        // TODO: 拍照功能
    }
    
    private void onHidePanelClicked() {
        // 直接回到“无面板”的预览界面
        hideSubOptions();
        hideSlider();
        hidePanel();
    }
    
    private void showSubOptions() {
        mIsSubOptionVisible = true;
        if (mSubOptionScrollView != null) {
            mSubOptionScrollView.setVisibility(View.VISIBLE);
        }
        // 底部按钮容器会自动通过约束布局调整位置，不需要切换
    }
    
    private void hideSubOptions() {
        mIsSubOptionVisible = false;
        if (mSubOptionScrollView != null) {
            mSubOptionScrollView.setVisibility(View.GONE);
        }
        // 底部按钮容器会自动通过约束布局调整位置，不需要切换
    }
    
    private void showSlider() {
        if (mBeautySliderLayout != null) {
            mBeautySliderLayout.setVisibility(View.VISIBLE);
        }
        // 切换到当前功能时，先恢复该功能保存的进度；默认 0
        if (mBeautySeekBar != null && mCurrentFunction != null) {
            int saved = mFunctionProgress.getOrDefault(buildFunctionKey(mCurrentTab, mCurrentFunction), 0);
            if (mBeautySeekBar.getProgress() != saved) {
                mBeautySeekBar.setProgress(saved);
            }
        }
        // 使用当前值立即应用一次参数，保证切换功能后立即生效
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
        // 隐藏底部控制面板
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
        // 显示底部控制面板
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
     * 切换到指定的 Tab
     * @param tab "beauty"(美颜), "reshape"(美型), "makeup"(美妆)
     */
    public void switchToTab(String tab) {
        if (tab != null) {
            switchTab(tab);
        }
    }
}

