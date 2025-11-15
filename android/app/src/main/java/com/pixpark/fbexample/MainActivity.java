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
import android.widget.Button;
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
import java.io.InputStream;
import com.pixpark.facebetter.BeautyEffectEngine;
import com.pixpark.facebetter.BeautyParams.*;
import com.pixpark.facebetter.ImageBuffer;
import com.pixpark.facebetter.ImageFrame;
import java.nio.ByteBuffer;

public class MainActivity extends AppCompatActivity {
  private static final String TAG = "MainActivity";
  private static final int CAMERA_PERMISSION_REQUEST_CODE = 200;

  private BeautyEffectEngine mBeautyEngine;
  private CameraHandler mCameraHandler;
  private FrameLayout mCameraPreviewContainer;
  private GLVideoRenderer mVideoRenderer;
  private BeautyPanelController mBeautyPanelController;
  private volatile boolean mResumeRenderOnNextFrame = false;
  
  // 图片选择器
  private ActivityResultLauncher<Intent> mImagePickerLauncher;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_main);

    // 保持屏幕常亮，防止息屏
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

    ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
      Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
      v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
      return insets;
    });

    // Initialize UI components
    initUI();

    initBeautyEngine();
    
    // 初始化图片选择器
    initImagePicker();

    checkCameraPermission();
  }
  
  /**
   * 初始化图片选择器
   */
  private void initImagePicker() {
    mImagePickerLauncher = registerForActivityResult(
        new ActivityResultContracts.StartActivityForResult(),
        result -> {
          if (result.getResultCode() == RESULT_OK && result.getData() != null) {
            Uri imageUri = result.getData().getData();
            if (imageUri != null) {
              Bitmap bitmap = loadBitmapFromUri(imageUri);
              if (bitmap != null) {
                // TODO: 处理选中的图片，设置虚拟背景
                // 这里用户后续自己实现
                Log.d(TAG, "Image selected, size: " + bitmap.getWidth() + "x" + bitmap.getHeight());
                Toast.makeText(this, "图片已选择: " + bitmap.getWidth() + "x" + bitmap.getHeight(), Toast.LENGTH_SHORT).show();
              } else {
                Toast.makeText(this, "无法加载图片", Toast.LENGTH_SHORT).show();
              }
            }
          }
        });
  }
  
  /**
   * 从 Uri 加载 Bitmap
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
   * 打开图片选择器
   */
  private void openImagePicker() {
    Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
    intent.setType("image/*");
    mImagePickerLauncher.launch(intent);
  }

  private void initBeautyEngine() {
    // 1) 配置日志（可选）
    BeautyEffectEngine.LogConfig logConfig = new BeautyEffectEngine.LogConfig();
    logConfig.consoleEnabled = true;
    logConfig.fileEnabled = false;
    logConfig.level = BeautyEffectEngine.LogLevel.INFO;
    logConfig.fileName = "android_beauty_engine.log";
    BeautyEffectEngine.setLogConfig(logConfig);

    // 2) 创建引擎实例
    BeautyEffectEngine.EngineConfig config = new BeautyEffectEngine.EngineConfig();
    config.appId = "";
    config.appKey = "";

    mBeautyEngine = new BeautyEffectEngine(this, config);
    Log.d(TAG, "BeautyEffectEngine initialized");

    // 3) 启用所有美颜类型（实际生效需配合具体参数值）
    mBeautyEngine.enableBeautyType(BeautyType.BASIC, true);
    mBeautyEngine.enableBeautyType(BeautyType.RESHAPE, true);
    mBeautyEngine.enableBeautyType(BeautyType.MAKEUP, true);
    mBeautyEngine.enableBeautyType(BeautyType.VIRTUAL_BACKGROUND, true);
  }

  private void initUI() {
    mCameraPreviewContainer = findViewById(R.id.camera_preview_container);

    // Create and add OpenGL video renderer
    mVideoRenderer = new GLVideoRenderer(this);
    mCameraPreviewContainer.addView(mVideoRenderer);

    // 初始化美颜面板控制器 - 传入 activity 的根布局
    View rootView = findViewById(R.id.main);
    mBeautyPanelController = new BeautyPanelController(rootView);
    
    // 设置美颜参数变化回调
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
        // 打开图片选择器
        openImagePicker();
      }
    });

    // 获取从主页传递的初始 Tab 参数
    String initialTab = getIntent().getStringExtra("initial_tab");
    if (initialTab != null && !initialTab.isEmpty()) {
      // 延迟切换 Tab，确保面板已经显示
      rootView.post(() -> {
        mBeautyPanelController.showPanel();
        mBeautyPanelController.switchToTab(initialTab);
      });
        }

    // 顶部按钮
    findViewById(R.id.btn_close).setOnClickListener(v -> finish());
    findViewById(R.id.btn_gallery).setOnClickListener(v -> {
      // TODO: 打开相册
      android.widget.Toast.makeText(this, "打开相册", android.widget.Toast.LENGTH_SHORT).show();
    });
    findViewById(R.id.btn_flip_camera).setOnClickListener(v -> {
      if (mCameraHandler != null) {
        if (mVideoRenderer != null) {
          // 暂停渲染并清空当前帧，避免切换过程中访问失效缓冲
          mVideoRenderer.setRenderingEnabled(false);
          mVideoRenderer.renderBuffer(null);
        }
        mResumeRenderOnNextFrame = true;
        mCameraHandler.switchCamera();
        android.widget.Toast.makeText(this, "已切换摄像头", android.widget.Toast.LENGTH_SHORT).show();
      }
    });
    findViewById(R.id.btn_more).setOnClickListener(v -> {
      // TODO: 更多选项
      android.widget.Toast.makeText(this, "更多选项", android.widget.Toast.LENGTH_SHORT).show();
    });

    // Before/After 对比按钮
    findViewById(R.id.btn_before_after).setOnClickListener(v -> {
      // TODO: 显示对比效果
      android.widget.Toast.makeText(this, "对比效果", android.widget.Toast.LENGTH_SHORT).show();
    });

    // 底部按钮
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
      // TODO: 拍照
      android.widget.Toast.makeText(this, "拍照", android.widget.Toast.LENGTH_SHORT).show();
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
                input.rotate(ImageBuffer.Rotation.ROTATION_270);
                if (mVideoRenderer != null) mVideoRenderer.setMirror(true);
              } else {
                input.rotate(ImageBuffer.Rotation.ROTATION_90);
                if (mVideoRenderer != null) mVideoRenderer.setMirror(false);
              }
              if (mResumeRenderOnNextFrame && mVideoRenderer != null) {
                mVideoRenderer.setRenderingEnabled(true);
                mResumeRenderOnNextFrame = false;
              }
              ImageFrame output =
                  mBeautyEngine.processImage(input, BeautyEffectEngine.ProcessMode.VIDEO);

              if (output != null) {
                if (mVideoRenderer != null) {
                  ImageBuffer buffer = output.toI420();
                  mVideoRenderer.renderBuffer(buffer);
                }
                output.release();
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
    // 如果美颜面板打开，先关闭面板
    if (mBeautyPanelController != null && mBeautyPanelController.isPanelVisible()) {
      mBeautyPanelController.hidePanel();
      return;
    }
    super.onBackPressed();
  }

  /**
   * 应用美颜参数
   */
  private void applyBeautyParam(String tab, String function, float value) {
    if (mBeautyEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }
    
    try {
      switch (tab) {
        case "beauty":
          // 基础美颜参数
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
          // 面部重塑参数
          ReshapeParam reshapeParam = mapToReshapeParam(function);
          if (reshapeParam != null) {
            mBeautyEngine.setBeautyParam(reshapeParam, value);
            Log.d(TAG, "Set " + reshapeParam + ": " + value);
          } else {
            Log.w(TAG, "Unknown reshape function: " + function);
          }
          break;
          
        case "makeup":
          // 美妆参数
          MakeupParam makeupParam = mapToMakeupParam(function);
          if (makeupParam != null) {
            mBeautyEngine.setBeautyParam(makeupParam, value);
            Log.d(TAG, "Set " + makeupParam + ": " + value);
          } else {
            Log.w(TAG, "Unknown makeup function: " + function);
          }
          break;
        
        case "virtual_bg":
          // 虚拟背景：模糊、预置、图片、关闭
          VirtualBackgroundOptions options = new VirtualBackgroundOptions();
          if ("none".equals(function)) {
            // 关闭虚拟背景
            options.mode = BackgroundMode.NONE;
            mBeautyEngine.setVirtualBackground(options);
            Log.d(TAG, "Set virtual background: NONE");
          } else if ("blur".equals(function)) {
            // 模糊背景
            options.mode = BackgroundMode.BLUR;
            mBeautyEngine.setVirtualBackground(options);
            Log.d(TAG, "Set virtual background: BLUR");
          } else if ("preset".equals(function)) {
            // 预置背景：使用 video_background.jpg
            Bitmap presetBitmap = BitmapFactory.decodeResource(getResources(), R.drawable.back_mobile);
            if (presetBitmap != null) {
              ImageFrame imageFrame = ImageFrame.createWithBitmap(presetBitmap);
              if (imageFrame != null) {
                options.mode = BackgroundMode.IMAGE;
                options.backgroundImage = imageFrame;
                mBeautyEngine.setVirtualBackground(options);
                Log.d(TAG, "Preset background set: " + presetBitmap.getWidth() + "x" + presetBitmap.getHeight());
              } else {
                Log.e(TAG, "Failed to create ImageFrame from bitmap");
                Toast.makeText(this, "预置背景加载失败", Toast.LENGTH_SHORT).show();
              }
            } else {
              Log.e(TAG, "Failed to load preset background bitmap");
              Toast.makeText(this, "预置背景图片加载失败", Toast.LENGTH_SHORT).show();
            }
          } else if (function != null && function.startsWith("image")) {
            // 背景图片切换（从相册选择）
            // options.mode = BackgroundMode.IMAGE;
            // options.backgroundImage = imageFrame; // 需要提供 ImageFrame
            // mBeautyEngine.setVirtualBackground(options);
            Log.w(TAG, "BACKGROUND_IMAGE not implemented, function=" + function);
          } else {
            Log.w(TAG, "Unknown virtual_bg function: " + function);
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
   * 将功能字符串映射到 ReshapeParam
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
   * 将功能字符串映射到 MakeupParam
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
   * 重置所有美颜参数
   */
  private void resetAllBeautyParams() {
    if (mBeautyEngine == null) {
      Log.w(TAG, "BeautyEngine not initialized");
      return;
    }
    
    try {
      // 重置基础美颜参数
      mBeautyEngine.setBeautyParam(BasicParam.WHITENING, 0.0f);
      mBeautyEngine.setBeautyParam(BasicParam.SMOOTHING, 0.0f);
      mBeautyEngine.setBeautyParam(BasicParam.ROSINESS, 0.0f);
      
      // 重置面部重塑参数
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
      
      // 重置美妆参数
      mBeautyEngine.setBeautyParam(MakeupParam.LIPSTICK, 0.0f);
      mBeautyEngine.setBeautyParam(MakeupParam.BLUSH, 0.0f);
      // 重置虚拟背景参数
      VirtualBackgroundOptions options = new VirtualBackgroundOptions();
      options.mode = BackgroundMode.NONE;
      mBeautyEngine.setVirtualBackground(options);
      
      Log.d(TAG, "All beauty params reset to 0");
    } catch (Exception e) {
      Log.e(TAG, "Error resetting beauty params", e);
    }
  }

  /**
   * 重置指定 Tab 的所有参数
   */
  private void resetBeautyTab(String tab) {
    if (mBeautyEngine == null) return;
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
          // 重置虚拟背景
          VirtualBackgroundOptions options = new VirtualBackgroundOptions();
          options.mode = BackgroundMode.NONE;
          mBeautyEngine.setVirtualBackground(options);
          break;
        case "filter":
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
