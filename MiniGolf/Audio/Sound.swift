import AVFoundation

/// Procedurally synthesized sound effects. Every sound is generated in code at startup,
/// so there are no audio assets. All calls are expected on the main thread.
final class SoundFX {
    static let shared = SoundFX()

    /// Persisted under "soundOn" (default true). When false every play method is a no-op.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            guard didStart, isEnabled != oldValue else { return }
            if isEnabled {
                startEngine(force: true)
            } else {
                engine?.pause() // save power while muted
            }
        }
    }

    private static let enabledKey = "soundOn"
    private static let poolSize = 10

    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var busyUntil: [TimeInterval] = []
    private var nextPlayer = 0
    private var format: AVAudioFormat?

    private var didStart = false
    private var unavailable = false
    private var lastStartAttempt: TimeInterval = -.infinity
    private var observers: [NSObjectProtocol] = []

    private var puttSoft: [AVAudioPCMBuffer] = []
    private var puttHard: [AVAudioPCMBuffer] = []
    private var wallHits: [AVAudioPCMBuffer] = []
    private var ballClacks: [AVAudioPCMBuffer] = []
    private var cupBuffer: AVAudioPCMBuffer?
    private var splashBuffer: AVAudioPCMBuffer?
    private var aceBuffer: AVAudioPCMBuffer?
    private var doubleAceBuffer: AVAudioPCMBuffer?
    private var goodBuffer: AVAudioPCMBuffer?
    private var neutralBuffer: AVAudioPCMBuffer?
    private var tapBuffer: AVAudioPCMBuffer?
    private var tickBuffer: AVAudioPCMBuffer?

    private var lastWall: TimeInterval = -.infinity
    private var lastTick: TimeInterval = -.infinity

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    // MARK: - Lifecycle

    func start() {
        guard !didStart else { return }
        didStart = true

        configureSession()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1) else {
            unavailable = true
            return
        }
        self.format = format
        synthesizeAll()
        buildGraph()
        observeNotifications()
        if isEnabled {
            startEngine(force: true)
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // Failure here is not fatal; the engine can usually still run with the default session.
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func buildGraph() {
        guard let format else { return }
        engine?.stop()
        let newEngine = AVAudioEngine()
        var nodes: [AVAudioPlayerNode] = []
        for _ in 0..<Self.poolSize {
            let node = AVAudioPlayerNode()
            newEngine.attach(node)
            newEngine.connect(node, to: newEngine.mainMixerNode, format: format)
            nodes.append(node)
        }
        newEngine.mainMixerNode.outputVolume = 0.9
        newEngine.prepare()
        engine = newEngine
        players = nodes
        busyUntil = Array(repeating: 0, count: nodes.count)
        nextPlayer = 0
    }

    /// Starts the engine if needed. Unforced attempts are throttled so a dead audio
    /// system (e.g. mid-interruption) isn't retried on every frame.
    @discardableResult
    private func startEngine(force: Bool = false) -> Bool {
        guard let engine, !unavailable else { return false }
        if engine.isRunning { return true }
        let now = ProcessInfo.processInfo.systemUptime
        guard force || now - lastStartAttempt > 1 else { return false }
        lastStartAttempt = now

        try? AVAudioSession.sharedInstance().setActive(true)
        do {
            try engine.start()
        } catch {
            return false
        }
        for player in players {
            player.stop()
            player.play()
        }
        busyUntil = Array(repeating: 0, count: players.count)
        return true
    }

    private func observeNotifications() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange,
                                            object: nil, queue: .main) { [weak self] note in
            guard let self, let changed = note.object as? AVAudioEngine,
                  changed === self.engine, !changed.isRunning else { return }
            // Hardware format may have changed (route change etc.); rebuild for clean connections.
            self.buildGraph()
            if self.isEnabled { self.startEngine(force: true) }
        })

        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                            object: nil, queue: .main) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended,
                  self.isEnabled else { return }
            self.startEngine(force: true)
        })

        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            // The old engine is unusable after a media server reset.
            self.configureSession()
            self.buildGraph()
            if self.isEnabled { self.startEngine(force: true) }
        })
    }

    // MARK: - Public sounds

    func putt(power: Double) {
        let p = Self.clamp(power)
        play((p >= 0.5 ? puttHard : puttSoft).randomElement(), volume: Self.scaled(p, floor: 0.35))
    }

    func wall(intensity: Double) {
        guard isEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastWall >= 0.04 else { return }
        lastWall = now
        play(wallHits.randomElement(), volume: Self.scaled(intensity, floor: 0.2))
    }

    func ballHit(intensity: Double) {
        play(ballClacks.randomElement(), volume: Self.scaled(intensity, floor: 0.25))
    }

    func cupDrop() { play(cupBuffer, volume: 0.9) }

    func splash() { play(splashBuffer, volume: 0.85) }

    func ace() { play(aceBuffer, volume: 0.85) }

    func doubleAce() { play(doubleAceBuffer, volume: 0.9) }

    func result(good: Bool) {
        play(good ? goodBuffer : neutralBuffer, volume: good ? 0.8 : 0.7)
    }

    func tap() { play(tapBuffer, volume: 0.7) }

    func tick() {
        guard isEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTick >= 0.03 else { return }
        lastTick = now
        play(tickBuffer, volume: 0.55)
    }

    // MARK: - Playback

    private func play(_ buffer: @autoclosure () -> AVAudioPCMBuffer?, volume: Double) {
        guard isEnabled else { return }
        if !didStart { start() }
        guard let buffer = buffer(), let engine, !players.isEmpty else { return }
        if !engine.isRunning && !startEngine() { return }

        let now = ProcessInfo.processInfo.systemUptime
        let index = pickPlayer(now: now)
        let player = players[index]
        player.volume = Float(Self.clamp(volume))
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
        busyUntil[index] = now + Double(buffer.frameLength) / Synth.sampleRate
    }

    /// Round-robin over idle players; if every player is busy, steal the one finishing soonest.
    private func pickPlayer(now: TimeInterval) -> Int {
        let count = players.count
        var chosen: Int?
        for offset in 0..<count {
            let i = (nextPlayer + offset) % count
            if busyUntil[i] <= now {
                chosen = i
                break
            }
        }
        let index = chosen ?? (busyUntil.indices.min { busyUntil[$0] < busyUntil[$1] } ?? 0)
        nextPlayer = (index + 1) % count
        return index
    }

    private static func clamp(_ x: Double) -> Double {
        x.isFinite ? min(1, max(0, x)) : 0
    }

    private static func scaled(_ x: Double, floor: Double) -> Double {
        floor + (1 - floor) * clamp(x)
    }

    // MARK: - Buffers

    private func synthesizeAll() {
        let pitches = [0.95, 1.0, 1.055]
        puttSoft = pitches.enumerated().compactMap { i, p in
            makeBuffer(Synth.putt(pitch: p, hard: false, seed: UInt32(101 + i)), peak: 0.7)
        }
        puttHard = pitches.enumerated().compactMap { i, p in
            makeBuffer(Synth.putt(pitch: p, hard: true, seed: UInt32(201 + i)), peak: 0.75)
        }
        wallHits = [0.92, 1.0, 1.08].enumerated().compactMap { i, p in
            makeBuffer(Synth.wall(pitch: p, seed: UInt32(301 + i)), peak: 0.75)
        }
        ballClacks = [0.95, 1.0, 1.06].enumerated().compactMap { i, p in
            makeBuffer(Synth.ballHit(pitch: p, seed: UInt32(401 + i)), peak: 0.55)
        }
        cupBuffer = makeBuffer(Synth.cupDrop(), peak: 0.7)
        splashBuffer = makeBuffer(Synth.splash(), peak: 0.7, fadeOut: 0.05)
        aceBuffer = makeBuffer(Synth.ace(), peak: 0.5, fadeOut: 0.08)
        doubleAceBuffer = makeBuffer(Synth.doubleAce(), peak: 0.5, fadeOut: 0.12)
        goodBuffer = makeBuffer(Synth.resultGood(), peak: 0.45, fadeOut: 0.08)
        neutralBuffer = makeBuffer(Synth.resultNeutral(), peak: 0.4, fadeOut: 0.08)
        tapBuffer = makeBuffer(Synth.tap(), peak: 0.35)
        tickBuffer = makeBuffer(Synth.tick(), peak: 0.25, fadeOut: 0.004)
    }

    /// Normalizes to `peak`, trims the inaudible tail and fades the end to avoid clicks.
    private func makeBuffer(_ samples: [Float], peak: Float, fadeOut: Double = 0.01) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let maxAbs = samples.reduce(Float(0)) { max($0, abs($1)) }
        guard maxAbs > 0 else { return nil }

        let silence = maxAbs * 0.0005
        var count = samples.count
        while count > 1 && abs(samples[count - 1]) < silence { count -= 1 }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
              let out = buffer.floatChannelData?[0] else { return nil }
        let gain = peak / maxAbs
        let fadeCount = min(count, max(1, Int(fadeOut * Synth.sampleRate)))
        for i in 0..<count {
            var v = samples[i] * gain
            let remaining = count - i
            if remaining <= fadeCount { v *= Float(remaining - 1) / Float(fadeCount) }
            out[i] = v
        }
        buffer.frameLength = AVAudioFrameCount(count)
        return buffer
    }
}

// MARK: - Synthesis

private enum Synth {
    static let sampleRate = 44_100.0

    enum Wave { case sine, triangle }

    /// xorshift32: fast, deterministic noise so every launch sounds identical.
    struct Rng {
        private var state: UInt32
        init(_ seed: UInt32) { state = seed == 0 ? 0x9E37_79B9 : seed }

        mutating func next() -> Double { // -1...1
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            return Double(state) / Double(UInt32.max) * 2 - 1
        }

        mutating func range(_ lo: Double, _ hi: Double) -> Double {
            lo + (hi - lo) * (next() + 1) * 0.5
        }
    }

    /// One-pole filter coefficient for cutoff `fc`.
    static func coef(_ fc: Double) -> Double {
        1 - exp(-2 * .pi * min(fc, sampleRate * 0.45) / sampleRate)
    }

    struct Track {
        var data: [Float]

        init(_ seconds: Double) {
            data = [Float](repeating: 0, count: max(1, Int(seconds * Synth.sampleRate)))
        }

        /// Adds an oscillator with a linear attack and exponential decay (`tau` = time constant, s).
        /// `glideFrom` sweeps the pitch exponentially from that frequency to `freq` over `glideTime`.
        mutating func tone(_ freq: Double, at start: Double = 0, amp: Double, tau: Double,
                           attack: Double = 0.003, wave: Wave = .sine,
                           glideFrom: Double? = nil, glideTime: Double = 0.05) {
            let sr = Synth.sampleRate
            var i = Int(start * sr)
            let n = data.count
            guard i < n, amp > 0 else { return }
            let attackCount = max(1, Int(max(attack, 0.002) * sr))
            let decay = exp(-1 / (tau * sr))
            let glideCount = max(1, Int(glideTime * sr))
            let glideStep = glideFrom.map { pow(freq / $0, 1 / Double(glideCount)) } ?? 1
            var f = glideFrom ?? freq
            var phase = 0.0
            var env = 1.0
            var j = 0
            data.withUnsafeMutableBufferPointer { out in
                while i < n && env > 0.0003 {
                    let ramp = j < attackCount ? Double(j) / Double(attackCount) : 1
                    let s: Double
                    switch wave {
                    case .sine: s = sin(2 * .pi * phase)
                    case .triangle: s = 1 - 4 * abs(phase - 0.5)
                    }
                    out[i] += Float(s * amp * env * ramp)
                    phase += f / sr
                    if phase >= 1 { phase -= 1 }
                    if j < glideCount { f *= glideStep }
                    if j >= attackCount { env *= decay }
                    i += 1
                    j += 1
                }
            }
        }

        /// Adds decaying noise through a 2-pole low-pass (optionally sweeping to `lowpassEnd`)
        /// and a 1-pole high-pass. Roughly gain-compensated so `amp` is comparable to `tone`.
        mutating func noise(at start: Double = 0, amp: Double, tau: Double, attack: Double = 0.002,
                            lowpass: Double, lowpassEnd: Double? = nil, sweepTime: Double = 0.2,
                            highpass: Double = 20, seed: UInt32) {
            let sr = Synth.sampleRate
            var i = Int(start * sr)
            let n = data.count
            guard i < n, amp > 0 else { return }
            var rng = Rng(seed)
            let attackCount = max(1, Int(max(attack, 0.002) * sr))
            let decay = exp(-1 / (tau * sr))
            let sweepCount = max(1, Int(sweepTime * sr))
            let sweepStep = lowpassEnd.map { pow($0 / lowpass, 1 / Double(sweepCount)) } ?? 1
            var fc = lowpass
            var a = Synth.coef(fc)
            let makeup = amp * (2 / a).squareRoot() * 0.9
            let hp = Synth.coef(highpass)
            var lp1 = 0.0, lp2 = 0.0, hpState = 0.0
            var env = 1.0
            var j = 0
            data.withUnsafeMutableBufferPointer { out in
                while i < n && env > 0.0003 {
                    lp1 += a * (rng.next() - lp1)
                    lp2 += a * (lp1 - lp2)
                    hpState += hp * (lp2 - hpState)
                    let ramp = j < attackCount ? Double(j) / Double(attackCount) : 1
                    out[i] += Float((lp2 - hpState) * makeup * env * ramp)
                    if lowpassEnd != nil && j < sweepCount {
                        fc *= sweepStep
                        a = Synth.coef(fc)
                    }
                    if j >= attackCount { env *= decay }
                    i += 1
                    j += 1
                }
            }
        }

        /// Soft mallet/chime note: fundamental, gentle overtones and a brief bright "ping".
        mutating func bell(_ f: Double, at start: Double, amp: Double, tau: Double) {
            tone(f, at: start, amp: amp, tau: tau, attack: 0.004)
            tone(f * 2, at: start, amp: amp * 0.22, tau: tau * 0.5)
            tone(f * 3, at: start, amp: amp * 0.07, tau: tau * 0.3)
            tone(f * 4.07, at: start, amp: amp * 0.1, tau: 0.02, attack: 0.002)
        }

        /// Rounder note with almost no overtones, for neutral feedback.
        mutating func softNote(_ f: Double, at start: Double, amp: Double, tau: Double) {
            tone(f, at: start, amp: amp, tau: tau, attack: 0.006)
            tone(f * 2, at: start, amp: amp * 0.1, tau: tau * 0.4, attack: 0.006)
            tone(f * 0.5, at: start, amp: amp * 0.25, tau: tau * 0.6, attack: 0.01, wave: .triangle)
        }
    }

    // MARK: Recipes

    /// Woody "tock": short main mode, an inharmonic mode for a hint of metal, a low body thump
    /// and a strike transient. The hard variant has more upper partials and a brighter click.
    static func putt(pitch: Double, hard: Bool, seed: UInt32) -> [Float] {
        var t = Track(0.16)
        let f = 980 * pitch
        t.tone(f, amp: 0.55, tau: 0.022, attack: 0.002)
        t.tone(f * 2.76, amp: hard ? 0.2 : 0.09, tau: 0.009, attack: 0.002)
        t.tone(f * 5.4, amp: hard ? 0.07 : 0.02, tau: 0.004, attack: 0.002)
        t.tone(240 * pitch, amp: 0.35, tau: 0.03, glideFrom: 330 * pitch, glideTime: 0.015)
        t.noise(amp: hard ? 0.22 : 0.12, tau: 0.004, lowpass: hard ? 5500 : 2600, highpass: 400, seed: seed)
        return t.data
    }

    /// Muted "thunk": low-mid body with a quick downward pitch bend plus dull, low-passed noise.
    static func wall(pitch: Double, seed: UInt32) -> [Float] {
        var t = Track(0.18)
        t.tone(230 * pitch, amp: 0.7, tau: 0.04, glideFrom: 330 * pitch, glideTime: 0.02)
        t.tone(585 * pitch, amp: 0.3, tau: 0.015)
        t.tone(115 * pitch, amp: 0.25, tau: 0.04, attack: 0.004)
        t.noise(amp: 0.35, tau: 0.012, lowpass: 1100, highpass: 90, seed: seed)
        return t.data
    }

    /// Crisp "clack": a few fast-decaying high partials and a tiny high-passed click.
    static func ballHit(pitch: Double, seed: UInt32) -> [Float] {
        var t = Track(0.1)
        let f = 2350 * pitch
        t.tone(f, amp: 0.6, tau: 0.012, attack: 0.002)
        t.tone(f * 1.48, amp: 0.28, tau: 0.007, attack: 0.002)
        t.tone(f * 2.31, amp: 0.12, tau: 0.004, attack: 0.002)
        t.tone(1180 * pitch, amp: 0.2, tau: 0.01, attack: 0.002)
        t.noise(amp: 0.25, tau: 0.003, lowpass: 9000, highpass: 1500, seed: seed)
        return t.data
    }

    /// Three accelerating rim clicks, then a hollow plonk whose pitch drops as the ball settles.
    static func cupDrop() -> [Float] {
        var t = Track(0.8)
        let clicks: [(time: Double, freq: Double, amp: Double)] = [
            (0.0, 2900, 0.45), (0.075, 3300, 0.36), (0.13, 2700, 0.28)
        ]
        for (i, c) in clicks.enumerated() {
            t.tone(c.freq, at: c.time, amp: c.amp, tau: 0.007, attack: 0.002)
            t.tone(c.freq * 1.53, at: c.time, amp: c.amp * 0.4, tau: 0.004, attack: 0.002)
            t.noise(at: c.time, amp: c.amp * 0.3, tau: 0.003, lowpass: 7000, highpass: 1200, seed: UInt32(77 + i))
        }
        let plonk = 0.19
        // Fundamental + 3rd harmonic reads as a closed tube, i.e. "hollow".
        t.tone(330, at: plonk, amp: 0.8, tau: 0.13, glideFrom: 520, glideTime: 0.06)
        t.tone(990, at: plonk, amp: 0.18, tau: 0.05, glideFrom: 1560, glideTime: 0.06)
        t.tone(140, at: plonk, amp: 0.35, tau: 0.05, attack: 0.004)
        t.noise(at: plonk, amp: 0.2, tau: 0.01, lowpass: 1500, highpass: 100, seed: 91)
        // Small settling bounce.
        t.tone(305, at: plonk + 0.11, amp: 0.22, tau: 0.08, glideFrom: 400, glideTime: 0.03)
        return t.data
    }

    /// Noise whose low-pass closes over ~350 ms, a low "sploosh" layer, an upward droplet blip
    /// at impact and a tail of small rising-pitch bubbles.
    static func splash() -> [Float] {
        var t = Track(0.7)
        t.tone(1300, amp: 0.25, tau: 0.03, glideFrom: 650, glideTime: 0.03)
        t.noise(amp: 0.9, tau: 0.13, attack: 0.012, lowpass: 3200, lowpassEnd: 500,
                sweepTime: 0.35, highpass: 180, seed: 1234)
        t.noise(amp: 0.5, tau: 0.09, attack: 0.02, lowpass: 600, highpass: 90, seed: 4321)
        var rng = Rng(2024)
        var time = 0.17
        for _ in 0..<6 {
            let f = rng.range(600, 1300)
            t.tone(f * 1.6, at: time, amp: rng.range(0.08, 0.16), tau: 0.025,
                   glideFrom: f, glideTime: 0.025)
            time += rng.range(0.04, 0.085)
        }
        return t.data
    }

    /// E5 - G5 - C6 rising chime.
    static func ace() -> [Float] {
        var t = Track(1.0)
        t.bell(659.26, at: 0.0, amp: 0.5, tau: 0.16)
        t.bell(783.99, at: 0.1, amp: 0.5, tau: 0.16)
        t.bell(1046.50, at: 0.2, amp: 0.6, tau: 0.26)
        return t.data
    }

    /// C5-E5-G5-C6-E6 arpeggio landing on a bright C major chord over a warm bed, with sparkles.
    static func doubleAce() -> [Float] {
        var t = Track(1.75)
        let run = [523.25, 659.26, 783.99, 1046.50, 1318.51]
        for (i, f) in run.enumerated() {
            t.bell(f, at: Double(i) * 0.085, amp: 0.42, tau: 0.16)
        }
        let land = 0.47
        for f in [1046.50, 1318.51, 1567.98] {
            t.bell(f, at: land, amp: 0.3, tau: 0.38)
        }
        t.bell(2093.0, at: land, amp: 0.16, tau: 0.3)
        t.tone(261.63, at: land, amp: 0.25, tau: 0.45, attack: 0.03, wave: .triangle)

        // Sparkle: tiny high pings from the C major pentatonic, thinning out over time.
        let sparkle = [2093.0, 2349.32, 2637.02, 3135.96, 3520.0, 4186.01]
        var rng = Rng(777)
        var time = land + 0.05
        while time < 1.3 {
            let f = sparkle[min(sparkle.count - 1, Int((rng.next() + 1) * 0.5 * Double(sparkle.count)))]
            let fade = max(0.25, 1 - (time - land) / 1.0)
            t.tone(f, at: time, amp: rng.range(0.05, 0.1) * fade, tau: 0.05, attack: 0.002)
            time += rng.range(0.035, 0.09)
        }
        return t.data
    }

    /// Rising major third, C5 -> E5.
    static func resultGood() -> [Float] {
        var t = Track(1.0)
        t.bell(523.25, at: 0.0, amp: 0.45, tau: 0.2)
        t.bell(659.26, at: 0.14, amp: 0.5, tau: 0.28)
        return t.data
    }

    /// Soft descending fourth, D5 -> A4: neither happy nor sad.
    static func resultNeutral() -> [Float] {
        var t = Track(0.95)
        t.softNote(587.33, at: 0.0, amp: 0.45, tau: 0.16)
        t.softNote(440.0, at: 0.15, amp: 0.45, tau: 0.22)
        return t.data
    }

    static func tap() -> [Float] {
        var t = Track(0.05)
        t.tone(1650, amp: 0.5, tau: 0.006, attack: 0.002)
        t.tone(820, amp: 0.35, tau: 0.01, attack: 0.002)
        t.noise(amp: 0.08, tau: 0.002, lowpass: 6000, highpass: 1500, seed: 5)
        return t.data
    }

    static func tick() -> [Float] {
        var t = Track(0.025)
        t.tone(2900, amp: 0.5, tau: 0.003, attack: 0.002)
        t.tone(1450, amp: 0.2, tau: 0.004, attack: 0.002)
        return t.data
    }
}
