import SwiftUI

/// What the alert pills show. The alerts controller fills it in every tick (or with sample values for a preview).
@MainActor @Observable
final class AlertModel {
    var breakKind = BreakKind.short
    var secondsToBreak: TimeInterval = 0
    /// How long before a break the heads-up appears: its bar is full then.
    var headsUpLength: TimeInterval = 10
    var minutesWithoutBreak = 0
    var canSnooze = true
    /// What Smart Pause is holding the timer for. Nil means it just resumed.
    var smartPause: SmartPauseReason?
}

/// Heads-up before a break, laid out like LookAway's: the time above a friendly line, a row of buttons,
/// and a bar along the bottom that drains as the break gets closer.
struct HeadsUpAlert: View {
    let model: AlertModel
    let onStart: () -> Void
    let onSnooze: (_ minutes: Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                RollingTime(text: TimeFormat.paddedClock(model.secondsToBreak),
                            font: .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold),
                            color: .labelColor)
                Text(model.breakKind == .long
                     ? "A long break is coming. Time to stretch."
                     : "Almost time. Your eyes will appreciate this.")
                    .foregroundStyle(.secondary)
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
            HeadsUpBar(fraction: model.secondsToBreak / model.headsUpLength, remaining: model.secondsToBreak)
        }
        .font(.body)
        .padding(16)
        .modifier(AlertBackground(cornerRadius: 26))
    }
}

/// Time left before the break: full when the heads-up appears, empty when the break starts.
/// Core Animation glides it down between the once-a-second updates (a SwiftUI animation would redraw
/// the whole pill on the CPU every frame, see DECISIONS.md).
private struct HeadsUpBar: NSViewRepresentable {
    let fraction: Double
    let remaining: TimeInterval

    func makeNSView(context: Context) -> DrainingBarView { DrainingBarView() }

    func updateNSView(_ view: DrainingBarView, context: Context) {
        view.drain(from: min(1, max(0, fraction)), over: remaining)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: DrainingBarView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 100, height: 4)
    }
}

final class DrainingBarView: NSView {
    private let fill = CALayer()
    private var fraction = 1.0
    private var remaining: TimeInterval = 0

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        layer?.addSublayer(fill)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var wantsUpdateLayer: Bool { true }

    /// Colours follow light/dark mode and the accent colour.
    override func updateLayer() {
        layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor
        fill.backgroundColor = NSColor.controlAccentColor.cgColor
    }

    override func layout() {
        super.layout()
        restart()
    }

    func drain(from fraction: Double, over remaining: TimeInterval) {
        self.fraction = fraction
        self.remaining = remaining
        restart()
    }

    /// The bar empties at a steady rate, so starting again from the latest value never jumps.
    private func restart() {
        layer?.cornerRadius = bounds.height / 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fill.cornerRadius = bounds.height / 2
        fill.frame = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
        fill.removeAllAnimations()
        if remaining > 0 {
            let animation = CABasicAnimation(keyPath: "bounds.size.width")
            animation.fromValue = bounds.width * fraction
            animation.toValue = 0
            animation.duration = remaining
            animation.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 20, preferred: 20)
            fill.add(animation, forKey: "drain")
        }
        CATransaction.commit()
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
            HStack(spacing: 4) {
                Text("\(model.breakKind == .long ? "Long" : "Short") break in")
                RollingTime(text: "\(seconds)", font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .bold),
                            color: .labelColor) // white in dark mode, black in light
            }
            .font(.headline)
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

    static func title(for reason: SmartPauseReason?) -> String {
        switch reason {
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
            Text(Self.title(for: model.smartPause)).font(.headline)
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
