import ExpoModulesCore
import UIKit

public final class FacebetterCameraView: ExpoView {
  let onStatus = EventDispatcher()

  private let preview = CameraGlView()
  private let costLabel = UILabel()

  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    preview.frame = bounds
    preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    preview.onStatus = { [weak self] status in
      self?.onStatus(["status": status])
    }
    preview.onFrameMs = { [weak self] milliseconds in
      self?.showProcessTime(milliseconds)
    }
    addSubview(preview)

    costLabel.textColor = .white
    costLabel.font = .systemFont(ofSize: 14)
    costLabel.textAlignment = .center
    costLabel.backgroundColor = UIColor(white: 0, alpha: 0.45)
    costLabel.isHidden = true
    addSubview(costLabel)
  }

  var smoothing: Float = 0.6
  var whitening: Float = 0.3
  var rosiness: Float = 0.15
  var blemish: Float = 0
  var clarity: Float = 0.2
  var skinOnly = false

  func applySkin() {
    preview.applySmoothing(
      smoothing,
      whitening: whitening,
      rosiness: rosiness,
      blemish: blemish,
      clarity: clarity,
      skinOnly: skinOnly
    )
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    preview.frame = bounds
    let width: CGFloat = 96
    let height: CGFloat = 32
    let top = safeAreaInsets.top + 12
    costLabel.frame = CGRect(
      x: bounds.width - width - 12,
      y: top,
      width: width,
      height: height
    )
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil {
      preview.start()
    } else {
      preview.shutdown()
    }
  }

  private func showProcessTime(_ milliseconds: Double) {
    costLabel.text = String(format: "%.1f ms", milliseconds)
    costLabel.isHidden = false
  }
}
