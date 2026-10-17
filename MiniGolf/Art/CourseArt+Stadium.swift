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

    /// One railroad tie of the border: dark, creosoted timber with grain along it, a split at the end and spikes.
    func tie(_ r: CGRect, horizontal: Bool, _ t: Theme, _ rng: inout SeededRandom) {
        let tone = t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.35))
        let path = CGPath(rect: r.insetBy(dx: horizontal ? 0.4 : 0, dy: horizontal ? 0 : 0.4), transform: nil)
        fill(CGPath(rect: r, transform: nil), t.borderSide.darker(0.45))
        linear(path, [tone.lighter(0.1), tone, tone.darker(0.12)],
               from: horizontal ? CGPoint(x: r.midX, y: r.maxY) : CGPoint(x: r.minX, y: r.midY),
               to: horizontal ? CGPoint(x: r.midX, y: r.minY) : CGPoint(x: r.maxX, y: r.midY))
        clipped(path) {
            for _ in 0..<5 {
                let g = CGMutablePath()
                if horizontal {
                    let y = rng.range(r.minY, r.maxY)
                    g.move(to: CGPoint(x: r.minX, y: y)); g.addLine(to: CGPoint(x: r.maxX, y: y + rng.range(-1, 1)))
                } else {
                    let x = rng.range(r.minX, r.maxX)
                    g.move(to: CGPoint(x: x, y: r.minY)); g.addLine(to: CGPoint(x: x + rng.range(-1, 1), y: r.maxY))
                }
                stroke(g, t.borderSide.darker(0.3).withAlphaComponent(0.5), rng.range(0.4, 0.8))
            }
            noise(alpha: 0.18)
        }
        // Spikes near each end.
        for f in [CGFloat(0.12), 0.88] {
            let p = horizontal ? CGPoint(x: r.minX + r.width * f, y: r.midY) : CGPoint(x: r.midX, y: r.minY + r.height * f)
            fill(circle(p, 0.9), UIColor(hex: 0x8A8F94))
        }
    }

    /// Mower stripes: the tournament look, in broad bands across the ground.
    func mowerStripes(_ t: Theme, _ rect: CGRect) {
        let band: CGFloat = 26
        var x = (rect.minX / band).rounded(.down) * band
        var light = Int((x / band).rounded()) % 2 == 0
        while x < rect.maxX {
            if light { fill(CGRect(x: x, y: rect.minY, width: band, height: rect.height), t.roughLight.withAlphaComponent(0.22)) }
            light.toggle()
            x += band
        }
    }

    /// Beds of pine straw: rust-brown needles scattered in loose drifts.
    func pineStraw(_ rect: CGRect, _ rng: inout SeededRandom) {
        let area = rect.width * rect.height
        let straw = [UIColor(hex: 0x9A5B32), UIColor(hex: 0xB0703F), UIColor(hex: 0x7E4726)]
        for _ in 0..<Int(area / 26000) {
            let center = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(22, 40)
            c.drawRadialGradient(gradient([straw[0].withAlphaComponent(0.85), straw[0].withAlphaComponent(0.6), straw[0].withAlphaComponent(0)],
                                          [0, 0.75, 1]),
                                 startCenter: center, startRadius: 0, endCenter: center, endRadius: r, options: [])
            for _ in 0..<Int(r * r / 6) {
                let a = rng.range(0, .pi * 2), d = rng.range(0, r * 0.9)
                let p = CGPoint(x: center.x + cos(a) * d, y: center.y + sin(a) * d)
                let b = rng.range(0, .pi), len = rng.range(2, 4)
                stroke(CourseArt.line(p, CGPoint(x: p.x + cos(b) * len, y: p.y + sin(b) * len)), rng.pick(straw), 0.6)
            }
        }
    }

    /// The gallery: a rope round the course on white stakes, with spectators bunched behind it.
    func gallery(_ rect: CGRect, _ rng: inout SeededRandom) {
        let o = CourseArt.borderOut, w = CGFloat(Course.width), h = CGFloat(Course.height)
        let rope = CGRect(x: -o - 12, y: -o - 12, width: w + 2 * o + 24, height: h + 2 * o + 24)
        stroke(rounded(rope, 16), UIColor.white.withAlphaComponent(0.7), 0.7)
        var s: CGFloat = 0
        let perimeter = 2 * (rope.width + rope.height)
        func point(_ d: CGFloat, out: CGFloat) -> CGPoint {
            var d = d.truncatingRemainder(dividingBy: perimeter)
            if d < rope.width { return CGPoint(x: rope.minX + d, y: rope.minY - out) }
            d -= rope.width
            if d < rope.height { return CGPoint(x: rope.maxX + out, y: rope.minY + d) }
            d -= rope.height
            if d < rope.width { return CGPoint(x: rope.maxX - d, y: rope.maxY + out) }
            d -= rope.width
            return CGPoint(x: rope.minX - out, y: rope.maxY - d)
        }
        while s < perimeter {
            fill(circle(point(s, out: 0), 1.2), .white)
            s += 30
        }
        let shirts = [UIColor(hex: 0xF4F1EA), UIColor(hex: 0xE0533D), UIColor(hex: 0xF2C14E), UIColor(hex: 0x3E7CB1),
                      UIColor(hex: 0x6BBF59), UIColor(hex: 0x1F2A36), UIColor(hex: 0xE88EB4), UIColor(hex: 0xFFFFFF)]
        let hats = [UIColor(hex: 0xFFFFFF), UIColor(hex: 0x2D3A4A), UIColor(hex: 0xC9A66B), UIColor(hex: 0xE0533D)]
        var d = rng.range(0, 20)
        while d < perimeter {
            // A bunch of spectators, then a gap.
            let bunch = rng.range(20, 70)
            var k = d
            while k < d + bunch {
                let p = point(k, out: rng.range(6, 22))
                if rect.contains(p) {
                    fill(circle(p, 2.1), rng.pick(shirts))
                    fill(circle(CGPoint(x: p.x, y: p.y + 0.7), 1.25), rng.pick(hats))
                }
                k += rng.range(3.2, 5)
            }
            d += bunch + rng.range(25, 80)
        }
    }

    /// A pond walled with railroad ties, as round an island green: clear water, then a timber edge.
    func bulkheadPond(_ water: CourseArt.Pond, _ t: Theme, _ rng: inout SeededRandom) {
        let pond = water.path, bounds = water.bounds
        radial(pond, [t.waterDeep, t.waterDeep.mixed(with: t.waterShallow, 0.5), t.waterShallow],
               locations: [0, 0.6, 1], center: CGPoint(x: bounds.midX, y: bounds.midY), radius: max(bounds.width, bounds.height) * 0.62)
        clipped(pond) {
            shadow(dx: 2, dy: -3, blur: 4, alpha: 0.5) {
                let ring = CGMutablePath()
                ring.addRect(bounds.insetBy(dx: -30, dy: -30))
                ring.addPath(pond)
                fill(ring, .black, evenOdd: true)
            }
            for _ in 0..<Int(bounds.width * bounds.height / 900) + 2 {
                let p = CGPoint(x: rng.range(bounds.minX, bounds.maxX), y: rng.range(bounds.minY, bounds.maxY))
                let len = rng.range(6, 14)
                stroke(CourseArt.line(p, CGPoint(x: p.x + len, y: p.y)), UIColor.white.withAlphaComponent(0.3), 0.8)
            }
        }
        // The ties: a dark band along the edge, cut into timbers.
        stroke(pond, t.borderSide.darker(0.4), 5.5)
        stroke(pond.copy(dashingWithPhase: 0, lengths: [7, 1.1]), t.borderTop, 4.4)
        stroke(pond, t.borderTop.lighter(0.15).withAlphaComponent(0.5), 0.6)
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
