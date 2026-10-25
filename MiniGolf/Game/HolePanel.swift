import SwiftUI

/// The nine you're on, beside the course when the screen leaves a column free (an iPad, or a Duo opened and held
/// upright): its holes with their pars, this round's scores (or your bests, in Free Play) and the hole you're on.
struct HolePanel: View {
    let game: GameModel
    let width: CGFloat

    private var nine: Nine? { game.inRound ? game.roundNine : game.nine(containing: game.levelIndex) }
    /// Room for the holes' names as well as their numbers.
    private var roomy: Bool { width >= 190 }

    var body: some View {
        if let nine {
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text(game.theme.setting.uppercased())
                        .font(.rounded(10, .black)).tracking(1.2)
                        .foregroundStyle(Color(game.theme.accent))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(nine.name).font(.rounded(20, .black)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(game.inRound ? "ROUND" : "FREE PLAY")
                        .font(.rounded(10, .black)).tracking(1.2)
                        .foregroundStyle(.white.opacity(0.55))
                }
                VStack(spacing: 0) {
                    ForEach(Array(nine.holes.enumerated()), id: \.offset) { k, i in row(k, i, nine) }
                    footer(nine)
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14).padding(.horizontal, 10)
            .frame(width: width)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .animation(.easeInOut(duration: 0.25), value: game.levelIndex)
        }
    }

    /// Row `k` of the nine: course hole `i`, with this round's score for it, or in Free Play your best.
    private func row(_ k: Int, _ i: Int, _ nine: Nine) -> some View {
        let level = GameModel.levels[i]
        let par = game.par(of: level)
        let here = i == game.levelIndex
        let score: Int? = game.inRound ? game.round.flatMap { k < $0.scores.count ? $0.scores[k] : nil } : game.bests[level.name]
        return HStack(spacing: 6) {
            Text("\(k + 1)").font(.rounded(13, .heavy).monospacedDigit())
                .foregroundStyle(here ? Color.ink : .white.opacity(0.6))
                .frame(width: 22, height: 22)
                .background(Circle().fill(here ? Color.putt : .clear))
            if roomy {
                Text(level.name).font(.rounded(13, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
            if game.trophies[level.name] != nil {
                Image(systemName: "trophy.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.putt)
            }
            Text("\(par)").font(.rounded(13, .semibold).monospacedDigit()).foregroundStyle(.white.opacity(0.6)).frame(width: 18)
            ScoreMark(score: score, par: par, size: 24).frame(width: 30)
        }
        .padding(.horizontal, 4).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 8).fill(here ? Color.white.opacity(0.1) : .clear))
    }

    private func footer(_ nine: Nine) -> some View {
        HStack {
            Text(game.inRound ? "ROUND" : "PAR").font(.rounded(11, .black)).tracking(1)
            Spacer(minLength: 0)
            if game.inRound {
                Text(game.roundToPar.map(GameModel.toPar) ?? "E").font(.rounded(17, .black).monospacedDigit())
            } else {
                Text("\(game.par(of: nine))").font(.rounded(17, .black).monospacedDigit())
            }
        }
        .foregroundStyle(Color.putt)
        .padding(.horizontal, 8).padding(.top, 8)
    }
}
