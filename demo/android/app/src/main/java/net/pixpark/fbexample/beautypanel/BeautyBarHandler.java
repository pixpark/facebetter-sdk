package net.pixpark.fbexample.beautypanel;

import android.view.View;
import net.pixpark.fbexample.R;

/** Binds top/bottom bar clicks to BeautyBarListener; no business logic. */
public class BeautyBarHandler {
  private final View mRootView;
  private final BeautyBarListener mListener;

  public BeautyBarHandler(View rootView, BeautyBarListener listener) {
    mRootView = rootView;
    mListener = listener;
    setupTopBar();
    setupBottomBar();
  }

  private void setupTopBar() {
    mRootView.findViewById(R.id.btn_close).setOnClickListener(v -> mListener.onClose());
    mRootView.findViewById(R.id.btn_gallery).setOnClickListener(v -> mListener.onOpenGallery());
    mRootView.findViewById(R.id.btn_flip_camera).setOnClickListener(v -> mListener.onFlipCamera());
    mRootView.findViewById(R.id.btn_more).setOnClickListener(v -> mListener.onMore());
    mRootView.findViewById(R.id.btn_before_after).setOnClickListener(v -> mListener.onBeforeAfter());
  }

  private void setupBottomBar() {
    mRootView.findViewById(R.id.btn_beauty_shape).setOnClickListener(v -> mListener.onBeautyPanelToggle());
    mRootView.findViewById(R.id.btn_makeup).setOnClickListener(v -> mListener.onOpenPanelTab("makeup"));
    mRootView.findViewById(R.id.btn_capture).setOnClickListener(v -> mListener.onCapture());
    mRootView.findViewById(R.id.btn_sticker).setOnClickListener(v -> mListener.onOpenPanelTab("sticker"));
    mRootView.findViewById(R.id.btn_filter).setOnClickListener(v -> mListener.onOpenPanelTab("filter"));
  }
}
