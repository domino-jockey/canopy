import SwiftUI

/// What the break screen shows: a copy of the scheduler's values. The overlay controller refreshes it
/// while the break is on, and stops when the break ends, so nothing changes while the screen fades out.
struct BreakDisplay: Equatable {
    var remaining: TimeInterval
    var isWaitingForEndBreak: Bool
    var canEndEarly: Bool
    var canSkip: Bool
    var canSnooze: Bool
    var snoozesLeft: Int?
    var skipsLeftToday: Int?
    /// How far the Balanced-mode ring has filled, 0 to 1.
    var skipProgress: Double
    var enforcement: EnforcementMode
    var escapeAction: EscapeAction

    @MainActor init(_ scheduler: BreakScheduler) {
        remaining = scheduler.breakRemaining
        isWaitingForEndBreak = scheduler.isWaitingForEndBreak
        canEndEarly = scheduler.canEndEarly
        canSkip = scheduler.canSkip
        canSnooze = scheduler.canSnooze
        snoozesLeft = scheduler.snoozesLeft
        skipsLeftToday = scheduler.skipsLeftToday
        skipProgress = scheduler.breakElapsed / scheduler.balancedSkipDelay
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
    /// A picture under a Mocha tint (0 to 1: how strongly the tint covers it).
    struct Background {
        var image: NSImage
        var tint: Double
    }

    let model: OverlayModel
    let message: BreakMessage
    let background: Background?
    let showClock: Bool
    let onSkip: () -> Void
    let onEndEarly: () -> Void
    let onSnooze: (_ minutes: Int) -> Void
    let onLock: () -> Void

    private var display: BreakDisplay { model.display }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TimelineView(.everyMinute) { context in
                    Label(context.date.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.title3.weight(.semibold))
                }
                .padding(.top, 48)
                .opacity(showClock ? 1 : 0)

                Spacer()

                if let symbol = message.symbol, !display.isWaitingForEndBreak {
                    Image(systemName: symbol)
                        .font(.system(size: 56))
                        .foregroundStyle(Mocha.mauve)
                        .padding(.bottom, 24)
                }

                Text(display.isWaitingForEndBreak ? "Break's over" : message.title)
                    .font(.system(size: 64, weight: .bold))
                    .contentTransition(.opacity)
                Text(display.isWaitingForEndBreak ? "Press End Break when you're ready" : message.subtitle)
                    .font(.title2)
                    .contentTransition(.opacity)
                    .padding(.top, 16)
                Capsule()
                    .fill(Mocha.surface2)
                    .frame(width: 120, height: 2)
                    .padding(.vertical, 40)
                Text(time)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(Mocha.mauve)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: time)

                Spacer()

                buttons
                footer
                    .padding(.top, 16)
                    .padding(.bottom, 56)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Mocha.text)
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
        .tint(Mocha.surface0)
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
        .foregroundStyle(Mocha.subtext0)
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

    /// A picture under a Mocha tint, or a Mocha gradient with a soft mauve glow at the top.
    @ViewBuilder
    private var backgroundLayer: some View {
        if let background {
            Image(nsImage: background.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(Mocha.base.opacity(background.tint))
        } else {
            LinearGradient(colors: [Mocha.base, Mocha.crust], startPoint: .top, endPoint: .bottom)
                .overlay(RadialGradient(colors: [Mocha.mauve.opacity(0.25), .clear],
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
            withAnimation(.spring(duration: 0.35, bounce: 0.25)) { expanded = hovering }
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
                    ProgressRing(progress: display.skipProgress)
                        // Ticks arrive once a second; animating over that second makes the fill smooth.
                        .animation(.linear(duration: 1), value: display.skipProgress)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!display.canSkip)
    }
}

/// A small ring that fills from 0 to 1.
private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Mocha.surface2, lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(Mocha.mauve, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 14, height: 14)
    }
}

/// Shows "emergency" with the letters typed so far lit up.
private struct EmergencyProgress: View {
    let typed: Int
    private let word = "emergency"

    var body: some View {
        HStack(spacing: 0) {
            Text(word.prefix(typed)).foregroundStyle(Mocha.peach)
            Text(word.dropFirst(typed)).foregroundStyle(Mocha.overlay0)
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
            .background(Mocha.surface1, in: .rect(cornerRadius: 5))
    }
}
