import AppKit
import AVFoundation

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
    /// The engine playing a pitched-down sound, kept until it finishes.
    private static var pitchedEngine: AVAudioEngine?

    /// "Pitch down" lowers the break end sound by this many semitones.
    private static let pitchDownSemitones: Float = 5

    static func play(_ sound: Sound, settings: TimerSettings) {
        let (enabled, fileName) = switch sound {
        case .breakStart: (settings.breakSounds, settings.breakStartSound.fileName(end: false))
        case .breakEnd: (settings.breakSounds, settings.breakEndSound.fileName(end: true))
        case .reminder: (settings.reminderSounds, settings.reminderSound.fileName(end: false))
        case .alert: (settings.alertSounds, settings.alertSound.fileName(end: false))
        }
        guard enabled else { return }
        if sound == .breakEnd && settings.pitchDownBreakEnd && !settings.breakEndSound.hasEndVersion {
            return playPitchedDown(fileName, volume: Float(settings.soundVolume))
        }
        let player = playing[fileName] ?? NSSound(named: fileName)
        playing[fileName] = player
        player?.stop()
        player?.volume = Float(settings.soundVolume)
        player?.play()
    }

    /// NSSound can't change pitch, so this goes through an audio engine with a pitch effect.
    /// A new engine each time (it's cheap); it stops once the sound has played, so it doesn't keep audio running.
    private static func playPitchedDown(_ fileName: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url) else { return }
        pitchedEngine?.stop()
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        pitch.pitch = -pitchDownSemitones * 100 // in cents
        engine.attach(player)
        engine.attach(pitch)
        engine.connect(player, to: pitch, format: file.processingFormat)
        engine.connect(pitch, to: engine.mainMixerNode, format: file.processingFormat)
        player.volume = volume
        player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { _ in
            DispatchQueue.main.async {
                if pitchedEngine === engine {
                    engine.stop()
                    pitchedEngine = nil
                }
            }
        }
        guard (try? engine.start()) != nil else { return }
        player.play()
        pitchedEngine = engine
    }
}
