import UIKit

extension CourseArt {
    /// Width over height of a hole's card in the menus.
    static let cardAspect: CGFloat = 0.7

    /// A hole's card for the menus: the course with ground and trees down its sides, cut to the card's shape.
    static func card(_ level: Level, pixelWidth: CGFloat) -> UIImage {
        let rect = courseRect.insetBy(dx: -26, dy: -26)
        let height = rect.width / cardAspect
        let crop = CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
        return scenic(level, rect: rect, pixelWidth: pixelWidth, crop: crop)
    }

    /// Course + ground + trees in one image, for menus. `rect` is in world units. With `crop`, only that part of it
    /// is drawn: trees still scatter over all of `rect`, so they stand as thick as ever, but those outside the crop
    /// are skipped, and the ground is only drawn beside the felt, which hides the rest. That's what keeps a card
    /// quick to draw.
    static func scenic(_ level: Level, rect: CGRect, pixelWidth: CGFloat, crop: CGRect? = nil) -> UIImage {
        let theme = Theme.for(level)
        let frame = crop ?? rect
        let ppu = pixelWidth / frame.width
        let seed = stableSeed(level.name)
        return render(frame, ppu: ppu) { p in
            if let crop {
                let felt = CGRect(x: 0, y: 0, width: Course.width, height: Course.height)
                for (k, piece) in crop.outside(felt).enumerated() {
                    p.clipped(CGPath(rect: piece, transform: nil)) { p.ground(theme, piece, seed &+ UInt64(k)) }
                }
            } else {
                p.ground(theme, rect, seed)
            }
            p.image(course(level, theme: theme, ppu: ppu).cgImage!, in: courseRect)
            p.movers(level, theme)
            p.flags(level)
            var rng = SeededRandom(seed: seed &+ 5)
            let felt = CGRect(x: -2, y: -2, width: Course.width + 4, height: Course.height + 4)
            var placed: [(CGPoint, CGFloat)] = []
            for _ in 0..<220 {
                let c = CGPoint(x: rng.range(rect.minX - 30, rect.maxX + 30), y: rng.range(rect.minY - 30, rect.maxY + 30))
                let tree = rng.unit() < 0.55
                let r = tree ? rng.range(30, 50) : rng.range(9, 14)
                let dx = max(felt.minX - c.x, 0, c.x - felt.maxX), dy = max(felt.minY - c.y, 0, c.y - felt.maxY)
                guard hypot(dx, dy) > r * 0.9, !placed.contains(where: { hypot($0.0.x - c.x, $0.0.y - c.y) < ($0.1 + r) * 0.8 }) else { continue }
                placed.append((c, r))
                // A tree's shadow falls a little past its radius.
                if let crop, !crop.insetBy(dx: -r * 1.6, dy: -r * 1.6).contains(c) { continue }
                p.c.saveGState()
                p.c.translateBy(x: c.x, y: c.y)
                // Each shadow is drawn through a transparency layer the size of the clip: unclipped, that's the whole
                // backdrop, which on an iPad is slow and leaves smears of colour where the layers meet.
                p.c.clip(to: CGRect(x: -r * 1.7, y: -r * 1.7, width: r * 3.4, height: r * 3.4))
                let color = rng.pick(theme.canopies)
                if tree {
                    p.tree(theme, radius: r, color: color, &rng)
                } else if theme.trees == .cactus || theme.ground == .snow {
                    p.rockShape(radius: r * 0.6, tone: theme.ground == .snow ? UIColor(hex: 0xB9C6D2) : theme.borderTop, &rng)
                } else if theme.trees == .tents {
                    p.balloons(radius: r, theme, &rng)
                } else {
                    p.canopy(radius: r, color: color.mixed(with: theme.rough, 0.25), &rng, flowers: rng.unit() < 0.6 ? theme.flowers : nil)
                }
                p.c.restoreGState()
            }
        }
    }
}

extension Painter {
    /// The movers where they stand as the hole loads (clock 0), drawn as the game draws them (GameScene.buildMovers):
    /// a shadow down and to the right, then the piece. A carousel lies flush with no shadow; a force field shows lit.
    func movers(_ level: Level, _ theme: Theme) {
        for m in level.movers {
            let body: UIImage, shadow: UIImage?, size: CGSize, center: Vec, angle: Double
            var beam: (image: UIImage, size: CGSize)?
            switch m.kind {
            case .rotor(let pivot, let blades, let length, _, _):
                body = CourseArt.rotor(blades: blades, length: length, radius: m.radius, theme: theme, ppu: ppu, shadow: false)
                shadow = CourseArt.rotor(blades: blades, length: length, radius: m.radius, theme: theme, ppu: ppu, shadow: true)
                size = CGSize(width: (length + 4) * 2, height: (length + 4) * 2)
                (center, angle) = (pivot, m.bladeAngle(0, at: 0))
            case .slider(let box, _, _):
                body = CourseArt.sliderBlock(box, radius: m.radius, theme: theme, ppu: ppu, shadow: false)
                shadow = CourseArt.sliderBlock(box, radius: m.radius, theme: theme, ppu: ppu, shadow: true)
                size = CGSize(width: box.width + 2 * m.radius, height: box.height + 2 * m.radius)
                (center, angle) = (box.center + m.sliderOffset(at: 0), 0)
            case .carousel(let pivot, let radius, _, _):
                body = CourseArt.carousel(radius: radius, theme: theme, ppu: ppu)
                shadow = nil
                size = CGSize(width: (radius + 3) * 2, height: (radius + 3) * 2)
                (center, angle) = (pivot, m.bladeAngle(0, at: 0))
            case .robot:
                body = CourseArt.robot(radius: m.radius, ppu: ppu, shadow: false)
                shadow = CourseArt.robot(radius: m.radius, ppu: ppu, shadow: true)
                size = CGSize(width: (m.radius + 3) * 2, height: (m.radius + 3) * 2)
                let pose = m.robotPose(at: 0)
                (center, angle) = (pose.pos, atan2(pose.heading.y, pose.heading.x))
            case .field(let a, let b, _, _, _):
                let length = (b - a).length
                body = CourseArt.fieldPosts(length: length, ppu: ppu, shadow: false)
                shadow = CourseArt.fieldPosts(length: length, ppu: ppu, shadow: true)
                size = CGSize(width: length + 14, height: 14)
                beam = (CourseArt.fieldBeam(length: length, ppu: ppu), CGSize(width: length, height: 10))
                (center, angle) = (Vec((a.x + b.x) / 2, (a.y + b.y) / 2), atan2(b.y - a.y, b.x - a.x))
            }
            if let shadow { place(shadow, size, at: CGPoint(x: center.x + 2.5, y: center.y - 3.5), angle, alpha: 0.3) }
            if let beam { place(beam.image, beam.size, at: center.cg, angle, alpha: 0.9, blend: .plusLighter) }
            place(body, size, at: center.cg, angle)
        }
    }

    /// A flag in every cup, standing as the game's do (GameScene.buildFlags), with the pennant caught mid-flutter.
    func flags(_ level: Level) {
        for (i, cup) in level.cups.enumerated() {
            c.saveGState()
            c.translateBy(x: cup.x, y: cup.y)
            stroke(CourseArt.line(.zero, CGPoint(x: 20, y: -15)), UIColor.black.withAlphaComponent(0.22), 2.2)
            let pole = CGPath(roundedRect: CGRect(x: -0.9, y: 0, width: 1.8, height: 38), cornerWidth: 0.9, cornerHeight: 0.9,
                              transform: nil)
            fill(pole, UIColor(hex: 0xF5F5F0))
            stroke(pole, UIColor(hex: 0x9A9A92), 0.4)
            fill(circle(CGPoint(x: 0, y: 38.5), 1.6), UIColor(hex: 0xF2C14E))
            let t = Double(i) * 1.3
            let pennant = CGMutablePath()
            pennant.move(to: CGPoint(x: 0.9, y: 37))
            pennant.addQuadCurve(to: CGPoint(x: 19 + sin(t) * 0.8, y: 32 + sin(t + 1.2) * 1.4),
                                 control: CGPoint(x: 10, y: 37 + sin(t + 0.6) * 2.0))
            pennant.addQuadCurve(to: CGPoint(x: 0.9, y: 26), control: CGPoint(x: 10, y: 27 + sin(t + 0.9) * 2.0))
            pennant.closeSubpath()
            fill(pennant, .white)
            stroke(pennant, UIColor(hex: 0xB9B9B0), 0.5)
            c.restoreGState()
        }
    }

    /// `image` drawn `size` big (world units), centred at `center` and turned `angle` radians, as a sprite would be.
    private func place(_ image: UIImage, _ size: CGSize, at center: CGPoint, _ angle: Double, alpha: CGFloat = 1,
                       blend: CGBlendMode = .normal) {
        guard let cg = image.cgImage else { return }
        c.saveGState()
        c.translateBy(x: center.x, y: center.y)
        c.rotate(by: angle)
        c.setAlpha(alpha)
        c.setBlendMode(blend)
        c.draw(cg, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        c.restoreGState()
    }
}

private extension CGRect {
    /// What's left of this rect around `hole`: the strips either side of it, then the bits above and below.
    func outside(_ hole: CGRect) -> [CGRect] {
        let h = intersection(hole)
        guard !h.isNull else { return [self] }
        return [CGRect(x: minX, y: minY, width: h.minX - minX, height: height),
                CGRect(x: h.maxX, y: minY, width: maxX - h.maxX, height: height),
                CGRect(x: h.minX, y: minY, width: h.width, height: h.minY - minY),
                CGRect(x: h.minX, y: h.maxY, width: h.width, height: maxY - h.maxY)].filter { $0.width > 0 && $0.height > 0 }
    }
}
