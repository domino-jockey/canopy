import SwiftUI

/// The icon + countdown shown in the menu bar. What's shown follows the Live Status settings.
struct MenuBarLabel: View {
    let scheduler: BreakScheduler

    private var settings: TimerSettings { scheduler.settings }

    var body: some View {
        HStack(spacing: 4) {
            if time == nil || settings.menuBarDisplay == .iconAndText {
                // The app icon's mug in one colour (Assets.xcassets/MenuBarIcon). Dimmed while paused or smart-paused.
                Image("MenuBarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 15)
                    .opacity(scheduler.state == .paused || scheduler.isSmartPaused || scheduler.isOffHours ? 0.5 : 1)
            }
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
    private var time: String? {
        guard settings.showLiveStatus, scheduler.state != .stopped, !scheduler.isOffHours else { return nil }
        let remaining = scheduler.workRemaining
        return settings.timerStyle == .clock ? TimeFormat.clock(remaining) : TimeFormat.minutes(remaining)
    }
}
