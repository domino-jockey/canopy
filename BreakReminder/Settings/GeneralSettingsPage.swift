import ServiceManagement
import SwiftUI

struct GeneralSettingsPage: View {
    /// macOS keeps the login item list itself, so this is read from it rather than saved by us.
    @State private var status = SMAppService.mainApp.status
    @State private var error: String?

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
