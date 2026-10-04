import Foundation

enum TimeFormat {
    /// "19:42". Rounds to the nearest second: countdown values sit close to whole seconds,
    /// and tick timing wobbles slightly either side, so rounding up would freeze and then skip.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
