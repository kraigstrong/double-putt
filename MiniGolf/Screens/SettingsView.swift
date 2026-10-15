import SwiftUI

/// Settings, from the title screen's gear: sound, the privacy policy and support pages, and the version.
struct SettingsView: View {
    let app: AppState

    static let privacyURL = URL(string: "https://brightbench.app/double-putt/privacy")!
    static let supportURL = URL(string: "https://brightbench.app/support")!

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                GlassIconButton(symbol: "chevron.left", size: 42) { app.screen = .title }
                Spacer()
                Text("Settings").font(.rounded(24, .heavy))
                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 12) {
                    Button { app.toggleSound() } label: {
                        row(symbol: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", title: "Sound") {
                            Text(app.soundOn ? "On" : "Off").font(.rounded(16, .heavy))
                                .foregroundStyle(app.soundOn ? Color.putt : .white.opacity(0.6))
                        }
                    }
                    .buttonStyle(PressStyle(scale: 0.97))

                    Link(destination: Self.privacyURL) {
                        row(symbol: "hand.raised.fill", title: "Privacy Policy") { external }
                    }
                    Link(destination: Self.supportURL) {
                        row(symbol: "questionmark.bubble.fill", title: "Support") { external }
                    }

                    VStack(spacing: 6) {
                        Text(version).font(.rounded(13, .bold)).foregroundStyle(.white.opacity(0.7))
                        Text("Double Putt sends anonymous gameplay counts, like which pairs were finished and in how many strokes, to help tune the courses. No names or device IDs.")
                            .font(.rounded(12, .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
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
    }

    private var external: some View {
        Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.6))
    }

    private func row<Trailing: View>(symbol: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 18, weight: .bold)).frame(width: 26)
            Text(title).font(.rounded(18, .heavy))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
