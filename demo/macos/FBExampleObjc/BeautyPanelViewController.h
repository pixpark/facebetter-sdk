//
//  BeautyPanelViewController.h
//  FBExampleObjc
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BeautyPanelDelegate <NSObject>
/** Param change: tab (e.g. "beauty"), function (e.g. "smooth"), value 0.0–1.0 (intensity) or 0/1 (off/on). */
- (void)beautyPanelDidChangeParam:(NSString *)tab function:(NSString *)function value:(float)value;
- (void)beautyPanelDidReset;
/** Reset params for the given tab. */
- (void)beautyPanelDidResetTab:(NSString *)tab;
/** Image selection (e.g. virtual background). */
- (void)beautyPanelDidRequestImageSelection:(NSString *)tab function:(NSString *)function;

- (void)beautyPanelDidTapCloseButton;
- (void)beautyPanelDidTapGalleryButton;
- (void)beautyPanelDidTapFlipCameraButton;
- (void)beautyPanelDidTapMoreButton;

@optional
/** Makeup style change: function (e.g. "lipstick", "blush"), styleIndex 0/1/2. Engine may use this when supported. */
- (void)beautyPanelDidChangeMakeupStyle:(NSString *)function styleIndex:(NSInteger)styleIndex;
/** Slider visibility changed: YES = panel should expand height for slider strip, NO = collapse. */
- (void)beautyPanelSliderVisibilityDidChange:(BOOL)visible;
@end

@interface BeautyPanelViewController : NSViewController

@property(nonatomic, assign) id<BeautyPanelDelegate> delegate;

- (void)showPanel;
- (void)hidePanel;
- (void)togglePanelVisibility;
- (void)switchToTab:(NSString *)tab;

@end

NS_ASSUME_NONNULL_END
