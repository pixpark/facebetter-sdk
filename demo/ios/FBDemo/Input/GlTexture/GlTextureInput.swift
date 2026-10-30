import Foundation

/// External-texture path. Call this on the thread that owns the GL context.
/// The texture is GL_TEXTURE_2D and is already upright. This path does not mirror or rotate.
enum GlTextureInput {
  static func process(
    texture: UInt32,
    width: Int32,
    height: Int32,
    engine: BeautyEngine,
    bypass: Bool
  ) -> UInt32? {
    guard !bypass, texture != 0 else { return nil }
    return engine.withEngine { fb in
      guard let input = FBImageFrame.create(
        withTexture: texture,
        width: width,
        height: height,
        stride: width * 4
      ) else {
        return nil
      }
      input.type = .video
      guard let output = fb.processImage(input) else { return nil }
      let rendered = output.texture()
      return rendered == 0 ? nil : rendered
    }
  }
}
