package net.pixpark.fbexample.beautypanel;

import android.view.View;
import androidx.constraintlayout.widget.ConstraintLayout;

/** Panel and bottom bar visibility only. */
public final class BeautyPanelVisibility {
  private final ConstraintLayout mPanelRoot;
  private final View mBottomControlPanel;
  private boolean mIsPanelVisible;

  public BeautyPanelVisibility(ConstraintLayout panelRoot, View bottomControlPanel) {
    mPanelRoot = panelRoot;
    mBottomControlPanel = bottomControlPanel;
  }

  public void showPanel() {
    mIsPanelVisible = true;
    if (mPanelRoot != null) {
      mPanelRoot.setVisibility(View.VISIBLE);
    }
    if (mBottomControlPanel != null) {
      mBottomControlPanel.setVisibility(View.GONE);
    }
  }

  public void hidePanel() {
    mIsPanelVisible = false;
    if (mPanelRoot != null) {
      mPanelRoot.setVisibility(View.GONE);
    }
    if (mBottomControlPanel != null) {
      mBottomControlPanel.setVisibility(View.VISIBLE);
    }
  }

  public boolean isPanelVisible() {
    return mIsPanelVisible;
  }
}
