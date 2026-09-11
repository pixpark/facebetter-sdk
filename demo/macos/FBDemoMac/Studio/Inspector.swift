import SwiftUI

struct Inspector: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    VStack(spacing: 0) {
      header
      tabBar
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          switch studio.tab {
          case .skin: SkinPanel(studio: studio)
          case .reshape: ReshapePanel(studio: studio)
          case .makeup: MakeupPanel(studio: studio)
          case .filter: FilterPanel(studio: studio)
          case .sticker: StickerPanel(studio: studio)
          case .background: BackgroundPanel(studio: studio)
          }
        }
        .padding(16)
      }
      footer
    }
    .frame(width: 380)
    .background(StudioColors.panel)
    .overlay(alignment: .leading) {
      Rectangle().fill(StudioColors.border).frame(width: 1)
    }
  }

  private var header: some View {
    HStack {
      HStack(spacing: 8) {
        Circle()
          .fill(Color(hex: 0x34D399))
          .frame(width: 8, height: 8)
        Text(studio.t("console.title"))
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Color(hex: 0xF3F4F6))
      }
      Spacer()
      Text(String(format: "%.0f FPS  %.1f ms", studio.fps, studio.processMs))
        .font(.system(size: 10, design: .monospaced).weight(.medium))
        .foregroundStyle(StudioColors.muted)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: 0x1C1B1D))
        .overlay(Capsule().stroke(Color.white.opacity(0.10)))
        .clipShape(Capsule())
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .overlay(alignment: .bottom) {
      Rectangle().fill(StudioColors.border).frame(height: 1)
    }
  }

  private var tabBar: some View {
    HStack(spacing: 4) {
      ForEach(BeautyTab.allCases) { item in
        Button {
          studio.tab = item
        } label: {
          VStack(spacing: 2) {
            Image(systemName: item.symbol)
              .font(.system(size: 12, weight: .semibold))
            Text(studio.t(item.labelKey))
              .font(.system(size: 10, weight: .medium))
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .foregroundStyle(studio.tab == item ? Color(hex: 0x0A0A0A) : StudioColors.muted)
          .background(
            studio.tab == item ? Color.white : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
          )
        }
        .buttonStyle(.plain)
        .withoutFocusRing()
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(hex: 0x14161C))
    .overlay(alignment: .bottom) {
      Rectangle().fill(StudioColors.border).frame(height: 1)
    }
  }

  private var footer: some View {
    HStack {
      PillButton(title: studio.t("console.reset"), symbol: "arrow.counterclockwise") {
        studio.reset()
      }
      Spacer()
    }
    .padding(12)
    .background(Color(hex: 0x16181F))
    .overlay(alignment: .top) {
      Rectangle().fill(StudioColors.border).frame(height: 1)
    }
  }
}

private struct SkinPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("skin.title"), symbol: "face.smiling") {
      Toggle(isOn: $studio.params.skinOnly) {
        Text(studio.t("skin.skinOnly"))
          .font(.system(size: 10))
          .foregroundStyle(Color(hex: 0xE5E7EB))
      }
      .toggleStyle(.switch)
      .controlSize(.mini)
    } content: {
      HStack {
        Text(studio.t("skin.smoothingStyle"))
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
        Spacer()
        Button(studio.t("skin.reset")) {
          studio.params.smoothing = 0
          studio.params.whitening = 0
          studio.params.rosiness = 0
          studio.params.sharpening = 0
        }
        .buttonStyle(.plain)
        .withoutFocusRing()
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
      }

      ChipGrid(columns: 3, spacing: 6) {
        ForEach(BeautyCatalog.smoothingStyles) { item in
          ChipButton(
            title: studio.t(item.labelKey),
            active: studio.params.smoothingStyle == item.id,
            fillWidth: true
          ) {
            studio.params.smoothingStyle = item.id
          }
        }
      }
      ParamSlider(label: studio.t("skin.smoothing"), value: $studio.params.smoothing)

      Text(studio.t("skin.whiteningTone"))
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
      ChipGrid(columns: 5, spacing: 4) {
        ForEach(BeautyCatalog.whiteningStyles) { item in
          ChipButton(
            title: studio.t(item.labelKey),
            active: studio.params.whiteningStyle == item.id,
            fillWidth: true
          ) {
            studio.params.whiteningStyle = item.id
          }
        }
      }
      ParamSlider(label: studio.t("skin.whitening"), value: $studio.params.whitening)
      ParamSlider(label: studio.t("skin.rosiness"), value: $studio.params.rosiness)
      ParamSlider(label: studio.t("skin.sharpening"), value: $studio.params.sharpening)
    }
  }
}

private struct ReshapePanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    ForEach(BeautyCatalog.reshapeGroups) { group in
      InspectorCard(title: studio.t("reshape.\(group.id)"), symbol: "person.crop.circle") {
        VStack(spacing: 12) {
          ForEach(group.items) { item in
            BipolarSlider(
              label: studio.t(item.labelKey),
              value: Binding(
                get: { studio.params.reshape[item.key] ?? 0 },
                set: { studio.params.reshape[item.key] = $0 }
              )
            )
          }
        }
      }
    }
  }
}

private struct MakeupPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("makeup.title"), symbol: "paintbrush.pointed") {
      Text(studio.t("makeup.fullSet"))
        .font(.system(size: 10))
        .foregroundStyle(Color(hex: 0xD1D5DB))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.05))
        .overlay(Capsule().stroke(Color.white.opacity(0.10)))
        .clipShape(Capsule())
    } content: {
      makeupBlock(
        title: studio.t("makeup.lipstick"),
        intensity: $studio.params.lipstick,
        colors: BeautyCatalog.lipstickColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.lipstickColor.rawValue) },
          set: { studio.params.lipstickColor = FBLipstickColor(rawValue: $0) ?? .rouge }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.blush"),
        intensity: $studio.params.blush,
        styles: BeautyCatalog.blushStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.blushStyle.rawValue) },
          set: { studio.params.blushStyle = FBBlushStyle(rawValue: $0) ?? .soft }
        ),
        colors: BeautyCatalog.blushColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.blushColor.rawValue) },
          set: { studio.params.blushColor = FBBlushColor(rawValue: $0) ?? .coralPink }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.contour"),
        intensity: $studio.params.contour,
        styles: BeautyCatalog.contourStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.contourStyle.rawValue) },
          set: { studio.params.contourStyle = FBContourStyle(rawValue: $0) ?? .natural }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.eyeshadow"),
        intensity: $studio.params.eyeshadow,
        styles: BeautyCatalog.eyeshadowStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.eyeshadowStyle.rawValue) },
          set: { studio.params.eyeshadowStyle = FBEyeShadowStyle(rawValue: $0) ?? .soft }
        ),
        colors: BeautyCatalog.eyeshadowColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.eyeshadowColor.rawValue) },
          set: { studio.params.eyeshadowColor = FBEyeShadowColor(rawValue: $0) ?? .plum }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.eyeliner"),
        intensity: $studio.params.eyeliner,
        styles: BeautyCatalog.eyelinerStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.eyelinerStyle.rawValue) },
          set: { studio.params.eyelinerStyle = FBEyeLinerStyle(rawValue: $0) ?? .classic }
        ),
        colors: BeautyCatalog.eyelinerColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.eyelinerColor.rawValue) },
          set: { studio.params.eyelinerColor = FBEyeLinerColor(rawValue: $0) ?? .coffee }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.eyebrow"),
        intensity: $studio.params.eyebrow,
        styles: BeautyCatalog.eyebrowStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.eyebrowStyle.rawValue) },
          set: { studio.params.eyebrowStyle = FBEyebrowStyle(rawValue: $0) ?? .natural }
        ),
        colors: BeautyCatalog.eyebrowColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.eyebrowColor.rawValue) },
          set: { studio.params.eyebrowColor = FBEyebrowColor(rawValue: $0) ?? .darkBrown }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.eyelash"),
        intensity: $studio.params.eyelash,
        styles: BeautyCatalog.eyelashStyles.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.eyelashStyle.rawValue) },
          set: { studio.params.eyelashStyle = FBEyelashStyle(rawValue: $0) ?? .classic }
        ),
        colors: BeautyCatalog.eyelashColors.map { ($0.id.rawValue, $0.labelKey, $0.color) },
        colorValue: Binding(
          get: { Int(studio.params.eyelashColor.rawValue) },
          set: { studio.params.eyelashColor = FBEyelashColor(rawValue: $0) ?? .black }
        )
      )
      divider
      makeupBlock(
        title: studio.t("makeup.pupil"),
        intensity: $studio.params.pupil,
        styles: BeautyCatalog.pupilColors.map { ($0.id.rawValue, $0.labelKey) },
        styleValue: Binding(
          get: { Int(studio.params.pupilColor.rawValue) },
          set: { studio.params.pupilColor = FBPupilColor(rawValue: $0) ?? .hazel }
        ),
        styleCaption: studio.t("makeup.pupilColor")
      )
    }
  }

  private var divider: some View {
    Rectangle().fill(StudioColors.cardBorder).frame(height: 1)
  }

  @ViewBuilder
  private func makeupBlock(
    title: String,
    intensity: Binding<Float>,
    styles: [(Int, String)] = [],
    styleValue: Binding<Int>? = nil,
    colors: [(Int, String, Color?)] = [],
    colorValue: Binding<Int>? = nil,
    styleCaption: String? = nil
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Color(hex: 0xD1D5DB))

      if !styles.isEmpty, let styleValue {
        Text(styleCaption ?? studio.t("makeup.style"))
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
        ChipGrid(columns: 4, spacing: 6) {
          ForEach(styles, id: \.0) { item in
            ChipButton(
              title: studio.t(item.1),
              active: styleValue.wrappedValue == item.0,
              fillWidth: true
            ) {
              styleValue.wrappedValue = item.0
            }
          }
        }
      }

      if !colors.isEmpty, let colorValue {
        Text(studio.t("makeup.color"))
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
        ChipGrid(columns: 3, spacing: 6) {
          ForEach(colors, id: \.0) { item in
            SwatchButton(
              title: studio.t(item.1),
              color: item.2,
              active: colorValue.wrappedValue == item.0
            ) {
              colorValue.wrappedValue = item.0
            }
          }
        }
      }

      ParamSlider(label: studio.t("makeup.intensity"), value: intensity)
    }
  }
}

private struct FilterPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("filter.title"), symbol: "camera.filters") {
      Text("\(studio.t("filter.intensityValue")) \(Int((studio.params.filterIntensity * 100).rounded()))%")
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
    } content: {
      ChipGrid(columns: 3, spacing: 8) {
        ChipButton(title: studio.t("filter.none"), active: studio.params.filterID == nil, fillWidth: true) {
          studio.params.filterID = nil
        }
        ForEach(BeautyCatalog.filterIDs, id: \.self) { id in
          ChipButton(title: studio.filterLabel(id), active: studio.params.filterID == id, fillWidth: true) {
            studio.params.filterID = id
          }
        }
      }
      ParamSlider(label: studio.t("filter.intensity"), value: $studio.params.filterIntensity)
        .disabled(studio.params.filterID == nil)
        .opacity(studio.params.filterID == nil ? 0.4 : 1)
    }
  }
}

private struct StickerPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("sticker.title"), symbol: "sparkles") {
      ChipGrid(columns: 3, spacing: 6) {
        ChipButton(title: studio.t("sticker.none"), active: studio.params.stickerID == nil, fillWidth: true) {
          studio.params.stickerID = nil
        }
        ForEach(BeautyCatalog.stickerIDs, id: \.self) { id in
          ChipButton(
            title: studio.t("sticker.\(id)"),
            active: studio.params.stickerID == id,
            fillWidth: true
          ) {
            studio.params.stickerID = id
          }
        }
      }
    }
  }
}

private struct BackgroundPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("bg.title"), symbol: "person.crop.rectangle") {
      Text(studio.t("bg.effect"))
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
      ChipGrid(columns: 3, spacing: 6) {
        ForEach(BackgroundFill.allCases) { fill in
          ChipButton(
            title: studio.t(fill.labelKey),
            active: studio.params.backgroundFill == fill,
            fillWidth: true
          ) {
            studio.params.backgroundFill = fill
          }
        }
      }
      if studio.params.backgroundFill == .blur {
        ParamSlider(label: studio.t("bg.blurAmount"), value: $studio.params.bgBlur)
      }

      Text(studio.t("bg.cutout"))
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
        .padding(.top, 4)
      ChipGrid(columns: 4, spacing: 6) {
        ChipButton(title: studio.t("bg.portrait"), active: studio.params.chroma == nil, fillWidth: true) {
          studio.params.chroma = nil
        }
        ForEach(BeautyCatalog.chromaOptions) { option in
          ChipButton(
            title: studio.t(option.labelKey),
            active: studio.params.chroma == option.id,
            color: option.color,
            fillWidth: true
          ) {
            studio.params.chroma = option.id
          }
        }
      }
      if studio.params.chroma != nil {
        ParamSlider(label: studio.t("bg.similarity"), value: $studio.params.chromaSimilarity)
        ParamSlider(label: studio.t("bg.smoothness"), value: $studio.params.chromaSmoothness)
        ParamSlider(label: studio.t("bg.desaturation"), value: $studio.params.chromaDesaturation)
      }
    }
  }
}
