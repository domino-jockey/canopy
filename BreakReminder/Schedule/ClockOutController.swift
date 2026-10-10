import AppKit
import SwiftUI

/// The full-screen "time to stop" at the Clock Out time. `update` runs every tick.
@MainActor
final class ClockOutController {
    private let scheduler: BreakScheduler
    private var lastClockOuts = 0
    private var windows: [NSWindow] = []

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
    }

    func update() {
        guard scheduler.clockOuts != lastClockOuts else { return }
        lastClockOuts = scheduler.clockOuts
        show()
    }

    /// Also used by the settings page's Preview button.
    func show() {
        guard windows.isEmpty else { return }
        SoundPlayer.play(.breakEnd, settings: scheduler.settings)
        windows = NSScreen.screens.map(makeWindow)
        windows.first?.makeKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.6
            windows.forEach { $0.animator().alphaValue = 1 }
        }
    }

    private func close() {
        let closing = windows
        windows = []
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            closing.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            MainActor.assumeIsolated { closing.forEach { $0.close() } }
        }
    }

    private func makeWindow(on screen: NSScreen) -> NSWindow {
        let window = KeyablePanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: false)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.alphaValue = 0

        let blur = NSVisualEffectView()
        blur.material = .fullScreenUI
        blur.blendingMode = .behindWindow
        blur.state = .active
        let content = NSHostingView(rootView: ClockOutView(
            message: scheduler.settings.clockOutMessage,
            onDone: { [weak self] in
                self?.scheduler.stop()
                self?.close()
            },
            onKeepWorking: { [weak self] in self?.close() }
        ))
        content.autoresizingMask = [.width, .height]
        blur.addSubview(content)
        window.contentView = blur
        window.setFrame(screen.frame, display: false)
        content.frame = blur.bounds
        window.orderFrontRegardless()
        return window
    }
}

/// Borderless windows can't take clicks on buttons straight away without this.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private struct ClockOutView: View {
    let message: String
    let onDone: () -> Void
    let onKeepWorking: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("Time to clock out")
                    .font(.system(size: 64, weight: .bold))
                Text(message)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 700)
                HStack(spacing: 12) {
                    Button(action: onDone) { Label("Done for today", systemImage: "checkmark") }
                    Button(action: onKeepWorking) { Label("Keep working", systemImage: "arrow.uturn.backward") }
                }
                .buttonStyle(.glass)
                .controlSize(.extraLarge)
                .padding(.top, 28)
                Text("Done for today stops the break timer. Start it again from the menu bar.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.white)
        }
        .environment(\.colorScheme, .dark)
    }
}
