import SwiftUI

@main
struct FBDemoApp: App {
  @StateObject private var studio = StudioModel()

  var body: some Scene {
    WindowGroup {
      StudioView()
        .environmentObject(studio)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
  }
}
