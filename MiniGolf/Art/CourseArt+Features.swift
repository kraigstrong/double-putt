import UIKit

/// Colors that identify each tunnel's pair of mouths.
enum TunnelColors {
    static let all = [UIColor(hex: 0x37C8C3), UIColor(hex: 0xF06BB0), UIColor(hex: 0xF5B83D)]
    static func color(_ i: Int) -> UIColor { all[i % all.count] }
}

extension Painter {
    // MARK: Terrain

    /// Sloped ground: a grid tinted by height, from blue at the low end of each side to red at the high end. The
    /// scene's dots (SlopeFlow) glide along its lines downhill, so the grid shows the shape and the dots the pull.
    func slopeGrid(_ level: Level, _ t: Theme) {
        guard level.hasGround else { return }
        func rect(_ b: Box) -> CGRect { CGRect(x: b.minX, y: b.minY, width: b.width, height: b.height) }
        var parts: [CGPath] = level.slopes.map { CourseArt.rounded(rect($0.box), 10, square: Corners(CourseArt.walledSides($0.box, level))) }
        parts += level.mounds.map { circle(CGPoint(x: $0.center.x, y: $0.center.y), CGFloat($0.radius)) }
        parts += level.terrain.features.map { CGPath(rect: rect($0.area), transform: nil) }
        guard let first = parts.first else { return }
        var region = parts.dropFirst().reduce(first) { $0.union($1) }
        // Starbase draws slope boxes as conveyor belts, whose chevrons (and the gliding dots) already show the pull.
        if t.scifi {
            for sl in level.slopes { region = region.subtracting(CGPath(rect: rect(sl.box), transform: nil)) }
            // Clipping to an empty path clips nothing, so with only belts there's no grid to draw at all.
            if region.boundingBoxOfPath.isEmpty { return }
        }
        // Only on green and fringe, worked out in paint order as the physics does: the bare felt is green, then each
        // patch adds or takes away.
        if !level.patches.isEmpty {
            var turf = CGPath(rect: CGRect(x: 0, y: 0, width: Course.width, height: Course.height), transform: nil)
            for p in level.patches {
                turf = p.surface.isTurf ? turf.union(patchPath(p)) : turf.subtracting(patchPath(p))
            }
            region = region.intersection(turf)
        }
        let r = Course.railRadius
        let felt = CGPath(rect: CGRect(x: r, y: r, width: Course.width - 2 * r, height: Course.height - 2 * r), transform: nil)

        // A faint edge round each sloped patch (a contoured side's edge sits under its rails).
        clipped(felt) { stroke(region, UIColor.white.withAlphaComponent(0.2), 1) }

        let gap = SlopeFlow.grid, step = 4.0, buckets = 24
        for side in [Side.a, .b] {
            let x0 = side.offset, x1 = side.offset + Course.half
            // Each side spans the whole blue-to-red scale over its own sloped ground.
            var lo = Double.infinity, hi = -Double.infinity
            for y in stride(from: 2.0, to: Course.height, by: step) {
                for x in stride(from: x0 + 2, to: x1, by: step) where level.isSloped(at: Vec(x, y)) {
                    let h = level.groundHeight(at: Vec(x, y))
                    lo = min(lo, h); hi = max(hi, h)
                }
            }
            guard lo <= hi else { continue }
            // One path per colour band, so thousands of short segments stroke in a couple of dozen calls.
            let paths = (0..<buckets).map { _ in CGMutablePath() }
            func segment(_ a: Vec, _ b: Vec) {
                let mid = Vec((a.x + b.x) / 2, (a.y + b.y) / 2)
                guard level.isSloped(at: mid) else { return }
                let f = hi - lo < 1e-3 ? 0.5 : (level.groundHeight(at: mid) - lo) / (hi - lo)
                let k = max(0, min(buckets - 1, Int(f * Double(buckets))))
                paths[k].move(to: CGPoint(x: a.x, y: a.y))
                paths[k].addLine(to: CGPoint(x: b.x, y: b.y))
            }
            for x in stride(from: x0 + gap, to: x1 - 1, by: gap) {
                for y in stride(from: 0, to: Course.height, by: step) { segment(Vec(x, y), Vec(x, y + step)) }
            }
            for y in stride(from: gap, to: Course.height - 1, by: gap) {
                for x in stride(from: x0, to: x1, by: step) { segment(Vec(x, y), Vec(min(x + step, x1), y)) }
            }
            clipped(region) {
                clipped(felt) {
                    for k in 0..<buckets {
                        let f = (CGFloat(k) + 0.5) / CGFloat(buckets)
                        stroke(paths[k], UIColor(hue: (220 - 220 * f) / 360, saturation: 0.69, brightness: 0.94, alpha: 0.75), 1.3)
                    }
                }
            }
        }
    }

    func chevron(at p: CGPoint, angle: CGFloat, size s: CGFloat, color: UIColor) {
        let path = CGMutablePath()
        let ca = cos(angle), sa = sin(angle)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: p.x + x * ca - y * sa, y: p.y + x * sa + y * ca) }
        path.move(to: pt(-s * 0.5, s * 0.8))
        path.addLine(to: pt(s * 0.5, 0))
        path.addLine(to: pt(-s * 0.5, -s * 0.8))
        stroke(path, color, 1.6)
    }

    /// Pipe mouths: a dark hole with a colored rim; the color pairs the two ends. Exit arrows when set.
    func tunnels(_ level: Level, _ t: Theme) {
        if t.scifi { teleporters(level); return }
        for (i, tn) in level.tunnels.enumerated() {
            let color = TunnelColors.color(i)
            for (mouth, exit) in [(tn.a, tn.exitA), (tn.b, tn.exitB)] {
                let c = CGPoint(x: mouth.x, y: mouth.y)
                let r = CGFloat(Tunnel.radius)
                shadow(dx: 1.5, dy: -2, blur: 2.5, alpha: 0.45) {
                    fill(circle(c, r + 4.5), color.darker(0.15))
                }
                linear(circle(c, r + 4.5), [color.lighter(0.35), color, color.darker(0.3)],
                       from: CGPoint(x: c.x - r, y: c.y + r), to: CGPoint(x: c.x + r, y: c.y - r))
                radial(circle(c, r), [UIColor(hex: 0x050505), UIColor(hex: 0x1C1C1C), UIColor(hex: 0x333333)], center: c, radius: r)
                clipped(circle(c, r)) {
                    shadow(dx: 1.5, dy: -2, blur: 3, alpha: 0.9) {
                        let ring = CGMutablePath()
                        ring.addPath(circle(c, r + 8))
                        ring.addPath(circle(c, r))
                        fill(ring, .black, evenOdd: true)
                    }
                }
                stroke(circle(c, r + 2.2), UIColor.white.withAlphaComponent(0.35), 0.8)
                if let exit {
                    let a = CGFloat(exit * .pi / 180)
                    let p = CGPoint(x: c.x + cos(a) * (r + 10), y: c.y + sin(a) * (r + 10))
                    chevron(at: p, angle: a, size: 5, color: color.lighter(0.4))
                }
            }
        }
    }

    /// Springboard pads: a red plate with a yellow rim and chevrons pointing where it launches the ball.
    func kickers(_ level: Level, _ t: Theme) {
        if t.scifi { boostPads(level); return }
        for k in level.kickers {
            let c = CGPoint(x: k.center.x, y: k.center.y)
            let r = CGFloat(Kicker.radius)
            let a = CGFloat(k.direction * .pi / 180)
            shadow(dx: 1, dy: -1.5, blur: 2, alpha: 0.4) { fill(circle(c, r + 2), UIColor(hex: 0x8A1F1F)) }
            linear(circle(c, r + 2), [UIColor(hex: 0xFFE27A), UIColor(hex: 0xF2A900)],
                   from: CGPoint(x: c.x - r, y: c.y + r), to: CGPoint(x: c.x + r, y: c.y - r))
            radial(circle(c, r - 1), [UIColor(hex: 0xFF7A6B), UIColor(hex: 0xE23B32), UIColor(hex: 0xA8231D)],
                   center: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.3), radius: r * 1.2)
            for (i, d) in [-5.5, 0.0, 5.5].enumerated() {
                let p = CGPoint(x: c.x + cos(a) * CGFloat(d), y: c.y + sin(a) * CGFloat(d))
                chevron(at: p, angle: a, size: 4.2, color: UIColor.white.withAlphaComponent(0.55 + 0.2 * CGFloat(i)))
            }
            stroke(circle(c, r + 2), UIColor.black.withAlphaComponent(0.3), 0.8)
        }
    }

    /// Round posts: stone, buoys (seaside) or lantern posts (night).
    func posts(_ level: Level, _ t: Theme) {
        for (i, b) in level.bumpers.enumerated() {
            let c = CGPoint(x: b.center.x, y: b.center.y)
            let r = CGFloat(b.radius)
            shadow(dx: r * 0.18, dy: -r * 0.28, blur: r * 0.3, alpha: 0.45) { fill(circle(c, r), .black) }
            switch t.post {
            case .buoy:
                radial(circle(c, r), [UIColor(hex: 0xFF6B5E), UIColor(hex: 0xE2412F), UIColor(hex: 0xA82A1D)], center: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.3), radius: r * 1.3)
                stroke(circle(c, r * 0.62), UIColor.white, r * 0.22)
                fill(circle(c, r * 0.22), UIColor(hex: 0xF2F2F2))
            case .lantern:
                radial(circle(c, r), [UIColor(hex: 0x6A7280), UIColor(hex: 0x3E434C)], center: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.3), radius: r * 1.3)
                fill(circle(c, r * 0.5), UIColor(hex: 0xFFE9A8))
                stroke(circle(c, r * 0.5), UIColor(hex: 0x2A2D33), 1)
            case .stone:
                radial(circle(c, r), [t.borderTop.lighter(0.25), t.borderTop, t.borderSide], center: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.3), radius: r * 1.3)
                stroke(circle(c, r * 0.72), t.borderSide.withAlphaComponent(0.5), 1)
            case .balloon:
                balloonPost(c, radius: r, color: t.flowers[i % t.flowers.count])
            }
            stroke(circle(c, r), UIColor.black.withAlphaComponent(0.35), 0.8)
        }
    }

    // MARK: Setting variants

    func tidepool(_ water: CourseArt.Pond, _ t: Theme, _ rng: inout SeededRandom) {
        let pond = water.path, bounds = water.bounds
        stroke(pond, UIColor(hex: 0xF3E6C4), 6)
        radial(pond, [t.waterDeep, t.waterShallow, t.waterShallow.lighter(0.25)], locations: [0, 0.7, 1],
               center: CGPoint(x: bounds.midX, y: bounds.midY), radius: max(bounds.width, bounds.height) * 0.62)
        clipped(pond) {
            for rect in water.parts { rockpool(rect, &rng) }
        }
        stroke(pond, UIColor.white.withAlphaComponent(0.7), 1.6)
    }

    private func rockpool(_ rect: CGRect, _ rng: inout SeededRandom) {
        for _ in 0..<5 {
            let p = CGPoint(x: rng.range(rect.minX + 8, rect.maxX - 8), y: rng.range(rect.minY + 8, rect.maxY - 8))
            let s = rng.range(3, 6)
            fill(CGPath(ellipseIn: CGRect(x: p.x - s, y: p.y - s * 0.7, width: s * 2, height: s * 1.4), transform: nil), UIColor(hex: 0x6E8B8A).withAlphaComponent(0.7))
        }
        for _ in 0..<3 {
            let p = CGPoint(x: rng.range(rect.minX + 10, rect.maxX - 10), y: rng.range(rect.minY + 10, rect.maxY - 10))
            star(p, r: rng.range(3, 4.5), color: UIColor(hex: 0xFF8A5B))
        }
    }

    func ice(_ water: CourseArt.Pond, _ t: Theme, _ rng: inout SeededRandom) {
        let pond = water.path, bounds = water.bounds
        stroke(pond, UIColor.white, 6)
        linear(pond, [t.waterShallow, t.waterDeep], from: CGPoint(x: bounds.minX, y: bounds.maxY), to: CGPoint(x: bounds.maxX, y: bounds.minY))
        clipped(pond) {
            for rect in water.parts { cracks(rect, &rng) }
        }
        stroke(pond, UIColor.white, 2)
    }

    private func cracks(_ rect: CGRect, _ rng: inout SeededRandom) {
        for _ in 0..<6 {
            let crack = CGMutablePath()
            var p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            crack.move(to: p)
            for _ in 0..<4 {
                p = CGPoint(x: p.x + rng.range(-16, 16), y: p.y + rng.range(-12, 12))
                crack.addLine(to: p)
            }
            stroke(crack, UIColor.white.withAlphaComponent(0.55), 0.7)
        }
        for _ in 0..<4 {
            let x = rng.range(rect.minX + 6, rect.maxX - 30)
            let y = rng.range(rect.minY + 6, rect.maxY - 6)
            stroke(CourseArt.line(CGPoint(x: x, y: y), CGPoint(x: x + 22, y: y + 8)), UIColor.white.withAlphaComponent(0.4), 2.5)
        }
    }

    func dune(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CourseArt.rounded(r, 3, square: square)
        linear(path, [t.rough.lighter(0.2), t.rough, t.roughShade], from: CGPoint(x: r.minX, y: r.maxY), to: CGPoint(x: r.maxX, y: r.minY))
        clipped(path) {
            var y = r.minY + 4
            while y < r.maxY {
                let ripple = CGMutablePath()
                ripple.move(to: CGPoint(x: r.minX, y: y))
                ripple.addCurve(to: CGPoint(x: r.maxX, y: y + rng.range(-3, 3)),
                                control1: CGPoint(x: r.minX + r.width * 0.33, y: y + 4), control2: CGPoint(x: r.minX + r.width * 0.66, y: y - 4))
                stroke(ripple, t.roughShade.darker(0.1).withAlphaComponent(0.45), 0.8)
                y += rng.range(6, 10)
            }
            for _ in 0..<Int(r.width * r.height / 160) + 2 {
                let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                for k in 0..<4 {
                    let a = CGFloat.pi / 2 + CGFloat(k - 2) * 0.25
                    stroke(CourseArt.line(p, CGPoint(x: p.x + cos(a) * 6, y: p.y + sin(a) * 7)), UIColor(hex: 0x8DA65A), 0.9)
                }
            }
        }
    }

    func rockBed(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CourseArt.rounded(r, 2, square: square)
        fill(path, t.borderSide.darker(0.25))
        clipped(path) {
            let count = Int(r.width * r.height / 60) + 3
            for _ in 0..<count {
                let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                let rad = rng.range(4, min(10, min(r.width, r.height) * 0.5))
                c.saveGState()
                c.translateBy(x: p.x, y: p.y)
                var local = rng
                rockShape(radius: rad, tone: t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.5)), &local)
                rng = local
                c.restoreGState()
            }
            if t.id == "desert" {
                for _ in 0..<Int(r.width * r.height / 900) + 1 {
                    let p = CGPoint(x: rng.range(r.minX + 6, r.maxX - 6), y: rng.range(r.minY + 6, r.maxY - 6))
                    blossom(p, size: 1.6, color: rng.pick(t.flowers))
                }
            }
        }
    }

    func snowbank(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CourseArt.rounded(r, 4, square: square)
        fill(path, UIColor(hex: 0xCADAE8))
        clipped(path) {
            for _ in 0..<Int(r.width * r.height / 90) + 3 {
                let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                let rad = rng.range(6, 13)
                fill(circle(CGPoint(x: p.x + 1.5, y: p.y - 2), rad), UIColor(hex: 0xB6CADC))
                fill(circle(p, rad), UIColor(hex: 0xF4F8FC))
                fill(circle(CGPoint(x: p.x - rad * 0.3, y: p.y + rad * 0.3), rad * 0.45), UIColor.white)
            }
        }
    }

    /// White snow along the top of walls.
    func snowCaps(_ level: Level, _ t: Theme) {
        let felt = CGRect(x: 0, y: 0, width: Course.width, height: Course.height).insetBy(dx: Course.railRadius, dy: Course.railRadius)
        clipped(CGPath(rect: felt, transform: nil)) {
            for w in level.rails where !CourseArt.isFrameRail(w) {
                let a = CGPoint(x: w.a.x, y: w.a.y), b = CGPoint(x: w.b.x, y: w.b.y)
                stroke(CourseArt.line(CGPoint(x: a.x - 0.8, y: a.y + 0.8), CGPoint(x: b.x - 0.8, y: b.y + 0.8)), UIColor.white.withAlphaComponent(0.9), w.radius * 1.1)
            }
        }
        let o = CourseArt.borderOut
        let band = CGRect(x: -o + 2, y: -o + 2, width: Course.width + 2 * o - 4, height: Course.height + 2 * o - 4)
        stroke(rounded(band, 10), UIColor.white.withAlphaComponent(0.85), 4)
    }

    func rockShape(radius r: CGFloat, tone: UIColor, _ rng: inout SeededRandom) {
        let path = CGMutablePath()
        let n = 7
        for k in 0..<n {
            let a = CGFloat(k) / CGFloat(n) * .pi * 2
            let d = r * rng.range(0.75, 1.0)
            let p = CGPoint(x: cos(a) * d, y: sin(a) * d * 0.85)
            k == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        shadow(dx: r * 0.2, dy: -r * 0.3, blur: r * 0.3, alpha: 0.4) { fill(path, tone.darker(0.2)) }
        linear(path, [tone.lighter(0.2), tone, tone.darker(0.25)], from: CGPoint(x: -r, y: r), to: CGPoint(x: r, y: -r))
        stroke(path, tone.darker(0.4).withAlphaComponent(0.6), 0.5)
    }

    func star(_ p: CGPoint, r: CGFloat, color: UIColor) {
        let path = CGMutablePath()
        for k in 0..<10 {
            let a = CGFloat(k) / 10 * .pi * 2 + .pi / 2
            let d = k % 2 == 0 ? r : r * 0.45
            let q = CGPoint(x: p.x + cos(a) * d, y: p.y + sin(a) * d)
            k == 0 ? path.move(to: q) : path.addLine(to: q)
        }
        path.closeSubpath()
        fill(path, color)
    }

    // MARK: Ground variants

    func sandGround(_ t: Theme, _ rect: CGRect, _ rng: inout SeededRandom) {
        let area = rect.width * rect.height
        for _ in 0..<Int(area / 9000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(40, 130)
            let color = rng.unit() < 0.6 ? t.roughShade.withAlphaComponent(0.5) : t.roughLight.withAlphaComponent(0.5)
            c.drawRadialGradient(gradient([color, color.withAlphaComponent(0)]), startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        noise(alpha: 0.12)
        for _ in 0..<Int(area / 400) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let w = rng.range(10, 26)
            let ripple = CGMutablePath()
            ripple.move(to: p)
            ripple.addQuadCurve(to: CGPoint(x: p.x + w, y: p.y), control: CGPoint(x: p.x + w / 2, y: p.y + 2.5))
            stroke(ripple, t.roughShade.darker(0.08).withAlphaComponent(0.35), 0.8)
        }
        for _ in 0..<Int(area / 2500) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            if t.id == "desert" {
                c.saveGState(); c.translateBy(x: p.x, y: p.y)
                var local = rng
                rockShape(radius: rng.range(2, 4), tone: t.borderTop, &local)
                rng = local
                c.restoreGState()
            } else {
                fill(circle(p, rng.range(1.2, 2.2)), rng.pick(t.flowers).withAlphaComponent(0.9))
            }
        }
        if t.id == "desert" {
            for _ in 0..<Int(area / 9000) {
                let crack = CGMutablePath()
                var p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
                crack.move(to: p)
                for _ in 0..<5 {
                    p = CGPoint(x: p.x + rng.range(-14, 14), y: p.y + rng.range(-14, 14))
                    crack.addLine(to: p)
                }
                stroke(crack, t.roughShade.darker(0.2).withAlphaComponent(0.4), 0.7)
            }
        }
    }

    func snowGround(_ t: Theme, _ rect: CGRect, _ rng: inout SeededRandom) {
        let area = rect.width * rect.height
        for _ in 0..<Int(area / 6000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(30, 110)
            let color = t.roughShade.withAlphaComponent(0.55)
            c.drawRadialGradient(gradient([color, color.withAlphaComponent(0)]), startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        for _ in 0..<Int(area / 120) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            fill(circle(p, rng.range(0.3, 0.8)), UIColor.white)
        }
        for _ in 0..<Int(area / 5000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let a = rng.range(0, .pi)
            stroke(CourseArt.line(p, CGPoint(x: p.x + cos(a) * 7, y: p.y + sin(a) * 7)), UIColor(hex: 0x6B5240).withAlphaComponent(0.6), 0.8)
        }
    }

    // MARK: Props

    func palm(radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom) {
        let fronds = Int(rng.range(8, 11))
        func frond(_ a: CGFloat, _ len: CGFloat) -> CGPath {
            let p = CGMutablePath()
            let ca = cos(a), sa = sin(a)
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * ca - y * sa, y: x * sa + y * ca) }
            p.move(to: .zero)
            p.addQuadCurve(to: pt(len, -len * 0.05), control: pt(len * 0.5, len * 0.22))
            p.addQuadCurve(to: .zero, control: pt(len * 0.5, -len * 0.18))
            return p
        }
        let angles = (0..<fronds).map { CGFloat($0) / CGFloat(fronds) * .pi * 2 + rng.range(-0.2, 0.2) }
        let lens = angles.map { _ in r * rng.range(0.85, 1.05) }
        shadow(dx: r * 0.3, dy: -r * 0.4, blur: r * 0.15, alpha: 0.35) {
            for (a, l) in zip(angles, lens) { fill(frond(a, l), color.darker(0.2)) }
        }
        for (a, l) in zip(angles, lens) {
            fill(frond(a, l), color)
            let ca = cos(a), sa = sin(a)
            stroke(CourseArt.line(.zero, CGPoint(x: ca * l * 0.95, y: sa * l * 0.95)), color.darker(0.3), 0.8)
        }
        fill(circle(.zero, r * 0.14), UIColor(hex: 0x8A6A3F))
        for k in 0..<3 {
            let a = CGFloat(k) * 2.1
            fill(circle(CGPoint(x: cos(a) * r * 0.12, y: sin(a) * r * 0.12), r * 0.07), UIColor(hex: 0x5C4428))
        }
    }

    func cactus(radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom) {
        shadow(dx: r * 0.35, dy: -r * 0.45, blur: r * 0.15, alpha: 0.35) {
            fill(circle(.zero, r * 0.55), color)
            if r > 12 {
                fill(circle(CGPoint(x: r * 0.55, y: r * 0.1), r * 0.3), color)
                fill(circle(CGPoint(x: -r * 0.5, y: -r * 0.2), r * 0.28), color)
            }
        }
        func body(_ p: CGPoint, _ br: CGFloat) {
            radial(circle(p, br), [color.lighter(0.2), color, color.darker(0.25)], center: CGPoint(x: p.x - br * 0.3, y: p.y + br * 0.3), radius: br * 1.3)
            for k in 0..<8 {
                let a = CGFloat(k) / 8 * .pi * 2
                stroke(CourseArt.line(p, CGPoint(x: p.x + cos(a) * br * 0.95, y: p.y + sin(a) * br * 0.95)), color.darker(0.3).withAlphaComponent(0.6), 0.6)
            }
            for _ in 0..<Int(br * 1.5) {
                let a = rng.range(0, .pi * 2), d = rng.range(br * 0.3, br * 0.95)
                fill(circle(CGPoint(x: p.x + cos(a) * d, y: p.y + sin(a) * d), 0.35), UIColor(hex: 0xF4EFD8))
            }
        }
        if r > 12 {
            body(CGPoint(x: r * 0.55, y: r * 0.1), r * 0.3)
            body(CGPoint(x: -r * 0.5, y: -r * 0.2), r * 0.28)
        }
        body(.zero, r * 0.55)
        if rng.unit() < 0.5 { blossom(CGPoint(x: -r * 0.1, y: r * 0.15), size: r * 0.12, color: UIColor(hex: 0xFF7AA2)) }
    }

    func pine(radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom) {
        func layer(_ rr: CGFloat, _ rot: CGFloat) -> CGPath {
            let path = CGMutablePath()
            let points = 9
            for k in 0..<(points * 2) {
                let a = CGFloat(k) / CGFloat(points * 2) * .pi * 2 + rot
                let d = k % 2 == 0 ? rr : rr * 0.62
                let p = CGPoint(x: cos(a) * d, y: sin(a) * d)
                k == 0 ? path.move(to: p) : path.addLine(to: p)
            }
            path.closeSubpath()
            return path
        }
        shadow(dx: r * 0.3, dy: -r * 0.4, blur: r * 0.2, alpha: 0.35) { fill(layer(r, 0), color.darker(0.2)) }
        let layers: [(CGFloat, CGFloat)] = [(1.0, 0), (0.72, 0.35), (0.45, 0.7)]
        for (k, (scale, rot)) in layers.enumerated() {
            let shape = layer(r * scale, rot)
            fill(shape, k == 0 ? color.darker(0.1) : color.lighter(CGFloat(k) * 0.08))
            clipped(shape) {
                // Snow settles on the lit (upper-left) side.
                fill(circle(CGPoint(x: -r * scale * 0.35, y: r * scale * 0.35), r * scale * 0.55), UIColor.white.withAlphaComponent(0.85))
            }
        }
        fill(circle(.zero, r * 0.1), UIColor.white)
    }
}

// MARK: - Mover sprites

extension CourseArt {
    /// A whole rotor (all blades + hub) pointing along +x at angle 0; the scene spins it.
    static func rotor(blades: Int, length: Double, radius: Double, theme t: Theme, ppu: CGFloat, shadow: Bool) -> UIImage {
        let ext = CGFloat(length) + 4
        let rect = CGRect(x: -ext, y: -ext, width: ext * 2, height: ext * 2)
        return render(rect, ppu: ppu) { p in
            let w = CGFloat(radius)
            for k in 0..<blades {
                p.c.saveGState()
                p.c.rotate(by: CGFloat(k) / CGFloat(blades) * .pi * 2)
                let blade = CGRect(x: 0, y: -w * 1.4, width: CGFloat(length), height: w * 2.8)
                let shape = p.rounded(blade, w)
                if shadow {
                    p.fill(shape, .black)
                } else {
                    p.linear(shape, [t.borderTop.lighter(0.15), t.borderTop, t.borderSide],
                             from: CGPoint(x: 0, y: w * 1.4), to: CGPoint(x: 0, y: -w * 1.4))
                    // Sail lattice.
                    p.clipped(shape) {
                        var x: CGFloat = 10
                        while x < CGFloat(length) {
                            p.stroke(line(CGPoint(x: x, y: -w * 1.4), CGPoint(x: x, y: w * 1.4)), t.borderSide.darker(0.3).withAlphaComponent(0.7), 0.7)
                            x += 9
                        }
                        p.stroke(line(CGPoint(x: 6, y: 0), CGPoint(x: CGFloat(length), y: 0)), t.borderSide.darker(0.4), 1)
                    }
                    p.stroke(shape, t.borderSide.darker(0.45), 0.8)
                }
                p.c.restoreGState()
            }
            let hub = p.circle(.zero, CGFloat(Mover.hubRadius))
            if shadow {
                p.fill(hub, .black)
            } else {
                p.radial(hub, [UIColor(hex: 0xE8E2D6), UIColor(hex: 0x9B9284), UIColor(hex: 0x5E574C)],
                         center: CGPoint(x: -2, y: 2), radius: CGFloat(Mover.hubRadius) * 1.3)
                p.fill(p.circle(.zero, 1.8), UIColor(hex: 0x3A352E))
            }
        }
    }

    /// A carousel disk, flat on the green: striped wedges, a rim of bulbs and a centre cap. The scene spins it.
    static func carousel(radius: Double, theme t: Theme, ppu: CGFloat) -> UIImage {
        let R = CGFloat(radius)
        let ext = R + 3
        return render(CGRect(x: -ext, y: -ext, width: ext * 2, height: ext * 2), ppu: ppu) { p in
            let disk = p.circle(.zero, R)
            p.shadow(dx: 1, dy: -1.5, blur: 2.5, alpha: 0.35) { p.fill(disk, .black) }
            let wedges = 10
            for k in 0..<wedges {
                let a0 = CGFloat(k) / CGFloat(wedges) * .pi * 2, a1 = CGFloat(k + 1) / CGFloat(wedges) * .pi * 2
                let wedge = CGMutablePath()
                wedge.move(to: .zero)
                wedge.addArc(center: .zero, radius: R, startAngle: a0, endAngle: a1, clockwise: false)
                wedge.closeSubpath()
                p.fill(wedge, t.stripes[k % t.stripes.count])
            }
            // Soft shading so it reads as a raised platform.
            p.radial(disk, [UIColor.white.withAlphaComponent(0.18), UIColor.clear, UIColor.black.withAlphaComponent(0.18)],
                     center: CGPoint(x: -R * 0.3, y: R * 0.3), radius: R * 1.3)
            p.stroke(p.circle(.zero, R - 1.5), UIColor(hex: 0xC9A04A), 3)
            for k in 0..<max(12, Int(R / 3.5)) {
                let a = CGFloat(k) / CGFloat(max(12, Int(R / 3.5))) * .pi * 2
                p.fill(p.circle(CGPoint(x: cos(a) * (R - 1.5), y: sin(a) * (R - 1.5)), 1.1), UIColor(hex: 0xFFF2B0))
            }
            let cap = p.circle(.zero, max(5, R * 0.16))
            p.radial(cap, [UIColor(hex: 0xFFE9A0), UIColor(hex: 0xD9A23A), UIColor(hex: 0x9A6A1E)],
                     center: CGPoint(x: -1.5, y: 1.5), radius: max(5, R * 0.16) * 1.3)
            // A pointer on the rim, so the spin is visible even when the stripes blur.
            p.fill(p.circle(CGPoint(x: R - 6, y: 0), 2.2), UIColor.white)
            p.stroke(disk, UIColor.black.withAlphaComponent(0.35), 0.8)
        }
    }

    /// A sliding block in the setting's wall style.
    static func sliderBlock(_ box: Box, radius: Double, theme t: Theme, ppu: CGFloat, shadow: Bool) -> UIImage {
        let r = CGFloat(radius)
        let rect = CGRect(x: -box.width / 2 - r, y: -box.height / 2 - r, width: box.width + 2 * r, height: box.height + 2 * r)
        return render(rect, ppu: ppu) { p in
            let shape = p.rounded(rect, r + 1)
            if shadow { p.fill(shape, .black); return }
            p.linear(shape, [t.borderTop.lighter(0.12), t.borderTop, t.borderSide],
                     from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.maxX, y: rect.minY))
            p.clipped(shape) {
                let horizontal = rect.width >= rect.height
                var s: CGFloat = 0
                let step: CGFloat = t.border == .stone ? 16 : 11
                while s < (horizontal ? rect.width : rect.height) {
                    let a = horizontal ? CGPoint(x: rect.minX + s, y: rect.minY) : CGPoint(x: rect.minX, y: rect.minY + s)
                    let b = horizontal ? CGPoint(x: rect.minX + s, y: rect.maxY) : CGPoint(x: rect.maxX, y: rect.minY + s)
                    p.stroke(line(a, b), t.borderSide.darker(0.35).withAlphaComponent(0.8), 0.8)
                    s += step
                }
                // Hazard chevrons so it reads as "this moves".
                let c = CGPoint(x: rect.midX, y: rect.midY)
                p.chevron(at: CGPoint(x: c.x - 6, y: c.y), angle: horizontal ? 0 : .pi / 2, size: 5, color: UIColor(hex: 0xFFD54F))
                p.chevron(at: CGPoint(x: c.x + 6, y: c.y), angle: horizontal ? .pi : -.pi / 2, size: 5, color: UIColor(hex: 0xFFD54F))
            }
            p.stroke(shape, t.borderSide.darker(0.45), 1)
            if t.snowCaps {
                p.stroke(line(CGPoint(x: rect.minX + 2, y: rect.maxY - 1.5), CGPoint(x: rect.maxX - 2, y: rect.maxY - 1.5)), .white, 2.5)
            }
        }
    }
}
