import Foundation

/// A shaped green: a closed outline with a wall all the way round, so balls bank off its edge, and turf only inside.
/// A pair with greens has no rectangular frame; the ground shows round them.
struct Green {
    /// Closed outline in course coordinates (the last point joins the first). Curvy greens are already sampled into
    /// short straight pieces.
    var outline: [Vec]

    /// The wall round the edge, one rail per piece of the outline.
    var edges: [Wall] {
        outline.indices.map { Wall(a: outline[$0], b: outline[($0 + 1) % outline.count], radius: Course.railRadius) }
    }

    /// Whether `p` is inside the outline (even-odd).
    func contains(_ p: Vec) -> Bool {
        var inside = false
        var j = outline.count - 1
        for i in outline.indices {
            let a = outline[i], b = outline[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        return inside
    }

    /// A smooth closed curve through `points` (Catmull-Rom), cut into pieces about `piece` units long.
    static func curve(through points: [Vec], piece: Double = 8) -> [Vec] {
        let n = points.count
        guard n >= 3 else { return points }
        var out: [Vec] = []
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n], p1 = points[i], p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            let steps = max(2, Int(((p2 - p1).length / piece).rounded(.up)))
            for k in 0..<steps {
                let t = Double(k) / Double(steps), t2 = t * t, t3 = t2 * t
                let a = p1 * 2, b = (p2 - p0) * t, c = (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2, d = (p1 * 3 - p0 - p2 * 3 + p3) * t3
                out.append((a + b + c + d) * 0.5)
            }
        }
        return out
    }
}

// MARK: - Builders

extension Level {
    /// A shaped green on one hole, outline points local to that hole (x 0–200). `smooth` runs a curve through the
    /// points (kidneys, rounds); otherwise the edges are straight (doglegs, diamonds).
    mutating func green(_ s: Side, _ points: [(Double, Double)], smooth: Bool = false) {
        green(points.map { Vec($0.0 + s.offset, $0.1) }, smooth: smooth)
    }

    /// A shaped green in course coordinates (x 0–400), e.g. one shared green across both holes.
    mutating func green(_ points: [Vec], smooth: Bool = false) {
        greens.append(Green(outline: smooth ? Green.curve(through: points) : points))
    }

    /// Whether `p` is on playable turf: inside a shaped green, or anywhere when the pair has none.
    func onGreen(_ p: Vec) -> Bool { greens.isEmpty || greens.contains { $0.contains(p) } }
}
