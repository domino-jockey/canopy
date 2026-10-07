import Foundation
import Observation

enum BreakKind: Equatable {
    case short, long
}

/// Why Smart Pause is holding the timer.
enum SmartPauseReason: Equatable {
    case meeting
    case focusApp(name: String)
    case focusMode
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
    private(set) var settings: TimerSettings
    private(set) var state: TimerState = .stopped
    /// Active seconds left before the next break.
    private(set) var workRemaining: TimeInterval
    /// Full length of the current break.
    private(set) var breakDuration: TimeInterval = 0
    /// Seconds left in the current break.
    private(set) var breakRemaining: TimeInterval = 0
    /// Breaks taken or skipped since starting. Decides when a long break is due.
    private(set) var completedBreaks = 0
    /// Snoozes used on the upcoming break.
    private(set) var snoozesUsed = 0
    /// Screen time since the last break actually taken. Skips and snoozes don't reset it.
    /// Counts while paused too: pausing the timer doesn't mean you've stepped away.
    private(set) var timeSinceBreak: TimeInterval = 0

    /// What Smart Pause detected on the last tick. Nil when nothing is holding the timer.
    private(set) var smartPauseReason: SmartPauseReason?
    /// After Smart Pause ends, the timer waits until this time before counting again.
    private(set) var smartPauseCooldownEnds: Date?
    /// Goes up by one each time the user comes back after being away long enough to reset the cycle.
    /// The alerts controller watches it to show "Welcome back".
    private(set) var returnsFromIdle = 0
    /// The user has been away long enough to reset, and hasn't come back yet.
    @ObservationIgnored private var isAway = false
    /// How long a due break has waited for the user to stop typing.
    @ObservationIgnored private var heldForTyping: TimeInterval = 0

    /// Skips used today. Saved to disk so restarting the app doesn't reset the daily limit.
    private var dailySkips: DailySkips

    @ObservationIgnored private var lastTick: Date?
    @ObservationIgnored private let defaults: UserDefaults

    /// Ticks normally arrive every second. A bigger gap means the Mac was asleep.
    private let maxTickGap: TimeInterval = 10
    /// A due break waits until there's been no typing or dragging for this long...
    static let typingPause: TimeInterval = 2
    /// ...but never longer than this, so typing can't dodge a break forever.
    static let maxTypingHold: TimeInterval = 30
    /// The overtime nudge comes back this often while breaks keep being dodged.
    static let overtimeRepeat: TimeInterval = 15 * 60

    init(settings: TimerSettings = .load(), defaults: UserDefaults = .standard) {
        self.settings = settings
        self.defaults = defaults
        self.workRemaining = settings.workInterval
        self.dailySkips = DailySkips.load(from: defaults)
    }

    var nextBreakKind: BreakKind {
        (completedBreaks + 1) % settings.longBreakEvery == 0 ? .long : .short
    }

    // MARK: - Rules

    var isOnBreak: Bool {
        if case .onBreak = state { true } else { false }
    }

    /// Seconds into the current break.
    var breakElapsed: TimeInterval {
        breakDuration - breakRemaining
    }

    /// The countdown has finished, but "hold until End Break" is keeping the break up.
    var isWaitingForEndBreak: Bool {
        isOnBreak && breakRemaining <= 0
    }

    /// Balanced mode: Skip unlocks halfway through the break.
    var balancedSkipDelay: TimeInterval {
        breakDuration / 2
    }

    var canSkip: Bool {
        guard isOnBreak, !isWaitingForEndBreak, skipsLeftToday != 0 else { return false }
        switch settings.enforcement {
        case .casual: return true
        case .balanced: return breakElapsed >= balancedSkipDelay
        case .hardcore: return false
        }
    }

    var canSkipNextBreak: Bool {
        (state == .working || state == .paused) && settings.enforcement != .hardcore && skipsLeftToday != 0
    }

    /// Nil means no limit.
    var skipsLeftToday: Int? {
        settings.maxSkipsPerDay.map { max(0, $0 - skipsUsedToday) }
    }

    private var skipsUsedToday: Int {
        dailySkips.day == today ? dailySkips.count : 0
    }

    /// Based on the last tick, so tests with fake times get fake days.
    private var today: Date {
        Calendar.current.startOfDay(for: lastTick ?? .now)
    }

    /// Which overtime nudge is due: 0 once screen time passes the break interval, then 1, 2…
    /// every 15 minutes. Nil while you're within your break interval.
    var overtimeStep: Int? {
        guard timeSinceBreak > settings.workInterval else { return nil }
        return Int((timeSinceBreak - settings.workInterval) / Self.overtimeRepeat)
    }

    /// Smart Pause is holding the timer: something was detected, or the cooldown after it hasn't passed.
    var isSmartPaused: Bool {
        isSmartPaused(at: lastTick ?? .now)
    }

    private func isSmartPaused(at time: Date) -> Bool {
        smartPauseReason != nil || smartPauseCooldownEnds.map { time < $0 } == true
    }

    /// The work countdown is running: working, and not held by Smart Pause.
    var isCountingDown: Bool {
        state == .working && !isSmartPaused
    }

    var canEndEarly: Bool {
        isWaitingForEndBreak || (isOnBreak && settings.allowEndingEarly && breakRemaining <= breakDuration / 4)
    }

    /// Nil means no limit.
    var snoozesLeft: Int? {
        settings.maxSnoozesPerBreak.map { max(0, $0 - snoozesUsed) }
    }

    var canSnooze: Bool {
        switch state {
        case .stopped: false
        // Snoozing a break that's on screen is a skip in disguise.
        case .onBreak: settings.enforcement != .hardcore && !isWaitingForEndBreak && snoozesLeft != 0
        case .working, .paused: snoozesLeft != 0
        }
    }

    // MARK: - Clock

    /// - Parameters:
    ///   - idleSeconds: since the last input of any kind.
    ///   - typingIdleSeconds: since the last key press or mouse drag.
    ///   - smartPause: what Smart Pause detects right now, if anything.
    func tick(now: Date, idleSeconds: TimeInterval, typingIdleSeconds: TimeInterval = .infinity,
              smartPause: SmartPauseReason? = nil) {
        defer { lastTick = now }
        let elapsed = lastTick.map { now.timeIntervalSince($0) } ?? 0
        // Time spent asleep counts as time away, the same as being idle.
        let awaySeconds = max(idleSeconds, elapsed > maxTickGap ? elapsed : 0)

        if smartPause == nil && smartPauseReason != nil {
            smartPauseCooldownEnds = now + settings.smartPauseCooldown
        }
        smartPauseReason = smartPause

        switch state {
        case .working:
            if awaySeconds >= settings.idleResetAfter {
                resetWork()
                timeSinceBreak = 0
                isAway = true
            } else if awaySeconds < settings.idlePauseAfter {
                if isAway {
                    isAway = false
                    returnsFromIdle += 1
                }
                timeSinceBreak += elapsed
                // Smart Pause holds the countdown, like pausing does.
                guard !isSmartPaused(at: now) else { break }
                workRemaining -= elapsed
                if workRemaining <= 0 { breakDue(elapsed: elapsed, typingIdleSeconds: typingIdleSeconds) }
            }
        case .paused:
            if awaySeconds >= settings.idleResetAfter {
                timeSinceBreak = 0
            } else if awaySeconds < settings.idlePauseAfter {
                timeSinceBreak += elapsed
            }
        case .onBreak:
            breakRemaining = max(0, breakRemaining - elapsed)
            if breakRemaining <= 0 && !settings.holdUntilEndBreak { endBreak(taken: true) }
        case .stopped:
            break
        }
    }

    // MARK: - Actions

    /// Saves new settings. A new break interval restarts the countdown; other changes
    /// (like break length) take effect from the next break.
    func apply(_ newSettings: TimerSettings) {
        let intervalChanged = newSettings.workInterval != settings.workInterval
        settings = newSettings
        settings.save(to: defaults)
        if intervalChanged && (state == .working || state == .paused) {
            workRemaining = settings.workInterval
        }
    }

    func start() {
        guard state == .stopped else { return }
        completedBreaks = 0
        timeSinceBreak = 0
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
        guard canSkipNextBreak else { return }
        recordSkip()
        completedBreaks += 1
        resetWork()
    }

    /// While working: push the next break back. During a break: end it and bring it back in `minutes`.
    func snooze(minutes: Int) {
        guard canSnooze else { return }
        let delay = TimeInterval(minutes * 60)
        if isOnBreak {
            workRemaining = delay
            state = .working
        } else {
            workRemaining += delay
        }
        snoozesUsed += 1
    }

    /// Skip the break that's on screen, if the enforcement mode allows it.
    func skipBreak() {
        guard canSkip else { return }
        recordSkip()
        endBreak(taken: false)
    }

    /// End Break button: near the end of a break, or when holding until End Break.
    func endBreakEarly() {
        guard canEndEarly else { return }
        endBreak(taken: true)
    }

    /// Ends the break in any mode, Hardcore included. Triggered by holding Esc.
    func emergencySkip() {
        guard isOnBreak else { return }
        endBreak(taken: false)
    }

    // MARK: - Helpers

    /// Starts the break, unless "hold off while typing" says to wait for a pause in typing first.
    private func breakDue(elapsed: TimeInterval, typingIdleSeconds: TimeInterval) {
        if settings.holdOffWhileTyping && typingIdleSeconds < Self.typingPause && heldForTyping < Self.maxTypingHold {
            heldForTyping += elapsed
            return
        }
        beginBreak()
    }

    private func beginBreak() {
        heldForTyping = 0
        breakDuration = nextBreakKind == .long ? settings.longBreakDuration : settings.shortBreakDuration
        breakRemaining = breakDuration
        state = .onBreak(nextBreakKind)
    }

    /// `taken` is false when the break was skipped, so it doesn't reset `timeSinceBreak`.
    private func endBreak(taken: Bool) {
        if taken { timeSinceBreak = 0 }
        completedBreaks += 1
        resetWork()
        state = .working
    }

    private func resetWork() {
        workRemaining = settings.workInterval
        snoozesUsed = 0
    }

    private func recordSkip() {
        dailySkips = DailySkips(day: today, count: skipsUsedToday + 1)
        dailySkips.save(to: defaults)
    }
}

private struct DailySkips: Codable, Equatable {
    var day: Date
    var count: Int

    private static let key = "dailySkips"

    static func load(from defaults: UserDefaults) -> DailySkips {
        guard let data = defaults.data(forKey: key),
              let skips = try? JSONDecoder().decode(DailySkips.self, from: data)
        else { return DailySkips(day: .distantPast, count: 0) }
        return skips
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try! JSONEncoder().encode(self), forKey: Self.key)
    }
}
