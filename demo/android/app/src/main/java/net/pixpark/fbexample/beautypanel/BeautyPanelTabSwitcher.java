package net.pixpark.fbexample.beautypanel;

import android.view.View;
import android.widget.HorizontalScrollView;
import android.widget.TextView;
import androidx.constraintlayout.widget.ConstraintLayout;
import net.pixpark.fbexample.R;

/** Tab bar selection style and scroll; notifies listener on click, Controller calls setTab(tab). */
public final class BeautyPanelTabSwitcher {
  public interface OnTabSelectedListener {
    void onTabSelected(String tab);
  }

  private final HorizontalScrollView mTabScrollView;
  private final TextView mTabBeauty;
  private final TextView mTabReshape;
  private final TextView mTabMakeup;
  private final TextView mTabFilter;
  private final TextView mTabSticker;
  private final TextView mTabBody;
  private final TextView mTabVirtualBg;
  private final TextView mTabQuality;

  public BeautyPanelTabSwitcher(ConstraintLayout panelRoot) {
    mTabScrollView = panelRoot.findViewById(R.id.tab_scroll_view);
    mTabBeauty = panelRoot.findViewById(R.id.tab_beauty);
    mTabReshape = panelRoot.findViewById(R.id.tab_reshape);
    mTabMakeup = panelRoot.findViewById(R.id.tab_makeup);
    mTabFilter = panelRoot.findViewById(R.id.tab_filter);
    mTabSticker = panelRoot.findViewById(R.id.tab_sticker);
    mTabBody = panelRoot.findViewById(R.id.tab_body);
    mTabVirtualBg = panelRoot.findViewById(R.id.tab_virtual_bg);
    mTabQuality = panelRoot.findViewById(R.id.tab_quality);
  }

  public void setOnTabSelectedListener(OnTabSelectedListener listener) {
    if (listener == null) return;
    setClick(mTabBeauty, "beauty", listener);
    setClick(mTabReshape, "reshape", listener);
    setClick(mTabMakeup, "makeup", listener);
    setClick(mTabFilter, "filter", listener);
    setClick(mTabSticker, "sticker", listener);
    setClick(mTabBody, "body", listener);
    setClick(mTabVirtualBg, "virtual_bg", listener);
    setClick(mTabQuality, "quality", listener);
  }

  private void setClick(TextView tab, String tabId, OnTabSelectedListener listener) {
    if (tab != null) {
      tab.setOnClickListener(v -> listener.onTabSelected(tabId));
    }
  }

  public void setTab(String tab) {
    resetAllTabStyles();
    TextView target = getTabView(tab);
    if (target != null) {
      target.setTextColor(0xFFFFFFFF);
      target.setTypeface(null, android.graphics.Typeface.BOLD);
    }
    scrollToTab(tab);
  }

  private void resetAllTabStyles() {
    resetTabStyle(mTabBeauty);
    resetTabStyle(mTabReshape);
    resetTabStyle(mTabMakeup);
    resetTabStyle(mTabFilter);
    resetTabStyle(mTabSticker);
    resetTabStyle(mTabBody);
    resetTabStyle(mTabVirtualBg);
    resetTabStyle(mTabQuality);
  }

  private void resetTabStyle(TextView tab) {
    if (tab != null) {
      tab.setTextColor(0xFFAAAAAA);
      tab.setTypeface(null, android.graphics.Typeface.NORMAL);
    }
  }

  private TextView getTabView(String tab) {
    switch (tab) {
      case "beauty": return mTabBeauty;
      case "reshape": return mTabReshape;
      case "makeup": return mTabMakeup;
      case "filter": return mTabFilter;
      case "sticker": return mTabSticker;
      case "body": return mTabBody;
      case "virtual_bg": return mTabVirtualBg;
      case "quality": return mTabQuality;
      default: return null;
    }
  }

  private void scrollToTab(String tab) {
    TextView targetTab = getTabView(tab);
    if (targetTab == null || mTabScrollView == null) return;
    final TextView finalTab = targetTab;
    mTabScrollView.post(() -> {
      int tabLeft = finalTab.getLeft();
      int tabWidth = finalTab.getWidth();
      int scrollViewWidth = mTabScrollView.getWidth();
      int scrollX = tabLeft - (scrollViewWidth / 2) + (tabWidth / 2);
      mTabScrollView.smoothScrollTo(scrollX, 0);
    });
  }
}
