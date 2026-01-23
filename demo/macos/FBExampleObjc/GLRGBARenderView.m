//
//  GLRGBARenderView.m
//  FBExampleObjc (macOS)
//

#import "GLRGBARenderView.h"
#import <OpenGL/gl3.h>

@interface GLRGBARenderView () {
  NSOpenGLContext *_glContext;
  GLuint _program;
  GLuint _vao;
  GLuint _vbo;
  GLuint _tbo;
  GLuint _texture;

  GLint _positionLoc;
  GLint _texCoordLoc;
  GLint _samplerLoc;

  FBImageBuffer *_currentBuffer;
  NSLock *_bufferLock;

  int32_t _videoWidth;
  int32_t _videoHeight;
  int32_t _viewWidth;
  int32_t _viewHeight;

  BOOL _mirrored;
}

- (void)setupGL;
- (void)tearDownGL;
- (GLuint)compileShader:(GLenum)type source:(const char *)src;
- (GLuint)createProgramWithVS:(const char *)vsFS:(const char *)fs;
- (void)updateTexture:(FBImageBuffer *)buffer;
- (void)updateVertices;

@end

@implementation GLRGBARenderView

- (instancetype)initWithFrame:(NSRect)frameRect {
  NSOpenGLPixelFormatAttribute attrs[] = {NSOpenGLPFAOpenGLProfile,
                                          NSOpenGLProfileVersion3_2Core,
                                          NSOpenGLPFAColorSize,
                                          (NSOpenGLPixelFormatAttribute)24,
                                          NSOpenGLPFAAlphaSize,
                                          (NSOpenGLPixelFormatAttribute)8,
                                          NSOpenGLPFADoubleBuffer,
                                          0};
  NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
  if (self = [super initWithFrame:frameRect pixelFormat:pf]) {
    // 在 Retina 下使用最佳分辨率表面，避免视口只占用点坐标（导致显示在左下角）
    [self setWantsBestResolutionOpenGLSurface:YES];
    _bufferLock = [[NSLock alloc] init];
    _videoWidth = _videoHeight = 0;
    _mirrored = NO;
    [self setupGL];
  }
  return self;
}

- (void)dealloc {
  [self tearDownGL];
}

- (void)prepareOpenGL {
  [super prepareOpenGL];
  [[self openGLContext] makeCurrentContext];
  // 使用 backing 像素尺寸设置视口，确保填满父视图
  NSRect backing = [self convertRectToBacking:self.bounds];
  _viewWidth = (int32_t)backing.size.width;
  _viewHeight = (int32_t)backing.size.height;
  glViewport(0, 0, _viewWidth, _viewHeight);
}

- (void)reshape {
  [super reshape];
  [[self openGLContext] makeCurrentContext];
  // Retina 下用 backing 尺寸，防止视口缩半导致画面居左下
  NSRect backing = [self convertRectToBacking:self.bounds];
  _viewWidth = (int32_t)backing.size.width;
  _viewHeight = (int32_t)backing.size.height;
  glViewport(0, 0, _viewWidth, _viewHeight);
  [self updateVertices];
}

- (void)setupGL {
  [[self openGLContext] makeCurrentContext];
  static const char *vs = "#version 150\n"
                          "in vec2 aPos;\n"
                          "in vec2 aTex;\n"
                          "out vec2 vTex;\n"
                          "void main(){\n"
                          "  gl_Position = vec4(aPos,0.0,1.0);\n"
                          "  vTex = aTex;\n"
                          "}";
  static const char *fs = "#version 150\n"
                          "uniform sampler2D uTex;\n"
                          "in vec2 vTex;\n"
                          "out vec4 fragColor;\n"
                          "void main(){\n"
                          "  fragColor = texture(uTex, vTex);\n"
                          "}";
  _program = [self createProgramWithVS:vs FS:fs];
  _positionLoc = glGetAttribLocation(_program, "aPos");
  _texCoordLoc = glGetAttribLocation(_program, "aTex");
  _samplerLoc = glGetUniformLocation(_program, "uTex");

  glGenVertexArrays(1, &_vao);
  glBindVertexArray(_vao);
  glGenBuffers(1, &_vbo);
  glGenBuffers(1, &_tbo);

  glGenTextures(1, &_texture);
  glBindTexture(GL_TEXTURE_2D, _texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  [self updateVertices];
}

- (void)tearDownGL {
  [[self openGLContext] makeCurrentContext];
  if (_texture) glDeleteTextures(1, &_texture);
  if (_vbo) glDeleteBuffers(1, &_vbo);
  if (_tbo) glDeleteBuffers(1, &_tbo);
  if (_vao) glDeleteVertexArrays(1, &_vao);
  if (_program) glDeleteProgram(_program);
  _texture = _vbo = _tbo = _vao = _program = 0;
}

- (GLuint)compileShader:(GLenum)type source:(const char *)src {
  GLuint s = glCreateShader(type);
  glShaderSource(s, 1, &src, NULL);
  glCompileShader(s);
  GLint ok = 0;
  glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    glDeleteShader(s);
    return 0;
  }
  return s;
}

- (GLuint)createProgramWithVS:(const char *)vs FS:(const char *)fs {
  GLuint v = [self compileShader:GL_VERTEX_SHADER source:vs];
  GLuint f = [self compileShader:GL_FRAGMENT_SHADER source:fs];
  if (!v || !f) return 0;
  GLuint p = glCreateProgram();
  glAttachShader(p, v);
  glAttachShader(p, f);
  glLinkProgram(p);
  glDeleteShader(v);
  glDeleteShader(f);
  GLint ok = 0;
  glGetProgramiv(p, GL_LINK_STATUS, &ok);
  if (!ok) {
    glDeleteProgram(p);
    return 0;
  }
  return p;
}

- (void)updateVertices {
  // 默认等比适配（letterbox/pillarbox）
  float vw = (_videoWidth > 0) ? (float)_videoWidth : 1.0f;
  float vh = (_videoHeight > 0) ? (float)_videoHeight : 1.0f;
  float ww = (_viewWidth > 0) ? (float)_viewWidth : (float)self.bounds.size.width;
  float wh = (_viewHeight > 0) ? (float)_viewHeight : (float)self.bounds.size.height;

  float videoAR = vw / vh;
  float viewAR = ww / wh;
  float sx = 1.0f, sy = 1.0f;
  if (videoAR > viewAR) {
    sy = viewAR / videoAR;
  } else {
    sx = videoAR / viewAR;
  }

  float vertices[] = {
      -sx,
      -sy,
      sx,
      -sy,
      -sx,
      sy,
      sx,
      sy,
  };
  float tex[] = {
      _mirrored ? 1.0f : 0.0f,
      1.0f,
      _mirrored ? 0.0f : 1.0f,
      1.0f,
      _mirrored ? 1.0f : 0.0f,
      0.0f,
      _mirrored ? 0.0f : 1.0f,
      0.0f,
  };

  glBindVertexArray(_vao);
  glBindBuffer(GL_ARRAY_BUFFER, _vbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(_positionLoc);
  glVertexAttribPointer(_positionLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);

  glBindBuffer(GL_ARRAY_BUFFER, _tbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(tex), tex, GL_STATIC_DRAW);
  glEnableVertexAttribArray(_texCoordLoc);
  glVertexAttribPointer(_texCoordLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void)setMirrored:(BOOL)mirrored {
  _mirrored = mirrored;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self updateVertices];
    [self setNeedsDisplay:YES];
  });
}

- (void)updateTexture:(FBImageBuffer *)buffer {
  if (!buffer) return;
  int32_t w = buffer.width;
  int32_t h = buffer.height;
  int32_t stride = buffer.stride;
  const uint8_t *data = buffer.data;
  if (!data) return;

  glBindTexture(GL_TEXTURE_2D, _texture);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  if (stride == w * 4) {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
  } else {
    // 逐行上传，处理 stride
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    for (int y = 0; y < h; ++y) {
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y, w, 1, GL_RGBA, GL_UNSIGNED_BYTE, data + y * stride);
    }
  }
}

- (void)renderBuffer:(FBImageBuffer *)buffer {
  if (!buffer) return;
  [_bufferLock lock];
  _currentBuffer = buffer;
  _videoWidth = buffer.width;
  _videoHeight = buffer.height;
  [_bufferLock unlock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self setNeedsDisplay:YES];
  });
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  [[self openGLContext] makeCurrentContext];
  // 每次绘制前根据 backing 尺寸刷新视口，避免窗口缩放后不更新
  NSRect backing = [self convertRectToBacking:self.bounds];
  int32_t curW = (int32_t)backing.size.width;
  int32_t curH = (int32_t)backing.size.height;
  if (curW != _viewWidth || curH != _viewHeight) {
    _viewWidth = curW;
    _viewHeight = curH;
    glViewport(0, 0, _viewWidth, _viewHeight);
    [self updateVertices];
  }
  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  FBImageBuffer *buffer = nil;
  [_bufferLock lock];
  buffer = _currentBuffer;
  [_bufferLock unlock];
  if (!buffer) {
    [[self openGLContext] flushBuffer];
    return;
  }

  [self updateVertices];
  [self updateTexture:buffer];

  glUseProgram(_program);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _texture);
  glUniform1i(_samplerLoc, 0);

  glBindVertexArray(_vao);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

  [[self openGLContext] flushBuffer];
}

@end
