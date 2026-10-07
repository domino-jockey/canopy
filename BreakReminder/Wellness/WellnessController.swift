import AppKit
import SwiftUI

/// Shows posture and blink reminders while you work. `update` runs every tick, after the scheduler's.
@MainActor
final class WellnessController {
    private let scheduler: BreakScheduler
    private var timer = WellnessTimer()
    private var lastTick: Date?
    private var lastCompletedBreaks = 0
    /// Windows of the reminder on screen (the bubble plus dimming, or the flash on every display).
    private var windows: [NSWindow] = []

    private let bubbleLength: TimeInterval = 4
    private let flashLength: TimeInterval = 1.2
    /// Space between a bubble and the screen edge.
    private let margin: CGFloat = 40

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
        let settings = scheduler.settings
        let reminder = settings.reminder(kind)
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.screens[0]
        SoundPlayer.play(.reminder, settings: settings)

        switch reminder.style {
        case .bubble:
            if settings.dimForReminders {
                windows += NSScreen.screens.map { makeWindow(frame: $0.frame, content: Mocha.crust.opacity(0.3)) }
            }
            let size = reminder.size.diameter + 40 // room for the shadow and the bounce
            windows.append(makeWindow(frame: bubbleFrame(size: size, at: reminder.position, on: screen),
                                      content: WellnessBubble(kind: kind, diameter: reminder.size.diameter)))
            present(for: bubbleLength)
        case .flash:
            windows = NSScreen.screens.map { makeWindow(frame: $0.frame, content: WellnessFlash(kind: kind)) }
            present(for: flashLength)
        }
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

    private func bubbleFrame(size: CGFloat, at position: GridPosition, on screen: NSScreen) -> NSRect {
        let area = screen.visibleFrame.insetBy(dx: margin, dy: margin)
        let x = area.minX + (area.width - size) * CGFloat(position.column) / 2
        // Row 0 is the top, but screen coordinates count up from the bottom.
        let y = area.maxY - size - (area.height - size) * CGFloat(position.row) / 2
        return NSRect(x: x, y: y, width: size, height: size)
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
