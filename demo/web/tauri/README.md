# Facebetter Demo - Tauri 桌面版

本目录是 **Tauri 壳**，仅负责用原生窗口加载 [../react](../react) 的构建产物，不包含任何业务逻辑。  
React 参考 Demo 保持在 `demo/web/react`，开发人员查看 Demo 时不受影响。

## 目录关系

```
demo/web/
├── react/          # React 参考 Demo（纯前端，开发用）
│   ├── src/
│   ├── package.json
│   └── ...
└── tauri/          # Tauri 桌面壳（本目录）
    ├── src-tauri/  # Rust 与配置
    └── package.json
```

- **开发 / 构建前端**：在 `demo/web/react` 中 `npm run dev` / `npm run build`。
- **开发 / 构建桌面版**：在 `demo/web/tauri` 中执行下方命令，Tauri 会自动先跑 React 的 dev/build。

## 环境要求

- Node.js（与 react 一致）
- [Rust](https://www.rust-lang.org/tools/install)
- 各平台 WebView：Windows 用 WebView2，macOS/Linux 用系统 WebView

## 使用方式

### 安装依赖

在 **本目录** `demo/web/tauri` 下执行：

```bash
npm install
```

（React 依赖在 `../react`，需在 `../react` 下单独 `npm install`。）

### 开发模式

```bash
npm run dev
```

- Tauri 会先执行 `beforeDevCommand`：在 `../react` 下执行 `npm run dev`（启动 Vite 开发服务器）。
- 然后打开桌面窗口，加载 `http://localhost:5173`（Vite 默认端口）。

### 构建桌面应用

```bash
npm run build
```

- Tauri 会先执行 `beforeBuildCommand`：在 `../react` 下执行 `npm run build`，生成 `../react/dist`。
- 再将 `../react/dist` 作为前端资源打包进桌面应用，输出到 `src-tauri/target/release/` 或 bundle 目录。

## 配置说明

- **前端产物路径**：`src-tauri/tauri.conf.json` 中 `build.frontendDist` 指向 `../../react/dist`（相对配置文件）。
- **开发地址**：`build.devUrl` 为 `http://localhost:5173`，需与 React 的 Vite 端口一致。
- **前置命令**：`beforeDevCommand` / `beforeBuildCommand` 的 `cwd` 为 `../../react`，在 React 目录下执行 `npm run dev` / `npm run build`。

如需改窗口大小、应用名等，只需改 `src-tauri/tauri.conf.json` 中的 `app.windows` 和 `productName` 等字段。
