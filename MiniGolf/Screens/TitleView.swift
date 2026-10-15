import SwiftUI

struct TitleView: View {
    let app: AppState
    @State private var zoom = false
    @State private var appeared = false
    @State private var devToast: String?
    private var game: GameModel { app.game }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: MenuArt.shared.title(size: geo.size))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(zoom ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 14).repeatForever(autoreverses: true), value: zoom)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(colors: [.black.opacity(0.35), .clear, .clear, Color.ink.opacity(0.85), Color.ink],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                    logo
                        .padding(.bottom, geo.size.height * 0.16)
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                        .onLongPressGesture(minimumDuration: 1.0) {
                            app.game.toggleDevMode()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            withAnimation { devToast = app.game.devMode ? "Dev mode on" : "Dev mode off" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { devToast = nil } }
                        }
                    Spacer()

                    VStack(spacing: 12) {
                        let continuing = game.round.map { !$0.isFinished } ?? false
                        if continuing, let round = game.round, let nine = game.roundNine {
                            PillButton(title: "Continue \(nine.name) · Pair \(round.current + 1)", symbol: "play.fill", fill: .putt) {
                                app.continueRound()
                            }
                        }
                        PillButton(title: "Courses", symbol: continuing ? "flag.fill" : "play.fill",
                                   fill: continuing ? .white.opacity(0.14) : .putt, text: continuing ? .white : .ink,
                                   height: continuing ? 50 : 56) {
                            app.screen = .courses
                        }
                        HStack(spacing: 12) {
                            PillButton(title: "Single Hole", symbol: "square.grid.3x3.fill", fill: .white.opacity(0.14), text: .white, height: 48) {
                                app.screen = .levels
                            }
                            PillButton(title: "Trophies", symbol: "trophy.fill", fill: .white.opacity(0.14), text: .white, height: 48) {
                                app.screen = .trophies
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                }

                if let devToast {
                    Text(devToast)
                        .font(.rounded(15, .bold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            zoom = true
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) { appeared = true }
        }
    }

    private var logo: some View {
        VStack(spacing: 6) {
            // The hard drop is the wordmark's 3D edge; on small text it reads as a doubled line.
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    BallGlyph(index: 0, size: 30)
                    BallGlyph(index: 1, size: 30)
                }
                .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                Text("DOUBLE")
                    .font(.rounded(58, .black))
                    .kerning(2)
                Text("PUTT")
                    .font(.rounded(86, .black))
                    .kerning(4)
                    .padding(.top, -26)
            }
            .shadow(color: Color.ink.opacity(0.6), radius: 0, x: 0, y: 5)
            Text("One swing. Two holes.")
                .font(.rounded(17, .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: Color.ink.opacity(0.7), radius: 3, y: 1)
                .padding(.top, -6)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }
}
