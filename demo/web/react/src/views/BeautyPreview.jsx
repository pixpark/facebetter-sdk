import React, { useState, useRef, useEffect, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import BeautyPanel from '../components/BeautyPanel'
import { 
  BeautyEffectEngine, 
  EngineConfig, 
  BeautyType, 
  BasicParam,
  ReshapeParam,
  MakeupParam,
  ChromaKeyParam,
  BackgroundMode,
  VirtualBackgroundOptions,
  FrameType,
  MirrorMode 
} from 'facebetter'
import './BeautyPreview.css'

// Filter IDs (same order as Mac demo: assets/filters/portrait/<id>/<id>.fbd)
const FILTER_IDS = [
  'initial_heart', 'first_love', 'vivid', 'confession', 'milk_tea', 'mousse',
  'japanese', 'dawn', 'cookie', 'lively', 'pure', 'fair', 'snow', 'plain',
  'natural', 'rose', 'tender', 'tender_2', 'extraordinary'
]
// Stickers: { id, path under assets/stickers/ }
const STICKER_LIST = [{ id: 'rabbit', path: 'face/rabbit/rabbit.fbd' }]

/**
 * Register filter and sticker resources (same logic as Mac demo).
 * Fetches .fbd files from public/assets and registers with engine.
 */
async function registerFiltersAndStickers(engine) {
  const base = typeof window !== 'undefined' && window.location ? window.location.origin : ''
  for (const id of FILTER_IDS) {
    try {
      const url = `${base}/assets/filters/portrait/${id}/${id}.fbd`
      const res = await fetch(url)
      if (!res.ok) continue
      const buf = await res.arrayBuffer()
      engine.registerFilter(id, new Uint8Array(buf))
    } catch (e) {
      console.warn(`[BeautyPreview] Failed to register filter: ${id}`, e)
    }
  }
  for (const { id, path } of STICKER_LIST) {
    try {
      const url = `${base}/assets/stickers/${path}`
      const res = await fetch(url)
      if (!res.ok) continue
      const buf = await res.arrayBuffer()
      engine.registerSticker(id, new Uint8Array(buf))
    } catch (e) {
      console.warn(`[BeautyPreview] Failed to register sticker: ${id}`, e)
    }
  }
}

/**
 * BeautyPreview Component
 * Main component for beauty effect preview and processing
 * Handles camera stream, image processing, and Facebetter engine integration
 * 
 * Features:
 * - Real-time video processing with Facebetter engine
 * - Static image processing
 * - Beauty parameter adjustment (beauty, reshape, makeup, virtual background, chroma key)
 * - Face detection visualization
 * - Photo capture and save
 * - Before/after comparison
 */
function BeautyPreview() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const initialTab = searchParams.get('tab') || null

  // React refs for DOM elements
  const displayCanvasRef = useRef(null)      // Canvas for displaying processed frames
  const beautySeekBarRef = useRef(null)     // Slider for beauty parameter adjustment
  const beautyPanelRef = useRef(null)       // Reference to BeautyPanel component
  const fileInputRef = useRef(null)         // Hidden file input for image selection

  // Component state
  const [statusMessage, setStatusMessage] = useState('')
  const [showBeautyPanel, setShowBeautyPanel] = useState(true)
  const [showBeautySlider, setShowBeautySlider] = useState(false)
  const [currentTab, setCurrentTab] = useState('beauty')
  const [currentFunction, setCurrentFunction] = useState(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [isActive, setIsActive] = useState(false)
  const [isMobileDevice, setIsMobileDevice] = useState(false)
  const [currentSliderValue, setCurrentSliderValue] = useState(0)
  const [sliderValue, setSliderValue] = useState(0)
  const [isImageMode, setIsImageMode] = useState(false)
  const [faceDetectionResults, setFaceDetectionResults] = useState([])
  const [faceDetectionEnabled, setFaceDetectionEnabled] = useState(false)
  const [showKeyPointNumbers, setShowKeyPointNumbers] = useState(false)

  // Persistent refs (not recreated on render)
  const engineRef = useRef(null)              // Facebetter engine instance
  const videoElementRef = useRef(null)        // HTML video element for camera stream
  const videoStreamRef = useRef(null)         // MediaStream from getUserMedia
  const displayCtxRef = useRef(null)          // Canvas 2D context for display
  const animationFrameIdRef = useRef(null)   // requestAnimationFrame ID
  const lastProcessedFrameRef = useRef(null)  // Last processed ImageData (for photo capture)
  const currentImageRef = useRef(null)        // Current image file (for image mode)
  const imageElementRef = useRef(null)        // Current image element (for image mode)

  // Component initialization
  useEffect(() => {
    const init = async () => {
      try {
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                        ('ontouchstart' in window || navigator.maxTouchPoints > 0)
        setIsMobileDevice(isMobile)
        
        initCanvas()
        await initEngine()
        await startCamera()
        
        if (initialTab) {
          setShowBeautyPanel(true)
          setCurrentTab(initialTab)
        }
      } catch (error) {
        console.error('Initialization failed:', error)
        setStatusMessage(`Error: ${error.message}`)
      }
    }

    init()

    // Cleanup
    return () => {
      cleanup()
    }
  }, [])

  /**
   * Initialize display canvas
   * Sets canvas size to match container dimensions (max 960px width)
   */
  const initCanvas = useCallback(() => {
    const canvas = displayCanvasRef.current
    if (!canvas) return
    
    const container = canvas.parentElement
    const containerWidth = container ? Math.min(container.clientWidth, 1280) : window.innerWidth
    const containerHeight = container ? container.clientHeight : window.innerHeight
    canvas.width = containerWidth
    canvas.height = containerHeight
    displayCtxRef.current = canvas.getContext('2d')
  }, [])

  /**
   * Initialize Facebetter engine
   * Creates and configures the BeautyEffectEngine instance with app credentials
   */
  const initEngine = useCallback(async () => {
    const appId = 'dddb24155fd045ab9c2d8aad83ad3a4a'
    const appKey = '-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc'
    
    if (!appId || !appKey || appId.trim() === '' || appKey.trim() === '') {
      console.error('[Facebetter] Error: appId and appKey must be configured.')
      setStatusMessage('Error: Please configure appId and appKey')
      setTimeout(() => setStatusMessage(''), 3000)
      return
    }

    // Create engine configuration with app credentials
    const config = new EngineConfig({
      appId: appId,
      appKey: appKey
    })

    // Initialize BeautyEffectEngine instance
    const engine = new BeautyEffectEngine(config)

    // Configure logging (console only, level 0 = all logs)
    await engine.setLogConfig({
      consoleEnabled: true,
      fileEnabled: false,
      level: 0
    })

    // Initialize the engine (loads models and resources)
    await engine.init()

    // Enable beauty effect types
    engine.setBeautyTypeEnabled(BeautyType.Basic, true)              // Basic beauty (whitening, smoothing, rosiness)
    engine.setBeautyTypeEnabled(BeautyType.Reshape, true)             // Face reshaping (face thin, eye size, etc.)
    engine.setBeautyTypeEnabled(BeautyType.Makeup, true)             // Makeup effects (lipstick, blush, etc.)
    engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)   // Virtual background replacement
    engine.setBeautyTypeEnabled(BeautyType.ChromaKey, false)          // Chroma key (disabled by default)

    // Register filter and sticker resources (same as Mac demo)
    await registerFiltersAndStickers(engine)

    // Set face detection callback to receive face landmarks and detection results
    engine.setCallbacks({
      onFaceLandmarks: (results) => {
        // results: Array of face detection results with bounding boxes, key points, scores, etc.
        setFaceDetectionResults(results)
      },
      maxFaces: 10  // Maximum number of faces to detect
    })

    engineRef.current = engine

    setStatusMessage('Engine initialized successfully')
    setTimeout(() => setStatusMessage(''), 2000)
  }, [])

  /**
   * Start camera stream
   * Requests user media access and begins video frame processing
   */
  const startCamera = useCallback(async () => {
    try {
      const videoStream = await navigator.mediaDevices.getUserMedia({
        video: {
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 30 }
        },
        audio: false
      })

      const videoElement = document.createElement('video')
      videoElement.srcObject = videoStream
      videoElement.autoplay = true
      videoElement.playsInline = true
      await videoElement.play()

      videoElementRef.current = videoElement
      videoStreamRef.current = videoStream

      setIsActive(true)
      processVideoFrame()

      setStatusMessage('Camera started successfully')
      setTimeout(() => setStatusMessage(''), 2000)
    } catch (error) {
      throw new Error(`Camera access failed: ${error.message}`)
    }
  }, [])

  /**
   * Process video frame with Facebetter engine
   * Captures frame from video stream, processes it through the engine, and displays the result
   * Note: Video preview is mirrored for better UX, but saved photos are not mirrored
   */
  const processVideoFrame = useCallback(() => {
    if (!isActive || !engineRef.current || !videoElementRef.current || !videoElementRef.current.videoWidth) {
      if (isActive) {
        animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
      }
      return
    }

    if (isProcessing) {
      if (isActive) {
        animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
      }
      return
    }

    setIsProcessing(true)

    try {
      const videoElement = videoElementRef.current
      const canvas = document.createElement('canvas')
      canvas.width = videoElement.videoWidth
      canvas.height = videoElement.videoHeight
      const ctx = canvas.getContext('2d')
      ctx.drawImage(videoElement, 0, 0)
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      
      // Process image through Facebetter engine (horizontal mirror for front-camera preview)
      // FrameType.Video: Optimized for video processing; MirrorMode.Horizontal: mirror input before process
      const processed = engineRef.current.processImage(imageData, canvas.width, canvas.height, FrameType.Video, MirrorMode.Horizontal)
      lastProcessedFrameRef.current = processed

      if (displayCtxRef.current && displayCanvasRef.current) {
        const canvas = displayCanvasRef.current
        
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtxRef.current = canvas.getContext('2d')
        }
        
        displayCtxRef.current.putImageData(processed, 0, 0)
        drawFaceDetectionResults(displayCtxRef.current, canvas.width, canvas.height, false)
        
        const container = canvas.parentElement
        if (container) {
          const maxWidth = Math.min(container.clientWidth, 1280)
          const maxHeight = container.clientHeight
          
          const imageAspect = processed.width / processed.height
          const containerAspect = maxWidth / maxHeight
          
          let cssWidth, cssHeight
          if (imageAspect > containerAspect) {
            cssWidth = maxWidth + 'px'
            cssHeight = (maxWidth / imageAspect) + 'px'
          } else {
            cssHeight = maxHeight + 'px'
            cssWidth = (maxHeight * imageAspect) + 'px'
          }
          
          canvas.style.width = cssWidth
          canvas.style.height = cssHeight
        }
      }
    } catch (error) {
      console.error('Frame processing error:', error)
    }

    setIsProcessing(false)

    if (isActive) {
      animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
    }
  }, [isActive, isProcessing])

  /**
   * Draw face detection results on canvas
   * Renders face bounding boxes, key points, scores, and IDs from Facebetter detection results
   * @param {CanvasRenderingContext2D} ctx - Canvas 2D context
   * @param {number} canvasWidth - Canvas width in pixels
   * @param {number} canvasHeight - Canvas height in pixels
   * @param {boolean} isMirrored - Whether to mirror x coordinates (for video preview)
   */
  const drawFaceDetectionResults = useCallback((ctx, canvasWidth, canvasHeight, isMirrored) => {
    if (!faceDetectionEnabled) return
    
    if (!ctx || !faceDetectionResults || faceDetectionResults.length === 0) {
      return
    }

    faceDetectionResults.forEach((result, index) => {
      let rectX = result.rect.x * canvasWidth
      let rectY = result.rect.y * canvasHeight
      let rectWidth = result.rect.width * canvasWidth
      let rectHeight = result.rect.height * canvasHeight

      if (isMirrored) {
        rectX = canvasWidth - rectX - rectWidth
      }

      ctx.strokeStyle = '#F9DA69'
      ctx.lineWidth = 1
      ctx.strokeRect(rectX, rectY, rectWidth, rectHeight)

      const scoreText = `Score: ${result.score.toFixed(3)}`
      ctx.fillStyle = '#F9DA69' 
      ctx.font = '14px Arial'
      ctx.fillText(scoreText, rectX, rectY - 5)

      if (result.key_points && result.key_points.length > 0) {
        result.key_points.forEach((point, pointIndex) => {
          const isVisible = !result.visibility || result.visibility.length <= pointIndex || result.visibility[pointIndex] > 0.5
          
          if (isVisible) {
            let x = point.x * canvasWidth
            const y = point.y * canvasHeight

            if (isMirrored) {
              x = canvasWidth - x
            }

            ctx.fillStyle = '#F0F0F0'  
            ctx.beginPath()
            ctx.arc(x, y, 1.5, 0, Math.PI * 2)
            ctx.fill()

            if (showKeyPointNumbers) {
              ctx.fillStyle = '#FFFFFF'
              ctx.font = '8px Arial'
              const textX = isMirrored ? x - 3 : x + 3
              ctx.fillText(pointIndex.toString(), textX, y - 3)
            }
          }
        })
      }

      if (result.face_id >= 0) {
        ctx.fillStyle = '#F0F0F0'
        ctx.font = '12px Arial'
        const idX = isMirrored ? rectX + rectWidth - 50 : rectX + 5
        ctx.fillText(`ID: ${result.face_id}`, idX, rectY + 20)
      }
    })
  }, [faceDetectionEnabled, faceDetectionResults, showKeyPointNumbers])

  /**
   * Apply beauty parameter to Facebetter engine
   * Sets various beauty effect parameters based on tab and function key
   * @param {string} tab - Tab type: 'beauty', 'reshape', 'makeup', 'virtual_bg', 'chroma_key', 'face_detection'
   * @param {string} functionKey - Function key (e.g., 'white', 'smooth', 'thin_face', etc.)
   * @param {number} value - Parameter value (0.0-1.0 for most params)
   */
  const applyBeautyParam = useCallback((tab, functionKey, value) => {
    const engine = engineRef.current
    if (!engine) return

    try {
      // Clamp value to valid range [0.0, 1.0]
      const paramValue = Math.max(0, Math.min(1, value))

      // Basic beauty parameters
      if (tab === 'beauty') {
        switch (functionKey) {
          case 'white':
            engine.setBasicParam(BasicParam.Whitening, paramValue)
            break
          case 'smooth':
            engine.setBasicParam(BasicParam.Smoothing, paramValue)
            break
          case 'rosiness':
            engine.setBasicParam(BasicParam.Rosiness, paramValue)
            break
        }
      } else if (tab === 'reshape') {
        switch (functionKey) {
          case 'thin_face':
            engine.setReshapeParam(ReshapeParam.FaceThin, paramValue)
            break
          case 'v_face':
            engine.setReshapeParam(ReshapeParam.FaceVShape, paramValue)
            break
          case 'narrow_face':
            engine.setReshapeParam(ReshapeParam.FaceNarrow, paramValue)
            break
          case 'short_face':
            engine.setReshapeParam(ReshapeParam.FaceShort, paramValue)
            break
          case 'cheekbone':
            engine.setReshapeParam(ReshapeParam.Cheekbone, paramValue)
            break
          case 'jawbone':
            engine.setReshapeParam(ReshapeParam.Jawbone, paramValue)
            break
          case 'chin':
            engine.setReshapeParam(ReshapeParam.Chin, paramValue)
            break
          case 'nose_slim':
            engine.setReshapeParam(ReshapeParam.NoseSlim, paramValue)
            break
          case 'big_eye':
            engine.setReshapeParam(ReshapeParam.EyeSize, paramValue)
            break
          case 'eye_distance':
            engine.setReshapeParam(ReshapeParam.EyeDistance, paramValue)
            break
        }
      } else if (tab === 'makeup') {
        switch (functionKey) {
          case 'lipstick':
            engine.setMakeupParam(MakeupParam.Lipstick, paramValue)
            break
          case 'blush':
            engine.setMakeupParam(MakeupParam.Blush, paramValue)
            break
        }
      } else if (tab === 'virtual_bg') {
        // Virtual background options
        if (functionKey === 'blur') {
          engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)
          const options = new VirtualBackgroundOptions({
            mode: value > 0 ? BackgroundMode.Blur : BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        } else if (functionKey === 'preset') {
          engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)
          if (value > 0) {
            loadPresetBackground()
          } else {
            const options = new VirtualBackgroundOptions({
              mode: BackgroundMode.None
            })
            engine.setVirtualBackground(options)
          }
        } else if (functionKey === 'image') {
          engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)
          if (value <= 0) {
            const options = new VirtualBackgroundOptions({
              mode: BackgroundMode.None
            })
            engine.setVirtualBackground(options)
          }
        } else if (functionKey === 'none') {
          engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, false)
          const options = new VirtualBackgroundOptions({
            mode: BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        }
      } else if (tab === 'sticker') {
        // Sticker: same logic as Mac demo
        if (functionKey === 'off' || paramValue <= 0) {
          engine.setSticker('')
        } else {
          engine.setSticker(functionKey)
        }
      } else if (tab === 'filter') {
        // Filter: same logic as Mac demo
        engine.setBeautyTypeEnabled(BeautyType.Filter, functionKey !== 'off' && paramValue > 0)
        if (functionKey === 'off' || paramValue <= 0) {
          engine.setFilterIntensity(0)
        } else {
          engine.setFilter(functionKey)
          engine.setFilterIntensity(paramValue)
        }
      } else if (tab === 'chroma_key') {
        // Chroma key (green screen) parameters
        if (!engine.isBeautyTypeEnabled(BeautyType.ChromaKey)) {
          engine.setBeautyTypeEnabled(BeautyType.ChromaKey, true)
        }
        
        if (functionKey === 'key_color') {
          // Key color: 0=green, 1=blue, 2=red (value mapped from 0.0-1.0 to 0-2)
          const colorValue = Math.round(value * 2)
          engine.setChromaKeyParam(ChromaKeyParam.KeyColor, colorValue / 2.0)
        } else if (functionKey === 'similarity') {
          // Similarity: 0.0-1.0, default 0.72
          engine.setChromaKeyParam(ChromaKeyParam.Similarity, paramValue)
        } else if (functionKey === 'smoothness') {
          // Smoothness: 0.0-1.0, default 0.18
          engine.setChromaKeyParam(ChromaKeyParam.Smoothness, paramValue)
        } else if (functionKey === 'desaturation') {
          // Desaturation: 0.0-1.0, default 0.35
          engine.setChromaKeyParam(ChromaKeyParam.Desaturation, paramValue)
        }
      } else if (tab === 'face_detection') {
        if (functionKey === 'enable') {
          setFaceDetectionEnabled(value > 0)
        } else if (functionKey === 'show_numbers') {
          setShowKeyPointNumbers(value > 0)
        }
      }

      if (isImageMode && imageElementRef.current) {
        processImage()
      }
    } catch (error) {
      console.error('Failed to apply beauty parameter:', error)
    }
  }, [isImageMode])

  /**
   * Load preset background image for virtual background
   * Loads a predefined background image and sets it as the virtual background
   */
  const loadPresetBackground = useCallback(async () => {
    const engine = engineRef.current
    if (!engine) return

    try {
      const img = new Image()
      img.crossOrigin = 'anonymous'
      
      await new Promise((resolve, reject) => {
        img.onload = resolve
        img.onerror = () => reject(new Error('Failed to load preset background image'))
        img.src = '/background.jpg'
      })

      // Set virtual background to image mode with the loaded image
      const options = new VirtualBackgroundOptions({
        mode: BackgroundMode.Image,
        backgroundImage: img
      })
      engine.setVirtualBackground(options)
      console.log('Preset background set successfully:', img.width, 'x', img.height)
    } catch (error) {
      console.error('Failed to load preset background:', error)
      setStatusMessage('Failed to load preset background')
      setTimeout(() => setStatusMessage(''), 2000)
    }
  }, [])

  /**
   * Process static image with Facebetter engine
   * Processes a loaded image file through the engine and displays the result
   * Note: Images are not mirrored (unlike video preview)
   */
  const processImage = useCallback(async () => {
    const engine = engineRef.current
    const imageElement = imageElementRef.current
    const canvas = displayCanvasRef.current
    
    if (!engine || !imageElement || !canvas) {
      return
    }

    try {
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = imageElement.width
      tempCanvas.height = imageElement.height
      const ctx = tempCanvas.getContext('2d')
      ctx.drawImage(imageElement, 0, 0)
      const imageData = ctx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)

      // Process image through Facebetter engine
      // FrameType.Image: Optimized for static image processing
      const processed = engine.processImage(imageData, tempCanvas.width, tempCanvas.height, FrameType.Image)

      if (processed && canvas) {
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtxRef.current = canvas.getContext('2d')
        }
        
        displayCtxRef.current.putImageData(processed, 0, 0)
        lastProcessedFrameRef.current = processed
        
        drawFaceDetectionResults(displayCtxRef.current, canvas.width, canvas.height, false)
        
        const container = canvas.parentElement
        if (container) {
          const maxWidth = Math.min(container.clientWidth, 960)
          const maxHeight = container.clientHeight
          
          const imageAspect = processed.width / processed.height
          const containerAspect = maxWidth / maxHeight
          
          let cssWidth, cssHeight
          if (imageAspect > containerAspect) {
            cssWidth = maxWidth + 'px'
            cssHeight = (maxWidth / imageAspect) + 'px'
          } else {
            cssHeight = maxHeight + 'px'
            cssWidth = (maxHeight * imageAspect) + 'px'
          }
          
          canvas.style.width = cssWidth
          canvas.style.height = cssHeight
        }
      }
    } catch (error) {
      console.error('Image processing failed:', error)
    }
  }, [drawFaceDetectionResults])

  /**
   * Reset all beauty parameters to default (0)
   * Resets all basic beauty, reshape, makeup, and virtual background parameters
   */
  const resetAllParams = useCallback(() => {
    const engine = engineRef.current
    if (!engine) return

    try {
      // Reset basic beauty parameters
      engine.setBasicParam(BasicParam.Whitening, 0)
      engine.setBasicParam(BasicParam.Smoothing, 0)
      engine.setBasicParam(BasicParam.Rosiness, 0)

      // Reset reshape parameters
      engine.setReshapeParam(ReshapeParam.FaceThin, 0)
      engine.setReshapeParam(ReshapeParam.FaceVShape, 0)
      engine.setReshapeParam(ReshapeParam.FaceNarrow, 0)
      engine.setReshapeParam(ReshapeParam.FaceShort, 0)
      engine.setReshapeParam(ReshapeParam.Cheekbone, 0)
      engine.setReshapeParam(ReshapeParam.Jawbone, 0)
      engine.setReshapeParam(ReshapeParam.Chin, 0)
      engine.setReshapeParam(ReshapeParam.NoseSlim, 0)
      engine.setReshapeParam(ReshapeParam.EyeSize, 0)
      engine.setReshapeParam(ReshapeParam.EyeDistance, 0)

      // Reset makeup parameters
      engine.setMakeupParam(MakeupParam.Lipstick, 0)
      engine.setMakeupParam(MakeupParam.Blush, 0)

      // Reset sticker and filter (same as Mac beautyPanelDidReset)
      engine.setSticker('')
      engine.setFilterIntensity(0)

      // Reset virtual background
      const options = new VirtualBackgroundOptions({
        mode: BackgroundMode.None
      })
      engine.setVirtualBackground(options)
    } catch (error) {
      console.error('Failed to reset all parameters:', error)
    }
  }, [])

  /**
   * Reset parameters for a specific tab
   * @param {string} tab - Tab type to reset: 'beauty', 'reshape', 'makeup', 'virtual_bg', 'chroma_key', 'face_detection'
   */
  const resetTabParams = useCallback((tab) => {
    const engine = engineRef.current
    if (!engine) return

    try {
      if (tab === 'beauty') {
        engine.setBasicParam(BasicParam.Whitening, 0)
        engine.setBasicParam(BasicParam.Smoothing, 0)
        engine.setBasicParam(BasicParam.Rosiness, 0)
      } else if (tab === 'reshape') {
        engine.setReshapeParam(ReshapeParam.FaceThin, 0)
        engine.setReshapeParam(ReshapeParam.FaceVShape, 0)
        engine.setReshapeParam(ReshapeParam.FaceNarrow, 0)
        engine.setReshapeParam(ReshapeParam.FaceShort, 0)
        engine.setReshapeParam(ReshapeParam.Cheekbone, 0)
        engine.setReshapeParam(ReshapeParam.Jawbone, 0)
        engine.setReshapeParam(ReshapeParam.Chin, 0)
        engine.setReshapeParam(ReshapeParam.NoseSlim, 0)
        engine.setReshapeParam(ReshapeParam.EyeSize, 0)
        engine.setReshapeParam(ReshapeParam.EyeDistance, 0)
      } else if (tab === 'makeup') {
        engine.setMakeupParam(MakeupParam.Lipstick, 0)
        engine.setMakeupParam(MakeupParam.Blush, 0)
      } else if (tab === 'virtual_bg') {
        const options = new VirtualBackgroundOptions({
          mode: BackgroundMode.None
        })
        engine.setVirtualBackground(options)
      } else if (tab === 'filter') {
        engine.setBeautyTypeEnabled(BeautyType.Filter, false)
        engine.setFilterIntensity(0)
      } else if (tab === 'sticker') {
        engine.setSticker('')
      } else if (tab === 'chroma_key') {
        engine.setChromaKeyParam(ChromaKeyParam.KeyColor, 0)
        engine.setChromaKeyParam(ChromaKeyParam.Similarity, 0)
        engine.setChromaKeyParam(ChromaKeyParam.Smoothness, 0)
        engine.setChromaKeyParam(ChromaKeyParam.Desaturation, 0)
        engine.setBeautyTypeEnabled(BeautyType.ChromaKey, false)
      } else if (tab === 'face_detection') {
        setFaceDetectionEnabled(true)
        setShowKeyPointNumbers(true)
      }

      if (isImageMode && imageElementRef.current) {
        processImage()
      }
    } catch (error) {
      console.error('Failed to reset tab parameters:', error)
    }
  }, [isImageMode, processImage])

  /**
   * Stop camera stream
   * Stops video tracks and cancels animation frame processing
   */
  const stopCamera = useCallback(() => {
    setIsActive(false)

    if (animationFrameIdRef.current) {
      cancelAnimationFrame(animationFrameIdRef.current)
      animationFrameIdRef.current = null
    }

    if (videoStreamRef.current) {
      videoStreamRef.current.getTracks().forEach(track => track.stop())
      videoStreamRef.current = null
    }

    if (videoElementRef.current) {
      videoElementRef.current.srcObject = null
      videoElementRef.current = null
    }
  }, [])

  /**
   * Cleanup resources
   * Stops video stream, cancels animation frames, and destroys Facebetter engine
   * Called on component unmount
   */
  const cleanup = useCallback(() => {
    setIsActive(false)

    if (animationFrameIdRef.current) {
      cancelAnimationFrame(animationFrameIdRef.current)
      animationFrameIdRef.current = null
    }

    if (videoStreamRef.current) {
      videoStreamRef.current.getTracks().forEach(track => track.stop())
      videoStreamRef.current = null
    }

    // Destroy Facebetter engine to free resources
    if (engineRef.current) {
      engineRef.current.destroy()
      engineRef.current = null
    }

    videoElementRef.current = null
    lastProcessedFrameRef.current = null
  }, [])

  // Event handlers
  const onTabChanged = useCallback((tabId) => {
    setCurrentTab(tabId)
    setCurrentFunction(null)
    setShowBeautySlider(false)
    
    if (tabId === 'chroma_key' && engineRef.current) {
      if (!engineRef.current.isBeautyTypeEnabled(BeautyType.ChromaKey)) {
        engineRef.current.setBeautyTypeEnabled(BeautyType.ChromaKey, true)
      }
    }
  }, [])

  const onBeautyParamChanged = useCallback((data) => {
    applyBeautyParam(data.tab, data.function, data.value)
  }, [applyBeautyParam])

  const onShowSlider = useCallback((data) => {
    setCurrentFunction(data.function)
    setCurrentSliderValue(data.value)
    setSliderValue(data.value)
    setShowBeautySlider(true)
    
    applyBeautyParam(data.tab, data.function, data.value / 100.0)
  }, [applyBeautyParam])

  const onHideSlider = useCallback(() => {
    setShowBeautySlider(false)
  }, [])

  const onResetTab = useCallback((tab) => {
    resetTabParams(tab)
  }, [resetTabParams])

  const onSliderChange = useCallback((event) => {
    const value = parseInt(event.target.value)
    setCurrentSliderValue(value)
    setSliderValue(value)

    if (currentFunction && beautyPanelRef.current) {
      beautyPanelRef.current.updateSliderValue(currentTab, currentFunction, value)
    }

    if (currentFunction) {
      applyBeautyParam(currentTab, currentFunction, value / 100.0)
    }
  }, [currentFunction, currentTab, applyBeautyParam])

  const onSliderStart = useCallback(() => {}, [])
  const onSliderEnd = useCallback(() => {}, [])

  const goBack = useCallback(() => {
    navigate('/')
  }, [navigate])

  const openGallery = useCallback(() => {
    if (fileInputRef.current) {
      fileInputRef.current.click()
    }
  }, [])

  const onImageSelected = useCallback(async (event) => {
    const file = event.target.files[0]
    if (!file) return

    if (!file.type.startsWith('image/')) {
      setStatusMessage('Please select an image file')
      setTimeout(() => setStatusMessage(''), 2000)
      return
    }

    try {
      if (isActive) {
        stopCamera()
      }

      const reader = new FileReader()
      reader.onload = async (e) => {
        try {
          const img = new Image()
          img.onload = async () => {
            setIsImageMode(true)
            currentImageRef.current = file
            imageElementRef.current = img

            await processImage()

            setStatusMessage('Image loaded successfully')
            setTimeout(() => setStatusMessage(''), 2000)
          }
          img.onerror = () => {
            setStatusMessage('Failed to load image')
            setTimeout(() => setStatusMessage(''), 2000)
          }
          img.src = e.target.result
        } catch (error) {
          console.error('Failed to process image:', error)
          setStatusMessage('Failed to process image: ' + error.message)
          setTimeout(() => setStatusMessage(''), 2000)
        }
      }
      reader.onerror = () => {
        setStatusMessage('Failed to read file')
        setTimeout(() => setStatusMessage(''), 2000)
      }
      reader.readAsDataURL(file)
    } catch (error) {
      console.error('Failed to select image:', error)
      setStatusMessage('Failed to select image: ' + error.message)
      setTimeout(() => setStatusMessage(''), 2000)
    }

    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }, [isActive, stopCamera, processImage])

  const flipCamera = useCallback(async () => {
    if (!isMobileDevice) {
      return
    }

    try {
      if (videoStreamRef.current) {
        videoStreamRef.current.getTracks().forEach(track => track.stop())
      }

      const currentFacingMode = videoElementRef.current?.srcObject?.getVideoTracks()[0]?.getSettings().facingMode
      const constraints = {
        video: {
          facingMode: currentFacingMode === 'user' ? 'environment' : 'user'
        }
      }

      const videoStream = await navigator.mediaDevices.getUserMedia(constraints)
      videoElementRef.current.srcObject = videoStream
      await videoElementRef.current.play()
      videoStreamRef.current = videoStream
    } catch (error) {
      console.error('Failed to switch camera:', error)
      alert('Failed to switch camera')
    }
  }, [isMobileDevice])

  const toggleMore = useCallback(() => {
    alert('More options coming soon')
  }, [])

  useEffect(() => {
    if (isActive && !isImageMode) {
      const startProcessing = () => {
        processVideoFrame()
      }
      startProcessing()
    } else {
      if (animationFrameIdRef.current) {
        cancelAnimationFrame(animationFrameIdRef.current)
        animationFrameIdRef.current = null
      }
    }
  }, [isActive, isImageMode, processVideoFrame])

  return (
    <div className="camera-preview-container">
      <canvas ref={displayCanvasRef} className="camera-canvas"></canvas>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        style={{ display: 'none' }}
        onChange={onImageSelected}
      />

      <div className="top-bar">
        <button className="control-btn" onClick={goBack}>
          <img src="/icons/close.png" alt="Back" className="control-icon" />
        </button>
        <button className="control-btn" onClick={openGallery}>
          <img src="/icons/gallery.png" alt="Gallery" className="control-icon" />
        </button>
        <button 
          className={`control-btn ${!isMobileDevice ? 'disabled' : ''}`}
          onClick={flipCamera}
          disabled={!isMobileDevice}
        >
          <img src="/icons/switchcamera.png" alt="Switch Camera" className="control-icon" />
        </button>
        <button className="control-btn" onClick={toggleMore}>
          <img src="/icons/more.png" alt="More" className="control-icon" />
        </button>
      </div>

      {showBeautyPanel && (
        <BeautyPanel
          ref={beautyPanelRef}
          currentTab={currentTab}
          onTabChanged={onTabChanged}
          onBeautyParamChanged={onBeautyParamChanged}
          onShowSlider={onShowSlider}
          onHideSlider={onHideSlider}
          onResetTab={onResetTab}
        />
      )}

      {showBeautySlider && showBeautyPanel && (
        <div className="beauty-slider-container">
          <div className="beauty-value-text">{sliderValue}</div>
          <input 
            ref={beautySeekBarRef}
            type="range" 
            className="beauty-seekbar"
            min="0" 
            max="100" 
            step="1"
            value={currentSliderValue}
            onChange={onSliderChange}
            onTouchStart={onSliderStart}
            onTouchEnd={onSliderEnd}
            onMouseDown={onSliderStart}
            onMouseUp={onSliderEnd}
          />
        </div>
      )}

      {statusMessage && (
        <div className="status-message">{statusMessage}</div>
      )}
    </div>
  )
}

export default BeautyPreview
