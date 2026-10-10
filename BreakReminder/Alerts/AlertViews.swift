import SwiftUI

/// What the alert pills show. The alerts controller fills it in every tick (or with sample values for a preview).
@MainActor @Observable
final class AlertModel {
    var breakKind = BreakKind.short
    var secondsToBreak: TimeInterval = 0
    var minutesWithoutBreak = 0
    var canSnooze = true
    /// What Smart Pause is holding the timer for. Nil means it just resumed.
    var smartPause: SmartPauseReason?
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
                        .font(.title2.monospaced().weight(.bold))
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.default, value: model.secondsToBreak)
                    Text(model.breakKind == .long
                         ? "A long break is coming. Time to stretch."
                         : "Almost time. Your eyes will appreciate this.")
                        .foregroundStyle(.secondary)
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
        .modifier(AlertBackground(cornerRadius: 26))
    }
}

/// A round clock face in the accent colour: tick marks and one hand.
private struct ClockBadge: View {
    var body: some View {
        ZStack {
            Circle().fill(Accent.gradient)
            ForEach(0..<12) { hour in
                Capsule()
                    .fill(.white.opacity(0.6))
                    .frame(width: 1.5, height: 4)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(hour) * 30))
            }
            Capsule()
                .fill(.white)
                .frame(width: 2.5, height: 12)
                .offset(y: -4)
        }
        .frame(width: 44, height: 44)
    }
}

/// Heads-up buttons: a softly filled pill for the main action, outline-only pills for snoozes.
private struct HeadsUpButtonStyle: ButtonStyle {
    let filled: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(filled ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear), in: Capsule())
            .overlay(Capsule().strokeBorder(filled ? AnyShapeStyle(.clear) : AnyShapeStyle(.tertiary)))
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
            AlertIcon(symbol: "leaf.fill", color: .green)
            Text("\(model.breakKind == .long ? "Long" : "Short") break in \(Text("\(seconds)").monospaced())")
                .font(.headline)
                .foregroundStyle(.tint)
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
                AlertIcon(symbol: "bolt.fill", color: .orange)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Text("\(model.minutesWithoutBreak)").monospaced()) \(model.minutesWithoutBreak == 1 ? "minute" : "minutes")")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("without a break")
                        .foregroundStyle(.secondary)
                }
            }
            .alertPill()
        }
        .buttonStyle(.plain)
    }
}

/// "Paused for your call" when Smart Pause starts, "Timer resumed" when it ends.
struct SmartPauseAlert: View {
    let model: AlertModel

    private var title: String {
        switch model.smartPause {
        case .meeting: "Paused for your call"
        case .focusApp(let name): "Paused while \(name) is open"
        case .focusMode: "Paused for your Focus"
        case nil: "Timer resumed"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            AlertIcon(symbol: model.smartPause == nil ? "play.fill" : "pause.fill",
                      color: model.smartPause == nil ? .green : .blue)
            Text(title).font(.headline)
        }
        .alertPill()
    }
}

/// After being away long enough for it to count as a break.
struct WelcomeBackAlert: View {
    let model: AlertModel

    var body: some View {
        HStack(spacing: 10) {
            AlertIcon(symbol: "hand.wave.fill", color: .yellow)
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome back").font(.headline)
                Text("That counted as a break. Next one in \(Text(TimeFormat.clock(model.secondsToBreak)).monospaced()).")
                    .foregroundStyle(.secondary)
            }
        }
        .alertPill()
    }
}

/// White symbol on a small circle in a system colour.
private struct AlertIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(color, in: Circle())
    }
}

/// Plain Liquid Glass, or the solid window colour when "Reduce transparency" is on.
private struct AlertBackground: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: cornerRadius))
        } else {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }
}

private extension View {
    /// Liquid Glass pill.
    func alertPill() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 10)
            .modifier(AlertBackground(cornerRadius: 18))
    }
}
