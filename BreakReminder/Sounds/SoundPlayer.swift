import AppKit

/// Plays the app's few sounds (from BreakTimer, see CREDITS.md) at the chosen volume.
@MainActor
enum SoundPlayer {
    enum Sound: String {
        case breakStart = "gong_start"
        case breakEnd = "gong_end"
        /// Posture/blink reminders and alert pills.
        case reminder = "blip_start"

        var isBreakSound: Bool { self != .reminder }
    }

    /// Kept so a sound isn't cut off when the next one starts.
    private static var playing: [Sound: NSSound] = [:]

    static func play(_ sound: Sound, settings: TimerSettings) {
        guard sound.isBreakSound ? settings.breakSounds : settings.reminderSounds else { return }
        let player = playing[sound] ?? NSSound(named: sound.rawValue)
        playing[sound] = player
        player?.stop()
        player?.volume = Float(settings.soundVolume)
        player?.play()
    }
}
