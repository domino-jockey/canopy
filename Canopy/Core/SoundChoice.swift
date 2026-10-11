import Foundation

/// A sound to pick in settings. BreakTimer's come in a start and an end version; Stretchly's are one file.
/// See CREDITS.md.
enum SoundChoice: String, Codable, CaseIterable {
    case gong, blip, bloop, ping, scifi, crystalGlass, windChime, ticToc, reverie

    var title: String {
        switch self {
        case .gong: "Gong"
        case .blip: "Blip"
        case .bloop: "Bloop"
        case .ping: "Ping"
        case .scifi: "Sci-fi"
        case .crystalGlass: "Crystal glass"
        case .windChime: "Wind chime"
        case .ticToc: "Tic-toc"
        case .reverie: "Reverie"
        }
    }

    /// BreakTimer's sounds have their own (lower) end version; Stretchly's are the same file at both ends.
    var hasEndVersion: Bool {
        switch self {
        case .gong, .blip, .bloop, .ping, .scifi: true
        case .crystalGlass, .windChime, .ticToc, .reverie: false
        }
    }

    /// The sound file's name in the app bundle.
    func fileName(end: Bool) -> String {
        switch self {
        case .gong, .blip, .bloop, .ping, .scifi: "\(rawValue)_\(end ? "end" : "start")"
        case .crystalGlass: "crystal_glass"
        case .windChime: "wind_chime"
        case .ticToc: "tic_toc"
        case .reverie: "reverie"
        }
    }
}
