//
//  GLTextureRenderView.h
//  FBExampleObjc
//
//  OpenGL ES 纹理渲染视图，支持外部纹理输入输出和回调处理
//

#import <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 纹理帧信息
typedef struct {
  GLuint textureId;
  int width;
  int height;
} TextureFrame;

// 视频帧处理回调协议
@protocol GLTextureRenderViewDelegate <NSObject>

/**
 * 处理视频帧纹理
 * @param srcFrame 输入纹理帧（只读）
 * @param dstFrame 输出纹理帧（可写，用于返回处理后的纹理ID和尺寸）
 * @return 错误码，0表示成功，非0表示失败
 */
- (int)onProcessVideoFrame:(TextureFrame)srcFrame dstFrame:(TextureFrame *)dstFrame;

@end

@interface GLTextureRenderView : UIView

@property(nonatomic, weak, nullable) id<GLTextureRenderViewDelegate> delegate;

// 设置是否进行左右镜像渲染（水平翻转）
- (void)setMirrored:(BOOL)mirrored;

// 启用/暂停渲染
- (void)setRenderingEnabled:(BOOL)enabled;

// 获取当前视口尺寸
- (CGSize)getViewportDimensions;

// 从图片初始化输入纹理
- (void)initializeInputTextureWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
