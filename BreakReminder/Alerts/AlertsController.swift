import AppKit

enum AlertKind {
    case headsUp, countdown, overtime, smartPause, welcomeBack
}

/// Decides when each alert pill shows. `update` runs every tick, right after the scheduler's.
@MainActor
final class AlertsController {
    private let scheduler: BreakScheduler
    private let model = AlertModel()
    private let headsUp: AlertPanel
    private let countdown: AlertPanel
    private let smartPause: AlertPanel
    private let welcomeBack: AlertPanel
    private lazy var overtime = AlertPanel(clickThrough: false, content: OvertimeAlert(model: model) { [unowned self] in
        overtimeOpen = false
        update()
    })

    /// The overtime step last seen, so each 15-minute step shows the nudge once.
    private var lastOvertimeStep: Int?
    /// Overtime nudge is up (until clicked, or a break starts).
    private var overtimeOpen = false
    /// A pill being previewed from settings, and when the preview ends.
    private var preview: (kind: AlertKind, ends: Date)?
    /// A short-lived pill (Smart Pause, welcome back) and when it goes away.
    private var flash: (kind: AlertKind, ends: Date)?
    private var wasSmartPaused = false
    private var lastReturnsFromIdle = 0
    /// Moves the countdown pill with the mouse while it's shown.
    private var followTimer: Timer?

    private let previewLength: TimeInterval = 5
    private let flashLength: TimeInterval = 4

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        headsUp = AlertPanel(clickThrough: false, content: HeadsUpAlert(
            model: model,
            onStart: { scheduler.startBreakNow() },
            onSnooze: { scheduler.snooze(minutes: $0) }
        ))
        countdown = AlertPanel(clickThrough: true, content: CountdownAlert(model: model))
        smartPause = AlertPanel(clickThrough: true, content: SmartPauseAlert(model: model))
        welcomeBack = AlertPanel(clickThrough: true, content: WelcomeBackAlert(model: model))
    }

    /// Shows one pill for a few seconds with sample values, from the settings page.
    func preview(_ kind: AlertKind) {
        preview = (kind, .now + previewLength)
        update()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + previewLength) { [weak self] in self?.update() }
    }

    func update() {
        let settings = scheduler.settings
        if let preview, preview.ends <= .now { self.preview = nil }
        let previewing = preview?.kind
        let working = scheduler.isCountingDown
        let paused = scheduler.state == .paused || scheduler.state == .working && scheduler.isSmartPaused
        let left = scheduler.workRemaining
        updateFlash()

        model.breakKind = scheduler.nextBreakKind
        model.canSnooze = scheduler.canSnooze
        switch previewing {
        case .headsUp: model.secondsToBreak = settings.headsUpSeconds
        case .countdown: model.secondsToBreak = settings.countdownSeconds
        case .overtime: model.minutesWithoutBreak = 45
        case .smartPause: model.smartPause = .meeting
        case .welcomeBack: model.secondsToBreak = settings.workInterval
        case nil:
            model.secondsToBreak = left
            model.minutesWithoutBreak = Int(scheduler.timeSinceBreak / 60)
            if flash?.kind == .smartPause { model.smartPause = scheduler.smartPauseReason }
        }

        // Heads-up and countdown: from N seconds before the break until it starts.
        set(headsUp, previewing == .headsUp || settings.showHeadsUp && working && left <= settings.headsUpSeconds)
        set(countdown, previewing == .countdown || settings.showCountdown && working && left <= settings.countdownSeconds)

        // Overtime: opens at each new 15-minute step, closes when clicked or a break starts.
        let step = scheduler.overtimeStep
        if step != lastOvertimeStep {
            lastOvertimeStep = step
            overtimeOpen = step != nil
        }
        if scheduler.isOnBreak { overtimeOpen = false }
        let overtimeAllowed = settings.showOvertimeNudge && (working || paused && settings.overtimeWhenPaused)

        // Short-lived pills: Smart Pause starting/ending, and welcome back.
        let flashing = previewing ?? (headsUp.isShown ? nil : flash?.kind)
        set(smartPause, flashing == .smartPause)
        set(welcomeBack, flashing == .welcomeBack)

        // All the top pills share one spot. Heads-up first, then the short-lived ones, then overtime.
        set(overtime, previewing == .overtime
            || overtimeOpen && overtimeAllowed && !headsUp.isShown && !smartPause.isShown && !welcomeBack.isShown)

        followCursor(countdown.isShown)
    }

    /// Starts a short-lived pill when Smart Pause starts or ends, or the user comes back from being away.
    private func updateFlash() {
        if let flash, flash.ends <= .now { self.flash = nil }
        let settings = scheduler.settings

        if scheduler.isSmartPaused != wasSmartPaused {
            wasSmartPaused = scheduler.isSmartPaused
            // Only worth mentioning while the timer would otherwise be counting.
            if settings.showSmartPauseAlerts && scheduler.state == .working {
                model.smartPause = scheduler.smartPauseReason
                flash = (.smartPause, .now + flashLength)
            }
        }
        if scheduler.returnsFromIdle != lastReturnsFromIdle {
            lastReturnsFromIdle = scheduler.returnsFromIdle
            if settings.showWelcomeBack { flash = (.welcomeBack, .now + flashLength) }
        }
    }

    private func set(_ panel: AlertPanel, _ visible: Bool) {
        guard visible else { return panel.hide() }
        if panel !== countdown { panel.moveToTop(scheduler.settings.alertPosition) }
        // The countdown pill sits alongside the heads-up, which already made a sound.
        if !panel.isShown && panel !== countdown { SoundPlayer.play(.reminder, settings: scheduler.settings) }
        panel.show()
    }

    private func followCursor(_ on: Bool) {
        guard on != (followTimer != nil) else { return }
        followTimer?.invalidate()
        followTimer = nil
        guard on else { return }
        countdown.moveNearCursor()
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.countdown.moveNearCursor() }
        }
        RunLoop.main.add(timer, forMode: .common)
        followTimer = timer
    }
}
