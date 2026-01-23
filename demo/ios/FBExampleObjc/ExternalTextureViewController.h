//
//  ExternalTextureViewController.h
//  FBExampleObjc
//
//  使用 externalContext + 纹理输入的最小 iOS 示例。
//
//  流程：
//  1. 使用 GLTextureRenderView 并设置 delegate 回调
//  2. GLTextureRenderView 内部读取图片生成纹理，在回调中带出
//  3. 在回调中使用 externalContext=true 创建 BeautyEffectEngine，并调用 processImage
//  4. 将处理后的纹理返回给 GLTextureRenderView 进行渲染
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExternalTextureViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
