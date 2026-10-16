import Foundation

/// What the ground is made of. Inside the usual frame a hole can be painted with shapes of each, so a green's shape
/// comes from what surrounds it, and a ball can roll from one to the next, losing pace as it goes.
enum Surface: UInt8 {
    case green, fringe, rough, sand, water

    /// Constant rolling resistance, units/s². Above any slope's pull (200), so a ball can rest on all of them.
    var rollDecel: Double {
        switch self {
        case .green, .water: return Tuning.rollDecel
        case .fringe: return 420
        case .rough: return 800
        case .sand: return 2400
        }
    }

    /// Proportional drag, 1/s.
    var drag: Double {
        switch self {
        case .green, .water: return Tuning.drag
        case .fringe: return 0.6
        case .rough: return 1.0
        case .sand: return 1.5
        }
    }

    /// Ground the slope grid and its dots show on (not sand or water).
    var isTurf: Bool { self == .green || self == .fringe || self == .rough }
}

/// One painted shape of a surface. Patches are painted in order, so a later one covers an earlier one.
struct Patch {
    var surface: Surface
    /// Closed outline in course coordinates (the last point joins the first). Curvy shapes are already sampled into
    /// short straight pieces.
    var outline: [Vec]
    /// Grows the shape by this much all round (a green's fringe is its outline grown by the collar's width).
    var pad = 0.0

    func contains(_ p: Vec) -> Bool {
        var inside = false
        var j = outline.count - 1
        for i in outline.indices {
            let a = outline[i], b = outline[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        if inside || pad <= 0 { return inside }
        let rr = pad * pad
        return outline.indices.contains { (p - closestPoint(p, outline[$0], outline[($0 + 1) % outline.count])).lengthSquared <= rr }
    }

    /// Bounding box, pad included.
    var bounds: Box {
        Box(outline.map(\.x).min()! - pad, outline.map(\.y).min()! - pad, outline.map(\.x).max()! + pad, outline.map(\.y).max()! + pad)
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

/// The painted surfaces baked into a 2-unit grid, so the physics looks a ball's ground up in one step.
struct SurfaceMap {
    static let cell = 2.0
    let cols: Int, rows: Int
    let cells: [UInt8]

    init(_ patches: [Patch]) {
        cols = Int(Course.width / Self.cell)
        rows = Int(Course.height / Self.cell)
        var cells = [UInt8](repeating: Surface.green.rawValue, count: cols * rows)
        for patch in patches {
            let b = patch.bounds
            let c0 = max(0, Int(b.minX / Self.cell)), c1 = min(cols - 1, Int(b.maxX / Self.cell))
            let r0 = max(0, Int(b.minY / Self.cell)), r1 = min(rows - 1, Int(b.maxY / Self.cell))
            guard c0 <= c1, r0 <= r1 else { continue }
            for r in r0...r1 {
                for c in c0...c1 where patch.contains(Vec((Double(c) + 0.5) * Self.cell, (Double(r) + 0.5) * Self.cell)) {
                    cells[r * cols + c] = patch.surface.rawValue
                }
            }
        }
        self.cells = cells
    }

    func at(_ p: Vec) -> Surface {
        let c = max(0, min(cols - 1, Int(p.x / Self.cell))), r = max(0, min(rows - 1, Int(p.y / Self.cell)))
        return Surface(rawValue: cells[r * cols + c]) ?? .green
    }
}

// MARK: - Builders

extension Level {
    /// Paints `surface` in a shape on one hole (points local to it, x 0–200) or, with nil, anywhere on the course
    /// (x 0–400). Later paint covers earlier. `smooth` runs a curve through the points; otherwise edges are straight.
    mutating func paint(_ surface: Surface, _ s: Side?, _ points: [(Double, Double)], smooth: Bool = false, pad: Double = 0) {
        let pts = points.map { Vec($0.0 + (s?.offset ?? 0), $0.1) }
        patches.append(Patch(surface: surface, outline: smooth ? Patch.curve(through: pts) : pts, pad: pad))
    }

    /// Covers a whole hole (or, with nil, the course) in `surface`: the ground a green sits in.
    mutating func ground(_ surface: Surface, _ s: Side?) {
        let w = s == nil ? Course.width : Course.half
        paint(surface, s, [(0, 0), (w, 0), (w, Course.height), (0, Course.height)])
    }

    /// A green in this shape, with a collar of fringe `fringe` wide round it.
    mutating func green(_ s: Side?, _ points: [(Double, Double)], smooth: Bool = true, fringe: Double = 14) {
        if fringe > 0 { paint(.fringe, s, points, smooth: smooth, pad: fringe) }
        paint(.green, s, points, smooth: smooth)
    }

    /// The surface at `p`: the last patch painted there, or green.
    func surface(at p: Vec) -> Surface { patches.last { $0.contains(p) }?.surface ?? .green }
}
