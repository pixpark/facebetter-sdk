package net.pixpark.fbexample.studio

import android.app.Application
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.camera.core.ImageProxy
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import net.pixpark.facebetter.FaceDetectionResult
import net.pixpark.facebetter.ImageFrame
import net.pixpark.fbexample.AppLocale
import net.pixpark.fbexample.L10n
import net.pixpark.fbexample.beauty.BeautySession
import net.pixpark.fbexample.beauty.BeautyTab
import net.pixpark.fbexample.beauty.MakeupItem
import net.pixpark.fbexample.beauty.SkinItem
import net.pixpark.fbexample.beauty.StudioParams
import net.pixpark.fbexample.beauty.detectStudioLocale
import net.pixpark.fbexample.beauty.loadFilterLabels
import net.pixpark.fbexample.beauty.persistStudioLocale
import net.pixpark.fbexample.engine.BeautyEngine
import net.pixpark.fbexample.engine.MediaStoreSaver
import net.pixpark.fbexample.engine.scaledIfNeeded
import net.pixpark.fbexample.engine.toDisplayBitmap
import net.pixpark.facebetter.BeautyParams.Reshape
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.roundToInt

enum class StudioSource { CAMERA, IMAGE }

class StudioViewModel(application: Application) : AndroidViewModel(application), BeautySession {
    private val engine = BeautyEngine(application)
    private val compareFlag = AtomicBoolean(false)
    private val captureFlag = AtomicBoolean(false)
    private val engineReady = AtomicBoolean(false)

    override var params by mutableStateOf(StudioParams())
        private set
    override var tab by mutableStateOf(BeautyTab.SKIN)
    override var selectedSkin by mutableStateOf(SkinItem.SMOOTHING)
    override var selectedReshape by mutableStateOf(Reshape.FACE_THIN)
    override var selectedMakeup by mutableStateOf(MakeupItem.LIPSTICK)
    override var locale by mutableStateOf(detectStudioLocale(application))
        private set
    var source by mutableStateOf(StudioSource.CAMERA)
        private set
    var showLandmarks by mutableStateOf(false)
    var isComparing by mutableStateOf(false)
        private set
    var statusKey by mutableStateOf("status.initializing")
        private set
    var faces by mutableStateOf<List<FaceDetectionResult>>(emptyList())
        private set
    var fps by mutableDoubleStateOf(0.0)
        private set
    var processMs by mutableDoubleStateOf(0.0)
        private set
    override var panelExpanded by mutableStateOf(false)
    var previewBitmap by mutableStateOf<Bitmap?>(null)
        private set
    private var filterLabels: Map<String, Pair<String, String>> = emptyMap()

    private var originalStill: Bitmap? = null
    private val previewBuffers = arrayOfNulls<Bitmap>(2)
    private var writeIndex = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private var statusJob: Job? = null
    private var frameCount = 0
    private var processMsAccum = 0.0
    private var lastFpsAt = SystemClock.elapsedRealtime()

    init {
        engine.onEvent = { key ->
            viewModelScope.launch(Dispatchers.Main) {
                engineReady.set(key == "status.ready")
                flash(key)
            }
        }
        engine.onFaces = { next ->
            viewModelScope.launch(Dispatchers.Main) {
                faces = next
            }
        }
        filterLabels = loadFilterLabels(application)
        engine.start()
        engineReady.set(engine.isReady)
        if (engine.statusKey.isNotEmpty()) {
            flash(engine.statusKey)
        }
    }

    fun notifyCameraDenied() {
        flash("status.permissionCamera")
    }

    override fun t(key: String): String = L10n.text(key, locale)

    fun updateLocale(next: AppLocale) {
        locale = next
        persistStudioLocale(getApplication(), next)
    }

    override fun updateParams(transform: StudioParams.() -> StudioParams) {
        val next = params.transform()
        params = next
        engine.apply(next)
        if (source == StudioSource.IMAGE) {
            reprocessStill()
        }
    }

    fun reset() {
        params = StudioParams()
        engine.apply(params)
        flash("status.reset")
        if (source == StudioSource.IMAGE) {
            reprocessStill()
        }
    }

    fun setCompareMode(value: Boolean) {
        isComparing = value
        compareFlag.set(value)
        if (source == StudioSource.IMAGE) {
            reprocessStill()
        }
    }

    fun capture() {
        if (source == StudioSource.IMAGE) {
            val bitmap = if (isComparing) originalStill else previewBitmap
            saveBitmap(bitmap)
            return
        }
        captureFlag.set(true)
    }

    fun loadImage(uri: Uri) {
        viewModelScope.launch(Dispatchers.IO) {
            val loaded = getApplication<Application>().contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it)
            }?.scaledIfNeeded() ?: return@launch
            originalStill = loaded
            source = StudioSource.IMAGE
            reprocessStill()
            viewModelScope.launch(Dispatchers.Main) { flash("status.imageLoaded") }
        }
    }

    fun backToCamera() {
        originalStill = null
        source = StudioSource.CAMERA
        flash("status.cameraOn")
    }

    fun suspendForExternalTexture() {
        engineReady.set(false)
        engine.release()
    }

    fun resumeAfterExternalTexture() {
        locale = detectStudioLocale(getApplication())
        engine.start()
        engine.apply(params)
        engineReady.set(engine.isReady)
        if (source == StudioSource.IMAGE) {
            reprocessStill()
        }
        if (engine.statusKey.isNotEmpty()) {
            flash(engine.statusKey)
        }
    }

    override fun filterLabel(id: String): String {
        val row = filterLabels[id] ?: return id.replace('_', ' ')
        return if (locale == AppLocale.ZH) row.first else row.second.replace('_', ' ')
    }

    fun processCameraFrame(image: ImageProxy, frontFacing: Boolean) {
        try {
            val input = image.toImageFrame(frontFacing) ?: return
            try {
                val bypass = compareFlag.get()
                val started = SystemClock.elapsedRealtimeNanos()
                val output = engine.process(input, asImage = false, bypass = bypass)
                val costMs = (SystemClock.elapsedRealtimeNanos() - started) / 1_000_000.0
                val displaySource = output ?: input
                publishPreview(displaySource.toDisplayBitmap(previewBuffers[writeIndex]), costMs)
                if (captureFlag.getAndSet(false)) {
                    val photoFrame = engine.process(input, asImage = true, bypass = false) ?: input
                    val photo = photoFrame.toDisplayBitmap(null)
                    if (photoFrame !== input && photoFrame !== output) {
                        photoFrame.release()
                    }
                    saveBitmap(photo)
                }
                if (output != null && output !== input) {
                    output.release()
                }
            } finally {
                input.release()
            }
        } finally {
            image.close()
        }
    }

    override fun onCleared() {
        engine.release()
        super.onCleared()
    }

    private fun reprocessStill() {
        val still = originalStill ?: return
        val input = ImageFrame.createWithBitmap(still) ?: return
        try {
            val output = engine.process(input, asImage = true, bypass = compareFlag.get())
            val bitmap = (output ?: input).toDisplayBitmap(previewBuffers[writeIndex])
            if (output != null && output !== input) {
                output.release()
            }
            publishPreview(bitmap, processCostMs = null)
        } finally {
            input.release()
        }
    }

    private fun saveBitmap(bitmap: Bitmap?) {
        viewModelScope.launch(Dispatchers.IO) {
            val ok = bitmap != null && MediaStoreSaver.save(getApplication(), bitmap)
            viewModelScope.launch(Dispatchers.Main) {
                flash(if (ok) "status.saved" else if (bitmap == null) "status.captureFailed" else "status.saveFailed")
            }
        }
    }

    private fun publishPreview(bitmap: Bitmap?, processCostMs: Double?) {
        if (bitmap == null) return
        previewBuffers[writeIndex] = bitmap
        writeIndex = 1 - writeIndex
        mainHandler.post {
            previewBitmap = bitmap
            if (processCostMs != null) {
                updateFps(processCostMs)
            }
        }
    }

    private fun flash(key: String) {
        statusKey = key
        statusJob?.cancel()
        statusJob = viewModelScope.launch {
            delay(2000)
            statusKey = ""
        }
    }

    private fun updateFps(processCostMs: Double) {
        frameCount += 1
        processMsAccum += processCostMs
        val now = SystemClock.elapsedRealtime()
        val elapsed = now - lastFpsAt
        if (elapsed >= 1000) {
            fps = frameCount * 1000.0 / elapsed
            processMs = processMsAccum / frameCount.coerceAtLeast(1)
            frameCount = 0
            processMsAccum = 0.0
            lastFpsAt = now
        }
    }
}

private fun ImageProxy.toImageFrame(frontFacing: Boolean): ImageFrame? {
    val frame = when (planes.size) {
        1 -> {
            // CameraX OUTPUT_IMAGE_FORMAT_RGBA_8888 — matches texture-path chroma.
            val plane = planes[0]
            plane.buffer.rewind()
            ImageFrame.createWithRGBA(plane.buffer, width, height, plane.rowStride)
        }
        else -> {
            val y = planes[0]
            val u = planes[1]
            val v = planes[2]
            y.buffer.rewind()
            u.buffer.rewind()
            v.buffer.rewind()
            ImageFrame.createWithAndroid420(
                width,
                height,
                y.buffer,
                y.rowStride,
                u.buffer,
                u.rowStride,
                v.buffer,
                v.rowStride,
                u.pixelStride,
            )
        }
    } ?: return null
    when (imageInfo.rotationDegrees % 360) {
        90 -> frame.rotate(ImageFrame.Rotation.ROTATION_90)
        180 -> frame.rotate(ImageFrame.Rotation.ROTATION_180)
        270 -> frame.rotate(ImageFrame.Rotation.ROTATION_270)
    }
    if (frontFacing) {
        frame.mirror("horizontal")
    }
    return frame
}

fun Float.toPercent(): Int = (this * 100f).roundToInt()
