import Foundation

/// Counts screen time towards each wellness reminder, and says when one is due.
/// No clock of its own, like `BreakScheduler`, so tests can drive it.
struct WellnessTimer {
    private(set) var elapsed: [WellnessKind: TimeInterval] = [:]

    /// Adds `seconds` of screen time. Returns the reminder to show now, if any.
    /// If both are due at once, posture shows and blink starts over (one bubble at a time).
    mutating func advance(by seconds: TimeInterval, settings: TimerSettings) -> WellnessKind? {
        var due: WellnessKind?
        for kind in WellnessKind.allCases {
            let reminder = settings.reminder(kind)
            let total = reminder.enabled ? (elapsed[kind] ?? 0) + seconds : 0
            if reminder.enabled && total >= reminder.interval {
                due = due ?? kind
                elapsed[kind] = 0
            } else {
                elapsed[kind] = total
            }
        }
        return due
    }

    mutating func reset() {
        elapsed = [:]
    }
}
