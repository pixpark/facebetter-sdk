import SwiftUI

@main
struct FBDemoMacApp: App {
  @StateObject private var studio = StudioModel()

  var body: some Scene {
    WindowGroup {
      StudioView()
        .environmentObject(studio)
        .preferredColorScheme(.dark)
        .frame(minWidth: 1100, minHeight: 720)
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 1280, height: 800)
  }
}
