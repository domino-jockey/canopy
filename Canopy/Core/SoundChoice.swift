import Foundation

/// A sound to pick in settings. BreakTimer's come in a start and an end version; Stretchly's are one file.
/// See CREDITS.md.
enum SoundChoice: String, Codable, CaseIterable {
    case gong, blip, bloop, ping, scifi, crystalGlass, windChime, ticToc

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
        }
    }

    /// The sound file's name in the app bundle.
    func fileName(end: Bool) -> String {
        switch self {
        case .gong, .blip, .bloop, .ping, .scifi: "\(rawValue)_\(end ? "end" : "start")"
        case .crystalGlass: "crystal_glass"
        case .windChime: "wind_chime"
        case .ticToc: "tic_toc"
        }
    }
}
