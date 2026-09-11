package net.pixpark.fbexample.texture

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Surface
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import net.pixpark.facebetter.BeautyParams.Reshape
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
import java.util.concurrent.atomic.AtomicBoolean

class TextureStudioSession(
    private val context: Context,
    initialLocale: AppLocale? = null,
) : BeautySession {
    private val appContext = context.applicationContext
    private val engine = BeautyEngine(appContext, externalContext = true)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val compareFlag = AtomicBoolean(false)
    private val captureFlag = AtomicBoolean(false)

    override var params by mutableStateOf(StudioParams())
        private set
    override var tab by mutableStateOf(BeautyTab.SKIN)
    override var selectedSkin by mutableStateOf(SkinItem.SMOOTHING)
    override var selectedReshape by mutableStateOf(Reshape.FACE_THIN)
    override var selectedMakeup by mutableStateOf(MakeupItem.LIPSTICK)
    override var panelExpanded by mutableStateOf(false)
    override var locale by mutableStateOf(initialLocale ?: detectStudioLocale(appContext))
        private set

    var isComparing by mutableStateOf(false)
        private set
    var statusKey by mutableStateOf("status.initializing")
        private set
    var fps by mutableDoubleStateOf(0.0)
        private set
    /** Default true: mimic customer UI-thread SetFilter/SetSticker while process stays on GL. */
    var applyOnUIThread by mutableStateOf(true)
        private set

    private var filterLabels: Map<String, Pair<String, String>> = emptyMap()
    private var preview: TexturePreviewView? = null
    private var lifecycleOwner: LifecycleOwner? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraSurface: Surface? = null
    @Volatile
    private var stopped = false
    private var applying = false
    private var statusJob: Job? = null
    private var frameCount = 0
    private var lastFpsAt = SystemClock.elapsedRealtime()
    private var frontFacing = true

    init {
        filterLabels = loadFilterLabels(appContext)
        engine.onEvent = { key ->
            mainHandler.post { flash(key) }
        }
    }

    fun attach(preview: TexturePreviewView, owner: LifecycleOwner) {
        this.preview = preview
        lifecycleOwner = owner
        preview.frontFacing = frontFacing
        preview.process = { texture, width, height ->
            engine.processTexture(texture, width, height, compareFlag.get())
        }
        preview.onPresented = {
            updateFps()
            if (captureFlag.getAndSet(false)) {
                val bitmap = preview.captureBitmap()
                mainHandler.post { saveBitmap(bitmap) }
            }
        }
        preview.onGlReady = {
            if (!stopped) {
                engine.start()
                engine.apply(params)
                mainHandler.post { flash("status.textureOn") }
            }
        }
        preview.onGlRelease = {
            engine.release()
        }
        preview.onCameraSurfaceReady = { surface ->
            cameraSurface = surface
            bindCamera()
        }
    }

    fun start() {
        stopped = false
    }

    fun stop() {
        if (stopped) {
            return
        }
        stopped = true
        // Unbind camera before tearing down GL / engine so Studio can reclaim the device.
        cameraProvider?.unbindAll()
        cameraProvider = null
        cameraSurface = null
        val current = preview
        preview = null
        current?.runOnGlSync {
            engine.release()
        }
        current?.shutdown()
        scope.cancel()
    }

    fun flipCamera() {
        frontFacing = !frontFacing
        preview?.frontFacing = frontFacing
        bindCamera()
    }

    fun reset() {
        applying = true
        params = StudioParams()
        applying = false
        applyParams()
        flash("status.reset")
    }

    fun toggleApplyThread() {
        applyOnUIThread = !applyOnUIThread
        applyParams()
        flash(if (applyOnUIThread) "status.applyOnUI" else "status.applyOnGL")
    }

    fun capture() {
        captureFlag.set(true)
    }

    fun setCompareMode(value: Boolean) {
        isComparing = value
        compareFlag.set(value)
        preview?.comparing = value
    }

    fun updateLocale(next: AppLocale) {
        locale = next
        persistStudioLocale(appContext, next)
    }

    override fun t(key: String): String = L10n.text(key, locale)

    override fun updateParams(transform: StudioParams.() -> StudioParams) {
        params = params.transform()
        applyParams()
    }

    override fun filterLabel(id: String): String {
        val row = filterLabels[id] ?: return id.replace('_', ' ')
        return if (locale == AppLocale.ZH) row.first else row.second.replace('_', ' ')
    }

    private fun applyParams() {
        if (applying || stopped) {
            return
        }
        val snapshot = params
        if (applyOnUIThread) {
            engine.apply(snapshot)
        } else {
            preview?.runOnGl {
                engine.apply(snapshot)
            }
        }
    }

    private fun bindCamera() {
        val owner = lifecycleOwner ?: return
        val surface = cameraSurface ?: return
        val cameraProviderFuture = ProcessCameraProvider.getInstance(appContext)
        cameraProviderFuture.addListener(
            {
                if (stopped) {
                    return@addListener
                }
                val provider = cameraProviderFuture.get()
                cameraProvider = provider
                provider.unbindAll()
                val rotation = (owner as? android.app.Activity)?.windowManager
                    ?.defaultDisplay?.rotation
                    ?: android.view.Surface.ROTATION_0
                val previewUseCase = Preview.Builder()
                    .setTargetRotation(rotation)
                    .build()
                previewUseCase.setSurfaceProvider { request ->
                    preview?.setCameraBufferSize(request.resolution.width, request.resolution.height)
                    request.provideSurface(surface, ContextCompat.getMainExecutor(appContext)) { }
                }
                val selector = if (frontFacing) {
                    CameraSelector.DEFAULT_FRONT_CAMERA
                } else {
                    CameraSelector.DEFAULT_BACK_CAMERA
                }
                runCatching {
                    provider.bindToLifecycle(owner, selector, previewUseCase)
                }
            },
            ContextCompat.getMainExecutor(appContext),
        )
    }

    private fun saveBitmap(bitmap: android.graphics.Bitmap?) {
        scope.launch(Dispatchers.IO) {
            val ok = bitmap != null && MediaStoreSaver.save(appContext, bitmap)
            launch(Dispatchers.Main) {
                flash(
                    when {
                        ok -> "status.saved"
                        bitmap == null -> "status.captureFailed"
                        else -> "status.saveFailed"
                    },
                )
            }
        }
    }

    private fun flash(key: String) {
        statusKey = key
        statusJob?.cancel()
        statusJob = scope.launch {
            delay(2000)
            statusKey = ""
        }
    }

    private fun updateFps() {
        frameCount += 1
        val now = SystemClock.elapsedRealtime()
        val elapsed = now - lastFpsAt
        if (elapsed >= 1000) {
            val value = frameCount * 1000.0 / elapsed
            frameCount = 0
            lastFpsAt = now
            mainHandler.post { fps = value }
        }
    }
}
