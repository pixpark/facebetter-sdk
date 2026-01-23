#import "CameraManager.h"

#pragma mark -
#pragma mark Private methods and instance variables

@interface CameraManager () {
  NSInteger frameRate;
}

@end

@implementation CameraManager

@synthesize sessionPreset;
@synthesize captureSession;
@synthesize currentCamera = inputCamera;
@synthesize delegate;

#pragma mark -
#pragma mark Initialization and teardown

+ (NSArray<AVCaptureDevice*>*)availableCameraDevices {
  return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
}

- (instancetype)init {
  return [self initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:nil];
}

- (instancetype)initWithCameraDevice:(AVCaptureDevice*)cameraDevice {
  return [self initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:cameraDevice];
}

- (instancetype)initWithDeviceUniqueID:(NSString*)deviceUniqueID {
  AVCaptureDevice* device = [AVCaptureDevice deviceWithUniqueID:deviceUniqueID];
  return [self initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:device];
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

  // Set camera device
  if (cameraDevice == nil) {
    inputCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
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
  [videoOutput setAlwaysDiscardsLateVideoFrames:NO];
  [videoOutput
      setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];

  [videoOutput setSampleBufferDelegate:self queue:processingQueue];
  if ([captureSession canAddOutput:videoOutput]) {
    [captureSession addOutput:videoOutput];
  } else {
    NSLog(@"Could not add video output");
    return nil;
  }

  // Set session preset
  self.sessionPreset = sessionPreset;
  [captureSession setSessionPreset:sessionPreset];
  [captureSession commitConfiguration];

  return self;
}

- (void)dealloc {
  [self stopCapture];
  [videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];

  if (captureSession) {
    [captureSession removeInput:videoInput];
    [captureSession removeOutput:videoOutput];
  }
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
  sessionPreset = newSessionPreset;
  [captureSession setSessionPreset:sessionPreset];
  [captureSession commitConfiguration];
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

- (NSInteger)frameRate {
  return frameRate;
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput*)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection*)connection {
  // Camera Data Output Hook.
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
