import UIKit

extension Painter {
    // MARK: Grandstands (the Stadium)

    /// Each grandstand's footprint, for the shadow pass.
    func standShapes(_ level: Level, fill color: UIColor) {
        for s in level.stands { fill(Self.standPath(s), color) }
    }

    /// Grandstands: rows of seats stepping up from a white front rail (the face you bank off) to a back wall, with a
    /// crowd dotted along the rows.
    func stands(_ level: Level, _ rng: inout SeededRandom) {
        let seats = UIColor(hex: 0x2F6F8F)
        let shirts = [UIColor(hex: 0xF4F1EA), UIColor(hex: 0xE0533D), UIColor(hex: 0xF2C14E), UIColor(hex: 0x3E7CB1),
                      UIColor(hex: 0x6BBF59), UIColor(hex: 0x1F2A36), UIColor(hex: 0xE88EB4)]
        let skin = [UIColor(hex: 0xF1C7A1), UIColor(hex: 0xC98E63), UIColor(hex: 0x8D5A3B), UIColor(hex: 0xE5B48A)]
        for s in level.stands {
            let c = s.corners.map { CGPoint(x: $0.x, y: $0.y) }
            let path = Self.standPath(s)
            fill(path, UIColor(hex: 0x8E959C))
            // Rows run front (0) to back (1): the left edge is c[0] → c[3], the right c[1] → c[2].
            func at(_ along: CGFloat, _ back: CGFloat) -> CGPoint {
                let l = lerp(c[0], c[3], back), r = lerp(c[1], c[2], back)
                return lerp(l, r, along)
            }
            let rows = max(3, Int(s.depth / 7)), wall: CGFloat = 0.14
            clipped(path) {
                for k in 0..<rows {
                    let b0 = CGFloat(k) / CGFloat(rows) * (1 - wall), b1 = CGFloat(k + 1) / CGFloat(rows) * (1 - wall)
                    let row = CGMutablePath()
                    row.addLines(between: [at(0, b0), at(1, b0), at(1, b1), at(0, b1)])
                    row.closeSubpath()
                    // Higher rows catch a little more light.
                    fill(row, seats.mixed(with: .white, 0.06 * CGFloat(k)))
                    stroke(CourseArt.line(at(0, b1), at(1, b1)), UIColor.black.withAlphaComponent(0.3), 0.8)
                    // The crowd: a shirt and a head per seat, with some seats empty.
                    let seatsInRow = max(2, Int(CGFloat(s.width) / 4.4))
                    for i in 0..<seatsInRow where rng.unit() < 0.72 {
                        let p = at((CGFloat(i) + 0.5) / CGFloat(seatsInRow), (b0 + b1) / 2)
                        fill(circle(p, 1.8), rng.pick(shirts))
                        fill(circle(CGPoint(x: p.x, y: p.y + 0.6), 1.05), rng.pick(skin))
                    }
                }
                // The back wall.
                let back = CGMutablePath()
                back.addLines(between: [at(0, 1 - wall), at(1, 1 - wall), at(1, 1), at(0, 1)])
                back.closeSubpath()
                fill(back, UIColor(hex: 0x5D646B))
                noise(alpha: 0.12)
            }
            stroke(path, UIColor(hex: 0x3E444A), 1)
            // The front rail you bank off.
            stroke(CourseArt.line(c[0], c[1]), UIColor.white, 2.2)
        }
    }

    private static func standPath(_ s: Stand) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: s.corners.map { CGPoint(x: $0.x, y: $0.y) })
        path.closeSubpath()
        return path
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ f: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }
}
