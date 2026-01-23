//
//  BeautyPanelViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/9/8.
//  Updated for new UI matching Android layout
//

#import "BeautyPanelViewController.h"

@interface BeautyPanelViewController ()

// Top button bar
@property(nonatomic, strong) UIView *topBar;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UIButton *galleryButton;
@property(nonatomic, strong) UIButton *flipCameraButton;
@property(nonatomic, strong) UIButton *moreButton;

@property(nonatomic, strong) UIView *panelRootView;
@property(nonatomic, strong) UIView *bottomControlPanel;

// Tab switching area
@property(nonatomic, strong) UIScrollView *tabScrollView;
@property(nonatomic, strong) UIStackView *tabContainer;
@property(nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property(nonatomic, strong) NSString *currentTab;

// Function button area
@property(nonatomic, strong) UIScrollView *functionScrollView;
@property(nonatomic, strong) UIStackView *functionButtonContainer;
@property(nonatomic, strong) NSMutableArray<UIButton *> *functionButtons;

// Sub-option area
@property(nonatomic, strong) UIScrollView *subOptionScrollView;
@property(nonatomic, strong) UIStackView *subOptionContainer;
@property(nonatomic, strong) NSMutableArray<UIButton *> *subOptionButtons;

// Filter mapping data
@property(nonatomic, strong) NSDictionary *filterMapping;

// Bottom button area
@property(nonatomic, strong) UIView *bottomButtonContainer;
@property(nonatomic, strong) UIButton *resetButton;
@property(nonatomic, strong) UIButton *captureButton;
@property(nonatomic, strong) UIButton *hidePanelButton;

// Slider
@property(nonatomic, strong) UIView *sliderContainer;
@property(nonatomic, strong) UISlider *valueSlider;
@property(nonatomic, strong) UILabel *valueLabel;
@property(nonatomic, assign) BOOL isSliderVisible;
@property(nonatomic, strong) NSLayoutConstraint *sliderContainerHeightConstraint;
// Before/After compare button
@property(nonatomic, strong) UIButton *beforeAfterButton;
@property(nonatomic, strong) NSLayoutConstraint *beforeAfterButtonBottomConstraint;

// State
@property(nonatomic, assign) BOOL isPanelVisible;
@property(nonatomic, assign) BOOL isSubOptionVisible;
@property(nonatomic, strong) NSString *currentFunction;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *functionProgress;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *toggleStates;
// Function button selection indicator (key: "tab:function", value: UIView)
@property(nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *functionIndicatorViews;

@end

@implementation BeautyPanelViewController

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // If it's tabScrollView, prevent vertical scrolling
  if (scrollView == self.tabScrollView) {
    // If contentOffset.y is not 0, force it to 0 (prevent vertical scrolling)
    if (scrollView.contentOffset.y != 0) {
      scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _currentTab = @"beauty";
    _functionProgress = [[NSMutableDictionary alloc] init];
    _toggleStates = [[NSMutableDictionary alloc] init];
    _functionIndicatorViews = [[NSMutableDictionary alloc] init];
    _functionButtons = [[NSMutableArray alloc] init];
    _subOptionButtons = [[NSMutableArray alloc] init];
    [self loadFilterMapping];
  }
  return self;
}

- (void)loadFilterMapping {
  NSString *mappingPath =
      [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"assets/filters/filter_mapping.json"];
  NSData *data = [NSData dataWithContentsOfFile:mappingPath];
  if (data) {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!error) {
      self.filterMapping = json[@"filters"];
    }
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  self.view.userInteractionEnabled = YES;  // Enable interaction so bottom control panel can receive click events

  [self setupTopBar];
  [self setupPanel];
  [self setupBottomControlPanel];
  [self hidePanel];  // Hidden by default
}

- (void)setupTopBar {
  // Top bar container (reference Android: padding 16dp, transparent background)
  self.topBar = [[UIView alloc] init];
  self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.topBar.backgroundColor = [UIColor clearColor];
  self.topBar.userInteractionEnabled = YES;  // Ensure can receive touch events
  [self.view addSubview:self.topBar];

  // Close button (48x48, icon 18pt)
  self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.closeButton.userInteractionEnabled = YES;
  self.closeButton.enabled = YES;
  UIImage *closeIcon = [UIImage imageNamed:@"close"];
  if (!closeIcon) {
    if (@available(iOS 13.0, *)) {
      closeIcon = [UIImage systemImageNamed:@"xmark"];
      closeIcon = [closeIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    closeIcon = [closeIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [self.closeButton setImage:closeIcon forState:UIControlStateNormal];
  self.closeButton.tintColor = [UIColor whiteColor];
  self.closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.closeButton addTarget:self
                       action:@selector(closeButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];

  // Gallery button (48x48, icon 22pt)
  self.galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.galleryButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.galleryButton.userInteractionEnabled = YES;
  self.galleryButton.enabled = YES;
  UIImage *galleryIcon = [UIImage imageNamed:@"camera3"];
  if (!galleryIcon) {
    if (@available(iOS 13.0, *)) {
      galleryIcon = [UIImage systemImageNamed:@"photo.on.rectangle"];
      galleryIcon = [galleryIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    galleryIcon = [galleryIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [self.galleryButton setImage:galleryIcon forState:UIControlStateNormal];
  self.galleryButton.tintColor = [UIColor whiteColor];
  self.galleryButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.galleryButton addTarget:self
                         action:@selector(galleryButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];

  // Flip camera button (48x48, icon 24pt)
  self.flipCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.flipCameraButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.flipCameraButton.userInteractionEnabled = YES;
  self.flipCameraButton.enabled = YES;
  UIImage *flipIcon = [UIImage imageNamed:@"switchcamera"];
  if (!flipIcon) {
    if (@available(iOS 13.0, *)) {
      flipIcon = [UIImage systemImageNamed:@"camera.rotate"];
      flipIcon = [flipIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    flipIcon = [flipIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [self.flipCameraButton setImage:flipIcon forState:UIControlStateNormal];
  self.flipCameraButton.tintColor = [UIColor whiteColor];
  self.flipCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.flipCameraButton addTarget:self
                            action:@selector(flipCameraButtonTapped:)
                  forControlEvents:UIControlEventTouchUpInside];

  // More options button (48x48, icon 22pt)
  self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.moreButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.moreButton.userInteractionEnabled = YES;
  self.moreButton.enabled = YES;
  UIImage *moreIcon = [UIImage imageNamed:@"more"];
  if (!moreIcon) {
    if (@available(iOS 13.0, *)) {
      moreIcon = [UIImage systemImageNamed:@"ellipsis"];
      moreIcon = [moreIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    moreIcon = [moreIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [self.moreButton setImage:moreIcon forState:UIControlStateNormal];
  self.moreButton.tintColor = [UIColor whiteColor];
  self.moreButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.moreButton addTarget:self
                      action:@selector(moreButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];

  // Use StackView to evenly distribute buttons (reference Android: Space between buttons, use FillEqually distribution)
  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.alignment = UIStackViewAlignmentCenter;
  buttonStack.spacing = 0;
  // StackView needs to enable interaction, but touch events will be passed to child views (buttons)
  buttonStack.userInteractionEnabled = YES;

  // Add buttons and spacer views
  [buttonStack addArrangedSubview:self.closeButton];

  UIView *spacer1 = [[UIView alloc] init];
  spacer1.translatesAutoresizingMaskIntoConstraints = NO;
  spacer1.userInteractionEnabled = NO;  // Spacer view doesn't intercept touch events
  [buttonStack addArrangedSubview:spacer1];

  [buttonStack addArrangedSubview:self.galleryButton];

  UIView *spacer2 = [[UIView alloc] init];
  spacer2.translatesAutoresizingMaskIntoConstraints = NO;
  spacer2.userInteractionEnabled = NO;  // Spacer view doesn't intercept touch events
  [buttonStack addArrangedSubview:spacer2];

  [buttonStack addArrangedSubview:self.flipCameraButton];

  UIView *spacer3 = [[UIView alloc] init];
  spacer3.translatesAutoresizingMaskIntoConstraints = NO;
  spacer3.userInteractionEnabled = NO;  // Spacer view doesn't intercept touch events
  [buttonStack addArrangedSubview:spacer3];

  [buttonStack addArrangedSubview:self.moreButton];

  [self.topBar addSubview:buttonStack];

  // Layout constraints
  [NSLayoutConstraint activateConstraints:@[
    // Button height fixed at 48pt, width automatically allocated by StackView's FillEqually (remove fixed width constraint to avoid conflicts)
    [self.closeButton.heightAnchor constraintEqualToConstant:48],
    [self.galleryButton.heightAnchor constraintEqualToConstant:48],
    [self.flipCameraButton.heightAnchor constraintEqualToConstant:48],
    [self.moreButton.heightAnchor constraintEqualToConstant:48],

    // StackView layout (left/right padding 16pt, vertically centered)
    [buttonStack.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:16],
    [buttonStack.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-16],
    [buttonStack.topAnchor constraintEqualToAnchor:self.topBar.topAnchor constant:16],
    [buttonStack.bottomAnchor constraintEqualToAnchor:self.topBar.bottomAnchor constant:-16],
    [buttonStack.heightAnchor constraintEqualToConstant:48]
  ]];

  // Set icon size (adjusted through contentEdgeInsets and imageEdgeInsets)
  // Close button icon: 18pt
  self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);  // (48-18)/2 = 15
  // Gallery button icon: 22pt
  self.galleryButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13);  // (48-22)/2 = 13
  // Flip camera button icon: 24pt
  self.flipCameraButton.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);  // (48-24)/2 = 12
  // More button icon: 22pt
  self.moreButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13);  // (48-22)/2 = 13

  // Top bar constraints (located at view top, height adaptive)
  NSLayoutYAxisAnchor *topAnchor;
  if (@available(iOS 11.0, *)) {
    topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
    if (!topAnchor) {
      topAnchor = self.view.topAnchor;
    }
  } else {
    topAnchor = self.view.topAnchor;
  }

  [NSLayoutConstraint activateConstraints:@[
    [self.topBar.topAnchor constraintEqualToAnchor:topAnchor],
    [self.topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    // Height determined by content (button 48pt + top/bottom padding 16pt × 2 = 80pt)
  ]];

  // Ensure top bar is on topmost layer
  [self.view bringSubviewToFront:self.topBar];
}

- (void)setupPanel {
  // Panel root view - semi-transparent background, covers entire panel area
  self.panelRootView = [[UIView alloc] init];
  self.panelRootView.translatesAutoresizingMaskIntoConstraints = NO;
  self.panelRootView.backgroundColor = [UIColor colorWithRed:0
                                                       green:0
                                                        blue:0
                                                       alpha:0.8];  // Semi-transparent black background
  self.panelRootView.hidden = YES;
  self.panelRootView.userInteractionEnabled = YES;  // Ensure can receive touch events
  [self.view addSubview:self.panelRootView];

  // Tab switching area
  [self setupTabScrollView];

  // Function button area
  [self setupFunctionScrollView];

  // Sub-option area (hidden by default)
  [self setupSubOptionScrollView];

  // Slider area (must be created before setting constraints)
  [self setupSliderContainer];

  // Bottom button area
  [self setupBottomButtonContainer];

  // Constraints
  [self setupPanelConstraints];
}

- (void)setupTabScrollView {
  self.tabScrollView = [[UIScrollView alloc] init];
  self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabScrollView.showsHorizontalScrollIndicator = NO;
  self.tabScrollView.showsVerticalScrollIndicator = NO;  // Disable vertical scroll indicator
  self.tabScrollView.alwaysBounceVertical = NO;          // Disable vertical bounce
  self.tabScrollView.alwaysBounceHorizontal = YES;       // Allow horizontal bounce
  self.tabScrollView.directionalLockEnabled = YES;       // Enable direction lock, prioritize horizontal scrolling
  self.tabScrollView.scrollEnabled = YES;                // Ensure scrolling is enabled
  // Set delegate to prevent vertical scrolling (BeautyPanelViewController already implements UIScrollViewDelegate)
  self.tabScrollView.delegate = self;
  self.tabScrollView.backgroundColor = [UIColor clearColor];  // Transparent, because parent view already has background
  [self.panelRootView addSubview:self.tabScrollView];

  self.tabContainer = [[UIStackView alloc] init];
  self.tabContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabContainer.axis = UILayoutConstraintAxisHorizontal;
  self.tabContainer.spacing = 0;
  self.tabContainer.alignment = UIStackViewAlignmentCenter;
  [self.tabScrollView addSubview:self.tabContainer];

  // Tab buttons
  NSArray *tabs =
      @[ @"Beauty", @"Reshape", @"Makeup", @"Filter", @"Sticker", @"Body", @"Virtual BG", @"Quality" ];
  NSMutableArray *buttons = [[NSMutableArray alloc] init];

  for (NSInteger i = 0; i < tabs.count; i++) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:tabs[i] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0]
                 forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    button.tag = i;
    [button addTarget:self
                  action:@selector(tabButtonTapped:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.tabContainer addArrangedSubview:button];
    [buttons addObject:button];
  }

  self.tabButtons = buttons;
  [self selectTabButton:0];  // Select first by default
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Update contentSize after layout is complete to ensure vertical scrolling is disabled
  [self updateTabScrollViewContentSize];
}

- (void)updateTabScrollViewContentSize {
  // Ensure contentSize's vertical height equals ScrollView's height so vertical scrolling is disabled
  CGFloat scrollViewHeight = self.tabScrollView.bounds.size.height;
  if (scrollViewHeight > 0) {
    CGSize contentSize = self.tabScrollView.contentSize;
    // If contentSize width is 0, layout is not complete yet, wait for next update
    if (contentSize.width > 0) {
      self.tabScrollView.contentSize = CGSizeMake(contentSize.width, scrollViewHeight);
    }
  }
}

- (void)setupFunctionScrollView {
  self.functionScrollView = [[UIScrollView alloc] init];
  self.functionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.functionScrollView.showsHorizontalScrollIndicator = NO;
  self.functionScrollView.backgroundColor = [UIColor clearColor];  // Transparent, because parent view already has background
  [self.panelRootView addSubview:self.functionScrollView];

  self.functionButtonContainer = [[UIStackView alloc] init];
  self.functionButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.functionButtonContainer.axis = UILayoutConstraintAxisHorizontal;
  self.functionButtonContainer.spacing = 8;
  self.functionButtonContainer.alignment = UIStackViewAlignmentCenter;
  [self.functionScrollView addSubview:self.functionButtonContainer];

  [self updateFunctionButtons];
}

- (void)setupSubOptionScrollView {
  self.subOptionScrollView = [[UIScrollView alloc] init];
  self.subOptionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.subOptionScrollView.showsHorizontalScrollIndicator = NO;
  self.subOptionScrollView.showsVerticalScrollIndicator = NO;
  self.subOptionScrollView.backgroundColor = [UIColor clearColor];  // Transparent, because parent view already has background
  self.subOptionScrollView.hidden = YES;
  self.subOptionScrollView.alwaysBounceHorizontal = YES;  // Allow horizontal bounce
  [self.panelRootView addSubview:self.subOptionScrollView];

  self.subOptionContainer = [[UIStackView alloc] init];
  self.subOptionContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.subOptionContainer.axis = UILayoutConstraintAxisHorizontal;
  self.subOptionContainer.spacing = 8;
  self.subOptionContainer.alignment = UIStackViewAlignmentCenter;
  [self.subOptionScrollView addSubview:self.subOptionContainer];
}

- (void)setupBottomButtonContainer {
  self.bottomButtonContainer = [[UIView alloc] init];
  self.bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomButtonContainer.backgroundColor = [UIColor clearColor];
  [self.panelRootView addSubview:self.bottomButtonContainer];

  // Use StackView to evenly distribute three buttons
  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.alignment = UIStackViewAlignmentCenter;
  [self.bottomButtonContainer addSubview:buttonStack];

  // Reset button
  self.resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UIStackView *resetStack = [[UIStackView alloc] init];
  resetStack.axis = UILayoutConstraintAxisHorizontal;
  resetStack.alignment = UIStackViewAlignmentCenter;
  resetStack.spacing = 8;

  UIImage *resetIcon = [UIImage imageNamed:@"reset"];
  if (!resetIcon) {
    if (@available(iOS 13.0, *)) {
      resetIcon = [UIImage systemImageNamed:@"arrow.counterclockwise"];
      resetIcon = [resetIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    // Set to template mode for tinting
    resetIcon = [resetIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  UIImageView *resetIconView = [[UIImageView alloc] initWithImage:resetIcon];
  resetIconView.tintColor = [UIColor whiteColor];
  resetIconView.contentMode = UIViewContentModeScaleAspectFit;
  [NSLayoutConstraint activateConstraints:@[
    [resetIconView.widthAnchor constraintEqualToConstant:20],
    [resetIconView.heightAnchor constraintEqualToConstant:20]
  ]];

  UILabel *resetLabel = [[UILabel alloc] init];
  resetLabel.text = @"Reset";
  resetLabel.textColor = [UIColor whiteColor];
  resetLabel.font = [UIFont systemFontOfSize:14];

  [resetStack addArrangedSubview:resetIconView];
  [resetStack addArrangedSubview:resetLabel];
  resetStack.userInteractionEnabled = NO;  // Disable StackView interaction to avoid intercepting button touch events
  [self.resetButton addSubview:resetStack];
  resetStack.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [resetStack.centerXAnchor constraintEqualToAnchor:self.resetButton.centerXAnchor],
    [resetStack.centerYAnchor constraintEqualToAnchor:self.resetButton.centerYAnchor]
  ]];
  [self.resetButton addTarget:self
                       action:@selector(resetButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
  [buttonStack addArrangedSubview:self.resetButton];

  // Capture button (middle) - Following Android implementation: white outer circle + green inner circle
  // Create container view
  UIView *captureButtonContainer = [[UIView alloc] init];
  captureButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  captureButtonContainer.backgroundColor = [UIColor clearColor];

  // Outer white circle
  UIView *outerCircle = [[UIView alloc] init];
  outerCircle.translatesAutoresizingMaskIntoConstraints = NO;
  outerCircle.backgroundColor = [UIColor whiteColor];
  outerCircle.layer.cornerRadius = 30;  // 60 / 2 = 30
  outerCircle.layer.masksToBounds = YES;
  [captureButtonContainer addSubview:outerCircle];

  // Inner green circle (capture button)
  self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.captureButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.captureButton.backgroundColor = [UIColor colorWithRed:0.0
                                                       green:1.0
                                                        blue:0.0
                                                       alpha:1.0];  // #00FF00
  self.captureButton.layer.cornerRadius = 25;                       // 50 / 2 = 25
  self.captureButton.layer.masksToBounds = YES;
  [self.captureButton addTarget:self
                         action:@selector(captureButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];
  [captureButtonContainer addSubview:self.captureButton];

  // Constraints: outer white circle 60x60, centered
  [NSLayoutConstraint activateConstraints:@[
    [outerCircle.centerXAnchor constraintEqualToAnchor:captureButtonContainer.centerXAnchor],
    [outerCircle.centerYAnchor constraintEqualToAnchor:captureButtonContainer.centerYAnchor],
    [outerCircle.widthAnchor constraintEqualToConstant:60],
    [outerCircle.heightAnchor constraintEqualToConstant:60],

    // Inner green circle 50x50, centered inside outer circle
    [self.captureButton.centerXAnchor constraintEqualToAnchor:outerCircle.centerXAnchor],
    [self.captureButton.centerYAnchor constraintEqualToAnchor:outerCircle.centerYAnchor],
    [self.captureButton.widthAnchor constraintEqualToConstant:50],
    [self.captureButton.heightAnchor constraintEqualToConstant:50]
  ]];

  [buttonStack addArrangedSubview:captureButtonContainer];

  // Hide panel button
  self.hidePanelButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UIStackView *hideStack = [[UIStackView alloc] init];
  hideStack.axis = UILayoutConstraintAxisHorizontal;
  hideStack.alignment = UIStackViewAlignmentCenter;
  hideStack.spacing = 8;

  UIImage *hideIcon = [UIImage imageNamed:@"menu"];
  if (!hideIcon) {
    if (@available(iOS 13.0, *)) {
      hideIcon = [UIImage systemImageNamed:@"grid"];
      hideIcon = [hideIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    // Set to template mode for tinting
    hideIcon = [hideIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  UIImageView *hideIconView = [[UIImageView alloc] initWithImage:hideIcon];
  hideIconView.tintColor = [UIColor whiteColor];
  hideIconView.contentMode = UIViewContentModeScaleAspectFit;
  [NSLayoutConstraint activateConstraints:@[
    [hideIconView.widthAnchor constraintEqualToConstant:20],
    [hideIconView.heightAnchor constraintEqualToConstant:20]
  ]];

  UILabel *hideLabel = [[UILabel alloc] init];
  hideLabel.text = @"Hide Panel";
  hideLabel.textColor = [UIColor whiteColor];
  hideLabel.font = [UIFont systemFontOfSize:14];

  [hideStack addArrangedSubview:hideIconView];
  [hideStack addArrangedSubview:hideLabel];
  hideStack.userInteractionEnabled = NO;  // Disable StackView interaction to avoid intercepting button touch events
  [self.hidePanelButton addSubview:hideStack];
  hideStack.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [hideStack.centerXAnchor constraintEqualToAnchor:self.hidePanelButton.centerXAnchor],
    [hideStack.centerYAnchor constraintEqualToAnchor:self.hidePanelButton.centerYAnchor]
  ]];
  [self.hidePanelButton addTarget:self
                           action:@selector(hidePanelButtonTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
  [buttonStack addArrangedSubview:self.hidePanelButton];

  // Constraints
  [NSLayoutConstraint activateConstraints:@[
    [buttonStack.topAnchor constraintEqualToAnchor:self.bottomButtonContainer.topAnchor
                                          constant:10],
    [buttonStack.leadingAnchor constraintEqualToAnchor:self.bottomButtonContainer.leadingAnchor
                                              constant:16],
    [buttonStack.trailingAnchor constraintEqualToAnchor:self.bottomButtonContainer.trailingAnchor
                                               constant:-16],
    [buttonStack.bottomAnchor constraintEqualToAnchor:self.bottomButtonContainer.bottomAnchor
                                             constant:-10]
  ]];
}

- (void)setupPanelConstraints {
  // Ensure all views are initialized
  NSAssert(self.panelRootView != nil, @"panelRootView cannot be nil");
  NSAssert(self.bottomButtonContainer != nil, @"bottomButtonContainer cannot be nil");
  NSAssert(self.sliderContainer != nil, @"sliderContainer cannot be nil");
  NSAssert(self.functionScrollView != nil, @"functionScrollView cannot be nil");
  NSAssert(self.tabScrollView != nil, @"tabScrollView cannot be nil");

  // Get safeAreaLayoutGuide (iOS 11+), use bottomAnchor if unavailable
  NSLayoutYAxisAnchor *bottomAnchor;
  if (@available(iOS 11.0, *)) {
    bottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
    if (!bottomAnchor) {
      bottomAnchor = self.view.bottomAnchor;
    }
  } else {
    bottomAnchor = self.view.bottomAnchor;
  }

  [NSLayoutConstraint activateConstraints:@[
    // Panel root view (from Tab area to bottom, only covers bottom panel area)
    [self.panelRootView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.panelRootView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.panelRootView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // Bottom button container (bottommost, same position as bottomControlPanel)
    [self.bottomButtonContainer.leadingAnchor
        constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.bottomButtonContainer.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.bottomButtonContainer.bottomAnchor constraintEqualToAnchor:bottomAnchor],
    [self.bottomButtonContainer.heightAnchor constraintEqualToConstant:80],

    // Function button scroll view (below Tab, above bottom buttons)
    [self.functionScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor
                                                          constant:16],
    [self.functionScrollView.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor
                       constant:-16],
    [self.functionScrollView.bottomAnchor
        constraintEqualToAnchor:self.bottomButtonContainer.topAnchor],
    [self.functionScrollView.heightAnchor constraintEqualToConstant:120],

    // Function button container
    [self.functionButtonContainer.topAnchor
        constraintEqualToAnchor:self.functionScrollView.topAnchor],
    [self.functionButtonContainer.leadingAnchor
        constraintEqualToAnchor:self.functionScrollView.leadingAnchor],
    [self.functionButtonContainer.trailingAnchor
        constraintEqualToAnchor:self.functionScrollView.trailingAnchor],
    [self.functionButtonContainer.bottomAnchor
        constraintEqualToAnchor:self.functionScrollView.bottomAnchor],
    [self.functionButtonContainer.heightAnchor
        constraintEqualToAnchor:self.functionScrollView.heightAnchor],

    // Tab scroll view (above function buttons)
    [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.tabScrollView.topAnchor
        constraintEqualToAnchor:self.panelRootView.topAnchor],  // Panel starts from Tab area
    [self.tabScrollView.bottomAnchor constraintEqualToAnchor:self.functionScrollView.topAnchor],
    [self.tabScrollView.heightAnchor constraintEqualToConstant:50],

    // Tab container (strictly limit height to ensure vertical scrolling is disabled)
    [self.tabContainer.topAnchor constraintEqualToAnchor:self.tabScrollView.topAnchor constant:8],
    [self.tabContainer.leadingAnchor constraintEqualToAnchor:self.tabScrollView.leadingAnchor
                                                    constant:8],
    [self.tabContainer.trailingAnchor constraintEqualToAnchor:self.tabScrollView.trailingAnchor
                                                     constant:-8],
    [self.tabContainer.heightAnchor
        constraintEqualToConstant:34],  // 50 - 8*2 = 34 (Tab ScrollView height 50 - top/bottom padding 8*2)

    // Sub-option scroll view (overlaps function buttons, replaces them when shown)
    [self.subOptionScrollView.leadingAnchor
        constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.subOptionScrollView.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.subOptionScrollView.bottomAnchor
        constraintEqualToAnchor:self.bottomButtonContainer.topAnchor],
    [self.subOptionScrollView.heightAnchor constraintEqualToConstant:120],

    // Sub-option container (allows horizontal scrolling)
    [self.subOptionContainer.topAnchor constraintEqualToAnchor:self.subOptionScrollView.topAnchor],
    [self.subOptionContainer.leadingAnchor
        constraintEqualToAnchor:self.subOptionScrollView.leadingAnchor
                       constant:16],
    [self.subOptionContainer.bottomAnchor
        constraintEqualToAnchor:self.subOptionScrollView.bottomAnchor],
    [self.subOptionContainer.heightAnchor
        constraintEqualToAnchor:self.subOptionScrollView.heightAnchor]
  ]];

  // Set sub-option container width constraint: use >= relation to allow content to exceed ScrollView width
  // This way StackView can automatically expand based on content, and ScrollView can scroll
  NSLayoutConstraint *subOptionWidthConstraint = [self.subOptionContainer.widthAnchor
      constraintGreaterThanOrEqualToAnchor:self.subOptionScrollView.widthAnchor
                                  constant:-32];
  subOptionWidthConstraint.priority = UILayoutPriorityDefaultLow;
  subOptionWidthConstraint.active = YES;

  // Slider container constraints (located above panel, at panel top)
  [NSLayoutConstraint activateConstraints:@[
    [self.sliderContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.sliderContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.sliderContainer.bottomAnchor constraintEqualToAnchor:self.panelRootView.topAnchor]
  ]];
  // Store height constraint for dynamic adjustment (initial 0, because slider is hidden by default)
  self.sliderContainerHeightConstraint =
      [self.sliderContainer.heightAnchor constraintEqualToConstant:0];
  self.sliderContainerHeightConstraint.active = YES;

  // Before/After button constraints (dynamic position: close to panel top when expanded, close to bottom control panel when collapsed)
  [NSLayoutConstraint activateConstraints:@[
    [self.beforeAfterButton.widthAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.heightAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                          constant:-16]
  ]];

  // Create two constraints: one bound to panel top (when expanded), one bound to bottom control panel (when collapsed)
  // Note: bottomControlPanel may not be created yet, so initial constraint is set in hidePanel
  // Create a temporary constraint here, will be dynamically switched in showPanel/hidePanel
}

- (void)setupBottomControlPanel {
  // Bottom control panel (Beauty/Reshape, Makeup, Capture, Sticker Effect, Filter Adjustment)
  self.bottomControlPanel = [[UIView alloc] init];
  self.bottomControlPanel.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomControlPanel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
  self.bottomControlPanel.userInteractionEnabled = YES;  // Ensure bottom control panel can receive click events
  [self.view addSubview:self.bottomControlPanel];

  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.spacing = 0;

  // Button configuration: icon name and title
  NSArray *buttonConfigs = @[
    @{@"icon" : @"meiyan", @"title" : @"Beauty"},
    @{@"icon" : @"meizhuang", @"title" : @"Makeup"},
    @{@"icon" : @"camera2", @"title" : @"Capture"},
    @{@"icon" : @"tiezhi2", @"title" : @"Sticker"},
    @{@"icon" : @"lvjing", @"title" : @"Filter"}
  ];

  for (NSDictionary *config in buttonConfigs) {
    UIStackView *buttonStackItem = [[UIStackView alloc] init];
    buttonStackItem.axis = UILayoutConstraintAxisVertical;
    buttonStackItem.alignment = UIStackViewAlignmentCenter;
    buttonStackItem.spacing = 4;

    UIImage *iconImage = [UIImage imageNamed:config[@"icon"]];
    if (!iconImage) {
      if (@available(iOS 13.0, *)) {
        iconImage = [UIImage systemImageNamed:@"circle.fill"];
      }
    } else {
      // Set to template mode for tinting
      iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    UIImageView *iconView = [[UIImageView alloc] initWithImage:iconImage];
    iconView.tintColor = [UIColor whiteColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [NSLayoutConstraint activateConstraints:@[
      [iconView.widthAnchor constraintEqualToConstant:32],
      [iconView.heightAnchor constraintEqualToConstant:32]
    ]];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = config[@"title"];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    [buttonStackItem addArrangedSubview:iconView];
    [buttonStackItem addArrangedSubview:titleLabel];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addSubview:buttonStackItem];
    buttonStackItem.translatesAutoresizingMaskIntoConstraints = NO;
    buttonStackItem.userInteractionEnabled = NO;  // Disable StackView interaction to avoid intercepting button touch events
    [NSLayoutConstraint activateConstraints:@[
      [buttonStackItem.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
      [buttonStackItem.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
    ]];

    // If it's capture button (middle), use white outer circle + green inner circle
      if ([config[@"title"] isEqualToString:@"Capture"]) {
      // Remove icon and text
      [buttonStackItem removeArrangedSubview:iconView];
      [buttonStackItem removeArrangedSubview:titleLabel];
      [iconView removeFromSuperview];
      [titleLabel removeFromSuperview];

      // Create white outer circle container
      UIView *outerCircleView = [[UIView alloc] init];
      outerCircleView.translatesAutoresizingMaskIntoConstraints = NO;
      outerCircleView.backgroundColor = [UIColor whiteColor];
      outerCircleView.layer.cornerRadius = 30;  // 60 / 2 = 30
      outerCircleView.layer.masksToBounds = YES;
      [button addSubview:outerCircleView];

      // Create green inner circle
      UIView *innerCircleView = [[UIView alloc] init];
      innerCircleView.translatesAutoresizingMaskIntoConstraints = NO;
      innerCircleView.backgroundColor = [UIColor colorWithRed:0.0
                                                        green:1.0
                                                         blue:0.0
                                                        alpha:1.0];  // #00FF00
      innerCircleView.layer.cornerRadius = 25;                       // 50 / 2 = 25
      innerCircleView.layer.masksToBounds = YES;
      [button addSubview:innerCircleView];

      [NSLayoutConstraint activateConstraints:@[
        // Outer white circle 60x60, centered
        [outerCircleView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [outerCircleView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [outerCircleView.widthAnchor constraintEqualToConstant:60],
        [outerCircleView.heightAnchor constraintEqualToConstant:60],

        // Inner green circle 50x50, centered inside outer circle
        [innerCircleView.centerXAnchor constraintEqualToAnchor:outerCircleView.centerXAnchor],
        [innerCircleView.centerYAnchor constraintEqualToAnchor:outerCircleView.centerYAnchor],
        [innerCircleView.widthAnchor constraintEqualToConstant:50],
        [innerCircleView.heightAnchor constraintEqualToConstant:50]
      ]];

      // Capture button click event
      [button addTarget:self
                    action:@selector(captureButtonTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    } else {
      // Other buttons: map to corresponding Tab based on title
      NSString *title = config[@"title"];
      SEL selector = nil;

      if ([title isEqualToString:@"Beauty"]) {
        selector = @selector(beautyButtonTapped:);
      } else if ([title isEqualToString:@"Makeup"]) {
        selector = @selector(makeupButtonTapped:);
      } else if ([title isEqualToString:@"Sticker"]) {
        selector = @selector(stickerButtonTapped:);
      } else if ([title isEqualToString:@"Filter"]) {
        selector = @selector(filterButtonTapped:);
      }

      if (selector) {
        [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
      }
    }

    [buttonStack addArrangedSubview:button];
  }

  [self.bottomControlPanel addSubview:buttonStack];

  [NSLayoutConstraint activateConstraints:@[
    [self.bottomControlPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.bottomControlPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.bottomControlPanel.bottomAnchor
        constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [self.bottomControlPanel.heightAnchor constraintEqualToConstant:80],

    [buttonStack.topAnchor constraintEqualToAnchor:self.bottomControlPanel.topAnchor constant:16],
    [buttonStack.leadingAnchor constraintEqualToAnchor:self.bottomControlPanel.leadingAnchor],
    [buttonStack.trailingAnchor constraintEqualToAnchor:self.bottomControlPanel.trailingAnchor],
    [buttonStack.bottomAnchor constraintEqualToAnchor:self.bottomControlPanel.bottomAnchor
                                             constant:-16]
  ]];
}

#pragma mark - Public Methods

- (void)showPanel {
  self.isPanelVisible = YES;
  self.panelRootView.hidden = NO;
  self.panelRootView.userInteractionEnabled = YES;  // Panel can receive touch events when shown
  self.view.userInteractionEnabled = YES;
  self.bottomControlPanel.hidden = YES;
  // Show compare button (independently controlled from slider)
  self.beforeAfterButton.hidden = NO;

  // Switch constraint: when panel is expanded, button is close to panel top
  if (self.beforeAfterButtonBottomConstraint) {
    self.beforeAfterButtonBottomConstraint.active = NO;
  }
  self.beforeAfterButtonBottomConstraint =
      [self.beforeAfterButton.bottomAnchor constraintEqualToAnchor:self.panelRootView.topAnchor
                                                          constant:-10];
  self.beforeAfterButtonBottomConstraint.active = YES;

  // Ensure top bar is always on topmost layer
  [self.view bringSubviewToFront:self.topBar];
  // Ensure compare button is on topmost layer, not blocked by bottom controls
  [self.view bringSubviewToFront:self.beforeAfterButton];

  // Update layout
  [UIView animateWithDuration:0.2
                   animations:^{
                     [self.view layoutIfNeeded];
                   }];
}

- (void)hidePanel {
  self.isPanelVisible = NO;
  self.panelRootView.hidden = YES;
  self.panelRootView.userInteractionEnabled = NO;  // Disable interaction when panel is hidden to avoid intercepting top button touch events
  self.view.userInteractionEnabled = YES;  // Keep interactive so bottomControlPanel can receive click events
  self.bottomControlPanel.hidden = NO;
  [self hideSubOptions];
  [self hideSlider];

  // Switch constraint: when panel is collapsed, button is close to bottom control panel
  if (self.beforeAfterButtonBottomConstraint) {
    self.beforeAfterButtonBottomConstraint.active = NO;
  }
  self.beforeAfterButtonBottomConstraint =
      [self.beforeAfterButton.bottomAnchor constraintEqualToAnchor:self.bottomControlPanel.topAnchor
                                                          constant:-10];
  self.beforeAfterButtonBottomConstraint.active = YES;

  // Ensure top bar is always on topmost layer
  [self.view bringSubviewToFront:self.topBar];
  // Still show compare button when panel is hidden, and bring to front
  self.beforeAfterButton.hidden = NO;
  [self.view bringSubviewToFront:self.beforeAfterButton];

  // Update layout
  [UIView animateWithDuration:0.2
                   animations:^{
                     [self.view layoutIfNeeded];
                   }];
}

- (void)switchToTab:(NSString *)tab {
  NSInteger index = [self tabIndexForName:tab];
  if (index >= 0 && index < self.tabButtons.count) {
    [self selectTabButton:index];
    [self tabButtonTapped:self.tabButtons[index]];
  }
}

#pragma mark - Private Methods

- (void)updateFunctionButtons {
  // Clear existing buttons and indicators
  for (UIButton *button in self.functionButtons) {
    [self.functionButtonContainer removeArrangedSubview:button];
    [button removeFromSuperview];
  }
  [self.functionButtons removeAllObjects];
  [self.functionIndicatorViews removeAllObjects];  // Clear indicator references

  // Create buttons based on current Tab
  NSArray *functions = [self functionsForCurrentTab];

  for (NSDictionary *function in functions) {
    UIButton *button = [self createFunctionButton:function];

    // Handle disabled state: only disable when explicitly set to @NO, default is enabled
    NSNumber *enabled = function[@"enabled"];
    if (enabled != nil && [enabled boolValue] == NO) {
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
      [button addSubview:soonLabel];
      [NSLayoutConstraint activateConstraints:@[
        [soonLabel.topAnchor constraintEqualToAnchor:button.topAnchor constant:2],
        [soonLabel.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-2],
        [soonLabel.widthAnchor constraintGreaterThanOrEqualToConstant:30],
        [soonLabel.heightAnchor constraintEqualToConstant:14]
      ]];
    }

    [self.functionButtonContainer addArrangedSubview:button];
    [self.functionButtons addObject:button];
  }

  // Update selected indicator state
  [self updateSelectionIndicators];
}

- (NSArray *)functionsForCurrentTab {
  if ([self.currentTab isEqualToString:@"beauty"]) {
    // Beauty: Off, Whitening (enabled), Dark (disabled), Smoothing (enabled), Rosiness (enabled)
    // Reference Android: white, smooth, rosiness enabled; dark disabled
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"white", @"title" : @"Whitening", @"icon" : @"meiyan"},
      @{@"key" : @"dark", @"title" : @"Dark", @"icon" : @"huanfase", @"enabled" : @NO},
      @{@"key" : @"smooth", @"title" : @"Smoothing", @"icon" : @"meiyan2"},
      @{@"key" : @"ai", @"title" : @"Rosiness", @"icon" : @"meiyan"}
    ];
  } else if ([self.currentTab isEqualToString:@"reshape"]) {
    // Reshape: Off, Thin Face, V Face, Narrow Face, Short Face, Cheekbone, Jawbone, Chin, Nose Slim, Big Eye, Eye Distance
    // Reference Android: All 10 reshape parameters are enabled
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"thin_face", @"title" : @"Thin Face", @"icon" : @"meixing2"},
      @{@"key" : @"v_face", @"title" : @"V Face", @"icon" : @"meixing2"},
      @{@"key" : @"narrow_face", @"title" : @"Narrow Face", @"icon" : @"meixing2"},
      @{@"key" : @"short_face", @"title" : @"Short Face", @"icon" : @"meixing2"},
      @{@"key" : @"cheekbone", @"title" : @"Cheekbone", @"icon" : @"meixing2"},
      @{@"key" : @"jawbone", @"title" : @"Jawbone", @"icon" : @"meixing2"},
      @{@"key" : @"chin", @"title" : @"Chin", @"icon" : @"meixing2"},
      @{@"key" : @"nose_slim", @"title" : @"Nose Slim", @"icon" : @"meixing2"},
      @{@"key" : @"big_eye", @"title" : @"Big Eye", @"icon" : @"meixing2"},
      @{@"key" : @"eye_distance", @"title" : @"Eye Distance", @"icon" : @"meixing2"}
    ];
  } else if ([self.currentTab isEqualToString:@"makeup"]) {
    // Makeup: Off, Lipstick, Blush, Eyebrow, Eyeshadow (all enabled, with sub-options)
    // Reference Android: All 4 functions enabled, all have sub-options
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"lipstick", @"title" : @"Lipstick", @"icon" : @"meizhuang"},
      @{@"key" : @"blush", @"title" : @"Blush", @"icon" : @"meizhuang"},
      @{@"key" : @"eyebrow", @"title" : @"Eyebrow", @"icon" : @"meizhuang"},
      @{@"key" : @"eyeshadow", @"title" : @"Eyeshadow", @"icon" : @"meizhuang"}
    ];
  } else if ([self.currentTab isEqualToString:@"filter"]) {
    // Filter: Off, then all portrait filters from mapping
    NSMutableArray *filters = [NSMutableArray array];
    
    // 1. Off button
    [filters addObject:@{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"}];
    
    // 2. Portrait filters
    // Hardcoded order to match Android's filter_mapping.json traversal order or specific preference
    // Or iterate through the directory structure as done in registration
    // Here we use a predefined list of keys matching the files we saw in `assets/filters/portrait`
    NSArray *filterKeys = @[
      @"initial_heart", @"first_love", @"vivid", @"confession", @"milk_tea", @"mousse", 
      @"japanese", @"dawn", @"cookie", @"lively", @"pure", @"fair", @"snow", @"plain", 
      @"natural", @"rose", @"tender", @"tender_2", @"extraordinary"
    ];
    
    for (NSString *key in filterKeys) {
      NSString *title = key;
      if (self.filterMapping && self.filterMapping[key]) {
        title = self.filterMapping[key][@"en"];
      }
      
      // Use 'toggle' type so it doesn't show slider
      [filters addObject:@{
        @"key" : key, 
        @"title" : title, 
        @"icon" : @"lvjing",
        @"type" : @"toggle"
      }];
    }
    
    return filters;
  } else if ([self.currentTab isEqualToString:@"sticker"]) {
    // Sticker: Off, Rabbit (toggle type)
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"rabbit", @"title" : @"Rabbit", @"icon" : @"tiezhi2", @"type" : @"toggle"}
    ];
  } else if ([self.currentTab isEqualToString:@"body"]) {
    // Body: Off, Slim (disabled)
    // Reference Android: Only 1, disabled
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"slim", @"title" : @"Slim", @"icon" : @"meiti", @"enabled" : @NO}
    ];
  } else if ([self.currentTab isEqualToString:@"virtual_bg"]) {
    // Virtual Background: Off, Blur, Preset, Image (all enabled, toggle type)
    // Reference Android: blur, preset, image all enabled (toggle type, not slider)
    // Add off button to maintain consistency with other tabs
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"blur", @"title" : @"Blur", @"icon" : @"xunibeijing", @"type" : @"toggle"},
      @{@"key" : @"preset", @"title" : @"Preset", @"icon" : @"back_preset", @"type" : @"toggle"},
      @{@"key" : @"image", @"title" : @"Image", @"icon" : @"photo", @"type" : @"toggle"}
    ];
  } else if ([self.currentTab isEqualToString:@"quality"]) {
    // Quality: Off, Sharpen (disabled)
    // Reference Android: Only 1, disabled
    return @[
      @{@"key" : @"off", @"title" : @"Off", @"icon" : @"disable"},
      @{@"key" : @"sharpen", @"title" : @"Sharpen", @"icon" : @"huazhitiaozheng2", @"enabled" : @NO}
    ];
  }

  return @[];
}

- (UIButton *)createFunctionButton:(NSDictionary *)function {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.translatesAutoresizingMaskIntoConstraints = NO;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.spacing = 4;

  // Icon container (dark gray background, circular)
  UIView *iconContainer = [[UIView alloc] init];
  iconContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
  iconContainer.layer.cornerRadius = 25;

  // Icon (read from Assets or use system icon)
  UIImageView *iconView = [[UIImageView alloc] init];
  NSString *iconName = function[@"icon"];
  UIImage *iconImage = [UIImage imageNamed:iconName];
  if (!iconImage) {
    // If it's a system icon name, use system icon
    if (@available(iOS 13.0, *)) {
      iconImage = [UIImage systemImageNamed:iconName];
      if (iconImage) {
        iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      }
    }
  } else {
    // Set regular image to template mode for tinting
    iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  iconView.image = iconImage;
  iconView.tintColor = [UIColor whiteColor];
  iconView.contentMode = UIViewContentModeScaleAspectFit;

  [iconContainer addSubview:iconView];
  iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [iconContainer.widthAnchor constraintEqualToConstant:50],
    [iconContainer.heightAnchor constraintEqualToConstant:50],
    [iconView.widthAnchor constraintEqualToConstant:28],
    [iconView.heightAnchor constraintEqualToConstant:28],
    [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor]
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = function[@"title"];
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont systemFontOfSize:12];
  titleLabel.textAlignment = NSTextAlignmentCenter;

  // Selected indicator: green short line, below text
  UIView *indicator = [[UIView alloc] init];
  indicator.backgroundColor = [UIColor colorWithRed:0.0
                                              green:1.0
                                               blue:0.0
                                              alpha:1.0];  // #00FF00 green
  indicator.layer.cornerRadius = 1.5;                      // Approximately 3pt / 2 = 1.5pt
  indicator.hidden = YES;                                  // Hidden by default
  indicator.translatesAutoresizingMaskIntoConstraints = NO;

  [stackView addArrangedSubview:iconContainer];
  [stackView addArrangedSubview:titleLabel];
  [stackView addArrangedSubview:indicator];
  stackView.userInteractionEnabled = NO;  // Disable StackView interaction to avoid intercepting button touch events

  // Set indicator size constraints (14pt x 3pt, reference Android's 14dp x 3dp)
  [NSLayoutConstraint activateConstraints:@[
    [indicator.widthAnchor constraintEqualToConstant:14],
    [indicator.heightAnchor constraintEqualToConstant:3]
  ]];

  // Save indicator reference for this function (with tab prefix)
  NSString *functionKey = function[@"key"];
  NSString *fullKey =
      [NSString stringWithFormat:@"%@:%@", self.currentTab ?: @"", functionKey ?: @""];
  if (fullKey && indicator) {
    self.functionIndicatorViews[fullKey] = indicator;
  }

  [button addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [stackView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [stackView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
    [button.widthAnchor constraintEqualToConstant:70]
  ]];

  button.tag = [self.functionButtons count];
  [button addTarget:self
                action:@selector(functionButtonTapped:)
      forControlEvents:UIControlEventTouchUpInside];

  return button;
}

- (void)selectTabButton:(NSInteger)index {
  for (NSInteger i = 0; i < self.tabButtons.count; i++) {
    UIButton *button = self.tabButtons[i];
    if (i == index) {
      [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
      button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    } else {
      [button setTitleColor:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0]
                   forState:UIControlStateNormal];
      button.titleLabel.font = [UIFont systemFontOfSize:16];
    }
  }
}

- (NSInteger)tabIndexForName:(NSString *)tabName {
  NSArray *tabNames = @[
    @"beauty",
    @"reshape",
    @"makeup",
    @"filter",
    @"sticker",
    @"body",
    @"virtual_bg",
    @"quality"
  ];
  return [tabNames indexOfObject:tabName];
}

- (void)showSubOptions {
  self.isSubOptionVisible = YES;
  self.subOptionScrollView.hidden = NO;
  // Force layout update to ensure ScrollView's contentSize is correctly calculated
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.subOptionScrollView layoutIfNeeded];
  });
}

- (void)hideSubOptions {
  self.isSubOptionVisible = NO;
  self.subOptionScrollView.hidden = YES;
}

- (void)setupSliderContainer {
  // Slider container should be above the panel, not inside the panel
  self.sliderContainer = [[UIView alloc] init];
  self.sliderContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.sliderContainer.backgroundColor = [UIColor clearColor];
  self.sliderContainer.hidden = YES;
  self.isSliderVisible = NO;
  [self.view addSubview:self.sliderContainer];  // Add to view instead of panelRootView

  // Value label
  self.valueLabel = [[UILabel alloc] init];
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.text = @"50";
  self.valueLabel.textColor = [UIColor whiteColor];
  self.valueLabel.font = [UIFont systemFontOfSize:13];
  self.valueLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
  self.valueLabel.layer.cornerRadius = 4;
  self.valueLabel.textAlignment = NSTextAlignmentCenter;
  self.valueLabel.hidden = YES;
  [self.sliderContainer addSubview:self.valueLabel];

  // Slider
  self.valueSlider = [[UISlider alloc] init];
  self.valueSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueSlider.minimumValue = 0;
  self.valueSlider.maximumValue = 100;
  self.valueSlider.value = 50;
  self.valueSlider.minimumTrackTintColor = [UIColor whiteColor];
  self.valueSlider.maximumTrackTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
  self.valueSlider.thumbTintColor = [UIColor whiteColor];
  [self.valueSlider addTarget:self
                       action:@selector(sliderValueChanged:)
             forControlEvents:UIControlEventValueChanged];
  [self.sliderContainer addSubview:self.valueSlider];

  [NSLayoutConstraint activateConstraints:@[
    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.sliderContainer.leadingAnchor
                                                  constant:16],
    [self.valueLabel.topAnchor constraintEqualToAnchor:self.sliderContainer.topAnchor constant:-5],
    [self.valueLabel.widthAnchor constraintGreaterThanOrEqualToConstant:40],
    [self.valueLabel.heightAnchor constraintEqualToConstant:24],

    [self.valueSlider.leadingAnchor constraintEqualToAnchor:self.sliderContainer.leadingAnchor
                                                   constant:16],
    [self.valueSlider.trailingAnchor constraintEqualToAnchor:self.sliderContainer.trailingAnchor
                                                    constant:-80],  // Reserve space for Before/After button
    [self.valueSlider.centerYAnchor constraintEqualToAnchor:self.sliderContainer.centerYAnchor],
    [self.valueSlider.heightAnchor constraintEqualToConstant:30]
  ]];

  // Before/After compare button
  self.beforeAfterButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.beforeAfterButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.beforeAfterButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
  self.beforeAfterButton.layer.cornerRadius = 25;  // 50 / 2 = 25
  self.beforeAfterButton.layer.masksToBounds = YES;

  UIImage *beforeAfterIcon = [UIImage imageNamed:@"before_after"];
  if (!beforeAfterIcon) {
    if (@available(iOS 13.0, *)) {
      beforeAfterIcon = [UIImage systemImageNamed:@"arrow.left.arrow.right"];
      beforeAfterIcon = [beforeAfterIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
  } else {
    beforeAfterIcon = [beforeAfterIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }

  UIImageView *iconView = [[UIImageView alloc] initWithImage:beforeAfterIcon];
  iconView.tintColor = [UIColor whiteColor];
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.beforeAfterButton addSubview:iconView];

  // Only set icon constraints inside the button, button's own constraints are set in setupPanelConstraints
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:22],
    [iconView.heightAnchor constraintEqualToConstant:22],
    [iconView.centerXAnchor constraintEqualToAnchor:self.beforeAfterButton.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:self.beforeAfterButton.centerYAnchor]
  ]];

  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterButtonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
  // Hold to preview original: press to disable all parameters, release to restore user-set parameters
  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterTouchDown:)
                   forControlEvents:UIControlEventTouchDown];
  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterTouchUp:)
                   forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                                     UIControlEventTouchCancel)];
  self.beforeAfterButton.hidden = YES;  // Hidden by default, shown/hidden together with slider
  [self.view addSubview:self.beforeAfterButton];
}

- (void)showSlider {
  self.isSliderVisible = YES;
  self.sliderContainer.hidden = NO;
  self.valueLabel.hidden = NO;
  // Update height constraint to show slider
  if (self.sliderContainerHeightConstraint) {
    self.sliderContainerHeightConstraint.constant = 60;
    [UIView animateWithDuration:0.2
                     animations:^{
                       [self.view layoutIfNeeded];
                     }];
  }
}

- (void)hideSlider {
  self.isSliderVisible = NO;
  self.sliderContainer.hidden = YES;
  self.valueLabel.hidden = YES;
  // Update height constraint to hide slider (height is 0)
  if (self.sliderContainerHeightConstraint) {
    self.sliderContainerHeightConstraint.constant = 0;
    [UIView animateWithDuration:0.2
                     animations:^{
                       [self.view layoutIfNeeded];
                     }];
  }
}

- (void)sliderValueChanged:(UISlider *)sender {
  NSInteger value = (NSInteger)sender.value;
  self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)value];

  // Save current function's progress (0-100)
  if (self.currentTab && self.currentFunction) {
    NSString *progressKey =
        [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
    self.functionProgress[progressKey] = @(value);
  }

  // Notify delegate of parameter change (convert progress value 0-100 to parameter value 0.0-1.0)
  if (self.currentTab && self.currentFunction &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    float paramValue = sender.value / 100.0f;
    [self.delegate beautyPanelDidChangeParam:self.currentTab
                                    function:self.currentFunction
                                       value:paramValue];
  }
}

#pragma mark - Actions

- (void)tabButtonTapped:(UIButton *)sender {
  NSInteger index = sender.tag;
  [self selectTabButton:index];

  NSArray *tabNames = @[
    @"beauty",
    @"reshape",
    @"makeup",
    @"filter",
    @"sticker",
    @"body",
    @"virtual_bg",
    @"quality"
  ];
  if (index < tabNames.count) {
    self.currentTab = tabNames[index];
    self.currentFunction = nil;  // Clear current function when switching tabs
    [self updateFunctionButtons];
    [self hideSubOptions];
    [self updateSelectionIndicators];  // Update indicators (hide all, since no function is selected after switching tabs)
  }
}

- (void)functionButtonTapped:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index < self.functionButtons.count) {
    NSArray *functions = [self functionsForCurrentTab];
    if (index < functions.count) {
      NSDictionary *function = functions[index];

      // Check if disabled: only disable when explicitly set to @NO
      NSNumber *enabled = function[@"enabled"];
      if (enabled != nil && [enabled boolValue] == NO) {
        return;  // Disabled function does not respond to clicks
      }

      NSString *functionKey = function[@"key"];

      // Handle off button
      if ([functionKey isEqualToString:@"off"]) {
        [self handleOffButtonClicked];
        return;
      }

      // Check button type: if it's toggle type, don't show slider
      NSString *buttonType = function[@"type"];
      if ([buttonType isEqualToString:@"toggle"]) {
        // Toggle type: switch state, don't show slider
        [self handleToggleFunction:functionKey];
        return;
      }

      self.currentFunction = functionKey;

      // Update selected indicator
      [self updateSelectionIndicators];

      // Show slider for adjusting parameters (slider type)
      [self showSlider];
      [self hideSubOptions];

      // Update slider initial value (based on current function's state)
      NSString *progressKey =
          [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
      NSNumber *progress = self.functionProgress[progressKey];
      if (progress) {
        self.valueSlider.value = [progress floatValue];
      } else {
        self.valueSlider.value = 0;  // Default value 0 (reference Android)
      }
      self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.valueSlider.value];

      // Immediately apply parameter once with current value to ensure it takes effect immediately after switching functions (reference Android)
      if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
        float paramValue = self.valueSlider.value / 100.0f;
        [self.delegate beautyPanelDidChangeParam:self.currentTab
                                        function:self.currentFunction
                                           value:paramValue];
      }
    }
  }
}

- (void)handleOffButtonClicked {
  // Clear current function selection
  self.currentFunction = nil;

  // Hide sub-options and slider
  [self hideSubOptions];
  [self hideSlider];

  if (!self.currentTab) {
    return;
  }

  // Clear all saved slider progress under current Tab
  NSString *prefix = [NSString stringWithFormat:@"%@:", self.currentTab];
  NSMutableArray *keysToRemove = [NSMutableArray array];
  for (NSString *key in self.functionProgress.allKeys) {
    if ([key hasPrefix:prefix]) {
      [keysToRemove addObject:key];
    }
  }
  [self.functionProgress removeObjectsForKeys:keysToRemove];

  // Determine close logic based on Tab type
  if ([self.currentTab isEqualToString:@"virtual_bg"]) {
    // Virtual background Tab: close all toggle-type function states
    NSString *togglePrefix = [NSString stringWithFormat:@"%@:", self.currentTab];
    NSMutableArray *toggleKeysToUpdate = [NSMutableArray array];
    for (NSString *key in self.toggleStates.allKeys) {
      if ([key hasPrefix:togglePrefix] && [self.toggleStates[key] boolValue]) {
        NSString *functionKey = [key substringFromIndex:togglePrefix.length];
        [toggleKeysToUpdate addObject:key];
        // TODO: Update visual state (if there's visual feedback for toggle button)
      }
    }
    for (NSString *key in toggleKeysToUpdate) {
      self.toggleStates[key] = @NO;
    }
    // Call callback, passing "none" to indicate closing virtual background
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      [self.delegate beautyPanelDidChangeParam:self.currentTab function:@"none" value:0.0f];
    }
  } else {
    // Other Tabs: close all enabled toggle-type functions one by one
    NSString *togglePrefix = [NSString stringWithFormat:@"%@:", self.currentTab];
    NSMutableArray *toggleKeysToUpdate = [NSMutableArray array];
    for (NSString *key in self.toggleStates.allKeys) {
      if ([key hasPrefix:togglePrefix] && [self.toggleStates[key] boolValue]) {
        NSString *functionKey = [key substringFromIndex:togglePrefix.length];
        [toggleKeysToUpdate addObject:key];
        // Call callback to close function
        if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:
                                                                         function:value:)]) {
          [self.delegate beautyPanelDidChangeParam:self.currentTab function:functionKey value:0.0f];
        }
        // TODO: Update visual state (if there's visual feedback for toggle button)
      }
    }
    for (NSString *key in toggleKeysToUpdate) {
      self.toggleStates[key] = @NO;
    }
    // Notify host to reset current Tab (slider-type functions)
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidResetTab:)]) {
      [self.delegate beautyPanelDidResetTab:self.currentTab];
    }
  }

  // Update selected indicator (hide all indicators)
  [self updateSelectionIndicators];
}

- (void)handleToggleFunction:(NSString *)functionKey {
  // Special handling: image button needs to open image picker
  if ([functionKey isEqualToString:@"image"] && [self.currentTab isEqualToString:@"virtual_bg"]) {
    // Image button: open image picker
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidRequestImageSelection:
                                                                               function:)]) {
      [self.delegate beautyPanelDidRequestImageSelection:self.currentTab function:functionKey];
    }
    // Don't update state, wait for image selection to complete before updating
    return;
  }

  // Regular toggle-type function: switch state (including blur and preset background)
  NSString *toggleKey = [NSString stringWithFormat:@"%@:%@", self.currentTab, functionKey];
  BOOL currentState = [self.toggleStates[toggleKey] boolValue];
  BOOL newState = !currentState;

  // Update state
  self.toggleStates[toggleKey] = @(newState);

  // Immediately call callback (1.0 = enabled, 0.0 = disabled)
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    [self.delegate beautyPanelDidChangeParam:self.currentTab
                                    function:functionKey
                                       value:newState ? 1.0f : 0.0f];
  }

  // Update visual state (if there's visual feedback for toggle button)
  // TODO: Update button's visual state (e.g., background color, border, etc.)

  // Update selected indicator (toggle type also shows selected indicator)
  self.currentFunction = functionKey;
  [self updateSelectionIndicators];

  // Toggle type doesn't show slider, only switches state
  [self hideSlider];
  [self hideSubOptions];
}

- (void)updateSelectionIndicators {
  // Build full key for currently selected function (tab:function)
  NSString *selectedKey =
      [NSString stringWithFormat:@"%@:%@", self.currentTab ?: @"", self.currentFunction ?: @""];

  // Iterate through all indicators, show selected one, hide others
  for (NSString *key in self.functionIndicatorViews.allKeys) {
    UIView *indicator = self.functionIndicatorViews[key];
    if (indicator) {
      indicator.hidden = ![key isEqualToString:selectedKey];
    }
  }
}

- (void)resetButtonTapped:(UIButton *)sender {
  // Reset slider progress to default value (0)
  self.valueSlider.value = 0;
  self.valueLabel.text = @"0";

  // Clear current function selection
  self.currentFunction = nil;

  // Update selected indicator (hide all indicators)
  [self updateSelectionIndicators];

  // Hide sub-options and slider
  [self hideSubOptions];
  [self hideSlider];

  // Clear all function progress
  [self.functionProgress removeAllObjects];

  // Clear all toggle states
  [self.toggleStates removeAllObjects];

  // Notify delegate to reset all beauty parameters
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)captureButtonTapped:(UIButton *)sender {
  // TODO: Capture photo function
}

- (void)hidePanelButtonTapped:(UIButton *)sender {
  // Hide sub-options and slider
  [self hideSubOptions];
  [self hideSlider];

  // Hide panel
  [self hidePanel];
}

- (void)beforeAfterButtonTapped:(UIButton *)sender {
  // Single click not handled, preview switch controlled by press/release events
}

- (void)beforeAfterTouchDown:(UIButton *)sender {
  // Press: disable all beauty parameters to preview original (doesn't modify saved UI numeric state)
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)beforeAfterTouchUp:(UIButton *)sender {
  // Release: restore user-set parameters (based on locally cached functionProgress/toggleStates)
  // 1) Restore slider-type parameters (beauty/reshape/makeup)
  for (NSString *key in self.functionProgress.allKeys) {
    NSArray<NSString *> *parts = [key componentsSeparatedByString:@":"];
    if (parts.count != 2) {
      continue;
    }
    NSString *tab = parts[0];
    NSString *function = parts[1];
    NSNumber *valueNumber = self.functionProgress[key];
    if (!valueNumber) {
      continue;
    }
    float paramValue = valueNumber.floatValue / 100.0f;
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      [self.delegate beautyPanelDidChangeParam:tab function:function value:paramValue];
    }
  }
  // 2) Restore toggle-type (e.g., virtual background blur/preset), true means enabled
  for (NSString *key in self.toggleStates.allKeys) {
    BOOL on = [self.toggleStates[key] boolValue];
    if (!on) {
      continue;
    }
    NSArray<NSString *> *parts = [key componentsSeparatedByString:@":"];
    if (parts.count != 2) {
      continue;
    }
    NSString *tab = parts[0];
    NSString *function = parts[1];
    // Skip image (requires external image resource retention, cannot be simply restored)
    if ([tab isEqualToString:@"virtual_bg"] && [function hasPrefix:@"image"]) {
      continue;
    }
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      [self.delegate beautyPanelDidChangeParam:tab function:function value:1.0f];
    }
  }
}

#pragma mark - Bottom Control Panel Actions

- (void)beautyButtonTapped:(UIButton *)sender {
  // Show beauty panel and switch to beauty Tab
  [self showPanel];
  [self switchToTab:@"beauty"];
}

- (void)makeupButtonTapped:(UIButton *)sender {
  // Show beauty panel and switch to makeup Tab
  [self showPanel];
  [self switchToTab:@"makeup"];
}

- (void)stickerButtonTapped:(UIButton *)sender {
  // Show beauty panel and switch to sticker Tab
  [self showPanel];
  [self switchToTab:@"sticker"];
}

- (void)filterButtonTapped:(UIButton *)sender {
  // Show beauty panel and switch to filter Tab
  [self showPanel];
  [self switchToTab:@"filter"];
}

#pragma mark - Top Bar Actions

- (void)closeButtonTapped:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidTapCloseButton)]) {
    [self.delegate beautyPanelDidTapCloseButton];
  }
}

- (void)galleryButtonTapped:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidTapGalleryButton)]) {
    [self.delegate beautyPanelDidTapGalleryButton];
  }
}

- (void)flipCameraButtonTapped:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidTapFlipCameraButton)]) {
    [self.delegate beautyPanelDidTapFlipCameraButton];
  }
}

- (void)moreButtonTapped:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidTapMoreButton)]) {
    [self.delegate beautyPanelDidTapMoreButton];
  }
}

@end
