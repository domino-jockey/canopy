import Foundation

enum TimeFormat {
    /// "19:42". Rounds up, so a countdown never shows "0:00" while time is left.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
