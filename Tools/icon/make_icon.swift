// Generates the 1024px app icon: a mallet putter, seen from address, striking both balls at once.
// Usage: swift Tools/icon/make_icon.swift MiniGolf/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let space = CGColorSpaceCreateDeviceRGB()
let orange: UInt32 = 0xFF8A3D
let purple: UInt32 = 0x8F6BFF

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
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

func shadowed(_ c: CGContext, dx: CGFloat, dy: CGFloat, blur: CGFloat, alpha: CGFloat, _ body: () -> Void) {
    c.saveGState()
    c.setShadow(offset: CGSize(width: dx, height: dy), blur: blur, color: rgb(0, alpha))
    c.beginTransparencyLayer(auxiliaryInfo: nil)
    body()
    c.endTransparencyLayer()
    c.restoreGState()
}

func clipped(_ c: CGContext, _ path: CGPath, _ body: () -> Void) {
    c.saveGState()
    c.addPath(path)
    c.clip()
    body()
    c.restoreGState()
}

// MARK: - Pieces

func turf(_ c: CGContext, center: CGPoint = CGPoint(x: S * 0.5, y: S * 0.62), light: UInt32 = 0x7FD27A, dark: UInt32 = 0x2A7438) {
    c.drawRadialGradient(grad([rgb(light), rgb(0x4FAE55), rgb(dark)], [0, 0.5, 1]),
                         startCenter: center, startRadius: 0, endCenter: center, endRadius: S * 0.85, options: [.drawsAfterEndLocation])
    c.setFillColor(rgb(0xFFFFFF, 0.045))
    for y in stride(from: 0, to: S, by: 128) { c.fill(CGRect(x: 0, y: y, width: S, height: 64)) }
}

func ball(_ c: CGContext, at p: CGPoint, r: CGFloat, band: UInt32) {
    let shape = CGPath(ellipseIn: circle(p, r), transform: nil)
    shadowed(c, dx: r * 0.10, dy: -r * 0.20, blur: r * 0.32, alpha: 0.42) {
        c.setFillColor(rgb(0xD9DDE2)); c.fillEllipse(in: circle(p, r))
    }
    let light = CGPoint(x: p.x - r * 0.32, y: p.y + r * 0.34)
    clipped(c, shape) {
        c.drawRadialGradient(grad([rgb(0xFFFFFF), rgb(0xF2F4F6), rgb(0xC3CAD2)], [0, 0.45, 1]),
                             startCenter: light, startRadius: 0, endCenter: light, endRadius: r * 1.5, options: [.drawsAfterEndLocation])
        // Alignment stripe along the putt (balls roll toward +y in the scene's frame).
        c.setFillColor(rgb(band))
        c.fill(CGRect(x: p.x - r * 0.31, y: p.y - r, width: r * 0.62, height: r * 2))
        // Dimples, foreshortened toward the rim.
        let s = r * 0.155
        var row = 0
        var y = p.y - r
        while y <= p.y + r {
            var x = p.x - r + (row % 2 == 0 ? 0 : s * 0.5)
            while x <= p.x + r {
                let v = CGPoint(x: (x - p.x) / r, y: (y - p.y) / r)
                let d = hypot(v.x, v.y)
                if d < 0.96 {
                    let z = sqrt(1 - d * d)
                    c.saveGState()
                    c.translateBy(x: x, y: y)
                    c.rotate(by: atan2(v.y, v.x))
                    let rr = s * 0.32
                    c.setFillColor(rgb(0x000000, 0.075))
                    c.fillEllipse(in: CGRect(x: -rr * z, y: -rr, width: rr * 2 * z, height: rr * 2))
                    c.restoreGState()
                }
                x += s
            }
            y += s * 0.87
            row += 1
        }
        c.drawRadialGradient(grad([rgb(0, 0), rgb(0, 0), rgb(0, 0.34)], [0, 0.55, 1]),
                             startCenter: light, startRadius: 0, endCenter: light, endRadius: r * 1.5, options: [.drawsAfterEndLocation])
    }
    // Specular highlight.
    c.saveGState()
    c.translateBy(x: p.x - r * 0.40, y: p.y + r * 0.36)
    c.rotate(by: 0.5)
    let hl = CGRect(x: -r * 0.26, y: -r * 0.15, width: r * 0.52, height: r * 0.30)
    clipped(c, CGPath(ellipseIn: hl, transform: nil)) {
        c.drawRadialGradient(grad([rgb(0xFFFFFF, 0.95), rgb(0xFFFFFF, 0)], [0, 1]),
                             startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r * 0.27, options: [])
    }
    c.restoreGState()
    c.setStrokeColor(rgb(0, 0.2))
    c.setLineWidth(r * 0.022)
    c.strokeEllipse(in: circle(p, r))
}

/// Golfer's-eye putter: looking down at address, shaft rising toward the camera from the heel.
func putterStrike(_ c: CGContext) {
    turf(c, center: CGPoint(x: S * 0.58, y: S * 0.70))
    c.saveGState()
    c.translateBy(x: S / 2, y: S / 2)
    c.rotate(by: -0.36)
    c.scaleBy(x: 0.9, y: 0.9)
    c.translateBy(x: -S / 2 + 10, y: -S / 2 + 30)

    let br: CGFloat = 112
    let ballY = S * 0.60
    let l = CGPoint(x: S * 0.355, y: ballY), r = CGPoint(x: S * 0.645, y: ballY)

    // Dotted guide paths ahead of each ball, like the in-game aim guide.
    for (p, color) in [(l, orange), (r, purple)] {
        for k in 0..<4 {
            let q = CGPoint(x: p.x, y: p.y + br + 60 + CGFloat(k) * 62)
            shadowed(c, dx: 2, dy: -3, blur: 4, alpha: 0.3) {
                c.setFillColor(rgb(color))
                c.fillEllipse(in: circle(q, 19 - CGFloat(k) * 3.2))
            }
        }
    }
    ball(c, at: l, r: br, band: orange)
    ball(c, at: r, r: br, band: purple)

    let faceY = ballY - br - 10
    let x0 = S * 0.17, x1 = S * 0.83
    let depth: CGFloat = 175
    let heel = CGPoint(x: x0 + 92, y: faceY - depth * 0.45)

    // Shaft shadow on the green (light from upper-left), long and soft.
    c.saveGState()
    c.setStrokeColor(rgb(0, 0.22))
    c.setLineWidth(46)
    c.setShadow(offset: .zero, blur: 30, color: rgb(0, 0.3))
    c.move(to: CGPoint(x: heel.x + 30, y: heel.y - 10))
    c.addLine(to: CGPoint(x: S * 0.80, y: -S * 0.1))
    c.strokePath()
    c.restoreGState()

    // Head.
    let headPath = CGMutablePath()
    // Flat face, rounded back: a half-moon mallet.
    let back = faceY - depth
    headPath.move(to: CGPoint(x: x0 + 18, y: faceY))
    headPath.addLine(to: CGPoint(x: x1 - 18, y: faceY))
    headPath.addQuadCurve(to: CGPoint(x: x1, y: faceY - 22), control: CGPoint(x: x1, y: faceY))
    headPath.addCurve(to: CGPoint(x: S / 2, y: back), control1: CGPoint(x: x1, y: back + 40), control2: CGPoint(x: S / 2 + 220, y: back))
    headPath.addCurve(to: CGPoint(x: x0, y: faceY - 22), control1: CGPoint(x: S / 2 - 220, y: back), control2: CGPoint(x: x0, y: back + 40))
    headPath.addQuadCurve(to: CGPoint(x: x0 + 18, y: faceY), control: CGPoint(x: x0, y: faceY))
    headPath.closeSubpath()
    shadowed(c, dx: 16, dy: -22, blur: 26, alpha: 0.45) {
        clipped(c, headPath) {
            c.drawLinearGradient(grad([rgb(0x5A6068), rgb(0x2E3238), rgb(0x1E2125)], [0, 0.5, 1]),
                                 start: CGPoint(x: 0, y: faceY), end: CGPoint(x: 0, y: faceY - depth), options: [])
            // Polished face edge.
            c.drawLinearGradient(grad([rgb(0xFFFFFF), rgb(0xC9CED5), rgb(0x8A9098)], [0, 0.5, 1]),
                                 start: CGPoint(x: 0, y: faceY), end: CGPoint(x: 0, y: faceY - 26), options: [])
            // Alignment line.
            c.setFillColor(rgb(0xFFFFFF))
            c.fill(CGRect(x: S / 2 - 9, y: faceY - depth + 40, width: 18, height: depth - 70))
            c.setFillColor(rgb(0xFFFFFF, 0.9))
            c.fill(CGRect(x: S / 2 - 120, y: faceY - 70, width: 14, height: 34))
            c.fill(CGRect(x: S / 2 + 106, y: faceY - 70, width: 14, height: 34))
        }
        c.addPath(headPath)
        c.setStrokeColor(rgb(0x14171A))
        c.setLineWidth(5)
        c.strokePath()
    }

    // Plumber's-neck hosel from the heel, then the shaft widening toward the camera, then the grip.
    func capsule(_ a: CGPoint, _ b: CGPoint, _ wa: CGFloat, _ wb: CGFloat, _ colors: [CGColor]) {
        let d = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let len = hypot(d.x, d.y)
        let n = CGPoint(x: -d.y / len, y: d.x / len)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: a.x + n.x * wa / 2, y: a.y + n.y * wa / 2))
        path.addLine(to: CGPoint(x: b.x + n.x * wb / 2, y: b.y + n.y * wb / 2))
        path.addArc(center: b, radius: wb / 2, startAngle: atan2(n.y, n.x), endAngle: atan2(-n.y, -n.x), clockwise: true)
        path.addLine(to: CGPoint(x: a.x - n.x * wa / 2, y: a.y - n.y * wa / 2))
        path.addArc(center: a, radius: wa / 2, startAngle: atan2(-n.y, -n.x), endAngle: atan2(n.y, n.x), clockwise: true)
        path.closeSubpath()
        clipped(c, path) {
            c.drawLinearGradient(grad(colors, colors.indices.map { CGFloat($0) / CGFloat(colors.count - 1) }),
                                 start: CGPoint(x: a.x + n.x * wb, y: a.y + n.y * wb),
                                 end: CGPoint(x: a.x - n.x * wb, y: a.y - n.y * wb), options: [])
        }
    }
    let silver = [rgb(0x7E858D), rgb(0xFFFFFF), rgb(0xC3C9D0), rgb(0x6C737B)]
    let shaftEnd = CGPoint(x: S * 0.30, y: S * 0.15)
    let gripEnd = CGPoint(x: S * 0.335, y: -S * 0.22)
    shadowed(c, dx: 10, dy: -14, blur: 16, alpha: 0.35) {
        // Straight shaft out of a short hosel at the heel, widening toward the camera.
        let dir = CGPoint(x: shaftEnd.x - heel.x, y: shaftEnd.y - heel.y)
        let len = hypot(dir.x, dir.y)
        let hoselEnd = CGPoint(x: heel.x + dir.x / len * 46, y: heel.y + dir.y / len * 46)
        capsule(heel, shaftEnd, 20, 40, silver)
        capsule(heel, hoselEnd, 30, 30, silver)
        capsule(shaftEnd, gripEnd, 78, 112, [rgb(0x2A2D31), rgb(0x5E636A), rgb(0x2A2D31), rgb(0x15171A)])
        // Grip texture rings and a colored collar.
        c.setStrokeColor(rgb(0x000000, 0.35))
        c.setLineWidth(4)
        for k in 1..<7 {
            let t = CGFloat(k) / 7
            let p = CGPoint(x: shaftEnd.x + (gripEnd.x - shaftEnd.x) * t, y: shaftEnd.y + (gripEnd.y - shaftEnd.y) * t)
            let w = (78 + 34 * t) / 2
            c.move(to: CGPoint(x: p.x - w, y: p.y - 3)); c.addLine(to: CGPoint(x: p.x + w, y: p.y + 3))
        }
        c.strokePath()
    }
    c.restoreGState()
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
save(render(putterStrike), out)
print("wrote \(out.path)")
