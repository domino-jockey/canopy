import Foundation

enum TimeFormat {
    /// "19:42". Rounds to the nearest second: countdown values sit close to whole seconds,
    /// and tick timing wobbles slightly either side, so rounding up would freeze and then skip.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "00:03": two-digit minutes, like LookAway's heads-up.
    static func paddedClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// "20m": minutes left, rounded up so it only reaches "0m" when time's up.
    static func minutes(_ seconds: TimeInterval) -> String {
        "\(Int((max(0, seconds.rounded()) / 60).rounded(.up)))m"
    }
}
