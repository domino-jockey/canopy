import AppKit
import SwiftUI

/// The break screen's big timer. A digit that changes rolls up like the menu bar clock: the old one
/// rises away fading out, while the new one comes up from below fading in.
/// `.numericText` redraws the whole break screen every frame (about 50% CPU). Here each digit is its own
/// layer, drawn once, and Core Animation moves and fades it on its own.
struct RollingTime: NSViewRepresentable {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeNSView(context: Context) -> RollingTimeView { RollingTimeView() }

    func updateNSView(_ view: RollingTimeView, context: Context) {
        view.show(text, reduceMotion: reduceMotion)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: RollingTimeView, context: Context) -> CGSize? {
        RollingTimeView.size(for: text)
    }
}

final class RollingTimeView: NSView {
    private static let font = NSFont.monospacedSystemFont(ofSize: 120, weight: .semibold)
    /// Every character takes the same box: it's a monospaced font.
    private static let cell = CGSize(
        width: ceil(("0" as NSString).size(withAttributes: [.font: font]).width),
        height: ceil(font.ascender - font.descender)
    )
    private static let duration = 0.25

    private var text = ""
    private var digits: [CALayer] = []

    static func size(for text: String) -> CGSize {
        CGSize(width: cell.width * CGFloat(text.count), height: cell.height)
    }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func show(_ newText: String, reduceMotion: Bool) {
        guard newText != text else { return }
        setAccessibilityLabel(newText)
        let old = Array(text), new = Array(newText)
        text = newText

        // First time, or the width changed (10:00 → 9:59): lay the digits out again, no roll.
        guard old.count == new.count else {
            digits.forEach { $0.removeFromSuperlayer() }
            digits = new.indices.map { addDigit(new[$0], column: $0) }
            return
        }
        for column in new.indices where new[column] != old[column] {
            let leaving = digits[column]
            let arriving = addDigit(new[column], column: column)
            digits[column] = arriving
            roll(out: leaving, in: arriving, reduceMotion: reduceMotion)
        }
    }

    private func addDigit(_ character: Character, column: Int) -> CALayer {
        let digit = CATextLayer()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        digit.frame = CGRect(x: CGFloat(column) * Self.cell.width, y: 0, width: Self.cell.width, height: Self.cell.height)
        digit.string = String(character)
        digit.font = Self.font
        digit.fontSize = Self.font.pointSize
        digit.foregroundColor = NSColor.white.cgColor
        digit.alignmentMode = .center
        digit.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        layer?.addSublayer(digit)
        CATransaction.commit()
        return digit
    }

    /// The old digit rises away and fades out; the new one comes up from below and fades in.
    private func roll(out leaving: CALayer, in arriving: CALayer, reduceMotion: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(Self.duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        CATransaction.setCompletionBlock { leaving.removeFromSuperlayer() }

        leaving.opacity = 0
        leaving.add(animation("opacity", from: 1, to: 0), forKey: "fade")
        arriving.add(animation("opacity", from: 0, to: 1), forKey: "fade")

        if !reduceMotion {
            let y = arriving.position.y
            let rise = Self.cell.height * 0.45
            leaving.position.y = y + rise
            leaving.add(animation("position.y", from: y, to: y + rise), forKey: "rise")
            arriving.add(animation("position.y", from: y - rise, to: y), forKey: "rise")
        }
        CATransaction.commit()
    }

    /// Takes its duration and easing from the surrounding transaction.
    private func animation(_ keyPath: String, from: CGFloat, to: CGFloat) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        return animation
    }
}
