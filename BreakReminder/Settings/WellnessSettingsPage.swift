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
                Toggle("Dim the screen when showing a bubble", isOn: settings.dimForReminders)
                Toggle("Keep reminders active during Smart Pause", isOn: settings.remindersDuringSmartPause)
                Toggle("Make reminders invisible in screen recordings", isOn: settings.hideRemindersFromRecordings)
                Toggle("Restart reminder timers after a break", isOn: settings.resetRemindersAfterBreak)
            }
        }
    }

    private func reminderSection(_ kind: WellnessKind, _ reminder: Binding<WellnessReminder>, about: String) -> some View {
        Section {
            Toggle("Enabled", isOn: reminder.enabled)
            Group {
                Picker("Show every", selection: reminder.interval) {
                    ForEach([2, 5, 10, 15, 20, 30], id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(TimeInterval(minutes * 60))
                    }
                }
                Picker("Style", selection: reminder.style) {
                    Text("Bubble").tag(ReminderStyle.bubble)
                    Text("Screen flash").tag(ReminderStyle.flash)
                }
                if reminder.wrappedValue.style == .bubble {
                    Picker("Size", selection: reminder.size) {
                        Text("Small").tag(ReminderSize.small)
                        Text("Medium").tag(ReminderSize.medium)
                        Text("Large").tag(ReminderSize.large)
                    }
                    LabeledContent("Position") {
                        PositionGrid(selection: reminder.position)
                    }
                }
            }
            .disabled(!reminder.wrappedValue.enabled)
        } header: {
            HStack {
                Text(kind.title)
                Button("Try it", systemImage: "play.circle") { preview(kind) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
            }
        } footer: {
            Text(about)
        }
    }
}

/// A tiny screen with 3×3 dots. Click a dot to put the bubble there.
private struct PositionGrid: View {
    @Binding var selection: GridPosition

    var body: some View {
        Grid(horizontalSpacing: 22, verticalSpacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        dot(GridPosition(row: row, column: column))
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            .tint.opacity(0.25),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    private func dot(_ position: GridPosition) -> some View {
        let selected = position == selection
        return Circle()
            .fill(selected ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary))
            .overlay(Circle().fill(.tint).padding(5).opacity(selected ? 1 : 0))
            .frame(width: 18, height: 18)
            .contentShape(Circle())
            .onTapGesture { selection = position }
    }
}
