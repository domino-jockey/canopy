import Foundation

/// How hard it is to skip a break that's on screen.
enum EnforcementMode: String, Codable {
    /// Skip works right away.
    case casual
    /// Skip unlocks a few seconds into the break.
    case balanced
    /// No skipping.
    case hardcore
}

enum EscapeAction: String, Codable {
    case skip, snooze, nothing
}

/// What the menu bar item shows while Live Status is on.
enum MenuBarDisplay: String, Codable {
    case iconAndText, textOnly
}

enum TimerStyle: String, Codable {
    /// "19:42"
    case clock
    /// "20m"
    case minutes
}

/// What's behind the break screen's text.
enum BreakBackground: String, Codable {
    /// The screen's own wallpaper, blurred.
    case wallpaper
    /// A picture the user picked.
    case image
    /// A Mocha gradient.
    case gradient
}

/// Where alert pills appear along the top of the screen.
enum AlertPosition: String, Codable {
    case topLeft, topCenter, topRight
}

enum WellnessKind: CaseIterable {
    case posture, blink
}

/// LookAway's glossy bubble, or DeskRest's brief screen flash.
enum ReminderStyle: String, Codable {
    case bubble, flash
}

enum ReminderSize: String, Codable {
    case small, medium, large
}

/// One cell of a 3×3 grid on the screen. Row 0 is the top, column 0 the left.
struct GridPosition: Codable, Equatable, Hashable {
    var row: Int
    var column: Int

    static let center = GridPosition(row: 1, column: 1)
}

/// A posture or blink reminder's settings.
struct WellnessReminder: Codable, Equatable {
    var enabled = false
    var interval: TimeInterval
    var style = ReminderStyle.bubble
    var size = ReminderSize.large
    var position = GridPosition.center
}

/// An app picked as a "deep focus" app.
struct FocusApp: Codable, Equatable, Hashable {
    var bundleID: String
    var name: String
}

/// The numbers and rules that drive the break cycle. All durations are in seconds.
struct TimerSettings: Codable, Equatable {
    var workInterval: TimeInterval = 20 * 60
    var shortBreakDuration: TimeInterval = 20
    var longBreakDuration: TimeInterval = 3 * 60
    var longBreakEvery = 4
    /// No input for this long and work time stops counting.
    var idlePauseAfter: TimeInterval = 2 * 60
    /// No input for this long counts as a break taken: the cycle restarts.
    var idleResetAfter: TimeInterval = 5 * 60

    var enforcement = EnforcementMode.balanced
    /// Nil means no limit.
    var maxSnoozesPerBreak: Int? = 2
    /// Skipping a break on screen and "Skip next break" both count. Nil means no limit.
    var maxSkipsPerDay: Int? = 3
    /// What pressing Esc twice on the break screen does.
    var escapeAction = EscapeAction.skip
    /// Show an End Break button in the last quarter of a break.
    var allowEndingEarly = false
    /// When the countdown ends, keep the break screen up until End Break is pressed.
    var holdUntilEndBreak = false
    var lockOnBreakStart = false

    /// Show the countdown in the menu bar. Off leaves just the icon.
    var showLiveStatus = true
    var menuBarDisplay = MenuBarDisplay.iconAndText
    var timerStyle = TimerStyle.clock

    var alertPosition = AlertPosition.topCenter
    /// Heads-up pill: appears this many seconds before a break and stays until it starts.
    var showHeadsUp = true
    var headsUpSeconds: TimeInterval = 10
    /// Pill next to the mouse pointer for the last few seconds before a break.
    var showCountdown = true
    var countdownSeconds: TimeInterval = 5
    /// "45 minutes without a break" when breaks are skipped or snoozed past.
    var showOvertimeNudge = true
    var overtimeWhenPaused = false
    /// Small pill when Smart Pause starts holding the timer, and when the timer resumes.
    var showSmartPauseAlerts = true

    /// A due break waits for a pause in typing or dragging (up to 30 s).
    var holdOffWhileTyping = true
    /// Smart Pause: microphone or camera in use.
    var pauseForMeetings = true
    var pauseForFocusApps = true
    /// Apps that pause the timer while they're in front.
    var focusApps: [FocusApp] = []
    /// Smart Pause: a macOS Focus (like Do Not Disturb) is on.
    var pauseForFocusMode = false
    /// After Smart Pause ends, wait this long before the timer counts again.
    var smartPauseCooldown: TimeInterval = 60
    /// "Welcome back" pill after being away long enough to reset the cycle.
    var showWelcomeBack = true

    var posture = WellnessReminder(interval: 10 * 60)
    var blink = WellnessReminder(interval: 5 * 60)
    /// Darken the screen a little while a bubble reminder shows.
    var dimForReminders = true
    var remindersDuringSmartPause = false
    /// Screen recordings and screen sharing don't see the reminders.
    var hideRemindersFromRecordings = true
    /// A break restarts both reminders' countdowns.
    var resetRemindersAfterBreak = true

    /// Gong when a break starts and ends.
    var breakSounds = true
    /// Blip for posture/blink reminders and alert pills.
    var reminderSounds = true
    /// 0 to 1.
    var soundVolume = 0.6

    /// Outside office hours the timer sleeps: no countdown, no breaks, no reminders.
    var officeHoursEnabled = false
    /// One per weekday, Sunday first (matching `Calendar`'s weekday numbers minus 1). Weekdays 9 to 5.
    var officeHours = (0..<7).map { DayHours(on: (1...5).contains($0), start: 9 * 60, end: 17 * 60) }
    var plannedBreaks: [PlannedBreak] = []
    /// At this time of day, a full-screen "time to stop" with a personal message.
    var clockOutEnabled = false
    var clockOutTime = 18 * 60
    var clockOutMessage = "Close the laptop. The rest can wait until tomorrow."

    var breakBackground = BreakBackground.wallpaper
    /// File path of the picture for `.image`.
    var backgroundImagePath: String?
    var showClockOnBreak = true
    /// Breaks show an exercise instead of a plain message.
    var showExercises = true
    /// Titles of built-in exercises turned off.
    var disabledExercises: Set<String> = []
    /// The user's own break messages, added to the mix. One line each.
    var customMessages: [String] = []

    /// Breaks taken in a day to keep the streak going.
    var dailyBreakGoal = 8

    func reminder(_ kind: WellnessKind) -> WellnessReminder {
        kind == .posture ? posture : blink
    }

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

extension TimerSettings {
    /// Reads each field on its own, so saved data from an older version (missing a newer
    /// field) keeps its other values instead of failing to load and resetting everything.
    init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, into value: inout T) {
            if let saved = try? container.decode(T.self, forKey: key) { value = saved }
        }
        read(.workInterval, into: &workInterval)
        read(.shortBreakDuration, into: &shortBreakDuration)
        read(.longBreakDuration, into: &longBreakDuration)
        read(.longBreakEvery, into: &longBreakEvery)
        read(.idlePauseAfter, into: &idlePauseAfter)
        read(.idleResetAfter, into: &idleResetAfter)
        read(.enforcement, into: &enforcement)
        read(.escapeAction, into: &escapeAction)
        read(.allowEndingEarly, into: &allowEndingEarly)
        read(.holdUntilEndBreak, into: &holdUntilEndBreak)
        read(.lockOnBreakStart, into: &lockOnBreakStart)
        read(.showLiveStatus, into: &showLiveStatus)
        read(.menuBarDisplay, into: &menuBarDisplay)
        read(.timerStyle, into: &timerStyle)
        read(.alertPosition, into: &alertPosition)
        read(.showHeadsUp, into: &showHeadsUp)
        read(.headsUpSeconds, into: &headsUpSeconds)
        read(.showCountdown, into: &showCountdown)
        read(.countdownSeconds, into: &countdownSeconds)
        read(.showOvertimeNudge, into: &showOvertimeNudge)
        read(.overtimeWhenPaused, into: &overtimeWhenPaused)
        read(.showSmartPauseAlerts, into: &showSmartPauseAlerts)
        read(.holdOffWhileTyping, into: &holdOffWhileTyping)
        read(.pauseForMeetings, into: &pauseForMeetings)
        read(.pauseForFocusApps, into: &pauseForFocusApps)
        read(.focusApps, into: &focusApps)
        read(.pauseForFocusMode, into: &pauseForFocusMode)
        read(.smartPauseCooldown, into: &smartPauseCooldown)
        read(.showWelcomeBack, into: &showWelcomeBack)
        read(.posture, into: &posture)
        read(.blink, into: &blink)
        read(.dimForReminders, into: &dimForReminders)
        read(.remindersDuringSmartPause, into: &remindersDuringSmartPause)
        read(.hideRemindersFromRecordings, into: &hideRemindersFromRecordings)
        read(.resetRemindersAfterBreak, into: &resetRemindersAfterBreak)
        read(.breakSounds, into: &breakSounds)
        read(.reminderSounds, into: &reminderSounds)
        read(.soundVolume, into: &soundVolume)
        read(.officeHoursEnabled, into: &officeHoursEnabled)
        read(.officeHours, into: &officeHours)
        read(.plannedBreaks, into: &plannedBreaks)
        read(.clockOutEnabled, into: &clockOutEnabled)
        read(.clockOutTime, into: &clockOutTime)
        read(.clockOutMessage, into: &clockOutMessage)
        read(.breakBackground, into: &breakBackground)
        read(.showClockOnBreak, into: &showClockOnBreak)
        read(.showExercises, into: &showExercises)
        read(.disabledExercises, into: &disabledExercises)
        read(.customMessages, into: &customMessages)
        read(.dailyBreakGoal, into: &dailyBreakGoal)
        backgroundImagePath = try? container.decode(String.self, forKey: .backgroundImagePath)
        // "No limit" (nil) is saved by leaving the key out, so a missing key means nil here.
        maxSnoozesPerBreak = try? container.decode(Int.self, forKey: .maxSnoozesPerBreak)
        maxSkipsPerDay = try? container.decode(Int.self, forKey: .maxSkipsPerDay)
    }
}
