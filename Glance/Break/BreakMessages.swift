struct BreakMessage {
    let title: String
    let subtitle: String
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

    static func random(for kind: BreakKind) -> BreakMessage {
        (kind == .long ? long : short).randomElement()!
    }
}
