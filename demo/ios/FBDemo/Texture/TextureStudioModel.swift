import Combine
import Photos
import SwiftUI
import UIKit

final class TextureStudioModel: BeautySession {
  @Published var isComparing = false {
    didSet {
      stateLock.lock()
      compareFlag = isComparing
      stateLock.unlock()
    }
  }
  @Published var statusKey = "status.initializing"
  @Published var fps: Double = 0

  let preview = TexturePreviewView(frame: .zero)

  private let engine: BeautyEngine
  private let camera = CameraSession()
  private let stateLock = NSLock()
  private var compareFlag = false
  private var captureFlag = false
  private var applying = false
  private var started = false
  private var statusResetItem: DispatchWorkItem?
  private var lastFrameAt = CACurrentMediaTime()
  private var frameCount = 0

  override init(locale: AppLocale? = nil) {
    engine = BeautyEngine(externalContext: true, startImmediately: false)
    super.init(locale: locale)
    engine.onEvent = { [weak self] key in
      DispatchQueue.main.async {
        self?.flash(key)
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
    preview.process = { [weak self] texture, width, height in
      guard let self else { return texture }
      self.stateLock.lock()
      let bypass = self.compareFlag
      self.stateLock.unlock()
      return self.engine.processTexture(texture, width: width, height: height, bypass: bypass) ?? texture
    }
    preview.onPresented = { [weak self] in
      self?.updateFPS()
    }
  }

  func start() {
    guard !started else { return }
    started = true
    preview.prepare()
    preview.runOnGLSync { [weak self] in
      guard let self else { return }
      self.engine.start()
      self.engine.apply(self.params)
    }
    camera.start()
    flash("status.textureOn")
  }

  func stop() {
    guard started else { return }
    started = false
    camera.stop()
    preview.runOnGLSync { [weak self] in
      self?.engine.shutdown()
    }
    preview.shutdown()
  }

  func flipCamera() {
    camera.flip()
  }

  func reset() {
    applying = true
    params = BeautyParams()
    applying = false
    applyOnGL()
    flash("status.reset")
  }

  func capture() {
    stateLock.lock()
    captureFlag = true
    stateLock.unlock()
  }

  override func paramsDidChange() {
    applyOnGL()
  }

  private func applyOnGL() {
    guard !applying, started else { return }
    let snapshot = params
    preview.runOnGL { [weak self] in
      self?.engine.apply(snapshot)
    }
  }

  private func handleCameraFrame(_ buffer: CVPixelBuffer) {
    stateLock.lock()
    let shouldCapture = captureFlag
    if shouldCapture {
      captureFlag = false
    }
    stateLock.unlock()

    preview.submit(buffer, bypass: false)

    if shouldCapture {
      let image = preview.captureImage()
      DispatchQueue.main.async {
        self.save(image: image)
      }
    }
  }

  private func updateFPS() {
    frameCount += 1
    let now = CACurrentMediaTime()
    let elapsed = now - lastFrameAt
    guard elapsed >= 1 else { return }
    let value = Double(frameCount) / elapsed
    frameCount = 0
    lastFrameAt = now
    DispatchQueue.main.async { [weak self] in
      self?.fps = value
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

  deinit {
    stop()
  }
}
