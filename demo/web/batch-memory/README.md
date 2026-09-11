# Facebetter 批量处理内存压测 Demo

最简 Demo：连续调用 `processImage` 约 3k 次，采样 **WASM 堆** 与 **JS 堆**，用于复现客户「批量处理照片内存溢出」问题。

## 快速开始

```bash
cd demo/web/batch-memory
rm -rf node_modules package-lock.json
npm install
npm run dev
```

依赖 `facebetter@1.5.1`（会自动带上对应 `facebetter-core`）。浏览器打开终端提示的地址（默认 `http://localhost:5174`）。

## 推荐复现步骤

1. **对照（正常用法）**  
   - 保留策略：`丢弃结果`  
   - 尺寸模式：`固定尺寸`  
   - 循环次数：`3000`  
   - 选一张真实人像，或直接用内置合成图  

2. **假泄漏对照**  
   - 保留策略：`全部 push 到数组`  
   - 预期：JS 堆近似线性上涨（`W×H×4×张数`）

3. **变尺寸压力**  
   - 尺寸模式：`多尺寸轮换`  
   - 预期：WASM 堆可能阶梯上涨且不回落（`ALLOW_MEMORY_GROWTH=1` 不会缩内存）

## 如何判读

| 现象 | 更可能原因 |
|------|------------|
| 仅 `JS 堆` 持续涨、`WASM 堆` 稳定 | 调用方积压 `ImageData` / Blob / ObjectURL |
| `WASM 堆` 阶梯上涨后不回落 | 堆增长策略 + 峰值/碎片，不一定是漏 `_free` |
| 同尺寸 + 丢弃结果，WASM 仍每帧大幅上涨 | 再查 C++/引擎侧真实泄漏 |

> Chrome 下 `performance.memory` 需开启 `--enable-precise-memory-info`，否则 JS 堆可能显示 N/A；也可看 Chrome 任务管理器。

## 说明

- 依赖 `facebetter@1.5.1`（npm）。
- 鉴权走 Vite 代理 `/api/fb-auth`（与正式 React Demo 相同）；不要把密钥打进浏览器包。
- 本 Demo **不**保留每张处理结果（默认），避免把调用方积压误判成 SDK 泄漏。
- 引擎结束请点「销毁引擎」；即便正确 `destroy()`，WASM 线性内存通常也不会缩回。
