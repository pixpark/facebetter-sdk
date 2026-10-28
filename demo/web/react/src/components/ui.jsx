export function Icon({ name, fill = false, className = '' }) {
  return (
    <span
      className={`material-symbols-outlined ${fill ? 'fill-icon' : ''} ${className}`}
    >
      {name}
    </span>
  )
}

export function Card({ title, icon, extra, children }) {
  return (
    <section className="bg-[#181a20] rounded-xl border border-[#262a35] p-4 space-y-3 shadow-sm">
      <div className="flex items-center justify-between pb-2 border-b border-[#262a35]">
        <div className="flex items-center gap-2 text-body-sm font-semibold text-gray-200">
          {icon ? <Icon name={icon} className="text-gray-300 text-base" /> : null}
          <span>{title}</span>
        </div>
        {extra}
      </div>
      {children}
    </section>
  )
}

export function IOSSwitch({ checked, onChange, label }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
      className={`relative shrink-0 w-[42px] h-[24px] rounded-full transition-colors duration-200 ${
        checked ? 'bg-[#34c759]' : 'bg-[#3a3a3c]'
      }`}
    >
      <span
        className={`absolute top-[2px] left-[2px] h-[20px] w-[20px] rounded-full bg-white shadow-sm transition-transform duration-200 ${
          checked ? 'translate-x-[18px]' : 'translate-x-0'
        }`}
      />
    </button>
  )
}

export function Pill({ active, onClick, children }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        active
          ? 'px-3 py-1 rounded-full text-label-sm font-medium bg-white text-neutral-950 shrink-0 flex items-center gap-1 shadow-sm'
          : 'px-3 py-1 rounded-full text-label-sm font-medium text-gray-400 hover:text-gray-200 hover:bg-[#20232b] shrink-0 flex items-center gap-1 transition-colors'
      }
    >
      {children}
    </button>
  )
}

export function Chip({ active, onClick, children, className = '', badge }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        `${className} relative py-1.5 px-2.5 rounded-lg text-center text-label-sm transition-colors ` +
        (active
          ? 'bg-white/10 border border-white/20 text-white'
          : 'bg-[#20232b] border border-white/5 hover:border-white/20 text-gray-400 hover:text-gray-200')
      }
    >
      {children}
      {badge ? (
        <span className="absolute top-0.5 right-0.5 text-[9px] leading-none px-1 py-px rounded-full bg-amber-400 text-black font-semibold">
          {badge}
        </span>
      ) : null}
    </button>
  )
}

const THUMB_W = 22
const THUMB_H = 11

function thumbLeft(percent) {
  return `calc(${percent}% - ${(percent / 100) * THUMB_W}px)`
}

function fillToThumb(percent) {
  return `calc(${percent}% + ${(0.5 - percent / 100) * THUMB_W}px)`
}

function SliderRow({ label, display, percent, origin = 0, children }) {
  const from = Math.min(percent, origin)
  const to = Math.max(percent, origin)
  const active = Math.abs(percent - origin) > 0.05
  const fillStyle = origin === 0
    ? { left: 0, width: fillToThumb(percent) }
    : {
        left: fillToThumb(from),
        width: `calc(${to - from}% + ${((from - to) / 100) * THUMB_W}px)`,
      }
  return (
    <label className="flex items-center gap-2">
      <span className="shrink-0 min-w-16 text-body-sm text-[#9ca3af]">{label}</span>
      <div className="relative flex-1 h-[22px]">
        <div className="absolute left-0 right-0 top-1/2 h-1 -translate-y-1/2 overflow-hidden rounded-full bg-[#3d3f4b]">
          {active ? (
            <div className="absolute top-0 h-full bg-[#466bd5]" style={fillStyle} />
          ) : null}
        </div>
        <div
          className="pointer-events-none absolute top-1/2 -translate-y-1/2 rounded-full bg-white"
          style={{ width: THUMB_W, height: THUMB_H, left: thumbLeft(percent) }}
        />
        {children}
      </div>
      <span className="w-8 shrink-0 text-right font-mono text-body-sm tabular-nums text-[#e5e7eb]">{display}</span>
    </label>
  )
}

export function ParamSlider({ label, value, min = 0, max = 100, onChange }) {
  const percent = ((value - min) / (max - min)) * 100
  return (
    <SliderRow label={label} display={value} percent={percent}>
      <input
        type="range"
        min={min}
        max={max}
        step={1}
        value={value}
        onChange={(event) => onChange(Number(event.target.value))}
        className="absolute inset-0 w-full cursor-pointer opacity-0"
      />
    </SliderRow>
  )
}

export function BipolarSlider({ label, value, onChange }) {
  const percent = ((value + 1) / 2) * 100
  const display = Math.round(value * 100)
  return (
    <SliderRow label={label} display={display} percent={percent} origin={50}>
      <input
        type="range"
        min={-100}
        max={100}
        step={1}
        value={display}
        onChange={(event) => onChange(Number(event.target.value) / 100)}
        className="absolute inset-0 w-full cursor-pointer opacity-0"
      />
    </SliderRow>
  )
}
