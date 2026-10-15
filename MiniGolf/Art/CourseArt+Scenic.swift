import Observation
import UIKit

extension CourseArt {
    /// Course + ground + trees in one image, for menus. `rect` is in world units.
    static func scenic(_ level: Level, rect: CGRect, pixelWidth: CGFloat) -> UIImage {
        let theme = Theme.for(level)
        let ppu = pixelWidth / rect.width
        let seed = stableSeed(level.name)
        return render(rect, ppu: ppu) { p in
            p.ground(theme, rect, seed)
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

/// Menu artwork. Course cards render in the background and appear when ready.
@MainActor
@Observable
final class MenuArt {
    static let shared = MenuArt()
    private(set) var cards: [String: UIImage] = [:]
    @ObservationIgnored private var pending: Set<String> = []
    @ObservationIgnored private var titleImage: UIImage?

    func card(_ level: Level) -> UIImage? {
        if let img = cards[level.name] { return img }
        if !pending.contains(level.name) {
            pending.insert(level.name)
            let lvl = level
            Task.detached(priority: .userInitiated) {
                let rect = CourseArt.courseRect.insetBy(dx: -26, dy: -26)
                let img = CourseArt.scenic(lvl, rect: rect, pixelWidth: 420)
                await MainActor.run { MenuArt.shared.cards[lvl.name] = img }
            }
        }
        return nil
    }

    /// Warm the cache so the course map opens instantly.
    func prefetch(_ levels: [Level]) { for l in levels { _ = card(l) } }

    func title(size: CGSize) -> UIImage {
        if let titleImage { return titleImage }
        let level = Levels.course.first { $0.name == "Reflection" } ?? Levels.course[0]
        let w: CGFloat = 520
        let h = w * max(size.height, 1) / max(size.width, 1)
        // Course top edge ~58% down the screen: logo over the meadow, cups just above the buttons.
        let top = Course.height + CourseArt.borderOut
        let rect = CGRect(x: Course.width / 2 - w / 2, y: top - h * 0.42, width: w, height: h)
        let img = CourseArt.scenic(level, rect: rect, pixelWidth: size.width * 3)
        titleImage = img
        return img
    }
}
