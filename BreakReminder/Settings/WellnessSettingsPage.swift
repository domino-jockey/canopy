import SwiftUI

struct WellnessSettingsPage: View {
    let scheduler: BreakScheduler
    let preview: (WellnessKind) -> Void

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            reminderSection(.posture, settings.posture,
                            about: "Helps you keep good posture by gently reminding you to sit up straight.")
            reminderSection(.blink, settings.blink,
                            about: "Prevents dry eyes by nudging you to blink at healthy intervals.")

            Section("Common settings") {
                Toggle("Keep reminders active during Smart Pause", isOn: settings.remindersDuringSmartPause)
                Toggle("Make reminders invisible in screen recordings", isOn: settings.hideRemindersFromRecordings)
                Toggle("Restart reminder timers after a break", isOn: settings.resetRemindersAfterBreak)
            }
        }
    }

    private func reminderSection(_ kind: WellnessKind, _ reminder: Binding<WellnessReminder>, about: String) -> some View {
        Section {
            Toggle("Enabled", isOn: reminder.enabled)
            Picker("Show every", selection: reminder.interval) {
                ForEach([2, 5, 10, 15, 20, 30], id: \.self) { minutes in
                    Text("\(minutes) minutes").tag(TimeInterval(minutes * 60))
                }
            }
            .disabled(!reminder.wrappedValue.enabled)
            Button("Preview", systemImage: "play.fill") { preview(kind) }
        } header: {
            Text(kind.title)
        } footer: {
            Text(about)
        }
    }
}
