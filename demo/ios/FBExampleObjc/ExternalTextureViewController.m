//
//  ExternalTextureViewController.m
//  FBExampleObjc
//
//  使用外部 OpenGL 纹理 + EngineConfig.externalContext 的实时渲染示例。
//

#import "ExternalTextureViewController.h"
#import "GLTextureRenderView.h"

#import <Facebetter/FBBeautyEffectEngine.h>
#import <Facebetter/FBImageFrame.h>
#import <OpenGLES/ES2/gl.h>

@interface ExternalTextureViewController () <GLTextureRenderViewDelegate>

@property(nonatomic, strong) GLTextureRenderView *renderView;
@property(nonatomic, strong) FBBeautyEffectEngine *engine;
@property(nonatomic, strong) UISlider *smoothingSlider;
@property(nonatomic, strong) UISlider *whiteningSlider;
@property(nonatomic, strong) UILabel *smoothingLabel;
@property(nonatomic, strong) UILabel *whiteningLabel;
@property(nonatomic, strong) UILabel *smoothingValueLabel;
@property(nonatomic, strong) UILabel *whiteningValueLabel;

@property(nonatomic, assign) float initialSmoothingValue;
@property(nonatomic, assign) float initialWhiteningValue;

@end

@implementation ExternalTextureViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"External Texture Demo";

  _initialSmoothingValue = 0.2f;
  _initialWhiteningValue = 0.0f;

  [self setupUI];
}

- (void)setupUI {
  // 创建渲染视图
  self.renderView = [[GLTextureRenderView alloc] init];
  self.renderView.translatesAutoresizingMaskIntoConstraints = NO;
  self.renderView.delegate = self;
  [self.view addSubview:self.renderView];

  // 创建滑动条容器
  UIView *sliderContainer = [[UIView alloc] init];
  sliderContainer.translatesAutoresizingMaskIntoConstraints = NO;
  sliderContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
  sliderContainer.layer.cornerRadius = 8;
  [self.view addSubview:sliderContainer];

  // 磨皮滑动条
  self.smoothingLabel = [[UILabel alloc] init];
  self.smoothingLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.smoothingLabel.text = @"磨皮";
  self.smoothingLabel.textColor = [UIColor whiteColor];
  self.smoothingLabel.font = [UIFont systemFontOfSize:16];
  [sliderContainer addSubview:self.smoothingLabel];

  self.smoothingSlider = [[UISlider alloc] init];
  self.smoothingSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.smoothingSlider.minimumValue = 0.0;
  self.smoothingSlider.maximumValue = 1.0;
  self.smoothingSlider.value = _initialSmoothingValue;
  [self.smoothingSlider addTarget:self
                           action:@selector(smoothingSliderChanged:)
                 forControlEvents:UIControlEventValueChanged];
  [sliderContainer addSubview:self.smoothingSlider];

  self.smoothingValueLabel = [[UILabel alloc] init];
  self.smoothingValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.smoothingValueLabel.text = [NSString stringWithFormat:@"%.2f", _initialSmoothingValue];
  self.smoothingValueLabel.textColor = [UIColor whiteColor];
  self.smoothingValueLabel.font = [UIFont systemFontOfSize:14];
  self.smoothingValueLabel.textAlignment = NSTextAlignmentCenter;
  [sliderContainer addSubview:self.smoothingValueLabel];

  // 美白滑动条
  self.whiteningLabel = [[UILabel alloc] init];
  self.whiteningLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.whiteningLabel.text = @"美白";
  self.whiteningLabel.textColor = [UIColor whiteColor];
  self.whiteningLabel.font = [UIFont systemFontOfSize:16];
  [sliderContainer addSubview:self.whiteningLabel];

  self.whiteningSlider = [[UISlider alloc] init];
  self.whiteningSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.whiteningSlider.minimumValue = 0.0;
  self.whiteningSlider.maximumValue = 1.0;
  self.whiteningSlider.value = _initialWhiteningValue;
  [self.whiteningSlider addTarget:self
                          action:@selector(whiteningSliderChanged:)
                forControlEvents:UIControlEventValueChanged];
  [sliderContainer addSubview:self.whiteningSlider];

  self.whiteningValueLabel = [[UILabel alloc] init];
  self.whiteningValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.whiteningValueLabel.text = [NSString stringWithFormat:@"%.2f", _initialWhiteningValue];
  self.whiteningValueLabel.textColor = [UIColor whiteColor];
  self.whiteningValueLabel.font = [UIFont systemFontOfSize:14];
  self.whiteningValueLabel.textAlignment = NSTextAlignmentCenter;
  [sliderContainer addSubview:self.whiteningValueLabel];

  // 设置约束
  UILayoutGuide *guide = self.view.safeAreaLayoutGuide;

  [NSLayoutConstraint activateConstraints:@[
    // 渲染视图填满整个屏幕
    [self.renderView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.renderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.renderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.renderView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // 滑动条容器在底部
    [sliderContainer.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
    [sliderContainer.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
    [sliderContainer.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-22],

    // 磨皮行
    [self.smoothingLabel.leadingAnchor constraintEqualToAnchor:sliderContainer.leadingAnchor
                                                      constant:16],
    [self.smoothingLabel.topAnchor constraintEqualToAnchor:sliderContainer.topAnchor constant:16],
    [self.smoothingLabel.widthAnchor constraintEqualToConstant:60],

    [self.smoothingSlider.leadingAnchor constraintEqualToAnchor:self.smoothingLabel.trailingAnchor
                                                       constant:8],
    [self.smoothingSlider.centerYAnchor
        constraintEqualToAnchor:self.smoothingLabel.centerYAnchor],
    [self.smoothingSlider.trailingAnchor
        constraintEqualToAnchor:self.smoothingValueLabel.leadingAnchor
                       constant:-8],

    [self.smoothingValueLabel.widthAnchor constraintEqualToConstant:50],
    [self.smoothingValueLabel.centerYAnchor
        constraintEqualToAnchor:self.smoothingLabel.centerYAnchor],
    [self.smoothingValueLabel.trailingAnchor
        constraintEqualToAnchor:sliderContainer.trailingAnchor
                      constant:-16],

    // 美白行
    [self.whiteningLabel.leadingAnchor constraintEqualToAnchor:sliderContainer.leadingAnchor
                                                      constant:16],
    [self.whiteningLabel.topAnchor constraintEqualToAnchor:self.smoothingLabel.bottomAnchor
                                                  constant:16],
    [self.whiteningLabel.widthAnchor constraintEqualToConstant:60],

    [self.whiteningSlider.leadingAnchor constraintEqualToAnchor:self.whiteningLabel.trailingAnchor
                                                       constant:8],
    [self.whiteningSlider.centerYAnchor
        constraintEqualToAnchor:self.whiteningLabel.centerYAnchor],
    [self.whiteningSlider.trailingAnchor
        constraintEqualToAnchor:self.whiteningValueLabel.leadingAnchor
                       constant:-8],

    [self.whiteningValueLabel.widthAnchor constraintEqualToConstant:50],
    [self.whiteningValueLabel.centerYAnchor
        constraintEqualToAnchor:self.whiteningLabel.centerYAnchor],
    [self.whiteningValueLabel.trailingAnchor
        constraintEqualToAnchor:sliderContainer.trailingAnchor
                      constant:-16],

    [sliderContainer.bottomAnchor constraintEqualToAnchor:self.whiteningLabel.bottomAnchor
                                                  constant:16]
  ]];

  // 初始化输入纹理
  UIImage *demoImage = [UIImage imageNamed:@"demo"];
  if (demoImage) {
    [self.renderView initializeInputTextureWithImage:demoImage];
  }
}

- (void)smoothingSliderChanged:(UISlider *)sender {
  float value = sender.value;
  self.smoothingValueLabel.text = [NSString stringWithFormat:@"%.2f", value];
  if (self.engine) {
    [self.engine setBasicParam:FBBasicParam_Smoothing floatValue:value];
  }
}

- (void)whiteningSliderChanged:(UISlider *)sender {
  float value = sender.value;
  self.whiteningValueLabel.text = [NSString stringWithFormat:@"%.2f", value];
  if (self.engine) {
    [self.engine setBasicParam:FBBasicParam_Whitening floatValue:value];
  }
}

#pragma mark - GLTextureRenderViewDelegate

- (int)onProcessVideoFrame:(TextureFrame)srcFrame dstFrame:(TextureFrame *)dstFrame {
  // Initialize engine if not initialized
  if (!self.engine) {
    
    
    FBLogConfig *logConfig = [[FBLogConfig alloc] init];
    logConfig.consoleEnabled = YES;
    [FBBeautyEffectEngine setLogConfig:logConfig];

    
    FBEngineConfig *config = [[FBEngineConfig alloc] init];
    // TODO: 替换为你的 AppId/AppKey 或 licenseJson
    config.appId = @"";
    config.appKey = @"";
    
    // 验证 appId 和 appKey
    if (!config.appId || !config.appKey || 
        [config.appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0 ||
        [config.appKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
      NSLog(@"[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code.");
      return -1;
    }
    
    config.externalContext = YES;

    self.engine = [FBBeautyEffectEngine createEngineWithConfig:config];
    if (!self.engine) {
      return -1;
    }

    [self.engine setBeautyTypeEnabled:FBBeautyType_Basic enabled:YES];
    [self.engine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:YES];

    // 应用初始滑动条的值
    [self.engine setBasicParam:FBBasicParam_Smoothing floatValue:_initialSmoothingValue];
    [self.engine setBasicParam:FBBasicParam_Whitening floatValue:_initialWhiteningValue];
  }

  // Create ImageFrame from input texture
  int stride = srcFrame.width * 4;  // RGBA stride
  FBImageFrame *inputFrame = [FBImageFrame createWithTexture:srcFrame.textureId
                                                        width:srcFrame.width
                                                       height:srcFrame.height
                                                       stride:stride];
  if (!inputFrame) {
    NSLog(@"createWithTexture failed");
    return -1;
  }

  // Process image
  inputFrame.type = FBFrameTypeImage;
  FBImageFrame *outputFrame =
      [self.engine processImage:inputFrame];
  if (!outputFrame) {
    NSLog(@"processImage returned nil");
    return -2;
  }

  // Get texture ID directly from output frame
  uint32_t outputTextureId = [outputFrame texture];
  if (outputTextureId == 0) {
    NSLog(@"Failed to get texture from output buffer");
    return -3;
  }

  // Set output texture and size
  dstFrame->textureId = outputTextureId;
  dstFrame->width = outputFrame.width;
  dstFrame->height = outputFrame.height;

  return 0;  // Success
}

- (void)dealloc {
  if (self.engine) {
    // 注意：FBBeautyEffectEngine 是单例，通常不需要手动释放
    // 但如果有自定义的清理逻辑，可以在这里处理
    self.engine = nil;
  }
}

@end


