# Facebetter Web Demo

React 相机 / 修图示例。通过 **npm** 安装 `facebetter` **2.0.0**。

```bash
cd demo/web/react
npm install
npm run dev
```

浏览器打开 `http://localhost:5175/`。默认按系统语言显示中文或英文，可在顶栏切换。

## 授权

Web 端不要把 AppKey 放进浏览器。开发时由本地 `/api/fb-auth` 代为请求鉴权；请在[控制台](https://facebetter.net)创建应用，并把 AppID / AppKey 配到环境变量 `FB_APP_ID` / `FB_APP_KEY`，或写进 `api/fb-auth.js`。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。

## 部署

`npm run build` 生成 `dist/`。按 [Web 文档](https://facebetter.net/docs/web/quick-start) 把静态资源和你自己的鉴权接口部署到服务器。本目录的 `vercel.json` 仅作一种托管示例。
