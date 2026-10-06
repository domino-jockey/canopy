import SwiftUI

enum SettingsPage: Hashable {
    case general, screenBreaks, alerts

    var title: String {
        switch self {
        case .general: "General"
        case .screenBreaks: "Screen Breaks"
        case .alerts: "Alerts / Nudges"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .screenBreaks: "leaf.fill"
        case .alerts: "bell.fill"
        }
    }

    /// Each page has its own Mocha accent. Later pages: blue, pink, yellow…
    var color: Color {
        switch self {
        case .general: Mocha.mauve
        case .screenBreaks: Mocha.green
        case .alerts: Mocha.peach
        }
    }
}

/// Sidebar window like System Settings. Each later phase adds its page to `SettingsPage`.
struct SettingsView: View {
    let scheduler: BreakScheduler
    let previewAlert: (AlertKind) -> Void
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
                }
                Section("Behavior & Feedback") {
                    row(.alerts)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Mocha.mantle)
            .navigationSplitViewColumnWidth(220)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch page {
                case .general: GeneralSettingsPage(scheduler: scheduler)
                case .screenBreaks: ScreenBreaksSettingsPage(scheduler: scheduler)
                case .alerts: AlertsSettingsPage(scheduler: scheduler, preview: previewAlert)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Mocha.base)
            .toggleStyle(.switch)
            .tint(Mocha.mauve)
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
        .foregroundStyle(Mocha.text)
        .preferredColorScheme(.dark)
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
                .fill(rowPage == page ? Mocha.surface0 : .clear)
                .padding(.horizontal, 10)
        )
    }
}

/// Dark symbol on a small pastel square, Catppuccin style.
private struct SidebarIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Mocha.crust)
            .frame(width: 22, height: 22)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}
