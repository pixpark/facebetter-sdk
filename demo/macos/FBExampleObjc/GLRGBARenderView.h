//
//  GLRGBARenderView.h
//  FBExampleObjc (macOS)
//

#import <Cocoa/Cocoa.h>

@class FBImageFrame;

NS_ASSUME_NONNULL_BEGIN

@interface GLRGBARenderView : NSOpenGLView

/// Renders RGBA FBImageFrame (convert to FBImageFormatRGBA first if needed).
- (void)renderFrame:(FBImageFrame *)frame;
 
@end

NS_ASSUME_NONNULL_END
