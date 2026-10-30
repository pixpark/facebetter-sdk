import CoreVideo
import UIKit

enum PixelBufferImages {
  /// Copy a BGRA frame into a new CPU-backed buffer the preview can lock.
  static func copyBGRA(_ frame: FBImageFrame) -> CVPixelBuffer? {
    let width = Int(frame.width)
    let height = Int(frame.height)
    let sourceStride = Int(frame.stride)
    guard let source = frame.data(), width > 0, height > 0 else { return nil }

    let attrs: [CFString: Any] = [
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
      kCVPixelBufferMetalCompatibilityKey: true,
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ]
    var output: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &output
    )
    guard status == kCVReturnSuccess, let output else { return nil }

    CVPixelBufferLockBaseAddress(output, [])
    defer { CVPixelBufferUnlockBaseAddress(output, []) }
    guard let destination = CVPixelBufferGetBaseAddress(output) else { return nil }
    let destinationStride = CVPixelBufferGetBytesPerRow(output)
    let rowBytes = min(sourceStride, destinationStride)
    for row in 0..<height {
      memcpy(
        destination.advanced(by: row * destinationStride),
        source.advanced(by: row * sourceStride),
        rowBytes
      )
    }
    return output
  }
}

extension UIImage {
  func fb_normalizedUp() -> UIImage {
    guard imageOrientation != .up else { return self }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }

  convenience init?(pixelBuffer: CVPixelBuffer) {
    let image = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
    self.init(cgImage: cgImage)
  }
}
