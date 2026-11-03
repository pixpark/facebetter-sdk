package expo.modules.facebettercamera

import android.content.Context
import android.util.Log
import net.pixpark.facebetter.BeautyEffectEngine
import net.pixpark.facebetter.BeautyParams.SmoothingStyle
import net.pixpark.facebetter.EngineCallbacks
import net.pixpark.facebetter.EngineEventCode
import net.pixpark.facebetter.ImageFrame
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

data class SkinParams(
  val smoothing: Float = 0.6f,
  val whitening: Float = 0.3f,
  val rosiness: Float = 0.15f,
  val blemish: Float = 0f,
  val clarity: Float = 0.2f,
  val skinOnly: Boolean = false,
)

/**
 * Facebetter engine used from the camera GL thread.
 * Same sample credentials as demo/android. The package name must be bound.
 */
class SkinEngine(private val context: Context) {
  private val lock = ReentrantLock()
  private var engine: BeautyEffectEngine? = null

  @Volatile
  var ready: Boolean = false
    private set

  fun start(onStatus: (String) -> Unit) {
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
        if (LICENSE_TOKEN.isNotBlank()) {
          config.licenseToken = LICENSE_TOKEN
        } else {
          config.appId = APP_ID
          config.appKey = APP_KEY
        }
        val created = BeautyEffectEngine(context.applicationContext, config)
        val callbacks = EngineCallbacks()
        callbacks.onEngineEvent = EngineCallbacks.OnEngineEventCallback { code, _ ->
          val status = when (code) {
            EngineEventCode.LICENSE_VALIDATION_SUCCESS,
            EngineEventCode.INITIALIZATION_COMPLETE -> {
              ready = true
              "ready"
            }
            EngineEventCode.LICENSE_VALIDATION_FAILED -> {
              ready = false
              "authFailed"
            }
            EngineEventCode.INITIALIZATION_FAILED -> {
              ready = false
              "initFailed"
            }
            else -> return@OnEngineEventCallback
          }
          onStatus(status)
        }
        created.setCallbacks(callbacks)
        created.setSmoothingStyle(SmoothingStyle.NATURAL)
        engine = created
        ready = true
        onStatus("ready")
      } catch (error: Throwable) {
        Log.e(TAG, "Failed to start engine", error)
        ready = false
        onStatus("initFailed")
      }
    }
  }

  fun apply(params: SkinParams) {
    val current = lock.withLock { engine?.takeIf { ready } } ?: return
    current.setSmoothing(params.smoothing)
    current.setWhitening(params.whitening)
    current.setRosiness(params.rosiness)
    current.setBlemish(params.blemish)
    current.setClarity(params.clarity)
    current.setBeautySkinOnly(params.skinOnly)
  }

  fun processTexture(texture: Int, width: Int, height: Int): Int {
    lock.withLock {
      val current = engine
      if (current == null || !ready || texture == 0 || width <= 0 || height <= 0) {
        return texture
      }
      val input = ImageFrame.createWithTexture(texture, width, height, width * 4)
        ?: return texture
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
    lock.withLock {
      engine?.release()
      engine = null
      ready = false
    }
  }

  companion object {
    private const val TAG = "SkinEngine"
    const val APP_ID = "dddb24155fd045ab9c2d8aad83ad3a4a"
    const val APP_KEY = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc"
    const val LICENSE_TOKEN = ""
  }
}
