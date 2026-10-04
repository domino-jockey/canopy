import SwiftUI

@main
struct GlanceApp: App {
    var body: some Scene {
        // Placeholder menu bar item so the app can be quit. Replaced in Phase 2.
        MenuBarExtra("Glance", systemImage: "eye") {
            Button("Quit Glance") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
