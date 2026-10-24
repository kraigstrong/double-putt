import Foundation

// Brute-force every first swing (angle x power x same/mirror) for each level and report what happens.
// Usage: Tools/solve.sh [pair name filter] [--course <name>] [--fine] [--candidates] [--drafts]
//        [--report | --readme | --verify | --timing | --probe <angle>]
//   (default)  full stats per pair: double-ace %, regions, per-side ace % and a suggested par, the most robust ace
//   --report   one line per pair (difficulty, window, par check, mechanics) plus a summary per course
//   --readme   the README's course tables, as markdown
//   --verify   every stored solution still double-aces; tees clear of movers; nine pairs per course; unique names
//   --timing   mover pairs: how exact the putt's timing has to be
// Movers never stop, so every search strikes at the movers' start pose (clock 0) unless noted.
//        LEVELS=Tools/levels/x.swift Tools/solve.sh --drafts   (levels in a scratch file's `Levels.drafts`)

let args = Array(CommandLine.arguments.dropFirst())
let valueFlags: Set<String> = ["--probe", "--course"]

func value(of flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    return args[i + 1]
}

/// Arguments that aren't flags or a flag's value.
let positional: [String] = {
    var out: [String] = []
    var i = 0
    while i < args.count {
        if valueFlags.contains(args[i]) { i += 2; continue }
        if !args[i].hasPrefix("--") { out.append(args[i]) }
        i += 1
    }
    return out
}()

let fine = args.contains("--fine")
let filter = positional.first?.lowercased()
let courseFilter = value(of: "--course")?.lowercased()

let angleStep = fine ? 0.1 : 0.25
let powerStep = fine ? 0.005 : 0.01
let angleCount = Int((360 / angleStep).rounded())
let powerCount = Int((1 / powerStep).rounded())

struct Best { var ai: Int; var pi: Int; var score: Int; var mirrored: Bool; var angleWindow: Double; var powerWindow: Double }

/// Runs `body` for 0..<n on at most SOLVER_THREADS threads (every core by default), so several solver runs at once
/// can share a machine without swamping it.
func parallel(_ n: Int, _ body: (Int) -> Void) {
    let cap = Int(ProcessInfo.processInfo.environment["SOLVER_THREADS"] ?? "") ?? ProcessInfo.processInfo.activeProcessorCount
    let threads = max(1, min(n, cap))
    DispatchQueue.concurrentPerform(iterations: threads) { t in
        for i in stride(from: t, to: n, by: threads) { body(i) }
    }
}

/// Grid of results, bit 0 = A sank, bit 1 = B sank, bit 2 = balls touched, bit 3 = a ball used the other side's cup.
/// Also returns how many shots found water.
func solve(_ level: Level, mirrored: Bool) -> (grid: [UInt8], splashes: Int) {
    let world = World(level: level)
    var grid = [UInt8](repeating: 0, count: angleCount * powerCount)
    var splashCount = [Int](repeating: 0, count: angleCount)
    grid.withUnsafeMutableBufferPointer { cells in
        let cellsPtr = cells
        splashCount.withUnsafeMutableBufferPointer { splashes in
            let splashPtr = splashes
            parallel(angleCount) { ai in
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

/// The grid's outcome (bits 0–1) at an angle/power index; angles wrap, powers don't.
func cell(_ grid: [UInt8], _ ai: Int, _ pi: Int) -> UInt8 {
    guard pi >= 0, pi < powerCount else { return 0 }
    return grid[((ai % angleCount + angleCount) % angleCount) * powerCount + pi] & 3
}

/// The double ace with the most double-ace neighbours (the most forgiving one), if it beats `best`.
func mostRobust(_ grid: [UInt8], mirrored: Bool, beating best: Best?) -> Best? {
    var best = best
    for ai in 0..<angleCount {
        for pi in 0..<powerCount where cell(grid, ai, pi) == 3 {
            var score = 0
            for da in -4...4 { for dp in -4...4 where cell(grid, ai + da, pi + dp) == 3 { score += 1 } }
            guard best == nil || score > best!.score else { continue }
            var a1 = 0; while a1 < 400, cell(grid, ai + a1 + 1, pi) == 3 { a1 += 1 }
            var a2 = 0; while a2 < 400, cell(grid, ai - a2 - 1, pi) == 3 { a2 += 1 }
            var p1 = 0; while cell(grid, ai, pi + p1 + 1) == 3 { p1 += 1 }
            var p2 = 0; while cell(grid, ai, pi - p2 - 1) == 3 { p2 += 1 }
            best = Best(ai: ai, pi: pi, score: score, mirrored: mirrored,
                        angleWindow: Double(a1 + a2 + 1) * angleStep, powerWindow: Double(p1 + p2 + 1) * powerStep)
        }
    }
    return best
}

/// How long (seconds) a shot keeps double-acing when struck earlier or later than `t`, scanning in `step`s.
func timingWindow(_ level: Level, _ shot: Shot, at t: Double, step: Double = 0.005, limit: Double = 1) -> (early: Double, late: Double) {
    func aces(_ t: Double) -> Bool {
        var w = World(level: level)
        w.time = t
        return w.simulate(shot: shot.velocity, mirrored: shot.mirrored).world.allSunk
    }
    var early = 0.0, late = 0.0
    while early < limit, aces(t - early - step) { early += step }
    while late < limit, aces(t + late + step) { late += step }
    return (early, late)
}

extension Level {
    /// Rotors or sliders, whose pose (and so the shot) depends on when you swing. Carousels pull the same way always.
    var hasTimedMovers: Bool { movers.contains { if case .carousel = $0.kind { false } else { true } } }
}

/// How far each ball's stored double ace is aimed off the straight line from its tee to the cup it drops in, in
/// degrees (nil without a solution, or for a ball that doesn't drop). Near zero means "just aim at the cup".
func aimOff(_ l: Level) -> [Double?]? {
    guard let s = l.solution else { return nil }
    var w = World(level: l)
    w.time = l.solutionTime
    let out = w.simulate(shot: s.velocity, mirrored: s.mirrored).world
    return (0..<2).map { b in
        guard let cup = out.balls[b].sunkIn else { return nil }
        let aim = b == 1 && s.mirrored ? 180 - s.angle : s.angle
        let d = l.cups[cup] - l.tees[b]
        let off = (aim - atan2(d.y, d.x) * 180 / .pi + 540).truncatingRemainder(dividingBy: 360) - 180
        return abs(off)
    }
}

/// The mechanics a pair uses, for reports and the README.
func mechanics(_ l: Level) -> String {
    var m: [String] = []
    if !l.water.isEmpty { m.append("water") }
    if !l.bumpers.isEmpty { m.append("bumpers") }
    if !l.stands.isEmpty { m.append("stands") }
    if !l.tunnels.isEmpty { m.append("tunnels") }
    if !l.slopes.isEmpty { m.append("slopes") }
    if l.mounds.contains(where: { $0.strength > 0 }) { m.append("hills") }
    if l.mounds.contains(where: { $0.strength < 0 }) { m.append("bowls") }
    if !l.terrain.isEmpty { m.append("contours") }
    // Painted surfaces other than green, e.g. "fringe, sand".
    for surface in [Surface.fringe, .rough, .sand, .water, .path] where l.patches.contains(where: { $0.surface == surface }) {
        m.append(surface == .water ? "ponds" : surface == .path ? "cart paths" : "\(surface)")
    }
    if l.movers.contains(where: { if case .rotor = $0.kind { true } else { false } }) { m.append("rotors") }
    if l.movers.contains(where: { if case .slider = $0.kind { true } else { false } }) { m.append("sliders") }
    if l.movers.contains(where: { if case .carousel = $0.kind { true } else { false } }) { m.append("carousels") }
    if l.movers.contains(where: { if case .robot = $0.kind { true } else { false } }) { m.append("robots") }
    if l.movers.contains(where: { if case .field = $0.kind { true } else { false } }) { m.append("force fields") }
    if !l.kickers.isEmpty { m.append("kickers") }
    return m.isEmpty ? "—" : m.joined(separator: ", ")
}

#if HAS_DRAFTS
let drafts = Levels.drafts
#else
let drafts: [Level] = []
#endif
let shipped = !args.contains("--drafts") && !args.contains("--candidates")
let levels = args.contains("--drafts") ? drafts
    : args.contains("--candidates") ? Candidates.all
    : Levels.course

/// The course a pair belongs to (nil for drafts and candidates).
func course(of index: Int) -> Nine? { shipped ? Levels.nines.first { $0.pairs.contains(index) } : nil }

/// The pairs chosen by the name filter and --course, with their index in `levels`.
let picked: [(index: Int, level: Level)] = levels.enumerated().compactMap { i, level in
    if let filter, !level.name.lowercased().contains(filter) { return nil }
    if let courseFilter {
        guard let c = course(of: i), c.id == courseFilter || c.name.lowercased().contains(courseFilter) else { return nil }
    }
    return (i, level)
}

// --probe <angle>: outcome at every power for one angle, e.g. Tools/solve.sh twins --probe 90
if let probe = value(of: "--probe"), let angle = Double(probe) {
    for (_, level) in picked {
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
    for (_, level) in picked {
        guard let shot = level.solution else { print("✗ \(level.name): no solution"); failed = true; continue }
        var world = World(level: level)
        world.time = level.solutionTime
        let ok = world.simulate(shot: shot.velocity, mirrored: shot.mirrored).world.allSunk
        // A tee in a mover's path would get relief before the first swing.
        let teesClear = !level.tees.contains { world.inMoverPath($0) }
        // A green or its fringe run up to a rail looks cut off by the frame.
        let roomy = level.greenClearance >= Level.greenMargin
        // A tee on a bank too steep to hold a ball would roll away before the first putt.
        let teesHold = !level.tees.contains { world.tooSteep(at: $0, on: level.surface(at: $0), leaning: nil) != nil }
        failed = failed || !ok || !teesClear || !roomy || !teesHold
        let timing = level.hasTimedMovers ? String(format: " at %.2fs", level.solutionTime) : ""
        print("\(ok ? "✓" : "✗") \(level.name): \(shot.angle)° \(Int(shot.power * 100))%\(shot.mirrored ? " mirror" : "")\(timing)"
              + (teesClear ? "" : "  ✗ a tee is in a mover's path")
              + (roomy ? "" : String(format: "  ✗ a green comes within %.0f of a wall (needs %.0f)", level.greenClearance, Level.greenMargin))
              + (teesHold ? "" : "  ✗ a tee is on a bank too steep to hold a ball"))
    }
    // Bests and trophies are saved by pair name, and a round is nine pairs.
    if shipped && filter == nil && courseFilter == nil {
        let names = Dictionary(grouping: Levels.course, by: \.name).filter { $0.value.count > 1 }.keys.sorted()
        for name in names { print("✗ more than one pair is called \(name)"); failed = true }
        for nine in Levels.nines where nine.pairs.count != 9 {
            print("✗ \(nine.name) has \(nine.pairs.count) pairs, not 9"); failed = true
        }
    }
    exit(failed ? 1 : 0)
}

// --readme: the README's course tables.
if args.contains("--readme") {
    for nine in shipped ? Levels.nines : [] {
        let pairs = picked.filter { nine.pairs.contains($0.index) }
        guard !pairs.isEmpty else { continue }
        let par = nine.pairs.reduce(0) { $0 + Levels.course[$1].par.reduce(0, +) }
        print("### \(nine.name) (par \(par))\n")
        print("| # | Pair | Setting | Par | Double ace needs | Mechanics |")
        print("| --- | --- | --- | --- | --- | --- |")
        for (i, l) in pairs {
            let needs = l.solution.map { $0.mirrored ? "Mirror" : "Same" } ?? "—"
            print("| \(i - nine.pairs.lowerBound + 1) | \(l.name) | \(Levels.settingNames[l.setting] ?? l.setting) | "
                  + "\(l.par.reduce(0, +)) | \(needs) | \(mechanics(l)) |")
        }
        print("")
    }
    exit(0)
}

// --timing: for pairs with movers, how forgiving the putt's timing is. For the stored solution, the window of
// strike times around its clock time that still double-ace; then across the whole mover cycle (coarse grid),
// how often some double ace exists and the double ace with the widest timing window.
if args.contains("--timing") {
    for (_, level) in picked where level.hasTimedMovers {
        let cycle = level.moverCycle
        print("\(level.name)  (mover cycle \(String(format: "%.2f", cycle))s)")
        if let shot = level.solution {
            let w = timingWindow(level, shot, at: level.solutionTime)
            print(String(format: "  stored solution at %.2fs: double-aces from %+.0f to %+.0f ms (%.0f ms window)",
                         level.solutionTime, -w.early * 1000, w.late * 1000, (w.early + w.late) * 1000 + 5))
        }
        let phases = min(60, Int((cycle / 0.1).rounded(.up)))
        let aStep = 0.5, pStep = 0.02
        let aCount = Int(360 / aStep), pCount = Int(1 / pStep)
        var phasesWithAce = 0
        var best: (shot: Shot, t: Double, window: Double)?
        for k in 0..<phases {
            let t = cycle * Double(k) / Double(phases)
            var world = World(level: level)
            world.time = t
            var found: [Shot] = []
            let lock = NSLock()
            for mirrored in [false, true] {
                parallel(aCount) { ai in
                    for pi in 0..<pCount {
                        let shot = Shot(angle: Double(ai) * aStep, power: Double(pi + 1) * pStep, mirrored: mirrored)
                        if world.simulate(shot: shot.velocity, mirrored: mirrored).world.allSunk {
                            lock.lock(); found.append(shot); lock.unlock()
                        }
                    }
                }
            }
            if !found.isEmpty { phasesWithAce += 1 }
            // Measure the timing window of a few of this phase's aces.
            for shot in found.shuffled().prefix(6) {
                let w = timingWindow(level, shot, at: t, step: 0.01)
                let width = w.early + w.late + 0.01
                if best == nil || width > best!.window { best = (shot, t - w.early + width / 2, width) }
            }
        }
        print(String(format: "  double ace exists at %d of %d strike times across the cycle", phasesWithAce, phases))
        if let b = best {
            print(String(format: "  widest timing found: %.0f ms around %.2fs  Shot(angle: %.2f, power: %.3f, mirrored: %@)",
                         b.window * 1000, b.t, b.shot.angle, b.shot.power, b.shot.mirrored ? "true" : "false"))
        }
    }
    exit(0)
}

// --report: one line per pair, then a summary per course. "Double ace" is the share of all first swings that
// double-ace in the better of Same / Mirror; "window" is the most forgiving ace's angle x power window.
if args.contains("--report") {
    func pad(_ s: String, _ n: Int) -> String { s.count >= n ? s : s + String(repeating: " ", count: n - s.count) }
    print(pad("#", 4) + pad("Course", 13) + pad("Pair", 18) + pad("Par", 6) + pad("Sugg", 6) + pad("Dbl ace", 9)
          + pad("Needs", 8) + pad("Window", 13) + pad("Aim off", 10) + pad("Ace A/B %", 12) + pad("Water", 7) + pad("Timing", 9)
          + "Mechanics")
    var summary: [(course: String, par: Int, aces: [Double])] = []
    for (i, level) in picked {
        var best: Best?
        var both = [0, 0]
        var sideAce = [0.0, 0.0]
        var water = 0.0
        for (m, mirrored) in [false, true].enumerated() {
            let (grid, splashes) = solve(level, mirrored: mirrored)
            let total = Double(grid.count)
            func count(_ v: UInt8) -> Int { grid.reduce(0) { $0 + ($1 & 3 == v ? 1 : 0) } }
            both[m] = count(3)
            sideAce[0] = max(sideAce[0], Double(count(1) + count(3)) / total * 100)
            sideAce[1] = max(sideAce[1], Double(count(2) + count(3)) / total * 100)
            water = max(water, Double(splashes) / total * 100)
            best = mostRobust(grid, mirrored: mirrored, beating: best)
        }
        let ace = Double(both.max()!) / Double(angleCount * powerCount) * 100
        let needs = both[0] == 0 && both[1] == 0 ? "none" : both[1] > both[0] ? "Mirror" : "Same"
        let window = best.map { String(format: "%.2f°×%.0f%%", $0.angleWindow, $0.powerWindow * 100) } ?? "—"
        var timing = "—"
        if level.hasTimedMovers, let shot = level.solution {
            let w = timingWindow(level, shot, at: level.solutionTime)
            timing = String(format: "%.0fms", (w.early + w.late) * 1000 + 5)
        }
        let off = aimOff(level).map { $0.map { $0.map { String(format: "%.0f", $0) } ?? "?" }.joined(separator: "/") + "°" } ?? "—"
        let c = course(of: i)
        let n = c.map { i - $0.pairs.lowerBound + 1 } ?? i + 1
        print(pad("\(n)", 4) + pad(c?.name ?? "draft", 13) + pad(level.name, 18) + pad("\(level.par[0])/\(level.par[1])", 6)
              + pad("\(sideAce[0] >= 0.25 ? 2 : 3)/\(sideAce[1] >= 0.25 ? 2 : 3)", 6) + pad(String(format: "%.3f%%", ace), 9)
              + pad(needs, 8) + pad(window, 13) + pad(off, 10) + pad(String(format: "%.2f/%.2f", sideAce[0], sideAce[1]), 12)
              + pad(String(format: "%.0f%%", water), 7) + pad(timing, 9) + mechanics(level))
        let name = c?.name ?? "draft"
        if summary.last?.course == name {
            summary[summary.count - 1].par += level.par.reduce(0, +)
            summary[summary.count - 1].aces.append(ace)
        } else {
            summary.append((name, level.par.reduce(0, +), [ace]))
        }
    }
    print("")
    for s in summary {
        let ramp = s.aces.map { String(format: "%.3f", $0) }.joined(separator: " → ")
        print("\(s.course): par \(s.par) over \(s.aces.count) pairs · double ace % by pair: \(ramp)")
    }
    exit(0)
}

for (index, level) in picked {
    print("[\(index + 1)] \(level.name)  (\(level.setting), par \(level.par[0])/\(level.par[1]))")
    var best: Best?
    var sideAce = [0.0, 0.0]

    for mirrored in [false, true] {
        let start = Date()
        let (grid, splashes) = solve(level, mirrored: mirrored)
        let total = grid.count
        func count(_ v: UInt8) -> Int { grid.reduce(0) { $0 + ($1 & 3 == v ? 1 : 0) } }
        let caroms = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 4 != 0 ? 1 : 0) }
        let swaps = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 8 != 0 ? 1 : 0) }
        let tunnelAces = grid.reduce(0) { $0 + ($1 & 3 == 3 && $1 & 16 != 0 ? 1 : 0) }
        sideAce[0] = max(sideAce[0], Double(count(1) + count(3)) / Double(total) * 100)
        sideAce[1] = max(sideAce[1], Double(count(2) + count(3)) / Double(total) * 100)
        func pct(_ n: Int) -> String { String(format: "%.3f%%", Double(n) / Double(total) * 100) }
        let both = count(3)
        print("  \(mirrored ? "MIRROR" : "SAME  ")  double ace \(pct(both)) (\(both))   A only \(pct(count(1)))   B only \(pct(count(2)))   water \(pct(splashes))   ball-hit aces \(caroms)   swapped-cup aces \(swaps)   tunnel aces \(tunnelAces)   [\(String(format: "%.1fs", Date().timeIntervalSince(start)))]")

        var regions: [(lo: Int, hi: Int)] = []
        for ai in 0..<angleCount where (0..<powerCount).contains(where: { cell(grid, ai, $0) == 3 }) {
            if let last = regions.last, last.hi == ai - 1 { regions[regions.count - 1].hi = ai } else { regions.append((ai, ai)) }
        }
        for r in regions.prefix(6) {
            var pLo = powerCount, pHi = 0
            for ai in r.lo...r.hi { for pi in 0..<powerCount where cell(grid, ai, pi) == 3 { pLo = min(pLo, pi); pHi = max(pHi, pi) } }
            print(String(format: "            angles %6.2f…%6.2f°  power %3.0f…%3.0f%%",
                         Double(r.lo) * angleStep, Double(r.hi) * angleStep, Double(pLo + 1) * powerStep * 100, Double(pHi + 1) * powerStep * 100))
        }
        if regions.count > 6 { print("            … \(regions.count - 6) more regions") }
        best = mostRobust(grid, mirrored: mirrored, beating: best)
    }

    // Rough par guide: a side you can ace from the tee fairly often is a par 2.
    print(String(format: "  side A ace %.2f%% → suggested par %d    side B ace %.2f%% → suggested par %d",
                 sideAce[0], sideAce[0] >= 0.25 ? 2 : 3, sideAce[1], sideAce[1] >= 0.25 ? 2 : 3))
    if let b = best {
        print(String(format: "  best: window %.2f° x %.0f%% power (neighbourhood %d/81)", b.angleWindow, b.powerWindow * 100, b.score))
        print(String(format: "  level.solution = Shot(angle: %.2f, power: %.3f, mirrored: %@)",
                     Double(b.ai) * angleStep, Double(b.pi + 1) * powerStep, b.mirrored ? "true" : "false"))
    } else {
        print("  NO DOUBLE ACE")
    }
}
