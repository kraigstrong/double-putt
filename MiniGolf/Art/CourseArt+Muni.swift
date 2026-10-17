import UIKit

extension Painter {
    // MARK: City Muni (course 8)

    /// One panel of the border: a concrete kerb (the wall you bank off) under a galvanized chain-link mesh, with a
    /// round post at the panel's end.
    func chainLinkPanel(_ r: CGRect, horizontal: Bool, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CGPath(rect: r, transform: nil)
        let tone = t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.12))
        linear(path, [tone.lighter(0.08), tone, tone.darker(0.06)],
               from: horizontal ? CGPoint(x: r.midX, y: r.maxY) : CGPoint(x: r.minX, y: r.midY),
               to: horizontal ? CGPoint(x: r.midX, y: r.minY) : CGPoint(x: r.maxX, y: r.midY))
        clipped(path) {
            for _ in 0..<Int(r.width * r.height / 5) {
                let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                fill(circle(p, 0.4), (rng.unit() < 0.5 ? UIColor.white : t.borderSide.darker(0.2)).withAlphaComponent(0.35))
            }
            // The mesh: diamonds from two sets of diagonals.
            let mesh = CGMutablePath()
            let span = r.width + r.height
            var s = -span
            while s < span {
                mesh.move(to: CGPoint(x: r.minX + s, y: r.minY)); mesh.addLine(to: CGPoint(x: r.minX + s + span, y: r.minY + span))
                mesh.move(to: CGPoint(x: r.minX + s, y: r.maxY)); mesh.addLine(to: CGPoint(x: r.minX + s + span, y: r.maxY - span))
                s += 3.4
            }
            stroke(mesh, UIColor(hex: 0x5F666D).withAlphaComponent(0.5), 0.55)
        }
        let seam = horizontal ? CourseArt.line(CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY))
                              : CourseArt.line(CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY))
        stroke(seam, t.borderSide.darker(0.3), 0.8)
        let post = horizontal ? CGPoint(x: r.maxX, y: r.midY) : CGPoint(x: r.midX, y: r.maxY)
        radial(circle(post, 2.6), [UIColor(hex: 0xD9DDE0), UIColor(hex: 0x9AA1A7)], center: CGPoint(x: post.x - 0.8, y: post.y + 0.8), radius: 3)
        stroke(circle(post, 2.6), UIColor(hex: 0x50565C), 0.7)
    }

    /// Worn ground round a busy public course: bare dirt where people cut across, and clumps of clover.
    func wornPatches(_ t: Theme, _ rect: CGRect, _ rng: inout SeededRandom) {
        let area = rect.width * rect.height
        let dirt = UIColor(hex: 0xA88B5E)
        for _ in 0..<Int(area / 22000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(14, 34)
            c.drawRadialGradient(gradient([dirt.withAlphaComponent(0.55), dirt.withAlphaComponent(0)]),
                                 startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        for _ in 0..<Int(area / 5000) {
            let center = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            for _ in 0..<Int(rng.range(4, 9)) {
                let p = CGPoint(x: center.x + rng.range(-7, 7), y: center.y + rng.range(-7, 7))
                fill(circle(p, rng.range(1.2, 1.8)), t.roughLight.lighter(0.1).withAlphaComponent(0.7))
            }
        }
    }

    /// The water tower, from above: a round tank with a pointed roof, a catwalk round it and four legs.
    func waterTower(radius r: CGFloat) {
        shadow(dx: r * 0.35, dy: -r * 0.5, blur: r * 0.25, alpha: 0.4) {
            for k in 0..<4 {
                let a = CGFloat(k) * .pi / 2 + .pi / 4
                stroke(CourseArt.line(.zero, CGPoint(x: cos(a) * r * 1.25, y: sin(a) * r * 1.25)), UIColor(hex: 0x6F767C), r * 0.08)
            }
            fill(circle(.zero, r * 1.06), UIColor(hex: 0x7C8389))
        }
        radial(circle(.zero, r), [UIColor(hex: 0xE4ECF2), UIColor(hex: 0xB8C6D1), UIColor(hex: 0x8C9DAB)],
               center: CGPoint(x: -r * 0.3, y: r * 0.3), radius: r * 1.3)
        // Roof panels meeting at the point.
        for k in 0..<12 {
            let a = CGFloat(k) * .pi / 6
            stroke(CourseArt.line(.zero, CGPoint(x: cos(a) * r, y: sin(a) * r)), UIColor(hex: 0x7F91A0).withAlphaComponent(0.6), 0.7)
        }
        stroke(circle(.zero, r * 0.94), UIColor(hex: 0x5E6E7B), r * 0.06)
        fill(circle(.zero, r * 0.12), UIColor(hex: 0x6C7C89))
        stroke(circle(.zero, r), UIColor(hex: 0x46525C), 1)
    }
}

extension CourseArt {
    static func waterTower(radius r: CGFloat, ppu: CGFloat) -> Prop {
        let half = r * 1.6
        let rect = CGRect(x: -half, y: -half, width: half * 2, height: half * 2)
        let img = render(rect, ppu: ppu) { p in p.waterTower(radius: r) }
        return Prop(image: img, size: rect.size)
    }
}
