//
//  GLTextureRenderView.m
//  FBExampleObjc
//
//  OpenGL ES 纹理渲染视图，支持外部纹理输入输出和回调处理
//

#import "GLTextureRenderView.h"
#import <OpenGLES/ES2/gl.h>
#import <QuartzCore/QuartzCore.h>

@interface GLTextureRenderView () {
  EAGLContext *_context;
  GLuint _framebuffer;
  GLuint _colorRenderbuffer;

  GLuint _program;
  GLint _positionHandle;
  GLint _texCoordHandle;
  GLint _textureHandle;

  // 顶点和纹理坐标数组（不使用 VBO，直接传递数组指针，与 gpupixel 保持一致）
  GLfloat _vertices[8];  // 4 个顶点，每个 2 个坐标 (x, y)
  GLfloat _texCoords[8]; // 4 个纹理坐标，每个 2 个坐标 (u, v)

  GLuint _inputTexture;
  GLuint _outputTexture;
  int _textureWidth;
  int _textureHeight;

  int _viewportWidth;
  int _viewportHeight;

  BOOL _mirrored;
  BOOL _renderingEnabled;

  CADisplayLink *_displayLink;
  
  // 保存输入图片，用于在重新设置时恢复纹理
  UIImage *_savedInputImage;
}

- (void)setupGL;
- (void)tearDownGL;
- (GLuint)loadShader:(GLenum)type source:(NSString *)source;
- (GLuint)createProgram:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource;
- (void)updateVertexCoordinates;
- (void)renderFrame;
- (void)createInputTextureFromSavedImage;

@end

@implementation GLTextureRenderView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.contentScaleFactor = [UIScreen mainScreen].scale;

    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{
      kEAGLDrawablePropertyRetainedBacking : @NO,
      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
    };

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
      NSLog(@"Failed to create EAGL context");
      return nil;
    }

    _inputTexture = 0;
    _outputTexture = 0;
    _textureWidth = 0;
    _textureHeight = 0;
    _viewportWidth = 0;
    _viewportHeight = 0;
    _mirrored = NO;
    _renderingEnabled = YES;

    // setupGL 将在 layoutSubviews 中调用
  }
  return self;
}

- (void)dealloc {
  [EAGLContext setCurrentContext:_context];
  
  // 在 dealloc 中删除输入纹理
  if (_inputTexture != 0) {
    glDeleteTextures(1, &_inputTexture);
    _inputTexture = 0;
  }
  
  [self tearDownGL];
  if (_displayLink) {
    [_displayLink invalidate];
    _displayLink = nil;
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];

  // 第一次布局时初始化 OpenGL
  if (_framebuffer == 0) {
    [EAGLContext setCurrentContext:_context];
    [self setupGL];
    [self startRenderLoop];
  } else {
    [EAGLContext setCurrentContext:_context];
    [self tearDownGL];
    [self setupGL];
  }

  _viewportWidth = (int)(self.bounds.size.width * self.contentScaleFactor);
  _viewportHeight = (int)(self.bounds.size.height * self.contentScaleFactor);

  [self updateVertexCoordinates];
}

- (void)startRenderLoop {
  if (_displayLink) {
    return;
  }
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame)];
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)setupGL {
  [EAGLContext setCurrentContext:_context];

  glGenFramebuffers(1, &_framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);

  glGenRenderbuffers(1, &_colorRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);

  CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
  if (eaglLayer.bounds.size.width <= 0 || eaglLayer.bounds.size.height <= 0) {
    return;
  }

  if (![_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer]) {
    return;
  }

  glFramebufferRenderbuffer(
      GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);

  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (status != GL_FRAMEBUFFER_COMPLETE) {
    return;
  }

  NSString *vertexShader = @"attribute vec4 a_position;\n"
                           @"attribute vec2 a_texCoord;\n"
                           @"varying vec2 v_texCoord;\n"
                           @"void main() {\n"
                           @"  gl_Position = a_position;\n"
                           @"  v_texCoord = a_texCoord;\n"
                           @"}\n";

  NSString *fragmentShader = @"precision mediump float;\n"
                             @"uniform sampler2D u_texture;\n"
                             @"varying vec2 v_texCoord;\n"
                             @"void main() {\n"
                             @"  gl_FragColor = texture2D(u_texture, v_texCoord);\n"
                             @"}\n";

  _program = [self createProgram:vertexShader fragmentSource:fragmentShader];
  if (_program == 0) {
    return;
  }

  // Get attribute and uniform locations
  _positionHandle = glGetAttribLocation(_program, "a_position");
  _texCoordHandle = glGetAttribLocation(_program, "a_texCoord");
  _textureHandle = glGetUniformLocation(_program, "u_texture");

  // 初始化顶点坐标（全屏显示）
  _vertices[0] = -1.0f; _vertices[1] = -1.0f;  // 左下
  _vertices[2] =  1.0f; _vertices[3] = -1.0f;  // 右下
  _vertices[4] = -1.0f; _vertices[5] =  1.0f;  // 左上
  _vertices[6] =  1.0f; _vertices[7] =  1.0f;  // 右上

  // 初始化纹理坐标（不镜像）
  _texCoords[0] = 0.0f; _texCoords[1] = 1.0f;  // 左下
  _texCoords[2] = 1.0f; _texCoords[3] = 1.0f;  // 右下
  _texCoords[4] = 0.0f; _texCoords[5] = 0.0f;  // 左上
  _texCoords[6] = 1.0f; _texCoords[7] = 0.0f;  // 右上

  glViewport(0, 0, (GLsizei)(self.bounds.size.width * self.contentScaleFactor),
             (GLsizei)(self.bounds.size.height * self.contentScaleFactor));
  
  if (_savedInputImage && _inputTexture == 0) {
    [self createInputTextureFromSavedImage];
  }
}

- (void)tearDownGL {
  [EAGLContext setCurrentContext:_context];

  if (_program) {
    glDeleteProgram(_program);
    _program = 0;
  }

  // 注意：不删除 _inputTexture，因为它是外部管理的资源
  // 当 layoutSubviews 被调用时（比如屏幕旋转），会重新设置 OpenGL 上下文
  // 但 _inputTexture 应该保持不变，因为它是在外部通过 initializeInputTextureWithImage: 创建的
  // 如果删除它，会导致纹理丢失
  // 注意：不再使用 VBO，所以不需要删除缓冲区

  if (_framebuffer) {
    glDeleteFramebuffers(1, &_framebuffer);
    _framebuffer = 0;
  }

  if (_colorRenderbuffer) {
    glDeleteRenderbuffers(1, &_colorRenderbuffer);
    _colorRenderbuffer = 0;
  }
}

- (GLuint)loadShader:(GLenum)type source:(NSString *)source {
  GLuint shader = glCreateShader(type);
  if (shader == 0) {
    return 0;
  }

  const char *sourceStr = [source UTF8String];
  glShaderSource(shader, 1, &sourceStr, NULL);
  glCompileShader(shader);

  GLint compiled;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
  if (!compiled) {
    GLint infoLen = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
    if (infoLen > 1) {
      char *infoLog = malloc(sizeof(char) * infoLen);
      glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
      NSLog(@"Error compiling shader:\n%s\n", infoLog);
      free(infoLog);
    }
    glDeleteShader(shader);
    return 0;
  }

  return shader;
}

- (GLuint)createProgram:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
  GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER source:vertexSource];
  if (vertexShader == 0) {
    return 0;
  }

  GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER source:fragmentSource];
  if (fragmentShader == 0) {
    glDeleteShader(vertexShader);
    return 0;
  }

  GLuint program = glCreateProgram();
  if (program == 0) {
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    return 0;
  }

  glAttachShader(program, vertexShader);
  glAttachShader(program, fragmentShader);
  glLinkProgram(program);

  GLint linkStatus;
  glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
  if (linkStatus == 0) {
    GLint infoLen = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
    if (infoLen > 1) {
      char *infoLog = malloc(sizeof(char) * infoLen);
      glGetProgramInfoLog(program, infoLen, NULL, infoLog);
      NSLog(@"Error linking program:\n%s\n", infoLog);
      free(infoLog);
    }
    glDeleteProgram(program);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    return 0;
  }

  glDeleteShader(vertexShader);
  glDeleteShader(fragmentShader);

  return program;
}

- (void)updateVertexCoordinates {
  if (_textureWidth <= 0 || _textureHeight <= 0 || _viewportWidth <= 0 || _viewportHeight <= 0) {
    // 如果尺寸信息不完整，使用全屏显示
    _vertices[0] = -1.0f; _vertices[1] = -1.0f;  // 左下
    _vertices[2] =  1.0f; _vertices[3] = -1.0f;  // 右下
    _vertices[4] = -1.0f; _vertices[5] =  1.0f;  // 左上
    _vertices[6] =  1.0f; _vertices[7] =  1.0f;  // 右上
    return;
  }

  // 计算纹理和视口的宽高比
  float textureAspect = (float)_textureWidth / (float)_textureHeight;
  float viewportAspect = (float)_viewportWidth / (float)_viewportHeight;

  float xScale = 1.0f;
  float yScale = 1.0f;

  if (textureAspect > viewportAspect) {
    // 纹理更宽，需要上下留黑边（letterbox）
    yScale = viewportAspect / textureAspect;
  } else {
    // 纹理更高，需要左右留黑边（pillarbox）
    xScale = textureAspect / viewportAspect;
  }

  // 更新顶点坐标数组
  _vertices[0] = -xScale; _vertices[1] = -yScale;  // 左下
  _vertices[2] =  xScale; _vertices[3] = -yScale;  // 右下
  _vertices[4] = -xScale; _vertices[5] =  yScale;  // 左上
  _vertices[6] =  xScale; _vertices[7] =  yScale;   // 右上
}

- (void)setMirrored:(BOOL)mirrored {
  if (_mirrored == mirrored) {
    return;
  }
  _mirrored = mirrored;

  // 更新纹理坐标数组（不需要 OpenGL 上下文）
  _texCoords[0] = _mirrored ? 1.0f : 0.0f; _texCoords[1] = 1.0f;  // 左下
  _texCoords[2] = _mirrored ? 0.0f : 1.0f; _texCoords[3] = 1.0f;  // 右下
  _texCoords[4] = _mirrored ? 1.0f : 0.0f; _texCoords[5] = 0.0f;  // 左上
  _texCoords[6] = _mirrored ? 0.0f : 1.0f; _texCoords[7] = 0.0f;  // 右上
}

- (void)setRenderingEnabled:(BOOL)enabled {
  _renderingEnabled = enabled;
}

- (CGSize)getViewportDimensions {
  return CGSizeMake(_viewportWidth, _viewportHeight);
}

- (void)initializeInputTextureWithImage:(UIImage *)image {
  if (!image) {
    return;
  }

  _savedInputImage = image;

  if (_framebuffer == 0) {
    return;  // 延迟到 setupGL 中创建
  }

  [self createInputTextureFromSavedImage];
}

- (void)createInputTextureFromSavedImage {
  if (!_savedInputImage) {
    return;
  }

  [EAGLContext setCurrentContext:_context];
  
  if (_inputTexture != 0) {
    glDeleteTextures(1, &_inputTexture);
    _inputTexture = 0;
  }

  CGImageRef cgImage = _savedInputImage.CGImage;
  size_t width = CGImageGetWidth(cgImage);
  size_t height = CGImageGetHeight(cgImage);
  size_t stride = width * 4;

  NSMutableData *rgbaData = [NSMutableData dataWithLength:stride * height];
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(rgbaData.mutableBytes, width, height, 8, stride,
                                                colorSpace,
                                                kCGImageAlphaPremultipliedLast |
                                                    kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);

  if (!context) {
    return;
  }

  CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
  CGContextRelease(context);

  glGenTextures(1, &_inputTexture);
  glBindTexture(GL_TEXTURE_2D, _inputTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, rgbaData.bytes);

  _textureWidth = (int)width;
  _textureHeight = (int)height;
  [self updateVertexCoordinates];
}

- (void)renderFrame {
  if (!_renderingEnabled || _inputTexture == 0 || !self.delegate) {
    return;
  }

  if (_framebuffer == 0 || _colorRenderbuffer == 0) {
    return;
  }

  [EAGLContext setCurrentContext:_context];
  
 
  TextureFrame srcFrame = {_inputTexture, _textureWidth, _textureHeight};
  TextureFrame dstFrame = {0, 0, 0};
  int errorCode = [self.delegate onProcessVideoFrame:srcFrame dstFrame:&dstFrame];

  if (errorCode != 0 || dstFrame.textureId == 0 || dstFrame.width <= 0 || dstFrame.height <= 0) {
    return;
  }

  glViewport(0, 0, _viewportWidth, _viewportHeight);

  _outputTexture = dstFrame.textureId;
  if (dstFrame.width > 0 && dstFrame.height > 0) {
    if (_textureWidth != dstFrame.width || _textureHeight != dstFrame.height) {
      _textureWidth = dstFrame.width;
      _textureHeight = dstFrame.height;
      [self updateVertexCoordinates];
    }
  }

  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
  GLenum fboStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (fboStatus != GL_FRAMEBUFFER_COMPLETE) {
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                              GL_RENDERBUFFER, _colorRenderbuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
      return;
    }
  }

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

  // Use shader program
  glUseProgram(_program);

  // 直接传递数组指针，不使用 VBO（与 gpupixel 保持一致）
  glEnableVertexAttribArray(_positionHandle);
  glVertexAttribPointer(_positionHandle, 2, GL_FLOAT, GL_FALSE, 0, _vertices);

  glEnableVertexAttribArray(_texCoordHandle);
  glVertexAttribPointer(_texCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, _texCoords);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _outputTexture);
  glUniform1i(_textureHandle, 0);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

  glDisableVertexAttribArray(_positionHandle);
  glDisableVertexAttribArray(_texCoordHandle);
  
  // 恢复 renderbuffer 绑定（gpupixel 可能修改了当前绑定）
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
  [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end

