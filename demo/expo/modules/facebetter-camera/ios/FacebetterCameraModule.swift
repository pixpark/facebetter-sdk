import ExpoModulesCore

public class FacebetterCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("FacebetterCamera")

    View(FacebetterCameraView.self) {
      Events("onStatus")

      Prop("smoothing") { (view: FacebetterCameraView, value: Double) in
        view.smoothing = Float(value)
      }
      Prop("whitening") { (view: FacebetterCameraView, value: Double) in
        view.whitening = Float(value)
      }
      Prop("rosiness") { (view: FacebetterCameraView, value: Double) in
        view.rosiness = Float(value)
      }
      Prop("blemish") { (view: FacebetterCameraView, value: Double) in
        view.blemish = Float(value)
      }
      Prop("clarity") { (view: FacebetterCameraView, value: Double) in
        view.clarity = Float(value)
      }
      Prop("skinOnly") { (view: FacebetterCameraView, value: Bool) in
        view.skinOnly = value
      }

      OnViewDidUpdateProps { view in
        view.applySkin()
      }
    }
  }
}
