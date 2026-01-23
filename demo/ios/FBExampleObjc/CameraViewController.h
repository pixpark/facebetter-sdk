//
//  CameraViewController.h
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//  Renamed from ViewController to CameraViewController
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "BeautyPanelViewController.h"
#import "CameraManager.h"

@interface CameraViewController : UIViewController <CameraManagerDelegate, BeautyPanelDelegate>

- (instancetype)initWithInitialTab:(NSString *)initialTab;
- (instancetype)init;

@end
