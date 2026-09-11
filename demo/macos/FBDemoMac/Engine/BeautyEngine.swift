import AppKit
import CoreVideo
import Foundation

final class BeautyEngine {
  private let lock = NSLock()
  private var engine: FBBeautyEffectEngine?
  private var previous = BeautyParams()
  private var resourceRoot: URL
  private var backgroundImageData: Data?

  private(set) var isReady = false
  private(set) var statusKey = "status.initializing"

  var onEvent: ((String) -> Void)?
  var onFaces: (([FBFaceDetectionResult]) -> Void)?

  init(startImmediately: Bool = true) {
    resourceRoot = Bundle.main.resourceURL?.appendingPathComponent("Facebetter", isDirectory: true)
      ?? Bundle.main.bundleURL
    if startImmediately {
      start()
    }
  }

  func apply(_ params: BeautyParams) {
    lock.lock()
    defer { lock.unlock() }
    applyLocked(params)
  }

  func process(_ pixelBuffer: CVPixelBuffer, asImage: Bool, bypass: Bool) -> CVPixelBuffer? {
    lock.lock()
    defer { lock.unlock() }
    guard !bypass, let engine, isReady else { return nil }
    return Self.processPixelBuffer(pixelBuffer, engine: engine, asImage: asImage)
  }

  /// Decode once into the same BGRA working format the engine consumes (React: canvas ImageData).
  func makeWorkingBuffer(from image: NSImage) -> CVPixelBuffer? {
    Self.makeBGRABuffer(from: image)
  }

  func process(_ image: NSImage, bypass: Bool) -> NSImage? {
    guard let buffer = makeWorkingBuffer(from: image) else { return image }
    if bypass { return NSImage(pixelBuffer: buffer) ?? image }
    guard let processed = process(buffer, asImage: true, bypass: false) else {
      return NSImage(pixelBuffer: buffer) ?? image
    }
    return NSImage(pixelBuffer: processed) ?? image
  }

  func snapshotImage(from pixelBuffer: CVPixelBuffer, bypass: Bool) -> NSImage? {
    if let processed = process(pixelBuffer, asImage: true, bypass: bypass) {
      return NSImage(pixelBuffer: processed)
    }
    return NSImage(pixelBuffer: pixelBuffer)
  }

  func start() {
    lock.lock()
    defer { lock.unlock() }
    startLocked()
  }

  func shutdown() {
    lock.lock()
    engine = nil
    isReady = false
    previous = BeautyParams()
    statusKey = "status.initializing"
    lock.unlock()
  }

  private func startLocked() {
    guard engine == nil else { return }
    let log = FBLogConfig()
    log.consoleEnabled = true
    log.fileEnabled = false
    log.level = .info
    FBBeautyEffectEngine.setLogConfig(log)

    let configValues = Self.loadConfig()
    let engineConfig = FBEngineConfig()
    let token = configValues["LICENSE_TOKEN"] ?? ""
    if !token.isEmpty {
      engineConfig.licenseToken = token
    } else {
      engineConfig.appId = configValues["APP_ID"] ?? ""
      engineConfig.appKey = configValues["APP_KEY"] ?? ""
    }

    let created = FBBeautyEffectEngine.createEngine(with: engineConfig)
    engine = created
    isReady = true
    statusKey = "status.ready"

    let callbacks = FBEngineCallbacks()
    callbacks.onEngineEvent = { [weak self] code, _ in
      guard let self else { return }
      let key: String
      var ready = self.isReady
      switch code {
      case .licenseValidationSuccess, .initializationComplete:
        ready = true
        key = "status.ready"
      case .licenseValidationFailed:
        ready = false
        key = "status.authFailed"
      case .initializationFailed:
        ready = false
        key = "status.initFailed"
      @unknown default:
        key = self.statusKey
      }
      self.lock.lock()
      self.isReady = ready
      self.statusKey = key
      self.lock.unlock()
      self.onEvent?(key)
    }
    callbacks.onFaceLandmarks = { [weak self] results in
      self?.onFaces?(results ?? [])
    }
    created.setCallbacks(callbacks)

    backgroundImageData = try? Data(contentsOf: resourceRoot.appendingPathComponent("background.jpg"))
    if created.responds(to: NSSelectorFromString("setSmoothing:")) {
      applyLocked(BeautyParams())
    } else {
      isReady = false
      statusKey = "status.sdkMismatch"
      onEvent?("status.sdkMismatch")
    }
  }

  private func applyLocked(_ params: BeautyParams) {
    guard let engine else { return }
    guard engine.responds(to: NSSelectorFromString("setSmoothing:")) else { return }
    let prev = previous
    previous = params

    engine.setSmoothing(params.smoothing)
    engine.setSmoothingStyle(params.smoothingStyle)
    engine.setWhitening(params.whitening)
    engine.setWhiteningStyle(params.whiteningStyle)
    engine.setRosiness(params.rosiness)
    engine.setSharpening(params.sharpening)
    engine.setBeautySkinOnly(params.skinOnly)

    for item in BeautyCatalog.reshapeItems {
      engine.setReshape(item.key, intensity: params.reshape[item.key] ?? 0)
    }

    engine.setLipstick(params.lipstick)
    engine.setLipstickColor(params.lipstickColor)
    engine.setBlush(params.blush)
    engine.setBlushStyle(params.blushStyle)
    engine.setBlushColor(params.blushColor)
    engine.setContour(params.contour)
    engine.setContourStyle(params.contourStyle)
    engine.setEyeShadow(params.eyeshadow)
    engine.setEyeShadowStyle(params.eyeshadowStyle)
    engine.setEyeShadowColor(params.eyeshadowColor)
    engine.setEyeLiner(params.eyeliner)
    engine.setEyeLinerStyle(params.eyelinerStyle)
    engine.setEyeLinerColor(params.eyelinerColor)
    engine.setEyebrow(params.eyebrow)
    engine.setEyebrowStyle(params.eyebrowStyle)
    engine.setEyebrowColor(params.eyebrowColor)
    engine.setEyelash(params.eyelash)
    engine.setEyelashStyle(params.eyelashStyle)
    engine.setEyelashColor(params.eyelashColor)
    engine.setPupil(params.pupil)
    engine.setPupilColor(params.pupilColor)

    if prev.filterID != params.filterID {
      if let filterID = params.filterID, let path = filterPath(filterID) {
        engine.setFilter(path)
      } else {
        engine.clearFilter()
      }
    }
    if params.filterID != nil {
      engine.setFilterIntensity(params.filterIntensity)
    }

    if prev.stickerID != params.stickerID {
      if let stickerID = params.stickerID, let path = stickerPath(stickerID) {
        engine.setSticker(path)
      } else {
        engine.clearSticker()
      }
    }

    if prev.chroma != params.chroma
      || prev.chromaSimilarity != params.chromaSimilarity
      || prev.chromaSmoothness != params.chromaSmoothness
      || prev.chromaDesaturation != params.chromaDesaturation {
      if let chroma = params.chroma {
        engine.setChromaKey(chroma)
        engine.setChromaKeySimilarity(params.chromaSimilarity)
        engine.setChromaKeySmoothness(params.chromaSmoothness)
        engine.setChromaKeyDesaturation(params.chromaDesaturation)
      } else {
        engine.clearChromaKey()
      }
    }

    if prev.backgroundFill != params.backgroundFill || prev.bgBlur != params.bgBlur {
      switch params.backgroundFill {
      case .blur:
        engine.setVirtualBackgroundBlur(params.bgBlur)
      case .image:
        if let backgroundImageData, !backgroundImageData.isEmpty {
          engine.setVirtualBackgroundWith(backgroundImageData)
        }
      case .off:
        engine.clearVirtualBackground()
      }
    }
  }

  private func filterPath(_ id: String) -> String? {
    let url = resourceRoot
      .appendingPathComponent("filters/portrait/\(id)/\(id).fbd")
    return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
  }

  private func stickerPath(_ id: String) -> String? {
    let url = resourceRoot.appendingPathComponent("stickers/face/\(id).fbd")
    return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
  }

  private static func loadConfig() -> [String: String] {
    guard let url = Bundle.main.url(forResource: "FacebetterConfig", withExtension: "plist"),
          let dictionary = NSDictionary(contentsOf: url) as? [String: String] else {
      return [:]
    }
    return dictionary
  }

  private static func processPixelBuffer(
    _ pixelBuffer: CVPixelBuffer,
    engine: FBBeautyEffectEngine,
    asImage: Bool
  ) -> CVPixelBuffer? {
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
    guard format == kCVPixelFormatType_32BGRA else { return nil }

    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
    let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
    let stride = Int32(CVPixelBufferGetBytesPerRow(pixelBuffer))
    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

    let input = FBImageFrame.create(
      withBGRA: base.assumingMemoryBound(to: UInt8.self),
      width: width,
      height: height,
      stride: stride
    )
    input?.type = asImage ? .image : .video
    guard let input,
          let output = engine.processImage(input),
          let bgra = output.convert(.BGRA) else {
      return nil
    }
    return copyBGRAFrame(bgra)
  }

  private static func copyBGRAFrame(_ frame: FBImageFrame) -> CVPixelBuffer? {
    let width = Int(frame.width)
    let height = Int(frame.height)
    let sourceStride = Int(frame.stride)
    guard let source = frame.data(), width > 0, height > 0 else { return nil }

    let attrs: [CFString: Any] = [
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
      kCVPixelBufferMetalCompatibilityKey: true,
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ]
    var output: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &output
    )
    guard status == kCVReturnSuccess, let output else { return nil }

    CVPixelBufferLockBaseAddress(output, [])
    defer { CVPixelBufferUnlockBaseAddress(output, []) }
    guard let destination = CVPixelBufferGetBaseAddress(output) else { return nil }
    let destinationStride = CVPixelBufferGetBytesPerRow(output)
    let rowBytes = min(sourceStride, destinationStride)
    for row in 0..<height {
      memcpy(
        destination.advanced(by: row * destinationStride),
        source.advanced(by: row * sourceStride),
        rowBytes
      )
    }
    return output
  }

  /// Same role as React `imageToImageData`: one DeviceRGB BGRA buffer for both
  /// compare-original and engine input, so zero-effect output matches hold-to-compare.
  private static func makeBGRABuffer(from image: NSImage) -> CVPixelBuffer? {
    guard let cgImage = image.fb_cgImage else { return nil }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return nil }

    let attrs: [CFString: Any] = [
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
      kCVPixelBufferMetalCompatibilityKey: true,
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ]
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &buffer
    )
    guard status == kCVReturnSuccess, let buffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo =
      CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let context = CGContext(
      data: base,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      return nil
    }
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    return buffer
  }
}

extension NSImage {
  convenience init?(pixelBuffer: CVPixelBuffer) {
    let image = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
    self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
  }

  var fb_cgImage: CGImage? {
    var rect = CGRect(origin: .zero, size: size)
    return cgImage(forProposedRect: &rect, context: nil, hints: nil)
  }
}
