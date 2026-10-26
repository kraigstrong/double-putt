import SwiftUI

/// What opened the purchase screen. The raw values are what the purchase screen's analytics will report.
struct UnlockOffer: Equatable {
    enum Source: String {
        /// A finished round's scorecard.
        case scorecard
        /// The result card after a free hole.
        case freeHole = "free_hole"
        /// A locked course on the Courses screen.
        case course
        /// A locked hole in Free Play.
        case hole
        /// A locked hole on the Trophy Shelf.
        case trophy
        /// Settings' Unlock row.
        case settings
        /// Continue on a saved round of a course that isn't open.
        case round
    }

    let source: Source
    /// The course it was opened about (none from Settings).
    var course: String?
}

/// The All Courses purchase: the courses it opens, the price, and Restore. Laid over whatever screen opened it.
struct UnlockView: View {
    let app: AppState
    let offer: UnlockOffer

    private enum Phase: Equatable { case offer, buying, restoring, pending, failed(String) }
    @State private var phase = Phase.offer

    private var game: GameModel { app.game }
    private var purchases: Purchases { game.purchases }
    private var busy: Bool { phase == .buying || phase == .restoring }
    /// The courses players get (Debug builds also play the ones still in development, which are never locked).
    private var released: [Nine] { game.nines.filter { !Levels.inDevelopment.contains($0.id) } }
    /// Every course but the free one: what the purchase opens.
    private var courses: [Nine] { released.filter { $0.id != Levels.freeCourse } }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { close() }
            ViewThatFits(in: .vertical) {
                card
                ScrollView { card }.scrollIndicators(.hidden)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .foregroundStyle(.white)
        .task { await purchases.loadProduct() }
    }

    private var card: some View {
        VStack(spacing: 14) {
            if purchases.ownsAllCourses { owned } else { pitch }
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            GlassIconButton(symbol: "xmark", size: 34) { close() }.padding(12).opacity(busy ? 0.4 : 1)
        }
    }

    @ViewBuilder private var pitch: some View {
        VStack(spacing: 4) {
            Text("Unlock all \(released.reduce(0) { $0 + $1.holes.count }) holes").font(.rounded(26, .black)).lineLimit(1).minimumScaleFactor(0.7)
            Text("One purchase, yours to keep.").font(.rounded(15, .semibold)).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 30)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
            ForEach(courses) { tile($0) }
        }
        VStack(alignment: .leading, spacing: 7) {
            perk("Every course, and every one we add")
            perk("Shared with your family")
            perk("No ads, no subscriptions")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        PillButton(title: buyTitle, symbol: busy ? nil : "lock.open.fill", fill: .putt, height: 54) { buy() }
            .disabled(busy)
            .padding(.top, 4)
        if let note { Text(note).font(.rounded(13, .semibold)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center) }
        Button { restore() } label: {
            Text(phase == .restoring ? "Checking…" : "Restore Purchase").font(.rounded(14, .bold)).foregroundStyle(.white.opacity(0.7))
                .padding(.vertical, 4).padding(.horizontal, 12).contentShape(Rectangle())
        }
        .buttonStyle(PressStyle(scale: 0.95))
        .disabled(busy)
    }

    @ViewBuilder private var owned: some View {
        Image(systemName: "checkmark.circle.fill").font(.system(size: 56, weight: .bold)).foregroundStyle(Color.putt)
            .padding(.top, 6)
        VStack(spacing: 4) {
            Text("Every course is open").font(.rounded(26, .black)).lineLimit(1).minimumScaleFactor(0.7)
            Text("Thanks for playing Double Putt.").font(.rounded(15, .semibold)).foregroundStyle(.white.opacity(0.7))
        }
        PillButton(title: "Let's Play", symbol: "play.fill", fill: .putt, height: 54) { app.unlockOffer = nil }
            .padding(.top, 6)
    }

    private func tile(_ nine: Nine) -> some View {
        let first = GameModel.levels[nine.holes.lowerBound]
        return VStack(spacing: 4) {
            Color(Theme.for(first).rough)
                .aspectRatio(1.25, contentMode: .fit)
                .overlay {
                    if let img = MenuArt.shared.card(first) { Image(uiImage: img).resizable().scaledToFill() }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
            Text(nine.name).font(.rounded(11, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func perk(_ text: String) -> some View {
        Label {
            Text(text).font(.rounded(15, .bold))
        } icon: {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .black)).foregroundStyle(Color.putt)
        }
    }

    private var buyTitle: String {
        switch phase {
        case .buying: return "One moment…"
        default: return purchases.displayPrice.map { "Unlock for \($0)" } ?? "Unlock"
        }
    }

    private var note: String? {
        switch phase {
        case .pending: return "Waiting for approval. Every course opens as soon as it's approved."
        case .failed(let message): return message
        default: return nil
        }
    }

    private func buy() {
        phase = .buying
        Task {
            switch await purchases.purchase() {
            case .bought, .cancelled: phase = .offer
            case .pending: phase = .pending
            case .failed:
                phase = .failed(purchases.product == nil ? "Can't reach the App Store right now. Try again in a moment."
                                                         : "That didn't go through. Try again.")
            }
        }
    }

    private func restore() {
        phase = .restoring
        Task {
            phase = await purchases.restore() ? .offer : .failed("There's no purchase to restore on this Apple Account.")
        }
    }

    private func close() {
        guard !busy else { return }
        app.unlockOffer = nil
    }
}
