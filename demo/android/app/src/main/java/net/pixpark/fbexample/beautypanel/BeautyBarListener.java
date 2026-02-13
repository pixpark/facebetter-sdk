package net.pixpark.fbexample.beautypanel;

/** Top/bottom bar click events; Activity implements, Bar only forwards clicks. */
public interface BeautyBarListener {
  void onClose();
  void onOpenGallery();
  void onFlipCamera();
  void onMore();
  void onBeforeAfter();
  void onBeautyPanelToggle();
  void onOpenPanelTab(String tab);
  void onCapture();
}
