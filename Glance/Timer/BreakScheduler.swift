import Foundation
import Observation

enum BreakKind: Equatable {
    case short, long
}

enum TimerState: Equatable {
    case stopped
    case working
    case onBreak(BreakKind)
    case paused
}

/// The break cycle's brain. It has no clock of its own: the app calls `tick`
/// about once a second with the current time and how long the user has been idle.
/// Tests call `tick` with fake times instead.
@MainActor @Observable
final class BreakScheduler {
    var settings: TimerSettings
    private(set) var state: TimerState = .stopped
    /// Active seconds left before the next break.
    private(set) var workRemaining: TimeInterval
    /// Seconds left in the current break.
    private(set) var breakRemaining: TimeInterval = 0
    /// Breaks taken or skipped since starting. Decides when a long break is due.
    private(set) var completedBreaks = 0
    /// Snoozes used on the upcoming break. Phase 4 puts a limit on this.
    private(set) var snoozesUsed = 0

    @ObservationIgnored private var lastTick: Date?

    /// Ticks normally arrive every second. A bigger gap means the Mac was asleep.
    private let maxTickGap: TimeInterval = 10

    init(settings: TimerSettings = .load()) {
        self.settings = settings
        self.workRemaining = settings.workInterval
    }

    var nextBreakKind: BreakKind {
        (completedBreaks + 1) % settings.longBreakEvery == 0 ? .long : .short
    }

    // MARK: - Clock

    func tick(now: Date, idleSeconds: TimeInterval) {
        defer { lastTick = now }
        let elapsed = lastTick.map { now.timeIntervalSince($0) } ?? 0
        // Time spent asleep counts as time away, the same as being idle.
        let awaySeconds = max(idleSeconds, elapsed > maxTickGap ? elapsed : 0)

        switch state {
        case .working:
            if awaySeconds >= settings.idleResetAfter {
                resetWork()
            } else if awaySeconds < settings.idlePauseAfter {
                workRemaining -= elapsed
                if workRemaining <= 0 { beginBreak() }
            }
        case .onBreak:
            breakRemaining -= elapsed
            if breakRemaining <= 0 { endBreak() }
        case .stopped, .paused:
            break
        }
    }

    // MARK: - Actions

    func start() {
        guard state == .stopped else { return }
        completedBreaks = 0
        resetWork()
        state = .working
    }

    func stop() {
        state = .stopped
    }

    func pause() {
        guard state == .working else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .working
    }

    func startBreakNow() {
        guard state == .working || state == .paused else { return }
        beginBreak()
    }

    func skipNextBreak() {
        guard state == .working || state == .paused else { return }
        completedBreaks += 1
        resetWork()
    }

    /// While working: push the next break back. During a break: end it and bring it back in `minutes`.
    func snooze(minutes: Int) {
        let delay = TimeInterval(minutes * 60)
        switch state {
        case .working, .paused:
            workRemaining += delay
        case .onBreak:
            workRemaining = delay
            state = .working
        case .stopped:
            return
        }
        snoozesUsed += 1
    }

    /// Ends the current break, whether it ran out or was skipped.
    func endBreak() {
        guard case .onBreak = state else { return }
        completedBreaks += 1
        resetWork()
        state = .working
    }

    // MARK: - Helpers

    private func beginBreak() {
        let kind = nextBreakKind
        breakRemaining = kind == .long ? settings.longBreakDuration : settings.shortBreakDuration
        state = .onBreak(kind)
    }

    private func resetWork() {
        workRemaining = settings.workInterval
        snoozesUsed = 0
    }
}
