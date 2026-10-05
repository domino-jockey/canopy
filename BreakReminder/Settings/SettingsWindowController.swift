import AppKit
import SwiftUI

/// The settings window, opened from the menu bar's "Settings…" item.
@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(scheduler: BreakScheduler) {
        window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(scheduler: scheduler)))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.setContentSize(NSSize(width: 820, height: 640))
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        // A menu-bar-only app isn't active by default, so bring it forward with the window.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
