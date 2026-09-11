package net.pixpark.fbexample.studio

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.runtime.LaunchedEffect
import androidx.core.content.ContextCompat
import net.pixpark.fbexample.camera.CameraController

class StudioActivity : ComponentActivity() {
    private val viewModel: StudioViewModel by viewModels()
    private lateinit var camera: CameraController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        camera = CameraController(this) { image, front ->
            if (viewModel.source == StudioSource.CAMERA) {
                viewModel.processCameraFrame(image, front)
            } else {
                image.close()
            }
        }

        setContent {
            val permissionLauncher = rememberLauncherForActivityResult(
                ActivityResultContracts.RequestPermission(),
            ) { granted ->
                if (granted) {
                    camera.start(this)
                    viewModel.backToCamera()
                } else {
                    viewModel.notifyCameraDenied()
                }
            }
            val picker = rememberLauncherForActivityResult(
                ActivityResultContracts.PickVisualMedia(),
            ) { uri ->
                if (uri != null) {
                    camera.stop()
                    viewModel.loadImage(uri)
                }
            }

            LaunchedEffect(viewModel.source) {
                if (viewModel.source == StudioSource.CAMERA) {
                    if (hasCameraPermission()) {
                        camera.start(this@StudioActivity)
                    } else {
                        permissionLauncher.launch(Manifest.permission.CAMERA)
                    }
                } else {
                    camera.stop()
                }
            }

            StudioScreen(
                viewModel = viewModel,
                onPickImage = {
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                },
                onStartCamera = {
                    if (hasCameraPermission()) {
                        viewModel.backToCamera()
                        camera.start(this)
                    } else {
                        permissionLauncher.launch(Manifest.permission.CAMERA)
                    }
                },
                onFlipCamera = {
                    if (hasCameraPermission()) {
                        camera.flip(this)
                    }
                },
                onFinish = { finish() },
            )
        }
    }

    override fun onStart() {
        super.onStart()
        if (viewModel.source == StudioSource.CAMERA && hasCameraPermission()) {
            camera.start(this)
        }
    }

    override fun onStop() {
        camera.stop()
        super.onStop()
    }

    override fun onDestroy() {
        camera.stop()
        super.onDestroy()
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
    }
}
