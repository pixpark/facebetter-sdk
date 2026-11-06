package expo.modules.facebettercamera

import android.Manifest
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCharacteristics
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.util.Size
import android.view.Gravity
import android.view.Surface
import android.view.View.MeasureSpec
import android.view.WindowInsets
import android.widget.FrameLayout
import android.widget.TextView
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import androidx.annotation.OptIn
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class FacebetterCameraView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  override val shouldUseAndroidLayout = true

  private val engine = SkinEngine(context)
  private val preview = CameraGlView(context)
  private val costLabel = TextView(context).apply {
    setTextColor(Color.WHITE)
    textSize = 14f
    gravity = Gravity.CENTER
    setPadding(dp(8), dp(4), dp(8), dp(4))
    setBackgroundColor(0x73000000)
    elevation = 8f * resources.displayMetrics.density
    visibility = INVISIBLE
  }
  private val debugLabel = TextView(context).apply {
    setTextColor(Color.WHITE)
    textSize = 11f
    setPadding(dp(8), dp(4), dp(8), dp(4))
    setBackgroundColor(0x73000000)
    elevation = 8f * resources.displayMetrics.density
    visibility = INVISIBLE
  }
  private var cameraInfoText = ""
  private var frameInfoText = ""
  private var cameraProvider: ProcessCameraProvider? = null
  private var cameraSurface: Surface? = null
  private var stopped = false
  private val statsPosted = AtomicBoolean(false)
  private var frameMs = 0.0

  var smoothing = 0.6f
  var whitening = 0.3f
  var rosiness = 0.15f
  var blemish = 0f
  var clarity = 0.2f
  var skinOnly = false

  val onStatus by EventDispatcher<Map<String, Any>>()

  init {
    keepScreenOn = true
    addView(
      preview,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      ),
    )
    addView(costLabel)
    addView(debugLabel)
    preview.frontFacing = true
    preview.process = { texture, width, height ->
      val started = SystemClock.elapsedRealtimeNanos()
      val output = engine.processTexture(texture, width, height)
      frameMs = (SystemClock.elapsedRealtimeNanos() - started) / 1_000_000.0
      if (statsPosted.compareAndSet(false, true)) {
        post {
          statsPosted.set(false)
          showProcessTime(frameMs)
        }
      }
      output
    }
    preview.onGlReady = {
      engine.start { status -> emit(status) }
      engine.apply(currentSkin())
    }
    preview.onGlRelease = { engine.release() }
    preview.onCameraSurfaceReady = { surface ->
      cameraSurface = surface
      bindCamera()
    }
    preview.onFrameInfo = { info ->
      frameInfoText = info
      Log.i(TAG, info)
      showDebug()
    }
  }

  fun applySkin() {
    val skin = currentSkin()
    preview.runOnGl { engine.apply(skin) }
  }

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    val width = right - left
    val height = bottom - top
    preview.layout(0, 0, width, height)
    val labelWidth = dp(96)
    val labelHeight = dp(32)
    val margin = dp(12)
    val labelTop = statusBarTop() + margin
    // layout() alone leaves the text layout at width 0, so only the background draws.
    costLabel.measure(
      MeasureSpec.makeMeasureSpec(labelWidth, MeasureSpec.EXACTLY),
      MeasureSpec.makeMeasureSpec(labelHeight, MeasureSpec.EXACTLY),
    )
    costLabel.layout(
      width - labelWidth - margin,
      labelTop,
      width - margin,
      labelTop + labelHeight,
    )
    val debugWidth = (width - labelWidth - margin * 3).coerceAtLeast(dp(120))
    debugLabel.measure(
      MeasureSpec.makeMeasureSpec(debugWidth, MeasureSpec.AT_MOST),
      MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
    )
    debugLabel.layout(
      margin,
      labelTop,
      margin + debugLabel.measuredWidth,
      labelTop + debugLabel.measuredHeight,
    )
  }

  private fun showDebug() {
    debugLabel.text = listOf(cameraInfoText, frameInfoText)
      .filter { it.isNotEmpty() }
      .joinToString("\n")
    debugLabel.visibility = if (debugLabel.text.isEmpty()) INVISIBLE else VISIBLE
    requestLayout()
  }

  private fun showProcessTime(ms: Double) {
    costLabel.text = String.format(Locale.US, "%.1f ms", ms)
    costLabel.visibility = VISIBLE
    requestLayout()
  }

  private fun statusBarTop(): Int {
    val insets = rootWindowInsets ?: return 0
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      insets.getInsets(WindowInsets.Type.statusBars()).top
    } else {
      @Suppress("DEPRECATION")
      insets.systemWindowInsetTop
    }
  }

  private fun dp(value: Int): Int {
    return (value * resources.displayMetrics.density).toInt()
  }

  override fun onDetachedFromWindow() {
    stopped = true
    cameraProvider?.unbindAll()
    cameraProvider = null
    preview.shutdown()
    super.onDetachedFromWindow()
  }

  private fun currentSkin() = SkinParams(smoothing, whitening, rosiness, blemish, clarity, skinOnly)

  private fun emit(status: String) {
    post { onStatus(mapOf("status" to status)) }
  }

  private fun bindCamera() {
    val surface = cameraSurface ?: return
    val owner = findLifecycleOwner() ?: run {
      emit("initFailed")
      return
    }
    if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
      != PackageManager.PERMISSION_GRANTED
    ) {
      emit("cameraDenied")
      return
    }
    val future = ProcessCameraProvider.getInstance(context)
    future.addListener({
      if (stopped) {
        return@addListener
      }
      val provider = future.get()
      cameraProvider = provider
      provider.unbindAll()
      val resolution = ResolutionSelector.Builder()
        .setResolutionStrategy(
          ResolutionStrategy(
            Size(TARGET_WIDTH, TARGET_HEIGHT),
            ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER,
          ),
        )
        .build()
      val rotation = display?.rotation ?: Surface.ROTATION_0
      val useCase = Preview.Builder()
        .setResolutionSelector(resolution)
        .setTargetRotation(rotation)
        .build()
      useCase.setSurfaceProvider { request ->
        val size = request.resolution
        val low = maxOf(size.width, size.height) < 1000
        cameraInfoText = buildString {
          append(Build.MANUFACTURER)
          append(' ')
          append(Build.MODEL)
          append(" cam ")
          append(size.width)
          append('x')
          append(size.height)
          if (low) {
            append(" LOW")
          }
        }
        Log.i(TAG, cameraInfoText)
        showDebug()
        preview.setCameraBufferSize(size.width, size.height)
        emit("camera ${size.width}x${size.height}")
        request.provideSurface(surface, ContextCompat.getMainExecutor(context)) { }
      }
      val selector = if (provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) {
        CameraSelector.DEFAULT_FRONT_CAMERA
      } else {
        CameraSelector.DEFAULT_BACK_CAMERA
      }
      preview.frontFacing = selector == CameraSelector.DEFAULT_FRONT_CAMERA
      runCatching {
        val camera = provider.bindToLifecycle(owner, selector, useCase)
        logPreviewSizes(camera)
      }.onFailure { error ->
        Log.e(TAG, "bindToLifecycle failed", error)
        emit("initFailed")
      }
    }, ContextCompat.getMainExecutor(context))
  }

  @OptIn(ExperimentalCamera2Interop::class)
  private fun logPreviewSizes(camera: androidx.camera.core.Camera) {
    val map = Camera2CameraInfo.from(camera.cameraInfo)
      .getCameraCharacteristic(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
    val sizes = map?.getOutputSizes(SurfaceTexture::class.java)
      ?.joinToString(",") { "${it.width}x${it.height}" }
      ?: "none"
    Log.i(TAG, "preview sizes $sizes")
  }

  private fun findLifecycleOwner(): LifecycleOwner? {
    var current: Context? = context
    while (current is ContextWrapper) {
      if (current is LifecycleOwner) {
        return current
      }
      current = current.baseContext
    }
    return current as? LifecycleOwner
  }

  companion object {
    private const val TAG = "FacebetterCamera"
    private const val TARGET_WIDTH = 1920
    private const val TARGET_HEIGHT = 1080
  }
}
