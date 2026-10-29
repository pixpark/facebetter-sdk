import SwiftUI
import UIKit

struct BeautyPanel: View {
  @ObservedObject var studio: BeautySession

  var body: some View {
    VStack(spacing: 0) {
      if studio.panelExpanded {
        tabContent
          .padding(.top, 10)
          .padding(.bottom, 6)
      }
      tabBar
        .padding(.top, studio.panelExpanded ? 4 : 10)
        .padding(.bottom, 10)
    }
    .background {
      UnevenRoundedRectangle(
        topLeadingRadius: 18,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: 18,
        style: .continuous
      )
      .fill(Color.black.opacity(0.82))
      .ignoresSafeArea(edges: .bottom)
    }
    .animation(.easeInOut(duration: 0.2), value: studio.panelExpanded)
    .environmentObject(studio)
  }

  @ViewBuilder
  private var tabContent: some View {
    switch studio.tab {
    case .skin:
      SkinSection()
    case .reshape:
      ReshapeSection()
    case .body:
      BodySection()
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
    HStack(spacing: 0) {
      ForEach(BeautyTab.allCases) { item in
        let selected = studio.tab == item && studio.panelExpanded
        Button {
          selectTab(item)
        } label: {
          VStack(spacing: 4) {
            Image(systemName: item.symbol)
              .font(.system(size: 18, weight: .semibold))
            Text(studio.t(item.labelKey))
              .font(.system(size: 12, weight: .medium))
              .lineLimit(1)
              .minimumScaleFactor(0.7)
            Capsule()
              .fill(selected ? PanelColor.brand : Color.clear)
              .frame(width: 16, height: 2)
          }
          .foregroundStyle(selected ? PanelColor.brand : Color.white.opacity(0.75))
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 6)
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

// MARK: - Skin

private struct SkinSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(spacing: 8) {
      SliderRow(
        title: studio.t(studio.selectedSkin.labelKey),
        value: intensityBinding,
        onReset: { studio.params.resetSkin() }
      ) {
        SkinOnlyCheck(title: studio.t("skin.skinOnly"), checked: studio.params.skinOnly) {
          studio.params.skinOnly.toggle()
        }
      }
      SecondaryTabBar(
        titles: SkinItem.allCases.map { studio.t($0.labelKey) },
        selected: SkinItem.allCases.firstIndex(of: studio.selectedSkin) ?? 0
      ) { index in
        studio.selectedSkin = SkinItem.allCases[index]
      }
      if studio.selectedSkin == .smoothing || studio.selectedSkin == .whitening {
        OptionScroller {
          if studio.selectedSkin == .smoothing {
            ForEach(BeautyCatalog.smoothingStyles) { item in
              TextChip(title: studio.t(item.labelKey), selected: studio.params.smoothingStyle == item.id) {
                studio.params.smoothingStyle = item.id
              }
            }
          } else {
            ForEach(BeautyCatalog.whiteningStyles) { item in
              TextChip(title: studio.t(item.labelKey), selected: studio.params.whiteningStyle == item.id) {
                studio.params.whiteningStyle = item.id
              }
            }
          }
        }
        .id(studio.selectedSkin)
      }
    }
  }

  private var intensityBinding: Binding<Float> {
    Binding(
      get: {
        switch studio.selectedSkin {
        case .smoothing: return studio.params.smoothing
        case .blemish: return studio.params.blemish
        case .whitening: return studio.params.whitening
        case .rosiness: return studio.params.rosiness
        case .clarity: return studio.params.clarity
        }
      },
      set: { value in
        switch studio.selectedSkin {
        case .smoothing: studio.params.smoothing = value
        case .blemish: studio.params.blemish = value
        case .whitening: studio.params.whitening = value
        case .rosiness: studio.params.rosiness = value
        case .clarity: studio.params.clarity = value
        }
      }
    )
  }
}

// MARK: - Reshape / body

private struct ReshapeSection: View {
  @EnvironmentObject private var studio: BeautySession
  @State private var groupID = BeautyCatalog.reshapeGroups[0].id

  var body: some View {
    VStack(spacing: 8) {
      SliderRow(
        title: studio.t(currentItem?.labelKey ?? "reshape.faceThin"),
        value: reshapeBinding,
        range: -1...1,
        signed: true,
        onReset: { studio.params.resetReshape() }
      )
      SecondaryTabBar(
        titles: BeautyCatalog.reshapeGroups.map { studio.t("reshape.\($0.id)") },
        selected: groupIndex
      ) { index in
        selectGroup(BeautyCatalog.reshapeGroups[index])
      }
      OptionScroller {
        ForEach(currentGroup.items) { item in
          TextChip(title: studio.t(item.labelKey), selected: studio.selectedReshape == item.key) {
            studio.selectedReshape = item.key
          }
        }
      }
      .id(groupID)
    }
    .onAppear(perform: syncGroup)
  }

  private var currentGroup: ReshapeGroup {
    BeautyCatalog.reshapeGroups.first { $0.id == groupID } ?? BeautyCatalog.reshapeGroups[0]
  }

  private var groupIndex: Int {
    BeautyCatalog.reshapeGroups.firstIndex { $0.id == groupID } ?? 0
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

  private func selectGroup(_ group: ReshapeGroup) {
    groupID = group.id
    if !group.items.contains(where: { $0.key == studio.selectedReshape }),
       let first = group.items.first {
      studio.selectedReshape = first.key
    }
  }

  private func syncGroup() {
    if let group = BeautyCatalog.reshapeGroups.first(where: {
      $0.items.contains { $0.key == studio.selectedReshape }
    }) {
      groupID = group.id
    }
  }
}

private struct BodySection: View {
  @EnvironmentObject private var studio: BeautySession
  @State private var groupID = BeautyCatalog.bodyGroups[0].id

  var body: some View {
    VStack(spacing: 8) {
      SliderRow(
        title: studio.t(currentItem?.labelKey ?? "reshape.bodySlim"),
        value: bodyBinding,
        onReset: { studio.params.resetBody() }
      )
      SecondaryTabBar(
        titles: BeautyCatalog.bodyGroups.map { studio.t("reshape.\($0.id)") },
        selected: groupIndex
      ) { index in
        selectGroup(BeautyCatalog.bodyGroups[index])
      }
      OptionScroller {
        ForEach(currentGroup.items) { item in
          TextChip(title: studio.t(item.labelKey), selected: studio.selectedBody == item.key) {
            studio.selectedBody = item.key
          }
        }
      }
      .id(groupID)
    }
    .onAppear(perform: syncGroup)
  }

  private var currentGroup: BodyReshapeGroup {
    BeautyCatalog.bodyGroups.first { $0.id == groupID } ?? BeautyCatalog.bodyGroups[0]
  }

  private var groupIndex: Int {
    BeautyCatalog.bodyGroups.firstIndex { $0.id == groupID } ?? 0
  }

  private func selectGroup(_ group: BodyReshapeGroup) {
    groupID = group.id
    if !group.items.contains(where: { $0.key == studio.selectedBody }),
       let first = group.items.first {
      studio.selectedBody = first.key
    }
  }

  private func syncGroup() {
    if let group = BeautyCatalog.bodyGroups.first(where: {
      $0.items.contains { $0.key == studio.selectedBody }
    }) {
      groupID = group.id
    }
  }

  private var currentItem: BodyReshapeItem? {
    BeautyCatalog.bodyItems.first { $0.key == studio.selectedBody }
  }

  private var bodyBinding: Binding<Float> {
    Binding(
      get: { studio.params.bodyReshape[studio.selectedBody] ?? 0 },
      set: { studio.params.bodyReshape[studio.selectedBody] = $0 }
    )
  }
}

// MARK: - Makeup

private struct MakeupSection: View {
  @EnvironmentObject private var studio: BeautySession

  var body: some View {
    VStack(spacing: 8) {
      SliderRow(
        title: studio.t("makeup.intensity"),
        value: intensityBinding,
        onReset: { studio.params.resetMakeup() }
      )
      SecondaryTabBar(
        titles: MakeupItem.allCases.map { studio.t($0.labelKey) },
        selected: MakeupItem.allCases.firstIndex(of: studio.selectedMakeup) ?? 0
      ) { index in
        studio.selectedMakeup = MakeupItem.allCases[index]
      }
      if studio.selectedMakeup == .teeth {
        OptionScroller {
          TextChip(title: studio.t("makeup.teethWhiten"), selected: true) {}
        }
      } else if !styles.isEmpty {
        OptionScroller {
          ForEach(styles) { item in
            TextChip(title: studio.t(item.labelKey), selected: styleBinding.wrappedValue == item.id) {
              styleBinding.wrappedValue = item.id
            }
          }
        }
        .id(studio.selectedMakeup)
      }
      if !colors.isEmpty {
        OptionScroller(height: 40) {
          ForEach(colors) { item in
            ColorDot(color: item.color ?? .white, selected: colorBinding.wrappedValue == item.id) {
              colorBinding.wrappedValue = item.id
            }
          }
        }
        .id(studio.selectedMakeup)
      }
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
    case .lipstick, .pupil, .teeth: return []
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
    case .contour, .teeth:
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
        case .contour, .teeth: return 0
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
        case .contour, .teeth: break
        }
      }
    )
  }
}

// MARK: - Filter

private enum FilterPage {
  case look
  case adjust
}

private enum AdjustItem: String, CaseIterable, Identifiable {
  case brightness
  case contrast
  case saturation
  case temperature
  case tint

  var id: String { rawValue }

  var labelKey: String { "color.\(rawValue)" }
}

private struct FilterSection: View {
  @EnvironmentObject private var studio: BeautySession
  @State private var page: FilterPage = .look
  @State private var adjust: AdjustItem = .brightness

  var body: some View {
    VStack(spacing: 8) {
      if page == .look {
        SliderRow(
          title: studio.t("filter.intensity"),
          value: $studio.params.filterIntensity,
          enabled: studio.params.filterID != nil,
          onReset: { studio.params.resetColor() }
        )
      } else {
        SliderRow(
          title: studio.t(adjust.labelKey),
          value: adjustBinding,
          range: -1...1,
          signed: true,
          onReset: { studio.params.resetColor() }
        )
      }
      SecondaryTabBar(
        titles: [studio.t("color.group.filter"), studio.t("color.group.adjust")],
        selected: page == .look ? 0 : 1
      ) { index in
        page = index == 0 ? .look : .adjust
      }
      if page == .look {
        FilterGrid()
      } else {
        OptionScroller {
          ForEach(AdjustItem.allCases) { item in
            TextChip(title: studio.t(item.labelKey), selected: adjust == item) {
              adjust = item
            }
          }
        }
      }
    }
  }

  private var adjustBinding: Binding<Float> {
    switch adjust {
    case .brightness: return $studio.params.brightness
    case .contrast: return $studio.params.contrast
    case .saturation: return $studio.params.saturation
    case .temperature: return $studio.params.colorTemperature
    case .tint: return $studio.params.colorTint
    }
  }
}

// MARK: - Sticker

private struct StickerSection: View {
  @EnvironmentObject private var studio: BeautySession
  @State private var kind: StickerKind = .face

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        ResetButton { studio.params.resetSticker() }
          .padding(.leading, 12)
        Spacer(minLength: 0)
      }
      SecondaryTabBar(
        titles: stickerKinds.map { studio.t($0.titleKey) },
        selected: stickerKinds.firstIndex(of: kind) ?? 0
      ) { index in
        kind = stickerKinds[index]
      }
      OptionScroller {
        TextChip(title: studio.t("sticker.none"), selected: studio.params.stickerID == nil) {
          studio.params.stickerID = nil
        }
        ForEach(BeautyCatalog.stickers(of: kind)) { item in
          TextChip(
            title: studio.t("sticker.\(item.id)"),
            selected: studio.params.stickerID == item.id,
            badge: item.animated ? studio.t("sticker.tag.animated") : nil
          ) {
            studio.params.stickerID = item.id
          }
        }
      }
      .id(kind)
    }
    .onAppear(perform: syncKind)
    .onChange(of: studio.params.stickerID) { _ in
      syncKind()
    }
  }

  private var stickerKinds: [StickerKind] {
    StickerKind.allCases.filter { !BeautyCatalog.stickers(of: $0).isEmpty }
  }

  private func syncKind() {
    guard let id = studio.params.stickerID,
          let item = BeautyCatalog.sticker(id: id) else {
      return
    }
    kind = item.kind
  }
}

// MARK: - Background

private enum BgPage {
  case scene
  case cutout
}

private enum ChromaParam: String, CaseIterable, Identifiable {
  case similarity
  case smoothness
  case desaturation

  var id: String { rawValue }

  var labelKey: String {
    switch self {
    case .similarity: return "bg.similarity"
    case .smoothness: return "bg.smoothness"
    case .desaturation: return "bg.desaturation"
    }
  }
}

private struct BackgroundSection: View {
  @EnvironmentObject private var studio: BeautySession
  @State private var page: BgPage = .scene
  @State private var chromaParam: ChromaParam = .similarity

  var body: some View {
    VStack(spacing: 8) {
      slider
      SecondaryTabBar(
        titles: [studio.t("tab.background"), studio.t("bg.cutout")],
        selected: page == .scene ? 0 : 1
      ) { index in
        page = index == 0 ? .scene : .cutout
      }
      OptionScroller {
        if page == .scene {
          ForEach(BackgroundFill.allCases) { fill in
            TextChip(title: studio.t(fill.labelKey), selected: studio.params.backgroundFill == fill) {
              studio.params.backgroundFill = fill
              if fill == .image, studio.params.bgPreset == nil {
                studio.params.bgPreset = BeautyCatalog.backgroundPresets.first?.id
              }
            }
          }
        } else {
          TextChip(title: studio.t("bg.portrait"), selected: studio.params.chroma == nil) {
            studio.params.chroma = nil
          }
          ForEach(BeautyCatalog.chromaOptions) { option in
            ColorChip(color: option.color ?? .white, selected: studio.params.chroma == option.id) {
              studio.params.chroma = option.id
            }
          }
          if studio.params.chroma != nil {
            RowDivider()
            ForEach(ChromaParam.allCases) { item in
              TextChip(title: studio.t(item.labelKey), selected: chromaParam == item) {
                chromaParam = item
              }
            }
          }
        }
      }
      .id(page == .scene)
      if page == .scene, studio.params.backgroundFill == .image {
        BackgroundPresetGrid()
      }
    }
  }

  @ViewBuilder
  private var slider: some View {
    if page == .scene {
      SliderRow(
        title: studio.t("bg.blurAmount"),
        value: $studio.params.bgBlur,
        enabled: studio.params.backgroundFill == .blur,
        onReset: { studio.params.resetBackground() }
      ) {
        SkinOnlyCheck(title: studio.t("bg.outline"), checked: studio.params.subjectOutline) {
          studio.params.subjectOutline.toggle()
        }
      }
    } else if studio.params.chroma != nil {
      SliderRow(
        title: studio.t(chromaParam.labelKey),
        value: chromaBinding,
        onReset: { studio.params.resetBackground() }
      )
    } else {
      SliderRow(
        title: studio.t("bg.portrait"),
        value: .constant(0),
        enabled: false,
        onReset: { studio.params.resetBackground() }
      )
    }
  }

  private var chromaBinding: Binding<Float> {
    switch chromaParam {
    case .similarity: return $studio.params.chromaSimilarity
    case .smoothness: return $studio.params.chromaSmoothness
    case .desaturation: return $studio.params.chromaDesaturation
    }
  }
}

// MARK: - Controls

private struct ChoiceItem: Identifiable {
  let id: Int
  let labelKey: String
}

private struct SwatchItem: Identifiable {
  let id: Int
  let labelKey: String
  let color: Color?
}

private struct OptionScroller<Content: View>: View {
  var height: CGFloat = 44
  @ViewBuilder var content: () -> Content

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        content()
      }
      .padding(.horizontal, 16)
    }
    .frame(height: height)
  }
}

private struct RowDivider: View {
  var body: some View {
    Rectangle()
      .fill(Color.white.opacity(0.22))
      .frame(width: 1, height: 22)
  }
}

private enum PanelColor {
  static let brand = Color(hex: 0x10B981)
}

private struct SecondaryTabBar: View {
  let titles: [String]
  let selected: Int
  let onSelect: (Int) -> Void

  private var scrolls: Bool { titles.count > 5 }

  var body: some View {
    Group {
      if scrolls {
        ScrollViewReader { proxy in
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
              ForEach(titles.indices, id: \.self) { index in
                tabButton(index).id(index)
              }
            }
            .padding(.horizontal, 14)
          }
          .onChange(of: selected) { index in
            withAnimation(.easeInOut(duration: 0.2)) {
              proxy.scrollTo(index, anchor: .center)
            }
          }
        }
      } else {
        HStack(spacing: 0) {
          ForEach(titles.indices, id: \.self) { index in
            tabButton(index)
              .frame(maxWidth: .infinity)
          }
        }
        .padding(.horizontal, 10)
      }
    }
    .frame(height: 38)
  }

  private func tabButton(_ index: Int) -> some View {
    let on = selected == index
    return Button {
      onSelect(index)
    } label: {
      VStack(spacing: 5) {
        Text(titles[index])
          .font(.system(size: 16, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(scrolls ? 1 : 0.7)
        Capsule()
          .fill(on ? PanelColor.brand : Color.clear)
          .frame(width: 19, height: 2)
      }
      .foregroundStyle(on ? PanelColor.brand : Color.white.opacity(0.5))
      .padding(.horizontal, scrolls ? 14 : 0)
      .frame(height: 38)
    }
    .buttonStyle(.plain)
  }
}

private struct FilterGrid: View {
  @EnvironmentObject private var studio: BeautySession

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
  private let rowHeight: CGFloat = 44
  private let rowSpacing: CGFloat = 8

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      LazyVGrid(columns: columns, spacing: rowSpacing) {
        TextChip(title: studio.t("filter.none"), selected: studio.params.filterID == nil, fillsWidth: true) {
          studio.params.filterID = nil
        }
        ForEach(BeautyCatalog.filterIDs, id: \.self) { id in
          TextChip(title: studio.filterLabel(id), selected: studio.params.filterID == id, fillsWidth: true) {
            studio.params.filterID = id
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .frame(height: rowHeight * 3 + rowSpacing * 2)
  }
}

private struct TextChip: View {
  let title: String
  let selected: Bool
  var badge: String? = nil
  var fillsWidth = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 14, weight: .semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .frame(width: fillsWidth ? nil : 80, height: 44)
        .foregroundStyle(selected ? Color.black : Color.white)
        .background(
          selected ? Color.white : Color.white.opacity(0.14),
          in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
          if let badge {
            Text(badge)
              .font(.system(size: 8, weight: .bold))
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
              .foregroundStyle(.black)
              .background(Color.yellow, in: Capsule())
              .padding(.top, 5)
              .padding(.trailing, 5)
          }
        }
    }
    .buttonStyle(.plain)
  }
}

private struct ColorDot: View {
  let color: Color
  let selected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Circle()
        .fill(color)
        .frame(width: 29, height: 29)
        .overlay {
          Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        }
        .overlay {
          Circle().strokeBorder(PanelColor.brand, lineWidth: selected ? 3 : 0)
            .padding(-3)
        }
        .frame(width: 40, height: 40)
    }
    .buttonStyle(.plain)
  }
}

private struct ColorChip: View {
  let color: Color
  let selected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Circle()
        .fill(color)
        .frame(width: 32, height: 32)
        .overlay {
          Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        }
        .overlay {
          Circle().strokeBorder(Color.white, lineWidth: selected ? 2 : 0)
            .padding(-3)
        }
        .frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
  }
}

private struct BackgroundPresetGrid: View {
  @EnvironmentObject private var studio: BeautySession

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(BeautyCatalog.backgroundPresets) { item in
        let selected = studio.params.bgPreset == item.id
        Button {
          studio.params.bgPreset = item.id
          studio.params.backgroundFill = .image
        } label: {
          VStack(spacing: 4) {
            PresetThumb(id: item.id)
              .frame(height: 52)
              .frame(maxWidth: .infinity)
              .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(studio.t(item.labelKey))
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(selected ? PanelColor.brand : Color.white.opacity(0.85))
              .lineLimit(1)
          }
          .padding(3)
          .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(selected ? PanelColor.brand : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
          }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
  }
}

private struct PresetThumb: View {
  let id: String
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Color.white.opacity(0.08)
      }
    }
    .onAppear(perform: load)
  }

  private func load() {
    guard image == nil else { return }
    let root = Bundle.main.resourceURL?.appendingPathComponent("Facebetter", isDirectory: true)
      ?? Bundle.main.bundleURL
    image = UIImage(contentsOfFile: root.appendingPathComponent("backgrounds/\(id).jpg").path)
  }
}

private struct SkinOnlyCheck: View {
  let title: String
  let checked: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        ZStack {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(checked ? PanelColor.brand : Color.clear)
            .overlay {
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(checked ? PanelColor.brand : Color.white.opacity(0.55), lineWidth: 1.5)
            }
            .frame(width: 16, height: 16)
          if checked {
            Image(systemName: "checkmark")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        Text(title)
          .font(.caption.weight(.medium))
          .foregroundStyle(.white.opacity(0.9))
          .lineLimit(1)
      }
    }
    .buttonStyle(.plain)
  }
}

private struct ResetButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "arrow.counterclockwise")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Color.white.opacity(0.9))
        .frame(width: 28, height: 32)
    }
    .buttonStyle(.plain)
  }
}

private struct SliderRow<Trailing: View>: View {
  let title: String
  @Binding var value: Float
  var range: ClosedRange<Float> = 0...1
  var signed = false
  var enabled = true
  let onReset: () -> Void
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    HStack(spacing: 8) {
      ResetButton(action: onReset)
        .padding(.leading, 12)
      ValueSlider(
        title: title,
        value: $value,
        range: range,
        signed: signed,
        enabled: enabled,
        padsLeading: false,
        padsTrailing: false
      )
      trailing()
    }
    .padding(.trailing, 16)
  }
}

extension SliderRow where Trailing == EmptyView {
  init(
    title: String,
    value: Binding<Float>,
    range: ClosedRange<Float> = 0...1,
    signed: Bool = false,
    enabled: Bool = true,
    onReset: @escaping () -> Void
  ) {
    self.title = title
    self._value = value
    self.range = range
    self.signed = signed
    self.enabled = enabled
    self.onReset = onReset
    self.trailing = { EmptyView() }
  }
}

private enum CenterSliderStyle {
  static let trackHeight: CGFloat = 4
  static let thumbSize: CGSize = {
    let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 280, height: 44))
    let bounds = slider.bounds
    let track = slider.trackRect(forBounds: bounds)
    let thumb = slider.thumbRect(forBounds: bounds, trackRect: track, value: 0.5)
    var size = thumb.size
    if size.width < 8 || size.height < 8 {
      size = CGSize(width: 28, height: 16)
    } else if size.width < size.height * 1.15 {
      size.height *= 0.62
    }
    return size
  }()
}

private struct CenterSlider: View {
  @Binding var value: Float
  let range: ClosedRange<Float>
  var signed = false
  var enabled = true

  var body: some View {
    let thumb = CenterSliderStyle.thumbSize
    GeometryReader { geo in
      let width = geo.size.width
      let inset = thumb.width / 2
      let travel = max(width - thumb.width, 1)
      let span = max(range.upperBound - range.lowerBound, 0.0001)
      let fraction = CGFloat((value - range.lowerBound) / span)
      let x = inset + min(max(fraction, 0), 1) * travel
      let mid = width / 2
      let fillStart = signed ? min(x, mid) : inset
      let fillWidth = signed ? abs(x - mid) : max(x - inset, 0)
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.white.opacity(0.28))
          .frame(width: travel, height: CenterSliderStyle.trackHeight)
          .offset(x: inset)
        Capsule()
          .fill(Color.white)
          .frame(width: fillWidth, height: CenterSliderStyle.trackHeight)
          .offset(x: fillStart)
        Capsule()
          .fill(Color.white)
          .frame(width: thumb.width, height: thumb.height)
          .shadow(color: .black.opacity(0.18), radius: 0.5, y: 0.5)
          .offset(x: x - inset)
      }
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { drag in
            guard enabled else { return }
            let clamped = min(max(0, (drag.location.x - inset) / travel), 1)
            value = range.lowerBound + Float(clamped) * span
          }
      )
    }
    .frame(height: max(thumb.height, 28))
    .allowsHitTesting(enabled)
  }
}

private struct ValueSlider: View {
  let title: String
  @Binding var value: Float
  var range: ClosedRange<Float> = 0...1
  var signed = false
  var enabled = true
  var padsLeading = true
  var padsTrailing = true

  var body: some View {
    HStack(spacing: 8) {
      Text(title)
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.9))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .layoutPriority(1)
      CenterSlider(value: $value, range: range, signed: signed, enabled: enabled)
        .frame(minWidth: 64)
      Text(readout)
        .font(.caption.monospacedDigit())
        .foregroundStyle(.white.opacity(0.75))
        .frame(width: 40, alignment: .leading)
        .layoutPriority(1)
    }
    .padding(.leading, padsLeading ? 16 : 0)
    .padding(.trailing, padsTrailing ? 16 : 0)
    .opacity(enabled ? 1 : 0.38)
  }

  private var readout: String {
    let number = value * 100
    if signed {
      return String(format: "%+.0f", number)
    }
    return "\(Int(number.rounded()))"
  }
}
