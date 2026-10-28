import { useEffect, useRef, useState } from 'react'
import { siteHomeUrl, useI18n } from '../i18n.jsx'
import { Icon } from './ui.jsx'

function drawImageData(canvas, imageData) {
  if (!canvas || !imageData) return
  if (canvas.width !== imageData.width || canvas.height !== imageData.height) {
    canvas.width = imageData.width
    canvas.height = imageData.height
  }
  canvas.getContext('2d').putImageData(imageData, 0, 0)
}

function syncOverlaySize(source, targets) {
  if (!source) return
  const width = `${source.clientWidth}px`
  const height = `${source.clientHeight}px`
  for (const canvas of targets) {
    if (!canvas) continue
    canvas.style.width = width
    canvas.style.height = height
  }
}

function fitDisplaySize(imageWidth, imageHeight, maxWidth, maxHeight) {
  if (!imageWidth || !imageHeight || maxWidth <= 0 || maxHeight <= 0) {
    return { width: 0, height: 0 }
  }
  const scale = Math.min(1, maxWidth / imageWidth, maxHeight / imageHeight)
  return {
    width: Math.max(1, Math.round(imageWidth * scale)),
    height: Math.max(1, Math.round(imageHeight * scale)),
  }
}

export default function Viewport({
  original,
  processed,
  onPickImage,
  onStartCamera,
  onLoadSample,
}) {
  const afterRef = useRef(null)
  const beforeRef = useRef(null)
  const stageRef = useRef(null)
  const { t, locale } = useI18n()
  const [holding, setHolding] = useState(false)
  const [stageSize, setStageSize] = useState({ width: 0, height: 0 })
  const showOriginal = holding && Boolean(original)
  const frame = processed || original
  const display = fitDisplaySize(frame?.width || 0, frame?.height || 0, stageSize.width, stageSize.height)

  useEffect(() => {
    const node = stageRef.current
    if (!node || typeof ResizeObserver === 'undefined') return undefined
    const update = () => {
      setStageSize({ width: node.clientWidth, height: node.clientHeight })
    }
    update()
    const observer = new ResizeObserver(update)
    observer.observe(node)
    return () => observer.disconnect()
  }, [])

  useEffect(() => {
    drawImageData(afterRef.current, processed)
    drawImageData(beforeRef.current, original)
    syncOverlaySize(afterRef.current, [beforeRef.current])
  }, [original, processed, showOriginal, display.width, display.height])

  const startHold = (event) => {
    if (!original || event.button > 0) return
    event.preventDefault()
    try {
      event.currentTarget.setPointerCapture(event.pointerId)
    } catch {
      /* some browsers reject capture on synthetic events */
    }
    setHolding(true)
  }

  const endHold = () => setHolding(false)

  return (
    <main className="flex-1 min-w-0 flex flex-col bg-[#0b0c10] relative overflow-hidden">
      <div className="flex-1 relative overflow-hidden bg-[#07080a] px-16 py-10">
        <div className="absolute inset-0 opacity-15 pointer-events-none bg-[radial-gradient(#272a33_1px,transparent_1px)] [background-size:16px_16px]" />
        <div
          ref={stageRef}
          className="relative z-10 w-full h-full flex items-center justify-center"
        >
        {display.width > 0 ? (
        <div
          className="relative bg-[#14161c] rounded shadow-2xl overflow-hidden border border-[#232731] select-none touch-none cursor-pointer shrink-0"
          style={{ width: display.width, height: display.height }}
          role="img"
          aria-label={showOriginal ? t('preview.ariaOriginal') : t('preview.ariaHold')}
          onPointerDown={startHold}
          onPointerUp={endHold}
          onPointerCancel={endHold}
          onLostPointerCapture={endHold}
          onContextMenu={(event) => event.preventDefault()}
        >
          <canvas ref={afterRef} className="block w-full h-full" />
          <div className={`absolute inset-0 z-10 overflow-hidden ${showOriginal ? '' : 'invisible'}`}>
            <canvas ref={beforeRef} className="block" />
            {showOriginal ? (
              <div className="absolute top-3 left-3 bg-[#0e1014]/85 backdrop-blur-md px-2 py-0.5 rounded border border-white/10 text-label-sm font-medium text-gray-200 flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-gray-400" />
                {t('preview.original')}
              </div>
            ) : null}
          </div>
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 z-30 pointer-events-none">
            <div className="px-2.5 py-1 rounded-full bg-[#0e1014]/80 backdrop-blur-md border border-white/10 text-label-sm text-gray-300 flex items-center gap-1.5 shadow-sm">
              <Icon name="touch_app" className="text-sm text-gray-400" />
              {showOriginal ? t('preview.release') : t('preview.hold')}
            </div>
          </div>
        </div>
        ) : (
        <div className="flex flex-col items-center gap-5">
          <p className="text-body-sm text-gray-500">{t('idle.hint')}</p>
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={onPickImage}
              className="w-44 h-36 rounded-2xl bg-[#14161c] border border-[#232731] hover:border-white/20 hover:bg-[#181a20] flex flex-col items-center justify-center gap-3 transition-colors"
            >
              <span className="w-11 h-11 rounded-full bg-[#181a20] border border-white/10 flex items-center justify-center">
                <Icon name="add_photo_alternate" className="text-2xl text-gray-200" />
              </span>
              <span className="text-body-sm font-medium text-gray-200">{t('idle.openImage')}</span>
            </button>
            <button
              type="button"
              onClick={onStartCamera}
              className="w-44 h-36 rounded-2xl bg-[#14161c] border border-[#232731] hover:border-white/20 hover:bg-[#181a20] flex flex-col items-center justify-center gap-3 transition-colors"
            >
              <span className="w-11 h-11 rounded-full bg-[#181a20] border border-white/10 flex items-center justify-center">
                <Icon name="photo_camera" className="text-2xl text-gray-200" />
              </span>
              <span className="text-body-sm font-medium text-gray-200">{t('idle.openCamera')}</span>
            </button>
          </div>
          <button
            type="button"
            onClick={onLoadSample}
            className="text-label-sm text-gray-500 hover:text-gray-200 underline underline-offset-4 decoration-white/20 hover:decoration-white/40 transition-colors"
          >
            {t('idle.sample')}
          </button>
        </div>
        )}
        </div>
        <a
          href={siteHomeUrl(locale)}
          target="_blank"
          rel="noopener noreferrer"
          className="absolute bottom-3 left-1/2 z-20 -translate-x-1/2 text-[9px] leading-none text-white/25 hover:text-white/45 transition-colors"
        >
          Facebetter Beauty Effect SDK
        </a>
      </div>
    </main>
  )
}
