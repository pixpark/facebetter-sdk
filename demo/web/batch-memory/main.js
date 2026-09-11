/**
 * Facebetter 批量处理内存压测 Demo
 *
 * 用法建议：
 * 1. 先跑「丢弃结果 + 固定尺寸」——若 WASM 堆仍阶梯上涨，才像 SDK/堆增长问题
 * 2. 再跑「全部 push」——JS 堆应线性涨（假泄漏对照）
 * 3. 再跑「多尺寸轮换」——观察 WASM 峰值是否被抬高且不回落（ALLOW_MEMORY_GROWTH）
 */

import {
  BeautyEffectEngine,
  EngineConfig,
  Reshape,
  FrameType,
} from 'facebetter'

/** 发布包可能未导出 getWasmModule，优先公开 API，再回退引擎内部 */
function resolveWasmModule() {
  if (engine && typeof engine._getWasmModule === 'function') {
    return engine._getWasmModule()
  }
  throw new Error('WASM module not available')
}

const VARY_SCALES = [1, 0.75, 1.25, 0.5, 1.1]

const DEFAULT_IMAGE_URL = new URL('./imgs/demo.jpg', import.meta.url).href

const el = {
  count: document.getElementById('count'),
  sampleEvery: document.getElementById('sampleEvery'),
  retainMode: document.getElementById('retainMode'),
  sizeMode: document.getElementById('sizeMode'),
  enableBeauty: document.getElementById('enableBeauty'),
  enableSkinOnly: document.getElementById('enableSkinOnly'),
  file: document.getElementById('file'),
  btnInit: document.getElementById('btnInit'),
  btnRun: document.getElementById('btnRun'),
  btnStop: document.getElementById('btnStop'),
  btnDestroy: document.getElementById('btnDestroy'),
  btnClearLog: document.getElementById('btnClearLog'),
  sourceInfo: document.getElementById('sourceInfo'),
  resolution: document.getElementById('resolution'),
  status: document.getElementById('status'),
  progress: document.getElementById('progress'),
  wasmHeap: document.getElementById('wasmHeap'),
  jsHeap: document.getElementById('jsHeap'),
  elapsed: document.getElementById('elapsed'),
  avgMs: document.getElementById('avgMs'),
  preview: document.getElementById('preview'),
  log: document.getElementById('log'),
}

let engine = null
let stopRequested = false
let sourceImages = [] // { imageData, width, height }

function formatBytes(n) {
  if (n == null || Number.isNaN(n)) return '-'
  if (n < 1024) return `${n} B`
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`
  return `${(n / (1024 * 1024)).toFixed(2)} MB`
}

function log(msg) {
  const line = `[${new Date().toLocaleTimeString()}] ${msg}`
  el.log.textContent += `${line}\n`
  el.log.scrollTop = el.log.scrollHeight
  console.log(line)
}

function readMemory() {
  let wasmBytes = null
  try {
    const Module = resolveWasmModule()
    wasmBytes =
      Module.HEAPU8?.buffer?.byteLength ??
      Module.buffer?.byteLength ??
      Module.asm?.memory?.buffer?.byteLength ??
      null
  } catch {
    wasmBytes = null
  }

  const jsBytes =
    typeof performance !== 'undefined' && performance.memory
      ? performance.memory.usedJSHeapSize
      : null

  return { wasmBytes, jsBytes }
}

function updateMemoryUI() {
  const { wasmBytes, jsBytes } = readMemory()
  el.wasmHeap.textContent = formatBytes(wasmBytes)
  el.jsHeap.textContent =
    jsBytes != null
      ? formatBytes(jsBytes)
      : 'N/A（需 Chrome 开 --enable-precise-memory-info）'
  return { wasmBytes, jsBytes }
}

function yieldToUI() {
  return new Promise((resolve) => setTimeout(resolve, 0))
}

function createSyntheticImageData(width = 1280, height = 720) {
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d', { willReadFrequently: true })
  const g = ctx.createLinearGradient(0, 0, width, height)
  g.addColorStop(0, '#4a90d9')
  g.addColorStop(0.5, '#f5d0a9')
  g.addColorStop(1, '#2d6a4f')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, width, height)
  // 简单「脸」占位，便于美颜管线有内容可跑
  ctx.fillStyle = '#f1c27d'
  ctx.beginPath()
  ctx.ellipse(width * 0.5, height * 0.45, width * 0.12, height * 0.18, 0, 0, Math.PI * 2)
  ctx.fill()
  ctx.fillStyle = '#333'
  ctx.beginPath()
  ctx.arc(width * 0.46, height * 0.42, 8, 0, Math.PI * 2)
  ctx.arc(width * 0.54, height * 0.42, 8, 0, Math.PI * 2)
  ctx.fill()
  return ctx.getImageData(0, 0, width, height)
}

function updateSourceUI(items) {
  if (!items.length) {
    el.sourceInfo.textContent = '无'
    el.resolution.textContent = '-'
    return
  }
  if (items.length === 1) {
    const s = items[0]
    el.sourceInfo.textContent = `${s.name}（${s.width}×${s.height}）`
    el.resolution.textContent = `${s.width} × ${s.height}`
  } else {
    const sizes = items.map((s) => `${s.width}×${s.height}`).join(', ')
    el.sourceInfo.textContent = `${items.length} 张（${sizes}）`
    el.resolution.textContent = `${items[0].width} × ${items[0].height} 等`
  }
}

function loadUrlAsImageData(url, name) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        canvas.width = img.naturalWidth
        canvas.height = img.naturalHeight
        const ctx = canvas.getContext('2d', { willReadFrequently: true })
        ctx.drawImage(img, 0, 0)
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
        resolve({
          imageData,
          width: canvas.width,
          height: canvas.height,
          name,
        })
      } catch (e) {
        reject(e)
      }
    }
    img.onerror = () => reject(new Error(`Failed to load ${name || url}`))
    img.src = url
  })
}

function loadFileAsImageData(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const img = new Image()
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        canvas.width = img.naturalWidth
        canvas.height = img.naturalHeight
        const ctx = canvas.getContext('2d', { willReadFrequently: true })
        ctx.drawImage(img, 0, 0)
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
        URL.revokeObjectURL(url)
        resolve({ imageData, width: canvas.width, height: canvas.height, name: file.name })
      } catch (e) {
        URL.revokeObjectURL(url)
        reject(e)
      }
    }
    img.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error(`Failed to load ${file.name}`))
    }
    img.src = url
  })
}

function scaleImageData(imageData, scale) {
  if (scale === 1) return imageData
  const w = Math.max(2, Math.round(imageData.width * scale))
  const h = Math.max(2, Math.round(imageData.height * scale))
  const src = document.createElement('canvas')
  src.width = imageData.width
  src.height = imageData.height
  src.getContext('2d').putImageData(imageData, 0, 0)
  const dst = document.createElement('canvas')
  dst.width = w
  dst.height = h
  const ctx = dst.getContext('2d', { willReadFrequently: true })
  ctx.drawImage(src, 0, 0, w, h)
  return ctx.getImageData(0, 0, w, h)
}

function drawPreview(imageData) {
  const canvas = el.preview
  const ctx = canvas.getContext('2d')
  if (canvas.width !== imageData.width || canvas.height !== imageData.height) {
    canvas.width = imageData.width
    canvas.height = imageData.height
  }
  ctx.putImageData(imageData, 0, 0)
}

async function ensureSources() {
  const files = el.file.files
  if (files && files.length > 0) {
    sourceImages = []
    for (const file of files) {
      const item = await loadFileAsImageData(file)
      sourceImages.push(item)
      log(`已加载: ${item.name} (${item.width}×${item.height})`)
    }
    updateSourceUI(sourceImages)
    drawPreview(sourceImages[0].imageData)
    return
  }
  if (sourceImages.length === 0) {
    await loadDefaultSource()
  }
}

async function loadDefaultSource() {
  try {
    const item = await loadUrlAsImageData(DEFAULT_IMAGE_URL, 'imgs/demo.jpg')
    sourceImages = [item]
    updateSourceUI(sourceImages)
    drawPreview(item.imageData)
    log(`默认图: ${item.name}（${item.width}×${item.height}）`)
  } catch (e) {
    log(`默认图加载失败，回退合成图: ${e.message || e}`)
    const imageData = createSyntheticImageData(1280, 720)
    sourceImages = [{ imageData, width: 1280, height: 720, name: 'synthetic-1280x720' }]
    updateSourceUI(sourceImages)
    drawPreview(imageData)
  }
}

async function initEngine() {
  if (engine) {
    log('引擎已存在，先销毁再重建')
    engine.destroy()
    engine = null
  }

  el.status.textContent = '初始化中…'
  el.btnInit.disabled = true

  try {
    const config = new EngineConfig({ authProxyUrl: '/api/fb-auth' })
    engine = new BeautyEffectEngine(config)
    await engine.setLogConfig({ consoleEnabled: true, fileEnabled: false, level: 2 })
    await engine.init()

    if (el.enableBeauty.checked) {
      engine.setSmoothing(0.6)
      engine.setWhitening(0.4)
      engine.setReshape(Reshape.FaceThin, 0.3)
    }

    // 客户反馈：启用 setBeautySkinOnly 时才出现 WASM 内存问题
    engine.setBeautySkinOnly(!!el.enableSkinOnly.checked)

    el.status.textContent = '已就绪'
    el.btnRun.disabled = false
    el.btnDestroy.disabled = false
    updateMemoryUI()
    const flags = []
    if (el.enableBeauty.checked) flags.push('磨皮 0.6 / 美白 0.4 / 瘦脸 0.3')
    flags.push(`skinOnly=${el.enableSkinOnly.checked}`)
    log(`引擎初始化完成（${flags.join('，')}）`)
  } catch (e) {
    el.status.textContent = '初始化失败'
    log(`初始化失败: ${e.message || e}`)
    engine = null
  } finally {
    el.btnInit.disabled = false
  }
}

async function runBatch() {
  if (!engine) {
    log('请先初始化引擎')
    return
  }

  stopRequested = false
  el.btnRun.disabled = true
  el.btnStop.disabled = false
  el.btnDestroy.disabled = true

  await ensureSources()

  const total = Math.max(1, Number(el.count.value) || 3000)
  const sampleEvery = Math.max(1, Number(el.sampleEvery.value) || 100)
  const retainMode = el.retainMode.value
  const sizeMode = el.sizeMode.value
  const retained = []
  let last = null

  const mem0 = updateMemoryUI()
  log(
    `开始批处理: count=${total}, retain=${retainMode}, size=${sizeMode}, ` +
      `sources=${sourceImages.length}, wasm0=${formatBytes(mem0.wasmBytes)}, js0=${formatBytes(mem0.jsBytes)}`
  )

  const t0 = performance.now()
  let processed = 0
  el.status.textContent = '处理中…'
  el.progress.textContent = `0 / ${total}`

  try {
    for (let i = 0; i < total; i++) {
      if (stopRequested) {
        log(`用户停止于第 ${i} 张`)
        break
      }

      const src = sourceImages[i % sourceImages.length]
      let input = src.imageData
      if (sizeMode === 'vary') {
        input = scaleImageData(src.imageData, VARY_SCALES[i % VARY_SCALES.length])
      }

      const out = engine.processImage(input, input.width, input.height, FrameType.Image)
      processed = i + 1

      if (retainMode === 'keep-all') {
        retained.push(out)
      } else if (retainMode === 'keep-last') {
        last = out
      }
      // discard: 不保留引用

      if (i === 0 || processed % sampleEvery === 0 || i === total - 1) {
        const mem = updateMemoryUI()
        const elapsed = performance.now() - t0
        el.progress.textContent = `${processed} / ${total}`
        el.elapsed.textContent = `${(elapsed / 1000).toFixed(1)} s`
        el.avgMs.textContent = `${(elapsed / processed).toFixed(1)} ms/张`
        drawPreview(out)
        log(
          `#${processed} ${out.width}x${out.height} | wasm=${formatBytes(mem.wasmBytes)} | js=${formatBytes(mem.jsBytes)} | retained=${retained.length}`
        )
        await yieldToUI()
      }
    }

    const mem1 = updateMemoryUI()
    const elapsed = performance.now() - t0
    el.progress.textContent = `${processed} / ${total}`
    el.elapsed.textContent = `${(elapsed / 1000).toFixed(1)} s`
    el.avgMs.textContent = `${(elapsed / Math.max(1, processed)).toFixed(1)} ms/张`
    el.status.textContent = stopRequested ? '已停止' : '完成'
    log(
      `结束 | wasm Δ=${formatBytes((mem1.wasmBytes ?? 0) - (mem0.wasmBytes ?? 0))} | ` +
        `js Δ=${formatBytes((mem1.jsBytes ?? 0) - (mem0.jsBytes ?? 0))} | ` +
        `keep-all 张数=${retained.length}`
    )
    log(
      '判读: 仅 JS 涨 → 调用方/ImageData 积压；WASM 阶梯涨且不回落 → ALLOW_MEMORY_GROWTH 峰值/碎片（常非漏 free）；同尺寸丢弃仍每帧 WASM 大涨 → 再查 C++'
    )
    // 防止 keep-all 结果被优化掉
    if (retained.length || last) {
      void (retained.length ? retained[retained.length - 1] : last)
    }
  } catch (e) {
    el.status.textContent = '出错'
    log(`批处理失败: ${e.message || e}`)
    console.error(e)
  } finally {
    el.btnRun.disabled = false
    el.btnStop.disabled = true
    el.btnDestroy.disabled = !engine
  }
}

function destroyEngine() {
  if (!engine) return
  engine.destroy()
  engine = null
  el.status.textContent = '已销毁'
  el.btnRun.disabled = true
  el.btnDestroy.disabled = true
  updateMemoryUI()
  log('引擎已 destroy()；注意 WASM 堆通常不会缩回（ALLOW_MEMORY_GROWTH）')
}

el.btnInit.addEventListener('click', () => initEngine())
el.btnRun.addEventListener('click', () => runBatch())
el.btnStop.addEventListener('click', () => {
  stopRequested = true
  log('停止请求已发送…')
})
el.btnDestroy.addEventListener('click', () => destroyEngine())
el.btnClearLog.addEventListener('click', () => {
  el.log.textContent = ''
})
el.file.addEventListener('change', async () => {
  sourceImages = []
  if (el.file.files?.length) {
    await ensureSources()
  } else {
    await loadDefaultSource()
  }
})

log('打开页面后：先「初始化引擎」，再「开始批处理」。建议用 Chrome 并观察任务管理器中的内存。')
loadDefaultSource()
