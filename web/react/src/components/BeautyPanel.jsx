import { useState, useMemo, useImperativeHandle, forwardRef } from 'react'
import './BeautyPanel.css'

const TYPE_SLIDER = 0
const TYPE_TOGGLE = 1

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

const BeautyPanel = forwardRef(({ 
  currentTab = 'beauty',
  onTabChanged,
  onBeautyParamChanged,
  onResetBeauty,
  onResetTab,
  onShowSlider,
  onHideSlider,
  onHidePanel,
  onCapture
}, ref) => {
  const [showSubOptions, setShowSubOptions] = useState(false)
  const [currentFunction, setCurrentFunction] = useState(null)
  const [currentSubOption, setCurrentSubOption] = useState(null)
  const [functionProgress, setFunctionProgress] = useState(new Map())
  const [toggleStates, setToggleStates] = useState(new Map())

  // 当前Tab的功能列表
  const currentFunctions = useMemo(() => {
    return functionConfigs[currentTab] || []
  }, [currentTab])

  // 当前子选项
  const currentSubOptions = useMemo(() => {
    if (!currentFunction) return []
    const func = currentFunctions.find(f => f.key === currentFunction)
    return func?.subOptions || []
  }, [currentFunction, currentFunctions])

  // 暴露方法给父组件
  useImperativeHandle(ref, () => ({
    updateSliderValue(tab, functionKey, value) {
      const key = `${tab}:${functionKey}`
      setFunctionProgress(prev => {
        const newMap = new Map(prev)
        newMap.set(key, value)
        return newMap
      })
    },
    getSliderValue(tab, functionKey) {
      const key = `${tab}:${functionKey}`
      return functionProgress.get(key) || 0
    }
  }))

  // Tab切换
  const switchTab = (tabId) => {
    setCurrentFunction(null)
    setCurrentSubOption(null)
    hideSubOptionsPanel()
    onTabChanged?.(tabId)
  }

  // 功能按钮点击
  const onFunctionClick = (func) => {
    if (!func.enabled) {
      alert(`${func.label}功能开发中，敬请期待 😊`)
      return
    }

    setCurrentFunction(func.key)

    if (func.type === TYPE_TOGGLE) {
      handleToggleFunction(func)
    } else if (func.type === TYPE_SLIDER) {
      if (func.subOptions && func.subOptions.length > 0) {
        setShowSubOptions(true)
        onHideSlider?.()
      } else {
        hideSubOptionsPanel()
        onShowSlider?.({
          tab: currentTab,
          function: func.key,
          value: functionProgress.get(`${currentTab}:${func.key}`) || 0
        })
      }
    }
  }

  // 处理开关型功能
  const handleToggleFunction = (func) => {
    if (func.key === 'image' && currentTab === 'virtual_bg') {
      alert('图片选择功能开发中')
      return
    }

    const functionKey = `${currentTab}:${func.key}`
    const currentState = toggleStates.get(functionKey) || false
    const newState = !currentState

    setToggleStates(prev => {
      const newMap = new Map(prev)
      newMap.set(functionKey, newState)
      return newMap
    })

    onBeautyParamChanged?.({
      tab: currentTab,
      function: func.key,
      value: newState ? 1.0 : 0.0
    })

    hideSubOptionsPanel()
    onHideSlider?.()
  }

  // 子选项点击
  const onSubOptionClick = (index, option) => {
    setCurrentSubOption(`style${index + 1}`)
    hideSubOptionsPanel()
    onShowSlider?.({
      tab: currentTab,
      function: currentFunction,
      value: functionProgress.get(`${currentTab}:${currentFunction}`) || 0
    })
  }

  // 关闭按钮点击
  const onBeautyOffClicked = () => {
    setCurrentFunction(null)
    hideSubOptionsPanel()
    onHideSlider?.()

    // 清除当前Tab下所有已保存的滑动条进度
    const prefix = `${currentTab}:`
    setFunctionProgress(prev => {
      const newMap = new Map(prev)
      for (const key of newMap.keys()) {
        if (key.startsWith(prefix)) {
          newMap.delete(key)
        }
      }
      return newMap
    })

    // 关闭所有开关型功能
    setToggleStates(prev => {
      const newMap = new Map(prev)
      for (const [key, value] of newMap.entries()) {
        if (key.startsWith(prefix) && value) {
          newMap.set(key, false)
          const functionKey = key.substring(prefix.length)
          onBeautyParamChanged?.({
            tab: currentTab,
            function: functionKey,
            value: 0.0
          })
        }
      }
      return newMap
    })

    onResetTab?.(currentTab)
  }

  // 重置美颜
  const onResetBeautyClicked = () => {
    setCurrentFunction(null)
    hideSubOptionsPanel()
    onHideSlider?.()

    setFunctionProgress(new Map())
    setToggleStates(new Map())

    onResetBeauty?.()
  }

  // 隐藏面板
  const onHidePanelClicked = () => {
    hideSubOptionsPanel()
    onHideSlider?.()
    onHidePanel?.()
  }

  // 显示子选项
  const showSubOptionsPanel = () => {
    setShowSubOptions(true)
  }

  // 隐藏子选项
  const hideSubOptionsPanel = () => {
    setShowSubOptions(false)
  }

  // 判断功能是否选中
  const isFunctionSelected = (functionKey) => {
    return currentFunction === functionKey
  }

  // 获取功能图标
  const getFunctionIcon = (iconName) => {
    return `/icons/${iconName}.png`
  }

  return (
    <div className="beauty-panel-wrapper">
      <div className="beauty-panel">
        {/* Tab 切换区域 */}
        <div className="tab-scroll-view">
          <div className="tab-container">
            {tabs.map(tab => (
              <button
                key={tab.id}
                className={`tab-btn ${currentTab === tab.id ? 'active' : ''}`}
                onClick={() => switchTab(tab.id)}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* 功能按钮区域 */}
        {!showSubOptions && (
          <div className="function-scroll-view">
            <div className="function-button-container">
              {/* 关闭按钮 */}
              <div className="function-button" onClick={onBeautyOffClicked}>
                <div className="function-icon-wrap">
                  <img src="/icons/close.png" alt="关闭" className="function-icon" />
                </div>
                <div className="function-label">关闭</div>
              </div>

              {/* 动态功能按钮 */}
              {currentFunctions.map(func => (
                <div
                  key={func.key}
                  className={`function-button ${!func.enabled ? 'disabled' : ''}`}
                  onClick={() => onFunctionClick(func)}
                >
                  <div className="function-icon-wrap">
                    <img src={getFunctionIcon(func.icon)} alt={func.label} className="function-icon" />
                    {!func.enabled && <div className="soon-badge">Soon</div>}
                  </div>
                  <div className="function-label">{func.label}</div>
                  {isFunctionSelected(func.key) && (
                    <div className="function-indicator"></div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 子选项区域 */}
        {showSubOptions && (
          <div className="sub-option-scroll-view">
            <div className="sub-option-container">
              {currentSubOptions.map((option, index) => (
                <div
                  key={index}
                  className="sub-option-button"
                  onClick={() => onSubOptionClick(index, option)}
                >
                  <div className="sub-option-icon-wrap">
                    <img src="/icons/beautycard3.png" alt="" className="sub-option-icon" />
                  </div>
                  <div className="sub-option-label">{option}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 底部按钮区域 */}
        <div className="bottom-button-container">
          <div className="bottom-button" onClick={onResetBeautyClicked}>
            <img src="/icons/reset.png" alt="重置" className="bottom-button-icon" />
            <span className="bottom-button-text">重置美颜</span>
          </div>
          <div className="bottom-button-center">
            <button className="capture-btn-panel" onClick={onCapture}>
              <div className="capture-inner-panel"></div>
            </button>
          </div>
          <div className="bottom-button" onClick={onHidePanelClicked}>
            <img src="/icons/menu.png" alt="隐藏" className="bottom-button-icon" />
            <span className="bottom-button-text">隐藏面板</span>
          </div>
        </div>
      </div>
    </div>
  )
})

BeautyPanel.displayName = 'BeautyPanel'

export default BeautyPanel

