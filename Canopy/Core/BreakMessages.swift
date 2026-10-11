import Foundation

/// What the break screen says. Exercises also have a symbol.
struct BreakMessage: Codable, Equatable, Hashable {
    var title: String
    var subtitle: String
    var symbol: String? = nil
}

enum BreakMessages {
    static let short = [
        BreakMessage(title: "Eyes to the horizon", subtitle: "Set your eyes on something distant until the countdown is over"),
        BreakMessage(title: "Look far away", subtitle: "Find the farthest thing you can see and rest your eyes on it"),
        BreakMessage(title: "Blink it out", subtitle: "Close your eyes, then blink slowly a few times"),
        BreakMessage(title: "Drop your shoulders", subtitle: "Let them fall away from your ears and take a deep breath"),
        BreakMessage(title: "Look out the window", subtitle: "Give your eyes something real and far away"),
    ]

    static let long = [
        BreakMessage(title: "Stand up and stretch", subtitle: "Reach for the ceiling, then roll your shoulders back"),
        BreakMessage(title: "Take a short walk", subtitle: "Get some water, or just walk around the room"),
        BreakMessage(title: "Move your body", subtitle: "Roll your neck, stretch your wrists, loosen your back"),
    ]

    /// Built-in exercises (like DeskRest's): quick eye and neck ones for short breaks, standing ones for long breaks.
    static let shortExercises = [
        BreakMessage(title: "Palming", subtitle: "Rub your hands warm, cup them over your closed eyes and relax", symbol: "hand.raised.fill"),
        BreakMessage(title: "Eye circles", subtitle: "Slowly roll your eyes in a big circle, then the other way", symbol: "eye"),
        BreakMessage(title: "Near and far", subtitle: "Look at your thumb up close, then at something far away. Repeat", symbol: "scope"),
        BreakMessage(title: "Neck tilt", subtitle: "Tilt your ear towards your shoulder, hold, then switch sides", symbol: "figure.mind.and.body"),
        BreakMessage(title: "Shoulder rolls", subtitle: "Roll your shoulders back five times, then forward five times", symbol: "figure.cooldown"),
        BreakMessage(title: "Chin tucks", subtitle: "Pull your chin straight back, hold for a moment, release. Repeat", symbol: "person.fill"),
        BreakMessage(title: "Wrist stretch", subtitle: "Hold one arm out and gently pull the fingers back, then switch", symbol: "hand.point.up.left.fill"),
    ]

    static let longExercises = [
        BreakMessage(title: "Stand and reach", subtitle: "Stand up, reach both arms to the ceiling and stretch tall", symbol: "figure.arms.open"),
        BreakMessage(title: "Chest opener", subtitle: "Clasp your hands behind your back and gently lift them", symbol: "figure.flexibility"),
        BreakMessage(title: "Lunge stretch", subtitle: "Step one foot back into a lunge, hold, then switch legs", symbol: "figure.strengthtraining.functional"),
        BreakMessage(title: "Walk and water", subtitle: "Take a short walk and drink a glass of water", symbol: "figure.walk"),
    ]

    /// Everything a break of this kind could show, given the settings: exercises or the built-in messages
    /// (the ones left on), plus the user's own messages for this kind of break.
    static func pool(for kind: BreakKind, settings: TimerSettings) -> [BreakMessage] {
        let on = { (list: [BreakMessage]) in list.filter { !settings.disabledExercises.contains($0.title) } }
        let exercises = on(kind == .long ? longExercises : shortExercises)
        let messages = on(kind == .long ? long : short)
        let builtIn = settings.showExercises && !exercises.isEmpty ? exercises : messages
        let own = (kind == .long ? settings.customLongMessages : settings.customShortMessages).filter { !$0.title.isEmpty }
        // Everything turned off: the built-in messages, so a break always has something to say.
        let pool = builtIn + own
        return pool.isEmpty ? (kind == .long ? long : short) : pool
    }

    static func random(for kind: BreakKind, settings: TimerSettings) -> BreakMessage {
        pool(for: kind, settings: settings).randomElement()!
    }
}
