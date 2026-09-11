import Foundation

struct BeautyParams: Equatable {
  var smoothing: Float = 0
  var smoothingStyle: FBSmoothingStyle = .texture
  var whitening: Float = 0
  var whiteningStyle: FBWhiteningStyle = .coldWhite
  var rosiness: Float = 0
  var sharpening: Float = 0
  var skinOnly = false
  var reshape: [FBReshape: Float] = BeautyParams.emptyReshape()

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

  var filterID: String?
  var filterIntensity: Float = 0.8
  var stickerID: String?

  var backgroundFill: BackgroundFill = .off
  var bgBlur: Float = 0.5
  var chroma: FBChromaKeyColor?
  var chromaSimilarity: Float = 0.4
  var chromaSmoothness: Float = 0.1
  var chromaDesaturation: Float = 0.1

  static func emptyReshape() -> [FBReshape: Float] {
    var values: [FBReshape: Float] = [:]
    for item in BeautyCatalog.reshapeItems {
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
    }
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
    }
  }
}
