package net.pixpark.fbexample.camera

import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
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

        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
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
}
