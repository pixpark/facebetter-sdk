import CoreImage
import MetalKit
import SwiftUI

final class PreviewMTKView: MTKView {
  private let commandQueue: MTLCommandQueue
  private let ciContext: CIContext
  private let frameLock = NSLock()
  private var currentPixelBuffer: CVPixelBuffer?
  private var currentImage: CIImage?
  private let colorSpace = CGColorSpaceCreateDeviceRGB()

  override init(frame: CGRect, device: MTLDevice?) {
    let resolved = device ?? MTLCreateSystemDefaultDevice()
    guard let resolved, let commandQueue = resolved.makeCommandQueue() else {
      fatalError("Facebetter requires Metal")
    }
    self.commandQueue = commandQueue
    self.ciContext = CIContext(mtlDevice: resolved)
    super.init(frame: frame, device: resolved)
    framebufferOnly = false
    colorPixelFormat = .bgra8Unorm
    isPaused = true
    enableSetNeedsDisplay = true
    contentMode = .scaleAspectFit
    backgroundColor = .black
    isOpaque = true
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func display(pixelBuffer: CVPixelBuffer) {
    frameLock.lock()
    currentPixelBuffer = pixelBuffer
    currentImage = nil
    frameLock.unlock()
    DispatchQueue.main.async { [weak self] in
      self?.setNeedsDisplay()
    }
  }

  func display(image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    frameLock.lock()
    currentPixelBuffer = nil
    currentImage = CIImage(cgImage: cgImage)
    frameLock.unlock()
    DispatchQueue.main.async { [weak self] in
      self?.setNeedsDisplay()
    }
  }

  func recoverAfterCover() {
    setNeedsLayout()
    layoutIfNeeded()
    if let metal = layer as? CAMetalLayer {
      let scale = window?.screen.scale ?? contentScaleFactor
      let pixels = CGSize(width: bounds.width * scale, height: bounds.height * scale)
      if pixels.width > 1, pixels.height > 1 {
        metal.drawableSize = pixels
      }
    }
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    autoreleasepool {
      frameLock.lock()
      let pixelBuffer = currentPixelBuffer
      let still = currentImage
      frameLock.unlock()

      let source: CIImage?
      if let pixelBuffer {
        source = CIImage(cvPixelBuffer: pixelBuffer)
      } else {
        source = still
      }

      guard let source,
            let drawable = currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer() else {
        return
      }

      let targetSize = CGSize(width: drawableSize.width, height: drawableSize.height)
      let scale = min(
        targetSize.width / source.extent.width,
        targetSize.height / source.extent.height
      )
      let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
      let translated = scaled.transformed(by: CGAffineTransform(
        translationX: (targetSize.width - scaled.extent.width) / 2 - scaled.extent.minX,
        y: (targetSize.height - scaled.extent.height) / 2 - scaled.extent.minY
      ))
      let targetBounds = CGRect(origin: .zero, size: targetSize)
      let background = CIImage(color: .black).cropped(to: targetBounds)
      let fitted = translated.composited(over: background)

      ciContext.render(
        fitted,
        to: drawable.texture,
        commandBuffer: commandBuffer,
        bounds: targetBounds,
        colorSpace: colorSpace
      )
      commandBuffer.present(drawable)
      commandBuffer.commit()
    }
  }
}

struct PreviewView: UIViewRepresentable {
  let preview: PreviewMTKView

  func makeUIView(context: Context) -> PreviewMTKView {
    preview
  }

  func updateUIView(_ uiView: PreviewMTKView, context: Context) {}
}
