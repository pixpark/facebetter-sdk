package net.pixpark.fbexample.beautypanel;

import android.content.Context;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.constraintlayout.widget.ConstraintLayout;
import net.pixpark.fbexample.R;

/** Slider and sub-option area views; visibility and content only, no state. */
public final class BeautyPanelSliderSubOption {
  public interface SubOptionClickListener {
    void onSubOptionClicked(int optionIndex, String optionName);
  }

  private final View mSliderLayout;
  private final SeekBar mSeekBar;
  private final TextView mValueText;
  private final View mSubOptionScrollView;
  private final LinearLayout mBtnSubOption1;
  private final LinearLayout mBtnSubOption2;
  private final LinearLayout mBtnSubOption3;
  private final LinearLayout mBtnSubOption4;
  private final Context mContext;

  public BeautyPanelSliderSubOption(View rootView, ConstraintLayout panelRoot) {
    mContext = rootView.getContext();
    mSliderLayout = rootView.findViewById(R.id.beauty_slider_layout);
    mSeekBar = mSliderLayout != null ? mSliderLayout.findViewById(R.id.beauty_seekbar) : null;
    mValueText = mSliderLayout != null ? mSliderLayout.findViewById(R.id.beauty_value_text) : null;
    mSubOptionScrollView = panelRoot.findViewById(R.id.sub_option_scroll_view);
    mBtnSubOption1 = panelRoot.findViewById(R.id.btn_sub_option_1);
    mBtnSubOption2 = panelRoot.findViewById(R.id.btn_sub_option_2);
    mBtnSubOption3 = panelRoot.findViewById(R.id.btn_sub_option_3);
    mBtnSubOption4 = panelRoot.findViewById(R.id.btn_sub_option_4);
  }

  public void showSliderView() {
    if (mSliderLayout != null) mSliderLayout.setVisibility(View.VISIBLE);
  }

  public void hideSliderView() {
    if (mSliderLayout != null) mSliderLayout.setVisibility(View.GONE);
  }

  public void showSubOptionsView() {
    if (mSubOptionScrollView != null) mSubOptionScrollView.setVisibility(View.VISIBLE);
  }

  public void hideSubOptionsView() {
    if (mSubOptionScrollView != null) mSubOptionScrollView.setVisibility(View.GONE);
  }

  public SeekBar getSeekBar() {
    return mSeekBar;
  }

  public void setSeekBarListener(SeekBar.OnSeekBarChangeListener listener) {
    if (mSeekBar != null) mSeekBar.setOnSeekBarChangeListener(listener);
  }

  public TextView getValueText() {
    return mValueText;
  }

  public void setSubOptionClickListener(SubOptionClickListener listener) {
    if (listener == null) return;
    setSubClick(mBtnSubOption1, 1, listener);
    setSubClick(mBtnSubOption2, 2, listener);
    setSubClick(mBtnSubOption3, 3, listener);
    setSubClick(mBtnSubOption4, 4, listener);
  }

  private void setSubClick(LinearLayout btn, int index, SubOptionClickListener listener) {
    if (btn != null) {
      btn.setOnClickListener(v -> {
        String name = getButtonText(btn);
        listener.onSubOptionClicked(index, name);
      });
    }
  }

  public void updateSubOptionButtons(String[] options, String currentFunction) {
    LinearLayout[] buttons = {mBtnSubOption1, mBtnSubOption2, mBtnSubOption3, mBtnSubOption4};
    for (int i = 0; i < buttons.length && i < options.length; i++) {
      if (buttons[i] != null) {
        buttons[i].setVisibility(View.VISIBLE);
        updateButtonText(buttons[i], options[i]);
        int iconRes = iconForFunction(currentFunction);
        if (iconRes != 0) updateButtonIcon(buttons[i], iconRes);
      }
    }
    for (int i = options.length; i < buttons.length; i++) {
      if (buttons[i] != null) buttons[i].setVisibility(View.GONE);
    }
  }

  private static int iconForFunction(String function) {
    if (function == null) return 0;
    switch (function) {
      case "lipstick": return R.drawable.lipstick;
      case "blush": return R.drawable.meizhuang;
      case "eyebrow": return R.drawable.eyebrow;
      case "eyeshadow": return R.drawable.eyeshadow;
      default: return 0;
    }
  }

  private void updateButtonText(LinearLayout button, String text) {
    if (button == null) return;
    for (int i = button.getChildCount() - 1; i >= 0; i--) {
      View child = button.getChildAt(i);
      if (child instanceof TextView) {
        ((TextView) child).setText(text);
        break;
      }
    }
  }

  private String getButtonText(LinearLayout button) {
    if (button == null) return "";
    for (int i = button.getChildCount() - 1; i >= 0; i--) {
      View child = button.getChildAt(i);
      if (child instanceof TextView) return ((TextView) child).getText().toString();
    }
    return "";
  }

  private void updateButtonIcon(LinearLayout button, int iconRes) {
    if (button == null) return;
    for (int i = 0; i < button.getChildCount(); i++) {
      View child = button.getChildAt(i);
      if (child instanceof android.widget.FrameLayout) {
        android.widget.FrameLayout wrap = (android.widget.FrameLayout) child;
        for (int j = 0; j < wrap.getChildCount(); j++) {
          View sub = wrap.getChildAt(j);
          if (sub instanceof android.widget.ImageView) {
            android.widget.ImageView iv = (android.widget.ImageView) sub;
            iv.setImageResource(iconRes);
            if (iconRes == R.drawable.lipstick || iconRes == R.drawable.meizhuang
                || iconRes == R.drawable.eyebrow || iconRes == R.drawable.eyeshadow) {
              iv.setScaleType(android.widget.ImageView.ScaleType.FIT_CENTER);
              int p = dp(8);
              iv.setPadding(p, p, p, p);
              iv.setColorFilter(new android.graphics.PorterDuffColorFilter(
                  android.graphics.Color.WHITE, android.graphics.PorterDuff.Mode.SRC_ATOP));
            } else {
              iv.setScaleType(android.widget.ImageView.ScaleType.CENTER_CROP);
              iv.setPadding(0, 0, 0, 0);
              iv.setColorFilter(null);
            }
            break;
          }
        }
        break;
      }
    }
  }

  private int dp(int value) {
    float density = mContext.getResources().getDisplayMetrics().density;
    return Math.round(value * density);
  }
}
