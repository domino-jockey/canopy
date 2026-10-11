import AppKit

/// Plays the app's sounds (the ones picked in settings) at the chosen volume.
@MainActor
enum SoundPlayer {
    enum Sound {
        case breakStart, breakEnd
        /// Posture/blink reminders.
        case reminder
        /// Alert pills.
        case alert
    }

    /// Kept so a sound isn't cut off when the next one starts.
    private static var playing: [String: NSSound] = [:]

    static func play(_ sound: Sound, settings: TimerSettings) {
        let (enabled, fileName) = switch sound {
        case .breakStart: (settings.breakSounds, settings.breakStartSound.fileName(end: false))
        case .breakEnd: (settings.breakSounds, settings.breakEndSound.fileName(end: true))
        case .reminder: (settings.reminderSounds, settings.reminderSound.fileName(end: false))
        case .alert: (settings.alertSounds, settings.alertSound.fileName(end: false))
        }
        guard enabled else { return }
        let player = playing[fileName] ?? NSSound(named: fileName)
        playing[fileName] = player
        player?.stop()
        player?.volume = Float(settings.soundVolume)
        player?.play()
    }
}
