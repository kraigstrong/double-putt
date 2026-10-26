import SwiftUI

/// Free Play: one row per course, swiped sideways to pick a hole. Tapping one plays it on its own (outside a round).
/// Without All Courses, a first row holds the free hole of every course past the free one, and tapping a locked hole
/// opens the purchase screen.
struct CourseMapView: View {
    let app: AppState
    private var game: GameModel { app.game }

    /// The free row's id among the courses' (for the scroll position).
    static let freeRow = "free"

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                GlassIconButton(symbol: "chevron.left", size: 42) { app.screen = .title }
                Spacer()
                VStack(spacing: 2) {
                    Text("Free Play").font(.rounded(24, .heavy))
                    Text(subtitle).font(.rounded(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                GlassIconButton(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", size: 42) { app.toggleSound() }
            }
            .padding(.horizontal, 16)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if game.hasLockedCourses {
                            freeRow.id(Self.freeRow)
                        }
                        ForEach(game.nines) { nine in
                            CourseRow(nine: nine, game: game, first: first(nine.id)) { open($0, in: nine) }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
                .scrollPosition(id: Binding(get: { app.freePlay.course }, set: { app.freePlay.course = $0 }), anchor: .top)
                // A position set before the scroll view appears doesn't move it, so go back there by hand.
                .onAppear { if let course = app.freePlay.course { proxy.scrollTo(course, anchor: .top) } }
            }
        }
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(UIColor(hex: 0x1B3A28)), Color.ink], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    /// Each course's free hole, labelled with its course.
    private var freeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Try a hole from every course").font(.rounded(22, .black)).lineLimit(1).minimumScaleFactor(0.8)
                Text("Free to play, one from each").font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 16)
            HoleStrip(holes: game.freeHoles, first: first(Self.freeRow)) { i in
                let level = GameModel.levels[i]
                HoleCard(number: game.holeNumber(i), level: level, best: game.best(for: level), trophy: game.hasTrophy(level),
                         course: game.nine(containing: i)?.name) {
                    app.play(level: i)
                }
            }
        }
    }

    private func first(_ row: String) -> Binding<Int?> {
        Binding(get: { app.freePlay.cards[row] }, set: { app.freePlay.cards[row] = $0 })
    }

    private func open(_ hole: Int, in nine: Nine) {
        if game.canPlay(hole) { app.play(level: hole) } else { app.offerUnlock(.hole, course: nine.id) }
    }

    private var subtitle: String {
        let won = GameModel.levels.filter(game.hasTrophy).count
        return "\(GameModel.levels.count) holes · \(won) \(won == 1 ? "trophy" : "trophies")"
    }
}

/// Where Free Play was left, so it opens there again (until the app quits): the course scrolled to the top, and
/// the first card in view on each course's row.
struct FreePlaySpot {
    var course: String?
    var cards: [String: Int] = [:]

    /// Bring a hole's course and card into view, unless they already are.
    mutating func reveal(_ hole: Int, in nines: [Nine]) {
        guard let k = nines.firstIndex(where: { $0.holes.contains(hole) }) else { return }
        let nine = nines[k]
        // Two cards show in full. Bring the hole in second, so the one before it shows too.
        let first = cards[nine.id] ?? nine.holes[0]
        if !(first...first + 1).contains(hole) { cards[nine.id] = max(hole - 1, nine.holes[0]) }
        // So do two courses.
        let top = course.flatMap { id in nines.firstIndex { $0.id == id } } ?? 0
        if !(top...top + 1).contains(k) { course = nine.id }
    }
}

/// A course's name and settings over its holes. Without All Courses, a locked course's holes show a lock, and its
/// free hole says so.
struct CourseRow: View {
    let nine: Nine
    let game: GameModel
    /// The first card in view.
    @Binding var first: Int?
    let play: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(nine.name).font(.rounded(22, .black))
                    Spacer()
                    Text(summary).font(.rounded(12, .bold)).foregroundStyle(.white.opacity(0.6))
                }
                // A one-setting course's line would only repeat its name ("Midway", "The Links").
                if !nine.name.localizedCaseInsensitiveContains(nine.settingNames) {
                    Text(nine.settingNames).font(.rounded(11, .bold)).foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 16)

            let locked = !game.canPlayRound(nine)
            HoleStrip(holes: nine.holes, first: $first) { i in
                let level = GameModel.levels[i]
                HoleCard(number: game.holeNumber(i), level: level, best: game.best(for: level), trophy: game.hasTrophy(level),
                         locked: !game.canPlay(i), free: locked && game.isFree(i)) {
                    play(i)
                }
            }
        }
    }

    private var summary: String {
        let won = nine.holes.filter { game.hasTrophy(GameModel.levels[$0]) }.count
        return "Par \(game.par(of: nine)) · \(won)/\(nine.holes.count) 🏆"
    }

    /// A card's width in a row `length` wide: two and a half cards across a phone, so the cut-off one says the row
    /// swipes, and on a wider screen as many more as fit at about that size (still ending on a half).
    static func cardWidth(in length: CGFloat) -> CGFloat {
        let count = max(5, Int(2 * length / 190) | 1)
        return (length - CGFloat(count - 1) * 10) / CGFloat(count) * 2 + 10
    }
}

/// Hole cards in a row that swipes sideways and settles on a card. Cards ease smaller and dimmer as they slide off
/// either edge.
struct HoleStrip<Card: View>: View {
    let holes: [Int]
    /// The first card in view.
    @Binding var first: Int?
    @ViewBuilder let card: (Int) -> Card

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(holes, id: \.self) { i in
                        card(i)
                            .containerRelativeFrame(.horizontal) { length, _ in CourseRow.cardWidth(in: length) }
                            .scrollTransition(.interactive, axis: .horizontal) { card, phase in
                                card.scaleEffect(1 - abs(phase.value) * 0.12).opacity(1 - abs(phase.value) * 0.5)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $first)
            .onAppear { if let first { proxy.scrollTo(first, anchor: .leading) } }
            .scrollIndicators(.hidden)
            // Let the card shadows spill below the row.
            .scrollClipDisabled()
        }
    }
}

private struct HoleCard: View {
    let number: Int
    let level: Level
    let best: Int?
    let trophy: Bool
    /// The hole's course, named over the hole (in the free row, where the row isn't a course).
    var course: String?
    /// Needs All Courses: tapping it opens the purchase screen.
    var locked = false
    /// The free hole of a locked course.
    var free = false
    let action: () -> Void

    var body: some View {
        let theme = Theme.for(level)
        let par = level.par[0] + level.par[1]
        Button(action: action) {
            // The backdrop sets the card's shape; the art and labels sit over it, so the art can't stretch the card.
            Color(theme.rough)
                .aspectRatio(CourseArt.cardAspect, contentMode: .fit)
                .overlay {
                    if let img = MenuArt.shared.card(level) {
                        // The art spills past the card before it's clipped; don't let the spill catch taps.
                        Image(uiImage: img).resizable().scaledToFill().allowsHitTesting(false)
                    }
                }
                .overlay {
                    LinearGradient(colors: [.clear, .clear, Color.ink.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                }
                .overlay {
                    if locked { Color.ink.opacity(0.45) }
                }
                .overlay {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(number)")
                                .font(.rounded(13, .black))
                                .foregroundStyle(Color.ink)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color(theme.accent)))
                            if free {
                                Text("FREE")
                                    .font(.rounded(10, .black)).tracking(0.8)
                                    .padding(.horizontal, 7).frame(height: 20)
                                    .background(Capsule().fill(Color.putt))
                                    .foregroundStyle(Color.ink)
                                    .padding(.top, 2)
                            }
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
                        if let course {
                            Text(course.uppercased()).font(.rounded(10, .black)).tracking(0.8)
                                .foregroundStyle(Color(theme.accent)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        Text(level.name).font(.rounded(15, .heavy)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                        Text(best.map { "Best \($0) · Par \(par)" } ?? "Par \(par)")
                            .font(.rounded(11, .semibold)).foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
        }
        .buttonStyle(PressStyle(scale: 0.95))
    }
}
