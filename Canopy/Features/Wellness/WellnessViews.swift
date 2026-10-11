import SwiftUI

extension WellnessKind {
    var title: String {
        self == .posture ? "Posture Reminder" : "Blink Reminder"
    }

    /// The line shown by the flash.
    var message: String {
        self == .posture ? "Watch your posture" : "Remember to blink"
    }
}

/// DeskRest-style flash: the screen darkens, a short line appears, then it all fades.
struct WellnessFlash: View {
    let kind: WellnessKind

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            Text(kind.message)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
        }
        .ignoresSafeArea()
    }
}
