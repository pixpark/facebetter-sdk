<template>
  <div class="camera-preview-container">
    <!-- 相机预览画布 -->
    <canvas ref="displayCanvas" class="camera-canvas"></canvas>

    <!-- 隐藏的文件选择器 -->
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      style="display: none"
      @change="onImageSelected"
    />

    <!-- 顶部控制栏 -->
    <div class="top-bar">
      <button class="control-btn" @click="goBack">
        <img src="/icons/close.png" alt="返回" class="control-icon" />
      </button>
      <button class="control-btn" @click="openGallery">
        <img src="/icons/gallery.png" alt="相册" class="control-icon" />
      </button>
      <button 
        class="control-btn" 
        :class="{ disabled: !isMobileDevice }"
        @click="flipCamera"
        :disabled="!isMobileDevice"
      >
        <img src="/icons/switchcamera.png" alt="切换摄像头" class="control-icon" />
      </button>
      <button class="control-btn" @click="toggleMore">
        <img src="/icons/more.png" alt="更多" class="control-icon" />
      </button>
    </div>

    <!-- 美颜面板 -->
    <BeautyPanel
      v-if="showBeautyPanel"
      :current-tab="currentTab"
      @tab-changed="onTabChanged"
      @beauty-param-changed="onBeautyParamChanged"
      @reset-beauty="onResetBeauty"
      @reset-tab="onResetTab"
      @show-slider="onShowSlider"
      @hide-slider="onHideSlider"
      @hide-panel="onHidePanel"
      @capture="capturePhoto"
      ref="beautyPanelRef"
    />

    <!-- 美颜滑块（单个滑块，当选中功能时显示，在美颜面板上方） -->
    <div v-if="showBeautySlider && showBeautyPanel" class="beauty-slider-container">
      <div 
        v-if="showSliderValue" 
        class="beauty-value-text"
        :style="{ left: sliderValuePosition + 'px' }"
      >
        {{ sliderValue }}
      </div>
      <input 
        ref="beautySeekBar"
        type="range" 
        class="beauty-seekbar"
        min="0" 
        max="100" 
        step="1"
        :value="currentSliderValue"
        @input="onSliderChange"
        @touchstart="onSliderStart"
        @touchend="onSliderEnd"
        @mousedown="onSliderStart"
        @mouseup="onSliderEnd"
      />
    </div>

    <!-- 前后对比按钮（在美颜面板上方） -->
    <button 
      v-if="showBeautyPanel" 
      class="before-after-btn"
      @mousedown="onBeforeAfterPress"
      @mouseup="onBeforeAfterRelease"
      @mouseleave="onBeforeAfterRelease"
      @touchstart="onBeforeAfterPress"
      @touchend="onBeforeAfterRelease"
      @touchcancel="onBeforeAfterRelease"
    >
      <img src="/icons/before_after.png" alt="前后对比" class="control-icon" />
    </button>

    <!-- 底部控制栏（当美颜面板隐藏时显示） -->
    <div v-if="!showBeautyPanel" class="bottom-bar">
      <div class="bottom-action" @click="onBeautyShapeClick">
        <img src="/icons/meiyan.png" alt="美颜美型" class="bottom-action-icon" />
        <span class="bottom-action-text">美颜美型</span>
      </div>
      <div class="bottom-action" @click="onMakeupClick">
        <img src="/icons/meizhuang.png" alt="美妆" class="bottom-action-icon" />
        <span class="bottom-action-text">美妆</span>
      </div>
      <div class="bottom-action-center">
        <button class="capture-btn" @click="capturePhoto">
          <div class="capture-inner"></div>
        </button>
      </div>
      <div class="bottom-action" @click="onStickerClick">
        <img src="/icons/tiezhi2.png" alt="贴纸特效" class="bottom-action-icon" />
        <span class="bottom-action-text">贴纸特效</span>
      </div>
      <div class="bottom-action" @click="onFilterClick">
        <img src="/icons/lvjing.png" alt="滤镜调色" class="bottom-action-icon" />
        <span class="bottom-action-text">滤镜调色</span>
      </div>
    </div>

    <!-- 状态提示 -->
    <div v-if="statusMessage" class="status-message">{{ statusMessage }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import BeautyPanel from '@/components/BeautyPanel.vue'
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

const props = defineProps({
  initialTab: {
    type: String,
    default: null
  }
})

const router = useRouter()
const displayCanvas = ref(null)
const beautySeekBar = ref(null)
const beautyPanelRef = ref(null)
const fileInput = ref(null)

// 状态管理
const statusMessage = ref('')
const showBeautyPanel = ref(false)
const showBeautySlider = ref(false)
const showSliderValue = ref(false)
const currentTab = ref('beauty')
const currentFunction = ref(null)
const isProcessing = ref(false)
const isActive = ref(false)

// 检测是否为移动设备
const isMobileDevice = ref(false)

// 滑块相关
const currentSliderValue = ref(0)
const sliderValue = ref(0)
const sliderValuePosition = ref(0)

// 对比按钮相关：保存当前美颜参数状态
const savedBeautyParams = ref({
  beauty: {
    white: 0,
    smooth: 0,
    rosiness: 0
  },
  reshape: {
    thin_face: 0
  }
})
const isBeforeAfterPressed = ref(false)

// 引擎和视频相关
let engine = null
let videoElement = null
let videoStream = null
let displayCtx = null
let animationFrameId = null
let lastProcessedFrame = null
let sliderValueTimer = null

// 图片处理模式相关
const isImageMode = ref(false)
let currentImage = null
let imageElement = null

onMounted(async () => {
  try {
    // 检测是否为移动设备
    isMobileDevice.value = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                          ('ontouchstart' in window || navigator.maxTouchPoints > 0)
    
    // 等待DOM渲染完成后再初始化画布
    await nextTick()
    
    // 初始化画布
    initCanvas()
    
    // 初始化引擎
    await initEngine()
    
    // 启动相机
    await startCamera()
    
    // 如果有初始标签，打开面板并切换
    if (props.initialTab) {
      showBeautyPanel.value = true
      currentTab.value = props.initialTab
    }
  } catch (error) {
    console.error('初始化失败:', error)
    statusMessage.value = `错误: ${error.message}`
  }
})

onBeforeUnmount(() => {
  cleanup()
})

// 初始化画布
const initCanvas = () => {
  const canvas = displayCanvas.value
  const container = canvas.parentElement
  // 使用容器的实际宽度（最大1200px），而不是窗口宽度
  const containerWidth = container ? Math.min(container.clientWidth, 1200) : window.innerWidth
  const containerHeight = container ? container.clientHeight : window.innerHeight
  canvas.width = containerWidth
  canvas.height = containerHeight
  displayCtx = canvas.getContext('2d')
}

// 初始化引擎
const initEngine = async () => {
  const config = new EngineConfig({
    appId: '',
    appKey: ''
  })

  engine = new BeautyEffectEngine(config)

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

  statusMessage.value = '引擎初始化成功'
  setTimeout(() => { statusMessage.value = '' }, 2000)
}

// 启动相机
const startCamera = async () => {
  try {
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 1280 },
        height: { ideal: 720 },
        frameRate: { ideal: 30 }
      },
      audio: false
    })

    videoElement = document.createElement('video')
    videoElement.srcObject = videoStream
    videoElement.autoplay = true
    videoElement.playsInline = true
    await videoElement.play()

    // 开始处理视频帧
    isActive.value = true
    processVideoFrame()

    statusMessage.value = '相机启动成功'
    setTimeout(() => { statusMessage.value = '' }, 2000)
  } catch (error) {
    throw new Error(`相机访问失败: ${error.message}`)
  }
}

// 处理视频帧
const processVideoFrame = async () => {
  if (!isActive.value || !engine || !videoElement || !videoElement.videoWidth) {
    if (isActive.value) {
      animationFrameId = requestAnimationFrame(processVideoFrame)
    }
    return
  }

  if (!isProcessing.value) {
    isProcessing.value = true

    try {
      // 从 video 元素获取图像数据
      const canvas = document.createElement('canvas')
      canvas.width = videoElement.videoWidth
      canvas.height = videoElement.videoHeight
      const ctx = canvas.getContext('2d')
      ctx.drawImage(videoElement, 0, 0)
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      
      // 处理视频帧
      const processed = engine.processImage(imageData, canvas.width, canvas.height, ProcessMode.Video)

      // 存储处理后的帧
      lastProcessedFrame = processed

      // 绘制到画布
      if (displayCtx && displayCanvas.value) {
        const canvas = displayCanvas.value
        
        // 画布的实际尺寸应该匹配处理后的图像尺寸（确保完整显示）
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtx = canvas.getContext('2d')
        }
        
        // 使用 putImageData 绘制（尺寸已匹配）
        displayCtx.putImageData(processed, 0, 0)
        
        // 设置CSS样式以实现等比缩放适应容器（保持宽高比，完整显示）
        const container = canvas.parentElement
        if (container) {
          const maxWidth = Math.min(container.clientWidth, 1200)
          const maxHeight = container.clientHeight
          
          const imageAspect = processed.width / processed.height
          const containerAspect = maxWidth / maxHeight
          
          let cssWidth, cssHeight
          if (imageAspect > containerAspect) {
            // 图像更宽，以宽度为准
            cssWidth = maxWidth + 'px'
            cssHeight = (maxWidth / imageAspect) + 'px'
          } else {
            // 图像更高，以高度为准
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

    isProcessing.value = false
  }

  if (isActive.value) {
    animationFrameId = requestAnimationFrame(processVideoFrame)
  }
}

// Tab切换
const onTabChanged = (tabId) => {
  currentTab.value = tabId
  currentFunction.value = null
  hideSlider()
}

// 美颜参数变化
const onBeautyParamChanged = (data) => {
  applyBeautyParam(data.tab, data.function, data.value)
}

// 显示滑块
const onShowSlider = (data) => {
  currentFunction.value = data.function
  currentSliderValue.value = data.value
  sliderValue.value = data.value
  updateSliderValuePosition()
  showBeautySlider.value = true
  
  // 立即应用一次参数
  applyBeautyParam(data.tab, data.function, data.value / 100.0)
}

// 隐藏滑块
const onHideSlider = () => {
  showBeautySlider.value = false
  showSliderValue.value = false
}

// 重置美颜
const onResetBeauty = () => {
  currentSliderValue.value = 0
  currentFunction.value = null
  hideSlider()
  resetAllParams()
}

// 重置Tab参数
const onResetTab = (tab) => {
  resetTabParams(tab)
}

// 隐藏面板
const onHidePanel = () => {
  showBeautyPanel.value = false
  hideSlider()
}

// 隐藏滑动条
const hideSlider = () => {
  showBeautySlider.value = false
  showSliderValue.value = false
}

// 滑块变化
const onSliderChange = (event) => {
  const value = parseInt(event.target.value)
  currentSliderValue.value = value
  sliderValue.value = value
  updateSliderValuePosition()

  // 保存进度到BeautyPanel组件
  if (currentFunction.value && beautyPanelRef.value) {
    beautyPanelRef.value.updateSliderValue(currentTab.value, currentFunction.value, value)
  }

  // 应用参数（0-100 转换为 0.0-1.0）
  if (currentFunction.value) {
    applyBeautyParam(currentTab.value, currentFunction.value, value / 100.0)
  }
}

// 滑块开始
const onSliderStart = () => {
  showSliderValue.value = true
}

// 滑块结束
const onSliderEnd = () => {
  if (sliderValueTimer) {
    clearTimeout(sliderValueTimer)
  }
  sliderValueTimer = setTimeout(() => {
    showSliderValue.value = false
  }, 500)
}

// 更新滑块数值位置
const updateSliderValuePosition = () => {
  nextTick(() => {
    if (!beautySeekBar.value) return
    
    const slider = beautySeekBar.value
    const sliderRect = slider.getBoundingClientRect()
    const sliderWidth = sliderRect.width - 32 // 减去左右padding
    const thumbPos = (currentSliderValue.value / 100) * sliderWidth
    
    // 计算数值文本位置（居中在thumb上方）
    sliderValuePosition.value = thumbPos + 16 // 加上左边距
  })
}

// 应用美颜参数
const applyBeautyParam = (tab, functionKey, value) => {
  if (!engine) return

  try {
    // API 期望 0.0-1.0 的浮点数，value 已经是 0.0-1.0 格式
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
        // TODO: 添加其他美型参数
      }
    } else if (tab === 'makeup') {
      switch (functionKey) {
        case 'lipstick':
          engine.setMakeupParam(MakeupParam.Lipstick, paramValue)
          break
        case 'blush':
          engine.setMakeupParam(MakeupParam.Blush, paramValue)
          break
        case 'eyebrow':
          // TODO: 眉毛参数（如果引擎支持）
          break
        case 'eyeshadow':
          // TODO: 眼影参数（如果引擎支持）
          break
      }
    } else if (tab === 'virtual_bg') {
      // 虚拟背景功能使用统一的 Options API（与其他平台一致）
      if (functionKey === 'blur') {
        // 模糊背景
        const options = new VirtualBackgroundOptions({
          mode: value > 0 ? BackgroundMode.Blur : BackgroundMode.None
        })
        engine.setVirtualBackground(options)
      } else if (functionKey === 'preset') {
        // 预置背景：加载预置图片并设置为Image模式
        if (value > 0) {
          loadPresetBackground()
        } else {
          const options = new VirtualBackgroundOptions({
            mode: BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        }
      } else if (functionKey === 'image') {
        // 图像背景：需要用户选择图片
        // 如果value > 0，说明用户想开启图像背景，但需要先选择图片
        // 这里先设置为None，实际图片选择功能在BeautyPanel中处理
        if (value <= 0) {
          const options = new VirtualBackgroundOptions({
            mode: BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        }
      } else if (functionKey === 'none') {
        // 关闭虚拟背景
        const options = new VirtualBackgroundOptions({
          mode: BackgroundMode.None
        })
        engine.setVirtualBackground(options)
      }
    }

    // 如果是图片模式，参数变更后重新处理图片
    if (isImageMode.value && imageElement) {
      processImage()
    }
  } catch (error) {
    console.error('应用美颜参数失败:', error)
  }
}

// 重置Tab参数
const resetTabParams = (tab) => {
  if (!engine) return

  try {
    if (tab === 'beauty') {
      engine.setBasicParam(BasicParam.Whitening, 0)
      engine.setBasicParam(BasicParam.Smoothing, 0)
      engine.setBasicParam(BasicParam.Rosiness, 0)
    } else if (tab === 'reshape') {
      engine.setReshapeParam(ReshapeParam.FaceThin, 0)
      // TODO: 重置其他美型参数
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
    if (isImageMode.value && imageElement) {
      processImage()
    }
  } catch (error) {
    console.error('重置Tab参数失败:', error)
  }
}

// 加载预置背景图片
const loadPresetBackground = async () => {
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
    statusMessage.value = '预置背景加载失败'
    setTimeout(() => { statusMessage.value = '' }, 2000)
  }
}

// 重置所有参数
const resetAllParams = () => {
  if (!engine) return

  try {
    // 重置基础美颜
    engine.setBasicParam(BasicParam.Whitening, 0)
    engine.setBasicParam(BasicParam.Smoothing, 0)
    engine.setBasicParam(BasicParam.Rosiness, 0)

    // 重置美型
    engine.setReshapeParam(ReshapeParam.FaceThin, 0)
    // TODO: 重置其他美型参数

    // 重置美妆
    engine.setMakeupParam(MakeupParam.Lipstick, 0)
    engine.setMakeupParam(MakeupParam.Blush, 0)

    // 重置虚拟背景
      const options = new VirtualBackgroundOptions({
        mode: BackgroundMode.None
      })
      engine.setVirtualBackground(options)
  } catch (error) {
    console.error('重置所有参数失败:', error)
  }
}


// 底部按钮点击
const onBeautyShapeClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'beauty'
}

const onMakeupClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'makeup'
}

const onStickerClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'sticker'
}

const onFilterClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'filter'
}

// 返回主页
const goBack = () => {
  router.push('/')
}

// 打开相册
// 打开图片选择器
const openGallery = () => {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

// 处理选中的图片
const onImageSelected = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  // 检查文件类型
  if (!file.type.startsWith('image/')) {
    statusMessage.value = '请选择图片文件'
    setTimeout(() => { statusMessage.value = '' }, 2000)
    return
  }

  try {
    // 停止相机
    if (isActive.value) {
      stopCamera()
    }

    // 加载图片
    const reader = new FileReader()
    reader.onload = async (e) => {
      try {
        const img = new Image()
        img.onload = async () => {
          // 切换到图片模式
          isImageMode.value = true
          currentImage = file
          imageElement = img

          // 注意：画布尺寸会在processImage中根据处理后的图像尺寸自动调整
          // 这里不需要预先设置画布尺寸

          // 处理图片（processImage会自动调整画布尺寸以匹配处理后的图像）
          await processImage()

          statusMessage.value = '图片加载成功'
          setTimeout(() => { statusMessage.value = '' }, 2000)
        }
        img.onerror = () => {
          statusMessage.value = '图片加载失败'
          setTimeout(() => { statusMessage.value = '' }, 2000)
        }
        img.src = e.target.result
      } catch (error) {
        console.error('处理图片失败:', error)
        statusMessage.value = '处理图片失败: ' + error.message
        setTimeout(() => { statusMessage.value = '' }, 2000)
      }
    }
    reader.onerror = () => {
      statusMessage.value = '读取文件失败'
      setTimeout(() => { statusMessage.value = '' }, 2000)
    }
    reader.readAsDataURL(file)
  } catch (error) {
    console.error('选择图片失败:', error)
    statusMessage.value = '选择图片失败: ' + error.message
    setTimeout(() => { statusMessage.value = '' }, 2000)
  }

  // 清空input，允许重复选择同一文件
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

// 处理图片（图片模式）
const processImage = async () => {
  if (!engine || !imageElement || !displayCanvas.value) {
    return
  }

  try {
    // 从图片元素获取图像数据
    const canvas = document.createElement('canvas')
    canvas.width = imageElement.width
    canvas.height = imageElement.height
    const ctx = canvas.getContext('2d')
    ctx.drawImage(imageElement, 0, 0)
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)

    // 使用Image处理模式处理图片
    const processed = engine.processImage(imageData, canvas.width, canvas.height, ProcessMode.Image)

    if (processed && displayCanvas.value) {
      const canvas = displayCanvas.value
      
      // 画布的实际尺寸应该匹配处理后的图像尺寸（确保完整显示）
      if (canvas.width !== processed.width || canvas.height !== processed.height) {
        canvas.width = processed.width
        canvas.height = processed.height
        displayCtx = canvas.getContext('2d')
      }
      
      // 绘制到画布
      displayCtx.putImageData(processed, 0, 0)
      lastProcessedFrame = processed
      
      // 设置CSS样式以实现等比缩放适应容器（保持宽高比，完整显示）
      const container = canvas.parentElement
      if (container) {
        const maxWidth = Math.min(container.clientWidth, 1200)
        const maxHeight = container.clientHeight
        
        const imageAspect = processed.width / processed.height
        const containerAspect = maxWidth / maxHeight
        
        let cssWidth, cssHeight
        if (imageAspect > containerAspect) {
          // 图像更宽，以宽度为准
          cssWidth = maxWidth + 'px'
          cssHeight = (maxWidth / imageAspect) + 'px'
        } else {
          // 图像更高，以高度为准
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
}

// 停止相机
const stopCamera = () => {
  isActive.value = false

  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId)
    animationFrameId = null
  }

  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop())
    videoStream = null
  }

  if (videoElement) {
    videoElement.srcObject = null
    videoElement = null
  }
}

// 切换摄像头
const flipCamera = async () => {
  // 桌面端不支持切换摄像头
  if (!isMobileDevice.value) {
    return
  }

  try {
    // 停止当前流
    if (videoStream) {
      videoStream.getTracks().forEach(track => track.stop())
    }

    // 切换摄像头
    const constraints = {
      video: {
        facingMode: videoElement?.srcObject?.getVideoTracks()[0]?.getSettings().facingMode === 'user' 
          ? 'environment' 
          : 'user'
      }
    }

    videoStream = await navigator.mediaDevices.getUserMedia(constraints)
    videoElement.srcObject = videoStream
    await videoElement.play()
  } catch (error) {
    console.error('切换摄像头失败:', error)
    alert('切换摄像头失败')
  }
}

// 更多选项
const toggleMore = () => {
  alert('更多选项功能开发中')
}

// 保存当前所有美颜参数
const saveCurrentBeautyParams = () => {
  if (!beautyPanelRef.value) return
  
  // 从BeautyPanel组件获取所有功能的进度值
  const beautyParams = {
    beauty: {},
    reshape: {}
  }
  
  // 获取美颜参数（0-100的值，需要转换为0.0-1.0）
  const whiteValue = beautyPanelRef.value.getSliderValue('beauty', 'white') || 0
  const smoothValue = beautyPanelRef.value.getSliderValue('beauty', 'smooth') || 0
  const rosinessValue = beautyPanelRef.value.getSliderValue('beauty', 'rosiness') || 0
  
  beautyParams.beauty.white = whiteValue / 100.0
  beautyParams.beauty.smooth = smoothValue / 100.0
  beautyParams.beauty.rosiness = rosinessValue / 100.0
  
  // 获取美型参数
  const thinFaceValue = beautyPanelRef.value.getSliderValue('reshape', 'thin_face') || 0
  beautyParams.reshape.thin_face = thinFaceValue / 100.0
  
  savedBeautyParams.value = beautyParams
}

// 恢复保存的美颜参数
const restoreBeautyParams = () => {
  const params = savedBeautyParams.value
  
  // 恢复美颜参数
  if (params.beauty) {
    if (params.beauty.white !== undefined) {
      const value = params.beauty.white
      applyBeautyParam('beauty', 'white', value)
      // 更新BeautyPanel的进度值（0.0-1.0转换为0-100）
      if (beautyPanelRef.value) {
        beautyPanelRef.value.updateSliderValue('beauty', 'white', Math.round(value * 100))
      }
    }
    if (params.beauty.smooth !== undefined) {
      const value = params.beauty.smooth
      applyBeautyParam('beauty', 'smooth', value)
      if (beautyPanelRef.value) {
        beautyPanelRef.value.updateSliderValue('beauty', 'smooth', Math.round(value * 100))
      }
    }
    if (params.beauty.rosiness !== undefined) {
      const value = params.beauty.rosiness
      applyBeautyParam('beauty', 'rosiness', value)
      if (beautyPanelRef.value) {
        beautyPanelRef.value.updateSliderValue('beauty', 'rosiness', Math.round(value * 100))
      }
    }
  }
  
  // 恢复美型参数
  if (params.reshape) {
    if (params.reshape.thin_face !== undefined) {
      const value = params.reshape.thin_face
      applyBeautyParam('reshape', 'thin_face', value)
      if (beautyPanelRef.value) {
        beautyPanelRef.value.updateSliderValue('reshape', 'thin_face', Math.round(value * 100))
      }
    }
  }
}

// 对比按钮按下
const onBeforeAfterPress = () => {
  if (isBeforeAfterPressed.value) return
  
  isBeforeAfterPressed.value = true
  
  // 保存当前美颜参数
  saveCurrentBeautyParams()
  
  // 关闭所有美颜效果
  resetAllParams()
}

// 对比按钮松开
const onBeforeAfterRelease = () => {
  if (!isBeforeAfterPressed.value) return
  
  isBeforeAfterPressed.value = false
  
  // 恢复美颜效果
  restoreBeautyParams()
}

// 拍照
const capturePhoto = async () => {
  if (!displayCanvas.value || !displayCtx) {
    statusMessage.value = '画布未初始化'
    setTimeout(() => { statusMessage.value = '' }, 2000)
    return
  }

  try {
    // 直接从显示画布获取当前美颜处理后的图像
    const canvas = displayCanvas.value
    const width = canvas.width
    const height = canvas.height

    if (width === 0 || height === 0) {
      statusMessage.value = '画布尺寸无效'
      setTimeout(() => { statusMessage.value = '' }, 2000)
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
        statusMessage.value = '保存失败'
        setTimeout(() => { statusMessage.value = '' }, 2000)
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

      statusMessage.value = '照片已保存'
      setTimeout(() => { statusMessage.value = '' }, 2000)
    }, 'image/png', 1.0)
  } catch (error) {
    console.error('拍照失败:', error)
    statusMessage.value = '拍照失败: ' + error.message
    setTimeout(() => { statusMessage.value = '' }, 2000)
  }
}

// 清理资源
const cleanup = () => {
  isActive.value = false

  if (sliderValueTimer) {
    clearTimeout(sliderValueTimer)
    sliderValueTimer = null
  }

  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId)
    animationFrameId = null
  }

  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop())
    videoStream = null
  }

  if (engine) {
    engine.destroy()
    engine = null
  }

  videoElement = null
  lastProcessedFrame = null
}
</script>

<style scoped>
.camera-preview-container {
  width: 100%;
  max-width: 1200px;
  height: 100vh;
  background: black;
  position: relative;
  overflow: hidden;
  margin: 0 auto;
}

.camera-canvas {
  display: block;
  margin: 0 auto;
  /* width 和 height 通过 JavaScript 动态设置以实现等比缩放 */
}

/* 顶部控制栏 */
.top-bar {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: linear-gradient(to bottom, rgba(0,0,0,0.5), transparent);
  z-index: 10;
}

.control-btn {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
}

.control-btn:active:not(.disabled) {
  background: rgba(255, 255, 255, 0.2);
}

.control-btn.disabled {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}

.control-icon {
  width: 20px;
  height: 20px;
  object-fit: contain;
  filter: brightness(0) invert(1);
}

/* 美颜滑块 */
.beauty-slider-container {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 0 16px 10px;
  padding-right: 80px;
  z-index: 11;
  pointer-events: none;
  /* 美颜面板高度约为 300px，滑动条应该在面板上方，紧挨着面板 */
  transform: translateY(calc(-280px));
  /* 设置最大宽度为 500px */
  max-width: 500px;
  margin: 0 auto;
}

.beauty-value-text {
  position: absolute;
  top: -5px;
  padding: 2px 12px;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  font-size: 13px;
  border-radius: 4px;
  transform: translateX(-50%);
  pointer-events: none;
  z-index: 16;
}

.beauty-seekbar {
  width: 100%;
  height: 4px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
  outline: none;
  -webkit-appearance: none;
  appearance: none;
  pointer-events: auto;
}

.beauty-seekbar::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
}

.beauty-seekbar::-moz-range-thumb {
  width: 16px;
  height: 16px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
  border: none;
}

/* 前后对比按钮 */
.before-after-btn {
  position: absolute;
  bottom: 0;
  /* 滑动条最大宽度500px，居中显示，所以滑动条右边缘在 50% + 250px 位置
     对比按钮在滑动条右侧30px，所以位置是 50% + 250px + 30px */
  left: calc(50% + 200px);
  width: 50px;
  height: 50px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 11;
  /* 与滑动条位置保持一致 */
  transform: translateY(calc(-270px));
}


/* 底部控制栏 */
.bottom-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-around;
  padding: 16px;
  background: rgba(0, 0, 0, 0.8);
  z-index: 10;
}

.bottom-action {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 8px;
  cursor: pointer;
}

.bottom-action-icon {
  width: 32px;
  height: 32px;
  object-fit: contain;
  filter: brightness(0) invert(1);
}

.bottom-action-text {
  margin-top: 4px;
  color: white;
  font-size: 12px;
}

.bottom-action-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.capture-btn {
  width: 60px;
  height: 60px;
  background: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  position: relative;
  padding: 5px;
  box-sizing: border-box;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}

.capture-btn:active {
  transform: scale(0.85);
  opacity: 0.8;
}

.capture-btn:hover {
  transform: scale(1.05);
}

.capture-inner {
  width: 50px;
  height: 50px;
  background: #00FF00;
  border-radius: 50%;
  flex-shrink: 0;
}

/* 状态提示 */
.status-message {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  z-index: 100;
}

/* 响应式设计 */
@media (max-width: 480px) {
  .beauty-slider-container {
    padding-right: 70px;
  }

  .bottom-bar {
    padding: 12px;
  }

  .capture-btn {
    width: 64px;
    height: 64px;
  }

  .capture-inner {
    width: 48px;
    height: 48px;
  }
}
</style>
