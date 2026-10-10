import SwiftUI

/// A menu of fixed durations, like System Settings ("20 minutes ⌄"). Values are in seconds.
/// A saved value that isn't one of the options still shows, as an extra item.
struct DurationPicker: View {
    let title: String
    @Binding var value: TimeInterval
    let options: [TimeInterval]

    var body: some View {
        Picker(title, selection: $value) {
            ForEach(options.contains(value) ? options : (options + [value]).sorted(), id: \.self) { seconds in
                Text(Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
                    .tag(seconds)
            }
        }
    }
}
