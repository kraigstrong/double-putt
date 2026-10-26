import SwiftUI

/// One trophy per hole, won with a double ace (in a round or Free Play). Each nine is a cabinet of three
/// shelves; tapping a slot plays that hole, or for a hole that needs All Courses, opens the purchase screen.
struct TrophyShelfView: View {
    let app: AppState
    private var game: GameModel { app.game }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                GlassIconButton(symbol: "chevron.left", size: 42) { app.screen = .title }
                Spacer()
                VStack(spacing: 2) {
                    Text("Trophy Shelf").font(.rounded(24, .heavy))
                    Text("\(won(GameModel.levels.indices)) of \(GameModel.levels.count) double aces")
                        .font(.rounded(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
            }
            .padding(.horizontal, 16)

            ScrollView {
                // One cabinet across a phone; side by side on a wider screen, rather than stretched across it.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 20, alignment: .top)], spacing: 24) {
                    ForEach(game.nines) { nine in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(nine.name).font(.rounded(22, .black))
                                Spacer()
                                Text("\(won(nine.holes))/\(nine.holes.count)").font(.rounded(14, .heavy)).foregroundStyle(Color.putt)
                            }
                            cabinet(nine.holes)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(UIColor(hex: 0x2A2016)), Color.ink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func won<C: Collection>(_ indices: C) -> Int where C.Element == Int {
        indices.filter { game.hasTrophy(GameModel.levels[$0]) }.count
    }

    private func cabinet(_ holes: [Int]) -> some View {
        let rows = stride(from: 0, to: holes.count, by: 3).map { Array(holes[$0..<min($0 + 3, holes.count)]) }
        return VStack(spacing: 14) {
            ForEach(rows, id: \.self) { row in
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(row, id: \.self) { i in slot(i) }
                    }
                    .padding(.horizontal, 6)
                    // The plank, with a brass plaque under each trophy.
                    HStack(spacing: 0) {
                        ForEach(row, id: \.self) { i in plaque(i) }
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 26)
                    .background(
                        LinearGradient(colors: [Color(UIColor(hex: 0xB07A45)), Color(UIColor(hex: 0x7A4B24)), Color(UIColor(hex: 0x5E3819))],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(alignment: .top) { Rectangle().fill(Color(UIColor(hex: 0xD49A60))).frame(height: 2) }
                    .shadow(color: .black.opacity(0.45), radius: 4, y: 4)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color(UIColor(hex: 0x3A2514)), Color(UIColor(hex: 0x24170D))], startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(UIColor(hex: 0x8A5A2E)), lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func slot(_ i: Int) -> some View {
        let level = GameModel.levels[i]
        let earned = game.hasTrophy(level)
        let locked = !game.canPlay(i)
        return Button {
            if locked { app.offerUnlock(.trophy, course: game.nine(containing: i)?.id) } else { app.play(level: i) }
        } label: {
            TrophyView(earned: earned, accent: Color(Theme.for(level).accent), size: 62)
                .overlay {
                    if locked {
                        Image(systemName: "lock.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white.opacity(0.55))
                            .offset(y: -6)
                    }
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle(scale: 0.92))
    }

    private func plaque(_ i: Int) -> some View {
        let level = GameModel.levels[i]
        let earned = game.hasTrophy(level)
        return Text("\(game.holeNumber(i)) · \(level.name)")
            .font(.rounded(9, .heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(earned ? Color(UIColor(hex: 0x3B2A10)) : .white.opacity(0.45))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(earned ? AnyShapeStyle(LinearGradient(colors: [Color(UIColor(hex: 0xF4D58A)), Color(UIColor(hex: 0xC9A04A))],
                                                                startPoint: .top, endPoint: .bottom))
                                 : AnyShapeStyle(Color.black.opacity(0.25)))
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
    }
}
