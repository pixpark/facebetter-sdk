//
//  CameraViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//  Renamed from ViewController to CameraViewController
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Facebetter/FBBeautyEffectEngine.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import "GLRGBARenderView.h"

/**
 * CameraViewController 负责：
 * 1. 初始化并管理相机采集
 * 2. 通过 BeautyEngine 处理帧，取得 RGBA 数据
 * 3. 使用自定义 OpenGL 视图进行渲染
 */
@interface CameraViewController () <UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate,
                                    PHPickerViewControllerDelegate>

@property(nonatomic, strong) FBBeautyEffectEngine *beautyEffectEngine;
@property(nonatomic, strong) CameraManager *cameraManager;

@property(nonatomic, strong) GLRGBARenderView *previewView;
@property(nonatomic, strong) BeautyPanelViewController *beautyPanelViewController;
@property(nonatomic, strong) NSString *initialTab;
@property(nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation CameraViewController

- (instancetype)init {
  return [self initWithInitialTab:nil];
}

- (instancetype)initWithInitialTab:(NSString *)initialTab {
  self = [super init];
  if (self) {
    _initialTab = initialTab;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Set up UI first to quickly display the page
  [self setupUI];

  // Delay initialization of time-consuming operations (beauty engine and camera) to avoid blocking page transition
  // Use dispatch_async to move initialization to next runloop, allowing page to display first
  dispatch_async(dispatch_get_main_queue(), ^{
    [self setupBeautyEngine];
    [self setupCameraManager];
  });
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // Hide navigation bar
  [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // Show navigation bar
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)setupUI {
  // Preview view: uses OpenGL to render RGBA data
  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.backgroundColor = [UIColor blackColor];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];

  // Beauty adjustment panel (includes top button bar)
  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];

  // Force load view (ensure view is already initialized)
  UIView *beautyPanelView = self.beautyPanelViewController.view;
  beautyPanelView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:beautyPanelView];
  [self.beautyPanelViewController didMoveToParentViewController:self];

  // Constraints
  [NSLayoutConstraint activateConstraints:@[
    // Preview view fills entire screen
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // Beauty panel occupies entire screen (includes top button bar and bottom panel)
    [beautyPanelView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [beautyPanelView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [beautyPanelView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [beautyPanelView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];

  // If there's an initial Tab, delay switching to specified Tab
  if (self.initialTab && self.initialTab.length > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.beautyPanelViewController showPanel];
      [self.beautyPanelViewController switchToTab:self.initialTab];
    });
  }
}

#pragma mark - Setup Methods

- (void)setupBeautyEngine {
  /*
   * Facebetter Beauty Engine 使用流程：
   * 1. 配置日志（可选）
   * 2. 使用 AppId/AppKey 创建引擎实例
   * 3. 启用需要的美颜类型（Basic/Reshape/Makeup/...）
   * 4. 后续通过 setXXXParam 接口实时调参（见 beautyPanelDidChangeParam）
   * 5. 不使用 setRenderView，处理结果通过 convert 提取后自行渲染
   */
 
  // 1. Configure logging (optional)
  FBLogConfig *logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"ios_beauty_engine.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];

  // 2. Create engine instance (replace with your AppId/AppKey)
  // Note: Engine creation may be time-consuming, but must be executed on main thread (some SDK requirements)
  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];
  
   engineConfig.appId = @"dddb24155fd045ab9c2d8aad83ad3a4a";
   engineConfig.appKey = @"-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";
   
   // Validate appId and appKey
   if (!engineConfig.appId || !engineConfig.appKey ||
       [engineConfig.appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0 ||
       [engineConfig.appKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
     NSLog(@"[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code.");
     return;
   }

  self.beautyEffectEngine = [FBBeautyEffectEngine createEngineWithConfig:engineConfig];

  // 3. Enable beauty types (actual effect requires specific parameter values)
  if (self.beautyEffectEngine) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_VirtualBackground enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Filter enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Sticker enabled:YES];

    // 3.5 Register filters and stickers
    [self registerFiltersAndStickers];
  }
}

- (void)setupCameraManager {
  // Camera permission check
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

  if (status == AVAuthorizationStatusNotDetermined) {
    // First request permission
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 if (granted) {
                                   [self initializeCamera];
                                 } else {
                                   [self showCameraPermissionAlert];
                                 }
                               });
                             }];
  } else if (status == AVAuthorizationStatusAuthorized) {
    // Already authorized, directly initialize camera
    [self initializeCamera];
  } else {
    // Not authorized, show alert
    [self showCameraPermissionAlert];
  }
}

- (void)initializeCamera {
  // Initialize camera manager and start capture
  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                       cameraDevice:nil];
  self.cameraManager.delegate = self;
  [self.cameraManager startCapture];
}

- (void)showCameraPermissionAlert {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"Camera Permission"
                                          message:@"Please allow camera access in Settings"
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *settingsAction = [UIAlertAction
      actionWithTitle:@"Go to Settings"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction *_Nonnull action) {
                [[UIApplication sharedApplication]
                              openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                              options:@{}
                    completionHandler:nil];
              }];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];

  [alert addAction:settingsAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // If beauty engine hasn't been initialized yet, skip processing
  if (!self.beautyEffectEngine) {
    return;
  }

  // Wrap camera frame as FBImageFrame, then hand to BeautyEngine for processing
  CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (!buffer) {
    return;
  }

  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);

  int width = (int32_t)CVPixelBufferGetWidth(buffer);
  int height = (int32_t)CVPixelBufferGetHeight(buffer);
  int stride = (int32_t)CVPixelBufferGetBytesPerRow(buffer);
  void *data = CVPixelBufferGetBaseAddress(buffer);

  FBImageFrame *inputImage = nil;
  OSType pixelFormat = CVPixelBufferGetPixelFormatType(buffer);

  switch (pixelFormat) {
    case kCVPixelFormatType_32BGRA:
      // One of iOS common camera formats (BGRA)
      inputImage = [FBImageFrame createWithBGRA:data width:width height:height stride:stride];
      break;

    case kCVPixelFormatType_32RGBA:
      // RGBA format
      inputImage = [FBImageFrame createWithRGBA:data width:width height:height stride:stride];
      break;

    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  // NV12
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
      // NV12: construct input from Y/UV planes
      const uint8_t *yPlane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
      size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);
      const uint8_t *uvPlane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 1);
      size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1);

      inputImage = [FBImageFrame createWithNV12:width
                                         height:height
                                          dataY:yPlane
                                        strideY:(int32_t)yStride
                                         dataUV:uvPlane
                                       strideUV:(int32_t)uvStride];
      break;
    }

    default:
      break;
  }

  // Process frame through engine (video mode)
  if (inputImage) {
    inputImage.type = FBFrameTypeVideo;
    FBImageFrame *outputFrame = [self.beautyEffectEngine processImage:inputImage];

    // Extract RGBA and render to OpenGL view
    if (outputFrame) {
      FBImageFrame *rgbaFrame = [outputFrame convert:FBImageFormatRGBA];
      if (rgbaFrame) {
        [self.previewView renderFrame:rgbaFrame];
      }
    }
  }

  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}

- (void)dealloc {
  // Stop camera capture
  [self.cameraManager stopCapture];
}

#pragma mark - BeautyPanelDelegate - Parameter Changes

- (void)beautyPanelDidChangeParam:(NSString *)tab function:(NSString *)function value:(float)value {
  if (!self.beautyEffectEngine) {
    return;
  }

  @try {
    if ([tab isEqualToString:@"beauty"]) {
      // Basic beauty parameters
      if ([function isEqualToString:@"white"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:value];
      } else if ([function isEqualToString:@"smooth"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:value];
      } else if ([function isEqualToString:@"rosiness"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:value];
      }
    } else if ([tab isEqualToString:@"reshape"]) {
      // Face reshape parameters
      FBReshapeParam reshapeParam = [self mapToReshapeParam:function];
      if (reshapeParam != -1) {
        [self.beautyEffectEngine setReshapeParam:reshapeParam floatValue:value];
      }
    } else if ([tab isEqualToString:@"makeup"]) {
      // Makeup parameters
      FBMakeupParam makeupParam = [self mapToMakeupParam:function];
      if (makeupParam != -1) {
        [self.beautyEffectEngine setMakeupParam:makeupParam floatValue:value];
      }
    } else if ([tab isEqualToString:@"filter"]) {
      // Filter logic: function name is the filter ID
      // If function is "off", it means clear filter
      if ([function isEqualToString:@"off"]) {
        [self.beautyEffectEngine setFilter:@""];
      } else {
        // Set filter
        [self.beautyEffectEngine setFilter:function];
      }
    } else if ([tab isEqualToString:@"sticker"]) {
      // Sticker logic: function name is the sticker ID
      // If function is "off", it means clear sticker
      if ([function isEqualToString:@"off"]) {
        [self.beautyEffectEngine setSticker:@""];
      } else {
        // Set sticker
        [self.beautyEffectEngine setSticker:function];
      }
    } else if ([tab isEqualToString:@"virtual_bg"]) {
      // Virtual background: blur, preset, image, off
      FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
      if ([function isEqualToString:@"none"]) {
        // Turn off virtual background
        options.mode = FBBackgroundModeNone;
        [self.beautyEffectEngine setVirtualBackground:options];
      } else if ([function isEqualToString:@"blur"]) {
        // Blur background
        options.mode = FBBackgroundModeBlur;
        [self.beautyEffectEngine setVirtualBackground:options];
      } else if ([function isEqualToString:@"preset"]) {
        // Preset background: use resource image
        UIImage *presetImage = [UIImage imageNamed:@"back_mobile"];
        if (presetImage) {
          // Use new createWithUIImage method
          FBImageFrame *imageFrame = [FBImageFrame createWithUIImage:presetImage];
          if (imageFrame) {
            options.mode = FBBackgroundModeImage;
            options.backgroundImage = imageFrame;
            [self.beautyEffectEngine setVirtualBackground:options];
          }
        } else {
          // If imageNamed fails, try loading from file path
          NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"back_mobile"
                                                                ofType:@"jpg"];
          if (!imagePath) {
            imagePath = [[NSBundle mainBundle] pathForResource:@"back_mobile" ofType:@"png"];
          }
          if (imagePath) {
            FBImageFrame *imageFrame = [FBImageFrame createWithFile:imagePath];
            if (imageFrame) {
              options.mode = FBBackgroundModeImage;
              options.backgroundImage = imageFrame;
              [self.beautyEffectEngine setVirtualBackground:options];
            }
          }
        }
      } else if ([function hasPrefix:@"image"]) {
        // Background image switch (selected from album)
        // Note: When user clicks "image" button, it triggers beautyPanelDidRequestImageSelection:function:
        // Method doesn't need handling here, as image selection is asynchronous, will be handled in handleSelectedImage:
      }
    }
  } @catch (NSException *exception) {
    NSLog(@"Error applying beauty param: %@", exception);
  }
}

#pragma mark - BeautyPanelDelegate - Helper Methods

- (FBReshapeParam)mapToReshapeParam:(NSString *)function {
  if ([function isEqualToString:@"thin_face"]) {
    return FBReshapeParam_FaceThin;
  } else if ([function isEqualToString:@"v_face"]) {
    return FBReshapeParam_FaceVShape;
  } else if ([function isEqualToString:@"narrow_face"]) {
    return FBReshapeParam_FaceNarrow;
  } else if ([function isEqualToString:@"short_face"]) {
    return FBReshapeParam_FaceShort;
  } else if ([function isEqualToString:@"cheekbone"]) {
    return FBReshapeParam_Cheekbone;
  } else if ([function isEqualToString:@"jawbone"]) {
    return FBReshapeParam_Jawbone;
  } else if ([function isEqualToString:@"chin"]) {
    return FBReshapeParam_Chin;
  } else if ([function isEqualToString:@"nose_slim"]) {
    return FBReshapeParam_NoseSlim;
  } else if ([function isEqualToString:@"big_eye"]) {
    return FBReshapeParam_EyeSize;
  } else if ([function isEqualToString:@"eye_distance"]) {
    return FBReshapeParam_EyeDistance;
  }
  return -1;  // Invalid parameter
}

- (FBMakeupParam)mapToMakeupParam:(NSString *)function {
  if ([function isEqualToString:@"lipstick"]) {
    return FBMakeupParam_Lipstick;
  } else if ([function isEqualToString:@"blush"]) {
    return FBMakeupParam_Blush;
  }
  return -1;  // Invalid parameter
}

- (void)beautyPanelDidReset {
  if (!self.beautyEffectEngine) {
    return;
  }

  @try {
    // Reset basic beauty parameters
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:0.0f];
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:0.0f];
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:0.0f];

    // Reset face reshape parameters
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceThin floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceVShape floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceNarrow floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceShort floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Cheekbone floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Jawbone floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Chin floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_NoseSlim floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeSize floatValue:0.0f];
    [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeDistance floatValue:0.0f];

    // Reset makeup parameters
    [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:0.0f];
    [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:0.0f];

    // Reset virtual background parameters
    FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
    options.mode = FBBackgroundModeNone;
    [self.beautyEffectEngine setVirtualBackground:options];
  } @catch (NSException *exception) {
    NSLog(@"Error resetting beauty params: %@", exception);
  }
}

- (void)beautyPanelDidResetTab:(NSString *)tab {
  if (!self.beautyEffectEngine) {
    return;
  }

  @try {
    if ([tab isEqualToString:@"beauty"]) {
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:0.0f];
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:0.0f];
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:0.0f];
    } else if ([tab isEqualToString:@"reshape"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceThin floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceVShape floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceNarrow floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceShort floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Cheekbone floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Jawbone floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Chin floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_NoseSlim floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeSize floatValue:0.0f];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeDistance floatValue:0.0f];
    } else if ([tab isEqualToString:@"makeup"]) {
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:0.0f];
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:0.0f];
    } else if ([tab isEqualToString:@"virtual_bg"]) {
      // Reset virtual background
      FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
      options.mode = FBBackgroundModeNone;
      [self.beautyEffectEngine setVirtualBackground:options];
    }
  } @catch (NSException *exception) {
    NSLog(@"Error resetting beauty tab: %@", exception);
  }
}

- (void)beautyPanelDidRequestImageSelection:(NSString *)tab function:(NSString *)function {
  // Check album permission
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

  if (status == PHAuthorizationStatusNotDetermined) {
    // Request permission
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (authorizationStatus == PHAuthorizationStatusAuthorized ||
            authorizationStatus == PHAuthorizationStatusLimited) {
          [self presentImagePicker];
        } else {
          [self showPhotoLibraryPermissionAlert];
        }
      });
    }];
  } else if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
    // Already authorized, directly open image picker
    [self presentImagePicker];
  } else {
    // Not authorized, show alert
    [self showPhotoLibraryPermissionAlert];
  }
}

#pragma mark - Image Selection

- (void)presentImagePicker {
  // iOS 14+ use PHPickerViewController (recommended)
  if (@available(iOS 14.0, *)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter imagesFilter];
    configuration.selectionLimit = 1;  // Select only one image

    PHPickerViewController *picker =
        [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
  } else {
    // iOS 13 and below use UIImagePickerController
    if (!self.imagePickerController) {
      self.imagePickerController = [[UIImagePickerController alloc] init];
      self.imagePickerController.delegate = self;
      self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      self.imagePickerController.mediaTypes = @[ @"public.image" ];
    }
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
  }
}

- (void)showPhotoLibraryPermissionAlert {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"Photo Library Permission"
                                          message:@"Please allow photo library access in Settings"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *settingsAction = [UIAlertAction
      actionWithTitle:@"Go to Settings"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction *_Nonnull action) {
                [[UIApplication sharedApplication]
                              openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                              options:@{}
                    completionHandler:nil];
              }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [alert addAction:settingsAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleSelectedImage:(UIImage *)image {
  if (!image || !self.beautyEffectEngine) {
    NSLog(@"Invalid image or beauty engine not initialized");
    return;
  }

  @try {
    // Use createWithUIImage method to create ImageFrame
    FBImageFrame *imageFrame = [FBImageFrame createWithUIImage:image];
    if (!imageFrame) {
      NSLog(@"Failed to create ImageFrame from selected image");
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showImageProcessingErrorAlert];
      });
      return;
    }

    // Set virtual background
    FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
    options.mode = FBBackgroundModeImage;
    options.backgroundImage = imageFrame;

    int result = [self.beautyEffectEngine setVirtualBackground:options];
    if (result == 0) {
      NSLog(@"Virtual background set successfully from selected image (size: %.0fx%.0f)",
            image.size.width,
            image.size.height);
    } else {
      NSLog(@"Failed to set virtual background, error code: %d", result);
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showImageProcessingErrorAlert];
      });
    }
  } @catch (NSException *exception) {
    NSLog(@"Error processing selected image: %@", exception);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self showImageProcessingErrorAlert];
    });
  }
}

- (void)showImageProcessingErrorAlert {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"Processing Failed"
                                          message:@"Failed to set selected image as virtual background, please try again"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
  [alert addAction:okAction];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate (iOS 14+)

- (void)picker:(PHPickerViewController *)picker
    didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
  [picker dismissViewControllerAnimated:YES completion:nil];

  if (results.count == 0) {
    return;
  }

  PHPickerResult *result = results.firstObject;

  // Load image
  if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
    [result.itemProvider loadObjectOfClass:[UIImage class]
                         completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object,
                                             NSError *_Nullable error) {
                           if (error) {
                             NSLog(@"Error loading image: %@", error);
                             return;
                           }

                           if ([object isKindOfClass:[UIImage class]]) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [self handleSelectedImage:(UIImage *)object];
                             });
                           }
                         }];
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
  [picker dismissViewControllerAnimated:YES completion:nil];

  // Get selected image
  UIImage *image = info[UIImagePickerControllerOriginalImage];
  if (image) {
    [self handleSelectedImage:image];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BeautyPanelDelegate - Top Bar Actions

- (void)beautyPanelDidTapCloseButton {
  // If there's a navigation controller, use pop to return
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    // If there's no navigation controller (might have been opened via present), use dismiss
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)beautyPanelDidTapGalleryButton {
  // TODO: Open album to select image
  // Can call beautyPanelDidRequestImageSelection:function: or implement own album selection logic
}

- (void)beautyPanelDidTapFlipCameraButton {
  // Switch front/back camera
  if (self.cameraManager) {
    [self.cameraManager switchCamera];
  }
}

- (void)beautyPanelDidTapMoreButton {
  // TODO: Show more options
}

- (void)registerFiltersAndStickers {
  if (!self.beautyEffectEngine)
    return;

  // 1. Register filters
  NSString *filtersPath =
      [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"assets/filters/portrait"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *filterDirs = [fileManager contentsOfDirectoryAtPath:filtersPath error:&error];
  if (!error) {
    for (NSString *dirName in filterDirs) {
      // Skip hidden files or files starting with .
      if ([dirName hasPrefix:@"."]) continue;
      
      NSString *fbdPath = [filtersPath stringByAppendingFormat:@"/%@/%@.fbd", dirName, dirName];
      if ([fileManager fileExistsAtPath:fbdPath]) {
        [self.beautyEffectEngine registerFilter:dirName fbdFilePath:fbdPath];
      }
    }
  }

  // 2. Register sticker (rabbit)
  NSString *stickerPath = [[[NSBundle mainBundle] bundlePath]
      stringByAppendingPathComponent:@"assets/stickers/face/rabbit/rabbit.fbd"];
  if ([fileManager fileExistsAtPath:stickerPath]) {
    [self.beautyEffectEngine registerSticker:@"rabbit" fbdFilePath:stickerPath];
  }
}

@end
