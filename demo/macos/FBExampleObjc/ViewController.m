//
//  ViewController.m
//  FBExampleObjc
//

#import "ViewController.h"
#import "BeautyCameraViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property(nonatomic, strong) NSScrollView *scrollView;
@property(nonatomic, strong) NSView *contentView;
@property(nonatomic, strong) NSView *contentContainer;
@property(nonatomic, strong) NSImageView *headerImageView;
@property(nonatomic, strong) CAGradientLayer *beautyTemplateGradientLayer;
@property(nonatomic, strong) NSButton *beautyTemplateButton;
@property(nonatomic, strong) NSButton *beautyEffectButton;
@property(nonatomic, strong) NSView *gridContainer;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  if (@available(macOS 10.14, *)) {
    self.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }

  self.view.wantsLayer = YES;
  self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
  [self setupUI];
}

- (void)viewDidAppear {
  [super viewDidAppear];
}

- (void)viewDidLayout {
  [super viewDidLayout];
  if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
    [CATransaction commit];
  }
}

- (void)setupUI {
  self.scrollView = [[NSScrollView alloc] init];
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.hasVerticalScroller = YES;
  self.scrollView.hasHorizontalScroller = NO;
  self.scrollView.autohidesScrollers = YES;
  self.scrollView.scrollerStyle = NSScrollerStyleOverlay;
  if (@available(macOS 10.14, *)) {
    self.scrollView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  [self.view addSubview:self.scrollView];

  self.contentView = [[NSView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  if (@available(macOS 10.14, *)) {
    self.contentView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  self.scrollView.documentView = self.contentView;

  self.contentContainer = [[NSView alloc] init];
  self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
  if (@available(macOS 10.14, *)) {
    self.contentContainer.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }
  [self.contentView addSubview:self.contentContainer];

  [self setupHeaderImage];
  [self setupFeatureGrid];
  [self setupLargeButtons];
  [self setupConstraints];
}

- (void)setupHeaderImage {
  self.headerImageView = [[NSImageView alloc] init];
  self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.headerImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
  self.headerImageView.imageAlignment = NSImageAlignTop;
  NSImage *headerImage = [NSImage imageNamed:@"header"];
  if (headerImage) {
    self.headerImageView.image = headerImage;
  } else {
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

  NSButton *settingsButton = [[NSButton alloc] init];
  settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  settingsButton.buttonType = NSButtonTypeMomentaryPushIn;
  settingsButton.bezelStyle = NSBezelStyleTexturedRounded;
  settingsButton.bordered = NO;
  NSImage *settingsIcon = [NSImage imageNamed:@"setting"];
  if (!settingsIcon && @available(macOS 11.0, *)) {
    settingsIcon = [NSImage imageWithSystemSymbolName:@"gearshape"
                             accessibilityDescription:@"Settings"];
  }
  if (settingsIcon) {
    settingsIcon.size = NSMakeSize(22, 22);
    settingsIcon.template = YES;
    [settingsButton setImage:settingsIcon];
    if (@available(macOS 10.14, *)) {
      settingsButton.contentTintColor = [NSColor whiteColor];
    }
  }

  [settingsButton setTarget:self];
  [settingsButton setAction:@selector(settingsButtonTapped:)];
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
  NSView *largeButtonsContainer = [[NSView alloc] init];
  largeButtonsContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentContainer addSubview:largeButtonsContainer];

  NSImage *beautyEffectIcon = [NSImage imageNamed:@"camera2"];
  if (!beautyEffectIcon && @available(macOS 11.0, *)) {
    beautyEffectIcon = [NSImage imageWithSystemSymbolName:@"camera.fill"
                                 accessibilityDescription:@"Beauty Effect"];
  }
  self.beautyEffectButton = [self createLargeButtonWithTitle:NSLocalizedString(@"beauty_effect", nil)
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

  NSImage *beautyTemplateIcon = [NSImage imageNamed:@"beautycard3"];
  if (!beautyTemplateIcon && @available(macOS 11.0, *)) {
    beautyTemplateIcon = [NSImage imageWithSystemSymbolName:@"photo.fill"
                                   accessibilityDescription:@"Beauty Template"];
  }
  self.beautyTemplateButton = [self createLargeButtonWithTitle:NSLocalizedString(@"beauty_template", nil)
                                                          icon:beautyTemplateIcon
                                                     tintColor:[NSColor blackColor]
                                               backgroundColor:[NSColor clearColor]
                                                     textColor:nil];
  [self.beautyTemplateButton setTarget:self];
  [self.beautyTemplateButton setAction:@selector(beautyTemplateButtonTapped:)];

  self.beautyTemplateGradientLayer = [CAGradientLayer layer];
  self.beautyTemplateGradientLayer.colors = @[
    (id)[NSColor colorWithRed:0xCC / 255.0 green:0xFB / 255.0 blue:0x78 / 255.0 alpha:1.0].CGColor,
    (id)[NSColor colorWithRed:0x75 / 255.0 green:0xED / 255.0 blue:0xE0 / 255.0 alpha:1.0].CGColor
  ];
  self.beautyTemplateGradientLayer.startPoint = CGPointMake(0, 0);
  self.beautyTemplateGradientLayer.endPoint = CGPointMake(1, 0);
  self.beautyTemplateGradientLayer.cornerRadius = 12;
  self.beautyTemplateGradientLayer.actions = @{
    @"bounds" : [NSNull null],
    @"frame" : [NSNull null],
    @"position" : [NSNull null]
  };
  self.beautyTemplateButton.wantsLayer = YES;
  [self.beautyTemplateButton.layer insertSublayer:self.beautyTemplateGradientLayer atIndex:0];
  self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;

  [largeButtonsContainer addSubview:self.beautyTemplateButton];

  [NSLayoutConstraint activateConstraints:@[
    [largeButtonsContainer.centerXAnchor
        constraintEqualToAnchor:self.contentContainer.centerXAnchor],
    [largeButtonsContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                    constant:-75],
    [largeButtonsContainer.widthAnchor constraintEqualToConstant:452],
    [largeButtonsContainer.heightAnchor constraintEqualToConstant:72],
    [self.beautyEffectButton.topAnchor constraintEqualToAnchor:largeButtonsContainer.topAnchor],
    [self.beautyEffectButton.leadingAnchor
        constraintEqualToAnchor:largeButtonsContainer.leadingAnchor constant:20],
    [self.beautyEffectButton.heightAnchor constraintEqualToConstant:72],
    [self.beautyEffectButton.widthAnchor constraintEqualToConstant:200],
    [self.beautyTemplateButton.topAnchor constraintEqualToAnchor:self.beautyEffectButton.topAnchor],
    [self.beautyTemplateButton.leadingAnchor
        constraintEqualToAnchor:self.beautyEffectButton.trailingAnchor
                       constant:12],
    [self.beautyTemplateButton.heightAnchor constraintEqualToConstant:72],
    [self.beautyTemplateButton.widthAnchor constraintEqualToConstant:200]
  ]];
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
      [CATransaction commit];
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
  button.title = @"";
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
  static const CGFloat kButtonSpacing = 12.0;
  static const CGFloat kRowSpacing = 16.0;
  static const CGFloat kHorizontalPadding = 16.0;
  static const NSInteger kButtonsPerRow = 5;

  self.gridContainer = [[NSView alloc] init];
  self.gridContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.gridContainer.wantsLayer = YES;
  self.gridContainer.layer.backgroundColor = [NSColor whiteColor].CGColor;
  self.gridContainer.layer.cornerRadius = 24;
  [self.contentContainer addSubview:self.gridContainer];

  NSArray *firstSectionFeatures = @[
    @{@"title" : NSLocalizedString(@"beauty", nil), @"selector" : @"beautyButtonTapped:", @"enabled" : @YES, @"iconName" : @"meiyan"},
    @{@"title" : NSLocalizedString(@"reshape", nil), @"selector" : @"reshapeButtonTapped:", @"enabled" : @YES, @"iconName" : @"meixing2"},
    @{@"title" : NSLocalizedString(@"makeup", nil), @"selector" : @"makeupButtonTapped:", @"enabled" : @YES, @"iconName" : @"meizhuang"},
    @{@"title" : NSLocalizedString(@"filter", nil), @"selector" : @"filterButtonTapped:", @"enabled" : @YES, @"iconName" : @"lvjing"},
    @{@"title" : NSLocalizedString(@"sticker", nil), @"selector" : @"stickerButtonTapped:", @"enabled" : @YES, @"iconName" : @"tiezhi2"},
    @{@"title" : NSLocalizedString(@"virtual_bg", nil), @"selector" : @"virtualBgButtonTapped:", @"enabled" : @YES, @"iconName" : @"xunibeijing"},
    @{@"title" : NSLocalizedString(@"body", nil), @"selector" : @"bodyButtonTapped:", @"enabled" : @NO, @"iconName" : @"meiti"},
    @{@"title" : NSLocalizedString(@"quality", nil), @"selector" : @"qualityButtonTapped:", @"enabled" : @NO, @"iconName" : @"huazhitiaozheng2"}
  ];

  NSStackView *firstSectionStack = [self createButtonGridWithFeatures:firstSectionFeatures
                                                        buttonsPerRow:kButtonsPerRow
                                                        buttonSpacing:kButtonSpacing
                                                           rowSpacing:kRowSpacing];
  [self.gridContainer addSubview:firstSectionStack];

  NSView *atomicCapabilitiesContainer = [[NSView alloc] init];
  atomicCapabilitiesContainer.translatesAutoresizingMaskIntoConstraints = NO;
  atomicCapabilitiesContainer.wantsLayer = YES;
  atomicCapabilitiesContainer.layer.backgroundColor = [NSColor whiteColor].CGColor;
  [self.contentContainer addSubview:atomicCapabilitiesContainer];

  NSTextField *atomicTitleLabel = [[NSTextField alloc] init];
  atomicTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  atomicTitleLabel.stringValue = NSLocalizedString(@"more_effects", nil);
  atomicTitleLabel.font = [NSFont boldSystemFontOfSize:18];
  atomicTitleLabel.textColor = [NSColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  atomicTitleLabel.editable = NO;
  atomicTitleLabel.bordered = NO;
  atomicTitleLabel.backgroundColor = [NSColor clearColor];
  [atomicCapabilitiesContainer addSubview:atomicTitleLabel];

  NSArray *secondSectionFeatures = @[
    @{@"title" : NSLocalizedString(@"face_detect", nil), @"selector" : @"faceDetectButtonTapped:", @"enabled" : @YES, @"iconName" : @"renlianjiance"},
    @{@"title" : NSLocalizedString(@"hair_color", nil), @"selector" : @"hairColorButtonTapped:", @"enabled" : @NO, @"iconName" : @"huanfase"},
    @{@"title" : NSLocalizedString(@"style_makeover", nil), @"selector" : @"styleButtonTapped:", @"enabled" : @NO, @"iconName" : @"fengge"},
    @{@"title" : NSLocalizedString(@"gesture", nil), @"selector" : @"gestureButtonTapped:", @"enabled" : @NO, @"iconName" : @"shoushi"},
    @{@"title" : NSLocalizedString(@"green_screen", nil), @"selector" : @"greenScreenButtonTapped:", @"enabled" : @NO, @"iconName" : @"lvmukoutu"}
  ];

  NSStackView *secondSectionStack = [self createButtonGridWithFeatures:secondSectionFeatures
                                                         buttonsPerRow:kButtonsPerRow
                                                         buttonSpacing:kButtonSpacing
                                                            rowSpacing:kRowSpacing];
  [atomicCapabilitiesContainer addSubview:secondSectionStack];

  [NSLayoutConstraint activateConstraints:@[
    [self.gridContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                 constant:-35],
    [self.gridContainer.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
    [self.gridContainer.trailingAnchor
        constraintEqualToAnchor:self.contentContainer.trailingAnchor],
    [firstSectionStack.topAnchor constraintEqualToAnchor:self.gridContainer.topAnchor constant:59],
    [firstSectionStack.leadingAnchor constraintEqualToAnchor:self.gridContainer.leadingAnchor
                                                    constant:kHorizontalPadding],
    [firstSectionStack.trailingAnchor constraintEqualToAnchor:self.gridContainer.trailingAnchor
                                                     constant:-kHorizontalPadding],
    [firstSectionStack.bottomAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor
                                                   constant:-12],
    [atomicCapabilitiesContainer.topAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor],
    [atomicCapabilitiesContainer.leadingAnchor
        constraintEqualToAnchor:self.contentContainer.leadingAnchor],
    [atomicCapabilitiesContainer.trailingAnchor
        constraintEqualToAnchor:self.contentContainer.trailingAnchor],
    [atomicCapabilitiesContainer.bottomAnchor
        constraintEqualToAnchor:self.contentContainer.bottomAnchor
                       constant:-20],
    [atomicTitleLabel.topAnchor constraintEqualToAnchor:atomicCapabilitiesContainer.topAnchor
                                               constant:8],
    [atomicTitleLabel.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:kHorizontalPadding],
    [atomicTitleLabel.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-kHorizontalPadding],
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
  button.title = @"";
  button.wantsLayer = YES;
  button.layer.backgroundColor = [NSColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0].CGColor;
  button.layer.cornerRadius = 12;

  NSLayoutConstraint *widthConstraint = [button.widthAnchor constraintEqualToConstant:80];
  widthConstraint.priority = NSLayoutPriorityRequired;
  widthConstraint.active = YES;
  NSLayoutConstraint *heightConstraint = [button.heightAnchor constraintEqualToConstant:80];
  heightConstraint.priority = NSLayoutPriorityRequired;
  heightConstraint.active = YES;

  NSStackView *stackView = [[NSStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
  stackView.alignment = NSLayoutAttributeCenterX;
  stackView.distribution = NSStackViewDistributionFill;
  stackView.spacing = 6;

  NSImageView *iconView = [[NSImageView alloc] init];
  NSString *iconName = feature[@"iconName"];
  NSImage *iconImage = [NSImage imageNamed:iconName];
  if (!iconImage && @available(macOS 11.0, *)) {
    iconImage = [NSImage imageWithSystemSymbolName:@"circle.fill" accessibilityDescription:nil];
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
  [titleLabel setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                       forOrientation:NSLayoutConstraintOrientationVertical];
  NSLayoutConstraint *minHeightConstraint =
      [titleLabel.heightAnchor constraintGreaterThanOrEqualToConstant:16];
  minHeightConstraint.active = YES;

  [stackView addArrangedSubview:iconView];
  [stackView addArrangedSubview:titleLabel];
  [button addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
    [stackView.topAnchor constraintGreaterThanOrEqualToAnchor:button.topAnchor constant:8],
    [stackView.bottomAnchor constraintLessThanOrEqualToAnchor:button.bottomAnchor constant:-8],
    [stackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:button.leadingAnchor constant:4],
    [stackView.trailingAnchor constraintLessThanOrEqualToAnchor:button.trailingAnchor constant:-4]
  ]];

  SEL selector = NSSelectorFromString(feature[@"selector"]);
  if (selector && [self respondsToSelector:selector]) {
    [button setTarget:self];
    [button setAction:selector];
  }
  BOOL enabled = [feature[@"enabled"] boolValue];
  button.enabled = enabled;
  if (!enabled) {
    button.alphaValue = 0.5;
    NSTextField *soonLabel = [[NSTextField alloc] init];
    soonLabel.stringValue = @"Soon";
    soonLabel.font = [NSFont systemFontOfSize:8];
    soonLabel.textColor = [NSColor whiteColor];
    soonLabel.wantsLayer = YES;
    soonLabel.layer.backgroundColor =
        [NSColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0].CGColor;
    soonLabel.layer.cornerRadius = 4;
    soonLabel.layer.masksToBounds = YES;
    soonLabel.editable = NO;
    soonLabel.bordered = NO;
    soonLabel.backgroundColor = [NSColor clearColor];
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
    [self.contentContainer.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.contentContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.contentContainer.widthAnchor constraintEqualToConstant:kContentWidth],
    [self.headerImageView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
    [self.headerImageView.centerXAnchor
        constraintEqualToAnchor:self.contentContainer.centerXAnchor],
    [self.headerImageView.widthAnchor constraintEqualToConstant:452],
    [self.headerImageView.heightAnchor constraintEqualToConstant:200]
  ]];
}

#pragma mark - Button Actions

- (void)beautyEffectButtonTapped:(NSButton *)sender {
  BeautyCameraViewController *cameraVC = [[BeautyCameraViewController alloc] init];
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
  BeautyCameraViewController *cameraVC = [[BeautyCameraViewController alloc] init];
  if (self.view.window) {
    self.view.window.contentViewController = cameraVC;
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
