package net.pixpark.fbexample.engine

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import net.pixpark.facebetter.BeautyEffectEngine
import net.pixpark.facebetter.EngineCallbacks
import net.pixpark.facebetter.EngineEventCode
import net.pixpark.facebetter.FaceDetectionResult
import net.pixpark.facebetter.ImageFrame
import net.pixpark.fbexample.beauty.BackgroundFill
import net.pixpark.fbexample.beauty.BeautyCatalog
import net.pixpark.fbexample.beauty.StudioParams
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class BeautyEngine(private val context: Context) {
    private val lock = ReentrantLock()
    private var engine: BeautyEffectEngine? = null
    private var previous = StudioParams()
    private var backgroundBytes: ByteArray? = null

    @Volatile
    var isReady: Boolean = false
        private set

    @Volatile
    var statusKey: String = "status.initializing"
        private set

    var onEvent: ((String) -> Unit)? = null
    var onFaces: ((List<FaceDetectionResult>) -> Unit)? = null

    fun start() {
        lock.withLock {
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
                config.externalContext = false

                val created = BeautyEffectEngine(context.applicationContext, config)
                engine = created
                isReady = true
                statusKey = "status.ready"

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
                callbacks.onFaceLandmarks = EngineCallbacks.OnFaceLandmarksCallback { results ->
                    onFaces?.invoke(results ?: emptyList())
                }
                created.setCallbacks(callbacks)

                backgroundBytes = runCatching {
                    context.assets.open("facebetter/background.jpg").use { it.readBytes() }
                }.getOrNull()

                applyLocked(StudioParams())
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

    fun apply(params: StudioParams) {
        lock.withLock { applyLocked(params) }
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

    fun release() {
        lock.withLock {
            engine?.release()
            engine = null
            isReady = false
        }
    }

    private fun applyLocked(params: StudioParams) {
        val current = engine ?: return
        val prev = previous
        previous = params

        current.setSmoothing(params.smoothing)
        current.setSmoothingStyle(params.smoothingStyle)
        current.setWhitening(params.whitening)
        current.setWhiteningStyle(params.whiteningStyle)
        current.setRosiness(params.rosiness)
        current.setSharpening(params.sharpening)
        current.setBeautySkinOnly(params.skinOnly)

        for (item in BeautyCatalog.reshapeItems) {
            current.setReshape(item.key, params.reshape[item.key] ?: 0f)
        }

        current.setLipstick(params.lipstick)
        current.setLipstickColor(params.lipstickColor)
        current.setBlush(params.blush)
        current.setBlushStyle(params.blushStyle)
        current.setBlushColor(params.blushColor)
        current.setContour(params.contour)
        current.setContourStyle(params.contourStyle)
        current.setEyeShadow(params.eyeshadow)
        current.setEyeShadowStyle(params.eyeshadowStyle)
        current.setEyeShadowColor(params.eyeshadowColor)
        current.setEyeLiner(params.eyeliner)
        current.setEyeLinerStyle(params.eyelinerStyle)
        current.setEyeLinerColor(params.eyelinerColor)
        current.setEyebrow(params.eyebrow)
        current.setEyebrowStyle(params.eyebrowStyle)
        current.setEyebrowColor(params.eyebrowColor)
        current.setEyelash(params.eyelash)
        current.setEyelashStyle(params.eyelashStyle)
        current.setEyelashColor(params.eyelashColor)
        current.setPupil(params.pupil)
        current.setPupilColor(params.pupilColor)

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
            val bytes = params.stickerId?.let { assetBytes("facebetter/stickers/face/$it.fbd") }
            if (bytes != null) {
                current.setSticker(bytes)
            } else {
                current.clearSticker()
            }
        }

        if (prev.chroma != params.chroma ||
            prev.chromaSimilarity != params.chromaSimilarity ||
            prev.chromaSmoothness != params.chromaSmoothness ||
            prev.chromaDesaturation != params.chromaDesaturation
        ) {
            val chroma = params.chroma
            if (chroma != null) {
                current.setChromaKey(chroma)
                current.setChromaKeySimilarity(params.chromaSimilarity)
                current.setChromaKeySmoothness(params.chromaSmoothness)
                current.setChromaKeyDesaturation(params.chromaDesaturation)
            } else {
                current.clearChromaKey()
            }
        }

        if (prev.backgroundFill != params.backgroundFill || prev.bgBlur != params.bgBlur) {
            when (params.backgroundFill) {
                BackgroundFill.BLUR -> current.setVirtualBackgroundBlur(params.bgBlur)
                BackgroundFill.IMAGE -> {
                    val bytes = backgroundBytes
                    if (bytes != null && bytes.isNotEmpty()) {
                        current.setVirtualBackground(bytes)
                    }
                }
                BackgroundFill.OFF -> current.clearVirtualBackground()
            }
        }
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
