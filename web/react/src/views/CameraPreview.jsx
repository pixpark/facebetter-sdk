import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import BeautyPanel from '../components/BeautyPanel'
import { 
  BeautyEffectEngine, 
  EngineConfig, 
  BeautyType, 
  BasicParam,
  ReshapeParam,
  MakeupParam,
  BackgroundMode,
  VirtualBackgroundOptions,
  ProcessMode 
} from 'facebetter'
import './CameraPreview.css'

function CameraPreview() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const initialTab = searchParams.get('tab') || null

  // Refs
  const displayCanvasRef = useRef(null)
  const beautySeekBarRef = useRef(null)
  const beautyPanelRef = useRef(null)
  const fileInputRef = useRef(null)

  // State
  const [statusMessage, setStatusMessage] = useState('')
  const [showBeautyPanel, setShowBeautyPanel] = useState(false)
  const [showBeautySlider, setShowBeautySlider] = useState(false)
  const [showSliderValue, setShowSliderValue] = useState(false)
  const [currentTab, setCurrentTab] = useState('beauty')
  const [currentFunction, setCurrentFunction] = useState(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [isActive, setIsActive] = useState(false)
  const isProcessingRef = useRef(false)
  const [isMobileDevice, setIsMobileDevice] = useState(false)
  const [currentSliderValue, setCurrentSliderValue] = useState(0)
  const [sliderValue, setSliderValue] = useState(0)
  const [sliderValuePosition, setSliderValuePosition] = useState(0)
  const [isImageMode, setIsImageMode] = useState(false)
  const [savedBeautyParams, setSavedBeautyParams] = useState({
    beauty: { white: 0, smooth: 0, rosiness: 0 },
    reshape: { thin_face: 0 }
  })
  const [isBeforeAfterPressed, setIsBeforeAfterPressed] = useState(false)

  // Refs for non-reactive values
  const engineRef = useRef(null)
  const videoElementRef = useRef(null)
  const videoStreamRef = useRef(null)
  const displayCtxRef = useRef(null)
  const animationFrameIdRef = useRef(null)
  const lastProcessedFrameRef = useRef(null)
  const sliderValueTimerRef = useRef(null)
  const imageElementRef = useRef(null)
  const currentImageRef = useRef(null)

  // 初始化
  useEffect(() => {
    const init = async () => {
      try {
        // 检测是否为移动设备
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                        ('ontouchstart' in window || navigator.maxTouchPoints > 0)
        setIsMobileDevice(isMobile)
        
        // 初始化画布
        initCanvas()
        
        // 初始化引擎
        await initEngine()
        
        // 启动相机
        await startCamera()
        
        // 如果有初始标签，打开面板并切换
        if (initialTab) {
          setShowBeautyPanel(true)
          setCurrentTab(initialTab)
        }
      } catch (error) {
        console.error('初始化失败:', error)
        setStatusMessage(`错误: ${error.message}`)
      }
    }

    init()

    return () => {
      cleanup()
    }
  }, [initialTab])

  // 初始化画布
  const initCanvas = useCallback(() => {
    const canvas = displayCanvasRef.current
    if (!canvas) return
    
    const container = canvas.parentElement
    const containerWidth = container ? Math.min(container.clientWidth, 1200) : window.innerWidth
    const containerHeight = container ? container.clientHeight : window.innerHeight
    canvas.width = containerWidth
    canvas.height = containerHeight
    displayCtxRef.current = canvas.getContext('2d')
  }, [])

  // 初始化引擎
  const initEngine = useCallback(async () => {
    const config = new EngineConfig({
      appId: '',
      appKey: ''
    })

    const engine = new BeautyEffectEngine(config)
    engineRef.current = engine

    // 配置日志
    await engine.setLogConfig({
      consoleEnabled: true,
      fileEnabled: false,
      level: 0
    })

    // 初始化引擎
    await engine.init()

    // 启用美颜类型
    engine.setBeautyTypeEnabled(BeautyType.Basic, true)
    engine.setBeautyTypeEnabled(BeautyType.Reshape, true)
    engine.setBeautyTypeEnabled(BeautyType.Makeup, true)
    engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)

    setStatusMessage('引擎初始化成功')
    setTimeout(() => setStatusMessage(''), 2000)
  }, [])

  // 启动相机
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

      // 开始处理视频帧
      setIsActive(true)
      processVideoFrame()

      setStatusMessage('相机启动成功')
      setTimeout(() => setStatusMessage(''), 2000)
    } catch (error) {
      throw new Error(`相机访问失败: ${error.message}`)
    }
  }, [])

  // 处理视频帧
  const processVideoFrame = useCallback(() => {
    const engine = engineRef.current
    const videoElement = videoElementRef.current
    const displayCtx = displayCtxRef.current
    const canvas = displayCanvasRef.current

    if (!isActive || !engine || !videoElement || !videoElement.videoWidth) {
      if (isActive) {
        animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
      }
      return
    }

    // 使用 ref 来跟踪处理状态，避免闭包问题
    if (isProcessingRef.current) {
      if (isActive) {
        animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
      }
      return
    }

    isProcessingRef.current = true

    try {
      // 从 video 元素获取图像数据
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = videoElement.videoWidth
      tempCanvas.height = videoElement.videoHeight
      const ctx = tempCanvas.getContext('2d')
      ctx.drawImage(videoElement, 0, 0)
      const imageData = ctx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
      
      // 处理视频帧
      const processed = engine.processImage(imageData, tempCanvas.width, tempCanvas.height, ProcessMode.Video)

      // 存储处理后的帧
      lastProcessedFrameRef.current = processed

      // 绘制到画布
      if (displayCtx && canvas) {
        // 画布的实际尺寸应该匹配处理后的图像尺寸
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtxRef.current = canvas.getContext('2d')
        }
        
        // 使用 putImageData 绘制
        displayCtx.putImageData(processed, 0, 0)
        
        // 设置CSS样式以实现等比缩放适应容器
        const container = canvas.parentElement
        if (container) {
          const maxWidth = Math.min(container.clientWidth, 1200)
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
      console.error('帧处理错误:', error)
    }

    isProcessingRef.current = false

    if (isActive) {
      animationFrameIdRef.current = requestAnimationFrame(processVideoFrame)
    }
  }, [isActive])

  // 启动/停止视频帧处理循环
  useEffect(() => {
    if (isActive) {
      processVideoFrame()
    } else {
      if (animationFrameIdRef.current) {
        cancelAnimationFrame(animationFrameIdRef.current)
        animationFrameIdRef.current = null
      }
    }
  }, [isActive, processVideoFrame])

  // Tab切换
  const onTabChanged = useCallback((tabId) => {
    setCurrentTab(tabId)
    setCurrentFunction(null)
    hideSlider()
  }, [])

  // 美颜参数变化
  const onBeautyParamChanged = useCallback((data) => {
    applyBeautyParam(data.tab, data.function, data.value)
  }, [])

  // 显示滑块
  const onShowSlider = useCallback((data) => {
    setCurrentFunction(data.function)
    setCurrentSliderValue(data.value)
    setSliderValue(data.value)
    updateSliderValuePosition()
    setShowBeautySlider(true)
    
    // 立即应用一次参数
    applyBeautyParam(data.tab, data.function, data.value / 100.0)
  }, [])

  // 隐藏滑块
  const onHideSlider = useCallback(() => {
    setShowBeautySlider(false)
    setShowSliderValue(false)
  }, [])

  const hideSlider = useCallback(() => {
    setShowBeautySlider(false)
    setShowSliderValue(false)
  }, [])

  // 重置美颜
  const onResetBeauty = useCallback(() => {
    setCurrentSliderValue(0)
    setCurrentFunction(null)
    hideSlider()
    resetAllParams()
  }, [hideSlider])

  // 重置Tab参数
  const onResetTab = useCallback((tab) => {
    resetTabParams(tab)
  }, [])

  // 隐藏面板
  const onHidePanel = useCallback(() => {
    setShowBeautyPanel(false)
    hideSlider()
  }, [hideSlider])

  // 滑块变化
  const onSliderChange = useCallback((event) => {
    const value = parseInt(event.target.value)
    setCurrentSliderValue(value)
    setSliderValue(value)
    updateSliderValuePosition()

    // 保存进度到BeautyPanel组件
    if (currentFunction && beautyPanelRef.current) {
      beautyPanelRef.current.updateSliderValue(currentTab, currentFunction, value)
    }

    // 应用参数（0-100 转换为 0.0-1.0）
    if (currentFunction) {
      applyBeautyParam(currentTab, currentFunction, value / 100.0)
    }
  }, [currentFunction, currentTab])

  // 滑块开始
  const onSliderStart = useCallback(() => {
    setShowSliderValue(true)
  }, [])

  // 滑块结束
  const onSliderEnd = useCallback(() => {
    if (sliderValueTimerRef.current) {
      clearTimeout(sliderValueTimerRef.current)
    }
    sliderValueTimerRef.current = setTimeout(() => {
      setShowSliderValue(false)
    }, 500)
  }, [])

  // 更新滑块数值位置
  const updateSliderValuePosition = useCallback(() => {
    if (!beautySeekBarRef.current) return
    
    const slider = beautySeekBarRef.current
    const sliderRect = slider.getBoundingClientRect()
    const sliderWidth = sliderRect.width - 32
    const thumbPos = (currentSliderValue / 100) * sliderWidth
    
    setSliderValuePosition(thumbPos + 16)
  }, [currentSliderValue])

  // 应用美颜参数
  const applyBeautyParam = useCallback((tab, functionKey, value) => {
    const engine = engineRef.current
    if (!engine) return

    try {
      const paramValue = Math.max(0, Math.min(1, value))

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
        // 虚拟背景功能使用统一的 Options API（与其他平台一致）
        if (functionKey === 'blur') {
          const options = new VirtualBackgroundOptions({
            mode: value > 0 ? BackgroundMode.Blur : BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        } else if (functionKey === 'preset') {
          if (value > 0) {
            loadPresetBackground()
          } else {
            const options = new VirtualBackgroundOptions({
              mode: BackgroundMode.None
            })
            engine.setVirtualBackground(options)
          }
        } else if (functionKey === 'image') {
          if (value <= 0) {
            const options = new VirtualBackgroundOptions({
              mode: BackgroundMode.None
            })
            engine.setVirtualBackground(options)
          }
        } else if (functionKey === 'none') {
          const options = new VirtualBackgroundOptions({
            mode: BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        }
      }

      // 如果是图片模式，参数变更后重新处理图片
      if (isImageMode && imageElementRef.current) {
        processImageRef.current()
      }
    } catch (error) {
      console.error('应用美颜参数失败:', error)
    }
  }, [isImageMode])

  // 重置Tab参数
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
      } else if (tab === 'makeup') {
        engine.setMakeupParam(MakeupParam.Lipstick, 0)
        engine.setMakeupParam(MakeupParam.Blush, 0)
      } else if (tab === 'virtual_bg') {
        const options = new VirtualBackgroundOptions({
          mode: BackgroundMode.None
        })
        engine.setVirtualBackground(options)
      }

      // 如果是图片模式，重新处理图片
      if (isImageMode && imageElementRef.current) {
        processImageRef.current()
      }
    } catch (error) {
      console.error('重置Tab参数失败:', error)
    }
  }, [isImageMode])

  // 加载预置背景图片
  const loadPresetBackground = useCallback(async () => {
    const engine = engineRef.current
    if (!engine) return

    try {
      const img = new Image()
      img.crossOrigin = 'anonymous'
      
      await new Promise((resolve, reject) => {
        img.onload = resolve
        img.onerror = () => reject(new Error('预置背景图片加载失败'))
        img.src = '/background.jpg'
      })

      // 使用统一的 setVirtualBackground API（与其他平台一致）
      const options = new VirtualBackgroundOptions({
        mode: BackgroundMode.Image,
        backgroundImage: img
      })
      engine.setVirtualBackground(options)
      console.log('预置背景设置成功:', img.width, 'x', img.height)
    } catch (error) {
      console.error('加载预置背景失败:', error)
      setStatusMessage('预置背景加载失败')
      setTimeout(() => setStatusMessage(''), 2000)
    }
  }, [])

  // 重置所有参数
  const resetAllParams = useCallback(() => {
    const engine = engineRef.current
    if (!engine) return

    try {
      engine.setBasicParam(BasicParam.Whitening, 0)
      engine.setBasicParam(BasicParam.Smoothing, 0)
      engine.setBasicParam(BasicParam.Rosiness, 0)
      engine.setReshapeParam(ReshapeParam.FaceThin, 0)
      engine.setMakeupParam(MakeupParam.Lipstick, 0)
      engine.setMakeupParam(MakeupParam.Blush, 0)
      const options = new VirtualBackgroundOptions({
        mode: BackgroundMode.None
      })
      engine.setVirtualBackground(options)
    } catch (error) {
      console.error('重置所有参数失败:', error)
    }
  }, [])

  // 底部按钮点击
  const onBeautyShapeClick = useCallback(() => {
    setShowBeautyPanel(true)
    setCurrentTab('beauty')
  }, [])

  const onMakeupClick = useCallback(() => {
    setShowBeautyPanel(true)
    setCurrentTab('makeup')
  }, [])

  const onStickerClick = useCallback(() => {
    setShowBeautyPanel(true)
    setCurrentTab('sticker')
  }, [])

  const onFilterClick = useCallback(() => {
    setShowBeautyPanel(true)
    setCurrentTab('filter')
  }, [])

  // 返回主页
  const goBack = useCallback(() => {
    navigate('/')
  }, [navigate])

  // 打开图片选择器
  const openGallery = useCallback(() => {
    if (fileInputRef.current) {
      fileInputRef.current.click()
    }
  }, [])

  // 处理选中的图片
  const onImageSelected = useCallback(async (event) => {
    const file = event.target.files[0]
    if (!file) return

    if (!file.type.startsWith('image/')) {
      setStatusMessage('请选择图片文件')
      setTimeout(() => setStatusMessage(''), 2000)
      return
    }

    try {
      // 停止相机
      if (isActive) {
        stopCamera()
      }

      // 加载图片
      const reader = new FileReader()
      reader.onload = async (e) => {
        try {
          const img = new Image()
          img.onload = async () => {
            setIsImageMode(true)
            currentImageRef.current = file
            imageElementRef.current = img

            await processImageRef.current()

            setStatusMessage('图片加载成功')
            setTimeout(() => setStatusMessage(''), 2000)
          }
          img.onerror = () => {
            setStatusMessage('图片加载失败')
            setTimeout(() => setStatusMessage(''), 2000)
          }
          img.src = e.target.result
        } catch (error) {
          console.error('处理图片失败:', error)
          setStatusMessage('处理图片失败: ' + error.message)
          setTimeout(() => setStatusMessage(''), 2000)
        }
      }
      reader.onerror = () => {
        setStatusMessage('读取文件失败')
        setTimeout(() => setStatusMessage(''), 2000)
      }
      reader.readAsDataURL(file)
    } catch (error) {
      console.error('选择图片失败:', error)
      setStatusMessage('选择图片失败: ' + error.message)
      setTimeout(() => setStatusMessage(''), 2000)
    }

    // 清空input
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }, [isActive])

  // 处理图片（图片模式）
  const processImage = useCallback(async () => {
    const engine = engineRef.current
    const imageElement = imageElementRef.current
    const canvas = displayCanvasRef.current

    if (!engine || !imageElement || !canvas) {
      return
    }

    try {
      // 从图片元素获取图像数据
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = imageElement.width
      tempCanvas.height = imageElement.height
      const ctx = tempCanvas.getContext('2d')
      ctx.drawImage(imageElement, 0, 0)
      const imageData = ctx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)

      // 使用Image处理模式处理图片
      const processed = engine.processImage(imageData, tempCanvas.width, tempCanvas.height, ProcessMode.Image)

      if (processed && canvas) {
        // 画布的实际尺寸应该匹配处理后的图像尺寸
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtxRef.current = canvas.getContext('2d')
        }
        
        // 绘制到画布
        displayCtxRef.current.putImageData(processed, 0, 0)
        lastProcessedFrameRef.current = processed
        
        // 设置CSS样式以实现等比缩放适应容器
        const container = canvas.parentElement
        if (container) {
          const maxWidth = Math.min(container.clientWidth, 1200)
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
      console.error('图片处理失败:', error)
    }
  }, [])

  // 使用 ref 存储 processImage 函数
  const processImageRef = useRef(processImage)
  useEffect(() => {
    processImageRef.current = processImage
  }, [processImage])

  // 停止相机
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

  // 切换摄像头
  const flipCamera = useCallback(async () => {
    if (!isMobileDevice) {
      return
    }

    try {
      // 停止当前流
      if (videoStreamRef.current) {
        videoStreamRef.current.getTracks().forEach(track => track.stop())
      }

      // 切换摄像头
      const constraints = {
        video: {
          facingMode: videoElementRef.current?.srcObject?.getVideoTracks()[0]?.getSettings().facingMode === 'user' 
            ? 'environment' 
            : 'user'
        }
      }

      const videoStream = await navigator.mediaDevices.getUserMedia(constraints)
      videoElementRef.current.srcObject = videoStream
      await videoElementRef.current.play()
      videoStreamRef.current = videoStream
    } catch (error) {
      console.error('切换摄像头失败:', error)
      alert('切换摄像头失败')
    }
  }, [isMobileDevice])

  // 更多选项
  const toggleMore = useCallback(() => {
    alert('更多选项功能开发中')
  }, [])

  // 保存当前所有美颜参数
  const saveCurrentBeautyParams = useCallback(() => {
    if (!beautyPanelRef.current) return
    
    const beautyParams = {
      beauty: {},
      reshape: {}
    }
    
    const whiteValue = beautyPanelRef.current.getSliderValue('beauty', 'white') || 0
    const smoothValue = beautyPanelRef.current.getSliderValue('beauty', 'smooth') || 0
    const rosinessValue = beautyPanelRef.current.getSliderValue('beauty', 'rosiness') || 0
    
    beautyParams.beauty.white = whiteValue / 100.0
    beautyParams.beauty.smooth = smoothValue / 100.0
    beautyParams.beauty.rosiness = rosinessValue / 100.0
    
    const thinFaceValue = beautyPanelRef.current.getSliderValue('reshape', 'thin_face') || 0
    beautyParams.reshape.thin_face = thinFaceValue / 100.0
    
    setSavedBeautyParams(beautyParams)
  }, [])

  // 恢复保存的美颜参数
  const restoreBeautyParams = useCallback(() => {
    const params = savedBeautyParams
    
    if (params.beauty) {
      if (params.beauty.white !== undefined) {
        const value = params.beauty.white
        applyBeautyParam('beauty', 'white', value)
        if (beautyPanelRef.current) {
          beautyPanelRef.current.updateSliderValue('beauty', 'white', Math.round(value * 100))
        }
      }
      if (params.beauty.smooth !== undefined) {
        const value = params.beauty.smooth
        applyBeautyParam('beauty', 'smooth', value)
        if (beautyPanelRef.current) {
          beautyPanelRef.current.updateSliderValue('beauty', 'smooth', Math.round(value * 100))
        }
      }
      if (params.beauty.rosiness !== undefined) {
        const value = params.beauty.rosiness
        applyBeautyParam('beauty', 'rosiness', value)
        if (beautyPanelRef.current) {
          beautyPanelRef.current.updateSliderValue('beauty', 'rosiness', Math.round(value * 100))
        }
      }
    }
    
    if (params.reshape) {
      if (params.reshape.thin_face !== undefined) {
        const value = params.reshape.thin_face
        applyBeautyParam('reshape', 'thin_face', value)
        if (beautyPanelRef.current) {
          beautyPanelRef.current.updateSliderValue('reshape', 'thin_face', Math.round(value * 100))
        }
      }
    }
  }, [savedBeautyParams, applyBeautyParam])

  // 对比按钮按下
  const onBeforeAfterPress = useCallback(() => {
    if (isBeforeAfterPressed) return
    
    setIsBeforeAfterPressed(true)
    saveCurrentBeautyParams()
    resetAllParams()
  }, [isBeforeAfterPressed, saveCurrentBeautyParams, resetAllParams])

  // 对比按钮松开
  const onBeforeAfterRelease = useCallback(() => {
    if (!isBeforeAfterPressed) return
    
    setIsBeforeAfterPressed(false)
    restoreBeautyParams()
  }, [isBeforeAfterPressed, restoreBeautyParams])

  // 拍照
  const capturePhoto = useCallback(async () => {
    const canvas = displayCanvasRef.current
    const displayCtx = displayCtxRef.current

    if (!canvas || !displayCtx) {
      setStatusMessage('画布未初始化')
      setTimeout(() => setStatusMessage(''), 2000)
      return
    }

    try {
      const width = canvas.width
      const height = canvas.height

      if (width === 0 || height === 0) {
        setStatusMessage('画布尺寸无效')
        setTimeout(() => setStatusMessage(''), 2000)
        return
      }

      // 创建临时canvas用于导出
      const exportCanvas = document.createElement('canvas')
      exportCanvas.width = width
      exportCanvas.height = height
      const exportCtx = exportCanvas.getContext('2d')
      
      // 将显示画布的内容绘制到导出画布
      exportCtx.drawImage(canvas, 0, 0)

      // 转换为blob并下载
      exportCanvas.toBlob((blob) => {
        if (!blob) {
          setStatusMessage('保存失败')
          setTimeout(() => setStatusMessage(''), 2000)
          return
        }

        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `facebetter_${Date.now()}.png`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)

        setStatusMessage('照片已保存')
        setTimeout(() => setStatusMessage(''), 2000)
      }, 'image/png', 1.0)
    } catch (error) {
      console.error('拍照失败:', error)
      setStatusMessage('拍照失败: ' + error.message)
      setTimeout(() => setStatusMessage(''), 2000)
    }
  }, [])

  // 清理资源
  const cleanup = useCallback(() => {
    setIsActive(false)

    if (sliderValueTimerRef.current) {
      clearTimeout(sliderValueTimerRef.current)
      sliderValueTimerRef.current = null
    }

    if (animationFrameIdRef.current) {
      cancelAnimationFrame(animationFrameIdRef.current)
      animationFrameIdRef.current = null
    }

    if (videoStreamRef.current) {
      videoStreamRef.current.getTracks().forEach(track => track.stop())
      videoStreamRef.current = null
    }

    if (engineRef.current) {
      engineRef.current.destroy()
      engineRef.current = null
    }

    videoElementRef.current = null
    lastProcessedFrameRef.current = null
  }, [])

  return (
    <div className="camera-preview-container">
      {/* 相机预览画布 */}
      <canvas ref={displayCanvasRef} className="camera-canvas"></canvas>

      {/* 隐藏的文件选择器 */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        style={{ display: 'none' }}
        onChange={onImageSelected}
      />

      {/* 顶部控制栏 */}
      <div className="top-bar">
        <button className="control-btn" onClick={goBack}>
          <img src="/icons/close.png" alt="返回" className="control-icon" />
        </button>
        <button className="control-btn" onClick={openGallery}>
          <img src="/icons/gallery.png" alt="相册" className="control-icon" />
        </button>
        <button 
          className={`control-btn ${!isMobileDevice ? 'disabled' : ''}`}
          onClick={flipCamera}
          disabled={!isMobileDevice}
        >
          <img src="/icons/switchcamera.png" alt="切换摄像头" className="control-icon" />
        </button>
        <button className="control-btn" onClick={toggleMore}>
          <img src="/icons/more.png" alt="更多" className="control-icon" />
        </button>
      </div>

      {/* 美颜面板 */}
      {showBeautyPanel && (
        <BeautyPanel
          currentTab={currentTab}
          onTabChanged={onTabChanged}
          onBeautyParamChanged={onBeautyParamChanged}
          onResetBeauty={onResetBeauty}
          onResetTab={onResetTab}
          onShowSlider={onShowSlider}
          onHideSlider={onHideSlider}
          onHidePanel={onHidePanel}
          onCapture={capturePhoto}
          ref={beautyPanelRef}
        />
      )}

      {/* 美颜滑块 */}
      {showBeautySlider && showBeautyPanel && (
        <div className="beauty-slider-container">
          {showSliderValue && (
            <div 
              className="beauty-value-text"
              style={{ left: sliderValuePosition + 'px' }}
            >
              {sliderValue}
            </div>
          )}
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

      {/* 前后对比按钮 */}
      {showBeautyPanel && (
        <button 
          className="before-after-btn"
          onMouseDown={onBeforeAfterPress}
          onMouseUp={onBeforeAfterRelease}
          onMouseLeave={onBeforeAfterRelease}
          onTouchStart={onBeforeAfterPress}
          onTouchEnd={onBeforeAfterRelease}
          onTouchCancel={onBeforeAfterRelease}
        >
          <img src="/icons/before_after.png" alt="前后对比" className="control-icon" />
        </button>
      )}

      {/* 底部控制栏 */}
      {!showBeautyPanel && (
        <div className="bottom-bar">
          <div className="bottom-action" onClick={onBeautyShapeClick}>
            <img src="/icons/meiyan.png" alt="美颜美型" className="bottom-action-icon" />
            <span className="bottom-action-text">美颜美型</span>
          </div>
          <div className="bottom-action" onClick={onMakeupClick}>
            <img src="/icons/meizhuang.png" alt="美妆" className="bottom-action-icon" />
            <span className="bottom-action-text">美妆</span>
          </div>
          <div className="bottom-action-center">
            <button className="capture-btn" onClick={capturePhoto}>
              <div className="capture-inner"></div>
            </button>
          </div>
          <div className="bottom-action" onClick={onStickerClick}>
            <img src="/icons/tiezhi2.png" alt="贴纸特效" className="bottom-action-icon" />
            <span className="bottom-action-text">贴纸特效</span>
          </div>
          <div className="bottom-action" onClick={onFilterClick}>
            <img src="/icons/lvjing.png" alt="滤镜调色" className="bottom-action-icon" />
            <span className="bottom-action-text">滤镜调色</span>
          </div>
        </div>
      )}

      {/* 状态提示 */}
      {statusMessage && (
        <div className="status-message">{statusMessage}</div>
      )}
    </div>
  )
}

export default CameraPreview

