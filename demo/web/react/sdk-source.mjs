import { existsSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const demoRoot = dirname(fileURLToPath(import.meta.url))

export const useLocalSdk =
  existsSync(join(demoRoot, '.use_local_sdk')) || process.env.FACEBETTER_LOCAL === '1'

export const localWebRoot = resolve(demoRoot, '../../../../fb/src/engine/web')
export const localFacebetter = join(localWebRoot, 'facebetter')
export const localFacebetterCore = join(localWebRoot, 'facebetter-core')

const LOCAL_PACKAGES = [
  ['facebetter', localFacebetter],
  ['facebetter-core', localFacebetterCore],
]

export function assertLocalSdk() {
  if (!useLocalSdk) return
  for (const [name, dir] of LOCAL_PACKAGES) {
    if (!existsSync(join(dir, 'package.json'))) {
      throw new Error(
        `Local ${name} not found:\n  ${dir}\n` +
          'Build the sibling engine packages first, for example:\n' +
          `  cd ${localWebRoot}/facebetter && npm run build`
      )
    }
  }
}

export function localSdkPackages() {
  return LOCAL_PACKAGES
}
