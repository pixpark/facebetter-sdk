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
  // Extend view beyond safe area to achieve full-screen effect (must be set after setupUI)
  if (@available(iOS 11.0, *)) {
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  } else {
// Use deprecated method for iOS 11.0 and below
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Update gradient layer size to match button size
  if (self.beautyTemplateGradientLayer && self.beautyTemplateButton) {
    self.beautyTemplateGradientLayer.frame = self.beautyTemplateButton.bounds;
  }

  // Ensure buttons are always on top of view hierarchy
  if (self.beautyEffectButton) {
    [self.view bringSubviewToFront:self.beautyEffectButton];
  }
  if (self.beautyTemplateButton) {
    [self.view bringSubviewToFront:self.beautyTemplateButton];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // Ensure buttons are on top of view hierarchy and can receive touch events
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
  // Create scroll view
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  [self.view addSubview:self.scrollView];

  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.scrollView addSubview:self.contentView];

  // Top image area
  [self setupHeaderImage];

  // Feature grid (add first to ensure it's below buttons)
  [self setupFeatureGrid];

  // Two large buttons (add last to ensure displayed on top)
  [self setupLargeButtons];

  // Constraints
  [self setupConstraints];
}

- (void)setupHeaderImage {
  self.headerImageView = [[UIImageView alloc] init];
  self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.headerImageView.clipsToBounds = YES;
  // Read header image from Assets.xcassets, corresponding to Android's header
  UIImage *headerImage = [UIImage imageNamed:@"header"];
  if (headerImage) {
    self.headerImageView.image = headerImage;
  } else {
    // If icon doesn't exist, use background color as fallback
    self.headerImageView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
  }
  [self.contentView addSubview:self.headerImageView];

}

- (void)setupLargeButtons {
  // Beauty Effect button - corresponding to Android's camera2
  UIImage *beautyEffectIcon = [UIImage imageNamed:@"camera2"];
  if (!beautyEffectIcon) {
    if (@available(iOS 13.0, *)) {
      beautyEffectIcon = [UIImage systemImageNamed:@"camera.fill"];
    }
  }
  self.beautyEffectButton = [self createLargeButtonWithTitle:@"Effect"
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
  // Add to self.view instead of contentView to ensure displayed above grid container
  [self.view addSubview:self.beautyEffectButton];

  // Beauty Template button - corresponding to Android's beautycard3
  UIImage *beautyTemplateIcon = [UIImage imageNamed:@"beautycard3"];
  if (!beautyTemplateIcon) {
    if (@available(iOS 13.0, *)) {
      beautyTemplateIcon = [UIImage systemImageNamed:@"photo.fill"];
    }
  }
  // Set background color to transparent, use gradient layer as background
  self.beautyTemplateButton = [self createLargeButtonWithTitle:@"Template"
                                                          icon:beautyTemplateIcon
                                                     tintColor:[UIColor blackColor]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:nil];
  [self.beautyTemplateButton addTarget:self
                                action:@selector(beautyTemplateButtonTapped:)
                      forControlEvents:UIControlEventTouchUpInside];

  // Create gradient background layer
  self.beautyTemplateGradientLayer = [CAGradientLayer layer];
  self.beautyTemplateGradientLayer.colors = @[
    (id)[UIColor colorWithRed:0xCC / 255.0 green:0xFB / 255.0 blue:0x78 / 255.0 alpha:1.0].CGColor,
    (id)[UIColor colorWithRed:0x75 / 255.0 green:0xED / 255.0 blue:0xE0 / 255.0 alpha:1.0].CGColor
  ];
  // Gradient direction: from left to right
  self.beautyTemplateGradientLayer.startPoint = CGPointMake(0, 0);
  self.beautyTemplateGradientLayer.endPoint = CGPointMake(1, 0);
  self.beautyTemplateGradientLayer.cornerRadius = 12;
  // Insert gradient layer at bottommost
  [self.beautyTemplateButton.layer insertSublayer:self.beautyTemplateGradientLayer atIndex:0];

  // Add to self.view instead of contentView to ensure displayed above grid container
  [self.view addSubview:self.beautyTemplateButton];

  [NSLayoutConstraint activateConstraints:@[
    // Beauty Effect button (move up 40 pixels)
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

    // Beauty Template button (top aligned with Beauty Effect button)
    [self.beautyTemplateButton.topAnchor constraintEqualToAnchor:self.beautyEffectButton.topAnchor],
    [self.beautyTemplateButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                             constant:-20],
    [self.beautyTemplateButton.heightAnchor constraintEqualToConstant:72]
  ]];

  // Ensure buttons are on top of view hierarchy and can receive touch events
  [self.view bringSubviewToFront:self.beautyEffectButton];
  [self.view bringSubviewToFront:self.beautyTemplateButton];

  // Ensure buttons can receive touch events
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
  // Ensure buttons can receive touch events
  button.userInteractionEnabled = YES;
  button.enabled = YES;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.axis = UILayoutConstraintAxisHorizontal;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.spacing = 12;
  // StackView doesn't intercept touch events, let button receive them
  stackView.userInteractionEnabled = NO;

  UIImageView *iconView = [[UIImageView alloc] init];
  // Set image to template rendering mode so tintColor takes effect
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
  // First grid container (white background, rounded corners)
  self.gridContainer = [[UIView alloc] init];
  self.gridContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.gridContainer.backgroundColor = [UIColor whiteColor];
  self.gridContainer.layer.cornerRadius = 24;
  self.gridContainer.layer.masksToBounds = YES;
  // Container needs to enable interaction so child views (buttons) can receive touch events
  self.gridContainer.userInteractionEnabled = YES;
  // Add to view instead of contentView to ensure consistent with screen width
  [self.view addSubview:self.gridContainer];

  // First area: first 8 feature buttons (Beauty to Quality Adjustment)
  // Button order consistent with Android
  NSArray *firstSectionFeatures = @[
    @{
      @"title" : @"Beauty",
      @"selector" : @"beautyButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meiyan"
    },
    @{
      @"title" : @"Reshape",
      @"selector" : @"reshapeButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meixing2"
    },
    @{
      @"title" : @"Makeup",
      @"selector" : @"makeupButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"meizhuang"
    },
    @{
      @"title" : @"Body",
      @"selector" : @"bodyButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"meiti"
    },
    @{
      @"title" : @"Filter",
      @"selector" : @"filterButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"lvjing"
    },
    @{
      @"title" : @"Sticker",
      @"selector" : @"stickerButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"tiezhi2"
    },
    @{
      @"title" : @"Virtual BG",
      @"selector" : @"virtualBgButtonTapped:",
      @"enabled" : @YES,
      @"iconName" : @"xunibeijing"
    },
    @{
      @"title" : @"Quality",
      @"selector" : @"qualityButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"huazhitiaozheng2"
    }
  ];

  // Create first area grid layout
  UIStackView *firstSectionStack = [[UIStackView alloc] init];
  firstSectionStack.translatesAutoresizingMaskIntoConstraints = NO;
  firstSectionStack.axis = UILayoutConstraintAxisVertical;
  firstSectionStack.spacing = 16;
  firstSectionStack.distribution = UIStackViewDistributionFill;
  // StackView needs to enable interaction so child views (buttons) can receive touch events
  // Note: UIStackView's userInteractionEnabled should be YES so its child views can receive touch events
  firstSectionStack.userInteractionEnabled = YES;

  // Create 2 rows, 4 buttons per row
  for (int row = 0; row < 2; row++) {
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.distribution = UIStackViewDistributionFillEqually;
    // StackView needs to enable interaction so child views (buttons) can receive touch events
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

  // Atomic Capabilities area container
  UIView *atomicCapabilitiesContainer = [[UIView alloc] init];
  atomicCapabilitiesContainer.translatesAutoresizingMaskIntoConstraints = NO;
  atomicCapabilitiesContainer.backgroundColor = [UIColor whiteColor];
  // Container needs to enable interaction so child views (buttons) can receive touch events
  atomicCapabilitiesContainer.userInteractionEnabled = YES;
  [self.contentView addSubview:atomicCapabilitiesContainer];

  // "Atomic Capabilities" title
  UILabel *atomicTitleLabel = [[UILabel alloc] init];
  atomicTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  atomicTitleLabel.text = @"Atomic Capabilities";
  atomicTitleLabel.font = [UIFont boldSystemFontOfSize:18];
  atomicTitleLabel.textColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  [atomicCapabilitiesContainer addSubview:atomicTitleLabel];

  // Second area: Atomic Capabilities buttons (Hair Color, Style Makeover, Face Detection, Gesture Detection, Green Screen Keying)
  NSArray *secondSectionFeatures = @[
    @{
      @"title" : @"Hair Color",
      @"selector" : @"hairColorButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"huanfase"
    },
    @{
      @"title" : @"Style",
      @"selector" : @"styleButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"fengge"
    },
    @{
      @"title" : @"Face Detect",
      @"selector" : @"faceDetectButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"renlianjiance"
    },
    @{
      @"title" : @"Gesture",
      @"selector" : @"gestureButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"shoushi"
    },
    @{
      @"title" : @"Green Screen",
      @"selector" : @"greenScreenButtonTapped:",
      @"enabled" : @NO,
      @"iconName" : @"lvmukoutu"
    }
  ];

  // Create second area grid layout
  UIStackView *secondSectionStack = [[UIStackView alloc] init];
  secondSectionStack.translatesAutoresizingMaskIntoConstraints = NO;
  secondSectionStack.axis = UILayoutConstraintAxisVertical;
  secondSectionStack.spacing = 16;
  secondSectionStack.distribution = UIStackViewDistributionFill;
  // StackView needs to enable interaction so child views (buttons) can receive touch events
  secondSectionStack.userInteractionEnabled = YES;

  // Row 1: 4 buttons (Hair Color, Style Makeover, Face Detection, Gesture Detection)
  UIStackView *secondRow1 = [[UIStackView alloc] init];
  secondRow1.translatesAutoresizingMaskIntoConstraints = NO;
  secondRow1.axis = UILayoutConstraintAxisHorizontal;
  secondRow1.spacing = 12;
  secondRow1.distribution = UIStackViewDistributionFillEqually;
  // StackView needs to enable interaction so child views (buttons) can receive touch events
  secondRow1.userInteractionEnabled = YES;

  for (int i = 0; i < 4; i++) {
    NSDictionary *feature = secondSectionFeatures[i];
    UIButton *button = [self createFeatureButton:feature];
    [secondRow1 addArrangedSubview:button];
  }
  [secondSectionStack addArrangedSubview:secondRow1];

  // Row 2: 2 buttons (Green Screen Keying, External Texture) + 2 placeholders
  UIStackView *secondRow2 = [[UIStackView alloc] init];
  secondRow2.translatesAutoresizingMaskIntoConstraints = NO;
  secondRow2.axis = UILayoutConstraintAxisHorizontal;
  secondRow2.spacing = 12;
  secondRow2.distribution = UIStackViewDistributionFillEqually;
  // StackView needs to enable interaction so child views (buttons) can receive touch events
  secondRow2.userInteractionEnabled = YES;

  // Green Screen Keying button
  NSDictionary *greenScreenFeature = secondSectionFeatures[4];
  UIButton *greenScreenButton = [self createFeatureButton:greenScreenFeature];
  [secondRow2 addArrangedSubview:greenScreenButton];

  // External Texture button
  NSDictionary *externalTextureFeature = @{
    @"title" : @"External Texture",
    @"selector" : @"externalTextureGridButtonTapped:",
    @"enabled" : @YES,
    @"iconName" : @"texture"
  };
  UIButton *externalTextureGridButton = [self createFeatureButton:externalTextureFeature];
  [secondRow2 addArrangedSubview:externalTextureGridButton];

  // Add 2 placeholder views
  for (int i = 0; i < 2; i++) {
    UIView *placeholder = [[UIView alloc] init];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [secondRow2 addArrangedSubview:placeholder];
  }

  [secondSectionStack addArrangedSubview:secondRow2];

  [atomicCapabilitiesContainer addSubview:secondSectionStack];

  // Setup constraints
  [NSLayoutConstraint activateConstraints:@[
    // First grid container (width same as screen width)
    [self.gridContainer.topAnchor constraintEqualToAnchor:self.headerImageView.bottomAnchor
                                                 constant:-35],
    [self.gridContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.gridContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

    // First area grid (adjust internal content position, because container moved up, buttons move up 45 pixels)
    [firstSectionStack.topAnchor constraintEqualToAnchor:self.gridContainer.topAnchor constant:59],
    [firstSectionStack.leadingAnchor constraintEqualToAnchor:self.gridContainer.leadingAnchor
                                                    constant:12],
    [firstSectionStack.trailingAnchor constraintEqualToAnchor:self.gridContainer.trailingAnchor
                                                     constant:-12],
    [firstSectionStack.bottomAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor
                                                   constant:-12],

    // Atomic Capabilities container
    [atomicCapabilitiesContainer.topAnchor constraintEqualToAnchor:self.gridContainer.bottomAnchor],
    [atomicCapabilitiesContainer.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor],
    [atomicCapabilitiesContainer.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor],
    [atomicCapabilitiesContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor
                                                             constant:-20],

    // Atomic Capabilities title
    [atomicTitleLabel.topAnchor constraintEqualToAnchor:atomicCapabilitiesContainer.topAnchor
                                               constant:8],
    [atomicTitleLabel.leadingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.leadingAnchor
                       constant:16],
    [atomicTitleLabel.trailingAnchor
        constraintEqualToAnchor:atomicCapabilitiesContainer.trailingAnchor
                       constant:-16],

    // Second area grid
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
  // Ensure buttons can receive touch events
  button.userInteractionEnabled = YES;
  // enabled state will be set later based on feature configuration

  // Ensure button is square (aspect ratio 1:1)
  [button.widthAnchor constraintEqualToAnchor:button.heightAnchor].active = YES;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.spacing = 4;
  // StackView doesn't intercept touch events, let button receive them
  stackView.userInteractionEnabled = NO;

  UIImageView *iconView = [[UIImageView alloc] init];
  // Read icon from Assets.xcassets
  NSString *iconName = feature[@"iconName"];
  UIImage *iconImage = [UIImage imageNamed:iconName];
  if (!iconImage) {
    // If icon doesn't exist, use system icon as fallback
    if (@available(iOS 13.0, *)) {
      // Select different system icons based on icon name
      if ([iconName isEqualToString:@"texture"]) {
        // External texture uses cube icon
        iconImage = [UIImage systemImageNamed:@"cube"];
      } else {
        iconImage = [UIImage systemImageNamed:@"circle.fill"];
      }
    }
  }
  iconView.image = iconImage;
  iconView.tintColor = [UIColor colorWithRed:0.26 green:0.26 blue:0.26 alpha:1.0];
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  // Icon doesn't intercept touch events
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
  // Label doesn't intercept touch events
  titleLabel.userInteractionEnabled = NO;

  [stackView addArrangedSubview:iconView];
  [stackView addArrangedSubview:titleLabel];

  [button addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
  ]];

  // Setup click event
  SEL selector = NSSelectorFromString(feature[@"selector"]);
  if (selector && [self respondsToSelector:selector]) {
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
  }

  // Set button state based on enabled state
  BOOL enabled = [feature[@"enabled"] boolValue];
  button.enabled = enabled;

  // Unavailable state
  if (!enabled) {
    button.alpha = 0.5;
    // Add Soon badge
    UILabel *soonLabel = [[UILabel alloc] init];
    soonLabel.text = @"Soon";
    soonLabel.font = [UIFont systemFontOfSize:8];
    soonLabel.textColor = [UIColor whiteColor];
    soonLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    soonLabel.layer.cornerRadius = 4;
    soonLabel.layer.masksToBounds = YES;
    soonLabel.textAlignment = NSTextAlignmentCenter;
    soonLabel.translatesAutoresizingMaskIntoConstraints = NO;
    // Soon badge doesn't intercept touch events
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

    // Directly constrain to view top to achieve full-screen effect
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
    // If no navigation controller, use present method
    UINavigationController *navVC =
        [[UINavigationController alloc] initWithRootViewController:cameraVC];
    navVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navVC animated:YES completion:nil];
  }
}

- (void)beautyTemplateButtonTapped:(UIButton *)sender {
  [self showToast:@"Beauty template feature is under development, stay tuned ✨"];
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
  [self showToast:@"Body feature is under development, stay tuned 🏃"];
}

- (void)filterButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"filter"];
}

- (void)stickerButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"sticker"];
}

- (void)virtualBgButtonTapped:(UIButton *)sender {
  [self navigateToCamera:@"virtual_bg"];
}

- (void)qualityButtonTapped:(UIButton *)sender {
  [self showToast:@"Quality adjustment feature is under development, stay tuned 📸"];
}

- (void)faceDetectButtonTapped:(UIButton *)sender {
  // Face detection feature temporarily unavailable, show message
  [self showToast:@"Face detection feature is under development, stay tuned 👤"];
}

- (void)hairColorButtonTapped:(UIButton *)sender {
  [self showToast:@"Hair color feature is under development, stay tuned 💇"];
}

- (void)styleButtonTapped:(UIButton *)sender {
  [self showToast:@"Style feature is under development, stay tuned 🎭"];
}

- (void)gestureButtonTapped:(UIButton *)sender {
  [self showToast:@"Gesture recognition feature is under development, stay tuned 👋"];
}

- (void)greenScreenButtonTapped:(UIButton *)sender {
  [self showToast:@"Green screen feature is under development, stay tuned 🎬"];
}

- (void)externalTextureGridButtonTapped:(UIButton *)sender {
  ExternalTextureViewController *vc = [[ExternalTextureViewController alloc] init];
  if (self.navigationController) {
    [self.navigationController pushViewController:vc animated:YES];
  } else {
    // If there's no navigation controller, use present method
    UINavigationController *navVC =
        [[UINavigationController alloc] initWithRootViewController:vc];
    navVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navVC animated:YES completion:nil];
  }
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
