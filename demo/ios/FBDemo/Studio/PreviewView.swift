import SwiftUI

/// CPU-pixel and gallery preview. The buffer is already in memory, so a CGImage is safe.
final class PixelPreview: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    isOpaque = true
    contentMode = .scaleAspectFit
    layer.contentsGravity = .resizeAspect
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func display(pixelBuffer: CVPixelBuffer) {
    guard let image = cgImage(from: pixelBuffer) else { return }
    show(image)
  }

  func display(image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    show(cgImage)
  }

  private func show(_ image: CGImage) {
    DispatchQueue.main.async { [weak self] in
      self?.layer.contents = image
    }
  }

  private func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let stride = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
      CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    )
    guard let context = CGContext(
      data: base,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: stride,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo.rawValue
    ) else {
      return nil
    }
    return context.makeImage()
  }
}

struct PixelPreviewRepresentable: UIViewRepresentable {
  let preview: PixelPreview

  func makeUIView(context: Context) -> PixelPreview {
    preview
  }

  func updateUIView(_ uiView: PixelPreview, context: Context) {}
}
