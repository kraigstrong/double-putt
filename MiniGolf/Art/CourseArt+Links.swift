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

extension Painter {
    /// A gull from above, heading +x, wings across its path: `half` is each wing's reach, `sweep` how far back the
    /// tips trail. Grey wings with black tips, white body and fanned tail.
    func gull(half: CGFloat, sweep: CGFloat, color: UIColor? = nil) {
        let white = color ?? UIColor(white: 0.97, alpha: 1), grey = color ?? UIColor(hex: 0xB9C2C9)
        let tipColor = color ?? UIColor(hex: 0x2B2B2E)
        for s: CGFloat in [-1, 1] {
            // Crooked like a gull's: out and a little forward to the wrist, then swept back to a black tip.
            let wrist = CGPoint(x: 2.2 - sweep * 0.2, y: s * half * 0.48)
            let tip = CGPoint(x: -sweep, y: s * half)
            let wing = CGMutablePath()
            wing.move(to: CGPoint(x: 1.6, y: s * 0.8))
            wing.addQuadCurve(to: wrist, control: CGPoint(x: 2.4, y: s * half * 0.25))
            wing.addQuadCurve(to: tip, control: CGPoint(x: 1.0 - sweep * 0.3, y: s * half * 0.82))
            wing.addQuadCurve(to: CGPoint(x: -0.6 - sweep * 0.4, y: s * half * 0.46), control: CGPoint(x: -sweep * 0.7, y: s * half * 0.7))
            wing.addQuadCurve(to: CGPoint(x: -1.6, y: s * 0.8), control: CGPoint(x: -1.4, y: s * half * 0.2))
            wing.closeSubpath()
            fill(wing, grey)
            clipped(wing) { fill(circle(tip, half * 0.22), tipColor) }
        }
        let tail = CGMutablePath()
        tail.move(to: CGPoint(x: -2.5, y: 0.9))
        tail.addLine(to: CGPoint(x: -5.6, y: 1.6))
        tail.addLine(to: CGPoint(x: -5.6, y: -1.6))
        tail.addLine(to: CGPoint(x: -2.5, y: -0.9))
        tail.closeSubpath()
        fill(tail, white)
        fill(CGPath(ellipseIn: CGRect(x: -3.6, y: -1.2, width: 7.2, height: 2.4), transform: nil), white)
        fill(circle(CGPoint(x: 3.9, y: 0), 1.3), white)
        if color == nil {
            let beak = CGMutablePath()
            beak.move(to: CGPoint(x: 5, y: 0.4)); beak.addLine(to: CGPoint(x: 6.6, y: 0)); beak.addLine(to: CGPoint(x: 5, y: -0.4))
            beak.closeSubpath()
            fill(beak, UIColor(hex: 0xF2C230))
        }
    }
}

extension CourseArt {
    /// Wingbeat frames for a gull (spread, mid, tucked, mid) and matching shadow frames; world units, heading +x.
    static func gullFrames(ppu: CGFloat) -> (bird: [UIImage], shadow: [UIImage]) {
        let rect = CGRect(x: -8, y: -11, width: 16, height: 22)
        let poses: [(CGFloat, CGFloat)] = [(9.5, 2.4), (8, 3.2), (5.6, 3.8), (8, 3.2)]
        let bird = poses.map { pose in render(rect, ppu: ppu) { p in p.gull(half: pose.0, sweep: pose.1) } }
        let shadow = poses.map { pose in render(rect, ppu: ppu) { p in p.gull(half: pose.0, sweep: pose.1, color: .black) } }
        return (bird, shadow)
    }
}
