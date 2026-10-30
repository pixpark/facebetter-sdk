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
import net.pixpark.fbexample.texture.GlTextureController
import net.pixpark.facebetter.BeautyParams.Reshape
import net.pixpark.facebetter.BeautyParams.BodyReshape
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
    override var selectedBody by mutableStateOf(BodyReshape.BODY_SLIM)
    override var selectedMakeup by mutableStateOf(MakeupItem.LIPSTICK)
    override var locale by mutableStateOf(detectStudioLocale(application))
        private set
    var source by mutableStateOf(StudioSource.CAMERA)
        private set
    var cameraInput by mutableStateOf(CameraInput.CPU)
        private set
    var applyOnUIThread by mutableStateOf(true)
        private set
    var isComparing by mutableStateOf(false)
        private set
    var statusKey by mutableStateOf("status.initializing")
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

    val glController = GlTextureController(
        context = application,
        engine = engine,
        params = { params },
        applyOnUiThread = { applyOnUIThread },
        onStatus = { key -> mainHandler.post { flash(key) } },
        onFrame = { costMs -> mainHandler.post { updateFps(costMs) } },
    )

    init {
        glController.onCapture = { bitmap -> saveBitmap(bitmap) }
        engine.onEvent = { key ->
            viewModelScope.launch(Dispatchers.Main) {
                engineReady.set(key == "status.ready")
                flash(key)
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
        applyCurrentParams()
        if (source == StudioSource.IMAGE) {
            reprocessStill()
        }
    }

    fun setCompareMode(value: Boolean) {
        isComparing = value
        compareFlag.set(value)
        glController.setComparing(value)
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
        if (cameraInput == CameraInput.GL_TEXTURE) {
            glController.requestCapture()
            return
        }
        captureFlag.set(true)
    }

    fun selectCameraInput(mode: CameraInput) {
        if (mode == cameraInput) {
            return
        }
        if (source == StudioSource.CAMERA) {
            if (mode == CameraInput.GL_TEXTURE) {
                engine.release()
                engineReady.set(false)
            } else {
                glController.stopPreview()
                engine.start()
                engine.apply(params)
                engineReady.set(engine.isReady)
            }
        }
        cameraInput = mode
        flash(if (mode == CameraInput.GL_TEXTURE) "status.inputGl" else "status.inputCpu")
    }

    fun toggleApplyThread() {
        applyOnUIThread = !applyOnUIThread
        applyCurrentParams()
        flash(if (applyOnUIThread) "status.applyOnUI" else "status.applyOnGL")
    }

    fun loadImage(uri: Uri) {
        viewModelScope.launch(Dispatchers.IO) {
            val loaded = getApplication<Application>().contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it)
            }?.scaledIfNeeded() ?: return@launch
            originalStill = loaded
            if (cameraInput == CameraInput.GL_TEXTURE) {
                glController.stopPreview()
                engine.start()
                engine.apply(params)
                engineReady.set(engine.isReady)
            }
            source = StudioSource.IMAGE
            reprocessStill()
            viewModelScope.launch(Dispatchers.Main) { flash("status.imageLoaded") }
        }
    }

    fun backToCamera() {
        originalStill = null
        source = StudioSource.CAMERA
        if (cameraInput == CameraInput.GL_TEXTURE) {
            engine.release()
            engineReady.set(false)
        }
        flash("status.cameraOn")
    }

    override fun filterLabel(id: String): String {
        val row = filterLabels[id] ?: return id.replace('_', ' ')
        return if (locale == AppLocale.ZH) row.first else row.second.replace('_', ' ')
    }

    fun processCameraFrame(image: ImageProxy, frontFacing: Boolean) {
        if (cameraInput != CameraInput.CPU || source != StudioSource.CAMERA) {
            image.close()
            return
        }
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
        glController.stopPreview()
        engine.release()
        super.onCleared()
    }

    private fun applyCurrentParams() {
        if (cameraInput == CameraInput.GL_TEXTURE && glController.active) {
            glController.apply(params)
        } else if (cameraInput != CameraInput.GL_TEXTURE || source == StudioSource.IMAGE) {
            engine.apply(params)
        }
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
    // CameraX leaves pixels in sensor orientation. Rotate and mirror this CPU
    // buffer here. These calls do not transform a GL texture.
    when (imageInfo.rotationDegrees % 360) {
        90 -> frame.rotate(ImageFrame.Rotation.ROTATION_90)
        180 -> frame.rotate(ImageFrame.Rotation.ROTATION_180)
        270 -> frame.rotate(ImageFrame.Rotation.ROTATION_270)
    }
    if (frontFacing) {
        frame.mirror(ImageFrame.MirrorMode.HORIZONTAL)
    }
    return frame
}

fun Float.toPercent(): Int = (this * 100f).roundToInt()
