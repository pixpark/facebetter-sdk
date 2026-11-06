#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Facebetter engine used from the camera GL thread.
/// Same sample credentials as the iOS and Android demos. The bundle id must be bound.
@interface SkinEngine : NSObject

- (void)start:(void (^)(NSString *status))onStatus;
- (void)applySmoothing:(float)smoothing
             whitening:(float)whitening
              rosiness:(float)rosiness
               blemish:(float)blemish
               clarity:(float)clarity
              skinOnly:(BOOL)skinOnly;
- (uint32_t)processTexture:(uint32_t)texture width:(int)width height:(int)height;
- (void)releaseEngine;

@end

NS_ASSUME_NONNULL_END
