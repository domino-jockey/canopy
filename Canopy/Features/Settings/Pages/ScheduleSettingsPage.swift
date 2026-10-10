import SwiftUI

struct ScheduleSettingsPage: View {
    let scheduler: BreakScheduler
    let previewClockOut: () -> Void

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section {
                Toggle("Only run during office hours", isOn: settings.officeHoursEnabled)
                if scheduler.settings.officeHoursEnabled {
                    ForEach(0..<7, id: \.self) { index in
                        dayRow(index, settings.officeHours[index])
                    }
                }
            } header: {
                Text("Office hours")
            } footer: {
                Text("Outside these hours the timer sleeps: no breaks, no reminders.")
            }

            Section {
                ForEach(settings.plannedBreaks) { $planned in
                    HStack {
                        TextField("Name", text: $planned.name)
                            .labelsHidden()
                        DatePicker("Time", selection: timeBinding($planned.time), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Picker("Length", selection: $planned.duration) {
                            ForEach([5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(TimeInterval(minutes * 60))
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                        Button("Remove", systemImage: "minus.circle.fill") {
                            settings.wrappedValue.plannedBreaks.removeAll { $0.id == planned.id }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                Button("Add Planned Break", systemImage: "plus") {
                    settings.wrappedValue.plannedBreaks.append(PlannedBreak(name: "Lunch", time: 12 * 60 + 30, duration: 45 * 60))
                }
            } header: {
                Text("Planned breaks")
            } footer: {
                Text("A break at the same time every day. It shows the break screen for the whole length, and doesn't change your regular break cycle.")
            }

            Section {
                Toggle("Clock Out", isOn: settings.clockOutEnabled)
                Group {
                    DatePicker("Time", selection: timeBinding(settings.clockOutTime), displayedComponents: .hourAndMinute)
                    TextField("Message", text: settings.clockOutMessage, axis: .vertical)
                }
                .disabled(!scheduler.settings.clockOutEnabled)
                Button("Preview", systemImage: "play.fill", action: previewClockOut)
            } header: {
                Text("End of the day")
            } footer: {
                Text("At this time a full screen tells you to stop, with your message. You can keep working if you need to.")
            }
        }
    }

    private func dayRow(_ index: Int, _ day: Binding<DayHours>) -> some View {
        HStack {
            Toggle(Calendar.current.weekdaySymbols[index], isOn: day.on)
            if day.wrappedValue.on {
                DatePicker("From", selection: timeBinding(day.start), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("to").foregroundStyle(.secondary)
                DatePicker("To", selection: timeBinding(day.end), displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
    }

    /// Times are saved as minutes after midnight; the time picker wants a Date.
    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { DaySchedule.date(forMinutes: minutes.wrappedValue) },
            set: { minutes.wrappedValue = DaySchedule.minutes(of: $0) }
        )
    }
}
