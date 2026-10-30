package net.pixpark.fbexample.engine

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import net.pixpark.facebetter.BeautyEffectEngine
import net.pixpark.facebetter.EngineCallbacks
import net.pixpark.facebetter.EngineEventCode
import net.pixpark.facebetter.ImageFrame
import net.pixpark.fbexample.beauty.BackgroundFill
import net.pixpark.fbexample.beauty.BeautyCatalog
import net.pixpark.fbexample.beauty.StickerKind
import net.pixpark.fbexample.beauty.StudioParams
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class BeautyEngine(
    private val context: Context,
) {
    private val lock = ReentrantLock()
    // Serializes parameter writes. Does not cover processImage, so intensity
    // changes are not stuck behind the frame currently being drawn.
    private val applyLock = ReentrantLock()
    private var engine: BeautyEffectEngine? = null
    private var previous = StudioParams()
    private var appliedOnce = false
    private var backgroundBytes: ByteArray? = null
    private val presetCache = mutableMapOf<String, ByteArray>()

    @Volatile
    var isReady: Boolean = false
        private set

    @Volatile
    var statusKey: String = "status.initializing"
        private set

    var onEvent: ((String) -> Unit)? = null

    fun start() {
        applyLock.withLock {
        lock.withLock {
            if (engine != null) {
                return
            }
            try {
                val log = BeautyEffectEngine.LogConfig()
                log.consoleEnabled = true
                log.fileEnabled = false
                log.level = BeautyEffectEngine.LogLevel.INFO
                BeautyEffectEngine.setLogConfig(log)

                val config = BeautyEffectEngine.EngineConfig()
                val token = CONFIG_LICENSE_TOKEN
                if (token.isNotBlank()) {
                    config.licenseToken = token
                } else {
                    config.appId = CONFIG_APP_ID
                    config.appKey = CONFIG_APP_KEY
                }

                val created = BeautyEffectEngine(context.applicationContext, config)
                engine = created
                isReady = true
                statusKey = "status.ready"
                assetBytes("facebetter/resource_3d.fbd")?.let { created.addResourcePack(it) }
                assetBytes("facebetter/resource_body.fbd")?.let { created.addResourcePack(it) }

                val callbacks = EngineCallbacks()
                callbacks.onEngineEvent = EngineCallbacks.OnEngineEventCallback { code, _ ->
                    val key = when (code) {
                        EngineEventCode.LICENSE_VALIDATION_SUCCESS,
                        EngineEventCode.INITIALIZATION_COMPLETE -> {
                            isReady = true
                            "status.ready"
                        }
                        EngineEventCode.LICENSE_VALIDATION_FAILED -> {
                            isReady = false
                            "status.authFailed"
                        }
                        EngineEventCode.INITIALIZATION_FAILED -> {
                            isReady = false
                            "status.initFailed"
                        }
                        else -> statusKey
                    }
                    statusKey = key
                    onEvent?.invoke(key)
                }
                created.setCallbacks(callbacks)

                backgroundBytes = runCatching {
                    context.assets.open("facebetter/background.jpg").use { it.readBytes() }
                }.getOrNull()

                applyLocked(created, StudioParams())
            } catch (error: Throwable) {
                Log.e(TAG, "Failed to start engine", error)
                isReady = false
                statusKey = if (error is UnsatisfiedLinkError || error is NoSuchMethodError) {
                    "status.sdkMismatch"
                } else {
                    "status.initFailed"
                }
                onEvent?.invoke(statusKey)
            }
        }
        }
    }

    fun apply(params: StudioParams) {
        applyLock.withLock {
            val current = lock.withLock { engine?.takeIf { isReady } } ?: return
            applyLocked(current, params)
        }
    }

    fun process(input: ImageFrame, asImage: Boolean, bypass: Boolean): ImageFrame? {
        lock.withLock {
            val current = engine
            if (bypass || current == null || !isReady) {
                return null
            }
            input.type = if (asImage) ImageFrame.FrameType.IMAGE else ImageFrame.FrameType.VIDEO
            return current.processImage(input)
        }
    }

    fun processTexture(texture: Int, width: Int, height: Int, bypass: Boolean): Int {
        lock.withLock {
            val current = engine
            if (bypass || current == null || !isReady || texture == 0 || width <= 0 || height <= 0) {
                return texture
            }
            val input = ImageFrame.createWithTexture(texture, width, height, width * 4) ?: return texture
            input.type = ImageFrame.FrameType.VIDEO
            val output = try {
                current.processImage(input)
            } finally {
                input.release()
            }
            val outTex = output?.texture ?: 0
            output?.release()
            return if (outTex != 0) outTex else texture
        }
    }

    fun release() {
        applyLock.withLock {
            lock.withLock {
                engine?.release()
                engine = null
                isReady = false
                previous = StudioParams()
                appliedOnce = false
                statusKey = "status.initializing"
            }
        }
    }

    private fun applyLocked(current: BeautyEffectEngine, params: StudioParams) {
        val prev = previous
        val force = !appliedOnce
        appliedOnce = true
        previous = params

        current.setSmoothing(params.smoothing)
        current.setSmoothingStyle(params.smoothingStyle)
        current.setWhitening(params.whitening)
        if (force || prev.whiteningStyle != params.whiteningStyle) {
            current.setWhiteningStyle(params.whiteningStyle)
        }
        current.setRosiness(params.rosiness)
        current.setBlemish(params.blemish)
        current.setClarity(params.clarity)
        current.setBrightness(params.brightness)
        current.setContrast(params.contrast)
        current.setSaturation(params.saturation)
        current.setColorTemperature(params.colorTemperature)
        current.setColorTint(params.colorTint)
        current.setBeautySkinOnly(params.skinOnly)

        for (item in BeautyCatalog.reshapeItems) {
            current.setReshape(item.key, params.reshape[item.key] ?: 0f)
        }
        for (item in BeautyCatalog.bodyItems) {
            current.setBodyReshape(item.key, params.bodyReshape[item.key] ?: 0f)
        }

        current.setLipstick(params.lipstick)
        if (force || prev.lipstickColor != params.lipstickColor) {
            current.setLipstickColor(params.lipstickColor)
        }
        current.setBlush(params.blush)
        if (force || prev.blushStyle != params.blushStyle) {
            current.setBlushStyle(params.blushStyle)
        }
        if (force || prev.blushColor != params.blushColor) {
            current.setBlushColor(params.blushColor)
        }
        current.setContour(params.contour)
        if (force || prev.contourStyle != params.contourStyle) {
            current.setContourStyle(params.contourStyle)
        }
        current.setEyeShadow(params.eyeshadow)
        if (force || prev.eyeshadowStyle != params.eyeshadowStyle) {
            current.setEyeShadowStyle(params.eyeshadowStyle)
        }
        if (force || prev.eyeshadowColor != params.eyeshadowColor) {
            current.setEyeShadowColor(params.eyeshadowColor)
        }
        current.setEyeLiner(params.eyeliner)
        if (force || prev.eyelinerStyle != params.eyelinerStyle) {
            current.setEyeLinerStyle(params.eyelinerStyle)
        }
        if (force || prev.eyelinerColor != params.eyelinerColor) {
            current.setEyeLinerColor(params.eyelinerColor)
        }
        current.setEyebrow(params.eyebrow)
        if (force || prev.eyebrowStyle != params.eyebrowStyle) {
            current.setEyebrowStyle(params.eyebrowStyle)
        }
        if (force || prev.eyebrowColor != params.eyebrowColor) {
            current.setEyebrowColor(params.eyebrowColor)
        }
        current.setEyelash(params.eyelash)
        if (force || prev.eyelashStyle != params.eyelashStyle) {
            current.setEyelashStyle(params.eyelashStyle)
        }
        if (force || prev.eyelashColor != params.eyelashColor) {
            current.setEyelashColor(params.eyelashColor)
        }
        current.setPupil(params.pupil)
        if (force || prev.pupilColor != params.pupilColor) {
            current.setPupilColor(params.pupilColor)
        }
        current.setTeethWhiten(params.teethWhiten)

        if (prev.filterId != params.filterId) {
            val bytes = params.filterId?.let { assetBytes("facebetter/filters/portrait/$it/$it.fbd") }
            if (bytes != null) {
                current.setFilter(bytes)
            } else {
                current.clearFilter()
            }
        }
        if (params.filterId != null) {
            current.setFilterIntensity(params.filterIntensity)
        }

        if (prev.stickerId != params.stickerId) {
            val id = params.stickerId
            if (id != null) {
                val item = BeautyCatalog.sticker(id)
                val folder = item?.kind?.folder ?: "face"
                val bytes = assetBytes("facebetter/stickers/$folder/$id.fbd")
                if (bytes != null) {
                    if (item?.kind == StickerKind.THREE_D) {
                        current.clearSticker()
                        current.set3DSticker(bytes)
                    } else {
                        current.clear3DSticker()
                        current.setSticker(bytes)
                    }
                } else {
                    current.clearSticker()
                    current.clear3DSticker()
                }
            } else {
                current.clearSticker()
                current.clear3DSticker()
            }
        }

        if (force || prev.chroma != params.chroma) {
            val chroma = params.chroma
            if (chroma != null) {
                current.setChromaKey(chroma)
            } else {
                current.clearChromaKey()
            }
        }
        if (params.chroma != null) {
            current.setChromaKeySimilarity(params.chromaSimilarity)
            current.setChromaKeySmoothness(params.chromaSmoothness)
            current.setChromaKeyDesaturation(params.chromaDesaturation)
        }

        if (force || prev.backgroundFill != params.backgroundFill || prev.bgPreset != params.bgPreset) {
            when (params.backgroundFill) {
                BackgroundFill.BLUR -> current.setVirtualBackgroundBlur(params.bgBlur)
                BackgroundFill.IMAGE -> {
                    val presetId = params.bgPreset ?: BeautyCatalog.backgroundPresets.firstOrNull()?.id
                    val bytes = presetId?.let { presetBytes(it) } ?: backgroundBytes
                    if (bytes != null && bytes.isNotEmpty()) {
                        current.setVirtualBackground(bytes)
                    }
                }
                BackgroundFill.OFF -> current.clearVirtualBackground()
            }
        } else if (params.backgroundFill == BackgroundFill.BLUR && prev.bgBlur != params.bgBlur) {
            current.setVirtualBackgroundBlur(params.bgBlur)
        }
        if (prev.subjectOutline != params.subjectOutline) {
            current.setSubjectOutline(params.subjectOutline)
        }
    }

    private fun presetBytes(id: String): ByteArray? {
        presetCache[id]?.let { return it }
        val bytes = assetBytes("facebetter/backgrounds/$id.jpg") ?: return null
        presetCache[id] = bytes
        return bytes
    }

    private fun assetBytes(path: String): ByteArray? {
        return runCatching { context.assets.open(path).use { it.readBytes() } }.getOrNull()
    }

    companion object {
        private const val TAG = "BeautyEngine"
        const val CONFIG_APP_ID = "dddb24155fd045ab9c2d8aad83ad3a4a"
        const val CONFIG_APP_KEY = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc"
        const val CONFIG_LICENSE_TOKEN = ""
    }
}

fun ImageFrame.toDisplayBitmap(reuse: Bitmap?): Bitmap? {
    val rgba = if (format == ImageFrame.Format.RGBA) this else convert(ImageFrame.Format.RGBA) ?: return null
    try {
        val width = rgba.width
        val height = rgba.height
        val stride = rgba.stride
        val buffer = rgba.data ?: return null
        buffer.rewind()
        val bitmap = if (reuse != null && reuse.width == width && reuse.height == height && !reuse.isRecycled) {
            reuse
        } else {
            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        }
        val rowBytes = width * 4
        if (stride == rowBytes && buffer.remaining() >= height * stride) {
            bitmap.copyPixelsFromBuffer(buffer)
        } else {
            val packed = java.nio.ByteBuffer.allocate(rowBytes * height)
            val source = ByteArray(stride)
            for (row in 0 until height) {
                buffer.position(row * stride)
                buffer.get(source, 0, minOf(stride, buffer.remaining()))
                packed.put(source, 0, rowBytes)
            }
            packed.rewind()
            bitmap.copyPixelsFromBuffer(packed)
        }
        return bitmap
    } finally {
        if (rgba !== this) {
            rgba.release()
        }
    }
}

fun Bitmap.scaledIfNeeded(maxLong: Int = 1920, maxShort: Int = 1080): Bitmap {
    val longSide = maxOf(width, height)
    val shortSide = minOf(width, height)
    if (longSide <= maxLong && shortSide <= maxShort) return this
    val scale = minOf(maxLong.toFloat() / longSide, maxShort.toFloat() / shortSide)
    return Bitmap.createScaledBitmap(this, (width * scale).toInt(), (height * scale).toInt(), true)
}
