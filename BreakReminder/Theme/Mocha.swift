import SwiftUI

/// The Catppuccin Mocha palette (catppuccin.com/palette). The whole app's look comes from these.
enum Mocha {
    // Accents
    static let rosewater = Color(hex: 0xf5e0dc)
    static let flamingo = Color(hex: 0xf2cdcd)
    static let pink = Color(hex: 0xf5c2e7)
    static let mauve = Color(hex: 0xcba6f7)
    static let red = Color(hex: 0xf38ba8)
    static let maroon = Color(hex: 0xeba0ac)
    static let peach = Color(hex: 0xfab387)
    static let yellow = Color(hex: 0xf9e2af)
    static let green = Color(hex: 0xa6e3a1)
    static let teal = Color(hex: 0x94e2d5)
    static let sky = Color(hex: 0x89dceb)
    static let sapphire = Color(hex: 0x74c7ec)
    static let blue = Color(hex: 0x89b4fa)
    static let lavender = Color(hex: 0xb4befe)

    // Text, lightest first
    static let text = Color(hex: 0xcdd6f4)
    static let subtext1 = Color(hex: 0xbac2de)
    static let subtext0 = Color(hex: 0xa6adc8)
    static let overlay2 = Color(hex: 0x9399b2)
    static let overlay1 = Color(hex: 0x7f849c)
    static let overlay0 = Color(hex: 0x6c7086)

    // Backgrounds, lightest first
    static let surface2 = Color(hex: 0x585b70)
    static let surface1 = Color(hex: 0x45475a)
    static let surface0 = Color(hex: 0x313244)
    static let base = Color(hex: 0x1e1e2e)
    static let mantle = Color(hex: 0x181825)
    static let crust = Color(hex: 0x11111b)
}

extension Color {
    /// A colour from a hex number like 0xcba6f7.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}
