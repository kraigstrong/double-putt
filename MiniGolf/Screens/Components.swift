import SwiftUI

extension Color {
    init(_ ui: UIColor) { self.init(uiColor: ui) }
    static let ink = Color(Palette.ink)
    static let sideA = Color(Palette.sideA)
    static let sideB = Color(Palette.sideB)
    static func side(_ i: Int) -> Color { i == 0 ? .sideA : .sideB }
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
                Text(title).lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12)
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

/// A nine-pair round's medal (see Medal for the thresholds).
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

/// A pair's double-ace trophy: a gold cup with a gem in the pair's setting color, or a dashed outline until it's won.
struct TrophyView: View {
    var earned = true
    var accent: Color = .putt
    /// Height; the cup is a little narrower.
    var size: CGFloat = 44

    var body: some View {
        let h = size
        ZStack {
            if earned {
                TrophyHandles().stroke(Color(UIColor(hex: 0xD99A0B)), lineWidth: h * 0.055)
                TrophyBody().fill(LinearGradient(colors: [Color(UIColor(hex: 0xFFE27A)), Color(UIColor(hex: 0xF2A900)), Color(UIColor(hex: 0xC77C02))],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                TrophyBody().stroke(Color(UIColor(hex: 0x9A5F00)).opacity(0.55), lineWidth: max(0.6, h * 0.014))
                Image(systemName: "star.fill")
                    .font(.system(size: h * 0.15, weight: .black))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(y: -h * 0.27)
                Ellipse().fill(.white.opacity(0.5))
                    .frame(width: h * 0.06, height: h * 0.2)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -h * 0.17, y: -h * 0.3)
                Circle().fill(accent)
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: max(0.5, h * 0.012)))
                    .frame(width: h * 0.09, height: h * 0.09)
                    .offset(y: h * 0.28)
            } else {
                ZStack {
                    TrophyHandles().stroke(.white.opacity(0.2), lineWidth: h * 0.05)
                    // The cup is see-through, so cut the handles away behind it.
                    TrophyBody().fill(.black).blendMode(.destinationOut)
                    TrophyBody().fill(.white.opacity(0.06))
                    TrophyBody().stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: max(1, h * 0.02), dash: [h * 0.06, h * 0.05]))
                }
                .compositingGroup()
            }
        }
        .frame(width: h * 0.9, height: h)
        .shadow(color: .black.opacity(earned ? 0.35 : 0), radius: h * 0.06, y: h * 0.04)
    }
}

/// Cup, stem and base of a trophy, filling the rect's height.
private struct TrophyBody: Shape {
    func path(in r: CGRect) -> Path {
        let h = r.height, cx = r.midX
        func y(_ f: CGFloat) -> CGFloat { r.minY + h * f }
        var p = Path()
        p.move(to: CGPoint(x: cx - h * 0.3, y: y(0.04)))
        p.addLine(to: CGPoint(x: cx + h * 0.3, y: y(0.04)))
        p.addQuadCurve(to: CGPoint(x: cx + h * 0.06, y: y(0.54)), control: CGPoint(x: cx + h * 0.3, y: y(0.46)))
        p.addLine(to: CGPoint(x: cx - h * 0.06, y: y(0.54)))
        p.addQuadCurve(to: CGPoint(x: cx - h * 0.3, y: y(0.04)), control: CGPoint(x: cx - h * 0.3, y: y(0.46)))
        p.closeSubpath()
        p.addRect(CGRect(x: cx - h * 0.05, y: y(0.52), width: h * 0.1, height: h * 0.2))
        let corner = CGSize(width: h * 0.03, height: h * 0.03)
        p.addRoundedRect(in: CGRect(x: cx - h * 0.22, y: y(0.7), width: h * 0.44, height: h * 0.16), cornerSize: corner)
        p.addRoundedRect(in: CGRect(x: cx - h * 0.28, y: y(0.86), width: h * 0.56, height: h * 0.1), cornerSize: corner)
        return p
    }
}

private struct TrophyHandles: Shape {
    func path(in r: CGRect) -> Path {
        let h = r.height
        var p = Path()
        for side in [-1.0, 1.0] as [CGFloat] {
            p.addEllipse(in: CGRect(x: r.midX + side * h * 0.3 - h * 0.12, y: r.minY + h * 0.08, width: h * 0.24, height: h * 0.26))
        }
        return p
    }
}

/// Small golf ball glyph in a side's color, stripe pointing up the line like the in-game balls.
struct BallGlyph: View {
    let index: Int
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.white, Color(UIColor(hex: 0xC4CAD1))], center: .init(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: size * 0.7))
            Rectangle().fill(Color.side(index)).frame(width: size * 0.32)
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
