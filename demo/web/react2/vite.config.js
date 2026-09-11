import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { facebetterAuthProxy } from '../fb-auth-proxy.js'

const repoWeb = fileURLToPath(new URL('../../../../fb/src/engine/web', import.meta.url))

export default defineConfig({
  plugins: [react(), facebetterAuthProxy()],
  resolve: {
    alias: {
      facebetter: `${repoWeb}/facebetter/src/esm/index.js`,
      'facebetter-core': `${repoWeb}/facebetter-core/dist/facebetter-core.js`,
    },
  },
  optimizeDeps: {
    exclude: ['facebetter', 'facebetter-core'],
  },
  server: {
    port: 5175,
    fs: {
      allow: ['..', '../../../../fb/src/engine/web'],
    },
  },
  build: {
    chunkSizeWarningLimit: 12000,
  },
})
