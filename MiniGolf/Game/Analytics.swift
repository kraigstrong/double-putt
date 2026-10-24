import Foundation

// Anonymous gameplay counts, sent to brightbench.app. The contract (every field and rule the server checks) is
// docs/analytics.md; change both together. Modeled on Bigger Fish's ArcadeAnalytics. No user, install, session or
// device IDs and no timestamps are sent: per-install facts (first launch, pairs finished, attempt counts) stay on
// the device and only decide what to send.

/// Which pair, by course, number, name and content revision.
struct PairContext: Codable, Equatable {
    let course: String
    let pair: Int
    let slug: String
    let revision: String
}

struct AnalyticsEvent: Codable, Equatable {
    enum Kind: String, Codable { case milestone, pair, round }

    /// A pair attempt's strokes per side, or a finished round's total.
    enum Strokes: Codable, Equatable {
        case sides([Int])
        case total(Int)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let sides = try? c.decode([Int].self) { self = .sides(sides) } else { self = .total(try c.decode(Int.self)) }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .sides(let sides): try c.encode(sides)
            case .total(let total): try c.encode(total)
            }
        }
    }

    let kind: Kind
    // Fields left nil aren't encoded, so each kind sends exactly its own fields.
    var name: String?
    var action: String?
    var course: String?
    var revision: String?
    var context: PairContext?
    var mode: String?
    var outcome: String?
    var replay: Bool?
    var attempt: Int?
    var strokes: Strokes?
    var par: Int?
    var swings: Int?
    var mirrorSwings: Int?
    var water: Int?
    var aces: Int?
    var doubleAce: Bool?
    var seconds: Int?
    var first: Bool?
    var pair: Int?
    var medal: String?
    var best: Bool?
}

struct AnalyticsBatch: Codable {
    var schema = 1
    let appVersion: String
    let build: String
    let channel: String
    let events: [AnalyticsEvent]
}

protocol AnalyticsSender {
    func send(_ batch: AnalyticsBatch)
}

/// All calls come from the main thread.
final class Analytics {
    static let isEnabled = true
    static let endpoint = URL(string: "https://brightbench.app/api/double-putt/events")!
    /// A public noise filter, not authentication: the server's strict validation is the protection.
    static let appKey = "double-putt-gameplay-v1"

    static var defaultEnabled: Bool {
        #if DEBUG
        // Launch-argument runs (a set pair, art dumps, the mechanic test pairs) aren't real play.
        let d = UserDefaults.standard
        if d.integer(forKey: "level") > 0 || d.bool(forKey: "dumpArt") || d.bool(forKey: "tests") { return false }
        #endif
        return isEnabled
    }

    /// Where this build came from: "debug" (an Xcode build), "testflight" or "appstore".
    static var channel: String {
        #if DEBUG
        "debug"
        #else
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "testflight" : "appstore"
        #endif
    }

    private struct Queued: Codable {
        var event: AnalyticsEvent
        let appVersion: String
        let build: String
        let channel: String
    }

    /// The pair attempt in progress, saved after each swing so one cut short by the app closing is sent as
    /// `abandoned` on the next launch.
    private struct Attempt: Codable {
        var context: PairContext
        var mode: String
        var par: Int
        var swings = 0
        var mirrorSwings = 0
        var water = 0
        var seconds = 0
        var strokes = [0, 0]
        var sunk = [false, false]
        var stamp: Queued?
    }

    let enabled: Bool
    private let defaults: UserDefaults
    private let sender: AnalyticsSender
    private let prefix = "doublePutt.metrics.v1."
    private var attempt: Attempt?
    /// Time on the current attempt counts only while it's in play: paused (or away from the app) doesn't count.
    private var playedBefore: TimeInterval = 0
    private var playingSince: Date?

    init(defaults: UserDefaults = .standard, sender: AnalyticsSender = URLAnalyticsSender(), enabled: Bool = Analytics.defaultEnabled) {
        self.defaults = defaults
        self.sender = sender
        self.enabled = enabled
    }

    // MARK: Lifecycle

    func launched() {
        guard enabled else { return }
        milestone("first_launch", scope: "install")
        if let data = defaults.data(forKey: prefix + "attempt"), let old = try? JSONDecoder().decode(Attempt.self, from: data) {
            finish(old, outcome: "abandoned")
        }
        defaults.removeObject(forKey: prefix + "attempt")
        // Anything queued last time but not sent (the app closed first) goes now.
        DispatchQueue.main.async { [weak self] in self?.flush() }
    }

    /// The app went to the background: send what's queued rather than wait (a player may not come back).
    func backgrounded() {
        guard enabled else { return }
        flush()
    }

    // MARK: Pairs

    /// A pair was loaded (started fresh, retried or restarted). Any attempt still open ends as `quit`.
    func pairStarted(_ context: PairContext, mode: String, par: Int) {
        guard enabled else { return }
        pairLeft()
        attempt = Attempt(context: context, mode: mode, par: par)
        playedBefore = 0
        playingSince = Date()
    }

    /// The pause menu opened or closed (leaving the app opens it).
    func setPaused(_ paused: Bool) {
        if paused, let since = playingSince {
            playedBefore += Date().timeIntervalSince(since)
            playingSince = nil
        } else if !paused, playingSince == nil {
            playingSince = Date()
        }
    }

    /// A swing was struck; `strokes` already counts it, so an attempt cut short mid-roll is saved with it.
    func swing(mirrored: Bool, strokes: [Int], sunk: [Bool]) {
        guard enabled, attempt != nil else { return }
        attempt?.swings += 1
        if mirrored { attempt?.mirrorSwings += 1 }
        attempt?.strokes = strokes
        attempt?.sunk = sunk
        checkpoint()
    }

    func splashed() {
        guard enabled, attempt != nil else { return }
        attempt?.water += 1
    }

    /// The swing's balls settled: keep the strokes so far, for a quit or an abandoned attempt.
    func settled(strokes: [Int], sunk: [Bool]) {
        guard enabled, attempt != nil else { return }
        attempt?.strokes = strokes
        attempt?.sunk = sunk
        checkpoint()
    }

    /// Both balls are in.
    func pairFinished(strokes: [Int]) {
        guard enabled, var a = attempt else { return }
        a.strokes = strokes
        a.sunk = [true, true]
        a.seconds = elapsed
        attempt = nil
        defaults.removeObject(forKey: prefix + "attempt")
        finish(a, outcome: "finished")
        DispatchQueue.main.async { [weak self] in self?.flush() }
    }

    /// The pair was left unfinished (Restart, moving on, or leaving the game screen).
    func pairLeft() {
        guard enabled, var a = attempt else { return }
        a.seconds = elapsed
        attempt = nil
        defaults.removeObject(forKey: prefix + "attempt")
        finish(a, outcome: "quit")
    }

    /// A dev-mode demo replaced the attempt: it isn't real play, so nothing is sent.
    func pairDiscarded() {
        attempt = nil
        defaults.removeObject(forKey: prefix + "attempt")
    }

    private var elapsed: Int {
        let played = playedBefore + (playingSince.map { Date().timeIntervalSince($0) } ?? 0)
        return min(3600, max(0, Int(played.rounded())))
    }

    private func checkpoint() {
        guard var a = attempt else { return }
        a.seconds = elapsed
        if a.stamp == nil { a.stamp = stamp(AnalyticsEvent(kind: .pair)) }
        attempt = a
        defaults.set(try? JSONEncoder().encode(a), forKey: prefix + "attempt")
    }

    private func key(_ c: PairContext) -> String { "\(c.revision).\(c.course).\(c.slug)" }

    /// Sends the attempt, if a swing was taken (loading a pair and leaving isn't an attempt).
    private func finish(_ a: Attempt, outcome: String) {
        guard a.swings > 0 else { return }
        let k = key(a.context)
        let replay = defaults.bool(forKey: prefix + "cleared." + k)
        var number = 0
        if !replay {
            number = min(1000, defaults.integer(forKey: prefix + "attempts." + k) + 1)
            defaults.set(number, forKey: prefix + "attempts." + k)
        }
        let finished = outcome == "finished"
        let strokes = a.strokes.map { min(99, max(0, $0)) }
        let aces = zip(strokes, a.sunk).filter { $0.0 == 1 && $0.1 }.count
        let swings = min(200, a.swings)
        var event = AnalyticsEvent(kind: .pair)
        event.context = a.context
        event.mode = a.mode
        event.outcome = outcome
        event.replay = replay
        event.attempt = number
        event.strokes = .sides(strokes)
        event.par = min(12, max(2, a.par))
        event.swings = swings
        event.mirrorSwings = min(swings, a.mirrorSwings)
        event.water = min(200, a.water)
        event.aces = aces
        event.doubleAce = finished && strokes == [1, 1]
        event.seconds = a.seconds
        // An abandoned attempt keeps the app version it was played on.
        var queued = a.stamp ?? stamp(event)
        queued.event = event
        enqueue(queued)
        if finished {
            defaults.set(true, forKey: prefix + "cleared." + k)
            milestone("pair_finished", scope: k, context: a.context)
            if strokes == [1, 1] { milestone("trophy_won", scope: k, context: a.context) }
        }
    }

    // MARK: Rounds and unlocks

    func roundStarted(course: String) {
        guard enabled else { return }
        let firstKey = prefix + "round.started." + course
        var event = AnalyticsEvent(kind: .round)
        event.action = "started"
        event.course = course
        event.revision = Levels.revision
        event.first = !defaults.bool(forKey: firstKey)
        defaults.set(true, forKey: firstKey)
        enqueue(stamp(event))
    }

    /// Leave Round, or a new round replacing an unfinished one. `pair` is the round's pair (1–9) when it was left.
    func roundLeft(course: String, pair: Int) {
        guard enabled else { return }
        var event = AnalyticsEvent(kind: .round)
        event.action = "left"
        event.course = course
        event.revision = Levels.revision
        event.pair = min(9, max(1, pair))
        enqueue(stamp(event))
    }

    func roundFinished(course: String, strokes: Int, par: Int, medal: Medal, best: Bool) {
        guard enabled else { return }
        var event = AnalyticsEvent(kind: .round)
        event.action = "finished"
        event.course = course
        event.revision = Levels.revision
        event.strokes = .total(min(999, max(9, strokes)))
        event.par = min(108, max(18, par))
        event.medal = switch medal {
        case .none: "none"
        case .bronze: "bronze"
        case .silver: "silver"
        case .gold: "gold"
        }
        event.best = best
        enqueue(stamp(event))
        DispatchQueue.main.async { [weak self] in self?.flush() }
    }

    /// A medal opened the next course.
    func courseUnlocked(_ course: String) {
        guard enabled else { return }
        var event = AnalyticsEvent(kind: .milestone)
        event.name = "course_unlocked"
        event.course = course
        event.revision = Levels.revision
        once("course_unlocked." + course, event)
    }

    // MARK: Queue

    private func milestone(_ name: String, scope: String, context: PairContext? = nil) {
        var event = AnalyticsEvent(kind: .milestone)
        event.name = name
        event.context = context
        once(name + "." + scope, event)
    }

    private func once(_ key: String, _ event: AnalyticsEvent) {
        let k = prefix + "milestone." + key
        guard !defaults.bool(forKey: k) else { return }
        defaults.set(true, forKey: k)
        enqueue(stamp(event))
    }

    private func stamp(_ event: AnalyticsEvent) -> Queued {
        let info = Bundle.main.infoDictionary
        return Queued(event: event,
                      appVersion: info?["CFBundleShortVersionString"] as? String ?? "0.1",
                      build: info?["CFBundleVersion"] as? String ?? "1",
                      channel: Self.channel)
    }

    private var stored: [Queued] {
        defaults.data(forKey: prefix + "queue").flatMap { try? JSONDecoder().decode([Queued].self, from: $0) } ?? []
    }

    /// What's waiting to be sent (for checks and debugging).
    var queue: [AnalyticsEvent] { stored.map(\.event) }

    private func enqueue(_ queued: Queued) {
        defaults.set(try? JSONEncoder().encode(Array((stored + [queued]).suffix(100))), forKey: prefix + "queue")
    }

    /// At-most-once delivery: the queue is cleared before sending, and failed batches are dropped, never retried.
    func flush() {
        guard enabled else { return }
        let events = stored
        guard !events.isEmpty else { return }
        defaults.removeObject(forKey: prefix + "queue")
        let groups = Dictionary(grouping: events) { "\($0.channel):\($0.appVersion):\($0.build)" }
        for group in groups.values {
            guard let first = group.first else { continue }
            for offset in stride(from: 0, to: group.count, by: 25) {
                sender.send(AnalyticsBatch(appVersion: first.appVersion, build: first.build, channel: first.channel,
                                           events: group[offset..<min(offset + 25, group.count)].map(\.event)))
            }
        }
    }
}

struct URLAnalyticsSender: AnalyticsSender {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.urlCredentialStorage = nil
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
    /// Encoding and starting the request happen off the main thread, so a send never costs a frame.
    private static let queue = DispatchQueue(label: "doublePutt.metrics.send", qos: .utility)

    func send(_ batch: AnalyticsBatch) {
        Self.queue.async {
            guard let data = try? JSONEncoder().encode(batch) else { return }
            var request = URLRequest(url: Analytics.endpoint)
            request.httpMethod = "POST"
            request.httpBody = data
            request.timeoutInterval = 15
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Analytics.appKey, forHTTPHeaderField: "X-App-Key")
            Self.session.dataTask(with: request).resume()
        }
    }
}
