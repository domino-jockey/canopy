import Charts
import SwiftUI

struct StatsSettingsPage: View {
    let scheduler: BreakScheduler
    /// The day under the pointer in the chart.
    @State private var hovered: Date?
    @State private var confirmingClear = false

    private var stats: StatsLog { scheduler.stats }

    var body: some View {
        let today = stats.day(.now)
        let week = stats.lastDays(7, from: .now)
        Form {
            Section("Today") {
                HStack(spacing: 12) {
                    StatTile(value: today.taken, label: "Breaks taken")
                    StatTile(value: today.skipped, label: "Skipped")
                    StatTile(value: today.snoozed, label: "Snoozed")
                    StatTile(value: stats.streak(today: .now), label: "Day streak", symbol: "flame.fill")
                }
                .padding(.vertical, 4)
            }

            Section {
                Chart {
                    ForEach(week, id: \.date) { day in
                        // Stacked: skipped at the bottom, snoozed on top.
                        ForEach([("Skipped", day.stats.percentSkipped), ("Snoozed", day.stats.percentSnoozed)], id: \.0) { kind, percent in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Percent", percent),
                                width: .ratio(0.55)
                            )
                            .foregroundStyle(by: .value("Kind", kind))
                            .opacity(hovered == nil || hovered == day.date ? 1 : 0.5)
                        }
                    }
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
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel("\(value.as(Int.self) ?? 0)%").font(.caption.monospaced())
                    }
                }
                .chartForegroundStyleScale(["Skipped": Color.orange, "Snoozed": Color.yellow])
                .chartLegend(position: .top, alignment: .trailing)
                .chartXSelection(value: Binding(
                    get: { hovered },
                    set: { hovered = $0.map { Calendar.current.startOfDay(for: $0) } }
                ))
                .frame(height: 220)
                .padding(.top, 24)
                .padding(.vertical, 8)
            } header: {
                Text("Skipped and snoozed, last 7 days")
            } footer: {
                Text("Share of each day's breaks you skipped or snoozed: lower is better. Hover over a day to see its numbers. Your streak is how many days in a row you didn't skip or snooze at all (days you didn't use your Mac don't count).")
            }

            Section {
                Button("Clear History…", role: .destructive) { confirmingClear = true }
                    .confirmationDialog("Clear all stats history?", isPresented: $confirmingClear) {
                        Button("Clear History", role: .destructive) { scheduler.clearStats() }
                    } message: {
                        Text("Breaks taken, skipped and snoozed, and your streak, go back to zero. This can't be undone.")
                    }
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
                RollingTime(text: "\(value)", font: .monospacedSystemFont(ofSize: 30, weight: .bold), color: .labelColor)
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
