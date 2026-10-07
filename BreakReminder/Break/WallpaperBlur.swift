import AppKit
import CoreImage
import ImageIO

@MainActor
enum WallpaperBlur {
    private static let context = CIContext()

    /// The screen's wallpaper, shrunk, heavily blurred and slightly darkened.
    /// Nil if the wallpaper can't be read (e.g. some dynamic wallpapers).
    static func image(for screen: NSScreen) -> NSImage? {
        NSWorkspace.shared.desktopImageURL(for: screen).flatMap { blurred($0) }
    }

    /// A picture the user picked for the break screen: lightly blurred, so the text stays readable.
    static func picture(at path: String) -> NSImage? {
        blurred(URL(fileURLWithPath: path), sigma: 4, size: 1600)
    }

    private static func blurred(_ url: URL, sigma: Double = 18, size: Int = 480) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              // Decoding a small copy is fast, and looks the same once blurred.
              let small = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: size,
              ] as CFDictionary)
        else { return nil }

        let input = CIImage(cgImage: small)
        let blurred = input.clampedToExtent()
            .applyingGaussianBlur(sigma: sigma)
            .cropped(to: input.extent)
        let tint = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.25))
            .cropped(to: input.extent)
        guard let output = context.createCGImage(tint.composited(over: blurred), from: input.extent)
        else { return nil }
        return NSImage(cgImage: output, size: .zero)
    }
}
