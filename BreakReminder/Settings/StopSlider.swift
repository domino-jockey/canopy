import SwiftUI

/// A duration slider that snaps to a few fixed stops, with the value shown big above it
/// (like DeskRest). Values are stored in seconds; `unit` only changes how they're shown.
struct StopSlider: View {
    enum Unit {
        case seconds, minutes

        var factor: TimeInterval { self == .seconds ? 1 : 60 }

        func name(_ count: Int) -> String {
            let word = self == .seconds ? "second" : "minute"
            return count == 1 ? word : word + "s"
        }
    }

    @Binding var value: TimeInterval
    /// In `unit`s, smallest first.
    let stops: [Int]
    let unit: Unit

    /// The stop closest to the current value, so values saved off-stop still show sensibly.
    private var index: Int {
        let current = value / unit.factor
        return stops.indices.min { abs(Double(stops[$0]) - current) < abs(Double(stops[$1]) - current) }!
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(stops[index])")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.coral)
                .contentTransition(.numericText())
            Text(unit.name(stops[index]))
                .foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { Double(index) },
                    set: { value = TimeInterval(stops[Int($0.rounded())]) * unit.factor }
                ),
                in: 0...Double(stops.count - 1),
                step: 1
            )
            .labelsHidden()
            tickLabels
        }
        .animation(.snappy, value: index)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    /// One label under each stop. The slider's track starts about half a knob in from each edge.
    private var tickLabels: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 10
            let spacing = (geometry.size.width - inset * 2) / CGFloat(stops.count - 1)
            ForEach(stops.indices, id: \.self) { i in
                Text("\(stops[i])")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(i == index ? Color.coral : .secondary)
                    .fixedSize()
                    .position(x: inset + spacing * CGFloat(i), y: 7)
                    .onTapGesture { value = TimeInterval(stops[i]) * unit.factor }
            }
        }
        .frame(height: 14)
    }
}
