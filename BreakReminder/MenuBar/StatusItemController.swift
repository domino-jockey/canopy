import AppKit
import KeyboardShortcuts
import SwiftUI

/// The menu bar item. Uses AppKit's NSStatusItem with a SwiftUI label inside,
/// because SwiftUI's MenuBarExtra can't animate its label.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let scheduler: BreakScheduler
    private let openSettings: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let label: NSHostingView<MenuBarLabel>

    init(scheduler: BreakScheduler, openSettings: @escaping () -> Void) {
        self.scheduler = scheduler
        self.openSettings = openSettings
        label = PassthroughHostingView(rootView: MenuBarLabel(scheduler: scheduler))
        super.init()

        let button = statusItem.button!
        button.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshWidth()
    }

    /// The status item doesn't size itself to the SwiftUI label, so match it by hand.
    func refreshWidth() {
        statusItem.length = label.fittingSize.width
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        switch scheduler.state {
        case .working, .paused:
            let next = scheduler.nextBreakKind == .long ? "Long break" : "Next break"
            let prefix = scheduler.state == .paused ? "Paused · " : scheduler.isSmartPaused ? "Smart Pause · " : ""
            menu.addItem(info("\(prefix)\(next) in \(TimeFormat.clock(scheduler.workRemaining))"))
            menu.addItem(.separator())
            if scheduler.state == .paused {
                add("Resume", #selector(resume), to: menu, shortcut: .pauseResume)
            } else {
                add("Pause", #selector(pause), to: menu, shortcut: .pauseResume)
            }
            add("Start break now", #selector(startBreak), to: menu, shortcut: .startBreakNow)
            if scheduler.canSnooze { menu.addItem(snoozeItem()) }
            if scheduler.canSkipNextBreak { add("Skip next break", #selector(skipNextBreak), to: menu) }
        case .onBreak:
            break // the break screen covers the menu bar, so there's nothing to show
        case .stopped:
            menu.addItem(info("Stopped"))
        }

        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(withTitle: "Quit BreakReminder", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func info(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// `shortcut`: show the user's recorded global shortcut next to the item.
    private func add(_ title: String, _ action: Selector, to menu: NSMenu, shortcut: KeyboardShortcuts.Name? = nil) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let shortcut { item.setShortcut(for: shortcut) }
        menu.addItem(item)
    }

    private func snoozeItem() -> NSMenuItem {
        let submenu = NSMenu()
        for minutes in [1, 5, 15] {
            let item = NSMenuItem(title: "\(minutes) min", action: #selector(snooze(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            submenu.addItem(item)
        }
        let item = NSMenuItem(title: "Snooze", action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    // MARK: - Actions

    @objc private func pause() { update { scheduler.pause() } }
    @objc private func resume() { update { scheduler.resume() } }
    @objc private func startBreak() { update { scheduler.startBreakNow() } }
    @objc private func skipNextBreak() { update { scheduler.skipNextBreak() } }
    @objc private func snooze(_ sender: NSMenuItem) { update { scheduler.snooze(minutes: sender.tag) } }
    @objc private func showSettings() { openSettings() }

    private func update(_ change: () -> Void) {
        change()
        refreshWidth()
    }
}

/// Lets clicks fall through the SwiftUI label to the status item button underneath.
private final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
