import Foundation

/// Office hours for one day of the week. Times are minutes after midnight.
struct DayHours: Codable, Equatable {
    var on: Bool
    var start: Int
    var end: Int
}

/// A break at a fixed time every day, like lunch.
struct PlannedBreak: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    /// Minutes after midnight.
    var time: Int
    var duration: TimeInterval
}

/// Clock-time rules: office hours, and spotting when a set time of day has just passed.
enum DaySchedule {
    /// Minutes after midnight, in the Mac's time zone.
    static func minutes(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return parts.hour! * 60 + parts.minute!
    }

    static func isWorkingHours(_ date: Date, settings: TimerSettings) -> Bool {
        guard settings.officeHoursEnabled else { return true }
        let day = settings.officeHours[Calendar.current.component(.weekday, from: date) - 1]
        let now = minutes(of: date)
        return day.on && day.start <= now && now < day.end
    }

    /// True when `minute` (after midnight) on `to`'s day falls after `from` and at or before `to`.
    /// Called with consecutive ticks, so it's true exactly once as the time passes.
    static func passed(_ minute: Int, from: Date, to: Date) -> Bool {
        let target = Calendar.current.startOfDay(for: to) + TimeInterval(minute * 60)
        return from < target && target <= to
    }

    /// "9:00 AM": a time of day for showing in the settings.
    static func date(forMinutes minute: Int) -> Date {
        Calendar.current.startOfDay(for: .now) + TimeInterval(minute * 60)
    }
}
