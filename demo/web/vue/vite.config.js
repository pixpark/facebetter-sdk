import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      // 使用 package.json 中配置的本地 facebetter 包
      // 'facebetter' 已通过 package.json 中的 "file:../../../src/engine/web/facebetter" 配置
      // 如果需要使用源码进行开发，可以取消下面的注释
      // 'facebetter': fileURLToPath(new URL('../../../src/engine/web/facebetter/src/esm/index.js', import.meta.url)),
    },
  },
  build: {
    // 调整 chunk 大小警告阈值（facebetter-core WASM 模块约 11MB）
    chunkSizeWarningLimit: 12000
  }
})
