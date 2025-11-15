//
//  GLRGBARenderView.h
//  FBExampleObjc (macOS)
//

#import <Cocoa/Cocoa.h>
#import <Facebetter/FBBeautyEffectEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLRGBARenderView : NSOpenGLView

- (void)renderBuffer:(FBImageBuffer *)buffer;

// 设置是否水平镜像显示（默认 NO）
- (void)setMirrored:(BOOL)mirrored;

@end

NS_ASSUME_NONNULL_END
