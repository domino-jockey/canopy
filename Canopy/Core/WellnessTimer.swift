import Foundation

/// Counts screen time towards each wellness reminder, and says when one is due.
/// No clock of its own, like `BreakScheduler`, so tests can drive it.
struct WellnessTimer {
    private(set) var elapsed: [WellnessKind: TimeInterval] = [:]

    /// A reminder due within this long of another one shows with it, so two flashes don't come back to back.
    static let mergeWindow: TimeInterval = 60

    /// Adds `seconds` of screen time. Returns the reminder to show now, if any.
    /// If both are due at once (or one is due within `mergeWindow`), posture shows and blink starts over.
    mutating func advance(by seconds: TimeInterval, settings: TimerSettings) -> WellnessKind? {
        var due: WellnessKind?
        for kind in WellnessKind.allCases {
            let reminder = settings.reminder(kind)
            let total = reminder.enabled ? (elapsed[kind] ?? 0) + seconds : 0
            elapsed[kind] = total
            if reminder.enabled && total >= reminder.interval { due = due ?? kind }
        }
        guard let due else { return nil }
        for kind in WellnessKind.allCases {
            let reminder = settings.reminder(kind)
            if reminder.enabled && (elapsed[kind] ?? 0) + Self.mergeWindow >= reminder.interval { elapsed[kind] = 0 }
        }
        return due
    }

    mutating func reset() {
        elapsed = [:]
    }
}
