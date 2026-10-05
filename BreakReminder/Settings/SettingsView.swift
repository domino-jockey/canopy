import SwiftUI

extension Color {
    /// LookAway's accent, used for toggles, sliders and the selected card.
    static let coral = Color(red: 0.95, green: 0.38, blue: 0.38)
}

enum SettingsPage: Hashable {
    case general, screenBreaks

    var title: String {
        switch self {
        case .general: "General"
        case .screenBreaks: "Screen Breaks"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .screenBreaks: "eye.slash.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .general: [Color(red: 0.75, green: 0.35, blue: 0.95), Color(red: 0.93, green: 0.35, blue: 0.75)]
        case .screenBreaks: [Color(red: 0.93, green: 0.35, blue: 0.75), Color(red: 0.95, green: 0.3, blue: 0.55)]
        }
    }
}

/// Sidebar window like System Settings. Each later phase adds its page to `SettingsPage`.
struct SettingsView: View {
    let scheduler: BreakScheduler
    @State private var page: SettingsPage? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $page) {
                row(.general)
                Section("Focus & Wellbeing") {
                    row(.screenBreaks)
                }
            }
            .navigationSplitViewColumnWidth(220)
        } detail: {
            Group {
                switch page ?? .general {
                case .general: GeneralSettingsPage()
                case .screenBreaks: ScreenBreaksSettingsPage(scheduler: scheduler)
                }
            }
            .formStyle(.grouped)
            .toggleStyle(.switch)
            .tint(.coral)
            .navigationTitle((page ?? .general).title)
        }
    }

    private func row(_ page: SettingsPage) -> some View {
        Label {
            Text(page.title)
        } icon: {
            SidebarIcon(symbol: page.symbol, colors: page.gradient)
        }
        .tag(page)
    }
}

/// White symbol on a small gradient square, like LookAway's sidebar.
private struct SidebarIcon: View {
    let symbol: String
    let colors: [Color]

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }
}
