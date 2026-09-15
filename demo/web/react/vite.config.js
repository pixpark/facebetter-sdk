import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { assertLocalSdk, localFacebetter, localFacebetterCore, localWebRoot, useLocalSdk } from './sdk-source.mjs'

if (useLocalSdk) {
  assertLocalSdk()
  console.log(`[fb] web demo: local packages ${localWebRoot}`)
} else {
  console.log('[fb] web demo: npm facebetter@2.0.0')
}

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: useLocalSdk
      ? {
          facebetter: localFacebetter,
          'facebetter-core': localFacebetterCore,
          'facebetter-core/assets': `${localFacebetterCore}/assets.js`,
        }
      : {},
  },
  optimizeDeps: {
    exclude: ['facebetter', 'facebetter-core'],
  },
  assetsInclude: ['**/*.wasm', '**/*.fbd'],
  server: {
    port: 5175,
    // Same path as production; forward to the deployed auth proxy (keys stay on Vercel).
    proxy: {
      '/api/facebetter/auth': {
        target: 'https://demo.facebetter.net',
        changeOrigin: true,
      },
    },
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
