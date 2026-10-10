import Foundation
import Testing
@testable import BreakReminder

@MainActor
struct SmartPauseTests {
    @Test func smartPauseHoldsCountdown() {
        let clock = FakeClock()
        clock.run(seconds: 60)
        clock.run(seconds: 30 * 60, smartPause: .meeting)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.workRemaining == 19 * 60)
        #expect(clock.scheduler.isSmartPaused)
        #expect(!clock.scheduler.isCountingDown)
    }

    @Test func cooldownKeepsBreakAwayAfterSmartPauseEnds() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 - 10)
        clock.run(seconds: 5, smartPause: .meeting) // ends with 10 s left
        clock.run(seconds: 1)
        #expect(clock.scheduler.workRemaining == 59) // pushed back to the 1 minute cooldown, and counting
        #expect(!clock.scheduler.isSmartPaused)
        clock.run(seconds: 58)
        #expect(clock.scheduler.state == .working)
        clock.run(seconds: 2)
        #expect(clock.scheduler.isOnBreak)
    }

    @Test func cooldownDoesNothingWhenBreakIsFarAway() {
        let clock = FakeClock()
        clock.run(seconds: 5, smartPause: .focusApp(name: "Xcode"))
        clock.run(seconds: 60)
        #expect(clock.scheduler.workRemaining == 20 * 60 - 60) // countdown didn't stop
    }

    @Test func noCooldownWhenSetToNone() {
        var settings = TimerSettings()
        settings.smartPauseCooldown = 0
        let clock = FakeClock(settings: settings)
        clock.run(seconds: 5, smartPause: .meeting)
        clock.run(seconds: 10)
        #expect(clock.scheduler.workRemaining == 20 * 60 - 10)
    }

    @Test func smartPauseCountsTowardOvertime() {
        let clock = FakeClock()
        clock.run(seconds: 600, smartPause: .meeting)
        #expect(clock.scheduler.timeSinceBreak == 600)
    }

    @Test func dueBreakWaitsForPauseInTyping() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 + 5, typingIdle: 0.5)
        #expect(clock.scheduler.state == .working)
        clock.run(seconds: 1, typingIdle: 3)
        #expect(clock.scheduler.state == .onBreak(.short))
    }

    @Test func typingCantHoldBreakForever() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 + 31, typingIdle: 0.5)
        #expect(clock.scheduler.state == .onBreak(.short))
    }

    @Test func typingHoldCanBeTurnedOff() {
        var settings = TimerSettings()
        settings.holdOffWhileTyping = false
        let clock = FakeClock(settings: settings)
        clock.run(seconds: 20 * 60, typingIdle: 0.5)
        #expect(clock.scheduler.state == .onBreak(.short))
    }

    @Test func comingBackFromLongIdleCountsOnce() {
        let clock = FakeClock()
        clock.run(seconds: 60)
        clock.run(seconds: 10, idle: 6 * 60)
        #expect(clock.scheduler.returnsFromIdle == 0)
        clock.run(seconds: 5)
        #expect(clock.scheduler.returnsFromIdle == 1)
        clock.run(seconds: 5)
        #expect(clock.scheduler.returnsFromIdle == 1)
    }

    @Test func wakingFromSleepCountsAsReturn() {
        let clock = FakeClock()
        clock.sleep(seconds: 3600)
        clock.run(seconds: 1)
        #expect(clock.scheduler.returnsFromIdle == 1)
    }

    @Test func smartPauseSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.focusApps = [FocusApp(bundleID: "us.zoom.xos", name: "zoom.us")]
        settings.pauseForFocusMode = true
        settings.smartPauseCooldown = 120
        settings.holdOffWhileTyping = false
        settings.showWelcomeBack = false
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    @Test func focusLinksSetFocusState() {
        let before = SmartPauseMonitor.isFocusModeOn
        #expect(SmartPauseMonitor.handle(URL(string: "breakreminder://focus-on")!))
        #expect(SmartPauseMonitor.isFocusModeOn)
        #expect(SmartPauseMonitor.handle(URL(string: "breakreminder://focus-off")!))
        #expect(!SmartPauseMonitor.isFocusModeOn)
        #expect(!SmartPauseMonitor.handle(URL(string: "breakreminder://nonsense")!))
        SmartPauseMonitor.isFocusModeOn = before
    }
}
