import UIKit

// The Links (course 7): fescue and gorse on a windswept seaside links.

extension Painter {
    /// Links ground: rolling swales of fescue, every tuft leaning the same way in the sea wind, with sandy scrapes
    /// and clumps of heather.
    func linksGround(_ t: Theme, _ rect: CGRect, _ rng: inout SeededRandom) {
        let area = rect.width * rect.height
        for _ in 0..<Int(area / 7000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(40, 120)
            let color = rng.unit() < 0.55 ? t.roughShade.withAlphaComponent(0.5) : t.roughLight.withAlphaComponent(0.45)
            c.drawRadialGradient(gradient([color, color.withAlphaComponent(0)]), startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        noise(alpha: 0.14)
        // Sandy scrapes where the wind has had the turf off.
        let sand = UIColor(hex: 0xDCCB9E)
        for _ in 0..<Int(area / 26000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(8, 20)
            c.drawRadialGradient(gradient([sand.withAlphaComponent(0.85), sand.withAlphaComponent(0.6), sand.withAlphaComponent(0)], [0, 0.6, 1]),
                                 startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        // Fescue tufts, leaning right: the wind comes in off the sea from the left.
        for _ in 0..<Int(area / 40) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let color = (rng.unit() < 0.55 ? t.roughLight : t.roughShade.darker(0.1)).withAlphaComponent(0.7)
            for _ in 0..<3 {
                let a = rng.range(0.95, 1.35), len = rng.range(4, 8)
                let tip = CGPoint(x: p.x + cos(a) * len + rng.range(-1, 1), y: p.y + sin(a) * len)
                stroke(CourseArt.line(p, tip), color, rng.range(0.5, 0.85))
            }
        }
        // Heather.
        for _ in 0..<Int(area / 5000) {
            let center = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            for _ in 0..<Int(rng.range(4, 10)) {
                let p = CGPoint(x: center.x + rng.range(-7, 7), y: center.y + rng.range(-5, 5))
                fill(circle(p, rng.range(0.8, 1.4)), UIColor(hex: 0xA77BBF).withAlphaComponent(0.85))
            }
        }
    }

    /// Gorse: a low, prickly mound of dark green, starred with yellow flowers.
    func gorse(radius r: CGFloat, color: UIColor, _ t: Theme, _ rng: inout SeededRandom) {
        func spiky(_ c0: CGPoint, _ rr: CGFloat) -> CGPath {
            let path = CGMutablePath()
            let points = 16
            for k in 0..<(points * 2) {
                let a = CGFloat(k) / CGFloat(points * 2) * .pi * 2
                let d = k % 2 == 0 ? rr : rr * 0.82
                let p = CGPoint(x: c0.x + cos(a) * d, y: c0.y + sin(a) * d)
                k == 0 ? path.move(to: p) : path.addLine(to: p)
            }
            path.closeSubpath()
            return path
        }
        var lobes: [(CGPoint, CGFloat)] = [(.zero, r * 0.6)]
        for k in 0..<6 {
            let a = CGFloat(k) / 6 * .pi * 2 + rng.range(-0.3, 0.3)
            lobes.append((CGPoint(x: cos(a) * r * 0.42, y: sin(a) * r * 0.36), r * rng.range(0.38, 0.5)))
        }
        shadow(dx: r * 0.2, dy: -r * 0.26, blur: r * 0.2, alpha: 0.4) {
            for (p, rr) in lobes { fill(spiky(p, rr), color.darker(0.25)) }
        }
        for (p, rr) in lobes { fill(spiky(CGPoint(x: p.x - rr * 0.1, y: p.y + rr * 0.12), rr * 0.88), color) }
        for (p, rr) in lobes where p.x - p.y < r * 0.2 {
            fill(circle(CGPoint(x: p.x - rr * 0.22, y: p.y + rr * 0.26), rr * 0.42), color.lighter(0.12))
        }
        for _ in 0..<Int(r * 3) {
            let a = rng.range(0, .pi * 2), d = rng.range(0, r * 0.8)
            fill(circle(CGPoint(x: cos(a) * d, y: sin(a) * d), rng.range(0.7, 1.3)), rng.pick(Array(t.flowers.prefix(2))))
        }
    }
}
