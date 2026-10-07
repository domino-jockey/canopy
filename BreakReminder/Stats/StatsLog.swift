import Foundation

/// One day's numbers.
struct DayStats: Codable, Equatable {
    var taken = 0
    var skipped = 0
    var snoozed = 0
}

/// A small daily log of breaks taken, skipped and snoozed, saved on disk.
struct StatsLog: Codable, Equatable {
    enum Event {
        case taken, skipped, snoozed
    }

    /// Keyed by day, "2026-10-07".
    private(set) var days: [String: DayStats] = [:]

    private static let key = "stats"
    /// Older days are dropped so the log stays small.
    private static let keepDays = 120

    mutating func record(_ event: Event, on date: Date) {
        var day = days[Self.dayKey(date)] ?? DayStats()
        switch event {
        case .taken: day.taken += 1
        case .skipped: day.skipped += 1
        case .snoozed: day.snoozed += 1
        }
        days[Self.dayKey(date)] = day
        let oldest = Self.dayKey(Calendar.current.date(byAdding: .day, value: -Self.keepDays, to: date)!)
        days = days.filter { $0.key >= oldest }
    }

    func day(_ date: Date) -> DayStats {
        days[Self.dayKey(date)] ?? DayStats()
    }

    /// The last `count` days, oldest first, ending with `today`.
    func lastDays(_ count: Int, from today: Date) -> [(date: Date, stats: DayStats)] {
        (0..<count).reversed().map { back in
            let date = Calendar.current.date(byAdding: .day, value: -back, to: Calendar.current.startOfDay(for: today))!
            return (date, day(date))
        }
    }

    /// Days in a row with at least `goal` breaks taken. Today counts once it reaches the goal;
    /// until then the streak runs up to yesterday, so it doesn't drop to 0 every morning.
    func streak(goal: Int, today: Date) -> Int {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: today)
        if day(date).taken < goal { date = calendar.date(byAdding: .day, value: -1, to: date)! }
        var count = 0
        while day(date).taken >= goal {
            count += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func load(from defaults: UserDefaults) -> StatsLog {
        guard let data = defaults.data(forKey: key),
              let log = try? JSONDecoder().decode(StatsLog.self, from: data)
        else { return StatsLog() }
        return log
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try! JSONEncoder().encode(self), forKey: Self.key)
    }
}
