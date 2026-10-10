import SwiftUI

/// In sidebar order.
enum SettingsPage: Hashable, CaseIterable {
    case general, screenBreaks, breakScreen, wellness, schedule, smartPause, stats, alerts, sounds, shortcuts, about

    var title: String {
        switch self {
        case .general: "General"
        case .screenBreaks: "Screen Breaks"
        case .breakScreen: "Break Screen"
        case .schedule: "Schedule"
        case .smartPause: "Smart Pause"
        case .wellness: "Wellness Reminders"
        case .stats: "Stats"
        case .alerts: "Alerts / Nudges"
        case .sounds: "Sounds"
        case .shortcuts: "Keyboard Shortcuts"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .screenBreaks: "leaf.fill"
        case .breakScreen: "paintbrush.fill"
        case .schedule: "calendar"
        case .smartPause: "pause.fill"
        case .wellness: "heart.fill"
        case .stats: "chart.bar.fill"
        case .alerts: "bell.fill"
        case .sounds: "speaker.wave.2.fill"
        case .shortcuts: "command"
        case .about: "info"
        }
    }

    /// Fixed colours like System Settings: one colour per group of similar pages.
    var color: Color {
        switch self {
        case .general, .about: .gray
        case .screenBreaks, .breakScreen, .wellness: .teal
        case .schedule, .smartPause, .stats: .purple
        case .alerts, .sounds: .red
        case .shortcuts: .orange
        }
    }
}

/// Sidebar window like System Settings. Each later phase adds its page to `SettingsPage`.
struct SettingsView: View {
    let scheduler: BreakScheduler
    let previewAlert: (AlertKind) -> Void
    let previewWellness: (WellnessKind) -> Void
    let previewClockOut: () -> Void
    /// Pages visited, for the ‹ › buttons. `position` is the one on screen.
    @State private var history: [SettingsPage] = [.general]
    @State private var position = 0

    private var page: SettingsPage { history[position] }

    var body: some View {
        NavigationSplitView {
            List {
                row(.general)
                Section("Focus & Wellbeing") {
                    row(.screenBreaks)
                    row(.breakScreen)
                    row(.wellness)
                    row(.schedule)
                    row(.smartPause)
                    row(.stats)
                }
                Section("Behavior & Feedback") {
                    row(.alerts)
                    row(.sounds)
                    row(.shortcuts)
                }
                Section("BreakReminder") {
                    row(.about)
                }
            }
            // In this AppKit-hosted window the column width alone is ignored; the frame makes it stick.
            .frame(minWidth: 240, idealWidth: 240)
            .navigationSplitViewColumnWidth(240)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch page {
                case .general: GeneralSettingsPage(scheduler: scheduler)
                case .screenBreaks: ScreenBreaksSettingsPage(scheduler: scheduler)
                case .breakScreen: BreakScreenSettingsPage(scheduler: scheduler)
                case .schedule: ScheduleSettingsPage(scheduler: scheduler, previewClockOut: previewClockOut)
                case .smartPause: SmartPauseSettingsPage(scheduler: scheduler)
                case .stats: StatsSettingsPage(scheduler: scheduler)
                case .wellness: WellnessSettingsPage(scheduler: scheduler, preview: previewWellness)
                case .alerts: AlertsSettingsPage(scheduler: scheduler, preview: previewAlert)
                case .sounds: SoundsSettingsPage(scheduler: scheduler)
                case .shortcuts: ShortcutsSettingsPage()
                case .about: AboutSettingsPage()
                }
            }
            .formStyle(.grouped)
            .toggleStyle(.switch)
            .navigationTitle(page.title)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button("Back", systemImage: "chevron.left") { position -= 1 }
                        .disabled(position == 0)
                    Button("Forward", systemImage: "chevron.right") { position += 1 }
                        .disabled(position == history.count - 1)
                }
            }
        }
    }

    private func open(_ newPage: SettingsPage) {
        guard newPage != page else { return }
        history = Array(history[...position]) + [newPage]
        position += 1
    }

    /// LookAway-style row: the selected page gets a soft pill, not the accent colour.
    private func row(_ rowPage: SettingsPage) -> some View {
        Button { open(rowPage) } label: {
            Label {
                Text(rowPage.title)
            } icon: {
                SidebarIcon(symbol: rowPage.symbol, color: rowPage.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(rowPage == page ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
                .padding(.horizontal, 10)
        )
    }
}

/// White symbol on a small gradient square, lighter at the top left (like openlookaway).
private struct SidebarIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(
                LinearGradient(colors: [color.mix(with: .white, by: 0.25), color], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }
}
