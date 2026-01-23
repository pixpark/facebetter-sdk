//
//  BeautyPanelViewController.h
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//  Updated for new UI matching iOS layout
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BeautyPanelDelegate <NSObject>
/**
 * 美颜参数变化回调（参考 iOS 实现）
 * @param tab 当前Tab: "beauty", "reshape", "makeup", "virtual_bg" 等
 * @param function 当前功能: "white", "smooth", "blur" 等
 * @param value 参数值：
 *              - 滑动条型功能：0.0 ~ 1.0 表示强度
 *              - 开关型功能：1.0 表示开启，0.0 表示关闭
 */
- (void)beautyPanelDidChangeParam:(NSString *)tab function:(NSString *)function value:(float)value;

/**
 * 重置所有美颜参数
 */
- (void)beautyPanelDidReset;

/**
 * 重置指定 Tab 下的所有参数
 * @param tab 当前Tab
 */
- (void)beautyPanelDidResetTab:(NSString *)tab;

/**
 * 图片选择回调（用于虚拟背景等需要选择图片的功能）
 * @param tab 当前Tab
 * @param function 当前功能（如 "image"）
 */
- (void)beautyPanelDidRequestImageSelection:(NSString *)tab function:(NSString *)function;

// 顶部按钮事件回调
- (void)beautyPanelDidTapCloseButton;
- (void)beautyPanelDidTapGalleryButton;
- (void)beautyPanelDidTapFlipCameraButton;
- (void)beautyPanelDidTapMoreButton;
@end

@interface BeautyPanelViewController : NSViewController

@property(nonatomic, assign) id<BeautyPanelDelegate> delegate;

- (void)showPanel;
- (void)hidePanel;
- (void)togglePanelVisibility;
- (void)switchToTab:(NSString *)tab;

@end

NS_ASSUME_NONNULL_END
