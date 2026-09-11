#!/usr/bin/env node
import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { spawnSync } from 'node:child_process'
import { assertLocalSdk, demoRoot, useLocalSdk } from '../sdk-source.mjs'

if (!useLocalSdk) {
  console.error('Missing .use_local_sdk. Copy .use_local_sdk.example first.')
  process.exit(1)
}

assertLocalSdk()

const pkgPath = join(demoRoot, 'package.json')
const lockPath = join(demoRoot, 'package-lock.json')
const origPkg = readFileSync(pkgPath, 'utf8')
const origLock = existsSync(lockPath) ? readFileSync(lockPath, 'utf8') : null
const pkg = JSON.parse(origPkg)

pkg.dependencies.facebetter = 'file:../../../../fb/src/engine/web/facebetter'
pkg.dependencies['facebetter-core'] = 'file:../../../../fb/src/engine/web/facebetter-core'
writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`)

const result = spawnSync('npm', ['install', ...process.argv.slice(2)], {
  cwd: demoRoot,
  stdio: 'inherit',
  shell: process.platform === 'win32',
})

writeFileSync(pkgPath, origPkg)
if (origLock != null) {
  writeFileSync(lockPath, origLock)
} else {
  rmSync(lockPath, { force: true })
}

process.exit(result.status ?? 1)
