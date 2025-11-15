<template>
  <div class="home-container">
    <!-- 顶部渐变背景区域 -->
    <div class="header-section">
      <div class="header-gradient">
        <img src="/icons/header.png" alt="Header" class="header-image" />
        <button class="settings-btn" @click="showSettings">
          <img src="/icons/setting.png" alt="设置" class="icon-white" />
        </button>
      </div>
    </div>

    <!-- 滚动内容区域 -->
    <div class="scroll-content">
      <!-- 两个大按钮（一半压住顶部图片，一半压住白色区域） -->
      <div class="primary-buttons">
        <button class="btn-primary btn-beauty-effect" @click="navigateToCamera(null)">
          <img src="/icons/camera2.png" alt="美颜特效" class="btn-icon" />
          <span>美颜特效</span>
        </button>
        <button class="btn-primary btn-beauty-template" @click="showComingSoon('美颜模板')">
          <img src="/icons/beautycard3.png" alt="美颜模板" class="btn-icon" />
          <span>美颜模板</span>
        </button>
      </div>
      
      <!-- 统一的白色容器（包含功能网格和原子能力，顶部圆角，压住背景图片） -->
      <div class="white-content-container">
        <!-- 功能网格 -->
        <div class="feature-grid">
          <!-- 第1行 -->
          <div class="feature-item" @click="navigateToCamera('beauty')">
            <img src="/icons/meiyan.png" alt="美颜" class="feature-icon" />
            <div class="feature-label">美颜</div>
          </div>
          <div class="feature-item" @click="navigateToCamera('reshape')">
            <img src="/icons/meixing2.png" alt="美型" class="feature-icon" />
            <div class="feature-label">美型</div>
          </div>
          <div class="feature-item" @click="navigateToCamera('makeup')">
            <img src="/icons/meizhuang.png" alt="美妆" class="feature-icon" />
            <div class="feature-label">美妆</div>
          </div>
          <div class="feature-item disabled" @click="showComingSoon('美体')">
            <img src="/icons/meiti.png" alt="美体" class="feature-icon" />
            <div class="feature-label">美体</div>
            <span class="soon-badge">Soon</span>
          </div>

          <!-- 第2行 -->
          <div class="feature-item disabled" @click="showComingSoon('滤镜')">
            <img src="/icons/lvjing.png" alt="滤镜" class="feature-icon" />
            <div class="feature-label">滤镜</div>
            <span class="soon-badge">Soon</span>
          </div>
          <div class="feature-item disabled" @click="showComingSoon('贴纸')">
            <img src="/icons/tiezhi2.png" alt="贴纸" class="feature-icon" />
            <div class="feature-label">贴纸</div>
            <span class="soon-badge">Soon</span>
          </div>
          <div class="feature-item" @click="navigateToCamera('virtual_bg')">
            <img src="/icons/xunibeijing.png" alt="虚拟背景" class="feature-icon" />
            <div class="feature-label">虚拟背景</div>
          </div>
          <div class="feature-item disabled" @click="showComingSoon('画质调整')">
            <img src="/icons/huazhitiaozheng2.png" alt="画质调整" class="feature-icon" />
            <div class="feature-label">画质调整</div>
            <span class="soon-badge">Soon</span>
          </div>
        </div>

        <!-- 原子能力区域 -->
        <div class="atomic-capabilities-section">
          <h2 class="section-title">原子能力</h2>
          <div class="atomic-grid">
            <div class="feature-item disabled" @click="showComingSoon('换发色')">
              <img src="/icons/huanfase.png" alt="换发色" class="feature-icon" />
              <div class="feature-label">换发色</div>
              <span class="soon-badge">Soon</span>
            </div>
            <div class="feature-item disabled" @click="showComingSoon('风格整装')">
              <img src="/icons/fengge.png" alt="风格整装" class="feature-icon" />
              <div class="feature-label">风格整装</div>
              <span class="soon-badge">Soon</span>
            </div>
            <div class="feature-item" @click="showComingSoon('人脸检测')">
              <img src="/icons/renlianjiance.png" alt="人脸检测" class="feature-icon" />
              <div class="feature-label">人脸检测</div>
            </div>
            <div class="feature-item disabled" @click="showComingSoon('手势检测')">
              <img src="/icons/shoushi.png" alt="手势检测" class="feature-icon" />
              <div class="feature-label">手势检测</div>
              <span class="soon-badge">Soon</span>
            </div>
            <div class="feature-item disabled" @click="showComingSoon('绿幕抠图')">
              <img src="/icons/lvmukoutu.png" alt="绿幕抠图" class="feature-icon" />
              <div class="feature-label">绿幕抠图</div>
              <span class="soon-badge">Soon</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const navigateToCamera = (tab) => {
  if (tab) {
    router.push({ path: '/camera', query: { tab } })
  } else {
    router.push('/camera')
  }
}

const showComingSoon = (feature) => {
  alert(`${feature}功能开发中，敬请期待 🎨`)
}

const showSettings = () => {
  alert('设置功能开发中，敬请期待 ⚙️')
}
</script>

<style scoped>
.home-container {
  width: 100%;
  max-width: 1200px;
  min-height: 100vh;
  background: #f0f0f0; /* 浅灰色背景，与白色容器区分 */
  overflow-y: auto;
  position: relative;
  margin: 0 auto;
}

/* 顶部渐变背景区域 */
.header-section {
  position: fixed;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  max-width: 1200px;
  height: 250px;
  z-index: 1;
  pointer-events: none;
}

.header-section .settings-btn {
  pointer-events: auto;
}

.header-gradient {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
}

.header-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  position: absolute;
  top: 0;
  left: 0;
}

.icon-white {
  filter: brightness(0) invert(1);
  width: 20px;
  height: 20px;
}

.settings-btn {
  position: absolute;
  top: 40px;
  right: 20px;
  width: 28px;
  height: 28px;
  background: transparent;
  border: none;
  cursor: pointer;
  z-index: 3;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 滚动内容区域 */
.scroll-content {
  padding: 0 0 40px 0;
  margin-top: 215px;
  position: relative;
  z-index: 2;
  max-width: 1200px;
  margin-left: auto;
  margin-right: auto;
}

/* 两个大按钮 */
.primary-buttons {
  display: flex;
  gap: 8px;
  padding: 0 20px;
  margin-top: -35px;
  margin-bottom: -35px;
  position: relative;
  z-index: 20;
  /* 移除 box-shadow，避免阴影影响白色容器的视觉效果 */
  /* box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); */
  pointer-events: auto;
  /* 确保按钮容器本身没有背景色，避免影响下面的白色容器 */
  background: transparent;
  max-width: 600px; /* 限制主按钮容器最大宽度 */
  margin-left: auto;
  margin-right: auto;
}

/* 响应式设计：根据屏幕宽度调整主按钮宽度 */
@media (min-width: 768px) {
  .primary-buttons {
    max-width: 600px;
  }
}

@media (min-width: 1024px) {
  .primary-buttons {
    max-width: 600px;
  }
}

@media (min-width: 1280px) {
  .primary-buttons {
    max-width: 600px;
  }
}

/* 统一的白色容器（包含功能网格和原子能力，顶部圆角，压住背景图片） */
.white-content-container {
  background: #ffffff;
  border-radius: 24px 24px 0 0;
  padding: 24px 12px 24px;
  padding-top: 60px; /* 增加顶部内边距，为主按钮留出空间 */
  margin-top: -35px;
  margin-bottom: 0;
  position: relative;
  z-index: 1;
  overflow: hidden;
  /* 确保白色容器延伸到底部，覆盖灰色背景 */
  min-height: calc(100vh - 215px);
}

.btn-primary {
  flex: 1;
  height: 72px;
  border-radius: 12px;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  font-size: 18px;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s, opacity 0.2s;
}

.btn-icon {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.btn-primary:active {
  transform: scale(0.98);
}

.btn-beauty-effect {
  background: #424242;
  color: white;
}

.btn-beauty-effect .btn-icon {
  filter: brightness(0) saturate(100%) invert(63%) sepia(95%) saturate(427%) hue-rotate(70deg) brightness(98%) contrast(88%);
}

.btn-beauty-template {
  background: linear-gradient(135deg, #a0f196 0%, #d4fc79 100%);
  color: black;
}

.btn-beauty-template .btn-icon {
  filter: brightness(0);
}


.feature-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  margin-top: 40px; /* 向下移动，与主按钮保持距离 */
  margin-bottom: 12px;
  padding: 0 12px;
}

/* 响应式设计：根据屏幕宽度调整按钮数量和间距 */
@media (min-width: 640px) {
  .feature-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 8px;
    padding: 0 16px;
  }
}

@media (min-width: 768px) {
  .feature-grid {
    grid-template-columns: repeat(6, 1fr);
    gap: 10px;
    padding: 0 20px;
  }
}

@media (min-width: 1024px) {
  .feature-grid {
    grid-template-columns: repeat(7, 1fr);
    gap: 12px;
    padding: 0 24px;
  }
}

@media (min-width: 1280px) {
  .feature-grid {
    grid-template-columns: repeat(8, 1fr);
    gap: 16px;
    padding: 0 32px;
  }
}

.feature-item {
  aspect-ratio: 1;
  background: #f5f5f5;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 8px;
  cursor: pointer;
  transition: background 0.2s;
  position: relative;
}

.feature-item:not(.disabled):active {
  background: #e0e0e0;
}

.feature-item.disabled {
  opacity: 0.5;
}

.feature-icon {
  width: 22px;
  height: 22px;
  object-fit: contain;
  margin-bottom: 4px;
  filter: brightness(0) saturate(100%) invert(26%) sepia(0%) saturate(0%) hue-rotate(0deg) brightness(96%) contrast(89%);
}

.feature-item.disabled .feature-icon {
  opacity: 0.5;
}

.feature-label {
  font-size: 12px;
  color: #757575;
  text-align: center;
}

.soon-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #ff9800;
  color: white;
  font-size: 9px;
  padding: 2px 4px;
  border-radius: 4px;
  font-weight: bold;
}

/* 原子能力区域（在白色容器内，共享背景，确保没有独立背景） */
.atomic-capabilities-section {
  padding: 8px 16px 24px;
  margin-top: 0;
  background: transparent;
}

.section-title {
  font-size: 18px;
  font-weight: bold;
  color: #424242;
  margin-bottom: 16px;
}

.atomic-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
}

/* 响应式设计：根据屏幕宽度调整原子能力按钮数量和间距 */
@media (min-width: 640px) {
  .atomic-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 8px;
  }
}

@media (min-width: 768px) {
  .atomic-grid {
    grid-template-columns: repeat(6, 1fr);
    gap: 10px;
  }
}

@media (min-width: 1024px) {
  .atomic-grid {
    grid-template-columns: repeat(7, 1fr);
    gap: 12px;
  }
}

@media (min-width: 1280px) {
  .atomic-grid {
    grid-template-columns: repeat(8, 1fr);
    gap: 16px;
  }
}
</style>

