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

function drawFaces(canvas, faces, imageData) {
  if (!canvas || !imageData) return
  canvas.width = imageData.width
  canvas.height = imageData.height
  const ctx = canvas.getContext('2d')
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  if (!faces?.length) return

  faces.forEach((face, index) => {
    const x = face.rect.x * canvas.width
    const y = face.rect.y * canvas.height
    const w = face.rect.width * canvas.width
    const h = face.rect.height * canvas.height
    ctx.strokeStyle = 'rgba(255,255,255,0.55)'
    ctx.setLineDash([6, 4])
    ctx.strokeRect(x, y, w, h)
    ctx.setLineDash([])
    ctx.strokeStyle = 'rgba(255,255,255,0.8)'
    ctx.lineWidth = 2
    const c = 8
    ctx.beginPath()
    ctx.moveTo(x, y + c); ctx.lineTo(x, y); ctx.lineTo(x + c, y)
    ctx.moveTo(x + w - c, y); ctx.lineTo(x + w, y); ctx.lineTo(x + w, y + c)
    ctx.moveTo(x, y + h - c); ctx.lineTo(x, y + h); ctx.lineTo(x + c, y + h)
    ctx.moveTo(x + w - c, y + h); ctx.lineTo(x + w, y + h); ctx.lineTo(x + w, y + h - c)
    ctx.stroke()

    if (face.key_points) {
      face.key_points.forEach((point, i) => {
        const visible = !face.visibility || face.visibility[i] > 0.4
        if (!visible) return
        ctx.fillStyle = '#fff'
        ctx.beginPath()
        ctx.arc(point.x * canvas.width, point.y * canvas.height, 1.4, 0, Math.PI * 2)
        ctx.fill()
      })
    }

    const score = ((face.score || 0) * 100).toFixed(1)
    const label = `Face_${String(index + 1).padStart(2, '0')} ${score}%`
    ctx.font = '10px "JetBrains Mono", monospace'
    const tw = ctx.measureText(label).width
    ctx.fillStyle = 'rgba(255,255,255,0.9)'
    ctx.fillRect(x + w / 2 - tw / 2 - 6, y - 18, tw + 12, 14)
    ctx.fillStyle = '#111317'
    ctx.fillText(label, x + w / 2 - tw / 2, y - 8)
  })
}

export default function Viewport({
  original,
  processed,
  faces,
  faceOverlay,
  onToggleFaceOverlay,
}) {
  const afterRef = useRef(null)
  const beforeRef = useRef(null)
  const overlayRef = useRef(null)
  const stageRef = useRef(null)
  const { t, locale } = useI18n()
  const [holding, setHolding] = useState(false)
  const [stageSize, setStageSize] = useState({ width: 0, height: 0 })
  const showOriginal = holding && Boolean(original)
  const showOverlay = faceOverlay && !showOriginal
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
    drawFaces(overlayRef.current, showOverlay ? faces : [], processed || original)
    syncOverlaySize(afterRef.current, [beforeRef.current, overlayRef.current])
  }, [original, processed, faces, showOverlay, showOriginal, display.width, display.height])

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
          <canvas ref={overlayRef} className="absolute inset-0 pointer-events-none z-20" />
          <button
            type="button"
            className={
              `absolute top-3 right-3 z-40 px-2.5 py-1 rounded-full backdrop-blur-md border text-label-sm font-medium flex items-center gap-1.5 shadow-sm ` +
              (faceOverlay
                ? 'bg-white text-neutral-950 border-white'
                : 'bg-[#0e1014]/80 text-gray-300 border-white/10 hover:text-white')
            }
            onPointerDown={(event) => event.stopPropagation()}
            onClick={(event) => {
              event.stopPropagation()
              onToggleFaceOverlay?.()
            }}
          >
            <Icon name="face" className="text-sm" />
            {t('preview.keypoints')}
          </button>
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 z-30 pointer-events-none">
            <div className="px-2.5 py-1 rounded-full bg-[#0e1014]/80 backdrop-blur-md border border-white/10 text-label-sm text-gray-300 flex items-center gap-1.5 shadow-sm">
              <Icon name="touch_app" className="text-sm text-gray-400" />
              {showOriginal ? t('preview.release') : t('preview.hold')}
            </div>
          </div>
        </div>
        ) : null}
        </div>
        <a
          href={siteHomeUrl(locale)}
          target="_blank"
          rel="noopener noreferrer"
          className="absolute bottom-3 left-1/2 z-20 -translate-x-1/2 text-[9px] leading-none text-white/25 hover:text-white/45 transition-colors"
        >
          © 2021–{new Date().getFullYear()} PIXPARK LTD
        </a>
      </div>
    </main>
  )
}
