import Foundation

// Brute-force every first swing (angle x power x same/mirror) for each level and report what happens.
// Usage: Tools/solve.sh [level name filter] [--fine] [--candidates] [--all] [--verify] [--probe <angle>]
//        LEVELS=Tools/levels/x.swift Tools/solve.sh --drafts   (levels in a scratch file's `Levels.drafts`)

let args = Array(CommandLine.arguments.dropFirst())
let fine = args.contains("--fine")
let filter = args.first { !$0.hasPrefix("--") }?.lowercased()

let angleStep = fine ? 0.1 : 0.25
let powerStep = fine ? 0.005 : 0.01
let angleCount = Int((360 / angleStep).rounded())
let powerCount = Int((1 / powerStep).rounded())

struct Best { var ai: Int; var pi: Int; var score: Int; var mirrored: Bool; var angleWindow: Double; var powerWindow: Double }

/// Grid of results, bit 0 = A sank, bit 1 = B sank, bit 2 = balls touched, bit 3 = a ball used the other hole's cup.
/// Also returns how many shots found water.
func solve(_ level: Level, mirrored: Bool) -> (grid: [UInt8], splashes: Int) {
    let world = World(level: level)
    var grid = [UInt8](repeating: 0, count: angleCount * powerCount)
    var splashCount = [Int](repeating: 0, count: angleCount)
    grid.withUnsafeMutableBufferPointer { cells in
        let cellsPtr = cells
        splashCount.withUnsafeMutableBufferPointer { splashes in
            let splashPtr = splashes
            DispatchQueue.concurrentPerform(iterations: angleCount) { ai in
                var s = 0
                for pi in 0..<powerCount {
                    let shot = Shot(angle: Double(ai) * angleStep, power: Double(pi + 1) * powerStep, mirrored: mirrored)
                    let out = world.simulate(shot: shot.velocity, mirrored: mirrored)
                    var r: UInt8 = 0
                    if out.world.balls[0].sunkIn != nil { r |= 1 }
                    if out.world.balls[1].sunkIn != nil { r |= 2 }
                    if out.ballHits > 0 { r |= 4 }
                    if out.world.balls[0].sunkIn == 1 || out.world.balls[1].sunkIn == 0 { r |= 8 }
                    if out.tunnels > 0 { r |= 16 }
                    if out.splashed.contains(true) { s += 1 }
                    cellsPtr[ai * powerCount + pi] = r
                }
                splashPtr[ai] = s
            }
        }
    }
    return (grid, splashCount.reduce(0, +))
}

#if HAS_DRAFTS
let drafts = Levels.drafts
#else
let drafts: [Level] = []
#endif
let levels = args.contains("--drafts") ? drafts
    : args.contains("--candidates") ? Candidates.all
    : Levels.course

// --probe <angle>: outcome at every power for one angle, e.g. Tools/solve.sh twins --probe 90
if let i = args.firstIndex(of: "--probe"), i + 1 < args.count, let angle = Double(args[i + 1]) {
    for level in levels where filter == nil || level.name.lowercased().contains(filter!) {
        for mirrored in [false, true] {
            let line = (20...100).map { p -> Character in
                let out = World(level: level).simulate(shot: Shot(angle: angle, power: Double(p) / 100).velocity, mirrored: mirrored)
                switch (out.world.balls[0].sunkIn != nil, out.world.balls[1].sunkIn != nil) {
                case (true, true): return "#"
                case (true, false): return "a"
                case (false, true): return "b"
                default: return "."
                }
            }
            print("\(level.name) \(mirrored ? "mirror" : "same  ") \(angle)°  20%…100%: \(String(line))")
        }
    }
    exit(0)
}

if args.contains("--verify") {
    var failed = false
    for level in levels {
        guard let shot = level.solution else { print("✗ \(level.name): no solution"); failed = true; continue }
        let out = World(level: level).simulate(shot: shot.velocity, mirrored: shot.mirrored)
        let ok = out.world.allSunk
        failed = failed || !ok
        print("\(ok ? "✓" : "✗") \(level.name): \(shot.angle)° \(Int(shot.power * 100))%\(shot.mirrored ? " mirror" : "")")
    }
    exit(failed ? 1 : 0)
}
for (index, level) in levels.enumerated() {
    if let filter, !level.name.lowercased().contains(filter) { continue }
    print("[\(index + 1)] \(level.name)  (\(level.setting), par \(level.par[0])/\(level.par[1]))")
    var best: Best?
    var holeAce = [0.0, 0.0]

    for mirrored in [false, true] {
        let start = Date()
        let (grid, splashes) = solve(level, mirrored: mirrored)
        let total = grid.count
        func count(_ v: UInt8) -> Int { grid.reduce(0) { $0 + ($1 & 3 == v ? 1 : 0) } }
        let caroms = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 4 != 0 ? 1 : 0) }
        let swaps = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 8 != 0 ? 1 : 0) }
        let tunnelAces = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 16 != 0 ? 1 : 0) }
        holeAce[0] = max(holeAce[0], Double(count(1) + count(3)) / Double(total) * 100)
        holeAce[1] = max(holeAce[1], Double(count(2) + count(3)) / Double(total) * 100)
        func pct(_ n: Int) -> String { String(format: "%.3f%%", Double(n) / Double(total) * 100) }
        let both = count(3)
        print("  \(mirrored ? "MIRROR" : "SAME  ")  double ace \(pct(both)) (\(both))   A only \(pct(count(1)))   B only \(pct(count(2)))   water \(pct(splashes))   ball-hit aces \(caroms)   swapped-cup aces \(swaps)   tunnel aces \(tunnelAces)   [\(String(format: "%.1fs", Date().timeIntervalSince(start)))]")

        func cell(_ ai: Int, _ pi: Int) -> UInt8 {
            guard pi >= 0, pi < powerCount else { return 0 }
            return grid[((ai % angleCount + angleCount) % angleCount) * powerCount + pi] & 3
        }
        var regions: [(lo: Int, hi: Int)] = []
        for ai in 0..<angleCount {
            var any = false
            for pi in 0..<powerCount where cell(ai, pi) == 3 {
                any = true
                var score = 0
                for da in -4...4 { for dp in -4...4 where cell(ai + da, pi + dp) == 3 { score += 1 } }
                if best == nil || score > best!.score {
                    var a1 = 0; while a1 < 400, cell(ai + a1 + 1, pi) == 3 { a1 += 1 }
                    var a2 = 0; while a2 < 400, cell(ai - a2 - 1, pi) == 3 { a2 += 1 }
                    var p1 = 0; while cell(ai, pi + p1 + 1) == 3 { p1 += 1 }
                    var p2 = 0; while cell(ai, pi - p2 - 1) == 3 { p2 += 1 }
                    best = Best(ai: ai, pi: pi, score: score, mirrored: mirrored,
                                angleWindow: Double(a1 + a2 + 1) * angleStep, powerWindow: Double(p1 + p2 + 1) * powerStep)
                }
            }
            if any {
                if let last = regions.last, last.hi == ai - 1 { regions[regions.count - 1].hi = ai } else { regions.append((ai, ai)) }
            }
        }
        for r in regions.prefix(6) {
            var pLo = powerCount, pHi = 0
            for ai in r.lo...r.hi { for pi in 0..<powerCount where cell(ai, pi) == 3 { pLo = min(pLo, pi); pHi = max(pHi, pi) } }
            print(String(format: "            angles %6.2f…%6.2f°  power %3.0f…%3.0f%%",
                         Double(r.lo) * angleStep, Double(r.hi) * angleStep, Double(pLo + 1) * powerStep * 100, Double(pHi + 1) * powerStep * 100))
        }
        if regions.count > 6 { print("            … \(regions.count - 6) more regions") }
    }

    // Rough par guide: a hole you can ace from the tee fairly often is a par 2.
    print(String(format: "  hole A ace %.2f%% → suggested par %d    hole B ace %.2f%% → suggested par %d",
                 holeAce[0], holeAce[0] >= 0.25 ? 2 : 3, holeAce[1], holeAce[1] >= 0.25 ? 2 : 3))
    if let b = best {
        print(String(format: "  best: window %.2f° x %.0f%% power (neighbourhood %d/81)", b.angleWindow, b.powerWindow * 100, b.score))
        print(String(format: "  level.solution = Shot(angle: %.2f, power: %.3f, mirrored: %@)",
                     Double(b.ai) * angleStep, Double(b.pi + 1) * powerStep, b.mirrored ? "true" : "false"))
    } else {
        print("  NO DOUBLE ACE")
    }
}
