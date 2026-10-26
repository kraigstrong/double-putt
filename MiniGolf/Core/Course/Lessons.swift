// How to Play: three practice holes, each teaching one idea. They're not in any course; MiniGolf/Game/Lessons.swift
// has the cards that coach each one.
extension Levels {
    static let lessons: [Level] = [aimAndPutt(), sameOrMirror(), waterAndPar()]

    /// Lesson 1. The same short, straight green twice: aim at the cup and both balls go in together.
    static func aimAndPutt() -> Level {
        var l = Level("Aim and Putt", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 100, 560); l.cup(.b, 100, 560)
        l.solution = Shot(angle: 90, power: 0.6)
        return l
    }

    /// Lesson 2. Shared tees, cups leaning opposite ways: Same sends one ball wide, Mirror sends each to its cup.
    static func sameOrMirror() -> Level {
        var l = Level("Same or Mirror", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 150, 560); l.cup(.b, 50, 560)
        l.solution = Shot(angle: 83.75, power: 0.6, mirrored: true)
        return l
    }

    /// Lesson 3. Twin greens, but one has a pond just left of the tee: putting straight up finds it, while a line
    /// at the cup clears it. A splash shows what water costs; the card at the end explains par.
    static func waterAndPar() -> Level {
        var l = Level("Water and Par", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 60, 110); l.tee(.b, 60, 110)
        l.cup(.a, 140, 600); l.cup(.b, 140, 600)
        l.water(.b, 0, 300, 75, 420)
        l.solution = Shot(angle: 80.75, power: 0.63)
        return l
    }
}
