import AppKit
import SwiftUI

/// A small floating window holding one alert pill. It sits above other apps on every Space
/// and never takes the keyboard, so it doesn't interrupt typing.
@MainActor
final class AlertPanel {
    private let window: NSPanel
    private(set) var isShown = false

    /// Gap between the pill and the screen edge or the mouse pointer.
    private let margin: CGFloat = 12
    /// Clear space around the pill so its shadow isn't cut off.
    private static let shadowRoom: CGFloat = 16

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
        window.contentView = FirstClickHostingView(rootView: content.padding(Self.shadowRoom))
    }

    func show() {
        guard !isShown else { return }
        isShown = true
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { $0.duration = 0.25; window.animator().alphaValue = 1 }
    }

    func hide() {
        guard isShown else { return }
        isShown = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
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
        window.setFrame(NSRect(origin: NSPoint(x: x, y: area.maxY - size.height), size: size), display: true)
    }

    /// Just below and to the right of the mouse pointer.
    func moveNearCursor() {
        let size = fittingSize
        let mouse = NSEvent.mouseLocation
        let origin = NSPoint(x: mouse.x + margin - Self.shadowRoom, y: mouse.y - margin - 12 - size.height + Self.shadowRoom)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private var fittingSize: NSSize { window.contentView!.fittingSize }

    private static var mouseScreen: NSScreen {
        NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.screens[0]
    }
}

/// Buttons in a window that isn't focused normally need one click to focus it and another to press.
/// This makes the first click press the button.
private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
