import AppKit

enum AlertKind {
    case headsUp, countdown, overtime
}

/// Decides when each alert pill shows. `update` runs every tick, right after the scheduler's.
@MainActor
final class AlertsController {
    private let scheduler: BreakScheduler
    private let model = AlertModel()
    private let headsUp: AlertPanel
    private let countdown: AlertPanel
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
    /// Moves the countdown pill with the mouse while it's shown.
    private var followTimer: Timer?

    private let previewLength: TimeInterval = 5

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        headsUp = AlertPanel(clickThrough: false, content: HeadsUpAlert(
            model: model,
            onStart: { scheduler.startBreakNow() },
            onSnooze: { scheduler.snooze(minutes: $0) }
        ))
        countdown = AlertPanel(clickThrough: true, content: CountdownAlert(model: model))
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
        let working = scheduler.state == .working
        let left = scheduler.workRemaining

        model.breakKind = scheduler.nextBreakKind
        model.canSnooze = scheduler.canSnooze
        switch previewing {
        case .headsUp: model.secondsToBreak = settings.headsUpSeconds
        case .countdown: model.secondsToBreak = settings.countdownSeconds
        case .overtime: model.minutesWithoutBreak = 45
        case nil:
            model.secondsToBreak = left
            model.minutesWithoutBreak = Int(scheduler.timeSinceBreak / 60)
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
        let overtimeAllowed = settings.showOvertimeNudge
            && (working || scheduler.state == .paused && settings.overtimeWhenPaused)
        // The heads-up sits in the same spot and matters more, so it goes first.
        set(overtime, previewing == .overtime || overtimeOpen && overtimeAllowed && !headsUp.isShown)

        followCursor(countdown.isShown)
    }

    private func set(_ panel: AlertPanel, _ visible: Bool) {
        guard visible else { return panel.hide() }
        if panel !== countdown { panel.moveToTop(scheduler.settings.alertPosition) }
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
