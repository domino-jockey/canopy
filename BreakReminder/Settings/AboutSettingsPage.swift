import SwiftUI

struct AboutSettingsPage: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "Version \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                    Text("Canopy").font(.title.weight(.bold))
                    Text(version).foregroundStyle(.secondary)
                    Text("A break reminder for your Mac, made for one person.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Credits") {
                credit("Sounds", "BreakTimer by Tom Watson (GPL-3.0)", "https://github.com/tom-james-watson/breaktimer-app")
                credit("Sounds", "Crystal glass by mlteenie (CC BY 3.0), wind chime by GnoteSoundz and tic-toc by magundah14 (CC0), via Stretchly",
                       "https://github.com/hovancik/stretchly")
                credit("Keyboard shortcuts", "KeyboardShortcuts by Sindre Sorhus (MIT)", "https://github.com/sindresorhus/KeyboardShortcuts")
                credit("Inspired by", "LookAway and DeskRest", "https://lookaway.com")
            }
        }
    }

    private func credit(_ title: String, _ detail: String, _ url: String) -> some View {
        LabeledContent(title) {
            Link(detail, destination: URL(string: url)!)
        }
    }
}
