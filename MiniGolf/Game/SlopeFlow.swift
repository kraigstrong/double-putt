import Foundation

/// The dots that glide along the slope grid (the grid itself is drawn in the course art): downhill along each line,
/// faster where the ground is steeper and still where it's flat. They keep an even gap: where two flows meet in a
/// dip the extra dots fade out, and where flows spread apart new ones fade in. A pure model; the scene draws it.
struct SlopeFlow {
    /// The grid square, five across a side, in course units.
    static let grid = Course.half / 5
    /// The gap the dots keep along a line: wider than a square, so the grid carries the shape and the dots stay sparse.
    static let dotGap = grid * 1.5
    /// Dot speed for each unit of pull along its line (units/s per units/s²).
    static let speedPerPull = 0.2
    /// Gentler pulls read as flat: the dots sit still.
    static let flatPull = 3.0
    /// Seconds for a dot to fade in or out.
    static let fade = 0.35

    struct Dot {
        enum Phase { case fadingIn, steady, fadingOut }
        var s: Double
        var alpha: Double
        var phase: Phase
    }

    /// One unbroken stretch of a grid line on sloped ground.
    struct Track {
        var vertical: Bool
        /// x of a vertical line, y of a horizontal one.
        var fixed: Double
        var start: Double
        /// Dot speed every unit from `start`, positive toward larger coordinates.
        var speeds: [Double]
        var dots: [Dot] = []

        var end: Double { start + Double(speeds.count - 1) }
        func speed(at s: Double) -> Double { speeds[max(0, min(speeds.count - 1, Int((s - start).rounded())))] }
        func point(_ s: Double) -> Vec { vertical ? Vec(fixed, s) : Vec(s, fixed) }
    }

    private(set) var tracks: [Track] = []
    var isEmpty: Bool { tracks.isEmpty }

    init(level: Level) {
        guard level.hasGround else { return }
        let gap = Self.grid
        var x = gap
        while x < Course.width - 1 {
            if abs(x - Course.half) > 1 { addTracks(vertical: true, fixed: x, length: Course.height, level) }
            x += gap
        }
        var y = gap
        while y < Course.height - 1 {
            addTracks(vertical: false, fixed: y, length: Course.width, level)
            y += gap
        }
    }

    /// Splits one grid line into tracks: the stretches on sloped ground clear of walls, cups and the like.
    private mutating func addTracks(vertical: Bool, fixed: Double, length: Double, _ level: Level) {
        var runStart: Double?
        var s = 0.0
        while s <= length {
            let p = vertical ? Vec(fixed, s) : Vec(s, fixed)
            let open = s < length && level.isSloped(at: p) && !Self.blocked(p, level)
            if open && runStart == nil { runStart = s }
            if !open, let a = runStart {
                if s - 1 - a >= 8 {
                    let speeds = stride(from: a, through: s - 1, by: 1).map { u -> Double in
                        let pull = level.groundAccel(at: vertical ? Vec(fixed, u) : Vec(u, fixed))
                        let along = vertical ? pull.y : pull.x
                        return abs(along) < Self.flatPull ? 0 : along * Self.speedPerPull
                    }
                    var t = Track(vertical: vertical, fixed: fixed, start: a, speeds: speeds)
                    var d = a + Double.random(in: 0..<Self.dotGap)
                    while d <= t.end { t.dots.append(Dot(s: d, alpha: 1, phase: .steady)); d += Self.dotGap }
                    tracks.append(t)
                }
                runStart = nil
            }
            s += 1
        }
    }

    /// Spots a dot shouldn't cross: walls and blocks, water, cups, pipe mouths, pads and posts.
    private static func blocked(_ p: Vec, _ level: Level) -> Bool {
        let clear = 3.0
        if p.x < clear || p.y < clear || p.x > Course.width - clear || p.y > Course.height - clear { return true }
        for w in level.walls where (p - closestPoint(p, w.a, w.b)).length < w.radius + clear { return true }
        let r = Course.blockRadius + clear
        for b in level.blocks where p.x > b.minX - r && p.x < b.maxX + r && p.y > b.minY - r && p.y < b.maxY + r { return true }
        if level.water.contains(where: { $0.contains(p) }) { return true }
        for c in level.cups where (p - c).length < Tuning.cupRadius + clear { return true }
        for t in level.tunnels where (p - t.a).length < Tunnel.radius + clear || (p - t.b).length < Tunnel.radius + clear {
            return true
        }
        for k in level.kickers where (p - k.center).length < Kicker.radius + clear { return true }
        for b in level.bumpers where (p - b.center).length < b.radius + clear { return true }
        return false
    }

    mutating func update(dt: Double) {
        for i in tracks.indices { Self.step(&tracks[i], dt: dt) }
    }

    private static func step(_ t: inout Track, dt: Double) {
        let gap = dotGap
        for k in t.dots.indices {
            t.dots[k].s += t.speed(at: t.dots[k].s) * dt
            switch t.dots[k].phase {
            case .fadingIn:
                t.dots[k].alpha = min(1, t.dots[k].alpha + dt / fade)
                if t.dots[k].alpha >= 1 { t.dots[k].phase = .steady }
            case .fadingOut:
                t.dots[k].alpha -= dt / fade
            case .steady:
                break
            }
        }
        let start = t.start, end = t.end
        t.dots.removeAll { $0.s < start - 1 || $0.s > end + 1 || ($0.phase == .fadingOut && $0.alpha <= 0) }
        t.dots.sort { $0.s < $1.s }

        // Crowded where flows meet: the later dot fades out.
        var previous: Double?
        for k in t.dots.indices where t.dots[k].phase != .fadingOut {
            if let p = previous, t.dots[k].s - p < gap * 0.55 {
                t.dots[k].phase = .fadingOut
            } else {
                previous = t.dots[k].s
            }
        }

        // Spread out where flows part, or behind the last dot in from an end: a new one fades in.
        let live = t.dots.filter { $0.phase != .fadingOut }.map(\.s)
        guard let first = live.first, let last = live.last else {
            t.dots.append(Dot(s: (start + end) / 2, alpha: 0, phase: .fadingIn))
            return
        }
        var born: [Double] = []
        if first - start > gap { born.append(first - gap) }
        if end - last > gap { born.append(last + gap) }
        for (a, b) in zip(live, live.dropFirst()) where b - a > gap * 1.6 { born.append((a + b) / 2) }
        t.dots += born.map { Dot(s: $0, alpha: 0, phase: .fadingIn) }
    }

    /// Each dot's position and opacity. Dots also fade within a few units of a track's ends.
    func forEachDot(_ body: (Vec, Double) -> Void) {
        for t in tracks {
            for d in t.dots {
                let a = d.alpha * max(0, min(1, (d.s - t.start) / 6, (t.end - d.s) / 6))
                if a > 0.02 { body(t.point(d.s), a) }
            }
        }
    }
}
