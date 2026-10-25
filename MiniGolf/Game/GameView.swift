import SpriteKit
import SwiftUI

struct GameView: View {
    let app: AppState
    @State private var showHint = false
    @Environment(\.scenePhase) private var scenePhase

    private var game: GameModel { app.game }
    private static let topBar: CGFloat = 52
    private static let bottomBar: CGFloat = 74

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: shownScene, isPaused: viewPaused, preferredFramesPerSecond: 120, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.safeAreaInsets.top + Self.topBar + 20)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.safeAreaInsets.bottom + Self.bottomBar + 30)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 6) {
                    topBar(compact: geo.size.width < 420).frame(height: Self.topBar).padding(.horizontal, geo.size.width < 420 ? 8 : 12)
                    Spacer()
                    bottomBar(compact: geo.size.width < 420).frame(height: Self.bottomBar).padding(.horizontal, geo.size.width < 420 ? 8 : 10).padding(.bottom, 4)
                }

                powerMeter(geo)
                holePanel(geo)

                let course = localCourseFrame(geo)
                let tip = tipSpot(course)
                // Hints sit below the tees (empty on every hole); the tutorial uses the open middle of Reflection.
                if showHint && game.tutorial == nil && !game.showResult {
                    HintBanner(text: game.level.hint)
                        .frame(width: tip.width)
                        .position(tip.center)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .onTapGesture { withAnimation { showHint = false } }
                }
                // Tips sit in the strip below the tees so they never cover the play area.
                ZStack {
                    if let step = game.tutorial {
                        TutorialCard(step: step) { withAnimation { game.dismissTutorial() } }
                            .transition(.move(edge: game.courseTurned ? .top : .bottom).combined(with: .opacity))
                    }
                }
                .frame(width: tip.width)
                .position(tip.center)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.tutorial)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showHint)

                if game.tutorial == .aim { DragDemo(frame: localCourseFrame(geo), turned: game.courseTurned) }

                if game.paused {
                    PauseMenu(app: app).transition(.opacity)
                }
                if game.showResult {
                    ResultCard(app: app).transition(.opacity)
                }
                if game.showScorecard {
                    ScorecardView(game: game, final: game.round?.isFinished ?? true) {
                        if game.round?.isFinished ?? true {
                            game.closeScorecard()
                            app.screen = .title
                        } else {
                            game.showScorecard = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: game.paused)
            .animation(.easeInOut(duration: 0.3), value: game.showResult)
            .animation(.easeInOut(duration: 0.3), value: game.showScorecard)
            .onAppear { updateInsets(geo); keepAwake(!game.paused) }
            .onDisappear { keepAwake(false); game.leftGame() }
            .onChange(of: geo.size) { updateInsets(geo) }
            .onChange(of: game.paused) { _, paused in keepAwake(!paused) }
            .onChange(of: scenePhase) { _, phase in
                // Leaving the app mid-hole pauses it, so the pause menu is up on return and nothing moved meanwhile.
                if phase != .active && !game.showResult && !game.showScorecard && !game.isComplete { game.paused = true }
            }
            .task(id: game.loadToken) {
                #if DEBUG
                // A store capture shows the hint for the whole clip, or not at all.
                if let clip = StoreCapture.clip {
                    showHint = clip.hint ?? false
                    return
                }
                #endif
                withAnimation { showHint = true }
                try? await Task.sleep(for: .seconds(5))
                withAnimation { showHint = false }
            }
        }
    }

    /// The game's scene, or a store capture's stand-in once it's running the scene itself (StoreCapture.swift).
    private var shownScene: SKScene {
        #if DEBUG
        if let standIn = app.captureStandIn { return standIn }
        #endif
        return app.scene
    }

    /// A store capture steps the scene itself (StoreCapture.swift), so the view never runs it.
    private var viewPaused: Bool {
        #if DEBUG
        if StoreCapture.isActive { return true }
        #endif
        return game.paused
    }

    private var subtitle: String {
        var s = "HOLE \(game.holeNumber(game.levelIndex)) · PAR \(game.par)"
        if game.inRound { s += " · " + (game.roundToPar.map { "ROUND \(GameModel.toPar($0))" } ?? "ROUND E") }
        return s
    }

    /// Aiming can outlast auto-lock, so the screen stays on while a hole is in play; paused, it sleeps as usual.
    private func keepAwake(_ on: Bool) { UIApplication.shared.isIdleTimerDisabled = on }

    private func updateInsets(_ geo: GeometryProxy) {
        let s = geo.safeAreaInsets
        // The sides' safe areas (a Duo keeps its camera and status bar down one side) go in as well: the course
        // stays clear of them, but still centres on the whole screen when there's room.
        game.insets = (hud: UIEdgeInsets(top: s.top + Self.topBar + 10, left: 14, bottom: s.bottom + Self.bottomBar + 14, right: 52),
                       sides: UIEdgeInsets(top: 0, left: s.leading, bottom: 0, right: s.trailing))
    }

    private func localCourseFrame(_ geo: GeometryProxy) -> CGRect {
        game.courseFrame.offsetBy(dx: -geo.safeAreaInsets.leading, dy: -geo.safeAreaInsets.top)
    }

    /// Where hints and tips go: the strip below the tees, empty on every hole. Turned, that strip runs down the
    /// course's left end, too narrow for words, so they hang across the top edge instead, under the bar.
    private func tipSpot(_ course: CGRect) -> (center: CGPoint, width: CGFloat) {
        if game.courseTurned {
            return (CGPoint(x: course.midX, y: course.minY + 26), max(min(course.width * 0.6, 520), 1))
        }
        return (CGPoint(x: course.midX, y: course.maxY - course.height * 0.055), max(course.width, 1))
    }

    // MARK: Bars

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            GlassIconButton(symbol: "pause.fill", size: compact ? 38 : 42) { game.paused = true }
            ScoreChip(index: 0, strokes: game.strokes[0], sunk: game.sunk[0])
            Spacer(minLength: 0)
            VStack(spacing: 1) {
                HStack(spacing: 5) {
                    Text(game.level.name).font(.rounded(compact ? 18 : 20, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                    // Tapping the name brings the hole's hint back; the bulb says so.
                    if !game.level.hint.isEmpty {
                        Image(systemName: showHint && game.tutorial == nil ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: compact ? 12 : 13, weight: .bold))
                            .foregroundStyle(showHint && game.tutorial == nil ? Color.putt : .white.opacity(0.8))
                    }
                }
                Text(subtitle)
                    .font(.rounded(10, .bold)).tracking(1.2).opacity(0.75)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { showHint.toggle() } }
            Spacer(minLength: 0)
            ScoreChip(index: 1, strokes: game.strokes[1], sunk: game.sunk[1])
            // A round is played as it lies; only Free Play can start a hole over. The gap keeps the name centered.
            if game.inRound {
                Color.clear.frame(width: compact ? 38 : 42, height: compact ? 38 : 42)
            } else {
                GlassIconButton(symbol: "arrow.counterclockwise", size: compact ? 38 : 42) { game.restart() }
            }
        }
    }

    private func bottomBar(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            SwingToggle(mirrored: game.mirrored, turned: game.courseTurned, segment: compact ? 50 : 58) { game.setMirrored($0) }
                .overlay(alignment: .topTrailing) { if game.tutorial == .mirror { BouncingArrow().offset(x: -21, y: -44) } }
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                RepeatButton(symbol: "chevron.left", size: compact ? 36 : 40) { game.nudge(angle: 0.25) }
                VStack(spacing: 1) {
                    Image(systemName: "scope").font(.system(size: 15, weight: .bold))
                    Text("AIM").font(.rounded(9, .black)).tracking(1)
                }
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: compact ? 34 : 40)
                RepeatButton(symbol: "chevron.right", size: compact ? 36 : 40) { game.nudge(angle: -0.25) }
            }
            .opacity(game.aim == nil ? 0.5 : 1)
            .disabled(!game.canAim || game.aim == nil)
            Spacer(minLength: 0)
            PuttButton(enabled: game.canPutt, rolling: game.isRolling) { game.putt() }
                .overlay(alignment: .top) { if game.tutorial == .putt { BouncingArrow().offset(y: -44) } }
        }
    }

    /// The nine's scorecard in the column left of an upright course, when it's wide enough to read: an iPad, or a Duo
    /// opened and held upright. Phones don't have the room, and a turned course fills the width.
    @ViewBuilder
    private func holePanel(_ geo: GeometryProxy) -> some View {
        let course = localCourseFrame(geo)
        let column = course.minX
        if !game.courseTurned, course.width > 0, column - 24 >= 120 {
            HolePanel(game: game, width: min(column - 24, 250))
                .position(x: column / 2, y: course.midY)
        }
    }

    @ViewBuilder
    private func powerMeter(_ geo: GeometryProxy) -> some View {
        let frame = localCourseFrame(geo)
        if frame.width > 0 {
            let x = min(frame.maxX + (geo.size.width - frame.maxX) / 2, geo.size.width - 24)
            PowerMeter(power: game.aim?.power, enabled: game.canAim,
                       nudge: { game.nudge(power: $0) }, set: { game.setPower($0) })
                .frame(height: GameScene.powerMeterHeight(courseHeight: frame.height))
                .position(x: x, y: frame.midY)
        }
    }
}

// MARK: - HUD pieces

private struct ScoreChip: View {
    let index: Int
    let strokes: Int
    let sunk: Bool

    var body: some View {
        HStack(spacing: 5) {
            BallGlyph(index: index, size: 16)
            Text("\(strokes)").font(.rounded(18, .heavy).monospacedDigit())
            if sunk { Image(systemName: "checkmark").font(.system(size: 11, weight: .black)) }
        }
        .foregroundStyle(sunk ? Color.ink : .white)
        .padding(.leading, 6).padding(.trailing, 10)
        .frame(height: 34)
        .background {
            Capsule().fill(sunk ? AnyShapeStyle(Color.side(index)) : AnyShapeStyle(.ultraThinMaterial))
        }
        .overlay(Capsule().strokeBorder(Color.side(index).opacity(0.9), lineWidth: 2))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sunk)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: strokes)
    }
}

private struct SwingToggle: View {
    let mirrored: Bool
    /// The course is turned, one green above the other: the arrows turn with it, so Mirror reads top to bottom.
    var turned = false
    var segment: CGFloat = 58
    let set: (Bool) -> Void

    var body: some View {
        HStack(spacing: 2) {
            segment("Same", icons: ["arrow.up.right", "arrow.up.right"], selected: !mirrored) { set(false) }
            segment("Mirror", icons: ["arrow.up.left", "arrow.up.right"], selected: mirrored) { set(true) }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        .sensoryFeedback(.selection, trigger: mirrored)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: mirrored)
    }

    private func segment(_ title: String, icons: [String], selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 2) { ForEach(icons.indices, id: \.self) { Image(systemName: icons[$0]) } }
                    .font(.system(size: 12, weight: .black))
                    .rotationEffect(.degrees(turned ? 90 : 0))
                Text(title).font(.rounded(12, .heavy))
            }
            .frame(width: segment, height: 48)
            .foregroundStyle(selected ? Color.ink : .white.opacity(0.85))
            .background(Capsule().fill(selected ? Color.cream : .clear))
        }
        .buttonStyle(PressStyle())
    }
}

private struct PuttButton: View {
    let enabled: Bool
    let rolling: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                PutterGlyph().frame(width: 18, height: 24)
                Text(rolling ? "…" : "PUTT").font(.rounded(21, .black))
            }
            .foregroundStyle(enabled ? Color.ink : .white.opacity(0.5))
            .frame(minWidth: 86, maxWidth: 112)
            .frame(height: 54)
            .background(
                Capsule().fill(enabled ? Color.putt : Color.white.opacity(0.12))
                    .shadow(color: .black.opacity(enabled ? 0.35 : 0), radius: 0, y: 4)
            )
            .overlay(Capsule().strokeBorder(.white.opacity(enabled ? 0.5 : 0.15), lineWidth: 1.5))
        }
        .buttonStyle(PressStyle(scale: 0.94))
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.2), value: enabled)
    }
}

/// A little putter: shaft, grip and a flat blade head (SF Symbols only has a full swing).
private struct PutterGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var shaft = Path()
            shaft.move(to: CGPoint(x: w * 0.78, y: h * 0.04))
            shaft.addLine(to: CGPoint(x: w * 0.34, y: h * 0.80))
            ctx.stroke(shaft, with: .foreground, style: StrokeStyle(lineWidth: w * 0.14, lineCap: .round))
            var grip = Path()
            grip.move(to: CGPoint(x: w * 0.78, y: h * 0.04))
            grip.addLine(to: CGPoint(x: w * 0.66, y: h * 0.25))
            ctx.stroke(grip, with: .foreground, style: StrokeStyle(lineWidth: w * 0.24, lineCap: .round))
            let head = Path(roundedRect: CGRect(x: 0, y: h * 0.72, width: w * 0.66, height: h * 0.26), cornerRadius: h * 0.08)
            ctx.fill(head, with: .foreground)
        }
    }
}

/// Tap to step once; hold to repeat, speeding up.
private struct RepeatButton: View {
    let symbol: String
    var size: CGFloat = 40
    let action: () -> Void
    @State private var task: Task<Void, Never>?
    @State private var pressed = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isEnabled, task == nil else { return }
                        pressed = true
                        task = Task { @MainActor in
                            action()
                            UISelectionFeedbackGenerator().selectionChanged()
                            SoundFX.shared.tick()
                            try? await Task.sleep(for: .milliseconds(380))
                            var n = 0
                            while !Task.isCancelled {
                                action()
                                if n % 3 == 0 { UISelectionFeedbackGenerator().selectionChanged() }
                                n += 1
                                try? await Task.sleep(for: .milliseconds(n > 15 ? 30 : 75))
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        task?.cancel()
                        task = nil
                    }
            )
    }
}

private struct PowerMeter: View {
    let power: Double?
    let enabled: Bool
    let nudge: (Double) -> Void
    let set: (Double) -> Void
    @State private var bucket = -1

    var body: some View {
        VStack(spacing: 8) {
            Text(power.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                .font(.rounded(13, .black).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
                .fixedSize()
            RepeatButton(symbol: "plus", size: 30) { nudge(0.01) }
            GeometryReader { g in
                let h = g.size.height
                ZStack(alignment: .bottom) {
                    Capsule().fill(.black.opacity(0.4))
                    LinearGradient(colors: [Color(UIColor(hex: 0x7BD36A)), Color(UIColor(hex: 0xFFD54F)), Color(UIColor(hex: 0xFF8A3D)), Color(UIColor(hex: 0xFF5A5F))],
                                   startPoint: .bottom, endPoint: .top)
                        .frame(height: h)
                        .mask(alignment: .bottom) {
                            Capsule().frame(height: max(h * (power ?? 0), power == nil ? 0 : 10))
                        }
                    VStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { k in
                            Spacer(minLength: 0)
                            Rectangle().fill(.white.opacity(k == 4 ? 0.55 : 0.28)).frame(height: 1).padding(.horizontal, k == 4 ? 3 : 6)
                        }
                        Spacer(minLength: 0)
                    }
                    Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
                }
                .animation(.interactiveSpring(response: 0.15), value: power)
                .contentShape(Rectangle().inset(by: -14))
                .gesture(
                    // Drag (or tap) anywhere on the bar to set power directly.
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard enabled else { return }
                            let p = min(max(1 - v.location.y / h, 0.02), 1)
                            set(p)
                            let b = Int(p * 10)
                            if b != bucket {
                                bucket = b
                                UISelectionFeedbackGenerator().selectionChanged()
                                SoundFX.shared.tick()
                            }
                        }
                        .onEnded { _ in bucket = -1 }
                )
            }
            .frame(width: 22)
            RepeatButton(symbol: "minus", size: 30) { nudge(-0.01) }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .disabled(!enabled)
        .opacity(enabled || power != nil ? 1 : 0.6)
    }
}

private struct HintBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill").foregroundStyle(Color.putt)
            Text(text).font(.rounded(14, .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

private struct TutorialCard: View {
    let step: TutorialStep
    let close: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { k in
                    Capsule().fill(k <= step.rawValue ? Color.putt : .white.opacity(0.3))
                        .frame(width: 5, height: k == step.rawValue ? 12 : 5)
                }
            }
            Text(step.text)
                .font(.rounded(13, .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            .buttonStyle(PressStyle())
        }
        .padding(.leading, 12).padding(.trailing, 8).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal, 10)
        .animation(.spring(response: 0.35), value: step)
    }
}

private struct BouncingArrow: View {
    @State private var up = false

    var body: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(Color.putt)
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
            .offset(y: up ? -8 : 0)
            .onAppear { withAnimation(.easeInOut(duration: 0.5).repeatForever()) { up = true } }
            .allowsHitTesting(false)
    }
}

/// A ghost finger demonstrating the pull-back: down the screen, or to the left when the course is turned (tees on
/// the left).
private struct DragDemo: View {
    let frame: CGRect
    var turned = false
    @State private var t = false

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 44))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            .position(turned ? CGPoint(x: frame.minX + frame.width * 0.4 - (t ? 110 : 0), y: frame.midY - 30)
                             : CGPoint(x: frame.midX + 30, y: frame.minY + frame.height * 0.6 + (t ? 110 : 0)))
            .opacity(t ? 0.25 : 0.95)
            .onAppear { withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: false)) { t = true } }
            .allowsHitTesting(false)
    }
}

// MARK: - Overlays

private struct PauseMenu: View {
    static let maxWidth: CGFloat = 380
    let app: AppState
    private var game: GameModel { app.game }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { game.paused = false }
            VStack(spacing: 12) {
                Text("Paused").font(.rounded(30, .black)).padding(.bottom, 4)
                PillButton(title: "Resume", symbol: "play.fill", fill: .putt) { game.paused = false }
                if !game.inRound {
                    PillButton(title: "Restart Hole", symbol: "arrow.counterclockwise", fill: .white.opacity(0.14), text: .white, height: 50) { game.restart() }
                }
                if game.inRound {
                    PillButton(title: "Scorecard", symbol: "list.number", fill: .white.opacity(0.14), text: .white, height: 50) {
                        game.paused = false
                        game.showScorecard = true
                    }
                    PillButton(title: "Leave Round", symbol: "door.left.hand.open", fill: .white.opacity(0.14), text: .white, height: 50) {
                        game.paused = false
                        game.leaveRound()
                        app.screen = .title
                    }
                } else {
                    PillButton(title: "Free Play", symbol: "square.grid.3x3.fill", fill: .white.opacity(0.14), text: .white, height: 50) {
                        game.paused = false
                        app.backToFreePlay()
                    }
                }
                HStack(spacing: 12) {
                    PillButton(title: app.soundOn ? "Sound On" : "Sound Off", symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                               fill: .white.opacity(0.14), text: .white, height: 46) { app.toggleSound() }
                    PillButton(title: "How to Play", symbol: "questionmark", fill: .white.opacity(0.14), text: .white, height: 46) { game.replayTutorial() }
                }
                if game.devMode {
                    VStack(spacing: 10) {
                        Text("DEV").font(.rounded(11, .black)).tracking(2).foregroundStyle(.white.opacity(0.5))
                        Toggle("Full path guide", isOn: Binding(get: { game.fullPathGuide }, set: { game.fullPathGuide = $0 }))
                            .font(.rounded(15, .semibold))
                            .tint(.putt)
                        HStack(spacing: 12) {
                            PillButton(title: "Show Ace", symbol: "lightbulb.fill", fill: .white.opacity(0.14), text: .white, height: 42) { game.demo() }
                            PillButton(title: "Reset", symbol: "trash", fill: .white.opacity(0.14), text: .white, height: 42) { game.resetProgress() }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            // A phone's width at most, so its buttons don't stretch across an iPad.
            .frame(maxWidth: Self.maxWidth)
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 28)
        }
    }
}

private struct ResultCard: View {
    let app: AppState
    @State private var shown = false
    private var game: GameModel { app.game }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                // Holes earn a trophy for a double ace (medals are for nine-hole rounds).
                if game.strokes == [1, 1] {
                    VStack(spacing: 8) {
                        TrophyView(accent: Color(game.theme.accent), size: 92)
                            .scaleEffect(shown ? 1 : 0.2)
                            .rotationEffect(.degrees(shown ? 0 : -40))
                        if game.newTrophy {
                            Text("NEW TROPHY")
                                .font(.rounded(12, .black)).tracking(1.2)
                                .fixedSize()
                                // Tracking also pads after the last letter; even it out so the text sits centered.
                                .padding(.leading, 11).padding(.trailing, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color.putt))
                                .foregroundStyle(Color.ink)
                                .opacity(shown ? 1 : 0)
                        }
                    }
                }
                Text(game.resultTitle)
                    .font(.rounded(36, .black))
                    .foregroundStyle(game.strokes == [1, 1] ? Color.putt : .white)
                HStack(spacing: 34) {
                    score(0)
                    score(1)
                }
                HStack(spacing: 6) {
                    Text("Total \(game.total) · Par \(game.par)" + (game.inRound ? " · Round \(game.roundToPar.map(GameModel.toPar) ?? "E")" : ""))
                    if game.newBest {
                        Text("NEW BEST")
                            .font(.rounded(11, .black)).tracking(1)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color(game.theme.accent)))
                            .foregroundStyle(Color.ink)
                    } else if let best = game.best {
                        Text("· Best \(best)")
                    }
                }
                .font(.rounded(15, .semibold))
                .foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 12) {
                    if game.inRound {
                        PillButton(title: "Card", symbol: "list.number", fill: .white.opacity(0.14), text: .white, height: 52) {
                            game.showScorecard = true
                        }
                        PillButton(title: game.isLastInRound ? "Finish" : "Next", symbol: game.isLastInRound ? "flag.checkered" : "arrow.right", fill: .putt, height: 52) {
                            game.nextInRound()
                        }
                    } else {
                        PillButton(title: "Retry", symbol: "arrow.counterclockwise", fill: .white.opacity(0.14), text: .white, height: 52) { game.restart() }
                        PillButton(title: game.isLastLevel ? "Free Play" : "Next", symbol: game.isLastLevel ? "square.grid.3x3.fill" : "arrow.right", fill: .putt, height: 52) {
                            if game.isLastLevel { app.backToFreePlay() } else { game.next() }
                        }
                    }
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: PauseMenu.maxWidth)
            .padding(26)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 26)
            .scaleEffect(shown ? 1 : 0.9)
            .opacity(shown ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { shown = true } }
    }

    private func score(_ i: Int) -> some View {
        VStack(spacing: 4) {
            BallGlyph(index: i, size: 22)
            Text("\(game.strokes[i])").font(.rounded(34, .black).monospacedDigit())
        }
        .foregroundStyle(.white)
    }
}
