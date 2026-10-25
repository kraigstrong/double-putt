import SwiftUI

/// A nine's scorecard, in classic notation: filled circle = double ace, circle = under par, square = over par.
/// A finished round shows its medal.
struct ScorecardView: View {
    let game: GameModel
    /// The round just finished (vs. peeking mid-round).
    let final: Bool
    let close: () -> Void

    private var scores: [Int?] { game.round?.scores ?? [] }
    private var nine: Nine { game.roundNine ?? game.nines[0] }
    private var holes: [Int] { Array(nine.holes) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { if !final { close() } }
            VStack(spacing: 12) {
                if final {
                    let par = game.par(of: nine)
                    let medal = Medal(round: totalSoFar, par: par)
                    HStack(spacing: 14) {
                        MedalView(medal: medal, size: 64)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(nine.name) Complete").font(.rounded(24, .black)).lineLimit(1).minimumScaleFactor(0.7)
                            Text(medal == .none ? "No medal this time" : "\(medal.title) medal")
                                .font(.rounded(15, .heavy))
                                .foregroundStyle(medal == .none ? .white.opacity(0.7) : Color.putt)
                            Text([Medal.bronze, .silver, .gold].map { "\($0.title) \($0.threshold(par: par))" }.joined(separator: " · "))
                                .font(.rounded(11, .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    if let next = game.newlyUnlocked {
                        Label("\(next.name) unlocked!", systemImage: "lock.open.fill")
                            .font(.rounded(15, .heavy))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Capsule().fill(Color.putt))
                            .foregroundStyle(Color.ink)
                    }
                }
                VStack(spacing: 2) {
                    if !final { Text(nine.name).font(.rounded(26, .black)) }
                    if let total = totalSoFar {
                        HStack(spacing: 8) {
                            Text("\(total) strokes").font(.rounded(15, .bold))
                            if let toPar = game.roundToPar {
                                Text(GameModel.toPar(toPar))
                                    .font(.rounded(15, .black))
                                    .foregroundStyle(toPar <= 0 ? Color.putt : .white)
                            }
                            if final && game.newBestRound {
                                Text("BEST ROUND")
                                    .font(.rounded(10, .black)).tracking(1)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.putt))
                                    .foregroundStyle(Color.ink)
                            }
                        }
                        .foregroundStyle(.white.opacity(0.85))
                    }
                }
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        ForEach(Array(holes.enumerated()), id: \.offset) { k, i in
                            row(k, i)
                        }
                        total
                    }
                }
                .frame(maxHeight: 430)
                PillButton(title: final ? "Done" : "Back to Game", symbol: final ? "flag.checkered" : "play.fill", fill: .putt, height: 50, action: close)
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.vertical, 30)
        }
    }

    private var totalSoFar: Int? {
        let done = scores.compactMap { $0 }
        return done.isEmpty ? nil : done.reduce(0, +)
    }

    private var header: some View {
        HStack {
            Text("#").frame(width: 26, alignment: .leading)
            Text("HOLE").frame(maxWidth: .infinity, alignment: .leading)
            Text("PAR").frame(width: 40)
            Text("SCORE").frame(width: 56)
        }
        .font(.rounded(10, .black)).tracking(1)
        .foregroundStyle(.white.opacity(0.5))
        .padding(.vertical, 6)
    }

    /// Row `k` of the nine: course hole `i`.
    private func row(_ k: Int, _ i: Int) -> some View {
        let level = GameModel.levels[i]
        let par = game.par(of: level)
        let score = k < scores.count ? scores[k] : nil
        return HStack {
            Text("\(k + 1)").font(.rounded(13, .bold).monospacedDigit()).foregroundStyle(.white.opacity(0.6)).frame(width: 26, alignment: .leading)
            Text(level.name).font(.rounded(14, .semibold)).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text("\(par)").font(.rounded(14, .semibold).monospacedDigit()).foregroundStyle(.white.opacity(0.7)).frame(width: 40)
            ScoreMark(score: score, par: par).frame(width: 56)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 5)
        .background(i == game.levelIndex && game.inRound && !final ? Color.white.opacity(0.08) : .clear)
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
    }

    private var total: some View {
        let done = scores.compactMap { $0 }
        return HStack {
            Text("TOTAL").font(.rounded(12, .black)).tracking(1).frame(maxWidth: .infinity, alignment: .leading)
            Text("\(game.par(of: nine))").font(.rounded(14, .heavy).monospacedDigit()).frame(width: 40)
            Text(done.isEmpty ? "–" : "\(done.reduce(0, +))").font(.rounded(18, .black).monospacedDigit()).frame(width: 56)
        }
        .foregroundStyle(Color.putt)
        .padding(.vertical, 7)
        .padding(.leading, 26)
        .background(Color.white.opacity(0.1))
    }
}

/// A hole's score in scorecard notation (see ScorecardView), or a dash before it's played.
struct ScoreMark: View {
    let score: Int?
    let par: Int
    var size: CGFloat = 28

    var body: some View {
        if let score {
            Text("\(score)")
                .font(.rounded(size * 0.54, .black).monospacedDigit())
                .foregroundStyle(score <= 2 ? Color.ink : .white)
                .frame(width: size, height: size)
                .background {
                    if score <= 2 {
                        Circle().fill(Color.putt)
                    } else if score < par {
                        Circle().strokeBorder(Color.putt, lineWidth: 2)
                    } else if score > par {
                        RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.5), lineWidth: 1.5)
                    }
                }
        } else {
            Text("–").font(.rounded(15, .bold)).foregroundStyle(.white.opacity(0.35))
        }
    }
}
