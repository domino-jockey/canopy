import SwiftUI

/// What the break screen shows: a copy of the scheduler's values. The overlay controller refreshes it
/// while the break is on, and stops when the break ends, so nothing changes while the screen fades out.
struct BreakDisplay: Equatable {
    var remaining: TimeInterval
    /// How much of the break has passed, 0 to 1.
    var progress: Double
    var isWaitingForEndBreak: Bool
    var canEndEarly: Bool
    var canSkip: Bool
    var canSnooze: Bool
    var snoozesLeft: Int?
    var skipsLeftToday: Int?
    /// How far the Balanced-mode ring has filled, 0 to 1.
    var skipProgress: Double
    /// Seconds until the Balanced-mode ring is full.
    var skipRemaining: TimeInterval
    var enforcement: EnforcementMode
    var escapeAction: EscapeAction

    @MainActor init(_ scheduler: BreakScheduler) {
        remaining = scheduler.breakRemaining
        progress = scheduler.breakDuration > 0 ? scheduler.breakElapsed / scheduler.breakDuration : 1
        isWaitingForEndBreak = scheduler.isWaitingForEndBreak
        canEndEarly = scheduler.canEndEarly
        canSkip = scheduler.canSkip
        canSnooze = scheduler.canSnooze
        snoozesLeft = scheduler.snoozesLeft
        skipsLeftToday = scheduler.skipsLeftToday
        skipProgress = scheduler.breakElapsed / scheduler.balancedSkipDelay
        skipRemaining = max(0, scheduler.balancedSkipDelay - scheduler.breakElapsed)
        enforcement = scheduler.settings.enforcement
        escapeAction = scheduler.settings.escapeAction
    }
}

/// State the break window needs that isn't part of the scheduler.
@MainActor @Observable
final class OverlayModel {
    var display: BreakDisplay
    /// Second stage of the entry animation: the wallpaper and text fading in.
    var revealed = false
    /// How many letters of "emergency" have been typed so far.
    var emergencyTyped = 0

    init(display: BreakDisplay) {
        self.display = display
    }
}

/// The content of the full-screen break window.
struct BreakView: View {
    /// A picture under a dark tint (0 to 1: how strongly the tint covers it).
    struct Background {
        var image: NSImage
        var tint: Double
    }

    let model: OverlayModel
    let message: BreakMessage
    let background: Background?
    let onSkip: () -> Void
    let onEndEarly: () -> Void
    let onSnooze: (_ minutes: Int) -> Void
    let onLock: () -> Void

    private var display: BreakDisplay { model.display }
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            // Big timer, a thin bar of time passed, then the message, centred on the screen.
            VStack(spacing: 0) {
                RollingTime(text: time)
                BreakProgressBar(progress: display.progress, remaining: display.remaining)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                Text(display.isWaitingForEndBreak ? "Break's over" : message.title)
                    .font(.system(size: 40, weight: .bold))
                    .contentTransition(.opacity)
                Text(display.isWaitingForEndBreak ? "Press End Break when you're ready" : message.subtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .padding(.top, 12)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)

            // Buttons along the bottom, apart from the centred block.
            VStack(spacing: 0) {
                Spacer()
                buttons
                footer
                    .padding(.top, 16)
                    .padding(.bottom, 56)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
        }
        .opacity(model.revealed ? 1 : 0)
        .environment(\.colorScheme, .dark)
    }

    private var buttons: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if display.canEndEarly {
                Button(action: onEndEarly) { Label("End Break", systemImage: "checkmark") }
            }
            if display.enforcement != .hardcore && !display.isWaitingForEndBreak {
                SkipColumn(display: display, onSkip: onSkip, onSnooze: onSnooze)
            }
            Button(action: onLock) { Label("Lock Screen", systemImage: "lock") }
        }
        .buttonStyle(.glass)
        .controlSize(.extraLarge)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            if display.canSnooze, let left = display.snoozesLeft {
                Text(left == 1 ? "1 snooze available" : "\(left) snoozes available")
            }
            if display.enforcement != .hardcore, let left = display.skipsLeftToday {
                Text(left == 1 ? "1 skip left today" : "\(left) skips left today")
            }
            if model.emergencyTyped > 0 {
                EmergencyProgress(typed: model.emergencyTyped)
            } else if let escapeHint {
                HStack(spacing: 5) {
                    Text("Press")
                    Keycap("esc")
                    Text(escapeHint)
                }
            } else if display.enforcement == .hardcore || display.skipsLeftToday == 0 {
                // No other way out, so mention the emergency word.
                Text("Type \"emergency\" to skip in an emergency")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    /// Only shown when double-Esc would actually do something.
    private var escapeHint: String? {
        switch display.escapeAction {
        case .skip: display.canSkip || display.enforcement == .balanced && display.skipsLeftToday != 0
            ? "twice to skip the break" : nil
        case .snooze: display.canSnooze ? "twice to snooze 5 min" : nil
        case .nothing: nil
        }
    }

    /// A picture under a dark tint, or near-black with a soft accent-coloured glow at the top.
    @ViewBuilder
    private var backgroundLayer: some View {
        if reduceTransparency {
            Color.black
        } else if let background {
            Image(nsImage: background.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(Color.black.opacity(background.tint))
        } else {
            Color.black
                .overlay(RadialGradient(colors: [Color.accentColor.opacity(0.22), .clear],
                                        center: .top, startRadius: 0, endRadius: 900))
        }
    }

    private var time: String {
        TimeFormat.clock(display.remaining)
    }
}

/// The Skip button with snooze pills tucked behind it, like LookAway
/// (`resources/break_screen_recording/extended_snooze_options.png`). Hovering the column makes the pills float up.
/// The pills are a real part of the layout (space is reserved for them), so clicks and hover work everywhere.
private struct SkipColumn: View {
    let display: BreakDisplay
    let onSkip: () -> Void
    let onSnooze: (_ minutes: Int) -> Void

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var buttonHeight: CGFloat = 48

    private let spacing: CGFloat = 8
    /// How much of each tucked pill shows above the one in front of it.
    private let peek: CGFloat = 8

    var body: some View {
        let options = display.canSnooze ? [1, 5] : []
        VStack(spacing: spacing) {
            ForEach(Array(options.enumerated()), id: \.element) { index, minutes in
                // How many places this pill is above the Skip button.
                let distance = CGFloat(options.count - index)
                Button { onSnooze(minutes) } label: {
                    Label("+\(minutes) min", systemImage: "zzz")
                        .frame(maxWidth: .infinity)
                        .opacity(expanded ? 1 : 0)
                }
                // Tucked: slide down behind Skip, shrink from the top so the peek stays visible.
                .scaleEffect(expanded ? 1 : 1 - distance * 0.1, anchor: .top)
                .offset(y: expanded ? 0 : distance * (buttonHeight + spacing - peek))
                .opacity(expanded ? 1 : 0.6)
                .allowsHitTesting(expanded)
            }
            skipButton
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { buttonHeight = $0 }
                .zIndex(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(.rect)
        .onHover { hovering in
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.25)) { expanded = hovering }
        }
    }

    private var skipButton: some View {
        Button(action: onSkip) {
            Label {
                Text(display.skipsLeftToday == 0 ? "No skips left" : "Skip Break")
            } icon: {
                if display.canSkip {
                    Image(systemName: "chevron.forward.2")
                } else if display.skipsLeftToday == 0 {
                    Image(systemName: "nosign")
                } else {
                    ProgressRing(progress: display.skipProgress, remaining: display.skipRemaining)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!display.canSkip)
    }
}

/// A thin line that fills with the accent colour as the break passes.
private struct BreakProgressBar: View {
    let progress: Double
    let remaining: TimeInterval
    private let size = CGSize(width: 420, height: 4)

    var body: some View {
        Capsule()
            .fill(.white.opacity(0.2))
            .overlay(BarFill(progress: progress, remaining: remaining, size: size))
            .frame(width: size.width, height: size.height)
    }
}

private struct BarFill: NSViewRepresentable {
    let progress: Double
    let remaining: TimeInterval
    let size: CGSize

    func makeNSView(context: Context) -> NSView {
        let fill = CALayer()
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: 0, y: size.height / 2)
        fill.bounds = CGRect(origin: .zero, size: size)
        fill.cornerRadius = size.height / 2
        fill.backgroundColor = NSColor.controlAccentColor.cgColor
        return layerHost(fill)
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let fill = view.layer?.sublayers?.first else { return }
        let current = fill.presentation()?.bounds.width ?? size.width * min(1, max(0, progress))
        glide(fill, "bounds.size.width", from: current, over: remaining)
    }
}

/// A small ring that fills from 0 to 1, starting at the top.
private struct ProgressRing: View {
    let progress: Double
    let remaining: TimeInterval

    var body: some View {
        Circle().stroke(.white.opacity(0.3), lineWidth: 2)
            .overlay(RingFill(progress: progress, remaining: remaining))
            .frame(width: 14, height: 14)
    }
}

private struct RingFill: NSViewRepresentable {
    let progress: Double
    let remaining: TimeInterval

    func makeNSView(context: Context) -> NSView {
        let ring = CAShapeLayer()
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: 7, y: 7), radius: 7, startAngle: .pi / 2, endAngle: -1.5 * .pi, clockwise: true)
        ring.path = path
        ring.fillColor = nil
        ring.lineWidth = 2
        ring.lineCap = .round
        ring.strokeColor = NSColor.controlAccentColor.cgColor
        return layerHost(ring)
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let ring = view.layer?.sublayers?.first as? CAShapeLayer else { return }
        let current = ring.presentation()?.strokeEnd ?? min(1, max(0, progress))
        glide(ring, "strokeEnd", from: current, over: remaining)
    }
}

/// A view that just shows `layer`, for the fills that Core Animation glides.
@MainActor private func layerHost(_ layer: CALayer) -> NSView {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.addSublayer(layer)
    return view
}

/// Moves a fill from `start` to its full value over `duration` seconds. Core Animation runs the glide on
/// its own; animating in SwiftUI instead redraws the whole break screen on the CPU every frame.
/// Called every tick, so the glide is re-aimed from where the fill is now and never jumps.
@MainActor private func glide(_ layer: CALayer, _ keyPath: String, from start: CGFloat, over duration: TimeInterval) {
    layer.removeAllAnimations()
    guard duration > 0 else { return }
    let animation = CABasicAnimation(keyPath: keyPath)
    animation.fromValue = start
    animation.duration = duration
    // The fills move only a few points a second, so 20 frames a second looks smooth and saves work.
    animation.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 20, preferred: 20)
    layer.add(animation, forKey: "glide")
}

/// Shows "emergency" with the letters typed so far lit up.
private struct EmergencyProgress: View {
    let typed: Int
    private let word = "emergency"

    var body: some View {
        HStack(spacing: 0) {
            Text(word.prefix(typed)).foregroundStyle(.orange)
            Text(word.dropFirst(typed)).foregroundStyle(.tertiary)
        }
        .font(.callout.monospaced().weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect()
    }
}

private struct Keycap: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: .rect(cornerRadius: 5))
    }
}
