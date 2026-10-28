import Foundation

struct BeautyParams: Equatable {
  var smoothing: Float = 0
  var smoothingStyle: FBSmoothingStyle = .texture
  var whitening: Float = 0
  var whiteningStyle: FBWhiteningStyle = .coldWhite
  var rosiness: Float = 0
  var clarity: Float = 0
  var brightness: Float = 0
  var contrast: Float = 0
  var saturation: Float = 0
  var colorTemperature: Float = 0
  var colorTint: Float = 0
  var skinOnly = false
  var reshape: [FBReshape: Float] = BeautyParams.emptyReshape()
  var bodyReshape: [FBBodyReshape: Float] = BeautyParams.emptyBodyReshape()

  var lipstick: Float = 0
  var lipstickColor: FBLipstickColor = .rouge
  var blush: Float = 0
  var blushStyle: FBBlushStyle = .soft
  var blushColor: FBBlushColor = .coralPink
  var contour: Float = 0
  var contourStyle: FBContourStyle = .natural
  var eyeshadow: Float = 0
  var eyeshadowStyle: FBEyeShadowStyle = .soft
  var eyeshadowColor: FBEyeShadowColor = .plum
  var eyeliner: Float = 0
  var eyelinerStyle: FBEyeLinerStyle = .classic
  var eyelinerColor: FBEyeLinerColor = .coffee
  var eyebrow: Float = 0
  var eyebrowStyle: FBEyebrowStyle = .natural
  var eyebrowColor: FBEyebrowColor = .darkBrown
  var eyelash: Float = 0
  var eyelashStyle: FBEyelashStyle = .classic
  var eyelashColor: FBEyelashColor = .black
  var pupil: Float = 0
  var pupilColor: FBPupilColor = .hazel
  var teethWhiten: Float = 0

  var filterID: String?
  var filterIntensity: Float = 0.8
  var stickerID: String?

  var backgroundFill: BackgroundFill = .off
  var bgPreset: String?
  var bgBlur: Float = 0.5
  var chroma: FBChromaKeyColor?
  var chromaSimilarity: Float = 0.4
  var chromaSmoothness: Float = 0.1
  var chromaDesaturation: Float = 0.1
  var subjectOutline = false

  static func emptyReshape() -> [FBReshape: Float] {
    var values: [FBReshape: Float] = [:]
    for item in BeautyCatalog.reshapeItems {
      values[item.key] = 0
    }
    return values
  }

  static func emptyBodyReshape() -> [FBBodyReshape: Float] {
    var values: [FBBodyReshape: Float] = [:]
    for item in BeautyCatalog.bodyItems {
      values[item.key] = 0
    }
    return values
  }

  func intensity(for item: MakeupItem) -> Float {
    switch item {
    case .lipstick: return lipstick
    case .blush: return blush
    case .contour: return contour
    case .eyeshadow: return eyeshadow
    case .eyeliner: return eyeliner
    case .eyebrow: return eyebrow
    case .eyelash: return eyelash
    case .pupil: return pupil
    case .teeth: return teethWhiten
    }
  }

  mutating func resetSkin() {
    let fresh = BeautyParams()
    smoothing = fresh.smoothing
    smoothingStyle = fresh.smoothingStyle
    whitening = fresh.whitening
    whiteningStyle = fresh.whiteningStyle
    rosiness = fresh.rosiness
    clarity = fresh.clarity
    skinOnly = fresh.skinOnly
  }

  mutating func resetReshape() {
    reshape = BeautyParams.emptyReshape()
  }

  mutating func resetBody() {
    bodyReshape = BeautyParams.emptyBodyReshape()
  }

  mutating func resetMakeup() {
    let fresh = BeautyParams()
    lipstick = fresh.lipstick
    lipstickColor = fresh.lipstickColor
    blush = fresh.blush
    blushStyle = fresh.blushStyle
    blushColor = fresh.blushColor
    contour = fresh.contour
    contourStyle = fresh.contourStyle
    eyeshadow = fresh.eyeshadow
    eyeshadowStyle = fresh.eyeshadowStyle
    eyeshadowColor = fresh.eyeshadowColor
    eyeliner = fresh.eyeliner
    eyelinerStyle = fresh.eyelinerStyle
    eyelinerColor = fresh.eyelinerColor
    eyebrow = fresh.eyebrow
    eyebrowStyle = fresh.eyebrowStyle
    eyebrowColor = fresh.eyebrowColor
    eyelash = fresh.eyelash
    eyelashStyle = fresh.eyelashStyle
    eyelashColor = fresh.eyelashColor
    pupil = fresh.pupil
    pupilColor = fresh.pupilColor
    teethWhiten = fresh.teethWhiten
  }

  mutating func resetColor() {
    let fresh = BeautyParams()
    brightness = fresh.brightness
    contrast = fresh.contrast
    saturation = fresh.saturation
    colorTemperature = fresh.colorTemperature
    colorTint = fresh.colorTint
    filterID = fresh.filterID
    filterIntensity = fresh.filterIntensity
  }

  mutating func resetSticker() {
    stickerID = nil
  }

  mutating func resetBackground() {
    let fresh = BeautyParams()
    backgroundFill = fresh.backgroundFill
    bgPreset = fresh.bgPreset
    bgBlur = fresh.bgBlur
    chroma = fresh.chroma
    chromaSimilarity = fresh.chromaSimilarity
    chromaSmoothness = fresh.chromaSmoothness
    chromaDesaturation = fresh.chromaDesaturation
    subjectOutline = fresh.subjectOutline
  }

  mutating func setIntensity(_ value: Float, for item: MakeupItem) {
    switch item {
    case .lipstick: lipstick = value
    case .blush: blush = value
    case .contour: contour = value
    case .eyeshadow: eyeshadow = value
    case .eyeliner: eyeliner = value
    case .eyebrow: eyebrow = value
    case .eyelash: eyelash = value
    case .pupil: pupil = value
    case .teeth: teethWhiten = value
    }
  }
}
