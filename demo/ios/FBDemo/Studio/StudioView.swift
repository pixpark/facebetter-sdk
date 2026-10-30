import PhotosUI
import SwiftUI

struct StudioView: View {
  @EnvironmentObject private var studio: StudioModel
  @State private var pickerItem: PhotosPickerItem?
  @State private var showInputSheet = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      preview
        .ignoresSafeArea()
        .allowsHitTesting(false)

      // The watermark sits around 82%–88% of the frame. A gradient across the lower half would gray out the white mark.
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.55), location: 0),
          .init(color: .clear, location: 0.18),
          .init(color: .clear, location: 0.90),
          .init(color: .black.opacity(0.55), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)

      VStack(spacing: 0) {
        topBar
        if studio.source == .camera && studio.fps > 0 {
          statusRow
        }
        ZStack(alignment: .top) {
          Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(previewGesture)
          if !studio.isComparing {
            holdHint
              .padding(.top, 10)
              .allowsHitTesting(false)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        if !studio.statusKey.isEmpty {
          statusChip
            .padding(.bottom, 8)
        }
        BeautyPanel(studio: studio)
          .contentShape(Rectangle())
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
    .sheet(isPresented: $showInputSheet) {
      InputModeSheet()
        .environmentObject(studio)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
  }

  @ViewBuilder
  private var preview: some View {
    if studio.showsGlPreview {
      GlTexturePreviewRepresentable(preview: studio.glPreview)
    } else if studio.showsCvPreview {
      CvPixelBufferPreviewRepresentable(preview: studio.cvPreview)
    } else {
      PixelPreviewRepresentable(preview: studio.pixelPreview)
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
        studio.capture()
      } label: {
        TopIcon(symbol: "square.and.arrow.up", title: studio.t("nav.export"))
      }

      Button {
        showInputSheet = true
      } label: {
        TopIcon(
          symbol: "square.stack.3d.up",
          title: studio.t(studio.cameraInput.shortKey),
          active: true
        )
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

  private var statusRow: some View {
    HStack(spacing: 8) {
      Spacer(minLength: 0)
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

  private func latencyColor(_ ms: Double) -> Color {
    if ms > 60 { return .red }
    if ms < 30 { return .green }
    return .orange
  }

  private var holdHint: some View {
    Text(studio.t("preview.hold"))
      .font(.caption2)
      .foregroundStyle(.white.opacity(0.55))
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(.black.opacity(0.35), in: Capsule())
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

private struct InputModeSheet: View {
  @EnvironmentObject private var studio: StudioModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(studio.t("input.title"))
        .font(.headline)
        .foregroundStyle(.white)
      Text(studio.t("input.subtitle"))
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.65))
        .fixedSize(horizontal: false, vertical: true)

      ForEach(CameraInput.allCases) { mode in
        Button {
          studio.setCameraInput(mode)
          dismiss()
        } label: {
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: studio.cameraInput == mode ? "largecircle.fill.circle" : "circle")
              .font(.body)
              .foregroundStyle(studio.cameraInput == mode ? .white : .white.opacity(0.45))
              .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
              Text(studio.t(mode.titleKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
              Text(studio.t(mode.detailKey))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
          }
          .padding(12)
          .background(.white.opacity(studio.cameraInput == mode ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
      }
      Spacer(minLength: 0)
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color.black.ignoresSafeArea())
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
