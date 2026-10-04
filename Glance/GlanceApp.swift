import SwiftUI

@main
struct GlanceApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        // The menu bar item lives in AppDelegate. SwiftUI needs at least one scene.
        Settings { EmptyView() }
    }
}
