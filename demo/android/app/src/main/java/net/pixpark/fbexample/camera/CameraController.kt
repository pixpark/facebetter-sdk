package net.pixpark.fbexample.camera

import android.app.Activity
import android.content.Context
import android.util.Size
import android.view.Surface
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraController(
    private val context: Context,
    private val onFrame: (ImageProxy, Boolean) -> Unit,
) {
    private var provider: ProcessCameraProvider? = null
    private var analyzerExecutor: ExecutorService? = null
    var frontFacing: Boolean = true
        private set

    fun start(owner: LifecycleOwner) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener(
            {
                val cameraProvider = cameraProviderFuture.get()
                provider = cameraProvider
                bind(owner, cameraProvider)
            },
            ContextCompat.getMainExecutor(context),
        )
    }

    fun stop() {
        provider?.unbindAll()
        analyzerExecutor?.shutdown()
        analyzerExecutor = null
    }

    fun flip(owner: LifecycleOwner) {
        frontFacing = !frontFacing
        val cameraProvider = provider ?: return
        bind(owner, cameraProvider)
    }

    private fun bind(owner: LifecycleOwner, cameraProvider: ProcessCameraProvider) {
        cameraProvider.unbindAll()
        analyzerExecutor?.shutdown()
        val executor = Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "fb-studio-camera").apply { priority = Thread.NORM_PRIORITY }
        }
        analyzerExecutor = executor

        // Match external-texture processing (~1280 long edge, full-chroma). CameraX
        // defaults to ~640x480 YUV which makes smoothing look softer/dirtier after upscale.
        val resolutionSelector = ResolutionSelector.Builder()
            .setAspectRatioStrategy(AspectRatioStrategy.RATIO_16_9_FALLBACK_AUTO_STRATEGY)
            .setResolutionStrategy(
                ResolutionStrategy(
                    Size(TARGET_WIDTH, TARGET_HEIGHT),
                    ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER,
                ),
            )
            .build()

        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolutionSelector)
            .setTargetRotation(displayRotation(owner))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysis.setAnalyzer(executor) { image ->
            onFrame(image, frontFacing)
        }

        val selector = if (frontFacing) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        cameraProvider.bindToLifecycle(owner, selector, analysis)
    }

    private fun displayRotation(owner: LifecycleOwner): Int {
        val activity = owner as? Activity ?: context as? Activity
        @Suppress("DEPRECATION")
        return activity?.windowManager?.defaultDisplay?.rotation ?: Surface.ROTATION_0
    }

    companion object {
        /** Align with TexturePreviewView MAX_LONG / 16:9 preview. */
        private const val TARGET_WIDTH = 1280
        private const val TARGET_HEIGHT = 720
    }
}
