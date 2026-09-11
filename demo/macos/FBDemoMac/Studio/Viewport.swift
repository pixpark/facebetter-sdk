import SwiftUI

struct Viewport: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    ZStack {
      StudioColors.stage
      DotGrid()
        .opacity(0.15)
        .allowsHitTesting(false)

      GeometryReader { proxy in
        let fitted = aspectFit(imageSize: studio.frameSize, in: proxy.size)
        ZStack {
          PreviewView(preview: studio.preview)
            .frame(width: fitted.width, height: fitted.height)
            .background(Color(hex: 0x14161C))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color(hex: 0x232731), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
            .gesture(compareGesture)
            .overlay {
              if studio.params.faceOverlay && !studio.isComparing {
                LandmarkOverlay(faces: studio.faces, imageSize: studio.frameSize)
                  .allowsHitTesting(false)
              }
            }
            .overlay(alignment: .topLeading) {
              if studio.isComparing {
                HStack(spacing: 6) {
                  Circle().fill(StudioColors.muted).frame(width: 6, height: 6)
                  Text(studio.t("preview.original"))
                    .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color(hex: 0xE5E7EB))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: 0x0E1014).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.10)))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(12)
              }
            }
            .overlay(alignment: .topTrailing) {
              Button {
                studio.params.faceOverlay.toggle()
              } label: {
                HStack(spacing: 6) {
                  Image(systemName: "face.dashed")
                  Text(studio.t("preview.keypoints"))
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(studio.params.faceOverlay ? Color(hex: 0x0A0A0A) : Color(hex: 0xD1D5DB))
                .background(studio.params.faceOverlay ? Color.white : Color(hex: 0x0E1014).opacity(0.80))
                .overlay(
                  Capsule().stroke(
                    studio.params.faceOverlay ? Color.white : Color.white.opacity(0.10),
                    lineWidth: 1
                  )
                )
                .clipShape(Capsule())
              }
              .buttonStyle(.plain)
              .withoutFocusRing()
              .padding(12)
            }
            .overlay(alignment: .bottom) {
              HStack(spacing: 6) {
                Image(systemName: "hand.tap")
                Text(studio.isComparing ? studio.t("preview.release") : studio.t("preview.hold"))
              }
              .font(.system(size: 11))
              .foregroundStyle(Color(hex: 0xD1D5DB))
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Color(hex: 0x0E1014).opacity(0.80))
              .overlay(Capsule().stroke(Color.white.opacity(0.10)))
              .clipShape(Capsule())
              .padding(.bottom, 12)
              .allowsHitTesting(false)
            }
            .opacity(studio.frameSize == .zero ? 0 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .padding(.horizontal, 48)
      .padding(.vertical, 32)

      VStack {
        Spacer()
        Text("© 2021–\(Calendar.current.component(.year, from: Date())) PIXPARK LTD")
          .font(.system(size: 9))
          .foregroundStyle(Color.white.opacity(0.25))
          .padding(.bottom, 10)
      }
      .allowsHitTesting(false)
    }
  }

  private var compareGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { _ in
        if !studio.isComparing {
          studio.isComparing = true
        }
      }
      .onEnded { _ in
        studio.isComparing = false
      }
  }
}

private struct DotGrid: View {
  var body: some View {
    Canvas { context, size in
      let step: CGFloat = 16
      var x: CGFloat = 0
      while x < size.width {
        var y: CGFloat = 0
        while y < size.height {
          let rect = CGRect(x: x, y: y, width: 1, height: 1)
          context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0x272A33)))
          y += step
        }
        x += step
      }
    }
  }
}

private struct LandmarkOverlay: View {
  let faces: [FBFaceDetectionResult]
  let imageSize: CGSize

  var body: some View {
    Canvas { context, size in
      guard imageSize.width > 0, imageSize.height > 0 else { return }
      for face in faces {
        let rect = face.rect
        let box = CGRect(
          x: CGFloat(rect.x) * size.width,
          y: CGFloat(rect.y) * size.height,
          width: CGFloat(rect.width) * size.width,
          height: CGFloat(rect.height) * size.height
        )
        context.stroke(Path(box), with: .color(.white.opacity(0.55)), lineWidth: 1)

        guard let points = face.keyPoints else { continue }
        let visibility = face.visibility ?? []
        for (index, point) in points.enumerated() {
          if index < visibility.count, visibility[index].floatValue < 0.4 {
            continue
          }
          let center = CGPoint(
            x: CGFloat(point.x) * size.width,
            y: CGFloat(point.y) * size.height
          )
          let dot = Path(ellipseIn: CGRect(x: center.x - 1.2, y: center.y - 1.2, width: 2.4, height: 2.4))
          context.fill(dot, with: .color(.white))
        }
      }
    }
  }
}

private func aspectFit(imageSize: CGSize, in viewSize: CGSize) -> CGSize {
  guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
    return .zero
  }
  let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
  return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
}
