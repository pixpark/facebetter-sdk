#import "CameraManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#pragma mark -
#pragma mark Private methods and instance variables

@interface CameraManager () {
  NSInteger frameRate;
  NSString* _sessionPreset;  // 添加sessionPreset的实例变量
}

@end

@implementation CameraManager

#pragma mark -
#pragma mark Initialization and teardown

+ (NSArray<AVCaptureDevice*>*)availableCameraDevices {
  return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
}

- (instancetype)init {
  return [self initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:nil];
}

- (instancetype)initWithCameraDevice:(AVCaptureDevice*)cameraDevice {
  return [self initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:cameraDevice];
}

- (instancetype)initWithDeviceUniqueID:(NSString*)deviceUniqueID {
  AVCaptureDevice* device = [AVCaptureDevice deviceWithUniqueID:deviceUniqueID];
  return [self initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:device];
}

- (instancetype)initWithSessionPreset:(NSString*)sessionPreset
                         cameraDevice:(AVCaptureDevice*)cameraDevice {
  if (!(self = [super init])) {
    return nil;
  }

  // Initialize processing queue
  processingQueue = dispatch_queue_create("com.cameramanager.processing", NULL);

  // Initialize state
  frameRate = 0;
  isPaused = NO;

  // 监听设备方向变化
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceOrientationDidChange:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];

  // Set camera device - 默认使用前置摄像头
  if (cameraDevice == nil) {
    // 优先选择前置摄像头
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    inputCamera = nil;
    for (AVCaptureDevice* device in devices) {
      if ([device position] == AVCaptureDevicePositionFront) {
        inputCamera = device;
        break;
      }
    }
    // 如果没有前置摄像头，则使用默认摄像头
    if (inputCamera == nil) {
      inputCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
  } else {
    inputCamera = cameraDevice;
  }

  if (!inputCamera) {
    return nil;
  }

  // Create capture session
  captureSession = [[AVCaptureSession alloc] init];
  [captureSession beginConfiguration];

  // Add video input
  NSError* error = nil;
  videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:&error];
  if ([captureSession canAddInput:videoInput]) {
    [captureSession addInput:videoInput];
  }

  // Add video output
  videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  // 丢弃迟到帧，避免处理旧帧造成可见延迟
  [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [videoOutput
      setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];

  [videoOutput setSampleBufferDelegate:self queue:processingQueue];
  if ([captureSession canAddOutput:videoOutput]) {
    [captureSession addOutput:videoOutput];

    // 设置视频方向为竖屏
    AVCaptureConnection* connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoOrientationSupported]) {
      [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }

    // 设置视频镜像（前置摄像头需要镜像）
    if ([connection isVideoMirroringSupported]) {
      BOOL shouldMirror = (inputCamera.position == AVCaptureDevicePositionFront);
      [connection setVideoMirrored:shouldMirror];
    }
  } else {
    NSLog(@"Could not add video output");
    return nil;
  }

  // Set session preset
  self.sessionPreset = sessionPreset;
  [captureSession setSessionPreset:sessionPreset];

  // 设置 30fps 采集（使用连接层最小帧间隔）
  [self setFrameRate:30];
  [captureSession commitConfiguration];

  return self;
}

- (void)dealloc {
  // 移除通知监听
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self stopCapture];
  [videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
}

#pragma mark -
#pragma mark Camera Control

- (void)startCapture {
  if (![captureSession isRunning]) {
    [captureSession startRunning];
  }
}

- (void)stopCapture {
  if ([captureSession isRunning]) {
    [captureSession stopRunning];
  }
}

- (void)pauseCapture {
  isPaused = YES;
}

- (void)resumeCapture {
  isPaused = NO;
}

- (void)switchCamera {
  if (!self.frontCameraAvailable) {
    return;
  }

  AVCaptureDevicePosition currentPosition = [[videoInput device] position];
  AVCaptureDevicePosition newPosition = (currentPosition == AVCaptureDevicePositionBack) ?
      AVCaptureDevicePositionFront :
      AVCaptureDevicePositionBack;

  AVCaptureDevice* newCamera = nil;
  NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice* device in devices) {
    if ([device position] == newPosition) {
      newCamera = device;
      break;
    }
  }

  if (newCamera) {
    NSError* error;
    AVCaptureDeviceInput* newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera
                                                                                 error:&error];

    if (newVideoInput) {
      [captureSession beginConfiguration];
      [captureSession removeInput:videoInput];

      if ([captureSession canAddInput:newVideoInput]) {
        [captureSession addInput:newVideoInput];
        videoInput = newVideoInput;
        inputCamera = newCamera;

        // 重新设置视频方向和镜像
        AVCaptureConnection* connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoOrientationSupported]) {
          [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }

        // 前置摄像头需要镜像，后置摄像头不需要
        if ([connection isVideoMirroringSupported]) {
          BOOL shouldMirror = (newCamera.position == AVCaptureDevicePositionFront);
          [connection setVideoMirrored:shouldMirror];
        }
      } else {
        [captureSession addInput:videoInput];
      }

      [captureSession commitConfiguration];
    }
  }
}

- (AVCaptureDevicePosition)cameraPosition {
  return [[videoInput device] position];
}

- (BOOL)isFrontCameraAvailable {
  NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice* device in devices) {
    if ([device position] == AVCaptureDevicePositionFront) {
      return YES;
    }
  }
  return NO;
}

- (void)setSessionPreset:(NSString*)newSessionPreset {
  [captureSession beginConfiguration];
  _sessionPreset = newSessionPreset;  // 直接设置backing变量
  [captureSession setSessionPreset:_sessionPreset];
  [captureSession commitConfiguration];
}

- (NSString*)sessionPreset {
  return _sessionPreset;
}

- (void)setFrameRate:(NSInteger)newFrameRate {
  frameRate = newFrameRate;

  for (AVCaptureConnection* connection in videoOutput.connections) {
    if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)]) {
      if (frameRate > 0) {
        connection.videoMinFrameDuration = CMTimeMake(1, (int32_t)frameRate);
      } else {
        connection.videoMinFrameDuration = kCMTimeInvalid;
      }
    }
  }
}

- (void)updateVideoOrientation:(AVCaptureVideoOrientation)orientation {
  for (AVCaptureConnection* connection in videoOutput.connections) {
    if ([connection isVideoOrientationSupported]) {
      [connection setVideoOrientation:orientation];
    }
  }
}

- (void)updateVideoMirroring:(BOOL)mirrored {
  for (AVCaptureConnection* connection in videoOutput.connections) {
    if ([connection isVideoMirroringSupported]) {
      [connection setVideoMirrored:mirrored];
    }
  }
}

- (NSInteger)frameRate {
  return frameRate;
}

- (AVCaptureSession*)captureSession {
  return captureSession;
}

- (AVCaptureDevice*)currentCamera {
  return inputCamera;
}

#pragma mark - Device Orientation

- (void)deviceOrientationDidChange:(NSNotification*)notification {
  UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
  AVCaptureVideoOrientation videoOrientation;

  switch (orientation) {
    case UIDeviceOrientationPortrait:
      videoOrientation = AVCaptureVideoOrientationPortrait;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
      break;
    case UIDeviceOrientationLandscapeLeft:
      videoOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    case UIDeviceOrientationLandscapeRight:
      videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    default:
      videoOrientation = AVCaptureVideoOrientationPortrait;
      break;
  }

  [self updateVideoOrientation:videoOrientation];
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput*)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection*)connection {
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(cameraManager:didOutputSampleBuffer:)]) {
    @autoreleasepool {
      [self.delegate cameraManager:self didOutputSampleBuffer:sampleBuffer];
    }
  }
}

#pragma mark -
#pragma mark Accessors

@end
