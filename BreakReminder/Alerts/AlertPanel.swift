import AppKit
import SwiftUI

/// A small floating window holding one alert pill. It sits above other apps on every Space
/// and never takes the keyboard, so it doesn't interrupt typing.
@MainActor
final class AlertPanel {
    private let window: NSPanel
    private let hostingView: NSView
    private(set) var isShown = false

    /// Gap between the pill and the screen edge or the mouse pointer.
    private let margin: CGFloat = 12
    /// Clear space around the pill so its shadow isn't cut off.
    private static let shadowRoom: CGFloat = 16
    /// How far top pills slide in from.
    private static let slideDistance: CGFloat = 14
    /// Where a top pill sits. Nil for the pill that follows the pointer.
    private var topFrame: NSRect?

    /// `clickThrough` lets clicks pass to whatever is underneath.
    init(clickThrough: Bool, content: some View) {
        window = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // the pill draws its own
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = clickThrough
        window.alphaValue = 0
        // We size and place the window ourselves (`moveToTop`, `moveNearCursor`). If the SwiftUI view were the
        // window's content view, it would also resize the window whenever the text changes width, fighting
        // those moves: the pill jumps sideways, and AppKit gets stuck in a layout loop and crashes the app.
        // Inside a plain container it still reports its size (`fittingSize`) but can't resize the window.
        hostingView = FirstClickHostingView(rootView: content.padding(Self.shadowRoom))
        hostingView.autoresizingMask = [.width, .height]
        let container = NSView()
        container.addSubview(hostingView)
        window.contentView = container
    }

    func show() {
        guard !isShown else { return }
        isShown = true
        // Top pills slide down from the menu bar with a little overshoot; the countdown by the pointer just fades.
        let slideTo = Self.reduceMotion ? nil : topFrame
        if let slideTo { window.setFrame(slideTo.offsetBy(dx: 0, dy: Self.slideDistance), display: false) }
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = slideTo == nil ? 0.25 : 0.45
            if let slideTo {
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.3, 0.4, 1)
                window.animator().setFrame(slideTo, display: true)
            }
            window.animator().alphaValue = 1
        }
    }

    func hide() {
        guard isShown else { return }
        isShown = false
        let slideFrom = Self.reduceMotion ? nil : topFrame
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            if let slideFrom { window.animator().setFrame(slideFrom.offsetBy(dx: 0, dy: Self.slideDistance), display: true) }
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                // Shown again while fading out? Then leave it up.
                if let self, !self.isShown { self.window.orderOut(nil) }
            }
        }
    }

    /// Top left, center or right of the screen the mouse is on, just below the menu bar.
    func moveToTop(_ position: AlertPosition) {
        let size = fittingSize
        let area = Self.mouseScreen.visibleFrame.insetBy(dx: margin - Self.shadowRoom, dy: margin - Self.shadowRoom)
        let x = switch position {
        case .topLeft: area.minX
        case .topCenter: area.midX - size.width / 2
        case .topRight: area.maxX - size.width
        }
        let frame = NSRect(origin: NSPoint(x: x, y: area.maxY - size.height), size: size)
        // Called every tick: leave the window (and a slide in progress) alone unless the spot changed.
        guard frame != topFrame else { return }
        topFrame = frame
        window.setFrame(frame, display: true)
    }

    /// Just below and to the right of the mouse pointer.
    func moveNearCursor() {
        topFrame = nil
        let size = fittingSize
        let mouse = NSEvent.mouseLocation
        let origin = NSPoint(x: mouse.x + margin - Self.shadowRoom, y: mouse.y - margin - 12 - size.height + Self.shadowRoom)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    var fittingSize: NSSize {
        hostingView.layoutSubtreeIfNeeded() // apply model changes made just now, before measuring
        return hostingView.fittingSize
    }

    private static var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private static var mouseScreen: NSScreen {
        NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.screens[0]
    }
}

/// Buttons in a window that isn't focused normally need one click to focus it and another to press.
/// This makes the first click press the button.
private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
