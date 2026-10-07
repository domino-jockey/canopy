import SwiftUI

struct SoundsSettingsPage: View {
    let scheduler: BreakScheduler

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section {
                soundRow("Break sounds", isOn: settings.breakSounds, sample: .breakStart)
                soundRow("Reminder and alert sounds", isOn: settings.reminderSounds, sample: .reminder)
            } footer: {
                Text("Break sounds: a gong when a break starts and ends. Reminder sounds: a blip for posture and blink reminders and alert pills. Sounds from BreakTimer.")
            }

            Section("Volume") {
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: settings.soundVolume, in: 0...1) { editing in
                        // Play a sample when the slider is let go, so you hear the new volume.
                        if !editing { SoundPlayer.play(.breakStart, settings: scheduler.settings) }
                    }
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                }
            }
        }
    }

    private func soundRow(_ title: String, isOn: Binding<Bool>, sample: SoundPlayer.Sound) -> some View {
        HStack {
            Toggle(title, isOn: isOn)
            Button("Play", systemImage: "play.circle") { SoundPlayer.play(sample, settings: scheduler.settings) }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .disabled(!isOn.wrappedValue)
        }
    }
}
