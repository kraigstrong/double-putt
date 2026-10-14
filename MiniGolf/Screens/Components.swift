import SwiftUI

extension Color {
    init(_ ui: UIColor) { self.init(uiColor: ui) }
    static let ink = Color(Palette.ink)
    static let holeA = Color(Palette.holeA)
    static let holeB = Color(Palette.holeB)
    static func hole(_ i: Int) -> Color { i == 0 ? .holeA : .holeB }
    static let cream = Color(UIColor(hex: 0xFFF8E7))
    static let putt = Color(UIColor(hex: 0xFFC94A))
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Springy press feedback + tap sound for every game button.
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { SoundFX.shared.tap() } }
    }
}

/// Round frosted icon button.
struct GlassIconButton: View {
    let symbol: String
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(PressStyle())
    }
}

/// Big pill button used for primary actions.
struct PillButton: View {
    let title: String
    var symbol: String?
    var fill: Color = .cream
    var text: Color = .ink
    var height: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.rounded(20, .heavy))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule().fill(fill)
                    .shadow(color: .black.opacity(0.3), radius: 0, y: 4)
            )
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5).padding(1))
        }
        .buttonStyle(PressStyle(scale: 0.96))
    }
}

/// A medal: gold = double ace, silver = 3, bronze = par.
struct MedalView: View {
    let medal: Medal
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            if medal == .none {
                Circle().strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            } else {
                Circle()
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                Circle()
                    .strokeBorder(.white.opacity(0.55), lineWidth: size * 0.05)
                    .padding(size * 0.09)
                Image(systemName: medal == .gold ? "star.fill" : "flag.fill")
                    .font(.system(size: size * 0.38, weight: .black))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            }
        }
        .frame(width: size, height: size)
    }

    private var colors: [Color] {
        switch medal {
        case .gold: return [Color(UIColor(hex: 0xFFE27A)), Color(UIColor(hex: 0xF2A900)), Color(UIColor(hex: 0xC77C02))]
        case .silver: return [Color(UIColor(hex: 0xF4F6F8)), Color(UIColor(hex: 0xB8C0C8)), Color(UIColor(hex: 0x7E8790))]
        case .bronze: return [Color(UIColor(hex: 0xF3B786)), Color(UIColor(hex: 0xC97A43)), Color(UIColor(hex: 0x8C4F25))]
        case .none: return []
        }
    }
}

/// Small golf ball glyph in a hole's color, stripe pointing up the line like the in-game balls.
struct BallGlyph: View {
    let index: Int
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.white, Color(UIColor(hex: 0xC4CAD1))], center: .init(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: size * 0.7))
            Rectangle().fill(Color.hole(index)).frame(width: size * 0.32)
            Circle().fill(RadialGradient(colors: [.clear, .clear, .black.opacity(0.28)], center: .init(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: size * 0.7))
            Ellipse().fill(.white.opacity(0.85))
                .frame(width: size * 0.28, height: size * 0.2)
                .offset(x: -size * 0.17, y: -size * 0.19)
            Circle().strokeBorder(.black.opacity(0.22), lineWidth: max(0.8, size * 0.04))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
