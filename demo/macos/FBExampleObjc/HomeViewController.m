//
//  HomeViewController.m
//  FBExampleObjc
//
//  Created for macOS version - Single column wide grid layout
//

#import "HomeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"

@interface HomeViewController ()

@property(nonatomic, strong) NSScrollView *scrollView;
@property(nonatomic, strong) NSView *contentView;
@property(nonatomic, strong) NSView *contentContainer;
@property(nonatomic, strong) NSImageView *headerImageView;
@property(nonatomic, strong) CAGradientLayer *beautyTemplateGradientLayer;
@property(nonatomic, strong) NSButton *beautyTemplateButton;
@property(nonatomic, strong) NSButton *beautyEffectButton;
@property(nonatomic, strong) NSView *gridContainer;

@end

@implementation HomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // 强制使用浅色模式，不响应系统暗黑模式
  if (@available(macOS 10.14, *)) {
    self.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }

  self.view.wantsLayer = YES;
  self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
  [self setupUI];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  // 在视图显示后，确保窗口大小为 600x600
  // 使用 dispatch_async 避免在布局过程中修改窗口大小
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.view.window) {
      NSSize currentContentSize = self.view.window.contentView.bounds.size;
      if (fabs(currentContentSize.width - 600) > 1 || fabs(currentContentSize.height - 600) > 1) {
        [self.view.window setContentSize:NSMakeSize(600, 600)];
      }
    }
  });
}

- (void)viewDidLayout {
  [super viewDidLayout];
  // 更新渐变图层的大小
  if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
    self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
  }

  // 注意：不要在 viewDidLayout 中修改窗口大小，会导致布局循环
  // 窗口大小应该在 AppDelegate 中通过 NSWindowDelegate 方法控制
}

- (void)setupUI {
  // 创建滚动视图
  self.scrollView = [[NSScrollView alloc] init];
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.hasVerticalScroller = YES;
  self.scrollView.hasHorizontalScroller = NO;  // 禁用水平滚动，因为内容已居中
  self.scrollView.autohidesScrollers = YES;
  self.scrollView.scrollerStyle = NSScrollerStyleOverlay;
  // 强制使用浅色模式
  if (@available(macOS 10.14, *)) {
    self.scrollView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  [self.view addSubview:self.scrollView];

  self.contentView = [[NSView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  // 强制使用浅色模式
  if (@available(macOS 10.14, *)) {
    self.contentView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  self.scrollView.documentView = self.contentView;

  // 创建居中容器（固定宽度为实际内容宽度 452pt）
  self.contentContainer = [[NSView alloc] init];
  self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
  // 强制使用浅色模式
  if (@available(macOS 10.14, *)) {
    self.contentContainer.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  [self.contentView addSubview:self.contentContainer];

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
  self.headerImageView = [[NSImageView alloc] init];
  self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.headerImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
  self.headerImageView.imageAlignment = NSImageAlignTop;

  // 从 Assets.xcassets 读取 header 图片
  NSImage *headerImage = [NSImage imageNamed:@"header"];
  if (headerImage) {
    self.headerImageView.image = headerImage;
  } else {
    // 如果图标不存在，使用渐变背景作为后备
    self.headerImageView.wantsLayer = YES;
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
      (id)[NSColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0].CGColor,
      (id)[NSColor colorWithRed:0.3 green:0.5 blue:0.7 alpha:1.0].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    self.headerImageView.layer = gradientLayer;
  }
  [self.contentContainer addSubview:self.headerImageView];

  // 设置按钮（背景图片右上角）
  NSButton *settingsButton = [[NSButton alloc] init];
  settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  settingsButton.buttonType = NSButtonTypeMomentaryPushIn;
  settingsButton.bezelStyle = NSBezelStyleTexturedRounded;
  settingsButton.bordered = NO;

  NSImage *settingsIcon = [NSImage imageNamed:@"setting"];
  if (!settingsIcon) {
    // 使用系统图标作为后备
    if (@available(macOS 11.0, *)) {
      settingsIcon = [NSImage imageWithSystemSymbolName:@"gearshape"
                               accessibilityDescription:@"Settings"];
    }
  }
  if (settingsIcon) {
    settingsIcon.size = NSMakeSize(22, 22);
    settingsIcon.template = YES;
    [settingsButton setImage:settingsIcon];
    // 设置图标颜色为白色
    if (@available(macOS 10.14, *)) {
      settingsButton.contentTintColor = [NSColor whiteColor];
    }
  }

  [settingsButton setTarget:self];
  [settingsButton setAction:@selector(settingsButtonTapped:)];
  // 添加到 headerImageView 上，确保显示在背景图片上层
  [self.headerImageView addSubview:settingsButton];

  [NSLayoutConstraint activateConstraints:@[
    [settingsButton.topAnchor constraintEqualToAnchor:self.headerImageView.topAnchor constant:16],
    [settingsButton.trailingAnchor constraintEqualToAnchor:self.headerImageView.trailingAnchor
                                                  constant:-16],
    [settingsButton.widthAnchor constraintEqualToConstant:22],
    [settingsButton.heightAnchor constraintEqualToConstant:22]
  ]];
}

- (void)setupLargeButtons {
  // 创建大按钮容器，用于居中两个按钮
  NSView *largeButtonsContainer = [[NSView alloc] init];
  largeButtonsContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentContainer addSubview:largeButtonsContainer];

  // 美颜特效按钮
  NSImage *beautyEffectIcon = [NSImage imageNamed:@"camera2"];
  if (!beautyEffectIcon) {
    if (@available(macOS 11.0, *)) {
      beautyEffectIcon = [NSImage imageWithSystemSymbolName:@"camera.fill"
                                   accessibilityDescription:@"Beauty Effect"];
    }
  }
  self.beautyEffectButton = [self createLargeButtonWithTitle:@"美颜特效"
                                                        icon:beautyEffectIcon
                                                   tintColor:[NSColor colorWithRed:0xA0 / 255.0
                                                                             green:0xF1 / 255.0
                                                                              blue:0x96 / 255.0
                                                                             alpha:1.0]
                                             backgroundColor:[NSColor colorWithRed:0x33 / 255.0
                                                                             green:0x33 / 255.0
                                                                              blue:0x33 / 255.0
                                                                             alpha:1.0]
                                                   textColor:[NSColor whiteColor]];
  [self.beautyEffectButton setTarget:self];
  [self.beautyEffectButton setAction:@selector(beautyEffectButtonTapped:)];
  [largeButtonsContainer addSubview:self.beautyEffectButton];

  // 美颜模板按钮
  NSImage *beautyTemplateIcon = [NSImage imageNamed:@"beautycard3"];
  if (!beautyTemplateIcon) {
    if (@available(macOS 11.0, *)) {
      beautyTemplateIcon = [NSImage imageWithSystemSymbolName:@"photo.fill"
                                     accessibilityDescription:@"Beauty Template"];
    }
  }
  self.beautyTemplateButton = [self createLargeButtonWithTitle:@"美颜模板"
                                                          icon:beautyTemplateIcon
                                                     tintColor:[NSColor blackColor]
                                               backgroundColor:[NSColor clearColor]
                                                     textColor:nil];
  [self.beautyTemplateButton setTarget:self];
  [self.beautyTemplateButton setAction:@selector(beautyTemplateButtonTapped:)];

  // 创建渐变背景图层
  self.beautyTemplateGradientLayer = [CAGradientLayer layer];
  self.beautyTemplateGradientLayer.colors = @[
    (id)[NSColor colorWithRed:0xCC / 255.0 green:0xFB / 255.0 blue:0x78 / 255.0 alpha:1.0].CGColor,
    (id)[NSColor colorWithRed:0x75 / 255.0 green:0xED / 255.0 blue:0xE0 / 255.0 alpha:1.0].CGColor
  ];
  self.beautyTemplateGradientLayer.startPoint = CGPointMake(0, 0);
  self.beautyTemplateGradientLayer.endPoint = CGPointMake(1, 0);
  self.beautyTemplateGradientLayer.cornerRadius = 12;
  // 确保按钮已启用 layer 支持
  self.beautyTemplateButton.wantsLayer = YES;
  // 插入渐变图层到最底层
  [self.beautyTemplateButton.layer insertSublayer:self.beautyTemplateGradientLayer atIndex:0];
  // 初始设置渐变图层大小（会在 viewDidLayout 中更新）
  self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;

  [largeButtonsContainer addSubview:self.beautyTemplateButton];

  [NSLayoutConstraint activateConstraints:@[
    // 大按钮容器：固定宽度（20 + 200 + 12 + 200 + 20 = 452pt），水平居中
    [largeButtonsContainer.centerXAnchor
        constraintEqualToAnchor:self.contentContainer.centerXAnchor],
    [largeButtonsContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                    constant:-75],
    [largeButtonsContainer.widthAnchor constraintEqualToConstant:452],
    [largeButtonsContainer.heightAnchor constraintEqualToConstant:72],

    // 美颜特效按钮
    [self.beautyEffectButton.topAnchor constraintEqualToAnchor:largeButtonsContainer.topAnchor],
    [self.beautyEffectButton.leadingAnchor
        constraintEqualToAnchor:largeButtonsContainer.leadingAnchor
                       constant:20],
    [self.beautyEffectButton.heightAnchor constraintEqualToConstant:72],
    [self.beautyEffectButton.widthAnchor constraintEqualToConstant:200],

    // 美颜模板按钮
    [self.beautyTemplateButton.topAnchor constraintEqualToAnchor:self.beautyEffectButton.topAnchor],
    [self.beautyTemplateButton.leadingAnchor
        constraintEqualToAnchor:self.beautyEffectButton.trailingAnchor
                       constant:12],
    [self.beautyTemplateButton.heightAnchor constraintEqualToConstant:72],
    [self.beautyTemplateButton.widthAnchor constraintEqualToConstant:200]
  ]];

  // 延迟更新渐变图层大小，确保在布局完成后更新
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
      self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
    }
  });
}

- (NSButton *)createLargeButtonWithTitle:(NSString *)title
                                    icon:(NSImage *)icon
                               tintColor:(NSColor *)tintColor
                         backgroundColor:(NSColor *)backgroundColor
                               textColor:(NSColor *)textColor {
  NSButton *button = [[NSButton alloc] init];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.buttonType = NSButtonTypeMomentaryPushIn;
  button.bezelStyle = NSBezelStyleTexturedRounded;
  button.bordered = NO;
  button.title = @"";  // 覆盖默认按钮文字
  button.wantsLayer = YES;
  button.layer.backgroundColor = backgroundColor.CGColor;
  button.layer.cornerRadius = 12;

  NSStackView *stackView = [[NSStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  stackView.alignment = NSLayoutAttributeCenterY;
  stackView.spacing = 12;

  NSImageView *iconView = [[NSImageView alloc] init];
  if (icon) {
    icon.size = NSMakeSize(28, 28);
    icon.template = YES;
    iconView.image = icon;
    iconView.contentTintColor = tintColor;
  }
  iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:28],
    [iconView.heightAnchor constraintEqualToConstant:28]
  ]];

  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = title;
  titleLabel.font = [NSFont boldSystemFontOfSize:18];
  titleLabel.textColor = textColor ? textColor : tintColor;
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  titleLabel.alignment = NSTextAlignmentCenter;

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
  // 布局常量
  static const CGFloat kButtonSpacing = 12.0;
  static const CGFloat kRowSpacing = 16.0;
  static const CGFloat kHorizontalPadding = 16.0;
  static const NSInteger kButtonsPerRow = 5;

  // 第一个网格容器（白色背景，带圆角）
  self.gridContainer = [[NSView alloc] init];
  self.gridContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.gridContainer.wantsLayer = YES;
  self.gridContainer.layer.backgroundColor = [NSColor whiteColor].CGColor;
  self.gridContainer.layer.cornerRadius = 24;
  [self.contentContainer addSubview:self.gridContainer];

  // 第一个区域：8个功能按钮
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

  NSStackView *firstSectionStack = [self createButtonGridWithFeatures:firstSectionFeatures
                                                        buttonsPerRow:kButtonsPerRow
                                                        buttonSpacing:kButtonSpacing
                                                           rowSpacing:kRowSpacing];
  [self.gridContainer addSubview:firstSectionStack];

  // 原子能力区域容器
  NSView *atomicCapabilitiesContainer = [[NSView alloc] init];
  atomicCapabilitiesContainer.translatesAutoresizingMaskIntoConstraints = NO;
  atomicCapabilitiesContainer.wantsLayer = YES;
  atomicCapabilitiesContainer.layer.backgroundColor = [NSColor whiteColor].CGColor;
  [self.contentContainer addSubview:atomicCapabilitiesContainer];

  // "原子能力"标题
  NSTextField *atomicTitleLabel = [[NSTextField alloc] init];
  atomicTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  atomicTitleLabel.stringValue = @"原子能力";
  atomicTitleLabel.font = [NSFont boldSystemFontOfSize:18];
  atomicTitleLabel.textColor = [NSColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  atomicTitleLabel.editable = NO;
  atomicTitleLabel.bordered = NO;
  atomicTitleLabel.backgroundColor = [NSColor clearColor];
  [atomicCapabilitiesContainer addSubview:atomicTitleLabel];

  // 第二个区域：原子能力按钮
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

  NSStackView *secondSectionStack = [self createButtonGridWithFeatures:secondSectionFeatures
                                                         buttonsPerRow:kButtonsPerRow
                                                         buttonSpacing:kButtonSpacing
                                                            rowSpacing:kRowSpacing];
  [atomicCapabilitiesContainer addSubview:secondSectionStack];

  // 设置约束
  [NSLayoutConstraint activateConstraints:@[
    // 第一个网格容器
    [self.gridContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                 constant:-35],
    [self.gridContainer.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
    [self.gridContainer.trailingAnchor
        constraintEqualToAnchor:self.contentContainer.trailingAnchor],

    // 第一个区域的网格
    [firstSectionStack.topAnchor constraintEqualToAnchor:self.gridContainer.topAnchor constant:59],
    [firstSectionStack.leadingAnchor constraintEqualToAnchor:self.gridContainer.leadingAnchor
                                                    constant:kHorizontalPadding],
    [firstSectionStack.trailingAnchor constraintEqualToAnchor:self.gridContainer.trailingAnchor
                                                     constant:-kHorizontalPadding],
    [firstSectionStack.bottomAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor
                                                   constant:-12],

    // 原子能力容器
    [atomicCapabilitiesContainer.topAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor],
    [atomicCapabilitiesContainer.leadingAnchor
        constraintEqualToAnchor:self.contentContainer.leadingAnchor],
    [atomicCapabilitiesContainer.trailingAnchor
        constraintEqualToAnchor:self.contentContainer.trailingAnchor],
    [atomicCapabilitiesContainer.bottomAnchor
        constraintEqualToAnchor:self.contentContainer.bottomAnchor
                       constant:-20],

    // 原子能力标题
    [atomicTitleLabel.topAnchor constraintEqualToAnchor:atomicCapabilitiesContainer.topAnchor
                                               constant:8],
    [atomicTitleLabel.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:kHorizontalPadding],
    [atomicTitleLabel.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-kHorizontalPadding],

    // 第二个区域的网格（使用与标题相同的间距，与第一区域的行间距一致）
    [secondSectionStack.topAnchor constraintEqualToAnchor:atomicTitleLabel.bottomAnchor
                                                 constant:kRowSpacing],
    [secondSectionStack.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:kHorizontalPadding],
    [secondSectionStack.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-kHorizontalPadding],
    [secondSectionStack.bottomAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.bottomAnchor
                       constant:-24]
  ]];
}

- (NSStackView *)createButtonGridWithFeatures:(NSArray *)features
                                buttonsPerRow:(NSInteger)buttonsPerRow
                                buttonSpacing:(CGFloat)buttonSpacing
                                   rowSpacing:(CGFloat)rowSpacing {
  NSStackView *verticalStack = [[NSStackView alloc] init];
  verticalStack.translatesAutoresizingMaskIntoConstraints = NO;
  verticalStack.orientation = NSUserInterfaceLayoutOrientationVertical;
  verticalStack.spacing = rowSpacing;
  verticalStack.distribution = NSStackViewDistributionFill;
  verticalStack.alignment = NSLayoutAttributeLeading;

  NSInteger totalButtons = features.count;
  for (NSInteger i = 0; i < totalButtons; i += buttonsPerRow) {
    NSStackView *rowStack = [[NSStackView alloc] init];
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    rowStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    rowStack.spacing = buttonSpacing;
    rowStack.distribution = NSStackViewDistributionFill;
    rowStack.alignment = NSLayoutAttributeCenterY;

    NSInteger endIndex = MIN(i + buttonsPerRow, totalButtons);
    for (NSInteger j = i; j < endIndex; j++) {
      NSDictionary *feature = features[j];
      NSButton *button = [self createFeatureButton:feature];
      [rowStack addArrangedSubview:button];
    }

    [verticalStack addArrangedSubview:rowStack];
  }

  return verticalStack;
}

- (NSButton *)createFeatureButton:(NSDictionary *)feature {
  NSButton *button = [[NSButton alloc] init];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.buttonType = NSButtonTypeMomentaryPushIn;
  button.bezelStyle = NSBezelStyleTexturedRounded;
  button.bordered = NO;
  // 清除按钮的默认 title，避免显示 "Button" 文字
  button.title = @"";
  button.wantsLayer = YES;
  button.layer.backgroundColor = [NSColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0].CGColor;
  button.layer.cornerRadius = 12;

  // 确保按钮是正方形，并设置固定宽度（与第一行按钮保持一致的大小）
  // 按钮宽度固定为 80pt，这样所有按钮大小一致
  NSLayoutConstraint *widthConstraint = [button.widthAnchor constraintEqualToConstant:80];
  widthConstraint.priority = NSLayoutPriorityRequired;  // 设置最高优先级，防止被 StackView 拉伸
  widthConstraint.active = YES;
  NSLayoutConstraint *heightConstraint = [button.heightAnchor constraintEqualToConstant:80];
  heightConstraint.priority = NSLayoutPriorityRequired;  // 设置最高优先级
  heightConstraint.active = YES;

  NSStackView *stackView = [[NSStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
  stackView.alignment = NSLayoutAttributeCenterX;
  stackView.distribution = NSStackViewDistributionFill;
  stackView.spacing = 6;  // 增加间距，确保图标和文字不重叠

  NSImageView *iconView = [[NSImageView alloc] init];
  NSString *iconName = feature[@"iconName"];
  NSImage *iconImage = [NSImage imageNamed:iconName];
  if (!iconImage) {
    // 如果图标不存在，使用系统图标作为后备
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:@"circle.fill" accessibilityDescription:nil];
    }
  }
  if (iconImage) {
    iconImage.size = NSMakeSize(22, 22);
    iconView.image = iconImage;
    iconView.contentTintColor = [NSColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  }
  iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:22],
    [iconView.heightAnchor constraintEqualToConstant:22]
  ]];

  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = feature[@"title"];
  titleLabel.font = [NSFont systemFontOfSize:12];
  titleLabel.textColor = [NSColor colorWithRed:0.46 green:0.46 blue:0.46 alpha:1.0];
  titleLabel.alignment = NSTextAlignmentCenter;
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  // 设置文字字段的内容压缩阻力，防止被压缩
  [titleLabel setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                       forOrientation:NSLayoutConstraintOrientationVertical];
  // 设置最小高度，确保文字有足够空间
  NSLayoutConstraint *minHeightConstraint =
      [titleLabel.heightAnchor constraintGreaterThanOrEqualToConstant:16];
  minHeightConstraint.active = YES;

  [stackView addArrangedSubview:iconView];
  [stackView addArrangedSubview:titleLabel];

  [button addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  // 设置 StackView 的边距，确保图标和文字有足够空间，不会重叠
  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
    // 设置上下边距，确保内容不会紧贴按钮边缘
    [stackView.topAnchor constraintGreaterThanOrEqualToAnchor:button.topAnchor constant:8],
    [stackView.bottomAnchor constraintLessThanOrEqualToAnchor:button.bottomAnchor constant:-8],
    // 设置左右边距
    [stackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:button.leadingAnchor constant:4],
    [stackView.trailingAnchor constraintLessThanOrEqualToAnchor:button.trailingAnchor constant:-4]
  ]];

  // 设置点击事件
  SEL selector = NSSelectorFromString(feature[@"selector"]);
  if (selector && [self respondsToSelector:selector]) {
    [button setTarget:self];
    [button setAction:selector];
  }

  // 根据 enabled 状态设置按钮状态
  BOOL enabled = [feature[@"enabled"] boolValue];
  button.enabled = enabled;

  // 不可用状态
  if (!enabled) {
    button.alphaValue = 0.5;
    // 添加 Soon 标签
    NSTextField *soonLabel = [[NSTextField alloc] init];
    soonLabel.stringValue = @"Soon";
    soonLabel.font = [NSFont systemFontOfSize:8];
    soonLabel.textColor = [NSColor whiteColor];
    soonLabel.wantsLayer = YES;
    soonLabel.layer.backgroundColor =
        [NSColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0].CGColor;
    soonLabel.layer.cornerRadius = 4;
    soonLabel.layer.masksToBounds = YES;  // 确保圆角显示
    soonLabel.editable = NO;
    soonLabel.bordered = NO;
    soonLabel.backgroundColor = [NSColor clearColor];  // 设置背景为透明，让 layer 背景色显示
    soonLabel.alignment = NSTextAlignmentCenter;
    soonLabel.translatesAutoresizingMaskIntoConstraints = NO;
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
  static const CGFloat kContentWidth = 480.0;

  [NSLayoutConstraint activateConstraints:@[
    [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentView.topAnchor],
    [self.contentView.leadingAnchor
        constraintEqualToAnchor:self.scrollView.contentView.leadingAnchor],
    [self.contentView.trailingAnchor
        constraintEqualToAnchor:self.scrollView.contentView.trailingAnchor],
    [self.contentView.bottomAnchor
        constraintEqualToAnchor:self.scrollView.contentView.bottomAnchor],
    [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

    // 内容容器：固定宽度，水平居中
    [self.contentContainer.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.contentContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.contentContainer.widthAnchor constraintEqualToConstant:kContentWidth],

    // Header 区域（宽度与两个大按钮的总宽度一致，水平居中）
    [self.headerImageView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
    [self.headerImageView.centerXAnchor
        constraintEqualToAnchor:self.contentContainer.centerXAnchor],
    [self.headerImageView.widthAnchor constraintEqualToConstant:452],
    [self.headerImageView.heightAnchor constraintEqualToConstant:200]
  ]];
}

#pragma mark - Button Actions

- (void)beautyEffectButtonTapped:(NSButton *)sender {
  ViewController *cameraVC = [[ViewController alloc] init];

  // macOS 替换窗口内容
  if (self.view.window) {
    self.view.window.contentViewController = cameraVC;
  }
}

- (void)beautyTemplateButtonTapped:(NSButton *)sender {
  [self showToast:@"美颜模板功能开发中，敬请期待 ✨"];
}

- (void)beautyButtonTapped:(NSButton *)sender {
  [self navigateToCamera:@"beauty"];
}

- (void)reshapeButtonTapped:(NSButton *)sender {
  [self navigateToCamera:@"reshape"];
}

- (void)makeupButtonTapped:(NSButton *)sender {
  [self navigateToCamera:@"makeup"];
}

- (void)bodyButtonTapped:(NSButton *)sender {
  [self showToast:@"美体功能开发中，敬请期待 🏃"];
}

- (void)filterButtonTapped:(NSButton *)sender {
  [self showToast:@"滤镜功能开发中，敬请期待 🎨"];
}

- (void)stickerButtonTapped:(NSButton *)sender {
  [self showToast:@"贴纸功能开发中，敬请期待 ✨"];
}

- (void)virtualBgButtonTapped:(NSButton *)sender {
  [self navigateToCamera:@"virtual_bg"];
}

- (void)qualityButtonTapped:(NSButton *)sender {
  [self showToast:@"画质调整功能开发中，敬请期待 📸"];
}

- (void)faceDetectButtonTapped:(NSButton *)sender {
  [self showToast:@"人脸检测功能开发中，敬请期待 👤"];
}

- (void)hairColorButtonTapped:(NSButton *)sender {
  [self showToast:@"染发功能开发中，敬请期待 💇"];
}

- (void)styleButtonTapped:(NSButton *)sender {
  [self showToast:@"风格化功能开发中，敬请期待 🎭"];
}

- (void)gestureButtonTapped:(NSButton *)sender {
  [self showToast:@"手势识别功能开发中，敬请期待 👋"];
}

- (void)greenScreenButtonTapped:(NSButton *)sender {
  [self showToast:@"绿幕抠图功能开发中，敬请期待 🎬"];
}

- (void)settingsButtonTapped:(NSButton *)sender {
  [self showToast:@"设置功能开发中，敬请期待 ⚙️"];
}

- (void)navigateToCamera:(NSString *)tab {
  ViewController *cameraVC = [[ViewController alloc] init];

  // macOS 替换窗口内容
  if (self.view.window) {
    self.view.window.contentViewController = cameraVC;

    // TODO: 传递 initialTab 参数到 ViewController
    // 需要在 ViewController 中添加 initWithInitialTab 方法
  }
}

- (void)showToast:(NSString *)message {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = message;
  alert.alertStyle = NSAlertStyleInformational;
  [alert addButtonWithTitle:@"确定"];
  [alert runModal];
}

@end
