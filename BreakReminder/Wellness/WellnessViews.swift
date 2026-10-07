import SwiftUI

extension WellnessKind {
    var title: String {
        self == .posture ? "Posture Reminder" : "Blink Reminder"
    }

    /// The line shown by the flash style.
    var message: String {
        self == .posture ? "Watch your posture" : "Remember to blink"
    }
}

extension ReminderSize {
    var diameter: CGFloat {
        switch self {
        case .small: 64
        case .medium: 96
        case .large: 128
        }
    }
}

/// LookAway-style glossy bubble in the app icon's gradient, with a little animation:
/// an arrow nudging upwards (posture) or eyes blinking (blink).
struct WellnessBubble: View {
    let kind: WellnessKind
    let diameter: CGFloat
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Mocha.mauve, Mocha.pink, Mocha.peach],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            // Gloss: a soft highlight across the top half.
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: diameter * 0.7, height: diameter * 0.4)
                .offset(y: -diameter * 0.22)
            if kind == .posture { postureArrow } else { blinkingEyes }
        }
        .frame(width: diameter, height: diameter)
        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 2))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        // "Reduce motion": no bounce in, no moving arrow or blinking (the window still fades).
        .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
        .opacity(appeared || reduceMotion ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) { appeared = true }
        }
    }

    private var postureArrow: some View {
        PhaseAnimator(reduceMotion ? [false] : [false, true]) { up in
            Image(systemName: "chevron.up")
                .font(.system(size: diameter * 0.36, weight: .black))
                .foregroundStyle(Mocha.crust)
                .offset(y: up ? -diameter * 0.08 : diameter * 0.06)
        } animation: { _ in .easeInOut(duration: 0.6) }
    }

    private var blinkingEyes: some View {
        PhaseAnimator(reduceMotion ? [true] : [true, false]) { open in
            HStack(spacing: diameter * 0.2) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(Mocha.crust)
                        .frame(width: diameter * 0.1, height: open ? diameter * 0.18 : diameter * 0.03)
                }
            }
        } animation: { open in open ? .easeIn(duration: 0.12) : .easeOut(duration: 0.6) }
    }
}

/// DeskRest-style flash: the screen darkens, the app icon and a short line appear, then it all fades.
struct WellnessFlash: View {
    let kind: WellnessKind

    var body: some View {
        ZStack {
            Mocha.crust.opacity(0.6)
            VStack(spacing: 28) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 180, height: 180)
                Text(kind.message)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Mocha.text)
            }
        }
        .ignoresSafeArea()
    }
}
