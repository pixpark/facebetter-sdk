package net.pixpark.fbexample;

import android.os.Bundle;
import android.util.Log;
import android.widget.CheckBox;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.activity.EdgeToEdge;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import java.io.InputStream;
import net.pixpark.facebetter.BeautyEffectEngine;
import net.pixpark.facebetter.BeautyParams;
import net.pixpark.facebetter.BeautyParams.*;
import net.pixpark.facebetter.ImageFrame;

/**
 * 使用 externalContext + 纹理输入的最小 Android 示例。
 *
 * 流程：
 * 1. 使用 GLVideoRenderer 并设置 onProcessVideoFrame 回调
 * 2. GLVideoRenderer 内部读取图片生成纹理，在回调中带出
 * 3. 在回调中使用 externalContext=true 创建 BeautyEffectEngine，并调用 processImage
 * 4. 将处理后的纹理返回给 GLVideoRenderer 进行渲染
 */
public class ExternalTextureActivity
    extends AppCompatActivity implements GLTextureRenderer.OnProcessVideoFrameCallback {
  private static final String TAG = "ExternalTextureActivity";
  private static final int ERROR_SUCCESS = 0;
  private static final int ERROR_CREATE_FRAME_FAILED = -1;
  private static final int ERROR_PROCESS_FAILED = -2;
  private static final int ERROR_GET_BUFFER_FAILED = -3;
  private static final String LUT_FILTER_ID = "vivid";
  private static final String LUT_ASSET_PATH = "filters/portrait/vivid/vivid.fbd";

  private GLTextureRenderer glVideoRenderer;
  private BeautyEffectEngine engine;
  private SeekBar seekBarSmoothing;
  private SeekBar seekBarWhitening;
  private TextView textSmoothingValue;
  private TextView textWhiteningValue;
  private CheckBox checkBoxLutEnable;
  private SeekBar seekBarLutIntensity;
  private TextView textLutIntensityValue;
  private float initialSmoothingValue = 0.2f;
  private float initialWhiteningValue = 0.0f;
  private float initialLutIntensityValue = 0.8f;
  private boolean initialLutEnabled = false;
  private boolean lutFilterRegistered = false;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    // Apply language settings (must be before setContentView)
    LanguageHelper.applyLanguage(this);
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_external_texture);

    glVideoRenderer = findViewById(R.id.gl_video_renderer);
    glVideoRenderer.setOnProcessVideoFrameCallback(this);

    // Initialize sliders
    seekBarSmoothing = findViewById(R.id.seekbar_smoothing);
    seekBarWhitening = findViewById(R.id.seekbar_whitening);
    textSmoothingValue = findViewById(R.id.text_smoothing_value);
    textWhiteningValue = findViewById(R.id.text_whitening_value);
    checkBoxLutEnable = findViewById(R.id.checkbox_lut_enable);
    seekBarLutIntensity = findViewById(R.id.seekbar_lut_intensity);
    textLutIntensityValue = findViewById(R.id.text_lut_intensity_value);

    // Setup smoothing slider listener
    seekBarSmoothing.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
      @Override
      public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (fromUser && engine != null) {
          float value = progress / 100.0f;
          engine.setBeautyParam(BasicParam.SMOOTHING, value);
          textSmoothingValue.setText(String.format("%.2f", value));
          Log.d(TAG, "Set SMOOTHING: " + value);
        }
      }

      @Override
      public void onStartTrackingTouch(SeekBar seekBar) {}

      @Override
      public void onStopTrackingTouch(SeekBar seekBar) {}
    });

    // Setup whitening slider listener
    seekBarWhitening.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
      @Override
      public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (fromUser && engine != null) {
          float value = progress / 100.0f;
          engine.setBeautyParam(BasicParam.WHITENING, value);
          textWhiteningValue.setText(String.format("%.2f", value));
          Log.d(TAG, "Set WHITENING: " + value);
        }
      }

      @Override
      public void onStartTrackingTouch(SeekBar seekBar) {}

      @Override
      public void onStopTrackingTouch(SeekBar seekBar) {}
    });

    // Setup LUT enable checkbox listener
    checkBoxLutEnable.setOnCheckedChangeListener((buttonView, isChecked) -> {
      initialLutEnabled = isChecked;
      if (engine != null) {
        engine.setFilter(isChecked ? LUT_FILTER_ID : "");
        Log.d(TAG, "LUT " + (isChecked ? "enabled" : "disabled"));
      }
    });

    // Setup LUT intensity slider listener
    seekBarLutIntensity.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
      @Override
      public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (fromUser) {
          initialLutIntensityValue = progress / 100.0f;
          textLutIntensityValue.setText(String.format("%.2f", initialLutIntensityValue));
          if (engine != null) {
            engine.setFilterIntensity(initialLutIntensityValue);
            Log.d(TAG, "Set LUT intensity: " + initialLutIntensityValue);
          }
        }
      }

      @Override
      public void onStartTrackingTouch(SeekBar seekBar) {}

      @Override
      public void onStopTrackingTouch(SeekBar seekBar) {}
    });

    // Initialize display values
    initialSmoothingValue = seekBarSmoothing.getProgress() / 100.0f;
    initialWhiteningValue = seekBarWhitening.getProgress() / 100.0f;
    initialLutIntensityValue = seekBarLutIntensity.getProgress() / 100.0f;
    initialLutEnabled = checkBoxLutEnable.isChecked();
    textSmoothingValue.setText(String.format("%.2f", initialSmoothingValue));
    textWhiteningValue.setText(String.format("%.2f", initialWhiteningValue));
    textLutIntensityValue.setText(String.format("%.2f", initialLutIntensityValue));
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (glVideoRenderer != null) {
      glVideoRenderer.cleanup();
    }
    if (engine != null) {
      engine.release();
      engine = null;
    }
  }

  @Override
  public int onProcessVideoFrame(
      GLTextureRenderer.TextureFrame srcFrame, GLTextureRenderer.TextureFrame dstFrame) {
    // Initialize engine if not initialized
    if (engine == null) {
      BeautyEffectEngine.LogConfig logConfig = new BeautyEffectEngine.LogConfig();
      logConfig.consoleEnabled = true;
      logConfig.level = BeautyEffectEngine.LogLevel.INFO;
      BeautyEffectEngine.setLogConfig(logConfig);

      BeautyEffectEngine.EngineConfig config = new BeautyEffectEngine.EngineConfig();
      // TODO: Replace with your AppId/AppKey or licenseJson
      config.appId = "dddb24155fd045ab9c2d8aad83ad3a4a";
      config.appKey = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";
      config.externalContext = true;

      engine = new BeautyEffectEngine(this, config);

      // Register vivid LUT filter from assets
      if (!lutFilterRegistered) {
        try (InputStream is = getAssets().open(LUT_ASSET_PATH)) {
          int size = is.available();
          byte[] buffer = new byte[size];
          int read = is.read(buffer);
          if (read != size) {
            Log.w(TAG, "Vivid filter read short: " + read + "/" + size);
          }
          int ret = engine.registerFilter(LUT_FILTER_ID, buffer);
          if (ret == 0) {
            lutFilterRegistered = true;
            Log.d(TAG, "Registered LUT filter: " + LUT_FILTER_ID);
          } else {
            Log.e(TAG, "registerFilter failed, code=" + ret);
          }
        } catch (Exception e) {
          Log.e(TAG, "Failed to load LUT filter: " + LUT_ASSET_PATH, e);
        }
      }

      // Apply initial slider values
      engine.setBeautyParam(BasicParam.SMOOTHING, initialSmoothingValue);
      engine.setBeautyParam(BasicParam.WHITENING, initialWhiteningValue);
      engine.setFilterIntensity(initialLutIntensityValue);
      if (initialLutEnabled && lutFilterRegistered) {
        engine.setFilter(LUT_FILTER_ID);
      }
      Log.d(TAG,
          "BeautyEffectEngine initialized with SMOOTHING: " + initialSmoothingValue
              + ", WHITENING: " + initialWhiteningValue
              + ", LUT: " + (initialLutEnabled ? LUT_FILTER_ID : "<off>")
              + " @ " + initialLutIntensityValue);
    }

    // Create ImageFrame from input texture
    int stride = srcFrame.width * 4; // RGBA stride
    ImageFrame inputFrame =
        ImageFrame.createWithTexture(srcFrame.textureId, srcFrame.width, srcFrame.height, stride);
    if (inputFrame == null) {
      Log.e(TAG, "createWithTexture failed");
      return ERROR_CREATE_FRAME_FAILED;
    }

    // Process image
    inputFrame.type = ImageFrame.FrameType.IMAGE;
    ImageFrame outputFrame = engine.processImage(inputFrame);
    if (outputFrame == null) {
      Log.e(TAG, "processImage returned null");
      return ERROR_PROCESS_FAILED;
    }

    // Get texture ID and dimensions directly from output frame
    int textureId = outputFrame.getTexture();
    if (textureId == 0) {
      Log.e(TAG, "getTexture returned 0");
      return ERROR_GET_BUFFER_FAILED;
    }

    // Set output texture and size
    dstFrame.textureId = textureId;
    dstFrame.width = outputFrame.getWidth();
    dstFrame.height = outputFrame.getHeight();

    outputFrame.release();
    inputFrame.release();
    return ERROR_SUCCESS;
  }
}
