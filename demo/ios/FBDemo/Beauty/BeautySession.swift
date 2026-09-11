import Combine
import Foundation
import SwiftUI

class BeautySession: ObservableObject {
  @Published var params = BeautyParams() {
    didSet { paramsDidChange() }
  }
  @Published var tab: BeautyTab = .skin
  @Published var selectedSkin: SkinItem = .smoothing
  @Published var selectedReshape: FBReshape = .faceThin
  @Published var selectedMakeup: MakeupItem = .lipstick
  @Published var locale: AppLocale
  @Published var panelExpanded = false
  @Published var filterLabels: [String: (zh: String, en: String)] = [:]

  init(locale: AppLocale? = nil) {
    if let locale {
      self.locale = locale
    } else if let saved = UserDefaults.standard.string(forKey: Self.localeKey),
              let locale = AppLocale(rawValue: saved) {
      self.locale = locale
    } else {
      let language = Locale.current.language.languageCode?.identifier ?? "en"
      self.locale = language.hasPrefix("zh") ? .zh : .en
    }
    loadFilterLabels()
  }

  func t(_ key: String) -> String {
    L10n.text(key, locale: locale)
  }

  func setLocale(_ next: AppLocale) {
    locale = next
    UserDefaults.standard.set(next.rawValue, forKey: Self.localeKey)
  }

  func syncLocaleFromDefaults() {
    guard let saved = UserDefaults.standard.string(forKey: Self.localeKey),
          let locale = AppLocale(rawValue: saved),
          locale != self.locale else {
      return
    }
    self.locale = locale
  }

  func filterLabel(_ id: String) -> String {
    guard let row = filterLabels[id] else {
      return id.replacingOccurrences(of: "_", with: " ")
    }
    return locale == .zh ? row.zh : row.en.replacingOccurrences(of: "_", with: " ")
  }

  func paramsDidChange() {}

  private func loadFilterLabels() {
    let candidates = [
      Bundle.main.url(forResource: "filter_mapping", withExtension: "json", subdirectory: "Facebetter"),
      Bundle.main.url(forResource: "filter_mapping", withExtension: "json", subdirectory: "Facebetter/filters"),
    ]
    guard let url = candidates.compactMap({ $0 }).first,
          let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let filters = json["filters"] as? [String: [String: Any]] else {
      return
    }
    var labels: [String: (zh: String, en: String)] = [:]
    for (id, row) in filters {
      labels[id] = (
        zh: row["zh"] as? String ?? id,
        en: row["en"] as? String ?? id
      )
    }
    filterLabels = labels
  }

  private static let localeKey = "fb.studio.locale"
}
