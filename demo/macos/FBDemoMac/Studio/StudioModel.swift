import AppKit
import Combine
import CoreVideo
import Foundation
import QuartzCore
import UniformTypeIdentifiers

enum StudioSource {
  case camera
  case image
}

final class StudioModel: BeautySession {
  @Published var source: StudioSource = .image
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
  /// Working-buffer original (React `originalRef` ImageData). Compare + process share this.
  private var originalPixelBuffer: CVPixelBuffer?
  private var processedPixelBuffer: CVPixelBuffer?
  private var compareFlag = false
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
    loadDefaultImage()
  }

  func startCamera() {
    source = .camera
    originalPixelBuffer = nil
    processedPixelBuffer = nil
    frameSize = .zero
    camera.start()
    flash("status.cameraOn")
  }

  func pickImage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    guard panel.runModal() == .OK, let url = panel.url,
          let image = NSImage(contentsOf: url) else {
      return
    }
    loadImage(image)
  }

  func loadImage(_ image: NSImage) {
    camera.stop()
    source = .image
    guard let buffer = engine.makeWorkingBuffer(from: image) else {
      flash("status.captureFailed")
      return
    }
    originalPixelBuffer = buffer
    processedPixelBuffer = nil
    isComparing = false
    updateFrameSize(
      CGSize(
        width: CVPixelBufferGetWidth(buffer),
        height: CVPixelBufferGetHeight(buffer)
      )
    )
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

  func exportImage() {
    let buffer: CVPixelBuffer?
    if source == .image {
      buffer = isComparing ? originalPixelBuffer : (processedPixelBuffer ?? originalPixelBuffer)
    } else {
      buffer = processedPixelBuffer ?? originalPixelBuffer
    }
    guard let buffer, let image = NSImage(pixelBuffer: buffer) else {
      flash("status.captureFailed")
      return
    }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    panel.nameFieldStringValue = "fb_\(formatter.string(from: Date())).png"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
      flash("status.saveFailed")
      return
    }
    do {
      try png.write(to: url)
      flash("status.saved")
    } catch {
      flash("status.saveFailed")
    }
  }

  override func paramsDidChange() {
    applyParams()
  }

  private func loadDefaultImage() {
    let candidates = [
      Bundle.main.url(forResource: "face", withExtension: "jpg"),
      Bundle.main.url(forResource: "face", withExtension: "jpg", subdirectory: "Facebetter"),
    ]
    if let url = candidates.compactMap({ $0 }).first,
       let image = NSImage(contentsOf: url) {
      loadImage(image)
      statusKey = ""
    } else {
      flash("status.ready")
    }
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
    guard let originalPixelBuffer else { return }

    if isComparing {
      preview.display(pixelBuffer: originalPixelBuffer)
      return
    }

    let output = engine.process(originalPixelBuffer, asImage: true, bypass: false)
      ?? originalPixelBuffer
    processedPixelBuffer = output
    updateFrameSize(
      CGSize(
        width: CVPixelBufferGetWidth(output),
        height: CVPixelBufferGetHeight(output)
      )
    )
    preview.display(pixelBuffer: output)
  }

  private func handleCameraFrame(_ buffer: CVPixelBuffer) {
    stateLock.lock()
    let bypass = compareFlag
    stateLock.unlock()

    let started = CACurrentMediaTime()
    let processed = engine.process(buffer, asImage: false, bypass: bypass)
    let costMs = (CACurrentMediaTime() - started) * 1000
    let shown = processed ?? buffer
    originalPixelBuffer = buffer
    if !bypass {
      processedPixelBuffer = shown
    }
    updateFrameSize(
      CGSize(
        width: CVPixelBufferGetWidth(shown),
        height: CVPixelBufferGetHeight(shown)
      )
    )
    preview.display(pixelBuffer: shown)
    updateFPS(processMs: costMs)
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
