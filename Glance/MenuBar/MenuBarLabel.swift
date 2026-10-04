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

    private var symbol: String {
        switch scheduler.state {
        case .working, .stopped: "timer"
        case .onBreak: "cup.and.saucer.fill"
        case .paused: "pause.circle"
        }
    }

    private var time: String? {
        switch scheduler.state {
        case .working, .paused: TimeFormat.clock(scheduler.workRemaining)
        case .onBreak: TimeFormat.clock(scheduler.breakRemaining)
        case .stopped: nil
        }
    }
}
