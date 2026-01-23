//
//  BeautyPanelViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/9/8.
//  Updated for new UI matching Android layout
//

#import "BeautyPanelViewController.h"

@interface BeautyPanelViewController ()

// 顶部按钮栏
@property(nonatomic, strong) UIView *topBar;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UIButton *galleryButton;
@property(nonatomic, strong) UIButton *flipCameraButton;
@property(nonatomic, strong) UIButton *moreButton;

@property(nonatomic, strong) UIView *panelRootView;
@property(nonatomic, strong) UIView *bottomControlPanel;

// Tab 切换区域
@property(nonatomic, strong) UIScrollView *tabScrollView;
@property(nonatomic, strong) UIStackView *tabContainer;
@property(nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property(nonatomic, strong) NSString *currentTab;

// 功能按钮区域
@property(nonatomic, strong) UIScrollView *functionScrollView;
@property(nonatomic, strong) UIStackView *functionButtonContainer;
@property(nonatomic, strong) NSMutableArray<UIButton *> *functionButtons;

// 子选项区域
@property(nonatomic, strong) UIScrollView *subOptionScrollView;
@property(nonatomic, strong) UIStackView *subOptionContainer;
@property(nonatomic, strong) NSMutableArray<UIButton *> *subOptionButtons;

// 底部按钮区域
@property(nonatomic, strong) UIView *bottomButtonContainer;
@property(nonatomic, strong) UIButton *resetButton;
@property(nonatomic, strong) UIButton *captureButton;
@property(nonatomic, strong) UIButton *hidePanelButton;

// 滑块
@property(nonatomic, strong) UIView *sliderContainer;
@property(nonatomic, strong) UISlider *valueSlider;
@property(nonatomic, strong) UILabel *valueLabel;
@property(nonatomic, assign) BOOL isSliderVisible;
@property(nonatomic, strong) NSLayoutConstraint *sliderContainerHeightConstraint;
// Before/After 对比按钮
@property(nonatomic, strong) UIButton *beforeAfterButton;
@property(nonatomic, strong) NSLayoutConstraint *beforeAfterButtonBottomConstraint;

// 状态
@property(nonatomic, assign) BOOL isPanelVisible;
@property(nonatomic, assign) BOOL isSubOptionVisible;
@property(nonatomic, strong) NSString *currentFunction;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *functionProgress;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *toggleStates;
// 功能按钮选中指示器（key: "tab:function", value: UIView）
@property(nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *functionIndicatorViews;

@end

@implementation BeautyPanelViewController

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // 如果是 tabScrollView，阻止垂直滚动
  if (scrollView == self.tabScrollView) {
    // 如果 contentOffset.y 不为 0，强制设为 0（阻止垂直滚动）
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
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  self.view.userInteractionEnabled = YES;  // 启用交互，以便底部控制面板可以接收点击事件

  [self setupTopBar];
  [self setupPanel];
  [self setupBottomControlPanel];
  [self hidePanel];  // 默认隐藏
}

- (void)setupTopBar {
  // 顶部栏容器（参考 Android：padding 16dp，透明背景）
  self.topBar = [[UIView alloc] init];
  self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.topBar.backgroundColor = [UIColor clearColor];
  self.topBar.userInteractionEnabled = YES;  // 确保可以接收触摸事件
  [self.view addSubview:self.topBar];

  // 关闭按钮（48x48，图标 18pt）
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

  // 相册按钮（48x48，图标 22pt）
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

  // 切换相机按钮（48x48，图标 24pt）
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

  // 更多选项按钮（48x48，图标 22pt）
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

  // 使用 StackView 均匀分布按钮（参考 Android：按钮之间有 Space，使用 FillEqually 分布）
  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.alignment = UIStackViewAlignmentCenter;
  buttonStack.spacing = 0;
  // StackView 需要启用交互，但触摸事件会传递给子视图（按钮）
  buttonStack.userInteractionEnabled = YES;

  // 添加按钮和间隔视图
  [buttonStack addArrangedSubview:self.closeButton];

  UIView *spacer1 = [[UIView alloc] init];
  spacer1.translatesAutoresizingMaskIntoConstraints = NO;
  spacer1.userInteractionEnabled = NO;  // 间隔视图不拦截触摸事件
  [buttonStack addArrangedSubview:spacer1];

  [buttonStack addArrangedSubview:self.galleryButton];

  UIView *spacer2 = [[UIView alloc] init];
  spacer2.translatesAutoresizingMaskIntoConstraints = NO;
  spacer2.userInteractionEnabled = NO;  // 间隔视图不拦截触摸事件
  [buttonStack addArrangedSubview:spacer2];

  [buttonStack addArrangedSubview:self.flipCameraButton];

  UIView *spacer3 = [[UIView alloc] init];
  spacer3.translatesAutoresizingMaskIntoConstraints = NO;
  spacer3.userInteractionEnabled = NO;  // 间隔视图不拦截触摸事件
  [buttonStack addArrangedSubview:spacer3];

  [buttonStack addArrangedSubview:self.moreButton];

  [self.topBar addSubview:buttonStack];

  // 布局约束
  [NSLayoutConstraint activateConstraints:@[
    // 按钮高度固定为 48pt，宽度由 StackView 的 FillEqually 自动分配（移除固定宽度约束避免冲突）
    [self.closeButton.heightAnchor constraintEqualToConstant:48],
    [self.galleryButton.heightAnchor constraintEqualToConstant:48],
    [self.flipCameraButton.heightAnchor constraintEqualToConstant:48],
    [self.moreButton.heightAnchor constraintEqualToConstant:48],

    // StackView 布局（左右 padding 16pt，垂直居中）
    [buttonStack.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:16],
    [buttonStack.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-16],
    [buttonStack.topAnchor constraintEqualToAnchor:self.topBar.topAnchor constant:16],
    [buttonStack.bottomAnchor constraintEqualToAnchor:self.topBar.bottomAnchor constant:-16],
    [buttonStack.heightAnchor constraintEqualToConstant:48]
  ]];

  // 设置图标大小（通过 contentEdgeInsets 和 imageEdgeInsets 调整）
  // 关闭按钮图标：18pt
  self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);  // (48-18)/2 = 15
  // 相册按钮图标：22pt
  self.galleryButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13);  // (48-22)/2 = 13
  // 切换相机按钮图标：24pt
  self.flipCameraButton.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);  // (48-24)/2 = 12
  // 更多按钮图标：22pt
  self.moreButton.imageEdgeInsets = UIEdgeInsetsMake(13, 13, 13, 13);  // (48-22)/2 = 13

  // 顶部栏约束（位于视图顶部，高度自适应）
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
    // 高度由内容决定（按钮 48pt + 上下 padding 16pt × 2 = 80pt）
  ]];

  // 确保顶部栏在最上层
  [self.view bringSubviewToFront:self.topBar];
}

- (void)setupPanel {
  // 面板根视图 - 半透明背景，覆盖整个面板区域
  self.panelRootView = [[UIView alloc] init];
  self.panelRootView.translatesAutoresizingMaskIntoConstraints = NO;
  self.panelRootView.backgroundColor = [UIColor colorWithRed:0
                                                       green:0
                                                        blue:0
                                                       alpha:0.8];  // 半透明黑色背景
  self.panelRootView.hidden = YES;
  self.panelRootView.userInteractionEnabled = YES;  // 确保可以接收触摸事件
  [self.view addSubview:self.panelRootView];

  // Tab 切换区域
  [self setupTabScrollView];

  // 功能按钮区域
  [self setupFunctionScrollView];

  // 子选项区域（默认隐藏）
  [self setupSubOptionScrollView];

  // 滑块区域（必须在设置约束前创建）
  [self setupSliderContainer];

  // 底部按钮区域
  [self setupBottomButtonContainer];

  // 约束
  [self setupPanelConstraints];
}

- (void)setupTabScrollView {
  self.tabScrollView = [[UIScrollView alloc] init];
  self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabScrollView.showsHorizontalScrollIndicator = NO;
  self.tabScrollView.showsVerticalScrollIndicator = NO;  // 禁用垂直滚动指示器
  self.tabScrollView.alwaysBounceVertical = NO;          // 禁用垂直弹性滚动
  self.tabScrollView.alwaysBounceHorizontal = YES;       // 允许水平弹性滚动
  self.tabScrollView.directionalLockEnabled = YES;       // 启用方向锁定，优先水平滚动
  self.tabScrollView.scrollEnabled = YES;                // 确保滚动启用
  // 设置代理以阻止垂直滚动（BeautyPanelViewController 已经实现了 UIScrollViewDelegate）
  self.tabScrollView.delegate = self;
  self.tabScrollView.backgroundColor = [UIColor clearColor];  // 透明，因为父视图已有背景
  [self.panelRootView addSubview:self.tabScrollView];

  self.tabContainer = [[UIStackView alloc] init];
  self.tabContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.tabContainer.axis = UILayoutConstraintAxisHorizontal;
  self.tabContainer.spacing = 0;
  self.tabContainer.alignment = UIStackViewAlignmentCenter;
  [self.tabScrollView addSubview:self.tabContainer];

  // Tab 按钮
  NSArray *tabs =
      @[ @"美颜", @"美型", @"美妆", @"滤镜", @"贴纸", @"美体", @"虚拟背景", @"画质调整" ];
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
  [self selectTabButton:0];  // 默认选中第一个
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // 在布局完成后更新 contentSize，确保垂直方向不可滚动
  [self updateTabScrollViewContentSize];
}

- (void)updateTabScrollViewContentSize {
  // 确保 contentSize 的垂直高度等于 ScrollView 的高度，这样垂直方向就不可滚动
  CGFloat scrollViewHeight = self.tabScrollView.bounds.size.height;
  if (scrollViewHeight > 0) {
    CGSize contentSize = self.tabScrollView.contentSize;
    // 如果 contentSize 宽度为 0，说明还没有布局完成，等待下次更新
    if (contentSize.width > 0) {
      self.tabScrollView.contentSize = CGSizeMake(contentSize.width, scrollViewHeight);
    }
  }
}

- (void)setupFunctionScrollView {
  self.functionScrollView = [[UIScrollView alloc] init];
  self.functionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.functionScrollView.showsHorizontalScrollIndicator = NO;
  self.functionScrollView.backgroundColor = [UIColor clearColor];  // 透明，因为父视图已有背景
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
  self.subOptionScrollView.backgroundColor = [UIColor clearColor];  // 透明，因为父视图已有背景
  self.subOptionScrollView.hidden = YES;
  self.subOptionScrollView.alwaysBounceHorizontal = YES;  // 允许水平弹性滚动
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

  // 使用 StackView 均匀分布三个按钮
  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.alignment = UIStackViewAlignmentCenter;
  [self.bottomButtonContainer addSubview:buttonStack];

  // 重置按钮
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
    // 设置为模板模式以便着色
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
  resetLabel.text = @"重置美颜";
  resetLabel.textColor = [UIColor whiteColor];
  resetLabel.font = [UIFont systemFontOfSize:14];

  [resetStack addArrangedSubview:resetIconView];
  [resetStack addArrangedSubview:resetLabel];
  resetStack.userInteractionEnabled = NO;  // 禁用 StackView 交互，避免拦截按钮的触摸事件
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

  // 拍照按钮（中间）- 仿照安卓实现：白色外圆 + 绿色内圆
  // 创建容器视图
  UIView *captureButtonContainer = [[UIView alloc] init];
  captureButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
  captureButtonContainer.backgroundColor = [UIColor clearColor];

  // 外层白色圆
  UIView *outerCircle = [[UIView alloc] init];
  outerCircle.translatesAutoresizingMaskIntoConstraints = NO;
  outerCircle.backgroundColor = [UIColor whiteColor];
  outerCircle.layer.cornerRadius = 30;  // 60 / 2 = 30
  outerCircle.layer.masksToBounds = YES;
  [captureButtonContainer addSubview:outerCircle];

  // 内层绿色圆（拍照按钮）
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

  // 约束：外层白色圆 60x60，居中
  [NSLayoutConstraint activateConstraints:@[
    [outerCircle.centerXAnchor constraintEqualToAnchor:captureButtonContainer.centerXAnchor],
    [outerCircle.centerYAnchor constraintEqualToAnchor:captureButtonContainer.centerYAnchor],
    [outerCircle.widthAnchor constraintEqualToConstant:60],
    [outerCircle.heightAnchor constraintEqualToConstant:60],

    // 内层绿色圆 50x50，居中在外层圆内
    [self.captureButton.centerXAnchor constraintEqualToAnchor:outerCircle.centerXAnchor],
    [self.captureButton.centerYAnchor constraintEqualToAnchor:outerCircle.centerYAnchor],
    [self.captureButton.widthAnchor constraintEqualToConstant:50],
    [self.captureButton.heightAnchor constraintEqualToConstant:50]
  ]];

  [buttonStack addArrangedSubview:captureButtonContainer];

  // 隐藏面板按钮
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
    // 设置为模板模式以便着色
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
  hideLabel.text = @"隐藏面板";
  hideLabel.textColor = [UIColor whiteColor];
  hideLabel.font = [UIFont systemFontOfSize:14];

  [hideStack addArrangedSubview:hideIconView];
  [hideStack addArrangedSubview:hideLabel];
  hideStack.userInteractionEnabled = NO;  // 禁用 StackView 交互，避免拦截按钮的触摸事件
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

  // 约束
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
  // 确保所有视图都已初始化
  NSAssert(self.panelRootView != nil, @"panelRootView 不能为 nil");
  NSAssert(self.bottomButtonContainer != nil, @"bottomButtonContainer 不能为 nil");
  NSAssert(self.sliderContainer != nil, @"sliderContainer 不能为 nil");
  NSAssert(self.functionScrollView != nil, @"functionScrollView 不能为 nil");
  NSAssert(self.tabScrollView != nil, @"tabScrollView 不能为 nil");

  // 获取 safeAreaLayoutGuide（iOS 11+），如果不可用则使用 bottomAnchor
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
    // 面板根视图（从 Tab 区域开始到底部，只覆盖底部面板区域）
    [self.panelRootView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.panelRootView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.panelRootView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    // 底部按钮容器（最底部，与 bottomControlPanel 位置一致）
    [self.bottomButtonContainer.leadingAnchor
        constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.bottomButtonContainer.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.bottomButtonContainer.bottomAnchor constraintEqualToAnchor:bottomAnchor],
    [self.bottomButtonContainer.heightAnchor constraintEqualToConstant:80],

    // 功能按钮滚动视图（在 Tab 下方，在底部按钮上方）
    [self.functionScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor
                                                          constant:16],
    [self.functionScrollView.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor
                       constant:-16],
    [self.functionScrollView.bottomAnchor
        constraintEqualToAnchor:self.bottomButtonContainer.topAnchor],
    [self.functionScrollView.heightAnchor constraintEqualToConstant:120],

    // 功能按钮容器
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

    // Tab 滚动视图（在功能按钮上方）
    [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.tabScrollView.topAnchor
        constraintEqualToAnchor:self.panelRootView.topAnchor],  // 面板从 Tab 区域开始
    [self.tabScrollView.bottomAnchor constraintEqualToAnchor:self.functionScrollView.topAnchor],
    [self.tabScrollView.heightAnchor constraintEqualToConstant:50],

    // Tab 容器（严格限制高度，确保垂直方向不可滚动）
    [self.tabContainer.topAnchor constraintEqualToAnchor:self.tabScrollView.topAnchor constant:8],
    [self.tabContainer.leadingAnchor constraintEqualToAnchor:self.tabScrollView.leadingAnchor
                                                    constant:8],
    [self.tabContainer.trailingAnchor constraintEqualToAnchor:self.tabScrollView.trailingAnchor
                                                     constant:-8],
    [self.tabContainer.heightAnchor
        constraintEqualToConstant:34],  // 50 - 8*2 = 34 (Tab ScrollView 高度 50 - 上下 padding 8*2)

    // 子选项滚动视图（与功能按钮重叠，显示时替换功能按钮）
    [self.subOptionScrollView.leadingAnchor
        constraintEqualToAnchor:self.panelRootView.leadingAnchor],
    [self.subOptionScrollView.trailingAnchor
        constraintEqualToAnchor:self.panelRootView.trailingAnchor],
    [self.subOptionScrollView.bottomAnchor
        constraintEqualToAnchor:self.bottomButtonContainer.topAnchor],
    [self.subOptionScrollView.heightAnchor constraintEqualToConstant:120],

    // 子选项容器（允许水平滚动）
    [self.subOptionContainer.topAnchor constraintEqualToAnchor:self.subOptionScrollView.topAnchor],
    [self.subOptionContainer.leadingAnchor
        constraintEqualToAnchor:self.subOptionScrollView.leadingAnchor
                       constant:16],
    [self.subOptionContainer.bottomAnchor
        constraintEqualToAnchor:self.subOptionScrollView.bottomAnchor],
    [self.subOptionContainer.heightAnchor
        constraintEqualToAnchor:self.subOptionScrollView.heightAnchor]
  ]];

  // 设置子选项容器宽度约束：使用 >= 关系，允许内容超出 ScrollView 宽度
  // 这样 StackView 可以根据内容自动扩展，ScrollView 才能滚动
  NSLayoutConstraint *subOptionWidthConstraint = [self.subOptionContainer.widthAnchor
      constraintGreaterThanOrEqualToAnchor:self.subOptionScrollView.widthAnchor
                                  constant:-32];
  subOptionWidthConstraint.priority = UILayoutPriorityDefaultLow;
  subOptionWidthConstraint.active = YES;

  // 滑动条容器约束（位于面板上方，在面板顶部）
  [NSLayoutConstraint activateConstraints:@[
    [self.sliderContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.sliderContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.sliderContainer.bottomAnchor constraintEqualToAnchor:self.panelRootView.topAnchor]
  ]];
  // 存储高度约束，以便动态调整（初始为 0，因为滑块默认隐藏）
  self.sliderContainerHeightConstraint =
      [self.sliderContainer.heightAnchor constraintEqualToConstant:0];
  self.sliderContainerHeightConstraint.active = YES;

  // Before/After 按钮约束（动态位置：面板展开时贴近面板顶部，面板折叠时贴近底部控制面板）
  [NSLayoutConstraint activateConstraints:@[
    [self.beforeAfterButton.widthAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.heightAnchor constraintEqualToConstant:50],
    [self.beforeAfterButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                          constant:-16]
  ]];

  // 创建两个约束：一个绑定到面板顶部（展开时），一个绑定到底部控制面板（折叠时）
  // 注意：bottomControlPanel 此时可能还未创建，所以初始约束在 hidePanel 中设置
  // 这里先创建一个临时约束，实际会在 showPanel/hidePanel 中动态切换
}

- (void)setupBottomControlPanel {
  // 底部控制面板（美颜美型、美妆、拍照、贴纸特效、滤镜调色）
  self.bottomControlPanel = [[UIView alloc] init];
  self.bottomControlPanel.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomControlPanel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
  self.bottomControlPanel.userInteractionEnabled = YES;  // 确保底部控制面板可以接收点击事件
  [self.view addSubview:self.bottomControlPanel];

  UIStackView *buttonStack = [[UIStackView alloc] init];
  buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
  buttonStack.axis = UILayoutConstraintAxisHorizontal;
  buttonStack.distribution = UIStackViewDistributionFillEqually;
  buttonStack.spacing = 0;

  // 按钮配置：图标名称和标题
  NSArray *buttonConfigs = @[
    @{@"icon" : @"meiyan", @"title" : @"美颜美型"},
    @{@"icon" : @"meizhuang", @"title" : @"美妆"},
    @{@"icon" : @"camera2", @"title" : @"拍照"},
    @{@"icon" : @"tiezhi2", @"title" : @"贴纸特效"},
    @{@"icon" : @"lvjing", @"title" : @"滤镜调色"}
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
      // 设置为模板模式以便着色
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
    buttonStackItem.userInteractionEnabled = NO;  // 禁用 StackView 交互，避免拦截按钮的触摸事件
    [NSLayoutConstraint activateConstraints:@[
      [buttonStackItem.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
      [buttonStackItem.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
    ]];

    // 如果是拍照按钮（中间），使用白色外圆 + 绿色内圆
    if ([config[@"title"] isEqualToString:@"拍照"]) {
      // 移除图标和文字
      [buttonStackItem removeArrangedSubview:iconView];
      [buttonStackItem removeArrangedSubview:titleLabel];
      [iconView removeFromSuperview];
      [titleLabel removeFromSuperview];

      // 创建白色外圆容器
      UIView *outerCircleView = [[UIView alloc] init];
      outerCircleView.translatesAutoresizingMaskIntoConstraints = NO;
      outerCircleView.backgroundColor = [UIColor whiteColor];
      outerCircleView.layer.cornerRadius = 30;  // 60 / 2 = 30
      outerCircleView.layer.masksToBounds = YES;
      [button addSubview:outerCircleView];

      // 创建绿色内圆
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
        // 外层白色圆 60x60，居中
        [outerCircleView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [outerCircleView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [outerCircleView.widthAnchor constraintEqualToConstant:60],
        [outerCircleView.heightAnchor constraintEqualToConstant:60],

        // 内层绿色圆 50x50，居中在外层圆内
        [innerCircleView.centerXAnchor constraintEqualToAnchor:outerCircleView.centerXAnchor],
        [innerCircleView.centerYAnchor constraintEqualToAnchor:outerCircleView.centerYAnchor],
        [innerCircleView.widthAnchor constraintEqualToConstant:50],
        [innerCircleView.heightAnchor constraintEqualToConstant:50]
      ]];

      // 拍照按钮点击事件
      [button addTarget:self
                    action:@selector(captureButtonTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    } else {
      // 其他按钮：根据标题映射到对应的 Tab
      NSString *title = config[@"title"];
      SEL selector = nil;

      if ([title isEqualToString:@"美颜美型"]) {
        selector = @selector(beautyButtonTapped:);
      } else if ([title isEqualToString:@"美妆"]) {
        selector = @selector(makeupButtonTapped:);
      } else if ([title isEqualToString:@"贴纸特效"]) {
        selector = @selector(stickerButtonTapped:);
      } else if ([title isEqualToString:@"滤镜调色"]) {
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
  self.panelRootView.userInteractionEnabled = YES;  // 面板显示时可以接收触摸事件
  self.view.userInteractionEnabled = YES;
  self.bottomControlPanel.hidden = YES;
  // 显示对比按钮（与滑块独立控制）
  self.beforeAfterButton.hidden = NO;

  // 切换约束：面板展开时，按钮贴近面板顶部
  if (self.beforeAfterButtonBottomConstraint) {
    self.beforeAfterButtonBottomConstraint.active = NO;
  }
  self.beforeAfterButtonBottomConstraint =
      [self.beforeAfterButton.bottomAnchor constraintEqualToAnchor:self.panelRootView.topAnchor
                                                          constant:-10];
  self.beforeAfterButtonBottomConstraint.active = YES;

  // 确保顶部栏始终在最上层
  [self.view bringSubviewToFront:self.topBar];
  // 确保对比按钮在最上层，不被底部控件遮挡
  [self.view bringSubviewToFront:self.beforeAfterButton];

  // 更新布局
  [UIView animateWithDuration:0.2
                   animations:^{
                     [self.view layoutIfNeeded];
                   }];
}

- (void)hidePanel {
  self.isPanelVisible = NO;
  self.panelRootView.hidden = YES;
  self.panelRootView.userInteractionEnabled = NO;  // 面板隐藏时禁用交互，避免拦截顶部按钮的触摸事件
  self.view.userInteractionEnabled = YES;  // 保持可交互，以便 bottomControlPanel 可以接收点击事件
  self.bottomControlPanel.hidden = NO;
  [self hideSubOptions];
  [self hideSlider];

  // 切换约束：面板折叠时，按钮贴近底部控制面板
  if (self.beforeAfterButtonBottomConstraint) {
    self.beforeAfterButtonBottomConstraint.active = NO;
  }
  self.beforeAfterButtonBottomConstraint =
      [self.beforeAfterButton.bottomAnchor constraintEqualToAnchor:self.bottomControlPanel.topAnchor
                                                          constant:-10];
  self.beforeAfterButtonBottomConstraint.active = YES;

  // 确保顶部栏始终在最上层
  [self.view bringSubviewToFront:self.topBar];
  // 面板隐藏时仍显示对比按钮，并置顶
  self.beforeAfterButton.hidden = NO;
  [self.view bringSubviewToFront:self.beforeAfterButton];

  // 更新布局
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
  // 清空现有按钮和指示器
  for (UIButton *button in self.functionButtons) {
    [self.functionButtonContainer removeArrangedSubview:button];
    [button removeFromSuperview];
  }
  [self.functionButtons removeAllObjects];
  [self.functionIndicatorViews removeAllObjects];  // 清空指示器引用

  // 根据当前 Tab 创建按钮
  NSArray *functions = [self functionsForCurrentTab];

  for (NSDictionary *function in functions) {
    UIButton *button = [self createFunctionButton:function];

    // 处理禁用状态：只有当明确设置为 @NO 时才禁用，默认是可用状态
    NSNumber *enabled = function[@"enabled"];
    if (enabled != nil && [enabled boolValue] == NO) {
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

  // 更新选中指示器状态
  [self updateSelectionIndicators];
}

- (NSArray *)functionsForCurrentTab {
  if ([self.currentTab isEqualToString:@"beauty"]) {
    // 美颜：关闭、美白(可用)、美黑(禁用)、磨皮(可用)、红润(可用)
    // 参考 Android: white, smooth, rosiness 可用；dark 禁用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"white", @"title" : @"美白", @"icon" : @"meiyan"},
      @{@"key" : @"dark", @"title" : @"美黑", @"icon" : @"huanfase", @"enabled" : @NO},
      @{@"key" : @"smooth", @"title" : @"磨皮", @"icon" : @"meiyan2"},
      @{@"key" : @"ai", @"title" : @"红润", @"icon" : @"meiyan"}
    ];
  } else if ([self.currentTab isEqualToString:@"reshape"]) {
    // 美型：关闭、瘦脸、V脸、窄脸、短脸、颧骨、下颌、下巴、瘦鼻、大眼、眼距
    // 参考 Android: 10个 reshape 参数全部可用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"thin_face", @"title" : @"瘦脸", @"icon" : @"meixing2"},
      @{@"key" : @"v_face", @"title" : @"V脸", @"icon" : @"meixing2"},
      @{@"key" : @"narrow_face", @"title" : @"窄脸", @"icon" : @"meixing2"},
      @{@"key" : @"short_face", @"title" : @"短脸", @"icon" : @"meixing2"},
      @{@"key" : @"cheekbone", @"title" : @"颧骨", @"icon" : @"meixing2"},
      @{@"key" : @"jawbone", @"title" : @"下颌", @"icon" : @"meixing2"},
      @{@"key" : @"chin", @"title" : @"下巴", @"icon" : @"meixing2"},
      @{@"key" : @"nose_slim", @"title" : @"瘦鼻", @"icon" : @"meixing2"},
      @{@"key" : @"big_eye", @"title" : @"大眼", @"icon" : @"meixing2"},
      @{@"key" : @"eye_distance", @"title" : @"眼距", @"icon" : @"meixing2"}
    ];
  } else if ([self.currentTab isEqualToString:@"makeup"]) {
    // 美妆：关闭、口红、腮红、眉毛、眼影（全部可用，有子选项）
    // 参考 Android: 4个功能全部可用，都有子选项
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"lipstick", @"title" : @"口红", @"icon" : @"meizhuang"},
      @{@"key" : @"blush", @"title" : @"腮红", @"icon" : @"meizhuang"},
      @{@"key" : @"eyebrow", @"title" : @"眉毛", @"icon" : @"meizhuang"},
      @{@"key" : @"eyeshadow", @"title" : @"眼影", @"icon" : @"meizhuang"}
    ];
  } else if ([self.currentTab isEqualToString:@"filter"]) {
    // 滤镜：关闭、自然、清新、复古、黑白（全部可用）
    // 参考 Android: 4个滤镜全部可用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"natural", @"title" : @"自然", @"icon" : @"lvjing"},
      @{@"key" : @"fresh", @"title" : @"清新", @"icon" : @"lvjing"},
      @{@"key" : @"retro", @"title" : @"复古", @"icon" : @"lvjing"},
      @{@"key" : @"bw", @"title" : @"黑白", @"icon" : @"lvjing"}
    ];
  } else if ([self.currentTab isEqualToString:@"sticker"]) {
    // 贴纸：关闭、可爱、搞笑（全部禁用）
    // 参考 Android: 只有2个，都禁用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"cute", @"title" : @"可爱", @"icon" : @"tiezhi2", @"enabled" : @NO},
      @{@"key" : @"funny", @"title" : @"搞笑", @"icon" : @"tiezhi2", @"enabled" : @NO}
    ];
  } else if ([self.currentTab isEqualToString:@"body"]) {
    // 美体：关闭、瘦身（禁用）
    // 参考 Android: 只有1个，禁用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"slim", @"title" : @"瘦身", @"icon" : @"meiti", @"enabled" : @NO}
    ];
  } else if ([self.currentTab isEqualToString:@"virtual_bg"]) {
    // 虚拟背景：关闭、模糊、预置、图像（全部可用，开关类型）
    // 参考 Android: blur, preset, image 全部可用（开关类型，不是滑块）
    // 添加关闭按钮以保持与其他 tab 的一致性
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"blur", @"title" : @"模糊", @"icon" : @"xunibeijing", @"type" : @"toggle"},
      @{@"key" : @"preset", @"title" : @"预置", @"icon" : @"back_preset", @"type" : @"toggle"},
      @{@"key" : @"image", @"title" : @"图像", @"icon" : @"photo", @"type" : @"toggle"}
    ];
  } else if ([self.currentTab isEqualToString:@"quality"]) {
    // 画质调整：关闭、锐化（禁用）
    // 参考 Android: 只有1个，禁用
    return @[
      @{@"key" : @"off", @"title" : @"关闭", @"icon" : @"disable"},
      @{@"key" : @"sharpen", @"title" : @"锐化", @"icon" : @"huazhitiaozheng2", @"enabled" : @NO}
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

  // 图标容器（深灰色背景，圆形）
  UIView *iconContainer = [[UIView alloc] init];
  iconContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
  iconContainer.layer.cornerRadius = 25;

  // 图标（从 Assets 读取或使用系统图标）
  UIImageView *iconView = [[UIImageView alloc] init];
  NSString *iconName = function[@"icon"];
  UIImage *iconImage = [UIImage imageNamed:iconName];
  if (!iconImage) {
    // 如果是系统图标名称，使用系统图标
    if (@available(iOS 13.0, *)) {
      iconImage = [UIImage systemImageNamed:iconName];
      if (iconImage) {
        iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      }
    }
  } else {
    // 普通图片设置为模板模式以便着色
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

  // 选中指示器：绿色短横线，位于文字下方
  UIView *indicator = [[UIView alloc] init];
  indicator.backgroundColor = [UIColor colorWithRed:0.0
                                              green:1.0
                                               blue:0.0
                                              alpha:1.0];  // #00FF00 绿色
  indicator.layer.cornerRadius = 1.5;                      // 约 3pt / 2 = 1.5pt
  indicator.hidden = YES;                                  // 默认隐藏
  indicator.translatesAutoresizingMaskIntoConstraints = NO;

  [stackView addArrangedSubview:iconContainer];
  [stackView addArrangedSubview:titleLabel];
  [stackView addArrangedSubview:indicator];
  stackView.userInteractionEnabled = NO;  // 禁用 StackView 交互，避免拦截按钮的触摸事件

  // 设置指示器大小约束（14pt x 3pt，参考 Android 的 14dp x 3dp）
  [NSLayoutConstraint activateConstraints:@[
    [indicator.widthAnchor constraintEqualToConstant:14],
    [indicator.heightAnchor constraintEqualToConstant:3]
  ]];

  // 保存该功能的指示器引用（带 tab 前缀）
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
  // 强制更新布局，确保 ScrollView 的 contentSize 正确计算
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.subOptionScrollView layoutIfNeeded];
  });
}

- (void)hideSubOptions {
  self.isSubOptionVisible = NO;
  self.subOptionScrollView.hidden = YES;
}

- (void)setupSliderContainer {
  // 滑动条容器应该在面板上方，而不是在面板内部
  self.sliderContainer = [[UIView alloc] init];
  self.sliderContainer.translatesAutoresizingMaskIntoConstraints = NO;
  self.sliderContainer.backgroundColor = [UIColor clearColor];
  self.sliderContainer.hidden = YES;
  self.isSliderVisible = NO;
  [self.view addSubview:self.sliderContainer];  // 添加到 view 而不是 panelRootView

  // 数值标签
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

  // 滑块
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
                                                    constant:-80],  // 为 Before/After 按钮留出空间
    [self.valueSlider.centerYAnchor constraintEqualToAnchor:self.sliderContainer.centerYAnchor],
    [self.valueSlider.heightAnchor constraintEqualToConstant:30]
  ]];

  // Before/After 对比按钮
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

  // 只设置按钮内部的图标约束，按钮本身的约束在 setupPanelConstraints 中设置
  [NSLayoutConstraint activateConstraints:@[
    [iconView.widthAnchor constraintEqualToConstant:22],
    [iconView.heightAnchor constraintEqualToConstant:22],
    [iconView.centerXAnchor constraintEqualToAnchor:self.beforeAfterButton.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:self.beforeAfterButton.centerYAnchor]
  ]];

  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterButtonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
  // 按住预览原图：按下关闭所有参数，松开恢复用户已设置参数
  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterTouchDown:)
                   forControlEvents:UIControlEventTouchDown];
  [self.beforeAfterButton addTarget:self
                             action:@selector(beforeAfterTouchUp:)
                   forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                                     UIControlEventTouchCancel)];
  self.beforeAfterButton.hidden = YES;  // 默认隐藏，与滑动条一起显示/隐藏
  [self.view addSubview:self.beforeAfterButton];
}

- (void)showSlider {
  self.isSliderVisible = YES;
  self.sliderContainer.hidden = NO;
  self.valueLabel.hidden = NO;
  // 更新高度约束，显示滑块
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
  // 更新高度约束，隐藏滑块（高度为 0）
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

  // 保存当前功能的进度（0-100）
  if (self.currentTab && self.currentFunction) {
    NSString *progressKey =
        [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
    self.functionProgress[progressKey] = @(value);
  }

  // 通知代理参数变化（将进度值 0-100 转换为参数值 0.0-1.0）
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
    self.currentFunction = nil;  // 切换 tab 时清空当前功能
    [self updateFunctionButtons];
    [self hideSubOptions];
    [self updateSelectionIndicators];  // 更新指示器（隐藏所有，因为切换 tab 后没有选中功能）
  }
}

- (void)functionButtonTapped:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index < self.functionButtons.count) {
    NSArray *functions = [self functionsForCurrentTab];
    if (index < functions.count) {
      NSDictionary *function = functions[index];

      // 检查是否禁用：只有当明确设置为 @NO 时才禁用
      NSNumber *enabled = function[@"enabled"];
      if (enabled != nil && [enabled boolValue] == NO) {
        return;  // 禁用功能不响应点击
      }

      NSString *functionKey = function[@"key"];

      // 处理关闭按钮
      if ([functionKey isEqualToString:@"off"]) {
        [self handleOffButtonClicked];
        return;
      }

      // 检查按钮类型：如果是开关类型（toggle），不显示滑动条
      NSString *buttonType = function[@"type"];
      if ([buttonType isEqualToString:@"toggle"]) {
        // 开关类型：切换状态，不显示滑动条
        [self handleToggleFunction:functionKey];
        return;
      }

      self.currentFunction = functionKey;

      // 更新选中指示器
      [self updateSelectionIndicators];

      // 显示滑块用于调节参数（滑动条类型）
      [self showSlider];
      [self hideSubOptions];

      // 更新滑块初始值（根据当前功能的状态）
      NSString *progressKey =
          [NSString stringWithFormat:@"%@:%@", self.currentTab, self.currentFunction];
      NSNumber *progress = self.functionProgress[progressKey];
      if (progress) {
        self.valueSlider.value = [progress floatValue];
      } else {
        self.valueSlider.value = 0;  // 默认值 0（参考 Android）
      }
      self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.valueSlider.value];

      // 使用当前值立即应用一次参数，保证切换功能后立即生效（参考 Android）
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
  // 清空当前功能选择
  self.currentFunction = nil;

  // 隐藏子选项和滑块
  [self hideSubOptions];
  [self hideSlider];

  if (!self.currentTab) {
    return;
  }

  // 清除当前 Tab 下所有已保存的滑动条进度
  NSString *prefix = [NSString stringWithFormat:@"%@:", self.currentTab];
  NSMutableArray *keysToRemove = [NSMutableArray array];
  for (NSString *key in self.functionProgress.allKeys) {
    if ([key hasPrefix:prefix]) {
      [keysToRemove addObject:key];
    }
  }
  [self.functionProgress removeObjectsForKeys:keysToRemove];

  // 根据 Tab 类型决定关闭逻辑
  if ([self.currentTab isEqualToString:@"virtual_bg"]) {
    // 虚拟背景 Tab：关闭所有开关型功能的状态
    NSString *togglePrefix = [NSString stringWithFormat:@"%@:", self.currentTab];
    NSMutableArray *toggleKeysToUpdate = [NSMutableArray array];
    for (NSString *key in self.toggleStates.allKeys) {
      if ([key hasPrefix:togglePrefix] && [self.toggleStates[key] boolValue]) {
        NSString *functionKey = [key substringFromIndex:togglePrefix.length];
        [toggleKeysToUpdate addObject:key];
        // TODO: 更新视觉状态（如果有开关按钮的视觉反馈）
      }
    }
    for (NSString *key in toggleKeysToUpdate) {
      self.toggleStates[key] = @NO;
    }
    // 调用回调，传递 "none" 表示关闭虚拟背景
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
      [self.delegate beautyPanelDidChangeParam:self.currentTab function:@"none" value:0.0f];
    }
  } else {
    // 其他 Tab：逐个关闭所有开启的开关型功能
    NSString *togglePrefix = [NSString stringWithFormat:@"%@:", self.currentTab];
    NSMutableArray *toggleKeysToUpdate = [NSMutableArray array];
    for (NSString *key in self.toggleStates.allKeys) {
      if ([key hasPrefix:togglePrefix] && [self.toggleStates[key] boolValue]) {
        NSString *functionKey = [key substringFromIndex:togglePrefix.length];
        [toggleKeysToUpdate addObject:key];
        // 调用回调关闭功能
        if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:
                                                                         function:value:)]) {
          [self.delegate beautyPanelDidChangeParam:self.currentTab function:functionKey value:0.0f];
        }
        // TODO: 更新视觉状态（如果有开关按钮的视觉反馈）
      }
    }
    for (NSString *key in toggleKeysToUpdate) {
      self.toggleStates[key] = @NO;
    }
    // 通知宿主重置当前Tab（滑动条型功能）
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidResetTab:)]) {
      [self.delegate beautyPanelDidResetTab:self.currentTab];
    }
  }

  // 更新选中指示器（隐藏所有指示器）
  [self updateSelectionIndicators];
}

- (void)handleToggleFunction:(NSString *)functionKey {
  // 特殊处理：图像按钮需要打开图片选择器
  if ([functionKey isEqualToString:@"image"] && [self.currentTab isEqualToString:@"virtual_bg"]) {
    // 图像按钮：打开图片选择器
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidRequestImageSelection:
                                                                               function:)]) {
      [self.delegate beautyPanelDidRequestImageSelection:self.currentTab function:functionKey];
    }
    // 不更新状态，等待图片选择完成后再更新
    return;
  }

  // 普通开关型功能：切换状态（包括模糊和预置背景）
  NSString *toggleKey = [NSString stringWithFormat:@"%@:%@", self.currentTab, functionKey];
  BOOL currentState = [self.toggleStates[toggleKey] boolValue];
  BOOL newState = !currentState;

  // 更新状态
  self.toggleStates[toggleKey] = @(newState);

  // 立即调用回调（1.0 = 开启, 0.0 = 关闭）
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:function:value:)]) {
    [self.delegate beautyPanelDidChangeParam:self.currentTab
                                    function:functionKey
                                       value:newState ? 1.0f : 0.0f];
  }

  // 更新视觉状态（如果有开关按钮的视觉反馈）
  // TODO: 更新按钮的视觉状态（例如背景色、边框等）

  // 更新选中指示器（开关类型也显示选中指示器）
  self.currentFunction = functionKey;
  [self updateSelectionIndicators];

  // 开关类型不显示滑动条，只切换状态
  [self hideSlider];
  [self hideSubOptions];
}

- (void)updateSelectionIndicators {
  // 构建当前选中功能的完整键（tab:function）
  NSString *selectedKey =
      [NSString stringWithFormat:@"%@:%@", self.currentTab ?: @"", self.currentFunction ?: @""];

  // 遍历所有指示器，显示选中的，隐藏其他的
  for (NSString *key in self.functionIndicatorViews.allKeys) {
    UIView *indicator = self.functionIndicatorViews[key];
    if (indicator) {
      indicator.hidden = ![key isEqualToString:selectedKey];
    }
  }
}

- (void)resetButtonTapped:(UIButton *)sender {
  // 重置滑块进度到默认值（0）
  self.valueSlider.value = 0;
  self.valueLabel.text = @"0";

  // 清空当前功能选择
  self.currentFunction = nil;

  // 更新选中指示器（隐藏所有指示器）
  [self updateSelectionIndicators];

  // 隐藏子选项和滑块
  [self hideSubOptions];
  [self hideSlider];

  // 清空所有功能进度
  [self.functionProgress removeAllObjects];

  // 清空所有切换状态
  [self.toggleStates removeAllObjects];

  // 通知代理重置所有美颜参数
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)captureButtonTapped:(UIButton *)sender {
  // TODO: 拍照功能
}

- (void)hidePanelButtonTapped:(UIButton *)sender {
  // 隐藏子选项和滑块
  [self hideSubOptions];
  [self hideSlider];

  // 隐藏面板
  [self hidePanel];
}

- (void)beforeAfterButtonTapped:(UIButton *)sender {
  // 单击不处理，由按下/松开事件控制预览开关
}

- (void)beforeAfterTouchDown:(UIButton *)sender {
  // 按下：关闭所有美颜参数预览原图（不修改已保存的 UI 数值状态）
  if ([self.delegate respondsToSelector:@selector(beautyPanelDidReset)]) {
    [self.delegate beautyPanelDidReset];
  }
}

- (void)beforeAfterTouchUp:(UIButton *)sender {
  // 松开：恢复用户已设置参数（依据本地缓存的 functionProgress/toggleStates）
  // 1) 恢复滑动条类参数（beauty/reshape/makeup）
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
  // 2) 恢复开关类（如虚拟背景 blur/preset），true 表示开启
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
    // 跳过 image（需要外部保留图像资源，无法简单恢复）
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
  // 显示美颜面板并切换到美颜 Tab
  [self showPanel];
  [self switchToTab:@"beauty"];
}

- (void)makeupButtonTapped:(UIButton *)sender {
  // 显示美颜面板并切换到美妆 Tab
  [self showPanel];
  [self switchToTab:@"makeup"];
}

- (void)stickerButtonTapped:(UIButton *)sender {
  // 显示美颜面板并切换到贴纸 Tab
  [self showPanel];
  [self switchToTab:@"sticker"];
}

- (void)filterButtonTapped:(UIButton *)sender {
  // 显示美颜面板并切换到滤镜 Tab
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
