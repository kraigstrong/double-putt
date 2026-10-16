import UIKit

extension Painter {
    // MARK: Shaped greens

    func outlinePath(_ g: Green) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: g.outline.map { CGPoint(x: $0.x, y: $0.y) })
        path.closeSubpath()
        return path
    }

    /// Every shaped green as one path (for clipping).
    func greensPath(_ level: Level) -> CGPath? {
        let paths = level.greens.map(outlinePath)
        guard let first = paths.first else { return nil }
        return paths.dropFirst().reduce(first) { $0.union($1) }
    }

    private func curb(_ g: Green) -> CGPath {
        outlinePath(g).copy(strokingWithWidth: Course.railRadius * 2, lineCap: .round, lineJoin: .round, miterLimit: 1)
    }

    /// Shaped greens instead of the framed felt: each a raised slab with a drop shadow onto the ground, mown turf,
    /// and a collar of slightly longer grass just inside the edge.
    func greens(_ level: Level, _ t: Theme) {
        for g in level.greens {
            let path = outlinePath(g)
            shadow(dx: 3.5, dy: -6, blur: 10, alpha: 0.45) { fill(curb(g).union(path), .black) }
            clipped(path) {
                felt(t)
                stroke(path, t.feltDark.darker(0.12).withAlphaComponent(0.5), 16)
                stroke(path, t.feltDark.darker(0.2).withAlphaComponent(0.3), 7)
            }
        }
    }

    /// The curbs, for the shadow pass.
    func greenEdgeShapes(_ level: Level, fill color: UIColor) {
        for g in level.greens { fill(curb(g), color) }
    }

    /// Each green's edge: a smooth curb in the setting's border colours, rounded on top.
    func greenEdges(_ level: Level, _ t: Theme) {
        for g in level.greens {
            let band = curb(g)
            fill(band, t.borderTop)
            clipped(band) {
                stroke(outlinePath(g), t.borderTop.lighter(0.18), Course.railRadius * 0.8)
                noise(alpha: 0.12)
            }
            stroke(band, t.borderSide.darker(0.4), 0.8)
        }
    }
}
