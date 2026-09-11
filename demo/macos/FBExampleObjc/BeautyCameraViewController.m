//
//  BeautyCameraViewController.m
//  FBExampleObjc
//

#import "BeautyCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Facebetter/FBBeautyEffectEngine.h>
#import <Facebetter/FBImageFrame.h>
#import "BeautyPanelViewController.h"
#import "CameraManager.h"
#import "GLRGBARenderView.h"

@interface BeautyCameraViewController () <CameraManagerDelegate, BeautyPanelDelegate>
@property(nonatomic, strong) FBBeautyEffectEngine *beautyEffectEngine;
@property(nonatomic, strong) CameraManager *cameraManager;
@property(nonatomic, strong) BeautyPanelViewController *beautyPanelViewController;
@property(nonatomic, strong) GLRGBARenderView *previewView;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic, strong) NSLayoutConstraint *panelHeightConstraint;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *stickerPaths;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *filterPaths;
@end

@implementation BeautyCameraViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  FBLogConfig *logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"facebetter_sdk.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];

  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];
  engineConfig.appId = @"968900281898d15dca9054978174d9c4";
  engineConfig.appKey = @"ajVrxcstNxTO5z2Yq8WKrPK-33x3TJWTFxpPDMkmzfE";

  if (!engineConfig.appId || !engineConfig.appKey ||
      [engineConfig.appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0 ||
      [engineConfig.appKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
    NSLog(@"[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code.");
    return;
  }

  self.beautyEffectEngine = [FBBeautyEffectEngine createEngineWithConfig:engineConfig];

  [self scanFilterAndStickerPaths];

  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];
  [self.view addSubview:self.beautyPanelViewController.view];

  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];

  self.panelHeightConstraint =
      [self.beautyPanelViewController.view.heightAnchor constraintEqualToConstant:140];

  [NSLayoutConstraint activateConstraints:@[
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor
        constraintEqualToAnchor:self.beautyPanelViewController.view.topAnchor],
    [self.beautyPanelViewController.view.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.beautyPanelViewController.view.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.beautyPanelViewController.view.bottomAnchor
        constraintEqualToAnchor:self.view.bottomAnchor],
    self.panelHeightConstraint
  ]];

  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                       cameraDevice:nil];
  self.cameraManager.delegate = self;
  [self.cameraManager startCapture];

  self.eventMonitor = [NSEvent
      addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                   handler:^NSEvent *(NSEvent *event) {
                                     if (event.modifierFlags & NSEventModifierFlagCommand &&
                                         event.keyCode == 11) {
                                       [self.beautyPanelViewController togglePanelVisibility];
                                       return nil;
                                     }
                                     return event;
                                   }];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(panelVisibilityChanged:)
                                               name:@"BeautyPanelVisibilityChanged"
                                             object:nil];
}

- (void)panelVisibilityChanged:(NSNotification *)notification {
  BOOL visible = [notification.object boolValue];
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        self.panelHeightConstraint.animator.constant = visible ? 140 : 0;
      }
      completionHandler:nil];
}

- (void)beautyPanelSliderVisibilityDidChange:(BOOL)visible {
  CGFloat height = visible ? 180 : 140;
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        self.panelHeightConstraint.animator.constant = height;
      }
      completionHandler:nil];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (!buffer) {
    return;
  }

  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
  int width = (int32_t)CVPixelBufferGetWidth(buffer);
  int height = (int32_t)CVPixelBufferGetHeight(buffer);
  int stride = (int32_t)CVPixelBufferGetBytesPerRow(buffer);

  void *data = CVPixelBufferGetBaseAddress(buffer);

  FBImageFrame *input_image = nil;
  OSType pixelFormat = CVPixelBufferGetPixelFormatType(buffer);
  switch (pixelFormat) {
    case kCVPixelFormatType_32BGRA:
      input_image = [FBImageFrame createWithBGRA:data width:width height:height stride:stride];
      break;
    case kCVPixelFormatType_32RGBA:
      input_image = [FBImageFrame createWithRGBA:data width:width height:height stride:stride];
      break;
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  // NV12
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
      const uint8_t *y_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
      size_t y_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);
      const uint8_t *uv_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 1);
      size_t uv_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1);
      input_image = [FBImageFrame createWithNV12:width
                                          height:height
                                           dataY:y_plane
                                         strideY:(int32_t)y_stride
                                          dataUV:uv_plane
                                        strideUV:(int32_t)uv_stride];
      break;
    }
    default:
      CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
      return;
  }

  if (!input_image) {
    CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
    return;
  }
  input_image.type = FBFrameTypeVideo;
  [input_image mirror:@"horizontal"];
  
  FBImageFrame *output_image = [self.beautyEffectEngine processImage:input_image];
  if (output_image) {
    FBImageFrame *rgbaFrame = ([output_image format] == FBImageFormatRGBA)
                                  ? output_image
                                  : [output_image convert:FBImageFormatRGBA];
    if (rgbaFrame) {
      [self.previewView renderFrame:rgbaFrame];
    }
  }

  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}

#pragma mark - BeautyPanelDelegate

- (void)beautyPanelDidChangeParam:(NSString *)tab function:(NSString *)function value:(float)value {
  if (!self.beautyEffectEngine) return;

  if ([tab isEqualToString:@"beauty"]) {
    if ([function isEqualToString:@"smooth"]) {
      [self.beautyEffectEngine setSmoothing:value];
    } else if ([function isEqualToString:@"white"]) {
      [self.beautyEffectEngine setWhitening:value];
    } else if ([function isEqualToString:@"ai"]) {
      [self.beautyEffectEngine setRosiness:value];
    } else if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setSmoothing:0];
      [self.beautyEffectEngine setWhitening:0];
      [self.beautyEffectEngine setRosiness:0];
    }
    return;
  }

  if ([tab isEqualToString:@"reshape"]) {
    if ([function isEqualToString:@"off"]) {
      [self resetAllReshape];
    } else {
      FBReshape param = [self mapToReshape:function];
      if ((NSInteger)param >= 0) {
        [self.beautyEffectEngine setReshape:param intensity:value];
      }
    }
    return;
  }

  if ([tab isEqualToString:@"makeup"]) {
    if ([function isEqualToString:@"lipstick"]) {
      [self.beautyEffectEngine setLipstick:value];
    } else if ([function isEqualToString:@"blush"]) {
      [self.beautyEffectEngine setBlush:value];
    } else if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setLipstick:0];
      [self.beautyEffectEngine setBlush:0];
    }
    return;
  }

  if ([tab isEqualToString:@"virtual_bg"]) {
    if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine clearVirtualBackground];
    } else if ([function isEqualToString:@"blur"]) {
      [self.beautyEffectEngine setVirtualBackgroundBlur:value];
    } else if ([function isEqualToString:@"preset"]) {
      NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"background" ofType:@"jpg"];
      if (!imagePath) {
        NSString *resRoot = [[NSBundle mainBundle] resourcePath];
        if (resRoot.length) {
          imagePath = [resRoot stringByAppendingPathComponent:@"background.jpg"];
          if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            imagePath = [resRoot stringByAppendingPathComponent:@"Icon/background.jpg"];
          }
        }
      }
      if (imagePath && [[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        [self.beautyEffectEngine setVirtualBackground:imagePath];
      }
    }
    return;
  }

  if ([tab isEqualToString:@"sticker"]) {
    if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine clearSticker];
    } else {
      NSString *path = self.stickerPaths[function];
      if (path.length) {
        [self.beautyEffectEngine setSticker:path];
      }
    }
    return;
  }

  if ([tab isEqualToString:@"filter"]) {
    if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine clearFilter];
    } else {
      NSString *path = self.filterPaths[function];
      if (path.length) {
        [self.beautyEffectEngine setFilter:path];
        [self.beautyEffectEngine setFilterIntensity:value];
      }
    }
    return;
  }

  NSLog(@"[Facebetter] Beauty param - tab: %@, function: %@, value: %.2f", tab, function, value);
}

- (FBReshape)mapToReshape:(NSString *)function {
  static NSDictionary<NSString *, NSNumber *> *kMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kMap = @{
      @"thin_face" : @(FBReshape_FaceThin),
      @"v_face" : @(FBReshape_FaceVShape),
      @"narrow_face" : @(FBReshape_FaceNarrow),
      @"short_face" : @(FBReshape_FaceShort),
      @"cheekbone" : @(FBReshape_Cheekbone),
      @"jawbone" : @(FBReshape_Jawbone),
      @"chin" : @(FBReshape_Chin),
      @"nose_slim" : @(FBReshape_NoseSlim),
      @"big_eye" : @(FBReshape_EyeSize),
      @"eye_distance" : @(FBReshape_EyeDistance),
      @"face_small" : @(FBReshape_FaceSmall),
      @"forehead" : @(FBReshape_Forehead),
      @"nose_long" : @(FBReshape_NoseLong),
      @"philtrum" : @(FBReshape_Philtrum),
      @"mouth_size" : @(FBReshape_MouthSize),
      @"mouth_position" : @(FBReshape_MouthPosition),
      @"mouth_smile" : @(FBReshape_MouthSmile),
      @"lip_thickness" : @(FBReshape_LipThickness),
      @"eye_round" : @(FBReshape_EyeRound),
      @"eye_position" : @(FBReshape_EyePosition),
      @"eye_angle" : @(FBReshape_EyeAngle),
      @"eye_corner_open" : @(FBReshape_EyeCornerOpen),
      @"lower_eyelid" : @(FBReshape_LowerEyelid),
      @"brow_position" : @(FBReshape_BrowPosition),
      @"brow_distance" : @(FBReshape_BrowDistance),
      @"brow_thickness" : @(FBReshape_BrowThickness),
    };
  });
  NSNumber *value = kMap[function];
  return value ? (FBReshape)value.integerValue : (FBReshape)-1;
}

- (void)resetAllReshape {
  for (NSInteger p = FBReshape_FaceThin; p <= FBReshape_BrowThickness; ++p) {
    [self.beautyEffectEngine setReshape:(FBReshape)p intensity:0];
  }
}

- (void)beautyPanelDidReset {
  if (!self.beautyEffectEngine) return;
  [self.beautyEffectEngine setSmoothing:0];
  [self.beautyEffectEngine setWhitening:0];
  [self.beautyEffectEngine setRosiness:0];
  [self resetAllReshape];
  [self.beautyEffectEngine setLipstick:0];
  [self.beautyEffectEngine setBlush:0];
  [self.beautyEffectEngine clearSticker];
  [self.beautyEffectEngine clearVirtualBackground];
  [self.beautyEffectEngine clearFilter];
}

- (void)beautyPanelDidResetTab:(NSString *)tab {
  [self beautyPanelDidReset];
}

- (void)beautyPanelDidRequestImageSelection:(NSString *)tab function:(NSString *)function {
  (void)tab;
  (void)function;
}

- (void)beautyPanelDidTapCloseButton {}
- (void)beautyPanelDidTapGalleryButton {}
- (void)beautyPanelDidTapFlipCameraButton {}
- (void)beautyPanelDidTapMoreButton {}

- (void)beautyPanelDidChangeMakeupStyle:(NSString *)function styleIndex:(NSInteger)styleIndex {
  (void)function;
  (void)styleIndex;
  // Makeup style APIs (setLipstickColor / setBlushStyle) are available on the engine.
}

- (void)scanFilterAndStickerPaths {
  if (!self.beautyEffectEngine) return;

  NSFileManager *fileManager = [NSFileManager defaultManager];
  // macOS: resources are in Contents/Resources, use resourcePath (iOS uses bundlePath = .app root)
  NSString *resourcesRoot = [[NSBundle mainBundle] resourcePath];
  if (!resourcesRoot.length) {
    resourcesRoot = [[NSBundle mainBundle] bundlePath];
  }
  self.filterPaths = [NSMutableDictionary dictionary];
  NSString *filtersPath = [resourcesRoot stringByAppendingPathComponent:@"assets/filters/portrait"];
  NSError *error = nil;
  NSArray *filterDirs = [fileManager contentsOfDirectoryAtPath:filtersPath error:&error];
  if (!error) {
    for (NSString *dirName in filterDirs) {
      if ([dirName hasPrefix:@"."]) continue;
      NSString *fbdPath = [filtersPath stringByAppendingPathComponent:
          [dirName stringByAppendingPathComponent:[dirName stringByAppendingPathExtension:@"fbd"]]];
      if ([fileManager fileExistsAtPath:fbdPath]) {
        self.filterPaths[dirName] = fbdPath;
      }
    }
  }

  // 贴纸：扫描 assets/stickers，记录 name -> .fbd 路径，应用时直接 SetSticker(path)
  self.stickerPaths = [NSMutableDictionary dictionary];
  NSString *stickersRoot = [resourcesRoot stringByAppendingPathComponent:@"assets/stickers"];
  NSArray *categoryDirs = [fileManager contentsOfDirectoryAtPath:stickersRoot error:&error];
  if (!error && categoryDirs.count) {
    BOOL isDir = NO;
    for (NSString *category in categoryDirs) {
      if ([category hasPrefix:@"."]) continue;
      NSString *categoryPath = [stickersRoot stringByAppendingPathComponent:category];
      if (![fileManager fileExistsAtPath:categoryPath isDirectory:&isDir] || !isDir) continue;
      NSArray *entries = [fileManager contentsOfDirectoryAtPath:categoryPath error:&error];
      if (error) continue;
      for (NSString *entry in entries) {
        if ([entry hasPrefix:@"."]) continue;
        NSString *entryPath = [categoryPath stringByAppendingPathComponent:entry];
        if ([entry.pathExtension.lowercaseString isEqualToString:@"fbd"]) {
          self.stickerPaths[entry.stringByDeletingPathExtension] = entryPath;
          continue;
        }
        NSString *nested = [entryPath stringByAppendingPathComponent:
            [entry stringByAppendingPathExtension:@"fbd"]];
        if ([fileManager fileExistsAtPath:nested]) {
          self.stickerPaths[entry] = nested;
        }
      }
    }
  }
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];
}

- (void)dealloc {
  [self.cameraManager stopCapture];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
