import AppKit
import SwiftUI

struct TopBar: View {
  @ObservedObject var studio: StudioModel

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "sparkles")
          .foregroundStyle(Color(hex: 0xE5E7EB))
        Text("Facebetter")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Color(hex: 0xF3F4F6))
        Text("Demo")
          .font(.system(size: 11))
          .foregroundStyle(StudioColors.muted)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color(hex: 0x181A20))
          .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
          .clipShape(Capsule())
      }

      Rectangle()
        .fill(Color.white.opacity(0.10))
        .frame(width: 1, height: 16)

      PillButton(
        title: studio.t("nav.replaceImage"),
        symbol: "photo.on.rectangle"
      ) {
        studio.pickImage()
      }

      PillButton(
        title: studio.t("nav.camera"),
        symbol: "camera",
        active: studio.source == .camera
      ) {
        studio.startCamera()
      }

      Spacer()

      PillButton(
        title: studio.t("nav.website"),
        symbol: "arrow.up.right.square"
      ) {
        if let url = URL(string: studio.locale == .zh
                          ? "https://facebetter.net/zh/"
                          : "https://facebetter.net/") {
          NSWorkspace.shared.open(url)
        }
      }

      HStack(spacing: 2) {
        localeButton(.zh, title: studio.t("nav.langZh"))
        localeButton(.en, title: studio.t("nav.langEn"))
      }
      .padding(2)
      .background(Color(hex: 0x181A20))
      .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
      .clipShape(Capsule())

      PillButton(
        title: studio.t("nav.export"),
        symbol: "square.and.arrow.down",
        emphasis: true
      ) {
        studio.exportImage()
      }
    }
    .padding(.horizontal, 24)
    .frame(height: 48)
    .background(StudioColors.topBar)
    .overlay(alignment: .bottom) {
      Rectangle().fill(StudioColors.border).frame(height: 1)
    }
  }

  private func localeButton(_ locale: AppLocale, title: String) -> some View {
    Button {
      studio.setLocale(locale)
    } label: {
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(studio.locale == locale ? Color(hex: 0x0A0A0A) : StudioColors.muted)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(studio.locale == locale ? Color.white : Color.clear)
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .withoutFocusRing()
  }
}