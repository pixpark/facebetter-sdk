package com.pixpark.fbexample;

import static android.widget.Toast.LENGTH_LONG;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.Image;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.Toast;
import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.pixpark.facebetter.BeautyEffectEngine;
import com.pixpark.facebetter.BeautyParams.*;
import com.pixpark.facebetter.ImageFrame;
import java.io.InputStream;
import java.nio.ByteBuffer;

public class BeautyActivity extends AppCompatActivity {
  private static final String TAG = "MainActivity";
  private static final int CAMERA_PERMISSION_REQUEST_CODE = 200;

  private BeautyEffectEngine mBeautyEngine;
  private CameraHandler mCameraHandler;
  private FrameLayout mCameraPreviewContainer;
  private GLBufferRenderer mVideoRenderer;
  private BeautyPanelController mBeautyPanelController;
  private volatile boolean mResumeRenderOnNextFrame = false;

  // Image picker
  private ActivityResultLauncher<Intent> mImagePickerLauncher;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // Apply language settings (must be before setContentView)
    LanguageHelper.applyLanguage(this);
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_main);

    // Keep screen on to prevent screen from turning off
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

    ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
      Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
      v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
      return insets;
    });

    // Initialize UI components
    initUI();

    initBeautyEngine();

    // Initialize image picker
    initImagePicker();

    checkCameraPermission();
  }

  /**
   * Initialize image picker
   */
  private void initImagePicker() {
    mImagePickerLauncher =
        registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
          if (result.getResultCode() == RESULT_OK && result.getData() != null) {
            Uri imageUri = result.getData().getData();
            if (imageUri != null) {
              Bitmap bitmap = loadBitmapFromUri(imageUri);
              if (bitmap != null) {
                // TODO: Process selected image and set as virtual background
                // User can implement this later
                Log.d(TAG, "Image selected, size: " + bitmap.getWidth() + "x" + bitmap.getHeight());
                Toast
                    .makeText(this, getString(R.string.image_selected, bitmap.getWidth(), bitmap.getHeight()),
                        Toast.LENGTH_SHORT)
                    .show();
              } else {
                Toast.makeText(this, getString(R.string.failed_to_load_image), Toast.LENGTH_SHORT).show();
              }
            }
          }
        });
  }

  /**
   * Load Bitmap from Uri
   */
  private Bitmap loadBitmapFromUri(Uri uri) {
    try {
      InputStream inputStream = getContentResolver().openInputStream(uri);
      if (inputStream != null) {
        Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
        inputStream.close();
        return bitmap;
      }
    } catch (Exception e) {
      Log.e(TAG, "Error loading image from URI", e);
    }
    return null;
  }

  /**
   * Open image picker
   */
  private void openImagePicker() {
    Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
    intent.setType("image/*");
    mImagePickerLauncher.launch(intent);
  }

  private void initBeautyEngine() {
    // 1) Configure logging (optional)
    BeautyEffectEngine.LogConfig logConfig = new BeautyEffectEngine.LogConfig();
    logConfig.consoleEnabled = true;
    logConfig.fileEnabled = false;
    logConfig.level = BeautyEffectEngine.LogLevel.INFO;
    logConfig.fileName = "android_beauty_engine.log";
    BeautyEffectEngine.setLogConfig(logConfig);

    // 2) Create engine instance
    BeautyEffectEngine.EngineConfig config = new BeautyEffectEngine.EngineConfig();
    config.appId = "dddb24155fd045ab9c2d8aad83ad3a4a";
    config.appKey = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";

    mBeautyEngine = new BeautyEffectEngine(this, config);
    Log.d(TAG, "BeautyEffectEngine initialized");

    // 3) Enable all beauty types (actual effect requires specific parameter values)
    mBeautyEngine.enableBeautyType(BeautyType.BASIC, true);
    mBeautyEngine.enableBeautyType(BeautyType.RESHAPE, true);
    mBeautyEngine.enableBeautyType(BeautyType.MAKEUP, true);
    mBeautyEngine.enableBeautyType(BeautyType.VIRTUAL_BACKGROUND, true);
    mBeautyEngine.enableBeautyType(BeautyType.FILTER, true);

    // 4) Register filters and stickers
    registerFilters();
    registerStickers();
  }

  private void registerFilters() {
    String[] portraitFilters = {
        "confession", "cookie", "dawn", "extraordinary", "fair", "first_love",
        "initial_heart", "japanese", "lively", "milk_tea", "mousse", "natural",
        "plain", "pure", "rose", "snow", "tender", "tender_2", "vivid"
    };

    for (String filterId : portraitFilters) {
      try {
        String path = "filters/portrait/" + filterId + "/" + filterId + ".fbd";
        InputStream is = getAssets().open(path);
        int size = is.available();
        byte[] buffer = new byte[size];
        is.read(buffer);
        is.close();

        int result = mBeautyEngine.registerFilter(filterId, buffer);
        if (result == 0) {
          Log.d(TAG, "Filter registered successfully: " + filterId);
        } else {
          Log.e(TAG, "Failed to register filter: " + filterId + ", result: " + result);
        }
      } catch (Exception e) {
        Log.e(TAG, "Error registering filter: " + filterId, e);
      }
    }
  }

  private void registerStickers() {
    try {
      InputStream is = getAssets().open("stickers/face/rabbit/rabbit.fbd");
      int size = is.available();
      byte[] buffer = new byte[size];
      is.read(buffer);
      is.close();

      int result = mBeautyEngine.registerSticker("rabbit", buffer);
      if (result == 0) {
        Log.d(TAG, "rabbit sticker registered successfully");
      } else {
        Log.e(TAG, "Failed to register rabbit sticker, result: " + result);
      }
    } catch (Exception e) {
      Log.e(TAG, "Error registering rabbit sticker", e);
    }
  }

  private void initUI() {
    mCameraPreviewContainer = findViewById(R.id.camera_preview_container);

    // Create and add OpenGL video renderer
    mVideoRenderer = new GLBufferRenderer(this);
    mCameraPreviewContainer.addView(mVideoRenderer);

    // Initialize beauty panel controller - pass activity root layout
    View rootView = findViewById(R.id.main);
    mBeautyPanelController = new BeautyPanelController(rootView);

    // Set beauty parameter change callback
    mBeautyPanelController.setBeautyParamCallback(new BeautyPanelController.BeautyParamCallback() {
      @Override
      public void onBeautyParamChanged(String tab, String function, float value) {
        applyBeautyParam(tab, function, value);
      }

      @Override
      public void onBeautyReset() {
        resetAllBeautyParams();
      }

      @Override
      public void onBeautyTabReset(String tab) {
        resetBeautyTab(tab);
      }

      @Override
      public void onImageSelectionRequested(String tab, String function) {
        // Open image picker
        openImagePicker();
      }
    });

    // Get initial Tab parameter passed from home page
    String initialTab = getIntent().getStringExtra("initial_tab");
    if (initialTab != null && !initialTab.isEmpty()) {
      // Delay tab switch to ensure panel is already displayed
      rootView.post(() -> {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab(initialTab);
      });
    }

    // Top buttons
    findViewById(R.id.btn_close).setOnClickListener(v -> finish());
    findViewById(R.id.btn_gallery).setOnClickListener(v -> {
      // TODO: Open gallery
      android.widget.Toast.makeText(this, getString(R.string.open_gallery), android.widget.Toast.LENGTH_SHORT).show();
    });
    findViewById(R.id.btn_flip_camera).setOnClickListener(v -> {
      if (mCameraHandler != null) {
        if (mVideoRenderer != null) {
          // Pause rendering and clear current frame to avoid accessing invalid buffer during switch
          mVideoRenderer.setRenderingEnabled(false);
          mVideoRenderer.renderFrame(null);
        }
        mResumeRenderOnNextFrame = true;
        mCameraHandler.switchCamera();
        android.widget.Toast.makeText(this, getString(R.string.camera_switched), android.widget.Toast.LENGTH_SHORT)
            .show();
      }
    });
    findViewById(R.id.btn_more).setOnClickListener(v -> {
      // TODO: More options
      android.widget.Toast.makeText(this, getString(R.string.more_options), android.widget.Toast.LENGTH_SHORT).show();
    });

    // Before/After compare button
    findViewById(R.id.btn_before_after).setOnClickListener(v -> {
      // TODO: Show compare effect
      android.widget.Toast.makeText(this, getString(R.string.compare_effect), android.widget.Toast.LENGTH_SHORT).show();
    });

    // Bottom buttons
    findViewById(R.id.btn_beauty_shape).setOnClickListener(v -> {
      mBeautyPanelController.togglePanel();
    });
    findViewById(R.id.btn_makeup).setOnClickListener(v -> {
      if (mBeautyPanelController != null) {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab("makeup");
      }
    });
    findViewById(R.id.btn_capture).setOnClickListener(v -> {
      // TODO: Capture photo
      android.widget.Toast.makeText(this, getString(R.string.capture), android.widget.Toast.LENGTH_SHORT).show();
    });
    findViewById(R.id.btn_sticker).setOnClickListener(v -> {
      if (mBeautyPanelController != null) {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab("sticker");
      }
    });
    findViewById(R.id.btn_filter).setOnClickListener(v -> {
      if (mBeautyPanelController != null) {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab("filter");
      }
    });
  }

  public void setupCamera() {
    if (mCameraHandler == null) {
      mCameraHandler = new CameraHandler(this);

      // Set frame callback
      mCameraHandler.setFrameCallback(new CameraHandler.FrameCallback() {
        @Override
        public void onFrameAvailable(Image image, int orientation) {
          final long startNs = System.nanoTime();
          try {
            // Process camera frame data here
            if (image == null) {
              Log.w(TAG, "onFrameAvailable: image is null");
              return;
            }

            // Get image planes
            Image.Plane[] planes = image.getPlanes();
            ByteBuffer yBuffer = planes[0].getBuffer();
            ByteBuffer uBuffer = planes[1].getBuffer();
            ByteBuffer vBuffer = planes[2].getBuffer();

            int yStride = planes[0].getRowStride();
            int uStride = planes[1].getRowStride();
            int vStride = planes[2].getRowStride();

            int uPixelStride = planes[1].getPixelStride();
            int width = image.getWidth();
            int height = image.getHeight();

            // Create input frame from camera data using ByteBuffer directly
            ImageFrame input = ImageFrame.createWithAndroid420(
                width, height, yBuffer, yStride, uBuffer, uStride, vBuffer, vStride, uPixelStride);
            if (input != null) {
              if (mCameraHandler != null && mCameraHandler.isFrontFacing()) {
                input.rotate(ImageFrame.Rotation.ROTATION_270);
                if (mVideoRenderer != null)
                  mVideoRenderer.setMirror(true);
              } else {
                input.rotate(ImageFrame.Rotation.ROTATION_90);
                if (mVideoRenderer != null)
                  mVideoRenderer.setMirror(false);
              }
              if (mResumeRenderOnNextFrame && mVideoRenderer != null) {
                mVideoRenderer.setRenderingEnabled(true);
                mResumeRenderOnNextFrame = false;
              }
              input.type = ImageFrame.FrameType.VIDEO;
              ImageFrame output = mBeautyEngine.processImage(input);

              if (output != null) {
                if (mVideoRenderer != null) {
                  mVideoRenderer.renderFrame(output);
                }
              }

              input.release();
            } else {
              Log.w(TAG, "Failed to process frame - output is null");
            }
          } finally {
            long elapsedUs = (System.nanoTime() - startNs) / 1000L;
          }
        }
      });

      // Start camera
      mCameraHandler.startCamera();
    }
  }

  public void checkCameraPermission() {
    // Check camera permission
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        != PackageManager.PERMISSION_GRANTED) {
      // If no camera permission, request permission
      ActivityCompat.requestPermissions(
          this, new String[] {Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST_CODE);
    } else {
      // Has permission, set up camera
      setupCamera();
    }
  }

  @Override
  public void onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        setupCamera();
      } else {
        Toast.makeText(this, "No camera permission!", LENGTH_LONG).show();
      }
    }
  }

  @Override
  protected void onResume() {
    super.onResume();

    if (mCameraHandler != null && !mCameraHandler.isCameraOpened()) {
      mCameraHandler.startCamera();
    }
  }

  @Override
  protected void onPause() {
    super.onPause();

    if (mCameraHandler != null) {
      mCameraHandler.stopCamera();
    }
  }

  @Override
  public void onBackPressed() {
    // If beauty panel is open, close it first
    if (mBeautyPanelController != null && mBeautyPanelController.isPanelVisible()) {
      mBeautyPanelController.hidePanel();
      return;
    }
    super.onBackPressed();
  }

  /**
   * Apply beauty parameters
   */
  private void applyBeautyParam(String tab, String function, float value) {
    if (mBeautyEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }

    try {
      switch (tab) {
        case "beauty":
          // Basic beauty parameters
          switch (function) {
            case "white":
              mBeautyEngine.setBeautyParam(BasicParam.WHITENING, value);
              Log.d(TAG, "Set WHITENING: " + value);
              break;
            case "smooth":
              mBeautyEngine.setBeautyParam(BasicParam.SMOOTHING, value);
              Log.d(TAG, "Set SMOOTHING: " + value);
              break;
            case "rosiness":
              mBeautyEngine.setBeautyParam(BasicParam.ROSINESS, value);
              Log.d(TAG, "Set ROSINESS: " + value);
              break;
            default:
              Log.w(TAG, "Unknown beauty function: " + function);
              break;
          }
          break;

        case "reshape":
          // Face reshape parameters
          ReshapeParam reshapeParam = mapToReshapeParam(function);
          if (reshapeParam != null) {
            mBeautyEngine.setBeautyParam(reshapeParam, value);
            Log.d(TAG, "Set " + reshapeParam + ": " + value);
          } else {
            Log.w(TAG, "Unknown reshape function: " + function);
          }
          break;

        case "makeup":
          // Makeup parameters
          MakeupParam makeupParam = mapToMakeupParam(function);
          if (makeupParam != null) {
            mBeautyEngine.setBeautyParam(makeupParam, value);
            Log.d(TAG, "Set " + makeupParam + ": " + value);
          } else {
            Log.w(TAG, "Unknown makeup function: " + function);
          }
          break;

        case "virtual_bg":
          // Virtual background: blur, preset, image, none
          VirtualBackgroundOptions options = new VirtualBackgroundOptions();
          if ("none".equals(function)) {
            // Disable virtual background
            options.mode = BackgroundMode.NONE;
            mBeautyEngine.setVirtualBackground(options);
            Log.d(TAG, "Set virtual background: NONE");
          } else if ("blur".equals(function)) {
            // Blur background
            options.mode = BackgroundMode.BLUR;
            mBeautyEngine.setVirtualBackground(options);
            Log.d(TAG, "Set virtual background: BLUR");
          } else if ("preset".equals(function)) {
            // Preset background: use video_background.jpg
            Bitmap presetBitmap =
                BitmapFactory.decodeResource(getResources(), R.drawable.back_mobile);
            if (presetBitmap != null) {
              ImageFrame imageFrame = ImageFrame.createWithBitmap(presetBitmap);
              if (imageFrame != null) {
                options.mode = BackgroundMode.IMAGE;
                options.backgroundImage = imageFrame;
                mBeautyEngine.setVirtualBackground(options);
                Log.d(TAG,
                    "Preset background set: " + presetBitmap.getWidth() + "x"
                        + presetBitmap.getHeight());
              } else {
                Log.e(TAG, "Failed to create ImageFrame from bitmap");
                Toast.makeText(this, getString(R.string.failed_to_load_preset_background), Toast.LENGTH_SHORT).show();
              }
            } else {
              Log.e(TAG, "Failed to load preset background bitmap");
              Toast.makeText(this, getString(R.string.failed_to_load_preset_background_image), Toast.LENGTH_SHORT).show();
            }
          } else if (function != null && function.startsWith("image")) {
            // Background image switch (select from gallery)
            // options.mode = BackgroundMode.IMAGE;
            // options.backgroundImage = imageFrame; // Need to provide ImageFrame
            // mBeautyEngine.setVirtualBackground(options);
            Log.w(TAG, "BACKGROUND_IMAGE not implemented, function=" + function);
          } else {
            Log.w(TAG, "Unknown virtual_bg function: " + function);
          }
          break;

        case "filter":
          if ("none".equals(function) || value == 0.0f) {
            mBeautyEngine.enableBeautyType(BeautyType.FILTER, false);
            mBeautyEngine.setFilter("");
            Log.d(TAG, "Filter disabled");
          } else {
            mBeautyEngine.enableBeautyType(BeautyType.FILTER, true);
            mBeautyEngine.setFilter(function);
            mBeautyEngine.setFilterIntensity(1.0f);
            Log.d(TAG, "Set filter: " + function);
          }
          break;

        case "sticker":
          if ("none".equals(function) || value == 0.0f) {
            mBeautyEngine.setSticker("");
            Log.d(TAG, "Sticker disabled");
          } else {
            mBeautyEngine.setSticker(function);
            Log.d(TAG, "Set sticker: " + function);
          }
          break;

        default:
          Log.w(TAG, "Unknown tab: " + tab);
          break;
      }
    } catch (Exception e) {
      Log.e(TAG, "Error applying beauty param", e);
    }
  }

  /**
   * Map function string to ReshapeParam
   */
  private ReshapeParam mapToReshapeParam(String function) {
    switch (function) {
      case "thin_face":
        return ReshapeParam.FACE_THIN;
      case "v_face":
        return ReshapeParam.FACE_V_SHAPE;
      case "narrow_face":
        return ReshapeParam.FACE_NARROW;
      case "short_face":
        return ReshapeParam.FACE_SHORT;
      case "cheekbone":
        return ReshapeParam.CHEEKBONE;
      case "jawbone":
        return ReshapeParam.JAWBONE;
      case "chin":
        return ReshapeParam.CHIN;
      case "nose_slim":
        return ReshapeParam.NOSE_SLIM;
      case "big_eye":
        return ReshapeParam.EYE_SIZE;
      case "eye_distance":
        return ReshapeParam.EYE_DISTANCE;
      default:
        return null;
    }
  }

  /**
   * Map function string to MakeupParam
   */
  private MakeupParam mapToMakeupParam(String function) {
    switch (function) {
      case "lipstick":
        return MakeupParam.LIPSTICK;
      case "blush":
        return MakeupParam.BLUSH;
      default:
        return null;
    }
  }

  /**
   * Reset all beauty parameters
   */
  private void resetAllBeautyParams() {
    if (mBeautyEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }

    try {
      // Reset basic beauty parameters
      mBeautyEngine.setBeautyParam(BasicParam.WHITENING, 0.0f);
      mBeautyEngine.setBeautyParam(BasicParam.SMOOTHING, 0.0f);
      mBeautyEngine.setBeautyParam(BasicParam.ROSINESS, 0.0f);

      // Reset face reshape parameters
      mBeautyEngine.setBeautyParam(ReshapeParam.FACE_THIN, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.FACE_V_SHAPE, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.FACE_NARROW, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.FACE_SHORT, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.CHEEKBONE, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.JAWBONE, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.CHIN, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.NOSE_SLIM, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.EYE_SIZE, 0.0f);
      mBeautyEngine.setBeautyParam(ReshapeParam.EYE_DISTANCE, 0.0f);

      // Reset makeup parameters
      mBeautyEngine.setBeautyParam(MakeupParam.LIPSTICK, 0.0f);
      mBeautyEngine.setBeautyParam(MakeupParam.BLUSH, 0.0f);
      // Reset virtual background parameters
      VirtualBackgroundOptions options = new VirtualBackgroundOptions();
      options.mode = BackgroundMode.NONE;
      mBeautyEngine.setVirtualBackground(options);

      // Reset filter
      mBeautyEngine.enableBeautyType(BeautyType.FILTER, false);
      mBeautyEngine.setFilter("");
      mBeautyEngine.setFilterIntensity(0.0f);

      Log.d(TAG, "All beauty params reset to 0");
    } catch (Exception e) {
      Log.e(TAG, "Error resetting beauty params", e);
    }
  }

  /**
   * Reset all parameters for specified Tab
   */
  private void resetBeautyTab(String tab) {
    if (mBeautyEngine == null)
      return;
    try {
      switch (tab) {
        case "beauty":
          mBeautyEngine.setBeautyParam(BasicParam.WHITENING, 0.0f);
          mBeautyEngine.setBeautyParam(BasicParam.SMOOTHING, 0.0f);
          mBeautyEngine.setBeautyParam(BasicParam.ROSINESS, 0.0f);
          break;
        case "reshape":
          mBeautyEngine.setBeautyParam(ReshapeParam.FACE_THIN, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.FACE_V_SHAPE, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.FACE_NARROW, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.FACE_SHORT, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.CHEEKBONE, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.JAWBONE, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.CHIN, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.NOSE_SLIM, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.EYE_SIZE, 0.0f);
          mBeautyEngine.setBeautyParam(ReshapeParam.EYE_DISTANCE, 0.0f);
          break;
        case "makeup":
          mBeautyEngine.setBeautyParam(MakeupParam.LIPSTICK, 0.0f);
          mBeautyEngine.setBeautyParam(MakeupParam.BLUSH, 0.0f);
          break;
        case "virtual_bg":
          // Reset virtual background
          VirtualBackgroundOptions options = new VirtualBackgroundOptions();
          options.mode = BackgroundMode.NONE;
          mBeautyEngine.setVirtualBackground(options);
          break;
        case "filter":
          mBeautyEngine.enableBeautyType(BeautyType.FILTER, false);
          mBeautyEngine.setFilter("");
          mBeautyEngine.setFilterIntensity(0.0f);
          break;
        case "sticker":
        case "body":
        case "quality":
        default:
          break;
      }
    } catch (Exception e) {
      Log.e(TAG, "resetBeautyTab error", e);
    }
  }

  @Override
  protected void onDestroy() {
    // Release camera resources
    if (mCameraHandler != null) {
      mCameraHandler.stopCamera();
      mCameraHandler = null;
    }

    // Release video renderer
    if (mVideoRenderer != null) {
      mVideoRenderer = null;
    }

    if (mBeautyEngine != null) {
      mBeautyEngine.release();
    }

    super.onDestroy();
  }
}
