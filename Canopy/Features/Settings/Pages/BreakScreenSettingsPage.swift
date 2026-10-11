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
            }

            Section {
                Toggle("Show an exercise on each break", isOn: settings.showExercises)
                if scheduler.settings.showExercises {
                    builtInList("Short breaks", BreakMessages.shortExercises)
                    builtInList("Long breaks", BreakMessages.longExercises)
                } else {
                    builtInList("Short breaks", BreakMessages.short)
                    builtInList("Long breaks", BreakMessages.long)
                }
            } header: {
                Text("Built-in")
            } footer: {
                Text(scheduler.settings.showExercises
                     ? "Short breaks get quick eye and neck exercises, long breaks get ones that get you up. Turn off any you don't like."
                     : "Plain messages instead of exercises. Turn off any you don't like.")
            }

            ownMessages("My short-break messages", settings.customShortMessages)
            ownMessages("My long-break messages", settings.customLongMessages)
        }
    }

    /// The user's own messages for one kind of break, mixed in with the built-in ones.
    private func ownMessages(_ title: String, _ messages: Binding<[BreakMessage]>) -> some View {
        Section {
            ForEach(messages.wrappedValue.indices, id: \.self) { index in
                HStack {
                    VStack {
                        TextField("Title", text: messages[index].title, prompt: Text("Drink some water"))
                        TextField("Instructions", text: messages[index].subtitle, prompt: Text("Instructions (optional)"))
                    }
                    .labelsHidden()
                    Button("Remove", systemImage: "minus.circle.fill") {
                        messages.wrappedValue.remove(at: index)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            Button("Add Exercise or Message", systemImage: "plus") {
                messages.wrappedValue.append(BreakMessage(title: "", subtitle: ""))
            }
        } header: {
            Text(title)
        } footer: {
            Text("Mixed in with the built-in ones. Instructions show below the title.")
        }
    }

    /// Built-in exercises or messages, each with a switch.
    private func builtInList(_ title: String, _ items: [BreakMessage]) -> some View {
        DisclosureGroup(title) {
            ForEach(items, id: \.title) { item in
                Toggle(isOn: Binding(
                    get: { !scheduler.settings.disabledExercises.contains(item.title) },
                    set: { on in
                        if on {
                            settings.wrappedValue.disabledExercises.remove(item.title)
                        } else {
                            settings.wrappedValue.disabledExercises.insert(item.title)
                        }
                    }
                )) {
                    let text = VStack(alignment: .leading) {
                        Text(item.title)
                        Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    if let symbol = item.symbol {
                        Label { text } icon: { Image(systemName: symbol).foregroundStyle(.tint) }
                    } else {
                        text
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
