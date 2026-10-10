import AppKit
import SwiftUI

/// Finder shows the fixed green icon (`AppIcon.icon`). Inside the app (Dock, About, Welcome, the flash reminder)
/// the icon is redrawn with the leaf in the accent colour, and again whenever the accent colour changes.
@MainActor
enum AccentIcon {
    private static var observer: NSObjectProtocol?

    static func start() {
        update()
        observer = NotificationCenter.default.addObserver(
            forName: NSColor.systemColorsDidChangeNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { update() }
        }
    }

    private static func update() {
        let renderer = ImageRenderer(content: IconView(accent: Color(nsColor: .controlAccentColor)))
        renderer.scale = 2
        NSApp.applicationIconImage = renderer.nsImage
    }
}

/// The app icon, flat: Icon Composer's dark background with the menu bar leaf on it.
/// Sized like macOS icons: the square fills about 80% of the image.
private struct IconView: View {
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 92, style: .continuous)
            .fill(LinearGradient(colors: [Color(white: 0.133), Color(white: 0.067)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 92, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 2))
            .overlay {
                Image("MenuBarIcon")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(accent)
                    .padding(64)
            }
            .frame(width: 412, height: 412)
            .padding(50)
    }
}
