#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Camera buffer to GL_TEXTURE_2D, then Facebetter, then the screen.
@interface CameraGlView : UIView

@property (nonatomic, copy, nullable) void (^onStatus)(NSString *status);
@property (nonatomic, copy, nullable) void (^onFrameMs)(double milliseconds);

- (void)start;
- (void)shutdown;
- (void)applySmoothing:(float)smoothing
             whitening:(float)whitening
              rosiness:(float)rosiness
               blemish:(float)blemish
               clarity:(float)clarity
              skinOnly:(BOOL)skinOnly;

@end

NS_ASSUME_NONNULL_END
