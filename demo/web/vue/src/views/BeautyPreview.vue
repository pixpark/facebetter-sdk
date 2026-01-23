<!--
  美颜预览页面组件
  功能：
  - 实时相机预览美颜（支持镜像显示）
  - 图片美颜处理
  - 美颜参数调节（磨皮、美白、红润、瘦脸等）
  - 拍照保存
  - 前后对比功能
-->
<template>
  <div class="camera-preview-container">
    <!-- 相机预览画布：显示处理后的视频帧或图片 -->
    <canvas ref="displayCanvas" class="camera-canvas"></canvas>

    <!-- 隐藏的文件选择器：用于选择本地图片 -->
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
  FrameType 
} from 'facebetter'

// ==================== Props ====================
const props = defineProps({
  /** 初始激活的标签页（beauty/reshape/makeup/virtual_bg） */
  initialTab: {
    type: String,
    default: null
  }
})

// ==================== 组件引用 ====================
const router = useRouter()
const displayCanvas = ref(null)      // 显示画布引用
const beautySeekBar = ref(null)      // 美颜滑块引用
const beautyPanelRef = ref(null)     // 美颜面板组件引用
const fileInput = ref(null)          // 文件选择器引用

// ==================== 状态管理 ====================
const statusMessage = ref('')              // 状态提示消息
const showBeautyPanel = ref(false)         // 是否显示美颜面板
const showBeautySlider = ref(false)        // 是否显示美颜滑块
const showSliderValue = ref(false)         // 是否显示滑块数值
const currentTab = ref('beauty')           // 当前激活的标签页
const currentFunction = ref(null)          // 当前选中的功能
const isProcessing = ref(false)            // 是否正在处理帧
const isActive = ref(false)                // 相机是否激活

// ==================== 设备检测 ====================
const isMobileDevice = ref(false)         // 是否为移动设备

// ==================== 滑块相关 ====================
const currentSliderValue = ref(0)          // 当前滑块值（0-100）
const sliderValue = ref(0)                 // 显示的滑块值
const sliderValuePosition = ref(0)         // 滑块数值文本位置

// ==================== 前后对比功能 ====================
/** 保存的美颜参数状态（用于前后对比） */
const savedBeautyParams = ref({
  beauty: {
    white: 0,      // 美白
    smooth: 0,     // 磨皮
    rosiness: 0    // 红润
  },
  reshape: {
    thin_face: 0   // 瘦脸
  }
})
const isBeforeAfterPressed = ref(false)   // 是否按下前后对比按钮

// ==================== 引擎和视频相关 ====================
let engine = null              // Facebetter 美颜引擎实例
let videoElement = null        // 视频元素
let videoStream = null         // 视频流
let displayCtx = null         // 显示画布的 2D 上下文
let animationFrameId = null    // 动画帧 ID
let lastProcessedFrame = null  // 最后处理后的帧数据（用于拍照保存）
let sliderValueTimer = null    // 滑块数值隐藏定时器

// ==================== 图片处理模式 ====================
const isImageMode = ref(false)  // 是否为图片处理模式
let currentImage = null          // 当前图片文件
let imageElement = null         // 当前图片元素

// ==================== 生命周期 ====================
onMounted(async () => {
  try {
    // 检测是否为移动设备（用于判断是否支持切换摄像头）
    isMobileDevice.value = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                          ('ontouchstart' in window || navigator.maxTouchPoints > 0)
    
    // 等待 DOM 渲染完成后再初始化画布
    await nextTick()
    
    // 初始化画布
    initCanvas()
    
    // 初始化美颜引擎
    await initEngine()
    
    // 启动相机
    await startCamera()
    
    // 如果有初始标签，打开面板并切换到对应标签
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
  // 清理资源
  cleanup()
})

// ==================== 初始化函数 ====================
/**
 * 初始化显示画布
 * 设置画布尺寸为容器尺寸（最大宽度 1200px）
 */
const initCanvas = () => {
  const canvas = displayCanvas.value
  const container = canvas.parentElement
  // 使用容器的实际宽度（最大 1200px），而不是窗口宽度
  const containerWidth = container ? Math.min(container.clientWidth, 1200) : window.innerWidth
  const containerHeight = container ? container.clientHeight : window.innerHeight
  canvas.width = containerWidth
  canvas.height = containerHeight
  displayCtx = canvas.getContext('2d')
}

/**
 * 初始化 Facebetter 美颜引擎
 * 配置引擎参数并启用所需的美颜功能
 */
const initEngine = async () => {
  const appId = ''
  const appKey = ''

  // 验证 appId 和 appKey
  if (!appId || !appKey || appId.trim() === '' || appKey.trim() === '') {
    console.error('[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code.')
    statusMessage.value = '错误：请配置 appId 和 appKey'
    setTimeout(() => { statusMessage.value = '' }, 3000)
    return
  }

  const config = new EngineConfig({
    appId: appId,
    appKey: appKey
  })

  engine = new BeautyEffectEngine(config)

  // 配置日志输出
  await engine.setLogConfig({
    consoleEnabled: true,  // 控制台日志
    fileEnabled: false,     // 文件日志
    level: 0                // 日志级别
  })

  // 初始化引擎
  await engine.init()

  // 启用所需的美颜类型
  engine.setBeautyTypeEnabled(BeautyType.Basic, true)              // 基础美颜（磨皮、美白、红润）
  engine.setBeautyTypeEnabled(BeautyType.Reshape, true)             // 美型（瘦脸、大眼等）
  engine.setBeautyTypeEnabled(BeautyType.Makeup, true)             // 美妆（口红、腮红等）

  statusMessage.value = '引擎初始化成功'
  setTimeout(() => { statusMessage.value = '' }, 2000)
}

/**
 * 启动相机
 * 获取用户媒体流并开始处理视频帧
 */
const startCamera = async () => {
  try {
    // 获取用户媒体流（摄像头）
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 640 },   // 理想宽度
        height: { ideal: 480 },   // 理想高度
        frameRate: { ideal: 15 }  // 理想帧率
      },
      audio: false  // 不需要音频
    })

    // 创建视频元素并设置流
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

/**
 * 处理视频帧
 * 从视频元素获取帧数据，使用美颜引擎处理，然后镜像显示到画布
 * 注意：相机预览需要镜像显示（符合用户习惯），但保存的照片是正常方向的
 */
const processVideoFrame = async () => {
  // 检查前置条件
  if (!isActive.value || !engine || !videoElement || !videoElement.videoWidth) {
    if (isActive.value) {
      animationFrameId = requestAnimationFrame(processVideoFrame)
    }
    return
  }

  // 防止重复处理（如果上一帧还在处理中，跳过当前帧）
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
      
      // 使用美颜引擎处理视频帧
      const processed = engine.processImage(imageData, canvas.width, canvas.height, FrameType.Video)

      // 存储处理后的帧（用于拍照保存，保存的是未镜像的原始数据）
      lastProcessedFrame = processed

      // 绘制到显示画布
      if (displayCtx && displayCanvas.value) {
        const canvas = displayCanvas.value
        
        // 调整画布尺寸以匹配处理后的图像尺寸
        if (canvas.width !== processed.width || canvas.height !== processed.height) {
          canvas.width = processed.width
          canvas.height = processed.height
          displayCtx = canvas.getContext('2d')
        }
        
        // 创建临时 canvas 用于镜像显示
        // 注意：putImageData 不受 canvas 变换影响，所以需要先绘制到临时 canvas
        // 然后使用 drawImage 配合变换来实现镜像
        const tempCanvas = document.createElement('canvas')
        tempCanvas.width = processed.width
        tempCanvas.height = processed.height
        const tempCtx = tempCanvas.getContext('2d')
        tempCtx.putImageData(processed, 0, 0)
        
        // 清空显示画布
        displayCtx.clearRect(0, 0, canvas.width, canvas.height)
        
        // 保存上下文状态
        displayCtx.save()
        
        // 应用水平翻转变换（镜像显示）
        // scale(-1, 1) 表示水平翻转，translate 用于调整位置
        displayCtx.scale(-1, 1)
        displayCtx.translate(-canvas.width, 0)
        
        // 使用 drawImage 绘制临时 canvas（会受变换影响，实现镜像）
        displayCtx.drawImage(tempCanvas, 0, 0)
        
        // 恢复上下文状态
        displayCtx.restore()
        
        // 设置 CSS 样式以实现等比缩放适应容器（保持宽高比，完整显示）
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

  // 继续处理下一帧
  if (isActive.value) {
    animationFrameId = requestAnimationFrame(processVideoFrame)
  }
}

// ==================== 美颜面板事件处理 ====================
/**
 * Tab 切换事件处理
 * @param {string} tabId - 标签页 ID（beauty/reshape/makeup/virtual_bg）
 */
const onTabChanged = (tabId) => {
  currentTab.value = tabId
  currentFunction.value = null
  hideSlider()
}

/**
 * 美颜参数变化事件处理
 * @param {Object} data - 参数数据
 * @param {string} data.tab - 标签页
 * @param {string} data.function - 功能键
 * @param {number} data.value - 参数值（0-100）
 */
const onBeautyParamChanged = (data) => {
  applyBeautyParam(data.tab, data.function, data.value)
}

/**
 * 显示滑块事件处理
 * @param {Object} data - 滑块数据
 * @param {string} data.tab - 标签页
 * @param {string} data.function - 功能键
 * @param {number} data.value - 当前值（0-100）
 */
const onShowSlider = (data) => {
  currentFunction.value = data.function
  currentSliderValue.value = data.value
  sliderValue.value = data.value
  updateSliderValuePosition()
  showBeautySlider.value = true
  
  // 立即应用一次参数（转换为 0.0-1.0）
  applyBeautyParam(data.tab, data.function, data.value / 100.0)
}

/**
 * 隐藏滑块事件处理
 */
const onHideSlider = () => {
  showBeautySlider.value = false
  showSliderValue.value = false
}

/**
 * 重置所有美颜参数
 */
const onResetBeauty = () => {
  currentSliderValue.value = 0
  currentFunction.value = null
  hideSlider()
  resetAllParams()
}

/**
 * 重置指定 Tab 的参数
 * @param {string} tab - 标签页 ID
 */
const onResetTab = (tab) => {
  resetTabParams(tab)
}

/**
 * 隐藏美颜面板
 */
const onHidePanel = () => {
  showBeautyPanel.value = false
  hideSlider()
}

/**
 * 隐藏滑动条
 */
const hideSlider = () => {
  showBeautySlider.value = false
  showSliderValue.value = false
}

// ==================== 滑块事件处理 ====================
/**
 * 滑块值变化事件处理
 * @param {Event} event - 输入事件
 */
const onSliderChange = (event) => {
  const value = parseInt(event.target.value)
  currentSliderValue.value = value
  sliderValue.value = value
  updateSliderValuePosition()

  // 同步进度到 BeautyPanel 组件
  if (currentFunction.value && beautyPanelRef.value) {
    beautyPanelRef.value.updateSliderValue(currentTab.value, currentFunction.value, value)
  }

  // 应用参数（0-100 转换为 0.0-1.0）
  if (currentFunction.value) {
    applyBeautyParam(currentTab.value, currentFunction.value, value / 100.0)
  }
}

/**
 * 滑块开始拖动事件处理
 */
const onSliderStart = () => {
  showSliderValue.value = true
}

/**
 * 滑块结束拖动事件处理
 * 延迟 500ms 后隐藏数值显示
 */
const onSliderEnd = () => {
  if (sliderValueTimer) {
    clearTimeout(sliderValueTimer)
  }
  sliderValueTimer = setTimeout(() => {
    showSliderValue.value = false
  }, 500)
}

/**
 * 更新滑块数值文本位置
 * 根据滑块当前值计算数值文本的显示位置
 */
const updateSliderValuePosition = () => {
  nextTick(() => {
    if (!beautySeekBar.value) return
    
    const slider = beautySeekBar.value
    const sliderRect = slider.getBoundingClientRect()
    const sliderWidth = sliderRect.width - 32  // 减去左右 padding
    const thumbPos = (currentSliderValue.value / 100) * sliderWidth
    
    // 计算数值文本位置（居中在 thumb 上方）
    sliderValuePosition.value = thumbPos + 16  // 加上左边距
  })
}

// ==================== 美颜参数应用 ====================
/**
 * 应用美颜参数到引擎
 * @param {string} tab - 标签页（beauty/reshape/makeup/virtual_bg）
 * @param {string} functionKey - 功能键
 * @param {number} value - 参数值（0.0-1.0）
 */
const applyBeautyParam = (tab, functionKey, value) => {
  if (!engine) return

  try {
    // 确保参数值在 0.0-1.0 范围内
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
        // 模糊背景模式
        engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)   // 虚拟背景
        const options = new VirtualBackgroundOptions({
          mode: value > 0 ? BackgroundMode.Blur : BackgroundMode.None
        })
        engine.setVirtualBackground(options)
      } else if (functionKey === 'preset') {
        // 预置背景：加载预置图片并设置为 Image 模式
        engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)   // 虚拟背景
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
        // 如果 value > 0，说明用户想开启图像背景，但需要先选择图片
        // 这里先设置为 None，实际图片选择功能在 BeautyPanel 中处理
        engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, true)
        if (value <= 0) {
          const options = new VirtualBackgroundOptions({
            mode: BackgroundMode.None
          })
          engine.setVirtualBackground(options)
        }
      } else if (functionKey === 'none') {
        engine.setBeautyTypeEnabled(BeautyType.VirtualBackground, false)   // 虚拟背景
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

/**
 * 重置指定 Tab 的所有参数
 * @param {string} tab - 标签页 ID
 */
const resetTabParams = (tab) => {
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
    }

    // 如果是图片模式，重新处理图片
    if (isImageMode.value && imageElement) {
      processImage()
    }
  } catch (error) {
    console.error('重置Tab参数失败:', error)
  }
}

/**
 * 加载预置背景图片
 * 从 /background.jpg 加载图片并设置为虚拟背景
 */
const loadPresetBackground = async () => {
  if (!engine) return

  try {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    
    // 等待图片加载完成
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

/**
 * 重置所有美颜参数
 * 将所有美颜、美型、美妆、虚拟背景参数重置为 0
 */
const resetAllParams = () => {
  if (!engine) return

  try {
    // 重置基础美颜参数
    engine.setBasicParam(BasicParam.Whitening, 0)   // 美白
    engine.setBasicParam(BasicParam.Smoothing, 0)   // 磨皮
    engine.setBasicParam(BasicParam.Rosiness, 0)    // 红润

    // 重置美型参数
    engine.setReshapeParam(ReshapeParam.FaceThin, 0)      // 瘦脸
    engine.setReshapeParam(ReshapeParam.FaceVShape, 0)      // V 脸
    engine.setReshapeParam(ReshapeParam.FaceNarrow, 0)     // 窄脸
    engine.setReshapeParam(ReshapeParam.FaceShort, 0)      // 短脸
    engine.setReshapeParam(ReshapeParam.Cheekbone, 0)      // 颧骨
    engine.setReshapeParam(ReshapeParam.Jawbone, 0)        // 下颌骨
    engine.setReshapeParam(ReshapeParam.Chin, 0)           // 下巴
    engine.setReshapeParam(ReshapeParam.NoseSlim, 0)        // 瘦鼻
    engine.setReshapeParam(ReshapeParam.EyeSize, 0)         // 大眼
    engine.setReshapeParam(ReshapeParam.EyeDistance, 0)     // 眼距

    // 重置美妆参数
    engine.setMakeupParam(MakeupParam.Lipstick, 0)  // 口红
    engine.setMakeupParam(MakeupParam.Blush, 0)     // 腮红

    // 重置虚拟背景
    const options = new VirtualBackgroundOptions({
      mode: BackgroundMode.None
    })
    engine.setVirtualBackground(options)
  } catch (error) {
    console.error('重置所有参数失败:', error)
  }
}


// ==================== UI 交互事件 ====================
/**
 * 美颜美型按钮点击
 */
const onBeautyShapeClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'beauty'
}

/**
 * 美妆按钮点击
 */
const onMakeupClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'makeup'
}

/**
 * 贴纸特效按钮点击
 */
const onStickerClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'sticker'
}

/**
 * 滤镜调色按钮点击
 */
const onFilterClick = () => {
  showBeautyPanel.value = true
  currentTab.value = 'filter'
}

/**
 * 返回主页
 */
const goBack = () => {
  router.push('/')
}

/**
 * 打开图片选择器（相册）
 */
const openGallery = () => {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

/**
 * 处理选中的图片
 * 从文件选择器获取图片，加载后切换到图片处理模式
 * @param {Event} event - 文件选择事件
 */
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
    // 停止相机（切换到图片模式）
    if (isActive.value) {
      stopCamera()
    }

    // 使用 FileReader 读取图片文件
    const reader = new FileReader()
    reader.onload = async (e) => {
      try {
        const img = new Image()
        img.onload = async () => {
          // 切换到图片模式
          isImageMode.value = true
          currentImage = file
          imageElement = img

          // 注意：画布尺寸会在 processImage 中根据处理后的图像尺寸自动调整
          // 这里不需要预先设置画布尺寸

          // 处理图片（processImage 会自动调整画布尺寸以匹配处理后的图像）
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

  // 清空 input，允许重复选择同一文件
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

/**
 * 处理图片（图片模式）
 * 使用美颜引擎处理图片并显示到画布
 * 注意：图片处理不需要镜像，保持原始方向
 */
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

    // 使用 Image 处理模式处理图片
    const processed = engine.processImage(imageData, canvas.width, canvas.height, ProcessMode.Image)

    if (processed && displayCanvas.value) {
      const canvas = displayCanvas.value
      
      // 调整画布尺寸以匹配处理后的图像尺寸
      if (canvas.width !== processed.width || canvas.height !== processed.height) {
        canvas.width = processed.width
        canvas.height = processed.height
        displayCtx = canvas.getContext('2d')
      }
      
      // 绘制到画布（图片不需要镜像，保持原始方向）
      displayCtx.putImageData(processed, 0, 0)
      lastProcessedFrame = processed
      
      // 设置 CSS 样式以实现等比缩放适应容器（保持宽高比，完整显示）
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

// ==================== 相机控制 ====================
/**
 * 停止相机
 * 停止视频流并清理相关资源
 */
const stopCamera = () => {
  isActive.value = false

  // 取消动画帧
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId)
    animationFrameId = null
  }

  // 停止所有视频轨道
  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop())
    videoStream = null
  }

  // 清理视频元素
  if (videoElement) {
    videoElement.srcObject = null
    videoElement = null
  }
}

/**
 * 切换摄像头（前后摄像头切换）
 * 仅在移动设备上支持
 */
const flipCamera = async () => {
  // 桌面端不支持切换摄像头
  if (!isMobileDevice.value) {
    return
  }

  try {
    // 停止当前视频流
    if (videoStream) {
      videoStream.getTracks().forEach(track => track.stop())
    }

    // 获取当前摄像头方向并切换
    const currentFacingMode = videoElement?.srcObject?.getVideoTracks()[0]?.getSettings().facingMode
    const constraints = {
      video: {
        facingMode: currentFacingMode === 'user' ? 'environment' : 'user'
      }
    }

    // 获取新的视频流
    videoStream = await navigator.mediaDevices.getUserMedia(constraints)
    videoElement.srcObject = videoStream
    await videoElement.play()
  } catch (error) {
    console.error('切换摄像头失败:', error)
    alert('切换摄像头失败')
  }
}

/**
 * 更多选项（暂未实现）
 */
const toggleMore = () => {
  alert('更多选项功能开发中')
}

// ==================== 前后对比功能 ====================
/**
 * 保存当前所有美颜参数
 * 用于前后对比功能，保存当前状态以便恢复
 */
const saveCurrentBeautyParams = () => {
  if (!beautyPanelRef.value) return
  
  // 从 BeautyPanel 组件获取所有功能的进度值
  const beautyParams = {
    beauty: {},
    reshape: {}
  }
  
  // 获取美颜参数（0-100 的值，转换为 0.0-1.0）
  const whiteValue = beautyPanelRef.value.getSliderValue('beauty', 'white') || 0
  const smoothValue = beautyPanelRef.value.getSliderValue('beauty', 'smooth') || 0
  const rosinessValue = beautyPanelRef.value.getSliderValue('beauty', 'rosiness') || 0
  
  beautyParams.beauty.white = whiteValue / 100.0
  beautyParams.beauty.smooth = smoothValue / 100.0
  beautyParams.beauty.rosiness = rosinessValue / 100.0
  
  // 获取美型参数
  const reshapeKeys = ['thin_face', 'v_face', 'narrow_face', 'short_face', 'cheekbone', 'jawbone', 'chin', 'nose_slim', 'big_eye', 'eye_distance']
  reshapeKeys.forEach(key => {
    const value = beautyPanelRef.value.getSliderValue('reshape', key) || 0
    beautyParams.reshape[key] = value / 100.0
  })
  
  savedBeautyParams.value = beautyParams
}

/**
 * 恢复保存的美颜参数
 * 用于前后对比功能，恢复之前保存的状态
 */
const restoreBeautyParams = () => {
  const params = savedBeautyParams.value
  
  // 恢复美颜参数
  if (params.beauty) {
    if (params.beauty.white !== undefined) {
      const value = params.beauty.white
      applyBeautyParam('beauty', 'white', value)
      // 同步更新 BeautyPanel 的进度值（0.0-1.0 转换为 0-100）
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
    const reshapeKeys = ['thin_face', 'v_face', 'narrow_face', 'short_face', 'cheekbone', 'jawbone', 'chin', 'nose_slim', 'big_eye', 'eye_distance']
    reshapeKeys.forEach(key => {
      if (params.reshape[key] !== undefined) {
        const value = params.reshape[key]
        applyBeautyParam('reshape', key, value)
        if (beautyPanelRef.value) {
          beautyPanelRef.value.updateSliderValue('reshape', key, Math.round(value * 100))
        }
      }
    })
  }
}

/**
 * 前后对比按钮按下事件
 * 保存当前参数并关闭所有美颜效果
 */
const onBeforeAfterPress = () => {
  if (isBeforeAfterPressed.value) return
  
  isBeforeAfterPressed.value = true
  
  // 保存当前美颜参数
  saveCurrentBeautyParams()
  
  // 关闭所有美颜效果（显示原始效果）
  resetAllParams()
}

/**
 * 前后对比按钮松开事件
 * 恢复之前保存的美颜参数
 */
const onBeforeAfterRelease = () => {
  if (!isBeforeAfterPressed.value) return
  
  isBeforeAfterPressed.value = false
  
  // 恢复美颜效果
  restoreBeautyParams()
}

// ==================== 拍照功能 ====================
/**
 * 拍照并保存
 * 相机模式：保存镜像图片（与预览一致）
 * 图片模式：保存正常方向的图片
 */
const capturePhoto = async () => {
  if (!displayCanvas.value || !displayCtx) {
    statusMessage.value = '画布未初始化'
    setTimeout(() => { statusMessage.value = '' }, 2000)
    return
  }

  try {
    // 使用处理后的原始图像数据
    if (!lastProcessedFrame) {
      statusMessage.value = '没有可保存的图像'
      setTimeout(() => { statusMessage.value = '' }, 2000)
      return
    }

    const width = lastProcessedFrame.width
    const height = lastProcessedFrame.height

    if (width === 0 || height === 0) {
      statusMessage.value = '画布尺寸无效'
      setTimeout(() => { statusMessage.value = '' }, 2000)
      return
    }

    // 创建临时 canvas 用于导出
    const exportCanvas = document.createElement('canvas')
    exportCanvas.width = width
    exportCanvas.height = height
    const exportCtx = exportCanvas.getContext('2d')
    
    // 根据模式决定是否镜像
    if (isImageMode.value) {
      // 图片模式：保存正常方向的图片（不需要镜像）
      exportCtx.putImageData(lastProcessedFrame, 0, 0)
    } else {
      // 相机模式：保存镜像图片（与预览一致）
      // 创建临时 canvas 用于镜像
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = width
      tempCanvas.height = height
      const tempCtx = tempCanvas.getContext('2d')
      tempCtx.putImageData(lastProcessedFrame, 0, 0)
      
      // 应用水平翻转变换（镜像）
      exportCtx.save()
      exportCtx.scale(-1, 1)
      exportCtx.translate(-width, 0)
      exportCtx.drawImage(tempCanvas, 0, 0)
      exportCtx.restore()
    }

    // 转换为 blob 并下载
    exportCanvas.toBlob((blob) => {
      if (!blob) {
        statusMessage.value = '保存失败'
        setTimeout(() => { statusMessage.value = '' }, 2000)
        return
      }

      // 创建下载链接
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

// ==================== 资源清理 ====================
/**
 * 清理所有资源
 * 在组件卸载时调用，释放相机、引擎等资源
 */
const cleanup = () => {
  isActive.value = false

  // 清理定时器
  if (sliderValueTimer) {
    clearTimeout(sliderValueTimer)
    sliderValueTimer = null
  }

  // 取消动画帧
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId)
    animationFrameId = null
  }

  // 停止视频流
  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop())
    videoStream = null
  }

  // 销毁引擎
  if (engine) {
    engine.destroy()
    engine = null
  }

  // 清理其他引用
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
