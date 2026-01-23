package com.pixpark.fbexample;

import android.content.Context;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.Log;
import com.pixpark.facebetter.ImageFrame;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class GLBufferRenderer extends GLSurfaceView implements GLSurfaceView.Renderer {
  private static final String TAG = "GLVideoRenderer";

  // Vertex shader for rendering YUV to RGB
  private static final String VERTEX_SHADER = "attribute vec4 a_position;\n"
      + "attribute vec2 a_texCoord;\n"
      + "varying vec2 v_texCoord;\n"
      + "void main() {\n"
      + "  gl_Position = a_position;\n"
      + "  v_texCoord = a_texCoord;\n"
      + "}\n";

  // Fragment shader for YUV420 to RGB conversion (ITU-R BT.601)
  private static final String FRAGMENT_SHADER = "precision mediump float;\n"
      + "uniform sampler2D y_texture;\n"
      + "uniform sampler2D u_texture;\n"
      + "uniform sampler2D v_texture;\n"
      + "varying vec2 v_texCoord;\n"
      + "void main() {\n"
      + "  // Sample and validate YUV values\n"
      + "  float y = clamp(texture2D(y_texture, v_texCoord).r, 0.0, 1.0);\n"
      + "  float u = clamp(texture2D(u_texture, v_texCoord).r, 0.0, 1.0) - 0.5;\n"
      + "  float v = clamp(texture2D(v_texture, v_texCoord).r, 0.0, 1.0) - 0.5;\n"
      + "  \n"
      + "  // ITU-R BT.601 YUV to RGB conversion matrix\n"
      + "  float r = y + 1.402 * v;\n"
      + "  float g = y - 0.344136 * u - 0.714136 * v;\n"
      + "  float b = y + 1.772 * u;\n"
      + "  \n"
      + "  // Final range validation\n"
      + "  gl_FragColor = vec4(clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), 1.0);\n"
      + "}\n";

  private int mProgram;
  private int mPositionHandle;
  private int mTexCoordHandle;
  private int mYTextureHandle;
  private int mUTextureHandle;
  private int mVTextureHandle;

  private int[] mTextures = new int[3]; // Y, U, V textures
  private FloatBuffer mVertexBuffer;
  private FloatBuffer mTexCoordBuffer;

  private ImageFrame mCurrentImageFrame;
  private final Object mFrameLock = new Object();

  // Video dimensions and viewport dimensions for aspect ratio calculation
  private int mVideoWidth = 0;
  private int mVideoHeight = 0;
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

  public GLBufferRenderer(Context context) {
    super(context);
    init();
  }

  public GLBufferRenderer(Context context, AttributeSet attrs) {
    super(context, attrs);
    init();
  }

  private void init() {
    setEGLContextClientVersion(2);
    setRenderer(this);
    setRenderMode(GLSurfaceView.RENDERMODE_WHEN_DIRTY);

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
    mYTextureHandle = GLES20.glGetUniformLocation(mProgram, "y_texture");
    mUTextureHandle = GLES20.glGetUniformLocation(mProgram, "u_texture");
    mVTextureHandle = GLES20.glGetUniformLocation(mProgram, "v_texture");

    // Generate textures
    GLES20.glGenTextures(3, mTextures, 0);

    // Configure textures
    for (int i = 0; i < 3; i++) {
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[i]);
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
      GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
      GLES20.glTexParameteri(
          GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
      GLES20.glTexParameteri(
          GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
    }
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

    synchronized (mFrameLock) {
      if (mCurrentImageFrame == null) {
        return;
      }

      // Use shader program
      GLES20.glUseProgram(mProgram);

      // Update textures with current frame data
      updateTextures(mCurrentImageFrame);
      // Release frame after uploading to GPU textures
      // The texture data is already on GPU, so it's safe to release the frame
      mCurrentImageFrame.release();
      mCurrentImageFrame = null;

      // Set vertex attributes
      GLES20.glEnableVertexAttribArray(mPositionHandle);
      GLES20.glVertexAttribPointer(mPositionHandle, 2, GLES20.GL_FLOAT, false, 0, mVertexBuffer);

      GLES20.glEnableVertexAttribArray(mTexCoordHandle);
      GLES20.glVertexAttribPointer(mTexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, mTexCoordBuffer);

      // Bind textures
      GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[0]);
      GLES20.glUniform1i(mYTextureHandle, 0);

      GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[1]);
      GLES20.glUniform1i(mUTextureHandle, 1);

      GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[2]);
      GLES20.glUniform1i(mVTextureHandle, 2);

      // Draw
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

      // Disable vertex arrays
      GLES20.glDisableVertexAttribArray(mPositionHandle);
      GLES20.glDisableVertexAttribArray(mTexCoordHandle);
    }
  }

  public void renderFrame(ImageFrame frame) {
    synchronized (mFrameLock) {
      // If there's an old frame that hasn't been rendered yet, release it
      // This prevents memory leaks when frames arrive faster than they can be rendered
      if (mCurrentImageFrame != null && mCurrentImageFrame != frame) {
        mCurrentImageFrame.release();
      }
      mCurrentImageFrame = frame;

      // Update video dimensions if they have changed
      if (frame != null && (mVideoWidth != frame.getWidth() || mVideoHeight != frame.getHeight())) {
        mVideoWidth = frame.getWidth();
        mVideoHeight = frame.getHeight();
        Log.d(TAG, "Video dimensions updated: " + mVideoWidth + "x" + mVideoHeight);

        // Update vertex coordinates based on new video aspect ratio
        updateVertexCoordinates();
      }
    }
    if (mRenderingEnabled) {
      requestRender();
    }
  }

  /**
   * 更新顶点坐标以保持视频的宽高比
   * 使用 letterbox 或 pillarbox 方式显示，确保视频不被拉伸
   */
  private void updateVertexCoordinates() {
    if (mVideoWidth <= 0 || mVideoHeight <= 0 || mViewportWidth <= 0 || mViewportHeight <= 0) {
      // 如果尺寸信息不完整，使用全屏显示
      mVertices[0] = -1.0f;
      mVertices[1] = -1.0f; // 左下
      mVertices[2] = 1.0f;
      mVertices[3] = -1.0f; // 右下
      mVertices[4] = -1.0f;
      mVertices[5] = 1.0f; // 左上
      mVertices[6] = 1.0f;
      mVertices[7] = 1.0f; // 右上
    } else {
      // 计算视频和视口的宽高比
      float videoAspectRatio = (float) mVideoWidth / mVideoHeight;
      float viewportAspectRatio = (float) mViewportWidth / mViewportHeight;

      float scaleX, scaleY;

      if (videoAspectRatio > viewportAspectRatio) {
        // 视频比视口更宽，需要 pillarbox（左右留黑边）
        scaleX = 1.0f;
        scaleY = viewportAspectRatio / videoAspectRatio;
      } else {
        // 视频比视口更高，需要 letterbox（上下留黑边）
        scaleX = videoAspectRatio / viewportAspectRatio;
        scaleY = 1.0f;
      }

      // 更新顶点坐标
      mVertices[0] = -scaleX;
      mVertices[1] = -scaleY; // 左下
      mVertices[2] = scaleX;
      mVertices[3] = -scaleY; // 右下
      mVertices[4] = -scaleX;
      mVertices[5] = scaleY; // 左上
      mVertices[6] = scaleX;
      mVertices[7] = scaleY; // 右上

      Log.d(TAG,
          String.format("Aspect ratio updated - Video: %.2f, Viewport: %.2f, Scale: %.2f, %.2f",
              videoAspectRatio, viewportAspectRatio, scaleX, scaleY));
    }

    // 更新顶点缓冲区
    mVertexBuffer.rewind();
    mVertexBuffer.put(mVertices);
    mVertexBuffer.position(0);
  }

  private void updateTextures(ImageFrame frame) {
    int width = frame.getWidth();
    int height = frame.getHeight();
    int strideY = frame.getStrideY();
    int strideU = frame.getStrideU();
    int strideV = frame.getStrideV();

    // Set pixel store alignment
    GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);

    // Update Y texture - handle stride properly
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[0]);
    ByteBuffer yBuffer = frame.getDataY();
    if (yBuffer == null) {
      Log.w(TAG, "Y plane buffer is null, skip frame");
      return;
    }
    yBuffer.rewind();

    if (strideY == width) {
      // No padding, upload directly
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, width, height, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, yBuffer);
    } else {
      // Handle stride by uploading row by row
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, width, height, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, null);
      for (int y = 0; y < height; y++) {
        yBuffer.position(y * strideY);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, y, width, 1, GLES20.GL_LUMINANCE,
            GLES20.GL_UNSIGNED_BYTE, yBuffer);
      }
    }

    // Update U texture - handle stride properly
    GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[1]);
    ByteBuffer uBuffer = frame.getDataU();
    if (uBuffer == null) {
      Log.w(TAG, "U plane buffer is null, skip frame");
      return;
    }
    uBuffer.rewind();

    int uvWidth = width / 2;
    int uvHeight = height / 2;

    if (strideU == uvWidth) {
      // No padding, upload directly
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, uvWidth, uvHeight, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, uBuffer);
    } else {
      // Handle stride by uploading row by row
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, uvWidth, uvHeight, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, null);
      for (int y = 0; y < uvHeight; y++) {
        uBuffer.position(y * strideU);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, y, uvWidth, 1, GLES20.GL_LUMINANCE,
            GLES20.GL_UNSIGNED_BYTE, uBuffer);
      }
    }

    // Update V texture - handle stride properly
    GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextures[2]);
    ByteBuffer vBuffer = frame.getDataV();
    if (vBuffer == null) {
      Log.w(TAG, "V plane buffer is null, skip frame");
      return;
    }
    vBuffer.rewind();

    if (strideV == uvWidth) {
      // No padding, upload directly
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, uvWidth, uvHeight, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, vBuffer);
    } else {
      // Handle stride by uploading row by row
      GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, uvWidth, uvHeight, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, null);
      for (int y = 0; y < uvHeight; y++) {
        vBuffer.position(y * strideV);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, y, uvWidth, 1, GLES20.GL_LUMINANCE,
            GLES20.GL_UNSIGNED_BYTE, vBuffer);
      }
    }
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
   * 手动设置视频尺寸（可选，通常由 renderFrame 自动检测）
   * @param width 视频宽度
   * @param height 视频高度
   */
  public void setVideoDimensions(int width, int height) {
    synchronized (mFrameLock) {
      if (mVideoWidth != width || mVideoHeight != height) {
        mVideoWidth = width;
        mVideoHeight = height;
        Log.d(TAG, "Video dimensions manually set: " + mVideoWidth + "x" + mVideoHeight);
        updateVertexCoordinates();
      }
    }
  }

  /**
   * 获取当前视频尺寸
   * @return 包含宽度和高度的数组 [width, height]
   */
  public int[] getVideoDimensions() {
    synchronized (mFrameLock) {
      return new int[] {mVideoWidth, mVideoHeight};
    }
  }

  /**
   * 获取当前视口尺寸
   * @return 包含宽度和高度的数组 [width, height]
   */
  public int[] getViewportDimensions() {
    return new int[] {mViewportWidth, mViewportHeight};
  }

  /**
   * 清理资源，供外部在Activity销毁时调用
   */
  public void cleanup() {
    synchronized (mFrameLock) {
      if (mCurrentImageFrame != null) {
        mCurrentImageFrame.release();
        mCurrentImageFrame = null;
      }
    }
    Log.d(TAG, "GLVideoRenderer cleanup completed");
  }
}