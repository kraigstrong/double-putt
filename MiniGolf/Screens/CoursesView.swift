import SwiftUI

/// Every course as a card with its par, best medal and trophies. Tapping one starts a round; later courses stay
/// locked until the one before has a medal.
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
                VStack(spacing: 12) {
                    ForEach(Array(game.nines.enumerated()), id: \.element.id) { k, nine in
                        CourseCard(number: k + 1, nine: nine, game: game) { play(nine) }
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
        .onAppear { MenuArt.shared.prefetch(game.nines.map { GameModel.levels[$0.pairs.lowerBound] }) }
        .confirmationDialog("Start a new round?", isPresented: Binding(get: { confirmNine != nil }, set: { if !$0 { confirmNine = nil } }),
                            titleVisibility: .visible, presenting: confirmNine) { nine in
            Button("Start \(nine.name)", role: .destructive) { app.playRound(nine) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            if let nine = game.roundNine, let round = game.round {
                Text("This ends your \(nine.name) round. You're on pair \(round.current + 1).")
            }
        }
    }

    private var subtitle: String {
        let medals = game.nines.filter { game.medal($0) != .none }.count
        return "\(game.nines.count) courses · \(medals) \(medals == 1 ? "medal" : "medals")"
    }

    private func play(_ nine: Nine) {
        if let round = game.round, !round.isFinished, round.hasProgress {
            confirmNine = nine
        } else {
            app.playRound(nine)
        }
    }
}

private struct CourseCard: View {
    let number: Int
    let nine: Nine
    let game: GameModel
    let action: () -> Void

    var body: some View {
        let first = GameModel.levels[nine.pairs.lowerBound]
        let theme = Theme.for(first)
        let unlocked = game.isUnlocked(nine)
        let best = game.bestRound(nine)
        let won = nine.pairs.filter { game.hasTrophy(GameModel.levels[$0]) }.count
        let inProgress = game.round.map { $0.nine == nine.id && !$0.isFinished && $0.hasProgress } ?? false
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.rounded(16, .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color(theme.accent)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(nine.name).font(.rounded(21, .heavy))
                    Text(settings).font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.65))
                    if unlocked {
                        Text("Par \(game.par(of: nine)) · \(won)/\(nine.pairs.count) 🏆" + (inProgress ? " · in progress" : ""))
                            .font(.rounded(12, .bold)).foregroundStyle(.white.opacity(0.85))
                    } else if let before = game.prerequisite(of: nine) {
                        Label("Earn a medal on \(before.name)", systemImage: "lock.fill")
                            .font(.rounded(12, .bold)).foregroundStyle(Color.putt)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if unlocked {
                    VStack(spacing: 3) {
                        MedalView(medal: game.medal(nine), size: 36)
                        Text(best.map { "Best \($0)" } ?? "—").font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.75))
                    }
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            .opacity(unlocked ? 1 : 0.6)
        }
        .buttonStyle(PressStyle(scale: 0.97))
        .disabled(!unlocked)
    }

    /// The course's settings in order, e.g. "Meadow · Garden · Moat · Seaside".
    private var settings: String {
        var seen: [String] = []
        for i in nine.pairs where !seen.contains(GameModel.levels[i].setting) { seen.append(GameModel.levels[i].setting) }
        return seen.map { Self.shortNames[$0] ?? $0.capitalized }.joined(separator: " · ")
    }

    /// Setting ids that don't read right capitalized.
    private static let shortNames = ["bigtop": "Big Top"]
}
