import UIKit

extension Painter {
    // MARK: Painted surfaces

    /// A patch's shape, grown by its pad (a fringe is its green's outline grown by the collar).
    func patchPath(_ p: Patch) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: p.outline.map { CGPoint(x: $0.x, y: $0.y) })
        path.closeSubpath()
        guard p.pad > 0 else { return path }
        return path.copy(strokingWithWidth: p.pad * 2, lineCap: .round, lineJoin: .round, miterLimit: 1).union(path)
    }

    /// The painted surfaces over the felt, in order, so later ones cover earlier ones (as in the physics).
    func surfaces(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        for p in level.patches {
            let path = patchPath(p)
            switch p.surface {
            case .green: clipped(path) { felt(t) }
            case .fringe: fringe(path, t)
            case .rough: rough(path, t, &rng)
            case .sand: sand(path, &rng)
            case .water:
                let b = path.boundingBox
                pond(CourseArt.Pond(parts: [b.insetBy(dx: b.width * 0.3, dy: b.height * 0.3)], path: path), t, &rng)
            }
        }
    }

    /// Fringe: the green's grass left a little longer, so a touch darker, with a tight mow.
    private func fringe(_ path: CGPath, _ t: Theme) {
        let b = path.boundingBox
        clipped(path) {
            fill(b, t.feltDark.darker(0.1))
            for y in stride(from: b.minY.rounded(.down), to: b.maxY, by: 12) {
                fill(CGRect(x: b.minX, y: y, width: b.width, height: 6), t.feltLight.darker(0.14).withAlphaComponent(0.7))
            }
            noise(alpha: 0.16)
        }
    }

    /// Rough: long, darker grass in tufts.
    private func rough(_ path: CGPath, _ t: Theme, _ rng: inout SeededRandom) {
        let b = path.boundingBox
        let base = t.feltDark.darker(0.3)
        clipped(path) {
            fill(b, base)
            let tufts = Int(b.width * b.height / 30)
            for _ in 0..<tufts {
                let p = CGPoint(x: rng.range(b.minX, b.maxX), y: rng.range(b.minY, b.maxY))
                let a = rng.range(-0.5, 0.5) + .pi / 2, len = rng.range(3, 6)
                let blade = CourseArt.line(p, CGPoint(x: p.x + cos(a) * len, y: p.y + sin(a) * len))
                stroke(blade, (rng.unit() < 0.5 ? base.darker(0.2) : base.lighter(0.16)).withAlphaComponent(0.8), 1)
            }
            noise(alpha: 0.2)
        }
    }

    /// Sand: a raked bunker, lit from the top left, with a shaded lip where it drops below the turf.
    private func sand(_ path: CGPath, _ rng: inout SeededRandom) {
        let b = path.boundingBox
        let light = UIColor(hex: 0xEEDCAE), dark = UIColor(hex: 0xD4BC86)
        linear(path, [light, dark], from: CGPoint(x: b.minX, y: b.maxY), to: CGPoint(x: b.maxX, y: b.minY))
        clipped(path) {
            // Rake lines: gentle parallel arcs.
            for y in stride(from: b.minY - b.width * 0.2, to: b.maxY, by: 7) {
                let arc = CGMutablePath()
                arc.move(to: CGPoint(x: b.minX, y: y))
                arc.addQuadCurve(to: CGPoint(x: b.maxX, y: y), control: CGPoint(x: b.midX, y: y + b.width * 0.2))
                stroke(arc, UIColor.white.withAlphaComponent(0.22), 1)
            }
            for _ in 0..<Int(b.width * b.height / 14) {
                let p = CGPoint(x: rng.range(b.minX, b.maxX), y: rng.range(b.minY, b.maxY))
                fill(circle(p, 0.5), (rng.unit() < 0.5 ? dark.darker(0.2) : UIColor.white).withAlphaComponent(0.5))
            }
            // The lip: shadow cast in from the edge.
            shadow(dx: 2.5, dy: -3.5, blur: 5, alpha: 0.4) {
                let ring = CGMutablePath()
                ring.addRect(b.insetBy(dx: -30, dy: -30))
                ring.addPath(path)
                fill(ring, .black, evenOdd: true)
            }
        }
        stroke(path, dark.darker(0.25).withAlphaComponent(0.8), 1)
    }
}
