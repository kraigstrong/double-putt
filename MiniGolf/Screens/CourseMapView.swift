import SwiftUI

/// All pairs, grouped into their settings. Tapping one plays it on its own (outside the round).
struct CourseMapView: View {
    let app: AppState
    private var game: GameModel { app.game }

    private struct Section: Identifiable {
        let id: Int
        let theme: Theme
        let indices: [Int]
    }

    private var sections: [Section] {
        var out: [Section] = []
        for (i, level) in Levels.course.enumerated() {
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
                    Text("The Course").font(.rounded(24, .heavy))
                    Text(subtitle).font(.rounded(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(section.theme.setting.uppercased())
                                    .font(.rounded(12, .black)).tracking(1.5)
                                    .foregroundStyle(Color(section.theme.accent))
                                Rectangle().fill(Color(section.theme.accent).opacity(0.35)).frame(height: 1)
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                ForEach(section.indices, id: \.self) { i in
                                    PairCard(index: i, level: Levels.course[i], best: game.best(for: Levels.course[i])) {
                                        app.play(level: i)
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
        .background(
            LinearGradient(colors: [Color(UIColor(hex: 0x1B3A28)), Color.ink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear { MenuArt.shared.prefetch(Levels.course) }
    }

    private var subtitle: String {
        let golds = Levels.course.filter { Medal(score: game.best(for: $0), par: game.par(of: $0)) == .gold }.count
        var s = "\(Levels.course.count) pairs · Par \(game.coursePar) · \(golds) double aces"
        if let best = game.bestRound { s += " · Best \(best)" }
        return s
    }
}

private struct PairCard: View {
    let index: Int
    let level: Level
    let best: Int?
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
                    HStack {
                        Text("\(index + 1)")
                            .font(.rounded(12, .black))
                            .foregroundStyle(Color.ink)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(theme.accent)))
                        Spacer()
                        MedalView(medal: Medal(score: best, par: par), size: 24)
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
        }
        .buttonStyle(PressStyle(scale: 0.95))
    }
}
