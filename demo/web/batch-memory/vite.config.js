import { defineConfig } from 'vite'
import { facebetterAuthProxy } from '../fb-auth-proxy.js'

export default defineConfig({
  plugins: [facebetterAuthProxy()],
  build: {
    chunkSizeWarningLimit: 12000,
  },
  server: {
    port: 5174,
  },
  optimizeDeps: {
    exclude: ['facebetter-core'],
  },
})
