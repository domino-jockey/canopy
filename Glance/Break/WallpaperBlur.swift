import AppKit
import CoreImage
import ImageIO

@MainActor
enum WallpaperBlur {
    private static let context = CIContext()

    /// The screen's wallpaper, shrunk, heavily blurred and slightly darkened.
    /// Nil if the wallpaper can't be read (e.g. some dynamic wallpapers).
    static func image(for screen: NSScreen) -> NSImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              // Decoding a small copy is fast, and looks the same once blurred.
              let small = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 480,
              ] as CFDictionary)
        else { return nil }

        let input = CIImage(cgImage: small)
        let blurred = input.clampedToExtent()
            .applyingGaussianBlur(sigma: 18)
            .cropped(to: input.extent)
        let tint = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.25))
            .cropped(to: input.extent)
        guard let output = context.createCGImage(tint.composited(over: blurred), from: input.extent)
        else { return nil }
        return NSImage(cgImage: output, size: .zero)
    }
}
