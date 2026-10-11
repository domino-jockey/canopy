import SwiftUI

struct SoundsSettingsPage: View {
    let scheduler: BreakScheduler

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section {
                Toggle("Break sounds", isOn: settings.breakSounds)
                Group {
                    soundPicker("Break starts", settings.breakStartSound, play: .breakStart)
                    soundPicker("Break ends", settings.breakEndSound, play: .breakEnd)
                }
                .disabled(!scheduler.settings.breakSounds)
            }

            Section {
                Toggle("Reminder sounds", isOn: settings.reminderSounds)
                soundPicker("Sound", settings.reminderSound, play: .reminder)
                    .disabled(!scheduler.settings.reminderSounds)
            } footer: {
                Text("For posture and blink reminders.")
            }

            Section {
                Toggle("Alert sounds", isOn: settings.alertSounds)
                soundPicker("Sound", settings.alertSound, play: .alert)
                    .disabled(!scheduler.settings.alertSounds)
            } footer: {
                Text("For alert pills, like the heads-up before a break. Sounds from BreakTimer and Stretchly.")
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

    /// A menu of sounds that plays the one you pick, like System Settings' alert sound, plus ▶ to hear it again.
    private func soundPicker(_ title: String, _ selection: Binding<SoundChoice>, play sound: SoundPlayer.Sound) -> some View {
        HStack {
            Picker(title, selection: selection) {
                ForEach(SoundChoice.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .onChange(of: selection.wrappedValue) { SoundPlayer.play(sound, settings: scheduler.settings) }
            Button("Play", systemImage: "play.circle") { SoundPlayer.play(sound, settings: scheduler.settings) }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
        }
    }
}
