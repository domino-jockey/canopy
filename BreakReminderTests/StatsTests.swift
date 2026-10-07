import Foundation
import Testing
@testable import BreakReminder

@MainActor
struct StatsTests {
    private let wednesday = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: wednesday)!
    }

    @Test func schedulerRecordsTakenSkippedSnoozed() {
        let clock = FakeClock()
        clock.run(seconds: 20 * 60 + 20) // one break taken
        clock.scheduler.snooze(minutes: 1)
        clock.scheduler.skipNextBreak()
        let today = clock.scheduler.stats.day(clock.now)
        #expect(today == DayStats(taken: 1, skipped: 1, snoozed: 1))
    }

    @Test func statsSurviveRestart() {
        let defaults = FakeClock.cleanDefaults()
        let clock = FakeClock(defaults: defaults)
        clock.run(seconds: 20 * 60 + 20)
        let restarted = BreakScheduler(settings: TimerSettings(), defaults: defaults)
        #expect(restarted.stats.day(clock.now).taken == 1)
    }

    @Test func lastSevenDaysOldestFirst() {
        var log = StatsLog()
        log.record(.taken, on: day(-6))
        log.record(.taken, on: day(0))
        log.record(.taken, on: day(0))
        let week = log.lastDays(7, from: wednesday)
        #expect(week.count == 7)
        #expect(week.map(\.stats.taken) == [1, 0, 0, 0, 0, 0, 2])
        #expect(week.last!.date == Calendar.current.startOfDay(for: wednesday))
    }

    @Test func streakCountsDaysAtGoal() {
        var log = StatsLog()
        for offset in [-3, -2, -1] {
            for _ in 0..<2 { log.record(.taken, on: day(offset)) }
        }
        // Today hasn't reached the goal yet: the streak runs up to yesterday.
        log.record(.taken, on: day(0))
        #expect(log.streak(goal: 2, today: wednesday) == 3)
        log.record(.taken, on: day(0))
        #expect(log.streak(goal: 2, today: wednesday) == 4)
        #expect(log.streak(goal: 3, today: wednesday) == 0)
    }

    @Test func gapBreaksStreak() {
        var log = StatsLog()
        log.record(.taken, on: day(-3))
        log.record(.taken, on: day(-1))
        #expect(log.streak(goal: 1, today: wednesday) == 1)
    }

    @Test func oldDaysAreDropped() {
        var log = StatsLog()
        log.record(.taken, on: day(-200))
        log.record(.taken, on: day(0))
        #expect(log.days.count == 1)
    }
}
