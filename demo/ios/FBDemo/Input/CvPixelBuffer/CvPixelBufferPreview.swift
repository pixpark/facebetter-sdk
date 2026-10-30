import AVFoundation
import CoreMedia
import CoreVideo
import SwiftUI
import UIKit

/// Displays a CVPixelBuffer without copying it into a CGImage.
///
/// Video output is still being written when processImage returns. This view keeps
/// the camera buffer alive for the engine's triple-buffer, and shows the previous
/// result. Locking that previous buffer waits out any leftover GPU work, then the
/// display layer samples the IOSurface. Stills are already complete and can be shown
/// through the pixel preview instead.
final class CvPixelBufferPreview: UIView {
  private let displayLayer = AVSampleBufferDisplayLayer()
  private var pending: CVPixelBuffer?
  private var onScreen: CVPixelBuffer?
  private var cameraBuffers: [CVPixelBuffer] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    isOpaque = true
    displayLayer.videoGravity = .resizeAspect
    displayLayer.backgroundColor = UIColor.black.cgColor
    layer.addSublayer(displayLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    displayLayer.frame = bounds
  }

  func present(camera: CVPixelBuffer, processed: CVPixelBuffer) {
    remember(camera)
    let ready = pending
    pending = processed
    if let ready {
      if CVPixelBufferLockBaseAddress(ready, .readOnly) == kCVReturnSuccess {
        CVPixelBufferUnlockBaseAddress(ready, .readOnly)
      }
      show(ready)
    } else {
      show(camera)
    }
  }

  func show(_ pixelBuffer: CVPixelBuffer) {
    onScreen = pixelBuffer
    DispatchQueue.main.async { [weak self] in
      self?.enqueue(pixelBuffer)
    }
  }

  func reset() {
    pending = nil
    onScreen = nil
    cameraBuffers.removeAll()
    DispatchQueue.main.async { [weak self] in
      self?.displayLayer.flushAndRemoveImage()
    }
  }

  private func remember(_ pixelBuffer: CVPixelBuffer) {
    cameraBuffers.append(pixelBuffer)
    if cameraBuffers.count > 3 {
      cameraBuffers.removeFirst()
    }
  }

  private func enqueue(_ pixelBuffer: CVPixelBuffer) {
    if displayLayer.status == .failed {
      displayLayer.flush()
    }
    var format: CMVideoFormatDescription?
    let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescriptionOut: &format
    )
    guard formatStatus == noErr, let format else { return }

    var timing = CMSampleTimingInfo(
      duration: .invalid,
      presentationTimeStamp: .zero,
      decodeTimeStamp: .invalid
    )
    var sample: CMSampleBuffer?
    let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescription: format,
      sampleTiming: &timing,
      sampleBufferOut: &sample
    )
    guard sampleStatus == noErr, let sample else { return }
    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) as? [NSMutableDictionary],
       let first = attachments.first {
      first[kCMSampleAttachmentKey_DisplayImmediately] = true
    }
    displayLayer.enqueue(sample)
  }
}

struct CvPixelBufferPreviewRepresentable: UIViewRepresentable {
  let preview: CvPixelBufferPreview

  func makeUIView(context: Context) -> CvPixelBufferPreview {
    preview
  }

  func updateUIView(_ uiView: CvPixelBufferPreview, context: Context) {}
}
