import { FILTER_IDS, STICKERS, TABS, pickFilterLabel } from '../catalog.js'
import {
  BLUSH_COLORS,
  BLUSH_STYLES,
  CHROMA_OPTIONS,
  CONTOUR_STYLES,
  EYEBROW_COLORS,
  EYEBROW_STYLES,
  EYELASH_COLORS,
  EYELASH_STYLES,
  EYELINER_COLORS,
  EYELINER_STYLES,
  EYESHADOW_COLORS,
  EYESHADOW_STYLES,
  LIPSTICK_COLORS,
  PUPIL_COLORS,
  RESHAPE_GROUPS,
  SKIN_PRESETS,
  WHITENING_STYLES,
} from '../catalog.js'
import { useI18n } from '../i18n.jsx'
import { BipolarSlider, Card, Chip, IOSSwitch, Icon, ParamSlider } from './ui.jsx'

function withLabels(items, t) {
  return items.map((item) => ({ ...item, label: t(item.labelKey) }))
}

function SwatchRow({ items, value, onChange, gradient }) {
  return (
    <div className="grid grid-cols-3 gap-1.5">
      {items.map((item) => {
        const active = value === item.id
        return (
          <button
            key={item.id}
            type="button"
            onClick={() => onChange(item.id)}
            className={
              `h-7 rounded-lg flex items-center justify-center text-telemetry-xs text-white/90 transition-colors ` +
              (gradient ? `bg-gradient-to-r ${item.swatch || 'from-zinc-700 to-zinc-500'} ` : `${item.swatch || 'bg-[#20232b]'} `) +
              (active ? 'ring-2 ring-white ring-offset-1 ring-offset-[#181a20]' : 'border border-white/15 hover:border-white/40')
            }
          >
            {item.label}
          </button>
        )
      })}
    </div>
  )
}

function SkinPanel({ params, setParams }) {
  const { t } = useI18n()
  return (
    <Card
      title={t('skin.title')}
      icon="face"
      extra={
        <div className="flex items-center gap-2">
          <div className="text-telemetry-xs text-gray-200">{t('skin.skinOnly')}</div>
          <IOSSwitch
            checked={params.skinOnly}
            label={t('skin.skinOnlyAria')}
            onChange={(checked) => setParams((p) => ({ ...p, skinOnly: checked }))}
          />
        </div>
      }
    >
      <div className="flex items-center justify-between">
        <span className="text-telemetry-xs text-gray-400">{t('skin.smoothingStyle')}</span>
        <button
          type="button"
          className="text-telemetry-xs text-gray-500 hover:text-white hover:underline"
          onClick={() => setParams((p) => ({ ...p, smoothing: 0, whitening: 0, rosiness: 0, sharpening: 0 }))}
        >
          {t('skin.reset')}
        </button>
      </div>
      <div className="grid grid-cols-3 gap-1.5">
        {SKIN_PRESETS.map((preset) => (
          <Chip
            key={preset.id}
            active={params.smoothingStyle === preset.smoothingStyle}
            onClick={() => setParams((p) => ({ ...p, smoothingStyle: preset.smoothingStyle }))}
          >
            {t(`smoothing.${preset.id}`)}
          </Chip>
        ))}
      </div>
      <ParamSlider label={t('skin.smoothing')} value={Math.round(params.smoothing * 100)} onChange={(v) => setParams((p) => ({ ...p, smoothing: v / 100 }))} />
      <div className="text-telemetry-xs text-gray-400">{t('skin.whiteningTone')}</div>
      <div className="grid grid-cols-5 gap-1">
        {WHITENING_STYLES.map((item) => (
          <Chip key={item.id} active={params.whiteningStyle === item.id} onClick={() => setParams((p) => ({ ...p, whiteningStyle: item.id }))}>
            {t(item.labelKey)}
          </Chip>
        ))}
      </div>
      <ParamSlider label={t('skin.whitening')} value={Math.round(params.whitening * 100)} onChange={(v) => setParams((p) => ({ ...p, whitening: v / 100 }))} />
      <ParamSlider label={t('skin.rosiness')} value={Math.round(params.rosiness * 100)} onChange={(v) => setParams((p) => ({ ...p, rosiness: v / 100 }))} />
      <ParamSlider label={t('skin.sharpening')} value={Math.round(params.sharpening * 100)} onChange={(v) => setParams((p) => ({ ...p, sharpening: v / 100 }))} />
    </Card>
  )
}

function ReshapePanel({ params, setParams }) {
  const { t } = useI18n()
  return (
    <>
      {RESHAPE_GROUPS.map((group) => (
        <Card key={group.id} title={t(`reshape.${group.id}`)} icon="accessibility_new">
          <div className="grid grid-cols-1 gap-3">
            {group.items.map((item) => (
              <BipolarSlider
                key={item.key}
                label={t(item.labelKey)}
                value={params.reshape[item.key] || 0}
                onChange={(value) => setParams((p) => ({ ...p, reshape: { ...p.reshape, [item.key]: value } }))}
              />
            ))}
          </div>
        </Card>
      ))}
    </>
  )
}

function MakeupBlock({
  title,
  dot,
  intensity,
  onIntensity,
  styles,
  styleValue,
  onStyle,
  styleLabel,
  colors,
  colorValue,
  onColor,
  colorLabel,
  intensityLabel,
  gradient,
}) {
  return (
    <div className="space-y-2.5">
      <div className="flex items-center text-telemetry-xs">
        <span className="text-gray-300 font-medium flex items-center gap-1">
          {dot ? <span className={`w-1.5 h-1.5 rounded-full ${dot}`} /> : null}
          {title}
        </span>
      </div>
      {styles ? (
        <>
          <div className="text-telemetry-xs text-gray-400">{styleLabel}</div>
          <div className="flex flex-wrap gap-1.5">
            {styles.map((item) => (
              <Chip key={item.id} active={styleValue === item.id} onClick={() => onStyle(item.id)}>
                {item.label}
              </Chip>
            ))}
          </div>
        </>
      ) : null}
      {colors ? (
        <>
          <div className="text-telemetry-xs text-gray-400">{colorLabel}</div>
          <SwatchRow items={colors} value={colorValue} onChange={onColor} gradient={gradient} />
        </>
      ) : null}
      <ParamSlider label={intensityLabel} value={Math.round(intensity * 100)} onChange={(v) => onIntensity(v / 100)} />
    </div>
  )
}

function MakeupPanel({ params, setParams }) {
  const { t } = useI18n()
  const styleLabel = t('makeup.style')
  const colorLabel = t('makeup.color')
  const intensityLabel = t('makeup.intensity')
  return (
    <Card title={t('makeup.title')} icon="brush" extra={<span className="px-2 py-0.5 rounded-full bg-white/5 text-gray-300 text-telemetry-xs border border-white/10">{t('makeup.fullSet')}</span>}>
      <MakeupBlock
        title={t('makeup.lipstick')}
        dot="bg-[#c2183b]"
        intensity={params.lipstick}
        onIntensity={(v) => setParams((p) => ({ ...p, lipstick: v }))}
        colors={withLabels(LIPSTICK_COLORS, t)}
        colorValue={params.lipstickColor}
        onColor={(id) => setParams((p) => ({ ...p, lipstickColor: id }))}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
        gradient
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.blush')}
        dot="bg-[#f87171]"
        intensity={params.blush}
        onIntensity={(v) => setParams((p) => ({ ...p, blush: v }))}
        styles={withLabels(BLUSH_STYLES, t)}
        styleValue={params.blushStyle}
        onStyle={(id) => setParams((p) => ({ ...p, blushStyle: id }))}
        colors={withLabels(BLUSH_COLORS, t)}
        colorValue={params.blushColor}
        onColor={(id) => setParams((p) => ({ ...p, blushColor: id }))}
        styleLabel={styleLabel}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.contour')}
        intensity={params.contour}
        onIntensity={(v) => setParams((p) => ({ ...p, contour: v }))}
        styles={withLabels(CONTOUR_STYLES, t)}
        styleValue={params.contourStyle}
        onStyle={(id) => setParams((p) => ({ ...p, contourStyle: id }))}
        styleLabel={styleLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.eyeshadow')}
        intensity={params.eyeshadow}
        onIntensity={(v) => setParams((p) => ({ ...p, eyeshadow: v }))}
        styles={withLabels(EYESHADOW_STYLES, t)}
        styleValue={params.eyeshadowStyle}
        onStyle={(id) => setParams((p) => ({ ...p, eyeshadowStyle: id }))}
        colors={withLabels(EYESHADOW_COLORS, t)}
        colorValue={params.eyeshadowColor}
        onColor={(id) => setParams((p) => ({ ...p, eyeshadowColor: id }))}
        styleLabel={styleLabel}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.eyeliner')}
        intensity={params.eyeliner}
        onIntensity={(v) => setParams((p) => ({ ...p, eyeliner: v }))}
        styles={withLabels(EYELINER_STYLES, t)}
        styleValue={params.eyelinerStyle}
        onStyle={(id) => setParams((p) => ({ ...p, eyelinerStyle: id }))}
        colors={withLabels(EYELINER_COLORS, t)}
        colorValue={params.eyelinerColor}
        onColor={(id) => setParams((p) => ({ ...p, eyelinerColor: id }))}
        styleLabel={styleLabel}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.eyebrow')}
        intensity={params.eyebrow}
        onIntensity={(v) => setParams((p) => ({ ...p, eyebrow: v }))}
        styles={withLabels(EYEBROW_STYLES, t)}
        styleValue={params.eyebrowStyle}
        onStyle={(id) => setParams((p) => ({ ...p, eyebrowStyle: id }))}
        colors={withLabels(EYEBROW_COLORS, t)}
        colorValue={params.eyebrowColor}
        onColor={(id) => setParams((p) => ({ ...p, eyebrowColor: id }))}
        styleLabel={styleLabel}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.eyelash')}
        intensity={params.eyelash}
        onIntensity={(v) => setParams((p) => ({ ...p, eyelash: v }))}
        styles={withLabels(EYELASH_STYLES, t)}
        styleValue={params.eyelashStyle}
        onStyle={(id) => setParams((p) => ({ ...p, eyelashStyle: id }))}
        colors={withLabels(EYELASH_COLORS, t)}
        colorValue={params.eyelashColor}
        onColor={(id) => setParams((p) => ({ ...p, eyelashColor: id }))}
        styleLabel={styleLabel}
        colorLabel={colorLabel}
        intensityLabel={intensityLabel}
      />
      <div className="h-px bg-[#262a35]" />
      <MakeupBlock
        title={t('makeup.pupil')}
        intensity={params.pupil}
        onIntensity={(v) => setParams((p) => ({ ...p, pupil: v }))}
        styles={withLabels(PUPIL_COLORS, t)}
        styleValue={params.pupilColor}
        onStyle={(id) => setParams((p) => ({ ...p, pupilColor: id }))}
        styleLabel={t('makeup.pupilColor')}
        intensityLabel={intensityLabel}
      />
    </Card>
  )
}

function FilterPanel({ params, setParams, filterMap = {} }) {
  const { t, locale } = useI18n()
  return (
    <Card
      title={t('filter.title')}
      icon="palette"
      extra={<span className="text-telemetry-xs text-gray-400">{t('filter.intensityValue')} {Math.round(params.filterIntensity * 100)}%</span>}
    >
      <div className="grid grid-cols-3 gap-2">
        <button
          type="button"
          onClick={() => setParams((p) => ({ ...p, filterId: null }))}
          className={`border rounded-lg bg-[#20232b] p-1.5 text-telemetry-xs ${params.filterId ? 'border-white/10 text-gray-400' : 'border-white/60 text-white'}`}
        >
          {t('filter.none')}
        </button>
        {FILTER_IDS.map((id) => (
          <button
            key={id}
            type="button"
            onClick={() => setParams((p) => ({ ...p, filterId: id }))}
            className={`border rounded-lg bg-[#20232b] p-1.5 text-telemetry-xs truncate ${
              params.filterId === id ? 'border-white/60 text-white' : 'border-white/10 text-gray-400 hover:border-white/20'
            }`}
          >
            {pickFilterLabel(filterMap[id], locale, id)}
          </button>
        ))}
      </div>
      <ParamSlider
        label={t('filter.intensity')}
        value={Math.round(params.filterIntensity * 100)}
        onChange={(v) => setParams((p) => ({ ...p, filterIntensity: v / 100 }))}
      />
    </Card>
  )
}

function BackgroundPanel({ params, setParams }) {
  const { t } = useI18n()
  const fill = params.bgBlur > 0 ? 'blur' : params.bgPreset ? 'image' : 'off'

  const setFill = (next) => {
    if (next === 'blur') {
      setParams((p) => ({ ...p, bgBlur: p.bgBlur > 0 ? p.bgBlur : 0.5, bgPreset: false }))
      return
    }
    if (next === 'image') {
      setParams((p) => ({ ...p, bgPreset: true, bgBlur: 0 }))
      return
    }
    setParams((p) => ({ ...p, bgPreset: false, bgBlur: 0 }))
  }

  return (
    <Card title={t('bg.title')}>
      <div className="text-telemetry-xs text-gray-400">{t('bg.effect')}</div>
      <div className="grid grid-cols-3 gap-1.5">
        <Chip active={fill === 'off'} onClick={() => setFill('off')}>
          {t('bg.original')}
        </Chip>
        <Chip active={fill === 'blur'} onClick={() => setFill('blur')}>
          {t('bg.blur')}
        </Chip>
        <Chip active={fill === 'image'} onClick={() => setFill('image')}>
          {t('bg.preset')}
        </Chip>
      </div>
      {fill === 'blur' ? (
        <ParamSlider
          label={t('bg.blurAmount')}
          value={Math.round(params.bgBlur * 100)}
          onChange={(v) => setParams((p) => ({ ...p, bgBlur: v / 100, bgPreset: false }))}
        />
      ) : null}
      {fill === 'image' ? (
        <img
          src="/background.jpg"
          alt={t('bg.preset')}
          className="w-full h-20 object-cover rounded-lg border border-white/10"
        />
      ) : null}

      <div className="text-telemetry-xs text-gray-400 pt-1">{t('bg.cutout')}</div>
      <div className="grid grid-cols-4 gap-1.5">
        <Chip
          active={params.chroma === null}
          onClick={() => setParams((p) => ({ ...p, chroma: null }))}
        >
          {t('bg.portrait')}
        </Chip>
        {CHROMA_OPTIONS.map((item) => (
          <Chip
            key={item.id}
            active={params.chroma === item.id}
            onClick={() => setParams((p) => ({ ...p, chroma: item.id }))}
          >
            {t(item.labelKey)}
          </Chip>
        ))}
      </div>
      {params.chroma !== null ? (
        <>
          <ParamSlider label={t('bg.similarity')} value={Math.round(params.chromaSimilarity * 100)} onChange={(v) => setParams((p) => ({ ...p, chromaSimilarity: v / 100 }))} />
          <ParamSlider label={t('bg.smoothness')} value={Math.round(params.chromaSmoothness * 100)} onChange={(v) => setParams((p) => ({ ...p, chromaSmoothness: v / 100 }))} />
          <ParamSlider label={t('bg.desaturation')} value={Math.round(params.chromaDesaturation * 100)} onChange={(v) => setParams((p) => ({ ...p, chromaDesaturation: v / 100 }))} />
        </>
      ) : null}
    </Card>
  )
}

function StickerPanel({ params, setParams }) {
  const { t } = useI18n()
  return (
    <Card title={t('sticker.title')}>
      <div className="grid grid-cols-3 gap-1.5">
        <Chip active={!params.stickerId} onClick={() => setParams((p) => ({ ...p, stickerId: null }))}>{t('sticker.none')}</Chip>
        {STICKERS.map((item) => (
          <Chip key={item.id} active={params.stickerId === item.id} onClick={() => setParams((p) => ({ ...p, stickerId: item.id }))}>
            {t(`sticker.${item.id}`)}
          </Chip>
        ))}
      </div>
    </Card>
  )
}

export default function Inspector({ tab, onTab, params, setParams, filterMap, stats, onReset }) {
  const { t } = useI18n()
  const fps = Math.round(stats?.fps || 0)
  const ms = (stats?.avgProcessTimeMs || 0).toFixed(1)
  return (
    <aside className="w-[380px] shrink-0 bg-[#111317] border-l border-[#222630] flex flex-col z-40 shadow-xl">
      <div className="px-5 py-3 border-b border-[#222630] flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-emerald-400" />
          <span className="text-body-sm font-semibold text-gray-100">{t('console.title')}</span>
        </div>
        <span className="text-telemetry-xs text-gray-400 font-medium px-2 py-0.5 rounded-full bg-[#1c1b1d] border border-white/10 tabular-nums">
          {fps} FPS&nbsp;&nbsp;{ms} ms
        </span>
      </div>
      <div className="px-3 py-2 border-b border-[#222630] bg-[#14161c] grid grid-cols-6 gap-1">
        {TABS.map((item) => {
          const active = tab === item.id
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onTab(item.id)}
              className={
                `min-w-0 flex flex-col items-center justify-center gap-0.5 py-1.5 rounded-lg transition-colors ` +
                (active
                  ? 'bg-white text-neutral-950 shadow-sm'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-[#20232b]')
              }
            >
              <Icon name={item.icon} className="text-sm" />
              <span className="text-telemetry-xs font-medium leading-none">{t(`tab.${item.id}`)}</span>
            </button>
          )
        })}
      </div>
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {tab === 'skin' ? <SkinPanel params={params} setParams={setParams} /> : null}
        {tab === 'reshape' ? <ReshapePanel params={params} setParams={setParams} /> : null}
        {tab === 'makeup' ? <MakeupPanel params={params} setParams={setParams} /> : null}
        {tab === 'filter' ? <FilterPanel params={params} setParams={setParams} filterMap={filterMap} /> : null}
        {tab === 'background' ? <BackgroundPanel params={params} setParams={setParams} /> : null}
        {tab === 'sticker' ? <StickerPanel params={params} setParams={setParams} /> : null}
      </div>
      <div className="p-3 bg-[#16181f] border-t border-[#222630] flex items-center">
        <button
          type="button"
          onClick={onReset}
          className="px-3 py-1.5 rounded-lg bg-[#20232b] hover:bg-[#282d38] text-gray-300 hover:text-white text-label-sm font-medium border border-white/10 flex items-center gap-1.5"
        >
          <Icon name="refresh" className="text-sm text-gray-400" />
          {t('console.reset')}
        </button>
      </div>
    </aside>
  )
}
