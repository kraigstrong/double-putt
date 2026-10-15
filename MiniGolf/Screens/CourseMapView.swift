import SwiftUI

/// Single Hole: every pair, grouped by nine and then by setting. Tapping one plays it on its own (outside a round).
struct CourseMapView: View {
    let app: AppState
    private var game: GameModel { app.game }

    private struct Section: Identifiable {
        let id: Int
        let theme: Theme
        let indices: [Int]
    }

    /// The nine's pairs in runs of the same setting.
    private func sections(_ nine: Nine) -> [Section] {
        var out: [Section] = []
        for i in nine.pairs {
            let level = GameModel.levels[i]
            if let last = out.last, last.theme.id == level.setting {
                out[out.count - 1] = Section(id: last.id, theme: last.theme, indices: last.indices + [i])
            } else {
                out.append(Section(id: i, theme: Theme.for(level), indices: [i]))
            }
        }
        return out
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                GlassIconButton(symbol: "chevron.left", size: 42) { app.screen = .title }
                Spacer()
                VStack(spacing: 2) {
                    Text("Single Hole").font(.rounded(24, .heavy))
                    Text(subtitle).font(.rounded(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(game.nines) { nine in
                        VStack(alignment: .leading, spacing: 14) {
                            let locked = !game.isUnlocked(nine)
                            HStack(alignment: .firstTextBaseline) {
                                Text(nine.name).font(.rounded(22, .black))
                                Spacer()
                                if locked, let before = game.prerequisite(of: nine) {
                                    Label("Earn a medal on \(before.name)", systemImage: "lock.fill")
                                        .font(.rounded(12, .bold)).foregroundStyle(Color.putt)
                                } else {
                                    Text(nineSummary(nine)).font(.rounded(12, .bold)).foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            ForEach(sections(nine)) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text(section.theme.setting.uppercased())
                                            .font(.rounded(12, .black)).tracking(1.5)
                                            .foregroundStyle(Color(section.theme.accent))
                                        Rectangle().fill(Color(section.theme.accent).opacity(0.35)).frame(height: 1)
                                    }
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                        ForEach(section.indices, id: \.self) { i in
                                            let level = GameModel.levels[i]
                                            PairCard(number: game.pairNumber(i), level: level, best: game.best(for: level),
                                                     trophy: game.hasTrophy(level), locked: locked) {
                                                app.play(level: i)
                                            }
                                        }
                                    }
                                }
                            }
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
        .onAppear { MenuArt.shared.prefetch(GameModel.levels) }
    }

    private var subtitle: String {
        let won = GameModel.levels.filter(game.hasTrophy).count
        return "\(GameModel.levels.count) pairs · \(won) \(won == 1 ? "trophy" : "trophies")"
    }

    private func nineSummary(_ nine: Nine) -> String {
        let won = nine.pairs.filter { game.hasTrophy(GameModel.levels[$0]) }.count
        return "Par \(game.par(of: nine)) · \(won)/\(nine.pairs.count) 🏆"
    }
}

private struct PairCard: View {
    let number: Int
    let level: Level
    let best: Int?
    let trophy: Bool
    /// Its course isn't open yet.
    let locked: Bool
    let action: () -> Void

    var body: some View {
        let theme = Theme.for(level)
        let par = level.par[0] + level.par[1]
        Button(action: action) {
            ZStack(alignment: .bottom) {
                Color(theme.rough)
                if let img = MenuArt.shared.card(level) {
                    Image(uiImage: img).resizable().scaledToFill().transition(.opacity)
                }
                LinearGradient(colors: [.clear, .clear, Color.ink.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top) {
                        Text("\(number)")
                            .font(.rounded(12, .black))
                            .foregroundStyle(Color.ink)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(theme.accent)))
                        Spacer()
                        Group {
                            if locked {
                                Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)).frame(width: 20, height: 22)
                            } else {
                                TrophyView(earned: trophy, accent: Color(theme.accent), size: 22)
                            }
                        }
                        .padding(5)
                        .background(Circle().fill(Color.ink.opacity(0.5)))
                    }
                    Spacer()
                    Text(level.name).font(.rounded(13, .heavy)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                    Text(best.map { "Best \($0) · Par \(par)" } ?? "Par \(par)")
                        .font(.rounded(10, .semibold)).foregroundStyle(.white.opacity(0.7))
                }
                .padding(8)
            }
            .aspectRatio(0.62, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
            .animation(.easeOut(duration: 0.3), value: MenuArt.shared.cards[level.name] != nil)
            .opacity(locked ? 0.45 : 1)
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .disabled(locked)
    }
}
