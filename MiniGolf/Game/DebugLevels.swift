#if DEBUG
// Mechanic test pairs for checking visuals: launch with `-tests 1`.
enum DebugLevels {
    static let all: [Level] = [starbaseTest(), muniTest(), stadiumTest(), tunnelTest(), slopeTest(), contourTest(), surfaceTest(), rotorTest(),
                               sliderTest(), funfairTest("midway"), funfairTest("bigtop"), funfairTest("fireworks")]

    /// Starbase: patrol robots, force fields, teleporter pads, a boost pad, machinery, an open hatch and a gravity well.
    static func starbaseTest() -> Level {
        var l = Level("starbaseTest", par: [2, 2], hint: "")
        l.setting = "starbase"
        l.frame(gaps: [560...640])
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.block(.a, 20, 380, 70, 420)
        l.block(.a, 130, 380, 180, 420)
        l.field(.a, 70, 400, 130, 400, period: 2, on: 1)
        l.robot(.a, [(40, 230), (160, 230), (160, 300), (40, 300)], period: 4)
        l.tunnel(.b, 60, 260, .b, 140, 640, exitB: 90)
        l.kicker(.b, 150, 200, toward: 100, speed: 520)
        l.field(.b, 20, 470, 180, 470, period: 3, on: 1.5, start: 1)
        l.water(.a, 30, 600, 90, 660)
        l.bowl(.b, 100, 720, radius: 40)
        l.robot(nil, [(160, 600), (240, 600)], period: 3, radius: 12)
        l.cup(.a, 140, 700); l.cup(.b, 100, 720)
        return l
    }

    /// City Muni: greens in rough with a cart path winding between them, a bunker, contours.
    static func muniTest() -> Level {
        var l = Level("muniTest", par: [2, 2], hint: "")
        l.setting = "muni"
        l.frame()
        l.ground(.rough, nil)
        l.cartPath(nil, [(150, 95), (130, 300), (260, 480), (240, 700), (300, 760)], width: 22)
        l.green(.a, [(40, 110), (150, 120), (160, 330), (90, 360), (30, 250)])
        l.green(.a, [(50, 520), (160, 540), (150, 720), (60, 730)])
        l.green(.b, [(70, 110), (170, 120), (170, 360), (60, 330)])
        l.green(.b, [(80, 560), (180, 560), (170, 740), (60, 720)])
        l.paint(.sand, .b, [(20, 420), (70, 400), (90, 450), (40, 480)], smooth: true)
        l.tilt(.a, downhill: 0, strength: 140)
        l.hollow(.b, 120, 650, radius: 50, strength: 200)
        l.tee(.a, 90, 160); l.tee(.b, 120, 160)
        l.cup(.a, 100, 640); l.cup(.b, 120, 650)
        return l
    }

    /// The Stadium: an island green in a tie-walled pond, a grandstand behind it, a waste bunker and a stand on the
    /// other side angled across a corner.
    static func stadiumTest() -> Level {
        var l = Level("stadiumTest", par: [2, 2], hint: "")
        l.setting = "stadium"
        l.frame()
        l.ground(.rough, nil)
        l.green(.a, [(50, 110), (150, 110), (150, 300), (50, 300)])
        l.paint(.water, .a, [(20, 420), (180, 420), (180, 700), (20, 700)], smooth: true)
        l.green(.a, [(60, 480), (140, 470), (150, 620), (70, 640)], fringe: 10)
        l.stand(.a, 100, 735, width: 140, depth: 30, facing: 270)
        l.green(.b, [(40, 110), (170, 110), (175, 700), (30, 720)])
        l.paint(.sand, .b, [(40, 300), (160, 320), (150, 380), (50, 360)], smooth: true)
        l.stand(.b, 160, 660, width: 90, depth: 28, facing: 225)
        l.tee(.a, 100, 150); l.tee(.b, 100, 150)
        l.cup(.a, 100, 560); l.cup(.b, 90, 600)
        return l
    }

    /// Kicker, carousel, balloon bumpers, a booth awning, a rail and a duck pond in one of the funfair looks.
    static func funfairTest(_ setting: String) -> Level {
        var l = Level("\(setting)Test", par: [2, 2], hint: "")
        l.setting = setting
        l.frame(gaps: [480...560])
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.kicker(.a, 100, 260, toward: 80, speed: 600)
        l.carousel(.b, 100, 420, radius: 50, rpm: 24)
        l.bumper(.a, 60, 520, r: 16); l.bumper(.a, 140, 600, r: 14)
        l.block(.b, 20, 600, 110, 640)
        l.rail(.b, 120, 250, 190, 300)
        l.water(.a, 120, 380, 190, 440)
        l.cup(.a, 140, 700); l.cup(.b, 100, 720)
        return l
    }

    static func tunnelTest() -> Level {
        var l = Level("tunnelTest", par: [2, 2], hint: "")
        l.setting = "desert"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.tunnel(.a, 100, 400, .b, 60, 600, exitB: 90)
        l.cup(.a, 150, 700); l.cup(.b, 60, 720)
        return l
    }

    static func slopeTest() -> Level {
        var l = Level("slopeTest", par: [2, 2], hint: "")
        l.setting = "seaside"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.slope(.a, 0, 300, 200, 500, downhill: 0, strength: 160)
        l.bowl(.b, 100, 650, radius: 60)
        l.cup(.a, 150, 680); l.cup(.b, 100, 650)
        return l
    }

    /// Smooth terrain: a lean, a tier, a hump and a hollow round the cup on one side; a lean and a tier on the other.
    static func contourTest() -> Level {
        var l = Level("contourTest", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.tilt(.a, downhill: 0, strength: 50)
        l.tier(.a, 100, 450, downhill: 260, strength: 160, width: 35)
        l.hump(.a, 60, 260, radius: 55, strength: 120)
        l.hollow(.a, 130, 660, radius: 60, strength: 140)
        l.tilt(.b, downhill: 200, strength: 70)
        l.tier(.b, 100, 380, downhill: 290, strength: 150, width: 50)
        l.cup(.a, 130, 660); l.cup(.b, 70, 690)
        return l
    }

    /// Painted surfaces: rough round a waisted green with a bunker and a wide fringe apron on one side; a green with a
    /// pond and a bunker on the other. Only for looking at surfaces, not solved for a double ace.
    static func surfaceTest() -> Level {
        var l = Level("surfaceTest", par: [2, 2], hint: "")
        l.setting = "links"
        l.bandon = true
        l.frame()
        l.ground(.rough, .a)
        // The fringe swells into a wide apron off the upper lobe's left side (point 7).
        l.green(.a, [(100, 90), (150, 105), (160, 300), (128, 450), (156, 630), (132, 740), (76, 745), (52, 630),
                     (72, 450), (40, 300), (50, 105)], apron: [7: 28])
        l.paint(.sand, .a, [(140, 380), (185, 400), (185, 470), (150, 490), (125, 440)], smooth: true)
        l.tilt(.a, downhill: 0, strength: 50)
        l.ground(.rough, .b)
        l.green(.b, [(50, 85), (150, 85), (160, 300), (155, 560), (140, 700), (100, 735), (60, 700), (45, 560),
                     (40, 300)])
        l.paint(.water, .b, [(60, 330), (140, 330), (150, 420), (100, 460), (50, 420)], smooth: true)
        l.paint(.sand, .b, [(120, 560), (180, 580), (175, 640), (130, 640)], smooth: true)
        l.tee(.a, 100, 130); l.tee(.b, 100, 120)
        l.cup(.a, 100, 690); l.cup(.b, 100, 700)
        return l
    }

    static func rotorTest() -> Level {
        var l = Level("rotorTest", par: [2, 2], hint: "")
        l.setting = "winter"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.rotor(.a, 100, 400, blades: 4, length: 50, rpm: 30)
        l.cup(.a, 100, 680); l.cup(.b, 100, 680)
        return l
    }

    static func sliderTest() -> Level {
        var l = Level("sliderTest", par: [2, 2], hint: "")
        l.setting = "moat"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.slider(.b, 10, 380, 90, 410, dx: 100, dy: 0, period: 2)
        l.cup(.a, 100, 680); l.cup(.b, 100, 680)
        return l
    }
}
#endif
