import Observation
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
    var soundOn = SoundFX.shared.isEnabled
    var freePlay = FreePlaySpot()
    let game: GameModel
    @ObservationIgnored let scene: GameScene

    init() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "tests") { GameModel.levels = DebugLevels.all }
        #endif
        let game = GameModel()
        self.game = game
        scene = GameScene(model: game)
        game.scene = scene
        SoundFX.shared.start()
        game.analytics.launched()
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
        #endif
    }

    /// A single pair from the course map (outside the round).
    func play(level: Int) {
        game.leaveRound()
        game.start(level: level)
        screen = .game
    }

    /// Back to Free Play from a pair, with that pair in view.
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
            switch app.screen {
            case .title: TitleView(app: app).transition(.opacity)
            case .courses: CoursesView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
            case .levels: CourseMapView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
            case .trophies: TrophyShelfView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
            case .settings: SettingsView(app: app).transition(.opacity.combined(with: .scale(scale: 1.04)))
            case .game: GameView(app: app).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.screen)
        .onChange(of: scenePhase) { _, phase in if phase == .background { app.game.analytics.backgrounded() } }
    }
}
