package net.pixpark.fbexample;

import android.content.Context;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.Log;
import net.pixpark.facebetter.ImageFrame;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class GLI420Renderer extends GLSurfaceView implements GLSurfaceView.Renderer {
  /**
   * Frame provider interface for obtaining frame data from external sources
   */
  public interface FrameProvider {
    /**
     * Provide current frame data
     * @return Current ImageFrame to render, returns null if no frame is available
     */
    ImageFrame getCurrentFrame();
    
    /**
     * Notify that the frame has been used and resources can be released
     * @param frame Frame that has been used
     */
    void releaseFrame(ImageFrame frame);
  }

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

  // Video dimensions and viewport dimensions for aspect ratio calculation
  private int mVideoWidth = 0;
  private int mVideoHeight = 0;
  private int mViewportWidth = 0;
  private int mViewportHeight = 0;

  // Horizontal mirror flag
  private boolean mRenderingEnabled = true;
  private FrameProvider mFrameProvider;

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

  public GLI420Renderer(Context context) {
    super(context);
    init();
  }

  public GLI420Renderer(Context context, AttributeSet attrs) {
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
   * Enable/disable rendering
   */
  public void setRenderingEnabled(boolean enabled) {
    mRenderingEnabled = enabled;
    if (enabled) {
      requestRender();
    }
  }

  /**
   * Set frame provider
   * @param provider Frame provider
   */
  public void setFrameProvider(FrameProvider provider) {
    mFrameProvider = provider;
  }

  /**
   * Release the current frame and clear the screen
   */
  public void releaseCurrentFrame() {
    // In "pull" mode, frame release is handled by FrameProvider
    // Just need to trigger a render to clear the screen
    requestRender();
  }

  @Override
  public void onSurfaceChanged(GL10 gl, int width, int height) {
    Log.d(TAG, "Surface changed: " + width + "x" + height);
    mViewportWidth = width;
    mViewportHeight = height;
    GLES20.glViewport(0, 0, width, height);

    // 视口变化时，在下一次渲染时会自动更新顶点坐标
  }

  @Override
  public void onDrawFrame(GL10 gl) {
    GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

    if (!mRenderingEnabled) {
      return;
    }

    // 从FrameProvider获取当前帧
    ImageFrame currentFrame = null;
    if (mFrameProvider != null) {
      currentFrame = mFrameProvider.getCurrentFrame();
    }

    if (currentFrame == null) {
      return;
    }

    try {
      // 更新顶点坐标以保持视频宽高比
      updateVertexCoordinates(currentFrame);
      
      // Use shader program
      GLES20.glUseProgram(mProgram);

      // Update textures with the current frame
      updateTextures(currentFrame);

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
    } finally {
      // 通知FrameProvider帧已使用完毕，可以释放资源
      if (mFrameProvider != null && currentFrame != null) {
        mFrameProvider.releaseFrame(currentFrame);
      }
    }
  }

  /**
   * 兼容旧的API，现在使用FrameProvider模式
   */
  public void renderFrame(ImageFrame frame) {
    // 在新的FrameProvider模式下，此方法不再使用
    // 保留此方法以保持兼容性
    if (frame != null) {
      frame.release();
    }
  }

  /**
   * Update vertex coordinates to maintain video aspect ratio
   * Uses letterbox or pillarbox display to ensure video is not stretched
   */
  private void updateVertexCoordinates(ImageFrame frame) {
    int videoWidth = 0;
    int videoHeight = 0;
    
    if (frame != null) {
      videoWidth = frame.getWidth();
      videoHeight = frame.getHeight();
    }
    
    if (videoWidth <= 0 || videoHeight <= 0 || mViewportWidth <= 0 || mViewportHeight <= 0) {
      // If dimension information is incomplete, use full-screen display
      mVertices[0] = -1.0f;
      mVertices[1] = -1.0f; // Bottom left
      mVertices[2] = 1.0f;
      mVertices[3] = -1.0f; // Bottom right
      mVertices[4] = -1.0f;
      mVertices[5] = 1.0f; // Top left
      mVertices[6] = 1.0f;
      mVertices[7] = 1.0f; // Top right
    } else {
      // Calculate video and viewport aspect ratios
      float videoAspectRatio = (float) videoWidth / videoHeight;
      float viewportAspectRatio = (float) mViewportWidth / mViewportHeight;

      float scaleX, scaleY;

      if (videoAspectRatio > viewportAspectRatio) {
        // Video is wider than viewport, need pillarbox (black bars on left/right)
        scaleX = 1.0f;
        scaleY = viewportAspectRatio / videoAspectRatio;
      } else {
        // Video is taller than viewport, need letterbox (black bars on top/bottom)
        scaleX = videoAspectRatio / viewportAspectRatio;
        scaleY = 1.0f;
      }

      // Update vertex coordinates
      mVertices[0] = -scaleX;
      mVertices[1] = -scaleY; // Bottom left
      mVertices[2] = scaleX;
      mVertices[3] = -scaleY; // Bottom right
      mVertices[4] = -scaleX;
      mVertices[5] = scaleY; // Top left
      mVertices[6] = scaleX;
      mVertices[7] = scaleY; // Top right

      Log.d(TAG,
          String.format("Aspect ratio updated - Video: %.2f, Viewport: %.2f, Scale: %.2f, %.2f",
              videoAspectRatio, viewportAspectRatio, scaleX, scaleY));
    }

    // Update vertex buffer
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
   * Manually set video dimensions (optional, now provided by FrameProvider)
   * @param width Video width
   * @param height Video height
   */
  public void setVideoDimensions(int width, int height) {
    // In new FrameProvider mode, this method is no longer used
    // Keep this method for compatibility
    mVideoWidth = width;
    mVideoHeight = height;
    Log.d(TAG, "Video dimensions manually set: " + mVideoWidth + "x" + mVideoHeight);
  }

  /**
   * Get current video dimensions
   * @return Array containing width and height [width, height]
   */
  public int[] getVideoDimensions() {
    return new int[] {mVideoWidth, mVideoHeight};
  }

  /**
   * Get current viewport dimensions
   * @return Array containing width and height [width, height]
   */
  public int[] getViewportDimensions() {
    return new int[] {mViewportWidth, mViewportHeight};
  }

  /**
   * Cleanup resources, called externally when Activity is destroyed
   */
  public void cleanup() {
    // In "pull" mode, frame release is handled by FrameProvider
    Log.d(TAG, "GLVideoRenderer cleanup completed");
  }
}