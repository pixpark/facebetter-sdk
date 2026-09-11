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

export function Chip({ active, onClick, children, className = '' }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        `${className} py-1.5 px-2.5 rounded-lg text-center text-label-sm transition-colors ` +
        (active
          ? 'bg-white/10 border border-white/20 text-white'
          : 'bg-[#20232b] border border-white/5 hover:border-white/20 text-gray-400 hover:text-gray-200')
      }
    >
      {children}
    </button>
  )
}

export function ParamSlider({ label, value, min = 0, max = 100, onChange }) {
  const percent = ((value - min) / (max - min)) * 100
  return (
    <label className="space-y-1 block">
      <div className="flex justify-between text-body-sm">
        <span className="text-gray-400">{label}</span>
        <span className="text-gray-200 font-medium text-label-sm font-mono">{value}</span>
      </div>
      <div className="relative flex items-center h-3">
        <div className="w-full h-1.5 bg-[#252830] rounded-full overflow-hidden">
          <div className="h-full bg-gray-200 rounded-full" style={{ width: `${percent}%` }} />
        </div>
        <input
          type="range"
          min={min}
          max={max}
          step={1}
          value={value}
          onChange={(event) => onChange(Number(event.target.value))}
          className="absolute inset-0 w-full opacity-0 cursor-pointer"
        />
        <div
          className="absolute -translate-x-1/2 w-3.5 h-3.5 rounded-full bg-[#111317] border-2 border-white shadow-sm pointer-events-none"
          style={{ left: `${percent}%` }}
        />
      </div>
    </label>
  )
}

export function BipolarSlider({ label, value, onChange }) {
  const percent = ((value + 1) / 2) * 100
  const display = Math.round(value * 100)
  return (
    <label className="space-y-1 block">
      <div className="flex justify-between text-telemetry-xs text-gray-400">
        <span>{label}</span>
        <span className="text-gray-200 font-medium font-mono">{display}</span>
      </div>
      <div className="relative flex items-center h-3">
        <div className="w-full h-1.5 bg-[#252830] rounded-full overflow-hidden">
          <div
            className="h-full bg-gray-200"
            style={
              value >= 0
                ? { marginLeft: '50%', width: `${percent - 50}%` }
                : { marginLeft: `${percent}%`, width: `${50 - percent}%` }
            }
          />
        </div>
        <input
          type="range"
          min={-100}
          max={100}
          step={1}
          value={display}
          onChange={(event) => onChange(Number(event.target.value) / 100)}
          className="absolute inset-0 w-full opacity-0 cursor-pointer"
        />
        <div
          className="absolute -translate-x-1/2 w-3.5 h-3.5 rounded-full bg-[#111317] border-2 border-white shadow-sm pointer-events-none"
          style={{ left: `${percent}%` }}
        />
      </div>
    </label>
  )
}
