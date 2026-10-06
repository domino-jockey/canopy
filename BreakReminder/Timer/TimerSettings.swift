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
        // "No limit" (nil) is saved by leaving the key out, so a missing key means nil here.
        maxSnoozesPerBreak = try? container.decode(Int.self, forKey: .maxSnoozesPerBreak)
        maxSkipsPerDay = try? container.decode(Int.self, forKey: .maxSkipsPerDay)
    }
}
