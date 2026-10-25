import SpriteKit
import UIKit
import simd

extension Vec {
    var cg: CGPoint { CGPoint(x: x, y: y) }
}

extension UIColor {
    var simd: simd_float4 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return simd_float4(Float(r), Float(g), Float(b), Float(a))
    }
}

final class GameScene: SKScene {
    /// Finger travel (points) for a full-power pull.
    static let maxDragPoints: CGFloat = 210
    /// Seconds from tapping Putt to the putter striking the balls.
    static let swing = 0.11

    let model: GameModel
    private var level: Level
    private var theme: Theme
    private var world: World
    /// The dots gliding along the slope grid.
    private var flow: SlopeFlow
    private var accumulator = 0.0
    private var lastUpdate: TimeInterval?

    var layoutInsets: UIEdgeInsets = .zero { didSet { layoutCamera() } }
    private let cam = SKCameraNode()
    private let worldNode = SKNode()
    private let groundNode = SKSpriteNode()
    private let courseNode = SKSpriteNode()
    private let propsNode = SKNode()
    private let fxNode = SKNode()
    private let guideNode = SKNode()
    private let flowNode = SKNode()
    private var flowDots: [SKSpriteNode] = []
    private let dragNode = SKShapeNode()
    private var ballNodes: [SKNode] = []
    /// Each ball's orientation (ball → world), turned on every physics step so it rolls as it moves.
    private var ballSpin: [simd_quatf] = []
    /// Each ball's paint shader input: the world → ball rotation.
    private var spinUniforms: [SKUniform] = []
    private var putters: [SKSpriteNode] = []
    /// One (sprite, shadow) per mover, in level order.
    private var moverNodes: [(body: SKSpriteNode, shadow: SKSpriteNode)] = []
    private var ambient: SKEmitterNode?

    private var pointsPerUnit: CGFloat = 1
    private var renderedPPU: CGFloat = 0
    private var renderedLevel: String?
    /// The part of the world the ground art covers: what was on screen when it was drawn, plus a margin.
    private var paintedRect = CGRect.null
    private var textureCache: [String: SKTexture] = [:]
    /// The screen changed size mid-hole and the art is being redrawn for it (see `redraw`): nothing moves till it's done.
    private var redrawing = false
    private var pendingRedraw: DispatchWorkItem?
    /// Hides the old art, stretched to the new size, while the redraw waits and draws.
    private let redrawCover = SKSpriteNode(color: .black, size: .zero)

    private var dragStart: CGPoint?
    /// Which side the current drag started over (0 = A, 1 = B).
    private var dragSide = 0
    private var tickBucket = -1
    private var drawnGuide: (aim: Shot?, canAim: Bool, full: Bool, side: Int)?
    private var guideDrawnAt: TimeInterval = 0
    /// Show Ace: mover-clock seconds left before tapping Putt, and how fast the clock runs until then.
    private var demoCountdown: (left: Double, rate: Double)?
    private var lastHaptic = 0.0

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notify = UINotificationFeedbackGenerator()

    init(model: GameModel) {
        self.model = model
        level = model.level
        theme = model.theme
        world = World(level: level)
        flow = SlopeFlow(level: level)
        super.init(size: CGSize(width: 400, height: 800))
        scaleMode = .resizeFill
        backgroundColor = theme.rough
        addChild(cam)
        camera = cam
        addChild(worldNode)
        groundNode.anchorPoint = .zero
        groundNode.zPosition = -20
        courseNode.anchorPoint = .zero
        courseNode.zPosition = 0
        propsNode.zPosition = 30
        fxNode.zPosition = 12
        guideNode.zPosition = 8
        flowNode.zPosition = 1
        dragNode.zPosition = 40
        dragNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
        dragNode.lineCap = .round
        for n in [groundNode, courseNode, flowNode, propsNode, fxNode, guideNode, dragNode] as [SKNode] { worldNode.addChild(n) }
        loadLevel()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutCamera()
    }

    // MARK: - Layout & art

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        layoutCamera()
    }

    private func layoutCamera() {
        // Wait for a real view and HUD insets; rendering art for a placeholder size is wasted work.
        guard view != nil, size.width > 10, size.height > 10, layoutInsets != .zero else { return }
        let margin = CourseArt.borderOut + 6
        let fullW = Course.width + 2 * margin, fullH = Course.height + 2 * margin
        let i = layoutInsets
        let availW = size.width - i.left - i.right, availH = size.height - i.top - i.bottom
        let s = min(availW / fullW, availH / fullH)
        guard s > 0 else { return }
        pointsPerUnit = s
        cam.setScale(1 / s)
        let free = CGPoint(x: i.left + availW / 2, y: i.bottom + availH / 2)
        cam.position = CGPoint(x: Course.width / 2 - (free.x - size.width / 2) / s,
                               y: Course.height / 2 - (free.y - size.height / 2) / s)
        let o = CourseArt.borderOut
        let frame = CGRect(x: (-o - cam.position.x) * s + size.width / 2,
                           y: size.height / 2 - (Course.height + o - cam.position.y) * s,
                           width: (Course.width + 2 * o) * s, height: (Course.height + 2 * o) * s)
        if model.courseFrame != frame { model.courseFrame = frame }
        if renderedLevel != level.name {
            buildArt(ppu: ppu)
        } else if abs(ppu - renderedPPU) / ppu > 0.15 || !paintedRect.contains(visibleRect) {
            redraw()
        }
    }

    /// Pixels per course unit for the current layout.
    private var ppu: CGFloat { pointsPerUnit * (view?.contentScaleFactor ?? 3) }

    /// The screen changed size mid-hole (a Duo opened or closed, an iPad turned or its window resized), so the art no
    /// longer fits it. Play holds still under a cover while the art is redrawn, then carries on where it was. A resize
    /// often comes in a few steps, so the redraw waits for them to settle.
    private func redraw() {
        pendingRedraw?.cancel()
        pendingRedraw = nil
        if model.paused {
            // The pause menu hides the course and nothing's moving: redraw now, ready for Resume (and finish any
            // redraw that was waiting when the game was paused).
            finishRedraw()
            return
        }
        redrawing = true
        if redrawCover.parent == nil {
            redrawCover.color = theme.rough
            redrawCover.alpha = 0
            redrawCover.zPosition = 1000
            cam.addChild(redrawCover)
        }
        // The camera's children are in screen points; a square covers the screen however the camera turns.
        let side = max(size.width, size.height) + 100
        redrawCover.size = CGSize(width: side, height: side)
        redrawCover.removeAllActions()
        redrawCover.run(.fadeIn(withDuration: 0.1))
        let work = DispatchWorkItem { [weak self] in self?.finishRedraw() }
        pendingRedraw = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    private func finishRedraw() {
        pendingRedraw = nil
        buildArt(ppu: ppu)
        redrawing = false
        // The wait isn't play time: the next frame picks up from here.
        lastUpdate = nil
        redrawCover.removeAllActions()
        if model.paused {
            // A paused scene doesn't run actions, so a fade would wait for Resume: the pause menu hides it anyway.
            redrawCover.removeFromParent()
        } else {
            redrawCover.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        }
    }

    private var visibleRect: CGRect {
        let w = size.width / pointsPerUnit, h = size.height / pointsPerUnit
        return CGRect(x: cam.position.x - w / 2, y: cam.position.y - h / 2, width: w, height: h)
    }

    private func texture(_ key: String, _ make: () -> UIImage) -> SKTexture {
        if let t = textureCache[key] { return t }
        let t = SKTexture(image: make())
        textureCache[key] = t
        return t
    }

    private func buildArt(ppu: CGFloat) {
        if abs(ppu - renderedPPU) / max(ppu, 0.01) > 0.15 { textureCache = [:] }
        renderedPPU = ppu
        renderedLevel = level.name
        backgroundColor = theme.rough
        let seed = CourseArt.stableSeed(level.name)

        let groundRect = visibleRect.insetBy(dx: -60, dy: -60).integral
        paintedRect = groundRect
        groundNode.texture = SKTexture(image: CourseArt.ground(theme, rect: groundRect, ppu: ppu * 0.6, seed: seed))
        groundNode.size = groundRect.size
        groundNode.position = groundRect.origin

        let courseRect = CourseArt.courseRect
        courseNode.texture = SKTexture(image: CourseArt.course(level, theme: theme, ppu: ppu))
        courseNode.size = courseRect.size
        courseNode.position = courseRect.origin

        buildProps(in: groundRect, seed: seed, ppu: ppu)
        buildFlags()
        buildWater()
        buildMovers(ppu: ppu)
        addLanterns()
        buildAmbient(in: visibleRect)
        buildBalls()
        drawnGuide = nil
    }

    private func buildProps(in rect: CGRect, seed: UInt64, ppu: CGFloat) {
        propsNode.removeAllChildren()
        var rng = SeededRandom(seed: seed &+ 5)
        let felt = CGRect(x: -2, y: -2, width: Course.width + 4, height: Course.height + 4)
        var placed: [(CGPoint, CGFloat)] = []
        func free(_ p: CGPoint, _ r: CGFloat, overlap: CGFloat) -> Bool {
            let dx = max(felt.minX - p.x, 0, p.x - felt.maxX), dy = max(felt.minY - p.y, 0, p.y - felt.maxY)
            guard hypot(dx, dy) > r * 0.9 else { return false }
            return !placed.contains { hypot($0.0.x - p.x, $0.0.y - p.y) < ($0.1 + r) * overlap }
        }
        // Prop textures are cached by key across holes, so keys carry the setting: each setting draws its own.
        func add(_ prop: CourseArt.Prop, key: String, at p: CGPoint, sway: Bool) {
            let node = SKSpriteNode(texture: texture(key) { prop.image }, size: prop.size)
            node.position = p
            if sway {
                let d = Double(rng.range(2.6, 4.2))
                let a = rng.range(0.008, 0.016)
                node.zRotation = -a
                node.run(.repeatForever(.sequence([.rotate(byAngle: a * 2, duration: d), .rotate(byAngle: -a * 2, duration: d)])))
                node.run(.wait(forDuration: Double(rng.range(0, 2))))
            }
            propsNode.addChild(node)
        }
        if level.bandon {
            // Bandon naps on the ground just right of the course, near the top: clear of the power meter and the
            // buttons on a phone. His spot is kept clear of trees.
            var spot = SeededRandom(seed: seed &+ 77)
            let p = CGPoint(x: Course.width + CourseArt.borderOut + 26, y: Course.height - spot.range(50, 100))
            let art = CourseArt.bandon(ppu: ppu)
            let dog = SKNode()
            dog.position = p
            dog.zRotation = spot.unit() < 0.5 ? 0.12 : .pi - 0.12
            let body = SKSpriteNode(texture: texture("bandon") { art.body.image }, size: art.body.size)
            body.anchorPoint = CGPoint(x: 0.5, y: 20 / art.body.size.height)
            let tail = SKSpriteNode(texture: texture("bandonTail") { art.tail.image }, size: art.tail.size)
            tail.anchorPoint = CGPoint(x: 0.5, y: 16 / art.tail.size.height)
            tail.position = CGPoint(x: 0, y: -16)
            tail.zPosition = -0.1
            dog.addChild(tail)
            dog.addChild(body)
            let wag = SKAction.sequence([.rotate(toAngle: 0.3, duration: 0.12), .rotate(toAngle: -0.3, duration: 0.12)])
            tail.run(.repeatForever(.sequence([.repeat(wag, count: 4), .rotate(toAngle: 0, duration: 0.1),
                                               .wait(forDuration: 3.5, withRange: 3)])))
            body.run(.repeatForever(.sequence([.scaleX(to: 1.04, duration: 1.5), .scaleX(to: 1, duration: 1.5)])))
            propsNode.addChild(dog)
            placed.append((p, 32))
        }
        if theme.ground == .muni {
            // The city's water tower stands just right of the course, near the top: the strip above the power meter.
            let p = CGPoint(x: Course.width + CourseArt.borderOut + 30, y: Course.height - 70)
            add(CourseArt.waterTower(radius: 28, ppu: ppu), key: "waterTower", at: p, sway: false)
            placed.append((p, 40))
        }
        for k in 0..<160 {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let r = rng.range(30, 52)
            guard free(p, r, overlap: 0.75) else { continue }
            placed.append((p, r))
            let variant = k % 5
            add(CourseArt.tree(theme, radius: 44, seed: seed &+ UInt64(variant), ppu: ppu), key: "tree-\(theme.id)-\(variant)", at: p, sway: theme.trees != .tents)
            propsNode.children.last?.setScale(r / 44)
        }
        for k in 0..<120 {
            let p = CGPoint(x: rng.range(rect.minX, rect.maxX), y: rng.range(rect.minY, rect.maxY))
            let isRock = rng.unit() < 0.3
            let r = isRock ? rng.range(5, 9) : rng.range(9, 15)
            guard free(p, r, overlap: 1.0) else { continue }
            placed.append((p, r))
            let variant = k % 4
            if isRock {
                let tone: UIColor? = theme.trees == .cactus ? theme.borderTop : theme.ground == .snow ? UIColor(hex: 0xAFC0CF) : nil
                add(CourseArt.rock(radius: 8, seed: seed &+ 100 &+ UInt64(variant), ppu: ppu, tone: tone), key: "rock-\(theme.id)-\(variant)", at: p, sway: false)
                propsNode.children.last?.setScale(r / 8)
            } else {
                add(CourseArt.bush(theme, radius: 13, seed: seed &+ 200 &+ UInt64(variant), ppu: ppu), key: "bush-\(theme.id)-\(variant)", at: p, sway: false)
                propsNode.children.last?.setScale(r / 13)
            }
        }
    }

    /// Night: glowing lanterns around the course and on posts.
    private func addLanterns() {
        guard theme.lanterns else { return }
        let o = CourseArt.borderOut + 10
        var spots: [CGPoint] = []
        for y in stride(from: 60.0, through: Course.height - 60, by: 150) {
            spots.append(CGPoint(x: -o, y: y)); spots.append(CGPoint(x: Course.width + o, y: y))
        }
        for x in [60.0, Course.width - 60] {
            spots.append(CGPoint(x: x, y: -o)); spots.append(CGPoint(x: x, y: Course.height + o))
        }
        spots += level.bumpers.map { $0.center.cg }
        for (k, p) in spots.enumerated() {
            let glow = SKSpriteNode(texture: texture("glow") { CourseArt.softDot(pixels: 64, color: .white, hardness: 0.05) })
            glow.size = CGSize(width: 120, height: 120)
            glow.color = UIColor(hex: 0xFFC56B)
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.45
            glow.position = p
            glow.zPosition = -1
            propsNode.addChild(glow)
            let d = 0.6 + Double(k % 5) * 0.13
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.34, duration: d), .fadeAlpha(to: 0.5, duration: d * 0.8)])))
            if k < spots.count - level.bumpers.count {
                let lamp = SKShapeNode(circleOfRadius: 4.5)
                lamp.fillColor = UIColor(hex: 0xFFE9A8)
                lamp.strokeColor = UIColor(hex: 0x2A2D33)
                lamp.lineWidth = 1.5
                lamp.position = p
                propsNode.addChild(lamp)
            }
        }
    }

    private func buildMovers(ppu: CGFloat) {
        moverNodes.forEach { $0.body.removeFromParent(); $0.shadow.removeFromParent() }
        moverNodes = level.movers.enumerated().map { k, m in
            let body: SKSpriteNode, shadow: SKSpriteNode
            switch m.kind {
            case .rotor(_, let blades, let length, _, _):
                let make = { (sh: Bool) in CourseArt.rotor(blades: blades, length: length, radius: m.radius, theme: self.theme, ppu: ppu, shadow: sh) }
                body = SKSpriteNode(texture: SKTexture(image: make(false)))
                shadow = SKSpriteNode(texture: SKTexture(image: make(true)))
                body.size = CGSize(width: (length + 4) * 2, height: (length + 4) * 2)
            case .slider(let box, _, _):
                let make = { (sh: Bool) in CourseArt.sliderBlock(box, radius: m.radius, theme: self.theme, ppu: ppu, shadow: sh) }
                body = SKSpriteNode(texture: SKTexture(image: make(false)))
                shadow = SKSpriteNode(texture: SKTexture(image: make(true)))
                body.size = CGSize(width: box.width + 2 * m.radius, height: box.height + 2 * m.radius)
            case .carousel(_, let radius, _, _):
                body = SKSpriteNode(texture: SKTexture(image: CourseArt.carousel(radius: radius, theme: self.theme, ppu: ppu)))
                shadow = SKSpriteNode()
                body.size = CGSize(width: (radius + 3) * 2, height: (radius + 3) * 2)
            case .robot:
                body = SKSpriteNode(texture: texture("robot-\(m.radius)") { CourseArt.robot(radius: m.radius, ppu: ppu, shadow: false) })
                shadow = SKSpriteNode(texture: texture("robotShadow-\(m.radius)") { CourseArt.robot(radius: m.radius, ppu: ppu, shadow: true) })
                body.size = CGSize(width: (m.radius + 3) * 2, height: (m.radius + 3) * 2)
            case .field(let a, let b, _, _, _):
                let length = (b - a).length
                body = SKSpriteNode(texture: SKTexture(image: CourseArt.fieldPosts(length: length, ppu: ppu, shadow: false)))
                shadow = SKSpriteNode(texture: SKTexture(image: CourseArt.fieldPosts(length: length, ppu: ppu, shadow: true)))
                body.size = CGSize(width: length + 14, height: 14)
                let beam = SKSpriteNode(texture: SKTexture(image: CourseArt.fieldBeam(length: length, ppu: ppu)))
                beam.size = CGSize(width: length, height: 10)
                beam.name = "beam"
                beam.blendMode = .add
                beam.zPosition = -0.1
                body.addChild(beam)
                body.position = Vec((a.x + b.x) / 2, (a.y + b.y) / 2).cg
                body.zRotation = atan2(b.y - a.y, b.x - a.x)
            }
            shadow.size = body.size
            shadow.alpha = 0.3
            body.zPosition = 17
            shadow.zPosition = 9
            if case .carousel = m.kind {
                // Flush with the green: under the guide and the balls, no cast shadow.
                body.zPosition = 2
                shadow.alpha = 0
            }
            body.name = "mover\(k)"
            worldNode.addChild(shadow)
            worldNode.addChild(body)
            return (body, shadow)
        }
        syncMovers(at: world.time)
    }

    /// Place mover sprites for physics time t.
    private func syncMovers(at t: Double) {
        for (k, m) in level.movers.enumerated() where k < moverNodes.count {
            let (body, shadow) = moverNodes[k]
            switch m.kind {
            case .rotor(let pivot, _, _, _, _), .carousel(let pivot, _, _, _):
                body.position = pivot.cg
                body.zRotation = m.bladeAngle(0, at: t)
            case .slider(let box, _, _):
                body.position = (box.center + m.sliderOffset(at: t)).cg
            case .robot:
                let pose = m.robotPose(at: t)
                body.position = pose.pos.cg
                body.zRotation = atan2(pose.heading.y, pose.heading.x)
            case .field(_, _, let period, _, _):
                // Lit: the beam blazes with a slight shimmer. Dark: a faint trace, flickering for the last moment
                // before it lights so you can see it coming.
                let beam = body.childNode(withName: "beam")
                if m.isLit(at: t) {
                    beam?.alpha = 0.9 + 0.1 * CGFloat(sin(t * 40))
                } else {
                    let soon = m.isLit(at: t + 0.3) || m.isLit(at: t + period * 0.02 + 0.3)
                    beam?.alpha = soon ? (sin(t * 60) > 0 ? 0.45 : 0.15) : 0.08
                }
            }
            shadow.position = CGPoint(x: body.position.x + 2.5, y: body.position.y - 3.5)
            shadow.zRotation = body.zRotation
        }
    }

    /// A ball that stopped in a mover's path slides clear of it (World.clearMoverPaths).
    private func giveRelief() {
        for (i, from) in world.clearMoverPaths() where i < ballNodes.count {
            let node = ballNodes[i]
            node.position = from.cg
            let slide = SKAction.move(to: world.balls[i].pos.cg, duration: 0.45)
            slide.timingMode = .easeInEaseOut
            node.run(.group([slide, .sequence([.scale(to: 1.25, duration: 0.2), .scale(to: 1, duration: 0.25)])]))
        }
    }

    private func buildFlags() {
        fxNode.removeAllChildren()
        for (i, cup) in level.cups.enumerated() {
            let flag = SKNode()
            flag.position = cup.cg
            flag.zPosition = 20
            flag.name = "flag\(i)"
            let shadow = SKShapeNode(path: CourseArt.line(.zero, CGPoint(x: 20, y: -15)))
            shadow.strokeColor = UIColor.black.withAlphaComponent(0.22)
            shadow.lineWidth = 2.2
            shadow.lineCap = .round
            shadow.zPosition = -1
            flag.addChild(shadow)
            let pole = SKShapeNode(rect: CGRect(x: -0.9, y: 0, width: 1.8, height: 38), cornerRadius: 0.9)
            pole.fillColor = UIColor(hex: 0xF5F5F0)
            pole.strokeColor = UIColor(hex: 0x9A9A92)
            pole.lineWidth = 0.4
            flag.addChild(pole)
            let finial = SKShapeNode(circleOfRadius: 1.6)
            finial.position = CGPoint(x: 0, y: 38.5)
            finial.fillColor = UIColor(hex: 0xF2C14E)
            finial.strokeColor = .clear
            flag.addChild(finial)
            // Neutral pennant: any ball can drop in any cup, so a cup shouldn't look like it belongs to one.
            let pennant = SKShapeNode()
            pennant.fillColor = .white
            pennant.strokeColor = UIColor(hex: 0xB9B9B0)
            pennant.lineWidth = 0.5
            flag.addChild(pennant)
            let phase = Double(i) * 1.3
            pennant.run(.repeatForever(.customAction(withDuration: 1) { node, _ in
                let t = CACurrentMediaTime() * 3.2 + phase
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0.9, y: 37))
                let tip = CGPoint(x: 19 + sin(t) * 0.8, y: 32 + sin(t + 1.2) * 1.4)
                path.addQuadCurve(to: tip, control: CGPoint(x: 10, y: 37 + sin(t + 0.6) * 2.0))
                path.addQuadCurve(to: CGPoint(x: 0.9, y: 26), control: CGPoint(x: 10, y: 27 + sin(t + 0.9) * 2.0))
                path.closeSubpath()
                (node as? SKShapeNode)?.path = path
            }))
            fxNode.addChild(flag)
        }
    }

    private func buildWater() {
        // Ripples only on open water big enough to hold them (not ice, not thin channels).
        guard theme.water != .ice else { return }
        for box in level.water where box.width > 48 && box.height > 32 {
            for k in 0..<4 {
                let w = CGFloat.random(in: 14...26)
                let ripple = SKShapeNode(path: {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: -w / 2, y: 0))
                    p.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: 0, y: 2.5))
                    return p
                }())
                ripple.strokeColor = UIColor.white.withAlphaComponent(0.5)
                ripple.lineWidth = 1
                ripple.lineCap = .round
                ripple.alpha = 0
                ripple.zPosition = 1
                fxNode.addChild(ripple)
                let loop = SKAction.sequence([
                    .run {
                        ripple.position = CGPoint(x: CGFloat.random(in: box.minX + 16...box.maxX - 16),
                                                  y: CGFloat.random(in: box.minY + 10...box.maxY - 10))
                    },
                    .group([.sequence([.fadeAlpha(to: 0.7, duration: 1.2), .fadeAlpha(to: 0, duration: 1.4)]),
                            .moveBy(x: CGFloat.random(in: -8...8), y: 0, duration: 2.6)]),
                    .wait(forDuration: Double.random(in: 0.2...1.5)),
                ])
                ripple.run(.sequence([.wait(forDuration: Double(k) * 0.7), .repeatForever(loop)]))
            }
        }
    }

    private func buildAmbient(in rect: CGRect) {
        ambient?.removeFromParent()
        ambient = nil
        removeAction(forKey: "fireworks")
        removeAction(forKey: "gulls")
        if theme.ambient == .sparks { startFireworks(in: rect) }
        if theme.ambient == .mist { startGulls(in: rect) }
        let e = SKEmitterNode()
        e.position = CGPoint(x: rect.midX, y: rect.maxY + 10)
        e.particlePositionRange = CGVector(dx: rect.width * 1.2, dy: 10)
        e.zPosition = 50
        e.particleBlendMode = .alpha
        switch theme.ambient {
        case .none:
            return
        case .petals:
            e.particleTexture = texture("petal") { CourseArt.leaf(color: .white, pixels: 24) }
            e.particleColor = UIColor(hex: 0xFFC2D6)
            e.particleColorBlendFactor = 1
            e.particleColorBlueRange = 0.2
            e.particleBirthRate = 0.9
            e.particleLifetime = 26
            e.particleSpeed = 22
            e.particleSpeedRange = 8
            e.emissionAngle = -.pi / 2 - 0.35
            e.emissionAngleRange = 0.4
            e.particleScale = 3.2
            e.particleScaleRange = 1.2
            e.particleRotationRange = .pi * 2
            e.particleRotationSpeed = 0.6
            e.particleAlpha = 0.9
        case .leaves:
            e.particleTexture = texture("leaf") { CourseArt.leaf(color: .white, pixels: 28) }
            e.particleColor = UIColor(hex: 0xE07B39)
            e.particleColorBlendFactor = 1
            e.particleColorRedRange = 0.15
            e.particleColorGreenRange = 0.35
            e.particleBirthRate = 1.1
            e.particleLifetime = 24
            e.particleSpeed = 28
            e.particleSpeedRange = 10
            e.emissionAngle = -.pi / 2 + 0.3
            e.emissionAngleRange = 0.5
            e.xAcceleration = -1.5
            e.particleScale = 4.5
            e.particleScaleRange = 1.5
            e.particleRotationRange = .pi * 2
            e.particleRotationSpeed = 1.2
            e.particleAlpha = 0.95
        case .snow:
            e.particleTexture = texture("dot") { CourseArt.softDot(pixels: 24) }
            e.particleColor = .white
            e.particleColorBlendFactor = 1
            e.particleBirthRate = 9
            e.particleLifetime = 30
            e.particleSpeed = 26
            e.particleSpeedRange = 10
            e.emissionAngle = -.pi / 2 - 0.15
            e.emissionAngleRange = 0.3
            e.xAcceleration = 1
            e.particleScale = 2.2
            e.particleScaleRange = 1.4
            e.particleAlpha = 0.85
            e.particleAlphaRange = 0.15
        case .dust:
            e.position = CGPoint(x: rect.minX - 10, y: rect.midY)
            e.particlePositionRange = CGVector(dx: 10, dy: rect.height)
            e.particleTexture = texture("dot") { CourseArt.softDot(pixels: 24) }
            e.particleColor = UIColor(hex: 0xF3D6AE)
            e.particleColorBlendFactor = 1
            e.particleBirthRate = 4
            e.particleLifetime = 22
            e.particleSpeed = 30
            e.particleSpeedRange = 12
            e.emissionAngle = 0.05
            e.emissionAngleRange = 0.2
            e.particleScale = 1.8
            e.particleScaleRange = 1
            e.particleAlpha = 0.45
        case .confetti:
            e.particleTexture = texture("confetti") { CourseArt.confetti(pixels: 24) }
            e.particleColor = UIColor(white: 0.55, alpha: 1)
            e.particleColorBlendFactor = 1
            e.particleColorRedRange = 0.9
            e.particleColorGreenRange = 0.9
            e.particleColorBlueRange = 0.9
            e.particleBirthRate = 1.6
            e.particleLifetime = 24
            e.particleSpeed = 26
            e.particleSpeedRange = 10
            e.emissionAngle = -.pi / 2
            e.emissionAngleRange = 0.5
            e.particleScale = 2.6
            e.particleScaleRange = 1
            e.particleRotationRange = .pi * 2
            e.particleRotationSpeed = 2.4
            e.particleAlpha = 0.95
        case .sparks:
            // Embers drifting down from fireworks overhead.
            e.position = CGPoint(x: rect.midX, y: rect.midY)
            e.particlePositionRange = CGVector(dx: rect.width, dy: rect.height)
            e.particleTexture = texture("mote") { CourseArt.softDot(pixels: 24, hardness: 0.15) }
            e.particleColor = UIColor(hex: 0xFFB0D8)
            e.particleColorBlendFactor = 1
            e.particleColorRedRange = 0.3
            e.particleColorGreenRange = 0.6
            e.particleColorBlueRange = 0.6
            e.particleBlendMode = .add
            e.particleBirthRate = 6
            e.particleLifetime = 4
            e.particleLifetimeRange = 2
            e.particleSpeed = 14
            e.particleSpeedRange = 8
            e.emissionAngle = -.pi / 2
            e.emissionAngleRange = 0.8
            e.particleScale = 0.9
            e.particleScaleRange = 0.5
            e.particleScaleSpeed = -0.15
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, 1, 0.6, 0], times: [0, 0.15, 0.6, 1])
        case .mist:
            // Sea mist rolling in off the water from the left, faint enough to putt through.
            e.position = CGPoint(x: rect.minX - 80, y: rect.midY)
            e.particlePositionRange = CGVector(dx: 10, dy: rect.height)
            e.particleTexture = texture("mote") { CourseArt.softDot(pixels: 24, hardness: 0.15) }
            e.particleColor = .white
            e.particleColorBlendFactor = 1
            e.particleBirthRate = 0.45
            e.particleLifetime = 48
            e.particleSpeed = 14
            e.particleSpeedRange = 5
            e.emissionAngle = 0
            e.emissionAngleRange = 0.15
            e.particleScale = 4
            e.particleScaleRange = 1.5
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, 0.1, 0.1, 0], times: [0, 0.2, 0.8, 1])
        case .fireflies, .motes:
            e.position = CGPoint(x: rect.midX, y: rect.midY)
            e.particlePositionRange = CGVector(dx: rect.width, dy: rect.height)
            e.particleTexture = texture("mote") { CourseArt.softDot(pixels: 24, hardness: 0.15) }
            e.particleColor = theme.ambient == .fireflies ? UIColor(hex: 0xD8FF8A) : UIColor(hex: 0xFFF6C8)
            e.particleColorBlendFactor = 1
            e.particleBlendMode = .add
            e.particleBirthRate = theme.ambient == .fireflies ? 5 : 2.2
            e.particleLifetime = 7
            e.particleSpeed = 5
            e.particleSpeedRange = 4
            e.emissionAngleRange = .pi * 2
            e.particleScale = 0.12
            e.particleScaleRange = 0.06
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, 0.8, 0.3, 0.8, 0], times: [0, 0.2, 0.5, 0.7, 1])
        }
        e.particleSize = CGSize(width: 2, height: 2)
        if theme.ambient == .fireflies || theme.ambient == .motes || theme.ambient == .mist { e.particleSize = CGSize(width: 40, height: 40) }
        e.targetNode = worldNode
        worldNode.addChild(e)
        e.advanceSimulationTime(20)
        ambient = e
    }

    /// Now and then a gull flies over the links, head first, beating its wings a few times and then gliding, its
    /// shadow flapping along the ground below.
    private func startGulls(in rect: CGRect) {
        let fly = SKAction.run { [weak self] in
            guard let self, !self.model.paused else { return }
            let scale: CGFloat = 2.2
            let frames = CourseArt.gullFrames(ppu: max(self.renderedPPU, 1) * 1.5 * scale)
            let birdFrames = frames.bird.enumerated().map { k, img in self.texture("gull\(k)") { img } }
            let shadowFrames = frames.shadow.enumerated().map { k, img in self.texture("gullShadow\(k)") { img } }
            let size = CGSize(width: 16 * scale, height: 22 * scale)

            let fromLeft = Bool.random()
            let start = CGPoint(x: fromLeft ? rect.minX - 20 : rect.maxX + 20, y: .random(in: rect.minY + 80...rect.maxY - 80))
            let end = CGPoint(x: fromLeft ? rect.maxX + 20 : rect.minX - 20, y: start.y + .random(in: -90...90))
            let heading = atan2(end.y - start.y, end.x - start.x)

            let gull = SKNode()
            gull.position = start
            gull.zPosition = 55
            let shadow = SKSpriteNode(texture: shadowFrames[0], size: size)
            shadow.alpha = 0.16
            shadow.position = CGPoint(x: 22, y: -34)
            let bird = SKSpriteNode(texture: birdFrames[0], size: size)
            for (node, textures) in [(shadow, shadowFrames), (bird, birdFrames)] {
                node.zRotation = heading
                gull.addChild(node)
                let beat = SKAction.animate(with: textures + [textures[0]], timePerFrame: 0.08)
                node.run(.repeatForever(.sequence([.repeat(beat, count: 3), .wait(forDuration: 1.1, withRange: 0.8)])))
            }
            self.worldNode.addChild(gull)
            let distance = hypot(end.x - start.x, end.y - start.y)
            gull.run(.sequence([.move(to: end, duration: Double(distance) / .random(in: 60...80)), .removeFromParent()]))
        }
        // The first comes along soon after the hole loads, then every so often.
        run(.sequence([.wait(forDuration: 3, withRange: 2), fly,
                       .repeatForever(.sequence([.wait(forDuration: 11, withRange: 8), fly]))]), withKey: "gulls")
    }

    /// Every few seconds a firework bursts in the margins round the course (never over the green).
    private func startFireworks(in rect: CGRect) {
        let felt = CGRect(x: -80, y: -80, width: Course.width + 160, height: Course.height + 160)
        let burst = SKAction.run { [weak self] in
            guard let self, !self.model.paused else { return }
            var p = CGPoint.zero
            for _ in 0..<12 {
                p = CGPoint(x: CGFloat.random(in: rect.minX...rect.maxX), y: CGFloat.random(in: rect.minY...rect.maxY))
                if !felt.contains(p) { break }
            }
            guard !felt.contains(p) else { return }
            let e = SKEmitterNode()
            e.particleTexture = self.texture("mote") { CourseArt.softDot(pixels: 24, hardness: 0.15) }
            e.position = p
            e.zPosition = 49
            e.particleBlendMode = .add
            e.particleColor = [UIColor(hex: 0xFF5DA2), UIColor(hex: 0x5DE2FF), UIColor(hex: 0xFFE45D), UIColor(hex: 0xB08CFF)].randomElement()!
            e.particleColorBlendFactor = 1
            e.numParticlesToEmit = 46
            e.particleBirthRate = 600
            e.particleLifetime = 1.3
            e.particleLifetimeRange = 0.4
            e.particleSpeed = 70
            e.particleSpeedRange = 25
            e.emissionAngleRange = .pi * 2
            e.yAcceleration = -30
            e.particleScale = 0.8
            e.particleScaleSpeed = -0.5
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [1, 1, 0], times: [0, 0.5, 1])
            self.worldNode.addChild(e)
            e.run(.sequence([.wait(forDuration: 2.2), .removeFromParent()]))
        }
        run(.repeatForever(.sequence([.wait(forDuration: 2.6, withRange: 2.0), burst])), withKey: "fireworks")
    }

    private func buildBalls() {
        ballNodes.forEach { $0.removeFromParent() }
        putters.forEach { $0.removeFromParent() }
        spinUniforms = []
        if ballSpin.count != world.balls.count {
            ballSpin = world.balls.map { _ in Self.setDown }
        }
        let px = 14 * renderedPPU * 1.5
        ballNodes = world.balls.indices.map { i in
            let node = SKNode()
            node.zPosition = 15
            let shadow = SKSpriteNode(texture: texture("shadow") { CourseArt.softDot(pixels: 48, color: .black, hardness: 0.35) })
            shadow.size = CGSize(width: 17, height: 17)
            shadow.alpha = 0.45
            shadow.position = CGPoint(x: 1.8, y: -2.6)
            shadow.name = "shadow"
            node.addChild(shadow)
            let d = CGSize(width: Tuning.ballRadius * 2, height: Tuning.ballRadius * 2)
            let base = SKSpriteNode(texture: texture("ballBase") { CourseArt.ball(.base, pixels: px) }, size: d)
            // The stripe, cap spots and dimples are painted on a turning sphere (see ballPaint), so they roll.
            let stripe = SKSpriteNode(texture: texture("white") { CourseArt.softDot(pixels: 4, hardness: 1) }, size: d)
            let spin = SKUniform(name: "u_rot", matrixFloat3x3: matrix_identity_float3x3)
            let color = Palette.side(i), sheen = color.lighter(0.18)
            stripe.shader = SKShader(source: Self.ballPaint, uniforms: [
                spin, SKUniform(name: "u_color", vectorFloat4: color.simd), SKUniform(name: "u_sheen", vectorFloat4: sheen.simd),
            ])
            spinUniforms.append(spin)
            let gloss = SKSpriteNode(texture: texture("ballGloss") { CourseArt.ball(.gloss, pixels: px) }, size: d)
            for (k, layer) in [base, stripe, gloss].enumerated() {
                layer.zPosition = CGFloat(k) * 0.01
                node.addChild(layer)
            }
            let trail = SKEmitterNode()
            trail.particleTexture = texture("dot") { CourseArt.softDot(pixels: 24) }
            trail.particleBirthRate = 0
            trail.particleLifetime = 0.35
            trail.particleSize = CGSize(width: 9, height: 9)
            trail.particleScaleSpeed = -2.4
            trail.particleAlpha = 0.35
            trail.particleAlphaSpeed = -1
            trail.particleColor = .white
            trail.particleColorBlendFactor = 1
            trail.zPosition = -0.5
            trail.targetNode = fxNode
            trail.name = "trail"
            node.addChild(trail)
            worldNode.addChild(node)
            return node
        }
        putters = world.balls.indices.map { _ in
            let p = SKSpriteNode(texture: texture("putter") { CourseArt.putter(pixels: 22 * renderedPPU * 1.5) })
            p.size = CGSize(width: 22, height: 20)
            p.anchorPoint = CGPoint(x: 16.0 / 22, y: 0.5)
            p.zPosition = 16
            p.alpha = 0
            worldNode.addChild(p)
            return p
        }
        syncBalls(reset: true)
    }

    /// Paints a ball's stripe, two cap spots and its dimples on a sphere turned by `u_rot` (world → ball), so they
    /// roll with it. The shading and shine layers above and below stay put: the light doesn't roll.
    private static let ballPaint = """
    void main() {
        vec2 p = v_tex_coord * 2.0 - 1.0;
        float r = length(p);
        vec3 b = u_rot * vec3(p, sqrt(max(0.0, 1.0 - r * r)));
        float aa = 0.06;
        float band = 1.0 - smoothstep(0.32 - aa, 0.32 + aa, abs(b.y));
        float sheen = smoothstep(0.18 - aa, 0.18 + aa, b.y) * band;
        vec3 spot = normalize(vec3(0.55, 0.62, 0.56));
        float spots = 1.0 - smoothstep(0.2 - aa, 0.2 + aa, min(distance(b, spot), distance(b, -spot)));
        float paint = max(band, spots);
        vec3 color = mix(u_color.rgb, u_sheen.rgb, sheen);
        float dimple = 0.09 * (1.0 - smoothstep(0.14, 0.24, length(fract(b * 3.5) - 0.5)));
        // No early return outside the disc: SpriteKit's Metal translation needs the one exit.
        float edge = 1.0 - smoothstep(0.94, 1.0, r);
        gl_FragColor = vec4(color * paint * (1.0 - dimple), paint + dimple * (1.0 - paint)) * edge;
    }
    """

    /// Rolls ball `i` along the ground by one physics step's move `d`: a turn of |d| / radius about the horizontal
    /// axis across its path. Per step, so a bounce mid-frame turns it the whole way round its path, not the chord.
    private func roll(_ i: Int, by d: Vec) {
        let dist = d.length
        guard dist > 0.0001 else { return }
        let axis = simd_float3(Float(-d.y / dist), Float(d.x / dist), 0)
        ballSpin[i] = simd_normalize(simd_quatf(angle: Float(dist / Tuning.ballRadius), axis: axis) * ballSpin[i])
    }

    /// How a ball sits on its tee before any aiming: stripe over the top, pointing straight up the course.
    private static let setDown = simd_quatf(angle: .pi / 2, axis: simd_float3(0, 0, 1))

    /// Sets ball `i` down for the putt the way a golfer would: stripe over the top, along the line. On a true roll it
    /// then holds steady while the spots and dimples turn, and it twists as the ball curls.
    private func lineUp(_ i: Int, to dir: Vec) {
        ballSpin[i] = simd_quatf(angle: Float(atan2(dir.y, dir.x)), axis: simd_float3(0, 0, 1))
        showSpin(i)
    }

    private func showSpin(_ i: Int) {
        guard spinUniforms.indices.contains(i) else { return }
        spinUniforms[i].matrixFloat3x3Value = simd_float3x3(ballSpin[i].inverse)
    }

    private func syncBalls(reset: Bool = false) {
        guard ballNodes.count == world.balls.count else { return }
        for (i, b) in world.balls.enumerated() {
            let node = ballNodes[i]
            if reset {
                node.removeAllActions()
                node.alpha = b.sunkIn == nil ? 1 : 0
                node.setScale(1)
                node.position = b.pos.cg
                ballSpin[i] = Self.setDown
            } else if b.sunkIn == nil {
                node.position = b.pos.cg
            }
            showSpin(i)
            if let trail = node.childNode(withName: "trail") as? SKEmitterNode {
                let speed = b.vel.length
                trail.particleBirthRate = b.sunkIn == nil && speed > 120 ? CGFloat(min(speed / 8, 90)) : 0
            }
        }
        let sunk = world.balls.map { $0.sunkIn != nil }
        if model.sunk != sunk { model.sunk = sunk }
    }

    // MARK: - Level

    func loadLevel() {
        removeAction(forKey: "demo")
        removeAction(forKey: "result")
        // Retrying a hole keeps the movers' clock, so they carry on instead of jumping back.
        let same = level.name == model.level.name
        let clock = same ? world.time : 0
        level = model.level
        theme = model.theme
        world = World(level: level)
        if !same {
            flow = SlopeFlow(level: level)
            for dot in flowDots { dot.isHidden = true }
        }
        world.time = clock
        accumulator = 0
        model.strokes = [0, 0]
        model.sunk = [false, false]
        model.isRolling = false
        model.isDemo = false
        demoCountdown = nil
        model.showResult = false
        model.aim = nil
        model.setMirrored(false)
        dragStart = nil
        dragNode.path = nil
        // A new hole draws its art for the screen as it is now, so a redraw on its way isn't needed.
        pendingRedraw?.cancel()
        pendingRedraw = nil
        redrawing = false
        redrawCover.removeFromParent()
        renderedLevel = nil
        layoutCamera()
        if renderedLevel == nil, renderedPPU > 0 { buildArt(ppu: renderedPPU) }
        syncBalls(reset: true)
        drawnGuide = nil
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = min(currentTime - (lastUpdate ?? currentTime), 1.0 / 20)
        lastUpdate = currentTime

        if model.paused || redrawing {
            // Nothing moves while paused, or while the art redraws for a new screen size.
        } else if model.isRolling && ballsReleased {
            accumulator += dt
            var events: [PhysicsEvent] = []
            while accumulator >= Tuning.dt {
                let before = world.balls.map(\.pos), seen = events.count
                world.step(&events)
                accumulator -= Tuning.dt
                // Pipes and water move a ball without rolling it.
                var jumped: Set<Int> = []
                for e in events[seen...] {
                    switch e {
                    case .tunnel(let b, _, _), .splash(let b, _): jumped.insert(b)
                    default: break
                    }
                }
                for i in world.balls.indices where !jumped.contains(i) && ballSpin.indices.contains(i) {
                    roll(i, by: world.balls[i].pos - before[i])
                }
            }
            handle(events, at: currentTime)
            syncBalls()
            syncMovers(at: world.time)
            if world.isSettled { settle() }
        } else if !level.movers.isEmpty {
            // Movers never stop: between swings (and during the putter's swing) the clock keeps running.
            if var demo = demoCountdown {
                let step = min(dt * demo.rate, demo.left)
                world.advanceMovers(by: step)
                demo.left -= step
                demoCountdown = demo.left > 0 ? demo : nil
                if demo.left <= 0, let shot = level.solution { putt(shot) }
            } else {
                world.advanceMovers(by: dt)
            }
            syncMovers(at: world.time)
        }

        if !model.paused && !redrawing && !flow.isEmpty {
            flow.update(dt: dt)
            drawFlow()
        }

        let state = (aim: model.aim, canAim: model.canAim, full: model.fullPathGuide, side: model.aimSide)
        // The full-path guide (dev) depends on when you'd swing, so it follows the movers.
        let stale = state.full && !level.movers.isEmpty && currentTime - guideDrawnAt > 0.1
        if drawnGuide == nil || drawnGuide!.aim != state.aim || drawnGuide!.canAim != state.canAim
            || drawnGuide!.full != state.full || drawnGuide!.side != state.side || stale {
            drawnGuide = state
            guideDrawnAt = currentTime
            drawGuide()
        }
    }

    private var ballsReleased = true

    /// Draws the slope dots from a pool of sprites, growing it as needed.
    private func drawFlow() {
        var used = 0
        flow.forEachDot { p, alpha in
            if used == flowDots.count {
                let dot = SKSpriteNode(texture: texture("flowDot") { CourseArt.softDot(pixels: 24, hardness: 0.7) },
                                       size: CGSize(width: 4.4, height: 4.4))
                flowNode.addChild(dot)
                flowDots.append(dot)
            }
            let dot = flowDots[used]
            dot.position = p.cg
            dot.alpha = CGFloat(alpha) * 0.9
            dot.isHidden = false
            used += 1
        }
        for dot in flowDots[used...] where !dot.isHidden { dot.isHidden = true }
    }

    private func handle(_ events: [PhysicsEvent], at time: TimeInterval) {
        for e in events {
            switch e {
            case .wall(let ball, let speed) where speed > 40:
                SoundFX.shared.wall(intensity: min(speed / 700, 1))
                if speed > 140, time - lastHaptic > 0.05 {
                    light.impactOccurred(intensity: min(speed / 600, 1))
                    lastHaptic = time
                }
                if speed > 260 { puff(at: world.balls[ball].pos, count: 6, color: theme.borderTop.lighter(0.3)) }
            case .bumper(let ball, let speed):
                SoundFX.shared.wall(intensity: min(speed / 500, 1))
                medium.impactOccurred()
                puff(at: world.balls[ball].pos, count: 6, color: .white)
            case .balls(_, _, let speed):
                SoundFX.shared.ballHit(intensity: min(speed / 600, 1))
                heavy.impactOccurred(intensity: min(0.4 + speed / 600, 1))
                let mid = (world.balls[0].pos + world.balls[1].pos) * 0.5
                puff(at: mid, count: 10, color: .white)
            case .sunk(let ball, let cup):
                sink(ball: ball, cup: cup)
            case .splash(let ball, let at):
                splash(ball: ball, at: at)
            case .kick(let ball, let at):
                SoundFX.shared.putt(power: 0.9)
                medium.impactOccurred(intensity: 0.8)
                puff(at: at, count: 10, color: UIColor(hex: 0xFFD54F))
                ballNodes[ball].run(.sequence([.scale(to: 1.25, duration: 0.06), .scale(to: 1, duration: 0.14)]))
            case .tunnel(let ball, let from, let to):
                let color = TunnelColors.color(level.tunnels.firstIndex { $0.a == from || $0.b == from } ?? 0)
                puff(at: from, count: 8, color: color)
                puff(at: to, count: 10, color: color)
                SoundFX.shared.putt(power: 0.25)
                light.impactOccurred(intensity: 0.7)
                ballNodes[ball].setScale(0.5)
                ballNodes[ball].run(.scale(to: 1, duration: 0.18))
            default:
                break
            }
        }
    }

    private func settle() {
        let demo = model.isDemo
        model.isRolling = false
        model.isDemo = false
        giveRelief()
        model.analytics.settled(strokes: model.strokes, sunk: world.balls.map { $0.sunkIn != nil })
        guard world.allSunk else { return }
        model.recordFinish(demo: demo)
        let doubleAce = model.strokes == [1, 1]
        if doubleAce {
            confetti()
            SoundFX.shared.doubleAce()
            notify.notificationOccurred(.success)
            cam.run(.sequence([.moveBy(x: 3, y: 0, duration: 0.04), .moveBy(x: -6, y: 0, duration: 0.06), .moveBy(x: 3, y: 0, duration: 0.04)]))
        } else {
            run(.sequence([.wait(forDuration: 0.4), .run { SoundFX.shared.result(good: self.model.total <= self.model.par) }]))
        }
        run(.sequence([.wait(forDuration: doubleAce ? 1.3 : 0.9), .run { [weak self] in self?.model.showResult = true }]), withKey: "result")
    }

    // MARK: - Shooting

    func putt(_ shot: Shot) {
        guard model.canAim || model.isDemo else { return }
        for i in world.balls.indices where world.balls[i].sunkIn == nil { model.strokes[i] += 1 }
        model.aim = nil
        model.isRolling = true
        ballsReleased = false
        accumulator = 0
        let swing = Self.swing
        for (i, putter) in putters.enumerated() where world.balls[i].sunkIn == nil {
            let dir = direction(shot, ball: i)
            let contact = world.balls[i].pos - dir * (Tuning.ballRadius + 1.5)
            putter.alpha = 1
            putter.run(.sequence([
                .move(to: contact.cg, duration: swing),
                .move(by: CGVector(dx: dir.x * 6, dy: dir.y * 6), duration: 0.08),
                .fadeOut(withDuration: 0.25),
            ]))
        }
        run(.sequence([.wait(forDuration: swing), .run { [weak self] in
            guard let self else { return }
            // Show Ace strikes on the exact tick the solver used (the countdown lands within a frame of it).
            if self.model.isDemo && !self.level.movers.isEmpty { self.world.time = self.level.solutionTime }
            #if DEBUG
            // So does a store capture's (StoreCapture.swift).
            if let strike = self.captureStrikeTime {
                self.world.time = strike
                self.captureStrikeTime = nil
            }
            #endif
            self.world.shoot(shot.velocity, mirrored: shot.mirrored)
            self.ballsReleased = true
            SoundFX.shared.putt(power: shot.power)
            self.medium.impactOccurred(intensity: 0.5 + shot.power * 0.5)
            for (i, b) in self.world.balls.enumerated() where b.sunkIn == nil {
                self.puff(at: b.pos - self.direction(shot, ball: i) * 6, count: 5, color: self.theme.feltLight.lighter(0.4))
            }
        }]))
    }

    func playDemo() {
        guard let shot = level.solution else { return }
        loadLevel()
        model.isDemo = true
        model.setMirrored(shot.mirrored)
        model.aim = shot
        drawnGuide = nil
        let show = 1.6
        guard world.moverCycle > 0 else {
            run(.sequence([.wait(forDuration: show), .run { [weak self] in self?.putt(shot) }]), withKey: "demo")
            return
        }
        // Wait for the movers to come round to the solution's timing, fast-forwarding a long wait.
        let cycle = world.moverCycle
        var press = level.solutionTime - Self.swing
        while press < world.time + show { press += cycle }
        let left = press - world.time
        demoCountdown = (left, max(1, left / show))
    }

    private func direction(_ shot: Shot, ball i: Int) -> Vec {
        var v = shot.velocity.normalized
        if shot.mirrored && i == 1 { v.x = -v.x }
        return v
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard model.canAim, !redrawing, dragStart == nil, let t = touches.first, let v = view else { return }
        dragStart = t.location(in: v)
        dragSide = convertPoint(fromView: dragStart!).x > Course.half ? 1 : 0
        tickBucket = model.aim.map { Int($0.power * 10) } ?? -1
        selection.prepare()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard model.canAim, let start = dragStart, let t = touches.first, let v = view else { return }
        let p = t.location(in: v)
        let pull = CGVector(dx: start.x - p.x, dy: p.y - start.y)
        let len = hypot(pull.dx, pull.dy)
        drawDrag(from: convertPoint(fromView: start), to: convertPoint(fromView: p))
        guard len > 12 else { return }
        var angle = atan2(pull.dy, pull.dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        // In Mirror, the ball on the side you drag on gets exactly this aim; the stored aim is ball A's.
        if model.mirrored && dragSide == 1 { angle = GameModel.flip(angle) }
        let power = min(len / Self.maxDragPoints, 1)
        model.aimSide = dragSide
        model.setAim(Shot(angle: angle, power: power))
        let bucket = Int(power * 10)
        if bucket != tickBucket {
            tickBucket = bucket
            selection.selectionChanged()
            SoundFX.shared.tick()
        }
    }

    /// The drag line: a ring where the finger went down and a line to where it is now (course units).
    private func drawDrag(from a: CGPoint, to b: CGPoint) {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: a.x - 5 / pointsPerUnit, y: a.y - 5 / pointsPerUnit, width: 10 / pointsPerUnit, height: 10 / pointsPerUnit))
        path.move(to: a)
        path.addLine(to: b)
        dragNode.path = path
        dragNode.lineWidth = 2 / pointsPerUnit
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endDrag() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endDrag() }

    private func endDrag() {
        guard dragStart != nil else { return }
        dragStart = nil
        dragNode.path = nil
        model.finishedAiming()
    }

    #if DEBUG
    // MARK: - Store capture (StoreCapture.swift)

    /// When set, the next putt strikes with the movers' clock at exactly this time, as Show Ace does, so a stored
    /// double ace on a hole with movers plays out as the solver found it.
    var captureStrikeTime: Double?
    private var captureFinger: SKShapeNode?

    /// The movers' clock, and how long they take to come round together (0 without movers).
    var captureMoverClock: Double { world.time }
    var captureMoverCycle: Double { world.moverCycle }
    var capturePointsPerUnit: CGFloat { pointsPerUnit }

    /// A ball's centre, in course units.
    func captureBall(_ i: Int) -> CGPoint { world.balls[i].pos.cg }

    /// One frame of a scripted drag on `side`'s ball from `start` to `finger` (course units), aiming `shot`: the drag
    /// line and the guide as a player's drag draws them, and a fingertip over it when `touch` is set.
    func captureDrag(side: Int, start: CGPoint, finger: CGPoint, shot: Shot, touch: Bool) {
        drawDrag(from: start, to: finger)
        if touch {
            let tip = captureFinger ?? {
                let node = SKShapeNode()
                node.fillColor = UIColor.white.withAlphaComponent(0.3)
                node.strokeColor = UIColor.white.withAlphaComponent(0.7)
                node.zPosition = 41
                worldNode.addChild(node)
                captureFinger = node
                return node
            }()
            let r = 21 / pointsPerUnit
            tip.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r), transform: nil)
            tip.lineWidth = 1.5 / pointsPerUnit
            tip.position = finger
            tip.isHidden = false
        }
        model.aimSide = side
        model.setAim(shot)
        let bucket = Int(shot.power * 10)
        if bucket != tickBucket {
            tickBucket = bucket
            SoundFX.shared.tick()
        }
    }

    func captureEndDrag() {
        dragNode.path = nil
        captureFinger?.isHidden = true
        tickBucket = -1
    }
    #endif

    // MARK: - Guide

    private func drawGuide() {
        guideNode.removeAllChildren()
        let aim = model.aim
        for (i, putter) in putters.enumerated() {
            guard let aim, model.canAim || model.isDemo, world.balls[i].sunkIn == nil else {
                if !model.isRolling { putter.alpha = 0 }
                continue
            }
            let dir = direction(aim, ball: i)
            lineUp(i, to: dir)
            let back = Tuning.ballRadius + 3 + 26 * aim.power
            putter.removeAllActions()
            putter.alpha = 1
            putter.position = (world.balls[i].pos - dir * back).cg
            putter.zRotation = atan2(dir.y, dir.x)
        }
        guard let aim, model.canAim || model.isDemo else { return }

        if aim.mirrored, world.balls.indices.contains(model.aimSide), world.balls[model.aimSide].sunkIn == nil {
            let ring = SKShapeNode(circleOfRadius: Tuning.ballRadius + 5)
            ring.position = world.balls[model.aimSide].pos.cg
            ring.strokeColor = UIColor.white.withAlphaComponent(0.85)
            ring.lineWidth = 1.5
            ring.glowWidth = 2
            guideNode.addChild(ring)
        }

        let paths = world.guide(shot: aim.velocity, mirrored: aim.mirrored, fullPath: model.fullPathGuide, lead: Self.swing)
        for (i, g) in paths.enumerated() where world.balls[i].sunkIn == nil {
            let color = Palette.side(i)
            for (k, piece) in g.pieces.enumerated() where piece.points.count > 1 {
                let pts = resample(piece.points, spacing: 8, skip: k == 0 ? Tuning.ballRadius + 4 : 6)
                guard !pts.isEmpty else { continue }
                guideNode.addChild(dots(pts, radius: piece.faded ? 1.6 : 1.9, color: color, alpha: piece.faded ? 0.6 : 1))
            }
            for m in g.markers {
                let ring = SKShapeNode(circleOfRadius: 3.6)
                ring.position = m.cg
                ring.strokeColor = .white
                ring.fillColor = color.withAlphaComponent(0.5)
                ring.lineWidth = 1.1
                guideNode.addChild(ring)
            }
            if model.fullPathGuide, let end = g.endPoint {
                let ghost = SKShapeNode(circleOfRadius: Tuning.ballRadius)
                ghost.position = end.cg
                ghost.strokeColor = color
                ghost.lineWidth = 1.5
                ghost.fillColor = UIColor.white.withAlphaComponent(g.end == .sunk ? 0.8 : 0.3)
                guideNode.addChild(ghost)
            }
        }
    }

    private func resample(_ pts: [Vec], spacing: Double, skip: Double) -> [Vec] {
        var out: [Vec] = []
        var carry = skip
        for k in 1..<max(pts.count, 1) {
            let a = pts[k - 1], b = pts[k]
            let seg = (b - a).length
            guard seg > 0 else { continue }
            var t = carry
            while t <= seg {
                out.append(a + (b - a) * (t / seg))
                t += spacing
            }
            carry = t - seg
        }
        return out
    }

    private func dots(_ pts: [Vec], radius: CGFloat, color: UIColor, alpha: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        for p in pts { path.addEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)) }
        let n = SKShapeNode(path: path)
        n.fillColor = color
        n.strokeColor = UIColor.white.withAlphaComponent(0.85)
        n.lineWidth = 0.7
        n.alpha = alpha
        return n
    }

    // MARK: - Effects

    private func sink(ball i: Int, cup: Int) {
        let node = ballNodes[i]
        let target = level.cups[cup].cg
        SoundFX.shared.cupDrop()
        notify.notificationOccurred(.success)
        node.run(.sequence([
            .group([.move(to: target, duration: 0.1), .scale(to: 0.7, duration: 0.18)]),
            .group([.scale(to: 0.35, duration: 0.18), .fadeOut(withDuration: 0.2)]),
        ]))
        node.childNode(withName: "shadow")?.run(.fadeOut(withDuration: 0.1))
        let strokes = model.strokes[i]
        // Just the side's strokes: par words only make sense for the whole hole, on the result card.
        let text = strokes == 1 ? "ACE!" : "\(strokes)"
        if strokes == 1, model.strokes != [1, 1] || world.balls.contains(where: { $0.sunkIn == nil }) {
            run(.sequence([.wait(forDuration: 0.25), .run { SoundFX.shared.ace() }]))
        }
        popText(text, at: CGPoint(x: target.x, y: target.y + 18), color: Palette.side(i), big: strokes == 1)
        let ring = SKShapeNode(circleOfRadius: Tuning.cupRadius)
        ring.position = target
        ring.strokeColor = .white
        ring.lineWidth = 1.5
        ring.zPosition = 14
        fxNode.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 2.4, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
    }

    private func splash(ball i: Int, at p: Vec) {
        model.strokes[i] += 1
        model.analytics.splashed()
        SoundFX.shared.splash()
        notify.notificationOccurred(.error)
        let e = SKEmitterNode()
        e.particleTexture = texture("dot") { CourseArt.softDot(pixels: 24) }
        e.position = p.cg
        e.numParticlesToEmit = 26
        e.particleBirthRate = 400
        e.particleLifetime = 0.55
        e.particleSpeed = 70
        e.particleSpeedRange = 40
        e.emissionAngleRange = .pi * 2
        e.particleSize = CGSize(width: 4, height: 4)
        e.particleScaleSpeed = -1
        e.particleColor = UIColor(hex: 0xDFF4FF)
        e.particleColorBlendFactor = 1
        e.particleAlphaSpeed = -1.6
        e.zPosition = 18
        fxNode.addChild(e)
        e.run(.sequence([.wait(forDuration: 1), .removeFromParent()]))
        for k in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 4)
            ring.position = p.cg
            ring.strokeColor = UIColor.white.withAlphaComponent(0.85)
            ring.lineWidth = 1.2
            ring.zPosition = 17
            ring.alpha = 0
            fxNode.addChild(ring)
            ring.run(.sequence([.wait(forDuration: Double(k) * 0.14), .fadeAlpha(to: 1, duration: 0.01),
                                .group([.scale(to: 4.5, duration: 0.7), .fadeOut(withDuration: 0.7)]), .removeFromParent()]))
        }
        let node = ballNodes[i]
        node.alpha = 0
        node.run(.sequence([.wait(forDuration: 0.5), .fadeIn(withDuration: 0.3)]))
        popText("+1", at: CGPoint(x: world.balls[i].pos.x, y: world.balls[i].pos.y + 16), color: UIColor(hex: 0xFF5A5F), big: false)
    }

    private func puff(at p: Vec, count: Int, color: UIColor) {
        let e = SKEmitterNode()
        e.particleTexture = texture("dot") { CourseArt.softDot(pixels: 24) }
        e.position = p.cg
        e.numParticlesToEmit = count
        e.particleBirthRate = 300
        e.particleLifetime = 0.4
        e.particleSpeed = 30
        e.particleSpeedRange = 15
        e.emissionAngleRange = .pi * 2
        e.particleSize = CGSize(width: 4, height: 4)
        e.particleScaleSpeed = -1.5
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleAlpha = 0.8
        e.particleAlphaSpeed = -2
        e.zPosition = 13
        fxNode.addChild(e)
        e.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
    }

    private func confetti() {
        let r = visibleRect
        for side in [-1.0, 1.0] {
            let e = SKEmitterNode()
            e.particleTexture = texture("confetti") {
                CourseArt.render(CGRect(x: 0, y: 0, width: 2, height: 1), ppu: 12) { p in p.fill(CGRect(x: 0, y: 0, width: 2, height: 1), .white) }
            }
            e.position = CGPoint(x: side < 0 ? r.minX + 10 : r.maxX - 10, y: r.midY - r.height * 0.1)
            e.numParticlesToEmit = 140
            e.particleBirthRate = 600
            e.particleLifetime = 3.2
            e.particleSpeed = 420
            e.particleSpeedRange = 160
            e.emissionAngle = side < 0 ? .pi / 3 : .pi * 2 / 3
            e.emissionAngleRange = 0.5
            e.yAcceleration = -260
            e.particleSize = CGSize(width: 7, height: 3.5)
            e.particleScaleRange = 0.4
            e.particleRotationRange = .pi * 2
            e.particleRotationSpeed = 6
            e.particleColor = UIColor(hex: 0xFF5A5F)
            e.particleColorBlendFactor = 1
            e.particleColorRedRange = 1
            e.particleColorGreenRange = 1
            e.particleColorBlueRange = 1
            e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [1, 1, 0], times: [0, 0.8, 1])
            e.zPosition = 60
            worldNode.addChild(e)
            e.run(.sequence([.wait(forDuration: 4), .removeFromParent()]))
        }
    }

    private func popText(_ text: String, at p: CGPoint, color: UIColor, big: Bool) {
        let label = textSprite(text, points: big ? 22 : 16, worldHeight: nil, color: color, outline: .white)
        label.position = p
        label.zPosition = 45
        label.setScale(0.3)
        label.alpha = 0
        fxNode.addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1.1, duration: 0.18)]),
            .scale(to: 1, duration: 0.08),
            .group([.moveBy(x: 0, y: 14, duration: 1.1), .sequence([.wait(forDuration: 0.7), .fadeOut(withDuration: 0.4)])]),
            .removeFromParent(),
        ]))
    }

    /// Text rendered with the rounded system font. Size by on-screen points or by world height.
    private func textSprite(_ text: String, points: CGFloat, worldHeight: CGFloat?, color: UIColor, outline: UIColor?) -> SKSpriteNode {
        let fontSize: CGFloat = 64
        var font = UIFont.systemFont(ofSize: fontSize, weight: .black)
        if let d = font.fontDescriptor.withDesign(.rounded) { font = UIFont(descriptor: d, size: fontSize) }
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if let outline {
            attrs[.strokeColor] = outline
            attrs[.strokeWidth] = -7
        }
        let str = NSAttributedString(string: text, attributes: attrs)
        let bounds = str.boundingRect(with: CGSize(width: 2000, height: 200), options: [], context: nil).integral.insetBy(dx: -6, dy: -4)
        let img = UIGraphicsImageRenderer(size: bounds.size).image { _ in
            str.draw(at: CGPoint(x: 6, y: 4))
        }
        let sprite = SKSpriteNode(texture: SKTexture(image: img))
        let aspect = bounds.width / bounds.height
        let h = worldHeight ?? (points / pointsPerUnit) * (bounds.height / fontSize)
        sprite.size = CGSize(width: h * aspect, height: h)
        return sprite
    }
}
