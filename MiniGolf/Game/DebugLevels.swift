#if DEBUG
// Mechanic test pairs for checking visuals: launch with `-tests 1`.
enum DebugLevels {
    static let all: [Level] = [tunnelTest(), slopeTest(), contourTest(), surfaceTest(), rotorTest(), sliderTest(),
                               funfairTest("midway"), funfairTest("bigtop"), funfairTest("fireworks")]

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

    /// Painted surfaces: rough round a waisted green with a bunker and a wide fringe apron on one hole; a green with a
    /// pond and a bunker on the other. Only for looking at surfaces, not solved for a double ace.
    static func surfaceTest() -> Level {
        var l = Level("surfaceTest", par: [2, 2], hint: "")
        l.setting = "meadow"
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
