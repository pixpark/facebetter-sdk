import { existsSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const demoRoot = dirname(fileURLToPath(import.meta.url))

export const useLocalSdk =
  existsSync(join(demoRoot, '.use_local_sdk')) || process.env.FACEBETTER_LOCAL === '1'

export const localWebRoot = resolve(demoRoot, '../../../../fb/build/web')
export const localFacebetter = join(localWebRoot, 'facebetter')
export const localFacebetterCore = join(localWebRoot, 'facebetter-core')
export const localFacebetterRel = '../../../../fb/build/web/facebetter'
export const localFacebetterCoreRel = '../../../../fb/build/web/facebetter-core'

const LOCAL_PACKAGES = [
  ['facebetter', localFacebetter, 'dist/facebetter.esm.js'],
  ['facebetter-core', localFacebetterCore, 'dist/facebetter-core.js'],
]

const LOCAL_CORE_FILES = [
  'dist/facebetter-core.wasm',
  'dist/resource.fbd',
  'assets.js',
]

export function assertLocalSdk() {
  if (!useLocalSdk) return
  for (const [name, dir, artifact] of LOCAL_PACKAGES) {
    if (!existsSync(join(dir, 'package.json')) || !existsSync(join(dir, artifact))) {
      throw new Error(
        `Local ${name} not found:\n  ${dir}\n` +
          'Build the sibling engine packages first:\n' +
          '  cd ../../../../fb && ./scripts/build_web.sh'
      )
    }
  }
  for (const file of LOCAL_CORE_FILES) {
    if (!existsSync(join(localFacebetterCore, file))) {
      throw new Error(
        `Local facebetter-core missing ${file}:\n  ${localFacebetterCore}\n` +
          'Build the sibling engine packages first:\n' +
          '  cd ../../../../fb && ./scripts/build_web.sh'
      )
    }
  }
}

export function localSdkPackages() {
  return LOCAL_PACKAGES
}
