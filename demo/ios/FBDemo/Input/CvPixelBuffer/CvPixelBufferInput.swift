import CoreVideo
import UIKit

/// Metal camera path. The capture buffer is already upright BGRA.
/// Video returns as soon as the command buffer is committed. Image waits for the GPU.
enum CvPixelBufferInput {
  static func process(
    _ pixelBuffer: CVPixelBuffer,
    engine: BeautyEngine,
    asImage: Bool,
    bypass: Bool
  ) -> CVPixelBuffer? {
    guard !bypass else { return nil }
    return engine.withEngine { fb in
      guard let input = FBImageFrame.create(with: pixelBuffer) else { return nil }
      input.type = asImage ? .image : .video
      guard let output = fb.processImage(input),
            let raw = output.cvPixelBuffer() else {
        return nil
      }
      // The frame owns the buffer. Returning it retains a copy for the caller.
      return raw.takeUnretainedValue()
    }
  }

  static func image(from pixelBuffer: CVPixelBuffer, engine: BeautyEngine) -> UIImage? {
    if let processed = process(pixelBuffer, engine: engine, asImage: true, bypass: false) {
      return UIImage(pixelBuffer: processed)
    }
    return UIImage(pixelBuffer: pixelBuffer)
  }
}
