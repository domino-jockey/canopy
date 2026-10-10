import Charts
import SwiftUI

struct StatsSettingsPage: View {
    let scheduler: BreakScheduler
    /// The day under the pointer in the chart.
    @State private var hovered: Date?

    private var settings: Binding<TimerSettings> {
        Binding(get: { scheduler.settings }, set: { scheduler.apply($0) })
    }

    private var stats: StatsLog { scheduler.stats }
    private var goal: Int { scheduler.settings.dailyBreakGoal }

    var body: some View {
        let today = stats.day(.now)
        let week = stats.lastDays(7, from: .now)
        Form {
            Section("Today") {
                HStack(spacing: 12) {
                    StatTile(value: today.taken, label: "Breaks taken")
                    StatTile(value: today.skipped, label: "Skipped")
                    StatTile(value: today.snoozed, label: "Snoozed")
                    StatTile(value: stats.streak(goal: goal, today: .now), label: "Day streak", symbol: "flame.fill")
                }
                .padding(.vertical, 4)
            }

            Section {
                Chart {
                    ForEach(week, id: \.date) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Breaks taken", day.stats.taken),
                            width: .ratio(0.55)
                        )
                        .foregroundStyle(.tint.opacity(hovered == nil || hovered == day.date ? 1 : 0.5))
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                    }
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(Color.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    if let hovered, let day = week.first(where: { $0.date == hovered }) {
                        RuleMark(x: .value("Day", hovered, unit: .day))
                            .foregroundStyle(.clear)
                            .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                                HoverCard(date: day.date, stats: day.stats)
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel().font(.caption.monospaced())
                    }
                }
                .chartXSelection(value: Binding(
                    get: { hovered },
                    set: { hovered = $0.map { Calendar.current.startOfDay(for: $0) } }
                ))
                .frame(height: 220)
                .padding(.top, 24)
                .padding(.vertical, 8)
            } header: {
                Text("Breaks taken, last 7 days")
            } footer: {
                Text("The dashed line is your daily goal. Hover over a day to see its skips and snoozes.")
            }

            Section {
                Stepper(value: settings.dailyBreakGoal, in: 1...30) {
                    LabeledContent("Daily goal", value: "\(goal) breaks")
                }
            } footer: {
                Text("Your streak is how many days in a row you've taken at least this many breaks.")
            }
        }
    }
}

/// A big number with a label under it.
private struct StatTile: View {
    let value: Int
    let label: String
    var symbol: String?

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let symbol { Image(systemName: symbol).font(.title3).foregroundStyle(.orange) }
                Text("\(value)")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .contentTransition(.numericText())
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// The hovered day's numbers.
private struct HoverCard: View {
    let date: Date
    let stats: DayStats

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(date.formatted(.dateTime.weekday(.wide).month().day())).font(.caption.weight(.semibold))
            Text("\(stats.taken) taken · \(stats.skipped) skipped · \(stats.snoozed) snoozed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
