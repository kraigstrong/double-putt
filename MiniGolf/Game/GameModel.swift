import Foundation
import Observation
import UIKit

/// A nine-hole round's medal. (Single holes earn trophies instead, for a double ace.)
enum Medal: Int, Comparable {
    case none, bronze, silver, gold

    static let silverUnder = 4
    static let goldUnder = 8

    /// Bronze at par or better, silver 4 under, gold 8 under.
    init(round score: Int?, par: Int) {
        guard let score else { self = .none; return }
        switch par - score {
        case Self.goldUnder...: self = .gold
        case Self.silverUnder...: self = .silver
        case 0...: self = .bronze
        default: self = .none
        }
    }

    /// The most strokes that still earn this medal.
    func threshold(par: Int) -> Int {
        switch self {
        case .gold: return par - Self.goldUnder
        case .silver: return par - Self.silverUnder
        case .bronze, .none: return par
        }
    }

    var title: String {
        switch self {
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .bronze: return "Bronze"
        case .none: return ""
        }
    }

    static func < (a: Medal, b: Medal) -> Bool { a.rawValue < b.rawValue }
}

extension Nine {
    /// The nines that exist for these holes (debug builds can swap in a short test course).
    static func all(levelCount: Int) -> [Nine] {
        Levels.playable.nines.compactMap { n in
            let holes = n.holes.clamped(to: 0..<levelCount)
            return holes.isEmpty ? nil : Nine(id: n.id, name: n.name, holes: holes)
        }
    }
}

/// A round of one nine, saved so it survives relaunches.
struct RoundState: Codable, Equatable {
    var nine: String
    /// One per hole of the nine.
    var scores: [Int?]
    /// Index within the nine of the hole being played.
    var current = 0

    var isFinished: Bool { current >= scores.count }
    var hasProgress: Bool { current > 0 || scores.contains { $0 != nil } }

    static func load() -> RoundState? {
        guard let data = UserDefaults.standard.data(forKey: "round") else { return nil }
        if let r = try? JSONDecoder().decode(RoundState.self, from: data) { return r }
        // Rounds used to be all 18 holes: carry one in progress over to the nine it's on.
        struct Legacy: Codable { var scores: [Int?]; var current: Int }
        guard let old = try? JSONDecoder().decode(Legacy.self, from: data), old.current < old.scores.count,
              let nine = Nine.all(levelCount: old.scores.count).first(where: { $0.holes.contains(old.current) })
        else { return nil }
        return RoundState(nine: nine.id, scores: nine.holes.map { old.scores[$0] }, current: old.current - nine.holes.lowerBound)
    }
}

enum TutorialStep: Int {
    case aim, mirror, putt

    var text: String {
        switch self {
        case .aim: return "Pull back anywhere to aim. Both balls take the shot."
        case .mirror: return "Tap Mirror. The other ball's shot flips."
        case .putt: return "Fine-tune with ‹ › or the power bar, then tap Putt."
        }
    }
}

/// Game state the UI observes. The scene owns the simulation and writes results here.
@MainActor
@Observable
final class GameModel {
    var levelIndex = 0
    var strokes = [0, 0]
    var sunk = [false, false]
    private(set) var mirrored = false
    /// Always stored as ball A's shot (what the physics takes); in Mirror, ball B gets it flipped.
    var aim: Shot?
    /// Which ball the player is steering (the side they last dragged on). In Mirror it gets the exact
    /// aim and the other ball the flip; nudges turn this ball.
    var aimSide = 0
    var isRolling = false
    var isDemo = false
    var showResult = false
    var paused = false {
        didSet { if paused != oldValue { analytics.setPaused(paused) } }
    }
    var tutorial: TutorialStep?
    /// Where the course sits on screen (scene/view points), so HUD pieces can hug it.
    var courseFrame: CGRect = .zero
    /// The course is turned a quarter to fill a wide screen (a Duo opened, an iPad on its side): tees on the left,
    /// one green above the other.
    var courseTurned = false
    /// Bumped when a hole is entered (not on retry), e.g. to flash the hint.
    private(set) var loadToken = 0
    private(set) var newBest = false
    /// The last finish double-aced a hole for the first time.
    private(set) var newTrophy = false
    /// The round in progress, if any (it's kept while playing single holes).
    private(set) var round: RoundState? = RoundState.load()
    /// True while this session is playing the round (vs. a single hole).
    private(set) var inRound = false
    /// Best finished round per nine (by id).
    private(set) var bestRounds: [String: Int] = UserDefaults.standard.dictionary(forKey: "bestRounds") as? [String: Int] ?? [:]
    /// Holes double-aced (by name), with when the trophy was won.
    private(set) var trophies: [String: Date] = GameModel.loadTrophies()
    var showScorecard = false
    private(set) var newBestRound = false
    var fullPathGuide = false
    /// Show Ace, the full-path guide and Reset. Xcode builds only: TestFlight and App Store builds don't have it.
    #if DEBUG
    private(set) var devMode = UserDefaults.standard.bool(forKey: "devMode")
    #else
    let devMode = false
    #endif
    private(set) var bests: [String: Int] = UserDefaults.standard.dictionary(forKey: "bests") as? [String: Int] ?? [:]
    private(set) var tutorialDone = UserDefaults.standard.bool(forKey: "tutorialDone")

    /// Screen area (points) covered by HUD, and the safe areas down the sides; the scene fits the course into what's
    /// left.
    @ObservationIgnored var insets: (hud: UIEdgeInsets, sides: UIEdgeInsets) = (.zero, .zero) {
        didSet { if insets != oldValue { scene?.layoutInsets = insets } }
    }

    @ObservationIgnored weak var scene: GameScene?
    @ObservationIgnored let analytics = Analytics()
    /// The All Courses purchase.
    let purchases = Purchases()
    /// The tips were asked for again (How to Play), so they're generic: the Mirror tip doesn't depend on the hole.
    @ObservationIgnored private var replayingTips = false
    /// First swing of the last attempt, restored on Retry so you can tweak it.
    @ObservationIgnored var lastOpeningShot: Shot?

    static var levels = Levels.playable.course
    var level: Level { Self.levels[levelIndex] }
    var theme: Theme { Theme.for(level) }
    var levelCount: Int { Self.levels.count }
    var total: Int { strokes[0] + strokes[1] }
    var par: Int { level.par[0] + level.par[1] }
    var best: Int? { bests[level.name] }
    var isComplete: Bool { sunk[0] && sunk[1] }
    var canAim: Bool { !isRolling && !isDemo && !isComplete && !paused }
    var canPutt: Bool { aim != nil && canAim }
    var isLastLevel: Bool { levelIndex == levelCount - 1 }

    func best(for level: Level) -> Int? { bests[level.name] }
    func par(of level: Level) -> Int { level.par[0] + level.par[1] }
    func hasTrophy(_ level: Level) -> Bool { trophies[level.name] != nil }

    // MARK: Nines

    var nines: [Nine] { Nine.all(levelCount: levelCount) }
    func nine(containing index: Int) -> Nine? { nines.first { $0.holes.contains(index) } }
    func par(of nine: Nine) -> Int { nine.holes.reduce(0) { $0 + par(of: Self.levels[$1]) } }
    func bestRound(_ nine: Nine) -> Int? { bestRounds[nine.id] }
    func medal(_ nine: Nine) -> Medal { Medal(round: bestRound(nine), par: par(of: nine)) }

    /// The course after this one in the list, if any: the scorecard's Up next.
    func nine(after nine: Nine) -> Nine? {
        guard let i = nines.firstIndex(of: nine), i + 1 < nines.count else { return nil }
        return nines[i + 1]
    }

    /// A hole's number within its nine (1–9).
    func holeNumber(_ index: Int) -> Int { index - (nine(containing: index)?.holes.lowerBound ?? 0) + 1 }
    /// The nine the saved round is on.
    var roundNine: Nine? { round.flatMap { r in nines.first { $0.id == r.nine } } }
    /// The last hole of the round being played.
    var isLastInRound: Bool { inRound && levelIndex == (roundNine?.holes.upperBound ?? 0) - 1 }

    /// Round score relative to par over the holes finished so far.
    var roundToPar: Int? {
        guard let round, let nine = roundNine else { return nil }
        let done = zip(round.scores, nine.holes).compactMap { s, i in s.map { $0 - par(of: Self.levels[i]) } }
        return done.isEmpty ? nil : done.reduce(0, +)
    }

    var roundTotal: Int? {
        guard let round, round.scores.allSatisfy({ $0 != nil }) else { return nil }
        return round.scores.compactMap { $0 }.reduce(0, +)
    }

    static func toPar(_ n: Int) -> String { n == 0 ? "E" : n > 0 ? "+\(n)" : "\(n)" }

    // MARK: Round

    func startRound(_ nine: Nine) {
        if let old = round, !old.isFinished, old.hasProgress, let oldNine = roundNine {
            analytics.roundLeft(course: oldNine.id, hole: old.current + 1)
        }
        analytics.roundStarted(course: nine.id)
        round = RoundState(nine: nine.id, scores: Array(repeating: nil, count: nine.holes.count))
        saveRound()
        inRound = true
        showScorecard = false
        start(level: nine.holes.lowerBound)
    }

    func continueRound() {
        guard let round, let nine = roundNine else { return }
        inRound = true
        start(level: nine.holes.lowerBound + min(round.current, nine.holes.count - 1))
    }

    /// Leave the round in place (it can be continued later) and play single holes.
    func leaveRound() {
        if inRound, let r = round, !r.isFinished, let nine = roundNine {
            analytics.roundLeft(course: nine.id, hole: r.current + 1)
        }
        inRound = false
    }

    func nextInRound() {
        guard var r = round, let nine = roundNine else { return next() }
        r.current = levelIndex - nine.holes.lowerBound + 1
        round = r
        saveRound()
        if r.isFinished {
            finishRound()
        } else {
            start(level: nine.holes.lowerBound + r.current)
        }
    }

    private func finishRound() {
        guard let nine = roundNine, let total = round?.scores.compactMap({ $0 }).reduce(0, +) else { return }
        let best = bestRounds[nine.id]
        newBestRound = best == nil || total < best!
        if newBestRound {
            bestRounds[nine.id] = total
            UserDefaults.standard.set(bestRounds, forKey: "bestRounds")
        }
        analytics.roundFinished(course: nine.id, strokes: total, par: par(of: nine),
                                medal: Medal(round: total, par: par(of: nine)), best: newBestRound)
        showResult = false
        showScorecard = true
    }

    /// Close the finished round's scorecard.
    func closeScorecard() {
        showScorecard = false
        if let round, round.isFinished {
            self.round = nil
            UserDefaults.standard.removeObject(forKey: "round")
        }
        inRound = false
    }

    private func saveRound() {
        if let round, let data = try? JSONEncoder().encode(round) {
            UserDefaults.standard.set(data, forKey: "round")
        }
    }

    var resultTitle: String {
        if strokes == [1, 1] { return "Double Ace!" }
        switch total - par {
        case ...(-2): return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        default: return "+\(total - par)"
        }
    }

    // MARK: Actions

    func start(level index: Int) {
        levelIndex = max(0, min(index, levelCount - 1))
        lastOpeningShot = nil
        paused = false
        replayingTips = false
        if levelIndex == 0 && !tutorialDone {
            tutorial = .aim
        } else if level.name == "Reflection" && !UserDefaults.standard.bool(forKey: "mirrorTaught") {
            // Opened straight from Free Play on a fresh install: teach aiming first; the Mirror tip follows the drag.
            tutorial = tutorialDone ? .mirror : .aim
        } else {
            tutorial = nil
        }
        scene?.loadLevel()
        loadToken += 1
        analytics.holeStarted(holeContext, mode: inRound ? "round" : "single", par: par)
    }

    /// Start the hole over. Free Play only: a round is played as it lies.
    func restart() {
        guard !inRound else { return }
        paused = false
        scene?.loadLevel()
        analytics.holeStarted(holeContext, mode: inRound ? "round" : "single", par: par)
        if let shot = lastOpeningShot, tutorial == nil {
            setMirrored(shot.mirrored)
            aim = shot
        }
    }

    func next() { start(level: levelIndex + 1) }

    func setMirrored(_ on: Bool) {
        guard on != mirrored else { return }
        // Keep the steered ball pointing where it was; only the other ball flips.
        if var a = aim {
            if aimSide == 1 {
                let bAngle = mirrored ? Self.flip(a.angle) : a.angle
                a.angle = on ? Self.flip(bAngle) : bAngle
            }
            a.mirrored = on
            aim = a
        }
        mirrored = on
        if tutorial == .mirror && on {
            tutorial = .putt
            UserDefaults.standard.set(true, forKey: "mirrorTaught")
        }
    }

    func setAim(_ shot: Shot) {
        var s = shot
        s.mirrored = mirrored
        aim = s
    }

    /// The last tip asks you to fine-tune; doing it is enough.
    private func completeTutorialIfFineTuning() {
        if tutorial == .putt { dismissTutorial() }
    }

    func dismissTutorial() {
        tutorial = nil
        replayingTips = false
        tutorialDone = true
        UserDefaults.standard.set(true, forKey: "tutorialDone")
        UserDefaults.standard.set(true, forKey: "mirrorTaught")
    }

    func finishedAiming() {
        guard tutorial == .aim, aim != nil else { return }
        let teachMirror = replayingTips || level.solution?.mirrored == true
        tutorial = teachMirror && !mirrored ? .mirror : .putt
    }

    /// Left-right flip of a direction in degrees.
    static func flip(_ angle: Double) -> Double {
        let a = (180 - angle).truncatingRemainder(dividingBy: 360)
        return a < 0 ? a + 360 : a
    }

    func nudge(angle: Double = 0, power: Double = 0) {
        guard canAim else { return }
        completeTutorialIfFineTuning()
        var a = aim ?? Shot(angle: 90, power: 0.5, mirrored: mirrored)
        // Turning the steered ball counter-clockwise turns ball A clockwise when B is steered in Mirror.
        let d = mirrored && aimSide == 1 ? -angle : angle
        a.angle = (a.angle + d).truncatingRemainder(dividingBy: 360)
        if a.angle < 0 { a.angle += 360 }
        a.power = min(max(a.power + power, 0.02), 1)
        a.mirrored = mirrored
        aim = a
    }

    /// Set power directly (power bar drag). Starts a straight-up aim if there isn't one yet.
    func setPower(_ p: Double) {
        guard canAim else { return }
        completeTutorialIfFineTuning()
        var a = aim ?? Shot(angle: 90, power: p, mirrored: mirrored)
        a.power = min(max(p, 0.02), 1)
        a.mirrored = mirrored
        aim = a
    }

    func putt() {
        guard let shot = aim, canPutt else { return }
        if total == 0 { lastOpeningShot = shot }
        if tutorial == .putt || tutorial == .mirror || tutorial == .aim {
            tutorial = nil
            tutorialDone = true
            UserDefaults.standard.set(true, forKey: "tutorialDone")
        }
        scene?.putt(shot)
        analytics.swing(mirrored: shot.mirrored, strokes: strokes, sunk: sunk)
    }

    /// The game screen closed: an unfinished hole counts as quit.
    func leftGame() { analytics.holeLeft() }

    /// Which hole this is, for analytics.
    var holeContext: HoleContext {
        HoleContext(course: nine(containing: levelIndex)?.id ?? "unknown", hole: holeNumber(levelIndex),
                    slug: Self.slug(level.name), revision: Levels.revision)
    }

    /// "Merry-Go-Round" → "merry-go-round".
    static func slug(_ name: String) -> String {
        let dashed = name.lowercased().map { $0.isASCII && ($0.isLetter || $0.isNumber) ? String($0) : "-" }.joined()
        return String(dashed.split(separator: "-").joined(separator: "-").prefix(48))
    }

    func toggleDevMode() {
        #if DEBUG
        devMode.toggle()
        UserDefaults.standard.set(devMode, forKey: "devMode")
        if !devMode { fullPathGuide = false }
        #endif
    }

    /// Show the tips again on the hole being played; the hole and the round carry on untouched.
    func replayTutorial() {
        paused = false
        replayingTips = true
        tutorial = .aim
    }

    func demo() {
        paused = false
        analytics.holeDiscarded()
        scene?.playDemo()
    }

    /// Score the finished hole. A dev-mode Show Ace still fills in the round, but earns no best or trophy.
    func recordFinish(demo: Bool = false) {
        if inRound, var r = round, let nine = roundNine, nine.holes.contains(levelIndex) {
            r.scores[levelIndex - nine.holes.lowerBound] = total
            round = r
            saveRound()
        }
        newBest = false
        newTrophy = false
        guard !demo else { return }
        analytics.holeFinished(strokes: strokes)
        newBest = best == nil || total < best!
        if newBest {
            bests[level.name] = total
            UserDefaults.standard.set(bests, forKey: "bests")
        }
        if strokes == [1, 1] && trophies[level.name] == nil {
            trophies[level.name] = Date()
            newTrophy = true
            saveTrophies()
        }
    }

    private static func loadTrophies() -> [String: Date] {
        let d = UserDefaults.standard
        if let saved = d.dictionary(forKey: "trophies") as? [String: Double] {
            return saved.mapValues { Date(timeIntervalSince1970: $0) }
        }
        // Before trophies, a best of 2 was a double ace: those holes start with their trophy.
        let bests = d.dictionary(forKey: "bests") as? [String: Int] ?? [:]
        let earned = bests.filter { $0.value <= 2 }.mapValues { _ in Date() }
        d.set(earned.mapValues { $0.timeIntervalSince1970 }, forKey: "trophies")
        return earned
    }

    private func saveTrophies() {
        UserDefaults.standard.set(trophies.mapValues { $0.timeIntervalSince1970 }, forKey: "trophies")
    }

    func resetProgress() {
        round = nil
        bestRounds = [:]
        trophies = [:]
        UserDefaults.standard.removeObject(forKey: "round")
        UserDefaults.standard.removeObject(forKey: "bestRounds")
        saveTrophies()
        bests = [:]
        UserDefaults.standard.removeObject(forKey: "bests")
        tutorialDone = false
        UserDefaults.standard.set(false, forKey: "tutorialDone")
        UserDefaults.standard.set(false, forKey: "mirrorTaught")
    }
}
