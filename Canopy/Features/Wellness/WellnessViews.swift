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

/// DeskRest-style flash: the screen darkens, the app icon and a short line appear, then it all fades.
struct WellnessFlash: View {
    let kind: WellnessKind

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(spacing: 28) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 180, height: 180)
                Text(kind.message)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }
}
