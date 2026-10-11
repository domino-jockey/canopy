import AppKit
import SwiftUI

/// A number that rolls when it changes, like the break screen's big timer: the old digit rises away fading
/// out, while the new one comes up from below fading in. Used for every changing number in the app.
/// `.numericText` redraws the whole view every frame (about 50% CPU on the break screen). Here each digit is
/// its own layer, drawn once, and Core Animation moves and fades it on its own.
struct RollingTime: NSViewRepresentable {
    let text: String
    var font = NSFont.monospacedSystemFont(ofSize: 120, weight: .semibold)
    var color = NSColor.white
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeNSView(context: Context) -> RollingTimeView { RollingTimeView(font: font, color: color) }

    func updateNSView(_ view: RollingTimeView, context: Context) {
        view.show(text, reduceMotion: reduceMotion)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: RollingTimeView, context: Context) -> CGSize? {
        nsView.size(for: text)
    }
}

final class RollingTimeView: NSView {
    private static let duration = 0.25

    private let font: NSFont
    private let color: NSColor
    private var text = ""
    private var digits: [CATextLayer] = []

    private var height: CGFloat { ceil(font.ascender - font.descender) }

    init(font: NSFont, color: NSColor) {
        self.font = font
        self.color = color
        super.init(frame: .zero)
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Each character's box: (left edge, width). Digits all have the same width, even in SF Pro.
    private func columns(for text: String) -> [(x: CGFloat, width: CGFloat)] {
        var x: CGFloat = 0
        return text.map { character in
            let width = ceil((String(character) as NSString).size(withAttributes: [.font: font]).width)
            defer { x += width }
            return (x, width)
        }
    }

    func size(for text: String) -> CGSize {
        CGSize(width: columns(for: text).last.map { $0.x + $0.width } ?? 0, height: height)
    }

    func show(_ newText: String, reduceMotion: Bool) {
        guard newText != text else { return }
        setAccessibilityLabel(newText)
        let old = Array(text), new = Array(newText)
        let oldColumns = columns(for: text), newColumns = columns(for: newText)
        text = newText

        // First time, or the layout changed (10:00 → 9:59): lay the digits out again, no roll.
        guard oldColumns.map(\.x) == newColumns.map(\.x) else {
            digits.forEach { $0.removeFromSuperlayer() }
            digits = new.indices.map { addDigit(new[$0], in: newColumns[$0]) }
            return
        }
        for column in new.indices where new[column] != old[column] {
            let leaving = digits[column]
            let arriving = addDigit(new[column], in: newColumns[column])
            digits[column] = arriving
            roll(out: leaving, in: arriving, reduceMotion: reduceMotion)
        }
    }

    /// Menu bar text switches between black and white with the wallpaper and dark mode.
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        let color = resolvedColor
        digits.forEach { $0.foregroundColor = color }
    }

    private var resolvedColor: CGColor {
        var resolved = color.cgColor
        effectiveAppearance.performAsCurrentDrawingAppearance { resolved = color.cgColor }
        return resolved
    }

    private func addDigit(_ character: Character, in column: (x: CGFloat, width: CGFloat)) -> CATextLayer {
        let digit = CATextLayer()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        digit.frame = CGRect(x: column.x, y: 0, width: column.width, height: height)
        digit.string = String(character)
        digit.font = font
        digit.fontSize = font.pointSize
        digit.foregroundColor = resolvedColor
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
            let rise = height * 0.45
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
