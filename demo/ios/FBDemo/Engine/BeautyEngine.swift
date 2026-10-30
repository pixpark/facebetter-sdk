import Foundation
import UIKit

final class BeautyEngine {
  private let lock = NSLock()
  // Serializes parameter writes. Does not cover processImage, so intensity
  // changes are not stuck behind the frame currently being drawn.
  private let applyLock = NSLock()
  private var engine: FBBeautyEffectEngine?
  private var previous = BeautyParams()
  private var appliedOnce = false
  private var resourceRoot: URL
  private var backgroundImageData: Data?
  private var presetCache: [String: Data] = [:]

  private(set) var isReady = false
  private(set) var statusKey = "status.initializing"

  var onEvent: ((String) -> Void)?

  init(startImmediately: Bool = true) {
    resourceRoot = Bundle.main.resourceURL?.appendingPathComponent("Facebetter", isDirectory: true)
      ?? Bundle.main.bundleURL
    if startImmediately {
      start()
    }
  }

  func apply(_ params: BeautyParams) {
    applyLock.lock()
    defer { applyLock.unlock() }
    lock.lock()
    let current = engine
    let ready = isReady
    lock.unlock()
    guard let current, ready else { return }
    applyLocked(params, engine: current)
  }

  /// Gallery stills. Always processed as an image, so the result is ready when this returns.
  func process(_ image: UIImage, bypass: Bool) -> UIImage? {
    guard !bypass else { return image }
    let normalized = image.fb_normalizedUp()
    guard let pixelBuffer = withEngine({ engine -> CVPixelBuffer? in
      guard let input = FBImageFrame.create(with: normalized) else { return nil }
      input.type = .image
      guard let output = engine.processImage(input),
            let bgra = output.convert(.BGRA) else {
        return nil
      }
      return PixelBufferImages.copyBGRA(bgra)
    }) else {
      return image
    }
    return UIImage(pixelBuffer: pixelBuffer) ?? image
  }

  func withEngine<T>(_ body: (FBBeautyEffectEngine) -> T?) -> T? {
    lock.lock()
    defer { lock.unlock() }
    guard let engine, isReady else { return nil }
    return body(engine)
  }

  func start() {
    applyLock.lock()
    lock.lock()
    defer {
      lock.unlock()
      applyLock.unlock()
    }
    startLocked()
  }

  func shutdown() {
    applyLock.lock()
    lock.lock()
    engine = nil
    isReady = false
    previous = BeautyParams()
    appliedOnce = false
    statusKey = "status.initializing"
    lock.unlock()
    applyLock.unlock()
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
    created.setCallbacks(callbacks)

    let packNames = ["resource_3d.fbd", "resource_body.fbd"]
    for name in packNames {
      let pack = resourceRoot.appendingPathComponent(name)
      if FileManager.default.fileExists(atPath: pack.path) {
        _ = created.addResourcePack(pack.path)
      }
    }

    backgroundImageData = try? Data(contentsOf: resourceRoot.appendingPathComponent("background.jpg"))
    if created.responds(to: NSSelectorFromString("setSmoothing:")) {
      applyLocked(BeautyParams(), engine: created)
    } else {
      isReady = false
      statusKey = "status.sdkMismatch"
      onEvent?("status.sdkMismatch")
    }
  }

  private func applyLocked(_ params: BeautyParams, engine: FBBeautyEffectEngine) {
    guard engine.responds(to: NSSelectorFromString("setSmoothing:")) else { return }
    let prev = previous
    let force = !appliedOnce
    appliedOnce = true
    previous = params

    engine.setSmoothing(params.smoothing)
    engine.setSmoothingStyle(params.smoothingStyle)
    engine.setWhitening(params.whitening)
    if force || prev.whiteningStyle != params.whiteningStyle {
      engine.setWhiteningStyle(params.whiteningStyle)
    }
    engine.setRosiness(params.rosiness)
    engine.setBlemish(params.blemish)
    engine.setClarity(params.clarity)
    engine.setBrightness(params.brightness)
    engine.setContrast(params.contrast)
    engine.setSaturation(params.saturation)
    engine.setColorTemperature(params.colorTemperature)
    engine.setColorTint(params.colorTint)
    engine.setBeautySkinOnly(params.skinOnly)

    for item in BeautyCatalog.reshapeItems {
      engine.setReshape(item.key, intensity: params.reshape[item.key] ?? 0)
    }
    for item in BeautyCatalog.bodyItems {
      engine.setBodyReshape(item.key, intensity: params.bodyReshape[item.key] ?? 0)
    }

    engine.setLipstick(params.lipstick)
    if force || prev.lipstickColor != params.lipstickColor {
      engine.setLipstickColor(params.lipstickColor)
    }
    engine.setBlush(params.blush)
    if force || prev.blushStyle != params.blushStyle {
      engine.setBlushStyle(params.blushStyle)
    }
    if force || prev.blushColor != params.blushColor {
      engine.setBlushColor(params.blushColor)
    }
    engine.setContour(params.contour)
    if force || prev.contourStyle != params.contourStyle {
      engine.setContourStyle(params.contourStyle)
    }
    engine.setEyeShadow(params.eyeshadow)
    if force || prev.eyeshadowStyle != params.eyeshadowStyle {
      engine.setEyeShadowStyle(params.eyeshadowStyle)
    }
    if force || prev.eyeshadowColor != params.eyeshadowColor {
      engine.setEyeShadowColor(params.eyeshadowColor)
    }
    engine.setEyeLiner(params.eyeliner)
    if force || prev.eyelinerStyle != params.eyelinerStyle {
      engine.setEyeLinerStyle(params.eyelinerStyle)
    }
    if force || prev.eyelinerColor != params.eyelinerColor {
      engine.setEyeLinerColor(params.eyelinerColor)
    }
    engine.setEyebrow(params.eyebrow)
    if force || prev.eyebrowStyle != params.eyebrowStyle {
      engine.setEyebrowStyle(params.eyebrowStyle)
    }
    if force || prev.eyebrowColor != params.eyebrowColor {
      engine.setEyebrowColor(params.eyebrowColor)
    }
    engine.setEyelash(params.eyelash)
    if force || prev.eyelashStyle != params.eyelashStyle {
      engine.setEyelashStyle(params.eyelashStyle)
    }
    if force || prev.eyelashColor != params.eyelashColor {
      engine.setEyelashColor(params.eyelashColor)
    }
    engine.setPupil(params.pupil)
    if force || prev.pupilColor != params.pupilColor {
      engine.setPupilColor(params.pupilColor)
    }
    engine.setTeethWhiten(params.teethWhiten)

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
        if BeautyCatalog.sticker(id: stickerID)?.kind == .threeD {
          engine.clearSticker()
          engine.set3DSticker(path)
        } else {
          engine.clear3DSticker()
          engine.setSticker(path)
        }
      } else {
        engine.clearSticker()
        engine.clear3DSticker()
      }
    }

    if force || prev.chroma != params.chroma {
      if let chroma = params.chroma {
        engine.setChromaKey(chroma)
      } else {
        engine.clearChromaKey()
      }
    }
    if params.chroma != nil {
      engine.setChromaKeySimilarity(params.chromaSimilarity)
      engine.setChromaKeySmoothness(params.chromaSmoothness)
      engine.setChromaKeyDesaturation(params.chromaDesaturation)
    }

    if force || prev.backgroundFill != params.backgroundFill || prev.bgPreset != params.bgPreset {
      switch params.backgroundFill {
      case .blur:
        engine.setVirtualBackgroundBlur(params.bgBlur)
      case .image:
        let presetID = params.bgPreset ?? BeautyCatalog.backgroundPresets.first?.id
        if let presetID, let data = presetData(presetID) {
          engine.setVirtualBackgroundWith(data)
        } else if let backgroundImageData, !backgroundImageData.isEmpty {
          engine.setVirtualBackgroundWith(backgroundImageData)
        }
      case .off:
        engine.clearVirtualBackground()
      }
    } else if params.backgroundFill == .blur && prev.bgBlur != params.bgBlur {
      engine.setVirtualBackgroundBlur(params.bgBlur)
    }
    if prev.subjectOutline != params.subjectOutline {
      engine.setSubjectOutline(params.subjectOutline)
    }
  }

  private func presetData(_ id: String) -> Data? {
    if let cached = presetCache[id] { return cached }
    let url = resourceRoot.appendingPathComponent("backgrounds/\(id).jpg")
    guard let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
    presetCache[id] = data
    return data
  }

  private func filterPath(_ id: String) -> String? {
    let url = resourceRoot
      .appendingPathComponent("filters/portrait/\(id)/\(id).fbd")
    return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
  }

  private func stickerPath(_ id: String) -> String? {
    guard let item = BeautyCatalog.sticker(id: id) else { return nil }
    let url = resourceRoot.appendingPathComponent("\(item.kind.folder)/\(id).fbd")
    return FileManager.default.fileExists(atPath: url.path) ? url.path : nil
  }

  private static func loadConfig() -> [String: String] {
    guard let url = Bundle.main.url(forResource: "FacebetterConfig", withExtension: "plist"),
          let dictionary = NSDictionary(contentsOf: url) as? [String: String] else {
      return [:]
    }
    return dictionary
  }
}
