//
//  AppDelegate.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property(nonatomic, strong) NSWindow *mainWindow;

@end

@implementation AppDelegate

static const CGFloat kMainWindowContentWidth = 900;
static const CGFloat kMainWindowContentHeight = 600;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSWindowStyleMask styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
  NSRect contentRect = NSMakeRect(0, 0, kMainWindowContentWidth, kMainWindowContentHeight);
  NSRect windowRect = [NSWindow frameRectForContentRect:contentRect styleMask:styleMask];

  self.mainWindow = [[NSWindow alloc] initWithContentRect:contentRect
                                                styleMask:styleMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
  self.mainWindow.title = @"Facebetter";
  self.mainWindow.delegate = self;
  if (@available(macOS 10.14, *)) {
    self.mainWindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
  }

  ViewController *rootVC = [[ViewController alloc] init];
  self.mainWindow.contentViewController = rootVC;
  [self.mainWindow setContentSize:NSMakeSize(kMainWindowContentWidth, kMainWindowContentHeight)];
  self.mainWindow.minSize = NSMakeSize(kMainWindowContentWidth, kMainWindowContentHeight);
  self.mainWindow.maxSize = NSMakeSize(kMainWindowContentWidth, kMainWindowContentHeight);

  NSRect screenFrame = [[NSScreen mainScreen] frame];
  NSRect centeredRect = NSMakeRect((screenFrame.size.width - windowRect.size.width) / 2,
                                   (screenFrame.size.height - windowRect.size.height) / 2,
                                   windowRect.size.width,
                                   windowRect.size.height);
  [self.mainWindow setFrame:centeredRect display:YES];
  [self.mainWindow makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
  return NO;
}

#pragma mark - NSWindowDelegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  NSRect contentRect = NSMakeRect(0, 0, kMainWindowContentWidth, kMainWindowContentHeight);
  NSRect windowRect = [NSWindow frameRectForContentRect:contentRect styleMask:sender.styleMask];
  return windowRect.size;
}

- (void)windowDidResize:(NSNotification *)notification {
  NSWindow *window = notification.object;
  if (window == self.mainWindow) {
    NSSize currentContentSize = window.contentView.bounds.size;
    if (fabs(currentContentSize.width - kMainWindowContentWidth) > 1 ||
        fabs(currentContentSize.height - kMainWindowContentHeight) > 1) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [window setContentSize:NSMakeSize(kMainWindowContentWidth, kMainWindowContentHeight)];
      });
    }
  }
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
  return YES;
}

@end
