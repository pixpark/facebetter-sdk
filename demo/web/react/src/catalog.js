import {
  Reshape,
  BodyReshape,
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

export const BG_PRESETS = [
  { id: 'office', labelKey: 'bg.preset.office' },
  { id: 'living', labelKey: 'bg.preset.living' },
  { id: 'bookshelf', labelKey: 'bg.preset.bookshelf' },
  { id: 'bedroom', labelKey: 'bg.preset.bedroom' },
  { id: 'indoor', labelKey: 'bg.preset.indoor' },
]

export const FILTER_IDS = [
  'initial_heart', 'first_love', 'vivid', 'confession', 'milk_tea', 'mousse',
  'japanese', 'dawn', 'cookie', 'lively', 'pure', 'fair', 'snow', 'plain',
  'natural', 'rose', 'tender', 'tender_2', 'extraordinary',
]

export const STICKERS = [
  { id: 'black_glass', kind: 'face' },
  { id: 'fox', kind: 'face' },
  { id: 'kiss2', kind: 'face' },
  { id: 'mustache', kind: 'face' },
  { id: 'fan_club', kind: 'face' },
  { id: 'falling_sakura', kind: 'face', animated: true },
  { id: 'falling_pigs', kind: 'face', animated: true },
  { id: 'butterfly', kind: 'screen', animated: true },
  { id: 'petals', kind: 'screen', animated: true },
  { id: 'oculos', kind: '3d' },
  { id: 'red_glasses', kind: '3d' },
]

export const STICKER_GROUPS = [
  { kind: 'face', titleKey: 'sticker.group.face' },
  { kind: 'screen', titleKey: 'sticker.group.screen' },
  { kind: '3d', titleKey: 'sticker.group.3d' },
]

export function stickerFolder(kind) {
  if (kind === '3d') return '3d'
  if (kind === 'screen') return 'screen'
  return 'face'
}

export const TABS = [
  { id: 'skin', icon: 'spa' },
  { id: 'reshape', icon: 'face' },
  { id: 'makeup', icon: 'brush' },
  { id: 'filter', icon: 'palette' },
  { id: 'sticker', icon: 'auto_awesome' },
  { id: 'body', icon: 'accessibility' },
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

export const BODY_GROUPS = [
  {
    id: 'bodyTorso',
    items: [
      { key: BodyReshape.BodySlim, labelKey: 'reshape.bodySlim' },
      { key: BodyReshape.TorsoLong, labelKey: 'reshape.torsoLong' },
      { key: BodyReshape.WaistSlim, labelKey: 'reshape.waistSlim' },
      { key: BodyReshape.BustEnhance, labelKey: 'reshape.bustEnhance' },
    ],
  },
  {
    id: 'bodyArm',
    items: [
      { key: BodyReshape.ShoulderSlim, labelKey: 'reshape.shoulderSlim' },
      { key: BodyReshape.ArmSlim, labelKey: 'reshape.armSlim' },
    ],
  },
  {
    id: 'bodyLeg',
    items: [
      { key: BodyReshape.LegSlim, labelKey: 'reshape.legSlim' },
      { key: BodyReshape.LegLong, labelKey: 'reshape.legLong' },
      { key: BodyReshape.LegStretch, labelKey: 'reshape.legStretch' },
    ],
  },
]

export const BODY_ITEMS = BODY_GROUPS.flatMap((group) => group.items)

export const LIPSTICK_COLORS = [
  { id: LipstickColor.Rouge, labelKey: 'lipstick.rouge', swatch: 'from-[#9d174d] to-[#be185d]' },
  { id: LipstickColor.RetroRed, labelKey: 'lipstick.retroRed', swatch: 'from-[#990024] to-[#c2183b]' },
  { id: LipstickColor.Peach, labelKey: 'lipstick.peach', swatch: 'from-[#be185d] to-[#fb7185]' },
  { id: LipstickColor.CoralOrange, labelKey: 'lipstick.coralOrange', swatch: 'from-[#b3391b] to-[#d65129]' },
  { id: LipstickColor.GentlePink, labelKey: 'lipstick.gentlePink', swatch: 'from-[#9d174d] to-[#f9a8d4]' },
  { id: LipstickColor.VitalityOrange, labelKey: 'lipstick.vitalityOrange', swatch: 'from-[#c2410c] to-[#fb923c]' },
  { id: LipstickColor.Rosewood, labelKey: 'lipstick.rosewood', swatch: 'from-[#8f4a52] to-[#af626a]' },
  { id: LipstickColor.BrickRed, labelKey: 'lipstick.brickRed', swatch: 'from-[#82301f] to-[#a33c2c]' },
  { id: LipstickColor.Berry, labelKey: 'lipstick.berry', swatch: 'from-[#6e2238] to-[#8b2d49]' },
  { id: LipstickColor.Nude, labelKey: 'lipstick.nude', swatch: 'from-[#9a6a58] to-[#c4917d]' },
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
  { id: BlushColor.Peach, labelKey: 'blushColor.peach', swatch: 'bg-[#c96a4a]/80' },
  { id: BlushColor.SakuraPink, labelKey: 'blushColor.sakuraPink', swatch: 'bg-[#c25b7a]/80' },
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
  { id: EyeShadowColor.Champagne, labelKey: 'eyeshadowColor.champagne', swatch: 'bg-[#a8835f]' },
  { id: EyeShadowColor.Caramel, labelKey: 'eyeshadowColor.caramel', swatch: 'bg-[#9a4a1c]' },
  { id: EyeShadowColor.Burgundy, labelKey: 'eyeshadowColor.burgundy', swatch: 'bg-[#6b1f2c]' },
  { id: EyeShadowColor.Charcoal, labelKey: 'eyeshadowColor.charcoal', swatch: 'bg-[#3a3536]' },
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
  { id: EyeLinerColor.Black, labelKey: 'eyelinerColor.black', swatch: 'bg-[#0a0a0a]' },
  { id: EyeLinerColor.Coffee, labelKey: 'eyelinerColor.coffee', swatch: 'bg-[#1c1917]' },
  { id: EyeLinerColor.Chocolate, labelKey: 'eyelinerColor.chocolate', swatch: 'bg-[#431407]' },
  { id: EyeLinerColor.Grey, labelKey: 'eyelinerColor.grey', swatch: 'bg-[#52525b]' },
  { id: EyeLinerColor.Burgundy, labelKey: 'eyelinerColor.burgundy', swatch: 'bg-[#7f1d1d]' },
  { id: EyeLinerColor.Plum, labelKey: 'eyelinerColor.plum', swatch: 'bg-[#581c87]' },
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
  { id: EyebrowColor.AshBrown, labelKey: 'eyebrowColor.ashBrown', swatch: 'bg-[#5c5049]' },
  { id: EyebrowColor.SoftBrown, labelKey: 'eyebrowColor.softBrown', swatch: 'bg-[#78716c]' },
  { id: EyebrowColor.Black, labelKey: 'eyebrowColor.black', swatch: 'bg-[#27272a]' },
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
  const bodyReshape = {}
  for (const item of BODY_ITEMS) {
    bodyReshape[item.key] = 0
  }
  return {
    smoothing: 0,
    smoothingStyle: SmoothingStyle.Texture,
    whitening: 0,
    whiteningStyle: WhiteningStyle.ColdWhite,
    rosiness: 0,
    blemish: 0,
    clarity: 0,
    brightness: 0,
    contrast: 0,
    saturation: 0,
    colorTemperature: 0,
    colorTint: 0,
    skinOnly: false,
    reshape,
    bodyReshape,
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
    teethWhiten: 0,
    filterId: null,
    filterIntensity: 0.8,
    stickerId: null,
    bgBlur: 0,
    bgPreset: null,
    chroma: null,
    chromaSimilarity: 0.4,
    chromaSmoothness: 0.1,
    chromaDesaturation: 0.1,
    subjectOutline: false,
  }
}

export function applyParams(engine, params, resources, prev = null) {
  const changed = (key) => !prev || prev[key] !== params[key]
  engine.setSmoothing(params.smoothing)
  engine.setSmoothingStyle(params.smoothingStyle)
  engine.setWhitening(params.whitening)
  if (changed('whiteningStyle')) engine.setWhiteningStyle(params.whiteningStyle)
  engine.setRosiness(params.rosiness)
  engine.setBlemish(params.blemish || 0)
  engine.setClarity(params.clarity)
  engine.setBrightness(params.brightness)
  engine.setContrast(params.contrast)
  engine.setSaturation(params.saturation)
  engine.setColorTemperature(params.colorTemperature)
  engine.setColorTint(params.colorTint)
  engine.setBeautySkinOnly(params.skinOnly)

  for (const [key, value] of Object.entries(params.reshape)) {
    engine.setReshape(Number(key), value)
  }
  for (const [key, value] of Object.entries(params.bodyReshape || {})) {
    engine.setBodyReshape(Number(key), value)
  }

  engine.setLipstick(params.lipstick)
  if (changed('lipstickColor')) engine.setLipstickColor(params.lipstickColor)
  engine.setBlush(params.blush)
  if (changed('blushStyle')) engine.setBlushStyle(params.blushStyle)
  if (changed('blushColor')) engine.setBlushColor(params.blushColor)
  engine.setContour(params.contour)
  if (changed('contourStyle')) engine.setContourStyle(params.contourStyle)
  engine.setEyeShadow(params.eyeshadow)
  if (changed('eyeshadowStyle')) engine.setEyeShadowStyle(params.eyeshadowStyle)
  if (changed('eyeshadowColor')) engine.setEyeShadowColor(params.eyeshadowColor)
  engine.setEyeLiner(params.eyeliner)
  if (changed('eyelinerStyle')) engine.setEyeLinerStyle(params.eyelinerStyle)
  if (changed('eyelinerColor')) engine.setEyeLinerColor(params.eyelinerColor)
  engine.setEyebrow(params.eyebrow)
  if (changed('eyebrowStyle')) engine.setEyebrowStyle(params.eyebrowStyle)
  if (changed('eyebrowColor')) engine.setEyebrowColor(params.eyebrowColor)
  engine.setEyelash(params.eyelash)
  if (changed('eyelashStyle')) engine.setEyelashStyle(params.eyelashStyle)
  if (changed('eyelashColor')) engine.setEyelashColor(params.eyelashColor)
  engine.setPupil(params.pupil)
  if (changed('pupilColor')) engine.setPupilColor(params.pupilColor)
  engine.setTeethWhiten(params.teethWhiten)

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
    const item = STICKERS.find((s) => s.id === params.stickerId)
    const data = params.stickerId ? resources.stickers.get(params.stickerId) : null
    if (item?.kind === '3d' && data) {
      engine.clearSticker()
      engine.set3DSticker(data)
    } else if (data) {
      engine.clear3DSticker()
      engine.setSticker(data)
    } else {
      engine.clearSticker()
      engine.clear3DSticker()
    }
  }

  if (changed('chroma')) {
    if (params.chroma === null || params.chroma === undefined) {
      engine.clearChromaKey()
    } else {
      engine.setChromaKey(params.chroma)
    }
  }
  if (params.chroma !== null && params.chroma !== undefined) {
    engine.setChromaKeySimilarity(params.chromaSimilarity)
    engine.setChromaKeySmoothness(params.chromaSmoothness)
    engine.setChromaKeyDesaturation(params.chromaDesaturation)
  }

  const backgroundModeChanged = !prev || prev.bgPreset !== params.bgPreset || (prev.bgBlur > 0) !== (params.bgBlur > 0)
  if (backgroundModeChanged) {
    if (params.bgBlur > 0) {
      engine.setVirtualBackgroundBlur(params.bgBlur)
    } else if (params.bgPreset && resources.backgrounds?.get(params.bgPreset)) {
      engine.setVirtualBackground(resources.backgrounds.get(params.bgPreset))
    } else {
      engine.clearVirtualBackground()
    }
  } else if (params.bgBlur > 0 && prev.bgBlur !== params.bgBlur) {
    engine.setVirtualBackgroundBlur(params.bgBlur)
  }
  if (!prev || prev.subjectOutline !== params.subjectOutline) {
    engine.setSubjectOutline(!!params.subjectOutline)
  }
}
