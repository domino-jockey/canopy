import AppKit
import SwiftUI

struct BreakScreenSettingsPage: View {
    let scheduler: BreakScheduler

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    var body: some View {
        Form {
            Section("Look") {
                Picker("Background", selection: settings.breakBackground) {
                    Text("Blurred wallpaper").tag(BreakBackground.wallpaper)
                    Text("Picture").tag(BreakBackground.image)
                    Text("Gradient").tag(BreakBackground.gradient)
                }
                if scheduler.settings.breakBackground == .image {
                    LabeledContent("Picture") {
                        HStack {
                            Text(scheduler.settings.backgroundImagePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "None")
                                .foregroundStyle(.secondary)
                            Button("Choose…", action: chooseImage)
                        }
                    }
                }
                Toggle("Show the time at the top", isOn: settings.showClockOnBreak)
            }

            Section {
                Toggle("Show an exercise on each break", isOn: settings.showExercises)
                if scheduler.settings.showExercises {
                    exerciseList("Short breaks", BreakMessages.shortExercises)
                    exerciseList("Long breaks", BreakMessages.longExercises)
                }
            } header: {
                Text("Exercises")
            } footer: {
                Text("Short breaks get quick eye and neck exercises, long breaks get ones that get you up. Turn off any you don't like.")
            }

            Section {
                ForEach(scheduler.settings.customMessages.indices, id: \.self) { index in
                    HStack {
                        TextField("Message", text: settings.customMessages[index], prompt: Text("Drink some water"))
                            .labelsHidden()
                        Button("Remove", systemImage: "minus.circle.fill") {
                            settings.wrappedValue.customMessages.remove(at: index)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(Mocha.overlay1)
                    }
                }
                Button("Add Message", systemImage: "plus") {
                    settings.wrappedValue.customMessages.append("")
                }
            } header: {
                Text("My messages")
            } footer: {
                Text("Mixed in with the exercises (or the built-in messages) on every break.")
            }
        }
    }

    private func exerciseList(_ title: String, _ exercises: [BreakMessage]) -> some View {
        DisclosureGroup(title) {
            ForEach(exercises, id: \.title) { exercise in
                Toggle(isOn: Binding(
                    get: { !scheduler.settings.disabledExercises.contains(exercise.title) },
                    set: { on in
                        if on {
                            settings.wrappedValue.disabledExercises.remove(exercise.title)
                        } else {
                            settings.wrappedValue.disabledExercises.insert(exercise.title)
                        }
                    }
                )) {
                    Label {
                        VStack(alignment: .leading) {
                            Text(exercise.title)
                            Text(exercise.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: exercise.symbol ?? "figure.walk").foregroundStyle(.tint)
                    }
                }
            }
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.wrappedValue.backgroundImagePath = url.path
    }
}
