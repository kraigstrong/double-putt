import UIKit

// Funfair settings (Midway, Big Top, Fireworks): painted boardwalk walls, booth roofs, striped tents, balloons and
// rubber ducks. Colours come from the theme's `borderTop`/`trim` (walls), `booths` (booth roofs), `stripes`
// (carousels), `canopies` (tents) and `flowers` (balloons).

extension CourseArt {
    /// A paper confetti strip for the ambient emitter (tinted per particle).
    static func confetti(pixels: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: pixels, height: pixels), format: format).image { ctx in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: pixels * 0.3, y: pixels * 0.1, width: pixels * 0.4, height: pixels * 0.8),
                         cornerRadius: pixels * 0.08).fill()
        }
    }
}

extension Painter {
    /// A painted boardwalk plank: the wall colour, faint grain, and a trim line along its light edge, so the trim runs
    /// unbroken round a border or a booth's frame.
    func paintedPlank(_ r: CGRect, horizontal: Bool, _ t: Theme, _ rng: inout SeededRandom) {
        let tone = t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.12))
        let path = CGPath(rect: r, transform: nil)
        linear(path, [tone.lighter(0.1), tone, tone.darker(0.1)],
               from: horizontal ? CGPoint(x: r.midX, y: r.maxY) : CGPoint(x: r.minX, y: r.midY),
               to: horizontal ? CGPoint(x: r.midX, y: r.minY) : CGPoint(x: r.maxX, y: r.midY))
        clipped(path) {
            for _ in 0..<3 {
                let g = CGMutablePath()
                if horizontal {
                    let y = rng.range(r.minY, r.maxY)
                    g.move(to: CGPoint(x: r.minX, y: y)); g.addLine(to: CGPoint(x: r.maxX, y: y + rng.range(-1, 1)))
                } else {
                    let x = rng.range(r.minX, r.maxX)
                    g.move(to: CGPoint(x: x, y: r.minY)); g.addLine(to: CGPoint(x: x + rng.range(-1, 1), y: r.maxY))
                }
                stroke(g, t.borderSide.withAlphaComponent(0.18), 0.5)
            }
            let inset: CGFloat = min(3, (horizontal ? r.height : r.width) * 0.25)
            let trim = horizontal ? CourseArt.line(CGPoint(x: r.minX, y: r.maxY - inset), CGPoint(x: r.maxX, y: r.maxY - inset))
                                  : CourseArt.line(CGPoint(x: r.minX + inset, y: r.minY), CGPoint(x: r.minX + inset, y: r.maxY))
            stroke(trim, t.trim.withAlphaComponent(0.9), 1.2)
        }
        let seam = horizontal ? CourseArt.line(CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY))
                              : CourseArt.line(CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY))
        stroke(seam, t.borderSide.darker(0.3), 0.8)
    }

    /// A booth roof filling a block: plain canvas in one of the setting's booth colours (each booth picks its own), with
    /// faint seams, and stripes only on the scalloped valance along its front (lower) edge.
    func awning(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        let path = CourseArt.rounded(r, 2, square: square)
        let canvas = rng.pick(t.booths).mixed(with: UIColor(hex: 0xFFF4E2), 0.12)
        let cream = UIColor(hex: 0xFFF4E2)
        clipped(path) {
            fill(path, canvas)
            // Seams run front to back, like canvas panels.
            var x = r.minX + 18
            while x < r.maxX - 4 {
                stroke(CourseArt.line(CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.maxY)), canvas.darker(0.16), 0.7)
                x += 18
            }
            // Light catches the roof's ridge (back), the valance sits in shade.
            linear(path, [UIColor.white.withAlphaComponent(0.2), UIColor.clear, UIColor.black.withAlphaComponent(0.18)],
                   from: CGPoint(x: r.midX, y: r.maxY), to: CGPoint(x: r.midX, y: r.minY))
            // Valance: a striped band with scallops along the front edge.
            let band: CGFloat = 8
            let depth = min(9, r.height * 0.35)
            var bx = r.minX
            var j = 0
            while bx < r.maxX {
                let color = j % 2 == 0 ? canvas.darker(0.05) : cream
                fill(CGRect(x: bx, y: r.minY, width: band, height: depth), color)
                fill(circle(CGPoint(x: bx + band / 2, y: r.minY + 0.5), band / 2), color.darker(0.06))
                bx += band
                j += 1
            }
            stroke(CourseArt.line(CGPoint(x: r.minX, y: r.minY + depth), CGPoint(x: r.maxX, y: r.minY + depth)),
                   UIColor.black.withAlphaComponent(0.2), 0.8)
        }
        shadow(dx: 0, dy: 0, blur: 3, alpha: 0.45) {
            let ring = CGMutablePath()
            ring.addRect(r.insetBy(dx: -10, dy: -10))
            ring.addPath(path)
            clipped(path) { fill(ring, .black, evenOdd: true) }
        }
    }

    /// A striped circus tent seen from above: alternating wedges, scalloped eaves, a pennant on the king pole.
    func tent(radius r: CGFloat, color: UIColor, _ t: Theme, _ rng: inout SeededRandom) {
        let wedges = 10
        let rot = rng.range(0, .pi * 2)
        shadow(dx: r * 0.12, dy: -r * 0.18, blur: r * 0.2, alpha: 0.4) { fill(circle(.zero, r * 0.95), .black) }
        // Dark canvas alternates with cream; a light (yellow) canvas with the setting's first stripe colour.
        let light = color.isLight ? t.stripes[0] : UIColor(hex: 0xFFF4E2)
        for k in 0..<wedges {
            let a0 = rot + CGFloat(k) / CGFloat(wedges) * .pi * 2, a1 = rot + CGFloat(k + 1) / CGFloat(wedges) * .pi * 2
            let wedge = CGMutablePath()
            wedge.move(to: .zero)
            wedge.addArc(center: .zero, radius: r * 0.92, startAngle: a0, endAngle: a1, clockwise: false)
            wedge.closeSubpath()
            fill(wedge, k % 2 == 0 ? color : light)
            // Eave scallop at the wedge's rim.
            let mid = (a0 + a1) / 2
            fill(circle(CGPoint(x: cos(mid) * r * 0.92, y: sin(mid) * r * 0.92), r * 0.13), k % 2 == 0 ? color.darker(0.1) : light.darker(0.06))
        }
        // The roof rises to the pole: light on the upper-left slopes.
        radial(circle(.zero, r * 0.92), [UIColor.white.withAlphaComponent(0.25), UIColor.clear, UIColor.black.withAlphaComponent(0.22)],
               center: CGPoint(x: -r * 0.25, y: r * 0.25), radius: r * 1.1)
        fill(circle(.zero, r * 0.1), UIColor(hex: 0xFFD54F))
        let flag = CGMutablePath()
        flag.move(to: CGPoint(x: 0, y: r * 0.05))
        flag.addLine(to: CGPoint(x: r * 0.32, y: r * 0.14))
        flag.addLine(to: CGPoint(x: 0, y: r * 0.24))
        flag.closeSubpath()
        fill(flag, color.lighter(0.25))
    }

    /// A small cluster of balloons on strings (the funfair's "bushes").
    func balloons(radius r: CGFloat, _ t: Theme, _ rng: inout SeededRandom) {
        let n = Int(rng.range(3, 5.99))
        let knot = CGPoint(x: r * 0.1, y: -r * 0.85)
        var spots: [CGPoint] = []
        for k in 0..<n {
            let a = CGFloat(k) / CGFloat(n) * .pi * 2 + rng.range(-0.3, 0.3)
            spots.append(CGPoint(x: cos(a) * r * 0.42, y: sin(a) * r * 0.42 + r * 0.15))
        }
        for p in spots { stroke(CourseArt.line(p, knot), UIColor.white.withAlphaComponent(0.6), 0.5) }
        for p in spots {
            let br = r * rng.range(0.34, 0.42)
            let c = rng.pick(t.flowers)
            shadow(dx: br * 0.2, dy: -br * 0.35, blur: br * 0.4, alpha: 0.35) { fill(circle(p, br), c) }
            radial(circle(p, br), [c.lighter(0.35), c, c.darker(0.2)], center: CGPoint(x: p.x - br * 0.35, y: p.y + br * 0.35), radius: br * 1.3)
            fill(circle(CGPoint(x: p.x - br * 0.35, y: p.y + br * 0.35), br * 0.22), UIColor.white.withAlphaComponent(0.55))
        }
    }

    /// A bumper drawn as a big glossy balloon with its knot.
    func balloonPost(_ c: CGPoint, radius r: CGFloat, color: UIColor) {
        radial(circle(c, r), [color.lighter(0.4), color, color.darker(0.25)], center: CGPoint(x: c.x - r * 0.35, y: c.y + r * 0.35), radius: r * 1.35)
        let knot = CGMutablePath()
        knot.move(to: CGPoint(x: c.x + r * 0.62, y: c.y - r * 0.62))
        knot.addLine(to: CGPoint(x: c.x + r * 0.95, y: c.y - r * 0.8))
        knot.addLine(to: CGPoint(x: c.x + r * 0.8, y: c.y - r * 0.95))
        knot.closeSubpath()
        fill(knot, color.darker(0.2))
        fill(CGPath(ellipseIn: CGRect(x: c.x - r * 0.6, y: c.y + r * 0.15, width: r * 0.42, height: r * 0.3), transform: nil),
             UIColor.white.withAlphaComponent(0.6))
    }

    /// A rubber duck bobbing on a pond, facing `facing` (+1 right, -1 left).
    func duck(at p: CGPoint, facing: CGFloat) {
        let body = CGPath(ellipseIn: CGRect(x: p.x - 6, y: p.y - 4, width: 12, height: 8), transform: nil)
        shadow(dx: 0.8, dy: -1.2, blur: 1.5, alpha: 0.35) { fill(body, UIColor(hex: 0xF2B705)) }
        radial(body, [UIColor(hex: 0xFFE680), UIColor(hex: 0xFFCC1A)], center: CGPoint(x: p.x - 2, y: p.y + 2), radius: 8)
        let head = CGPoint(x: p.x + facing * 4, y: p.y + 2.5)
        fill(circle(head, 3.2), UIColor(hex: 0xFFD83A))
        fill(CGPath(ellipseIn: CGRect(x: head.x + facing * 2.2 - 1.6, y: head.y - 1, width: 3.2, height: 1.8), transform: nil),
             UIColor(hex: 0xFF8A2A))
        fill(circle(CGPoint(x: head.x + facing * 1, y: head.y + 1), 0.55), UIColor(hex: 0x222222))
    }
}

extension UIColor {
    /// Bright enough to read as the light stripe of a pair.
    var isLight: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b > 0.6
    }
}
