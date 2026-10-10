import ServiceManagement
import SwiftUI

struct GeneralSettingsPage: View {
    let scheduler: BreakScheduler
    /// macOS keeps the login item list itself, so this is read from it rather than saved by us.
    @State private var status = SMAppService.mainApp.status
    @State private var error: String?

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(get: { status == .enabled }, set: setLaunchAtLogin))
            } footer: {
                if status == .requiresApproval {
                    Text("Allow BreakReminder in System Settings › General › Login Items.")
                } else if let error {
                    Text(error)
                }
            }

            Section("Menu bar") {
                MenuBarPreview(scheduler: scheduler)
                    .listRowInsets(EdgeInsets())
                Toggle("Live Status", isOn: settings.showLiveStatus)
                Picker("Display", selection: settings.menuBarDisplay) {
                    Text("Icon and text").tag(MenuBarDisplay.iconAndText)
                    Text("Text only").tag(MenuBarDisplay.textOnly)
                }
                .disabled(!scheduler.settings.showLiveStatus)
                Picker("Timer style", selection: settings.timerStyle) {
                    Text("19:42").tag(TimerStyle.clock)
                    Text("20m").tag(TimerStyle.minutes)
                }
                .disabled(!scheduler.settings.showLiveStatus)
            }
        }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        status = SMAppService.mainApp.status
    }
}

/// A strip of fake menu bar showing the real, live menu bar item, so changes show up as you make them.
private struct MenuBarPreview: View {
    let scheduler: BreakScheduler

    var body: some View {
        HStack {
            Image(systemName: "apple.logo")
            Text("BreakReminder").fontWeight(.semibold)
            Spacer()
            MenuBarLabel(scheduler: scheduler)
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(.bar)
    }
}
