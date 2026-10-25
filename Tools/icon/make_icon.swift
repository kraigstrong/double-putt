// Generates the 1024px app icon: down on the green, face on, two striped balls with a rounded mallet right behind them.
// Usage: swift Tools/icon/make_icon.swift MiniGolf/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let orange: UInt32 = 0xFF8A3D
let purple: UInt32 = 0x8F6BFF
let putt: UInt32 = 0xFFC94A
let shadowGreen: UInt32 = 0x0A4A26
/// Upper-left light, for the shading on the balls.
let light: CGPoint = {
    let v = CGPoint(x: -0.55, y: 0.83), l = hypot(v.x, v.y)
    return CGPoint(x: v.x / l, y: v.y / l)
}()

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, a])!
}

func grad(_ colors: [CGColor], _ locs: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locs)!
}

func context(_ w: Int, _ h: Int) -> CGContext {
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.setLineCap(.round)
    c.setLineJoin(.round)
    return c
}

func circle(_ p: CGPoint, _ r: CGFloat) -> CGRect { CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2) }

func clipped(_ c: CGContext, _ path: CGPath, _ body: () -> Void) {
    c.saveGState()
    c.addPath(path)
    c.clip()
    body()
    c.restoreGState()
}

func fill(_ c: CGContext, _ path: CGPath, _ hex: UInt32, _ a: CGFloat = 1) {
    c.addPath(path)
    c.setFillColor(rgb(hex, a))
    c.fillPath()
}

func roundedPolygon(_ pts: [CGPoint], _ radii: [CGFloat]) -> CGPath {
    let p = CGMutablePath()
    let n = pts.count
    p.move(to: CGPoint(x: (pts[n - 1].x + pts[0].x) / 2, y: (pts[n - 1].y + pts[0].y) / 2))
    for i in 0..<n { p.addArc(tangent1End: pts[i], tangent2End: pts[(i + 1) % n], radius: radii[i]) }
    p.closeSubpath()
    return p
}

/// A round-ended stroke from a to b, width wa at a widening to wb at b.
func taper(_ a: CGPoint, _ b: CGPoint, _ wa: CGFloat, _ wb: CGFloat) -> CGPath {
    let len = hypot(b.x - a.x, b.y - a.y)
    let n = CGPoint(x: -(b.y - a.y) / len, y: (b.x - a.x) / len)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: a.x + n.x * wa / 2, y: a.y + n.y * wa / 2))
    path.addLine(to: CGPoint(x: b.x + n.x * wb / 2, y: b.y + n.y * wb / 2))
    path.addArc(center: b, radius: wb / 2, startAngle: atan2(n.y, n.x), endAngle: atan2(-n.y, -n.x), clockwise: true)
    path.addLine(to: CGPoint(x: a.x - n.x * wa / 2, y: a.y - n.y * wa / 2))
    path.addArc(center: a, radius: wa / 2, startAngle: atan2(-n.y, -n.x), endAngle: atan2(n.y, n.x), clockwise: true)
    path.closeSubpath()
    return path
}

/// A soft elliptical shadow on the green.
func groundShadow(_ c: CGContext, _ p: CGPoint, rx: CGFloat, ry: CGFloat, alpha: CGFloat) {
    c.saveGState()
    c.translateBy(x: p.x, y: p.y)
    c.scaleBy(x: 1, y: ry / rx)
    c.drawRadialGradient(grad([rgb(shadowGreen, alpha), rgb(shadowGreen, alpha * 0.6), rgb(shadowGreen, 0)], [0, 0.5, 1]),
                         startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: rx, options: [])
    c.restoreGState()
}

// MARK: - Pieces

func scenery(_ c: CGContext, horizon hz: CGFloat) {
    // Sky, brightest where the sun sits top-left.
    c.drawLinearGradient(grad([rgb(0x3F9BFF), rgb(0x94CEFF), rgb(0xDDF1FF)], [0, 0.6, 1]), start: CGPoint(x: 0, y: S),
                         end: CGPoint(x: 0, y: hz), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    let sun = CGPoint(x: S * 0.24, y: S * 0.86)
    c.drawRadialGradient(grad([rgb(0xFFFFFF, 0.7), rgb(0xFFFFFF, 0)], [0, 1]), startCenter: sun, startRadius: 0,
                         endCenter: sun, endRadius: S * 0.4, options: [])
    // Hazy hedge line on the horizon.
    c.setFillColor(rgb(0x86CDAE))
    for (i, x) in stride(from: -20 as CGFloat, to: S + 40, by: 54).enumerated() {
        c.fillEllipse(in: circle(CGPoint(x: x, y: hz + 4), i % 3 == 0 ? 46 : 34))
    }
    // The green, darkening toward the camera.
    clipped(c, CGPath(rect: CGRect(x: 0, y: 0, width: S, height: hz), transform: nil)) {
        c.drawLinearGradient(grad([rgb(0x6AD493), rgb(0x34B26A), rgb(0x1A844A)], [0, 0.4, 1]), start: CGPoint(x: 0, y: hz),
                             end: .zero, options: [])
    }
}

/// Rounded mallet, face on: the milled face, and above it the half-moon crown curving away from the camera.
func putter(_ c: CGContext) {
    let x0 = S * 0.11, x1 = S * 0.89
    let faceBottom = S * 0.40, faceTop = S * 0.525, depth = S * 0.17
    let back = faceTop + depth
    groundShadow(c, CGPoint(x: S / 2, y: faceBottom + 2), rx: S * 0.43, ry: S * 0.035, alpha: 0.4)

    let crown = CGMutablePath()
    crown.move(to: CGPoint(x: x0, y: faceTop))
    crown.addLine(to: CGPoint(x: x1, y: faceTop))
    crown.addCurve(to: CGPoint(x: S / 2, y: back), control1: CGPoint(x: x1 + S * 0.005, y: faceTop + depth * 0.75),
                   control2: CGPoint(x: S * 0.74, y: back))
    crown.addCurve(to: CGPoint(x: x0, y: faceTop), control1: CGPoint(x: S * 0.26, y: back),
                   control2: CGPoint(x: x0 - S * 0.005, y: faceTop + depth * 0.75))
    crown.closeSubpath()
    clipped(c, crown) {
        c.drawLinearGradient(grad([rgb(0x5B646E), rgb(0x76808B)], [0, 1]), start: CGPoint(x: 0, y: faceTop),
                             end: CGPoint(x: 0, y: back), options: [])
        let sheen = CGPoint(x: S * 0.40, y: back - depth * 0.35)
        c.drawRadialGradient(grad([rgb(0xFFFFFF, 0.22), rgb(0xFFFFFF, 0)], [0, 1]), startCenter: sheen, startRadius: 0,
                             endCenter: sheen, endRadius: S * 0.3, options: [])
    }
    // Sight line, aimed between the balls.
    fill(c, taper(CGPoint(x: S / 2, y: faceTop + depth * 0.16), CGPoint(x: S / 2, y: back - depth * 0.2), 14, 12), putt)

    // Square along the top so face and crown read as one body; rounded where it sits on the green.
    let face = roundedPolygon([CGPoint(x: x0, y: faceTop), CGPoint(x: x1, y: faceTop), CGPoint(x: x1, y: faceBottom),
                               CGPoint(x: x0, y: faceBottom)], [4, 4, S * 0.04, S * 0.04])
    clipped(c, face) {
        c.drawLinearGradient(grad([rgb(0x434B54), rgb(0x22272D)], [0, 1]), start: CGPoint(x: 0, y: faceTop),
                             end: CGPoint(x: 0, y: faceBottom), options: [])
        // Milling grooves, then the polished top edge.
        c.setFillColor(rgb(0xFFFFFF, 0.05))
        for y in stride(from: faceBottom + 6, to: faceTop - 6, by: 10) { c.fill(CGRect(x: 0, y: y, width: S, height: 3)) }
        c.setFillColor(rgb(0xB5BEC8, 0.9))
        c.fill(CGRect(x: 0, y: faceTop - 5, width: S, height: 5))
    }

    // Shaft from the heel, at true scale against the head and balls, so the grip is far above the frame:
    // a black ferrule where it meets the crown, then chrome running out of the top.
    let base = CGPoint(x: S * 0.775, y: faceTop + depth * 0.42)
    let dir = CGPoint(x: 0.196, y: 0.981)
    let side = CGPoint(x: -dir.y, y: dir.x)
    func section(_ from: CGFloat, _ to: CGFloat, _ w0: CGFloat, _ w1: CGFloat) -> CGPath {
        let a = CGPoint(x: base.x + dir.x * from, y: base.y + dir.y * from)
        let b = CGPoint(x: base.x + dir.x * to, y: base.y + dir.y * to)
        let p = CGMutablePath()
        p.addLines(between: [CGPoint(x: a.x + side.x * w0 / 2, y: a.y + side.y * w0 / 2), CGPoint(x: b.x + side.x * w1 / 2, y: b.y + side.y * w1 / 2),
                             CGPoint(x: b.x - side.x * w1 / 2, y: b.y - side.y * w1 / 2), CGPoint(x: a.x - side.x * w0 / 2, y: a.y - side.y * w0 / 2)])
        p.closeSubpath()
        return p
    }
    /// Shading across the shaft, lit from the left.
    func across(_ colors: [UInt32], _ locs: [CGFloat], width w: CGFloat) {
        c.drawLinearGradient(grad(colors.map { rgb($0) }, locs), start: CGPoint(x: base.x + side.x * w / 2, y: base.y + side.y * w / 2),
                             end: CGPoint(x: base.x - side.x * w / 2, y: base.y - side.y * w / 2),
                             options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
    let shaftW: CGFloat = 66, ferruleW: CGFloat = 80, ferruleLen: CGFloat = 50
    // Soft contact shadow on the crown, thrown right, away from the light.
    c.saveGState()
    c.translateBy(x: base.x + 12, y: base.y - 6)
    c.scaleBy(x: 1, y: 0.3)
    c.drawRadialGradient(grad([rgb(0, 0.4), rgb(0, 0)], [0, 1]), startCenter: .zero, startRadius: ferruleW * 0.35,
                         endCenter: .zero, endRadius: ferruleW * 0.85, options: [.drawsBeforeStartLocation])
    c.restoreGState()
    clipped(c, section(ferruleLen - 6, 900, shaftW, shaftW + 8)) {
        across([0x8E979F, 0xF4F7F9, 0xC9D0D7, 0x8A939C, 0x4F5760], [0, 0.25, 0.45, 0.75, 1], width: shaftW + 4)
    }
    // The ferrule's sides, then its rounded foot (shaded separately: as one clip path the overlap would cancel out).
    for part in [section(0, ferruleLen, ferruleW, ferruleW - 6),
                 CGPath(ellipseIn: CGRect(x: base.x - ferruleW / 2, y: base.y - 12, width: ferruleW, height: 24), transform: nil)] {
        clipped(c, part) {
            across([0x2A2F35, 0x59616A, 0x22272C, 0x111417], [0, 0.28, 0.7, 1], width: ferruleW)
        }
    }
}

/// Flat-shaded ball, its alignment stripe running toward the camera, with one shade crescent away from the light.
func ball(_ c: CGContext, at p: CGPoint, r: CGFloat, band: UInt32) {
    groundShadow(c, CGPoint(x: p.x + r * 0.12, y: p.y - r * 0.93), rx: r * 0.98, ry: r * 0.17, alpha: 0.45)
    c.setFillColor(rgb(0xFFFFFF))
    c.fillEllipse(in: circle(p, r))
    clipped(c, CGPath(ellipseIn: circle(p, r), transform: nil)) {
        c.setFillColor(rgb(band))
        c.fill(CGRect(x: p.x - r * 0.25, y: p.y - r * 1.1, width: r * 0.5, height: r * 2.2))
        let lit = CGPoint(x: p.x + light.x * r * 0.24, y: p.y + light.y * r * 0.24)
        let crescent = CGMutablePath()
        crescent.addEllipse(in: circle(p, r * 1.05))
        crescent.addEllipse(in: circle(lit, r))
        c.addPath(crescent)
        c.setFillColor(rgb(0, 0.11))
        c.fillPath(using: .evenOdd)
    }
}

func icon(_ c: CGContext) {
    scenery(c, horizon: S * 0.64)
    putter(c)
    let r = S * 0.155
    ball(c, at: CGPoint(x: S * 0.325, y: S * 0.27), r: r, band: orange)
    ball(c, at: CGPoint(x: S * 0.675, y: S * 0.27), r: r, band: purple)
}

// MARK: - Output

func render(_ draw: (CGContext) -> Void) -> CGImage {
    let c = context(Int(S), Int(S))
    draw(c)
    return c.makeImage()!
}

/// App Store Connect rejects an icon with an alpha channel, even a fully opaque one, so flatten before saving.
func opaque(_ img: CGImage) -> CGImage {
    let c = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
    return c.makeImage()!
}

func save(_ img: CGImage, _ url: URL) {
    let d = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, opaque(img), nil)
    CGImageDestinationFinalize(d)
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png")
save(render(icon), out)
print("wrote \(out.path)")
