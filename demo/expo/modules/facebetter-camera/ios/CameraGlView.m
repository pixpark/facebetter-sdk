#define GLES_SILENCE_DEPRECATION
#import "CameraGlView.h"

#import "SkinEngine.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <stdatomic.h>
#import <time.h>

@interface CameraGlView () <AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation CameraGlView {
  CAEAGLLayer *_drawableLayer;
  dispatch_queue_t _glQueue;
  dispatch_queue_t _sessionQueue;
  EAGLContext *_context;
  CVOpenGLESTextureCacheRef _textureCache;
  GLuint _framebuffer;
  GLuint _colorbuffer;
  GLint _drawableWidth;
  GLint _drawableHeight;
  GLuint _program;
  GLuint _vao;
  GLuint _positionVbo;
  GLuint _uvVbo;
  BOOL _prepared;
  BOOL _needsResize;
  BOOL _busy;
  BOOL _started;
  BOOL _reportedSize;
  atomic_int _statsPosted;

  AVCaptureSession *_session;
  AVCaptureVideoDataOutput *_videoOutput;
  SkinEngine *_engine;

  float _smoothing;
  float _whitening;
  float _rosiness;
  float _blemish;
  float _clarity;
  BOOL _skinOnly;
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _glQueue = dispatch_queue_create("net.pixpark.fbexample.expo.gl", DISPATCH_QUEUE_SERIAL);
    _sessionQueue = dispatch_queue_create("net.pixpark.fbexample.expo.camera", DISPATCH_QUEUE_SERIAL);
    _engine = [[SkinEngine alloc] init];
    _smoothing = 0.6f;
    _whitening = 0.3f;
    _rosiness = 0.15f;
    _blemish = 0;
    _clarity = 0.2f;
    _drawableLayer = (CAEAGLLayer *)self.layer;
    self.contentScaleFactor = UIScreen.mainScreen.scale;
    self.backgroundColor = UIColor.blackColor;
    self.opaque = YES;
    _drawableLayer.opaque = YES;
    _drawableLayer.drawableProperties = @{
      kEAGLDrawablePropertyRetainedBacking: @NO,
      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
    };
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  dispatch_async(_glQueue, ^{
    self->_needsResize = YES;
  });
}

- (void)start {
  if (_started) {
    return;
  }
  _started = YES;
  [self requestCamera:^(BOOL granted) {
    if (!self->_started) {
      return;
    }
    if (!granted) {
      [self emitStatus:@"cameraDenied"];
      return;
    }
    dispatch_async(self->_glQueue, ^{
      if (!self->_started) {
        return;
      }
      [self prepareGL];
      if (!self->_prepared) {
        [self emitStatus:@"initFailed"];
        return;
      }
      [self->_engine start:^(NSString *status) {
        [self emitStatus:status];
      }];
      [self applyLocked];
      dispatch_async(self->_sessionQueue, ^{
        [self startCamera];
      });
    });
  }];
}

- (void)shutdown {
  _started = NO;
  dispatch_sync(_sessionQueue, ^{
    if (self->_session.isRunning) {
      [self->_session stopRunning];
    }
  });
  dispatch_sync(_glQueue, ^{
    if (self->_context == nil) {
      return;
    }
    [EAGLContext setCurrentContext:self->_context];
    [self->_engine releaseEngine];
    [self deleteGL];
    self->_prepared = NO;
    [EAGLContext setCurrentContext:nil];
    self->_context = nil;
  });
}

- (void)applySmoothing:(float)smoothing
             whitening:(float)whitening
              rosiness:(float)rosiness
               blemish:(float)blemish
               clarity:(float)clarity
              skinOnly:(BOOL)skinOnly {
  _smoothing = smoothing;
  _whitening = whitening;
  _rosiness = rosiness;
  _blemish = blemish;
  _clarity = clarity;
  _skinOnly = skinOnly;
  dispatch_async(_glQueue, ^{
    [self applyLocked];
  });
}

- (void)applyLocked {
  [_engine applySmoothing:_smoothing
                whitening:_whitening
                 rosiness:_rosiness
                  blemish:_blemish
                  clarity:_clarity
                 skinOnly:_skinOnly];
}

- (void)requestCamera:(void (^)(BOOL granted))completion {
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status == AVAuthorizationStatusAuthorized) {
    completion(YES);
    return;
  }
  if (status == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:completion];
    return;
  }
  completion(NO);
}

- (void)startCamera {
  if (_session == nil) {
    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
      _session.sessionPreset = AVCaptureSessionPreset1920x1080;
    } else if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
      _session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                  mediaType:AVMediaTypeVideo
                                                                   position:AVCaptureDevicePositionFront];
    if (device == nil) {
      [self emitStatus:@"initFailed"];
      return;
    }
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input == nil || ![_session canAddInput:input]) {
      [self emitStatus:@"initFailed"];
      return;
    }
    [_session addInput:input];

    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    _videoOutput.videoSettings = @{
      (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
    };
    [_videoOutput setSampleBufferDelegate:self queue:_glQueue];
    if (![_session canAddOutput:_videoOutput]) {
      [self emitStatus:@"initFailed"];
      return;
    }
    [_session addOutput:_videoOutput];

    AVCaptureConnection *connection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
      connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    if (connection.isVideoMirroringSupported) {
      connection.automaticallyAdjustsVideoMirroring = NO;
      connection.videoMirrored = YES;
    }
  }
  if (!_session.isRunning) {
    [_session startRunning];
  }
}

- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  if (_busy || !_prepared) {
    return;
  }
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (pixelBuffer == nil) {
    return;
  }
  _busy = YES;
  [self render:pixelBuffer];
  _busy = NO;
}

- (void)prepareGL {
  if (_prepared) {
    return;
  }
  _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  if (_context == nil || ![EAGLContext setCurrentContext:_context]) {
    return;
  }
  CVReturn cacheStatus = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
  if (cacheStatus != kCVReturnSuccess || _textureCache == NULL) {
    return;
  }
  [self buildProgram];
  [self buildQuad];
  _prepared = _program != 0;
}

- (void)render:(CVPixelBufferRef)pixelBuffer {
  if (!_prepared || _context == nil || _textureCache == NULL) {
    return;
  }
  [EAGLContext setCurrentContext:_context];
  [self resizeDrawableIfNeeded];
  if (_drawableWidth <= 0 || _drawableHeight <= 0) {
    return;
  }

  int width = (int)CVPixelBufferGetWidth(pixelBuffer);
  int height = (int)CVPixelBufferGetHeight(pixelBuffer);
  if (!_reportedSize && width > 0 && height > 0) {
    _reportedSize = YES;
    [self emitStatus:[NSString stringWithFormat:@"camera %dx%d", width, height]];
  }

  CVOpenGLESTextureRef cvTexture = NULL;
  CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height,
      0x80E1, GL_UNSIGNED_BYTE, 0, &cvTexture);
  if (status != kCVReturnSuccess || cvTexture == NULL) {
    return;
  }
  GLuint inputTexture = CVOpenGLESTextureGetName(cvTexture);
  glBindTexture(GL_TEXTURE_2D, inputTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glBindVertexArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glUseProgram(0);

  uint64_t started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
  GLuint outputTexture = [_engine processTexture:inputTexture width:width height:height];
  double milliseconds = (double)(clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - started) / 1e6;
  if (outputTexture == 0) {
    outputTexture = inputTexture;
  }
  [self publishFrameMs:milliseconds];

  [self drawTexture:outputTexture imageWidth:width imageHeight:height];
  [_context presentRenderbuffer:GL_RENDERBUFFER];
  CFRelease(cvTexture);
  CVOpenGLESTextureCacheFlush(_textureCache, 0);
}

- (void)publishFrameMs:(double)milliseconds {
  if (atomic_exchange(&_statsPosted, 1) != 0) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    atomic_store(&self->_statsPosted, 0);
    if (self.onFrameMs) {
      self.onFrameMs(milliseconds);
    }
  });
}

- (void)drawTexture:(GLuint)texture imageWidth:(int)imageWidth imageHeight:(int)imageHeight {
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
  glViewport(0, 0, _drawableWidth, _drawableHeight);
  glClearColor(0, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  if (imageWidth <= 0 || imageHeight <= 0) {
    return;
  }
  float viewW = (float)_drawableWidth;
  float viewH = (float)_drawableHeight;
  float scale = MIN(viewW / imageWidth, viewH / imageHeight);
  int fittedW = (int)(imageWidth * scale);
  int fittedH = (int)(imageHeight * scale);
  int x = (int)((viewW - fittedW) / 2);
  int y = (int)((viewH - fittedH) / 2);
  glViewport(x, y, MAX(fittedW, 1), MAX(fittedH, 1));
  glUseProgram(_program);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture);
  glBindVertexArray(_vao);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glBindVertexArray(0);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorbuffer);
}

- (void)resizeDrawableIfNeeded {
  if (!_needsResize || _context == nil) {
    return;
  }
  _needsResize = NO;
  if (_framebuffer == 0) {
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_colorbuffer);
  }
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorbuffer);
  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_drawableLayer];
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorbuffer);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_drawableWidth);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_drawableHeight);
}

- (void)buildProgram {
  const char *vertex =
      "#version 300 es\n"
      "layout(location = 0) in vec2 aPos;\n"
      "layout(location = 1) in vec2 aUV;\n"
      "out vec2 vUV;\n"
      "void main() {\n"
      "  gl_Position = vec4(aPos, 0.0, 1.0);\n"
      "  vUV = aUV;\n"
      "}\n";
  const char *fragment =
      "#version 300 es\n"
      "precision mediump float;\n"
      "in vec2 vUV;\n"
      "uniform sampler2D uTex;\n"
      "out vec4 fragColor;\n"
      "void main() {\n"
      "  fragColor = texture(uTex, vUV);\n"
      "}\n";
  GLuint vs = [self compile:GL_VERTEX_SHADER source:vertex];
  GLuint fs = [self compile:GL_FRAGMENT_SHADER source:fragment];
  if (vs == 0 || fs == 0) {
    return;
  }
  _program = glCreateProgram();
  glAttachShader(_program, vs);
  glAttachShader(_program, fs);
  glLinkProgram(_program);
  glDeleteShader(vs);
  glDeleteShader(fs);
  GLint ok = 0;
  glGetProgramiv(_program, GL_LINK_STATUS, &ok);
  if (ok == GL_FALSE) {
    glDeleteProgram(_program);
    _program = 0;
    return;
  }
  glUseProgram(_program);
  glUniform1i(glGetUniformLocation(_program, "uTex"), 0);
}

- (GLuint)compile:(GLenum)type source:(const char *)source {
  GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &source, NULL);
  glCompileShader(shader);
  GLint ok = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (ok == GL_FALSE) {
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

- (void)buildQuad {
  const GLfloat positions[] = {-1, -1, 1, -1, -1, 1, 1, 1};
  const GLfloat uvs[] = {0, 1, 1, 1, 0, 0, 1, 0};
  glGenVertexArrays(1, &_vao);
  glBindVertexArray(_vao);
  glGenBuffers(1, &_positionVbo);
  glBindBuffer(GL_ARRAY_BUFFER, _positionVbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
  glGenBuffers(1, &_uvVbo);
  glBindBuffer(GL_ARRAY_BUFFER, _uvVbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), uvs, GL_STATIC_DRAW);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, NULL);
  glBindVertexArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)deleteGL {
  if (_framebuffer != 0) {
    glDeleteFramebuffers(1, &_framebuffer);
    _framebuffer = 0;
  }
  if (_colorbuffer != 0) {
    glDeleteRenderbuffers(1, &_colorbuffer);
    _colorbuffer = 0;
  }
  if (_vao != 0) {
    glDeleteVertexArrays(1, &_vao);
    _vao = 0;
  }
  if (_positionVbo != 0) {
    glDeleteBuffers(1, &_positionVbo);
    _positionVbo = 0;
  }
  if (_uvVbo != 0) {
    glDeleteBuffers(1, &_uvVbo);
    _uvVbo = 0;
  }
  if (_program != 0) {
    glDeleteProgram(_program);
    _program = 0;
  }
  if (_textureCache != NULL) {
    CFRelease(_textureCache);
    _textureCache = NULL;
  }
}

- (void)emitStatus:(NSString *)status {
  void (^callback)(NSString *) = self.onStatus;
  if (callback == nil) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    callback(status);
  });
}

@end
