import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { facebetterAuthProxy } from '../fb-auth-proxy.js'
import { assertLocalSdk, localFacebetter, localFacebetterCore, localWebRoot, useLocalSdk } from './sdk-source.mjs'

if (useLocalSdk) {
  assertLocalSdk()
  console.log(`[fb] web demo: local packages ${localWebRoot}`)
} else {
  console.log('[fb] web demo: npm facebetter@2.0.0')
}

export default defineConfig({
  plugins: [react(), facebetterAuthProxy()],
  resolve: {
    alias: useLocalSdk
      ? {
          facebetter: localFacebetter,
          'facebetter-core': localFacebetterCore,
        }
      : {},
  },
  optimizeDeps: {
    exclude: useLocalSdk ? ['facebetter', 'facebetter-core'] : [],
  },
  server: {
    port: 5175,
    fs: {
      allow: useLocalSdk
        ? ['..', localWebRoot]
        : ['..'],
    },
  },
  build: {
    chunkSizeWarningLimit: 12000,
  },
})
