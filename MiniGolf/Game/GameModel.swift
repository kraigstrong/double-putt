import Foundation
import Observation
import UIKit

enum Medal: Int, Comparable {
    case none, bronze, silver, gold

    /// Gold = double ace, silver = under par, bronze = par.
    init(score: Int?, par: Int) {
        guard let score else { self = .none; return }
        if score <= 2 { self = .gold } else if score < par { self = .silver } else if score == par { self = .bronze } else { self = .none }
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

/// A round of the whole course, saved so it survives relaunches.
struct RoundState: Codable, Equatable {
    var scores: [Int?]
    var current = 0
}

enum TutorialStep: Int {
    case aim, mirror, putt

    var text: String {
        switch self {
        case .aim: return "Drag anywhere and pull back to aim. Both balls get the shot."
        case .mirror: return "Tap Mirror. The side you drag on aims exactly; the other ball flips."
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
    var paused = false
    var tutorial: TutorialStep?
    /// Where the course sits on screen (scene/view points), so HUD pieces can hug it.
    var courseFrame: CGRect = .zero
    /// Bumped when a pair is entered (not on retry), e.g. to flash the hint.
    private(set) var loadToken = 0
    private(set) var newBest = false
    /// The current round (nil when playing single pairs from the course map).
    private(set) var round: RoundState? = {
        guard let data = UserDefaults.standard.data(forKey: "round") else { return nil }
        return try? JSONDecoder().decode(RoundState.self, from: data)
    }()
    /// True while this session is playing the round (vs. a single pair).
    private(set) var inRound = false
    private(set) var bestRound: Int? = UserDefaults.standard.object(forKey: "bestRound") as? Int
    var showScorecard = false
    private(set) var newBestRound = false
    var fullPathGuide = false
    private(set) var devMode = UserDefaults.standard.bool(forKey: "devMode")
    private(set) var bests: [String: Int] = UserDefaults.standard.dictionary(forKey: "bests") as? [String: Int] ?? [:]
    private(set) var tutorialDone = UserDefaults.standard.bool(forKey: "tutorialDone")

    /// Screen area (points) covered by HUD; the scene fits the course into what's left.
    @ObservationIgnored var insets: UIEdgeInsets = .zero {
        didSet { if insets != oldValue { scene?.layoutInsets = insets } }
    }

    @ObservationIgnored weak var scene: GameScene?
    /// First swing of the last attempt, restored on Retry so you can tweak it.
    @ObservationIgnored var lastOpeningShot: Shot?

    static var levels = Levels.course
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
    var coursePar: Int { Self.levels.reduce(0) { $0 + par(of: $1) } }

    /// Round score relative to par over the pairs finished so far.
    var roundToPar: Int? {
        guard let round else { return nil }
        let done = zip(round.scores, Self.levels).compactMap { s, l in s.map { $0 - par(of: l) } }
        return done.isEmpty ? nil : done.reduce(0, +)
    }

    var roundTotal: Int? {
        guard let round, round.scores.allSatisfy({ $0 != nil }) else { return nil }
        return round.scores.compactMap { $0 }.reduce(0, +)
    }

    static func toPar(_ n: Int) -> String { n == 0 ? "E" : n > 0 ? "+\(n)" : "\(n)" }

    // MARK: Round

    func startRound() {
        round = RoundState(scores: Array(repeating: nil, count: levelCount))
        saveRound()
        inRound = true
        showScorecard = false
        start(level: 0)
    }

    func continueRound() {
        guard let round else { return startRound() }
        inRound = true
        start(level: min(round.current, levelCount - 1))
    }

    /// Leave the round in place (it can be continued later) and play single pairs.
    func leaveRound() { inRound = false }

    func nextInRound() {
        guard var r = round else { return next() }
        r.current = levelIndex + 1
        round = r
        saveRound()
        if r.current >= levelCount {
            finishRound()
        } else {
            start(level: r.current)
        }
    }

    private func finishRound() {
        guard let total = round?.scores.compactMap({ $0 }).reduce(0, +) else { return }
        newBestRound = bestRound == nil || total < bestRound!
        if newBestRound {
            bestRound = total
            UserDefaults.standard.set(total, forKey: "bestRound")
        }
        showResult = false
        showScorecard = true
    }

    /// Close the finished round's scorecard.
    func closeScorecard() {
        showScorecard = false
        if let round, round.current >= levelCount {
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
        if levelIndex == 0 && !tutorialDone {
            tutorial = .aim
        } else if level.name == "Reflection" && !UserDefaults.standard.bool(forKey: "mirrorTaught") {
            tutorial = .mirror
        } else {
            tutorial = nil
        }
        scene?.loadLevel()
        loadToken += 1
    }

    func restart() {
        paused = false
        scene?.loadLevel()
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
        tutorialDone = true
        UserDefaults.standard.set(true, forKey: "tutorialDone")
        UserDefaults.standard.set(true, forKey: "mirrorTaught")
    }

    func finishedAiming() {
        guard tutorial == .aim, aim != nil else { return }
        tutorial = level.solution?.mirrored == true && !mirrored ? .mirror : .putt
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
    }

    func toggleDevMode() {
        devMode.toggle()
        UserDefaults.standard.set(devMode, forKey: "devMode")
        if !devMode { fullPathGuide = false }
    }

    func replayTutorial() {
        tutorialDone = false
        UserDefaults.standard.set(false, forKey: "tutorialDone")
        start(level: 0)
    }

    func demo() {
        paused = false
        scene?.playDemo()
    }

    func recordFinish() {
        if inRound, var r = round, levelIndex < r.scores.count {
            r.scores[levelIndex] = total
            round = r
            saveRound()
        }
        newBest = best == nil || total < best!
        if newBest {
            bests[level.name] = total
            UserDefaults.standard.set(bests, forKey: "bests")
        }
    }

    func resetProgress() {
        round = nil
        bestRound = nil
        UserDefaults.standard.removeObject(forKey: "round")
        UserDefaults.standard.removeObject(forKey: "bestRound")
        bests = [:]
        UserDefaults.standard.removeObject(forKey: "bests")
        tutorialDone = false
        UserDefaults.standard.set(false, forKey: "tutorialDone")
        UserDefaults.standard.set(false, forKey: "mirrorTaught")
    }
}
