//
//  BeautyPanelViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//  Updated for new UI matching iOS layout
//

#import "BeautyPanelViewController.h"
#import <QuartzCore/QuartzCore.h>

// 自定义容器视图类，不拦截鼠标事件
@interface NonInterceptingContainerView : NSView
@end

@implementation NonInterceptingContainerView

- (NSView *)hitTest:(NSPoint)point {
  // 返回父视图（按钮），让按钮接收点击事件
  NSLog(@"[NonInterceptingContainerView] hitTest - returning superview: %@", self.superview);
  if ([self.superview isKindOfClass:[NSButton class]]) {
    // 将点转换到父视图的坐标系
    NSPoint superPoint = [self convertPoint:point toView:self.superview];
    return [self.superview hitTest:superPoint];
  }
  return [super hitTest:point];
}

- (void)mouseDown:(NSEvent *)event {
  NSLog(@"[NonInterceptingContainerView] mouseDown - forwarding to superview: %@", self.superview);
  // 直接调用父按钮的 mouseDown
  if ([self.superview isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)self.superview;
    [button mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}

- (void)mouseUp:(NSEvent *)event {
  NSLog(@"[NonInterceptingContainerView] mouseUp - forwarding to superview: %@", self.superview);
  // 直接调用父按钮的 mouseUp，这会触发按钮的 action
  if ([self.superview isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)self.superview;
    [button mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}

- (BOOL)acceptsFirstResponder {
  return NO;  // 不接受第一响应者，让事件传递
}

@end

// 自定义图标视图类，不拦截鼠标事件
@interface NonInterceptingImageView : NSImageView
@end

@implementation NonInterceptingImageView

- (NSView *)hitTest:(NSPoint)point {
  // 返回父视图的父视图（按钮），让按钮接收点击事件
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSPoint buttonPoint = [self convertPoint:point toView:buttonView];
    return [buttonView hitTest:buttonPoint];
  }
  return [super hitTest:point];
}

- (void)mouseDown:(NSEvent *)event {
  NSLog(@"[NonInterceptingImageView] mouseDown - forwarding");
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)buttonView;
    [button mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}

- (void)mouseUp:(NSEvent *)event {
  NSLog(@"[NonInterceptingImageView] mouseUp - forwarding");
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)buttonView;
    [button mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}

@end

// 自定义标签视图类，不拦截鼠标事件
@interface NonInterceptingTextField : NSTextField
@end

@implementation NonInterceptingTextField

- (NSView *)hitTest:(NSPoint)point {
  // 返回父视图的父视图（按钮），让按钮接收点击事件
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSPoint buttonPoint = [self convertPoint:point toView:buttonView];
    return [buttonView hitTest:buttonPoint];
  }
  return [super hitTest:point];
}

- (void)mouseDown:(NSEvent *)event {
  NSLog(@"[NonInterceptingTextField] mouseDown - forwarding");
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)buttonView;
    [button mouseDown:event];
  } else {
    [super mouseDown:event];
  }
}

- (void)mouseUp:(NSEvent *)event {
  NSLog(@"[NonInterceptingTextField] mouseUp - forwarding");
  NSView *buttonView = self.superview.superview;
  if ([buttonView isKindOfClass:[NSButton class]]) {
    NSButton *button = (NSButton *)buttonView;
    [button mouseUp:event];
  } else {
    [super mouseUp:event];
  }
}

@end

// 自定义按钮类来追踪事件
@interface EventTrackingButton : NSButton
@end

@implementation EventTrackingButton

- (void)mouseDown:(NSEvent *)event {
  NSLog(@"[EventTrackingButton] mouseDown received!");
  [super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
  NSLog(@"[EventTrackingButton] mouseUp received!");
  [super mouseUp:event];
}

@end

// 自定义对比按钮类，用于处理按住和松开事件
// 前向声明
@class BeautyPanelViewController;

// 定义协议，让 BeautyPanelViewController 实现这些方法
@protocol BeforeAfterButtonDelegate <NSObject>
- (void)beforeAfterTouchDown;
- (void)beforeAfterTouchUp;
@end

@interface BeforeAfterButton : NSButton
@property(nonatomic, assign) id<BeforeAfterButtonDelegate> panelController;
@end

@implementation BeforeAfterButton

- (void)mouseDown:(NSEvent *)event {
  NSLog(@"[BeforeAfterButton] mouseDown - 按住预览原图");
  if (self.panelController &&
      [self.panelController respondsToSelector:@selector(beforeAfterTouchDown)]) {
    [self.panelController beforeAfterTouchDown];
  }
  [super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
  NSLog(@"[BeforeAfterButton] mouseUp - 松开恢复参数");
  if (self.panelController &&
      [self.panelController respondsToSelector:@selector(beforeAfterTouchUp)]) {
    [self.panelController beforeAfterTouchUp];
  }
  [super mouseUp:event];
}

@end

@interface BeautyPanelViewController () <BeforeAfterButtonDelegate>

// 主容器视图
@property(nonatomic, strong) NSView *panelRootView;

// Tab 切换区域
@property(nonatomic, strong) NSScrollView *tabScrollView;
@property(nonatomic, strong) NSView *tabContainer;
@property(nonatomic, strong) NSMutableArray<NSButton *> *tabButtons;
@property(nonatomic, strong) NSString *currentTab;

// 功能按钮区域
@property(nonatomic, strong) NSScrollView *functionScrollView;
@property(nonatomic, strong) NSView *functionButtonContainer;
@property(nonatomic, strong) NSMutableArray<NSButton *> *functionButtons;

// 底部按钮区域
@property(nonatomic, strong) NSView *bottomButtonContainer;
@property(nonatomic, strong) NSButton *resetButton;
@property(nonatomic, strong) NSButton *captureButton;
@property(nonatomic, strong) NSButton *hidePanelButton;

// 滑动条
@property(nonatomic, strong) NSView *sliderContainer;
@property(nonatomic, strong) NSSlider *valueSlider;
@property(nonatomic, strong) NSTextField *valueLabel;
@property(nonatomic, assign) BOOL isSliderVisible;
@property(nonatomic, strong) NSLayoutConstraint *sliderContainerHeightConstraint;

// Before/After 对比按钮
@property(nonatomic, strong) NSButton *beforeAfterButton;
@property(nonatomic, assign) BOOL isBeforeAfterPressed;

// 面板状态
@property(nonatomic, assign) BOOL isPanelVisible;
@property(nonatomic, strong) NSString *currentFunction;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *functionProgress;

// 对比按钮方法声明
- (void)beforeAfterTouchDown;
- (void)beforeAfterTouchUp;

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
    _isSliderVisible = NO;
    _isBeforeAfterPressed = NO;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.wantsLayer = YES;
  self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
  self.view.translatesAutoresizingMaskIntoConstraints = NO;

  [self setupPanel];
  // 默认显示面板
  [self showPanel];
}

- (void)viewDidLayout {
  [super viewDidLayout];
  // 更新滚动视图的内容大小
  [self updateScrollViewContentSize];
}

- (void)updateScrollViewContentSize {
  // 强制更新布局
  [self.tabContainer setNeedsLayout:YES];
  [self.tabContainer layoutSubtreeIfNeeded];

  [self.functionButtonContainer setNeedsLayout:YES];
  [self.functionButtonContainer layoutSubtreeIfNeeded];

  // 重新计算并设置 Tab 容器的大小
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

  // 重新计算并设置功能按钮容器的大小
  // 确保高度与滚动视图高度一致（80），防止垂直滚动
  if (self.functionButtons.count > 0) {
    CGFloat spacing = 8;
    CGFloat buttonHeight = 80;      // 功能按钮高度
    CGFloat scrollViewHeight = 80;  // 滚动视图固定高度（与约束一致）
    CGFloat buttonWidth = 70;
    CGFloat padding = 0;
    CGFloat totalWidth = self.functionButtons.count * buttonWidth +
        (self.functionButtons.count - 1) * spacing + padding * 2;

    // 确保容器高度等于滚动视图高度，防止垂直滚动
    self.functionButtonContainer.frame = NSMakeRect(0, 0, totalWidth, scrollViewHeight);
  }

  // 更新滚动视图
  [self.tabScrollView reflectScrolledClipView:self.tabScrollView.contentView];
  [self.functionScrollView reflectScrolledClipView:self.functionScrollView.contentView];
}

- (void)setupPanel {
  // 面板根视图 - 不透明深色背景（因为现在是独立的下半部分）
  self.panelRootView = [[NSView alloc] init];
  self.panelRootView.wantsLayer = YES;
  self.panelRootView.layer.backgroundColor = [[NSColor colorWithRed:0.15
                                                              green:0.15
                                                               blue:0.15
                                                              alpha:1.0] CGColor];
  self.panelRootView.translatesAutoresizingMaskIntoConstraints = NO;
  self.panelRootView.alphaValue = 1.0;
  self.panelRootView.hidden = NO;
  [self.view addSubview:self.panelRootView];

  // Tab 切换区域
  [self setupTabScrollView];

  // 功能按钮区域
  [self setupFunctionScrollView];

  // 底部按钮区域
  [self setupBottomButtonContainer];

  // 设置滑动条
  [self setupSliderContainer];

  // 设置约束
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
  [self.panelRootView addSubview:self.tabScrollView];

  self.tabContainer = [[NSView alloc] init];
  self.tabContainer.wantsLayer = YES;
  self.tabContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  // NSScrollView 的文档视图应该使用 frame-based 布局，不需要设置
  // translatesAutoresizingMaskIntoConstraints
  [self.tabScrollView setDocumentView:self.tabContainer];

  // Tab 按钮
  NSArray<NSString *> *tabs =
      @[ @"美颜", @"美型", @"美妆", @"滤镜", @"贴纸", @"美体", @"虚拟背景", @"画质调整" ];

  for (NSInteger i = 0; i < tabs.count; i++) {
    NSString *tabTitle = tabs[i];
    NSButton *button = [[NSButton alloc] init];
    [button setTitle:tabTitle];
    [button setBezelStyle:NSBezelStyleRounded];
    [button setTarget:self];
    [button setAction:@selector(tabButtonTapped:)];
    [button setTag:i];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    // 设置按钮样式
    button.wantsLayer = YES;
    [button setBordered:NO];

    // 设置文字颜色
    NSMutableAttributedString *attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:tabTitle];
    if (i == 0) {
      // 第一个默认选中
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

  // 设置 Tab 按钮约束
  [self setupTabButtonConstraints];
}

- (void)setupTabButtonConstraints {
  if (self.tabButtons.count == 0) return;

  CGFloat spacing = 16;       // Tab 按钮之间的间距
  CGFloat buttonHeight = 30;  // 减小 Tab 按钮高度
  CGFloat padding = 16;       // 左右边距

  // 设置第一个按钮约束
  NSButton *firstButton = self.tabButtons[0];
  firstButton.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [firstButton.leadingAnchor constraintEqualToAnchor:self.tabContainer.leadingAnchor
                                              constant:padding],
    [firstButton.centerYAnchor constraintEqualToAnchor:self.tabContainer.centerYAnchor],
    [firstButton.heightAnchor constraintEqualToConstant:buttonHeight]
  ]];

  // 设置其他按钮约束
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

  // 设置最后一个按钮的 trailing 约束，用于确定容器宽度
  NSButton *lastButton = self.tabButtons.lastObject;
  NSLayoutConstraint *trailingConstraint =
      [lastButton.trailingAnchor constraintEqualToAnchor:self.tabContainer.trailingAnchor
                                                constant:-padding];
  trailingConstraint.priority = NSLayoutPriorityDefaultLow;
  [NSLayoutConstraint activateConstraints:@[ trailingConstraint ]];

  // 使用 frame 设置容器大小（文档视图需要 frame-based 布局）
  [self.tabContainer setNeedsLayout:YES];
  [self.tabContainer layoutSubtreeIfNeeded];

  // 计算总宽度
  CGFloat totalWidth = 0;
  for (NSButton *button in self.tabButtons) {
    [button sizeToFit];
    totalWidth += button.frame.size.width;
  }
  totalWidth += (self.tabButtons.count - 1) * spacing + padding * 2;

  // 设置文档视图的 frame
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
  // 禁用垂直滚动
  [self.functionScrollView setHasVerticalScroller:NO];
  [self.functionScrollView setHasVerticalRuler:NO];
  [self.functionScrollView setVerticalScrollElasticity:NSScrollElasticityNone];
  [self.panelRootView addSubview:self.functionScrollView];

  self.functionButtonContainer = [[NSView alloc] init];
  self.functionButtonContainer.wantsLayer = YES;
  self.functionButtonContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  // NSScrollView 的文档视图应该使用 frame-based 布局，不需要设置
  // translatesAutoresizingMaskIntoConstraints
  [self.functionScrollView setDocumentView:self.functionButtonContainer];

  [self updateFunctionButtons];
}

- (void)updateFunctionButtons {
  // 清空现有按钮
  for (NSButton *button in self.functionButtons) {
    [button removeFromSuperview];
  }
  [self.functionButtons removeAllObjects];

  // 根据当前 Tab 创建按钮
  NSArray *functions = [self functionsForCurrentTab];

  for (NSInteger i = 0; i < functions.count; i++) {
    NSDictionary *function = functions[i];
    NSButton *button = [self createFunctionButton:function];
    button.tag = i;
    [self.functionButtonContainer addSubview:button];
    [self.functionButtons addObject:button];
  }

  // 设置功能按钮约束
  [self setupFunctionButtonConstraints];
}

- (NSArray *)functionsForCurrentTab {
  if ([self.currentTab isEqualToString:@"beauty"]) {
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"white", @"title" : @"美白", @"icon" : @"meiyan"},
      @{@"key" : @"smooth", @"title" : @"磨皮", @"icon" : @"meiyan2"},
      @{@"key" : @"ai", @"title" : @"红润", @"icon" : @"meiyan"}
    ];
  } else if ([self.currentTab isEqualToString:@"reshape"]) {
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"thin_face", @"title" : @"瘦脸", @"icon" : @"meixing2"},
      @{@"key" : @"v_face", @"title" : @"V脸", @"icon" : @"meixing2"},
      @{@"key" : @"narrow_face", @"title" : @"窄脸", @"icon" : @"meixing2"}
    ];
  } else if ([self.currentTab isEqualToString:@"makeup"]) {
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"lipstick", @"title" : @"口红", @"icon" : @"meizhuang"},
      @{@"key" : @"blush", @"title" : @"腮红", @"icon" : @"meizhuang"},
      @{@"key" : @"eyebrow", @"title" : @"眉毛", @"icon" : @"meizhuang"}
    ];
  } else if ([self.currentTab isEqualToString:@"filter"]) {
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"natural", @"title" : @"自然", @"icon" : @"lvjing"},
      @{@"key" : @"fresh", @"title" : @"清新", @"icon" : @"lvjing"},
      @{@"key" : @"retro", @"title" : @"复古", @"icon" : @"lvjing"}
    ];
  }

  return @[];
}

- (NSButton *)createFunctionButton:(NSDictionary *)function {
  NSButton *button = [[NSButton alloc] init];
  [button setTitle:@""];  // 清除默认标题
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.wantsLayer = YES;
  [button setBordered:NO];

  // 图标容器（深灰色背景，圆形）- 减小尺寸
  NSView *iconContainer = [[NSView alloc] init];
  iconContainer.wantsLayer = YES;
  iconContainer.layer.backgroundColor = [[NSColor colorWithRed:0.3 green:0.3 blue:0.3
                                                         alpha:1.0] CGColor];
  iconContainer.layer.cornerRadius = 20;  // 减小圆角
  iconContainer.translatesAutoresizingMaskIntoConstraints = NO;

  // 图标（从 bundle 读取或使用系统图标）
  NSImageView *iconView = [[NSImageView alloc] init];
  NSString *iconName = function[@"icon"];
  NSImage *iconImage = [NSImage imageNamed:iconName];

  // 如果 bundle 中没有图片，尝试使用系统符号图标（macOS 11+）
  if (!iconImage && iconName.length > 0) {
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:iconName accessibilityDescription:nil];
    }
  }

  // 如果还是没有图标，使用默认图标
  if (!iconImage) {
    // 使用系统图标作为占位符
    if (@available(macOS 11.0, *)) {
      iconImage = [NSImage imageWithSystemSymbolName:@"circle.fill" accessibilityDescription:nil];
    } else {
      // macOS 10.x 使用通用图标
      iconImage = [[NSImage alloc] initWithSize:NSMakeSize(28, 28)];
      [iconImage lockFocus];
      [[NSColor whiteColor] set];
      NSRectFill(NSMakeRect(0, 0, 28, 28));
      [iconImage unlockFocus];
    }
  }

  // 设置图标为模板模式以便着色
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

  // 标题标签
  NSTextField *titleLabel = [[NSTextField alloc] init];
  titleLabel.stringValue = function[@"title"];
  titleLabel.editable = NO;
  titleLabel.bordered = NO;
  titleLabel.backgroundColor = [NSColor clearColor];
  titleLabel.textColor = [NSColor whiteColor];
  titleLabel.font = [NSFont systemFontOfSize:12];
  titleLabel.alignment = NSTextAlignmentCenter;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  // 选中指示器：绿色短横线
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
    // 图标容器 - 减小尺寸
    [iconContainer.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [iconContainer.topAnchor constraintEqualToAnchor:button.topAnchor],
    [iconContainer.widthAnchor constraintEqualToConstant:40],
    [iconContainer.heightAnchor constraintEqualToConstant:40],

    // 图标视图（居中在容器中）- 减小尺寸
    [iconView.centerXAnchor constraintEqualToAnchor:iconContainer.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
    [iconView.widthAnchor constraintEqualToConstant:24],
    [iconView.heightAnchor constraintEqualToConstant:24],

    // 标题标签 - 减小间距
    [titleLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [titleLabel.topAnchor constraintEqualToAnchor:iconContainer.bottomAnchor constant:2],
    [titleLabel.widthAnchor constraintLessThanOrEqualToConstant:70],

    // 指示器
    [indicator.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
    [indicator.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2],
    [indicator.widthAnchor constraintEqualToConstant:14],
    [indicator.heightAnchor constraintEqualToConstant:3],

    // 按钮宽度
    [button.widthAnchor constraintEqualToConstant:70]
  ]];

  [button setTarget:self];
  [button setAction:@selector(functionButtonTapped:)];
  [button setEnabled:YES];  // 确保按钮可用

  NSLog(@"[BeautyPanel] Created function button: %@, tag: %ld",
        function[@"title"],
        (long)[self.functionButtons count]);

  return button;
}

- (void)setupFunctionButtonConstraints {
  if (self.functionButtons.count == 0) return;

  CGFloat spacing = 8;
  CGFloat buttonHeight = 80;  // 减小功能按钮高度
  CGFloat buttonWidth = 70;
  CGFloat padding = 0;

  // 设置第一个按钮约束
  NSButton *firstButton = self.functionButtons[0];
  firstButton.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [firstButton.leadingAnchor constraintEqualToAnchor:self.functionButtonContainer.leadingAnchor
                                              constant:padding],
    [firstButton.centerYAnchor constraintEqualToAnchor:self.functionButtonContainer.centerYAnchor],
    [firstButton.widthAnchor constraintEqualToConstant:buttonWidth],
    [firstButton.heightAnchor constraintEqualToConstant:buttonHeight]
  ]];

  // 设置其他按钮约束
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

  // 使用 frame 设置容器大小（文档视图需要 frame-based 布局）
  [self.functionButtonContainer setNeedsLayout:YES];
  [self.functionButtonContainer layoutSubtreeIfNeeded];

  // 计算总宽度
  CGFloat totalWidth = self.functionButtons.count * buttonWidth +
      (self.functionButtons.count - 1) * spacing + padding * 2;

  // 设置文档视图的 frame - 高度固定为 80，与滚动视图高度一致，防止垂直滚动
  CGFloat scrollViewHeight = 80;  // 与约束中的高度一致
  self.functionButtonContainer.frame = NSMakeRect(0, 0, totalWidth, scrollViewHeight);
}

- (void)setupBottomButtonContainer {
  self.bottomButtonContainer = [[NSView alloc] init];
  self.bottomButtonContainer.wantsLayer = YES;
  self.bottomButtonContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  self.bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.panelRootView addSubview:self.bottomButtonContainer];

  // 使用 StackView 均匀分布三个按钮
  NSView *buttonStack = [[NSView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  [self.bottomButtonContainer addSubview:buttonStack];

  // 重置按钮 - 包含图标和文字
  self.resetButton = [[NSButton alloc] init];
  [self.resetButton setTitle:@""];  // 清除默认标题
  [self.resetButton setBezelStyle:NSBezelStyleRounded];
  [self.resetButton setTarget:self];
  [self.resetButton setAction:@selector(resetButtonTapped:)];
  self.resetButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.resetButton.wantsLayer = YES;
  [self.resetButton setBordered:NO];

  // 创建水平容器视图（模拟 StackView）- 使用不拦截事件的容器视图
  NSView *resetContainer = [[NonInterceptingContainerView alloc] init];
  resetContainer.translatesAutoresizingMaskIntoConstraints = NO;
  resetContainer.wantsLayer = YES;
  resetContainer.layer.backgroundColor = [NSColor clearColor].CGColor;

  // 重置图标
  NSImageView *resetIconView = [[NSImageView alloc] init];
  NSImage *resetIcon = [NSImage imageNamed:@"reset"];
  if (!resetIcon) {
    // 使用系统图标
    if (@available(macOS 11.0, *)) {
      resetIcon = [NSImage imageWithSystemSymbolName:@"arrow.counterclockwise"
                            accessibilityDescription:nil];
    } else {
      // macOS 10.x 创建占位图标
      resetIcon = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
      [resetIcon lockFocus];
      [[NSColor whiteColor] set];
      NSRectFill(NSMakeRect(0, 0, 20, 20));
      [resetIcon unlockFocus];
    }
  }
  if (resetIcon) {
    NSImage *templateIcon = [resetIcon copy];
    [templateIcon setTemplate:YES];
    resetIcon = templateIcon;
  }
  resetIconView.image = resetIcon;
  if (@available(macOS 10.14, *)) {
    resetIconView.contentTintColor = [NSColor whiteColor];
  }
  resetIconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  resetIconView.translatesAutoresizingMaskIntoConstraints = NO;

  // 重置文字标签
  NSTextField *resetLabel = [[NSTextField alloc] init];
  resetLabel.stringValue = @"重置";
  resetLabel.editable = NO;
  resetLabel.bordered = NO;
  resetLabel.backgroundColor = [NSColor clearColor];
  resetLabel.textColor = [NSColor whiteColor];
  resetLabel.font = [NSFont systemFontOfSize:14];
  resetLabel.translatesAutoresizingMaskIntoConstraints = NO;

  [resetContainer addSubview:resetIconView];
  [resetContainer addSubview:resetLabel];
  [self.resetButton addSubview:resetContainer];

  [NSLayoutConstraint activateConstraints:@[
    // 图标
    [resetIconView.leadingAnchor constraintEqualToAnchor:resetContainer.leadingAnchor],
    [resetIconView.centerYAnchor constraintEqualToAnchor:resetContainer.centerYAnchor],
    [resetIconView.widthAnchor constraintEqualToConstant:20],
    [resetIconView.heightAnchor constraintEqualToConstant:20],

    // 文字标签
    [resetLabel.leadingAnchor constraintEqualToAnchor:resetIconView.trailingAnchor constant:8],
    [resetLabel.centerYAnchor constraintEqualToAnchor:resetContainer.centerYAnchor],
    [resetLabel.trailingAnchor constraintEqualToAnchor:resetContainer.trailingAnchor],

    // 容器居中
    [resetContainer.centerXAnchor constraintEqualToAnchor:self.resetButton.centerXAnchor],
    [resetContainer.centerYAnchor constraintEqualToAnchor:self.resetButton.centerYAnchor]
  ]];

  [buttonStack addSubview:self.resetButton];

  // 拍照按钮（中间）- 白色外圆 + 绿色内圆
  NSView *captureButtonContainer = [[NSView alloc] init];
  captureButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  captureButtonContainer.wantsLayer = YES;
  captureButtonContainer.layer.backgroundColor = [NSColor clearColor].CGColor;

  // 外层白色圆
  NSView *outerCircle = [[NSView alloc] init];
  outerCircle.translatesAutoresizingMaskIntoConstraints = NO;
  outerCircle.wantsLayer = YES;
  outerCircle.layer.backgroundColor = [NSColor whiteColor].CGColor;
  outerCircle.layer.cornerRadius = 20;
  [captureButtonContainer addSubview:outerCircle];

  // 内层绿色圆（拍照按钮）
  self.captureButton = [[NSButton alloc] init];
  [self.captureButton setTitle:@""];  // 清除默认标题
  self.captureButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.captureButton.wantsLayer = YES;
  self.captureButton.layer.backgroundColor = [[NSColor colorWithRed:0.0
                                                              green:1.0
                                                               blue:0.0
                                                              alpha:1.0] CGColor];
  self.captureButton.layer.cornerRadius = 18;
  [self.captureButton setTarget:self];
  [self.captureButton setAction:@selector(captureButtonTapped:)];
  [self.captureButton setBordered:NO];
  [captureButtonContainer addSubview:self.captureButton];

  [NSLayoutConstraint activateConstraints:@[
    [outerCircle.centerXAnchor constraintEqualToAnchor:captureButtonContainer.centerXAnchor],
    [outerCircle.centerYAnchor constraintEqualToAnchor:captureButtonContainer.centerYAnchor],
    [outerCircle.widthAnchor constraintEqualToConstant:40],
    [outerCircle.heightAnchor constraintEqualToConstant:40],

    [self.captureButton.centerXAnchor constraintEqualToAnchor:outerCircle.centerXAnchor],
    [self.captureButton.centerYAnchor constraintEqualToAnchor:outerCircle.centerYAnchor],
    [self.captureButton.widthAnchor constraintEqualToConstant:36],
    [self.captureButton.heightAnchor constraintEqualToConstant:36]
  ]];

  [buttonStack addSubview:captureButtonContainer];

  // 隐藏面板按钮 - 包含图标和文字，使用自定义按钮类来追踪事件
  self.hidePanelButton = [[EventTrackingButton alloc] init];
  [self.hidePanelButton setTitle:@""];  // 清除默认标题
  [self.hidePanelButton setBezelStyle:NSBezelStyleRounded];
  [self.hidePanelButton setTarget:self];
  [self.hidePanelButton setAction:@selector(hidePanelButtonTapped:)];
  self.hidePanelButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.hidePanelButton.wantsLayer = YES;
  [self.hidePanelButton setBordered:NO];
  [self.hidePanelButton setEnabled:YES];  // 确保按钮可用

  NSLog(@"[BeautyPanel] hidePanelButton created, enabled: %d, target: %@, action: %s",
        self.hidePanelButton.enabled,
        self.hidePanelButton.target,
        sel_getName(self.hidePanelButton.action));

  // 创建水平容器视图（模拟 StackView）- 使用不拦截事件的容器视图
  NSView *hideContainer = [[NonInterceptingContainerView alloc] init];
  hideContainer.translatesAutoresizingMaskIntoConstraints = NO;
  hideContainer.wantsLayer = YES;
  hideContainer.layer.backgroundColor = [NSColor clearColor].CGColor;

  // 隐藏图标 - 使用不拦截事件的图标视图
  NSImageView *hideIconView = [[NonInterceptingImageView alloc] init];
  NSImage *hideIcon = [NSImage imageNamed:@"menu"];
  if (!hideIcon) {
    // 使用系统图标
    if (@available(macOS 11.0, *)) {
      hideIcon = [NSImage imageWithSystemSymbolName:@"grid" accessibilityDescription:nil];
    } else {
      // macOS 10.x 创建占位图标
      hideIcon = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
      [hideIcon lockFocus];
      [[NSColor whiteColor] set];
      NSRectFill(NSMakeRect(0, 0, 20, 20));
      [hideIcon unlockFocus];
    }
  }
  if (hideIcon) {
    NSImage *templateIcon = [hideIcon copy];
    [templateIcon setTemplate:YES];
    hideIcon = templateIcon;
  }
  hideIconView.image = hideIcon;
  if (@available(macOS 10.14, *)) {
    hideIconView.contentTintColor = [NSColor whiteColor];
  }
  hideIconView.imageScaling = NSImageScaleProportionallyUpOrDown;
  hideIconView.translatesAutoresizingMaskIntoConstraints = NO;

  // 隐藏文字标签 - 使用不拦截事件的文本视图
  NSTextField *hideLabel = [[NonInterceptingTextField alloc] init];
  hideLabel.stringValue = @"隐藏面板";
  hideLabel.editable = NO;
  hideLabel.bordered = NO;
  hideLabel.backgroundColor = [NSColor clearColor];
  hideLabel.textColor = [NSColor whiteColor];
  hideLabel.font = [NSFont systemFontOfSize:14];
  hideLabel.translatesAutoresizingMaskIntoConstraints = NO;

  [hideContainer addSubview:hideIconView];
  [hideContainer addSubview:hideLabel];
  [self.hidePanelButton addSubview:hideContainer];

  NSLog(@"[BeautyPanel] hidePanelButton setup complete:");
  NSLog(@"  - enabled: %d", self.hidePanelButton.enabled);
  NSLog(@"  - target: %@", self.hidePanelButton.target);
  NSLog(@"  - action: %s", sel_getName(self.hidePanelButton.action));
  NSLog(@"  - subviews count: %lu", (unsigned long)self.hidePanelButton.subviews.count);

  [NSLayoutConstraint activateConstraints:@[
    // 图标
    [hideIconView.leadingAnchor constraintEqualToAnchor:hideContainer.leadingAnchor],
    [hideIconView.centerYAnchor constraintEqualToAnchor:hideContainer.centerYAnchor],
    [hideIconView.widthAnchor constraintEqualToConstant:20],
    [hideIconView.heightAnchor constraintEqualToConstant:20],

    // 文字标签
    [hideLabel.leadingAnchor constraintEqualToAnchor:hideIconView.trailingAnchor constant:8],
    [hideLabel.centerYAnchor constraintEqualToAnchor:hideContainer.centerYAnchor],
    [hideLabel.trailingAnchor constraintEqualToAnchor:hideContainer.trailingAnchor],

    // 容器居中，并设置最小宽度和高度（只包裹内容，不填满按钮）
    [hideContainer.centerXAnchor constraintEqualToAnchor:self.hidePanelButton.centerXAnchor],
    [hideContainer.centerYAnchor constraintEqualToAnchor:self.hidePanelButton.centerYAnchor],
    [hideContainer.heightAnchor constraintEqualToConstant:20],
    [hideContainer.widthAnchor constraintGreaterThanOrEqualToConstant:80]
  ]];

  NSLog(@"[BeautyPanel] hidePanelButton container constraints set");

  [buttonStack addSubview:self.hidePanelButton];

  // 在布局完成后检查按钮状态
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"[BeautyPanel] hidePanelButton after layout:");
    NSLog(@"  - frame: %@", NSStringFromRect(self.hidePanelButton.frame));
    NSLog(@"  - bounds: %@", NSStringFromRect(self.hidePanelButton.bounds));
    NSLog(@"  - hidden: %d", self.hidePanelButton.hidden);
    NSLog(@"  - alpha: %f", self.hidePanelButton.alphaValue);
    NSLog(@"  - enabled: %d", self.hidePanelButton.enabled);
    NSLog(@"  - window: %@", self.hidePanelButton.window);
  });

  // 约束
  [NSLayoutConstraint activateConstraints:@[
    [buttonStack.topAnchor constraintEqualToAnchor:self.bottomButtonContainer.topAnchor constant:5],
    [buttonStack.leadingAnchor constraintEqualToAnchor:self.bottomButtonContainer.leadingAnchor
                                              constant:16],
    [buttonStack.trailingAnchor constraintEqualToAnchor:self.bottomButtonContainer.trailingAnchor
                                               constant:-16],
    [buttonStack.bottomAnchor constraintEqualToAnchor:self.bottomButtonContainer.bottomAnchor
                                             constant:-5],

    [self.resetButton.leadingAnchor constraintEqualToAnchor:buttonStack.leadingAnchor],
    [self.resetButton.centerYAnchor constraintEqualToAnchor:buttonStack.centerYAnchor],
    [self.resetButton.widthAnchor constraintEqualToAnchor:buttonStack.widthAnchor multiplier:0.33],
    [self.resetButton.heightAnchor constraintEqualToConstant:35],  // 减小重置按钮高度

    [captureButtonContainer.centerXAnchor constraintEqualToAnchor:buttonStack.centerXAnchor],
    [captureButtonContainer.centerYAnchor constraintEqualToAnchor:buttonStack.centerYAnchor],
    [captureButtonContainer.widthAnchor constraintEqualToAnchor:buttonStack.widthAnchor
                                                     multiplier:0.33],
    [captureButtonContainer.heightAnchor constraintEqualToConstant:50],  // 减小拍照按钮容器高度

    [self.hidePanelButton.trailingAnchor constraintEqualToAnchor:buttonStack.trailingAnchor],
    [self.hidePanelButton.centerYAnchor constraintEqualToAnchor:buttonStack.centerYAnchor],
    [self.hidePanelButton.widthAnchor constraintEqualToAnchor:buttonStack.widthAnchor
                                                   multiplier:0.33],
    [self.hidePanelButton.heightAnchor constraintEqualToConstant:35]  // 减小隐藏面板按钮高度
  ]];
}

- (void)setupPanelConstraints {
  [NSLayoutConstraint activateConstraints:@[
    // 面板根视图：填充整个视图（因为现在是独立的下半部分）
    [self.panelRootView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.panelRootView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.panelRootView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.panelRootView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // 滑动条容器（在面板内部顶部）
    [self.sliderContainer.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.sliderContainer.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.sliderContainer.topAnchor constraintEqualToAnchor:self.panelRootView.topAnchor]
  ]];

  // 存储高度约束，以便动态调整（初始为 0，因为滑块默认隐藏）
  self.sliderContainerHeightConstraint =
      [self.sliderContainer.heightAnchor constraintEqualToConstant:0];
  self.sliderContainerHeightConstraint.active = YES;

  // Before/After 按钮约束（在滑动条右侧）
  [NSLayoutConstraint activateConstraints:@[
    [self.beforeAfterButton.widthAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.heightAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.trailingAnchor
        constraintEqualToAnchor:self.sliderContainer.trailingAnchor
                       constant:-16],
    [self.beforeAfterButton.centerYAnchor
        constraintEqualToAnchor:self.sliderContainer.centerYAnchor]
  ]];

  [NSLayoutConstraint activateConstraints:@[
    // Tab 滚动视图（在滑动条下方，如果滑动条隐藏则在顶部）
    [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.tabScrollView.topAnchor constraintEqualToAnchor:self.sliderContainer.bottomAnchor],
    [self.tabScrollView.heightAnchor constraintEqualToConstant:40],

    // 功能按钮滚动视图（中间）- 增加与 Tab 之间的间距，确保不重叠
    [self.functionScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor
                                                          constant:16],
    [self.functionScrollView.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor
                       constant:-16],
    [self.functionScrollView.topAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor
                                                      constant:12],
    [self.functionScrollView.heightAnchor constraintEqualToConstant:80],

    // 底部按钮容器（底部）- 减少间距和高度
    [self.bottomButtonContainer.leadingAnchor
        constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.bottomButtonContainer.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.bottomButtonContainer.topAnchor
        constraintEqualToAnchor:self.functionScrollView.bottomAnchor
                       constant:8],
    [self.bottomButtonContainer.bottomAnchor
        constraintEqualToAnchor:self.panelRootView.bottomAnchor],
    [self.bottomButtonContainer.heightAnchor constraintEqualToConstant:50]
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
    [self updateFunctionButtons];
    // 切换 tab 时隐藏滑动条
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

- (void)functionButtonTapped:(NSButton *)sender {
  NSLog(@"[BeautyPanel] functionButtonTapped called!");
  NSLog(@"  - button tag: %ld", (long)sender.tag);
  NSLog(@"  - current tab: %@", self.currentTab);

  if (sender.tag < self.functionButtons.count) {
    NSArray *functions = [self functionsForCurrentTab];
    if (sender.tag < functions.count) {
      NSDictionary *function = functions[sender.tag];
      NSString *functionKey = function[@"key"];
      NSString *functionTitle = function[@"title"];
      NSLog(@"  - function key: %@", functionKey);
      NSLog(@"  - function title: %@", functionTitle);

      // 更新当前功能
      self.currentFunction = functionKey;

      // 显示滑动条
      [self showSlider];

      // 更新滑块初始值（根据当前功能的状态）
      NSString *progressKey =
          [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
      NSNumber *progress = self.functionProgress[progressKey];
      if (progress) {
        self.valueSlider.doubleValue = [progress doubleValue];
      } else {
        self.valueSlider.doubleValue = 0;  // 默认值 0
      }
      self.valueLabel.stringValue =
          [NSString stringWithFormat:@"%.0f", self.valueSlider.doubleValue];

      // 使用当前值立即应用一次参数，保证切换功能后立即生效
      if (self.delegate &&
          [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
        float paramValue = (float)(self.valueSlider.doubleValue / 100.0);
        [self.delegate beautyPanelDidChangeParam:self.currentTab
                                        function:self.currentFunction
                                           value:paramValue];
      }
    } else {
      NSLog(@"  - ERROR: function index %ld out of range (count: %lu)",
            (long)sender.tag,
            (unsigned long)functions.count);
    }
  } else {
    NSLog(@"  - ERROR: button tag %ld out of range (count: %lu)",
          (long)sender.tag,
          (unsigned long)self.functionButtons.count);
  }
}

- (void)resetButtonTapped:(NSButton *)sender {
  NSLog(@"[BeautyPanel] resetButtonTapped");

  // 隐藏滑动条
  [self hideSlider];

  // 重置所有功能的进度
  [self.functionProgress removeAllObjects];

  // 重置滑块值
  self.valueSlider.doubleValue = 0;
  self.valueLabel.stringValue = @"0";

  // 清空当前功能选择
  self.currentFunction = nil;

  // 通知代理重置
  if (self.delegate && [self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)captureButtonTapped:(NSButton *)sender {
  // UI 布局，不实现具体功能
}

- (void)hidePanelButtonTapped:(NSButton *)sender {
  NSLog(@"[BeautyPanel] hidePanelButtonTapped called!");
  [self hidePanel];
}

#pragma mark - Public Methods

- (void)showPanel {
  self.isPanelVisible = YES;
  self.panelRootView.hidden = NO;

  // 由于现在是独立的下半部分，不需要淡入淡出动画
  self.panelRootView.alphaValue = 1.0;

  // 通知父视图控制器更新布局约束
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BeautyPanelVisibilityChanged"
                                                      object:@YES];
}

- (void)hidePanel {
  self.isPanelVisible = NO;

  // 隐藏滑动条
  [self hideSlider];

  // 由于现在是独立的下半部分，直接隐藏
  self.panelRootView.hidden = YES;

  // 通知父视图控制器更新布局约束
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

#pragma mark - Slider Setup

- (void)setupSliderContainer {
  // 滑动条容器在面板内部顶部
  self.sliderContainer = [[NSView alloc] init];
  self.sliderContainer.wantsLayer = YES;
  self.sliderContainer.layer.backgroundColor = [NSColor clearColor].CGColor;
  self.sliderContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.sliderContainer.hidden = YES;
  self.isSliderVisible = NO;
  [self.panelRootView addSubview:self.sliderContainer];  // 添加到 panelRootView

  // 数值标签
  self.valueLabel = [[NSTextField alloc] init];
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.stringValue = @"50";
  self.valueLabel.textColor = [NSColor whiteColor];
  self.valueLabel.font = [NSFont systemFontOfSize:13];
  self.valueLabel.backgroundColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.6];
  self.valueLabel.bordered = NO;
  self.valueLabel.editable = NO;
  self.valueLabel.alignment = NSTextAlignmentCenter;
  self.valueLabel.wantsLayer = YES;
  self.valueLabel.layer.cornerRadius = 4;
  self.valueLabel.hidden = YES;
  [self.sliderContainer addSubview:self.valueLabel];

  // 滑块
  self.valueSlider = [[NSSlider alloc] init];
  self.valueSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueSlider.minValue = 0;
  self.valueSlider.maxValue = 100;
  self.valueSlider.doubleValue = 50;
  self.valueSlider.target = self;
  self.valueSlider.action = @selector(sliderValueChanged:);
  [self.sliderContainer addSubview:self.valueSlider];

  // Before/After 对比按钮
  BeforeAfterButton *beforeAfterBtn = [[BeforeAfterButton alloc] init];
  beforeAfterBtn.panelController = self;
  self.beforeAfterButton = beforeAfterBtn;
  self.beforeAfterButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.beforeAfterButton.wantsLayer = YES;
  self.beforeAfterButton.layer.backgroundColor = [[NSColor colorWithRed:0.3
                                                                  green:0.3
                                                                   blue:0.3
                                                                  alpha:1.0] CGColor];
  self.beforeAfterButton.layer.cornerRadius = 25;  // 50 / 2 = 25
  self.beforeAfterButton.bordered = NO;
  self.beforeAfterButton.title = @"";

  // 加载图标
  NSImage *beforeAfterIcon = nil;
  NSBundle *bundle = [NSBundle mainBundle];
  if (bundle) {
    NSString *iconPath = [bundle pathForResource:@"before_after" ofType:@"png"];
    if (iconPath) {
      beforeAfterIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }
  }

  // 如果没有图标，使用系统图标
  if (!beforeAfterIcon) {
    if (@available(macOS 11.0, *)) {
      beforeAfterIcon = [NSImage imageWithSystemSymbolName:@"arrow.left.arrow.right"
                                  accessibilityDescription:nil];
    }
  }

  if (beforeAfterIcon) {
    NSImage *templateImage = [beforeAfterIcon copy];
    [templateImage setTemplate:YES];
    NSImageView *iconView = [[NSImageView alloc] init];
    iconView.image = templateImage;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(macOS 10.14, *)) {
      iconView.contentTintColor = [NSColor whiteColor];
    }
    [self.beforeAfterButton addSubview:iconView];

    [NSLayoutConstraint activateConstraints:@[
      [iconView.widthAnchor constraintEqualToConstant:22],
      [iconView.heightAnchor constraintEqualToConstant:22],
      [iconView.centerXAnchor constraintEqualToAnchor:self.beforeAfterButton.centerXAnchor],
      [iconView.centerYAnchor constraintEqualToAnchor:self.beforeAfterButton.centerYAnchor]
    ]];
  }

  // 创建自定义按钮类来处理按住和松开事件
  // 使用 mouseDown 和 mouseUp 事件
  self.beforeAfterButton.target = self;
  self.beforeAfterButton.action = @selector(beforeAfterButtonTapped:);
  self.beforeAfterButton.hidden = YES;                     // 默认隐藏，与滑动条一起显示/隐藏
  [self.panelRootView addSubview:self.beforeAfterButton];  // 添加到 panelRootView

  [NSLayoutConstraint activateConstraints:@[
    // 数值标签
    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.sliderContainer.leadingAnchor
                                                  constant:16],
    [self.valueLabel.topAnchor constraintEqualToAnchor:self.sliderContainer.topAnchor constant:5],
    [self.valueLabel.widthAnchor constraintGreaterThanOrEqualToConstant:40],
    [self.valueLabel.heightAnchor constraintEqualToConstant:24],

    // 滑块
    [self.valueSlider.leadingAnchor constraintEqualToAnchor:self.sliderContainer.leadingAnchor
                                                   constant:16],
    [self.valueSlider.trailingAnchor constraintEqualToAnchor:self.sliderContainer.trailingAnchor
                                                    constant:-80],  // 为 Before/After 按钮留出空间
    [self.valueSlider.centerYAnchor constraintEqualToAnchor:self.sliderContainer.centerYAnchor],
    [self.valueSlider.heightAnchor constraintEqualToConstant:30]
  ]];
}

- (void)showSlider {
  self.isSliderVisible = YES;
  self.sliderContainer.hidden = NO;
  self.valueLabel.hidden = NO;
  self.beforeAfterButton.hidden = NO;

  // 更新高度约束，显示滑块
  if (self.sliderContainerHeightConstraint) {
    self.sliderContainerHeightConstraint.constant = 60;
    [NSAnimationContext
        runAnimationGroup:^(NSAnimationContext *context) {
          context.duration = 0.2;
          [self.view layoutSubtreeIfNeeded];
        }
        completionHandler:nil];
  }
}

- (void)hideSlider {
  self.isSliderVisible = NO;
  self.sliderContainer.hidden = YES;
  self.valueLabel.hidden = YES;
  self.beforeAfterButton.hidden = YES;

  // 更新高度约束，隐藏滑块（高度为 0）
  if (self.sliderContainerHeightConstraint) {
    self.sliderContainerHeightConstraint.constant = 0;
    [NSAnimationContext
        runAnimationGroup:^(NSAnimationContext *context) {
          context.duration = 0.2;
          [self.view layoutSubtreeIfNeeded];
        }
        completionHandler:nil];
  }
}

- (void)sliderValueChanged:(NSSlider *)sender {
  NSInteger value = (NSInteger)sender.doubleValue;
  self.valueLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)value];

  // 保存当前功能的进度（0-100）
  if (self.currentTab && self.currentFunction) {
    NSString *progressKey =
        [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
    self.functionProgress[progressKey] = @(value);
  }

  // 通知代理参数变化（将进度值 0-100 转换为参数值 0.0-1.0）
  if (self.currentTab && self.currentFunction && self.delegate &&
      [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    float paramValue = (float)(sender.doubleValue / 100.0);
    [self.delegate beautyPanelDidChangeParam:self.currentTab
                                    function:self.currentFunction
                                       value:paramValue];
  }
}

- (void)beforeAfterButtonTapped:(NSButton *)sender {
  NSLog(@"[BeautyPanel] beforeAfterButtonTapped");
  // 对比按钮的点击处理（如果需要）
}

- (void)beforeAfterTouchDown {
  NSLog(@"[BeautyPanel] beforeAfterTouchDown - 按住预览原图");
  self.isBeforeAfterPressed = YES;
  // 按住时关闭所有参数（通过 delegate 通知重置）
  if (self.delegate && [self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)beforeAfterTouchUp {
  NSLog(@"[BeautyPanel] beforeAfterTouchUp - 松开恢复参数");
  self.isBeforeAfterPressed = NO;
  // 松开时恢复用户已设置参数
  // 重新应用所有已保存的参数
  for (NSString *key in self.functionProgress.allKeys) {
    NSArray *components = [key componentsSeparatedByString:@":"];
    if (components.count == 2) {
      NSString *tab = components[0];
      NSString *function = components[1];
      NSNumber *progress = self.functionProgress[key];
      if (progress && self.delegate &&
          [self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
        float paramValue = [progress floatValue] / 100.0f;
        [self.delegate beautyPanelDidChangeParam:tab function:function value:paramValue];
      }
    }
  }
}

@end