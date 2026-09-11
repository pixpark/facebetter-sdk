import Combine
import CoreVideo
import Photos
import SwiftUI
import UIKit

enum StudioSource {
  case camera
  case image
}

final class StudioModel: BeautySession {
  @Published var source: StudioSource = .camera
  @Published var showLandmarks = false
  @Published var isComparing = false {
    didSet {
      stateLock.lock()
      compareFlag = isComparing
      stateLock.unlock()
      reprocessStillIfNeeded()
    }
  }
  @Published var statusKey = "status.initializing"
  @Published var faces: [FBFaceDetectionResult] = []
  @Published var frameSize: CGSize = .zero
  @Published var fps: Double = 0
  @Published var processMs: Double = 0

  let preview = PreviewMTKView(frame: .zero, device: nil)

  private let engine = BeautyEngine()
  private let camera = CameraSession()
  private let stateLock = NSLock()
  private var originalImage: UIImage?
  private var processedImage: UIImage?
  private var compareFlag = false
  private var captureFlag = false
  private var applying = false
  private var statusResetItem: DispatchWorkItem?
  private var lastFrameAt = CACurrentMediaTime()
  private var frameCount = 0
  private var processMsAccum = 0.0

  override init(locale: AppLocale? = nil) {
    super.init(locale: locale)
    engine.onEvent = { [weak self] key in
      DispatchQueue.main.async {
        self?.flash(key)
      }
    }
    engine.onFaces = { [weak self] faces in
      DispatchQueue.main.async {
        self?.faces = faces
      }
    }
    camera.onFrame = { [weak self] buffer in
      self?.handleCameraFrame(buffer)
    }
    camera.onError = { [weak self] key in
      DispatchQueue.main.async {
        self?.flash(key)
      }
    }

    applyParams()
    startCamera()
  }

  func startCamera() {
    source = .camera
    originalImage = nil
    processedImage = nil
    frameSize = .zero
    camera.start()
    preview.recoverAfterCover()
    flash("status.cameraOn")
  }

  func flipCamera() {
    guard source == .camera else { return }
    camera.flip()
  }

  func loadImage(_ image: UIImage) {
    camera.stop()
    source = .image
    originalImage = image.fb_normalizedUp()
    isComparing = false
    if let originalImage {
      updateFrameSize(originalImage.size)
    }
    reprocessStill()
    flash("status.imageLoaded")
  }

  func reset() {
    applying = true
    params = BeautyParams()
    applying = false
    applyParams()
    flash("status.reset")
  }

  func suspendForExternalTexture() {
    camera.stop()
    engine.shutdown()
  }

  func resumeAfterExternalTexture() {
    syncLocaleFromDefaults()
    engine.start()
    applyParams()
    if source == .camera {
      startCamera()
    } else {
      reprocessStill()
    }
    preview.recoverAfterCover()
    DispatchQueue.main.async { [weak self] in
      self?.preview.recoverAfterCover()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      guard let self else { return }
      if self.source == .camera {
        self.camera.start()
      }
      self.preview.recoverAfterCover()
    }
  }

  override func paramsDidChange() {
    applyParams()
  }

  func capture() {
    if source == .image {
      save(image: isComparing ? originalImage : processedImage)
      return
    }
    stateLock.lock()
    captureFlag = true
    stateLock.unlock()
  }

  private func applyParams() {
    guard !applying else { return }
    engine.apply(params)
    reprocessStillIfNeeded()
  }

  private func reprocessStillIfNeeded() {
    guard source == .image else { return }
    reprocessStill()
  }

  private func reprocessStill() {
    guard let originalImage else { return }
    let output = engine.process(originalImage, bypass: isComparing) ?? originalImage
    processedImage = output
    updateFrameSize(output.size)
    preview.display(image: output)
  }

  private func handleCameraFrame(_ buffer: CVPixelBuffer) {
    stateLock.lock()
    let bypass = compareFlag
    let shouldCapture = captureFlag
    if shouldCapture {
      captureFlag = false
    }
    stateLock.unlock()

    let started = CACurrentMediaTime()
    let processed = engine.process(buffer, asImage: false, bypass: bypass)
    let costMs = (CACurrentMediaTime() - started) * 1000
    let shown = processed ?? buffer
    updateFrameSize(
      CGSize(
        width: CVPixelBufferGetWidth(shown),
        height: CVPixelBufferGetHeight(shown)
      )
    )
    preview.display(pixelBuffer: shown)
    updateFPS(processMs: costMs)

    if shouldCapture {
      let photo = engine.snapshotImage(from: buffer, bypass: false)
      DispatchQueue.main.async {
        self.save(image: photo)
      }
    }
  }

  private func updateFrameSize(_ size: CGSize) {
    guard size.width > 0, size.height > 0 else { return }
    let apply = { [weak self] in
      guard let self else { return }
      if abs(self.frameSize.width - size.width) < 0.5,
         abs(self.frameSize.height - size.height) < 0.5 {
        return
      }
      self.frameSize = size
    }
    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }

  private func updateFPS(processMs costMs: Double) {
    frameCount += 1
    processMsAccum += costMs
    let now = CACurrentMediaTime()
    let elapsed = now - lastFrameAt
    if elapsed >= 1 {
      let value = Double(frameCount) / elapsed
      let avgMs = processMsAccum / Double(max(frameCount, 1))
      frameCount = 0
      processMsAccum = 0
      lastFrameAt = now
      DispatchQueue.main.async {
        self.fps = value
        self.processMs = avgMs
      }
    }
  }

  private func save(image: UIImage?) {
    guard let image else {
      flash("status.captureFailed")
      return
    }
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async { self.flash("status.saveFailed") }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, _ in
        DispatchQueue.main.async {
          self.flash(success ? "status.saved" : "status.saveFailed")
        }
      }
    }
  }

  private func flash(_ key: String) {
    statusKey = key
    statusResetItem?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.statusKey = ""
    }
    statusResetItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
  }
}
