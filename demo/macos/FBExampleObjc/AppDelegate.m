//
//  AppDelegate.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import "AppDelegate.h"
#import "HomeViewController.h"

@interface AppDelegate ()

@property(nonatomic, strong) NSWindow *mainWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // 创建主窗口，固定大小为 600x600（内容区域）
  // 移除 NSWindowStyleMaskResizable，使窗口不可调整大小
  NSWindowStyleMask styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;

  // 计算窗口 frame（包含标题栏）
  NSRect contentRect = NSMakeRect(0, 0, 600, 600);
  NSRect windowRect = [NSWindow frameRectForContentRect:contentRect styleMask:styleMask];

  self.mainWindow = [[NSWindow alloc] initWithContentRect:contentRect
                                                styleMask:styleMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
  self.mainWindow.title = @"Facebetter";
  self.mainWindow.delegate = self;  // 设置窗口代理，防止窗口大小改变

  // 强制使用浅色模式，不响应系统暗黑模式
  if (@available(macOS 10.14, *)) {
    self.mainWindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }

  // 设置内容区域大小为 600x600
  [self.mainWindow setContentSize:NSMakeSize(600, 600)];

  // 设置最小和最大尺寸都为 600x600，确保窗口大小固定
  self.mainWindow.minSize = NSMakeSize(600, 600);
  self.mainWindow.maxSize = NSMakeSize(600, 600);

  // 创建 HomeViewController
  HomeViewController *homeVC = [[HomeViewController alloc] init];
  self.mainWindow.contentViewController = homeVC;

  // 设置窗口 frame，确保大小正确（包含标题栏）
  NSRect screenFrame = [[NSScreen mainScreen] frame];
  NSRect centeredRect = NSMakeRect((screenFrame.size.width - windowRect.size.width) / 2,
                                   (screenFrame.size.height - windowRect.size.height) / 2,
                                   windowRect.size.width,
                                   windowRect.size.height);
  [self.mainWindow setFrame:centeredRect display:YES];

  // 显示窗口
  [self.mainWindow makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  // ensure the application exits when the last window is closed
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
  return YES;
}

#pragma mark - NSWindowDelegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  // 阻止窗口大小改变，始终返回固定大小（600x600 内容区域对应的窗口大小）
  NSRect contentRect = NSMakeRect(0, 0, 600, 600);
  NSRect windowRect = [NSWindow frameRectForContentRect:contentRect styleMask:sender.styleMask];
  return windowRect.size;
}

- (void)windowDidResize:(NSNotification *)notification {
  // 如果窗口大小被改变，强制恢复为 600x600
  NSWindow *window = notification.object;
  if (window == self.mainWindow) {
    NSSize currentContentSize = window.contentView.bounds.size;
    if (fabs(currentContentSize.width - 600) > 1 || fabs(currentContentSize.height - 600) > 1) {
      // 使用 dispatch_async 避免在 resize 通知中直接修改导致循环
      dispatch_async(dispatch_get_main_queue(), ^{
        [window setContentSize:NSMakeSize(600, 600)];
      });
    }
  }
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
  return YES;
}

@end
