import { siteHomeUrl, useI18n } from '../i18n.jsx'
import { Icon } from './ui.jsx'

export default function TopBar({
  onPickImage,
  onStartCamera,
  source,
  onExport,
}) {
  const { t, locale, setLocale } = useI18n()

  return (
    <header className="h-12 px-6 flex items-center justify-between w-full border-b border-[#222630] bg-[#0e1014] z-50 shrink-0">
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          <Icon name="auto_awesome" fill className="text-gray-200 text-xl" />
          <span className="text-headline-sm font-semibold text-gray-100 tracking-tight">
            FaceBetter
            <span className="text-gray-400 text-xs px-2 py-0.5 rounded-full bg-[#181a20] border border-white/10 font-normal ml-2">
              Studio
            </span>
          </span>
        </div>
        <div className="h-4 w-px bg-white/10 mx-1" />
        <button
          type="button"
          onClick={onPickImage}
          className="px-3 py-1 rounded-full bg-[#181a20] hover:bg-[#222630] border border-white/10 text-body-sm text-gray-300 hover:text-white flex items-center gap-1.5 transition-colors"
        >
          <Icon name="add_photo_alternate" className="text-sm text-gray-400" />
          {t('nav.replaceImage')}
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
      </div>

      <div className="flex items-center gap-3">
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
        <button
          type="button"
          onClick={onExport}
          className="px-4 py-1.5 rounded-full bg-white text-neutral-950 hover:bg-gray-200 font-medium text-body-sm shadow-sm flex items-center gap-1.5 transition-all"
        >
          <Icon name="download" fill className="text-sm" />
          {t('nav.export')}
        </button>
      </div>
    </header>
  )
}
