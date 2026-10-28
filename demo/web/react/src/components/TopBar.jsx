import { siteHomeUrl, useI18n } from '../i18n.jsx'
import { Icon } from './ui.jsx'

export default function TopBar({
  onPickImage,
  onStartCamera,
  source,
  onExport,
}) {
  const { t, locale, setLocale } = useI18n()
  const idle = source === 'idle'

  return (
    <header className="h-12 w-full border-b border-[#222630] bg-[#0e1014] z-50 shrink-0 flex">
      <div className="flex-1 min-w-0 relative flex items-center px-6">
        <div className="flex items-center gap-2 min-w-0">
          <img src="/logo.png" alt="" className="h-8 w-8 shrink-0 rounded-full" />
          <span className="flex flex-col leading-none min-w-0">
            <span className="text-headline-sm font-semibold text-gray-100 tracking-tight">Facebetter</span>
            <span className="mt-0.5 text-[11px] font-normal text-gray-400 tracking-tight whitespace-nowrap">
              {t('app.product')}
            </span>
          </span>
        </div>
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="pointer-events-auto flex items-center gap-2">
            <button
              type="button"
              onClick={onPickImage}
              className="px-3 py-1 rounded-full bg-[#181a20] hover:bg-[#222630] border border-white/10 text-body-sm text-gray-300 hover:text-white flex items-center gap-1.5 transition-colors"
            >
              <Icon name="add_photo_alternate" className="text-sm text-gray-400" />
              {idle ? t('nav.openImage') : t('nav.replaceImage')}
            </button>
            <button
              type="button"
              onClick={onStartCamera}
              className={`px-3 py-1 rounded-full border text-body-sm flex items-center gap-1.5 transition-colors ${
                source === 'camera'
                  ? 'bg-white text-neutral-950 border-white'
                  : 'bg-[#181a20] hover:bg-[#222630] border-white/10 text-gray-300 hover:text-white'
              }`}
            >
              <Icon name="photo_camera" className="text-sm" />
              {t('nav.camera')}
            </button>
            <button
              type="button"
              onClick={onExport}
              disabled={idle}
              className={`px-3 py-1 rounded-full border text-body-sm flex items-center gap-1.5 transition-colors ${
                idle
                  ? 'bg-white/10 text-white/40 border-white/10 cursor-not-allowed'
                  : 'bg-white text-neutral-950 border-white hover:bg-gray-200'
              }`}
            >
              <Icon name="download" fill className="text-sm" />
              {t('nav.export')}
            </button>
          </div>
        </div>
      </div>

      <div className="w-[380px] shrink-0 flex items-center justify-end gap-3 px-5">
        <a
          href={siteHomeUrl(locale)}
          target="_blank"
          rel="noopener noreferrer"
          className="px-3 py-1 rounded-full bg-[#181a20] hover:bg-[#222630] border border-white/10 text-body-sm text-gray-300 hover:text-white flex items-center gap-1.5 transition-colors"
        >
          <Icon name="open_in_new" className="text-sm text-gray-400" />
          {t('nav.website')}
        </a>
        <div
          className="flex items-center rounded-full bg-[#181a20] border border-white/10 p-0.5"
          role="group"
          aria-label={t('nav.language')}
        >
          <button
            type="button"
            onClick={() => setLocale('zh')}
            className={`min-w-[32px] px-2 py-0.5 rounded-full text-label-sm font-medium transition-colors ${
              locale === 'zh'
                ? 'bg-white text-neutral-950'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            {t('nav.langZh')}
          </button>
          <button
            type="button"
            onClick={() => setLocale('en')}
            className={`min-w-[32px] px-2 py-0.5 rounded-full text-label-sm font-medium transition-colors ${
              locale === 'en'
                ? 'bg-white text-neutral-950'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            {t('nav.langEn')}
          </button>
        </div>
      </div>
    </header>
  )
}
