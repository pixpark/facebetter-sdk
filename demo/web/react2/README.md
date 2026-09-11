# FaceBetter Studio

FaceBetter Studio（`demo/web/react2`），按 `stitch_ai_ui` 设计稿实现。默认根据系统语言显示中文或英文，可在顶栏右侧手动切换。

```bash
cd demo/web/react2
npm install
npm run dev
```

浏览器打开 `http://localhost:5175/`。本地联调依赖并列引擎仓：`../fb/src/engine/web/facebetter` 与 `facebetter-core`。

本地开发时，`POST /api/fb-auth` 由 Vite 插件 `demo/web/fb-auth-proxy.js` 代签。

## 部署到 Vercel

本机 `vite build` 后执行 `vercel deploy --prod`。上传的是 `dist/` 和 `api/`，不上传 `package.json`（避免云端再 `npm install` 本地 `file:` SDK）。

项目已在第一次部署时关联过（`.vercel`），之后：

```bash
cd demo/web/react2
npm run build
vercel deploy --prod
```

或 `npm run deploy`。

若控制台仍按 Vite 去装依赖：Vercel 项目 Settings → General → Framework Preset 改成 **Other**。
