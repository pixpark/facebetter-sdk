import SwiftUI

struct StudioView: View {
  @EnvironmentObject private var studio: StudioModel

  var body: some View {
    VStack(spacing: 0) {
      TopBar(studio: studio)
      HStack(spacing: 0) {
        Viewport(studio: studio)
        Inspector(studio: studio)
      }
    }
    .background(StudioColors.bg)
    .overlay(alignment: .bottomLeading) {
      if !studio.statusKey.isEmpty {
        Text(studio.t(studio.statusKey))
          .font(.system(size: 12))
          .foregroundStyle(Color(hex: 0xE5E7EB))
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Color(hex: 0x181A20).opacity(0.90))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.white.opacity(0.10), lineWidth: 1)
          )
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .padding(.leading, 24)
          .padding(.bottom, 24)
      }
    }
  }
}
