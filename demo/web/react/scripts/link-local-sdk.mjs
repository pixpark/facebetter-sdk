#!/usr/bin/env node
import { mkdirSync, rmSync, symlinkSync } from 'node:fs'
import { join } from 'node:path'
import { assertLocalSdk, demoRoot, localSdkPackages, useLocalSdk } from '../sdk-source.mjs'

if (!useLocalSdk) {
  process.exit(0)
}

assertLocalSdk()
mkdirSync(join(demoRoot, 'node_modules'), { recursive: true })

for (const [name, target] of localSdkPackages()) {
  const dest = join(demoRoot, 'node_modules', name)
  rmSync(dest, { recursive: true, force: true })
  symlinkSync(target, dest, 'dir')
  console.log(`[fb] web demo: local ${name} -> ${target}`)
}
