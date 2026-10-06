import AppKit
import SwiftUI

/// The settings window, opened from the menu bar's "Settings…" item.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    init(scheduler: BreakScheduler) {
        window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(scheduler: scheduler)))
        super.init()
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified // one slim bar with ‹ › and the title, like System Settings
        window.backgroundColor = NSColor(Mocha.base) // the title bar area
        window.setContentSize(NSSize(width: 820, height: 640))
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
    }

    func show() {
        // Menu-bar-only apps' windows float over Stage Manager instead of getting their own stage,
        // so act as a normal app (with a Dock icon) while settings are open.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
