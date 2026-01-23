<template>
  <div class="beauty-panel-wrapper">
    <div class="beauty-panel">
      <!-- Tab 切换区域 -->
      <div class="tab-scroll-view">
        <div class="tab-container">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            :class="['tab-btn', { active: currentTab === tab.id }]"
            @click="switchTab(tab.id)"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>

      <!-- 功能按钮区域 -->
      <div class="function-scroll-view">
        <div class="function-button-container">
          <!-- 关闭按钮 -->
          <div class="function-button" @click="onBeautyOffClicked">
            <div class="function-icon-wrap">
              <img src="/icons/close.png" alt="关闭" class="function-icon" />
            </div>
            <div class="function-label">关闭</div>
          </div>

          <!-- 动态功能按钮 -->
          <div
            v-for="func in currentFunctions"
            :key="func.key"
            :class="['function-button', { disabled: !func.enabled }]"
            @click="onFunctionClick(func)"
          >
            <div class="function-icon-wrap">
              <img :src="getFunctionIcon(func.icon)" :alt="func.label" class="function-icon" />
              <div v-if="!func.enabled" class="soon-badge">Soon</div>
            </div>
            <div class="function-label">{{ func.label }}</div>
            <div 
              v-if="isFunctionSelected(func.key)" 
              class="function-indicator"
            ></div>
          </div>
        </div>
      </div>

      <!-- 子选项区域（默认隐藏，覆盖在功能按钮位置） -->
      <div v-if="showSubOptions" class="sub-option-scroll-view">
        <div class="sub-option-container">
          <div
            v-for="(option, index) in currentSubOptions"
            :key="index"
            class="sub-option-button"
            @click="onSubOptionClick(index, option)"
          >
            <div class="sub-option-icon-wrap">
              <img src="/icons/beautycard3.png" alt="" class="sub-option-icon" />
            </div>
            <div class="sub-option-label">{{ option }}</div>
          </div>
        </div>
      </div>

      <!-- 底部按钮区域 -->
      <div class="bottom-button-container">
        <div class="bottom-button" @click="onResetBeautyClicked">
          <img src="/icons/reset.png" alt="重置" class="bottom-button-icon" />
          <span class="bottom-button-text">重置美颜</span>
        </div>
        <div class="bottom-button-center">
          <button class="capture-btn-panel" @click="onCaptureClicked">
            <div class="capture-inner-panel"></div>
          </button>
        </div>
        <div class="bottom-button" @click="onHidePanelClicked">
          <img src="/icons/menu.png" alt="隐藏" class="bottom-button-icon" />
          <span class="bottom-button-text">隐藏面板</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  currentTab: {
    type: String,
    default: 'beauty'
  }
})

const emit = defineEmits([
  'tab-changed',
  'beauty-param-changed',
  'reset-beauty',
  'hide-panel',
  'capture'
])

// 状态管理
const showSubOptions = ref(false)
const currentFunction = ref(null)
const currentSubOption = ref(null)

// 功能进度存储（tab:function -> 0-100）
const functionProgress = ref(new Map())
// 开关状态存储（tab:function -> true/false）
const toggleStates = ref(new Map())

// Tab 配置
const tabs = [
  { id: 'beauty', label: '美颜' },
  { id: 'reshape', label: '美型' },
  { id: 'makeup', label: '美妆' },
  { id: 'filter', label: '滤镜' },
  { id: 'sticker', label: '贴纸' },
  { id: 'body', label: '美体' },
  { id: 'virtual_bg', label: '虚拟背景' },
  { id: 'quality', label: '画质调整' }
]

// 功能配置
const TYPE_SLIDER = 0
const TYPE_TOGGLE = 1

const functionConfigs = {
  beauty: [
    { key: 'white', label: '美白', icon: 'meiyan', enabled: true, type: TYPE_SLIDER },
    { key: 'dark', label: '美黑', icon: 'huanfase', enabled: false, type: TYPE_SLIDER },
    { key: 'smooth', label: '磨皮', icon: 'meiyan', enabled: true, type: TYPE_SLIDER },
    { key: 'rosiness', label: '红润', icon: 'meiyan', enabled: true, type: TYPE_SLIDER }
  ],
  reshape: [
    { key: 'thin_face', label: '瘦脸', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'v_face', label: 'V脸', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'narrow_face', label: '窄脸', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'short_face', label: '短脸', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'cheekbone', label: '颧骨', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'jawbone', label: '下颌', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'chin', label: '下巴', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'nose_slim', label: '瘦鼻', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'big_eye', label: '大眼', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'eye_distance', label: '眼距', icon: 'meixing2', enabled: true, type: TYPE_SLIDER }
  ],
  makeup: [
    { key: 'lipstick', label: '口红', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['样式1', '样式2', '样式3'] },
    { key: 'blush', label: '腮红', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['样式1', '样式2', '样式3'] },
    { key: 'eyebrow', label: '眉毛', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['样式1', '样式2', '样式3'] },
    { key: 'eyeshadow', label: '眼影', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['样式1', '样式2', '样式3'] }
  ],
  filter: [
    { key: 'natural', label: '自然', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'fresh', label: '清新', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'retro', label: '复古', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'bw', label: '黑白', icon: 'lvjing', enabled: true, type: TYPE_SLIDER }
  ],
  sticker: [
    { key: 'cute', label: '可爱', icon: 'tiezhi2', enabled: false, type: TYPE_SLIDER },
    { key: 'funny', label: '搞笑', icon: 'tiezhi2', enabled: false, type: TYPE_SLIDER }
  ],
  body: [
    { key: 'slim', label: '瘦身', icon: 'meiti', enabled: false, type: TYPE_SLIDER }
  ],
  virtual_bg: [
    { key: 'blur', label: '模糊', icon: 'lvmukoutu', enabled: true, type: TYPE_TOGGLE },
    { key: 'preset', label: '预置', icon: 'xunibeijing', enabled: true, type: TYPE_TOGGLE },
    { key: 'image', label: '图像', icon: 'gallery', enabled: true, type: TYPE_TOGGLE }
  ],
  quality: [
    { key: 'sharpen', label: '锐化', icon: 'huazhitiaozheng2', enabled: false, type: TYPE_SLIDER }
  ]
}

// 当前Tab的功能列表
const currentFunctions = computed(() => {
  return functionConfigs[props.currentTab] || []
})

// 当前子选项
const currentSubOptions = ref([])

// Tab切换
const switchTab = (tabId) => {
  currentFunction.value = null
  currentSubOption.value = null
  hideSubOptionsPanel()
  emit('tab-changed', tabId)
}

// 功能按钮点击
const onFunctionClick = (func) => {
  if (!func.enabled) {
    alert(`${func.label}功能开发中，敬请期待 😊`)
    return
  }

  currentFunction.value = func.key

  if (func.type === TYPE_TOGGLE) {
    // 开关型：切换状态
    handleToggleFunction(func)
  } else if (func.type === TYPE_SLIDER) {
    // 滑动条型
    if (func.subOptions && func.subOptions.length > 0) {
      // 有子选项：显示子选项
      currentSubOptions.value = func.subOptions
      showSubOptionsPanel()
      emit('hide-slider')
    } else {
      // 无子选项：直接显示滑动条
      hideSubOptionsPanel()
      emit('show-slider', {
        tab: props.currentTab,
        function: func.key,
        value: functionProgress.value.get(`${props.currentTab}:${func.key}`) || 0
      })
    }
  }
}

// 处理开关型功能
const handleToggleFunction = (func) => {
  if (func.key === 'image' && props.currentTab === 'virtual_bg') {
    // 图像按钮：打开图片选择器
    alert('图片选择功能开发中')
    return
  }

  // 普通开关型功能：切换状态
  const functionKey = `${props.currentTab}:${func.key}`
  const currentState = toggleStates.value.get(functionKey) || false
  const newState = !currentState

  // 更新状态
  toggleStates.value.set(functionKey, newState)

  // 应用参数（1.0 = 开启, 0.0 = 关闭）
  emit('beauty-param-changed', {
    tab: props.currentTab,
    function: func.key,
    value: newState ? 1.0 : 0.0
  })

  // 不显示滑动条
  hideSubOptionsPanel()
  emit('hide-slider')
}

// 子选项点击
const onSubOptionClick = (index, option) => {
  currentSubOption.value = `style${index + 1}`
  hideSubOptionsPanel()
  emit('show-slider', {
    tab: props.currentTab,
    function: currentFunction.value,
    value: functionProgress.value.get(`${props.currentTab}:${currentFunction.value}`) || 0
  })
  // TODO: 应用具体的样式
}

// 关闭按钮点击
const onBeautyOffClicked = () => {
  currentFunction.value = null
  hideSubOptionsPanel()
  emit('hide-slider')

  // 清除当前Tab下所有已保存的滑动条进度
  const prefix = `${props.currentTab}:`
  for (const key of functionProgress.value.keys()) {
    if (key.startsWith(prefix)) {
      functionProgress.value.delete(key)
    }
  }

  // 关闭所有开关型功能
  for (const [key, value] of toggleStates.value.entries()) {
    if (key.startsWith(prefix) && value) {
      toggleStates.value.set(key, false)
      const functionKey = key.substring(prefix.length)
      emit('beauty-param-changed', {
        tab: props.currentTab,
        function: functionKey,
        value: 0.0
      })
    }
  }

  // 重置当前Tab的所有参数
  emit('reset-tab', props.currentTab)
}

// 重置美颜
const onResetBeautyClicked = () => {
  currentFunction.value = null
  hideSubOptionsPanel()
  emit('hide-slider')

  // 清空所有进度和状态
  functionProgress.value.clear()
  toggleStates.value.clear()

  // 重置所有参数
  emit('reset-beauty')
}

// 隐藏面板
const onHidePanelClicked = () => {
  hideSubOptionsPanel()
  emit('hide-slider')
  emit('hide-panel')
}

// 拍照
const onCaptureClicked = () => {
  emit('capture')
}

// 显示子选项
const showSubOptionsPanel = () => {
  showSubOptions.value = true
}

// 隐藏子选项
const hideSubOptionsPanel = () => {
  showSubOptions.value = false
}

// 判断功能是否选中
const isFunctionSelected = (functionKey) => {
  return currentFunction.value === functionKey
}

// 获取功能图标
const getFunctionIcon = (iconName) => {
  return `/icons/${iconName}.png`
}

// 暴露方法：更新滑块值
defineExpose({
  updateSliderValue(tab, functionKey, value) {
    const key = `${tab}:${functionKey}`
    functionProgress.value.set(key, value)
  },
  getSliderValue(tab, functionKey) {
    const key = `${tab}:${functionKey}`
    return functionProgress.value.get(key) || 0
  }
})
</script>

<style scoped>
/* 美颜面板容器 */
.beauty-panel-wrapper {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 10;
}

/* 美颜面板 */
.beauty-panel {
  position: relative;
  width: 100%;
  background: rgba(0, 0, 0, 0.8);
}

/* Tab 切换区域 */
.tab-scroll-view {
  width: 100%;
  height: 50px;
  padding-top: 8px;
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.tab-scroll-view::-webkit-scrollbar {
  display: none;
}

.tab-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 0 8px;
  height: 100%;
}

.tab-btn {
  min-width: 80px;
  height: 100%;
  padding: 0 12px;
  background: transparent;
  border: none;
  color: #AAAAAA;
  font-size: 16px;
  cursor: pointer;
  white-space: nowrap;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.2s;
}

.tab-btn.active {
  color: white;
  font-weight: bold;
}

/* 功能按钮区域 */
.function-scroll-view {
  width: 100%;
  height: 120px;
  padding: 0 16px;
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
  -ms-overflow-style: none;
  position: relative;
}

.function-scroll-view::-webkit-scrollbar {
  display: none;
}

.function-button-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: 100%;
}

.function-button {
  width: 70px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 8px;
  margin-right: 8px;
  cursor: pointer;
  position: relative;
}

.function-button.disabled {
  opacity: 0.5;
}

.function-icon-wrap {
  width: 50px;
  height: 50px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.function-icon {
  width: 28px;
  height: 28px;
  object-fit: contain;
  filter: brightness(0) invert(1);
}

.soon-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  padding: 1px 3px;
  background: rgba(255, 0, 0, 0.8);
  color: white;
  font-size: 8px;
  border-radius: 2px;
}

.function-label {
  margin-top: 4px;
  color: white;
  font-size: 12px;
  text-align: center;
}

.function-indicator {
  width: 14px;
  height: 3px;
  margin-top: 3px;
  background: #00FF00;
  border-radius: 2px;
}

/* 子选项区域（覆盖在功能按钮位置） */
.sub-option-scroll-view {
  position: absolute;
  top: 50px; /* Tab区域高度 */
  left: 0;
  right: 0;
  width: 100%;
  height: 120px;
  padding: 0 16px;
  background: rgba(0, 0, 0, 0.8);
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
  -ms-overflow-style: none;
  z-index: 2;
}

.sub-option-scroll-view::-webkit-scrollbar {
  display: none;
}

.sub-option-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: 100%;
}

.sub-option-button {
  width: 70px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 8px;
  margin-right: 8px;
  cursor: pointer;
}

.sub-option-icon-wrap {
  width: 50px;
  height: 50px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.sub-option-icon {
  width: 40px;
  height: 40px;
  object-fit: cover;
}

.sub-option-label {
  margin-top: 4px;
  color: white;
  font-size: 12px;
  text-align: center;
}

/* 底部按钮区域 */
.bottom-button-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  min-height: 80px;
  padding: 10px 16px;
}

.bottom-button {
  flex: 1;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  padding: 8px;
  cursor: pointer;
}

.bottom-button-icon {
  width: 20px;
  height: 20px;
  object-fit: contain;
  filter: brightness(0) invert(1);
  margin-right: 8px;
}

.bottom-button-text {
  color: white;
  font-size: 14px;
}

.bottom-button-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.capture-btn-panel {
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

.capture-btn-panel:active {
  transform: scale(0.85);
  opacity: 0.8;
}

.capture-btn-panel:hover {
  transform: scale(1.05);
}

.capture-inner-panel {
  width: 50px;
  height: 50px;
  background: #00FF00;
  border-radius: 50%;
  flex-shrink: 0;
}
</style>

