import SwiftUI

/// Every course as a card with its par, best medal and trophies. Tapping one starts a round, or for a course that
/// needs All Courses, opens the purchase screen. While some course is locked, the Sampler (a free hole from each)
/// follows the free course.
struct CoursesView: View {
    let app: AppState
    /// Starting this nine would end the round in progress, so ask first.
    @State private var confirmNine: Nine?
    private var game: GameModel { app.game }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                GlassIconButton(symbol: "chevron.left", size: 42) { app.screen = .title }
                Spacer()
                VStack(spacing: 2) {
                    Text("Courses").font(.rounded(24, .heavy))
                    Text(subtitle).font(.rounded(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
            }
            .padding(.horizontal, 16)

            ScrollView {
                // One column on a phone; side by side on a wider screen, rather than stretching across it.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 12)], spacing: 12) {
                    ForEach(Array(game.nines.enumerated()), id: \.element.id) { k, nine in
                        CourseCard(number: k + 1, nine: nine, game: game) { play(nine) }
                        if nine.id == Levels.freeCourse && game.hasLockedCourses, let sampler = game.sampler {
                            CourseCard(number: nil, nine: sampler, game: game) { play(sampler) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(UIColor(hex: 0x1B3A28)), Color.ink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .confirmationDialog("Start a new round?", isPresented: Binding(get: { confirmNine != nil }, set: { if !$0 { confirmNine = nil } }),
                            titleVisibility: .visible, presenting: confirmNine) { nine in
            Button("Start \(nine.name)", role: .destructive) { app.playRound(nine) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            if let nine = game.roundNine, let round = game.round {
                Text("This ends your \(nine.name) round. You're on hole \(round.current + 1).")
            }
        }
    }

    private var subtitle: String {
        let medals = game.nines.filter { game.medal($0) != .none }.count
        return "\(game.nines.count) courses · \(medals) \(medals == 1 ? "medal" : "medals")"
    }

    private func play(_ nine: Nine) {
        if !game.canPlayRound(nine) {
            app.offerUnlock(.course, course: nine.id)
        } else if let round = game.round, !round.isFinished, round.hasProgress {
            confirmNine = nine
        } else {
            app.playRound(nine)
        }
    }
}

private struct CourseCard: View {
    /// Its place in the list; none for the Sampler, which isn't a course of its own.
    let number: Int?
    let nine: Nine
    let game: GameModel
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let first = GameModel.levels[nine.holes[0]]
        let theme = Theme.for(first)
        let locked = !game.canPlayRound(nine)
        let best = game.bestRound(nine)
        let won = nine.holes.filter { game.hasTrophy(GameModel.levels[$0]) }.count
        let inProgress = game.round.map { $0.nine == nine.id && !$0.isFinished && $0.hasProgress } ?? false
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if let number { Text("\(number)") } else { Image(systemName: "sparkles") }
                }
                .font(.rounded(16, .black))
                .foregroundStyle(Color.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(theme.accent)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(nine.name).font(.rounded(21, .heavy))
                    Text(number == nil ? "One hole from every course" : nine.settingNames)
                        .font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.65))
                    Text("Par \(game.par(of: nine)) · \(won)/\(nine.holes.count) 🏆" + (inProgress ? " · in progress" : ""))
                        .font(.rounded(12, .bold)).foregroundStyle(.white.opacity(0.85))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if locked {
                    VStack(spacing: 5) {
                        Image(systemName: "lock.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 30)
                        Text("Unlock").font(.rounded(11, .heavy)).foregroundStyle(Color.putt)
                    }
                } else {
                    VStack(spacing: 3) {
                        MedalView(medal: game.medal(nine), size: 36)
                        Text(best.map { "Best \($0)" } ?? "—").font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(14)
            // Side by side on a big screen, the cards stand taller and show more of their course.
            .frame(maxWidth: .infinity, minHeight: sizeClass == .regular ? 150 : nil, alignment: .leading)
            .background {
                ZStack {
                    Color(theme.rough)
                    if let img = MenuArt.shared.card(first) {
                        Image(uiImage: img).resizable().scaledToFill().opacity(0.45)
                    }
                    LinearGradient(colors: [Color.ink.opacity(0.9), Color.ink.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                }
                // The art fills a wide card from a tall image, so it spills far past the card; clipping hides that
                // but doesn't stop it catching taps meant for the cards around it.
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
        }
        .buttonStyle(PressStyle(scale: 0.97))
    }
}

extension Nine {
    /// The course's settings in order, e.g. "Meadow · Garden · Moat · Seaside".
    @MainActor var settingNames: String {
        var seen: [String] = []
        for i in holes where !seen.contains(GameModel.levels[i].setting) { seen.append(GameModel.levels[i].setting) }
        return seen.map { Self.shortNames[$0] ?? $0.capitalized }.joined(separator: " · ")
    }

    /// Setting ids that don't read right capitalized.
    private static let shortNames = ["bigtop": "Big Top"]
}
