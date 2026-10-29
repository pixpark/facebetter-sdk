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
          case .body: BodyPanel(studio: studio)
          case .makeup: MakeupPanel(studio: studio)
          case .filter: FilterPanel(studio: studio)
          case .sticker: StickerPanel(studio: studio)
          case .background: BackgroundPanel(studio: studio)
          }
        }
        .padding(16)
      }
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

}

private struct SectionHead: View {
  let title: String
  var rule = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if rule {
        Rectangle().fill(StudioColors.cardBorder).frame(height: 1)
      }
      Text(title)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Color(hex: 0xE5E7EB))
    }
  }
}

private struct CardReset: View {
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(StudioColors.muted)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .withoutFocusRing()
    .help(label)
  }
}

private struct SkinPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("skin.title"), symbol: "camera.macro") {
      CardReset(label: studio.t("console.reset")) {
        let fresh = BeautyParams()
        studio.params.smoothing = fresh.smoothing
        studio.params.smoothingStyle = fresh.smoothingStyle
        studio.params.whitening = fresh.whitening
        studio.params.whiteningStyle = fresh.whiteningStyle
        studio.params.rosiness = fresh.rosiness
        studio.params.blemish = fresh.blemish
        studio.params.clarity = fresh.clarity
        studio.params.skinOnly = fresh.skinOnly
      }
    } content: {
      Toggle(isOn: $studio.params.skinOnly) {
        Text(studio.t("skin.skinOnly"))
          .font(.system(size: 10))
          .foregroundStyle(Color(hex: 0xE5E7EB))
      }
      .toggleStyle(.switch)
      .controlSize(.mini)

      SectionHead(title: studio.t("skin.group.smooth"), rule: true)
      Text(studio.t("skin.smoothingStyle"))
        .font(.system(size: 10))
        .foregroundStyle(StudioColors.muted)
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
      ParamSlider(label: studio.t("skin.blemish"), value: $studio.params.blemish)

      SectionHead(title: studio.t("skin.group.tone"), rule: true)
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

      SectionHead(title: studio.t("skin.group.clarity"), rule: true)
      ParamSlider(label: studio.t("skin.clarity"), value: $studio.params.clarity)
    }
  }
}

private struct ReshapePanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("tab.reshape"), symbol: "face.smiling") {
      CardReset(label: studio.t("console.reset")) {
        studio.params.reshape = BeautyParams.emptyReshape()
      }
    } content: {
      ForEach(Array(BeautyCatalog.reshapeGroups.enumerated()), id: \.element.id) { index, group in
        SectionHead(title: studio.t("reshape.\(group.id)"), rule: index > 0)
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

private struct BodyPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("tab.body"), symbol: "figure.stand") {
      CardReset(label: studio.t("console.reset")) {
        studio.params.bodyReshape = BeautyParams.emptyBodyReshape()
      }
    } content: {
      ForEach(Array(BeautyCatalog.bodyGroups.enumerated()), id: \.element.id) { index, group in
        SectionHead(title: studio.t("reshape.\(group.id)"), rule: index > 0)
        ForEach(group.items) { item in
          ParamSlider(
            label: studio.t(item.labelKey),
            value: Binding(
              get: { studio.params.bodyReshape[item.key] ?? 0 },
              set: { studio.params.bodyReshape[item.key] = $0 }
            )
          )
        }
      }
    }
  }
}

private struct MakeupPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("makeup.title"), symbol: "paintbrush.pointed") {
      HStack(spacing: 8) {
        Text(studio.t("makeup.fullSet"))
          .font(.system(size: 10))
          .foregroundStyle(Color(hex: 0xD1D5DB))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color.white.opacity(0.05))
          .overlay(Capsule().stroke(Color.white.opacity(0.10)))
          .clipShape(Capsule())
        CardReset(label: studio.t("console.reset")) {
          let fresh = BeautyParams()
          studio.params.lipstick = fresh.lipstick
          studio.params.lipstickColor = fresh.lipstickColor
          studio.params.blush = fresh.blush
          studio.params.blushStyle = fresh.blushStyle
          studio.params.blushColor = fresh.blushColor
          studio.params.teethWhiten = fresh.teethWhiten
          studio.params.contour = fresh.contour
          studio.params.contourStyle = fresh.contourStyle
          studio.params.eyeshadow = fresh.eyeshadow
          studio.params.eyeshadowStyle = fresh.eyeshadowStyle
          studio.params.eyeshadowColor = fresh.eyeshadowColor
          studio.params.eyeliner = fresh.eyeliner
          studio.params.eyelinerStyle = fresh.eyelinerStyle
          studio.params.eyelinerColor = fresh.eyelinerColor
          studio.params.eyebrow = fresh.eyebrow
          studio.params.eyebrowStyle = fresh.eyebrowStyle
          studio.params.eyebrowColor = fresh.eyebrowColor
          studio.params.eyelash = fresh.eyelash
          studio.params.eyelashStyle = fresh.eyelashStyle
          studio.params.eyelashColor = fresh.eyelashColor
          studio.params.pupil = fresh.pupil
          studio.params.pupilColor = fresh.pupilColor
        }
      }
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
        title: studio.t("makeup.teeth"),
        intensity: $studio.params.teethWhiten,
        styles: [(0, "makeup.teethWhiten")],
        styleValue: .constant(0),
        styleCaption: ""
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
        ),
        colorColumns: 4
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
        ),
        colorColumns: 4
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
        ),
        colorColumns: 4
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
    styleCaption: String? = nil,
    colorColumns: Int = 3
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Color(hex: 0xD1D5DB))

      if !styles.isEmpty, let styleValue {
        let caption = styleCaption ?? studio.t("makeup.style")
        if !caption.isEmpty {
          Text(caption)
            .font(.system(size: 10))
            .foregroundStyle(StudioColors.muted)
        }
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
        ChipGrid(columns: colorColumns, spacing: 6) {
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
    InspectorCard(title: studio.t("tab.filter"), symbol: "camera.filters") {
      HStack(spacing: 8) {
        Text("\(studio.t("filter.intensityValue")) \(Int((studio.params.filterIntensity * 100).rounded()))%")
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
        CardReset(label: studio.t("console.reset")) {
          let fresh = BeautyParams()
          studio.params.brightness = fresh.brightness
          studio.params.contrast = fresh.contrast
          studio.params.saturation = fresh.saturation
          studio.params.colorTemperature = fresh.colorTemperature
          studio.params.colorTint = fresh.colorTint
          studio.params.filterID = fresh.filterID
          studio.params.filterIntensity = fresh.filterIntensity
        }
      }
    } content: {
      SectionHead(title: studio.t("color.group.adjust"))
      BipolarSlider(label: studio.t("color.brightness"), value: $studio.params.brightness)
      BipolarSlider(label: studio.t("color.contrast"), value: $studio.params.contrast)
      BipolarSlider(label: studio.t("color.saturation"), value: $studio.params.saturation)
      BipolarSlider(label: studio.t("color.temperature"), value: $studio.params.colorTemperature)
      BipolarSlider(label: studio.t("color.tint"), value: $studio.params.colorTint)
      SectionHead(title: studio.t("color.group.filter"), rule: true)
      ParamSlider(label: studio.t("filter.intensity"), value: $studio.params.filterIntensity)
        .disabled(studio.params.filterID == nil)
        .opacity(studio.params.filterID == nil ? 0.4 : 1)
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
    }
  }
}

private struct StickerPanel: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    InspectorCard(title: studio.t("sticker.title"), symbol: "sparkles") {
      CardReset(label: studio.t("console.reset")) {
        studio.params.stickerID = nil
      }
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        ChipGrid(columns: 3, spacing: 6) {
          ChipButton(title: studio.t("sticker.none"), active: studio.params.stickerID == nil, fillWidth: true) {
            studio.params.stickerID = nil
          }
        }
        ForEach(StickerKind.allCases.filter { !BeautyCatalog.stickers(of: $0).isEmpty }) { kind in
          Text(studio.t(kind.titleKey))
            .font(.system(size: 10))
            .foregroundStyle(StudioColors.muted)
          ChipGrid(columns: 3, spacing: 6) {
            ForEach(BeautyCatalog.stickers(of: kind)) { item in
              ChipButton(
                title: studio.t("sticker.\(item.id)"),
                active: studio.params.stickerID == item.id,
                badge: item.animated ? studio.t("sticker.tag.animated") : nil,
                fillWidth: true
              ) {
                studio.params.stickerID = item.id
              }
            }
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
      CardReset(label: studio.t("console.reset")) {
        let fresh = BeautyParams()
        studio.params.backgroundFill = fresh.backgroundFill
        studio.params.bgBlur = fresh.bgBlur
        studio.params.bgPreset = fresh.bgPreset
        studio.params.chroma = fresh.chroma
        studio.params.chromaSimilarity = fresh.chromaSimilarity
        studio.params.chromaSmoothness = fresh.chromaSmoothness
        studio.params.chromaDesaturation = fresh.chromaDesaturation
        studio.params.subjectOutline = fresh.subjectOutline
      }
    } content: {
      Toggle(isOn: $studio.params.subjectOutline) {
        Text(studio.t("bg.outline"))
          .font(.system(size: 10))
          .foregroundStyle(Color(hex: 0xE5E7EB))
      }
      .toggleStyle(.switch)
      .controlSize(.mini)
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
            if fill == .blur, studio.params.bgBlur <= 0 {
              studio.params.bgBlur = 0.5
            }
            if fill == .image, studio.params.bgPreset == nil {
              studio.params.bgPreset = "office"
            }
          }
        }
      }
      if studio.params.backgroundFill == .blur {
        ParamSlider(label: studio.t("bg.blurAmount"), value: $studio.params.bgBlur)
      }
      if studio.params.backgroundFill == .image {
        Text(studio.t("bg.presets"))
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
        ChipGrid(columns: 3, spacing: 6) {
          ForEach(BeautyCatalog.backgroundPresets, id: \.id) { item in
            ChipButton(
              title: studio.t(item.labelKey),
              active: studio.params.bgPreset == item.id,
              fillWidth: true
            ) {
              studio.params.bgPreset = item.id
            }
          }
        }
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
