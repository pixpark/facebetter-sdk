//
//  GLRGBARenderView.h
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//

#import <Facebetter/FBBeautyEffectEngine.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLRGBARenderView : UIView

- (void)renderBuffer:(FBImageBuffer *)buffer;

// 设置是否水平镜像（默认 NO）
- (void)setMirrored:(BOOL)mirrored;

@end

NS_ASSUME_NONNULL_END
