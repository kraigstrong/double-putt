import Foundation

// Pure-Swift, deterministic physics shared by the game, the aim guide and the
// headless solver (Tools/solver). Fixed timestep, no randomness.

struct Vec: Equatable {
    var x: Double
    var y: Double

    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }

    static let zero = Vec(0, 0)

    static func + (a: Vec, b: Vec) -> Vec { Vec(a.x + b.x, a.y + b.y) }
    static func - (a: Vec, b: Vec) -> Vec { Vec(a.x - b.x, a.y - b.y) }
    static func * (a: Vec, s: Double) -> Vec { Vec(a.x * s, a.y * s) }
    static func += (a: inout Vec, b: Vec) { a = a + b }
    static func -= (a: inout Vec, b: Vec) { a = a - b }

    func dot(_ o: Vec) -> Double { x * o.x + y * o.y }
    var lengthSquared: Double { x * x + y * y }
    var length: Double { lengthSquared.squareRoot() }
    var normalized: Vec {
        let l = length
        return l > 0 ? Vec(x / l, y / l) : .zero
    }

    /// Angle in degrees, 0 = right, 90 = up.
    static func shot(degrees: Double, speed: Double) -> Vec {
        let r = degrees * .pi / 180
        return Vec(cos(r) * speed, sin(r) * speed)
    }
}

/// A rail: a capsule (segment with thickness). Walls, block edges and the divider are all rails.
struct Wall {
    var a: Vec
    var b: Vec
    var radius: Double
}

struct Bumper {
    var center: Vec
    var radius: Double
}

struct Box {
    var minX: Double, minY: Double, maxX: Double, maxY: Double

    init(_ minX: Double, _ minY: Double, _ maxX: Double, _ maxY: Double) {
        self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY
    }

    func contains(_ p: Vec) -> Bool { p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY }
    var width: Double { maxX - minX }
    var height: Double { maxY - minY }
    var center: Vec { Vec((minX + maxX) / 2, (minY + maxY) / 2) }
    func offset(_ v: Vec) -> Box { Box(minX + v.x, minY + v.y, maxX + v.x, maxY + v.y) }
}

/// A two-way pipe. A ball rolling over one mouth pops out of the other.
struct Tunnel {
    var a: Vec
    var b: Vec
    /// Direction (degrees) a ball leaves mouth `a` / `b`. nil keeps its incoming direction.
    var exitA: Double?
    var exitB: Double?

    static let radius = 11.0
    static let speedKept = 0.9
}

/// A tilted area that pushes rolling balls. Keep |accel| below Tuning.rollDecel so balls can rest on it.
struct Slope {
    var box: Box
    var accel: Vec
}

/// A round hill (strength > 0 pushes out) or bowl (strength < 0 pulls in). Same |strength| rule as slopes.
struct Mound {
    var center: Vec
    var radius: Double
    var strength: Double
}

/// Something that moves while balls roll. Every swing starts it from t = 0, so shots stay deterministic.
struct Mover {
    enum Kind {
        /// Blades spinning around a hub. omega in rad/s (positive = counter-clockwise), phase in radians.
        case rotor(pivot: Vec, blades: Int, length: Double, omega: Double, phase: Double)
        /// A block sliding from `box` to `box + travel` and back, smoothly, every `period` seconds.
        case slider(box: Box, travel: Vec, period: Double)
    }

    var kind: Kind
    var radius = 4.0

    static let hubRadius = 7.0
    static let restitution = 0.6

    func sliderOffset(at t: Double) -> Vec {
        guard case .slider(_, let travel, let period) = kind else { return .zero }
        return travel * (0.5 - 0.5 * cos(2 * .pi * t / period))
    }

    func bladeAngle(_ k: Int, at t: Double) -> Double {
        guard case .rotor(_, let blades, _, let omega, let phase) = kind else { return 0 }
        return phase + omega * t + 2 * .pi * Double(k) / Double(blades)
    }

    /// Calls `body` with each solid piece at time t and the surface velocity function for it.
    @inline(__always)
    func forEachWall(at t: Double, _ body: (Wall, (Vec) -> Vec) -> Void) {
        switch kind {
        case .rotor(let pivot, let blades, let length, let omega, _):
            let spin: (Vec) -> Vec = { p in Vec(-omega * (p.y - pivot.y), omega * (p.x - pivot.x)) }
            body(Wall(a: pivot, b: pivot, radius: Mover.hubRadius), spin)
            for k in 0..<blades {
                let a = bladeAngle(k, at: t)
                body(Wall(a: pivot, b: pivot + Vec(cos(a), sin(a)) * length, radius: radius), spin)
            }
        case .slider(let box, let travel, let period):
            let o = sliderOffset(at: t)
            let v = travel * (.pi / period * sin(2 * .pi * t / period))
            let b = box.offset(o)
            let surface: (Vec) -> Vec = { _ in v }
            let p0 = Vec(b.minX, b.minY), p1 = Vec(b.maxX, b.minY), p2 = Vec(b.maxX, b.maxY), p3 = Vec(b.minX, b.maxY)
            body(Wall(a: p0, b: p1, radius: radius), surface)
            body(Wall(a: p1, b: p2, radius: radius), surface)
            body(Wall(a: p2, b: p3, radius: radius), surface)
            body(Wall(a: p3, b: p0, radius: radius), surface)
        }
    }
}

struct Ball {
    var pos: Vec
    var vel: Vec = .zero
    /// Where the current shot started; water sends the ball back here.
    var restPos: Vec
    var sunkIn: Int?
    /// The tunnel mouth this ball just came out of; ignored until the ball rolls clear.
    var ignoreMouth: Vec?

    init(at p: Vec) { pos = p; restPos = p }

    var isMoving: Bool { sunkIn == nil && (vel.x != 0 || vel.y != 0) }
}

enum PhysicsEvent {
    case wall(ball: Int, speed: Double)
    case bumper(ball: Int, speed: Double)
    case balls(a: Int, b: Int, speed: Double)
    case sunk(ball: Int, cup: Int)
    case splash(ball: Int, at: Vec)
    case tunnel(ball: Int, from: Vec, to: Vec)

    var contactBalls: [Int] {
        switch self {
        case .wall(let b, _), .bumper(let b, _): return [b]
        case .balls(let a, let b, _): return [a, b]
        case .sunk, .splash, .tunnel: return []
        }
    }
}

enum Tuning {
    static let ballRadius = 7.0
    static let cupRadius = 12.0
    static let maxShotSpeed = 1050.0
    static let rollDecel = 240.0       // constant rolling resistance, units/s²
    static let drag = 0.35             // proportional drag, 1/s
    static let stopSpeed = 5.0
    static let captureSpeed = 330.0    // faster than this and the ball lips out
    static let cupPull = 1400.0        // slope into the cup, units/s²
    static let wallRestitution = 0.72
    static let bumperRestitution = 1.0
    static let ballRestitution = 0.92
    static let dt = 1.0 / 480.0
}

struct World {
    var balls: [Ball]
    var cups: [Vec]
    var cupTaken: [Bool]
    var walls: [Wall]
    var bumpers: [Bumper]
    var water: [Box]
    var tunnels: [Tunnel]
    var slopes: [Slope]
    var mounds: [Mound]
    var movers: [Mover]
    /// Seconds since the current swing started (drives movers).
    var time = 0.0
    /// Aim-guide tracing: no rolling friction, so the guide's length never depends on where the ball stops.
    var frictionless = false

    init(level: Level) {
        balls = level.tees.map { Ball(at: $0) }
        cups = level.cups
        cupTaken = level.cups.map { _ in false }
        walls = level.walls
        bumpers = level.bumpers
        water = level.water
        tunnels = level.tunnels
        slopes = level.slopes
        mounds = level.mounds
        movers = level.movers
    }

    var isSettled: Bool { !balls.contains { $0.isMoving } }
    var allSunk: Bool { balls.allSatisfy { $0.sunkIn != nil } }

    mutating func shoot(_ v: Vec, mirrored: Bool) {
        time = 0
        resetMovers()
        for i in balls.indices where balls[i].sunkIn == nil {
            balls[i].restPos = balls[i].pos
            balls[i].vel = (mirrored && i == 1) ? Vec(-v.x, v.y) : v
        }
    }

    /// Movers return to their start pose; nudge any resting ball they would overlap.
    mutating func resetMovers() {
        time = 0
        guard !movers.isEmpty else { return }
        let r = Tuning.ballRadius
        for i in balls.indices where balls[i].sunkIn == nil {
            for m in movers {
                m.forEachWall(at: 0) { w, _ in
                    let q = closestPoint(balls[i].pos, w.a, w.b)
                    let d = balls[i].pos - q
                    let minDist = r + w.radius + 0.5
                    if d.lengthSquared < minDist * minDist {
                        let n = d.lengthSquared > 0 ? d.normalized : Vec(0, -1)
                        balls[i].pos = q + n * minDist
                    }
                }
            }
        }
    }

    /// Advance one fixed substep (Tuning.dt).
    mutating func step(_ events: inout [PhysicsEvent]) {
        let dt = Tuning.dt
        let r = Tuning.ballRadius
        time += dt

        for i in balls.indices where balls[i].sunkIn == nil {
            var b = balls[i]
            let wasMoving = b.isMoving
            if wasMoving {
                b.pos += b.vel * dt

                for w in walls {
                    let q = closestPoint(b.pos, w.a, w.b)
                    let d = b.pos - q
                    let minDist = r + w.radius
                    let distSq = d.lengthSquared
                    if distSq < minDist * minDist && distSq > 0 {
                        let n = d * (1 / distSq.squareRoot())
                        b.pos = q + n * minDist
                        let vn = b.vel.dot(n)
                        if vn < 0 {
                            b.vel -= n * ((1 + Tuning.wallRestitution) * vn)
                            events.append(.wall(ball: i, speed: -vn))
                        }
                    }
                }

                for bp in bumpers {
                    let d = b.pos - bp.center
                    let minDist = r + bp.radius
                    let distSq = d.lengthSquared
                    if distSq < minDist * minDist && distSq > 0 {
                        let n = d * (1 / distSq.squareRoot())
                        b.pos = bp.center + n * minDist
                        let vn = b.vel.dot(n)
                        if vn < 0 {
                            b.vel -= n * ((1 + Tuning.bumperRestitution) * vn)
                            events.append(.bumper(ball: i, speed: -vn))
                        }
                    }
                }
            }

            // Movers also shove resting balls.
            if !movers.isEmpty {
                let t = time
                for m in movers {
                    m.forEachWall(at: t) { w, surface in
                        let q = closestPoint(b.pos, w.a, w.b)
                        let d = b.pos - q
                        let minDist = r + w.radius
                        let distSq = d.lengthSquared
                        guard distSq < minDist * minDist else { return }
                        let n = distSq > 0 ? d * (1 / distSq.squareRoot()) : Vec(0, 1)
                        b.pos = q + n * minDist
                        let u = surface(q)
                        let vn = (b.vel - u).dot(n)
                        if vn < 0 {
                            b.vel -= n * ((1 + Mover.restitution) * vn)
                            if -vn > 20 { events.append(.wall(ball: i, speed: -vn)) }
                        }
                    }
                }
            }
            balls[i] = b
        }

        // Ball-ball (equal mass).
        if balls.count == 2, balls[0].sunkIn == nil, balls[1].sunkIn == nil,
           balls[0].isMoving || balls[1].isMoving {
            let d = balls[0].pos - balls[1].pos
            let distSq = d.lengthSquared
            if distSq < 4 * r * r && distSq > 0 {
                let dist = distSq.squareRoot()
                let n = d * (1 / dist)
                let push = (2 * r - dist) / 2
                balls[0].pos += n * push
                balls[1].pos -= n * push
                let rv = (balls[0].vel - balls[1].vel).dot(n)
                if rv < 0 {
                    let j = -(1 + Tuning.ballRestitution) * rv / 2
                    balls[0].vel += n * j
                    balls[1].vel -= n * j
                    events.append(.balls(a: 0, b: 1, speed: -rv))
                }
            }
        }

        for i in balls.indices where balls[i].isMoving {
            var b = balls[i]
            var speed = b.vel.length
            var overCup = false

            for c in cups.indices where !cupTaken[c] {
                let toCup = cups[c] - b.pos
                let dist = toCup.length
                guard dist < Tuning.cupRadius else { continue }
                overCup = true
                // Slow balls drop near the rim; faster ones need to be closer to center.
                let dropRadius = Tuning.cupRadius * (1 - 0.6 * speed / Tuning.captureSpeed)
                if speed < Tuning.captureSpeed && dist < max(dropRadius, 3) {
                    b.sunkIn = c
                    b.pos = cups[c]
                    b.vel = .zero
                    cupTaken[c] = true
                    events.append(.sunk(ball: i, cup: c))
                    break
                }
                b.vel += toCup.normalized * (Tuning.cupPull * dt)
            }
            if b.sunkIn != nil { balls[i] = b; continue }

            if !tunnels.isEmpty {
                let rr = Tunnel.radius * Tunnel.radius
                for t in tunnels {
                    let from: Vec, to: Vec, exit: Double?
                    if b.ignoreMouth != t.a && (b.pos - t.a).lengthSquared < rr {
                        (from, to, exit) = (t.a, t.b, t.exitB)
                    } else if b.ignoreMouth != t.b && (b.pos - t.b).lengthSquared < rr {
                        (from, to, exit) = (t.b, t.a, t.exitA)
                    } else {
                        continue
                    }
                    events.append(.tunnel(ball: i, from: from, to: to))
                    let s = b.vel.length * Tunnel.speedKept
                    b.vel = exit.map { Vec.shot(degrees: $0, speed: s) } ?? b.vel * Tunnel.speedKept
                    b.pos = to
                    b.ignoreMouth = to
                    break
                }
                if let m = b.ignoreMouth, (b.pos - m).length > Tunnel.radius + 2 { b.ignoreMouth = nil }
            }

            if water.contains(where: { $0.contains(b.pos) }) {
                events.append(.splash(ball: i, at: b.pos))
                b.pos = b.restPos
                b.vel = .zero
                b.ignoreMouth = nil
                balls[i] = b
                continue
            }

            for s in slopes where s.box.contains(b.pos) { b.vel += s.accel * dt }
            for m in mounds {
                let d = b.pos - m.center
                let dist = d.length
                if dist < m.radius && dist > 1 { b.vel += d * (m.strength * dt / dist) }
            }

            speed = b.vel.length
            let newSpeed = frictionless ? speed : (speed - Tuning.rollDecel * dt) * (1 - Tuning.drag * dt)
            if newSpeed <= Tuning.stopSpeed && !overCup {
                b.vel = .zero
            } else {
                b.vel = b.vel * (max(newSpeed, Tuning.stopSpeed) / speed)
            }
            balls[i] = b
        }
    }

    // MARK: - Simulation helpers (aim guide + solver)

    struct Outcome {
        var world: World
        var splashed: [Bool]
        var ballHits = 0
        var tunnels = 0
    }

    /// Run a whole shot to rest.
    func simulate(shot v: Vec, mirrored: Bool, maxSeconds: Double = 20) -> Outcome {
        var w = self
        w.shoot(v, mirrored: mirrored)
        var events: [PhysicsEvent] = []
        var out = Outcome(world: w, splashed: balls.map { _ in false })
        let maxSteps = Int(maxSeconds / Tuning.dt)
        var n = 0
        while !w.isSettled && n < maxSteps {
            events.removeAll(keepingCapacity: true)
            w.step(&events)
            for e in events {
                switch e {
                case .splash(let b, _): out.splashed[b] = true
                case .balls: out.ballHits += 1
                case .tunnel: out.tunnels += 1
                default: break
                }
            }
            n += 1
        }
        out.world = w
        return out
    }

    enum GuideEnd { case rolling, rest, sunk, splash }

    struct GuidePath {
        struct Piece {
            var points: [Vec]
            /// After the first contact or a tunnel: drawn lighter.
            var faded: Bool
        }
        var pieces: [Piece] = []
        /// First-contact points and tunnel mouths.
        var markers: [Vec] = []
        var end: GuideEnd = .rolling
        var endPoint: Vec? { pieces.last?.points.last }

        mutating func add(_ p: Vec) { pieces[pieces.count - 1].points.append(p) }
    }

    /// Trace each ball's path. With `fullPath` false, stops `afterContact` units after the ball's first contact
    /// (or tunnel), or after `maxLength` units, whichever comes first.
    func guide(shot v: Vec, mirrored: Bool, fullPath: Bool, afterContact: Double = 55, maxLength: Double = 320) -> [GuidePath] {
        var w = self
        if !fullPath {
            // The short guide is an aim line, not a prediction: no friction, cups or water, so it never
            // shows where the ball stops, whether it drops, or whether it reaches the water.
            w.frictionless = true
            w.cupTaken = w.cupTaken.map { _ in true }
            w.water = []
        }
        w.shoot(v, mirrored: mirrored)
        var paths = w.balls.map { b -> GuidePath in
            var p = GuidePath()
            p.pieces = [.init(points: [b.pos], faded: false)]
            if b.sunkIn != nil { p.end = .sunk }
            return p
        }
        var tracing = balls.map { $0.sunkIn == nil }
        var contacted = balls.map { _ in false }
        var travelAfter = balls.map { _ in 0.0 }
        var travel = balls.map { _ in 0.0 }
        var events: [PhysicsEvent] = []
        let maxSteps = Int(14 / Tuning.dt)
        var n = 0
        while tracing.contains(true) && n < maxSteps {
            let before = w.balls.map(\.pos)
            var teleported = balls.map { _ in false }
            events.removeAll(keepingCapacity: true)
            w.step(&events)
            n += 1
            for e in events {
                for b in e.contactBalls where tracing[b] && !contacted[b] {
                    contacted[b] = true
                    let p = w.balls[b].pos
                    paths[b].add(p)
                    paths[b].markers.append(p)
                    paths[b].pieces.append(.init(points: [p], faded: true))
                }
                switch e {
                case .tunnel(let b, let from, let to) where tracing[b]:
                    paths[b].add(from)
                    paths[b].markers.append(from)
                    paths[b].markers.append(to)
                    paths[b].pieces.append(.init(points: [to], faded: true))
                    contacted[b] = true
                    travelAfter[b] = 0
                    teleported[b] = true
                case .sunk(let b, _) where tracing[b]:
                    paths[b].add(w.balls[b].pos); paths[b].end = .sunk; tracing[b] = false
                case .splash(let b, let at) where tracing[b]:
                    paths[b].add(at); paths[b].end = .splash; tracing[b] = false
                default: break
                }
            }
            for b in w.balls.indices where tracing[b] {
                let moved = teleported[b] ? 0 : (w.balls[b].pos - before[b]).length
                travel[b] += moved
                if contacted[b] { travelAfter[b] += moved }
                if n % 6 == 0 { paths[b].add(w.balls[b].pos) }
                if !w.balls[b].isMoving {
                    paths[b].add(w.balls[b].pos); paths[b].end = .rest; tracing[b] = false
                } else if !fullPath && (travelAfter[b] >= afterContact || travel[b] >= maxLength) {
                    paths[b].add(w.balls[b].pos); tracing[b] = false
                }
            }
        }
        return paths
    }
}

@inline(__always)
func closestPoint(_ p: Vec, _ a: Vec, _ b: Vec) -> Vec {
    let ab = b - a
    let lenSq = ab.lengthSquared
    if lenSq == 0 { return a }
    let t = min(max((p - a).dot(ab) / lenSq, 0), 1)
    return a + ab * t
}
