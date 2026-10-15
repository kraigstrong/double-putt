import Foundation

/// Course space: 400 x 800, y up. Hole A is x 0...200, hole B is x 200...400.
enum Course {
    static let width = 400.0
    static let height = 800.0
    static let half = 200.0
    static let railRadius = 4.0
    static let blockRadius = 3.0
}

enum Side: Int {
    case a = 0, b = 1
    var offset: Double { self == .a ? 0 : Course.half }
}

struct Shot: Equatable {
    var angle: Double   // degrees, 0 = right, 90 = up
    var power: Double   // 0...1
    var mirrored = false  // hole B's ball gets the shot flipped left-to-right

    var velocity: Vec { .shot(degrees: angle, speed: power * Tuning.maxShotSpeed) }
}

struct Level {
    var name: String
    var hint: String
    var par: [Int]
    /// Visual setting: meadow, garden, moat, seaside, autumn, desert, winter, night.
    var setting = "meadow"
    var tees: [Vec] = [.zero, .zero]
    var cups: [Vec] = [.zero, .zero]
    var rails: [Wall] = []
    var blocks: [Box] = []
    var bumpers: [Bumper] = []
    var water: [Box] = []
    var tunnels: [Tunnel] = []
    var slopes: [Slope] = []
    var mounds: [Mound] = []
    var movers: [Mover] = []
    /// A known double ace, found by Tools/solver.
    var solution: Shot?
    /// Where the movers' clock must be when `solution` is struck (the clock starts at 0 when the pair loads).
    var solutionTime = 0.0

    init(_ name: String, par: [Int], hint: String) {
        self.name = name
        self.par = par
        self.hint = hint
    }

    /// Seconds until every mover is back at its start pose together (0 = no movers).
    var moverCycle: Double {
        let periods = movers.map(\.period).filter { $0 > 0 }
        guard let longest = periods.max() else { return 0 }
        for k in 1...240 {
            let t = longest * Double(k)
            if periods.allSatisfy({ abs((t / $0).rounded() - t / $0) < 1e-6 }) { return t }
        }
        return 0
    }

    var walls: [Wall] {
        rails + blocks.flatMap { b -> [Wall] in
            let c = [Vec(b.minX, b.minY), Vec(b.maxX, b.minY), Vec(b.maxX, b.maxY), Vec(b.minX, b.maxY)]
            return (0..<4).map { Wall(a: c[$0], b: c[($0 + 1) % 4], radius: Course.blockRadius) }
        }
    }

    // MARK: Builders (x/y are local to the side's hole)

    /// Outer fence plus the shared middle wall. `gaps` are y-ranges where the middle wall is open.
    mutating func frame(gaps: [ClosedRange<Double>] = []) {
        let w = Course.width, h = Course.height, r = Course.railRadius
        rails += [
            Wall(a: Vec(0, 0), b: Vec(w, 0), radius: r),
            Wall(a: Vec(w, 0), b: Vec(w, h), radius: r),
            Wall(a: Vec(w, h), b: Vec(0, h), radius: r),
            Wall(a: Vec(0, h), b: Vec(0, 0), radius: r),
        ]
        var y = 0.0
        for g in gaps.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if g.lowerBound > y { rails.append(Wall(a: Vec(Course.half, y), b: Vec(Course.half, g.lowerBound), radius: r)) }
            y = g.upperBound
        }
        if y < h { rails.append(Wall(a: Vec(Course.half, y), b: Vec(Course.half, h), radius: r)) }
    }

    mutating func tee(_ s: Side, _ x: Double, _ y: Double) { tees[s.rawValue] = Vec(x + s.offset, y) }
    mutating func cup(_ s: Side, _ x: Double, _ y: Double) { cups[s.rawValue] = Vec(x + s.offset, y) }

    mutating func rail(_ s: Side, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        rails.append(Wall(a: Vec(x1 + s.offset, y1), b: Vec(x2 + s.offset, y2), radius: Course.railRadius))
    }

    mutating func block(_ s: Side, _ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double) {
        blocks.append(Box(minX + s.offset, minY, maxX + s.offset, maxY))
    }

    mutating func bumper(_ s: Side, _ x: Double, _ y: Double, r: Double = 16) {
        bumpers.append(Bumper(center: Vec(x + s.offset, y), radius: r))
    }

    mutating func water(_ s: Side, _ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double) {
        water.append(Box(minX + s.offset, minY, maxX + s.offset, maxY))
    }

    /// A pipe between two mouths (each on either hole). A ball rolling over one mouth pops out of the other.
    /// `exitA` / `exitB`: direction in degrees a ball leaves that mouth; nil keeps its incoming direction.
    mutating func tunnel(_ sa: Side, _ ax: Double, _ ay: Double, _ sb: Side, _ bx: Double, _ by: Double,
                         exitA: Double? = nil, exitB: Double? = nil) {
        tunnels.append(Tunnel(a: Vec(ax + sa.offset, ay), b: Vec(bx + sb.offset, by), exitA: exitA, exitB: exitB))
    }

    /// A tilted area. `downhill` in degrees (0 = right, 90 = up); strength in units/s², capped at 200 so balls can rest.
    mutating func slope(_ s: Side, _ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double,
                        downhill: Double, strength: Double = 140) {
        slopes.append(Slope(box: Box(minX + s.offset, minY, maxX + s.offset, maxY),
                            accel: .shot(degrees: downhill, speed: min(strength, 200))))
    }

    /// A round hill that pushes balls outward.
    mutating func hill(_ s: Side, _ x: Double, _ y: Double, radius: Double, strength: Double = 140) {
        mounds.append(Mound(center: Vec(x + s.offset, y), radius: radius, strength: min(strength, 200)))
    }

    /// A round bowl that pulls balls toward its center.
    mutating func bowl(_ s: Side, _ x: Double, _ y: Double, radius: Double, strength: Double = 140) {
        mounds.append(Mound(center: Vec(x + s.offset, y), radius: radius, strength: -min(strength, 200)))
    }

    /// A windmill-style spinner. rpm > 0 spins counter-clockwise; blades are at `phase` degrees when the pair loads.
    mutating func rotor(_ s: Side, _ x: Double, _ y: Double, blades: Int = 2, length: Double, rpm: Double, phase: Double = 0) {
        movers.append(Mover(kind: .rotor(pivot: Vec(x + s.offset, y), blades: blades, length: length,
                                         omega: rpm * 2 * .pi / 60, phase: phase * .pi / 180)))
    }

    /// A block that slides by (dx, dy) and back every `period` seconds, starting from this rect when the pair loads.
    mutating func slider(_ s: Side, _ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double,
                         dx: Double, dy: Double, period: Double) {
        movers.append(Mover(kind: .slider(box: Box(minX + s.offset, minY, maxX + s.offset, maxY),
                                          travel: Vec(dx, dy), period: period), radius: 3))
    }
}

enum Levels {
    /// The full course, in round order. Pairs 5, 7, 9 and 11–18 live in `Course/`.
    static let course: [Level] = [
        twins(), reflection(), bankShot(),           // Spring Meadow
        backboard(), hedgerow(),                     // Walled Garden
        moat(), drawbridge(),                        // Castle Moat
        pinball(), dunes(),                          // Seaside Boardwalk
        carom(), hollow(),                           // Autumn Grove
        canyonPipe(), mesa(),                        // Desert Canyon
        windmill(), sledRun(),                       // Winter Village
        crossover(), lanterns(), midnight(),         // Night Garden
    ]

    static func twins() -> Level {
        var l = Level("Twins", par: [2, 2], hint: "One swing moves both balls. Same hole twice — warm up.")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 100, 660); l.cup(.b, 100, 660)
        l.solution = Shot(angle: 90, power: 0.66)
        return l
    }

    static func reflection() -> Level {
        var l = Level("Reflection", par: [2, 2], hint: "These holes are mirror images. Try the Mirror swing.")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 50, 110); l.tee(.b, 150, 110)
        l.cup(.a, 150, 680); l.cup(.b, 50, 680)
        l.solution = Shot(angle: 122.5, power: 0.76, mirrored: true)
        return l
    }

    static func backboard() -> Level {
        var l = Level("Backboard", par: [2, 2], hint: "Hit it hard enough for the long one. The short one has a backboard.")
        l.setting = "garden"
        l.frame()
        l.block(.b, 0, 500, 200, 800)
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 100, 700); l.cup(.b, 100, 430)
        l.solution = Shot(angle: 90, power: 0.68)
        return l
    }

    static func bankShot() -> Level {
        var l = Level("Bank Shot", par: [2, 3], hint: "One hole wants it straight. The other wants a wall.")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 30, 110); l.tee(.b, 110, 110)
        l.cup(.a, 165, 640); l.cup(.b, 140, 700)
        l.block(.b, 50, 380, 150, 420)
        l.solution = Shot(angle: 108.75, power: 0.93)
        return l
    }

    static func moat() -> Level {
        var l = Level("Moat", par: [3, 3], hint: "Each moat has a dry crossing — on opposite sides.")
        l.setting = "moat"
        l.frame()
        l.water(.a, 0, 330, 140, 420)
        l.water(.b, 60, 330, 200, 420)
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 100, 700); l.cup(.b, 100, 700)
        l.solution = Shot(angle: 70.25, power: 0.71, mirrored: true)
        return l
    }

    static func pinball() -> Level {
        var l = Level("Buoys", par: [2, 2], hint: "Buoys give back everything you put in.")
        l.setting = "seaside"
        l.frame()
        l.bumper(.a, 100, 380, r: 20)
        l.bumper(.b, 60, 300, r: 16); l.bumper(.b, 150, 480, r: 16)
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 40, 720); l.cup(.b, 150, 700)
        l.solution = Shot(angle: 135.75, power: 0.92, mirrored: true)
        return l
    }

    static func crossover() -> Level {
        var l = Level("Crossover", par: [3, 2], hint: "A's lane is a dead end — both cups are in B's lane. Any ball, any cup.")
        l.setting = "night"
        l.frame(gaps: [520...640])
        l.block(.a, 0, 660, 200, 800)
        l.rail(.b, 100, 690, 100, 800)
        l.block(.b, 60, 300, 140, 340)
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cups = [Vec(250, 740), Vec(350, 740)]
        l.solution = Shot(angle: 126, power: 0.95, mirrored: true)
        return l
    }

    static func carom() -> Level {
        var l = Level("Carom", par: [2, 2], hint: "The holes share a green up top. Balls can hit each other.")
        l.setting = "autumn"
        l.frame()
        l.rails.removeLast()
        l.rails.append(Wall(a: Vec(Course.half, 0), b: Vec(Course.half, 480), radius: Course.railRadius))
        l.block(.a, 60, 560, 140, 600)
        l.block(.b, 60, 560, 140, 600)
        l.tee(.a, 120, 110); l.tee(.b, 60, 110)
        l.cup(.a, 140, 730); l.cup(.b, 60, 730)
        l.solution = Shot(angle: 53.5, power: 0.95, mirrored: true)
        return l
    }
}
