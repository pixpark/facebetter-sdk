import Foundation

/// How a camera frame is handed to the engine. Gallery stills always use the image API.
enum CameraInput: String, CaseIterable, Identifiable {
  case cvPixelBuffer
  case cpuPixels
  case glTexture

  var id: String { rawValue }

  var titleKey: String {
    switch self {
    case .cvPixelBuffer: return "input.cv.title"
    case .cpuPixels: return "input.cpu.title"
    case .glTexture: return "input.gl.title"
    }
  }

  var shortKey: String {
    switch self {
    case .cvPixelBuffer: return "input.cv.short"
    case .cpuPixels: return "input.cpu.short"
    case .glTexture: return "input.gl.short"
    }
  }

  var detailKey: String {
    switch self {
    case .cvPixelBuffer: return "input.cv.detail"
    case .cpuPixels: return "input.cpu.detail"
    case .glTexture: return "input.gl.detail"
    }
  }

  var statusKey: String {
    switch self {
    case .cvPixelBuffer: return "status.inputCv"
    case .cpuPixels: return "status.inputCpu"
    case .glTexture: return "status.inputGl"
    }
  }
}
