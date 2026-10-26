#if DEBUG
import Metal
import SpriteKit
import UIKit

/// Marketing captures, from Xcode builds only: App Store screenshots, the App Store preview and the trailer's
/// footage. `Tools/capture/` drives it (see README). Launched with `-storeCapture <clip>` and the clip's script as JSON
/// in the DP_CAPTURE_CLIP environment variable (an entry of Tools/capture/clips.json), the app opens the clip's hole
/// and plays its swings as a player would (a drag on one ball, Same or Mirror, then Putt), or opens the clip's screen
/// (the Trophy Shelf), saving the frames it draws, the HUD included, to Documents/StoreCapture: NNNNN.jpg, any stills
/// asked for as still-N.png, then done.txt. They're the screen's size, whatever the simulator (an iPhone, an iPad, an
/// iPhone Duo closed), or with `-canvas` the canvas's: a Duo opened, which a simulator can't do from the command line.
///
/// Frame by frame, as Bigger Fish's footage plays: the scene comes off its view and an SKRenderer steps it, its
/// update, actions and particles alike, exactly a 60th of a second at a time, however long a frame takes to save
/// (Stepper). So footage never stutters, and a rerun plays the same swings the same way. (The ambience, a gull or a
/// firework, is SpriteKit's random and can differ.) Each frame the renderer draws is shown where the scene was, and the
/// window is saved, HUD and all. SwiftUI's animations would run on the wall clock in between, so they're off: the HUD changes on the frame
/// it happens (the result card comes up without its fade). The game's sounds are logged by name against the same
/// clock (cues.txt) and saved as WAVs (sounds/), so the scripts can rebuild the soundtrack: the simulator records none.
///
/// It stages a fresh saved state (the tutorial done, a round if the clip plays one, the trophies it lists) over whatever
/// the app had, so the scripts run it on a simulator of its own. Analytics are off.
enum StoreCapture {
    /// A clip's script: one entry of Tools/capture/clips.json.
    struct Clip: Decodable {
        var name: String
        /// The hole, by name (unless the clip shows a screen).
        var hole: String?
        /// A screen shown instead of a hole, as it stands.
        var screen: Screen?
        /// Trophies won, staged: per course in order, its cabinet's three shelves of three holes, "x" a trophy and "."
        /// an empty slot ("xx. x.x ..x"). Courses left out have none.
        var trophies: [String]?
        /// Played in a round: the scores of the holes before it on its course, or "auto" for a round going well.
        var round: Round?
        /// The hole's hint showing the whole clip.
        var hint: Bool?
        /// A fingertip over each drag (default true).
        var touch: Bool?
        /// Seconds before the first swing (default 0.8).
        var lead: Double?
        var swings: [Swing]?
        /// Seconds kept after the last swing settles, or a screen is held (default 2.5): the result card comes up in
        /// them.
        var tail: Double?
    }

    enum Screen: String, Decodable {
        /// The Trophy Shelf.
        case trophies

        var shown: AppState.Screen {
            switch self {
            case .trophies: .trophies
            }
        }
    }

    enum Round: Decodable {
        case auto
        case scores([Int])

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let scores = try? c.decode([Int].self) {
                self = .scores(scores)
            } else if try c.decode(String.self) == "auto" {
                self = .auto
            } else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "round is \"auto\" or the scores before")
            }
        }
    }

    /// One swing: a drag on one ball to the aim, Same or Mirror, then Putt.
    struct Swing: Decodable {
        /// "solution" (the hole's stored double ace, struck on the solver's tick), or [degrees, power] as the guide
        /// takes them: ball A's direction (0 right, 90 up) and 0–1.
        var aim: Aim
        /// Mirror (default: the solution's choice, otherwise Same).
        var mirror: Bool?
        /// Tap Mirror (or Same) "before" the drag or "after" it (default), when the other ball's guide flips over.
        var toggle: String?
        /// The ball dragged on: 0 the left green's, 1 the right's (default 0).
        var side: Int?
        /// Seconds before the drag (default 0.5, or the clip's lead for the first swing).
        var wait: Double?
        /// Seconds the drag takes (default 0.9).
        var drag: Double?
        /// Seconds between the drag and Putt (default 0.5).
        var hold: Double?
        /// Putt at the end (default true); false leaves it aimed, for a still.
        var putt: Bool?
    }

    enum Aim: Decodable {
        case solution
        case shot(angle: Double, power: Double)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let pair = try? c.decode([Double].self), pair.count == 2 {
                self = .shot(angle: pair[0], power: pair[1])
            } else if try c.decode(String.self) == "solution" {
                self = .solution
            } else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "aim is \"solution\" or [degrees, power]")
            }
        }
    }

    /// What to save, from the launch arguments: frames from -captureFrom to -captureTo (seconds), every
    /// -captureEvery'th, at -captureScale times the screen (below 1 for a quick look), or none with -captureNoFrames;
    /// and -captureStills as PNGs at full size (seconds, comma separated).
    struct Request {
        var frames = true
        var from = 0.0
        var to = Double.infinity
        var every = 1
        var scale = 1.0
        var stills: [Double] = []
    }

    static let isActive = ProcessInfo.processInfo.arguments.contains("-storeCapture")

    /// This launch's clip, if it's a capture.
    static let clip: Clip? = {
        guard isActive else { return nil }
        guard let json = ProcessInfo.processInfo.environment["DP_CAPTURE_CLIP"] else { return nil }
        do {
            return try JSONDecoder().decode(Clip.self, from: Data(json.utf8))
        } catch {
            fail("the clip's JSON doesn't read: \(error)")
            return nil
        }
    }()

    static let request: Request = {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), args.indices.contains(i + 1) else { return nil }
            return args[i + 1]
        }
        var r = Request()
        r.frames = !args.contains("-captureNoFrames")
        if let from = value("-captureFrom").flatMap(Double.init), from >= 0 { r.from = from }
        if let to = value("-captureTo").flatMap(Double.init), to > r.from { r.to = to }
        if let every = value("-captureEvery").flatMap(Int.init), every >= 1 { r.every = every }
        if let scale = value("-captureScale").flatMap(Double.init), scale > 0, scale <= 1 { r.scale = scale }
        r.stills = value("-captureStills")?.split(separator: ",").compactMap { Double($0) } ?? []
        return r
    }()

    static let framesPerSecond = 60.0

    /// Seconds into the clip: the clock the scene is stepped on, and the sounds are logged against.
    static var clock = 0.0
    private static var cues: [String] = []

    @MainActor private static func levelIndex(_ name: String) -> Int? { GameModel.levels.firstIndex { $0.name == name } }

    // MARK: Staged state

    /// Before the game reads its saved state: a fresh one, with the tutorial done, the clip's trophies won and its round
    /// in progress.
    @MainActor static func stage() {
        guard isActive else { return }
        let defaults = UserDefaults.standard
        if let domain = Bundle.main.bundleIdentifier { defaults.removePersistentDomain(forName: domain) }
        defaults.set(true, forKey: "tutorialDone")
        defaults.set(true, forKey: "mirrorTaught")
        if let trophies = clip?.trophies { stage(trophies: trophies) }
        guard let clip, let round = clip.round, let hole = clip.hole, let index = levelIndex(hole),
              let nine = Nine.all(levelCount: GameModel.levels.count).first(where: { $0.holes.contains(index) }) else { return }
        let played = index - nine.holes.lowerBound
        let scores: [Int]
        switch round {
        case .scores(let given):
            scores = given
        case .auto:
            // A round going well: par, with a birdie every third hole.
            scores = (0..<played).map { k in
                let level = GameModel.levels[nine.holes.lowerBound + k]
                return level.par[0] + level.par[1] - (k % 3 == 1 ? 1 : 0)
            }
        }
        guard scores.count == played else {
            return fail("\(hole) is hole \(played + 1) of \(nine.name), so its round needs \(played) scores, not \(scores.count)")
        }
        let rest = [Int?](repeating: nil, count: nine.holes.count - played)
        let state = RoundState(nine: nine.id, scores: scores.map { Optional($0) } + rest, current: played)
        defaults.set(try? JSONEncoder().encode(state), forKey: "round")
    }

    /// The trophies a clip lists (Clip.trophies), as the game saves them.
    @MainActor private static func stage(trophies cabinets: [String]) {
        let nines = Nine.all(levelCount: GameModel.levels.count)
        guard cabinets.count <= nines.count else {
            return fail("trophies for \(cabinets.count) courses, but there are \(nines.count)")
        }
        var won: [String: Double] = [:]
        for (nine, cabinet) in zip(nines, cabinets) {
            let slots = cabinet.filter { $0 != " " }
            guard slots.count == nine.holes.count, slots.allSatisfy({ $0 == "x" || $0 == "." }) else {
                return fail("\(nine.name)'s trophies are \(nine.holes.count) slots, each x or ., not \"\(cabinet)\"")
            }
            for (index, slot) in zip(nine.holes, slots) where slot == "x" {
                won[GameModel.levels[index].name] = Date.now.timeIntervalSince1970
            }
        }
        UserDefaults.standard.set(won, forKey: "trophies")
    }

    /// Opens the clip's hole, or its screen, and records it once it's up.
    @MainActor static func open(_ app: AppState) {
        guard isActive else { return }
        guard let clip else { return fail("no clip: DP_CAPTURE_CLIP holds its JSON (Tools/capture/clips.json)") }
        SoundFX.shared.captureClock = { clock }
        SoundFX.shared.captureCue = { name, volume in cues.append(String(format: "%.4f %@ %.3f", clock, name, volume)) }
        if let screen = clip.screen {
            app.screen = screen.shown
        } else {
            guard let hole = clip.hole else { return fail("\(clip.name) has no hole or screen") }
            guard let index = levelIndex(hole) else { return fail("no hole called \(hole)") }
            if clip.round != nil, app.game.round != nil {
                app.continueRound()
            } else {
                app.play(level: index)
            }
        }
        Task { await record(clip, app: app) }
    }

    // MARK: Recording

    /// Where the frames go (cleared at launch), for the scripts to collect from the simulator.
    static let directory: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StoreCapture", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    /// JPEGs are encoded off the main thread, a few at once.
    private static let encoder: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .userInitiated
        return queue
    }()

    /// A clip being recorded: what's on screen, and how it moves from frame to frame.
    @MainActor private struct Take {
        let window: UIWindow
        /// Plays the clip to `seconds` in; true once it's over.
        let advance: (Double) -> Bool
        /// Puts the frame on screen, to be saved; false if it couldn't be drawn.
        let show: () -> Bool
        /// What happened when, for done.txt.
        let timeline: () -> [String]
    }

    @MainActor private static func record(_ clip: Clip, app: AppState) async {
        let take: Take?
        if let screen = clip.screen {
            take = await screenTake(screen, clip: clip, app: app)
        } else {
            take = await holeTake(clip, app: app)
        }
        guard let take else { return }
        do {
            try SoundFX.shared.exportSounds(to: directory.appendingPathComponent("sounds", isDirectory: true))
        } catch {
            return fail("couldn't save the sounds: \(error.localizedDescription)")
        }

        let window = take.window
        let request = request
        let first = Int((request.from * framesPerSecond).rounded())
        let last = request.to.isFinite ? Int((request.to * framesPerSecond).rounded()) : Int.max
        var stills = request.stills.enumerated().map { (index: $0.offset, frame: Int(($0.element * framesPerSecond).rounded())) }
        var frame = 0, saved = 0
        let started = Date()
        while true {
            clock = Double(frame) / framesPerSecond
            let finished = take.advance(clock)
            let footage = request.frames && frame >= first && frame <= last && (frame - first) % request.every == 0
            let due = stills.filter { $0.frame <= frame }
            if footage || !due.isEmpty {
                guard take.show() else { return fail("couldn't draw frame \(frame)") }
                // Lets SwiftUI draw the model's changes first.
                try? await Task.sleep(for: .milliseconds(1))
                if footage {
                    let image = snapshot(window, scale: request.scale)
                    let url = directory.appendingPathComponent(String(format: "%05d.jpg", saved))
                    encoder.addOperation { try? image.jpegData(compressionQuality: 0.92)?.write(to: url) }
                    saved += 1
                }
                for still in due {
                    let url = directory.appendingPathComponent("still-\(still.index).png")
                    do {
                        try snapshot(window, scale: 1).pngData()?.write(to: url)
                    } catch {
                        return fail("couldn't save still \(still.index): \(error.localizedDescription)")
                    }
                }
                stills.removeAll { $0.frame <= frame }
                // A few frames waiting to encode at most, as each is the whole screen.
                while encoder.operationCount > 6 { try? await Task.sleep(for: .milliseconds(5)) }
            }
            guard failure == nil else { return }
            // Done with the clip, or with what was asked for.
            if ((finished || !request.frames) && stills.isEmpty) || frame >= last { break }
            frame += 1
            guard clock < 180 else { return fail("the clip ran past three minutes") }
        }
        await withCheckedContinuation { done in encoder.addBarrierBlock { done.resume() } }
        let length = Double(frame) / framesPerSecond
        let summary = String(format: "%d frames of %.2fs, in %ds", saved, length, Int(Date().timeIntervalSince(started)))
        do {
            try ((["# seconds sound volume (before the mixer, at \(SoundFX.mixerVolume))"] + cues).joined(separator: "\n") + "\n")
                .write(to: directory.appendingPathComponent("cues.txt"), atomically: true, encoding: .utf8)
            try (([summary, "seconds event:"] + take.timeline()).joined(separator: "\n") + "\n")
                .write(to: directory.appendingPathComponent("done.txt"), atomically: true, encoding: .utf8)
        } catch {
            return fail("couldn't save the cues: \(error.localizedDescription)")
        }
        print("[StoreCapture] \(clip.name): \(summary)")
    }

    /// Waits for the menu art and `ready`, then past the screen's fade in; false if it doesn't come in 90 seconds.
    @MainActor private static func settle(_ app: AppState, until ready: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(90)
        while !(app.artReady && ready()) {
            guard Date() < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(50))
        }
        try? await Task.sleep(for: .seconds(1))
        return true
    }

    /// The clip's hole once it's on screen, played by its Director and stepped a frame at a time (Stepper).
    @MainActor private static func holeTake(_ clip: Clip, app: AppState) async -> Take? {
        let scene = app.scene, game = app.game
        // The game screen up and the course laid out.
        guard await settle(app, until: { app.screen == .game && scene.view?.window != nil && game.courseFrame != .zero }) else {
            fail("the hole never came on screen")
            return nil
        }
        guard let view = scene.view, let window = view.window else {
            fail("the hole's view went away")
            return nil
        }
        // Laid out for the screen; now off the view, which shows a stand-in, so only the stepper runs it (Stepper). The
        // game screen shows the stand-in too, so SwiftUI doesn't put the scene back.
        scene.scaleMode = .fill
        let standIn = SKScene(size: view.bounds.size)
        app.captureStandIn = standIn
        view.presentScene(standIn)
        guard scene.view == nil else {
            fail("the hole's scene stayed on its view")
            return nil
        }
        guard let stepper = Stepper(scene: scene) else {
            fail("no Metal device to draw frames with")
            return nil
        }
        let overlay = UIImageView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)

        let screenScale = window.screen.scale
        let pixels = CGSize(width: (view.bounds.width * screenScale).rounded(), height: (view.bounds.height * screenScale).rounded())
        let director = Director(clip: clip, scene: scene, game: game)
        return Take(window: window,
                    advance: { now in
                        let finished = director.tick(at: now)
                        stepper.step(to: now)
                        return finished
                    },
                    show: {
                        guard let drawn = stepper.image(pixels: pixels) else { return false }
                        overlay.image = UIImage(cgImage: drawn, scale: screenScale, orientation: .up)
                        return true
                    },
                    timeline: { director.timeline })
    }

    /// The clip's screen once it's up, held as it stands for the clip's tail.
    @MainActor private static func screenTake(_ screen: Screen, clip: Clip, app: AppState) async -> Take? {
        func window() -> UIWindow? {
            UIApplication.shared.connectedScenes.lazy.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        }
        guard await settle(app, until: { app.screen == screen.shown && window() != nil }), let window = window() else {
            fail("the \(screen.rawValue) screen never came up")
            return nil
        }
        let held = clip.tail ?? 2.5
        return Take(window: window, advance: { $0 >= held - 1e-6 }, show: { true }, timeline: { [] })
    }

    /// The window as drawn, HUD and all, `scale` times the screen's resolution, with no alpha. Under `-canvas`, which
    /// lays the app out at another size and scales it to fit the screen (DebugCanvas), just the canvas, at its own size:
    /// a Duo opened, drawn on the Duo's own simulator, comes out at the inner screen's pixels. The window is drawn
    /// afresh at the image's resolution, so the scaling doesn't soften it.
    @MainActor private static func snapshot(_ window: UIWindow, scale: Double) -> UIImage {
        let format = UIGraphicsImageRendererFormat(for: window.traitCollection)
        format.opaque = true
        format.scale = window.screen.scale * scale
        let bounds = window.bounds
        var size = bounds.size, frame = bounds
        if let canvas = DebugCanvas.launchSize {
            // The window, scaled up and shifted so the canvas, centred on it at `fit`, fills the image.
            let fit = min(bounds.width / canvas.width, bounds.height / canvas.height)
            size = canvas
            frame = CGRect(x: -(bounds.width / fit - canvas.width) / 2, y: -(bounds.height / fit - canvas.height) / 2,
                           width: bounds.width / fit, height: bounds.height / fit)
        }
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            _ = window.drawHierarchy(in: frame, afterScreenUpdates: true)
        }
    }

    /// Why the clip couldn't be captured, once it can't: recording stops.
    private(set) static var failure: String?

    /// Tells the script the clip couldn't be captured, and why.
    static func fail(_ reason: String) {
        failure = failure ?? reason
        print("[StoreCapture] failed: \(reason)")
        try? reason.write(to: directory.appendingPathComponent("failed.txt"), atomically: true, encoding: .utf8)
    }

    // MARK: Stepping the scene

    /// Steps the scene a frame at a time and draws it offscreen, as Math Reef's capture does (kraigstrong/bigger-fish,
    /// MathReef/StoreCapture.swift). The scene is off the view by then (`record` swaps in a stand-in): a view, even
    /// paused, renders whenever it's laid out (SKView.layoutSubviews), and that runs its scene's update on the wall
    /// clock, many seconds from the capture's. Every overlay frame and HUD change lays it out, so the scene's time
    /// jumped back and forth: particles aged past their lifetime in a frame (a double ace's confetti never showed), and
    /// a clip recorded from partway in stalled while the physics caught up.
    @MainActor final class Stepper {
        private let renderer: SKRenderer
        private let device: MTLDevice
        private let queue: MTLCommandQueue
        private let scene: SKScene
        private let start = CACurrentMediaTime()

        init?(scene: SKScene) {
            guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
            self.device = device
            self.queue = queue
            self.scene = scene
            renderer = SKRenderer(device: device)
            renderer.scene = scene
        }

        /// The last step's time.
        private var last: Double?

        /// The scene `seconds` into the clip.
        func step(to seconds: Double) {
            scene.isPaused = false
            renderer.update(atTime: start + seconds)
            // Particles, stepped by hand: SpriteKit ages them unreliably under a renderer (they lived a third as long),
            // and gives an emitter born during an update an enormous first step that spends and ages out all its
            // particles before they're drawn (a double ace's confetti, made as the balls settle). Each emitter's own
            // clock is stopped (speed 0, which also marks it as taken over: the game never sets an emitter's speed), one
            // born during this update starts over, and every one advances a frame.
            let dt = seconds - (last ?? seconds)
            scene.enumerateChildNodes(withName: "//*") { node, _ in
                guard let emitter = node as? SKEmitterNode else { return }
                if emitter.speed != 0 {
                    if self.last != nil { emitter.resetSimulation() }
                    emitter.speed = 0
                }
                if dt > 0 { emitter.advanceSimulationTime(dt) }
            }
            last = seconds
        }

        /// The scene as it stands, drawn `pixels` big.
        func image(pixels: CGSize) -> CGImage? {
            let width = Int(pixels.width), height = Int(pixels.height)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .shared
            guard let texture = device.makeTexture(descriptor: descriptor), let commands = queue.makeCommandBuffer() else { return nil }
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            scene.backgroundColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = texture
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].clearColor = MTLClearColor(red: Double(r), green: Double(g), blue: Double(b), alpha: 1)
            pass.colorAttachments[0].storeAction = .store
            renderer.render(withViewport: CGRect(x: 0, y: 0, width: width, height: height), commandBuffer: commands,
                            renderPassDescriptor: pass)
            commands.commit()
            commands.waitUntilCompleted()
            let bytesPerRow = width * 4
            var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
            texture.getBytes(&bytes, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
            return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue
                                                    | CGImageAlphaInfo.noneSkipFirst.rawValue),
                           provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        }
    }

    // MARK: Playing the clip

    /// Plays the clip's swings frame by frame, as a player would: a pause, a drag that settles on the aim (the drag
    /// line, the guide and the power ticks with it), Same or Mirror tapped, a moment's hold, Putt, and the balls
    /// rolling to a stop.
    @MainActor final class Director {
        private enum Step {
            case wait(Double)
            /// Waits so that, `lead` seconds on, Putt strikes on the solver's tick: for a stored double ace on a hole
            /// with movers.
            case align(lead: Double)
            case mirror(Bool)
            case drag(target: Shot, side: Int, seconds: Double)
            case putt
            case settle
        }

        private let clip: Clip
        private let swings: [Swing]
        private let scene: GameScene
        private let game: GameModel
        private var steps: [Step] = []
        private var begun: Double?
        private var swing = 0
        /// The drag's start (course units), fixed when it begins.
        private var anchor: CGPoint?
        /// When a stored double ace on a hole with movers has to strike.
        private var strike: Double?
        private(set) var timeline: [String] = []

        init(clip: Clip, scene: GameScene, game: GameModel) {
            self.clip = clip
            swings = clip.swings ?? []
            self.scene = scene
            self.game = game
        }

        /// Plays the clip at `now`; true once it's over.
        func tick(at now: Double) -> Bool {
            while true {
                if steps.isEmpty {
                    guard swing < swings.count else { return true }
                    plan(swings[swing], first: swing == 0, last: swing == swings.count - 1)
                    swing += 1
                }
                let begun = begun ?? now
                self.begun = begun
                guard run(steps[0], begun: begun, now: now) else { return false }
                steps.removeFirst()
                self.begun = nil
            }
        }

        private func log(_ now: Double, _ event: String) {
            timeline.append(String(format: "%.2f %@", now, event))
        }

        private func plan(_ swing: Swing, first: Bool, last: Bool) {
            let solution = game.level.solution
            let target: Shot
            switch swing.aim {
            case .solution:
                guard let solution else {
                    fail("\(game.level.name) has no stored double ace")
                    steps = [.wait(0)]
                    return
                }
                target = Shot(angle: solution.angle, power: solution.power, mirrored: swing.mirror ?? solution.mirrored)
            case .shot(let angle, let power):
                target = Shot(angle: angle, power: power, mirrored: swing.mirror ?? false)
            }
            let before = swing.toggle == "before"
            let drag = swing.drag ?? 0.9, hold = swing.hold ?? 0.5
            let tapAfter = !before && game.mirrored != target.mirrored
            var plan: [Step] = [.wait(swing.wait ?? (first ? clip.lead ?? 0.8 : 0.5))]
            if before && game.mirrored != target.mirrored { plan += [.mirror(target.mirrored), .wait(0.35)] }
            if case .solution = swing.aim, scene.captureMoverCycle > 0, swing.putt ?? true {
                plan.append(.align(lead: drag + (tapAfter ? 0.7 : 0) + hold))
            }
            plan.append(.drag(target: target, side: swing.side ?? 0, seconds: drag))
            if tapAfter { plan += [.wait(0.3), .mirror(target.mirrored), .wait(0.4)] }
            plan.append(.wait(hold))
            if swing.putt ?? true { plan += [.putt, .settle] }
            if last { plan.append(.wait(clip.tail ?? 2.5)) }
            steps = plan
        }

        /// Plays one step; true once it's done.
        private func run(_ step: Step, begun: Double, now: Double) -> Bool {
            switch step {
            case .wait(let seconds):
                return now - begun >= seconds - 1e-6
            case .align(let lead):
                // The press, `swing` before the strike, has to land on the solution's time on the movers' clock, which
                // runs a 60th of a second a frame from here on.
                let time = scene.captureMoverClock, cycle = scene.captureMoverCycle
                var press = game.level.solutionTime - GameScene.swing
                while press < time + lead { press += cycle }
                strike = press + GameScene.swing
                steps.insert(.wait(press - time - lead), at: 1)
                return true
            case .mirror(let on):
                game.setMirrored(on)
                log(now, on ? "Mirror" : "Same")
                return true
            case .drag(let target, let side, let seconds):
                return drag(target, side: side, seconds: seconds, begun: begun, now: now)
            case .putt:
                scene.captureStrikeTime = strike
                strike = nil
                game.putt()
                log(now, "Putt")
                return true
            case .settle:
                guard !game.isRolling else { return false }
                log(now, game.isComplete ? "both in, \(game.strokes[0]) and \(game.strokes[1])" : "settled")
                return true
            }
        }

        /// A frame of the drag: the finger pulls back from a point just ahead of the ball, the aim swinging round to
        /// the target as the power builds, and lifts on the last frame.
        private func drag(_ target: Shot, side: Int, seconds: Double, begun: Double, now: Double) -> Bool {
            let u = min(1, (now - begun) / max(seconds, 1 / framesPerSecond))
            let e = u * u * (3 - 2 * u)
            // The dragged ball's direction: in Mirror the right green's ball goes the flip of ball A's.
            let angle = target.mirrored && side == 1 ? GameModel.flip(target.angle) : target.angle
            let swingIn = (swing % 2 == 0 ? 1.0 : -1.0) * 14 * (1 - e)
            let ppu = max(scene.capturePointsPerUnit, 0.01)
            let full = target.power * GameScene.maxDragPoints / ppu
            func direction(_ degrees: Double) -> CGVector {
                CGVector(dx: cos(degrees * .pi / 180), dy: sin(degrees * .pi / 180))
            }
            if anchor == nil {
                // Centred on the ball at full pull, kept inside the course.
                let ball = scene.captureBall(side), d = direction(angle)
                var start = CGPoint(x: ball.x + d.dx * full / 2, y: ball.y + d.dy * full / 2)
                let end = CGPoint(x: start.x - d.dx * full, y: start.y - d.dy * full)
                start.x += max(0, -10 - min(start.x, end.x)) - max(0, max(start.x, end.x) - Course.width - 10)
                start.y += max(0, -10 - min(start.y, end.y)) - max(0, max(start.y, end.y) - Course.height - 10)
                anchor = start
                log(now, "drag")
            }
            let d = direction(angle + swingIn), pull = full * e
            let finger = CGPoint(x: anchor!.x - d.dx * pull, y: anchor!.y - d.dy * pull)
            // The aim is stored as ball A's: the flip of the dragged one's when it's B's in Mirror.
            let dragged = u >= 1 ? angle : angle + swingIn
            var stored = game.mirrored && side == 1 ? GameModel.flip(dragged) : dragged
            stored = stored.truncatingRemainder(dividingBy: 360)
            if stored < 0 { stored += 360 }
            scene.captureDrag(side: side, start: anchor!, finger: finger,
                              shot: Shot(angle: stored, power: max(0.02, target.power * e)), touch: clip.touch ?? true)
            guard u >= 1 else { return false }
            scene.captureEndDrag()
            anchor = nil
            return true
        }
    }
}
#endif
