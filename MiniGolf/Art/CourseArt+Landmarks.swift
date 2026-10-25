import UIKit

extension CourseArt {
    /// The setting's landmark: one set piece, drawn big in the spare space beside the course on a big screen (see
    /// GameScene.landmarkSpot). Top-down like everything else, lit from the upper left; about `r` world units in radius.
    static func landmark(_ theme: Theme, radius r: CGFloat, ppu: CGFloat) -> Prop {
        let half = r * 1.3
        let rect = CGRect(x: -half, y: -half, width: half * 2, height: half * 2)
        var rng = SeededRandom(seed: stableSeed(theme.id) &+ 900)
        let img = render(rect, ppu: ppu) { p in p.landmark(theme, radius: r, &rng) }
        return Prop(image: img, size: rect.size)
    }
}

extension Painter {
    func landmark(_ t: Theme, radius r: CGFloat, _ rng: inout SeededRandom) {
        switch t.id {
        case "meadow": barn(r, &rng)
        case "garden": fountain(r, t, &rng)
        case "moat": castleTower(r, t, &rng)
        case "seaside": beachUmbrellas(r, &rng)
        case "autumn": pumpkinPatch(r, &rng)
        case "desert": coveredWagon(r, &rng)
        case "winter": snowman(r, &rng)
        case "night": gazebo(r)
        case "midway": candyCart(r, t, &rng)
        case "bigtop": bigTop(r, t)
        case "fireworks": launchRack(r, &rng)
        case "links": lighthouse(r, &rng)
        case "muni": golfCarts(r)
        case "stadium": marquee(r, t)
        case "starbase": shuttlePad(r)
        default: break
        }
    }

    // MARK: Helpers

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private func poly(_ pts: [CGPoint]) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: pts)
        p.closeSubpath()
        return p
    }

    private func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2), transform: nil)
    }

    /// Draws `body` turned by `a` about `p` (shadows still fall the same way: they're set in screen space).
    private func turned(_ a: CGFloat, at p: CGPoint = .zero, _ body: () -> Void) {
        c.saveGState()
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: a)
        body()
        c.restoreGState()
    }

    /// A regular polygon of `n` sides, corner-radius `R`, the first corner at angle `a0`.
    private func regular(_ n: Int, _ R: CGFloat, center: CGPoint = .zero, a0: CGFloat = 0) -> CGPath {
        poly((0..<n).map { k in
            let a = a0 + CGFloat(k) / CGFloat(n) * .pi * 2
            return pt(center.x + cos(a) * R, center.y + sin(a) * R)
        })
    }

    /// A pie slice of a circle.
    private func wedge(_ R: CGFloat, center: CGPoint = .zero, from a0: CGFloat, to a1: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: center)
        p.addArc(center: center, radius: R, startAngle: a0, endAngle: a1, clockwise: false)
        p.closeSubpath()
        return p
    }

    /// A soft drop shadow for a shape `size` across.
    private func dropShadow(_ size: CGFloat, _ body: () -> Void) {
        shadow(dx: size * 0.08, dy: -size * 0.12, blur: size * 0.1, alpha: 0.45, body)
    }

    /// The scenery's own props, drawn at `p`.
    private func canopy(radius: CGFloat, color: UIColor, _ rng: inout SeededRandom, flowers: [UIColor]?, at p: CGPoint) {
        turned(0, at: p) { canopy(radius: radius, color: color, &rng, flowers: flowers) }
    }

    private func rock(radius: CGFloat, _ rng: inout SeededRandom, at p: CGPoint) {
        turned(0, at: p) { rock(radius: radius, &rng) }
    }

    private func balloons(radius: CGFloat, _ t: Theme, _ rng: inout SeededRandom, at p: CGPoint) {
        turned(0, at: p) { balloons(radius: radius, t, &rng) }
    }

    private func glow(_ p: CGPoint, _ R: CGFloat, _ color: UIColor, _ alpha: CGFloat) {
        radial(circle(p, R), [color.withAlphaComponent(alpha), color.withAlphaComponent(0)], center: p, radius: R)
    }

    /// A round hay bale seen from above: golden, wound in rings.
    private func hayBale(_ p: CGPoint, _ R: CGFloat) {
        let gold = UIColor(hex: 0xD9B44A)
        dropShadow(R * 2) { fill(circle(p, R), gold) }
        radial(circle(p, R), [gold.lighter(0.25), gold, gold.darker(0.2)], center: pt(p.x - R * 0.3, p.y + R * 0.3), radius: R * 1.3)
        for k in 1...3 { stroke(circle(p, R * CGFloat(k) / 4), gold.darker(0.3).withAlphaComponent(0.5), R * 0.06) }
        clipped(circle(p, R)) { noise(alpha: 0.18) }
    }

    // MARK: Spring Meadow: a red barn with hay bales

    func barn(_ r: CGFloat, _ rng: inout SeededRandom) {
        hayBale(pt(r * 0.66, -r * 0.7), r * 0.17)
        hayBale(pt(r * 0.95, -r * 0.45), r * 0.15)
        hayBale(pt(-r * 0.8, -r * 0.75), r * 0.14)
        let red = UIColor(hex: 0xB8382E), cream = UIColor(hex: 0xF3EBDD)
        turned(-0.08, at: pt(-r * 0.05, r * 0.12)) {
            let w = r * 1.35, h = r * 0.9
            let body = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            dropShadow(w) { fill(CGPath(rect: body, transform: nil), .black) }
            // Two roof planes meet at the ridge; the upper one catches the light.
            let upper = CGPath(rect: CGRect(x: body.minX, y: 0, width: w, height: h / 2), transform: nil)
            let lower = CGPath(rect: CGRect(x: body.minX, y: body.minY, width: w, height: h / 2), transform: nil)
            linear(upper, [red.lighter(0.1), red], from: pt(0, h / 2), to: .zero)
            linear(lower, [red.darker(0.12), red.darker(0.3)], from: .zero, to: pt(0, -h / 2))
            clipped(CGPath(rect: body, transform: nil)) {
                // Standing seams down each plane.
                for k in 1..<16 {
                    let x = body.minX + w * CGFloat(k) / 16
                    stroke(CourseArt.line(pt(x, body.minY), pt(x, body.maxY)), red.darker(0.4).withAlphaComponent(0.45), r * 0.012)
                }
                noise(alpha: 0.12)
            }
            stroke(CourseArt.line(pt(body.minX, 0), pt(body.maxX, 0)), cream, r * 0.035)
            stroke(CGPath(rect: body, transform: nil), cream, r * 0.03)
            // A cupola on the ridge, with a weathervane.
            let s = r * 0.13
            dropShadow(s * 2) { fill(CGPath(rect: CGRect(x: -s, y: -s, width: 2 * s, height: 2 * s), transform: nil), red.darker(0.2)) }
            fill(poly([pt(-s, s), pt(s, s), pt(0, 0)]), red.lighter(0.15))
            fill(poly([pt(-s, -s), pt(s, -s), pt(0, 0)]), red.darker(0.3))
            fill(poly([pt(-s, s), pt(-s, -s), pt(0, 0)]), red.lighter(0.05))
            fill(poly([pt(s, s), pt(s, -s), pt(0, 0)]), red.darker(0.15))
            stroke(CGPath(rect: CGRect(x: -s, y: -s, width: 2 * s, height: 2 * s), transform: nil), cream, r * 0.02)
            let vane = UIColor(hex: 0x3A3A3A)
            stroke(CourseArt.line(pt(-s * 1.1, 0), pt(s * 1.0, 0)), vane, r * 0.018)
            fill(poly([pt(s * 1.35, 0), pt(s * 0.95, s * 0.28), pt(s * 0.95, -s * 0.28)]), vane)
            fill(poly([pt(-s * 1.1, 0), pt(-s * 1.35, s * 0.25), pt(-s * 1.2, 0), pt(-s * 1.35, -s * 0.25)]), vane)
        }
    }

    // MARK: Walled Garden: a tiered stone fountain

    func fountain(_ r: CGFloat, _ t: Theme, _ rng: inout SeededRandom) {
        let stone = t.borderTop, R = r * 0.92
        let rim = regular(8, R, a0: .pi / 8)
        dropShadow(R * 2) { fill(rim, stone.darker(0.2)) }
        linear(rim, [stone.lighter(0.12), stone, stone.darker(0.15)], from: pt(-R, R), to: pt(R, -R))
        clipped(rim) { noise(alpha: 0.15) }
        stroke(rim, stone.darker(0.35).withAlphaComponent(0.6), r * 0.012)
        // The basin's water, shaded under its near rim.
        let pool = regular(8, R * 0.82, a0: .pi / 8)
        radial(pool, [t.waterShallow.lighter(0.15), t.waterShallow, t.waterDeep], center: pt(-R * 0.2, R * 0.2), radius: R * 1.1)
        clipped(pool) {
            shadow(dx: r * 0.03, dy: -r * 0.05, blur: r * 0.06, alpha: 0.5) {
                let ring = CGMutablePath()
                ring.addPath(circle(.zero, R * 1.5))
                ring.addPath(pool)
                fill(ring, .black, evenOdd: true)
            }
            for k in 0..<3 {
                stroke(circle(.zero, R * (0.4 + 0.13 * CGFloat(k))), UIColor.white.withAlphaComponent(0.35 - 0.08 * CGFloat(k)), r * 0.012)
            }
            for _ in 0..<7 {
                let a = rng.range(0, .pi * 2), d = R * rng.range(0.42, 0.72)
                fill(circle(pt(cos(a) * d, sin(a) * d), r * 0.018), UIColor(hex: 0xE8C25A).withAlphaComponent(0.85))
            }
        }
        // The pedestal and its upper bowl, and the spout's spray.
        dropShadow(R * 0.7) { fill(circle(.zero, R * 0.3), stone) }
        radial(circle(.zero, R * 0.3), [stone.lighter(0.2), stone, stone.darker(0.2)], center: pt(-R * 0.1, R * 0.1), radius: R * 0.38)
        radial(circle(.zero, R * 0.22), [t.waterShallow.lighter(0.3), t.waterShallow], center: pt(-R * 0.05, R * 0.05), radius: R * 0.25)
        for k in 0..<12 {
            let a = CGFloat(k) / 12 * .pi * 2
            fill(circle(pt(cos(a) * R * 0.14, sin(a) * R * 0.14), r * 0.016), UIColor.white.withAlphaComponent(0.85))
        }
        fill(circle(.zero, r * 0.035), .white)
        // Clipped box balls at the corners.
        for k in 0..<4 {
            let a = CGFloat(k) * .pi / 2 + .pi / 4
            canopy(radius: r * 0.13, color: t.canopies.first ?? .green, &rng, flowers: nil, at: pt(cos(a) * R * 1.12, sin(a) * R * 1.12))
        }
    }

    // MARK: Castle Moat: a round tower with a pennant

    func castleTower(_ r: CGFloat, _ t: Theme, _ rng: inout SeededRandom) {
        let stone = t.borderTop, R = r * 0.85
        dropShadow(R * 2) { fill(circle(.zero, R), stone.darker(0.25)) }
        radial(circle(.zero, R), [stone.lighter(0.1), stone, stone.darker(0.18)], center: pt(-R * 0.3, R * 0.3), radius: R * 1.3)
        // Coursed stone on the wall-walk.
        clipped(circle(.zero, R)) {
            for ring in [0.8, 0.9] as [CGFloat] { stroke(circle(.zero, R * ring), stone.darker(0.3).withAlphaComponent(0.4), r * 0.01) }
            for k in 0..<28 {
                let a = CGFloat(k) / 28 * .pi * 2 + (k % 2 == 0 ? 0 : 0.05)
                stroke(CourseArt.line(pt(cos(a) * R * 0.72, sin(a) * R * 0.72), pt(cos(a) * R, sin(a) * R)), stone.darker(0.3).withAlphaComponent(0.35), r * 0.008)
            }
            noise(alpha: 0.15)
        }
        // Merlons round the rim, each casting a little shadow inward.
        for k in 0..<14 {
            let a = CGFloat(k) / 14 * .pi * 2
            turned(a, at: pt(cos(a) * R * 0.93, sin(a) * R * 0.93)) {
                let m = CGRect(x: -R * 0.07, y: -R * 0.11, width: R * 0.14, height: R * 0.22)
                shadow(dx: r * 0.02, dy: -r * 0.03, blur: r * 0.03, alpha: 0.5) { fill(CGPath(rect: m, transform: nil), stone.lighter(0.08)) }
                stroke(CGPath(rect: m, transform: nil), stone.darker(0.3), r * 0.008)
            }
        }
        // The roof: planks round a hatch.
        let floor = circle(.zero, R * 0.66)
        let wood = UIColor(hex: 0x8A6238)
        fill(floor, wood)
        clipped(floor) {
            for k in -8...8 {
                let y = CGFloat(k) * R * 0.08
                stroke(CourseArt.line(pt(-R, y), pt(R, y)), wood.darker(0.3).withAlphaComponent(0.6), r * 0.008)
            }
            shadow(dx: r * 0.02, dy: -r * 0.04, blur: r * 0.06, alpha: 0.6) {
                let ring = CGMutablePath()
                ring.addPath(circle(.zero, R * 1.2))
                ring.addPath(floor)
                fill(ring, .black, evenOdd: true)
            }
            noise(alpha: 0.12)
        }
        let hatch = CGRect(x: R * 0.15, y: -R * 0.42, width: R * 0.22, height: R * 0.22)
        fill(CGPath(rect: hatch, transform: nil), wood.darker(0.35))
        stroke(CGPath(rect: hatch, transform: nil), UIColor(hex: 0x3A2A18), r * 0.01)
        // The flagpole and a pennant streaming out.
        let blue = UIColor(hex: 0x2F6FB5)
        dropShadow(r * 0.1) { fill(circle(pt(-R * 0.1, R * 0.1), r * 0.035), UIColor(hex: 0xE8C25A)) }
        let flag = CGMutablePath()
        flag.move(to: pt(-R * 0.1, R * 0.12))
        flag.addQuadCurve(to: pt(R * 0.5, R * 0.22), control: pt(R * 0.2, R * 0.28))
        flag.addQuadCurve(to: pt(-R * 0.1, R * 0.32), control: pt(R * 0.2, R * 0.2))
        flag.closeSubpath()
        shadow(dx: r * 0.03, dy: -r * 0.05, blur: r * 0.03, alpha: 0.4) { fill(flag, blue) }
        fill(flag, blue.lighter(0.1))
    }

    // MARK: Seaside Boardwalk: beach umbrellas over towels

    func beachUmbrellas(_ r: CGFloat, _ rng: inout SeededRandom) {
        let towels: [(CGPoint, CGFloat, UIColor)] = [
            (pt(-r * 0.45, -r * 0.25), 0.25, UIColor(hex: 0x3BA7C9)), (pt(r * 0.42, r * 0.05), -0.35, UIColor(hex: 0xF2A33A)),
        ]
        for (p, a, color) in towels {
            turned(a, at: p) {
                let towel = CGRect(x: -r * 0.2, y: -r * 0.38, width: r * 0.4, height: r * 0.76)
                shadow(dx: r * 0.01, dy: -r * 0.02, blur: r * 0.02, alpha: 0.3) { fill(CGPath(rect: towel, transform: nil), color) }
                for k in 0..<4 {
                    let y = towel.minY + towel.height * (0.12 + 0.22 * CGFloat(k))
                    fill(CGPath(rect: CGRect(x: towel.minX, y: y, width: towel.width, height: towel.height * 0.07), transform: nil), .white)
                }
                clipped(CGPath(rect: towel, transform: nil)) { noise(alpha: 0.15) }
            }
        }
        // A beach ball and a bucket.
        let ball = pt(r * 0.02, -r * 0.72), br = r * 0.1
        dropShadow(br * 2) { fill(circle(ball, br), .white) }
        for (k, color) in [UIColor(hex: 0xE84C3D), UIColor(hex: 0xFFD54F), UIColor(hex: 0x3B82F6)].enumerated() {
            let a0 = CGFloat(k) * .pi * 2 / 3
            fill(wedge(br, center: ball, from: a0, to: a0 + .pi / 3), color)
        }
        radial(circle(ball, br), [UIColor.white.withAlphaComponent(0.5), UIColor.clear, UIColor.black.withAlphaComponent(0.2)], center: pt(ball.x - br * 0.3, ball.y + br * 0.3), radius: br * 1.3)
        let bucket = pt(-r * 0.85, r * 0.5)
        dropShadow(r * 0.16) { fill(circle(bucket, r * 0.08), UIColor(hex: 0xE84C3D)) }
        fill(circle(bucket, r * 0.06), UIColor(hex: 0xC93B2E))
        stroke(ellipse(pt(bucket.x + r * 0.02, bucket.y), r * 0.09, r * 0.04), UIColor(hex: 0x555555), r * 0.012)
        // Umbrellas over the towels' heads.
        for (p, colors) in [(pt(-r * 0.35, r * 0.25), [UIColor(hex: 0xE84C3D), .white]),
                            (pt(r * 0.5, r * 0.55), [UIColor(hex: 0x2F7FD0), UIColor(hex: 0xFFF4E2)])] {
            let R = r * 0.42
            shadow(dx: r * 0.12, dy: -r * 0.18, blur: r * 0.08, alpha: 0.35) { fill(circle(p, R), .black) }
            let rot = rng.range(0, .pi)
            for k in 0..<8 {
                let a0 = rot + CGFloat(k) / 8 * .pi * 2, a1 = rot + CGFloat(k + 1) / 8 * .pi * 2
                fill(wedge(R, center: p, from: a0, to: a1), colors[k % 2])
                let mid = (a0 + a1) / 2
                fill(circle(pt(p.x + cos(mid) * R * 0.97, p.y + sin(mid) * R * 0.97), R * 0.12), colors[k % 2].darker(0.06))
            }
            radial(circle(p, R), [UIColor.white.withAlphaComponent(0.3), UIColor.clear, UIColor.black.withAlphaComponent(0.2)],
                   center: pt(p.x - R * 0.3, p.y + R * 0.3), radius: R * 1.2)
            fill(circle(p, R * 0.08), UIColor(hex: 0xDDDDDD))
        }
    }

    // MARK: Autumn Grove: a pumpkin patch

    func pumpkinPatch(_ r: CGFloat, _ rng: inout SeededRandom) {
        let soil = UIColor(hex: 0x6B4A2F)
        let patch = ellipse(.zero, r * 0.95, r * 0.75)
        fill(patch, soil)
        clipped(patch) {
            for k in -6...6 {
                let y = CGFloat(k) * r * 0.12
                stroke(CourseArt.line(pt(-r, y), pt(r, y + r * 0.05)), soil.darker(0.3).withAlphaComponent(0.6), r * 0.03)
            }
            noise(alpha: 0.25)
        }
        // Vines wandering between the pumpkins, with broad leaves.
        let vine = UIColor(hex: 0x4F7A2A)
        for _ in 0..<5 {
            let p = CGMutablePath()
            var at = pt(rng.range(-r * 0.7, r * 0.7), rng.range(-r * 0.55, r * 0.55))
            p.move(to: at)
            for _ in 0..<3 {
                let next = pt(at.x + rng.range(-r * 0.35, r * 0.35), at.y + rng.range(-r * 0.25, r * 0.25))
                p.addQuadCurve(to: next, control: pt((at.x + next.x) / 2 + rng.range(-r * 0.1, r * 0.1), (at.y + next.y) / 2 + rng.range(-r * 0.1, r * 0.1)))
                at = next
                let leaf = pt(at.x + rng.range(-r * 0.06, r * 0.06), at.y + rng.range(-r * 0.06, r * 0.06))
                fill(circle(leaf, r * rng.range(0.06, 0.09)), vine.lighter(rng.range(0, 0.15)))
            }
            stroke(p, vine, r * 0.018)
        }
        var spots: [(CGPoint, CGFloat)] = []
        for _ in 0..<40 where spots.count < 8 {
            let R = r * rng.range(0.1, 0.17)
            let p = pt(rng.range(-r * 0.75, r * 0.75), rng.range(-r * 0.55, r * 0.55))
            guard (p.x * p.x) / (r * r * 0.8) + (p.y * p.y) / (r * r * 0.5) < 1, !spots.contains(where: { hypot($0.0.x - p.x, $0.0.y - p.y) < ($0.1 + R) * 1.05 }) else { continue }
            spots.append((p, R))
        }
        for (p, R) in spots {
            let orange = UIColor(hex: 0xE8822A).mixed(with: UIColor(hex: 0xF2A33A), rng.unit())
            let body = ellipse(p, R, R * 0.88)
            dropShadow(R * 2) { fill(body, orange) }
            radial(body, [orange.lighter(0.25), orange, orange.darker(0.25)], center: pt(p.x - R * 0.3, p.y + R * 0.3), radius: R * 1.3)
            clipped(body) {
                for k in -2...2 {
                    stroke(ellipse(p, R * (0.3 + 0.17 * abs(CGFloat(k))), R * 0.9), orange.darker(0.3).withAlphaComponent(0.4), R * 0.06)
                }
            }
            fill(CGPath(rect: CGRect(x: p.x - R * 0.08, y: p.y - R * 0.08, width: R * 0.16, height: R * 0.16), transform: nil), UIColor(hex: 0x5A6B2A))
        }
        hayBale(pt(r * 0.85, r * 0.62), r * 0.16)
    }

    // MARK: Desert Canyon: a covered wagon by a campfire

    func coveredWagon(_ r: CGFloat, _ rng: inout SeededRandom) {
        // A campfire ringed with stones.
        let fire = pt(r * 0.6, -r * 0.65)
        glow(fire, r * 0.45, UIColor(hex: 0xFFB347), 0.35)
        for k in 0..<9 {
            let a = CGFloat(k) / 9 * .pi * 2
            rock(radius: r * 0.045, &rng, at: pt(fire.x + cos(a) * r * 0.14, fire.y + sin(a) * r * 0.14))
        }
        for a in [0.4, 2.2] as [CGFloat] {
            stroke(CourseArt.line(pt(fire.x - cos(a) * r * 0.1, fire.y - sin(a) * r * 0.1), pt(fire.x + cos(a) * r * 0.1, fire.y + sin(a) * r * 0.1)), UIColor(hex: 0x5A3A22), r * 0.035)
        }
        radial(circle(fire, r * 0.09), [UIColor(hex: 0xFFF2A8), UIColor(hex: 0xFFB347), UIColor(hex: 0xE8562A)], center: fire, radius: r * 0.1)
        // A barrel.
        let barrel = pt(-r * 0.75, -r * 0.55)
        dropShadow(r * 0.3) { fill(circle(barrel, r * 0.13), UIColor(hex: 0x8A5A32)) }
        radial(circle(barrel, r * 0.13), [UIColor(hex: 0xA8743F), UIColor(hex: 0x7A4E2A)], center: pt(barrel.x - r * 0.04, barrel.y + r * 0.04), radius: r * 0.16)
        for k in [0.6, 0.95] as [CGFloat] { stroke(circle(barrel, r * 0.13 * k), UIColor(hex: 0x3F3F3F), r * 0.012) }
        // The wagon: bows of canvas over a wooden bed, wheels showing at the corners.
        turned(0.35, at: pt(-r * 0.05, r * 0.15)) {
            let L = r * 1.25, W = r * 0.62
            let wood = UIColor(hex: 0x6E4A2A)
            for x in [-L * 0.32, L * 0.32] {
                for y in [-W * 0.55, W * 0.55] {
                    let wheel = CGRect(x: x - r * 0.15, y: y - r * 0.03, width: r * 0.3, height: r * 0.06)
                    dropShadow(r * 0.2) { fill(CGPath(roundedRect: wheel, cornerWidth: r * 0.02, cornerHeight: r * 0.02, transform: nil), wood.darker(0.3)) }
                }
            }
            stroke(CourseArt.line(pt(L * 0.5, 0), pt(L * 0.85, 0)), wood, r * 0.04)
            stroke(CourseArt.line(pt(L * 0.85, -W * 0.25), pt(L * 0.85, W * 0.25)), wood, r * 0.035)
            let canvas = CGPath(roundedRect: CGRect(x: -L / 2, y: -W / 2, width: L, height: W), cornerWidth: W * 0.45, cornerHeight: W * 0.45, transform: nil)
            let cloth = UIColor(hex: 0xF2E6CC)
            dropShadow(L) { fill(canvas, cloth) }
            linear(canvas, [cloth.lighter(0.25), cloth, cloth.darker(0.2)], from: pt(0, W / 2), to: pt(0, -W / 2))
            clipped(canvas) {
                for k in 1..<6 {
                    let x = -L / 2 + L * CGFloat(k) / 6
                    stroke(CourseArt.line(pt(x, -W), pt(x, W)), cloth.darker(0.25).withAlphaComponent(0.6), r * 0.02)
                }
                noise(alpha: 0.12)
            }
            stroke(canvas, cloth.darker(0.35), r * 0.012)
        }
    }

    // MARK: Winter Village: a snowman beside a sled

    func snowman(_ r: CGFloat, _ rng: inout SeededRandom) {
        let snow = UIColor(hex: 0xF7FAFC), shade = UIColor(hex: 0xBFD0E0)
        // A sled, parked.
        turned(-0.5, at: pt(r * 0.62, -r * 0.55)) {
            let bed = CGRect(x: -r * 0.32, y: -r * 0.12, width: r * 0.64, height: r * 0.24)
            for y in [-r * 0.14, r * 0.14] {
                stroke(CourseArt.line(pt(-r * 0.38, y), pt(r * 0.32, y)), UIColor(hex: 0x4A4A4A), r * 0.025)
                stroke(CGPath(ellipseIn: CGRect(x: r * 0.3, y: y - r * 0.05, width: r * 0.1, height: r * 0.1), transform: nil), UIColor(hex: 0x4A4A4A), r * 0.02)
            }
            dropShadow(r * 0.6) { fill(CGPath(rect: bed, transform: nil), UIColor(hex: 0xC8392E)) }
            for k in 0..<4 {
                let x = bed.minX + bed.width * (0.1 + 0.24 * CGFloat(k))
                fill(CGPath(rect: CGRect(x: x, y: bed.minY, width: bed.width * 0.16, height: bed.height), transform: nil), UIColor(hex: 0xE04A3D))
            }
        }
        // Three balls of snow, seen from just above: the head's on top.
        let base = pt(-r * 0.05, -r * 0.05), mid = pt(-r * 0.1, r * 0.04), head = pt(-r * 0.14, r * 0.11)
        shadow(dx: r * 0.15, dy: -r * 0.22, blur: r * 0.12, alpha: 0.35) { fill(circle(base, r * 0.5), shade) }
        for (p, R) in [(base, r * 0.5), (mid, r * 0.36), (head, r * 0.24)] {
            shadow(dx: r * 0.02, dy: -r * 0.04, blur: r * 0.05, alpha: 0.25) { fill(circle(p, R), snow) }
            radial(circle(p, R), [.white, snow, shade], locations: [0, 0.5, 1], center: pt(p.x - R * 0.35, p.y + R * 0.35), radius: R * 1.35)
        }
        // Stick arms from the middle.
        let twig = UIColor(hex: 0x5A3E26)
        for (end, fork) in [(pt(-r * 0.75, r * 0.25), pt(-r * 0.85, r * 0.38)), (pt(r * 0.55, r * 0.15), pt(r * 0.66, r * 0.28))] {
            stroke(CourseArt.line(pt(mid.x, mid.y), end), twig, r * 0.03)
            stroke(CourseArt.line(pt((mid.x + end.x * 3) / 4, (mid.y + end.y * 3) / 4), fork), twig, r * 0.02)
        }
        // Coal buttons down the front, a red scarf, a carrot nose and a hat.
        for k in 0..<3 { fill(circle(pt(mid.x + r * 0.12 + CGFloat(k) * r * 0.06, mid.y - r * 0.2 + CGFloat(k) * r * 0.02), r * 0.025), UIColor(hex: 0x2A2A2A)) }
        let scarf = UIColor(hex: 0xD83A3A)
        let wrap = CGMutablePath()
        wrap.addArc(center: head, radius: r * 0.25, startAngle: 0.6, endAngle: 0.6 + .pi * 1.4, clockwise: true)
        stroke(wrap, scarf, r * 0.045)
        stroke(CourseArt.line(pt(head.x + r * 0.18, head.y - r * 0.15), pt(head.x + r * 0.32, head.y - r * 0.34)), scarf, r * 0.05)
        fill(poly([pt(head.x + r * 0.08, head.y - r * 0.02), pt(head.x + r * 0.08, head.y - r * 0.1), pt(head.x + r * 0.3, head.y - r * 0.12)]), UIColor(hex: 0xF08A24))
        dropShadow(r * 0.3) { fill(circle(pt(head.x - r * 0.04, head.y + r * 0.04), r * 0.17), UIColor(hex: 0x2A2A2A)) }
        fill(circle(pt(head.x - r * 0.06, head.y + r * 0.06), r * 0.11), UIColor(hex: 0x3A3A3A))
        stroke(circle(pt(head.x - r * 0.06, head.y + r * 0.06), r * 0.115), UIColor(hex: 0x8A2A2A), r * 0.015)
    }

    // MARK: Night Garden: a gazebo strung with fairy lights

    func gazebo(_ r: CGFloat) {
        let R = r * 0.82
        glow(.zero, r * 1.25, UIColor(hex: 0xFFC56B), 0.35)
        let roof = regular(8, R, a0: .pi / 8)
        dropShadow(R * 2) { fill(roof, .black) }
        let wood = UIColor(hex: 0x3E5A6B)
        // Eight panels rising to the finial, each lit by how it faces the light (upper left).
        for k in 0..<8 {
            let a0 = .pi / 8 + CGFloat(k) / 8 * .pi * 2, a1 = a0 + .pi / 4
            let facing = cos((a0 + a1) / 2 - 3 * .pi / 4)
            fill(poly([.zero, pt(cos(a0) * R, sin(a0) * R), pt(cos(a1) * R, sin(a1) * R)]), facing > 0 ? wood.lighter(0.18 * facing) : wood.darker(-0.3 * facing))
            stroke(CourseArt.line(.zero, pt(cos(a0) * R, sin(a0) * R)), wood.darker(0.45), r * 0.02)
        }
        clipped(roof) { noise(alpha: 0.12) }
        stroke(roof, wood.darker(0.5), r * 0.025)
        fill(circle(.zero, r * 0.07), UIColor(hex: 0xE8C25A))
        // Fairy lights swagged along the eaves and down the ridges.
        let bulb = UIColor(hex: 0xFFE9A8)
        for k in 0..<8 {
            let a0 = .pi / 8 + CGFloat(k) / 8 * .pi * 2, a1 = a0 + .pi / 4
            let p0 = pt(cos(a0) * R, sin(a0) * R), p1 = pt(cos(a1) * R, sin(a1) * R)
            for j in 0..<5 {
                let f = (CGFloat(j) + 0.5) / 5
                let sag = sin(f * .pi) * r * 0.05
                let p = pt(p0.x + (p1.x - p0.x) * f, p0.y + (p1.y - p0.y) * f)
                let out = pt(p.x * (1 + sag / R), p.y * (1 + sag / R))
                glow(out, r * 0.07, bulb, 0.7)
                fill(circle(out, r * 0.018), bulb)
            }
            for j in 1..<4 {
                let f = CGFloat(j) / 4
                let p = pt(p0.x * f, p0.y * f)
                glow(p, r * 0.05, bulb, 0.6)
                fill(circle(p, r * 0.014), bulb)
            }
        }
    }

    // MARK: Midway: a cotton candy cart with balloons

    func candyCart(_ r: CGFloat, _ t: Theme, _ rng: inout SeededRandom) {
        turned(-0.12, at: pt(-r * 0.1, -r * 0.05)) {
            let W = r * 1.05, H = r * 0.62
            let cart = CGRect(x: -W / 2, y: -H / 2, width: W, height: H)
            for x in [-W * 0.3, W * 0.3] {
                for y in [-H / 2 - r * 0.04, H / 2 + r * 0.04] {
                    fill(CGPath(roundedRect: CGRect(x: x - r * 0.1, y: y - r * 0.035, width: r * 0.2, height: r * 0.07), cornerWidth: r * 0.03, cornerHeight: r * 0.03, transform: nil), UIColor(hex: 0x2A2A2A))
                }
            }
            dropShadow(W) { fill(CGPath(rect: cart, transform: nil), .black) }
            // The striped awning over the back half; the counter, with the candy, in front.
            let counter = CGRect(x: cart.minX, y: cart.minY, width: W, height: H * 0.45)
            fill(CGPath(rect: counter, transform: nil), UIColor(hex: 0xF4EFE6))
            let awning = CGRect(x: cart.minX - r * 0.05, y: cart.minY + H * 0.4, width: W + r * 0.1, height: H * 0.65)
            shadow(dx: r * 0.03, dy: -r * 0.06, blur: r * 0.04, alpha: 0.4) { fill(CGPath(rect: awning, transform: nil), t.stripes[1]) }
            for k in stride(from: 0, to: 9, by: 2) {
                let x = awning.minX + awning.width * CGFloat(k) / 9
                fill(CGPath(rect: CGRect(x: x, y: awning.minY, width: awning.width / 9, height: awning.height), transform: nil), t.stripes[0])
            }
            for k in 0..<9 {
                let x = awning.minX + awning.width * (CGFloat(k) + 0.5) / 9
                fill(circle(pt(x, awning.minY), awning.width / 18), k % 2 == 0 ? t.stripes[0] : t.stripes[1])
            }
            linear(CGPath(rect: awning, transform: nil), [UIColor.white.withAlphaComponent(0.2), UIColor.black.withAlphaComponent(0.15)], from: pt(0, awning.maxY), to: pt(0, awning.minY))
            for (k, color) in [UIColor(hex: 0xFF9ED2), UIColor(hex: 0x9ED8FF), UIColor(hex: 0xFFB8E0)].enumerated() {
                let p = pt(cart.minX + W * (0.25 + 0.25 * CGFloat(k)), cart.minY + H * 0.2)
                for j in 0..<5 {
                    let a = CGFloat(j) / 5 * .pi * 2
                    fill(circle(pt(p.x + cos(a) * r * 0.05, p.y + sin(a) * r * 0.05), r * 0.07), color.lighter(0.1))
                }
                fill(circle(p, r * 0.07), color)
            }
        }
        balloons(radius: r * 0.42, t, &rng, at: pt(r * 0.72, r * 0.55))
    }

    // MARK: Big Top: the big tent, bunting round its eaves

    func bigTop(_ r: CGFloat, _ t: Theme) {
        let R = r * 0.86, wedges = 16
        let red = UIColor(hex: 0xC8202E), gold = UIColor(hex: 0xFFC94A)
        // Guy ropes to stakes round the tent.
        for k in 0..<8 {
            let a = CGFloat(k) / 8 * .pi * 2 + .pi / 16
            stroke(CourseArt.line(pt(cos(a) * R, sin(a) * R), pt(cos(a) * r * 1.2, sin(a) * r * 1.2)), UIColor(hex: 0xEDE3CF).withAlphaComponent(0.7), r * 0.01)
            fill(circle(pt(cos(a) * r * 1.2, sin(a) * r * 1.2), r * 0.02), UIColor(hex: 0x6E4A2A))
        }
        dropShadow(R * 2) { fill(circle(.zero, R), .black) }
        for k in 0..<wedges {
            let a0 = CGFloat(k) / CGFloat(wedges) * .pi * 2, a1 = CGFloat(k + 1) / CGFloat(wedges) * .pi * 2
            fill(wedge(R, from: a0, to: a1), k % 2 == 0 ? red : gold)
        }
        radial(circle(.zero, R), [UIColor.white.withAlphaComponent(0.25), UIColor.clear, UIColor.black.withAlphaComponent(0.25)],
               center: pt(-R * 0.25, R * 0.25), radius: R * 1.1)
        // Bunting round the eaves, then the king pole's star.
        for k in 0..<32 {
            let a = (CGFloat(k) + 0.5) / 32 * .pi * 2
            let p = pt(cos(a) * R * 1.02, sin(a) * R * 1.02)
            turned(a - .pi / 2, at: p) {
                fill(poly([pt(-R * 0.05, 0), pt(R * 0.05, 0), pt(0, R * 0.09)]), [red, gold, UIColor(hex: 0x3B82F6), .white][k % 4])
            }
        }
        stroke(circle(.zero, R * 1.02), UIColor(hex: 0x6E4A2A).withAlphaComponent(0.8), r * 0.008)
        let star = poly((0..<10).map { k in
            let a = .pi / 2 + CGFloat(k) / 10 * .pi * 2
            let d = k % 2 == 0 ? r * 0.12 : r * 0.05
            return pt(cos(a) * d, sin(a) * d)
        })
        dropShadow(r * 0.2) { fill(star, gold) }
        fill(star, gold.lighter(0.2))
    }

    // MARK: Fireworks: a launch rack of mortars, a few rockets beside it

    func launchRack(_ r: CGFloat, _ rng: inout SeededRandom) {
        let wood = UIColor(hex: 0x8A6238)
        turned(0.12, at: pt(-r * 0.1, r * 0.08)) {
            let W = r * 1.05, H = r * 0.8
            let crate = CGRect(x: -W / 2, y: -H / 2, width: W, height: H)
            dropShadow(W) { fill(CGPath(rect: crate, transform: nil), wood) }
            clipped(CGPath(rect: crate, transform: nil)) {
                for k in 0..<6 {
                    let y = crate.minY + H * CGFloat(k) / 6
                    fill(CGPath(rect: CGRect(x: crate.minX, y: y, width: W, height: H / 6), transform: nil), wood.mixed(with: wood.darker(0.2), rng.unit()))
                    stroke(CourseArt.line(pt(crate.minX, y), pt(crate.maxX, y)), wood.darker(0.4), r * 0.01)
                }
                noise(alpha: 0.15)
            }
            stroke(CGPath(rect: crate, transform: nil), wood.darker(0.45), r * 0.02)
            // Mortar tubes in rows, wrapped in coloured paper; a couple just fired, still smoking with sparks.
            let wraps = [UIColor(hex: 0xE84C3D), UIColor(hex: 0x3B82F6), UIColor(hex: 0xFFD54F), UIColor(hex: 0x4CC38A), UIColor(hex: 0xB08CFF)]
            for row in 0..<3 {
                for col in 0..<4 {
                    let p = pt(crate.minX + W * (CGFloat(col) + 0.5) / 4, crate.minY + H * (CGFloat(row) + 0.5) / 3)
                    let tr = r * 0.11
                    dropShadow(tr * 2) { fill(circle(p, tr), wraps[(row * 4 + col) % wraps.count]) }
                    radial(circle(p, tr), [wraps[(row * 4 + col) % wraps.count].lighter(0.3), wraps[(row * 4 + col) % wraps.count]], center: pt(p.x - tr * 0.3, p.y + tr * 0.3), radius: tr * 1.2)
                    fill(circle(p, tr * 0.62), UIColor(hex: 0x1E1E1E))
                    if (row + col) % 5 == 1 {
                        glow(p, tr * 2.2, UIColor(hex: 0xFFE07A), 0.55)
                        for _ in 0..<6 {
                            let a = rng.range(0, .pi * 2), d = tr * rng.range(0.6, 1.8)
                            fill(circle(pt(p.x + cos(a) * d, p.y + sin(a) * d), r * 0.012), UIColor(hex: 0xFFF2B0))
                        }
                    }
                }
            }
        }
        // Rockets lying ready, on their sticks.
        for (k, p) in [pt(r * 0.55, -r * 0.72), pt(r * 0.78, -r * 0.6)].enumerated() {
            turned(0.6 + CGFloat(k) * 0.1, at: p) {
                stroke(CourseArt.line(pt(-r * 0.4, 0), pt(0, 0)), UIColor(hex: 0xC9A66B), r * 0.015)
                let body = CGRect(x: 0, y: -r * 0.04, width: r * 0.24, height: r * 0.08)
                dropShadow(r * 0.2) { fill(CGPath(rect: body, transform: nil), k == 0 ? UIColor(hex: 0xE84C3D) : UIColor(hex: 0x3B82F6)) }
                fill(poly([pt(r * 0.24, -r * 0.04), pt(r * 0.34, 0), pt(r * 0.24, r * 0.04)]), UIColor(hex: 0xEDEDED))
            }
        }
    }

    // MARK: Seaside Links: a lighthouse on its rocks, its lamp lit

    func lighthouse(_ r: CGFloat, _ rng: inout SeededRandom) {
        // Rocks the tower stands on.
        for _ in 0..<14 {
            let a = rng.range(0, .pi * 2), d = r * rng.range(0.45, 0.82)
            rock(radius: r * rng.range(0.1, 0.18), &rng, at: pt(cos(a) * d, sin(a) * d * 0.85))
        }
        // The beam, sweeping out over the links.
        let beam = CGMutablePath()
        beam.move(to: .zero)
        beam.addArc(center: .zero, radius: r * 1.3, startAngle: -0.75, endAngle: -0.35, clockwise: false)
        beam.closeSubpath()
        radial(beam, [UIColor(hex: 0xFFF2B0).withAlphaComponent(0.55), UIColor(hex: 0xFFF2B0).withAlphaComponent(0)], center: .zero, radius: r * 1.3)
        // The tower's top: a red band round white, the gallery's railing, the lantern and its red cap.
        let R = r * 0.42
        shadow(dx: r * 0.25, dy: -r * 0.38, blur: r * 0.12, alpha: 0.4) { fill(circle(.zero, R), .black) }
        fill(circle(.zero, R), UIColor(hex: 0xC8392E))
        fill(circle(.zero, R * 0.82), UIColor(hex: 0xF4F1EA))
        radial(circle(.zero, R), [UIColor.white.withAlphaComponent(0.2), UIColor.clear, UIColor.black.withAlphaComponent(0.25)], center: pt(-R * 0.3, R * 0.3), radius: R * 1.3)
        stroke(circle(.zero, R * 0.9), UIColor(hex: 0x2A2A2A), r * 0.015)
        for k in 0..<16 {
            let a = CGFloat(k) / 16 * .pi * 2
            fill(circle(pt(cos(a) * R * 0.9, sin(a) * R * 0.9), r * 0.012), UIColor(hex: 0x2A2A2A))
        }
        glow(.zero, R * 0.9, UIColor(hex: 0xFFE07A), 0.6)
        fill(circle(.zero, R * 0.5), UIColor(hex: 0x2B3A44))
        fill(circle(.zero, R * 0.42), UIColor(hex: 0xFFE9A0).withAlphaComponent(0.85))
        for k in 0..<6 {
            let a = CGFloat(k) / 6 * .pi * 2
            stroke(CourseArt.line(pt(cos(a) * R * 0.2, sin(a) * R * 0.2), pt(cos(a) * R * 0.5, sin(a) * R * 0.5)), UIColor(hex: 0x2B3A44), r * 0.012)
        }
        radial(circle(.zero, R * 0.24), [UIColor(hex: 0xE85A4A), UIColor(hex: 0xA82A20)], center: pt(-R * 0.08, R * 0.08), radius: R * 0.28)
        fill(circle(.zero, R * 0.05), UIColor(hex: 0x2A2A2A))
    }

    // MARK: City Muni: golf carts parked on a pad

    func golfCarts(_ r: CGFloat) {
        let pad = CGRect(x: -r * 0.9, y: -r * 0.65, width: r * 1.8, height: r * 1.3)
        fill(CGPath(rect: pad, transform: nil), UIColor(hex: 0xA9A9A2))
        clipped(CGPath(rect: pad, transform: nil)) { noise(alpha: 0.2) }
        for k in 0..<4 {
            let x = pad.minX + pad.width * CGFloat(k) / 3
            stroke(CourseArt.line(pt(x, pad.minY + r * 0.1), pt(x, pad.maxY - r * 0.1)), UIColor.white.withAlphaComponent(0.8), r * 0.02)
        }
        for (k, color) in [UIColor(hex: 0xF4F1EA), UIColor(hex: 0x2E7D4F), UIColor(hex: 0xF4F1EA)].enumerated() {
            let cx = pad.minX + pad.width * (CGFloat(k) + 0.5) / 3
            turned(k == 1 ? 0.05 : -0.04, at: pt(cx, -r * 0.02)) {
                let W = r * 0.36, L = r * 0.78
                for y in [-L * 0.32, L * 0.3] {
                    for x in [-W / 2, W / 2] {
                        fill(CGPath(roundedRect: CGRect(x: x - r * 0.035, y: y - r * 0.07, width: r * 0.07, height: r * 0.14), cornerWidth: r * 0.02, cornerHeight: r * 0.02, transform: nil), UIColor(hex: 0x1E1E1E))
                    }
                }
                let body = CGPath(roundedRect: CGRect(x: -W / 2, y: -L / 2, width: W, height: L), cornerWidth: W * 0.25, cornerHeight: W * 0.25, transform: nil)
                dropShadow(W) { fill(body, color.darker(0.1)) }
                // Golf bag on the back, the roof over the seats, the windscreen at the front.
                fill(circle(pt(0, -L * 0.36), W * 0.22), UIColor(hex: 0x3A3A3A))
                for j in 0..<3 { fill(circle(pt(-W * 0.1 + CGFloat(j) * W * 0.1, -L * 0.36), W * 0.05), UIColor(hex: 0xCCCCCC)) }
                let roof = CGPath(roundedRect: CGRect(x: -W * 0.48, y: -L * 0.22, width: W * 0.96, height: L * 0.6), cornerWidth: W * 0.12, cornerHeight: W * 0.12, transform: nil)
                shadow(dx: r * 0.03, dy: -r * 0.05, blur: r * 0.04, alpha: 0.35) { fill(roof, color) }
                linear(roof, [color.lighter(0.15), color, color.darker(0.12)], from: pt(-W / 2, L * 0.4), to: pt(W / 2, -L * 0.2))
                fill(CGPath(rect: CGRect(x: -W * 0.42, y: L * 0.38, width: W * 0.84, height: L * 0.05), transform: nil), UIColor(hex: 0x9FC8E0).withAlphaComponent(0.8))
            }
        }
    }

    // MARK: Stadium Course: a hospitality marquee

    func marquee(_ r: CGFloat, _ t: Theme) {
        let W = r * 1.5, H = r * 0.62
        let green = UIColor(hex: 0x1F6B45), canvas = UIColor(hex: 0xF7F5EF)
        turned(-0.06) {
            let tent = CGRect(x: -W / 2, y: -H / 2, width: W, height: H)
            dropShadow(W) { fill(CGPath(rect: tent, transform: nil), .black) }
            // Three square bays, each peaked over its middle: four facets lit by how they face (light from the
            // upper left), seams down to the corners and a finial on top.
            let bay = W / 3
            for k in 0..<3 {
                let x0 = tent.minX + bay * CGFloat(k), peak = pt(x0 + bay / 2, 0)
                let corners = [pt(x0, H / 2), pt(x0 + bay, H / 2), pt(x0 + bay, -H / 2), pt(x0, -H / 2)]
                let shades: [CGFloat] = [0.0, 0.16, 0.24, 0.07]
                for j in 0..<4 {
                    fill(poly([corners[j], corners[(j + 1) % 4], peak]), canvas.darker(shades[j]))
                }
                for corner in corners { stroke(CourseArt.line(corner, peak), canvas.darker(0.3), r * 0.01) }
                fill(circle(peak, r * 0.03), UIColor(hex: 0xE8C25A))
                fill(poly([pt(peak.x, peak.y + r * 0.02), pt(peak.x + r * 0.13, peak.y + r * 0.06), pt(peak.x, peak.y + r * 0.1)]), green.lighter(0.15))
            }
            // A green scalloped valance round the eaves.
            stroke(CGPath(rect: tent, transform: nil), green, r * 0.03)
            let n = 21
            for k in 0..<n {
                let x = -W / 2 + W * (CGFloat(k) + 0.5) / CGFloat(n)
                fill(circle(pt(x, H / 2), r * 0.032), green)
                fill(circle(pt(x, -H / 2), r * 0.032), green.darker(0.15))
            }
            for k in 0..<4 {
                let y = -H / 2 + H * (CGFloat(k) + 0.5) / 4
                fill(circle(pt(-W / 2, y), r * 0.032), green.lighter(0.05))
                fill(circle(pt(W / 2, y), r * 0.032), green.darker(0.2))
            }
            clipped(CGPath(rect: tent, transform: nil)) { noise(alpha: 0.08) }
        }
        // Café tables under umbrellas out front.
        for p in [pt(-r * 0.45, -r * 0.72), pt(r * 0.3, -r * 0.78)] {
            shadow(dx: r * 0.05, dy: -r * 0.08, blur: r * 0.05, alpha: 0.35) { fill(circle(p, r * 0.16), green) }
            for k in 0..<6 {
                let a0 = CGFloat(k) / 6 * .pi * 2
                fill(wedge(r * 0.16, center: p, from: a0, to: a0 + .pi / 3), k % 2 == 0 ? green : canvas)
            }
            fill(circle(p, r * 0.02), canvas.darker(0.3))
        }
    }

    // MARK: Starbase: a shuttle on its landing pad

    func shuttlePad(_ r: CGFloat) {
        let R = r * 0.98
        dropShadow(R * 2) { fill(circle(.zero, R), UIColor(hex: 0x2B3440)) }
        radial(circle(.zero, R), [UIColor(hex: 0x3A4552), UIColor(hex: 0x262E38)], center: pt(-R * 0.3, R * 0.3), radius: R * 1.3)
        clipped(circle(.zero, R)) { noise(alpha: 0.15) }
        // Hazard stripes round the rim, a landing ring, and lights.
        let ring = CGMutablePath()
        ring.addPath(circle(.zero, R * 0.97))
        ring.addPath(circle(.zero, R * 0.86))
        clipped(ring, evenOdd: true) {
            for k in 0..<36 {
                let a = CGFloat(k) / 36 * .pi * 2
                fill(wedge(R, from: a, to: a + .pi / 36), k % 2 == 0 ? UIColor(hex: 0xF2C14E) : UIColor(hex: 0x1E1E1E))
            }
        }
        stroke(circle(.zero, R * 0.62), UIColor(hex: 0xF2C14E).withAlphaComponent(0.8), r * 0.02)
        for k in 0..<12 {
            let a = CGFloat(k) / 12 * .pi * 2
            let p = pt(cos(a) * R * 0.76, sin(a) * R * 0.76)
            glow(p, r * 0.07, UIColor(hex: 0x6FE3FF), 0.7)
            fill(circle(p, r * 0.018), UIColor(hex: 0xC8F6FF))
        }
        // The shuttle, nose to the upper right: delta wings, a tail fin, the cockpit, engines aglow.
        turned(0.6) {
            let hull = UIColor(hex: 0xEEF1F4), trim = UIColor(hex: 0x9AA6B2)
            let wings = poly([pt(-r * 0.15, r * 0.35), pt(-r * 0.5, -r * 0.42), pt(-r * 0.05, -r * 0.3), pt(r * 0.05, -r * 0.3), pt(r * 0.5, -r * 0.42), pt(r * 0.15, r * 0.35)])
            shadow(dx: r * 0.12, dy: -r * 0.18, blur: r * 0.08, alpha: 0.5) { fill(wings, trim) }
            linear(wings, [hull, trim], from: pt(-r * 0.4, r * 0.2), to: pt(r * 0.4, -r * 0.4))
            stroke(wings, trim.darker(0.3), r * 0.01)
            let body = CGPath(roundedRect: CGRect(x: -r * 0.11, y: -r * 0.45, width: r * 0.22, height: r * 0.95), cornerWidth: r * 0.11, cornerHeight: r * 0.11, transform: nil)
            fill(body, hull)
            linear(body, [UIColor.white, hull, trim], from: pt(-r * 0.11, 0), to: pt(r * 0.11, 0))
            stroke(body, trim.darker(0.25), r * 0.01)
            fill(ellipse(pt(0, r * 0.35), r * 0.07, r * 0.1), UIColor(hex: 0x1F3B5A))
            fill(ellipse(pt(-r * 0.02, r * 0.38), r * 0.025, r * 0.04), UIColor.white.withAlphaComponent(0.6))
            stroke(CourseArt.line(pt(0, -r * 0.42), pt(0, -r * 0.1)), trim.darker(0.4), r * 0.03)
            for x in [-r * 0.06, 0, r * 0.06] {
                glow(pt(x, -r * 0.5), r * 0.08, UIColor(hex: 0x6FE3FF), 0.8)
                fill(circle(pt(x, -r * 0.46), r * 0.03), UIColor(hex: 0x3A4552))
            }
        }
    }
}
