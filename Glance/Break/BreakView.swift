import SwiftUI

/// Drives the second stage of the entry animation: the wallpaper and text fading in.
@MainActor @Observable
final class OverlayModel {
    var revealed = false
}

/// The content of the full-screen break window.
struct BreakView: View {
    let scheduler: BreakScheduler
    let model: OverlayModel
    let message: BreakMessage
    let background: NSImage?
    let onSkip: () -> Void
    let onLock: () -> Void

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

                Spacer()

                Text(message.title)
                    .font(.system(size: 64, weight: .bold))
                Text(message.subtitle)
                    .font(.title2)
                    .padding(.top, 16)
                Capsule()
                    .frame(width: 120, height: 2)
                    .opacity(0.5)
                    .padding(.vertical, 40)
                Text(time)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: time)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onSkip) { Label("Skip Break", systemImage: "chevron.forward.2") }
                    Button(action: onLock) { Label("Lock Screen", systemImage: "lock") }
                }
                .buttonStyle(.glass)
                .controlSize(.extraLarge)

                HStack(spacing: 5) {
                    Text("Press")
                    Text("esc")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.15), in: .rect(cornerRadius: 5))
                    Text("twice to skip the break")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
                .padding(.bottom, 56)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
        }
        .opacity(model.revealed ? 1 : 0)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let background {
            Image(nsImage: background)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var time: String {
        TimeFormat.clock(scheduler.breakRemaining)
    }
}
