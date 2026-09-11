import {
  Reshape,
  WhiteningStyle,
  SmoothingStyle,
  LipstickColor,
  BlushStyle,
  BlushColor,
  ContourStyle,
  EyeShadowStyle,
  EyeShadowColor,
  EyeLinerStyle,
  EyeLinerColor,
  EyebrowStyle,
  EyebrowColor,
  EyelashStyle,
  EyelashColor,
  PupilColor,
  ChromaKeyColor,
} from 'facebetter'

export const FILTER_IDS = [
  'initial_heart', 'first_love', 'vivid', 'confession', 'milk_tea', 'mousse',
  'japanese', 'dawn', 'cookie', 'lively', 'pure', 'fair', 'snow', 'plain',
  'natural', 'rose', 'tender', 'tender_2', 'extraordinary',
]

export const STICKERS = [
  { id: 'black_glass' },
  { id: 'pixel_glass' },
  { id: 'fox' },
  { id: 'antler' },
  { id: 'crown' },
  { id: 'hat' },
  { id: 'hat3' },
  { id: 'kiss' },
  { id: 'kiss2' },
  { id: 'mustache' },
  { id: 'mustache2' },
]

export const TABS = [
  { id: 'skin', icon: 'face' },
  { id: 'reshape', icon: 'accessibility_new' },
  { id: 'makeup', icon: 'brush' },
  { id: 'filter', icon: 'palette' },
  { id: 'sticker', icon: 'auto_awesome' },
  { id: 'background', icon: 'blur_on' },
]

export const SKIN_PRESETS = [
  { id: 'texture', smoothingStyle: SmoothingStyle.Texture },
  { id: 'natural', smoothingStyle: SmoothingStyle.Natural },
  { id: 'smooth', smoothingStyle: SmoothingStyle.Smooth },
]

export const WHITENING_STYLES = [
  { id: WhiteningStyle.ColdWhite, labelKey: 'whitening.coldWhite' },
  { id: WhiteningStyle.PinkWhite, labelKey: 'whitening.pinkWhite' },
  { id: WhiteningStyle.WarmWhite, labelKey: 'whitening.warmWhite' },
  { id: WhiteningStyle.Wheat, labelKey: 'whitening.wheat' },
  { id: WhiteningStyle.Tan, labelKey: 'whitening.tan' },
]

export const RESHAPE_GROUPS = [
  {
    id: 'face',
    items: [
      { key: Reshape.FaceThin, labelKey: 'reshape.faceThin' },
      { key: Reshape.FaceNarrow, labelKey: 'reshape.faceNarrow' },
      { key: Reshape.FaceSmall, labelKey: 'reshape.faceSmall' },
      { key: Reshape.FaceShort, labelKey: 'reshape.faceShort' },
      { key: Reshape.FaceVShape, labelKey: 'reshape.faceVShape' },
      { key: Reshape.Cheekbone, labelKey: 'reshape.cheekbone' },
      { key: Reshape.Jawbone, labelKey: 'reshape.jawbone' },
      { key: Reshape.Chin, labelKey: 'reshape.chin' },
    ],
  },
  {
    id: 'brow',
    items: [
      { key: Reshape.Forehead, labelKey: 'reshape.forehead' },
      { key: Reshape.BrowPosition, labelKey: 'reshape.browPosition' },
      { key: Reshape.BrowDistance, labelKey: 'reshape.browDistance' },
      { key: Reshape.BrowThickness, labelKey: 'reshape.browThickness' },
    ],
  },
  {
    id: 'eye',
    items: [
      { key: Reshape.EyeSize, labelKey: 'reshape.eyeSize' },
      { key: Reshape.EyeRound, labelKey: 'reshape.eyeRound' },
      { key: Reshape.EyeDistance, labelKey: 'reshape.eyeDistance' },
      { key: Reshape.EyePosition, labelKey: 'reshape.eyePosition' },
      { key: Reshape.EyeAngle, labelKey: 'reshape.eyeAngle' },
      { key: Reshape.EyeCornerOpen, labelKey: 'reshape.eyeCornerOpen' },
      { key: Reshape.LowerEyelid, labelKey: 'reshape.lowerEyelid' },
    ],
  },
  {
    id: 'nose',
    items: [
      { key: Reshape.NoseSlim, labelKey: 'reshape.noseSlim' },
      { key: Reshape.NoseLong, labelKey: 'reshape.noseLong' },
    ],
  },
  {
    id: 'mouth',
    items: [
      { key: Reshape.Philtrum, labelKey: 'reshape.philtrum' },
      { key: Reshape.MouthSize, labelKey: 'reshape.mouthSize' },
      { key: Reshape.MouthPosition, labelKey: 'reshape.mouthPosition' },
      { key: Reshape.MouthSmile, labelKey: 'reshape.mouthSmile' },
      { key: Reshape.LipThickness, labelKey: 'reshape.lipThickness' },
    ],
  },
]

export const LIPSTICK_COLORS = [
  { id: LipstickColor.Rouge, labelKey: 'lipstick.rouge', swatch: 'from-[#9d174d] to-[#be185d]' },
  { id: LipstickColor.RetroRed, labelKey: 'lipstick.retroRed', swatch: 'from-[#990024] to-[#c2183b]' },
  { id: LipstickColor.Peach, labelKey: 'lipstick.peach', swatch: 'from-[#be185d] to-[#fb7185]' },
  { id: LipstickColor.CoralOrange, labelKey: 'lipstick.coralOrange', swatch: 'from-[#b3391b] to-[#d65129]' },
  { id: LipstickColor.GentlePink, labelKey: 'lipstick.gentlePink', swatch: 'from-[#9d174d] to-[#f9a8d4]' },
  { id: LipstickColor.VitalityOrange, labelKey: 'lipstick.vitalityOrange', swatch: 'from-[#c2410c] to-[#fb923c]' },
]

export const BLUSH_STYLES = [
  { id: BlushStyle.SunKissed, labelKey: 'blush.sunKissed' },
  { id: BlushStyle.Igari, labelKey: 'blush.igari' },
  { id: BlushStyle.Soft, labelKey: 'blush.soft' },
  { id: BlushStyle.Apple, labelKey: 'blush.apple' },
  { id: BlushStyle.Classic, labelKey: 'blush.classic' },
  { id: BlushStyle.Doll, labelKey: 'blush.doll' },
  { id: BlushStyle.Rose, labelKey: 'blush.rose' },
]

export const BLUSH_COLORS = [
  { id: BlushColor.CoralPink, labelKey: 'blushColor.coralPink', swatch: 'bg-[#b45309]/80' },
  { id: BlushColor.DustyRose, labelKey: 'blushColor.dustyRose', swatch: 'bg-[#9f1239]/80' },
  { id: BlushColor.VividRed, labelKey: 'blushColor.vividRed', swatch: 'bg-[#be123c]/80' },
  { id: BlushColor.Berry, labelKey: 'blushColor.berry', swatch: 'bg-[#831843]/80' },
  { id: BlushColor.SunsetOrange, labelKey: 'blushColor.sunsetOrange', swatch: 'bg-[#c2410c]/80' },
]

export const CONTOUR_STYLES = [
  { id: ContourStyle.Natural, labelKey: 'contour.natural' },
  { id: ContourStyle.Sculpt, labelKey: 'contour.sculpt' },
  { id: ContourStyle.Glow, labelKey: 'contour.glow' },
  { id: ContourStyle.Slim, labelKey: 'contour.slim' },
  { id: ContourStyle.Nose, labelKey: 'contour.nose' },
  { id: ContourStyle.Glam, labelKey: 'contour.glam' },
]

export const EYESHADOW_STYLES = [
  { id: EyeShadowStyle.Soft, labelKey: 'eyeshadow.soft' },
  { id: EyeShadowStyle.Crease, labelKey: 'eyeshadow.crease' },
  { id: EyeShadowStyle.Smoky, labelKey: 'eyeshadow.smoky' },
  { id: EyeShadowStyle.Halo, labelKey: 'eyeshadow.halo' },
  { id: EyeShadowStyle.Glow, labelKey: 'eyeshadow.glow' },
  { id: EyeShadowStyle.Drama, labelKey: 'eyeshadow.drama' },
  { id: EyeShadowStyle.Warm, labelKey: 'eyeshadow.warm' },
]

export const EYESHADOW_COLORS = [
  { id: EyeShadowColor.Plum, labelKey: 'eyeshadowColor.plum', swatch: 'bg-[#6b21a8]' },
  { id: EyeShadowColor.Brown, labelKey: 'eyeshadowColor.brown', swatch: 'bg-[#78350f]' },
  { id: EyeShadowColor.Gold, labelKey: 'eyeshadowColor.gold', swatch: 'bg-[#a16207]' },
  { id: EyeShadowColor.Pink, labelKey: 'eyeshadowColor.pink', swatch: 'bg-[#9d174d]' },
]

export const EYELINER_STYLES = [
  { id: EyeLinerStyle.Classic, labelKey: 'eyeliner.classic' },
  { id: EyeLinerStyle.Flick, labelKey: 'eyeliner.flick' },
  { id: EyeLinerStyle.CatEye, labelKey: 'eyeliner.catEye' },
  { id: EyeLinerStyle.Natural, labelKey: 'eyeliner.natural' },
  { id: EyeLinerStyle.Bold, labelKey: 'eyeliner.bold' },
  { id: EyeLinerStyle.Soft, labelKey: 'eyeliner.soft' },
]

export const EYELINER_COLORS = [
  { id: EyeLinerColor.Burgundy, labelKey: 'eyelinerColor.burgundy', swatch: 'bg-[#7f1d1d]' },
  { id: EyeLinerColor.Plum, labelKey: 'eyelinerColor.plum', swatch: 'bg-[#581c87]' },
  { id: EyeLinerColor.Chocolate, labelKey: 'eyelinerColor.chocolate', swatch: 'bg-[#431407]' },
  { id: EyeLinerColor.Coffee, labelKey: 'eyelinerColor.coffee', swatch: 'bg-[#1c1917]' },
  { id: EyeLinerColor.Mauve, labelKey: 'eyelinerColor.mauve', swatch: 'bg-[#3f3f46]' },
]

export const EYEBROW_STYLES = [
  { id: EyebrowStyle.Natural, labelKey: 'eyebrow.natural' },
  { id: EyebrowStyle.Soft, labelKey: 'eyebrow.soft' },
  { id: EyebrowStyle.Feathered, labelKey: 'eyebrow.feathered' },
  { id: EyebrowStyle.Mist, labelKey: 'eyebrow.mist' },
  { id: EyebrowStyle.Arched, labelKey: 'eyebrow.arched' },
  { id: EyebrowStyle.Powder, labelKey: 'eyebrow.powder' },
  { id: EyebrowStyle.Wild, labelKey: 'eyebrow.wild' },
  { id: EyebrowStyle.Full, labelKey: 'eyebrow.full' },
  { id: EyebrowStyle.Straight, labelKey: 'eyebrow.straight' },
]

export const EYEBROW_COLORS = [
  { id: EyebrowColor.DarkBrown, labelKey: 'eyebrowColor.darkBrown', swatch: 'bg-[#44403c]' },
  { id: EyebrowColor.Black, labelKey: 'eyebrowColor.black', swatch: 'bg-[#18181b]' },
  { id: EyebrowColor.SoftBrown, labelKey: 'eyebrowColor.softBrown', swatch: 'bg-[#78716c]' },
]

export const EYELASH_STYLES = [
  { id: EyelashStyle.Classic, labelKey: 'eyelash.classic' },
  { id: EyelashStyle.Manga, labelKey: 'eyelash.manga' },
  { id: EyelashStyle.Winged, labelKey: 'eyelash.winged' },
  { id: EyelashStyle.Wispy, labelKey: 'eyelash.wispy' },
  { id: EyelashStyle.Clustered, labelKey: 'eyelash.clustered' },
  { id: EyelashStyle.Doll, labelKey: 'eyelash.doll' },
]

export const EYELASH_COLORS = [
  { id: EyelashColor.Black, labelKey: 'eyelashColor.black', swatch: 'bg-[#09090b]' },
  { id: EyelashColor.Brown, labelKey: 'eyelashColor.brown', swatch: 'bg-[#44403c]' },
  { id: EyelashColor.SoftBlack, labelKey: 'eyelashColor.softBlack', swatch: 'bg-[#27272a]' },
]

export const PUPIL_COLORS = [
  { id: PupilColor.Hazel, labelKey: 'pupil.hazel' },
  { id: PupilColor.Ice, labelKey: 'pupil.ice' },
  { id: PupilColor.Mocha, labelKey: 'pupil.mocha' },
  { id: PupilColor.Olive, labelKey: 'pupil.olive' },
  { id: PupilColor.Gloss, labelKey: 'pupil.gloss' },
  { id: PupilColor.Moss, labelKey: 'pupil.moss' },
  { id: PupilColor.Sand, labelKey: 'pupil.sand' },
  { id: PupilColor.Glow, labelKey: 'pupil.glow' },
  { id: PupilColor.Slate, labelKey: 'pupil.slate' },
]

export const CHROMA_OPTIONS = [
  { id: ChromaKeyColor.Green, labelKey: 'bg.green' },
  { id: ChromaKeyColor.Blue, labelKey: 'bg.blue' },
  { id: ChromaKeyColor.Red, labelKey: 'bg.red' },
]

export function prettyFilterName(name) {
  if (!name) return ''
  return name.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

export function pickFilterLabel(row, locale, id) {
  if (!row) return prettyFilterName(id) || id
  if (locale === 'zh') return row.zh || prettyFilterName(row.en) || id
  return prettyFilterName(row.en) || row.zh || id
}

export const STUDIO_LOOK = {
  smoothing: 0.68,
  whitening: 0.42,
  rosiness: 0.35,
  sharpening: 0.25,
  lipstick: 0.75,
  lipstickColor: LipstickColor.RetroRed,
  blush: 0.48,
  blushStyle: BlushStyle.Soft,
  blushColor: BlushColor.CoralPink,
  reshape: {
    [Reshape.FaceThin]: 0.45,
    [Reshape.FaceVShape]: 0.3,
    [Reshape.Cheekbone]: 0.2,
    [Reshape.Chin]: 0.35,
    [Reshape.EyeSize]: 0.4,
    [Reshape.NoseSlim]: 0.3,
  },
}

export function createDefaultParams() {
  const reshape = {}
  for (const group of RESHAPE_GROUPS) {
    for (const item of group.items) {
      reshape[item.key] = 0
    }
  }
  return {
    smoothing: 0,
    smoothingStyle: SmoothingStyle.Texture,
    whitening: 0,
    whiteningStyle: WhiteningStyle.ColdWhite,
    rosiness: 0,
    sharpening: 0,
    skinOnly: false,
    reshape,
    lipstick: 0,
    lipstickColor: LipstickColor.Rouge,
    blush: 0,
    blushStyle: BlushStyle.Soft,
    blushColor: BlushColor.CoralPink,
    contour: 0,
    contourStyle: ContourStyle.Natural,
    eyeshadow: 0,
    eyeshadowStyle: EyeShadowStyle.Soft,
    eyeshadowColor: EyeShadowColor.Plum,
    eyeliner: 0,
    eyelinerStyle: EyeLinerStyle.Classic,
    eyelinerColor: EyeLinerColor.Coffee,
    eyebrow: 0,
    eyebrowStyle: EyebrowStyle.Natural,
    eyebrowColor: EyebrowColor.DarkBrown,
    eyelash: 0,
    eyelashStyle: EyelashStyle.Classic,
    eyelashColor: EyelashColor.Black,
    pupil: 0,
    pupilColor: PupilColor.Hazel,
    filterId: null,
    filterIntensity: 0.8,
    stickerId: null,
    bgBlur: 0,
    bgPreset: false,
    chroma: null,
    chromaSimilarity: 0.4,
    chromaSmoothness: 0.1,
    chromaDesaturation: 0.1,
    faceOverlay: false,
  }
}

export function applyParams(engine, params, resources, prev = null) {
  engine.setSmoothing(params.smoothing)
  engine.setSmoothingStyle(params.smoothingStyle)
  engine.setWhitening(params.whitening)
  engine.setWhiteningStyle(params.whiteningStyle)
  engine.setRosiness(params.rosiness)
  engine.setSharpening(params.sharpening)
  engine.setBeautySkinOnly(params.skinOnly)

  for (const [key, value] of Object.entries(params.reshape)) {
    engine.setReshape(Number(key), value)
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

  const filterChanged = !prev || prev.filterId !== params.filterId
  if (filterChanged) {
    if (params.filterId && resources.filters.get(params.filterId)) {
      engine.setFilter(resources.filters.get(params.filterId))
    } else {
      engine.clearFilter()
    }
  }
  if (params.filterId) {
    engine.setFilterIntensity(params.filterIntensity)
  }

  if (!prev || prev.stickerId !== params.stickerId) {
    if (params.stickerId && resources.stickers.get(params.stickerId)) {
      engine.setSticker(resources.stickers.get(params.stickerId))
    } else {
      engine.clearSticker()
    }
  }

  const chromaChanged =
    !prev ||
    prev.chroma !== params.chroma ||
    prev.chromaSimilarity !== params.chromaSimilarity ||
    prev.chromaSmoothness !== params.chromaSmoothness ||
    prev.chromaDesaturation !== params.chromaDesaturation
  if (chromaChanged) {
    if (params.chroma === null || params.chroma === undefined) {
      engine.clearChromaKey()
    } else {
      engine.setChromaKey(params.chroma)
      engine.setChromaKeySimilarity(params.chromaSimilarity)
      engine.setChromaKeySmoothness(params.chromaSmoothness)
      engine.setChromaKeyDesaturation(params.chromaDesaturation)
    }
  }

  const backgroundChanged =
    !prev ||
    prev.bgBlur !== params.bgBlur ||
    prev.bgPreset !== params.bgPreset
  if (backgroundChanged) {
    if (params.bgBlur > 0) {
      engine.setVirtualBackgroundBlur(params.bgBlur)
    } else if (params.bgPreset && resources.background) {
      engine.setVirtualBackground(resources.background)
    } else {
      engine.clearVirtualBackground()
    }
  }
}
