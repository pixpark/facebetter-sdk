import { useRef, useState } from 'react'
import Inspector from './components/Inspector.jsx'
import TopBar from './components/TopBar.jsx'
import Viewport from './components/Viewport.jsx'
import { useI18n } from './i18n.jsx'
import { useStudioEngine } from './useStudioEngine.js'

export default function App() {
  const fileRef = useRef(null)
  const [tab, setTab] = useState('skin')
  const studio = useStudioEngine()
  const { t } = useI18n()

  const statusText = studio.statusKey
    ? `${t(studio.statusKey)}${studio.statusExtra ? `: ${studio.statusExtra}` : ''}`
    : ''

  return (
    <div className="h-screen min-w-[1100px] w-full flex flex-col bg-[#0b0c10] text-[#f3f4f6] antialiased overflow-hidden">
      <TopBar
        onPickImage={() => fileRef.current?.click()}
        onStartCamera={() => studio.startCamera().catch((error) => window.alert(error.message))}
        source={studio.source}
        onExport={() => studio.exportImage('image/png')}
      />

      <div className="flex-1 flex overflow-hidden relative">
        <Viewport
          original={studio.original}
          processed={studio.processed}
          faces={studio.faces}
          faceOverlay={studio.params.faceOverlay}
          onToggleFaceOverlay={() => studio.setParams((p) => ({ ...p, faceOverlay: !p.faceOverlay }))}
        />
        <Inspector
          tab={tab}
          onTab={setTab}
          params={studio.params}
          setParams={studio.setParams}
          filterMap={studio.filterMap}
          onReset={studio.resetParams}
        />
      </div>

      <input
        ref={fileRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(event) => {
          const file = event.target.files?.[0]
          if (file) studio.loadImageFile(file)
          event.target.value = ''
        }}
      />

      {statusText ? (
        <div className="fixed left-6 bottom-6 z-50 px-3 py-1.5 rounded-lg bg-[#181a20]/90 border border-white/10 text-label-sm text-gray-200">
          {statusText}
        </div>
      ) : null}
    </div>
  )
}
