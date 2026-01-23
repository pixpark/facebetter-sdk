//
//  HomeViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/11/04.
//

#import "HomeViewController.h"
#import "CameraViewController.h"
#import "ExternalTextureViewController.h"

@interface HomeViewController ()

@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIImageView *headerImageView;
@property(nonatomic, strong) CAGradientLayer *beautyTemplateGradientLayer;
@property(nonatomic, strong) UIButton *beautyTemplateButton;
@property(nonatomic, strong) UIButton *beautyEffectButton;
@property(nonatomic, strong) UIView *gridContainer;

@end

@implementation HomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  [self setupUI];
  // 让视图延伸到安全区域外，实现全屏效果（需要在 setupUI 之后设置）
  if (@available(iOS 11.0, *)) {
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  } else {
// iOS 11.0 以下使用已弃用的方法
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // 更新渐变图层的大小，使其与按钮大小一致
  if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
    self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
  }

  // 确保按钮始终在视图层级最上层
  if (self.beautyEffectButton) {
    [self.view bringSubviewToFront:self.beautyEffectButton];
  }
  if (self.beautyTemplateButton) {
    [self.view bringSubviewToFront:self.beautyTemplateButton];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // 确保按钮在视图层级最上层，可以接收触摸事件
  if (self.beautyEffectButton) {
    [self.view bringSubviewToFront:self.beautyEffectButton];
    self.beautyEffectButton.userInteractionEnabled = YES;
    self.beautyEffectButton.enabled = YES;
  }
  if (self.beautyTemplateButton) {
    [self.view bringSubviewToFront:self.beautyTemplateButton];
    self.beautyTemplateButton.userInteractionEnabled = YES;
    self.beautyTemplateButton.enabled = YES;
  }
}

- (void)setupUI {
  // 创建滚动视图
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  [self.view addSubview:self.scrollView];

  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.scrollView addSubview:self.contentView];

  // 顶部图片区域
  [self setupHeaderImage];

  // 功能网格（先添加，确保在按钮下方）
  [self setupFeatureGrid];

  // 两个大按钮（最后添加，确保显示在上层）
  [self setupLargeButtons];

  // 约束
  [self setupConstraints];
}

- (void)setupHeaderImage {
  self.headerImageView = [[UIImageView alloc] init];
  self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.headerImageView.clipsToBounds = YES;
  // 从 Assets.xcassets 读取 header 图片，对应 Android 的 header
  UIImage *headerImage = [UIImage imageNamed:@"header"];
  if (headerImage) {
    self.headerImageView.image = headerImage;
  } else {
    // 如果图标不存在，使用背景色作为后备
    self.headerImageView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
  }
  [self.contentView addSubview:self.headerImageView];

  // 设置按钮（右上角，最顶部）
  UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
  settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  // 从 Assets.xcassets 读取图标，对应 Android 的 setting
  UIImage *settingsIcon = [UIImage imageNamed:@"setting"];
  if (!settingsIcon) {
    // 如果图标不存在，使用系统图标作为后备
    if (@available(iOS 13.0, *)) {
      settingsIcon = [UIImage systemImageNamed:@"gearshape"];
    }
  }
  // 设置为模板模式，以便 tintColor 生效
  if (settingsIcon) {
    settingsIcon = [settingsIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [settingsButton setImage:settingsIcon forState:UIControlStateNormal];
  settingsButton.tintColor = [UIColor whiteColor];
  [settingsButton addTarget:self
                     action:@selector(settingsButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
  // 添加到 self.view 而不是 contentView，确保在视图最上层
  [self.view addSubview:settingsButton];

  [NSLayoutConstraint activateConstraints:@[
    // 放到状态栏区域内（与状态栏图标对齐）
    // 使用 topAnchor 加上合适的偏移，让按钮在状态栏区域中间位置
    [settingsButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50],
    [settingsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    // 调小尺寸：从 28x28 改为 22x22
    [settingsButton.widthAnchor constraintEqualToConstant:22],
    [settingsButton.heightAnchor constraintEqualToConstant:22]
  ]];
}

- (void)setupLargeButtons {
  // 美颜特效按钮 - 对应 Android 的 camera2
  UIImage *beautyEffectIcon = [UIImage imageNamed:@"camera2"];
  if (!beautyEffectIcon) {
    if (@available(iOS 13.0, *)) {
      beautyEffectIcon = [UIImage systemImageNamed:@"camera.fill"];
    }
  }
  self.beautyEffectButton = [self createLargeButtonWithTitle:@"美颜特效"
                                                        icon:beautyEffectIcon
                                                   tintColor:[UIColor colorWithRed:0xA0 / 255.0
                                                                             green:0xF1 / 255.0
                                                                              blue:0x96 / 255.0
                                                                             alpha:1.0]
                                             backgroundColor:[UIColor colorWithRed:0x33 / 255.0
                                                                             green:0x33 / 255.0
                                                                              blue:0x33 / 255.0
                                                                             alpha:1.0]
                                                   textColor:[UIColor whiteColor]];
  [self.beautyEffectButton addTarget:self
                              action:@selector(beautyEffectButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
  // 添加到 self.view 而不是 contentView，确保显示在网格容器之上
  [self.view addSubview:self.beautyEffectButton];

  // 美颜模板按钮 - 对应 Android 的 beautycard3
  UIImage *beautyTemplateIcon = [UIImage imageNamed:@"beautycard3"];
  if (!beautyTemplateIcon) {
    if (@available(iOS 13.0, *)) {
      beautyTemplateIcon = [UIImage systemImageNamed:@"photo.fill"];
    }
  }
  // 背景色设为透明，使用渐变图层作为背景
  self.beautyTemplateButton = [self createLargeButtonWithTitle:@"美颜模板"
                                                          icon:beautyTemplateIcon
                                                     tintColor:[UIColor blackColor]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:nil];
  [self.beautyTemplateButton addTarget:self
                                action:@selector(beautyTemplateButtonTapped:)
                      forControlEvents:UIControlEventTouchUpInside];

  // 创建渐变背景图层
  self.beautyTemplateGradientLayer = [CAGradientLayer layer];
  self.beautyTemplateGradientLayer.colors = @[
    (id)[UIColor colorWithRed:0xCC / 255.0 green:0xFB / 255.0 blue:0x78 / 255.0 alpha:1.0].CGColor,
    (id)[UIColor colorWithRed:0x75 / 255.0 green:0xED / 255.0 blue:0xE0 / 255.0 alpha:1.0].CGColor
  ];
  // 渐变方向：从左到右
  self.beautyTemplateGradientLayer.startPoint = CGPointMake(0, 0);
  self.beautyTemplateGradientLayer.endPoint = CGPointMake(1, 0);
  self.beautyTemplateGradientLayer.cornerRadius = 12;
  // 将渐变图层插入到最底层
  [self.beautyTemplateButton.layer insertSublayer:self.beautyTemplateGradientLayer atIndex:0];

  // 添加到 self.view 而不是 contentView，确保显示在网格容器之上
  [self.view addSubview:self.beautyTemplateButton];

  [NSLayoutConstraint activateConstraints:@[
    // 美颜特效按钮（向上移动 40 像素）
    [self.beautyEffectButton.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                      constant:-75],
    [self.beautyEffectButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                          constant:20],
    [self.beautyEffectButton.trailingAnchor
        constraintEqualToAnchor:self.beautyTemplateButton.leadingAnchor
                       constant:-8],
    [self.beautyEffectButton.widthAnchor
        constraintEqualToAnchor:self.beautyTemplateButton.widthAnchor],
    [self.beautyEffectButton.heightAnchor constraintEqualToConstant:72],

    // 美颜模板按钮（与美颜特效按钮顶部对齐）
    [self.beautyTemplateButton.topAnchor constraintEqualToAnchor:self.beautyEffectButton.topAnchor],
    [self.beautyTemplateButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                             constant:-20],
    [self.beautyTemplateButton.heightAnchor constraintEqualToConstant:72]
  ]];

  // 确保按钮在视图层级最上层，可以接收触摸事件
  [self.view bringSubviewToFront:self.beautyEffectButton];
  [self.view bringSubviewToFront:self.beautyTemplateButton];

  // 确保按钮可以接收触摸事件
  self.beautyEffectButton.userInteractionEnabled = YES;
  self.beautyTemplateButton.userInteractionEnabled = YES;
}

- (UIButton *)createLargeButtonWithTitle:(NSString *)title
                                    icon:(UIImage *)icon
                               tintColor:(UIColor *)tintColor
                         backgroundColor:(UIColor *)backgroundColor
                               textColor:(UIColor *)textColor {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.backgroundColor = backgroundColor;
  button.layer.cornerRadius = 12;
  button.clipsToBounds = YES;
  // 确保按钮可以接收触摸事件
  button.userInteractionEnabled = YES;
  button.enabled = YES;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.axis = UILayoutConstraintAxisHorizontal;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.spacing = 12;
  // StackView 不拦截触摸事件，让按钮接收
  stackView.userInteractionEnabled = NO;

  UIImageView *iconView = [[UIImageView alloc] init];
  // 将图片设置为模板渲染模式，这样 tintColor 才能生效
  UIImage *templatedIcon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  iconView.image = templatedIcon;
  iconView.tintColor = tintColor;
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:28],
    [iconView.heightAnchor constraintEqualToConstant:28]
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = title;
  titleLabel.font = [UIFont boldSystemFontOfSize:18];
  titleLabel.textColor = textColor ? textColor : tintColor;

  [stackView addArrangedSubview:iconView];
  [stackView addArrangedSubview:titleLabel];
  [button addSubview:stackView];

  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
  ]];

  return button;
}

- (void)setupFeatureGrid {
  // 第一个网格容器（白色背景，带圆角）
  self.gridContainer = [[UIView alloc] init];
  self.gridContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.gridContainer.backgroundColor = [UIColor whiteColor];
  self.gridContainer.layer.cornerRadius = 24;
  self.gridContainer.layer.masksToBounds = YES;
  // 容器需要启用交互，以便子视图（按钮）可以接收触摸事件
  self.gridContainer.userInteractionEnabled = YES;
  // 添加到 view 而不是 contentView，确保和屏幕宽度一致
  [self.view addSubview:self.gridContainer];

  // 第一个区域：前8个功能按钮（美颜到画质调整）
  // 按钮顺序与 Android 保持一致
  NSArray *firstSectionFeatures = @[
    @{
      @"title" : @"美颜",
      @"selector" : @"beautyButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meiyan"
    },
    @{
      @"title" : @"美型",
      @"selector" : @"reshapeButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meixing2"
    },
    @{
      @"title" : @"美妆",
      @"selector" : @"makeupButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meizhuang"
    },
    @{
      @"title" : @"美体",
      @"selector" : @"bodyButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"meiti"
    },
    @{
      @"title" : @"滤镜",
      @"selector" : @"filterButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"lvjing"
    },
    @{
      @"title" : @"贴纸",
      @"selector" : @"stickerButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"tiezhi2"
    },
    @{
      @"title" : @"虚拟背景",
      @"selector" : @"virtualBgButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"xunibeijing"
    },
    @{
      @"title" : @"画质调整",
      @"selector" : @"qualityButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"huazhitiaozheng2"
    }
  ];

  // 创建第一个区域的网格布局
  UIStackView *firstSectionStack = [[UIStackView alloc] init];
  firstSectionStack.translatesAutoresizingMaskIntoConstraints = NO;
  firstSectionStack.axis = UILayoutConstraintAxisVertical;
  firstSectionStack.spacing = 16;
  firstSectionStack.distribution = UIStackViewDistributionFill;
  // StackView 需要启用交互，以便子视图（按钮）可以接收触摸事件
  // 注意：UIStackView 的 userInteractionEnabled 应该为 YES，这样它的子视图才能接收触摸事件
  firstSectionStack.userInteractionEnabled = YES;

  // 创建2行，每行4个按钮
  for (int row = 0; row < 2; row++) {
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.distribution = UIStackViewDistributionFillEqually;
    // StackView 需要启用交互，以便子视图（按钮）可以接收触摸事件
    rowStack.userInteractionEnabled = YES;

    for (int col = 0; col < 4; col++) {
      int index = row * 4 + col;
      NSDictionary *feature = firstSectionFeatures[index];
      UIButton *button = [self createFeatureButton:feature];
      [rowStack addArrangedSubview:button];
    }

    [firstSectionStack addArrangedSubview:rowStack];
  }

  [self.gridContainer addSubview:firstSectionStack];

  // 原子能力区域容器
  UIView *atomicCapabilitiesContainer = [[UIView alloc] init];
  atomicCapabilitiesContainer.translatesAutoresizingMaskIntoConstraints = NO;
  atomicCapabilitiesContainer.backgroundColor = [UIColor whiteColor];
  // 容器需要启用交互，以便子视图（按钮）可以接收触摸事件
  atomicCapabilitiesContainer.userInteractionEnabled = YES;
  [self.contentView addSubview:atomicCapabilitiesContainer];

  // "原子能力"标题
  UILabel *atomicTitleLabel = [[UILabel alloc] init];
  atomicTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  atomicTitleLabel.text = @"原子能力";
  atomicTitleLabel.font = [UIFont boldSystemFontOfSize:18];
  atomicTitleLabel.textColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  [atomicCapabilitiesContainer addSubview:atomicTitleLabel];

  // 第二个区域：原子能力按钮（换发色、风格整装、人脸检测、手势检测、绿幕抠图）
  NSArray *secondSectionFeatures = @[
    @{
      @"title" : @"换发色",
      @"selector" : @"hairColorButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"huanfase"
    },
    @{
      @"title" : @"风格整装",
      @"selector" : @"styleButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"fengge"
    },
    @{
      @"title" : @"人脸检测",
      @"selector" : @"faceDetectButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"renlianjiance"
    },
    @{
      @"title" : @"手势检测",
      @"selector" : @"gestureButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"shoushi"
    },
    @{
      @"title" : @"绿幕抠图",
      @"selector" : @"greenScreenButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"lvmukoutu"
    }
  ];

  // 创建第二个区域的网格布局
  UIStackView *secondSectionStack = [[UIStackView alloc] init];
  secondSectionStack.translatesAutoresizingMaskIntoConstraints = NO;
  secondSectionStack.axis = UILayoutConstraintAxisVertical;
  secondSectionStack.spacing = 16;
  secondSectionStack.distribution = UIStackViewDistributionFill;
  // StackView 需要启用交互，以便子视图（按钮）可以接收触摸事件
  secondSectionStack.userInteractionEnabled = YES;

  // 第1行：4个按钮（换发色、风格整装、人脸检测、手势检测）
  UIStackView *secondRow1 = [[UIStackView alloc] init];
  secondRow1.translatesAutoresizingMaskIntoConstraints = NO;
  secondRow1.axis = UILayoutConstraintAxisHorizontal;
  secondRow1.spacing = 12;
  secondRow1.distribution = UIStackViewDistributionFillEqually;
  // StackView 需要启用交互，以便子视图（按钮）可以接收触摸事件
  secondRow1.userInteractionEnabled = YES;

  for (int i = 0; i < 4; i++) {
    NSDictionary *feature = secondSectionFeatures[i];
    UIButton *button = [self createFeatureButton:feature];
    [secondRow1 addArrangedSubview:button];
  }
  [secondSectionStack addArrangedSubview:secondRow1];

  // 第2行：2个按钮（绿幕抠图、外部纹理）+ 2个占位
  UIStackView *secondRow2 = [[UIStackView alloc] init];
  secondRow2.translatesAutoresizingMaskIntoConstraints = NO;
  secondRow2.axis = UILayoutConstraintAxisHorizontal;
  secondRow2.spacing = 12;
  secondRow2.distribution = UIStackViewDistributionFillEqually;
  // StackView 需要启用交互，以便子视图（按钮）可以接收触摸事件
  secondRow2.userInteractionEnabled = YES;

  // 绿幕抠图按钮
  NSDictionary *greenScreenFeature = secondSectionFeatures[4];
  UIButton *greenScreenButton = [self createFeatureButton:greenScreenFeature];
  [secondRow2 addArrangedSubview:greenScreenButton];

  // 外部纹理按钮
  NSDictionary *externalTextureFeature = @{
    @"title" : @"外部纹理",
    @"selector" : @"externalTextureGridButtonTapped:",
    @"enabled" : @YES,
    @"iconName" : @"texture"
  };
  UIButton *externalTextureGridButton = [self createFeatureButton:externalTextureFeature];
  [secondRow2 addArrangedSubview:externalTextureGridButton];

  // 添加2个占位视图
  for (int i = 0; i < 2; i++) {
    UIView *placeholder = [[UIView alloc] init];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [secondRow2 addArrangedSubview:placeholder];
  }

  [secondSectionStack addArrangedSubview:secondRow2];

  [atomicCapabilitiesContainer addSubview:secondSectionStack];

  // 设置约束
  [NSLayoutConstraint activateConstraints:@[
    // 第一个网格容器（宽度和屏幕宽度一样）
    [self.gridContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                 constant:-35],
    [self.gridContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.gridContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

    // 第一个区域的网格（调整内部内容的位置，因为容器向上移动了，按钮向上移动 45 像素）
    [firstSectionStack.topAnchor constraintEqualToAnchor:self.gridContainer.topAnchor constant:59],
    [firstSectionStack.leadingAnchor constraintEqualToAnchor:self.gridContainer.leadingAnchor
                                                    constant:12],
    [firstSectionStack.trailingAnchor constraintEqualToAnchor:self.gridContainer.trailingAnchor
                                                     constant:-12],
    [firstSectionStack.bottomAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor
                                                   constant:-12],

    // 原子能力容器
    [atomicCapabilitiesContainer.topAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor],
    [atomicCapabilitiesContainer.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor],
    [atomicCapabilitiesContainer.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor],
    [atomicCapabilitiesContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor
                                                             constant:-20],

    // 原子能力标题
    [atomicTitleLabel.topAnchor constraintEqualToAnchor:atomicCapabilitiesContainer.topAnchor
                                               constant:8],
    [atomicTitleLabel.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:16],
    [atomicTitleLabel.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-16],

    // 第二个区域的网格
    [secondSectionStack.topAnchor constraintEqualToAnchor:atomicTitleLabel.bottomAnchor
                                                 constant:16],
    [secondSectionStack.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:16],
    [secondSectionStack.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-16],
    [secondSectionStack.bottomAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.bottomAnchor
                       constant:-24]
  ]];
}

- (UIButton *)createFeatureButton:(NSDictionary *)feature {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
  button.layer.cornerRadius = 12;
  // 确保按钮可以接收触摸事件
  button.userInteractionEnabled = YES;
  // enabled 状态会根据 feature 配置在后面设置

  // 确保按钮是正方形（宽高比 1:1）
  [button.widthAnchor constraintEqualToAnchor:button.heightAnchor].active = YES;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.spacing = 4;
  // StackView 不拦截触摸事件，让按钮接收
  stackView.userInteractionEnabled = NO;

  UIImageView *iconView = [[UIImageView alloc] init];
  // 从 Assets.xcassets 读取图标
  NSString *iconName = feature[@"iconName"];
  UIImage *iconImage = [UIImage imageNamed:iconName];
  if (!iconImage) {
    // 如果图标不存在，使用系统图标作为后备
    if (@available(iOS 13.0, *)) {
      // 根据图标名称选择不同的系统图标
      if ([iconName isEqualToString:@"texture"]) {
        // 外部纹理使用立方体图标
        iconImage = [UIImage systemImageNamed:@"cube"];
      } else {
        iconImage = [UIImage systemImageNamed:@"circle.fill"];
      }
    }
  }
  iconView.image = iconImage;
  iconView.tintColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  // 图标不拦截触摸事件
  iconView.userInteractionEnabled = NO;
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:22],
    [iconView.heightAnchor constraintEqualToConstant:22]
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = feature[@"title"];
  titleLabel.font = [UIFont systemFontOfSize:12];
  titleLabel.textColor = [UIColor colorWithRed:0.46 green:0.46 blue:0.46 alpha:1.0];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  // 标签不拦截触摸事件
  titleLabel.userInteractionEnabled = NO;

  [stackView addArrangedSubview:iconView];
  [stackView addArrangedSubview:titleLabel];

  [button addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
  ]];

  // 设置点击事件
  SEL selector = NSSelectorFromString(feature[@"selector"]);
  if (selector && [self respondsToSelector:selector]) {
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
  }

  // 根据 enabled 状态设置按钮状态
  BOOL enabled = [feature[@"enabled"] boolValue];
  button.enabled = enabled;

  // 不可用状态
  if (!enabled) {
    button.alpha = 0.5;
    // 添加 Soon 标签
    UILabel *soonLabel = [[UILabel alloc] init];
    soonLabel.text = @"Soon";
    soonLabel.font = [UIFont systemFontOfSize:8];
    soonLabel.textColor = [UIColor whiteColor];
    soonLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    soonLabel.layer.cornerRadius = 4;
    soonLabel.layer.masksToBounds = YES;
    soonLabel.textAlignment = NSTextAlignmentCenter;
    soonLabel.translatesAutoresizingMaskIntoConstraints = NO;
    // Soon 标签不拦截触摸事件
    soonLabel.userInteractionEnabled = NO;
    [button addSubview:soonLabel];
    [NSLayoutConstraint activateConstraints:@[
      [soonLabel.topAnchor constraintEqualToAnchor:button.topAnchor constant:2],
      [soonLabel.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-2],
      [soonLabel.widthAnchor constraintGreaterThanOrEqualToConstant:30],
      [soonLabel.heightAnchor constraintEqualToConstant:14]
    ]];
  }

  return button;
}

- (void)setupConstraints {
  [NSLayoutConstraint activateConstraints:@[
    [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
    [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
    [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
    [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

    // 直接约束到 view 顶部，实现全屏效果
    [self.headerImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.headerImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
    [self.headerImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    [self.headerImageView.heightAnchor constraintEqualToConstant:250]
  ]];
}

#pragma mark - Button Actions

- (void)beautyEffectButtonTapped:(UIButton *)sender {
  CameraViewController *cameraVC = [[CameraViewController alloc] init];

  if (self.navigationController) {
    [self.navigationController pushViewController:cameraVC animated:YES];
  } else {
    // 如果没有导航控制器，使用 present 方式
    UINavigationController *navVC =
        [[UINavigationController alloc] initWithRootViewController:cameraVC];
    navVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navVC animated:YES completion:nil];
  }
}

- (void)beautyTemplateButtonTapped:(UIButton *)sender {
  [self showToast:@"美颜模板功能开发中，敬请期待 ✨"];
}

- (void)beautyButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"beauty"];
}

- (void)reshapeButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"reshape"];
}

- (void)makeupButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"makeup"];
}

- (void)bodyButtonTapped:(UIButton *)sender {
  [self showToast:@"美体功能开发中，敬请期待 🏃"];
}

- (void)filterButtonTapped:(UIButton *)sender {
  // 滤镜功能暂时不可用，显示提示
  [self showToast:@"滤镜功能开发中，敬请期待 🎨"];
}

- (void)stickerButtonTapped:(UIButton *)sender {
  // 贴纸功能暂时不可用，显示提示
  [self showToast:@"贴纸功能开发中，敬请期待 ✨"];
}

- (void)virtualBgButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"virtual_bg"];
}

- (void)qualityButtonTapped:(UIButton *)sender {
  [self showToast:@"画质调整功能开发中，敬请期待 📸"];
}

- (void)faceDetectButtonTapped:(UIButton *)sender {
  // 人脸检测功能暂时不可用，显示提示
  [self showToast:@"人脸检测功能开发中，敬请期待 👤"];
}

- (void)hairColorButtonTapped:(UIButton *)sender {
  [self showToast:@"染发功能开发中，敬请期待 💇"];
}

- (void)styleButtonTapped:(UIButton *)sender {
  [self showToast:@"风格化功能开发中，敬请期待 🎭"];
}

- (void)gestureButtonTapped:(UIButton *)sender {
  [self showToast:@"手势识别功能开发中，敬请期待 👋"];
}

- (void)greenScreenButtonTapped:(UIButton *)sender {
  [self showToast:@"绿幕抠图功能开发中，敬请期待 🎬"];
}

- (void)externalTextureGridButtonTapped:(UIButton *)sender {
  ExternalTextureViewController *vc = [[ExternalTextureViewController alloc] init];
  if (self.navigationController) {
    [self.navigationController pushViewController:vc animated:YES];
  } else {
    // 如果没有导航控制器，使用 present 方式
    UINavigationController *navVC =
        [[UINavigationController alloc] initWithRootViewController:vc];
    navVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navVC animated:YES completion:nil];
  }
}

- (void)settingsButtonTapped:(UIButton *)sender {
  [self showToast:@"设置功能开发中，敬请期待 ⚙️"];
}

- (void)navigateToCamera:(NSString *)tab {
  CameraViewController *cameraVC = [[CameraViewController alloc] initWithInitialTab:tab];
  [self.navigationController pushViewController:cameraVC animated:YES];
}

- (void)showToast:(NSString *)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:alert
                     animated:YES
                   completion:^{
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                                    dispatch_get_main_queue(),
                                    ^{
                                      [alert dismissViewControllerAnimated:YES completion:nil];
                                    });
                   }];
}

@end
