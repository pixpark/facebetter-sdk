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

  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_VirtualBackground enabled:TRUE];

  [self registerFiltersAndStickers];

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
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:value];
    } else if ([function isEqualToString:@"white"]) {
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:value];
    } else if ([function isEqualToString:@"ai"]) {
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:value];
    } else if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:0];
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:0];
      [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:0];
    }
    return;
  }

  if ([tab isEqualToString:@"reshape"]) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape
                                          enabled:![function isEqualToString:@"off"]];
    if ([function isEqualToString:@"thin_face"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceThin floatValue:value];
    } else if ([function isEqualToString:@"v_face"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceVShape floatValue:value];
    } else if ([function isEqualToString:@"narrow_face"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceNarrow floatValue:value];
    } else if ([function isEqualToString:@"short_face"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceShort floatValue:value];
    } else if ([function isEqualToString:@"cheekbone"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Cheekbone floatValue:value];
    } else if ([function isEqualToString:@"jawbone"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Jawbone floatValue:value];
    } else if ([function isEqualToString:@"chin"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Chin floatValue:value];
    } else if ([function isEqualToString:@"nose_slim"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_NoseSlim floatValue:value];
    } else if ([function isEqualToString:@"big_eye"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeSize floatValue:value];
    } else if ([function isEqualToString:@"eye_distance"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeDistance floatValue:value];
    } else if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceThin floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceVShape floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceNarrow floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceShort floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Cheekbone floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Jawbone floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Chin floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_NoseSlim floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeSize floatValue:0];
      [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeDistance floatValue:0];
    }
    return;
  }

  if ([tab isEqualToString:@"makeup"]) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup
                                          enabled:![function isEqualToString:@"off"]];
    if ([function isEqualToString:@"lipstick"]) {
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:value];
    } else if ([function isEqualToString:@"blush"]) {
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:value];
    } else if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:0];
      [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:0];
    }
    return;
  }

  if ([tab isEqualToString:@"virtual_bg"]) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_VirtualBackground
                                          enabled:![function isEqualToString:@"off"]];
    FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
    if ([function isEqualToString:@"off"]) {
      options.mode = FBBackgroundModeNone;
      [self.beautyEffectEngine setVirtualBackground:options];
    } else if ([function isEqualToString:@"blur"]) {
      options.mode = FBBackgroundModeBlur;
      [self.beautyEffectEngine setVirtualBackground:options];
    } else if ([function isEqualToString:@"preset"]) {
      FBImageFrame *imageFrame = nil;
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
        imageFrame = [FBImageFrame createWithFile:imagePath];
      }
      if (!imageFrame) {
        NSImage *img = [NSImage imageNamed:@"background"];
        if (img) imageFrame = [FBImageFrame createWithNSImage:img];
      }
      if (imageFrame) {
        options.mode = FBBackgroundModeImage;
        options.backgroundImage = imageFrame;
        [self.beautyEffectEngine setVirtualBackground:options];
      }
    }
    return;
  }

  if ([tab isEqualToString:@"sticker"]) {
    if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setSticker:@""];
    } else {
      [self.beautyEffectEngine setSticker:function];
    }
    return;
  }

  if ([tab isEqualToString:@"filter"]) {
    [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Filter
                                          enabled:![function isEqualToString:@"off"]];
    if ([function isEqualToString:@"off"]) {
      [self.beautyEffectEngine setFilterIntensity:0];
    } else {
      [self.beautyEffectEngine setFilter:function];
      [self.beautyEffectEngine setFilterIntensity:value];
    }
    return;
  }

  NSLog(@"[Facebetter] Beauty param - tab: %@, function: %@, value: %.2f", tab, function, value);
}

- (void)beautyPanelDidReset {
  if (!self.beautyEffectEngine) return;
  [self.beautyEffectEngine setBasicParam:FBBasicParam_Smoothing floatValue:0];
  [self.beautyEffectEngine setBasicParam:FBBasicParam_Whitening floatValue:0];
  [self.beautyEffectEngine setBasicParam:FBBasicParam_Rosiness floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceThin floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceVShape floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceNarrow floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_FaceShort floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Cheekbone floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Jawbone floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_Chin floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_NoseSlim floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeSize floatValue:0];
  [self.beautyEffectEngine setReshapeParam:FBReshapeParam_EyeDistance floatValue:0];
  [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Lipstick floatValue:0];
  [self.beautyEffectEngine setMakeupParam:FBMakeupParam_Blush floatValue:0];
  [self.beautyEffectEngine setSticker:@""];
  FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
  options.mode = FBBackgroundModeNone;
  [self.beautyEffectEngine setVirtualBackground:options];
  [self.beautyEffectEngine setFilterIntensity:0];
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
  // Engine currently only has setMakeupParam(param, value); style not exposed. Store or apply when API is added.
}

- (void)registerFiltersAndStickers {
  if (!self.beautyEffectEngine) return;

  NSFileManager *fileManager = [NSFileManager defaultManager];
  // macOS: resources are in Contents/Resources, use resourcePath (iOS uses bundlePath = .app root)
  NSString *resourcesRoot = [[NSBundle mainBundle] resourcePath];
  if (!resourcesRoot.length) {
    resourcesRoot = [[NSBundle mainBundle] bundlePath];
  }
  NSString *filtersPath = [resourcesRoot stringByAppendingPathComponent:@"assets/filters/portrait"];
  NSError *error = nil;
  NSArray *filterDirs = [fileManager contentsOfDirectoryAtPath:filtersPath error:&error];
  if (!error) {
    for (NSString *dirName in filterDirs) {
      if ([dirName hasPrefix:@"."]) continue;
      NSString *fbdPath = [filtersPath stringByAppendingPathComponent:
          [dirName stringByAppendingPathComponent:[dirName stringByAppendingPathExtension:@"fbd"]]];
      if ([fileManager fileExistsAtPath:fbdPath]) {
        [self.beautyEffectEngine registerFilter:dirName fbdFilePath:fbdPath];
      }
    }
  }

  // 贴纸：扫描 assets/stickers/分类名/贴纸名/贴纸名.fbd（如 face/rabbit/rabbit.fbd）
  NSString *stickersRoot = [resourcesRoot stringByAppendingPathComponent:@"assets/stickers"];
  NSArray *categoryDirs = [fileManager contentsOfDirectoryAtPath:stickersRoot error:&error];
  if (!error && categoryDirs.count) {
    for (NSString *category in categoryDirs) {
      if ([category hasPrefix:@"."]) continue;
      NSString *categoryPath = [stickersRoot stringByAppendingPathComponent:category];
      NSArray *stickerDirs = [fileManager contentsOfDirectoryAtPath:categoryPath error:&error];
      if (error) continue;
      for (NSString *stickerName in stickerDirs) {
        if ([stickerName hasPrefix:@"."]) continue;
        NSString *fbdPath = [categoryPath stringByAppendingPathComponent:
            [stickerName stringByAppendingPathComponent:[stickerName stringByAppendingPathExtension:@"fbd"]]];
        if ([fileManager fileExistsAtPath:fbdPath]) {
          [self.beautyEffectEngine registerSticker:stickerName fbdFilePath:fbdPath];
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
