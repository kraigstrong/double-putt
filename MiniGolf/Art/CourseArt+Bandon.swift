import UIKit

// Bandon, a cream long-haired dachshund, naps beside a few of The Links' holes (Level.bandon), just outside the play
// area. Drawn from above in two pieces so his tail can wag.

extension Painter {
    /// Bandon, lying with his chin on his paws, seen from above: head toward +y, the base of his tail at y = -16.
    /// The tail is drawn separately (dachshundTail) so it can wag.
    func dachshund() {
        let cream = UIColor(hex: 0xF3E4C8), shade = UIColor(hex: 0xDEC59C), feather = UIColor(hex: 0xCDAB7C)
        let nose = UIColor(hex: 0x2E2522)
        func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGPath {
            CGPath(ellipseIn: CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h), transform: nil)
        }
        let body = CGPath(roundedRect: CGRect(x: -6.5, y: -17, width: 13, height: 31), cornerWidth: 6.5, cornerHeight: 6.5, transform: nil)
        shadow(dx: 1.6, dy: -2.2, blur: 2.5, alpha: 0.35) {
            fill(body, cream)
            fill(oval(0, 19, 11, 10), cream)
        }
        // Hind legs tucked alongside, front paws reaching forward under the chin.
        for s: CGFloat in [-1, 1] {
            fill(oval(s * 6.8, -11, 4.5, 8), shade)
            fill(oval(s * 3.2, 24.5, 3.6, 6), cream)
            stroke(CourseArt.line(CGPoint(x: s * 3.2 - 0.8, y: 27), CGPoint(x: s * 3.2 - 0.8, y: 25.6)), shade.darker(0.15), 0.4)
            stroke(CourseArt.line(CGPoint(x: s * 3.2 + 0.8, y: 27), CGPoint(x: s * 3.2 + 0.8, y: 25.6)), shade.darker(0.15), 0.4)
        }
        // Body: lit along the back, long hair feathering at the flanks.
        radial(body, [cream.lighter(0.08), cream, shade], locations: [0, 0.55, 1], center: CGPoint(x: -1.5, y: 2), radius: 17)
        for k in 0..<9 {
            let y = -14 + CGFloat(k) * 3.4
            for s: CGFloat in [-1, 1] {
                let wisp = CGMutablePath()
                wisp.move(to: CGPoint(x: s * 5.4, y: y))
                wisp.addQuadCurve(to: CGPoint(x: s * 7.4, y: y - 2.6), control: CGPoint(x: s * 7.2, y: y - 0.4))
                stroke(wisp, feather.withAlphaComponent(0.8), 0.7)
            }
        }
        stroke(CourseArt.line(CGPoint(x: 0, y: -13), CGPoint(x: 0, y: 11)), cream.lighter(0.15).withAlphaComponent(0.7), 1.2)
        // Head and long muzzle.
        let head = oval(0, 18.5, 10.5, 9.5)
        radial(head, [cream.lighter(0.08), cream, shade], locations: [0, 0.6, 1], center: CGPoint(x: -1, y: 20), radius: 7)
        let muzzle = CGMutablePath()
        muzzle.move(to: CGPoint(x: -3, y: 21))
        muzzle.addQuadCurve(to: CGPoint(x: 0, y: 29), control: CGPoint(x: -3.2, y: 27.5))
        muzzle.addQuadCurve(to: CGPoint(x: 3, y: 21), control: CGPoint(x: 3.2, y: 27.5))
        muzzle.closeSubpath()
        fill(muzzle, cream)
        fill(oval(0, 28.4, 2.4, 1.8), nose)
        // Eyes closed: he's napping.
        for s: CGFloat in [-1, 1] {
            let lid = CGMutablePath()
            lid.move(to: CGPoint(x: s * 1.4, y: 21.2))
            lid.addQuadCurve(to: CGPoint(x: s * 3.4, y: 21.2), control: CGPoint(x: s * 2.4, y: 20.4))
            stroke(lid, nose.withAlphaComponent(0.8), 0.5)
        }
        // Long feathered ears hanging either side of the head.
        for s: CGFloat in [-1, 1] {
            c.saveGState()
            c.translateBy(x: s * 5.6, y: 17)
            c.rotate(by: s * 0.25)
            let ear = oval(0, -2.5, 5.2, 11)
            fill(ear, feather)
            clipped(ear) {
                for k in 0..<4 {
                    stroke(CourseArt.line(CGPoint(x: -1.6 + CGFloat(k), y: 2), CGPoint(x: -2 + CGFloat(k) * 1.2, y: -8)),
                           shade.withAlphaComponent(0.7), 0.5)
                }
            }
            c.restoreGState()
        }
    }

    /// Bandon's tail: a long feathered plume hanging from its base at (0, 0), toward -y.
    func dachshundTail() {
        let cream = UIColor(hex: 0xF3E4C8), feather = UIColor(hex: 0xCDAB7C)
        let plume = CGMutablePath()
        plume.move(to: CGPoint(x: -1.6, y: 0))
        plume.addQuadCurve(to: CGPoint(x: 0, y: -14), control: CGPoint(x: -4.6, y: -8))
        plume.addQuadCurve(to: CGPoint(x: 1.6, y: 0), control: CGPoint(x: 4.6, y: -8))
        plume.closeSubpath()
        fill(plume, feather)
        fill(CGPath(ellipseIn: CGRect(x: -1.4, y: -9, width: 2.8, height: 9), transform: nil), cream)
        for k in 0..<4 {
            let y = -2 - CGFloat(k) * 3
            stroke(CourseArt.line(CGPoint(x: -2.6, y: y), CGPoint(x: -3.6, y: y - 2)), feather.darker(0.1), 0.5)
            stroke(CourseArt.line(CGPoint(x: 2.6, y: y), CGPoint(x: 3.6, y: y - 2)), feather.darker(0.1), 0.5)
        }
    }
}

extension CourseArt {
    /// Bandon and his tail, as props (world units).
    static func bandon(ppu: CGFloat) -> (body: Prop, tail: Prop) {
        let bodyRect = CGRect(x: -12, y: -20, width: 24, height: 52)
        let tailRect = CGRect(x: -5, y: -16, width: 10, height: 17)
        let body = render(bodyRect, ppu: ppu) { p in p.dachshund() }
        let tail = render(tailRect, ppu: ppu) { p in p.dachshundTail() }
        return (Prop(image: body, size: bodyRect.size), Prop(image: tail, size: tailRect.size))
    }
}
