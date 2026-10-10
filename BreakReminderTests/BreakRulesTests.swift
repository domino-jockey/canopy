import Testing
@testable import Canopy

@MainActor
struct BreakRulesTests {
    /// A clock that's already 1 second into a 20-second short break.
    private func onBreak(_ change: (inout TimerSettings) -> Void = { _ in }) -> FakeClock {
        var settings = TimerSettings()
        change(&settings)
        let clock = FakeClock(settings: settings)
        clock.scheduler.startBreakNow()
        clock.run(seconds: 1)
        return clock
    }

    // MARK: - Enforcement

    @Test func casualSkipsRightAway() {
        let clock = onBreak { $0.enforcement = .casual }
        clock.scheduler.skipBreak()
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 1)
    }

    @Test func balancedSkipUnlocksHalfwayThroughBreak() {
        let clock = onBreak()
        clock.run(seconds: 8)
        clock.scheduler.skipBreak()
        #expect(clock.scheduler.state == .onBreak(.short))
        clock.run(seconds: 1)
        #expect(clock.scheduler.canSkip)
        clock.scheduler.skipBreak()
        #expect(clock.scheduler.state == .working)
    }

    @Test func hardcoreBlocksEverySkip() {
        let clock = onBreak { $0.enforcement = .hardcore }
        clock.run(seconds: 10)
        clock.scheduler.skipBreak()
        clock.scheduler.snooze(minutes: 5)
        #expect(clock.scheduler.state == .onBreak(.short))
        clock.run(seconds: 9)
        #expect(clock.scheduler.state == .working)
        clock.scheduler.skipNextBreak()
        #expect(clock.scheduler.completedBreaks == 1)
    }

    @Test func emergencySkipWorksInHardcore() {
        let clock = onBreak { $0.enforcement = .hardcore }
        clock.scheduler.emergencySkip()
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 1)
    }

    @Test func emergencySkipOnlyDuringBreak() {
        let clock = FakeClock()
        clock.run(seconds: 10)
        clock.scheduler.emergencySkip()
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 0)
        #expect(clock.scheduler.workRemaining == 20 * 60 - 10)
    }

    @Test func emergencySkipIgnoresDailyLimit() {
        let clock = onBreak { $0.maxSkipsPerDay = 0 }
        #expect(!clock.scheduler.canSkip)
        clock.scheduler.emergencySkip()
        #expect(clock.scheduler.state == .working)
    }

    // MARK: - Daily skip limit

    @Test func dailyLimitCountsBothKindsOfSkip() {
        var settings = TimerSettings()
        settings.enforcement = .casual
        let clock = FakeClock(settings: settings)
        clock.scheduler.skipNextBreak()
        clock.scheduler.skipNextBreak()
        clock.scheduler.startBreakNow()
        clock.scheduler.skipBreak()
        #expect(clock.scheduler.skipsLeftToday == 0)
        #expect(!clock.scheduler.canSkipNextBreak)
        clock.scheduler.startBreakNow()
        #expect(!clock.scheduler.canSkip)
        clock.scheduler.skipBreak()
        #expect(clock.scheduler.state == .onBreak(.long))
    }

    @Test func dailyLimitResetsNextDay() {
        let clock = FakeClock()
        for _ in 0..<3 { clock.scheduler.skipNextBreak() }
        #expect(clock.scheduler.skipsLeftToday == 0)
        clock.sleep(seconds: 24 * 60 * 60)
        #expect(clock.scheduler.skipsLeftToday == 3)
        #expect(clock.scheduler.canSkipNextBreak)
    }

    @Test func dailyLimitSurvivesRestart() {
        let defaults = FakeClock.cleanDefaults()
        let first = FakeClock(defaults: defaults)
        first.scheduler.skipNextBreak()
        let restarted = FakeClock(defaults: defaults)
        #expect(restarted.scheduler.skipsLeftToday == 2)
    }

    @Test func noDailyLimit() {
        let clock = FakeClock(settings: { var s = TimerSettings(); s.maxSkipsPerDay = nil; return s }())
        for _ in 0..<10 { clock.scheduler.skipNextBreak() }
        #expect(clock.scheduler.completedBreaks == 10)
        #expect(clock.scheduler.skipsLeftToday == nil)
    }

    // MARK: - Snooze limit

    @Test func snoozeLimitStopsThirdSnooze() {
        let clock = FakeClock()
        clock.scheduler.snooze(minutes: 1)
        clock.scheduler.snooze(minutes: 1)
        clock.scheduler.snooze(minutes: 1)
        #expect(clock.scheduler.workRemaining == 22 * 60)
        #expect(clock.scheduler.snoozesLeft == 0)
        #expect(!clock.scheduler.canSnooze)
    }

    @Test func snoozeLimitResetsAfterBreak() {
        let clock = FakeClock()
        clock.scheduler.snooze(minutes: 1)
        clock.scheduler.snooze(minutes: 1)
        clock.run(seconds: 22 * 60 + 20)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.canSnooze)
    }

    @Test func noSnoozeLimit() {
        var settings = TimerSettings()
        settings.maxSnoozesPerBreak = nil
        let clock = FakeClock(settings: settings)
        for _ in 0..<5 { clock.scheduler.snooze(minutes: 1) }
        #expect(clock.scheduler.workRemaining == 25 * 60)
        #expect(clock.scheduler.snoozesLeft == nil)
    }

    // MARK: - Ending early

    @Test func endEarlyIsOffByDefault() {
        let clock = onBreak()
        clock.run(seconds: 17)
        clock.scheduler.endBreakEarly()
        #expect(clock.scheduler.state == .onBreak(.short))
    }

    @Test func endEarlyOnlyInLastQuarter() {
        let clock = onBreak { $0.allowEndingEarly = true }
        clock.run(seconds: 9)
        clock.scheduler.endBreakEarly()
        #expect(clock.scheduler.state == .onBreak(.short))
        clock.run(seconds: 5)
        clock.scheduler.endBreakEarly()
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 1)
    }

    // MARK: - Hold until End Break

    @Test func holdKeepsBreakUpUntilEndBreak() {
        let clock = onBreak { $0.holdUntilEndBreak = true }
        clock.run(seconds: 60)
        #expect(clock.scheduler.state == .onBreak(.short))
        #expect(clock.scheduler.isWaitingForEndBreak)
        #expect(!clock.scheduler.canSkip)
        #expect(!clock.scheduler.canSnooze)
        clock.scheduler.endBreakEarly()
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.workRemaining == 20 * 60)
    }
}
