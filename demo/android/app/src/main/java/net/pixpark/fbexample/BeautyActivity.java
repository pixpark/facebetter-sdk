package net.pixpark.fbexample;

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
import net.pixpark.facebetter.BeautyEffectEngine;
import net.pixpark.facebetter.BeautyParams.BeautyType;
import net.pixpark.facebetter.ImageFrame;
import net.pixpark.fbexample.beautypanel.BeautyBarHandler;
import net.pixpark.fbexample.beautypanel.BeautyBarListener;
import net.pixpark.fbexample.beautypanel.BeautyPanelController;
import net.pixpark.fbexample.beautypanel.BeautyParamApplier;

import java.io.InputStream;
import java.nio.ByteBuffer;

public class BeautyActivity extends AppCompatActivity implements GLI420Renderer.FrameProvider {
  private static final String TAG = "BeautyActivity";
  private static final int CAMERA_PERMISSION_REQUEST_CODE = 200;

  private BeautyEffectEngine mBeautyEngine;
  private BeautyParamApplier mBeautyParamApplier;
  private CameraHandler mCameraHandler;
  private FrameLayout mCameraPreviewContainer;
  private GLI420Renderer mVideoRenderer;
  private BeautyPanelController mBeautyPanelController;
  private volatile boolean mResumeRenderOnNextFrame = false;

  // Image mode
  private Bitmap mSelectedBitmap = null;
  private boolean mIsImageMode = false;
  
  // Store the latest camera frame
  private ImageFrame mLatestCameraFrame;
  private final Object mFrameLock = new Object();
  // Flag to indicate if the next frame should be saved
  private volatile boolean mShouldSaveFrame = false;

  // Image picker
  private ActivityResultLauncher<Intent> mImagePickerLauncher;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    LanguageHelper.applyLanguage(this);
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_main);

    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

    ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
      Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
      v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
      return insets;
    });

    initPreview();
    setupBeautyPanel();
    new BeautyBarHandler(findViewById(R.id.main), createBarListener());

    initBeautyEngine();

    initImagePicker();

    checkCameraPermission();
  }

  private void prepareSelectedImage() {
    if (mSelectedBitmap == null || mBeautyEngine == null || mVideoRenderer == null) {
      return;
    }

    final Bitmap bitmapToProcess = scaleBitmapIfNeeded(mSelectedBitmap);
    synchronized (mFrameLock) {
      mIsImageMode = true;
      mSelectedBitmap = bitmapToProcess;
    }
    
    if (mVideoRenderer != null) {
      mVideoRenderer.setRenderingEnabled(true);
      mVideoRenderer.requestRender();
    }
  }

  /** Scale down bitmap if exceeds 1920x1080, keep aspect ratio. */
  private Bitmap scaleBitmapIfNeeded(Bitmap bitmap) {
    final int MAX_LONG_SIDE = 1920;
    final int MAX_SHORT_SIDE = 1080;

    int width = bitmap.getWidth();
    int height = bitmap.getHeight();

    int longSide = Math.max(width, height);
    int shortSide = Math.min(width, height);
    if (longSide <= MAX_LONG_SIDE && shortSide <= MAX_SHORT_SIDE) {
      return bitmap;
    }
    float scaleFactor = Math.min(
        (float) MAX_LONG_SIDE / longSide,
        (float) MAX_SHORT_SIDE / shortSide
    );
    int newWidth = Math.round(width * scaleFactor);
    int newHeight = Math.round(height * scaleFactor);
    Bitmap scaledBitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true);
    Log.d(TAG, "Scaled image from " + width + "x" + height + " to " + newWidth + "x" + newHeight);

    return scaledBitmap;
  }

  private void initImagePicker() {
    mImagePickerLauncher =
        registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
          if (result.getResultCode() == RESULT_OK && result.getData() != null) {
            Uri imageUri = result.getData().getData();
            if (imageUri != null) {
              Bitmap bitmap = loadBitmapFromUri(imageUri);
              if (bitmap != null) {
                mSelectedBitmap = bitmap;
                mIsImageMode = true;

                if (mCameraHandler != null) {
                  mCameraHandler.stopCamera();
                }
                prepareSelectedImage();

                Log.d(TAG, "Image selected, size: " + bitmap.getWidth() + "x" + bitmap.getHeight());
              } else {
                Toast.makeText(this, getString(R.string.failed_to_load_image), Toast.LENGTH_SHORT).show();
              }
            }
          }
        });
  }

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

  private void openImagePicker() {
    Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
    intent.setType("image/*");
    mImagePickerLauncher.launch(intent);
  }

  private void initBeautyEngine() {
    BeautyEffectEngine.LogConfig logConfig = new BeautyEffectEngine.LogConfig();
    logConfig.consoleEnabled = true;
    logConfig.fileEnabled = false;
    logConfig.level = BeautyEffectEngine.LogLevel.INFO;
    logConfig.fileName = "android_beauty_engine.log";
    BeautyEffectEngine.setLogConfig(logConfig);

    BeautyEffectEngine.EngineConfig config = new BeautyEffectEngine.EngineConfig();
    config.appId = "dddb24155fd045ab9c2d8aad83ad3a4a";
    config.appKey = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";

    mBeautyEngine = new BeautyEffectEngine(this, config);
    mBeautyParamApplier = new BeautyParamApplier(this, mBeautyEngine);
    Log.d(TAG, "BeautyEffectEngine initialized");

    mBeautyEngine.enableBeautyType(BeautyType.BASIC, true);
    mBeautyEngine.enableBeautyType(BeautyType.RESHAPE, true);
    mBeautyEngine.enableBeautyType(BeautyType.MAKEUP, true);
    mBeautyEngine.enableBeautyType(BeautyType.VIRTUAL_BACKGROUND, true);
    mBeautyEngine.enableBeautyType(BeautyType.FILTER, true);

    BeautyResourceLoader.registerFilters(mBeautyEngine, this);
    BeautyResourceLoader.registerStickers(mBeautyEngine, this);
  }

  private void initPreview() {
    mCameraPreviewContainer = findViewById(R.id.camera_preview_container);
    mVideoRenderer = new GLI420Renderer(this);
    mVideoRenderer.setFrameProvider(this);
    mCameraPreviewContainer.addView(mVideoRenderer);
  }

  private void setupBeautyPanel() {
    View rootView = findViewById(R.id.main);
    mBeautyPanelController = new BeautyPanelController(rootView);
    mBeautyPanelController.setBeautyParamCallback(new BeautyPanelController.BeautyParamCallback() {
      @Override
      public void onBeautyParamChanged(String tab, String function, float value) {
        if (mBeautyParamApplier != null) {
          mBeautyParamApplier.apply(tab, function, value);
        }
        if (mIsImageMode) {
          prepareSelectedImage();
        }
      }

      @Override
      public void onBeautyReset() {
        if (mBeautyParamApplier != null) {
          mBeautyParamApplier.resetAll();
        }
        if (mIsImageMode) {
          mIsImageMode = false;
          mSelectedBitmap = null;
          if (mVideoRenderer != null) {
            mVideoRenderer.releaseCurrentFrame();
          }
          if (mCameraHandler != null) {
            mCameraHandler.startCamera();
          }
        }
      }

      @Override
      public void onBeautyTabReset(String tab) {
        if (mBeautyParamApplier != null) {
          mBeautyParamApplier.resetTab(tab);
        }
      }

      @Override
      public void onImageSelectionRequested(String tab, String function) {
        openImagePicker();
      }

      @Override
      public void onCaptureRequested() {
        captureAndSaveImage();
      }
    });

    String initialTab = getIntent().getStringExtra("initial_tab");
    if (initialTab != null && !initialTab.isEmpty()) {
      rootView.post(() -> {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab(initialTab);
      });
    }
  }

  private BeautyBarListener createBarListener() {
    return new BeautyBarListener() {
      @Override
      public void onClose() {
        finish();
      }

      @Override
      public void onOpenGallery() {
        openImagePicker();
      }

      @Override
      public void onFlipCamera() {
        if (mIsImageMode) {
          mIsImageMode = false;
          mSelectedBitmap = null;
          if (mVideoRenderer != null) mVideoRenderer.releaseCurrentFrame();
          if (mCameraHandler != null) mCameraHandler.startCamera();
          Toast.makeText(BeautyActivity.this, "Back to Camera", Toast.LENGTH_SHORT).show();
          return;
        }
        if (mCameraHandler == null) return;
        if (mVideoRenderer != null) {
          mVideoRenderer.setRenderingEnabled(false);
          synchronized (mFrameLock) {
            if (mLatestCameraFrame != null) {
              mLatestCameraFrame.release();
              mLatestCameraFrame = null;
            }
          }
        }
        mResumeRenderOnNextFrame = true;
        mCameraHandler.switchCamera();
        Toast.makeText(BeautyActivity.this, getString(R.string.camera_switched), Toast.LENGTH_SHORT).show();
      }

      @Override
      public void onMore() {
        Toast.makeText(BeautyActivity.this, getString(R.string.more_options), Toast.LENGTH_SHORT).show();
      }

      @Override
      public void onBeforeAfter() {
        Toast.makeText(BeautyActivity.this, getString(R.string.compare_effect), Toast.LENGTH_SHORT).show();
      }

      @Override
      public void onBeautyPanelToggle() {
        mBeautyPanelController.togglePanel();
      }

      @Override
      public void onOpenPanelTab(String tab) {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab(tab);
      }

      @Override
      public void onCapture() {
        captureAndSaveImage();
      }
    };
  }

  public void setupCamera() {
    if (mCameraHandler == null) {
      mCameraHandler = new CameraHandler(this);

      mCameraHandler.setFrameCallback(new CameraHandler.FrameCallback() {
        @Override
        public void onFrameAvailable(Image image, int orientation) {
          if (mIsImageMode) {
            if (image != null) {
              image.close();
            }
            return;
          }
          final long startNs = System.nanoTime();
          try {
            if (image == null) {
              Log.w(TAG, "onFrameAvailable: image is null");
              return;
            }

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

            ImageFrame input = ImageFrame.createWithAndroid420(
                width, height, yBuffer, yStride, uBuffer, uStride, vBuffer, vStride, uPixelStride);
            if (input != null) {
              if (mCameraHandler != null && mCameraHandler.isFrontFacing()) {
                input.rotate(ImageFrame.Rotation.ROTATION_270);
                input.mirror("horizontal");
              } else {
                input.rotate(ImageFrame.Rotation.ROTATION_90);
              }
              if (mResumeRenderOnNextFrame && mVideoRenderer != null) {
                mVideoRenderer.setRenderingEnabled(true);
                mResumeRenderOnNextFrame = false;
              }
              input.type = ImageFrame.FrameType.VIDEO;
              
              synchronized (mFrameLock) {
                if (mLatestCameraFrame != null) {
                  mLatestCameraFrame.release();
                }
                mLatestCameraFrame = input;
              }
              if (mVideoRenderer != null) {
                mVideoRenderer.requestRender();
              }

            } else {
              Log.w(TAG, "Failed to process frame - output is null");
            }
          } finally {
            long elapsedUs = (System.nanoTime() - startNs) / 1000L;
          }
        }
      });

      mCameraHandler.startCamera();
    }
  }

  public void checkCameraPermission() {
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        != PackageManager.PERMISSION_GRANTED) {
      ActivityCompat.requestPermissions(
          this, new String[] {Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST_CODE);
    } else {
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
    if (mBeautyPanelController != null && mBeautyPanelController.isPanelVisible()) {
      mBeautyPanelController.hidePanel();
      return;
    }
    super.onBackPressed();
  }

  @Override
  public ImageFrame getCurrentFrame() {
    synchronized (mFrameLock) {
      ImageFrame resultFrame = null;
      ImageFrame outputFrame = null;
      
      if (mIsImageMode) {
        if (mSelectedBitmap != null) {
          try {
            ImageFrame input = ImageFrame.createWithBitmap(mSelectedBitmap);
            if (input != null) {
              input.type = ImageFrame.FrameType.IMAGE;
              outputFrame = mBeautyEngine.processImage(input);
              if (outputFrame != null) {
                ImageFrame i420Output = outputFrame.convert(ImageFrame.Format.I420);
                if (i420Output != null) {
                  resultFrame = i420Output;
                }
              }
              input.release();
            }
          } catch (Exception e) {
            Log.e(TAG, "Error processing image in getCurrentFrame", e);
          }
        }
      } else {
        if (mLatestCameraFrame != null) {
          try {
            outputFrame = mBeautyEngine.processImage(mLatestCameraFrame);

            if (outputFrame != null) {
              resultFrame = outputFrame;
            }
          } catch (Exception e) {
            Log.e(TAG, "Error processing camera frame in getCurrentFrame", e);
          }
        }
      }
      
      if (mShouldSaveFrame && outputFrame != null) {
        mShouldSaveFrame = false;
        CaptureFrameSaver.save(outputFrame, this, new CaptureFrameSaver.SaveResultListener() {
          @Override
          public void onSuccess() {
            runOnUiThread(() -> CaptureFrameSaver.showSaveResultToast(BeautyActivity.this, true));
          }

          @Override
          public void onFailure() {
            runOnUiThread(() -> CaptureFrameSaver.showSaveResultToast(BeautyActivity.this, false));
          }
        });
      }

      return resultFrame;
    }
  }
  
  @Override
  public void releaseFrame(ImageFrame frame) {
    if (frame != null) {
      frame.release();
    }
  }

  private void captureAndSaveImage() {
    mShouldSaveFrame = true;
    if (mVideoRenderer != null) {
      mVideoRenderer.requestRender();
    }
  }

  @Override
  protected void onDestroy() {
    if (mCameraHandler != null) {
      mCameraHandler.stopCamera();
      mCameraHandler = null;
    }

    if (mVideoRenderer != null) {
      mVideoRenderer = null;
    }

    synchronized (mFrameLock) {
      if (mLatestCameraFrame != null) {
        mLatestCameraFrame.release();
        mLatestCameraFrame = null;
      }
    }

    if (mBeautyEngine != null) {
      mBeautyEngine.release();
    }

    super.onDestroy();
  }
}
