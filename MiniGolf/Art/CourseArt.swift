import UIKit

/// Procedural artwork. Everything is drawn with Core Graphics into textures in world units
/// (course space, y up) at a given pixels-per-unit, so it stays crisp on any screen.
enum CourseArt {
    /// World units drawn around the 400 x 800 course (border + drop shadow).
    static let pad: CGFloat = 34
    /// The outer border extends this far outside the course edge.
    static let borderOut: CGFloat = 14
    static var courseRect: CGRect { CGRect(x: -pad, y: -pad, width: Course.width + 2 * pad, height: Course.height + 2 * pad) }

    // MARK: - Entry points

    static func course(_ level: Level, theme: Theme, ppu: CGFloat) -> UIImage {
        render(courseRect, ppu: ppu) { p in
            var rng = SeededRandom(seed: stableSeed(level.name))
            p.courseShadow()
            p.felt(theme)
            // Paint can run past the frame (a pond drawn out to the edge); only what's inside the rails shows.
            p.clipped(CGPath(rect: p.feltRect, transform: nil)) { p.surfaces(level, theme, &rng) }
            p.slopeGrid(level, theme)
            p.water(level, theme, &rng)
            p.tees(level, theme)
            p.cups(level, theme)
            p.tunnels(level, theme)
            p.kickers(level, theme)
            p.shadow(dx: 2.6, dy: -3.6, blur: 4.5, alpha: 0.4) {
                p.borderShape(fill: .black)
                p.railShapes(level, fill: .black)
                p.blockShapes(level, fill: .black)
                p.standShapes(level, fill: .black)
            }
            p.border(theme, &rng)
            p.rails(level, theme, &rng)
            p.blocks(level, theme, &rng)
            p.stands(level, &rng)
            if theme.snowCaps { p.snowCaps(level, theme) }
            p.posts(level, theme)
        }
    }

    static func ground(_ theme: Theme, rect: CGRect, ppu: CGFloat, seed: UInt64) -> UIImage {
        render(rect, ppu: ppu) { p in p.ground(theme, rect, seed) }
    }

    /// A course thumbnail with a bit of surrounding ground, for menus.
    static func thumbnail(_ level: Level, width: CGFloat, scale: CGFloat) -> UIImage {
        let theme = Theme.for(level)
        let rect = courseRect.insetBy(dx: -20, dy: -20)
        let ppu = width * scale / rect.width
        return render(rect, ppu: ppu) { p in
            p.ground(theme, rect, 3)
            p.image(course(level, theme: theme, ppu: ppu).cgImage!, in: courseRect)
        }
    }

    struct Prop {
        let image: UIImage
        let size: CGSize   // world units
    }

    static func tree(_ theme: Theme, radius r: CGFloat, seed: UInt64, ppu: CGFloat) -> Prop {
        let half = r * 1.55
        let rect = CGRect(x: -half, y: -half, width: half * 2, height: half * 2)
        var rng = SeededRandom(seed: seed)
        let color = rng.pick(theme.canopies)
        let img = render(rect, ppu: ppu) { p in p.tree(theme, radius: r, color: color, &rng) }
        return Prop(image: img, size: rect.size)
    }

    static func bush(_ theme: Theme, radius r: CGFloat, seed: UInt64, ppu: CGFloat) -> Prop {
        let half = r * 1.6
        let rect = CGRect(x: -half, y: -half, width: half * 2, height: half * 2)
        var rng = SeededRandom(seed: seed)
        let color = rng.pick(theme.canopies).mixed(with: theme.rough, 0.25)
        let flowers = rng.unit() < 0.6 ? theme.flowers : nil
        let img = render(rect, ppu: ppu) { p in
            switch theme.trees {
            case .cactus: p.cactus(radius: r * 0.9, color: rng.pick(theme.canopies), &rng)
            case .pine: p.pine(radius: r, color: rng.pick(theme.canopies), &rng)
            case .round, .palm: p.canopy(radius: r, color: color, &rng, flowers: flowers)
            case .tents: p.balloons(radius: r, theme, &rng)
            case .gorse: p.gorse(radius: r * 0.8, color: rng.pick(theme.canopies), theme, &rng)
            case .crates: p.console(radius: r * 0.8, theme, &rng)
            }
        }
        return Prop(image: img, size: rect.size)
    }

    static func rock(radius r: CGFloat, seed: UInt64, ppu: CGFloat, tone: UIColor? = nil) -> Prop {
        let half = r * 1.6
        let rect = CGRect(x: -half, y: -half, width: half * 2, height: half * 2)
        var rng = SeededRandom(seed: seed)
        let img = render(rect, ppu: ppu) { p in
            if let tone { p.rockShape(radius: r, tone: tone, &rng) } else { p.rock(radius: r, &rng) }
        }
        return Prop(image: img, size: rect.size)
    }

    /// A ball is three layers so only the stripe turns: base (fixed), stripe (rotated to the
    /// ball's line, like a golfer's alignment line), gloss with dimples and lighting (fixed).
    /// The ball's fixed layers; its stripe, spots and dimples roll (GameScene's ball paint shader).
    enum BallLayer { case base, gloss }

    static func ball(_ layer: BallLayer, pixels: CGFloat) -> UIImage {
        let r = Tuning.ballRadius
        let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
        return render(rect, ppu: pixels / (r * 2)) { p in
            switch layer {
            case .base: p.ballBase(radius: r)
            case .gloss: p.ballGloss(radius: r)
            }
        }
    }

    static func softDot(pixels: CGFloat, color: UIColor = .white, hardness: CGFloat = 0.2) -> UIImage {
        let rect = CGRect(x: -1, y: -1, width: 2, height: 2)
        return render(rect, ppu: pixels / 2) { p in
            p.radial(CGPath(ellipseIn: rect, transform: nil), [color, color, color.withAlphaComponent(0)],
                     locations: [0, hardness, 1], center: .zero, radius: 1)
        }
    }

    static func leaf(color: UIColor, pixels: CGFloat) -> UIImage {
        let rect = CGRect(x: -1, y: -0.6, width: 2, height: 1.2)
        return render(rect, ppu: pixels / 2) { p in
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -1, y: 0))
            path.addQuadCurve(to: CGPoint(x: 1, y: 0), control: CGPoint(x: 0, y: 0.9))
            path.addQuadCurve(to: CGPoint(x: -1, y: 0), control: CGPoint(x: 0, y: -0.9))
            p.fill(path, color)
            p.stroke(line(CGPoint(x: -0.9, y: 0), CGPoint(x: 0.9, y: 0)), color.darker(0.3), 0.08)
        }
    }

    static func putter(pixels: CGFloat) -> UIImage {
        // Head 18 x 6 world units plus a stub of shaft, pointing +x (toward the ball).
        let rect = CGRect(x: -16, y: -10, width: 22, height: 20)
        return render(rect, ppu: pixels / 22) { p in
            p.shadow(dx: 1.5, dy: -2, blur: 2, alpha: 0.35) {
                p.stroke(line(CGPoint(x: -14, y: 6), CGPoint(x: -1, y: 1)), UIColor(hex: 0x2B2B2B), 1.6)
                let head = CGPath(roundedRect: CGRect(x: -3, y: -9, width: 7, height: 18), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
                p.linear(head, [UIColor(hex: 0xF4F6F8), UIColor(hex: 0xA9B0B8), UIColor(hex: 0x6E757D)],
                         from: CGPoint(x: -3, y: 9), to: CGPoint(x: 4, y: -9))
                p.stroke(head, UIColor(hex: 0x4A5058), 0.5)
            }
            p.fill(CGPath(rect: CGRect(x: 2.6, y: -7, width: 0.9, height: 14), transform: nil), UIColor.white.withAlphaComponent(0.5))
        }
    }

    // MARK: - Rendering

    static func render(_ worldRect: CGRect, ppu: CGFloat, _ draw: (Painter) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let size = CGSize(width: max(1, ceil(worldRect.width * ppu)), height: max(1, ceil(worldRect.height * ppu)))
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: 0, y: size.height)
            c.scaleBy(x: size.width / worldRect.width, y: -size.height / worldRect.height)
            c.translateBy(x: -worldRect.minX, y: -worldRect.minY)
            c.setLineCap(.round)
            c.setLineJoin(.round)
            draw(Painter(c: c, ppu: ppu))
        }
    }

    static let noise: CGImage = {
        let n = 128
        var rng = SeededRandom(seed: 99)
        var data = [UInt8](repeating: 0, count: n * n * 4)
        for i in 0..<(n * n) {
            let a = Int(rng.next() % 110)
            let v = rng.next() % 2 == 0 ? 0 : a
            data[i * 4] = UInt8(v); data[i * 4 + 1] = UInt8(v); data[i * 4 + 2] = UInt8(v); data[i * 4 + 3] = UInt8(a)
        }
        let provider = CGDataProvider(data: Data(data) as CFData)!
        return CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }()

    static func stableSeed(_ s: String) -> UInt64 {
        s.unicodeScalars.reduce(1469598103934665603) { ($0 ^ UInt64($1.value)) &* 1099511628211 }
    }

    static func line(_ a: CGPoint, _ b: CGPoint) -> CGPath {
        let p = CGMutablePath()
        p.move(to: a)
        p.addLine(to: b)
        return p
    }

    /// Outer fence rails sit exactly on the course edge; they're drawn as the border band instead.
    static func isFrameRail(_ w: Wall) -> Bool {
        let onX = { (x: Double) in w.a.x == x && w.b.x == x }
        let onY = { (y: Double) in w.a.y == y && w.b.y == y }
        return onX(0) || onX(Course.width) || onY(0) || onY(Course.height)
    }

    /// Sides of a box (as corner pairs, e.g. `.left`) that sit on a straight wall, outer fence included,
    /// running the side's full length. Corners there are drawn square so the shape runs cleanly under the
    /// wall instead of curling away from it.
    static func walledSides(_ b: Box, _ level: Level) -> [Corners] {
        var sides: [Corners] = []
        for w in level.rails {
            if w.a.x == w.b.x, min(w.a.y, w.b.y) <= b.minY, max(w.a.y, w.b.y) >= b.maxY {
                if w.a.x == b.minX { sides.append(.left) }
                if w.a.x == b.maxX { sides.append(.right) }
            } else if w.a.y == w.b.y, min(w.a.x, w.b.x) <= b.minX, max(w.a.x, w.b.x) >= b.maxX {
                if w.a.y == b.minY { sides.append(.bottom) }
                if w.a.y == b.maxY { sides.append(.top) }
            }
        }
        return sides
    }

    /// A rect rounded by `r` except at the `square` corners.
    static func rounded(_ rect: CGRect, _ r: CGFloat, square: Corners) -> CGPath {
        let r = max(min(r, rect.width / 2 - 0.01, rect.height / 2 - 0.01), 0)
        let path = CGMutablePath()
        let pts = Corners.points(of: rect)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        for k in 1...4 {
            let (corner, p) = pts[k % 4]
            path.addArc(tangent1End: p, tangent2End: pts[(k + 1) % 4].1, radius: square.contains(corner) ? 0 : r)
        }
        path.closeSubpath()
        return path
    }

    /// A body of water: touching water boxes merge into one pond, so there are no seams between them.
    struct Pond {
        var parts: [CGRect]
        var path: CGPath
        var bounds: CGRect { path.boundingBoxOfPath }
    }

    static func ponds(_ level: Level) -> [Pond] {
        let boxes = level.water
        let rects = boxes.map { CGRect(x: $0.minX, y: $0.minY, width: $0.width, height: $0.height) }
        // Boxes join when they overlap or share a stretch of edge that isn't a wall.
        func joined(_ i: Int, _ j: Int) -> Bool {
            let a = rects[i], b = rects[j], walls = walledSides(boxes[i], level)
            let ySpan = min(a.maxY, b.maxY) - max(a.minY, b.minY), xSpan = min(a.maxX, b.maxX) - max(a.minX, b.minX)
            if ySpan > 0, a.maxX == b.minX { return !walls.contains(.right) }
            if ySpan > 0, a.minX == b.maxX { return !walls.contains(.left) }
            if xSpan > 0, a.maxY == b.minY { return !walls.contains(.top) }
            if xSpan > 0, a.minY == b.maxY { return !walls.contains(.bottom) }
            return xSpan > 0 && ySpan > 0
        }
        var group = Array(rects.indices)
        func root(_ i: Int) -> Int { group[i] == i ? i : root(group[i]) }
        for i in rects.indices { for j in rects.indices where j > i && joined(i, j) { group[root(j)] = root(i) } }

        return rects.indices.filter { root($0) == $0 }.map { r in
            let members = rects.indices.filter { root($0) == r }
            var path: CGPath?
            for i in members {
                // Square where the pond meets a wall or runs on into another box; rounded where it meets turf.
                var square = Corners(walledSides(boxes[i], level))
                for (corner, p) in Corners.points(of: rects[i])
                where members.contains(where: { $0 != i && rects[$0].insetBy(dx: -0.01, dy: -0.01).contains(p) }) {
                    square.insert(corner)
                }
                let part = rounded(rects[i], 12, square: square)
                path = path?.union(part) ?? part
            }
            return Pond(parts: members.map { rects[$0] }, path: path!)
        }
    }
}

/// Rect corners, for shapes rounded only where they stand free.
struct Corners: OptionSet {
    let rawValue: Int
    static let bottomLeft = Corners(rawValue: 1), bottomRight = Corners(rawValue: 2)
    static let topRight = Corners(rawValue: 4), topLeft = Corners(rawValue: 8)
    static let left: Corners = [.bottomLeft, .topLeft], right: Corners = [.bottomRight, .topRight]
    static let bottom: Corners = [.bottomLeft, .bottomRight], top: Corners = [.topLeft, .topRight]

    static func points(of r: CGRect) -> [(Corners, CGPoint)] {
        [(.bottomLeft, CGPoint(x: r.minX, y: r.minY)), (.bottomRight, CGPoint(x: r.maxX, y: r.minY)),
         (.topRight, CGPoint(x: r.maxX, y: r.maxY)), (.topLeft, CGPoint(x: r.minX, y: r.maxY))]
    }
}

// MARK: - Painter

struct Painter {
    let c: CGContext
    let ppu: CGFloat

    func shadow(dx: CGFloat, dy: CGFloat, blur: CGFloat, alpha: CGFloat, _ body: () -> Void) {
        c.saveGState()
        // Shadow offsets are in base (pixel) space, where +height is down on iOS.
        c.setShadow(offset: CGSize(width: dx * ppu, height: -dy * ppu), blur: blur * ppu,
                    color: UIColor.black.withAlphaComponent(alpha).cgColor)
        c.beginTransparencyLayer(auxiliaryInfo: nil)
        body()
        c.endTransparencyLayer()
        c.restoreGState()
    }

    func clipped(_ path: CGPath, evenOdd: Bool = false, _ body: () -> Void) {
        c.saveGState()
        c.addPath(path)
        c.clip(using: evenOdd ? .evenOdd : .winding)
        body()
        c.restoreGState()
    }

    func fill(_ path: CGPath, _ color: UIColor, evenOdd: Bool = false) {
        c.addPath(path)
        c.setFillColor(color.cgColor)
        c.fillPath(using: evenOdd ? .evenOdd : .winding)
    }

    func fill(_ rect: CGRect, _ color: UIColor) {
        c.setFillColor(color.cgColor)
        c.fill(rect)
    }

    func stroke(_ path: CGPath, _ color: UIColor, _ width: CGFloat) {
        c.addPath(path)
        c.setStrokeColor(color.cgColor)
        c.setLineWidth(width)
        c.strokePath()
    }

    func gradient(_ colors: [UIColor], _ locations: [CGFloat]? = nil) -> CGGradient {
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray,
                   locations: locations ?? colors.indices.map { CGFloat($0) / CGFloat(max(colors.count - 1, 1)) })!
    }

    func linear(_ path: CGPath, _ colors: [UIColor], locations: [CGFloat]? = nil, from: CGPoint, to: CGPoint) {
        clipped(path) { c.drawLinearGradient(gradient(colors, locations), start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]) }
    }

    func radial(_ path: CGPath, _ colors: [UIColor], locations: [CGFloat]? = nil, center: CGPoint, radius: CGFloat) {
        clipped(path) { c.drawRadialGradient(gradient(colors, locations), startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation]) }
    }

    /// Draw a bitmap. Our space is y-up like native Quartz, so CGImages land upright as-is.
    func image(_ img: CGImage, in rect: CGRect) {
        c.draw(img, in: rect)
    }

    func noise(alpha: CGFloat) {
        c.saveGState()
        c.setAlpha(alpha)
        c.draw(CourseArt.noise, in: CGRect(x: 0, y: 0, width: 128 / ppu, height: 128 / ppu), byTiling: true)
        c.restoreGState()
    }

    func circle(_ center: CGPoint, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2), transform: nil)
    }

    func rounded(_ rect: CGRect, _ r: CGFloat) -> CGPath {
        let r = min(r, rect.width / 2 - 0.01, rect.height / 2 - 0.01)
        return CGPath(roundedRect: rect, cornerWidth: max(r, 0), cornerHeight: max(r, 0), transform: nil)
    }

    // MARK: Course pieces

    private var outerRect: CGRect {
        let o = CourseArt.borderOut
        return CGRect(x: -o, y: -o, width: Course.width + 2 * o, height: Course.height + 2 * o)
    }

    fileprivate var feltRect: CGRect {
        let r = Course.railRadius
        return CGRect(x: r, y: r, width: Course.width - 2 * r, height: Course.height - 2 * r)
    }

    func courseShadow() {
        shadow(dx: 5, dy: -9, blur: 16, alpha: 0.5) { fill(rounded(outerRect, 12), .black) }
    }

    func felt(_ t: Theme) {
        let rect = CGRect(x: 0, y: 0, width: Course.width, height: Course.height)
        clipped(CGPath(rect: rect, transform: nil)) {
            fill(rect, t.feltDark)
            for y in stride(from: 0.0, to: Course.height, by: 100) {
                fill(CGRect(x: 0, y: y, width: Course.width, height: 50), t.feltLight)
            }
            // Soft cross-mow and sheen for depth.
            for x in stride(from: 0.0, to: Course.width, by: 100) {
                fill(CGRect(x: x, y: 0, width: 50, height: Course.height), UIColor.white.withAlphaComponent(0.025))
            }
            c.drawLinearGradient(gradient([UIColor.white.withAlphaComponent(0.10), UIColor.white.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.10)]),
                                 start: CGPoint(x: 0, y: Course.height), end: CGPoint(x: Course.width, y: 0), options: [])
            noise(alpha: 0.10)
        }
    }

    func tees(_ level: Level, _ t: Theme) {
        for (i, tee) in level.tees.enumerated() {
            let box = CGRect(x: tee.x - 20, y: tee.y - 13, width: 40, height: 26)
            fill(rounded(box, 6), t.feltLight.lighter(0.12))
            stroke(rounded(box, 6), UIColor.white.withAlphaComponent(0.35), 0.8)
            for dx in [-14.0, 14.0] {
                let m = CGPoint(x: tee.x + dx, y: tee.y)
                shadow(dx: 0.8, dy: -1, blur: 1, alpha: 0.4) { fill(circle(m, 2.6), Palette.hole(i)) }
                fill(circle(CGPoint(x: m.x - 0.8, y: m.y + 0.8), 0.9), UIColor.white.withAlphaComponent(0.7))
            }
        }
    }

    func cups(_ level: Level, _ t: Theme) {
        for cup in level.cups {
            let p = CGPoint(x: cup.x, y: cup.y)
            let r = Tuning.cupRadius
            fill(circle(p, r + 7), t.feltLight.lighter(0.08).withAlphaComponent(0.55))
            let hole = circle(p, r)
            radial(hole, [UIColor(hex: 0x050505), UIColor(hex: 0x1A1A1A), UIColor(hex: 0x3A3A3A)], center: p, radius: r)
            // Lit white liner on the far (lower-right) wall, deep shadow on the near wall.
            clipped(hole) {
                stroke(circle(CGPoint(x: p.x + 0.6, y: p.y - 0.6), r - 1.2), UIColor.white.withAlphaComponent(0.85), 1.8)
                shadow(dx: 2, dy: -2.5, blur: 3, alpha: 0.95) {
                    let ring = CGMutablePath()
                    ring.addPath(circle(p, r + 8))
                    ring.addPath(hole)
                    fill(ring, .black, evenOdd: true)
                }
            }
            stroke(hole, UIColor.black.withAlphaComponent(0.5), 0.8)
        }
    }

    func water(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        for water in CourseArt.ponds(level) { pond(water, t, &rng) }
    }

    /// One pond in the setting's water style (painted ponds call this too).
    func pond(_ water: CourseArt.Pond, _ t: Theme, _ rng: inout SeededRandom) {
        switch t.water {
        case .tidepool: tidepool(water, t, &rng); return
        case .ice: ice(water, t, &rng); return
        case .bulkhead: bulkheadPond(water, t, &rng); return
        case .void: voidPond(water, t, &rng); return
        case .pond: break
        }
        let pond = water.path, bounds = water.bounds
        // Sandy bank: a band hugging the water's edge (the inner half is covered by the water).
        stroke(pond, UIColor(hex: 0xE3D3A6).withAlphaComponent(0.9), 5)
        radial(pond, [t.waterDeep, t.waterDeep.mixed(with: t.waterShallow, 0.5), t.waterShallow],
               locations: [0, 0.55, 1], center: CGPoint(x: bounds.midX, y: bounds.midY), radius: max(bounds.width, bounds.height) * 0.62)
        clipped(pond) {
            // Bank shadow on the near edges.
            shadow(dx: 3, dy: -4, blur: 6, alpha: 0.55) {
                let ring = CGMutablePath()
                ring.addRect(bounds.insetBy(dx: -30, dy: -30))
                ring.addPath(pond)
                fill(ring, .black, evenOdd: true)
            }
            for rect in water.parts {
                if t.ducks {
                    let count = min(3, max(1, Int(rect.width * rect.height / 9000)))
                    for _ in 0..<count {
                        duck(at: CGPoint(x: rng.range(rect.minX + 8, max(rect.minX + 8, rect.maxX - 8)),
                                         y: rng.range(rect.minY + 6, max(rect.minY + 6, rect.maxY - 6))),
                             facing: rng.unit() < 0.5 ? -1 : 1)
                    }
                } else {
                    lilies(rect, &rng)
                }
            }
        }
        stroke(pond, UIColor.white.withAlphaComponent(0.45), 1.2)
        for rect in water.parts { reeds(rect, &rng) }
    }

    /// Ripples and lily pads on one box of a pond (called inside the pond's clip).
    private func lilies(_ rect: CGRect, _ rng: inout SeededRandom) {
        for _ in 0..<5 {
            let y = rng.range(rect.minY + 10, rect.maxY - 10)
            let x = rng.range(rect.minX + 6, rect.maxX - 40)
            let w = rng.range(18, 40)
            let ripple = CGMutablePath()
            ripple.move(to: CGPoint(x: x, y: y))
            ripple.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w / 2, y: y + 3))
            stroke(ripple, UIColor.white.withAlphaComponent(0.22), 1.0)
        }
        for _ in 0..<3 {
            let p = CGPoint(x: rng.range(rect.minX + 14, rect.maxX - 14), y: rng.range(rect.minY + 12, rect.maxY - 12))
            let r = rng.range(5, 8)
            let notch = rng.range(0, .pi * 2)
            let pad = CGMutablePath()
            pad.move(to: p)
            pad.addArc(center: p, radius: r, startAngle: notch + 0.35, endAngle: notch + .pi * 2 - 0.35, clockwise: false)
            pad.closeSubpath()
            shadow(dx: 1, dy: -1.5, blur: 1.5, alpha: 0.35) { fill(pad, UIColor(hex: 0x4E9A3F)) }
            stroke(circle(p, r * 0.55), UIColor(hex: 0x6DB85A).withAlphaComponent(0.6), 0.6)
            if rng.unit() < 0.5 { fill(circle(CGPoint(x: p.x + r * 0.3, y: p.y + r * 0.2), 2.2), UIColor(hex: 0xFFC6DA)) }
        }
    }

    /// Reeds along the outer-wall side of one box of a pond.
    private func reeds(_ rect: CGRect, _ rng: inout SeededRandom) {
        let wallSide: CGFloat = rect.minX <= 1 ? rect.minX + 6 : rect.maxX - 6
        for _ in 0..<9 {
            let base = CGPoint(x: wallSide + rng.range(-4, 4), y: rng.range(rect.minY + 6, rect.maxY - 6))
            let tip = CGPoint(x: base.x + rng.range(-5, 5), y: base.y + rng.range(6, 12))
            stroke(CourseArt.line(base, tip), UIColor(hex: 0x3E7D35), 1.1)
            if rng.unit() < 0.4 { fill(rounded(CGRect(x: tip.x - 0.9, y: tip.y - 3, width: 1.8, height: 4), 0.9), UIColor(hex: 0x6B4A2B)) }
        }
    }

    // MARK: Walls

    func borderShape(fill color: UIColor) {
        let band = CGMutablePath()
        band.addPath(rounded(outerRect, 12))
        band.addRect(feltRect)
        fill(band, color, evenOdd: true)
    }

    func railShapes(_ level: Level, fill color: UIColor) {
        for w in level.rails where !CourseArt.isFrameRail(w) {
            fill(capsule(w), color)
        }
    }

    func blockShapes(_ level: Level, fill color: UIColor) {
        for b in level.blocks { fill(rounded(blockRect(b), 4), color) }
    }

    private func blockRect(_ b: Box) -> CGRect {
        let r = Course.blockRadius
        return CGRect(x: b.minX - r, y: b.minY - r, width: b.width + 2 * r, height: b.height + 2 * r)
    }

    private func capsule(_ w: Wall) -> CGPath {
        CourseArt.line(CGPoint(x: w.a.x, y: w.a.y), CGPoint(x: w.b.x, y: w.b.y))
            .copy(strokingWithWidth: w.radius * 2, lineCap: .round, lineJoin: .round, miterLimit: 1)
    }

    func border(_ t: Theme, _ rng: inout SeededRandom) {
        let band = CGMutablePath()
        band.addPath(rounded(outerRect, 12))
        band.addRect(feltRect)
        let o = CourseArt.borderOut, r = Course.railRadius, w = Course.width, h = Course.height
        clipped(band, evenOdd: true) {
            strip(CGRect(x: -o, y: h - r, width: w + 2 * o, height: o + r), horizontal: true, t, &rng)
            strip(CGRect(x: -o, y: -o, width: w + 2 * o, height: o + r), horizontal: true, t, &rng)
            strip(CGRect(x: -o, y: r, width: o + r, height: h - 2 * r), horizontal: false, t, &rng)
            strip(CGRect(x: w - r, y: r, width: o + r, height: h - 2 * r), horizontal: false, t, &rng)
        }
        // Bevel: light on the outer top-left lip, dark lip where the wall meets the turf.
        stroke(rounded(outerRect.insetBy(dx: 0.8, dy: 0.8), 11), UIColor.white.withAlphaComponent(0.28), 1.2)
        stroke(rounded(outerRect, 12), t.borderSide.darker(0.45), 1.0)
        stroke(CGPath(rect: feltRect.insetBy(dx: -0.5, dy: -0.5), transform: nil), t.borderSide.darker(0.35), 1.2)
    }

    /// Planks or stones laid along a strip.
    private func strip(_ r: CGRect, horizontal: Bool, _ t: Theme, _ rng: inout SeededRandom) {
        let length = horizontal ? r.width : r.height
        var pos: CGFloat = 0
        var k = 0
        while pos < length - 0.5 {
            let len: CGFloat
            switch t.border {
            case .wood: len = min(rng.range(70, 130), length - pos)
            case .stone: len = min(rng.range(18, 34), length - pos)
            case .painted: len = min(rng.range(60, 110), length - pos)
            case .chainLink: len = min(rng.range(44, 60), length - pos)
            case .ties: len = min(rng.range(24, 34), length - pos)
            }
            let piece = horizontal
                ? CGRect(x: r.minX + pos, y: r.minY, width: len, height: r.height)
                : CGRect(x: r.minX, y: r.minY + pos, width: r.width, height: len)
            switch t.border {
            case .wood: plank(piece, horizontal: horizontal, t, &rng)
            case .stone: stone(piece, t, &rng)
            case .painted: paintedPlank(piece, horizontal: horizontal, t, &rng)
            case .chainLink: chainLinkPanel(piece, horizontal: horizontal, t, &rng)
            case .ties: tie(piece, horizontal: horizontal, t, &rng)
            }
            pos += len
            k += 1
        }
    }

    private func plank(_ r: CGRect, horizontal: Bool, _ t: Theme, _ rng: inout SeededRandom) {
        let tone = t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.22))
        let path = CGPath(rect: r, transform: nil)
        linear(path, [tone.lighter(0.08), tone, tone.darker(0.08)],
               from: horizontal ? CGPoint(x: r.midX, y: r.maxY) : CGPoint(x: r.minX, y: r.midY),
               to: horizontal ? CGPoint(x: r.midX, y: r.minY) : CGPoint(x: r.maxX, y: r.midY))
        clipped(path) {
            for _ in 0..<6 {
                let g = CGMutablePath()
                if horizontal {
                    let y = rng.range(r.minY, r.maxY)
                    g.move(to: CGPoint(x: r.minX, y: y))
                    g.addCurve(to: CGPoint(x: r.maxX, y: y + rng.range(-1.5, 1.5)),
                               control1: CGPoint(x: r.minX + r.width * 0.3, y: y + rng.range(-2, 2)),
                               control2: CGPoint(x: r.minX + r.width * 0.7, y: y + rng.range(-2, 2)))
                } else {
                    let x = rng.range(r.minX, r.maxX)
                    g.move(to: CGPoint(x: x, y: r.minY))
                    g.addCurve(to: CGPoint(x: x + rng.range(-1.5, 1.5), y: r.maxY),
                               control1: CGPoint(x: x + rng.range(-2, 2), y: r.minY + r.height * 0.3),
                               control2: CGPoint(x: x + rng.range(-2, 2), y: r.minY + r.height * 0.7))
                }
                stroke(g, t.borderSide.withAlphaComponent(0.28), rng.range(0.3, 0.7))
            }
        }
        let seam = horizontal ? CourseArt.line(CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY))
                              : CourseArt.line(CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY))
        stroke(seam, t.borderSide.darker(0.35), 0.9)
        // Nail heads near the seam.
        let nail = horizontal ? CGPoint(x: r.maxX - 4, y: r.midY) : CGPoint(x: r.midX, y: r.maxY - 4)
        fill(circle(nail, 0.8), t.borderSide.darker(0.5).withAlphaComponent(0.7))
    }

    private func stone(_ r: CGRect, _ t: Theme, _ rng: inout SeededRandom) {
        let tone = t.borderTop.mixed(with: t.borderSide, rng.range(0, 0.3))
        let block = rounded(r.insetBy(dx: 0.7, dy: 0.7), 2.2)
        fill(CGPath(rect: r, transform: nil), t.borderSide.darker(0.35))
        linear(block, [tone.lighter(0.1), tone, tone.darker(0.12)], from: CGPoint(x: r.minX, y: r.maxY), to: CGPoint(x: r.maxX, y: r.minY))
        clipped(block) {
            // Speckles instead of the tiled noise (tiling ignores small clips and washes out neighbours).
            for _ in 0..<Int(r.width * r.height / 6) {
                let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                fill(circle(p, rng.range(0.2, 0.45)), (rng.unit() < 0.5 ? UIColor.white : UIColor.black).withAlphaComponent(0.12))
            }
            stroke(rounded(r.insetBy(dx: 0.7, dy: 0.7).offsetBy(dx: 0.6, dy: -0.6), 2.2), UIColor.white.withAlphaComponent(0.3), 0.8)
        }
    }

    /// Interior rails end flush against the border's inner face rather than poking a round cap into it.
    func rails(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        clipped(CGPath(rect: feltRect, transform: nil)) { railBodies(level, t, &rng) }
    }

    private func railBodies(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        for w in level.rails where !CourseArt.isFrameRail(w) {
            let shape = capsule(w)
            let a = CGPoint(x: w.a.x, y: w.a.y), b = CGPoint(x: w.b.x, y: w.b.y)
            let len = hypot(b.x - a.x, b.y - a.y)
            let d = CGPoint(x: (b.x - a.x) / len, y: (b.y - a.y) / len)
            var n = CGPoint(x: -d.y, y: d.x)
            if n.y - n.x < 0 { n = CGPoint(x: -n.x, y: -n.y) }   // toward the light (up-left)
            fill(shape, t.borderTop)
            if t.border == .painted {
                // Painted rails: the wall colour with a trim line down the middle.
                clipped(shape) {
                    linear(shape, [t.borderTop.lighter(0.15), t.borderTop, t.borderSide],
                           from: CGPoint(x: a.x + n.x * w.radius, y: a.y + n.y * w.radius),
                           to: CGPoint(x: a.x - n.x * w.radius, y: a.y - n.y * w.radius))
                    stroke(CourseArt.line(a, b), t.trim.withAlphaComponent(0.9), 1.1)
                }
                stroke(shape, t.borderSide.darker(0.4), 0.8)
                continue
            }
            clipped(shape) {
                linear(shape, [t.borderTop.lighter(0.12), t.borderTop, t.borderSide],
                       from: CGPoint(x: a.x + n.x * w.radius, y: a.y + n.y * w.radius),
                       to: CGPoint(x: a.x - n.x * w.radius, y: a.y - n.y * w.radius))
                let step: CGFloat = t.border == .stone ? 22 : 90
                var s = rng.range(4, step)
                while s < len {
                    let p = CGPoint(x: a.x + d.x * s, y: a.y + d.y * s)
                    stroke(CourseArt.line(CGPoint(x: p.x - n.x * 6, y: p.y - n.y * 6), CGPoint(x: p.x + n.x * 6, y: p.y + n.y * 6)),
                           t.borderSide.darker(0.3), 0.8)
                    s += step * rng.range(0.8, 1.2)
                }
                noise(alpha: 0.14)
            }
            stroke(shape, t.borderSide.darker(0.4), 0.8)
        }
    }

    /// Planters are clipped to the open turf, so a wall they touch stays on top and they butt up against its face.
    /// The rim on that side straddles the wall's centerline by the block radius (3), inside the wall's own (4), so it vanishes.
    func blocks(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        let turf = level.rails.filter { !CourseArt.isFrameRail($0) }
            .reduce(CGPath(rect: feltRect, transform: nil)) { $0.subtracting(capsule($1)) }
        clipped(turf) { blockBodies(level, t, &rng) }
    }

    private func blockBodies(_ level: Level, _ t: Theme, _ rng: inout SeededRandom) {
        for b in level.blocks {
            let outer = blockRect(b)
            let path = rounded(outer, 4)
            fill(path, t.borderTop)
            var r2 = rng
            clipped(path) {
                strip(CGRect(x: outer.minX, y: outer.maxY - 6, width: outer.width, height: 6), horizontal: true, t, &r2)
                strip(CGRect(x: outer.minX, y: outer.minY, width: outer.width, height: 6), horizontal: true, t, &r2)
                strip(CGRect(x: outer.minX, y: outer.minY + 6, width: 6, height: outer.height - 12), horizontal: false, t, &r2)
                strip(CGRect(x: outer.maxX - 6, y: outer.minY + 6, width: 6, height: outer.height - 12), horizontal: false, t, &r2)
            }
            rng = r2
            stroke(path, t.borderSide.darker(0.4), 0.9)
            bed(outer.insetBy(dx: 6, dy: 6), square: Corners(CourseArt.walledSides(b, level)), t, &rng)
        }
    }

    /// A planted bed: soil, hedges and flowers.
    /// `square`: corners against a wall, kept square so the bed meets the wall without a wedge of rim showing.
    private func bed(_ r: CGRect, square: Corners, _ t: Theme, _ rng: inout SeededRandom) {
        switch t.bed {
        case .dune: dune(r, square: square, t, &rng); return
        case .rocks: rockBed(r, square: square, t, &rng); return
        case .snowbank: snowbank(r, square: square, t, &rng); return
        case .awning: awning(r, square: square, t, &rng); return
        case .machinery: machinery(r, square: square, t, &rng); return
        case .flowers: break
        }
        let path = CourseArt.rounded(r, 2, square: square)
        fill(path, UIColor(hex: 0x4A3424))
        clipped(path) {
            noise(alpha: 0.25)
            shadow(dx: 1.5, dy: -2, blur: 2, alpha: 0.5) {
                let count = Int(r.width * r.height / 70) + 3
                for _ in 0..<count {
                    let p = CGPoint(x: rng.range(r.minX, r.maxX), y: rng.range(r.minY, r.maxY))
                    let rad = rng.range(5, min(11, min(r.width, r.height) * 0.6))
                    let color = rng.pick(t.canopies).mixed(with: UIColor(hex: 0x2E6B2C), t.id == "autumn" ? 0.0 : 0.3)
                    fill(circle(p, rad), color.darker(0.12))
                    fill(circle(CGPoint(x: p.x - rad * 0.2, y: p.y + rad * 0.2), rad * 0.72), color)
                    fill(circle(CGPoint(x: p.x - rad * 0.35, y: p.y + rad * 0.35), rad * 0.3), color.lighter(0.15))
                }
            }
            let flowers = Int(r.width * r.height / 220) + 2
            for _ in 0..<flowers {
                let p = CGPoint(x: rng.range(r.minX + 2, r.maxX - 2), y: rng.range(r.minY + 2, r.maxY - 2))
                blossom(p, size: rng.range(1.3, 2.1), color: rng.pick(t.flowers))
            }
        }
        shadow(dx: 0, dy: 0, blur: 3, alpha: 0.6) {
            let ring = CGMutablePath()
            ring.addRect(r.insetBy(dx: -10, dy: -10))
            ring.addPath(path)
            clipped(path) { fill(ring, .black, evenOdd: true) }
        }
    }

    func blossom(_ p: CGPoint, size s: CGFloat, color: UIColor) {
        for k in 0..<5 {
            let a = CGFloat(k) / 5 * .pi * 2
            fill(circle(CGPoint(x: p.x + cos(a) * s * 0.75, y: p.y + sin(a) * s * 0.75), s * 0.6), color)
        }
        fill(circle(p, s * 0.42), UIColor(hex: 0xFFD54F))
    }

    // MARK: Scenery

    func ground(_ t: Theme, _ rect: CGRect, _ seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        fill(rect, t.rough)
        switch t.ground {
        case .sand: sandGround(t, rect, &rng); return
        case .snow: snowGround(t, rect, &rng); return
        case .links: linksGround(t, rect, &rng); return
        case .deck: deckGround(t, rect, &rng); return
        case .grass, .muni: break
        case .stadium: mowerStripes(t, rect)
        }
        let area = rect.width * rect.height
        for _ in 0..<Int(area / 9000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(40, 130)
            let color = rng.unit() < 0.6 ? t.roughShade.withAlphaComponent(0.55) : t.roughLight.withAlphaComponent(0.35)
            c.drawRadialGradient(gradient([color, color.withAlphaComponent(0)]), startCenter: p, startRadius: 0, endCenter: p, endRadius: r, options: [])
        }
        noise(alpha: 0.16)
        for _ in 0..<Int(area / 70) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let tip = CGPoint(x: p.x + rng.range(-1.5, 1.5), y: p.y + rng.range(2, 5))
            stroke(CourseArt.line(p, tip), (rng.unit() < 0.5 ? t.roughLight : t.roughShade).withAlphaComponent(0.6), rng.range(0.5, 0.9))
        }
        for _ in 0..<Int(area / 4000) {
            let center = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let color = rng.pick(t.flowers)
            for _ in 0..<Int(rng.range(3, 8)) {
                blossom(CGPoint(x: center.x + rng.range(-9, 9), y: center.y + rng.range(-9, 9)), size: rng.range(1.2, 2.0), color: color)
            }
        }
        if !t.litter.isEmpty {
            for _ in 0..<Int(area / 260) {
                let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
                c.saveGState()
                c.translateBy(x: p.x, y: p.y)
                c.rotate(by: rng.range(0, .pi))
                let s = rng.range(1.8, 3.2)
                fill(CGPath(ellipseIn: CGRect(x: -s, y: -s * 0.55, width: s * 2, height: s * 1.1), transform: nil), rng.pick(t.litter).withAlphaComponent(0.85))
                c.restoreGState()
            }
        }
        for _ in 0..<Int(area / 6000) {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let s = rng.range(1.2, 2.6)
            fill(CGPath(ellipseIn: CGRect(x: p.x - s, y: p.y - s * 0.7, width: s * 2, height: s * 1.4), transform: nil), UIColor(hex: 0xB9B3A6).withAlphaComponent(0.8))
        }
        if t.ground == .muni { wornPatches(t, rect, &rng) }
        if t.ground == .stadium { pineStraw(rect, &rng); gallery(rect, &rng) }
    }

    func tree(_ t: Theme, radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom) {
        switch t.trees {
        case .round: canopy(radius: r, color: color, &rng, flowers: nil)
        case .palm: palm(radius: r, color: color, &rng)
        case .cactus: cactus(radius: r * 0.6, color: color, &rng)
        case .pine: pine(radius: r, color: color, &rng)
        case .tents: tent(radius: r * 0.9, color: color, t, &rng)
        case .gorse: gorse(radius: r * 0.7, color: color, t, &rng)
        case .crates: crate(radius: r * 0.75, color: color, &rng)
        }
    }

    func canopy(radius r: CGFloat, color: UIColor, _ rng: inout SeededRandom, flowers: [UIColor]?) {
        var blobs: [(CGPoint, CGFloat)] = [(.zero, r * 0.62)]
        let n = Int(rng.range(6, 9))
        for k in 0..<n {
            let a = CGFloat(k) / CGFloat(n) * .pi * 2 + rng.range(-0.3, 0.3)
            let d = r * rng.range(0.38, 0.5)
            blobs.append((CGPoint(x: cos(a) * d, y: sin(a) * d), r * rng.range(0.42, 0.56)))
        }
        shadow(dx: r * 0.22, dy: -r * 0.3, blur: r * 0.25, alpha: 0.45) {
            for (p, br) in blobs { fill(circle(p, br), color.darker(0.22)) }
        }
        for (p, br) in blobs { fill(circle(CGPoint(x: p.x - br * 0.12, y: p.y + br * 0.14), br * 0.86), color) }
        for (p, br) in blobs where p.x - p.y < r * 0.2 {
            fill(circle(CGPoint(x: p.x - br * 0.25, y: p.y + br * 0.28), br * 0.45), color.lighter(0.14))
        }
        for _ in 0..<Int(r * 2.2) {
            let a = rng.range(0, .pi * 2), d = rng.range(0, r * 0.9)
            let p = CGPoint(x: cos(a) * d, y: sin(a) * d)
            fill(circle(p, rng.range(r * 0.04, r * 0.09)), (rng.unit() < 0.5 ? color.lighter(0.25) : color.darker(0.25)).withAlphaComponent(0.5))
        }
        if let flowers {
            let fc = rng.pick(flowers)
            for _ in 0..<Int(r * 0.8) {
                let a = rng.range(0, .pi * 2), d = rng.range(0, r * 0.85)
                blossom(CGPoint(x: cos(a) * d, y: sin(a) * d), size: rng.range(1.0, 1.6), color: fc)
            }
        }
    }

    func rock(radius r: CGFloat, _ rng: inout SeededRandom) {
        let path = CGMutablePath()
        let n = 7
        for k in 0..<n {
            let a = CGFloat(k) / CGFloat(n) * .pi * 2
            let d = r * rng.range(0.75, 1.0)
            let p = CGPoint(x: cos(a) * d, y: sin(a) * d * 0.8)
            k == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        shadow(dx: r * 0.2, dy: -r * 0.3, blur: r * 0.3, alpha: 0.45) { fill(path, UIColor(hex: 0x8E8A80)) }
        linear(path, [UIColor(hex: 0xC9C5BB), UIColor(hex: 0x9C988E), UIColor(hex: 0x6F6B63)], from: CGPoint(x: -r, y: r), to: CGPoint(x: r, y: -r))
        clipped(path) { noise(alpha: 0.2) }
        stroke(path, UIColor(hex: 0x5A564F).withAlphaComponent(0.6), 0.6)
    }

    func ballBase(radius r: CGFloat) {
        radial(circle(.zero, r), [.white, UIColor(hex: 0xF1F3F5), UIColor(hex: 0xC4CAD1)], locations: [0, 0.45, 1],
               center: CGPoint(x: -r * 0.3, y: r * 0.3), radius: r * 1.35)
    }

    func ballGloss(radius r: CGFloat) {
        let shape = circle(.zero, r)
        clipped(shape) {
            radial(shape, [UIColor.clear, UIColor.clear, UIColor.black.withAlphaComponent(0.28)], locations: [0, 0.55, 1],
                   center: CGPoint(x: -r * 0.3, y: r * 0.3), radius: r * 1.4)
        }
        fill(CGPath(ellipseIn: CGRect(x: -r * 0.62, y: r * 0.18, width: r * 0.55, height: r * 0.4), transform: nil), UIColor.white.withAlphaComponent(0.9))
        stroke(shape, UIColor.black.withAlphaComponent(0.25), r * 0.08)
    }
}
