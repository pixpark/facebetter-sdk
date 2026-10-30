package net.pixpark.fbexample.texture

import android.content.Context
import android.view.Surface
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import net.pixpark.fbexample.beauty.StudioParams
import net.pixpark.fbexample.engine.BeautyEngine
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Camera as a GL_TEXTURE_2D. The engine is started on this GL thread and released
 * before the context goes away. Beauty parameters stay on the studio model.
 */
class GlTextureController(
    context: Context,
    private val engine: BeautyEngine,
    private val params: () -> StudioParams,
    private val applyOnUiThread: () -> Boolean,
    private val onStatus: (String) -> Unit,
    private val onFrame: (Double) -> Unit,
) {
    private val appContext = context.applicationContext
    private val compareFlag = AtomicBoolean(false)
    private val captureFlag = AtomicBoolean(false)

    private var preview: TexturePreviewView? = null
    private var lifecycleOwner: LifecycleOwner? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraSurface: Surface? = null
    @Volatile
    private var stopped = true
    private var frontFacing = true
    var active: Boolean = false
        private set

    var onCapture: ((android.graphics.Bitmap?) -> Unit)? = null

    fun attach(preview: TexturePreviewView, owner: LifecycleOwner) {
        stopped = false
        active = false
        this.preview = preview
        lifecycleOwner = owner
        preview.frontFacing = frontFacing
        preview.comparing = compareFlag.get()
        preview.process = { texture, width, height ->
            val started = android.os.SystemClock.elapsedRealtimeNanos()
            val rendered = GlTextureInput.process(
                texture,
                width,
                height,
                engine,
                compareFlag.get(),
            )
            onFrame((android.os.SystemClock.elapsedRealtimeNanos() - started) / 1_000_000.0)
            rendered
        }
        preview.onPresented = {
            if (captureFlag.getAndSet(false)) {
                onCapture?.invoke(preview.captureBitmap())
            }
        }
        preview.onGlReady = {
            if (!stopped) {
                engine.start()
                engine.apply(params())
                active = true
                onStatus("status.inputGl")
            }
        }
        preview.onGlRelease = {
            active = false
            engine.release()
        }
        preview.onCameraSurfaceReady = { surface ->
            cameraSurface = surface
            bindCamera()
        }
    }

    fun stopPreview() {
        if (stopped && preview == null) {
            return
        }
        stopped = true
        active = false
        cameraProvider?.unbindAll()
        cameraProvider = null
        cameraSurface = null
        val current = preview
        preview = null
        lifecycleOwner = null
        current?.shutdown()
    }

    fun setComparing(value: Boolean) {
        compareFlag.set(value)
        preview?.comparing = value
    }

    fun requestCapture() {
        captureFlag.set(true)
    }

    fun flipCamera() {
        frontFacing = !frontFacing
        preview?.frontFacing = frontFacing
        bindCamera()
    }

    fun apply(snapshot: StudioParams) {
        if (stopped) {
            return
        }
        if (applyOnUiThread()) {
            engine.apply(snapshot)
        } else {
            preview?.runOnGl { engine.apply(snapshot) }
        }
    }

    fun runOnGl(work: () -> Unit) {
        val current = preview
        if (current == null) {
            work()
        } else {
            current.runOnGl(work)
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
                    ?: Surface.ROTATION_0
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
}
