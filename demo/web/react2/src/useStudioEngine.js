import { useCallback, useEffect, useRef, useState } from 'react'
import { BeautyEffectEngine, EngineConfig, FrameType, MirrorMode } from 'facebetter'
import {
  FILTER_IDS,
  STICKERS,
  STUDIO_LOOK,
  applyParams,
  createDefaultParams,
} from './catalog.js'

const MAX_EDGE = 1280

async function loadBuffer(url) {
  const res = await fetch(url)
  if (!res.ok) return null
  return new Uint8Array(await res.arrayBuffer())
}

async function loadResources() {
  const filters = new Map()
  await Promise.all(
    FILTER_IDS.map(async (id) => {
      const data = await loadBuffer(`/assets/filters/portrait/${id}/${id}.fbd`)
      if (data) filters.set(id, data)
    })
  )
  const stickers = new Map()
  await Promise.all(
    STICKERS.map(async (item) => {
      const data = await loadBuffer(`/stickers/face/${item.id}.fbd`)
      if (data) stickers.set(item.id, data)
    })
  )
  return {
    filters,
    stickers,
    background: await loadBuffer('/background.jpg'),
  }
}

function imageToImageData(image, maxEdge = MAX_EDGE) {
  const scale = Math.min(1, maxEdge / Math.max(image.width, image.height))
  const width = Math.max(1, Math.round(image.width * scale))
  const height = Math.max(1, Math.round(image.height * scale))
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d', { willReadFrequently: true })
  ctx.drawImage(image, 0, 0, width, height)
  return ctx.getImageData(0, 0, width, height)
}

export function useStudioEngine() {
  const engineRef = useRef(null)
  const resourcesRef = useRef({ filters: new Map(), stickers: new Map(), background: null })
  const originalRef = useRef(null)
  const processedRef = useRef(null)
  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const rafRef = useRef(0)
  const busyRef = useRef(false)
  const sourceRef = useRef('image')

  const [statusKey, setStatusKey] = useState('status.initializing')
  const [statusExtra, setStatusExtra] = useState('')
  const [ready, setReady] = useState(false)
  const [params, setParams] = useState(() => createDefaultParams())
  const [faces, setFaces] = useState([])
  const [source, setSource] = useState('image')
  const [frameId, setFrameId] = useState(0)
  const [filterMap, setFilterMap] = useState({})
  const appliedParamsRef = useRef(null)

  const bumpFrame = useCallback(() => setFrameId((id) => id + 1), [])

  const flash = useCallback((key, extra = '') => {
    setStatusKey(key)
    setStatusExtra(extra)
    window.setTimeout(() => {
      setStatusKey('')
      setStatusExtra('')
    }, 2200)
  }, [])

  const processCurrent = useCallback((frameType = FrameType.Image, mirror = MirrorMode.None) => {
    const engine = engineRef.current
    const original = originalRef.current
    if (!engine || !original) return
    processedRef.current = engine.processImage(
      original,
      original.width,
      original.height,
      frameType,
      mirror
    )
    bumpFrame()
  }, [bumpFrame])

  const stopCamera = useCallback(() => {
    if (rafRef.current) {
      cancelAnimationFrame(rafRef.current)
      rafRef.current = 0
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop())
      streamRef.current = null
    }
    videoRef.current = null
  }, [])

  const pumpCamera = useCallback(() => {
    const video = videoRef.current
    const engine = engineRef.current
    if (!video || !engine || video.readyState < 2) {
      rafRef.current = requestAnimationFrame(pumpCamera)
      return
    }
    if (!busyRef.current) {
      busyRef.current = true
      try {
        const canvas = document.createElement('canvas')
        canvas.width = video.videoWidth
        canvas.height = video.videoHeight
        const ctx = canvas.getContext('2d', { willReadFrequently: true })
        // Front-camera selfie preview: flip once here so original and
        // processed share the same orientation during hold-to-compare.
        ctx.translate(canvas.width, 0)
        ctx.scale(-1, 1)
        ctx.drawImage(video, 0, 0)
        originalRef.current = ctx.getImageData(0, 0, canvas.width, canvas.height)
        processCurrent(FrameType.Video, MirrorMode.None)
      } catch (error) {
        console.error(error)
      } finally {
        busyRef.current = false
      }
    }
    rafRef.current = requestAnimationFrame(pumpCamera)
  }, [processCurrent])

  const loadImageElement = useCallback((image) => {
    stopCamera()
    sourceRef.current = 'image'
    setSource('image')
    originalRef.current = imageToImageData(image)
    processCurrent(FrameType.Image)
  }, [processCurrent, stopCamera])

  const loadImageFile = useCallback(async (file) => {
    const url = URL.createObjectURL(file)
    try {
      const image = new Image()
      await new Promise((resolve, reject) => {
        image.onload = resolve
        image.onerror = reject
        image.src = url
      })
      loadImageElement(image)
      flash('status.imageLoaded')
    } finally {
      URL.revokeObjectURL(url)
    }
  }, [flash, loadImageElement])

  const startCamera = useCallback(async () => {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false,
    })
    stopCamera()
    const video = document.createElement('video')
    video.srcObject = stream
    video.playsInline = true
    video.muted = true
    await video.play()
    streamRef.current = stream
    videoRef.current = video
    sourceRef.current = 'camera'
    setSource('camera')
    rafRef.current = requestAnimationFrame(pumpCamera)
    flash('status.cameraOn')
  }, [flash, pumpCamera, stopCamera])

  const resetParams = useCallback(() => {
    setParams(createDefaultParams())
    flash('status.reset')
  }, [flash])

  const applyLook = useCallback(() => {
    setParams((prev) => ({
      ...prev,
      ...STUDIO_LOOK,
      reshape: { ...prev.reshape, ...STUDIO_LOOK.reshape },
    }))
    flash('status.lookApplied')
  }, [flash])

  const exportImage = useCallback((mimeType = 'image/png') => {
    const frame = processedRef.current
    if (!frame) return
    const canvas = document.createElement('canvas')
    canvas.width = frame.width
    canvas.height = frame.height
    canvas.getContext('2d').putImageData(frame, 0, 0)
    canvas.toBlob(
      (blob) => {
        if (!blob) return
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        const pad = (value) => String(value).padStart(2, '0')
        const now = new Date()
        const stamp = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
        a.download = `fb_${stamp}.${mimeType === 'image/jpeg' ? 'jpg' : 'png'}`
        a.click()
        URL.revokeObjectURL(url)
      },
      mimeType,
      0.92
    )
  }, [])

  useEffect(() => {
    if (!ready || !engineRef.current) return
    try {
      const engine = engineRef.current
      applyParams(engine, params, resourcesRef.current, appliedParamsRef.current)
      appliedParamsRef.current = params

      if (sourceRef.current === 'image') {
        processCurrent(FrameType.Image)
      }
    } catch (error) {
      console.error(error)
      flash('status.paramFailed', error.message)
    }
  }, [flash, params, processCurrent, ready])

  useEffect(() => {
    let cancelled = false
    const boot = async () => {
      try {
        const engine = new BeautyEffectEngine(new EngineConfig({
          authProxyUrl: '/api/fb-auth',
        }))
        await engine.setLogConfig({ consoleEnabled: true, fileEnabled: false, level: 2 })
        await engine.init()
        const resources = await loadResources()
        if (cancelled) {
          engine.destroy()
          return
        }
        engineRef.current = engine
        resourcesRef.current = resources
        appliedParamsRef.current = null
        engine.setCallbacks({
          onFaceLandmarks: (results) => setFaces(results || []),
        })
        setReady(true)
        setStatusKey('')
        setStatusExtra('')
        const image = new Image()
        image.src = '/face.jpg'
        await image.decode()
        if (!cancelled) loadImageElement(image)
      } catch (error) {
        console.error(error)
        setStatusKey('status.initFailed')
        setStatusExtra(error.message || '')
      }
    }
    boot()
    fetch('/filter_mapping.json')
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (!data?.filters) return
        setFilterMap(data.filters)
      })
      .catch(() => {})
    return () => {
      cancelled = true
      stopCamera()
      engineRef.current?.destroy()
      engineRef.current = null
    }
  }, [loadImageElement, stopCamera])

  return {
    statusKey,
    statusExtra,
    ready,
    params,
    setParams,
    faces,
    source,
    frameId,
    filterMap,
    original: originalRef.current,
    processed: processedRef.current,
    loadImageFile,
    startCamera,
    stopCamera,
    resetParams,
    applyLook,
    exportImage,
  }
}
