import SwiftUI

/// The icon + countdown shown in the menu bar.
struct MenuBarLabel: View {
    let scheduler: BreakScheduler

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            if let time {
                Text(time)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
        }
        .font(.body)
        .animation(.default, value: time)
        .padding(.horizontal, 8)
        .fixedSize()
    }

    // Breaks aren't shown here: the break screen covers the menu bar.
    private var symbol: String {
        scheduler.state == .paused ? "pause.circle" : "timer"
    }

    private var time: String? {
        scheduler.state == .stopped ? nil : TimeFormat.clock(scheduler.workRemaining)
    }
}
