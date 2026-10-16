#if DEBUG
// Mechanic test pairs for checking visuals: launch with `-tests 1`.
enum DebugLevels {
    static let all: [Level] = [tunnelTest(), slopeTest(), contourTest(), greenTest(), sharedGreenTest(), rotorTest(), sliderTest(),
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

    /// Shaped greens: a curvy kidney on one hole, an angled dogleg on the other, both contoured.
    static func greenTest() -> Level {
        var l = Level("greenTest", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.green(.a, [(100, 60), (170, 90), (185, 250), (140, 420), (175, 600), (160, 760), (90, 780), (25, 720),
                     (30, 520), (70, 380), (20, 220), (35, 90)], smooth: true)
        l.green(.b, [(40, 50), (150, 50), (150, 450), (190, 520), (190, 770), (60, 770), (60, 560), (40, 500)])
        l.tee(.a, 100, 130); l.tee(.b, 95, 120)
        l.tilt(.a, downhill: 180, strength: 40)
        l.hollow(.a, 110, 690, radius: 60, strength: 120)
        l.tier(.b, 120, 480, downhill: 270, strength: 150, width: 35)
        l.cup(.a, 110, 690); l.cup(.b, 140, 700)
        return l
    }

    /// One peanut-shaped green shared by both holes, with a hump in the waist.
    static func sharedGreenTest() -> Level {
        var l = Level("sharedGreenTest", par: [2, 2], hint: "")
        l.setting = "meadow"
        l.green([Vec(60, 80), Vec(340, 80), Vec(380, 250), Vec(300, 400), Vec(380, 560), Vec(340, 760), Vec(60, 760),
                 Vec(20, 560), Vec(100, 400), Vec(20, 250)], smooth: true)
        l.tee(.a, 120, 130); l.tee(.b, 80, 130)
        l.hump(nil, 200, 400, radius: 90, strength: 110)
        l.tilt(nil, downhill: 270, strength: 30)
        l.cup(.a, 130, 680); l.cup(.b, 70, 680)
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
