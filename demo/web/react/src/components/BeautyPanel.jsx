import React, { useState, useMemo, useImperativeHandle, forwardRef, useEffect } from 'react'
import './BeautyPanel.css'

// Function types
const TYPE_SLIDER = 0  // Slider-based parameter (0-100)
const TYPE_TOGGLE = 1  // Toggle-based parameter (on/off)

// Tabs aligned with Mac demo (beauty, reshape, makeup, filter, sticker, body, virtual_bg, quality)
const tabs = [
  { id: 'beauty', label: 'Beauty' },
  { id: 'reshape', label: 'Reshape' },
  { id: 'makeup', label: 'Makeup' },
  { id: 'filter', label: 'Filter' },
  { id: 'sticker', label: 'Sticker' },
  { id: 'body', label: 'Body' },
  { id: 'virtual_bg', label: 'Virtual BG' },
  { id: 'quality', label: 'Quality' }
]

// Filter keys order and labels (en) aligned with Mac demo filter_mapping
const FILTER_KEYS = [
  'initial_heart', 'first_love', 'vivid', 'confession', 'milk_tea', 'mousse',
  'japanese', 'dawn', 'cookie', 'lively', 'pure', 'fair', 'snow', 'plain',
  'natural', 'rose', 'tender', 'tender_2', 'extraordinary'
]
const FILTER_LABELS_EN = {
  initial_heart: 'initial_heart', first_love: 'first_love', vivid: 'vivid',
  confession: 'confession', milk_tea: 'milk_tea', mousse: 'mousse',
  japanese: 'japanese', dawn: 'dawn', cookie: 'cookie', lively: 'lively',
  pure: 'pure', fair: 'fair', snow: 'snow', plain: 'plain', natural: 'natural',
  rose: 'rose', tender: 'tender', tender_2: 'tender_2', extraordinary: 'extraordinary'
}

const functionConfigs = {
  beauty: [
    { key: 'white', label: 'Whitening', icon: 'meiyan', enabled: true, type: TYPE_SLIDER },
    { key: 'smooth', label: 'Smoothing', icon: 'meiyan2', enabled: true, type: TYPE_SLIDER },
    { key: 'rosiness', label: 'Rosiness', icon: 'meiyan', enabled: true, type: TYPE_SLIDER }
  ],
  reshape: [
    { key: 'thin_face', label: 'Thin Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'v_face', label: 'V-Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'narrow_face', label: 'Narrow Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'short_face', label: 'Short Face', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'cheekbone', label: 'Cheekbone', icon: 'meixing2', enabled: true, type: TYPE_SLIDER },
    { key: 'jawbone', label: 'Jawbone', icon: 'jawbone', enabled: true, type: TYPE_SLIDER },
    { key: 'chin', label: 'Chin', icon: 'chin', enabled: true, type: TYPE_SLIDER },
    { key: 'nose_slim', label: 'Nose', icon: 'nose', enabled: true, type: TYPE_SLIDER },
    { key: 'big_eye', label: 'Big Eye', icon: 'eyes', enabled: true, type: TYPE_SLIDER },
    { key: 'eye_distance', label: 'Eye Distance', icon: 'eyes', enabled: true, type: TYPE_SLIDER }
  ],
  makeup: [
    { key: 'lipstick', label: 'Lipstick', icon: 'lipstick', enabled: true, type: TYPE_SLIDER, subOptions: ['Moist', 'Vitality', 'Retro'] },
    { key: 'blush', label: 'Blush', icon: 'meizhuang', enabled: true, type: TYPE_SLIDER, subOptions: ['Japanese', 'Sector', 'Tipsy'] },
    { key: 'eyebrow', label: 'Eyebrow', icon: 'eyebrow', enabled: true, type: TYPE_SLIDER },
    { key: 'eyeshadow', label: 'Eyeshadow', icon: 'eyeshadow', enabled: true, type: TYPE_SLIDER }
  ],
  filter: FILTER_KEYS.map(key => ({
    key,
    label: FILTER_LABELS_EN[key] || key,
    icon: 'lvjing',
    enabled: true,
    type: TYPE_SLIDER
  })),
  sticker: [
    { key: 'rabbit', label: 'Rabbit', icon: 'rabbit', enabled: true, type: TYPE_SLIDER }
  ],
  body: [
    { key: 'slim', label: 'Slim', icon: 'meiti', enabled: true, type: TYPE_SLIDER }
  ],
  virtual_bg: [
    { key: 'blur', label: 'Blur', icon: 'blur', enabled: true, type: TYPE_TOGGLE },
    { key: 'preset', label: 'Virtual BG Image', icon: 'back_preset', enabled: true, type: TYPE_TOGGLE }
  ],
  quality: [
    { key: 'sharpen', label: 'Sharpen', icon: 'huazhitiaozheng2', enabled: true, type: TYPE_SLIDER }
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
 * @param {Function} onShowSlider - Callback to show parameter slider
 * @param {Function} onHideSlider - Callback to hide parameter slider
 * @param {Function} onResetTab - Callback to reset current tab parameters
 */
const BeautyPanel = forwardRef(({ currentTab, onTabChanged, onBeautyParamChanged, onShowSlider, onHideSlider, onResetTab }, ref) => {
  const [showSubOptions, setShowSubOptions] = useState(false)
  const [currentFunction, setCurrentFunction] = useState(null)
  const [currentSubOption, setCurrentSubOption] = useState(null)
  const [currentSubOptionIcon, setCurrentSubOptionIcon] = useState('meizhuang')
  const [functionProgress, setFunctionProgress] = useState(new Map())
  const [toggleStates, setToggleStates] = useState(new Map())
  const [currentSubOptionsList, setCurrentSubOptionsList] = useState([])
  const [filterLabels, setFilterLabels] = useState(null)

  const currentFunctions = useMemo(() => {
    if (currentTab === 'filter') {
      return FILTER_KEYS.map(key => ({
        key,
        label: (filterLabels && filterLabels[key]) || FILTER_LABELS_EN[key] || key,
        icon: 'lvjing',
        enabled: true,
        type: TYPE_SLIDER
      }))
    }
    return functionConfigs[currentTab] || []
  }, [currentTab, filterLabels])

  useEffect(() => {
    fetch('/filter_mapping.json')
      .then(res => res.ok ? res.json() : null)
      .then(data => {
        if (data?.filters) {
          const lang = (navigator.language || '').startsWith('zh') ? 'zh' : 'en'
          const labels = {}
          for (const [key, val] of Object.entries(data.filters)) {
            labels[key] = (val && val[lang]) ? val[lang] : (val?.en || key)
          }
          setFilterLabels(labels)
        }
      })
      .catch(() => {})
  }, [])

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
        setCurrentSubOptionsList(func.subOptions)
        setCurrentSubOptionIcon(func.icon || 'meizhuang')
        showSubOptionsPanel()
        onHideSlider()
      } else {
        // Show slider for direct parameter adjustment
        hideSubOptionsPanel()
        onShowSlider({
          tab: currentTab,
          function: func.key,
          value: functionProgress.get(`${currentTab}:${func.key}`) ?? (currentTab === 'filter' ? 80 : currentTab === 'sticker' ? 100 : 0)
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
   * Handle sub-option click (e.g., makeup style)
   * Shows slider for further adjustment
   */
  const onSubOptionClick = (index, option) => {
    setCurrentSubOption(`style${index + 1}`)
    hideSubOptionsPanel()
    onShowSlider({
      tab: currentTab,
      function: currentFunction,
      value: functionProgress.get(`${currentTab}:${currentFunction}`) ?? (currentTab === 'filter' ? 80 : currentTab === 'sticker' ? 100 : 0)
    })
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
    return `/icons/${currentSubOptionIcon}.png`
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
                  <div className="sub-option-icon-wrap">
                    <img src={getSubOptionIcon(option)} alt="" className="sub-option-icon" />
                  </div>
                  <div className="sub-option-label">{option}</div>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>
    </div>
  )
})

BeautyPanel.displayName = 'BeautyPanel'

export default BeautyPanel
