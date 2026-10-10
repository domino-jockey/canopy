import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SmartPauseSettingsPage: View {
    let scheduler: BreakScheduler

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section {
                Toggle("Hold off breaks while I'm typing or dragging", isOn: settings.holdOffWhileTyping)
            } footer: {
                Text("When a break is due, it waits for a pause in your typing, up to 30 seconds.")
            }

            Section {
                Toggle("Meetings or calls", isOn: settings.pauseForMeetings)
                Toggle("Deep focus apps", isOn: settings.pauseForFocusApps)
                if scheduler.settings.pauseForFocusApps {
                    ForEach(scheduler.settings.focusApps, id: \.self) { app in
                        FocusAppRow(app: app) {
                            settings.wrappedValue.focusApps.removeAll { $0 == app }
                        }
                    }
                    Button("Add App…", systemImage: "plus", action: addApp)
                }
                Toggle("macOS Focus", isOn: settings.pauseForFocusMode)
                Picker("Cooldown after smart pause ends", selection: settings.smartPauseCooldown) {
                    Text("None").tag(TimeInterval(0))
                    Text("30 seconds").tag(TimeInterval(30))
                    Text("1 minute").tag(TimeInterval(60))
                    Text("2 minutes").tag(TimeInterval(120))
                    Text("5 minutes").tag(TimeInterval(300))
                }
            } header: {
                Text("Automatically pause during")
            } footer: {
                Text("Meetings: any app using the microphone or camera. Deep focus apps: while one is in front.")
            }

            if scheduler.settings.pauseForFocusMode {
                Section("Set up macOS Focus") {
                    Text("""
                    macOS only tells apps about Focus through Shortcuts. In the Shortcuts app, open \
                    Automation and add two for each Focus you use:
                    1. “When [Focus] is turned on” → Open URL `canopy://focus-on`
                    2. “When [Focus] is turned off” → Open URL `canopy://focus-off`
                    Set each to run immediately.
                    """)
                    .foregroundStyle(.secondary)
                    Button("Open Shortcuts", systemImage: "arrow.up.forward.app") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
                    }
                }
            }

            Section {
                Picker("Stop counting when I'm away for", selection: settings.idlePauseAfter) {
                    Text("30 seconds").tag(TimeInterval(30))
                    Text("1 minute").tag(TimeInterval(60))
                    Text("2 minutes").tag(TimeInterval(2 * 60))
                }
                Picker("Count as a break when I'm away for", selection: settings.idleResetAfter) {
                    Text("3 minutes").tag(TimeInterval(3 * 60))
                    Text("5 minutes").tag(TimeInterval(5 * 60))
                    Text("10 minutes").tag(TimeInterval(10 * 60))
                    Text("15 minutes").tag(TimeInterval(15 * 60))
                }
                Toggle("Show a heads-up when I come back", isOn: settings.showWelcomeBack)
            } header: {
                Text("Stepping away")
            } footer: {
                Text("With no mouse or keyboard input, the timer stops counting after the first time, and starts a fresh cycle after the second.")
            }
        }
    }

    /// Picks an app from /Applications to add to the deep focus list.
    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let id = Bundle(url: url)?.bundleIdentifier,
                  !scheduler.settings.focusApps.contains(where: { $0.bundleID == id })
            else { continue }
            let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
            settings.wrappedValue.focusApps.append(FocusApp(bundleID: id, name: name))
        }
    }
}

/// An app's icon and name, with a button to remove it from the list.
private struct FocusAppRow: View {
    let app: FocusApp
    let remove: () -> Void

    var body: some View {
        HStack {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            Text(app.name)
            Spacer()
            Button("Remove", systemImage: "minus.circle.fill", action: remove)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 20)
    }
}
