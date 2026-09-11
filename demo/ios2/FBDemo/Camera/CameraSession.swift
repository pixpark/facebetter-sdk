import AVFoundation
import CoreVideo
import UIKit

final class CameraSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  var onFrame: ((CVPixelBuffer) -> Void)?
  var onError: ((String) -> Void)?

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "net.pixpark.fbstudio.camera.session")
  private let outputQueue = DispatchQueue(label: "net.pixpark.fbstudio.camera.output")
  private let videoOutput = AVCaptureVideoDataOutput()
  private var videoInput: AVCaptureDeviceInput?
  private var configured = false

  private(set) var position: AVCaptureDevice.Position = .front
  private(set) var isRunning = false

  func start() {
    requestPermission { [weak self] granted in
      guard let self else { return }
      guard granted else {
        self.onError?("status.permissionCamera")
        return
      }
      self.sessionQueue.async {
        do {
          if !self.configured {
            try self.configure()
          }
          if !self.session.isRunning {
            self.session.startRunning()
          }
          self.isRunning = true
        } catch {
          self.onError?("status.permissionCamera")
        }
      }
    }
  }

  func stop() {
    sessionQueue.async {
      if self.session.isRunning {
        self.session.stopRunning()
      }
      self.isRunning = false
    }
  }

  func flip() {
    sessionQueue.async {
      let next: AVCaptureDevice.Position = self.position == .front ? .back : .front
      do {
        try self.replaceInput(position: next)
        self.position = next
      } catch {
        self.onError?("status.captureFailed")
      }
    }
  }

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    onFrame?(pixelBuffer)
  }

  private func requestPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      completion(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    default:
      completion(false)
    }
  }

  private func configure() throws {
    session.beginConfiguration()
    defer { session.commitConfiguration() }
    session.sessionPreset = .hd1280x720
    try replaceInput(position: position)

    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
    guard session.canAddOutput(videoOutput) else {
      throw CameraError.cannotAddOutput
    }
    session.addOutput(videoOutput)
    configureConnection()
    configured = true
  }

  private func replaceInput(position: AVCaptureDevice.Position) throws {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
      throw CameraError.unavailable
    }
    let input = try AVCaptureDeviceInput(device: device)
    if let videoInput {
      session.removeInput(videoInput)
    }
    guard session.canAddInput(input) else {
      throw CameraError.cannotAddInput
    }
    session.addInput(input)
    videoInput = input
    configureConnection()
  }

  private func configureConnection() {
    guard let connection = videoOutput.connection(with: .video) else { return }
    if connection.isVideoOrientationSupported {
      connection.videoOrientation = .portrait
    }
    if connection.isVideoMirroringSupported {
      connection.automaticallyAdjustsVideoMirroring = false
      connection.isVideoMirrored = videoInput?.device.position == .front
    }
  }
}

private enum CameraError: Error {
  case unavailable
  case cannotAddInput
  case cannotAddOutput
}
