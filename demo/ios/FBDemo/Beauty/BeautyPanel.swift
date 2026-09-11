import SwiftUI

struct BeautyPanel: View {
  @ObservedObject var studio: BeautySession

  var body: some View {
    VStack(spacing: 8) {
      if studio.panelExpanded {
        tabContent
      }
      tabBar
    }
    .padding(.top, studio.panelExpanded ? 10 : 8)
    .padding(.bottom, 8)
    .background {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
        .opacity(0.82)
    }
    .background(
      Color.black.opacity(0.38),
      in: RoundedRectangle(cornerRadius: 24, style: .continuous)
    )
    .padding(.horizontal, 8)
    .padding(.bottom, 6)
    .animation(.easeInOut(duration: 0.22), value: studio.panelExpanded)
    .environmentObject(studio)
  }

  @ViewBuilder
  private var tabContent: some View {
    switch studio.tab {
    case .skin:
      SkinSection()
    case .reshape:
      ReshapeSection()
    case .makeup:
      MakeupSection()
    case .filter:
      FilterSection()
    case .sticker:
      StickerSection()
    case .background:
      BackgroundSection()
    }
  }

  private var tabBar: some View {
    HStack(spacing: 4) {
      ForEach(BeautyTab.allCases) { item in
        Button {
          selectTab(item)
        } label: {
          VStack(spacing: 4) {
            Image(systemName: item.symbol)
              .font(.system(size: 15, weight: .semibold))
            Text(studio.t(item.labelKey))
              .font(.caption2)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .foregroundStyle(studio.tab == item && studio.panelExpanded ? .black : .white.opacity(0.78))
          .background(
            studio.tab == item && studio.panelExpanded ? Color.white : Color.clear,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
          )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 10)
  }

  private func selectTab(_ item: BeautyTab) {
    if studio.tab == item && studio.panelExpanded {
      studio.panelExpanded = false
    } else {
      studio.tab = item
      studio.panelExpanded = true
    }
  }
}

private struct SkinSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      IntensitySlider(title: studio.t(studio.selectedSkin.labelKey), value: intensityBinding)
        .padding(.horizontal, 14)

      HStack(spacing: 8) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(SkinItem.allCases) { item in
              ChoiceChip(
                title: studio.t(item.labelKey),
                selected: studio.selectedSkin == item
              ) {
                studio.selectedSkin = item
              }
            }
          }
        }
        Toggle(studio.t("skin.skinOnly"), isOn: $studio.params.skinOnly)
          .toggleStyle(SwitchToggleStyle(tint: .white))
          .font(.caption)
          .foregroundStyle(.white)
          .fixedSize()
      }
      .padding(.horizontal, 14)

      if studio.selectedSkin == .smoothing {
        ChipRow(
          items: BeautyCatalog.smoothingStyles.map { ($0.id, $0.labelKey) },
          selection: studio.params.smoothingStyle
        ) { studio.params.smoothingStyle = $0 }
        .padding(.horizontal, 14)
      }

      if studio.selectedSkin == .whitening {
        ChipRow(
          items: BeautyCatalog.whiteningStyles.map { ($0.id, $0.labelKey) },
          selection: studio.params.whiteningStyle
        ) { studio.params.whiteningStyle = $0 }
        .padding(.horizontal, 14)
      }
    }
  }

  private var intensityBinding: Binding<Float> {
    Binding(
      get: {
        switch studio.selectedSkin {
        case .smoothing: return studio.params.smoothing
        case .whitening: return studio.params.whitening
        case .rosiness: return studio.params.rosiness
        case .sharpening: return studio.params.sharpening
        }
      },
      set: { value in
        switch studio.selectedSkin {
        case .smoothing: studio.params.smoothing = value
        case .whitening: studio.params.whitening = value
        case .rosiness: studio.params.rosiness = value
        case .sharpening: studio.params.sharpening = value
        }
      }
    )
  }
}

private struct ReshapeSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(spacing: 10) {
      BipolarSlider(
        title: studio.t(currentItem?.labelKey ?? "reshape.faceThin"),
        value: reshapeBinding
      )
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(BeautyCatalog.reshapeItems) { item in
            ChoiceChip(
              title: studio.t(item.labelKey),
              selected: studio.selectedReshape == item.key
            ) {
              studio.selectedReshape = item.key
            }
          }
        }
        .padding(.horizontal, 14)
      }
    }
  }

  private var currentItem: ReshapeItem? {
    BeautyCatalog.reshapeItems.first { $0.key == studio.selectedReshape }
  }

  private var reshapeBinding: Binding<Float> {
    Binding(
      get: { studio.params.reshape[studio.selectedReshape] ?? 0 },
      set: { studio.params.reshape[studio.selectedReshape] = $0 }
    )
  }
}

private struct MakeupSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(MakeupItem.allCases) { item in
            ChoiceChip(
              title: studio.t(item.labelKey),
              selected: studio.selectedMakeup == item
            ) {
              studio.selectedMakeup = item
            }
          }
        }
        .padding(.horizontal, 14)
      }

      if !styles.isEmpty {
        Text(studio.t("makeup.style"))
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.55))
          .padding(.horizontal, 14)
        ChipWrap(items: styles, selection: styleBinding)
      }
      if !colors.isEmpty {
        Text(studio.t("makeup.color"))
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.55))
          .padding(.horizontal, 14)
        SwatchRow(items: colors, selection: colorBinding)
      }
      IntensitySlider(title: studio.t("makeup.intensity"), value: intensityBinding)
        .padding(.horizontal, 14)
    }
  }

  private var styles: [ChoiceItem] {
    switch studio.selectedMakeup {
    case .blush: return BeautyCatalog.blushStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .contour: return BeautyCatalog.contourStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .eyeshadow: return BeautyCatalog.eyeshadowStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .eyeliner: return BeautyCatalog.eyelinerStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .eyebrow: return BeautyCatalog.eyebrowStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .eyelash: return BeautyCatalog.eyelashStyles.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey) }
    case .lipstick, .pupil: return []
    }
  }

  private var colors: [SwatchItem] {
    switch studio.selectedMakeup {
    case .lipstick:
      return BeautyCatalog.lipstickColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .blush:
      return BeautyCatalog.blushColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .eyeshadow:
      return BeautyCatalog.eyeshadowColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .eyeliner:
      return BeautyCatalog.eyelinerColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .eyebrow:
      return BeautyCatalog.eyebrowColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .eyelash:
      return BeautyCatalog.eyelashColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .pupil:
      return BeautyCatalog.pupilColors.map { .init(id: Int($0.id.rawValue), labelKey: $0.labelKey, color: $0.color) }
    case .contour:
      return []
    }
  }

  private var intensityBinding: Binding<Float> {
    Binding(
      get: { studio.params.intensity(for: studio.selectedMakeup) },
      set: { studio.params.setIntensity($0, for: studio.selectedMakeup) }
    )
  }

  private var styleBinding: Binding<Int> {
    Binding(
      get: {
        switch studio.selectedMakeup {
        case .blush: return Int(studio.params.blushStyle.rawValue)
        case .contour: return Int(studio.params.contourStyle.rawValue)
        case .eyeshadow: return Int(studio.params.eyeshadowStyle.rawValue)
        case .eyeliner: return Int(studio.params.eyelinerStyle.rawValue)
        case .eyebrow: return Int(studio.params.eyebrowStyle.rawValue)
        case .eyelash: return Int(studio.params.eyelashStyle.rawValue)
        default: return 0
        }
      },
      set: { value in
        switch studio.selectedMakeup {
        case .blush: studio.params.blushStyle = FBBlushStyle(rawValue: value) ?? .soft
        case .contour: studio.params.contourStyle = FBContourStyle(rawValue: value) ?? .natural
        case .eyeshadow: studio.params.eyeshadowStyle = FBEyeShadowStyle(rawValue: value) ?? .soft
        case .eyeliner: studio.params.eyelinerStyle = FBEyeLinerStyle(rawValue: value) ?? .classic
        case .eyebrow: studio.params.eyebrowStyle = FBEyebrowStyle(rawValue: value) ?? .natural
        case .eyelash: studio.params.eyelashStyle = FBEyelashStyle(rawValue: value) ?? .classic
        default: break
        }
      }
    )
  }

  private var colorBinding: Binding<Int> {
    Binding(
      get: {
        switch studio.selectedMakeup {
        case .lipstick: return Int(studio.params.lipstickColor.rawValue)
        case .blush: return Int(studio.params.blushColor.rawValue)
        case .eyeshadow: return Int(studio.params.eyeshadowColor.rawValue)
        case .eyeliner: return Int(studio.params.eyelinerColor.rawValue)
        case .eyebrow: return Int(studio.params.eyebrowColor.rawValue)
        case .eyelash: return Int(studio.params.eyelashColor.rawValue)
        case .pupil: return Int(studio.params.pupilColor.rawValue)
        case .contour: return 0
        }
      },
      set: { value in
        switch studio.selectedMakeup {
        case .lipstick: studio.params.lipstickColor = FBLipstickColor(rawValue: value) ?? .rouge
        case .blush: studio.params.blushColor = FBBlushColor(rawValue: value) ?? .coralPink
        case .eyeshadow: studio.params.eyeshadowColor = FBEyeShadowColor(rawValue: value) ?? .plum
        case .eyeliner: studio.params.eyelinerColor = FBEyeLinerColor(rawValue: value) ?? .coffee
        case .eyebrow: studio.params.eyebrowColor = FBEyebrowColor(rawValue: value) ?? .darkBrown
        case .eyelash: studio.params.eyelashColor = FBEyelashColor(rawValue: value) ?? .black
        case .pupil: studio.params.pupilColor = FBPupilColor(rawValue: value) ?? .hazel
        case .contour: break
        }
      }
    )
  }
}

private struct FilterSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(spacing: 10) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ChoiceChip(title: studio.t("filter.none"), selected: studio.params.filterID == nil) {
            studio.params.filterID = nil
          }
          ForEach(BeautyCatalog.filterIDs, id: \.self) { id in
            ChoiceChip(title: studio.filterLabel(id), selected: studio.params.filterID == id) {
              studio.params.filterID = id
            }
          }
        }
        .padding(.horizontal, 14)
      }
      IntensitySlider(title: studio.t("filter.intensity"), value: $studio.params.filterIntensity)
        .disabled(studio.params.filterID == nil)
        .opacity(studio.params.filterID == nil ? 0.4 : 1)
        .padding(.horizontal, 14)
    }
  }
}

private struct StickerSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ChoiceChip(title: studio.t("sticker.none"), selected: studio.params.stickerID == nil) {
          studio.params.stickerID = nil
        }
        ForEach(BeautyCatalog.stickerIDs, id: \.self) { id in
          ChoiceChip(
            title: studio.t("sticker.\(id)"),
            selected: studio.params.stickerID == id
          ) {
            studio.params.stickerID = id
          }
        }
      }
      .padding(.horizontal, 14)
    }
  }
}

private struct BackgroundSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        ForEach(BackgroundFill.allCases) { fill in
          ChoiceChip(
            title: studio.t(fill.labelKey),
            selected: studio.params.backgroundFill == fill
          ) {
            studio.params.backgroundFill = fill
          }
        }
      }
      .padding(.horizontal, 14)

      if studio.params.backgroundFill == .blur {
        IntensitySlider(title: studio.t("bg.blurAmount"), value: $studio.params.bgBlur)
          .padding(.horizontal, 14)
      }

      Text(studio.t("bg.cutout"))
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 14)

      HStack(spacing: 8) {
        ChoiceChip(title: studio.t("bg.portrait"), selected: studio.params.chroma == nil) {
          studio.params.chroma = nil
        }
        ForEach(BeautyCatalog.chromaOptions) { option in
          ChoiceChip(
            title: studio.t(option.labelKey),
            selected: studio.params.chroma == option.id,
            color: option.color
          ) {
            studio.params.chroma = option.id
          }
        }
      }
      .padding(.horizontal, 14)

      if studio.params.chroma != nil {
        IntensitySlider(title: studio.t("bg.similarity"), value: $studio.params.chromaSimilarity)
          .padding(.horizontal, 14)
        IntensitySlider(title: studio.t("bg.smoothness"), value: $studio.params.chromaSmoothness)
          .padding(.horizontal, 14)
        IntensitySlider(title: studio.t("bg.desaturation"), value: $studio.params.chromaDesaturation)
          .padding(.horizontal, 14)
      }
    }
  }
}

private struct ChoiceItem: Identifiable {
  let id: Int
  let labelKey: String
}

private struct SwatchItem: Identifiable {
  let id: Int
  let labelKey: String
  let color: Color?
}

private struct ChipRow<Value: Hashable>: View {
  @EnvironmentObject private var studio: BeautySession
  let items: [(Value, String)]
  let selection: Value
  let onSelect: (Value) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          ChoiceChip(title: studio.t(item.1), selected: selection == item.0) {
            onSelect(item.0)
          }
        }
      }
    }
  }
}

private struct ChipWrap: View {
  @EnvironmentObject private var studio: BeautySession
  let items: [ChoiceItem]
  @Binding var selection: Int

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(items) { item in
          ChoiceChip(title: studio.t(item.labelKey), selected: selection == item.id) {
            selection = item.id
          }
        }
      }
      .padding(.horizontal, 14)
    }
  }
}

private struct SwatchRow: View {
  @EnvironmentObject private var studio: BeautySession
  let items: [SwatchItem]
  @Binding var selection: Int

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(items) { item in
          Button {
            selection = item.id
          } label: {
            Text(studio.t(item.labelKey))
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.white)
              .padding(.horizontal, 10)
              .padding(.vertical, 9)
              .background(item.color ?? Color.white.opacity(0.16))
              .clipShape(Capsule())
              .overlay(
                Capsule().stroke(selection == item.id ? Color.white : Color.clear, lineWidth: 2)
              )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 14)
    }
  }
}

private struct ChoiceChip: View {
  let title: String
  let selected: Bool
  var color: Color?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let color {
          Circle().fill(color).frame(width: 8, height: 8)
        }
        Text(title)
          .font(.caption.weight(.semibold))
          .lineLimit(1)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 9)
      .foregroundStyle(selected ? .black : .white)
      .background(selected ? Color.white : Color.white.opacity(0.12), in: Capsule())
    }
    .buttonStyle(.plain)
  }
}

private struct IntensitySlider: View {
  let title: String
  @Binding var value: Float

  var body: some View {
    HStack(spacing: 10) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: 72, alignment: .leading)
      Slider(value: Binding(
        get: { Double(value) },
        set: { value = Float($0) }
      ), in: 0...1)
      .tint(.white)
      Text("\(Int((value * 100).rounded()))")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.white.opacity(0.8))
        .frame(width: 32, alignment: .trailing)
    }
  }
}

private struct BipolarSlider: View {
  let title: String
  @Binding var value: Float

  var body: some View {
    VStack(spacing: 6) {
      HStack {
        Text(title)
          .font(.caption)
          .foregroundStyle(.white.opacity(0.85))
        Spacer()
        Text(String(format: "%+.0f", value * 100))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.white.opacity(0.8))
      }
      Slider(value: Binding(
        get: { Double(value) },
        set: { value = Float($0) }
      ), in: -1...1)
      .tint(.white)
    }
    .padding(.horizontal, 14)
  }
}
