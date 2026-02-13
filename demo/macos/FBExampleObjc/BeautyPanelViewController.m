//
//  BeautyPanelViewController.m
//  FBExampleObjc
//

#import "BeautyPanelViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface NonInterceptingContainerView : NSView
@end
@implementation NonInterceptingContainerView
- (NSView *)hitTest:(NSPoint)point {
  if ([self.superview isKindOfClass:[NSButton class]]) {
    NSPoint superPoint = [self convertPoint:point toView:self.superview];
    return [self.superview hitTest:superPoint];
  }
  return [super hitTest:point];
}
- (void)mouseDown:(NSEvent *)event {
  if ([self.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}
- (void)mouseUp:(NSEvent *)event {
  if ([self.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}
- (BOOL)acceptsFirstResponder { return NO; }
@end

@interface NonInterceptingImageView : NSImageView
@end
@implementation NonInterceptingImageView
- (NSView *)hitTest:(NSPoint)point {
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSPoint buttonPoint = [self convertPoint:point toView:buttonView];
    return [buttonView hitTest:buttonPoint];
  }
  return [super hitTest:point];
}
- (void)mouseDown:(NSEvent *)event {
  if ([self.superview.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview.superview mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}
- (void)mouseUp:(NSEvent *)event {
  if ([self.superview.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview.superview mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}
@end

@interface NonInterceptingTextField : NSTextField
@end
@implementation NonInterceptingTextField
- (NSView *)hitTest:(NSPoint)point {
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSPoint buttonPoint = [self convertPoint:point toView:buttonView];
    return [buttonView hitTest:buttonPoint];
  }
  return [super hitTest:point];
}
- (void)mouseDown:(NSEvent *)event {
  if ([self.superview.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview.superview mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}
- (void)mouseUp:(NSEvent *)event {
  if ([self.superview.superview isKindOfClass:[NSButton class]]) {
    [(NSButton *)self.superview.superview mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}
@end

@interface EventTrackingButton : NSButton
@end
@implementation EventTrackingButton
- (void)mouseDown:(NSEvent *)event { [super mouseDown:event]; }
- (void)mouseUp:(NSEvent *)event { [super mouseUp:event]; }
@end

static const CGFloat kSliderStripHeight = 40.0;

@interface BeautyPanelViewController ()
@property(nonatomic, strong) NSView *panelRootView;
@property(nonatomic, strong) NSView *sliderStripView;
@property(nonatomic, strong) NSLayoutConstraint *sliderStripHeightConstraint;
@property(nonatomic, strong) NSView *leftContainerView;
@property(nonatomic, strong) NSScrollView *tabScrollView;
@property(nonatomic, strong) NSView *tabContainer;
@property(nonatomic, strong) NSMutableArray<NSButton *> *tabButtons;
@property(nonatomic, strong) NSString *currentTab;
@property(nonatomic, strong) NSScrollView *functionScrollView;
@property(nonatomic, strong) NSView *functionButtonContainer;
@property(nonatomic, strong) NSMutableArray<NSButton *> *functionButtons;
@property(nonatomic, strong) NSSlider *valueSlider;
@property(nonatomic, strong) NSTextField *valueLabel;
@property(nonatomic, strong) NSMutableArray<NSButton *> *styleButtons;
@property(nonatomic, assign) NSInteger currentMakeupStyleIndex;
@property(nonatomic, assign) BOOL isSliderVisible;
@property(nonatomic, assign) BOOL isPanelVisible;
@property(nonatomic, strong) NSString *currentFunction;
@property(nonatomic, copy) NSString *showingSubButtonsForFunctionKey;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *functionProgress;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *makeupStyleIndex;
@property(nonatomic, strong) NSDictionary *filterMapping;
@end

@implementation BeautyPanelViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _currentTab = @"beauty";
    _tabButtons = [[NSMutableArray alloc] init];
    _functionButtons = [[NSMutableArray alloc] init];
    _isPanelVisible = YES;
    _functionProgress = [[NSMutableDictionary alloc] init];
    _makeupStyleIndex = [[NSMutableDictionary alloc] init];
    _isSliderVisible = NO;
    NSString *resourcesRoot = [[NSBundle mainBundle] resourcePath];
    if (!resourcesRoot.length) resourcesRoot = [[NSBundle mainBundle] bundlePath];
    NSString *mappingPath = [resourcesRoot stringByAppendingPathComponent:@"assets/filters/filter_mapping.json"];
    NSData *data = [NSData dataWithContentsOfFile:mappingPath];
    if (data) {
      NSError *error = nil;
      NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
      if (!error && json[@"filters"]) {
        _filterMapping = json[@"filters"];
      }
    }
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.wantsLayer = YES;
  self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
  self.view.translatesAutoresizingMaskIntoConstraints = NO;

  [self setupPanel];
  [self showPanel];
}

- (void)viewDidLayout {
  [super viewDidLayout];
  [self updateScrollViewContentSize];
}

- (void)updateScrollViewContentSize {
  [self.tabContainer setNeedsLayout:YES];
  [self.tabContainer layoutSubtreeIfNeeded];

  [self.functionButtonContainer setNeedsLayout:YES];
  [self.functionButtonContainer layoutSubtreeIfNeeded];

  if (self.tabButtons.count > 0) {
    CGFloat spacing = 16;
    CGFloat buttonHeight = 30;
    CGFloat padding = 16;
    CGFloat totalWidth = 0;

    for (NSButton *button in self.tabButtons) {
      [button sizeToFit];
      totalWidth += button.frame.size.width;
    }
    totalWidth += (self.tabButtons.count - 1) * spacing + padding * 2;

    self.tabContainer.frame = NSMakeRect(0, 0, totalWidth, buttonHeight);
  }

  NSInteger functionRowCount = self.functionButtons.count + self.styleButtons.count;
  if (functionRowCount > 0) {
    CGFloat spacing = 8;
    CGFloat buttonHeight = 80;
    CGFloat buttonWidth = 70;
    CGFloat padding = 0;
    CGFloat totalWidth = functionRowCount * buttonWidth +
        (functionRowCount - 1) * spacing + padding * 2;

    self.functionButtonContainer.frame = NSMakeRect(0, 0, totalWidth, buttonHeight);
  }
  [self.tabScrollView reflectScrolledClipView:self.tabScrollView.contentView];
  [self.functionScrollView reflectScrolledClipView:self.functionScrollView.contentView];
}

- (void)setupPanel {
  self.panelRootView = [[NSView alloc] init];
  self.panelRootView.wantsLayer = YES;
  self.panelRootView.layer.backgroundColor = [[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0] CGColor];
  self.panelRootView.translatesAutoresizingMaskIntoConstraints = NO;
  self.panelRootView.alphaValue = 1.0;
  self.panelRootView.hidden = NO;
  [self.view addSubview:self.panelRootView];

  [self setupSliderStripView];

  self.leftContainerView = [[NSView alloc] init];
  self.leftContainerView.wantsLayer = YES;
  self.leftContainerView.layer.backgroundColor = [NSColor clearColor].CGColor;
  self.leftContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.panelRootView addSubview:self.leftContainerView];

  [self setupTabScrollView];
  [self setupFunctionScrollView];

  [self setupPanelConstraints];
}

- (void)setupTabScrollView {
  self.tabScrollView = [[NSScrollView alloc] init];
  self.tabScrollView.hasHorizontalScroller = NO;
  self.tabScrollView.hasVerticalScroller = NO;
  self.tabScrollView.autohidesScrollers = YES;
  self.tabScrollView.horizontalScrollElasticity = NSScrollElasticityAllowed;
  self.tabScrollView.verticalScrollElasticity = NSScrollElasticityNone;
  self.tabScrollView.backgroundColor = [NSColor clearColor];
  self.tabScrollView.drawsBackground = NO;
  self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.leftContainerView addSubview:self.tabScrollView];

  self.tabContainer = [[NSView alloc] init];
  self.tabContainer.wantsLayer = YES;
  self.tabContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  [self.tabScrollView setDocumentView:self.tabContainer];

  NSArray<NSString *> *tabs = @[
    NSLocalizedString(@"beauty", nil),
    NSLocalizedString(@"reshape", nil),
    NSLocalizedString(@"makeup", nil),
    NSLocalizedString(@"filter", nil),
    NSLocalizedString(@"sticker", nil),
    NSLocalizedString(@"body", nil),
    NSLocalizedString(@"virtual_bg", nil),
    NSLocalizedString(@"quality", nil)
  ];

  for (NSInteger i = 0; i < tabs.count; i++) {
    NSString *tabTitle = tabs[i];
    NSButton *button = [[NSButton alloc] init];
    [button setTitle:tabTitle];
    [button setBezelStyle:NSBezelStyleRounded];
    [button setTarget:self];
    [button setAction:@selector(tabButtonTapped:)];
    [button setTag:i];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.wantsLayer = YES;
    [button setBordered:NO];
    [button setFocusRingType:NSFocusRingTypeNone];

    NSMutableAttributedString *attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:tabTitle];
    if (i == 0) {
      [attributedTitle addAttribute:NSForegroundColorAttributeName
                              value:[NSColor whiteColor]
                              range:NSMakeRange(0, tabTitle.length)];
      [attributedTitle addAttribute:NSFontAttributeName
                              value:[NSFont systemFontOfSize:16 weight:NSFontWeightMedium]
                              range:NSMakeRange(0, tabTitle.length)];
    } else {
      [attributedTitle addAttribute:NSForegroundColorAttributeName
                              value:[NSColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0]
                              range:NSMakeRange(0, tabTitle.length)];
      [attributedTitle addAttribute:NSFontAttributeName
                              value:[NSFont systemFontOfSize:16]
                              range:NSMakeRange(0, tabTitle.length)];
    }
    [button setAttributedTitle:attributedTitle];

    [self.tabContainer addSubview:button];
    [self.tabButtons addObject:button];
  }
  [self setupTabButtonConstraints];
}

- (void)setupTabButtonConstraints {
  if (self.tabButtons.count == 0) return;
  CGFloat spacing = 16;
  CGFloat buttonHeight = 30;
  CGFloat padding = 16;

  NSButton *firstButton = self.tabButtons[0];
  firstButton.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [firstButton.leadingAnchor constraintEqualToAnchor:self.tabContainer.leadingAnchor
                                              constant:padding],
    [firstButton.centerYAnchor constraintEqualToAnchor:self.tabContainer.centerYAnchor],
    [firstButton.heightAnchor constraintEqualToConstant:buttonHeight]
  ]];

  for (NSInteger i = 1; i < self.tabButtons.count; i++) {
    NSButton *button = self.tabButtons[i];
    NSButton *previousButton = self.tabButtons[i - 1];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
      [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor constant:spacing],
      [button.centerYAnchor constraintEqualToAnchor:self.tabContainer.centerYAnchor],
      [button.heightAnchor constraintEqualToConstant:buttonHeight]
    ]];
  }
  NSButton *lastButton = self.tabButtons.lastObject;
  NSLayoutConstraint *trailingConstraint =
      [lastButton.trailingAnchor constraintEqualToAnchor:self.tabContainer.trailingAnchor constant:-padding];
  trailingConstraint.priority = NSLayoutPriorityDefaultLow;
  [NSLayoutConstraint activateConstraints:@[ trailingConstraint ]];

  [self.tabContainer setNeedsLayout:YES];
  [self.tabContainer layoutSubtreeIfNeeded];
  CGFloat totalWidth = 0;
  for (NSButton *button in self.tabButtons) {
    [button sizeToFit];
    totalWidth += button.frame.size.width;
  }
  totalWidth += (self.tabButtons.count - 1) * spacing + padding * 2;
  self.tabContainer.frame = NSMakeRect(0, 0, totalWidth, buttonHeight);
}

- (void)setupFunctionScrollView {
  self.functionScrollView = [[NSScrollView alloc] init];
  self.functionScrollView.hasHorizontalScroller = NO;
  self.functionScrollView.hasVerticalScroller = NO;
  self.functionScrollView.autohidesScrollers = YES;
  self.functionScrollView.horizontalScrollElasticity = NSScrollElasticityAllowed;
  self.functionScrollView.verticalScrollElasticity = NSScrollElasticityNone;
  self.functionScrollView.scrollerStyle = NSScrollerStyleOverlay;
  self.functionScrollView.backgroundColor = [NSColor clearColor];
  self.functionScrollView.drawsBackground = NO;
  self.functionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.functionScrollView setHasVerticalScroller:NO];
  [self.functionScrollView setHasVerticalRuler:NO];
  [self.functionScrollView setVerticalScrollElasticity:NSScrollElasticityNone];
  [self.leftContainerView addSubview:self.functionScrollView];

  self.functionButtonContainer = [[NSView alloc] init];
  self.functionButtonContainer.wantsLayer = YES;
  self.functionButtonContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  [self.functionScrollView setDocumentView:self.functionButtonContainer];

  [self updateFunctionButtons];
}

- (void)updateFunctionButtons {
  for (NSButton *button in self.functionButtons) {
    [button removeFromSuperview];
  }
  [self.functionButtons removeAllObjects];
  for (NSButton *b in self.styleButtons) {
    [b removeFromSuperview];
  }
  [self.styleButtons removeAllObjects];

  if (self.showingSubButtonsForFunctionKey.length > 0) {
    [self buildSubButtonsInFunctionRow];
    return;
  }
  NSArray *functions = [self functionsForCurrentTab];
  for (NSInteger i = 0; i < functions.count; i++) {
    NSDictionary *function = functions[i];
    NSButton *button = [self createFunctionButton:function];
    button.tag = i;
    [self.functionButtonContainer addSubview:button];
    [self.functionButtons addObject:button];
  }
  [self setupFunctionButtonConstraints];
}

- (void)buildSubButtonsInFunctionRow {
  NSDictionary *config = [self currentFunctionConfigForKey:self.showingSubButtonsForFunctionKey];
  NSArray *subOptions = config[@"subOptions"];
  if (subOptions.count == 0) {
    self.showingSubButtonsForFunctionKey = nil;
    [self updateFunctionButtons];
    return;
  }
  NSInteger backTag = -1;
  NSButton *backButton = [self createBackButton];
  backButton.tag = backTag;
  [self.functionButtonContainer addSubview:backButton];
  [self.functionButtons addObject:backButton];

  NSNumber *stored = self.makeupStyleIndex[self.showingSubButtonsForFunctionKey];
  NSInteger selectedIndex = stored ? [stored integerValue] : 0;
  if (selectedIndex >= (NSInteger)subOptions.count) selectedIndex = 0;
  NSString *styleIconName = [self.showingSubButtonsForFunctionKey isEqualToString:@"lipstick"]
                               ? @"lipstick"
                               : @"meizhuang";
  for (NSInteger i = 0; i < (NSInteger)subOptions.count; i++) {
    NSDictionary *opt = subOptions[i];
    NSString *titleKey = opt[@"titleKey"];
    NSString *title = titleKey.length ? NSLocalizedString(titleKey, nil) : opt[@"key"];
    BOOL selected = (i == selectedIndex);
    NSButton *btn = [self createStyleButtonWithTitle:title
                                                 icon:styleIconName
                                                  tag:i
                                            selected:selected];
    [btn setAction:@selector(subButtonInRowTapped:)];
    [self.functionButtonContainer addSubview:btn];
    [self.styleButtons addObject:btn];
  }
  [self setupSubButtonsInRowConstraints];
}

- (NSDictionary *)currentFunctionConfigForKey:(NSString *)functionKey {
  NSArray *functions = [self functionsForCurrentTab];
  for (NSDictionary *f in functions) {
    if ([f[@"key"] isEqualToString:functionKey]) return f;
  }
  return nil;
}

- (NSButton *)createBackButton {
  NSButton *button = [[NSButton alloc] init];
  [button setTitle:@""];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.wantsLayer = YES;
  [button setBordered:NO];
  button.tag = -1;

  NSView *iconContainer = [[NSView alloc] init];
  iconContainer.wantsLayer = YES;
  iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor];
  iconContainer.layer.cornerRadius = 20;
  iconContainer.translatesAutoresizingMaskIntoConstraints = NO;

  NSImageView *iconView = [[NSImageView alloc] init];
  if (@available(macOS 11.0, *)) {
    NSImage *img = [NSImage imageWithSystemSymbolName:@"chevron.left" accessibilityDescription:nil];
    if (img) {
      [img setTemplate:YES];
      iconView.image = img;
    }
  }
  if (@available(macOS 10.14, *)) {
    iconView.contentTintColor = [NSColor whiteColor];
  }
  iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;
  [iconContainer addSubview:iconView];

  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = NSLocalizedString(@"back", nil);
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  titleLabel.textColor = [NSColor whiteColor];
  titleLabel.font = [NSFont systemFontOfSize:12];
  titleLabel.alignment = NSTextAlignmentCenter;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  [button addSubview:iconContainer];
  [button addSubview:titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [iconContainer.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [iconContainer.topAnchor constraintEqualToAnchor:button.topAnchor],
    [iconContainer.widthAnchor constraintEqualToConstant:40],
    [iconContainer.heightAnchor constraintEqualToConstant:40],
    [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
    [iconView.widthAnchor constraintEqualToConstant:24],
    [iconView.heightAnchor constraintEqualToConstant:24],
    [titleLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [titleLabel.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:2],
    [titleLabel.widthAnchor constraintLessThanOrEqualToConstant:70],
    [button.widthAnchor constraintEqualToConstant:70]
  ]];
  [button setTarget:self];
  [button setAction:@selector(backFromSubButtonsTapped:)];
  return button;
}

- (void)setupSubButtonsInRowConstraints {
  CGFloat spacing = 8;
  CGFloat buttonWidth = 70;
  CGFloat buttonHeight = 80;
  NSInteger count = self.functionButtons.count + self.styleButtons.count;
  if (count == 0) return;
  NSButton *firstButton = self.functionButtons.firstObject;
  firstButton.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [firstButton.leadingAnchor constraintEqualToAnchor:self.functionButtonContainer.leadingAnchor],
    [firstButton.centerYAnchor constraintEqualToAnchor:self.functionButtonContainer.centerYAnchor],
    [firstButton.widthAnchor constraintEqualToConstant:buttonWidth],
    [firstButton.heightAnchor constraintEqualToConstant:buttonHeight]
  ]];
  NSButton *prev = firstButton;
  for (NSButton *btn in self.styleButtons) {
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
      [btn.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor constant:spacing],
      [btn.centerYAnchor constraintEqualToAnchor:self.functionButtonContainer.centerYAnchor],
      [btn.widthAnchor constraintEqualToConstant:buttonWidth],
      [btn.heightAnchor constraintEqualToConstant:buttonHeight]
    ]];
    prev = btn;
  }
  [self.functionButtonContainer setNeedsLayout:YES];
  [self.functionButtonContainer layoutSubtreeIfNeeded];
  CGFloat totalWidth = count * buttonWidth + (count - 1) * spacing;
  self.functionButtonContainer.frame = NSMakeRect(0, 0, totalWidth, 80);
}

- (void)backFromSubButtonsTapped:(NSButton *)sender {
  self.showingSubButtonsForFunctionKey = nil;
  [self updateFunctionButtons];
}

- (void)subButtonInRowTapped:(NSButton *)sender {
  NSInteger index = sender.tag;
  NSDictionary *config = [self currentFunctionConfigForKey:self.showingSubButtonsForFunctionKey];
  NSArray *subOptions = config[@"subOptions"];
  if (index < 0 || index >= (NSInteger)subOptions.count) return;
  NSString *parentKey = self.showingSubButtonsForFunctionKey;
  self.currentFunction = parentKey;
  self.currentMakeupStyleIndex = index;
  self.makeupStyleIndex[parentKey] = @(index);
  self.showingSubButtonsForFunctionKey = nil;

  [self updateFunctionButtons];
  [self showSlider];
  NSString *progressKey = [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
  NSNumber *progress = self.functionProgress[progressKey];
  double defaultVal = 0;
  self.valueSlider.doubleValue = progress ? [progress doubleValue] : defaultVal;
  self.valueLabel.stringValue = [NSString stringWithFormat:@"%.0f", self.valueSlider.doubleValue];

  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeMakeupStyle:styleIndex:)]) {
    [self.delegate beautyPanelDidChangeMakeupStyle:parentKey styleIndex:index];
  }
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    float paramValue = (float)(self.valueSlider.doubleValue / 100.0);
    [self.delegate beautyPanelDidChangeParam:self.currentTab function:self.currentFunction value:paramValue];
  }
}

- (NSString *)filterMappingLanguageKey {
  NSString *preferred = [NSLocale preferredLanguages].firstObject;
  return (preferred && [preferred hasPrefix:@"zh"]) ? @"zh" : @"en";
}

- (NSArray *)functionsForCurrentTab {
  if ([self.currentTab isEqualToString:@"beauty"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"white", @"title" : NSLocalizedString(@"whitening", nil), @"icon" : @"meiyan"},
      @{@"key" : @"smooth", @"title" : NSLocalizedString(@"smoothing", nil), @"icon" : @"meiyan2"},
      @{@"key" : @"ai", @"title" : NSLocalizedString(@"rosiness", nil), @"icon" : @"meiyan"}
    ];
  } else if ([self.currentTab isEqualToString:@"reshape"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"thin_face", @"title" : NSLocalizedString(@"thin_face", nil), @"icon" : @"meixing2"},
      @{@"key" : @"v_face", @"title" : NSLocalizedString(@"v_face", nil), @"icon" : @"meixing2"},
      @{@"key" : @"narrow_face", @"title" : NSLocalizedString(@"narrow_face", nil), @"icon" : @"meixing2"},
      @{@"key" : @"short_face", @"title" : NSLocalizedString(@"short_face", nil), @"icon" : @"meixing2"},
      @{@"key" : @"cheekbone", @"title" : NSLocalizedString(@"cheekbone", nil), @"icon" : @"meixing2"},
      @{@"key" : @"jawbone", @"title" : NSLocalizedString(@"jawbone", nil), @"icon" : @"jawbone"},
      @{@"key" : @"chin", @"title" : NSLocalizedString(@"chin", nil), @"icon" : @"chin"},
      @{@"key" : @"nose_slim", @"title" : NSLocalizedString(@"nose_slim", nil), @"icon" : @"nose"},
      @{@"key" : @"big_eye", @"title" : NSLocalizedString(@"big_eye", nil), @"icon" : @"eyes"},
      @{@"key" : @"eye_distance", @"title" : NSLocalizedString(@"eye_distance", nil), @"icon" : @"eyes"}
    ];
  } else if ([self.currentTab isEqualToString:@"makeup"]) {
    NSArray *lipstickSub = @[
      @{@"key" : @"0", @"titleKey" : @"makeup_lipstick_style_moist"},
      @{@"key" : @"1", @"titleKey" : @"makeup_lipstick_style_vitality"},
      @{@"key" : @"2", @"titleKey" : @"makeup_lipstick_style_retro"}
    ];
    NSArray *blushSub = @[
      @{@"key" : @"0", @"titleKey" : @"makeup_blush_style_japanese"},
      @{@"key" : @"1", @"titleKey" : @"makeup_blush_style_sector"},
      @{@"key" : @"2", @"titleKey" : @"makeup_blush_style_tipsy"}
    ];
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"lipstick", @"title" : NSLocalizedString(@"lipstick", nil), @"icon" : @"lipstick", @"subOptions" : lipstickSub},
      @{@"key" : @"blush", @"title" : NSLocalizedString(@"blush", nil), @"icon" : @"meizhuang", @"subOptions" : blushSub},
      @{@"key" : @"eyebrow", @"title" : NSLocalizedString(@"eyebrow", nil), @"icon" : @"eyebrow"},
      @{@"key" : @"eyeshadow", @"title" : NSLocalizedString(@"eyeshadow", nil), @"icon" : @"eyeshadow"}
    ];
  } else if ([self.currentTab isEqualToString:@"filter"]) {
    NSMutableArray *filters = [NSMutableArray array];
    [filters addObject:@{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"}];
    NSString *langKey = [self filterMappingLanguageKey];
    NSArray *filterKeys = @[
      @"initial_heart", @"first_love", @"vivid", @"confession", @"milk_tea", @"mousse",
      @"japanese", @"dawn", @"cookie", @"lively", @"pure", @"fair", @"snow", @"plain",
      @"natural", @"rose", @"tender", @"tender_2", @"extraordinary"
    ];
    for (NSString *key in filterKeys) {
      NSString *title = key;
      if (self.filterMapping && self.filterMapping[key]) {
        NSString *mapped = self.filterMapping[key][langKey];
        if (mapped.length) title = mapped;
      }
      [filters addObject:@{@"key" : key, @"title" : title, @"icon" : @"lvjing"}];
    }
    return filters;
  } else if ([self.currentTab isEqualToString:@"sticker"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"rabbit", @"title" : NSLocalizedString(@"rabbit", nil), @"icon" : @"rabbit", @"slider" : @NO}
    ];
  } else if ([self.currentTab isEqualToString:@"body"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"slim", @"title" : NSLocalizedString(@"slim", nil), @"icon" : @"meiti"}
    ];
  } else if ([self.currentTab isEqualToString:@"virtual_bg"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable", @"slider" : @NO},
      @{@"key" : @"blur", @"title" : NSLocalizedString(@"blur", nil), @"icon" : @"blur", @"slider" : @NO},
      @{@"key" : @"preset", @"title" : NSLocalizedString(@"virtual_bg_image", nil), @"icon" : @"back_preset", @"slider" : @NO}
    ];
  } else if ([self.currentTab isEqualToString:@"quality"]) {
    return @[
      @{@"key" : @"off", @"title" : NSLocalizedString(@"off", nil), @"icon" : @"disable"},
      @{@"key" : @"sharpen", @"title" : NSLocalizedString(@"sharpen", nil), @"icon" : @"huazhitiaozheng2"}
    ];
  }

  return @[];
}

- (NSButton *)createFunctionButton:(NSDictionary *)function {
  NSButton *button = [[NSButton alloc] init];
  [button setTitle:@""];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.wantsLayer = YES;
  [button setBordered:NO];

  NSView *iconContainer = [[NSView alloc] init];
  iconContainer.wantsLayer = YES;
  iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor];
  iconContainer.layer.cornerRadius = 20;
  iconContainer.translatesAutoresizingMaskIntoConstraints = NO;

  NSImageView *iconView = [[NSImageView alloc] init];
  NSString *iconName = function[@"icon"];
  NSImage *iconImage = [NSImage imageNamed:iconName];
  if (!iconImage && iconName.length > 0 && @available(macOS 11.0, *)) {
    iconImage = [NSImage imageWithSystemSymbolName:iconName accessibilityDescription:nil];
  }
  if (!iconImage) {
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:@"circle.fill" accessibilityDescription:nil];
    } else {
      iconImage = [[NSImage alloc] initWithSize:NSMakeSize(28, 28)];
      [iconImage lockFocus];
      [[NSColor whiteColor] set];
      NSRectFill(NSMakeRect(0, 0, 28, 28));
      [iconImage unlockFocus];
    }
  }
  if (iconImage) {
    NSImage *templateImage = [iconImage copy];
    [templateImage setTemplate:YES];
    iconImage = templateImage;
  }

  iconView.image = iconImage;
  if (@available(macOS 10.14, *)) {
    iconView.contentTintColor = [NSColor whiteColor];
  }
  iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;

  [iconContainer addSubview:iconView];

  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = function[@"title"];
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  titleLabel.textColor = [NSColor whiteColor];
  titleLabel.font = [NSFont systemFontOfSize:12];
  titleLabel.alignment = NSTextAlignmentCenter;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  NSView *indicator = [[NSView alloc] init];
  indicator.wantsLayer = YES;
  indicator.layer.backgroundColor = [[NSColor colorWithRed:0.0 green:1.0 blue:0.0
                                                     alpha:1.0] CGColor];
  indicator.layer.cornerRadius = 1.5;
  indicator.hidden = YES;
  indicator.translatesAutoresizingMaskIntoConstraints = NO;

  [button addSubview:iconContainer];
  [button addSubview:titleLabel];
  [button addSubview:indicator];

  [NSLayoutConstraint activateConstraints:@[
    [iconContainer.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [iconContainer.topAnchor constraintEqualToAnchor:button.topAnchor],
    [iconContainer.widthAnchor constraintEqualToConstant:40],
    [iconContainer.heightAnchor constraintEqualToConstant:40],
    [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
    [iconView.widthAnchor constraintEqualToConstant:24],
    [iconView.heightAnchor constraintEqualToConstant:24],
    [titleLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [titleLabel.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:2],
    [titleLabel.widthAnchor constraintLessThanOrEqualToConstant:70],
    [indicator.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [indicator.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2],
    [indicator.widthAnchor constraintEqualToConstant:14],
    [indicator.heightAnchor constraintEqualToConstant:3],
    [button.widthAnchor constraintEqualToConstant:70]
  ]];

  [button setTarget:self];
  [button setAction:@selector(functionButtonTapped:)];
  [button setEnabled:YES];
  return button;
}

- (void)setupFunctionButtonConstraints {
  if (self.functionButtons.count == 0) return;
  CGFloat spacing = 8;
  CGFloat buttonHeight = 80;
  CGFloat buttonWidth = 70;
  CGFloat padding = 0;

  NSButton *firstButton = self.functionButtons[0];
  firstButton.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [firstButton.leadingAnchor constraintEqualToAnchor:self.functionButtonContainer.leadingAnchor
                                              constant:padding],
    [firstButton.centerYAnchor constraintEqualToAnchor:self.functionButtonContainer.centerYAnchor],
    [firstButton.widthAnchor constraintEqualToConstant:buttonWidth],
    [firstButton.heightAnchor constraintEqualToConstant:buttonHeight]
  ]];

  for (NSInteger i = 1; i < self.functionButtons.count; i++) {
    NSButton *button = self.functionButtons[i];
    NSButton *previousButton = self.functionButtons[i - 1];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
      [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor constant:spacing],
      [button.centerYAnchor constraintEqualToAnchor:self.functionButtonContainer.centerYAnchor],
      [button.widthAnchor constraintEqualToConstant:buttonWidth],
      [button.heightAnchor constraintEqualToConstant:buttonHeight]
    ]];
  }
  [self.functionButtonContainer setNeedsLayout:YES];
  [self.functionButtonContainer layoutSubtreeIfNeeded];
  CGFloat totalWidth = self.functionButtons.count * buttonWidth +
      (self.functionButtons.count - 1) * spacing + padding * 2;
  CGFloat scrollViewHeight = 80;
  self.functionButtonContainer.frame = NSMakeRect(0, 0, totalWidth, scrollViewHeight);
}

- (void)setupPanelConstraints {
  self.sliderStripHeightConstraint =
      [self.sliderStripView.heightAnchor constraintEqualToConstant:0];

  [NSLayoutConstraint activateConstraints:@[
    [self.panelRootView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.panelRootView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.panelRootView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.panelRootView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.sliderStripView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.sliderStripView.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.sliderStripView.topAnchor constraintEqualToAnchor:self.panelRootView.topAnchor],
    self.sliderStripHeightConstraint,
    [self.leftContainerView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.leftContainerView.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.leftContainerView.topAnchor constraintEqualToAnchor:self.sliderStripView.bottomAnchor],
    [self.leftContainerView.bottomAnchor constraintEqualToAnchor:self.panelRootView.bottomAnchor],
    [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.leftContainerView.leadingAnchor],
    [self.tabScrollView.trailingAnchor
        constraintEqualToAnchor:self.leftContainerView.trailingAnchor],
    [self.tabScrollView.topAnchor constraintEqualToAnchor:self.leftContainerView.topAnchor],
    [self.tabScrollView.heightAnchor constraintEqualToConstant:40],
    [self.functionScrollView.leadingAnchor
        constraintEqualToAnchor:self.leftContainerView.leadingAnchor constant:16],
    [self.functionScrollView.trailingAnchor
        constraintEqualToAnchor:self.leftContainerView.trailingAnchor
                       constant:-16],
    [self.functionScrollView.topAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor
                                                      constant:12],
    [self.functionScrollView.heightAnchor constraintEqualToConstant:80]
  ]];
}

#pragma mark - Button Actions

- (void)tabButtonTapped:(NSButton *)sender {
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
    self.showingSubButtonsForFunctionKey = nil;
    [self updateFunctionButtons];
    [self hideSlider];
  }
}

- (void)selectTabButton:(NSInteger)index {
  for (NSInteger i = 0; i < self.tabButtons.count; i++) {
    NSButton *button = self.tabButtons[i];
    NSString *title = button.title;

    NSMutableAttributedString *attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:title];
    if (i == index) {
      [attributedTitle addAttribute:NSForegroundColorAttributeName
                              value:[NSColor whiteColor]
                              range:NSMakeRange(0, title.length)];
      [attributedTitle addAttribute:NSFontAttributeName
                              value:[NSFont systemFontOfSize:16 weight:NSFontWeightMedium]
                              range:NSMakeRange(0, title.length)];
    } else {
      [attributedTitle addAttribute:NSForegroundColorAttributeName
                              value:[NSColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0]
                              range:NSMakeRange(0, title.length)];
      [attributedTitle addAttribute:NSFontAttributeName
                              value:[NSFont systemFontOfSize:16]
                              range:NSMakeRange(0, title.length)];
    }
    [button setAttributedTitle:attributedTitle];
  }
}

- (BOOL)functionNeedsSlider:(NSDictionary *)function {
  if ([function[@"key"] isEqualToString:@"off"]) return NO;
  NSNumber *slider = function[@"slider"];
  return (slider == nil || [slider boolValue]);
}

- (void)functionButtonTapped:(NSButton *)sender {
  if (sender.tag >= self.functionButtons.count) return;
  NSArray *functions = [self functionsForCurrentTab];
  if (sender.tag >= functions.count) return;
  NSDictionary *function = functions[sender.tag];
  NSString *functionKey = function[@"key"];
  NSArray *subOptions = function[@"subOptions"];
  if (subOptions.count > 0) {
    self.showingSubButtonsForFunctionKey = functionKey;
    [self updateFunctionButtons];
    return;
  }
  self.currentFunction = functionKey;
  if ([self functionNeedsSlider:function]) {
    [self showSlider];
    NSString *progressKey = [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
    NSNumber *progress = self.functionProgress[progressKey];
    double defaultVal = [self.currentTab isEqualToString:@"filter"] ? 80 : 0;
    self.valueSlider.doubleValue = progress ? [progress doubleValue] : defaultVal;
    self.valueLabel.stringValue = [NSString stringWithFormat:@"%.0f", self.valueSlider.doubleValue];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      float paramValue = (float)(self.valueSlider.doubleValue / 100.0);
      [self.delegate beautyPanelDidChangeParam:self.currentTab
                                      function:self.currentFunction
                                         value:paramValue];
    }
  } else {
    [self hideSlider];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      [self.delegate beautyPanelDidChangeParam:self.currentTab
                                      function:self.currentFunction
                                         value:0];
    }
  }
}

#pragma mark - Public Methods

- (void)showPanel {
  self.isPanelVisible = YES;
  self.panelRootView.hidden = NO;
  self.panelRootView.alphaValue = 1.0;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BeautyPanelVisibilityChanged"
                                                      object:@YES];
}

- (void)hidePanel {
  self.isPanelVisible = NO;
  [self hideSlider];
  self.panelRootView.hidden = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BeautyPanelVisibilityChanged"
                                                      object:@NO];
}

- (void)togglePanelVisibility {
  if (self.isPanelVisible) {
    [self hidePanel];
  } else {
    [self showPanel];
  }
}

- (void)switchToTab:(NSString *)tab {
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
  NSInteger index = [tabNames indexOfObject:tab];
  if (index != NSNotFound && index < self.tabButtons.count) {
    [self selectTabButton:index];
    [self tabButtonTapped:self.tabButtons[index]];
  }
}

#pragma mark - Slider Strip (above tab row, overlays video)

- (void)setupSliderStripView {
  self.sliderStripView = [[NSView alloc] init];
  self.sliderStripView.wantsLayer = YES;
  self.sliderStripView.layer.backgroundColor =
      [[NSColor colorWithWhite:0.12 alpha:0.95] CGColor];
  self.sliderStripView.translatesAutoresizingMaskIntoConstraints = NO;
  self.sliderStripView.hidden = YES;
  [self.panelRootView addSubview:self.sliderStripView];

  self.valueSlider = [[NSSlider alloc] init];
  self.valueSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueSlider.minValue = 0;
  self.valueSlider.maxValue = 100;
  self.valueSlider.doubleValue = 50;
  self.valueSlider.target = self;
  self.valueSlider.action = @selector(sliderValueChanged:);
  self.valueSlider.enabled = NO;
  [self.sliderStripView addSubview:self.valueSlider];

  self.valueLabel = [[NSTextField alloc] init];
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.stringValue = @"50";
  self.valueLabel.textColor = [NSColor whiteColor];
  self.valueLabel.font = [NSFont systemFontOfSize:13];
  self.valueLabel.backgroundColor = [NSColor clearColor];
  self.valueLabel.bordered = NO;
  self.valueLabel.editable = NO;
  self.valueLabel.alignment = NSTextAlignmentRight;
  self.valueLabel.wantsLayer = YES;
  [self.sliderStripView addSubview:self.valueLabel];

  static const CGFloat kSliderWidth = 400.0;
  static const CGFloat kSliderLabelGap = 8.0;
  static const CGFloat kLabelWidth = 36.0;
  static const CGFloat kSliderGroupWidth = kSliderWidth + kSliderLabelGap + kLabelWidth;
  [NSLayoutConstraint activateConstraints:@[
    [self.valueSlider.leadingAnchor constraintEqualToAnchor:self.sliderStripView.centerXAnchor
                                                   constant:-kSliderGroupWidth / 2.0],
    [self.valueSlider.widthAnchor constraintEqualToConstant:kSliderWidth],
    [self.valueSlider.centerYAnchor constraintEqualToAnchor:self.sliderStripView.centerYAnchor],
    [self.valueSlider.heightAnchor constraintEqualToConstant:24],
    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.valueSlider.trailingAnchor
                                                 constant:kSliderLabelGap],
    [self.valueLabel.centerYAnchor constraintEqualToAnchor:self.sliderStripView.centerYAnchor],
    [self.valueLabel.widthAnchor constraintEqualToConstant:kLabelWidth],
    [self.valueLabel.heightAnchor constraintEqualToConstant:20]
  ]];

  self.styleButtons = [[NSMutableArray alloc] init];
}

- (void)showSlider {
  self.isSliderVisible = YES;
  self.valueSlider.enabled = YES;
  self.sliderStripView.hidden = NO;
  self.sliderStripHeightConstraint.constant = kSliderStripHeight;
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelSliderVisibilityDidChange:)]) {
    [self.delegate beautyPanelSliderVisibilityDidChange:YES];
  }
}

- (void)hideSlider {
  self.isSliderVisible = NO;
  self.valueSlider.enabled = NO;
  self.sliderStripView.hidden = YES;
  self.sliderStripHeightConstraint.constant = 0;
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelSliderVisibilityDidChange:)]) {
    [self.delegate beautyPanelSliderVisibilityDidChange:NO];
  }
}

- (NSDictionary *)currentFunctionConfig {
  NSArray *functions = [self functionsForCurrentTab];
  for (NSDictionary *f in functions) {
    if ([f[@"key"] isEqualToString:self.currentFunction]) return f;
  }
  return nil;
}

- (NSButton *)createStyleButtonWithTitle:(NSString *)title
                                   icon:(NSString *)iconName
                                 tag:(NSInteger)tag
                               selected:(BOOL)selected {
  NSButton *button = [[NSButton alloc] init];
  [button setTitle:@""];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.wantsLayer = YES;
  [button setBordered:NO];
  button.tag = tag;

  NSView *iconContainer = [[NSView alloc] init];
  iconContainer.wantsLayer = YES;
  iconContainer.layer.cornerRadius = 20;
  iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
  if (selected) {
    iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1.0] CGColor];
  } else {
    iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor];
  }

  NSImageView *iconView = [[NSImageView alloc] init];
  NSImage *iconImage = [NSImage imageNamed:iconName];
  if (!iconImage && iconName.length > 0) {
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:iconName accessibilityDescription:nil];
    }
  }
  if (!iconImage) {
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:@"circle.fill" accessibilityDescription:nil];
    }
  }
  if (iconImage) {
    NSImage *templateImage = [iconImage copy];
    [templateImage setTemplate:YES];
    iconImage = templateImage;
  }
  iconView.image = iconImage;
  if (@available(macOS 10.14, *)) {
    iconView.contentTintColor = [NSColor whiteColor];
  }
  iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;
  [iconContainer addSubview:iconView];

  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = title;
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  titleLabel.textColor = [NSColor whiteColor];
  titleLabel.font = [NSFont systemFontOfSize:12];
  titleLabel.alignment = NSTextAlignmentCenter;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  [button addSubview:iconContainer];
  [button addSubview:titleLabel];

  [NSLayoutConstraint activateConstraints:@[
    [iconContainer.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [iconContainer.topAnchor constraintEqualToAnchor:button.topAnchor],
    [iconContainer.widthAnchor constraintEqualToConstant:40],
    [iconContainer.heightAnchor constraintEqualToConstant:40],
    [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
    [iconView.widthAnchor constraintEqualToConstant:24],
    [iconView.heightAnchor constraintEqualToConstant:24],
    [titleLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [titleLabel.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:2],
    [titleLabel.widthAnchor constraintLessThanOrEqualToConstant:70]
  ]];

  [button setTarget:self];
  [button setAction:@selector(styleButtonTapped:)];
  return button;
}

- (void)updateStyleButtons {
  /* Sub-buttons are now shown in the function row via buildSubButtonsInFunctionRow. No-op. */
}

- (void)styleButtonTapped:(NSButton *)sender {
  NSInteger index = sender.tag;
  NSDictionary *config = [self currentFunctionConfig];
  NSArray *subOptions = config[@"subOptions"];
  if (index < 0 || index >= (NSInteger)subOptions.count) return;
  self.currentMakeupStyleIndex = index;
  self.makeupStyleIndex[self.currentFunction] = @(index);
  for (NSInteger i = 0; i < (NSInteger)self.styleButtons.count; i++) {
    NSButton *b = self.styleButtons[i];
    BOOL selected = (i == index);
    NSView *iconContainer = b.subviews.firstObject;
    if (iconContainer.wantsLayer && iconContainer.layer) {
      iconContainer.layer.backgroundColor = selected
          ? [[NSColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1.0] CGColor]
          : [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor];
    }
  }
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeMakeupStyle:styleIndex:)]) {
    [self.delegate beautyPanelDidChangeMakeupStyle:self.currentFunction styleIndex:(NSInteger)index];
  }
}

- (void)sliderValueChanged:(NSSlider *)sender {
  NSInteger value = (NSInteger)sender.doubleValue;
  self.valueLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)value];
  if (self.currentTab && self.currentFunction) {
    NSString *progressKey = [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
    self.functionProgress[progressKey] = @(value);
  }
  if (self.currentTab && self.currentFunction && self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    float paramValue = (float)(sender.doubleValue / 100.0);
    [self.delegate beautyPanelDidChangeParam:self.currentTab
                                    function:self.currentFunction
                                       value:paramValue];
  }
}

@end
