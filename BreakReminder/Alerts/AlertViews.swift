import SwiftUI

/// What the alert pills show. The alerts controller fills it in every tick (or with sample values for a preview).
@MainActor @Observable
final class AlertModel {
    var breakKind = BreakKind.short
    var secondsToBreak: TimeInterval = 0
    var minutesWithoutBreak = 0
    var canSnooze = true
}

/// Heads-up before a break, laid out like LookAway's: a round clock badge, the time above a friendly line,
/// and a row of buttons underneath.
struct HeadsUpAlert: View {
    let model: AlertModel
    let onStart: () -> Void
    let onSnooze: (_ minutes: Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ClockBadge()
                VStack(alignment: .leading, spacing: 2) {
                    Text(TimeFormat.paddedClock(model.secondsToBreak))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.default, value: model.secondsToBreak)
                    Text(model.breakKind == .long
                         ? "A long break is coming. Time to stretch."
                         : "Almost time. Your eyes will appreciate this.")
                        .foregroundStyle(Mocha.subtext0)
                }
            }
            HStack(spacing: 8) {
                Button("Start this break now", action: onStart)
                    .buttonStyle(HeadsUpButtonStyle(filled: true))
                ForEach([1, 5, 15], id: \.self) { minutes in
                    Button("+\(minutes)m") { onSnooze(minutes) }
                        .buttonStyle(HeadsUpButtonStyle(filled: false))
                        .disabled(!model.canSnooze)
                }
            }
        }
        .font(.body)
        .padding(16)
        .glassEffect(.regular.tint(Mocha.base.opacity(0.75)), in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Mocha.surface1.opacity(0.8)))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
        .foregroundStyle(Mocha.text)
        .environment(\.colorScheme, .dark)
    }
}

/// A round clock face in the app icon's mauve → pink → peach gradient: tick marks and one hand.
private struct ClockBadge: View {
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Mocha.mauve, Mocha.pink, Mocha.peach],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            ForEach(0..<12) { hour in
                Capsule()
                    .fill(Mocha.crust.opacity(0.35))
                    .frame(width: 1.5, height: 4)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(hour) * 30))
            }
            Capsule()
                .fill(Mocha.crust.opacity(0.8))
                .frame(width: 2.5, height: 12)
                .offset(y: -4)
        }
        .frame(width: 44, height: 44)
    }
}

/// LookAway's heads-up buttons: a softly filled pill for the main action, outline-only pills for snoozes.
private struct HeadsUpButtonStyle: ButtonStyle {
    let filled: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(filled ? Mocha.surface0 : .clear, in: Capsule())
            .overlay(Capsule().strokeBorder(filled ? .clear : Mocha.surface1))
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
    }
}

/// "Short break in 5", next to the mouse pointer.
struct CountdownAlert: View {
    let model: AlertModel

    var body: some View {
        let seconds = max(0, Int(model.secondsToBreak.rounded()))
        HStack(spacing: 8) {
            AlertIcon(symbol: "leaf.fill", color: Mocha.green)
            Text("\(model.breakKind == .long ? "Long" : "Short") break in \(seconds)")
                .font(.headline)
                .foregroundStyle(Mocha.mauve)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: seconds)
        }
        .alertPill()
    }
}

/// "45 minutes without a break". Clicking it dismisses it.
struct OvertimeAlert: View {
    let model: AlertModel
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 10) {
                AlertIcon(symbol: "bolt.fill", color: Mocha.peach)
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.minutesWithoutBreak == 1 ? "1 minute" : "\(model.minutesWithoutBreak) minutes")
                        .font(.headline)
                        .foregroundStyle(Mocha.peach)
                    Text("without a break")
                        .foregroundStyle(Mocha.subtext0)
                }
            }
            .alertPill()
        }
        .buttonStyle(.plain)
    }
}

/// Dark symbol on a pastel square, like the settings sidebar.
private struct AlertIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Mocha.crust)
            .frame(width: 26, height: 26)
            .background(color, in: RoundedRectangle(cornerRadius: 7))
    }
}

private extension View {
    /// Mocha-tinted Liquid Glass pill.
    func alertPill() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(Mocha.base.opacity(0.6)), in: .rect(cornerRadius: 18))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
            .foregroundStyle(Mocha.text)
            .environment(\.colorScheme, .dark)
    }
}
