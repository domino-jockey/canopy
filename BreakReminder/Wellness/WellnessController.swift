import AppKit
import SwiftUI

/// Shows posture and blink reminders while you work. `update` runs every tick, after the scheduler's.
@MainActor
final class WellnessController {
    private let scheduler: BreakScheduler
    private var timer = WellnessTimer()
    private var lastTick: Date?
    private var lastCompletedBreaks = 0
    /// Windows of the flash on screen, one per display.
    private var windows: [NSWindow] = []

    private let flashLength: TimeInterval = 1.2

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
    }

    func update(idleSeconds: TimeInterval) {
        let now = Date.now
        let elapsed = lastTick.map { now.timeIntervalSince($0) } ?? 0
        lastTick = now
        let settings = scheduler.settings

        if scheduler.completedBreaks != lastCompletedBreaks {
            lastCompletedBreaks = scheduler.completedBreaks
            if settings.resetRemindersAfterBreak { timer.reset() }
        }

        // Count screen time only: working, at the Mac, and (unless allowed) not held by Smart Pause.
        // A long gap between ticks means the Mac slept.
        let counting = scheduler.state == .working && !scheduler.isOffHours
            && idleSeconds < settings.idlePauseAfter
            && (!scheduler.isSmartPaused || settings.remindersDuringSmartPause)
            && elapsed < 10
        guard counting, let due = timer.advance(by: elapsed, settings: settings) else { return }
        show(due)
    }

    /// Shows a reminder now, from the settings page's ▶ button.
    func preview(_ kind: WellnessKind) {
        show(kind)
    }

    private func show(_ kind: WellnessKind) {
        guard windows.isEmpty else { return }
        SoundPlayer.play(.reminder, settings: scheduler.settings)
        windows = NSScreen.screens.map { makeWindow(frame: $0.frame, content: WellnessFlash(kind: kind)) }
        present(for: flashLength)
    }

    /// Fades the windows in, keeps them up for `duration`, then fades them out.
    private func present(for duration: TimeInterval) {
        let shown = windows
        shown.forEach { $0.orderFrontRegardless() }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            shown.forEach { $0.animator().alphaValue = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                shown.forEach { $0.animator().alphaValue = 0 }
            } completionHandler: {
                MainActor.assumeIsolated {
                    shown.forEach { $0.close() }
                    self?.windows.removeAll { shown.contains($0) }
                }
            }
        }
    }

    /// A see-through, click-through window above other apps on every Space.
    private func makeWindow(frame: NSRect, content: some View) -> NSWindow {
        let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.alphaValue = 0
        if scheduler.settings.hideRemindersFromRecordings { window.sharingType = .none }
        window.contentView = NSHostingView(rootView: content)
        window.setFrame(frame, display: false)
        return window
    }
}
