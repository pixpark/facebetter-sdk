import React, { useState, useMemo, useImperativeHandle, forwardRef } from 'react'
import './BeautyPanel.css'

// Function types
const TYPE_SLIDER = 0  // Slider-based parameter (0-100)
const TYPE_TOGGLE = 1  // Toggle-based parameter (on/off)

const tabs = [
  { id: 'beauty', label: 'Beauty' },
  { id: 'reshape', label: 'Reshape' },
  { id: 'makeup', label: 'Makeup' },
  { id: 'filter', label: 'Filter' },
  { id: 'sticker', label: 'Sticker' },
  { id: 'body', label: 'Body' },
  { id: 'virtual_bg', label: 'Virtual BG' },
  { id: 'chroma_key', label: 'Chroma Key' },
  { id: 'quality', label: 'Quality' },
  { id: 'face_detection', label: 'Face Detection' }
]

const functionConfigs = {
  beauty: [
    { key: 'white', label: 'Whitening', icon: 'meiyan', enabled: true, type: TYPE_SLIDER },
    { key: 'dark', label: 'Tanning', icon: 'huanfase', enabled: false, type: TYPE_SLIDER },
    { key: 'smooth', label: 'Smoothing', icon: 'meiyan', enabled: true, type: TYPE_SLIDER },
    { key: 'rosiness', label: 'Rosiness', icon: 'meiyan', enabled: true, type: TYPE_SLIDER }
  ],
  reshape: [
    { key: 'thin_face', label: 'Face Thin', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'v_face', label: 'V-Shape', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'narrow_face', label: 'Narrow Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'short_face', label: 'Short Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'cheekbone', label: 'Cheekbone', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'jawbone', label: 'Jawbone', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'chin', label: 'Chin', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'nose_slim', label: 'Nose Slim', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'big_eye', label: 'Big Eye', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'eye_distance', label: 'Eye Distance', icon: 'meixing2', enabled: true, type: TYPE_SLIDER }
  ],
  makeup: [
    { key: 'lipstick', label: 'Lipstick', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['Style 1', 'Style 2', 'Style 3'] },
    { key: 'blush', label: 'Blush', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['Style 1', 'Style 2', 'Style 3'] },
    { key: 'eyebrow', label: 'Eyebrow', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['Style 1', 'Style 2', 'Style 3'] },
    { key: 'eyeshadow', label: 'Eyeshadow', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['Style 1', 'Style 2', 'Style 3'] }
  ],
  filter: [
    { key: 'natural', label: 'Natural', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'fresh', label: 'Fresh', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'retro', label: 'Retro', icon: 'lvjing', enabled: true, type: TYPE_SLIDER },
    { key: 'bw', label: 'B&W', icon: 'lvjing', enabled: true, type: TYPE_SLIDER }
  ],
  sticker: [
    { key: 'cute', label: 'Cute', icon: 'tiezhi2', enabled: false, type: TYPE_SLIDER },
    { key: 'funny', label: 'Funny', icon: 'tiezhi2', enabled: false, type: TYPE_SLIDER }
  ],
  body: [
    { key: 'slim', label: 'Slim', icon: 'meiti', enabled: false, type: TYPE_SLIDER }
  ],
  virtual_bg: [
    { key: 'blur', label: 'Blur', icon: 'lvmukoutu', enabled: true, type: TYPE_TOGGLE },
    { key: 'preset', label: 'Preset', icon: 'xunibeijing', enabled: true, type: TYPE_TOGGLE },
    { key: 'image', label: 'Image', icon: 'gallery', enabled: true, type: TYPE_TOGGLE }
  ],
  chroma_key: [
    { key: 'key_color', label: 'Key Color', icon: 'color', enabled: true, type: TYPE_SLIDER, subOptions: ['Green', 'Blue', 'Red'] },
    { key: 'similarity', label: 'Similarity', icon: 'opacity', enabled: true, type: TYPE_SLIDER },
    { key: 'smoothness', label: 'Smoothness', icon: 'smooth', enabled: true, type: TYPE_SLIDER },
    { key: 'desaturation', label: 'Desaturation', icon: 'tuise', enabled: true, type: TYPE_SLIDER }
  ],
  quality: [
    { key: 'sharpen', label: 'Sharpen', icon: 'huazhitiaozheng2', enabled: false, type: TYPE_SLIDER }
  ],
  face_detection: [
    { key: 'enable', label: 'On/Off', icon: 'face-scan', enabled: true, type: TYPE_TOGGLE },
    { key: 'show_numbers', label: 'Show Numbers', icon: 'number', enabled: true, type: TYPE_TOGGLE }
  ]
}

/**
 * BeautyPanel Component
 * Control panel for adjusting beauty effect parameters
 * Communicates with parent component (BeautyPreview) which applies parameters to Facebetter engine
 * 
 * @param {string} currentTab - Current active tab (beauty, reshape, makeup, etc.)
 * @param {Function} onTabChanged - Callback when tab changes
 * @param {Function} onBeautyParamChanged - Callback when beauty parameter changes (calls Facebetter engine)
 * @param {Function} onResetBeauty - Callback to reset all beauty parameters
 * @param {Function} onHidePanel - Callback to hide the panel
 * @param {Function} onCapture - Callback to capture photo
 * @param {Function} onShowSlider - Callback to show parameter slider
 * @param {Function} onHideSlider - Callback to hide parameter slider
 * @param {Function} onResetTab - Callback to reset current tab parameters
 */
const BeautyPanel = forwardRef(({ currentTab, onTabChanged, onBeautyParamChanged, onResetBeauty, onHidePanel, onCapture, onShowSlider, onHideSlider, onResetTab }, ref) => {
  const [showSubOptions, setShowSubOptions] = useState(false)
  const [currentFunction, setCurrentFunction] = useState(null)
  const [currentSubOption, setCurrentSubOption] = useState(null)
  const [functionProgress, setFunctionProgress] = useState(new Map())
  const [toggleStates, setToggleStates] = useState(new Map())
  const [currentSubOptionsList, setCurrentSubOptionsList] = useState([])

  const currentFunctions = useMemo(() => {
    return functionConfigs[currentTab] || []
  }, [currentTab])

  // Expose methods to parent component via ref
  // Used for syncing slider values and toggle states with Facebetter engine state
  useImperativeHandle(ref, () => ({
    /**
     * Update slider value for a specific function
     * @param {string} tab - Tab ID
     * @param {string} functionKey - Function key
     * @param {number} value - Value (0-100)
     */
    updateSliderValue(tab, functionKey, value) {
      const key = `${tab}:${functionKey}`
      setFunctionProgress(prev => {
        const newMap = new Map(prev)
        newMap.set(key, value)
        return newMap
      })
    },
    /**
     * Get current slider value for a specific function
     * @param {string} tab - Tab ID
     * @param {string} functionKey - Function key
     * @returns {number} Current value (0-100)
     */
    getSliderValue(tab, functionKey) {
      const key = `${tab}:${functionKey}`
      return functionProgress.get(key) || 0
    },
    /**
     * Set toggle state for a specific function
     * @param {string} tab - Tab ID
     * @param {string} functionKey - Function key
     * @param {boolean} state - Toggle state
     */
    setToggleState(tab, functionKey, state) {
      const key = `${tab}:${functionKey}`
      setToggleStates(prev => {
        const newMap = new Map(prev)
        newMap.set(key, state)
        return newMap
      })
    }
  }))

  const switchTab = (tabId) => {
    setCurrentFunction(null)
    setCurrentSubOption(null)
    hideSubOptionsPanel()
    onTabChanged(tabId)
  }

  /**
   * Handle function button click
   * For slider types: shows slider or sub-options
   * For toggle types: toggles state and applies to Facebetter engine
   */
  const onFunctionClick = (func) => {
    if (!func.enabled) {
      alert(`${func.label} feature coming soon 😊`)
      return
    }

    setCurrentFunction(func.key)

    if (func.type === TYPE_TOGGLE) {
      handleToggleFunction(func)
    } else if (func.type === TYPE_SLIDER) {
      if (func.subOptions && func.subOptions.length > 0) {
        // Show sub-options (e.g., color selection for chroma key)
        setCurrentSubOptionsList(func.subOptions)
        showSubOptionsPanel()
        onHideSlider()
      } else {
        // Show slider for direct parameter adjustment
        hideSubOptionsPanel()
        onShowSlider({
          tab: currentTab,
          function: func.key,
          value: functionProgress.get(`${currentTab}:${func.key}`) || 0
        })
      }
    }
  }

  /**
   * Handle toggle function (on/off type)
   * Updates toggle state and applies to Facebetter engine via parent callback
   */
  const handleToggleFunction = (func) => {
    if (func.key === 'image' && currentTab === 'virtual_bg') {
      alert('Image selection feature coming soon')
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

    // Apply to Facebetter engine: 1.0 = on, 0.0 = off
    onBeautyParamChanged({
      tab: currentTab,
      function: func.key,
      value: newState ? 1.0 : 0.0
    })

    hideSubOptionsPanel()
    onHideSlider()
  }

  /**
   * Handle sub-option click (e.g., color selection for chroma key)
   * For chroma key color: directly applies to Facebetter engine
   * For other options: shows slider for further adjustment
   */
  const onSubOptionClick = (index, option) => {
    setCurrentSubOption(`style${index + 1}`)
    hideSubOptionsPanel()
    
    if (currentTab === 'chroma_key' && currentFunction === 'key_color') {
      // Chroma key color: green=0, blue=1, red=2
      // Map index to 0.0-1.0 range for Facebetter engine
      const colorValue = index
      const sliderValue = (colorValue / 2) * 100
      setFunctionProgress(prev => {
        const newMap = new Map(prev)
        newMap.set(`${currentTab}:${currentFunction}`, sliderValue)
        return newMap
      })
      
      // Apply directly to Facebetter engine
      onBeautyParamChanged({
        tab: currentTab,
        function: currentFunction,
        value: colorValue / 2.0
      })
      onHideSlider()
    } else {
      // Show slider for other sub-options
      onShowSlider({
        tab: currentTab,
        function: currentFunction,
        value: functionProgress.get(`${currentTab}:${currentFunction}`) || 0
      })
    }
  }

  const onBeautyOffClicked = () => {
    setCurrentFunction(null)
    hideSubOptionsPanel()
    onHideSlider()

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

    setToggleStates(prev => {
      const newMap = new Map(prev)
      for (const [key, value] of newMap.entries()) {
        if (key.startsWith(prefix) && value) {
          newMap.set(key, false)
          const functionKey = key.substring(prefix.length)
          onBeautyParamChanged({
            tab: currentTab,
            function: functionKey,
            value: 0.0
          })
        }
      }
      return newMap
    })

    onResetTab(currentTab)
  }

  const onResetBeautyClicked = () => {
    setCurrentFunction(null)
    hideSubOptionsPanel()
    onHideSlider()

    setFunctionProgress(new Map())
    setToggleStates(new Map())

    onResetBeauty()
  }

  const onHidePanelClicked = () => {
    hideSubOptionsPanel()
    onHideSlider()
    onHidePanel()
  }

  const showSubOptionsPanel = () => {
    setShowSubOptions(true)
  }

  const hideSubOptionsPanel = () => {
    setShowSubOptions(false)
  }

  const isFunctionSelected = (functionKey) => {
    return currentFunction === functionKey
  }

  const isToggleOn = (functionKey) => {
    const key = `${currentTab}:${functionKey}`
    return toggleStates.get(key) || false
  }

  const getFunctionIcon = (iconName) => {
    return `/icons/${iconName}.png`
  }

  const getSubOptionIcon = (option) => {
    return `/icons/${option}.png`
  }

  const isChromaKeyColorOption = (option) => {
    return currentTab === 'chroma_key' && currentFunction === 'key_color'
  }

  const getColorOptionBackground = (option) => {
    if (option === 'Green') return '#00FF00'
    if (option === 'Blue') return '#0000FF'
    if (option === 'Red') return '#FF0000'
    return '#CCCCCC'
  }

  return (
    <div className="beauty-panel-wrapper">
      <div className="beauty-panel">
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

        <div className="function-scroll-view">
          <div className="function-button-container">
            <div className="function-button" onClick={onBeautyOffClicked}>
              <div className="function-icon-wrap">
                <img src="/icons/close.png" alt="Close" className="function-icon" />
              </div>
              <div className="function-label">Close</div>
            </div>
            {currentFunctions.map(func => (
              <div
                key={func.key}
                className={`function-button ${!func.enabled ? 'disabled' : ''}`}
                onClick={() => onFunctionClick(func)}
              >
                <div 
                  className={`function-icon-wrap ${
                    func.type === TYPE_TOGGLE && isToggleOn(func.key) ? 'toggle-on' : ''
                  } ${
                    func.type === TYPE_TOGGLE && !isToggleOn(func.key) ? 'toggle-off' : ''
                  }`}
                >
                  <img src={getFunctionIcon(func.icon)} alt={func.label} className="function-icon" />
                  {!func.enabled && <div className="soon-badge">Soon</div>}
                </div>
                <div className="function-label">{func.label}</div>
                {(isFunctionSelected(func.key) || (func.type === TYPE_TOGGLE && isToggleOn(func.key))) && (
                  <div className="function-indicator"></div>
                )}
              </div>
            ))}
          </div>
        </div>

        {showSubOptions && (
          <div className="sub-option-scroll-view">
            <div className="sub-option-container">
              {currentSubOptionsList.map((option, index) => (
                <div
                  key={index}
                  className="sub-option-button"
                  onClick={() => onSubOptionClick(index, option)}
                >
                  {isChromaKeyColorOption(option) ? (
                    <div 
                      className="sub-option-icon-wrap"
                      style={{ background: getColorOptionBackground(option) }}
                    ></div>
                  ) : (
                    <div className="sub-option-icon-wrap">
                      <img src={getSubOptionIcon(option)} alt="" className="sub-option-icon" />
                    </div>
                  )}
                  <div className="sub-option-label">{option}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="bottom-button-container">
          <div className="bottom-button" onClick={onResetBeautyClicked}>
            <img src="/icons/reset.png" alt="Reset" className="bottom-button-icon" />
            <span className="bottom-button-text">Reset</span>
          </div>
          <div className="bottom-button-center">
            <button className="capture-btn-panel" onClick={onCapture}>
              <div className="capture-inner-panel"></div>
            </button>
          </div>
          <div className="bottom-button" onClick={onHidePanelClicked}>
            <img src="/icons/menu.png" alt="Hide" className="bottom-button-icon" />
            <span className="bottom-button-text">Hide</span>
          </div>
        </div>
      </div>
    </div>
  )
})

BeautyPanel.displayName = 'BeautyPanel'

export default BeautyPanel
