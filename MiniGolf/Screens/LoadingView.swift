import SwiftUI

/// Shown at launch while the menu art loads (see MenuArt). From the cache that's a blink; the first launch of a new
/// build draws it all, which takes a few seconds. It starts as the launch screen's plain ink and only shows its balls
/// and bar if the wait runs on, so a quick load looks like no loading screen at all.
struct LoadingView: View {
    let app: AppState
    @State private var progress = 0.0
    @State private var shown = false
    @Environment(\.displayScale) private var scale

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 22) {
                HStack(spacing: 14) {
                    BallGlyph(index: 0, size: 34).offset(y: shown ? -8 : 0)
                    BallGlyph(index: 1, size: 34).offset(y: shown ? 0 : -8)
                }
                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: shown)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(width: 200, height: 8)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Color.putt).frame(width: 8 + 192 * progress)
                    }
                    .animation(.easeOut(duration: 0.2), value: progress)
                Text("Setting up the greens…")
                    .font(.rounded(15, .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(shown ? 1 : 0)
            .task {
                // The title's backdrop is drawn for this size, which is the title screen's too.
                await MenuArt.shared.prepare(GameModel.levels, screen: geo.size, scale: scale) { progress = $0 }
                withAnimation(.easeInOut(duration: 0.35)) { app.artReady = true }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.3)) { shown = true }
        }
    }
}
