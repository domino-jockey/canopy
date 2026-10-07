import KeyboardShortcuts
import SwiftUI

struct ShortcutsSettingsPage: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Pause or resume", name: .pauseResume)
                KeyboardShortcuts.Recorder("Start break now", name: .startBreakNow)
                KeyboardShortcuts.Recorder("Snooze upcoming break by 5 minutes", name: .snoozeFive)
            } footer: {
                Text("These work whichever app is in front. Click a box and press the keys you want.")
            }
        }
    }
}
