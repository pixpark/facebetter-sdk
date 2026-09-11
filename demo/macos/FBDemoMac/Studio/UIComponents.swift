import SwiftUI

struct StudioColors {
  static let bg = Color(hex: 0x0B0C10)
  static let topBar = Color(hex: 0x0E1014)
  static let panel = Color(hex: 0x111317)
  static let card = Color(hex: 0x181A20)
  static let border = Color(hex: 0x222630)
  static let cardBorder = Color(hex: 0x262A35)
  static let chip = Color(hex: 0x20232B)
  static let muted = Color(hex: 0x9CA3AF)
  static let stage = Color(hex: 0x07080A)
}

/// Avoid macOS default focus ring (gray rectangle around buttons).
struct QuietButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.82 : 1)
  }
}

extension View {
  @ViewBuilder
  func quietButton() -> some View {
    if #available(macOS 14.0, *) {
      buttonStyle(QuietButtonStyle())
        .focusEffectDisabled()
    } else {
      buttonStyle(QuietButtonStyle())
    }
  }

  @ViewBuilder
  func withoutFocusRing() -> some View {
    if #available(macOS 14.0, *) {
      focusEffectDisabled()
    } else {
      self
    }
  }
}

struct ChipButton: View {
  let title: String
  let active: Bool
  var color: Color?
  var fillWidth = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let color {
          Circle().fill(color).frame(width: 6, height: 6)
        }
        Text(title)
          .font(.system(size: 11, weight: .medium))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: fillWidth ? .infinity : nil)
      .padding(.horizontal, fillWidth ? 6 : 10)
      .padding(.vertical, 7)
      .foregroundStyle(active ? Color.white : StudioColors.muted)
      .background(active ? Color.white.opacity(0.10) : StudioColors.chip)
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(active ? Color.white.opacity(0.22) : Color.white.opacity(0.06), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .quietButton()
  }
}

/// Equal-width columns that span the panel, matching React `grid-cols-N`.
struct ChipGrid<Content: View>: View {
  let columns: Int
  var spacing: CGFloat = 6
  @ViewBuilder var content: () -> Content

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: spacing), count: columns),
      spacing: spacing
    ) {
      content()
    }
  }
}

/// Content-hugging wrap like React `flex flex-wrap gap-1.5`.
struct FlowLayout: Layout {
  var spacing: CGFloat = 6

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0
    var height: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > 0, x + size.width > maxWidth {
        x = 0
        y += rowHeight + spacing
        rowHeight = 0
      }
      rowHeight = max(rowHeight, size.height)
      x += size.width + spacing
      height = max(height, y + rowHeight)
    }
    return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var x = bounds.minX
    var y = bounds.minY
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > bounds.minX, x + size.width > bounds.maxX {
        x = bounds.minX
        y += rowHeight + spacing
        rowHeight = 0
      }
      subview.place(
        at: CGPoint(x: x, y: y),
        proposal: ProposedViewSize(width: size.width, height: size.height)
      )
      rowHeight = max(rowHeight, size.height)
      x += size.width + spacing
    }
  }
}

struct ParamSlider: View {
  let label: String
  @Binding var value: Float
  var range: ClosedRange<Float> = 0...1

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.system(size: 12))
          .foregroundStyle(StudioColors.muted)
        Spacer()
        Text("\(Int((value * 100).rounded()))")
          .font(.system(size: 11, design: .monospaced).weight(.medium))
          .foregroundStyle(Color(hex: 0xE5E7EB))
      }
      Slider(value: Binding(
        get: { Double(value) },
        set: { value = Float($0) }
      ), in: Double(range.lowerBound)...Double(range.upperBound))
      .tint(Color(hex: 0xD1D5DB))
    }
  }
}

struct BipolarSlider: View {
  let label: String
  @Binding var value: Float

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.system(size: 11))
          .foregroundStyle(StudioColors.muted)
        Spacer()
        Text(String(format: "%+.0f", value * 100))
          .font(.system(size: 11, design: .monospaced).weight(.medium))
          .foregroundStyle(Color(hex: 0xE5E7EB))
      }
      Slider(value: Binding(
        get: { Double(value) },
        set: { value = Float($0) }
      ), in: -1...1)
      .tint(Color(hex: 0xD1D5DB))
    }
  }
}

struct InspectorCard<Extra: View, Content: View>: View {
  let title: String
  let symbol: String
  @ViewBuilder var extra: () -> Extra
  @ViewBuilder var content: () -> Content

  init(
    title: String,
    symbol: String,
    @ViewBuilder extra: @escaping () -> Extra = { EmptyView() },
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.symbol = symbol
    self.extra = extra
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label {
          Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: 0xE5E7EB))
        } icon: {
          Image(systemName: symbol)
            .foregroundStyle(Color(hex: 0xD1D5DB))
        }
        Spacer()
        extra()
      }
      .padding(.bottom, 8)
      .overlay(alignment: .bottom) {
        Rectangle().fill(StudioColors.cardBorder).frame(height: 1)
      }
      content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(StudioColors.card)
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(StudioColors.cardBorder, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct PillButton: View {
  let title: String
  var symbol: String?
  var active = false
  var emphasis = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: 12, weight: .medium))
        }
        Text(title)
          .font(.system(size: 12, weight: emphasis ? .semibold : .medium))
      }
      .padding(.horizontal, emphasis ? 16 : 12)
      .padding(.vertical, emphasis ? 7 : 5)
      .foregroundStyle(active || emphasis ? Color(hex: 0x0A0A0A) : Color(hex: 0xD1D5DB))
      .background(active || emphasis ? Color.white : Color(hex: 0x181A20))
      .overlay(
        Capsule().stroke(
          active || emphasis ? Color.white : Color.white.opacity(0.10),
          lineWidth: 1
        )
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
    }
    .quietButton()
  }
}

struct SwatchButton: View {
  let title: String
  let color: Color?
  let active: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.white.opacity(0.92))
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background(color ?? StudioColors.chip)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
              active ? Color.white : Color.white.opacity(0.14),
              lineWidth: active ? 1.5 : 1
            )
        )
    }
    .quietButton()
  }
}
