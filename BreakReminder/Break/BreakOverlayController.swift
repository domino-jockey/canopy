import AppKit
import Observation
import SwiftUI

/// Shows the full-screen break window on every display while the scheduler is on a break.
@MainActor
final class BreakOverlayController {
    private let scheduler: BreakScheduler
    private var windows: [NSWindow] = []
    private var model: OverlayModel?
    private var keyMonitor: Any?
    private var lastEscape: Date?
    /// The last few letters typed on the break screen, to spot "emergency".
    private var typed = ""
    private var activationObserver: NSObjectProtocol?

    private let blurInDuration = 0.4
    private let revealDuration = 0.6
    private let emergencyWord = "emergency"

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        observeState()
        // When another app comes to the front during a break (e.g. after unlocking), take the keyboard back.
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.takeFocus() }
        }
    }

    /// Re-runs `stateChanged` whenever the scheduler's state changes, so a break
    /// started from the menu shows immediately instead of on the next tick.
    private func observeState() {
        withObservationTracking {
            _ = scheduler.state
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.stateChanged()
                self?.observeState()
            }
        }
    }

    private func stateChanged() {
        if case .onBreak(let kind) = scheduler.state {
            if windows.isEmpty { show(kind: kind) }
        } else if !windows.isEmpty {
            hide()
        }
    }

    /// Keeps the break screen's copy of the scheduler's values up to date while the break is on.
    /// Once the break ends it stops, so the screen fades out showing exactly what it last showed.
    private func observeDisplay(_ model: OverlayModel) {
        let display = withObservationTracking {
            BreakDisplay(scheduler)
        } onChange: { [weak self, weak model] in
            Task { @MainActor in
                guard let self, let model, self.model === model, self.scheduler.isOnBreak else { return }
                self.observeDisplay(model)
            }
        }
        // Switching to "Break's over" changes the text and buttons; animate it instead of snapping.
        if display.isWaitingForEndBreak != model.display.isWaitingForEndBreak {
            withAnimation(.easeInOut(duration: 0.6)) { model.display = display }
        } else {
            model.display = display
        }
    }

    // MARK: - Show / hide

    private func show(kind: BreakKind) {
        let model = OverlayModel(display: BreakDisplay(scheduler))
        let message = BreakMessages.random(for: kind)
        self.model = model
        observeDisplay(model)
        windows = NSScreen.screens.map { makeWindow(on: $0, model: model, message: message) }

        takeFocus()
        if scheduler.settings.lockOnBreakStart { Self.lockScreen() }
        typed = ""
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { self?.keyPressed(event) }
            return nil // the break screen swallows all typing
        }

        // Stage 1: live blur of the screen fades in. Stage 2: wallpaper and text fade in.
        let shown = windows
        NSAnimationContext.runAnimationGroup { context in
            context.duration = blurInDuration
            shown.forEach { $0.animator().alphaValue = 1 }
        } completionHandler: { [revealDuration] in
            MainActor.assumeIsolated {
                withAnimation(.easeInOut(duration: revealDuration)) { model.revealed = true }
            }
        }
    }

    private func hide() {
        let closing = windows
        let model = self.model
        windows = []
        self.model = nil
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil

        // Reverse order: wallpaper and text fade out, then the blur.
        withAnimation(.easeInOut(duration: blurInDuration)) {
            model?.revealed = false
        } completion: { [blurInDuration] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = blurInDuration
                closing.forEach { $0.animator().alphaValue = 0 }
            } completionHandler: {
                MainActor.assumeIsolated { closing.forEach { $0.close() } }
            }
        }
    }

    private func makeWindow(on screen: NSScreen, model: OverlayModel, message: BreakMessage) -> NSWindow {
        let window = OverlayWindow(
            contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        window.hidesOnDeactivate = false
        window.setFrame(screen.frame, display: false)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.alphaValue = 0

        // Blurs whatever is behind the window, live. No Screen Recording permission needed.
        let blur = NSVisualEffectView()
        blur.material = .fullScreenUI
        blur.blendingMode = .behindWindow
        blur.state = .active

        let content = NSHostingView(rootView: BreakView(
            model: model,
            message: message,
            background: WallpaperBlur.image(for: screen),
            onSkip: { [weak self] in self?.scheduler.skipBreak() },
            onEndEarly: { [weak self] in self?.scheduler.endBreakEarly() },
            onSnooze: { [weak self] in self?.scheduler.snooze(minutes: $0) },
            onLock: { Self.lockScreen() }
        ))
        content.frame = blur.bounds
        content.autoresizingMask = [.width, .height]
        blur.addSubview(content)
        window.contentView = blur

        window.orderFrontRegardless()
        return window
    }

    /// Gives the break window the keyboard, so its buttons look enabled and Esc reaches it.
    /// The window is a non-activating panel, so this works without BreakReminder becoming the active app.
    private func takeFocus() {
        windows.first?.makeKey()
    }

    // MARK: - Actions

    private func keyPressed(_ event: NSEvent) {
        guard !event.isARepeat else { return } // holding a key sends repeats; only count real presses
        if event.keyCode == 53 { // Esc
            escapePressed()
        } else {
            letterTyped(event.charactersIgnoringModifiers?.lowercased() ?? "")
        }
    }

    /// Typing "emergency" skips the break in any mode, Hardcore included.
    private func letterTyped(_ letter: String) {
        typed = String((typed + letter).suffix(emergencyWord.count))
        // How much of "emergency" the user has typed so far, e.g. "emer" → 4.
        let matched = (0...emergencyWord.count).last { typed.hasSuffix(emergencyWord.prefix($0)) } ?? 0
        model?.emergencyTyped = matched
        if matched == emergencyWord.count {
            typed = ""
            scheduler.emergencySkip()
        }
    }

    private func escapePressed() {
        let now = Date.now
        if let lastEscape, now.timeIntervalSince(lastEscape) < 1 {
            self.lastEscape = nil
            switch scheduler.settings.escapeAction {
            case .skip: scheduler.skipBreak()
            case .snooze: scheduler.snooze(minutes: 5)
            case .nothing: break
            }
        } else {
            lastEscape = now
        }
    }

    /// Locks the Mac using the same undocumented function as ⌃⌘Q. If a future macOS removes it,
    /// falls back to turning the display off (which locks only if the password is required immediately).
    private static func lockScreen() {
        let login = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        if let symbol = dlsym(login, "SACLockScreenImmediate") {
            typealias LockFunction = @convention(c) () -> Int32
            _ = unsafeBitCast(symbol, to: LockFunction.self)()
            return
        }
        let pmset = Process()
        pmset.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        pmset.arguments = ["displaysleepnow"]
        try? pmset.run()
    }
}

/// Borderless windows can't take keyboard input by default. This one needs to, for Esc.
private final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { true }
}
