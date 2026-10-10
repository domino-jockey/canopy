import AppKit
import SwiftUI

/// A short intro shown the first time the app launches.
@MainActor
final class WelcomeWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private static let seenKey = "hasSeenWelcome"

    /// Shows the welcome window unless it's been seen before.
    func showIfFirstLaunch(openSettings: @escaping () -> Void) {
        // Tests run inside the app; they shouldn't use up the welcome.
        let testing = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        guard !testing, !UserDefaults.standard.bool(forKey: Self.seenKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.seenKey)

        let window = NSWindow(contentViewController: NSHostingController(rootView: WelcomeView(
            onSettings: { [weak self] in
                self?.window?.close()
                openSettings()
            },
            onDone: { [weak self] in self?.window?.close() }
        )))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.window = window
        // Like the settings window: a normal app while it's open, so it gets its own Stage Manager stage.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct WelcomeView: View {
    let onSettings: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            VStack(spacing: 6) {
                Text("Welcome to Canopy").font(.title.weight(.bold))
                Text("Small breaks, so your eyes and back last the whole day.").foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 14) {
                row("leaf.fill", .green, "A 20-second break every 20 minutes",
                    "Every 4th one is a longer break to stand up and stretch.")
                row("menubar.rectangle", .accentColor, "Lives in the menu bar",
                    "The leaf shows the time to your next break. Click it to pause, snooze or open Settings.")
                row("pause.fill", .blue, "Gets out of the way",
                    "Pauses during calls and while you're away, and waits for you to stop typing.")
            }
            .frame(maxWidth: 420, alignment: .leading)
            HStack(spacing: 12) {
                Button("Open Settings", action: onSettings)
                Button("Get Started", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            Text("No permissions needed. Turn on Launch at login in Settings › General.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 540)
    }

    private func row(_ symbol: String, _ color: Color, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
