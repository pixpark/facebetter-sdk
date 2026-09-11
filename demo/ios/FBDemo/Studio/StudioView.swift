import PhotosUI
import SwiftUI

struct StudioView: View {
  @EnvironmentObject private var studio: StudioModel
  @State private var pickerItem: PhotosPickerItem?
  @State private var showTextureDemo = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      PreviewView(preview: studio.preview)
        .ignoresSafeArea()
        .gesture(previewGesture)

      if studio.showLandmarks && !studio.isComparing {
        LandmarkOverlay(faces: studio.faces, imageSize: studio.frameSize)
          .ignoresSafeArea()
          .allowsHitTesting(false)
      }

      LinearGradient(
        colors: [.black.opacity(0.55), .clear, .black.opacity(0.72)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)

      VStack(spacing: 0) {
        topBar
        fpsBadge
        Spacer()
          .allowsHitTesting(false)
        if !studio.statusKey.isEmpty {
          statusChip
            .padding(.bottom, 8)
        }
        if !studio.isComparing {
          HStack(spacing: 8) {
            hintChip(studio.t("preview.hold"))
            if studio.panelExpanded {
              hintChip(studio.t("preview.collapseHint"))
            }
          }
          .padding(.bottom, 8)
          .allowsHitTesting(false)
        }
        BeautyPanel(studio: studio)
      }
    }
    .onChange(of: pickerItem) { item in
      guard let item else { return }
      Task {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
          await MainActor.run {
            studio.loadImage(image)
          }
        }
      }
    }
    .fullScreenCover(isPresented: $showTextureDemo) {
      TextureStudioView(locale: studio.locale) {
        studio.resumeAfterExternalTexture()
      }
      .preferredColorScheme(.dark)
      .statusBarHidden(true)
    }
  }

  private var previewGesture: some Gesture {
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

  private func hintChip(_ text: String) -> some View {
    Text(text)
      .font(.caption2)
      .foregroundStyle(.white.opacity(0.55))
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(.black.opacity(0.35), in: Capsule())
  }

  private var topBar: some View {
    HStack(spacing: 6) {
      PhotosPicker(selection: $pickerItem, matching: .images) {
        TopIcon(symbol: "photo", title: studio.t("nav.gallery"))
      }

      if studio.source == .image {
        Button {
          studio.startCamera()
        } label: {
          TopIcon(symbol: "camera", title: studio.t("nav.camera"), active: true)
        }
      } else {
        Button {
          studio.flipCamera()
        } label: {
          TopIcon(symbol: "camera.rotate", title: studio.t("nav.flip"))
        }
      }

      Button {
        studio.reset()
      } label: {
        TopIcon(symbol: "arrow.counterclockwise", title: studio.t("nav.reset"))
      }

      Button {
        studio.capture()
      } label: {
        TopIcon(symbol: "square.and.arrow.up", title: studio.t("nav.export"))
      }

      Button {
        studio.showLandmarks.toggle()
      } label: {
        TopIcon(
          symbol: "dot.viewfinder",
          title: studio.t("nav.landmarks"),
          active: studio.showLandmarks
        )
      }

      Button {
        studio.suspendForExternalTexture()
        showTextureDemo = true
      } label: {
        TopIcon(symbol: "square.stack.3d.up", title: studio.t("nav.texture"))
      }

      Menu {
        ForEach(AppLocale.allCases) { item in
          Button {
            studio.setLocale(item)
          } label: {
            if studio.locale == item {
              Label(item.shortLabel, systemImage: "checkmark")
            } else {
              Text(item.shortLabel)
            }
          }
        }
      } label: {
        TopIcon(symbol: "globe", title: studio.locale.shortLabel, active: true)
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 8)
  }

  @ViewBuilder
  private var fpsBadge: some View {
    if studio.source == .camera && studio.fps > 0 {
      HStack {
        Spacer()
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 5) {
            Circle()
              .fill(studio.fps > 25 ? Color.green : Color.orange)
              .frame(width: 6, height: 6)
            Text(String(format: "%.0f FPS", studio.fps))
              .font(.caption2.monospacedDigit())
              .foregroundStyle(.white.opacity(0.7))
          }
          if studio.processMs > 0 {
            HStack(spacing: 5) {
              Circle()
                .fill(latencyColor(studio.processMs))
                .frame(width: 6, height: 6)
              Text(String(format: "%.0f ms", studio.processMs))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
            }
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 6)
    }
  }

  private func latencyColor(_ ms: Double) -> Color {
    if ms > 60 { return .red }
    if ms < 30 { return .green }
    return .orange
  }

  private var statusChip: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(studio.isComparing ? Color.gray : Color.green)
        .frame(width: 6, height: 6)
      Text(studio.isComparing ? studio.t("preview.original") : studio.t(studio.statusKey))
        .font(.caption)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(.black.opacity(0.55), in: Capsule())
    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
  }
}

struct TopIcon: View {
  let symbol: String
  let title: String
  var active = false

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: symbol)
        .font(.system(size: 15, weight: .semibold))
      Text(title)
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .foregroundStyle(active ? .black : .white)
    .frame(maxWidth: .infinity)
    .frame(height: 46)
    .background(
      active ? Color.white : Color.white.opacity(0.10),
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }
}

private struct LandmarkOverlay: View {
  let faces: [FBFaceDetectionResult]
  let imageSize: CGSize

  var body: some View {
    GeometryReader { proxy in
      Canvas { context, size in
        let content = aspectFitRect(imageSize: imageSize, in: size)
        guard content.width > 0, content.height > 0 else { return }
        for face in faces {
          let rect = face.rect
          let box = CGRect(
            x: content.minX + CGFloat(rect.x) * content.width,
            y: content.minY + CGFloat(rect.y) * content.height,
            width: CGFloat(rect.width) * content.width,
            height: CGFloat(rect.height) * content.height
          )
          context.stroke(Path(box), with: .color(.white.opacity(0.7)), lineWidth: 1)

          guard let points = face.keyPoints else { continue }
          let visibility = face.visibility ?? []
          for (index, point) in points.enumerated() {
            if index < visibility.count, visibility[index].floatValue < 0.4 {
              continue
            }
            let center = CGPoint(
              x: content.minX + CGFloat(point.x) * content.width,
              y: content.minY + CGFloat(point.y) * content.height
            )
            let dot = Path(
              ellipseIn: CGRect(x: center.x - 1.2, y: center.y - 1.2, width: 2.4, height: 2.4)
            )
            context.fill(dot, with: .color(.white))
          }
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
    }
  }
}

private func aspectFitRect(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
  guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
    return .zero
  }
  let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
  let width = imageSize.width * scale
  let height = imageSize.height * scale
  return CGRect(
    x: (viewSize.width - width) / 2,
    y: (viewSize.height - height) / 2,
    width: width,
    height: height
  )
}
