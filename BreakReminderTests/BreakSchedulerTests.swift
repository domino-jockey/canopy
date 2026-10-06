import Foundation
import Testing
@testable import BreakReminder

/// Drives a scheduler with fake time, one tick per second.
@MainActor
final class FakeClock {
    let scheduler: BreakScheduler
    var now = Date(timeIntervalSinceReferenceDate: 0)

    /// Test-only storage (not the real app's), wiped for each new clock unless one is passed in.
    static func cleanDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "BreakReminderTests.scheduler")!
        defaults.removePersistentDomain(forName: "BreakReminderTests.scheduler")
        return defaults
    }

    init(settings: TimerSettings = TimerSettings(), defaults: UserDefaults = cleanDefaults()) {
        scheduler = BreakScheduler(settings: settings, defaults: defaults)
        scheduler.start()
        scheduler.tick(now: now, idleSeconds: 0)
    }

    func run(seconds: Int, idle: TimeInterval = 0) {
        for _ in 0..<seconds {
            now += 1
            scheduler.tick(now: now, idleSeconds: idle)
        }
    }

    /// Simulates the Mac sleeping: one tick after a long gap.
    func sleep(seconds: TimeInterval) {
        now += seconds
        scheduler.tick(now: now, idleSeconds: 0)
    }
}

@MainActor
struct BreakSchedulerTests {
    @Test func breakStartsAfterWorkInterval() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 - 1)
        #expect(clock.scheduler.state == .working)
        clock.run(seconds: 1)
        #expect(clock.scheduler.state == .onBreak(.short))
        #expect(clock.scheduler.breakRemaining == 20)
    }

    @Test func breakEndsAndWorkRestarts() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 + 20)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.workRemaining == 20 * 60)
        #expect(clock.scheduler.completedBreaks == 1)
    }

    @Test func everyFourthBreakIsLong() {
        let clock = FakeClock()
        clock.run(seconds: 3 * (20 * 60 + 20))
        #expect(clock.scheduler.completedBreaks == 3)
        clock.run(seconds: 20 * 60)
        #expect(clock.scheduler.state == .onBreak(.long))
        #expect(clock.scheduler.breakRemaining == 3 * 60)
    }

    @Test func idleStopsCounting() {
        let clock = FakeClock()
        clock.run(seconds: 600)
        clock.run(seconds: 120, idle: 150)
        #expect(clock.scheduler.workRemaining == 600)
    }

    @Test func longIdleResetsCycle() {
        let clock = FakeClock()
        clock.run(seconds: 600)
        clock.run(seconds: 1, idle: 5 * 60)
        #expect(clock.scheduler.workRemaining == 20 * 60)
        #expect(clock.scheduler.state == .working)
    }

    @Test func longSleepResetsCycle() {
        let clock = FakeClock()
        clock.run(seconds: 600)
        clock.sleep(seconds: 30 * 60)
        #expect(clock.scheduler.workRemaining == 20 * 60)
        #expect(clock.scheduler.state == .working)
    }

    @Test func shortSleepDoesNotCount() {
        let clock = FakeClock()
        clock.run(seconds: 600)
        clock.sleep(seconds: 3 * 60)
        #expect(clock.scheduler.workRemaining == 600)
    }

    @Test func pauseFreezesAndResumeContinues() {
        let clock = FakeClock()
        clock.run(seconds: 100)
        clock.scheduler.pause()
        clock.run(seconds: 500)
        #expect(clock.scheduler.state == .paused)
        #expect(clock.scheduler.workRemaining == 1100)
        clock.scheduler.resume()
        clock.run(seconds: 10)
        #expect(clock.scheduler.workRemaining == 1090)
    }

    @Test func snoozeWhileWorkingAddsTime() {
        let clock = FakeClock()
        clock.run(seconds: 1100)
        clock.scheduler.snooze(minutes: 5)
        #expect(clock.scheduler.workRemaining == 400)
        #expect(clock.scheduler.snoozesUsed == 1)
    }

    @Test func snoozeDuringBreakBringsItBack() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60)
        clock.scheduler.snooze(minutes: 1)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 0)
        clock.run(seconds: 60)
        #expect(clock.scheduler.state == .onBreak(.short))
        #expect(clock.scheduler.snoozesUsed == 1)
    }

    @Test func snoozesResetAfterBreak() {
        let clock = FakeClock()
        clock.scheduler.snooze(minutes: 1)
        clock.run(seconds: 21 * 60 + 20)
        #expect(clock.scheduler.snoozesUsed == 0)
    }

    @Test func skipNextBreakRestartsCycle() {
        let clock = FakeClock()
        clock.run(seconds: 500)
        clock.scheduler.skipNextBreak()
        #expect(clock.scheduler.workRemaining == 20 * 60)
        #expect(clock.scheduler.completedBreaks == 1)
    }

    @Test func startBreakNow() {
        let clock = FakeClock()
        clock.run(seconds: 10)
        clock.scheduler.startBreakNow()
        #expect(clock.scheduler.state == .onBreak(.short))
    }

    @Test func stopIgnoresTicks() {
        let clock = FakeClock()
        clock.scheduler.stop()
        clock.run(seconds: 30 * 60)
        #expect(clock.scheduler.state == .stopped)
    }

    @Test func settingsSaveAndLoad() {
        let defaults = UserDefaults(suiteName: "BreakReminderTests")!
        defaults.removePersistentDomain(forName: "BreakReminderTests")
        var settings = TimerSettings()
        settings.workInterval = 25 * 60
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    @Test func oldSavedSettingsKeepTheirValues() throws {
        // Saved by a version that had only these fields; maxSkipsPerDay was "No limit".
        let json = #"{"workInterval": 1500, "enforcement": "hardcore", "maxSnoozesPerBreak": 1}"#
        let settings = try JSONDecoder().decode(TimerSettings.self, from: Data(json.utf8))
        #expect(settings.workInterval == 25 * 60)
        #expect(settings.enforcement == .hardcore)
        #expect(settings.maxSnoozesPerBreak == 1)
        #expect(settings.maxSkipsPerDay == nil)
        #expect(settings.shortBreakDuration == TimerSettings().shortBreakDuration)
    }

    @Test func noLimitSurvivesSaveAndLoad() {
        let defaults = UserDefaults(suiteName: "BreakReminderTests")!
        defaults.removePersistentDomain(forName: "BreakReminderTests")
        var settings = TimerSettings()
        settings.maxSnoozesPerBreak = nil
        settings.maxSkipsPerDay = nil
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    @Test func menuBarStyleSurvivesSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.showLiveStatus = false
        settings.menuBarDisplay = .textOnly
        settings.timerStyle = .minutes
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    @Test func alertSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.alertPosition = .topRight
        settings.showHeadsUp = false
        settings.headsUpSeconds = 30
        settings.showCountdown = false
        settings.countdownSeconds = 3
        settings.showOvertimeNudge = false
        settings.overtimeWhenPaused = true
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    // MARK: - Overtime

    @Test func takenBreakResetsTimeSinceBreak() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 + 20)
        #expect(clock.scheduler.timeSinceBreak == 0)
        #expect(clock.scheduler.overtimeStep == nil)
    }

    @Test func skippedBreakStartsOvertime() {
        var settings = TimerSettings()
        settings.enforcement = .casual
        let clock = FakeClock(settings: settings)
        clock.run(seconds: 20 * 60)
        #expect(clock.scheduler.overtimeStep == nil) // exactly at the interval: the break is on screen
        clock.scheduler.skipBreak()
        clock.run(seconds: 1)
        #expect(clock.scheduler.overtimeStep == 0)
        clock.run(seconds: 15 * 60)
        #expect(clock.scheduler.overtimeStep == 1)
    }

    @Test func snoozingPastIntervalStartsOvertime() {
        let clock = FakeClock()
        clock.run(seconds: 19 * 60)
        clock.scheduler.snooze(minutes: 5)
        clock.run(seconds: 61)
        #expect(clock.scheduler.overtimeStep == 0)
    }

    @Test func timeSinceBreakCountsWhilePaused() {
        let clock = FakeClock()
        clock.run(seconds: 60)
        clock.scheduler.pause()
        clock.run(seconds: 60)
        #expect(clock.scheduler.timeSinceBreak == 120)
        #expect(clock.scheduler.workRemaining == 19 * 60)
    }

    @Test func longIdleResetsTimeSinceBreak() {
        let clock = FakeClock()
        clock.run(seconds: 60)
        clock.scheduler.pause()
        clock.run(seconds: 1, idle: 5 * 60)
        #expect(clock.scheduler.timeSinceBreak == 0)
    }

    @Test func applySavesAndRestartsCountdown() {
        let defaults = FakeClock.cleanDefaults()
        let clock = FakeClock(defaults: defaults)
        clock.run(seconds: 5 * 60)
        var settings = clock.scheduler.settings
        settings.workInterval = 30 * 60
        clock.scheduler.apply(settings)
        #expect(clock.scheduler.workRemaining == 30 * 60)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    @Test func breakLengthChangeKeepsCountdown() {
        let clock = FakeClock()
        clock.run(seconds: 5 * 60)
        var settings = clock.scheduler.settings
        settings.shortBreakDuration = 60
        clock.scheduler.apply(settings)
        #expect(clock.scheduler.workRemaining == 15 * 60)
        clock.run(seconds: 15 * 60)
        #expect(clock.scheduler.breakDuration == 60)
    }
}
