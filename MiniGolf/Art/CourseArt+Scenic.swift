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
