import UIKit

/// Starbase's glow colors.
enum Neon {
    static let cyan = UIColor(hex: 0x4FE3FF)
    static let magenta = UIColor(hex: 0xFF5FD2)
    static let amber = UIColor(hex: 0xFFD166)
}

extension Painter {
    // MARK: Starbase (course 10)

    /// The station deck round the course: dark floor plates with seams and rivets, a few lit panels, and hazard
    /// stripes by the hull.
    func deckGround(_ t: Theme, _ rect: CGRect, _ rng: inout SeededRandom) {
        let plate: CGFloat = 40
        var y = (rect.minY / plate).rounded(.down) * plate
        while y < rect.maxY {
            var x = (rect.minX / plate).rounded(.down) * plate
            while x < rect.maxX {
                let r = CGRect(x: x, y: y, width: plate, height: plate)
                fill(r.insetBy(dx: 0.6, dy: 0.6), t.rough.mixed(with: t.roughLight, rng.range(0, 0.25)))
                for (cx, cy) in [(r.minX + 4, r.minY + 4), (r.maxX - 4, r.minY + 4), (r.minX + 4, r.maxY - 4), (r.maxX - 4, r.maxY - 4)] {
                    fill(circle(CGPoint(x: cx, y: cy), 0.9), t.roughLight.lighter(0.15))
                }
                if rng.unit() < 0.12 {
                    // Floor grating: thin slots across the plate.
                    for k in 0..<5 {
                        fill(CGRect(x: r.minX + 8, y: r.minY + 9 + CGFloat(k) * 5, width: plate - 16, height: 1.8), t.roughShade.darker(0.35))
                    }
                } else if rng.unit() < 0.06 {
                    let light = rng.pick(t.flowers)
                    fill(rounded(CGRect(x: r.midX - 7, y: r.midY - 2, width: 14, height: 4), 2), light.withAlphaComponent(0.85))
                }
                x += plate
            }
            y += plate
        }
        noise(alpha: 0.12)
        // Hazard stripes just outside the hull.
        let o = CourseArt.borderOut, w = CGFloat(Course.width), h = CGFloat(Course.height)
        let band = CGMutablePath()
        band.addRect(CGRect(x: -o - 10, y: -o - 10, width: w + 2 * o + 20, height: h + 2 * o + 20))
        band.addRect(CGRect(x: -o, y: -o, width: w + 2 * o, height: h + 2 * o))
        clipped(band, evenOdd: true) {
            var s = -h
            while s < w + h {
                let stripe = CGMutablePath()
                stripe.move(to: CGPoint(x: s - o - 20, y: -o - 20))
                stripe.addLine(to: CGPoint(x: s - o - 10, y: -o - 20))
                stripe.addLine(to: CGPoint(x: s - o - 10 + h + 2 * o + 40, y: h + o + 20))
                stripe.addLine(to: CGPoint(x: s - o - 20 + h + 2 * o + 40, y: h + o + 20))
                stripe.closeSubpath()
                fill(stripe, Neon.amber.withAlphaComponent(0.55))
                s += 20
            }
        }
    }

    /// A cargo crate seen from above: a box with cross bracing and a stencilled mark.
    func crate(radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom) {
        let a = rng.range(-0.3, 0.3)
        c.saveGState()
        c.rotate(by: a)
        let box = CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)
        shadow(dx: r * 0.15, dy: -r * 0.2, blur: r * 0.2, alpha: 0.5) { fill(rounded(box, 2), color.darker(0.3)) }
        linear(rounded(box, 2), [color.lighter(0.12), color, color.darker(0.15)], from: CGPoint(x: -r, y: r), to: CGPoint(x: r, y: -r))
        let inner = box.insetBy(dx: r * 0.16, dy: r * 0.16)
        stroke(CGPath(rect: inner, transform: nil), color.darker(0.35), 1.2)
        stroke(CourseArt.line(CGPoint(x: inner.minX, y: inner.minY), CGPoint(x: inner.maxX, y: inner.maxY)), color.darker(0.35), 1.2)
        stroke(CourseArt.line(CGPoint(x: inner.minX, y: inner.maxY), CGPoint(x: inner.maxX, y: inner.minY)), color.darker(0.35), 1.2)
        fill(rounded(CGRect(x: -r * 0.3, y: -r * 0.12, width: r * 0.6, height: r * 0.24), 1), UIColor.white.withAlphaComponent(0.5))
        stroke(rounded(box, 2), UIColor.black.withAlphaComponent(0.45), 0.8)
        c.restoreGState()
    }

    /// A console: a slanted desk of controls with a lit screen and a few buttons.
    func console(radius r: CGFloat, _ t: Theme, _ rng: inout SeededRandom) {
        let body = rounded(CGRect(x: -r, y: -r * 0.6, width: 2 * r, height: 1.2 * r), 3)
        shadow(dx: r * 0.12, dy: -r * 0.18, blur: r * 0.2, alpha: 0.5) { fill(body, UIColor(hex: 0x2E3542)) }
        linear(body, [UIColor(hex: 0x6C7888), UIColor(hex: 0x465060)], from: CGPoint(x: 0, y: r * 0.6), to: CGPoint(x: 0, y: -r * 0.6))
        let screen = rounded(CGRect(x: -r * 0.75, y: -r * 0.05, width: r * 1.5, height: r * 0.5), 1.5)
        let glow = rng.pick(t.flowers)
        fill(screen, glow.withAlphaComponent(0.85))
        for k in 0..<3 {
            fill(CGRect(x: -r * 0.65, y: r * 0.05 + CGFloat(k) * r * 0.13, width: r * rng.range(0.4, 1.2), height: r * 0.05), UIColor.white.withAlphaComponent(0.6))
        }
        for k in 0..<4 {
            fill(circle(CGPoint(x: -r * 0.6 + CGFloat(k) * r * 0.4, y: -r * 0.35), r * 0.09), rng.pick(t.flowers))
        }
        stroke(body, UIColor.black.withAlphaComponent(0.5), 0.8)
    }

    /// A block as station machinery: a steel housing with vents and a strip of status lights.
    func machinery(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CourseArt.rounded(r, 2, square: square)
        linear(path, [UIColor(hex: 0x56616F), UIColor(hex: 0x3B4450)], from: CGPoint(x: r.minX, y: r.maxY), to: CGPoint(x: r.maxX, y: r.minY))
        clipped(path) {
            let horizontal = r.width >= r.height
            var s: CGFloat = 6
            while s < (horizontal ? r.width : r.height) - 6 {
                let slot = horizontal ? CGRect(x: r.minX + s, y: r.minY + 4, width: 2, height: r.height - 8)
                                      : CGRect(x: r.minX + 4, y: r.minY + s, width: r.width - 8, height: 2)
                fill(slot, UIColor.black.withAlphaComponent(0.35))
                s += 5
            }
            let n = max(1, Int((horizontal ? r.width : r.height) / 24))
            for k in 0..<n {
                let f = (CGFloat(k) + 0.5) / CGFloat(n)
                let p = horizontal ? CGPoint(x: r.minX + r.width * f, y: r.midY) : CGPoint(x: r.midX, y: r.minY + r.height * f)
                fill(circle(p, 1.4), rng.pick(t.flowers))
            }
            noise(alpha: 0.12)
        }
        stroke(path, UIColor.black.withAlphaComponent(0.4), 0.8)
    }

    /// Water as an open hatch to space: black, full of stars, with a glowing rim and hazard-striped edge. `hidden`
    /// adds a pair's hidden stars (`CourseArt.hiddenStars`) to those that fall in this hatch.
    func voidPond(_ water: CourseArt.Pond, _ t: Theme, _ rng: inout SeededRandom, hidden: [CourseArt.Star] = []) {
        let pond = water.path, b = water.bounds
        stroke(pond.copy(dashingWithPhase: 0, lengths: [5, 5]), Neon.amber, 5)
        radial(pond, [t.waterShallow, t.waterDeep], center: CGPoint(x: b.midX, y: b.midY), radius: max(b.width, b.height) * 0.6)
        clipped(pond) {
            for _ in 0..<Int(b.width * b.height / 60) + 6 {
                let p = CGPoint(x: rng.range(b.minX, b.maxX), y: rng.range(b.minY, b.maxY))
                let r = rng.range(0.3, 0.9), alpha = rng.range(0.4, 0.95)
                // A little dark sky round the hidden stars, so their lines read to someone who looks for them.
                if hidden.contains(where: { hypot($0.center.x - p.x, $0.center.y - p.y) < 3 }) { continue }
                fill(circle(p, r), UIColor.white.withAlphaComponent(alpha))
            }
            for star in hidden { fill(circle(star.center, star.radius), UIColor.white.withAlphaComponent(star.alpha)) }
            shadow(dx: 0, dy: 0, blur: 6, alpha: 0.8) {
                let ring = CGMutablePath()
                ring.addRect(b.insetBy(dx: -30, dy: -30))
                ring.addPath(pond)
                fill(ring, Neon.cyan.withAlphaComponent(0.5), evenOdd: true)
            }
        }
        stroke(pond, Neon.cyan.withAlphaComponent(0.7), 1)
    }

    /// Tunnels as teleporter pads: a glowing ring in the pair's color round a dark hex-plated pad.
    func teleporters(_ level: Level) {
        for (i, tn) in level.tunnels.enumerated() {
            let color = TunnelColors.color(i)
            for (mouth, exit) in [(tn.a, tn.exitA), (tn.b, tn.exitB)] {
                let c = CGPoint(x: mouth.x, y: mouth.y)
                let r = CGFloat(Tunnel.radius)
                shadow(dx: 0, dy: 0, blur: 6, alpha: 0.9) { stroke(circle(c, r + 2.5), color, 3) }
                radial(circle(c, r + 1), [color.withAlphaComponent(0.55), UIColor(hex: 0x0B1020)], center: c, radius: r + 1)
                clipped(circle(c, r)) {
                    for k in 0..<6 {
                        let a = CGFloat(k) * .pi / 3
                        stroke(CourseArt.line(c, CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)), color.withAlphaComponent(0.35), 0.7)
                    }
                }
                stroke(circle(c, r * 0.55), color.lighter(0.4).withAlphaComponent(0.8), 0.8)
                fill(circle(c, 1.6), UIColor.white)
                if let exit {
                    let a = CGFloat(exit * .pi / 180)
                    let p = CGPoint(x: c.x + cos(a) * (r + 10), y: c.y + sin(a) * (r + 10))
                    chevron(at: p, angle: a, size: 5, color: color.lighter(0.4))
                }
            }
        }
    }

    /// Slope boxes as conveyor belts: dark belting with ribs across it and chevrons pointing the way it carries.
    func conveyors(_ level: Level) {
        for sl in level.slopes {
            let r = CGRect(x: sl.box.minX, y: sl.box.minY, width: sl.box.width, height: sl.box.height)
            let path = rounded(r, 4)
            fill(path, UIColor(hex: 0x1E242E))
            let a = CGFloat(atan2(sl.accel.y, sl.accel.x))
            clipped(path) {
                // Ribs across the belt, square to the way it runs.
                let d = CGPoint(x: cos(a), y: sin(a)), n = CGPoint(x: -d.y, y: d.x)
                let reach = hypot(r.width, r.height)
                var k = -reach
                while k < reach {
                    let c = CGPoint(x: r.midX + d.x * k, y: r.midY + d.y * k)
                    stroke(CourseArt.line(CGPoint(x: c.x - n.x * reach, y: c.y - n.y * reach), CGPoint(x: c.x + n.x * reach, y: c.y + n.y * reach)),
                           UIColor(hex: 0x39424F), 1.4)
                    k += 6
                }
                var y = r.minY + 14
                while y < r.maxY - 6 {
                    var x = r.minX + 14
                    while x < r.maxX - 6 {
                        chevron(at: CGPoint(x: x, y: y), angle: a, size: 5, color: Neon.amber.withAlphaComponent(0.75))
                        x += 28
                    }
                    y += 28
                }
            }
            stroke(path, Neon.amber.withAlphaComponent(0.6), 1)
        }
    }

    /// Hills and bowls as repulsors and gravity wells: rings of light, magenta pushing out, cyan pulling in.
    func wells(_ level: Level) {
        for m in level.mounds {
            let c = CGPoint(x: m.center.x, y: m.center.y), R = CGFloat(m.radius)
            let color = m.strength > 0 ? Neon.magenta : Neon.cyan
            for k in 1...3 {
                let f = CGFloat(k) / 3
                stroke(circle(c, R * f), color.withAlphaComponent(0.55 - 0.12 * CGFloat(k)), 1.4)
            }
            shadow(dx: 0, dy: 0, blur: 5, alpha: 0.9) { fill(circle(c, 3), color) }
            fill(circle(c, 1.5), UIColor.white)
        }
    }

    /// Kickers as boost pads: a dark plate with glowing chevrons pointing where it launches the ball.
    func boostPads(_ level: Level) {
        for k in level.kickers {
            let c = CGPoint(x: k.center.x, y: k.center.y)
            let r = CGFloat(Kicker.radius)
            let a = CGFloat(k.direction * .pi / 180)
            shadow(dx: 0, dy: 0, blur: 5, alpha: 0.8) { stroke(circle(c, r + 1.5), Neon.cyan, 2) }
            radial(circle(c, r + 0.5), [UIColor(hex: 0x24304A), UIColor(hex: 0x0E1424)], center: c, radius: r)
            for (i, d) in [-5.5, 0.0, 5.5].enumerated() {
                let p = CGPoint(x: c.x + cos(a) * CGFloat(d), y: c.y + sin(a) * CGFloat(d))
                chevron(at: p, angle: a, size: 4.2, color: Neon.cyan.withAlphaComponent(0.5 + 0.25 * CGFloat(i)))
            }
        }
    }
}

// MARK: - Hidden stars

extension CourseArt {
    /// A star in a hatch to space: centre, radius and brightness.
    struct Star {
        var center: CGPoint
        var radius: CGFloat
        var alpha: CGFloat
    }

    /// A pattern some of a hatch's stars line up along. The stars are drawn just like the ones round them, so it
    /// shows only to someone who knows it's there. Strokes are in pattern units (y up, 6 tall), placed at `origin`,
    /// `scale` course units per pattern unit and turned `tilt` degrees anticlockwise.
    struct StarPattern {
        var origin: CGPoint
        var scale: CGFloat
        var tilt: CGFloat
        var strokes: [[(CGFloat, CGFloat)]]
    }

    /// Two of Starbase's open hatches hide a pattern in their stars.
    static let starPatterns: [String: StarPattern] = [
        "Airlock": StarPattern(origin: CGPoint(x: 244, y: 710), scale: 5, tilt: 5, strokes: [
            [(0, 0), (0, 6), (2.6, 6), (3.5, 5.6), (3.9, 4.8), (3.5, 3.6), (2.6, 3.1), (0, 3.1)],
            [(2.2, 3.1), (4, 0)],
            [(5.6, 0), (7.6, 0)],
            [(6.6, 0), (6.6, 6)],
            [(5.6, 6), (7.6, 6)],
            [(9.2, 6), (9.2, 0), (12.6, 0)],
            [(17.6, 6), (14.2, 6), (14.2, 0), (17.6, 0)],
            [(14.2, 3.1), (16.8, 3.1)],
            [(19.2, 6), (21.2, 3), (23.2, 6)],
            [(21.2, 3), (21.2, 0)],
        ]),
        "Laser Grid": StarPattern(origin: CGPoint(x: 222, y: 704), scale: 5, tilt: -4, strokes: [
            [(0, 0), (0, 6), (2.6, 6), (3.5, 5.6), (3.9, 4.8), (3.5, 3.6), (2.6, 3.1), (0, 3.1)],
            [(2.2, 3.1), (4, 0)],
            [(9, 6), (5.6, 6), (5.6, 0), (9, 0)],
            [(5.6, 3.1), (8.2, 3.1)],
            [(10.6, 0), (12.6, 6), (14.6, 0)],
            [(11.4, 2.4), (13.8, 2.4)],
            [(20, 4.9), (19.4, 5.7), (18.2, 6), (17, 5.7), (16.3, 4.6), (16.2, 3), (16.3, 1.4), (17, 0.3), (18.2, 0),
             (19.4, 0.3), (20.1, 1.2), (20.2, 2.7), (18.5, 2.7)],
            [(21.8, 0), (23.8, 6), (25.8, 0)],
            [(22.6, 2.4), (25, 2.4)],
            [(27.4, 0), (27.4, 6), (31.4, 0), (31.4, 6)],
        ]),
    ]

    /// A pair's hidden stars: spaced about evenly along its pattern's strokes, each nudged a little off its line, and
    /// as varied in size and brightness as the rest. None on a pair without a pattern. They draw on their own random
    /// numbers, so the rest of the pair's art stays as it was.
    static func hiddenStars(_ level: Level) -> [Star] {
        guard let pattern = starPatterns[level.name] else { return [] }
        var rng = SeededRandom(seed: stableSeed(level.name) &+ 1)
        let spacing: CGFloat = 3.6, nudge: CGFloat = 0.65
        let a = pattern.tilt * .pi / 180
        var stars: [Star] = []
        for stroke in pattern.strokes {
            let points = stroke.map { CGPoint(x: pattern.origin.x + pattern.scale * ($0.0 * cos(a) - $0.1 * sin(a)),
                                              y: pattern.origin.y + pattern.scale * ($0.0 * sin(a) + $0.1 * cos(a))) }
            let segments = zip(points, points.dropFirst()).map { ($0, $1, hypot($1.x - $0.x, $1.y - $0.y)) }
            let length = segments.reduce(0) { $0 + $1.2 }
            let count = max(1, Int((length / spacing).rounded()))
            for k in 0...count {
                var s = length * CGFloat(k) / CGFloat(count), p = points[points.count - 1]
                for (from, to, d) in segments {
                    if s <= d { p = CGPoint(x: from.x + (to.x - from.x) * s / d, y: from.y + (to.y - from.y) * s / d); break }
                    s -= d
                }
                // Where strokes meet, one star does for both.
                if stars.contains(where: { hypot($0.center.x - p.x, $0.center.y - p.y) < spacing * 0.6 }) { continue }
                stars.append(Star(center: CGPoint(x: p.x + rng.range(-nudge, nudge), y: p.y + rng.range(-nudge, nudge)),
                                  radius: rng.range(0.3, 0.9), alpha: rng.range(0.4, 0.95)))
            }
        }
        return stars
    }
}

// MARK: - Starbase mover sprites

extension CourseArt {
    /// A patrol robot seen from above, facing +x (the scene turns it to its heading): a round steel body on two
    /// treads, a glowing visor at the front and a beacon on top.
    static func robot(radius: Double, ppu: CGFloat, shadow: Bool) -> UIImage {
        // Drawn out to its full radius, the edge a ball bounces off, so a bank touches the robot.
        let R = CGFloat(radius), ext = R + 3
        return render(CGRect(x: -ext, y: -ext, width: ext * 2, height: ext * 2), ppu: ppu) { p in
            if shadow { p.fill(p.circle(.zero, R), .black); return }
            let body = p.circle(.zero, R)
            p.radial(body, [UIColor(hex: 0xFFFFFF), UIColor(hex: 0xD5DCE4), UIColor(hex: 0x8B96A3)], center: CGPoint(x: -R * 0.35, y: R * 0.35), radius: R * 1.15)
            // Treads showing at each side.
            for side in [CGFloat(1), -1] {
                let tread = p.rounded(CGRect(x: -R * 0.6, y: side > 0 ? R * 0.68 : -R * 0.98, width: R * 1.2, height: R * 0.3), R * 0.12)
                p.clipped(body) { p.fill(tread, UIColor(hex: 0x2A2F36)) }
            }
            p.stroke(p.circle(.zero, R * 0.62), Neon.amber, R * 0.16)
            // The visor: a glowing arc across the front.
            let visor = CGMutablePath()
            visor.addArc(center: .zero, radius: R * 0.78, startAngle: -0.7, endAngle: 0.7, clockwise: false)
            p.shadow(dx: 0, dy: 0, blur: 4, alpha: 1) { p.stroke(visor, Neon.cyan, R * 0.2) }
            p.stroke(visor, UIColor.white.withAlphaComponent(0.85), R * 0.06)
            p.fill(p.circle(.zero, R * 0.28), UIColor(hex: 0xC3CCD6))
            p.fill(p.circle(CGPoint(x: -R * 0.05, y: 0), R * 0.12), Neon.magenta)
            p.stroke(body, UIColor(hex: 0x2E343C), 1.2)
        }
    }

    /// A force field's emitters, drawn along +x and centred: a post at each end with a faint guide line between, so
    /// the gate shows even while it's dark. The beam is drawn separately.
    static func fieldPosts(length: Double, ppu: CGFloat, shadow: Bool) -> UIImage {
        let L = CGFloat(length), r: CGFloat = 5
        return render(CGRect(x: -L / 2 - r - 2, y: -r - 2, width: L + 2 * r + 4, height: 2 * r + 4), ppu: ppu) { p in
            if shadow {
                for x in [-L / 2, L / 2] { p.fill(p.circle(CGPoint(x: x, y: 0), r), .black) }
                return
            }
            p.stroke(line(CGPoint(x: -L / 2, y: 0), CGPoint(x: L / 2, y: 0)), Neon.cyan.withAlphaComponent(0.25), 1)
            for x in [-L / 2, L / 2] {
                let c = CGPoint(x: x, y: 0)
                p.radial(p.circle(c, r), [UIColor(hex: 0x8C97A5), UIColor(hex: 0x3A424E)], center: CGPoint(x: x - 1.5, y: 1.5), radius: r * 1.2)
                p.stroke(p.circle(c, r * 0.55), Neon.cyan, 1.2)
                p.stroke(p.circle(c, r), UIColor.black.withAlphaComponent(0.5), 0.6)
            }
        }
    }

    /// A force field's beam along +x and centred: a bright core in a cyan glow.
    static func fieldBeam(length: Double, ppu: CGFloat) -> UIImage {
        let L = CGFloat(length)
        return render(CGRect(x: -L / 2, y: -5, width: L, height: 10), ppu: ppu) { p in
            let band = CGRect(x: -L / 2, y: -4, width: L, height: 8)
            p.linear(CGPath(rect: band, transform: nil), [Neon.cyan.withAlphaComponent(0), Neon.cyan.withAlphaComponent(0.85), Neon.cyan.withAlphaComponent(0)],
                     locations: [0, 0.5, 1], from: CGPoint(x: 0, y: 4), to: CGPoint(x: 0, y: -4))
            p.fill(CGRect(x: -L / 2, y: -0.9, width: L, height: 1.8), UIColor.white.withAlphaComponent(0.95))
        }
    }
}
