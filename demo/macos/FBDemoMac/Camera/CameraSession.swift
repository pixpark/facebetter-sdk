import AVFoundation
import CoreVideo
import Foundation

final class CameraSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  var onFrame: ((CVPixelBuffer) -> Void)?
  var onError: ((String) -> Void)?

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "net.pixpark.fbdemomac.camera.session")
  private let outputQueue = DispatchQueue(label: "net.pixpark.fbdemomac.camera.output")
  private let videoOutput = AVCaptureVideoDataOutput()
  private var videoInput: AVCaptureDeviceInput?
  private var configured = false
  private var wantsRunning = false

  private(set) var isRunning = false

  func start() {
    wantsRunning = true
    requestPermission { [weak self] granted in
      guard let self else { return }
      guard granted else {
        self.onError?("status.permissionCamera")
        return
      }
      self.startRunningIfNeeded()
    }
  }

  func stop() {
    wantsRunning = false
    sessionQueue.sync {
      if self.session.isRunning {
        self.session.stopRunning()
      }
      self.isRunning = false
    }
  }

  private func startRunningIfNeeded() {
    sessionQueue.async { [weak self] in
      guard let self, self.wantsRunning else { return }
      do {
        if !self.configured {
          try self.configure()
        }
        if !self.session.isRunning {
          self.session.startRunning()
        }
        self.isRunning = self.session.isRunning
      } catch {
        self.isRunning = false
        self.onError?("status.permissionCamera")
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
    if session.canSetSessionPreset(.hd1280x720) {
      session.sessionPreset = .hd1280x720
    }

    let device = AVCaptureDevice.default(for: .video)
    guard let device else { throw CameraError.unavailable }
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else { throw CameraError.cannotAddInput }
    session.addInput(input)
    videoInput = input

    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
    guard session.canAddOutput(videoOutput) else {
      throw CameraError.cannotAddOutput
    }
    session.addOutput(videoOutput)
    configured = true
  }
}

private enum CameraError: Error {
  case unavailable
  case cannotAddInput
  case cannotAddOutput
}
