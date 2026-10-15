import UIKit

/// Visual setting for a hole pair. Everything is drawn in code from these values.
struct Theme {
    enum Border { case wood, stone }
    enum Ambient { case none, petals, leaves, motes, fireflies, snow, dust }
    enum Ground { case grass, sand, snow }
    enum Trees { case round, palm, cactus, pine }
    enum Bed { case flowers, dune, rocks, snowbank }
    enum Water { case pond, tidepool, ice }
    enum Post { case stone, buoy, lantern }

    var id = ""
    /// Display name, e.g. "Spring Meadow".
    var setting: String { Levels.settingNames[id] ?? id }
    var rough = UIColor.green, roughShade = UIColor.green, roughLight = UIColor.green
    var feltLight = UIColor.green, feltDark = UIColor.green
    var border = Border.wood
    var borderTop = UIColor.brown, borderSide = UIColor.brown
    /// White caps along the top of rails (winter).
    var snowCaps = false
    var canopies: [UIColor] = []
    var flowers: [UIColor] = []
    var litter: [UIColor] = []
    /// Candy-stripe pair for striped borders, awnings, tents and carousels.
    var stripes = [UIColor(hex: 0xF0524F), UIColor(hex: 0xFFF4E2)]
    var waterDeep = UIColor(hex: 0x1D6FA5), waterShallow = UIColor(hex: 0x56B9DE)
    var ambient = Ambient.none
    var ground = Ground.grass
    var trees = Trees.round
    var bed = Bed.flowers
    var water = Water.pond
    var post = Post.stone
    /// Glowing lanterns around the course (night).
    var lanterns = false
    /// SwiftUI accents for cards and the results screen.
    var accent = UIColor.white

    static let meadow: Theme = {
        var t = Theme()
        t.id = "meadow"
        t.rough = UIColor(hex: 0x5C9A3A); t.roughShade = UIColor(hex: 0x4A8530); t.roughLight = UIColor(hex: 0x7DB451)
        t.feltLight = UIColor(hex: 0x5DBB5A); t.feltDark = UIColor(hex: 0x51AD4F)
        t.border = .wood; t.borderTop = UIColor(hex: 0xD8B47A); t.borderSide = UIColor(hex: 0x9C7243)
        t.canopies = [UIColor(hex: 0x3F8F3A), UIColor(hex: 0x2F7A33), UIColor(hex: 0x57A844)]
        t.flowers = [UIColor(hex: 0xFF8FB1), UIColor(hex: 0xFFFFFF), UIColor(hex: 0xFFD54F), UIColor(hex: 0xC5A3FF)]
        t.ambient = .petals; t.accent = UIColor(hex: 0x7BC96F)
        return t
    }()

    static let garden: Theme = {
        var t = Theme()
        t.id = "garden"
        t.rough = UIColor(hex: 0x4F8A3B); t.roughShade = UIColor(hex: 0x41782F); t.roughLight = UIColor(hex: 0x6BA34C)
        t.feltLight = UIColor(hex: 0x58B25E); t.feltDark = UIColor(hex: 0x4CA353)
        t.border = .stone; t.borderTop = UIColor(hex: 0xD9D2C5); t.borderSide = UIColor(hex: 0x9E968A)
        t.canopies = [UIColor(hex: 0x2E6E33), UIColor(hex: 0x3B7F3A), UIColor(hex: 0x24602B)]
        t.flowers = [UIColor(hex: 0xE84C5B), UIColor(hex: 0xFFFFFF), UIColor(hex: 0xF7A1C4)]
        t.accent = UIColor(hex: 0xE8838F)
        return t
    }()

    static let moat: Theme = {
        var t = Theme()
        t.id = "moat"
        t.rough = UIColor(hex: 0x4E7F3D); t.roughShade = UIColor(hex: 0x3F6D32); t.roughLight = UIColor(hex: 0x6A9750)
        t.feltLight = UIColor(hex: 0x52AC5F); t.feltDark = UIColor(hex: 0x479E55)
        t.border = .stone; t.borderTop = UIColor(hex: 0xBFC0B8); t.borderSide = UIColor(hex: 0x7F817B)
        t.canopies = [UIColor(hex: 0x356F3F), UIColor(hex: 0x4A8A48), UIColor(hex: 0x2B5F36)]
        t.flowers = [UIColor(hex: 0xFFFFFF), UIColor(hex: 0x9FC8FF), UIColor(hex: 0xFFE27A)]
        t.waterDeep = UIColor(hex: 0x17619A); t.waterShallow = UIColor(hex: 0x4DB0D8)
        t.ambient = .motes; t.bed = .rocks; t.accent = UIColor(hex: 0x5DB7E0)
        return t
    }()

    static let seaside: Theme = {
        var t = Theme()
        t.id = "seaside"
        t.rough = UIColor(hex: 0xE9D6A6); t.roughShade = UIColor(hex: 0xD8BF88); t.roughLight = UIColor(hex: 0xF6EACB)
        t.feltLight = UIColor(hex: 0x4FBE86); t.feltDark = UIColor(hex: 0x44B07A)
        t.border = .wood; t.borderTop = UIColor(hex: 0xDCCFB6); t.borderSide = UIColor(hex: 0x9A8C73)
        t.canopies = [UIColor(hex: 0x3E9B57), UIColor(hex: 0x2F8A4A), UIColor(hex: 0x58B065)]
        t.flowers = [UIColor(hex: 0xFFFFFF), UIColor(hex: 0xF7C2B0), UIColor(hex: 0xF0D9A8)]
        t.waterDeep = UIColor(hex: 0x0F7FA0); t.waterShallow = UIColor(hex: 0x52D3D6)
        t.ground = .sand; t.trees = .palm; t.bed = .dune; t.water = .tidepool; t.post = .buoy
        t.accent = UIColor(hex: 0x52D3D6)
        return t
    }()

    static let autumn: Theme = {
        var t = Theme()
        t.id = "autumn"
        t.rough = UIColor(hex: 0x7F8E3E); t.roughShade = UIColor(hex: 0x6C7A33); t.roughLight = UIColor(hex: 0x9AA853)
        t.feltLight = UIColor(hex: 0x62AE52); t.feltDark = UIColor(hex: 0x57A049)
        t.border = .wood; t.borderTop = UIColor(hex: 0xA8714A); t.borderSide = UIColor(hex: 0x6B4229)
        t.canopies = [UIColor(hex: 0xE07B39), UIColor(hex: 0xC8452C), UIColor(hex: 0xE9B949), UIColor(hex: 0xB85C2A)]
        t.flowers = [UIColor(hex: 0xF2C14E), UIColor(hex: 0xE76F51)]
        t.litter = [UIColor(hex: 0xE07B39), UIColor(hex: 0xC8452C), UIColor(hex: 0xE9B949)]
        t.ambient = .leaves; t.accent = UIColor(hex: 0xF0A04B)
        return t
    }()

    static let desert: Theme = {
        var t = Theme()
        t.id = "desert"
        t.rough = UIColor(hex: 0xD99E63); t.roughShade = UIColor(hex: 0xC4844C); t.roughLight = UIColor(hex: 0xEABB86)
        t.feltLight = UIColor(hex: 0x74B45A); t.feltDark = UIColor(hex: 0x68A64F)
        t.border = .stone; t.borderTop = UIColor(hex: 0xCB7A50); t.borderSide = UIColor(hex: 0x8C4A2F)
        t.canopies = [UIColor(hex: 0x4C8C4A), UIColor(hex: 0x5E9E55), UIColor(hex: 0x3F7A40)]
        t.flowers = [UIColor(hex: 0xFF7AA2), UIColor(hex: 0xFFD166)]
        t.waterDeep = UIColor(hex: 0x127A8A); t.waterShallow = UIColor(hex: 0x47C3C4)
        t.ground = .sand; t.trees = .cactus; t.bed = .rocks; t.ambient = .dust
        t.accent = UIColor(hex: 0xEE9A62)
        return t
    }()

    static let winter: Theme = {
        var t = Theme()
        t.id = "winter"
        t.rough = UIColor(hex: 0xEAF1F7); t.roughShade = UIColor(hex: 0xCFDCE9); t.roughLight = UIColor(hex: 0xFFFFFF)
        t.feltLight = UIColor(hex: 0x5DB47E); t.feltDark = UIColor(hex: 0x52A672)
        t.border = .wood; t.borderTop = UIColor(hex: 0x94725A); t.borderSide = UIColor(hex: 0x5C4535); t.snowCaps = true
        t.canopies = [UIColor(hex: 0x2E5E45), UIColor(hex: 0x3A6F52), UIColor(hex: 0x24503A)]
        t.flowers = [UIColor(hex: 0xD94A4A), UIColor(hex: 0xFFFFFF)]
        t.waterDeep = UIColor(hex: 0x86BEDD); t.waterShallow = UIColor(hex: 0xD3EBF7)
        t.ground = .snow; t.trees = .pine; t.bed = .snowbank; t.water = .ice; t.ambient = .snow
        t.accent = UIColor(hex: 0x9CCBEB)
        return t
    }()

    static let night: Theme = {
        var t = Theme()
        t.id = "night"
        t.rough = UIColor(hex: 0x1C3325); t.roughShade = UIColor(hex: 0x13261A); t.roughLight = UIColor(hex: 0x2A4834)
        t.feltLight = UIColor(hex: 0x2A7448); t.feltDark = UIColor(hex: 0x24673F)
        t.border = .stone; t.borderTop = UIColor(hex: 0x737B88); t.borderSide = UIColor(hex: 0x40454E)
        t.canopies = [UIColor(hex: 0x1F4A33), UIColor(hex: 0x27583D), UIColor(hex: 0x183D29)]
        t.flowers = [UIColor(hex: 0x9FE8FF), UIColor(hex: 0xFFE29A), UIColor(hex: 0xD9A8FF)]
        t.waterDeep = UIColor(hex: 0x0D2747); t.waterShallow = UIColor(hex: 0x245887)
        t.ambient = .fireflies; t.post = .lantern; t.lanterns = true
        t.accent = UIColor(hex: 0xFFD27A)
        return t
    }()

    static let all: [String: Theme] = Dictionary(uniqueKeysWithValues:
        [meadow, garden, moat, seaside, autumn, desert, winter, night].map { ($0.id, $0) })

    static func `for`(_ level: Level) -> Theme { all[level.setting] ?? .meadow }
}

enum Palette {
    static let holeA = UIColor(hex: 0xFF8A3D)
    static let holeB = UIColor(hex: 0x8F6BFF)
    static func hole(_ i: Int) -> UIColor { i == 0 ? holeA : holeB }
    static let ink = UIColor(hex: 0x10231A)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }

    func mixed(with other: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }

    func lighter(_ t: CGFloat) -> UIColor { mixed(with: .white, t) }
    func darker(_ t: CGFloat) -> UIColor { mixed(with: .black, t) }
}

/// Deterministic RNG so scenery is stable per level.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
    mutating func range(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + (hi - lo) * unit() }
    mutating func pick<T>(_ items: [T]) -> T { items[Int(next() % UInt64(items.count))] }
}
