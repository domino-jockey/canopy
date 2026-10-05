import SwiftUI

struct ScreenBreaksSettingsPage: View {
    let scheduler: BreakScheduler

    /// Every change goes through the scheduler, which saves it and applies it right away.
    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Show a break after") {
                    Text("of focused screen time").foregroundStyle(.secondary)
                }
                StopSlider(value: settings.workInterval, stops: [10, 15, 20, 25, 30, 45, 60, 90], unit: .minutes)
                LabeledContent("Break duration") {}
                StopSlider(value: settings.shortBreakDuration, stops: [10, 15, 20, 30, 45, 60, 90, 120, 180], unit: .seconds)
            }

            Section("Long breaks") {
                Stepper(value: settings.longBreakEvery, in: 2...10) {
                    LabeledContent("Long break", value: "Every \(ordinal(scheduler.settings.longBreakEvery)) break")
                }
                LabeledContent("Long break duration") {}
                StopSlider(value: settings.longBreakDuration, stops: [1, 2, 3, 4, 5, 10], unit: .minutes)
            }

            Section("Break enforcement") {
                HStack(alignment: .top, spacing: 16) {
                    ForEach([EnforcementMode.casual, .balanced, .hardcore], id: \.self) { mode in
                        EnforcementCard(mode: mode, isSelected: scheduler.settings.enforcement == mode) {
                            settings.wrappedValue.enforcement = mode
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                Picker("Skips allowed per day", selection: settings.maxSkipsPerDay) {
                    limitOptions([0, 1, 2, 3, 5, 10])
                }
                Picker("Snoozes allowed per break", selection: settings.maxSnoozesPerBreak) {
                    limitOptions([0, 1, 2, 3, 5])
                }
            } footer: {
                Text("Skips include “Skip next break”. Typing “emergency” on the break screen always works and doesn't count.")
            }

            Section {
                Picker("Double escape action on break screen", selection: settings.escapeAction) {
                    Text("Skip the break").tag(EscapeAction.skip)
                    Text("Snooze 5 minutes").tag(EscapeAction.snooze)
                    Text("Do nothing").tag(EscapeAction.nothing)
                }
                Toggle("Let me “End Break” early if nearly done", isOn: settings.allowEndingEarly)
                Toggle("Keep the break screen up until I press “End Break”", isOn: settings.holdUntilEndBreak)
                Toggle("Lock my Mac automatically when a break starts", isOn: settings.lockOnBreakStart)
            } header: {
                Text("More")
            } footer: {
                Text("While the break screen is held, the next focus cycle waits until you press End Break.")
            }
        }
    }

    @ViewBuilder
    private func limitOptions(_ counts: [Int]) -> some View {
        ForEach(counts, id: \.self) { count in
            Text(count == 0 ? "None" : "\(count)").tag(Int?.some(count))
        }
        Text("No limit").tag(Int?.none)
    }

    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: n as NSNumber)!
    }
}

/// A picture card for one enforcement mode: a mini "Skip Break" pill on LookAway's gradient.
private struct EnforcementCard: View {
    let mode: EnforcementMode
    let isSelected: Bool
    let select: () -> Void

    private var title: String {
        switch mode {
        case .casual: "Casual"
        case .balanced: "Balanced"
        case .hardcore: "Hardcore"
        }
    }

    private var subtitle: String {
        switch mode {
        case .casual: "Skip anytime"
        case .balanced: "Skip after half the break"
        case .hardcore: "No skips allowed"
        }
    }

    private var symbol: String {
        switch mode {
        case .casual: "chevron.forward.2"
        case .balanced: "circle.dashed"
        case .hardcore: "nosign"
        }
    }

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.25, blue: 0.55), Color(red: 0.75, green: 0.3, blue: 0.35), Color(red: 0.85, green: 0.5, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Label("Skip Break", systemImage: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(mode == .hardcore ? 0.5 : 0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.2), in: Capsule())
                }
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(3)
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(isSelected ? Color.coral : .clear, lineWidth: 3)
                }
                Text(title).fontWeight(isSelected ? .semibold : .regular)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
