package expo.modules.facebettercamera

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class FacebetterCameraModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("FacebetterCamera")

    View(FacebetterCameraView::class) {
      Events("onStatus")

      Prop("smoothing") { view: FacebetterCameraView, value: Double ->
        view.smoothing = value.toFloat()
      }
      Prop("whitening") { view: FacebetterCameraView, value: Double ->
        view.whitening = value.toFloat()
      }
      Prop("rosiness") { view: FacebetterCameraView, value: Double ->
        view.rosiness = value.toFloat()
      }
      Prop("blemish") { view: FacebetterCameraView, value: Double ->
        view.blemish = value.toFloat()
      }
      Prop("clarity") { view: FacebetterCameraView, value: Double ->
        view.clarity = value.toFloat()
      }
      Prop("skinOnly") { view: FacebetterCameraView, value: Boolean ->
        view.skinOnly = value
      }

      OnViewDidUpdateProps { view ->
        view.applySkin()
      }
    }
  }
}
