import SwiftUI

struct AlertsSettingsPage: View {
    let scheduler: BreakScheduler
    let preview: (AlertKind) -> Void

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section("Position") {
                HStack(alignment: .top, spacing: 16) {
                    ForEach([AlertPosition.topLeft, .topCenter, .topRight], id: \.self) { position in
                        PositionCard(position: position, isSelected: scheduler.settings.alertPosition == position) {
                            settings.wrappedValue.alertPosition = position
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                Toggle("Show a reminder before a break appears", isOn: settings.showHeadsUp)
                Picker("Show it", selection: settings.headsUpSeconds) {
                    secondsOptions([5, 10, 15, 30, 60])
                }
                .disabled(!scheduler.settings.showHeadsUp)
                previewButton(.headsUp)
            } header: {
                Text("Break reminder")
            } footer: {
                Text("Stays up until the break starts, with buttons to start it now or push it back.")
            }

            Section {
                Toggle("Show a countdown next to the pointer", isOn: settings.showCountdown)
                Picker("Countdown duration", selection: settings.countdownSeconds) {
                    secondsOptions([3, 5, 10])
                }
                .disabled(!scheduler.settings.showCountdown)
                previewButton(.countdown)
            } header: {
                Text("Countdown before break")
            } footer: {
                Text("Follows the mouse pointer. Clicks go straight through it.")
            }

            Section {
                Toggle("Show when Smart Pause pauses or resumes the timer", isOn: settings.showSmartPauseAlerts)
                previewButton(.smartPause)
            } header: {
                Text("Smart pause alerts")
            } footer: {
                Text("A small pill for a few seconds. Smart Pause has its own settings page.")
            }

            Section {
                Toggle("Show how long I've gone without a break", isOn: settings.showOvertimeNudge)
                Toggle("Show even when paused", isOn: settings.overtimeWhenPaused)
                    .disabled(!scheduler.settings.showOvertimeNudge)
                previewButton(.overtime)
            } header: {
                Text("Overtime nudge")
            } footer: {
                Text("Appears when skipping or snoozing takes you past your break interval, then every 15 minutes. Click it to dismiss.")
            }
        }
    }

    private func previewButton(_ kind: AlertKind) -> some View {
        Button("Preview", systemImage: "play.fill") { preview(kind) }
    }

    @ViewBuilder
    private func secondsOptions(_ counts: [TimeInterval]) -> some View {
        ForEach(counts, id: \.self) { seconds in
            Text("\(Int(seconds)) seconds before").tag(seconds)
        }
    }
}

/// A tiny screen with a pill drawn where alerts will appear.
private struct PositionCard: View {
    let position: AlertPosition
    let isSelected: Bool
    let select: () -> Void

    private var title: String {
        switch position {
        case .topLeft: "Top left"
        case .topCenter: "Top center"
        case .topRight: "Top right"
        }
    }

    private var alignment: Alignment {
        switch position {
        case .topLeft: .topLeading
        case .topCenter: .top
        case .topRight: .topTrailing
        }
    }

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Capsule().fill(.primary).frame(width: 18, height: 3)
                    Capsule().fill(.tertiary).frame(width: 30, height: 2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .frame(height: 80)
                .background(.tint.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                .padding(3)
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 3)
                }
                Text(title).fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
