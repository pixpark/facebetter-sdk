package net.pixpark.fbexample.texture

import android.content.Context
import android.graphics.Bitmap
import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLES30
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.AttributeSet
import android.util.Log
import android.view.Surface
import android.view.TextureView
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Camera OES → blit to GL_TEXTURE_2D → caller processes → draw. TextureView so Compose
 * overlays sit above the preview (GLSurfaceView / SurfaceView would cover them).
 */
class TexturePreviewView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : TextureView(context, attrs), TextureView.SurfaceTextureListener {

    var process: ((Int, Int, Int) -> Int)? = null
    var onPresented: (() -> Unit)? = null
    var onCameraSurfaceReady: ((Surface) -> Unit)? = null
    var onGlReady: (() -> Unit)? = null
    var onGlRelease: (() -> Unit)? = null

    @Volatile
    var comparing: Boolean = false

    @Volatile
    var frontFacing: Boolean = true

    private val glThread = HandlerThread("fb-texture-gl").apply { start() }
    private val glHandler = Handler(glThread.looper)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val frameAvailable = AtomicBoolean(false)
    private val released = AtomicBoolean(false)

    private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
    private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE
    private var eglConfig: EGLConfig? = null

    private var oesProgram = 0
    private var drawProgram = 0
    private var oesPosLoc = 0
    private var oesUvLoc = 0
    private var oesMatrixLoc = 0
    private var oesMirrorLoc = 0
    private var drawPosLoc = 0
    private var drawUvLoc = 0
    private var vao = 0
    private var positionVbo = 0
    private var uvVbo = 0

    private var oesTexture = 0
    private var cameraTexture: SurfaceTexture? = null
    private var cameraSurface: Surface? = null
    private val texMatrix = FloatArray(16)

    private var blitFbo = 0
    private var blitTexture = 0
    private var blitWidth = 0
    private var blitHeight = 0

    private var drawableWidth = 0
    private var drawableHeight = 0
    @Volatile
    private var cameraBufferWidth = 0
    @Volatile
    private var cameraBufferHeight = 0
    private var lastOutputTexture = 0
    private var lastWidth = 0
    private var lastHeight = 0
    private var glReady = false

    private val quadPositions = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
    private val quadUvs = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)

    init {
        isOpaque = true
        surfaceTextureListener = this
        if (isAvailable) {
            val texture = surfaceTexture
            if (texture != null) {
                onSurfaceTextureAvailable(texture, width, height)
            }
        }
    }

    fun runOnGl(block: () -> Unit) {
        if (released.get()) {
            return
        }
        glHandler.post {
            if (released.get()) {
                return@post
            }
            makeCurrent()
            block()
        }
    }

    fun runOnGlSync(block: () -> Unit) {
        if (released.get() || !glThread.isAlive) {
            return
        }
        if (Looper.myLooper() == glThread.looper) {
            makeCurrent()
            block()
            return
        }
        val latch = CountDownLatch(1)
        glHandler.post {
            try {
                makeCurrent()
                block()
            } finally {
                latch.countDown()
            }
        }
        if (!latch.await(3, TimeUnit.SECONDS)) {
            Log.w(TAG, "GL sync timed out")
        }
    }

    fun setCameraBufferSize(width: Int, height: Int) {
        if (width <= 0 || height <= 0) {
            return
        }
        cameraBufferWidth = width
        cameraBufferHeight = height
        cameraTexture?.setDefaultBufferSize(width, height)
    }

    fun captureBitmap(): Bitmap? {
        var bitmap: Bitmap? = null
        runOnGlSync {
            bitmap = readLastOutput()
        }
        return bitmap
    }

    fun shutdown() {
        if (!released.compareAndSet(false, true)) {
            return
        }
        runOnGlSync {
            releaseGl()
        }
        glThread.quitSafely()
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        glHandler.post {
            drawableWidth = width
            drawableHeight = height
            if (!initEgl(surface)) {
                return@post
            }
            if (!makeCurrent()) {
                return@post
            }
            buildResources()
            glReady = true
            onGlReady?.invoke()
        }
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        glHandler.post {
            drawableWidth = width
            drawableHeight = height
            blitWidth = 0
            blitHeight = 0
        }
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        if (released.get() || !glThread.isAlive) {
            return true
        }
        val latch = CountDownLatch(1)
        glHandler.post {
            try {
                releaseGl()
            } finally {
                latch.countDown()
            }
        }
        latch.await(3, TimeUnit.SECONDS)
        return true
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) = Unit

    private fun initEgl(window: SurfaceTexture): Boolean {
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
            Log.e(TAG, "eglGetDisplay failed")
            return false
        }
        val version = IntArray(2)
        if (!EGL14.eglInitialize(eglDisplay, version, 0, version, 1)) {
            Log.e(TAG, "eglInitialize failed")
            return false
        }
        val attribs = intArrayOf(
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_RENDERABLE_TYPE, EGLExt.EGL_OPENGL_ES3_BIT_KHR,
            EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<EGLConfig>(1)
        val num = IntArray(1)
        if (!EGL14.eglChooseConfig(eglDisplay, attribs, 0, configs, 0, 1, num, 0) || num[0] <= 0) {
            Log.e(TAG, "eglChooseConfig ES3 failed")
            return false
        }
        eglConfig = configs[0]
        val ctxAttribs = intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE)
        eglContext = EGL14.eglCreateContext(
            eglDisplay,
            eglConfig,
            EGL14.EGL_NO_CONTEXT,
            ctxAttribs,
            0,
        )
        if (eglContext == EGL14.EGL_NO_CONTEXT) {
            Log.e(TAG, "eglCreateContext failed 0x${EGL14.eglGetError().toString(16)}")
            return false
        }
        val surfaceAttribs = intArrayOf(EGL14.EGL_NONE)
        eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, eglConfig, window, surfaceAttribs, 0)
        if (eglSurface == EGL14.EGL_NO_SURFACE) {
            Log.e(TAG, "eglCreateWindowSurface failed")
            return false
        }
        return true
    }

    private fun makeCurrent(): Boolean {
        if (eglDisplay == EGL14.EGL_NO_DISPLAY || eglSurface == EGL14.EGL_NO_SURFACE) {
            return false
        }
        return EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
    }

    private fun buildResources() {
        oesProgram = link(
            OES_VERTEX,
            OES_FRAGMENT,
        )
        drawProgram = link(
            DRAW_VERTEX,
            DRAW_FRAGMENT,
        )
        if (oesProgram == 0 || drawProgram == 0) {
            Log.e(TAG, "Failed to link programs")
            return
        }
        oesPosLoc = GLES20.glGetAttribLocation(oesProgram, "aPos")
        oesUvLoc = GLES20.glGetAttribLocation(oesProgram, "aUV")
        oesMatrixLoc = GLES20.glGetUniformLocation(oesProgram, "uTexMatrix")
        oesMirrorLoc = GLES20.glGetUniformLocation(oesProgram, "uMirror")
        drawPosLoc = GLES20.glGetAttribLocation(drawProgram, "aPos")
        drawUvLoc = GLES20.glGetAttribLocation(drawProgram, "aUV")
        GLES20.glUseProgram(oesProgram)
        GLES20.glUniform1i(GLES20.glGetUniformLocation(oesProgram, "uTex"), 0)
        GLES20.glUseProgram(drawProgram)
        GLES20.glUniform1i(GLES20.glGetUniformLocation(drawProgram, "uTex"), 0)

        val pos = buffer(quadPositions)
        val uv = buffer(quadUvs)
        val vaos = IntArray(1)
        GLES30.glGenVertexArrays(1, vaos, 0)
        vao = vaos[0]
        GLES30.glBindVertexArray(vao)
        val buffers = IntArray(2)
        GLES20.glGenBuffers(2, buffers, 0)
        positionVbo = buffers[0]
        uvVbo = buffers[1]
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, positionVbo)
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, pos.capacity() * 4, pos, GLES20.GL_STATIC_DRAW)
        GLES20.glEnableVertexAttribArray(0)
        GLES20.glVertexAttribPointer(0, 2, GLES20.GL_FLOAT, false, 0, 0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, uvVbo)
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, uv.capacity() * 4, uv, GLES20.GL_STATIC_DRAW)
        GLES20.glEnableVertexAttribArray(1)
        GLES20.glVertexAttribPointer(1, 2, GLES20.GL_FLOAT, false, 0, 0)
        GLES30.glBindVertexArray(0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)

        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        oesTexture = textures[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTexture)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)

        val camera = SurfaceTexture(oesTexture)
        camera.setOnFrameAvailableListener(
            {
                frameAvailable.set(true)
                glHandler.post { render() }
            },
            glHandler,
        )
        if (cameraBufferWidth > 0 && cameraBufferHeight > 0) {
            camera.setDefaultBufferSize(cameraBufferWidth, cameraBufferHeight)
        }
        cameraTexture = camera
        val surface = Surface(camera)
        cameraSurface = surface
        mainHandler.post { onCameraSurfaceReady?.invoke(surface) }
    }

    private fun render() {
        if (released.get() || !glReady) {
            return
        }
        if (!makeCurrent()) {
            return
        }
        val camera = cameraTexture ?: return
        if (frameAvailable.getAndSet(false)) {
            camera.updateTexImage()
            camera.getTransformMatrix(texMatrix)
        }
        val (procW, procH) = processingSize()
        if (procW <= 0 || procH <= 0) {
            return
        }
        ensureBlitTexture(procW, procH)
        blitOesTo2d()

        // SDK face-detect uses GLES2 client arrays. A bound VBO/VAO makes those
        // CPU pointers look like buffer offsets and crashes in glDrawArrays.
        resetEngineGlState()
        var output = blitTexture
        if (!comparing) {
            output = process?.invoke(blitTexture, procW, procH) ?: blitTexture
            if (output == 0) {
                output = blitTexture
            }
        }
        lastOutputTexture = output
        lastWidth = procW
        lastHeight = procH
        drawToScreen(output, procW, procH)
        EGL14.eglSwapBuffers(eglDisplay, eglSurface)
        onPresented?.invoke()
    }

    /**
     * Process at the camera frame's display-oriented size (not the TextureView size),
     * so drawToScreen can aspect-fit with letterboxing instead of stretching.
     */
    private fun processingSize(): Pair<Int, Int> {
        var width = cameraBufferWidth
        var height = cameraBufferHeight
        if (width <= 0 || height <= 0) {
            width = drawableWidth.coerceAtLeast(1)
            height = drawableHeight.coerceAtLeast(1)
        } else if (drawableWidth > 0 && drawableHeight > 0) {
            // SurfaceTexture's transform orients the buffer to the view. When the
            // buffer is landscape and the view is portrait (or vice versa), swap
            // so the blit FBO matches the upright frame aspect.
            val viewPortrait = drawableHeight >= drawableWidth
            val bufferPortrait = height >= width
            if (viewPortrait != bufferPortrait) {
                val swapped = width
                width = height
                height = swapped
            }
        }
        val longSide = maxOf(width, height)
        if (longSide <= MAX_LONG) {
            return even(width) to even(height)
        }
        val scale = MAX_LONG.toFloat() / longSide
        return even((width * scale).toInt()) to even((height * scale).toInt())
    }

    private fun ensureBlitTexture(width: Int, height: Int) {
        if (blitTexture != 0 && blitWidth == width && blitHeight == height) {
            return
        }
        deleteBlit()
        blitWidth = width
        blitHeight = height
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        blitTexture = textures[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, blitTexture)
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            GLES20.GL_RGBA,
            width,
            height,
            0,
            GLES20.GL_RGBA,
            GLES20.GL_UNSIGNED_BYTE,
            null,
        )
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        val fbos = IntArray(1)
        GLES20.glGenFramebuffers(1, fbos, 0)
        blitFbo = fbos[0]
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, blitFbo)
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER,
            GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D,
            blitTexture,
            0,
        )
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    private fun blitOesTo2d() {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, blitFbo)
        GLES20.glViewport(0, 0, blitWidth, blitHeight)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glUseProgram(oesProgram)
        GLES20.glUniformMatrix4fv(oesMatrixLoc, 1, false, texMatrix, 0)
        GLES20.glUniform1i(oesMirrorLoc, if (frontFacing) 1 else 0)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTexture)
        GLES30.glBindVertexArray(vao)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES30.glBindVertexArray(0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
    }

    private fun drawToScreen(texture: Int, imageWidth: Int, imageHeight: Int) {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glViewport(0, 0, drawableWidth, drawableHeight)
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        if (imageWidth <= 0 || imageHeight <= 0 || drawableWidth <= 0 || drawableHeight <= 0) {
            return
        }
        val viewW = drawableWidth.toFloat()
        val viewH = drawableHeight.toFloat()
        val scale = minOf(viewW / imageWidth, viewH / imageHeight)
        val fittedW = imageWidth * scale
        val fittedH = imageHeight * scale
        val x = ((viewW - fittedW) / 2f).toInt()
        val y = ((viewH - fittedH) / 2f).toInt()
        GLES20.glViewport(x, y, fittedW.toInt(), fittedH.toInt())
        GLES20.glUseProgram(drawProgram)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
        GLES30.glBindVertexArray(vao)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES30.glBindVertexArray(0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
    }

    private fun resetEngineGlState() {
        GLES30.glBindVertexArray(0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glUseProgram(0)
    }

    private fun readLastOutput(): Bitmap? {
        if (lastOutputTexture == 0 || lastWidth <= 0 || lastHeight <= 0) {
            return null
        }
        val width = lastWidth
        val height = lastHeight
        val fbos = IntArray(1)
        GLES20.glGenFramebuffers(1, fbos, 0)
        val fbo = fbos[0]
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fbo)
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER,
            GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D,
            lastOutputTexture,
            0,
        )
        if (GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER) != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
            GLES20.glDeleteFramebuffers(1, fbos, 0)
            return null
        }
        val pixels = ByteBuffer.allocateDirect(width * height * 4).order(ByteOrder.nativeOrder())
        GLES20.glReadPixels(0, 0, width, height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixels)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glDeleteFramebuffers(1, fbos, 0)
        val stride = width * 4
        val flipped = ByteArray(stride * height)
        val row = ByteArray(stride)
        pixels.rewind()
        for (y in 0 until height) {
            pixels.position((height - 1 - y) * stride)
            pixels.get(row)
            System.arraycopy(row, 0, flipped, y * stride, stride)
        }
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(flipped))
        return bitmap
    }

    private fun releaseGl() {
        if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
            return
        }
        if (eglSurface != EGL14.EGL_NO_SURFACE) {
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        }
        onGlRelease?.invoke()
        cameraTexture?.setOnFrameAvailableListener(null)
        cameraSurface?.release()
        cameraSurface = null
        cameraTexture?.release()
        cameraTexture = null
        deleteBlit()
        if (oesTexture != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(oesTexture), 0)
            oesTexture = 0
        }
        if (vao != 0) {
            GLES30.glDeleteVertexArrays(1, intArrayOf(vao), 0)
            vao = 0
        }
        if (positionVbo != 0 || uvVbo != 0) {
            GLES20.glDeleteBuffers(2, intArrayOf(positionVbo, uvVbo), 0)
            positionVbo = 0
            uvVbo = 0
        }
        if (oesProgram != 0) {
            GLES20.glDeleteProgram(oesProgram)
            oesProgram = 0
        }
        if (drawProgram != 0) {
            GLES20.glDeleteProgram(drawProgram)
            drawProgram = 0
        }
        lastOutputTexture = 0
        glReady = false
        EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
        if (eglSurface != EGL14.EGL_NO_SURFACE) {
            EGL14.eglDestroySurface(eglDisplay, eglSurface)
            eglSurface = EGL14.EGL_NO_SURFACE
        }
        if (eglContext != EGL14.EGL_NO_CONTEXT) {
            EGL14.eglDestroyContext(eglDisplay, eglContext)
            eglContext = EGL14.EGL_NO_CONTEXT
        }
        EGL14.eglReleaseThread()
        EGL14.eglTerminate(eglDisplay)
        eglDisplay = EGL14.EGL_NO_DISPLAY
    }

    private fun deleteBlit() {
        if (blitFbo != 0) {
            GLES20.glDeleteFramebuffers(1, intArrayOf(blitFbo), 0)
            blitFbo = 0
        }
        if (blitTexture != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(blitTexture), 0)
            blitTexture = 0
        }
        blitWidth = 0
        blitHeight = 0
    }

    private fun link(vertex: String, fragment: String): Int {
        val vs = compile(GLES20.GL_VERTEX_SHADER, vertex)
        val fs = compile(GLES20.GL_FRAGMENT_SHADER, fragment)
        if (vs == 0 || fs == 0) {
            return 0
        }
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vs)
        GLES20.glAttachShader(program, fs)
        GLES20.glBindAttribLocation(program, 0, "aPos")
        GLES20.glBindAttribLocation(program, 1, "aUV")
        GLES20.glLinkProgram(program)
        GLES20.glDeleteShader(vs)
        GLES20.glDeleteShader(fs)
        val ok = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, ok, 0)
        if (ok[0] == 0) {
            Log.e(TAG, "Program link: ${GLES20.glGetProgramInfoLog(program)}")
            GLES20.glDeleteProgram(program)
            return 0
        }
        return program
    }

    private fun compile(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        val ok = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, ok, 0)
        if (ok[0] == 0) {
            Log.e(TAG, "Shader compile: ${GLES20.glGetShaderInfoLog(shader)}")
            GLES20.glDeleteShader(shader)
            return 0
        }
        return shader
    }

    private fun buffer(values: FloatArray): FloatBuffer {
        return ByteBuffer.allocateDirect(values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(values)
                position(0)
            }
    }

    companion object {
        private const val TAG = "TexturePreviewView"
        private const val MAX_LONG = 1280

        private const val OES_VERTEX = """#version 300 es
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUV;
uniform mat4 uTexMatrix;
uniform int uMirror;
out vec2 vUV;
void main() {
  gl_Position = vec4(aPos, 0.0, 1.0);
  vec2 uv = (uTexMatrix * vec4(aUV, 0.0, 1.0)).xy;
  if (uMirror == 1) {
    uv.x = 1.0 - uv.x;
  }
  vUV = uv;
}
"""

        private const val OES_FRAGMENT = """#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
in vec2 vUV;
uniform samplerExternalOES uTex;
out vec4 fragColor;
void main() {
  fragColor = texture(uTex, vUV);
}
"""

        private const val DRAW_VERTEX = """#version 300 es
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUV;
out vec2 vUV;
void main() {
  gl_Position = vec4(aPos, 0.0, 1.0);
  // TextureView window surface is top-left origin; GL textures are bottom-left.
  vUV = vec2(aUV.x, 1.0 - aUV.y);
}
"""

        private const val DRAW_FRAGMENT = """#version 300 es
precision mediump float;
in vec2 vUV;
uniform sampler2D uTex;
out vec4 fragColor;
void main() {
  fragColor = texture(uTex, vUV);
}
"""

        private fun even(value: Int): Int = (value.coerceAtLeast(2) / 2) * 2
    }
}
