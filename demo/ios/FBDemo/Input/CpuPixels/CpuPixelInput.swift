import CoreVideo
import UIKit

/// Pointer path. Lock the camera buffer, copy BGRA, and pass the bytes to processImage.
/// Use this when the source is not a CVPixelBuffer. Video pixels are ready when this returns.
enum CpuPixelInput {
  static func process(
    _ pixelBuffer: CVPixelBuffer,
    engine: BeautyEngine,
    asImage: Bool,
    bypass: Bool
  ) -> CVPixelBuffer? {
    guard !bypass else { return nil }
    guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
      return nil
    }
    return engine.withEngine { fb in
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
      let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
      let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
      let stride = Int32(CVPixelBufferGetBytesPerRow(pixelBuffer))
      guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
      guard let input = FBImageFrame.create(
        withBGRA: base.assumingMemoryBound(to: UInt8.self),
        width: width,
        height: height,
        stride: stride
      ) else {
        return nil
      }
      input.type = asImage ? .image : .video
      guard let output = fb.processImage(input),
            let bgra = output.convert(.BGRA) else {
        return nil
      }
      return PixelBufferImages.copyBGRA(bgra)
    }
  }

  static func image(from pixelBuffer: CVPixelBuffer, engine: BeautyEngine) -> UIImage? {
    if let processed = process(pixelBuffer, engine: engine, asImage: true, bypass: false) {
      return UIImage(pixelBuffer: processed)
    }
    return UIImage(pixelBuffer: pixelBuffer)
  }
}
