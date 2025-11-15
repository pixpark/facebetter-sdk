//
//  GLRGBARenderView.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//

#import "GLRGBARenderView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

@interface GLRGBARenderView () {
  EAGLContext *_context;
  GLuint _framebuffer;
  GLuint _colorRenderbuffer;
  GLuint _texture;
  
  GLuint _program;
  GLint _positionHandle;
  GLint _texCoordHandle;
  GLint _textureHandle;
  
  GLuint _vertexBuffer;
  GLuint _texCoordBuffer;
  
  FBImageBuffer *_currentBuffer;
  NSLock *_bufferLock;
  
  int32_t _videoWidth;
  int32_t _videoHeight;
  int32_t _viewWidth;
  int32_t _viewHeight;

  // 渲染内容模式：0 = 等比适配(留黑边)，1 = 等比填充(可能裁剪)
  NSInteger _contentMode;

  BOOL _mirrored;
}

- (void)setupGL;
- (void)tearDownGL;
- (GLuint)loadShader:(GLenum)type source:(NSString *)source;
- (GLuint)createProgram:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource;
- (void)updateTexture:(FBImageBuffer *)buffer;
- (void)updateVertexCoordinates;

@end

@implementation GLRGBARenderView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{
      kEAGLDrawablePropertyRetainedBacking: @NO,
      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
    };
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
      NSLog(@"Failed to create EAGL context");
      return nil;
    }
    
    _bufferLock = [[NSLock alloc] init];
    _videoWidth = 0;
    _videoHeight = 0;
    _viewWidth = 0;
    _viewHeight = 0;
    _contentMode = 0; // 默认等比适配
    _mirrored = NO;   // 默认不镜像
    
    // setupGL 将在 layoutSubviews 中调用，此时 view 已经添加到视图层级
  }
  return self;
}

- (void)dealloc {
  [self tearDownGL];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // 第一次布局时初始化 OpenGL
  if (_framebuffer == 0) {
    [EAGLContext setCurrentContext:_context];
    [self setupGL];
  } else {
    [EAGLContext setCurrentContext:_context];
    [self tearDownGL];
    [self setupGL];
  }
  
  _viewWidth = (int32_t)(self.bounds.size.width * self.contentScaleFactor);
  _viewHeight = (int32_t)(self.bounds.size.height * self.contentScaleFactor);
  
  [self updateVertexCoordinates];
  
  [self display];
}

- (void)setupGL {
  [EAGLContext setCurrentContext:_context];
  
  // Create framebuffer
  glGenFramebuffers(1, &_framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
  
  // Create color renderbuffer
  glGenRenderbuffers(1, &_colorRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
  
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
  
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (status != GL_FRAMEBUFFER_COMPLETE) {
    NSLog(@"Failed to make complete framebuffer object: %x", status);
    return;
  }
  
  // Create texture
  glGenTextures(1, &_texture);
  glBindTexture(GL_TEXTURE_2D, _texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  
  // Create shader program
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
    NSLog(@"Failed to create shader program");
    return;
  }
  
  // Get attribute and uniform locations
  _positionHandle = glGetAttribLocation(_program, "a_position");
  _texCoordHandle = glGetAttribLocation(_program, "a_texCoord");
  _textureHandle = glGetUniformLocation(_program, "u_texture");
  
  // Create vertex buffer
  GLfloat vertices[] = {
    -1.0f, -1.0f,  // 左下
     1.0f, -1.0f,  // 右下
    -1.0f,  1.0f,  // 左上
     1.0f,  1.0f   // 右上
  };
  
  glGenBuffers(1, &_vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  
  // Create texture coordinate buffer（考虑镜像）
  GLfloat texCoords[] = {
    _mirrored ? 1.0f : 0.0f, 1.0f,  // 左下
    _mirrored ? 0.0f : 1.0f, 1.0f,  // 右下
    _mirrored ? 1.0f : 0.0f, 0.0f,  // 左上
    _mirrored ? 0.0f : 1.0f, 0.0f   // 右上
  };
  
  glGenBuffers(1, &_texCoordBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, _texCoordBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
  
  glViewport(0, 0, (GLsizei)(self.bounds.size.width * self.contentScaleFactor), 
                   (GLsizei)(self.bounds.size.height * self.contentScaleFactor));
}

- (void)setMirrored:(BOOL)mirrored {
  _mirrored = mirrored;
  [EAGLContext setCurrentContext:_context];
  GLfloat texCoords[] = {
    _mirrored ? 1.0f : 0.0f, 1.0f,
    _mirrored ? 0.0f : 1.0f, 1.0f,
    _mirrored ? 1.0f : 0.0f, 0.0f,
    _mirrored ? 0.0f : 1.0f, 0.0f
  };
  glBindBuffer(GL_ARRAY_BUFFER, _texCoordBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self display];
  });
}

- (void)tearDownGL {
  [EAGLContext setCurrentContext:_context];
  
  if (_program) {
    glDeleteProgram(_program);
    _program = 0;
  }
  
  if (_texture) {
    glDeleteTextures(1, &_texture);
    _texture = 0;
  }
  
  if (_vertexBuffer) {
    glDeleteBuffers(1, &_vertexBuffer);
    _vertexBuffer = 0;
  }
  
  if (_texCoordBuffer) {
    glDeleteBuffers(1, &_texCoordBuffer);
    _texCoordBuffer = 0;
  }
  
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
  if (_videoWidth <= 0 || _videoHeight <= 0 || _viewWidth <= 0 || _viewHeight <= 0) {
    // 如果尺寸信息不完整，使用全屏显示
    GLfloat vertices[] = {
      -1.0f, -1.0f,  // 左下
       1.0f, -1.0f,  // 右下
      -1.0f,  1.0f,  // 左上
       1.0f,  1.0f   // 右上
    };
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    return;
  }
  
  // 计算视频和视口的宽高比
  float videoAspectRatio = ((float)_videoWidth) / ((float)_videoHeight);
  float viewportAspectRatio = ((float)_viewWidth) / ((float)_viewHeight);
  
  float scaleX = 1.0f;
  float scaleY = 1.0f;

  if (_contentMode == 0) {
    // 等比适配（留黑边）Aspect Fit
    if (videoAspectRatio > viewportAspectRatio) {
      // 视频更宽，左右对齐，上下留黑边
      scaleX = 1.0f;
      scaleY = viewportAspectRatio / videoAspectRatio;
    } else {
      // 视频更高，左右留黑边
      scaleX = videoAspectRatio / viewportAspectRatio;
      scaleY = 1.0f;
    }
  } else {
    // 等比填充（可能裁剪）Aspect Fill
    if (videoAspectRatio > viewportAspectRatio) {
      // 视频更宽，需要放大到填满高度，左右裁剪
      scaleX = videoAspectRatio / viewportAspectRatio;
      scaleY = 1.0f;
    } else {
      // 视频更高，需要放大到填满宽度，上下裁剪
      scaleX = 1.0f;
      scaleY = viewportAspectRatio / videoAspectRatio;
    }
    // 将放大后的顶点归一化到 [-1,1] 区间进行裁剪显示
    // 这里通过反向缩放顶点达到裁剪效果
    scaleX = 1.0f / scaleX;
    scaleY = 1.0f / scaleY;
  }
  
  // 更新顶点坐标
  GLfloat vertices[] = {
    -scaleX, -scaleY,  // 左下
     scaleX, -scaleY,  // 右下
    -scaleX,  scaleY,  // 左上
     scaleX,  scaleY   // 右上
  };
  
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)updateTexture:(FBImageBuffer *)buffer {
  if (!buffer) {
    return;
  }
  
  int32_t width = buffer.width;
  int32_t height = buffer.height;
  int32_t stride = buffer.stride;
  const uint8_t *data = buffer.data;
  
  if (!data) {
    return;
  }
  
  glBindTexture(GL_TEXTURE_2D, _texture);
  
  // Set pixel store alignment
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  
  if (stride == width * 4) {
    // No padding, upload directly
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
  } else {
    // Handle stride by uploading row by row
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    for (int y = 0; y < height; y++) {
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y, width, 1, GL_RGBA, GL_UNSIGNED_BYTE, data + y * stride);
    }
  }
}

- (void)renderBuffer:(FBImageBuffer *)buffer {
  if (!buffer) {
    return;
  }
  
  [_bufferLock lock];
  // 仅记录当前缓冲及尺寸，具体顶点更新放在 display，确保以最新视口尺寸计算
  _videoWidth = buffer.width;
  _videoHeight = buffer.height;
  _currentBuffer = buffer;
  
  [_bufferLock unlock];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self display];
  });
}

- (void)display {
  if (!_context || _framebuffer == 0) {
    return;
  }
  
  [EAGLContext setCurrentContext:_context];
  
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
  
  // 更新 viewport 尺寸（如果改变了）
  int32_t currentViewWidth = (int32_t)(self.bounds.size.width * self.contentScaleFactor);
  int32_t currentViewHeight = (int32_t)(self.bounds.size.height * self.contentScaleFactor);
  
  if (currentViewWidth != _viewWidth || currentViewHeight != _viewHeight) {
    _viewWidth = currentViewWidth;
    _viewHeight = currentViewHeight;
  }
  
  // 确保使用最新的视频尺寸与视口尺寸计算顶点（避免早期调用导致全屏顶点覆盖）
  [self updateVertexCoordinates];
  
  glViewport(0, 0, _viewWidth, _viewHeight);
  
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  
  [_bufferLock lock];
  FBImageBuffer *buffer = _currentBuffer;
  [_bufferLock unlock];
  
  if (!buffer) {
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    return;
  }
  
  // Use shader program
  glUseProgram(_program);
  
  // Update texture
  [self updateTexture:buffer];
  
  // Set vertex attributes
  glEnableVertexAttribArray(_positionHandle);
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
  glVertexAttribPointer(_positionHandle, 2, GL_FLOAT, GL_FALSE, 0, 0);
  
  glEnableVertexAttribArray(_texCoordHandle);
  glBindBuffer(GL_ARRAY_BUFFER, _texCoordBuffer);
  glVertexAttribPointer(_texCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, 0);
  
  // Bind texture
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _texture);
  glUniform1i(_textureHandle, 0);
  
  // Draw
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  // Disable vertex arrays
  glDisableVertexAttribArray(_positionHandle);
  glDisableVertexAttribArray(_texCoordHandle);
  
  [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end

