import UIKit
import SwiftUI

/// Turns the camera buffer into a GL_TEXTURE_2D, asks GlTextureInput to process it,
/// then draws the output texture in this context. The draw is ordered after the
/// engine's GL commands, so the preview does not sample an unfinished texture.
final class GlTexturePreview: UIView {
  let glQueue = DispatchQueue(label: "net.pixpark.fbstudio.texture.gl")

  var process: ((UInt32, Int32, Int32) -> UInt32)?
  var onPresented: (() -> Void)?

  private var glContext: EAGLContext?
  private var textureCache: CVOpenGLESTextureCache?
  private var framebuffer: GLuint = 0
  private var colorbuffer: GLuint = 0
  private var drawableWidth: GLint = 0
  private var drawableHeight: GLint = 0
  private var program: GLuint = 0
  private var vao: GLuint = 0
  private var positionVbo: GLuint = 0
  private var uvVbo: GLuint = 0
  private var prepared = false
  private var needsResize = true
  private var busy = false
  private let busyLock = NSLock()
  private var drawableLayer: CAEAGLLayer!

  override class var layerClass: AnyClass {
    CAEAGLLayer.self
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    let eaglLayer = layer as! CAEAGLLayer
    drawableLayer = eaglLayer
    contentScaleFactor = UIScreen.main.scale
    backgroundColor = .black
    isOpaque = true
    eaglLayer.isOpaque = true
    eaglLayer.drawableProperties = [
      kEAGLDrawablePropertyRetainedBacking: false,
      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
    ]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    glQueue.async { [weak self] in
      self?.needsResize = true
    }
  }

  func prepare() {
    glQueue.sync {
      guard !self.prepared else { return }
      let context = EAGLContext(api: .openGLES3)
      guard let context else {
        NSLog("GlTexturePreview: failed to create EAGLContext")
        return
      }
      EAGLContext.setCurrent(context)
      self.glContext = context

      var cache: CVOpenGLESTextureCache?
      let cacheStatus = CVOpenGLESTextureCacheCreate(
        kCFAllocatorDefault,
        nil,
        context,
        nil,
        &cache
      )
      guard cacheStatus == kCVReturnSuccess, let cache else {
        NSLog("GlTexturePreview: CVOpenGLESTextureCacheCreate failed %d", cacheStatus)
        return
      }
      self.textureCache = cache
      self.buildProgram()
      self.buildQuad()
      self.prepared = self.program != 0
    }
  }

  func shutdown() {
    glQueue.sync {
      guard let context = self.glContext else { return }
      EAGLContext.setCurrent(context)
      self.deleteBuffers()
      if self.program != 0 {
        glDeleteProgram(self.program)
        self.program = 0
      }
      self.textureCache = nil
      self.prepared = false
      EAGLContext.setCurrent(nil)
      self.glContext = nil
    }
  }

  func runOnGL(_ work: @escaping () -> Void) {
    glQueue.async { [weak self] in
      guard let self, let context = self.glContext else { return }
      EAGLContext.setCurrent(context)
      work()
    }
  }

  func runOnGLSync(_ work: () -> Void) {
    glQueue.sync {
      if let context = self.glContext {
        EAGLContext.setCurrent(context)
      }
      work()
    }
  }

  func submit(_ pixelBuffer: CVPixelBuffer, bypass: Bool) {
    busyLock.lock()
    if busy {
      busyLock.unlock()
      return
    }
    busy = true
    busyLock.unlock()

    glQueue.async { [weak self] in
      defer {
        self?.busyLock.lock()
        self?.busy = false
        self?.busyLock.unlock()
      }
      self?.render(pixelBuffer, bypass: bypass)
    }
  }

  /// Export runs on this context. The GL engine cannot take a CVPixelBuffer, so the
  /// photo goes through the CPU pixel path and waits for the still.
  func captureStill(_ pixelBuffer: CVPixelBuffer, engine: BeautyEngine) -> UIImage? {
    var image: UIImage?
    runOnGLSync {
      image = CpuPixelInput.image(from: pixelBuffer, engine: engine)
    }
    return image
  }

  private func render(_ pixelBuffer: CVPixelBuffer, bypass: Bool) {
    guard prepared, let context = glContext, let cache = textureCache else { return }
    EAGLContext.setCurrent(context)
    resizeDrawableIfNeeded()
    guard drawableWidth > 0, drawableHeight > 0 else { return }

    let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
    let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
    var cvTexture: CVOpenGLESTexture?
    let format = GLenum(0x80E1) // GL_BGRA
    let status = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      cache,
      pixelBuffer,
      nil,
      GLenum(GL_TEXTURE_2D),
      GL_RGBA,
      GLsizei(width),
      GLsizei(height),
      format,
      GLenum(GL_UNSIGNED_BYTE),
      0,
      &cvTexture
    )
    guard status == kCVReturnSuccess, let cvTexture else { return }

    let inputTexture = CVOpenGLESTextureGetName(cvTexture)
    glBindTexture(GLenum(GL_TEXTURE_2D), inputTexture)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

    var outputTexture = inputTexture
    if !bypass, let process {
      // SDK face-detect path uses GLES2 client arrays. A bound VBO/VAO makes
      // those CPU pointers look like buffer offsets and crashes in glDrawArrays.
      resetEngineGLState()
      outputTexture = process(inputTexture, width, height)
      if outputTexture == 0 {
        outputTexture = inputTexture
      }
    }

    draw(texture: outputTexture, imageWidth: width, imageHeight: height)
    context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    CVOpenGLESTextureCacheFlush(cache, 0)
    onPresented?()
  }

  private func draw(texture: GLuint, imageWidth: Int32, imageHeight: Int32) {
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
    glViewport(0, 0, drawableWidth, drawableHeight)
    glClearColor(0, 0, 0, 1)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

    let viewW = CGFloat(drawableWidth)
    let viewH = CGFloat(drawableHeight)
    let imageW = CGFloat(imageWidth)
    let imageH = CGFloat(imageHeight)
    guard imageW > 0, imageH > 0 else { return }
    let scale = min(viewW / imageW, viewH / imageH)
    let fittedW = imageW * scale
    let fittedH = imageH * scale
    let x = GLint((viewW - fittedW) / 2)
    let y = GLint((viewH - fittedH) / 2)
    glViewport(x, y, GLsizei(fittedW), GLsizei(fittedH))

    glUseProgram(program)
    glActiveTexture(GLenum(GL_TEXTURE0))
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glBindVertexArray(vao)
    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
    glBindVertexArray(0)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorbuffer)
  }

  private func resetEngineGLState() {
    glBindVertexArray(0)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    glUseProgram(0)
  }

  private func resizeDrawableIfNeeded() {
    guard needsResize, let context = glContext else { return }
    needsResize = false
    if framebuffer == 0 {
      glGenFramebuffers(1, &framebuffer)
      glGenRenderbuffers(1, &colorbuffer)
    }
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorbuffer)
    context.renderbufferStorage(Int(GL_RENDERBUFFER), from: drawableLayer)
    glFramebufferRenderbuffer(
      GLenum(GL_FRAMEBUFFER),
      GLenum(GL_COLOR_ATTACHMENT0),
      GLenum(GL_RENDERBUFFER),
      colorbuffer
    )
    glGetRenderbufferParameteriv(
      GLenum(GL_RENDERBUFFER),
      GLenum(GL_RENDERBUFFER_WIDTH),
      &drawableWidth
    )
    glGetRenderbufferParameteriv(
      GLenum(GL_RENDERBUFFER),
      GLenum(GL_RENDERBUFFER_HEIGHT),
      &drawableHeight
    )
  }

  private func buildProgram() {
    let vertex = """
    #version 300 es
    layout(location = 0) in vec2 aPos;
    layout(location = 1) in vec2 aUV;
    out vec2 vUV;
    void main() {
      gl_Position = vec4(aPos, 0.0, 1.0);
      vUV = aUV;
    }
    """
    let fragment = """
    #version 300 es
    precision mediump float;
    in vec2 vUV;
    uniform sampler2D uTex;
    out vec4 fragColor;
    void main() {
      fragColor = texture(uTex, vUV);
    }
    """
    let vs = compile(type: GLenum(GL_VERTEX_SHADER), source: vertex)
    let fs = compile(type: GLenum(GL_FRAGMENT_SHADER), source: fragment)
    guard vs != 0, fs != 0 else { return }
    program = glCreateProgram()
    glAttachShader(program, vs)
    glAttachShader(program, fs)
    glLinkProgram(program)
    glDeleteShader(vs)
    glDeleteShader(fs)
    var ok: GLint = 0
    glGetProgramiv(program, GLenum(GL_LINK_STATUS), &ok)
    if ok == GL_FALSE {
      NSLog("GlTexturePreview: program link failed")
      glDeleteProgram(program)
      program = 0
      return
    }
    glUseProgram(program)
    glUniform1i(glGetUniformLocation(program, "uTex"), 0)
  }

  private func compile(type: GLenum, source: String) -> GLuint {
    let shader = glCreateShader(type)
    source.withCString { pointer in
      var cString: UnsafePointer<GLchar>? = UnsafePointer(pointer)
      var length = GLint(source.utf8.count)
      glShaderSource(shader, 1, &cString, &length)
    }
    glCompileShader(shader)
    var ok: GLint = 0
    glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &ok)
    if ok == GL_FALSE {
      var logLength: GLint = 0
      glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
      if logLength > 0 {
        var log = [GLchar](repeating: 0, count: Int(logLength))
        glGetShaderInfoLog(shader, logLength, nil, &log)
        NSLog("GlTexturePreview shader: %s", log)
      }
      glDeleteShader(shader)
      return 0
    }
    return shader
  }

  private func buildQuad() {
    let positions: [GLfloat] = [-1, -1, 1, -1, -1, 1, 1, 1]
    let uvs: [GLfloat] = [0, 1, 1, 1, 0, 0, 1, 0]
    glGenVertexArrays(1, &vao)
    glBindVertexArray(vao)
    glGenBuffers(1, &positionVbo)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), positionVbo)
    positions.withUnsafeBytes { bytes in
      glBufferData(GLenum(GL_ARRAY_BUFFER), bytes.count, bytes.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    glGenBuffers(1, &uvVbo)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), uvVbo)
    uvs.withUnsafeBytes { bytes in
      glBufferData(GLenum(GL_ARRAY_BUFFER), bytes.count, bytes.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    glEnableVertexAttribArray(1)
    glVertexAttribPointer(1, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    glBindVertexArray(0)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
  }

  private func deleteBuffers() {
    if framebuffer != 0 {
      glDeleteFramebuffers(1, &framebuffer)
      framebuffer = 0
    }
    if colorbuffer != 0 {
      glDeleteRenderbuffers(1, &colorbuffer)
      colorbuffer = 0
    }
    if vao != 0 {
      glDeleteVertexArrays(1, &vao)
      vao = 0
    }
    if positionVbo != 0 {
      glDeleteBuffers(1, &positionVbo)
      positionVbo = 0
    }
    if uvVbo != 0 {
      glDeleteBuffers(1, &uvVbo)
      uvVbo = 0
    }
  }
}

struct GlTexturePreviewRepresentable: UIViewRepresentable {
  let preview: GlTexturePreview

  func makeUIView(context: Context) -> GlTexturePreview {
    preview
  }

  func updateUIView(_ uiView: GlTexturePreview, context: Context) {}
}
