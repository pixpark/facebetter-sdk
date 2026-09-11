import SwiftUI
import UIKit

enum BeautyTab: String, CaseIterable, Identifiable {
  case skin
  case reshape
  case makeup
  case filter
  case sticker
  case background

  var id: String { rawValue }

  var labelKey: String { "tab.\(rawValue)" }

  var symbol: String {
    switch self {
    case .skin: return "face.smiling"
    case .reshape: return "person.crop.circle"
    case .makeup: return "paintbrush.pointed"
    case .filter: return "camera.filters"
    case .sticker: return "sparkles"
    case .background: return "person.crop.rectangle"
    }
  }
}

enum SkinItem: String, CaseIterable, Identifiable {
  case smoothing
  case whitening
  case rosiness
  case sharpening

  var id: String { rawValue }
  var labelKey: String { "skin.\(rawValue)" }
}

enum MakeupItem: String, CaseIterable, Identifiable {
  case lipstick
  case blush
  case contour
  case eyeshadow
  case eyeliner
  case eyebrow
  case eyelash
  case pupil

  var id: String { rawValue }
  var labelKey: String { "makeup.\(rawValue)" }
}

enum BackgroundFill: String, CaseIterable, Identifiable {
  case off
  case blur
  case image

  var id: String { rawValue }

  var labelKey: String {
    switch self {
    case .off: return "bg.original"
    case .blur: return "bg.blur"
    case .image: return "bg.preset"
    }
  }
}

struct CatalogOption<Value: Hashable>: Identifiable {
  let id: Value
  let labelKey: String
  let color: Color?

  init(id: Value, labelKey: String, color: Color? = nil) {
    self.id = id
    self.labelKey = labelKey
    self.color = color
  }
}

struct ReshapeItem: Identifiable {
  let key: FBReshape
  let labelKey: String
  var id: Int { Int(key.rawValue) }
}

struct ReshapeGroup: Identifiable {
  let id: String
  let items: [ReshapeItem]
}

enum BeautyCatalog {
  static let smoothingStyles: [CatalogOption<FBSmoothingStyle>] = [
    .init(id: .texture, labelKey: "smoothing.texture"),
    .init(id: .natural, labelKey: "smoothing.natural"),
    .init(id: .smooth, labelKey: "smoothing.smooth"),
  ]

  static let whiteningStyles: [CatalogOption<FBWhiteningStyle>] = [
    .init(id: .coldWhite, labelKey: "whitening.coldWhite"),
    .init(id: .pinkWhite, labelKey: "whitening.pinkWhite"),
    .init(id: .warmWhite, labelKey: "whitening.warmWhite"),
    .init(id: .wheat, labelKey: "whitening.wheat"),
    .init(id: .tan, labelKey: "whitening.tan"),
  ]

  static let reshapeGroups: [ReshapeGroup] = [
    ReshapeGroup(id: "face", items: [
      .init(key: .faceThin, labelKey: "reshape.faceThin"),
      .init(key: .faceNarrow, labelKey: "reshape.faceNarrow"),
      .init(key: .faceSmall, labelKey: "reshape.faceSmall"),
      .init(key: .faceShort, labelKey: "reshape.faceShort"),
      .init(key: .faceVShape, labelKey: "reshape.faceVShape"),
      .init(key: .cheekbone, labelKey: "reshape.cheekbone"),
      .init(key: .jawbone, labelKey: "reshape.jawbone"),
      .init(key: .chin, labelKey: "reshape.chin"),
    ]),
    ReshapeGroup(id: "brow", items: [
      .init(key: .forehead, labelKey: "reshape.forehead"),
      .init(key: .browPosition, labelKey: "reshape.browPosition"),
      .init(key: .browDistance, labelKey: "reshape.browDistance"),
      .init(key: .browThickness, labelKey: "reshape.browThickness"),
    ]),
    ReshapeGroup(id: "eye", items: [
      .init(key: .eyeSize, labelKey: "reshape.eyeSize"),
      .init(key: .eyeRound, labelKey: "reshape.eyeRound"),
      .init(key: .eyeDistance, labelKey: "reshape.eyeDistance"),
      .init(key: .eyePosition, labelKey: "reshape.eyePosition"),
      .init(key: .eyeAngle, labelKey: "reshape.eyeAngle"),
      .init(key: .eyeCornerOpen, labelKey: "reshape.eyeCornerOpen"),
      .init(key: .lowerEyelid, labelKey: "reshape.lowerEyelid"),
    ]),
    ReshapeGroup(id: "nose", items: [
      .init(key: .noseSlim, labelKey: "reshape.noseSlim"),
      .init(key: .noseLong, labelKey: "reshape.noseLong"),
    ]),
    ReshapeGroup(id: "mouth", items: [
      .init(key: .philtrum, labelKey: "reshape.philtrum"),
      .init(key: .mouthSize, labelKey: "reshape.mouthSize"),
      .init(key: .mouthPosition, labelKey: "reshape.mouthPosition"),
      .init(key: .mouthSmile, labelKey: "reshape.mouthSmile"),
      .init(key: .lipThickness, labelKey: "reshape.lipThickness"),
    ]),
  ]

  static let reshapeItems: [ReshapeItem] = reshapeGroups.flatMap(\.items)

  static let lipstickColors: [CatalogOption<FBLipstickColor>] = [
    .init(id: .rouge, labelKey: "lipstick.rouge", color: Color(hex: 0xBE185D)),
    .init(id: .retroRed, labelKey: "lipstick.retroRed", color: Color(hex: 0xC2183B)),
    .init(id: .peach, labelKey: "lipstick.peach", color: Color(hex: 0xFB7185)),
    .init(id: .coralOrange, labelKey: "lipstick.coralOrange", color: Color(hex: 0xD65129)),
    .init(id: .gentlePink, labelKey: "lipstick.gentlePink", color: Color(hex: 0xF9A8D4)),
    .init(id: .vitalityOrange, labelKey: "lipstick.vitalityOrange", color: Color(hex: 0xFB923C)),
  ]

  static let blushStyles: [CatalogOption<FBBlushStyle>] = [
    .init(id: .sunKissed, labelKey: "blush.sunKissed"),
    .init(id: .igari, labelKey: "blush.igari"),
    .init(id: .soft, labelKey: "blush.soft"),
    .init(id: .apple, labelKey: "blush.apple"),
    .init(id: .classic, labelKey: "blush.classic"),
    .init(id: .doll, labelKey: "blush.doll"),
    .init(id: .rose, labelKey: "blush.rose"),
  ]

  static let blushColors: [CatalogOption<FBBlushColor>] = [
    .init(id: .coralPink, labelKey: "blushColor.coralPink", color: Color(hex: 0xB45309)),
    .init(id: .dustyRose, labelKey: "blushColor.dustyRose", color: Color(hex: 0x9F1239)),
    .init(id: .vividRed, labelKey: "blushColor.vividRed", color: Color(hex: 0xBE123C)),
    .init(id: .berry, labelKey: "blushColor.berry", color: Color(hex: 0x831843)),
    .init(id: .sunsetOrange, labelKey: "blushColor.sunsetOrange", color: Color(hex: 0xC2410C)),
  ]

  static let contourStyles: [CatalogOption<FBContourStyle>] = [
    .init(id: .natural, labelKey: "contour.natural"),
    .init(id: .sculpt, labelKey: "contour.sculpt"),
    .init(id: .glow, labelKey: "contour.glow"),
    .init(id: .slim, labelKey: "contour.slim"),
    .init(id: .nose, labelKey: "contour.nose"),
    .init(id: .glam, labelKey: "contour.glam"),
  ]

  static let eyeshadowStyles: [CatalogOption<FBEyeShadowStyle>] = [
    .init(id: .soft, labelKey: "eyeshadow.soft"),
    .init(id: .crease, labelKey: "eyeshadow.crease"),
    .init(id: .smoky, labelKey: "eyeshadow.smoky"),
    .init(id: .halo, labelKey: "eyeshadow.halo"),
    .init(id: .glow, labelKey: "eyeshadow.glow"),
    .init(id: .drama, labelKey: "eyeshadow.drama"),
    .init(id: .warm, labelKey: "eyeshadow.warm"),
  ]

  static let eyeshadowColors: [CatalogOption<FBEyeShadowColor>] = [
    .init(id: .plum, labelKey: "eyeshadowColor.plum", color: Color(hex: 0x6B21A8)),
    .init(id: .brown, labelKey: "eyeshadowColor.brown", color: Color(hex: 0x78350F)),
    .init(id: .gold, labelKey: "eyeshadowColor.gold", color: Color(hex: 0xA16207)),
    .init(id: .pink, labelKey: "eyeshadowColor.pink", color: Color(hex: 0x9D174D)),
  ]

  static let eyelinerStyles: [CatalogOption<FBEyeLinerStyle>] = [
    .init(id: .classic, labelKey: "eyeliner.classic"),
    .init(id: .flick, labelKey: "eyeliner.flick"),
    .init(id: .catEye, labelKey: "eyeliner.catEye"),
    .init(id: .natural, labelKey: "eyeliner.natural"),
    .init(id: .bold, labelKey: "eyeliner.bold"),
    .init(id: .soft, labelKey: "eyeliner.soft"),
  ]

  static let eyelinerColors: [CatalogOption<FBEyeLinerColor>] = [
    .init(id: .burgundy, labelKey: "eyelinerColor.burgundy", color: Color(hex: 0x7F1D1D)),
    .init(id: .plum, labelKey: "eyelinerColor.plum", color: Color(hex: 0x581C87)),
    .init(id: .chocolate, labelKey: "eyelinerColor.chocolate", color: Color(hex: 0x431407)),
    .init(id: .coffee, labelKey: "eyelinerColor.coffee", color: Color(hex: 0x1C1917)),
    .init(id: .mauve, labelKey: "eyelinerColor.mauve", color: Color(hex: 0x3F3F46)),
  ]

  static let eyebrowStyles: [CatalogOption<FBEyebrowStyle>] = [
    .init(id: .natural, labelKey: "eyebrow.natural"),
    .init(id: .soft, labelKey: "eyebrow.soft"),
    .init(id: .feathered, labelKey: "eyebrow.feathered"),
    .init(id: .mist, labelKey: "eyebrow.mist"),
    .init(id: .arched, labelKey: "eyebrow.arched"),
    .init(id: .powder, labelKey: "eyebrow.powder"),
    .init(id: .wild, labelKey: "eyebrow.wild"),
    .init(id: .full, labelKey: "eyebrow.full"),
    .init(id: .straight, labelKey: "eyebrow.straight"),
  ]

  static let eyebrowColors: [CatalogOption<FBEyebrowColor>] = [
    .init(id: .darkBrown, labelKey: "eyebrowColor.darkBrown", color: Color(hex: 0x44403C)),
    .init(id: .black, labelKey: "eyebrowColor.black", color: Color(hex: 0x18181B)),
    .init(id: .softBrown, labelKey: "eyebrowColor.softBrown", color: Color(hex: 0x78716C)),
  ]

  static let eyelashStyles: [CatalogOption<FBEyelashStyle>] = [
    .init(id: .classic, labelKey: "eyelash.classic"),
    .init(id: .manga, labelKey: "eyelash.manga"),
    .init(id: .winged, labelKey: "eyelash.winged"),
    .init(id: .wispy, labelKey: "eyelash.wispy"),
    .init(id: .clustered, labelKey: "eyelash.clustered"),
    .init(id: .doll, labelKey: "eyelash.doll"),
  ]

  static let eyelashColors: [CatalogOption<FBEyelashColor>] = [
    .init(id: .black, labelKey: "eyelashColor.black", color: Color(hex: 0x09090B)),
    .init(id: .brown, labelKey: "eyelashColor.brown", color: Color(hex: 0x44403C)),
    .init(id: .softBlack, labelKey: "eyelashColor.softBlack", color: Color(hex: 0x27272A)),
  ]

  static let pupilColors: [CatalogOption<FBPupilColor>] = [
    .init(id: .hazel, labelKey: "pupil.hazel", color: Color(hex: 0x92400E)),
    .init(id: .ice, labelKey: "pupil.ice", color: Color(hex: 0x7DD3FC)),
    .init(id: .mocha, labelKey: "pupil.mocha", color: Color(hex: 0x44403C)),
    .init(id: .olive, labelKey: "pupil.olive", color: Color(hex: 0x3F6212)),
    .init(id: .gloss, labelKey: "pupil.gloss", color: Color(hex: 0x292524)),
    .init(id: .moss, labelKey: "pupil.moss", color: Color(hex: 0x4D7C0F)),
    .init(id: .sand, labelKey: "pupil.sand", color: Color(hex: 0xA8A29E)),
    .init(id: .glow, labelKey: "pupil.glow", color: Color(hex: 0xFDE68A)),
    .init(id: .slate, labelKey: "pupil.slate", color: Color(hex: 0x64748B)),
  ]

  static let chromaOptions: [CatalogOption<FBChromaKeyColor>] = [
    .init(id: .green, labelKey: "bg.green", color: Color(hex: 0x22C55E)),
    .init(id: .blue, labelKey: "bg.blue", color: Color(hex: 0x3B82F6)),
    .init(id: .red, labelKey: "bg.red", color: Color(hex: 0xEF4444)),
  ]

  static let filterIDs: [String] = [
    "initial_heart", "first_love", "vivid", "confession", "milk_tea", "mousse",
    "japanese", "dawn", "cookie", "lively", "pure", "fair", "snow", "plain",
    "natural", "rose", "tender", "tender_2", "extraordinary",
  ]

  static let stickerIDs: [String] = [
    "black_glass", "pixel_glass", "fox", "antler", "crown", "hat", "hat3",
    "kiss", "kiss2", "mustache", "mustache2",
  ]
}

extension Color {
  init(hex: UInt32, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: alpha
    )
  }
}
