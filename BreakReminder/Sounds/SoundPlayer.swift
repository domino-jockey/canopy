import AppKit

/// A sound to pick in settings. BreakTimer's come in a start and an end version; Stretchly's are one file.
/// See CREDITS.md.
enum SoundChoice: String, Codable, CaseIterable {
    case gong, blip, bloop, ping, scifi, crystalGlass, windChime, ticToc

    var title: String {
        switch self {
        case .gong: "Gong"
        case .blip: "Blip"
        case .bloop: "Bloop"
        case .ping: "Ping"
        case .scifi: "Sci-fi"
        case .crystalGlass: "Crystal glass"
        case .windChime: "Wind chime"
        case .ticToc: "Tic-toc"
        }
    }

    /// The sound file's name in the app bundle.
    func fileName(end: Bool) -> String {
        switch self {
        case .gong, .blip, .bloop, .ping, .scifi: "\(rawValue)_\(end ? "end" : "start")"
        case .crystalGlass: "crystal_glass"
        case .windChime: "wind_chime"
        case .ticToc: "tic_toc"
        }
    }
}

/// Plays the app's sounds (the ones picked in settings) at the chosen volume.
@MainActor
enum SoundPlayer {
    enum Sound {
        case breakStart, breakEnd
        /// Posture/blink reminders and alert pills.
        case reminder
    }

    /// Kept so a sound isn't cut off when the next one starts.
    private static var playing: [String: NSSound] = [:]

    static func play(_ sound: Sound, settings: TimerSettings) {
        let (enabled, fileName) = switch sound {
        case .breakStart: (settings.breakSounds, settings.breakStartSound.fileName(end: false))
        case .breakEnd: (settings.breakSounds, settings.breakEndSound.fileName(end: true))
        case .reminder: (settings.reminderSounds, settings.reminderSound.fileName(end: false))
        }
        guard enabled else { return }
        let player = playing[fileName] ?? NSSound(named: fileName)
        playing[fileName] = player
        player?.stop()
        player?.volume = Float(settings.soundVolume)
        player?.play()
    }
}
