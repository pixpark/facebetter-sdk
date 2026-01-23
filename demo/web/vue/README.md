# Facebetter Vue Demo

基于 Vue 3 的美颜相机应用，集成了 Facebetter Web SDK。

## 功能特性

- 🏠 **主页**：功能入口页面，包含美颜特效、美型、美妆等功能入口
- 📷 **美颜预览**：实时相机美颜预览和图片美颜处理，支持多种美颜参数调节
- ✨ **美颜效果**：支持磨皮、美白、红润、瘦脸等美颜效果
- 📸 **拍照保存**：支持拍照并保存处理后的照片

## 项目结构

```
demo/web/vue/
├── public/                  # 静态资源文件
├── src/
│   ├── views/
│   │   ├── Home.vue         # 主页组件
│   │   └── BeautyPreview.vue  # 美颜预览页组件（支持相机和图片）
│   ├── components/
│   │   └── BeautyPanel.vue  # 美颜面板组件
│   ├── router/
│   │   └── index.js        # 路由配置
│   ├── App.vue
│   └── main.js
├── package.json
└── vite.config.js
```

## 安装和运行

### 安装依赖

```bash
npm install
```

**注意**：Facebetter SDK 已通过 npm 安装。安装 `facebetter` 时会自动安装 `facebetter-core` 依赖，无需手动配置。

### 开发模式

```bash
npm run dev
```

应用将在 `http://localhost:5173` 启动。

### 构建生产版本

```bash
npm run build
```

## 使用说明

### 主页

- 点击"美颜特效"按钮进入美颜预览页
- 点击功能网格中的功能按钮（如"美颜"、"美型"等）进入对应的美颜预览页
- 标记为 "Soon" 的功能正在开发中

### 美颜预览页

- **顶部控制栏**：
  - 返回按钮：返回主页
  - 相册按钮：打开相册选择图片进行美颜处理
  - 切换摄像头：切换前后摄像头（仅移动设备）
  - 更多选项：更多功能（开发中）

- **美颜参数调节**：
  - 点击底部中间的美颜按钮打开/关闭美颜面板
  - 在美颜面板中可以调节磨皮、美白、红润、瘦脸等参数

- **拍照/保存**：
  - 点击底部中间的圆形拍照按钮
  - 处理后的照片会自动下载（相机模式或图片模式）

## 技术栈

- Vue 3 (Composition API)
- Vue Router 4
- Facebetter Web SDK v1.0.10 (通过 npm 安装，自动包含 facebetter-core)
- Vite

## 注意事项

1. **浏览器兼容性**：需要支持 WebAssembly 的现代浏览器（Chrome 57+, Firefox 52+, Safari 11+, Edge 16+）
2. **HTTPS 要求**：相机访问需要 HTTPS 环境（localhost 除外）
3. **性能优化**：已实现 canvas 和 ImageData 复用，提升视频处理性能
4. **SDK 安装**：Facebetter SDK 通过 npm 自动安装。`facebetter` 包会自动安装 `facebetter-core` 依赖，无需手动配置

## 开发计划

- [x] 实现前后对比功能
- [x] 实现相册选择功能
- [x] 实现更多美颜参数（美型、美妆等）
- [x] 实现虚拟背景功能
- [ ] 优化移动端体验
