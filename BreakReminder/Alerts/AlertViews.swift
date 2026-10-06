import SwiftUI

/// What the alert pills show. The alerts controller fills it in every tick (or with sample values for a preview).
@MainActor @Observable
final class AlertModel {
    var breakKind = BreakKind.short
    var secondsToBreak: TimeInterval = 0
    var minutesWithoutBreak = 0
    var canSnooze = true
}

/// Heads-up before a break: countdown, a friendly line, and buttons to start now or push it back.
struct HeadsUpAlert: View {
    let model: AlertModel
    let onStart: () -> Void
    let onSnooze: (_ minutes: Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AlertIcon(symbol: "leaf.fill", color: Mocha.green)
                Text(TimeFormat.clock(model.secondsToBreak))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Mocha.mauve)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: model.secondsToBreak)
                Text(model.breakKind == .long
                     ? "A long break is coming. Time to stretch."
                     : "Almost time. Your eyes will appreciate this.")
                    .foregroundStyle(Mocha.subtext1)
            }
            HStack(spacing: 6) {
                Button("Start this break now", action: onStart)
                ForEach([1, 5, 15], id: \.self) { minutes in
                    Button("+\(minutes)m") { onSnooze(minutes) }
                        .disabled(!model.canSnooze)
                }
            }
            .buttonStyle(.glass)
            .tint(Mocha.surface0)
        }
        .alertPill()
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
