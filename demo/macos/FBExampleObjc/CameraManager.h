#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

// Delegate Protocol for Camera Data Output.
@protocol CameraManagerDelegate <NSObject>

@optional
- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

/**
 A Camera Manager that provides frames from camera
*/
@interface CameraManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
  // Capture components
  AVCaptureSession* captureSession;
  AVCaptureDevice* inputCamera;
  AVCaptureDeviceInput* videoInput;
  AVCaptureVideoDataOutput* videoOutput;

  // State
  BOOL isPaused;
  dispatch_queue_t processingQueue;
}

// MARK: - Properties

/// The capture session
@property(readonly, nonatomic) AVCaptureSession* captureSession;

/// Session preset (e.g., AVCaptureSessionPreset1920x1080)
@property(readwrite, nonatomic, copy) NSString* sessionPreset;

/// Frame rate (0 = default)
@property(readwrite, nonatomic) NSInteger frameRate;

/// Whether front-facing camera is available
@property(readonly, nonatomic, getter=isFrontCameraAvailable) BOOL frontCameraAvailable;

/// Current camera device
@property(readonly, nonatomic) AVCaptureDevice* currentCamera;

/// Delegate for camera data callbacks
@property(nonatomic, weak) id<CameraManagerDelegate> delegate;

// MARK: - Initialization

/// Get all available camera devices
+ (NSArray<AVCaptureDevice*>*)availableCameraDevices;

/// Initialize with specific camera device
- (instancetype)initWithCameraDevice:(AVCaptureDevice*)cameraDevice;

/// Initialize with device unique ID
- (instancetype)initWithDeviceUniqueID:(NSString*)deviceUniqueID;

/// Initialize with session preset and camera device
- (instancetype)initWithSessionPreset:(NSString*)sessionPreset
                         cameraDevice:(AVCaptureDevice*)cameraDevice;

// MARK: - Camera Control

/// Start camera capture
- (void)startCapture;

/// Stop camera capture
- (void)stopCapture;

/// Pause camera capture
- (void)pauseCapture;

/// Resume camera capture
- (void)resumeCapture;

/// Switch between front and rear cameras
- (void)switchCamera;

/// Get current camera position
- (AVCaptureDevicePosition)cameraPosition;

@end
