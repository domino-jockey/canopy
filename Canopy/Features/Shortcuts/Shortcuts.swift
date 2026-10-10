import KeyboardShortcuts

/// The three global shortcuts. The KeyboardShortcuts package saves what the user records.
extension KeyboardShortcuts.Name {
    static let pauseResume = Self("pauseResume")
    static let startBreakNow = Self("startBreakNow")
    static let snoozeFive = Self("snoozeFive")
}

@MainActor
enum Shortcuts {
    /// Runs each action when its shortcut is pressed, whichever app is in front.
    static func listen(scheduler: BreakScheduler, after: @escaping @MainActor () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .pauseResume) {
            scheduler.state == .paused ? scheduler.resume() : scheduler.pause()
            after()
        }
        KeyboardShortcuts.onKeyUp(for: .startBreakNow) {
            scheduler.startBreakNow()
            after()
        }
        KeyboardShortcuts.onKeyUp(for: .snoozeFive) {
            scheduler.snooze(minutes: 5)
            after()
        }
    }
}
