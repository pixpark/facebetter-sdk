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
  @Published var cameraInput: CameraInput = .cvPixelBuffer
  @Published var isComparing = false {
    didSet {
      stateLock.lock()
      compareFlag = isComparing
      stateLock.unlock()
      reprocessStillIfNeeded()
    }
  }
  @Published var statusKey = "status.initializing"
  @Published var frameSize: CGSize = .zero
  @Published var fps: Double = 0
  @Published var processMs: Double = 0
  let pixelPreview = PixelPreview(frame: .zero)
  let cvPreview = CvPixelBufferPreview(frame: .zero)
  let glPreview = GlTexturePreview(frame: .zero)

  var showsCvPreview: Bool { source == .camera && cameraInput == .cvPixelBuffer }
  var showsGlPreview: Bool { source == .camera && cameraInput == .glTexture }

  private let engine = BeautyEngine()
  private let camera = CameraSession()
  private let stateLock = NSLock()
  private var inputMode = CameraInput.cvPixelBuffer
  private var originalImage: UIImage?
  private var processedImage: UIImage?
  private var compareFlag = false
  private var captureFlag = false
  private var applying = false
  private var glReady = false
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
    camera.onFrame = { [weak self] buffer in
      self?.handleCameraFrame(buffer)
    }
    camera.onError = { [weak self] key in
      DispatchQueue.main.async {
        self?.flash(key)
      }
    }
    glPreview.process = { [weak self] texture, width, height in
      guard let self else { return texture }
      self.stateLock.lock()
      let bypass = self.compareFlag
      self.stateLock.unlock()
      let started = CACurrentMediaTime()
      let rendered = GlTextureInput.process(
        texture: texture,
        width: width,
        height: height,
        engine: self.engine,
        bypass: bypass
      ) ?? texture
      self.noteTiming(processMs: (CACurrentMediaTime() - started) * 1000)
      return rendered
    }
    glPreview.onPresented = { [weak self] in
      self?.noteFrame()
    }

    applyParams()
    startCamera()
  }

  func startCamera() {
    source = .camera
    originalImage = nil
    processedImage = nil
    frameSize = .zero
    cvPreview.reset()
    camera.start()
    flash("status.cameraOn")
  }

  func flipCamera() {
    guard source == .camera else { return }
    camera.flip()
  }

  func setCameraInput(_ mode: CameraInput) {
    guard mode != cameraInput else { return }
    camera.stop()
    cvPreview.reset()
    let leavingGL = inputMode == .glTexture
    stateLock.lock()
    inputMode = mode
    stateLock.unlock()
    cameraInput = mode
    if mode == .glTexture {
      useGlEngine()
    } else if leavingGL {
      useMetalEngine()
    }
    if source == .camera {
      frameSize = .zero
      camera.start()
    } else {
      reprocessStill()
    }
    flash(mode.statusKey)
  }

  func loadImage(_ image: UIImage) {
    camera.stop()
    source = .image
    cvPreview.reset()
    originalImage = image.fb_normalizedUp()
    isComparing = false
    if let originalImage {
      updateFrameSize(originalImage.size)
    }
    reprocessStill()
    flash("status.imageLoaded")
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

  private func useMetalEngine() {
    glReady = false
    glPreview.shutdown()
    engine.shutdown()
    engine.start()
    engine.apply(params)
  }

  private func useGlEngine() {
    glPreview.prepare()
    engine.shutdown()
    glPreview.runOnGLSync { [weak self] in
      guard let self else { return }
      self.engine.start()
      self.engine.apply(self.params)
    }
    glReady = true
  }

  private func applyParams() {
    guard !applying else { return }
    if inputMode != .glTexture || glReady {
      engine.apply(params)
    }
    reprocessStillIfNeeded()
  }

  private func reprocessStillIfNeeded() {
    guard source == .image else { return }
    reprocessStill()
  }

  private func reprocessStill() {
    guard let originalImage else { return }
    let comparing = isComparing
    let publish: (UIImage) -> Void = { [weak self] output in
      guard let self else { return }
      self.processedImage = output
      self.updateFrameSize(output.size)
      self.pixelPreview.display(image: output)
    }
    if inputMode == .glTexture && glReady {
      glPreview.runOnGL { [weak self] in
        guard let self else { return }
        let output = self.engine.process(originalImage, bypass: comparing) ?? originalImage
        DispatchQueue.main.async {
          publish(output)
        }
      }
    } else {
      publish(engine.process(originalImage, bypass: comparing) ?? originalImage)
    }
  }

  private func handleCameraFrame(_ buffer: CVPixelBuffer) {
    stateLock.lock()
    let bypass = compareFlag
    let shouldCapture = captureFlag
    let mode = inputMode
    if shouldCapture {
      captureFlag = false
    }
    stateLock.unlock()

    switch mode {
    case .cvPixelBuffer:
      presentCv(buffer, bypass: bypass)
    case .cpuPixels:
      presentCpu(buffer, bypass: bypass)
    case .glTexture:
      glPreview.submit(buffer, bypass: bypass)
      updateFrameSize(
        CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
      )
    }

    guard shouldCapture else { return }
    let photo: UIImage?
    switch mode {
    case .cvPixelBuffer:
      photo = CvPixelBufferInput.image(from: buffer, engine: engine)
    case .cpuPixels:
      photo = CpuPixelInput.image(from: buffer, engine: engine)
    case .glTexture:
      photo = glPreview.captureStill(buffer, engine: engine)
    }
    DispatchQueue.main.async {
      self.save(image: photo)
    }
  }

  private func presentCv(_ buffer: CVPixelBuffer, bypass: Bool) {
    let started = CACurrentMediaTime()
    let processed = CvPixelBufferInput.process(
      buffer,
      engine: engine,
      asImage: false,
      bypass: bypass
    )
    noteTiming(processMs: (CACurrentMediaTime() - started) * 1000)
    noteFrame()
    updateFrameSize(
      CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
    )
    if let processed, !bypass {
      cvPreview.present(camera: buffer, processed: processed)
    } else {
      cvPreview.show(buffer)
    }
  }

  private func presentCpu(_ buffer: CVPixelBuffer, bypass: Bool) {
    let started = CACurrentMediaTime()
    let processed = CpuPixelInput.process(
      buffer,
      engine: engine,
      asImage: false,
      bypass: bypass
    )
    noteTiming(processMs: (CACurrentMediaTime() - started) * 1000)
    noteFrame()
    let shown = processed ?? buffer
    updateFrameSize(
      CGSize(width: CVPixelBufferGetWidth(shown), height: CVPixelBufferGetHeight(shown))
    )
    pixelPreview.display(pixelBuffer: shown)
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

  private func noteTiming(processMs costMs: Double) {
    stateLock.lock()
    processMsAccum += costMs
    stateLock.unlock()
  }

  private func noteFrame() {
    stateLock.lock()
    frameCount += 1
    let elapsed = CACurrentMediaTime() - lastFrameAt
    let count = frameCount
    let avgMs = count > 0 ? processMsAccum / Double(count) : 0
    let publish = elapsed >= 1
    if publish {
      frameCount = 0
      processMsAccum = 0
      lastFrameAt = CACurrentMediaTime()
    }
    stateLock.unlock()
    guard publish else { return }
    let value = Double(count) / elapsed
    DispatchQueue.main.async {
      self.fps = value
      self.processMs = avgMs
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
    let apply = { [weak self] in
      guard let self else { return }
      self.statusKey = key
      self.statusResetItem?.cancel()
      let work = DispatchWorkItem { [weak self] in
        self?.statusKey = ""
      }
      self.statusResetItem = work
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }
}
