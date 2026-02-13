import React from 'react'
import { useNavigate } from 'react-router-dom'
import './Home.css'

/**
 * Home Component
 * Main landing page with feature grid and navigation to beauty preview
 */
function Home() {
  const navigate = useNavigate()

  /**
   * Navigate to camera/preview page
   * @param {string|null} tab - Optional tab to open (beauty, reshape, makeup, virtual_bg, etc.)
   */
  const navigateToCamera = (tab) => {
    if (tab) {
      navigate(`/camera?tab=${tab}`)
    } else {
      navigate('/camera')
    }
  }

  const showComingSoon = (feature) => {
    alert(`${feature} feature coming soon 🎨`)
  }

  const showSettings = () => {
    alert('Settings feature coming soon ⚙️')
  }

  return (
    <div className="home-container">
      <div className="header-section">
        <div className="header-gradient">
          <img src="/icons/header.png" alt="Header" className="header-image" />
          <button className="settings-btn" onClick={showSettings}>
            <img src="/icons/setting.png" alt="Settings" className="icon-white" />
          </button>
        </div>
      </div>

      <div className="scroll-content">
        <div className="primary-buttons">
          <button className="btn-primary btn-beauty-effect" onClick={() => navigateToCamera(null)}>
            <img src="/icons/camera2.png" alt="Beauty Effect" className="btn-icon" />
            <span>Beauty Effect</span>
          </button>
          <button className="btn-primary btn-beauty-template" onClick={() => showComingSoon('Beauty Template')}>
            <img src="/icons/beautycard3.png" alt="Beauty Template" className="btn-icon" />
            <span>Beauty Template</span>
          </button>
        </div>
        
        <div className="white-content-container">
          <div className="feature-grid">
            <div className="feature-item" onClick={() => navigateToCamera('beauty')}>
              <img src="/icons/meiyan.png" alt="Beauty" className="feature-icon" />
              <div className="feature-label">Beauty</div>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('reshape')}>
              <img src="/icons/meixing2.png" alt="Reshape" className="feature-icon" />
              <div className="feature-label">Reshape</div>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('makeup')}>
              <img src="/icons/meizhuang.png" alt="Makeup" className="feature-icon" />
              <div className="feature-label">Makeup</div>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('Body')}>
              <img src="/icons/meiti.png" alt="Body" className="feature-icon" />
              <div className="feature-label">Body</div>
              <span className="soon-badge">Soon</span>
            </div>

            <div className="feature-item disabled" onClick={() => showComingSoon('Filter')}>
              <img src="/icons/lvjing.png" alt="Filter" className="feature-icon" />
              <div className="feature-label">Filter</div>
              <span className="soon-badge">Soon</span>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('Sticker')}>
              <img src="/icons/tiezhi2.png" alt="Sticker" className="feature-icon" />
              <div className="feature-label">Sticker</div>
              <span className="soon-badge">Soon</span>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('virtual_bg')}>
              <img src="/icons/xunibeijing.png" alt="Virtual Background" className="feature-icon" />
              <div className="feature-label">Virtual BG</div>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('Quality')}>
              <img src="/icons/huazhitiaozheng2.png" alt="Quality" className="feature-icon" />
              <div className="feature-label">Quality</div>
              <span className="soon-badge">Soon</span>
            </div>
          </div>

          <div className="atomic-capabilities-section">
            <h2 className="section-title">More effect</h2>
            <div className="atomic-grid">
              <div className="feature-item disabled" onClick={() => showComingSoon('Hair Color')}>
                <img src="/icons/huanfase.png" alt="Hair Color" className="feature-icon" />
                <div className="feature-label">Hair Color</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('Style')}>
                <img src="/icons/fengge.png" alt="Style" className="feature-icon" />
                <div className="feature-label">Style</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item" onClick={() => showComingSoon('Face Detection')}>
                <img src="/icons/renlianjiance.png" alt="Face Detection" className="feature-icon" />
                <div className="feature-label">Face Detection</div>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('Hand Detection')}>
                <img src="/icons/shoushi.png" alt="Hand Detection" className="feature-icon" />
                <div className="feature-label">Hand Detection</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('Chroma Key')}>
                <img src="/icons/lvmukoutu.png" alt="Chroma Key" className="feature-icon" />
                <div className="feature-label">Chroma Key</div>
                <span className="soon-badge">Soon</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Home
