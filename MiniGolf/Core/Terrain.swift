import Foundation

/// Smooth, contoured ground: a few shapes added together. Unlike `Slope` boxes, which switch on at their edges,
/// these rise and fall gradually, so a green can lean, step up a tier, and swell or dip in one piece. Every shape
/// is a cheap polynomial (no exp or trig per step) because the solver runs the physics millions of times.
struct Terrain {
    struct Feature {
        enum Kind {
            /// The area leans one way: a constant pull.
            case tilt(Vec)
            /// A bank across the area through `origin`, falling toward `normal` (unit). The pull is strongest on the
            /// line and fades to nothing `width` either side.
            case tier(origin: Vec, normal: Vec, strength: Double, width: Double)
            /// A round hump (amplitude > 0) or hollow (< 0), flat again at `radius`.
            case mound(center: Vec, radius: Double, amplitude: Double)
        }
        var kind: Kind
        /// Where the feature applies (usually its side), so one side's lean never leaks into the other.
        var area: Box
    }

    /// Contours can pull harder than the green (240) or fringe (330) can hold a ball, so a putt that comes up short on
    /// a steep bank rolls back down it, like a links false front; World.step lets such a ball roll on. Rough (520)
    /// holds anything up to this cap, so a runaway always stops. (Slope boxes and mounds stay at 200.)
    static let maxPull = 400.0
    /// A mound's steepest pull, as a multiple of amplitude / radius (at r = radius / √3).
    static let moundPeak = 8 / (3 * 3.0.squareRoot())

    var features: [Feature] = []
    var isEmpty: Bool { features.isEmpty }

    /// The downhill pull at `p`, in units/s².
    func accel(at p: Vec) -> Vec {
        var a = Vec.zero
        for f in features where f.area.contains(p) {
            switch f.kind {
            case .tilt(let v):
                a += v
            case let .tier(origin, normal, strength, width):
                let u = (p - origin).dot(normal) / width
                if u > -1 && u < 1 {
                    let k = 1 - u * u
                    a += normal * (strength * k * k)
                }
            case let .mound(center, radius, amplitude):
                let d = p - center
                let q = d.lengthSquared / (radius * radius)
                if q < 1 { a += d * (4 * amplitude * (1 - q) / (radius * radius)) }
            }
        }
        let m = a.lengthSquared
        return m > Self.maxPull * Self.maxPull ? a * (Self.maxPull / m.squareRoot()) : a
    }

    /// Ground height at `p`, for drawing (the pull is its downhill gradient, before the cap).
    func height(at p: Vec) -> Double {
        var h = 0.0
        for f in features where f.area.contains(p) {
            switch f.kind {
            case .tilt(let v):
                h -= v.dot(p - f.area.center)
            case let .tier(origin, normal, strength, width):
                let u = max(-1, min(1, (p - origin).dot(normal) / width))
                h -= strength * width * (u - 2 * u * u * u / 3 + u * u * u * u * u / 5)
            case let .mound(center, radius, amplitude):
                let q = (p - center).lengthSquared / (radius * radius)
                if q < 1 { h += amplitude * (1 - q) * (1 - q) }
            }
        }
        return h
    }
}

// MARK: - Builders

extension Level {
    // Contours take a side (`.a` / `.b`, x local to it, staying in it) or nil for the whole course (x 0–400), e.g.
    // on one green shared by both sides.

    /// The whole side leans toward `downhill` degrees (0 = right, 90 = up), pulling at `strength` units/s².
    mutating func tilt(_ s: Side?, downhill: Double, strength: Double) {
        terrain.features.append(.init(kind: .tilt(.shot(degrees: downhill, speed: min(strength, Terrain.maxPull))),
                                      area: Self.sideArea(s)))
    }

    /// A bank across the side through (x, y), falling toward `downhill` degrees: a step up to a higher tier.
    /// It pulls hardest (`strength`) on the line and fades out `width` either side.
    mutating func tier(_ s: Side?, _ x: Double, _ y: Double, downhill: Double, strength: Double, width: Double = 40) {
        terrain.features.append(.init(kind: .tier(origin: Vec(x + (s?.offset ?? 0), y), normal: .shot(degrees: downhill, speed: 1),
                                                  strength: min(strength, Terrain.maxPull), width: width),
                                      area: Self.sideArea(s)))
    }

    /// A rounded hump that sheds balls outward, pulling hardest (`strength`) a little over halfway out and flat
    /// again at `radius`.
    mutating func hump(_ s: Side?, _ x: Double, _ y: Double, radius: Double, strength: Double) {
        mound(s, x, y, radius: radius, strength: strength)
    }

    /// A rounded hollow that gathers balls toward its middle (great around a cup).
    mutating func hollow(_ s: Side?, _ x: Double, _ y: Double, radius: Double, strength: Double) {
        mound(s, x, y, radius: radius, strength: -strength)
    }

    private mutating func mound(_ s: Side?, _ x: Double, _ y: Double, radius: Double, strength: Double) {
        let pull = max(-Terrain.maxPull, min(strength, Terrain.maxPull))
        terrain.features.append(.init(kind: .mound(center: Vec(x + (s?.offset ?? 0), y), radius: radius,
                                                   amplitude: pull * radius / Terrain.moundPeak),
                                      area: Self.sideArea(s)))
    }

    private static func sideArea(_ s: Side?) -> Box {
        guard let s else { return Box(0, 0, Course.width, Course.height) }
        return Box(s.offset, 0, s.offset + Course.half, Course.height)
    }
}

// MARK: - Reading the ground (drawing)

extension Level {
    /// Whether anything tilts this pair's green.
    var hasGround: Bool { !slopes.isEmpty || !mounds.isEmpty || !terrain.isEmpty }

    /// Whether `p` sits on sloped green or fringe: in a slope box, a mound, or a side with terrain.
    func isSloped(at p: Vec) -> Bool {
        guard patches.isEmpty || surface(at: p).isTurf else { return false }
        return slopes.contains { $0.box.contains(p) }
            || mounds.contains { ($0.center - p).lengthSquared < $0.radius * $0.radius }
            || terrain.features.contains { $0.area.contains(p) }
    }

    /// The pull a ball feels at `p`: the same pieces `World.step` applies, added up.
    func groundAccel(at p: Vec) -> Vec {
        var a = Vec.zero
        for s in slopes where s.box.contains(p) { a += s.accel }
        for m in mounds {
            let d = p - m.center
            let dist = d.length
            if dist < m.radius && dist > 1 { a += d * (m.strength / dist) }
        }
        return a + terrain.accel(at: p)
    }

    /// Ground height at `p`, for tinting the grid. A slope box is a plane level with its surroundings at its centre;
    /// a hill is a cone (a bowl an upturned one).
    func groundHeight(at p: Vec) -> Double {
        var h = terrain.height(at: p)
        for s in slopes where s.box.contains(p) { h -= s.accel.dot(p - s.box.center) }
        for m in mounds {
            let r = (p - m.center).length
            if r < m.radius { h += m.strength * (m.radius - r) }
        }
        return h
    }
}
