package com.pixpark.fbexample;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.Log;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * 视频渲染器，通过回调模式处理纹理并渲染
 */
public class GLTextureRenderer extends GLSurfaceView implements GLSurfaceView.Renderer {
  private static final String TAG = "GLVideoRenderer";

  /**
   * 纹理帧信息封装类
   * 用于封装纹理ID和尺寸信息
   */
  public static class TextureFrame {
    /** 纹理ID */
    public int textureId;

    /** 纹理宽度 */
    public int width;

    /** 纹理高度 */
    public int height;

    /**
     * 构造函数
     * @param textureId 纹理ID
     * @param width 纹理宽度
     * @param height 纹理高度
     */
    public TextureFrame(int textureId, int width, int height) {
      this.textureId = textureId;
      this.width = width;
      this.height = height;
    }

    /**
     * 默认构造函数，所有值初始化为0
     */
    public TextureFrame() {
      this(0, 0, 0);
    }

    /**
     * 检查纹理是否有效
     * @return true 如果纹理ID大于0且宽高都大于0
     */
    public boolean isValid() {
      return textureId > 0 && width > 0 && height > 0;
    }

    @Override
    public String toString() {
      return "TextureFrame{textureId=" + textureId + ", width=" + width + ", height=" + height
          + "}";
    }
  }

  /**
   * 视频帧处理回调接口
   */
  public interface OnProcessVideoFrameCallback {
    /**
     * 处理视频帧纹理
     * @param srcFrame 输入纹理帧（只读，包含输入纹理ID和尺寸）
     * @param dstFrame 输出纹理帧（可写，用于返回处理后的纹理ID和尺寸）
     * @return 错误码，0表示成功，非0表示失败
     */
    int onProcessVideoFrame(TextureFrame srcFrame, TextureFrame dstFrame);
  }

  // Vertex shader
  private static final String VERTEX_SHADER = "attribute vec4 a_position;\n"
      + "attribute vec2 a_texCoord;\n"
      + "varying vec2 v_texCoord;\n"
      + "void main() {\n"
      + "  gl_Position = a_position;\n"
      + "  v_texCoord = a_texCoord;\n"
      + "}\n";

  // Fragment shader for texture rendering
  private static final String FRAGMENT_SHADER = "precision mediump float;\n"
      + "uniform sampler2D u_texture;\n"
      + "varying vec2 v_texCoord;\n"
      + "void main() {\n"
      + "  gl_FragColor = texture2D(u_texture, v_texCoord);\n"
      + "}\n";

  private int mProgram;
  private int mPositionHandle;
  private int mTexCoordHandle;
  private int mTextureHandle;

  private FloatBuffer mVertexBuffer;
  private FloatBuffer mTexCoordBuffer;

  // Callback mode
  private OnProcessVideoFrameCallback mProcessCallback;
  private int mInputTexture = 0; // Input texture for callback mode
  private int mOutputTexture = 0; // Output texture for callback mode
  private int mTextureWidth = 0;
  private int mTextureHeight = 0;

  // Video dimensions and viewport dimensions for aspect ratio calculation
  private int mViewportWidth = 0;
  private int mViewportHeight = 0;

  // Horizontal mirror flag
  private boolean mMirrorHorizontal = false;
  private boolean mRenderingEnabled = true;

  // Vertex coordinates for a full-screen quad (will be updated based on aspect ratio)
  private float[] mVertices = {
      -1.0f,
      -1.0f,
      1.0f,
      -1.0f,
      -1.0f,
      1.0f,
      1.0f,
      1.0f,
  };

  // Texture coordinates
  private static final float[] TEX_COORDS = {
      0.0f,
      1.0f,
      1.0f,
      1.0f,
      0.0f,
      0.0f,
      1.0f,
      0.0f,
  };

  // Texture coordinates for horizontal mirror
  private static final float[] TEX_COORDS_MIRROR_X = {
      1.0f,
      1.0f,
      0.0f,
      1.0f,
      1.0f,
      0.0f,
      0.0f,
      0.0f,
  };

  public GLTextureRenderer(Context context) {
    super(context);
    init();
  }

  public GLTextureRenderer(Context context, AttributeSet attrs) {
    super(context, attrs);
    init();
  }

  private void init() {
    setEGLContextClientVersion(2);
    setRenderer(this);
    setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);

    // Initialize vertex buffer
    ByteBuffer bb = ByteBuffer.allocateDirect(mVertices.length * 4);
    bb.order(ByteOrder.nativeOrder());
    mVertexBuffer = bb.asFloatBuffer();
    mVertexBuffer.put(mVertices);
    mVertexBuffer.position(0);

    // Initialize texture coordinate buffer
    bb = ByteBuffer.allocateDirect(TEX_COORDS.length * 4);
    bb.order(ByteOrder.nativeOrder());
    mTexCoordBuffer = bb.asFloatBuffer();
    mTexCoordBuffer.put(TEX_COORDS);
    mTexCoordBuffer.position(0);
  }

  @Override
  public void onSurfaceCreated(GL10 gl, EGLConfig config) {
    Log.d(TAG, "Surface created");
    GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // Create shader program
    mProgram = createProgram(VERTEX_SHADER, FRAGMENT_SHADER);
    if (mProgram == 0) {
      Log.e(TAG, "Failed to create shader program");
      return;
    }

    // Get attribute and uniform locations
    mPositionHandle = GLES20.glGetAttribLocation(mProgram, "a_position");
    mTexCoordHandle = GLES20.glGetAttribLocation(mProgram, "a_texCoord");
    mTextureHandle = GLES20.glGetUniformLocation(mProgram, "u_texture");

    // Initialize input texture from bitmap
    initializeInputTexture();
  }

  /**
   * 设置是否进行左右镜像渲染（水平翻转）。
   */
  public void setMirror(boolean mirror) {
    if (mMirrorHorizontal == mirror)
      return;
    mMirrorHorizontal = mirror;

    // 更新纹理坐标缓冲
    float[] coords = mMirrorHorizontal ? TEX_COORDS_MIRROR_X : TEX_COORDS;
    mTexCoordBuffer.rewind();
    mTexCoordBuffer.put(coords);
    mTexCoordBuffer.position(0);

    requestRender();
  }

  /**
   * 启用/暂停渲染
   */
  public void setRenderingEnabled(boolean enabled) {
    mRenderingEnabled = enabled;
    if (enabled) {
      requestRender();
    }
  }

  @Override
  public void onSurfaceChanged(GL10 gl, int width, int height) {
    Log.d(TAG, "Surface changed: " + width + "x" + height);
    mViewportWidth = width;
    mViewportHeight = height;
    GLES20.glViewport(0, 0, width, height);

    // Update vertex coordinates based on current video aspect ratio
    updateVertexCoordinates();
  }

  @Override
  public void onDrawFrame(GL10 gl) {
    GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

    if (!mRenderingEnabled) {
      return;
    }

    if (mInputTexture == 0 || mProcessCallback == null) {
      return;
    }

    // Create source and destination frame objects
    TextureFrame srcFrame = new TextureFrame(mInputTexture, mTextureWidth, mTextureHeight);
    TextureFrame dstFrame = new TextureFrame();

    // Call callback to process texture
    int errorCode = mProcessCallback.onProcessVideoFrame(srcFrame, dstFrame);

    if (errorCode != 0) {
      Log.w(TAG, "Callback returned error code: " + errorCode);
      return;
    }

    // 视口可能被回调修改，重设置一下
    GLES20.glViewport(0, 0, mViewportWidth, mViewportHeight);

    // Update output texture and dimensions
    mOutputTexture = dstFrame.textureId;
    if (dstFrame.width > 0 && dstFrame.height > 0) {
      if (mTextureWidth != dstFrame.width || mTextureHeight != dstFrame.height) {
        mTextureWidth = dstFrame.width;
        mTextureHeight = dstFrame.height;
        updateVertexCoordinates();
      }
    }

    // Use shader program
    GLES20.glUseProgram(mProgram);

    // Set vertex attributes
    GLES20.glEnableVertexAttribArray(mPositionHandle);
    GLES20.glVertexAttribPointer(mPositionHandle, 2, GLES20.GL_FLOAT, false, 0, mVertexBuffer);

    GLES20.glEnableVertexAttribArray(mTexCoordHandle);
    GLES20.glVertexAttribPointer(mTexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, mTexCoordBuffer);

    // Bind output texture
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mOutputTexture);
    GLES20.glUniform1i(mTextureHandle, 0);

    // Draw
    GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

    // Disable vertex arrays
    GLES20.glDisableVertexAttribArray(mPositionHandle);
    GLES20.glDisableVertexAttribArray(mTexCoordHandle);
  }

  /**
   * 更新顶点坐标以保持视频的宽高比
   * 使用 letterbox 或 pillarbox 方式显示，确保视频不被拉伸
   */
  private void updateVertexCoordinates() {
    // 如果纹理或视口尺寸无效，使用全屏
    if (mTextureWidth <= 0 || mTextureHeight <= 0 || mViewportWidth <= 0 || mViewportHeight <= 0) {
      mVertices[0] = -1.0f;
      mVertices[1] = -1.0f; // 左下
      mVertices[2] = 1.0f;
      mVertices[3] = -1.0f; // 右下
      mVertices[4] = -1.0f;
      mVertices[5] = 1.0f; // 左上
      mVertices[6] = 1.0f;
      mVertices[7] = 1.0f; // 右上
    } else {
      // 计算纹理和视口的宽高比
      float textureAspect = (float) mTextureWidth / (float) mTextureHeight;
      float viewportAspect = (float) mViewportWidth / (float) mViewportHeight;

      float xScale = 1.0f;
      float yScale = 1.0f;

      if (textureAspect > viewportAspect) {
        // 纹理更宽，需要上下留黑边（letterbox）
        // 以宽度为准，高度按比例缩放
        yScale = viewportAspect / textureAspect;
      } else {
        // 纹理更高，需要左右留黑边（pillarbox）
        // 以高度为准，宽度按比例缩放
        xScale = textureAspect / viewportAspect;
      }

      // 计算缩放后的顶点坐标
      mVertices[0] = -xScale; // 左下 x
      mVertices[1] = -yScale; // 左下 y
      mVertices[2] = xScale; // 右下 x
      mVertices[3] = -yScale; // 右下 y
      mVertices[4] = -xScale; // 左上 x
      mVertices[5] = yScale; // 左上 y
      mVertices[6] = xScale; // 右上 x
      mVertices[7] = yScale; // 右上 y
    }

    // 更新顶点缓冲区
    mVertexBuffer.rewind();
    mVertexBuffer.put(mVertices);
    mVertexBuffer.position(0);
  }

  private int createProgram(String vertexSource, String fragmentSource) {
    int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
    if (vertexShader == 0) {
      return 0;
    }

    int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
    if (fragmentShader == 0) {
      return 0;
    }

    int program = GLES20.glCreateProgram();
    if (program != 0) {
      GLES20.glAttachShader(program, vertexShader);
      GLES20.glAttachShader(program, fragmentShader);
      GLES20.glLinkProgram(program);

      int[] linkStatus = new int[1];
      GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
      if (linkStatus[0] != GLES20.GL_TRUE) {
        Log.e(TAG, "Could not link program: " + GLES20.glGetProgramInfoLog(program));
        GLES20.glDeleteProgram(program);
        program = 0;
      }
    }

    return program;
  }

  private int loadShader(int type, String source) {
    int shader = GLES20.glCreateShader(type);
    if (shader != 0) {
      GLES20.glShaderSource(shader, source);
      GLES20.glCompileShader(shader);

      int[] compiled = new int[1];
      GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
      if (compiled[0] == 0) {
        Log.e(TAG, "Could not compile shader " + type + ": " + GLES20.glGetShaderInfoLog(shader));
        GLES20.glDeleteShader(shader);
        shader = 0;
      }
    }

    return shader;
  }

  @Override
  protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    cleanup();
    Log.d(TAG, "GLVideoRenderer detached from window");
  }

  /**
   * 获取当前视口尺寸
   * @return 包含宽度和高度的数组 [width, height]
   */
  public int[] getViewportDimensions() {
    return new int[] {mViewportWidth, mViewportHeight};
  }

  /**
   * 设置视频帧处理回调
   *
   * @param callback 回调接口
   */
  public void setOnProcessVideoFrameCallback(OnProcessVideoFrameCallback callback) {
    mProcessCallback = callback;
    Log.d(TAG, "Process callback " + (callback != null ? "set" : "cleared"));
  }

  /**
   * 初始化输入纹理（从资源图片加载）
   */
  private void initializeInputTexture() {
    try {
      // Load bitmap from resources without density scaling
      // Use BitmapFactory.Options to get original size
      BitmapFactory.Options options = new BitmapFactory.Options();
      options.inScaled = false; // Disable density-based scaling
      options.inJustDecodeBounds = false; // Actually decode the bitmap

      Bitmap bitmap =
          BitmapFactory.decodeResource(getContext().getResources(), R.drawable.demo, options);
      if (bitmap == null) {
        Log.e(TAG, "Failed to load test bitmap");
        return;
      }

      mTextureWidth = bitmap.getWidth();
      mTextureHeight = bitmap.getHeight();
      int stride = bitmap.getRowBytes();

      // Copy RGBA data from bitmap
      ByteBuffer buffer = ByteBuffer.allocateDirect(stride * mTextureHeight);
      bitmap.copyPixelsToBuffer(buffer);
      buffer.rewind();
      bitmap.recycle();

      // Create input texture
      int[] texIds = new int[1];
      GLES20.glGenTextures(1, texIds, 0);
      mInputTexture = texIds[0];
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mInputTexture);
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
      GLES20.glTexParameteri(
          GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
      GLES20.glTexParameteri(
          GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);

      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, mTextureWidth, mTextureHeight, 0,
          GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer);

      // Update video dimensions for aspect ratio
      updateVertexCoordinates();

      Log.d(TAG,
          "Input texture initialized: " + mInputTexture + ", size: " + mTextureWidth + "x"
              + mTextureHeight);
    } catch (Exception e) {
      Log.e(TAG, "Failed to initialize input texture", e);
    }
  }

  /**
   * 清理资源，供外部在Activity销毁时调用
   */
  public void cleanup() {
    // Cleanup input texture
    if (mInputTexture != 0) {
      int[] textures = {mInputTexture};
      GLES20.glDeleteTextures(1, textures, 0);
      mInputTexture = 0;
    }

    Log.d(TAG, "GLVideoRenderer cleanup completed");
  }
}