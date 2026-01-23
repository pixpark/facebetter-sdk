//
//  main.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    // 手动初始化 NSApplication，避免加载 Storyboard
    NSApplication *application = [NSApplication sharedApplication];

    // 创建 AppDelegate
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    [application setDelegate:appDelegate];

    // 运行应用
    [application run];
  }
  return 0;
}
