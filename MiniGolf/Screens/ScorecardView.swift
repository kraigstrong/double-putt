import SwiftUI

/// The round's scorecard, in classic notation: circle = under par, double circle = double ace, square = over par.
struct ScorecardView: View {
    let game: GameModel
    /// The round just finished (vs. peeking mid-round).
    let final: Bool
    let close: () -> Void

    private var scores: [Int?] { game.round?.scores ?? [] }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { if !final { close() } }
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(final ? "Round Complete" : "Scorecard").font(.rounded(26, .black))
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
                        ForEach(Array(Levels.course.enumerated()), id: \.offset) { i, level in
                            row(i, level)
                            if i == 8 { subtotal("OUT", 0..<9) }
                        }
                        subtotal("IN", 9..<Levels.course.count)
                        subtotal("TOTAL", 0..<Levels.course.count, strong: true)
                    }
                }
                .frame(maxHeight: 520)
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
            Text("PAIR").frame(maxWidth: .infinity, alignment: .leading)
            Text("PAR").frame(width: 40)
            Text("SCORE").frame(width: 56)
        }
        .font(.rounded(10, .black)).tracking(1)
        .foregroundStyle(.white.opacity(0.5))
        .padding(.vertical, 6)
    }

    private func row(_ i: Int, _ level: Level) -> some View {
        let par = game.par(of: level)
        let score = i < scores.count ? scores[i] : nil
        return HStack {
            Text("\(i + 1)").font(.rounded(13, .bold).monospacedDigit()).foregroundStyle(.white.opacity(0.6)).frame(width: 26, alignment: .leading)
            Text(level.name).font(.rounded(14, .semibold)).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            Text("\(par)").font(.rounded(14, .semibold).monospacedDigit()).foregroundStyle(.white.opacity(0.7)).frame(width: 40)
            ScoreMark(score: score, par: par).frame(width: 56)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 5)
        .background(i == game.levelIndex && game.inRound && !final ? Color.white.opacity(0.08) : .clear)
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
    }

    private func subtotal(_ label: String, _ range: Range<Int>, strong: Bool = false) -> some View {
        let levels = Levels.course
        let par = range.reduce(0) { $0 + game.par(of: levels[$1]) }
        let done = range.compactMap { $0 < scores.count ? scores[$0] : nil }
        return HStack {
            Text(label).font(.rounded(12, .black)).tracking(1).frame(maxWidth: .infinity, alignment: .leading)
            Text("\(par)").font(.rounded(14, .heavy).monospacedDigit()).frame(width: 40)
            Text(done.isEmpty ? "–" : "\(done.reduce(0, +))").font(.rounded(strong ? 18 : 15, .black).monospacedDigit()).frame(width: 56)
        }
        .foregroundStyle(strong ? Color.putt : .white)
        .padding(.vertical, 7)
        .padding(.leading, 26)
        .background(Color.white.opacity(strong ? 0.1 : 0.05))
    }
}

private struct ScoreMark: View {
    let score: Int?
    let par: Int

    var body: some View {
        if let score {
            Text("\(score)")
                .font(.rounded(15, .black).monospacedDigit())
                .foregroundStyle(score <= 2 ? Color.ink : .white)
                .frame(width: 28, height: 28)
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
