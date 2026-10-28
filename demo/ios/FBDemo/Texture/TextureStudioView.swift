import SwiftUI

struct TextureStudioView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: TextureStudioModel
  let onStopped: () -> Void

  init(locale: AppLocale, onStopped: @escaping () -> Void) {
    _model = StateObject(wrappedValue: TextureStudioModel(locale: locale))
    self.onStopped = onStopped
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      TexturePreviewRepresentable(preview: model.preview)
        .ignoresSafeArea()
        .gesture(previewGesture)

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
        hud
        if !model.isComparing {
          holdHint
            .padding(.top, 10)
        }
        Spacer()
          .allowsHitTesting(false)
        if !model.statusKey.isEmpty {
          statusChip
            .padding(.bottom, 8)
        }
        BeautyPanel(studio: model)
      }
    }
    .onAppear { model.start() }
    .onDisappear {
      model.stop()
      onStopped()
    }
  }

  private var previewGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { _ in
        if !model.isComparing {
          model.isComparing = true
        }
      }
      .onEnded { _ in
        model.isComparing = false
      }
  }

  private var topBar: some View {
    HStack(spacing: 6) {
      Button {
        model.stop()
        dismiss()
      } label: {
        TopIcon(symbol: "chevron.backward", title: model.t("nav.close"))
      }
      Button {
        model.flipCamera()
      } label: {
        TopIcon(symbol: "camera.rotate", title: model.t("nav.flip"))
      }
      Button {
        model.reset()
      } label: {
        TopIcon(symbol: "arrow.counterclockwise", title: model.t("nav.reset"))
      }
      Button {
        model.capture()
      } label: {
        TopIcon(symbol: "square.and.arrow.up", title: model.t("nav.export"))
      }
      Menu {
        ForEach(AppLocale.allCases) { item in
          Button {
            model.setLocale(item)
          } label: {
            if model.locale == item {
              Label(item.shortLabel, systemImage: "checkmark")
            } else {
              Text(item.shortLabel)
            }
          }
        }
      } label: {
        TopIcon(symbol: "globe", title: model.locale.shortLabel, active: true)
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 8)
  }

  private var hud: some View {
    HStack(spacing: 8) {
      Text(model.t("texture.title"))
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.9))
      Button {
        model.toggleApplyThread()
      } label: {
        Text(model.t(model.applyOnUIThread ? "texture.applyUI" : "texture.applyGL"))
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.white.opacity(0.85))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(.white.opacity(0.12), in: Capsule())
      }
      .buttonStyle(.plain)
      Spacer(minLength: 0)
      if model.fps > 0 {
        Text(String(format: "%.0f FPS", model.fps))
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.white.opacity(0.7))
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 6)
  }

  private var holdHint: some View {
    Text(model.t("preview.hold"))
      .font(.caption2)
      .foregroundStyle(.white.opacity(0.55))
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(.black.opacity(0.35), in: Capsule())
  }

  private var statusChip: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(model.isComparing ? Color.gray : Color.green)
        .frame(width: 6, height: 6)
      Text(model.isComparing ? model.t("preview.original") : model.t(model.statusKey))
        .font(.caption)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(.black.opacity(0.55), in: Capsule())
    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
  }
}
