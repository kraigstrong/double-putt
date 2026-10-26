import Observation
import SpriteKit
import SwiftUI

@main
struct DoublePuttApp: App {
    @State private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView(app: app)
                .statusBarHidden()
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
@Observable
final class AppState {
    enum Screen: Equatable { case title, courses, levels, trophies, settings, game }

    var screen: Screen = .title
    /// The menu art is loaded (see LoadingView), so the screens can show.
    var artReady = false
    var soundOn = SoundFX.shared.isEnabled
    var freePlay = FreePlaySpot()
    /// The purchase screen, while it's up, and what opened it.
    var unlockOffer: UnlockOffer?
    let game: GameModel
    @ObservationIgnored let scene: GameScene
    #if DEBUG
    /// What the game screen's view shows instead of the game's scene during a store capture, which runs the scene
    /// itself (StoreCapture.swift).
    var captureStandIn: SKScene?
    #endif

    init() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "tests") { GameModel.levels = DebugLevels.all }
        // Before the game reads its saved state: a store capture stages its own.
        StoreCapture.stage()
        #endif
        let game = GameModel()
        self.game = game
        scene = GameScene(model: game)
        game.scene = scene
        SoundFX.shared.start()
        game.analytics.launched()
        game.purchases.start()
        #if DEBUG
        // Launch args for testing, e.g. `-level 3 -aim 70.25,0.71,mirror -guide full`
        let d = UserDefaults.standard
        if d.bool(forKey: "dumpArt") {
            // Write rendered art to Documents/art for inspection.
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("art")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            for level in Levels.course {
                let start = Date()
                let img = CourseArt.course(level, theme: Theme.for(level), ppu: 2.4)
                print("render \(level.name): \(Int(Date().timeIntervalSince(start) * 1000)) ms")
                try? img.pngData()?.write(to: dir.appendingPathComponent("\(level.name).png"))
            }
        }
        if d.bool(forKey: "dumpLandmarks") {
            // Write each setting's landmark to Documents/landmarks for inspection.
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("landmarks")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            for (id, theme) in Theme.all {
                let prop = CourseArt.landmark(theme, radius: 100, ppu: 2)
                try? prop.image.pngData()?.write(to: dir.appendingPathComponent("\(id).png"))
            }
        }
        if d.integer(forKey: "level") > 0 {
            play(level: d.integer(forKey: "level") - 1)
            if d.string(forKey: "guide") == "full" { game.fullPathGuide = true }
            if let parts = d.string(forKey: "aim")?.split(separator: ","), parts.count >= 2,
               let angle = Double(parts[0]), let power = Double(parts[1]) {
                game.tutorial = nil
                game.setMirrored(parts.count > 2 && parts[2] == "mirror")
                game.setAim(Shot(angle: angle, power: power))
            }
        }
        StoreCapture.open(self)
        #endif
    }

    /// A single hole from the course map (outside the round).
    func play(level: Int) {
        game.leaveRound()
        game.start(level: level)
        screen = .game
    }

    /// Back to Free Play from a hole, with that hole in view.
    func backToFreePlay() {
        freePlay.reveal(game.levelIndex, in: game.nines)
        screen = .levels
    }

    func playRound(_ nine: Nine) {
        game.startRound(nine)
        screen = .game
    }

    func continueRound() {
        game.continueRound()
        screen = .game
    }

    /// Open the purchase screen over the screen that's showing.
    func offerUnlock(_ source: UnlockOffer.Source, course: String? = nil) {
        unlockOffer = UnlockOffer(source: source, course: course)
        game.analytics.unlockShown(source: source.rawValue, course: source == .settings ? nil : course)
    }

    /// Free Play, at its row of free holes: from the purchase screen, for a player who isn't ready to buy.
    func showFreeHoles() {
        unlockOffer = nil
        if game.showScorecard { game.closeScorecard() }
        freePlay.course = CourseMapView.freeRow
        screen = .levels
    }

    func toggleSound() {
        soundOn.toggle()
        SoundFX.shared.isEnabled = soundOn
        SoundFX.shared.tap()
    }
}

struct RootView: View {
    let app: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(uiColor: Palette.ink).ignoresSafeArea()
            if !app.artReady {
                LoadingView(app: app).transition(.opacity)
            } else {
                switch app.screen {
                case .title: TitleView(app: app).transition(.opacity)
                case .courses: CoursesView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
                case .levels: CourseMapView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
                case .trophies: TrophyShelfView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
                case .settings: SettingsView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
                case .game: GameView(app: app).transition(.opacity)
                }
                if let offer = app.unlockOffer {
                    UnlockView(app: app, offer: offer).transition(.opacity).zIndex(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.screen)
        .animation(.easeInOut(duration: 0.25), value: app.unlockOffer)
        .onChange(of: scenePhase) { _, phase in if phase == .background { app.game.analytics.backgrounded() } }
        #if DEBUG
        // A store capture steps time itself, frame by frame, and SwiftUI's animations would run on the wall clock in
        // between: the HUD changes on the frame it happens instead.
        .transaction { if StoreCapture.isActive { $0.animation = nil; $0.disablesAnimations = true } }
        .modifier(DebugCanvas())
        #endif
    }
}

#if DEBUG
/// `-canvas 951x669` lays the app out at that size in points, scaled to fit the screen: an iPhone Duo opened, say, or
/// an iPad turned, on any simulator (neither can be folded or turned from the command line). With `-canvasTurn 4` it
/// turns every 4 seconds, swapping width and height, to try out a resize mid-hole. A store capture saves the canvas at
/// its own size (StoreCapture.swift).
struct DebugCanvas: ViewModifier {
    /// The size `-canvas` asks for, if any.
    static let launchSize: CGSize? = {
        let parts = UserDefaults.standard.string(forKey: "canvas")?.split(separator: "x").compactMap { Double($0) } ?? []
        return parts.count == 2 ? CGSize(width: parts[0], height: parts[1]) : nil
    }()

    @State private var size = launchSize

    func body(content: Content) -> some View {
        canvas(content).task {
            let every = UserDefaults.standard.double(forKey: "canvasTurn")
            guard every > 0 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(every))
                if let s = size { size = CGSize(width: s.height, height: s.width) }
            }
        }
    }

    @ViewBuilder
    private func canvas(_ content: Content) -> some View {
        if let size {
            GeometryReader { geo in
                content
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .scaleEffect(min(geo.size.width / size.width, geo.size.height / size.height))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()
            .background(Color.black)
        } else {
            content
        }
    }
}
#endif
