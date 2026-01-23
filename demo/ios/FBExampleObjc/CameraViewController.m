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

  // 先设置 UI，让页面快速显示
  [self setupUI];

  // 延迟初始化耗时操作（美颜引擎和相机），避免阻塞页面跳转
  // 使用 dispatch_async 将初始化移到下一个 runloop，让页面先显示出来
  dispatch_async(dispatch_get_main_queue(), ^{
    [self setupBeautyEngine];
    [self setupCameraManager];
  });
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // 隐藏导航栏
  [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // 显示导航栏
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)setupUI {
  // 预览视图：使用 OpenGL 渲染 RGBA 数据
  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.backgroundColor = [UIColor blackColor];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];

  // 美颜调节面板（包含顶部按钮栏）
  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];

  // 强制加载 view（确保 view 已经初始化）
  UIView *beautyPanelView = self.beautyPanelViewController.view;
  beautyPanelView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:beautyPanelView];
  [self.beautyPanelViewController didMoveToParentViewController:self];

  // 约束
  [NSLayoutConstraint activateConstraints:@[
    // 预览视图占满整个屏幕
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // 美颜面板占据整个屏幕（包含顶部按钮栏和底部面板）
    [beautyPanelView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [beautyPanelView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [beautyPanelView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [beautyPanelView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];

  // 如果有初始 Tab，延迟切换到指定 Tab
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

  // 1. 配置日志（可选）
  FBLogConfig *logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"ios_beauty_engine.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];

  // 2. 创建引擎实例（需替换为你的 AppId/AppKey）
  // 注意：引擎创建可能耗时，但必须在主线程执行（某些 SDK 要求）
  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];
  
   engineConfig.appId = @"";
   engineConfig.appKey = @"";
   
   // 验证 appId 和 appKey
   if (!engineConfig.appId || !engineConfig.appKey ||
       [engineConfig.appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0 ||
       [engineConfig.appKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
     NSLog(@"[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code.");
     return;
   }

  self.beautyEffectEngine = [FBBeautyEffectEngine createEngineWithConfig:engineConfig];

  // 3. 启用美颜类型（实际生效需配合具体参数值）
  if (self.beautyEffectEngine) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:YES];
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_VirtualBackground enabled:YES];
  }
}

- (void)setupCameraManager {
  // 相机权限检查
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

  if (status == AVAuthorizationStatusNotDetermined) {
    // 首次请求权限
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
    // 已授权，直接初始化相机
    [self initializeCamera];
  } else {
    // 未授权，显示提示
    [self showCameraPermissionAlert];
  }
}

- (void)initializeCamera {
  // 初始化相机管理器并开始采集
  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                       cameraDevice:nil];
  self.cameraManager.delegate = self;
  [self.cameraManager startCapture];
}

- (void)showCameraPermissionAlert {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"相机权限"
                                          message:@"请在设置中允许应用访问相机"
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *settingsAction = [UIAlertAction
      actionWithTitle:@"去设置"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction *_Nonnull action) {
                [[UIApplication sharedApplication]
                              openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                              options:@{}
                    completionHandler:nil];
              }];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];

  [alert addAction:settingsAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // 如果美颜引擎还未初始化，跳过处理
  if (!self.beautyEffectEngine) {
    return;
  }

  // 将相机帧包装为 FBImageFrame，再交给 BeautyEngine 处理
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
      // iOS 常见相机格式之一（BGRA）
      inputImage = [FBImageFrame createWithBGRA:data width:width height:height stride:stride];
      break;

    case kCVPixelFormatType_32RGBA:
      // RGBA 格式
      inputImage = [FBImageFrame createWithRGBA:data width:width height:height stride:stride];
      break;

    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  // NV12
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
      // NV12：从 Y/UV 平面构造输入
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

  // 通过引擎处理帧（视频模式）
  if (inputImage) {
    inputImage.type = FBFrameTypeVideo;
    FBImageFrame *outputFrame = [self.beautyEffectEngine processImage:inputImage];

    // 提取 RGBA 并渲染到 OpenGL 视图
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
  // 停止相机采集
  [self.cameraManager stopCapture];
}

#pragma mark - BeautyPanelDelegate - Parameter Changes

- (void)beautyPanelDidChangeParam:(NSString *)tab function:(NSString *)function value:(float)value {
  if (!self.beautyEffectEngine) {
    return;
  }

  @try {
    if ([tab isEqualToString:@"beauty"]) {
      // 基础美颜参数
      if ([function isEqualToString:@"white"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:value];
      } else if ([function isEqualToString:@"smooth"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:value];
      } else if ([function isEqualToString:@"rosiness"]) {
        [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:value];
      }
    } else if ([tab isEqualToString:@"reshape"]) {
      // 面部重塑参数
      FBReshapeParam reshapeParam = [self mapToReshapeParam:function];
      if (reshapeParam != -1) {
        [self.beautyEffectEngine setReshapeParam:reshapeParam floatValue:value];
      }
    } else if ([tab isEqualToString:@"makeup"]) {
      // 美妆参数
      FBMakeupParam makeupParam = [self mapToMakeupParam:function];
      if (makeupParam != -1) {
        [self.beautyEffectEngine setMakeupParam:makeupParam floatValue:value];
      }
    } else if ([tab isEqualToString:@"virtual_bg"]) {
      // 虚拟背景：模糊、预置、图片、关闭
      FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
      if ([function isEqualToString:@"none"]) {
        // 关闭虚拟背景
        options.mode = FBBackgroundModeNone;
        [self.beautyEffectEngine setVirtualBackground:options];
      } else if ([function isEqualToString:@"blur"]) {
        // 模糊背景
        options.mode = FBBackgroundModeBlur;
        [self.beautyEffectEngine setVirtualBackground:options];
      } else if ([function isEqualToString:@"preset"]) {
        // 预置背景：使用资源图片
        UIImage *presetImage = [UIImage imageNamed:@"back_mobile"];
        if (presetImage) {
          // 使用新的 createWithUIImage 方法
          FBImageFrame *imageFrame = [FBImageFrame createWithUIImage:presetImage];
          if (imageFrame) {
            options.mode = FBBackgroundModeImage;
            options.backgroundImage = imageFrame;
            [self.beautyEffectEngine setVirtualBackground:options];
          }
        } else {
          // 如果 imageNamed 失败，尝试从文件路径加载
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
        // 背景图片切换（从相册选择）
        // 注意：当用户点击 "image" 按钮时，会触发 beautyPanelDidRequestImageSelection:function:
        // 方法 这里不需要处理，因为图片选择是异步的，会在 handleSelectedImage: 中处理
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
  return -1;  // 无效参数
}

- (FBMakeupParam)mapToMakeupParam:(NSString *)function {
  if ([function isEqualToString:@"lipstick"]) {
    return FBMakeupParam_Lipstick;
  } else if ([function isEqualToString:@"blush"]) {
    return FBMakeupParam_Blush;
  }
  return -1;  // 无效参数
}

- (void)beautyPanelDidReset {
  if (!self.beautyEffectEngine) {
    return;
  }

  @try {
    // 重置基础美颜参数
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:0.0f];
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:0.0f];
    [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:0.0f];

    // 重置面部重塑参数
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

    // 重置美妆参数
    [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:0.0f];
    [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:0.0f];

    // 重置虚拟背景参数
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
      // 重置虚拟背景
      FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
      options.mode = FBBackgroundModeNone;
      [self.beautyEffectEngine setVirtualBackground:options];
    }
  } @catch (NSException *exception) {
    NSLog(@"Error resetting beauty tab: %@", exception);
  }
}

- (void)beautyPanelDidRequestImageSelection:(NSString *)tab function:(NSString *)function {
  // 检查相册权限
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

  if (status == PHAuthorizationStatusNotDetermined) {
    // 请求权限
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
    // 已授权，直接打开图片选择器
    [self presentImagePicker];
  } else {
    // 未授权，显示提示
    [self showPhotoLibraryPermissionAlert];
  }
}

#pragma mark - Image Selection

- (void)presentImagePicker {
  // iOS 14+ 使用 PHPickerViewController（推荐）
  if (@available(iOS 14.0, *)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter imagesFilter];
    configuration.selectionLimit = 1;  // 只选择一张图片

    PHPickerViewController *picker =
        [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
  } else {
    // iOS 13 及以下使用 UIImagePickerController
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
      [UIAlertController alertControllerWithTitle:@"相册权限"
                                          message:@"请在设置中允许应用访问相册"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *settingsAction = [UIAlertAction
      actionWithTitle:@"去设置"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction *_Nonnull action) {
                [[UIApplication sharedApplication]
                              openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                              options:@{}
                    completionHandler:nil];
              }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
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
    // 使用 createWithUIImage 方法创建 ImageFrame
    FBImageFrame *imageFrame = [FBImageFrame createWithUIImage:image];
    if (!imageFrame) {
      NSLog(@"Failed to create ImageFrame from selected image");
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showImageProcessingErrorAlert];
      });
      return;
    }

    // 设置虚拟背景
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
      [UIAlertController alertControllerWithTitle:@"处理失败"
                                          message:@"无法将选中的图片设置为虚拟背景，请重试"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
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

  // 加载图片
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

  // 获取选中的图片
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
  // 如果有导航控制器，使用 pop 返回
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    // 如果没有导航控制器（可能是通过 present 方式打开的），使用 dismiss
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)beautyPanelDidTapGalleryButton {
  // TODO: 打开相册选择图片
  // 可以调用 beautyPanelDidRequestImageSelection:function: 或实现自己的相册选择逻辑
}

- (void)beautyPanelDidTapFlipCameraButton {
  // 切换前后摄像头
  if (self.cameraManager) {
    [self.cameraManager switchCamera];
  }
}

- (void)beautyPanelDidTapMoreButton {
  // TODO: 显示更多选项
}

@end
