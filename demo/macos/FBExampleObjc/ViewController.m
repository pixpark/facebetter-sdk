//
//  ViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Facebetter/FBBeautyEffectEngine.h>
#import "BeautyPanelViewController.h"
#import "CameraManager.h"
#import "GLRGBARenderView.h"

@interface ViewController () <CameraManagerDelegate, BeautyPanelDelegate>
@property(nonatomic, strong) FBBeautyEffectEngine *beautyEffectEngine;
@property(nonatomic, strong) CameraManager *cameraManager;
@property(nonatomic, strong) BeautyPanelViewController *beautyPanelViewController;
@property(nonatomic, strong) GLRGBARenderView *previewView;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic, strong) NSLayoutConstraint *panelHeightConstraint;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // 日志
  FBLogConfig *logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"facebetter_sdk.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];

  // engine
  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];

  // replace with your appid and appkey
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

  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_VirtualBackground enabled:TRUE];

  // 初始化美颜调节面板（先添加，以便建立约束关系）
  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];
  [self.view addSubview:self.beautyPanelViewController.view];

  // 使用自定义 OpenGL 视图渲染 RGBA（占据上半部分）
  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.previewView setMirrored:YES];
  [self.view addSubview:self.previewView];

  // 设置约束：预览视图在上半部分，面板视图在下半部分
  self.panelHeightConstraint =
      [self.beautyPanelViewController.view.heightAnchor constraintEqualToConstant:180];

  [NSLayoutConstraint activateConstraints:@[
    // 预览视图：占据上半部分
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor
        constraintEqualToAnchor:self.beautyPanelViewController.view.topAnchor],

    // 美颜面板视图：占据下半部分，固定高度
    [self.beautyPanelViewController.view.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.beautyPanelViewController.view.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.beautyPanelViewController.view.bottomAnchor
        constraintEqualToAnchor:self.view.bottomAnchor],
    self.panelHeightConstraint
  ]];

  // 初始化相机管理器
  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                       cameraDevice:nil];
  self.cameraManager.delegate = self;
  [self.cameraManager startCapture];

  // 设置键盘快捷键来切换面板显示/隐藏 (Cmd+B)
  self.eventMonitor = [NSEvent
      addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                   handler:^NSEvent *(NSEvent *event) {
                                     if (event.modifierFlags & NSEventModifierFlagCommand &&
                                         event.keyCode == 11) {  // Cmd+B
                                       [self.beautyPanelViewController togglePanelVisibility];
                                       return nil;  // 阻止事件继续传播
                                     }
                                     return event;
                                   }];

  // 监听面板显示/隐藏通知
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
        self.panelHeightConstraint.animator.constant = visible ? 180 : 0;
      }
      completionHandler:nil];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // 获取图像缓冲区
  CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (!buffer) {
    return;
  }

  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
  int width = (int32_t)CVPixelBufferGetWidth(buffer);
  int height = (int32_t)CVPixelBufferGetHeight(buffer);
  int stride = (int32_t)CVPixelBufferGetBytesPerRow(buffer);

  void *data = CVPixelBufferGetBaseAddress(buffer);

  FBImageFrame *input_image;
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
      // 获取Y平面数据
      const uint8_t *y_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
      size_t y_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);

      // 获取UV平面数据
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
      break;
  }

  FBImageFrame *output_image = [self.beautyEffectEngine processImage:input_image
                                                         processMode:FBProcessModeVideo];
  if (output_image) {
    FBImageBuffer *rgba = [output_image toRGBA];
    if (rgba) {
      [self.previewView renderBuffer:rgba];
    }
  }

  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}

#pragma mark - 定时器相关方法

- (void)processImageWithTimer {
}

#pragma mark - BeautyPanelDelegate

- (void)beautyPanelDidChangeParam:(FBBeautyType)beautyType
                            param:(NSInteger)paramType
                            value:(float)value {
  switch (beautyType) {
    case FBBeautyType_Basic: {
      FBBasicParam basicParam = (FBBasicParam)paramType;
      [self.beautyEffectEngine setBasicParam:basicParam floatValue:value];
      break;
    }
    case FBBeautyType_Reshape: {
      FBReshapeParam reshapeParam = (FBReshapeParam)paramType;
      [self.beautyEffectEngine setReshapeParam:reshapeParam floatValue:value];
      break;
    }
    case FBBeautyType_Makeup: {
      FBMakeupParam makeupParam = (FBMakeupParam)paramType;
      [self.beautyEffectEngine setMakeupParam:makeupParam floatValue:value];
      break;
    }
    case FBBeautyType_VirtualBackground: {
      // 使用新的虚拟背景接口
      FBVirtualBackgroundOptions *options = [[FBVirtualBackgroundOptions alloc] init];
      if (value > 0.5f) {
        options.mode = FBBackgroundModeBlur;
      } else {
        options.mode = FBBackgroundModeNone;
      }
      [self.beautyEffectEngine setVirtualBackground:options];
      break;
    }
  }

  NSLog(@"Beauty param changed - Type: %ld, Param: %ld, Value: %.2f",
        (long)beautyType,
        (long)paramType,
        value);
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];
  // Update the view, if already loaded.
}

- (void)dealloc {
  // 停止相机采集
  [self.cameraManager stopCapture];

  // 移除通知监听
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
