import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const repoWeb = fileURLToPath(new URL('../../../../fb/src/engine/web', import.meta.url))

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      // 直接走仓库源码，改 JS 不用先 rollup
      facebetter: `${repoWeb}/facebetter/src/esm/index.js`,
      'facebetter-core': `${repoWeb}/facebetter-core/dist/facebetter-core.js`,
    },
  },
  optimizeDeps: {
    exclude: ['facebetter', 'facebetter-core'],
  },
  build: {
    // 调整 chunk 大小警告阈值（facebetter-core WASM 模块约 11MB）
    chunkSizeWarningLimit: 12000
  }
})
