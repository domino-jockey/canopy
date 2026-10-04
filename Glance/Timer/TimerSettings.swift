import Foundation

/// The numbers that drive the break cycle. All durations are in seconds.
struct TimerSettings: Codable, Equatable {
    var workInterval: TimeInterval = 20 * 60
    var shortBreakDuration: TimeInterval = 20
    var longBreakDuration: TimeInterval = 3 * 60
    var longBreakEvery = 4
    /// No input for this long and work time stops counting.
    var idlePauseAfter: TimeInterval = 2 * 60
    /// No input for this long counts as a break taken: the cycle restarts.
    var idleResetAfter: TimeInterval = 5 * 60

    private static let key = "timerSettings"

    static func load(from defaults: UserDefaults = .standard) -> TimerSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(TimerSettings.self, from: data)
        else { return TimerSettings() }
        return settings
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(try! JSONEncoder().encode(self), forKey: Self.key)
    }
}
