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

/// A picture card for one enforcement mode: a tiny break screen with that mode's Skip button.
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

    private var color: Color {
        switch mode {
        case .casual: Mocha.green
        case .balanced: Mocha.peach
        case .hardcore: Mocha.red
        }
    }

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                // A tiny break screen showing how its Skip button behaves in this mode.
                VStack(spacing: 6) {
                    Text("0:20")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Mocha.mauve)
                    HStack(spacing: 5) {
                        skipIcon
                        Text("Skip")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mode == .hardcore ? Mocha.overlay0 : Mocha.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Mocha.surface0, in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Mocha.crust)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Mocha.surface0))
                .padding(3)
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 3)
                }
                Text(title).fontWeight(isSelected ? .semibold : .regular)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var skipIcon: some View {
        switch mode {
        case .casual:
            Image(systemName: "chevron.forward.2").foregroundStyle(color)
        case .balanced:
            // A ring partway through filling, like the real Balanced Skip button.
            ZStack {
                Circle().stroke(Mocha.surface2, lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 10, height: 10)
        case .hardcore:
            Image(systemName: "nosign").foregroundStyle(color)
        }
    }
}
