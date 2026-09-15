# Facebetter Web Demo

React 相机 / 修图示例。通过 **npm** 安装 `facebetter` **2.0.1**。

```bash
cd demo/web/react
npm install
npm run dev
```

浏览器打开 `http://localhost:5175/`。默认按系统语言显示中文或英文，可在顶栏切换。

## 授权

页面只请求自家代理，再把响应交给引擎（**不含** AppID / AppKey）：

| 文件 | 作用 |
|------|------|
| `src/fetchLicenseToken.js` | 前端：`POST /api/facebetter/auth` |
| `api/facebetter/auth.js` | 服务端：用环境变量签名并请求上游，返回 token |

本地开发时 Vite 把 `/api/facebetter/auth` 转到已部署的 Demo 代理；生产部署时由 Vercel Function 处理。

在你们自己的后端接入时，照抄 `api/facebetter/auth.js` 的流程即可。协议说明与字段表见 [授权与许可](https://facebetter.net/docs/intro/license)。

## 部署

```bash
npm run build
vercel deploy --prod
```

密钥写入 Vercel 环境变量（勿提交仓库）：

```bash
printf '%s' 'your-app-id'  | vercel env add FB_APP_ID production
printf '%s' 'your-app-key' | vercel env add FB_APP_KEY production
```
