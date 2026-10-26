import Foundation

/// How to Play: three lessons, each a practice hole (`Levels.lessons`) coached by cards that wait for you to do what
/// they ask. A new player starts on them; Settings has them any time.
enum Lesson: Int, CaseIterable {
    case aim, mirror, water

    var level: Level { Levels.lessons[rawValue] }
    var next: Lesson? { Lesson(rawValue: rawValue + 1) }

    /// The card a lesson opens with.
    var firstStep: LessonStep {
        switch self {
        case .aim: .pull
        case .mirror: .aimOne
        case .water: .water
        }
    }

    /// What the lesson taught, on the card when its hole is done.
    var takeaway: String {
        switch self {
        case .aim: "One swing plays both greens. That's the game."
        case .mirror: "Pick Same or Mirror on every swing."
        case .water: "Each green has its own par. Any ball can drop in any cup."
        }
    }
}

/// A control a lesson's card points an arrow at.
enum LessonControl { case aim, power, mirror, putt }

/// A lesson's card. Each waits for what it asks: a drag, a nudge, Mirror, or Putt.
enum LessonStep: Equatable {
    // Aim and Putt
    case pull, fineTune, putt
    // Same or Mirror
    case aimOne, mirror, puttMirror
    // Water and Par
    case water, doubleAce
    // After a swing that leaves a ball out
    case again, oneIn, splash

    var text: String {
        switch self {
        case .pull: "Pull back anywhere to aim. Let go and the aim stays."
        case .fineTune: "Fine-tune with ‹ › and the power bar."
        case .putt: "Tap Putt. One swing hits both balls."
        case .aimOne: "These cups lean opposite ways. Aim at one of them."
        case .mirror: "The other line misses. Tap Mirror to flip it."
        case .puttMirror: "Both lines head for a cup now. Putt!"
        case .water: "Water costs a stroke, and the ball goes back."
        case .doubleAce: "Sink both on the first swing for a double ace."
        case .again: "Not quite. Putt again from where they stopped."
        case .oneIn: "One's in! The next swing moves just the other."
        case .splash: "Splash! That's a stroke, and the ball goes back."
        }
    }

    /// The controls the card's arrows point at.
    var arrows: Set<LessonControl> {
        switch self {
        case .fineTune: [.aim, .power]
        case .mirror: [.mirror]
        case .putt, .puttMirror: [.putt]
        default: []
        }
    }
}
