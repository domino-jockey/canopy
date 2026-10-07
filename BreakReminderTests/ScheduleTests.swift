import Foundation
import Testing
@testable import BreakReminder

@MainActor
struct ScheduleTests {
    /// A Wednesday at the given local time.
    private func wednesday(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: hour, minute: minute))!
    }

    /// A clock whose ticks start at `start` (its first tick is a long gap, so it counts as time away).
    private func clock(at start: Date, _ change: (inout TimerSettings) -> Void) -> FakeClock {
        var settings = TimerSettings()
        change(&settings)
        let clock = FakeClock(settings: settings)
        clock.now = start
        clock.sleep(seconds: 0)
        return clock
    }

    @Test func officeHoursRule() {
        var settings = TimerSettings()
        #expect(DaySchedule.isWorkingHours(wednesday(22), settings: settings)) // off: always working hours
        settings.officeHoursEnabled = true
        #expect(DaySchedule.isWorkingHours(wednesday(9), settings: settings))
        #expect(!DaySchedule.isWorkingHours(wednesday(17), settings: settings))
        #expect(!DaySchedule.isWorkingHours(wednesday(8, 59), settings: settings))
        let sunday = Calendar.current.date(byAdding: .day, value: 4, to: wednesday(10))!
        #expect(!DaySchedule.isWorkingHours(sunday, settings: settings))
    }

    @Test func timerSleepsOutsideOfficeHours() {
        let clock = clock(at: wednesday(16, 59)) { $0.officeHoursEnabled = true }
        clock.run(seconds: 60)
        #expect(clock.scheduler.workRemaining == 20 * 60 - 59)
        clock.run(seconds: 30 * 60)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.workRemaining == 20 * 60 - 59)
        #expect(clock.scheduler.isOffHours)
        #expect(!clock.scheduler.isCountingDown)
    }

    @Test func plannedBreakStartsOnTime() {
        let clock = clock(at: wednesday(12, 29)) {
            $0.plannedBreaks = [PlannedBreak(name: "Lunch", time: 12 * 60 + 30, duration: 45 * 60)]
        }
        clock.run(seconds: 59)
        #expect(clock.scheduler.state == .working)
        clock.run(seconds: 1)
        #expect(clock.scheduler.state == .onBreak(.long))
        #expect(clock.scheduler.plannedBreakName == "Lunch")
        #expect(clock.scheduler.breakRemaining == 45 * 60)
    }

    @Test func plannedBreakDoesntMoveTheCycle() {
        let clock = clock(at: wednesday(12, 29)) {
            $0.plannedBreaks = [PlannedBreak(name: "Lunch", time: 12 * 60 + 30, duration: 5 * 60)]
        }
        clock.run(seconds: 60 + 5 * 60)
        #expect(clock.scheduler.state == .working)
        #expect(clock.scheduler.completedBreaks == 0)
        #expect(clock.scheduler.plannedBreakName == nil)
    }

    @Test func plannedBreakMissedWhileAsleepDoesntFire() {
        let clock = clock(at: wednesday(12)) {
            $0.plannedBreaks = [PlannedBreak(name: "Lunch", time: 12 * 60 + 30, duration: 45 * 60)]
        }
        clock.sleep(seconds: 3600)
        #expect(clock.scheduler.state == .working)
    }

    @Test func clockOutFiresOnceAtItsTime() {
        let clock = clock(at: wednesday(17, 59)) { $0.clockOutEnabled = true }
        clock.run(seconds: 59)
        #expect(clock.scheduler.clockOuts == 0)
        clock.run(seconds: 120)
        #expect(clock.scheduler.clockOuts == 1)
    }

    @Test func scheduleSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.officeHoursEnabled = true
        settings.officeHours[0] = DayHours(on: true, start: 600, end: 720)
        settings.plannedBreaks = [PlannedBreak(name: "Walk", time: 900, duration: 600)]
        settings.clockOutEnabled = true
        settings.clockOutMessage = "Go home"
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }
}
