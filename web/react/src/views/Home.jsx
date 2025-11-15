import { useNavigate } from 'react-router-dom'
import './Home.css'

function Home() {
  const navigate = useNavigate()

  const navigateToCamera = (tab) => {
    if (tab) {
      navigate(`/camera?tab=${tab}`)
    } else {
      navigate('/camera')
    }
  }

  const showComingSoon = (feature) => {
    alert(`${feature}功能开发中，敬请期待 🎨`)
  }

  const showSettings = () => {
    alert('设置功能开发中，敬请期待 ⚙️')
  }

  return (
    <div className="home-container">
      {/* 顶部渐变背景区域 */}
      <div className="header-section">
        <div className="header-gradient">
          <img src="/icons/header.png" alt="Header" className="header-image" />
          <button className="settings-btn" onClick={showSettings}>
            <img src="/icons/setting.png" alt="设置" className="icon-white" />
          </button>
        </div>
      </div>

      {/* 滚动内容区域 */}
      <div className="scroll-content">
        {/* 两个大按钮（一半压住顶部图片，一半压住白色区域） */}
        <div className="primary-buttons">
          <button className="btn-primary btn-beauty-effect" onClick={() => navigateToCamera(null)}>
            <img src="/icons/camera2.png" alt="美颜特效" className="btn-icon" />
            <span>美颜特效</span>
          </button>
          <button className="btn-primary btn-beauty-template" onClick={() => showComingSoon('美颜模板')}>
            <img src="/icons/beautycard3.png" alt="美颜模板" className="btn-icon" />
            <span>美颜模板</span>
          </button>
        </div>
        
        {/* 统一的白色容器（包含功能网格和原子能力，顶部圆角，压住背景图片） */}
        <div className="white-content-container">
          {/* 功能网格 */}
          <div className="feature-grid">
            {/* 第1行 */}
            <div className="feature-item" onClick={() => navigateToCamera('beauty')}>
              <img src="/icons/meiyan.png" alt="美颜" className="feature-icon" />
              <div className="feature-label">美颜</div>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('reshape')}>
              <img src="/icons/meixing2.png" alt="美型" className="feature-icon" />
              <div className="feature-label">美型</div>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('makeup')}>
              <img src="/icons/meizhuang.png" alt="美妆" className="feature-icon" />
              <div className="feature-label">美妆</div>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('美体')}>
              <img src="/icons/meiti.png" alt="美体" className="feature-icon" />
              <div className="feature-label">美体</div>
              <span className="soon-badge">Soon</span>
            </div>

            {/* 第2行 */}
            <div className="feature-item disabled" onClick={() => showComingSoon('滤镜')}>
              <img src="/icons/lvjing.png" alt="滤镜" className="feature-icon" />
              <div className="feature-label">滤镜</div>
              <span className="soon-badge">Soon</span>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('贴纸')}>
              <img src="/icons/tiezhi2.png" alt="贴纸" className="feature-icon" />
              <div className="feature-label">贴纸</div>
              <span className="soon-badge">Soon</span>
            </div>
            <div className="feature-item" onClick={() => navigateToCamera('virtual_bg')}>
              <img src="/icons/xunibeijing.png" alt="虚拟背景" className="feature-icon" />
              <div className="feature-label">虚拟背景</div>
            </div>
            <div className="feature-item disabled" onClick={() => showComingSoon('画质调整')}>
              <img src="/icons/huazhitiaozheng2.png" alt="画质调整" className="feature-icon" />
              <div className="feature-label">画质调整</div>
              <span className="soon-badge">Soon</span>
            </div>
          </div>

          {/* 原子能力区域 */}
          <div className="atomic-capabilities-section">
            <h2 className="section-title">原子能力</h2>
            <div className="atomic-grid">
              <div className="feature-item disabled" onClick={() => showComingSoon('换发色')}>
                <img src="/icons/huanfase.png" alt="换发色" className="feature-icon" />
                <div className="feature-label">换发色</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('风格整装')}>
                <img src="/icons/fengge.png" alt="风格整装" className="feature-icon" />
                <div className="feature-label">风格整装</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item" onClick={() => showComingSoon('人脸检测')}>
                <img src="/icons/renlianjiance.png" alt="人脸检测" className="feature-icon" />
                <div className="feature-label">人脸检测</div>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('手势检测')}>
                <img src="/icons/shoushi.png" alt="手势检测" className="feature-icon" />
                <div className="feature-label">手势检测</div>
                <span className="soon-badge">Soon</span>
              </div>
              <div className="feature-item disabled" onClick={() => showComingSoon('绿幕抠图')}>
                <img src="/icons/lvmukoutu.png" alt="绿幕抠图" className="feature-icon" />
                <div className="feature-label">绿幕抠图</div>
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

