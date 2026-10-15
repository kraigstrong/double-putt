#if DEBUG
// Mechanic test pairs for checking visuals: launch with `-tests 1`.
enum DebugLevels {
    static let all: [Level] = [tunnelTest(), slopeTest(), rotorTest(), sliderTest(), funfairTest()]

    static func funfairTest() -> Level {
        var l = Level("funfairTest", par: [2, 2], hint: "")
        l.setting = "midway"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.kicker(.a, 100, 260, toward: 80, speed: 600)
        l.carousel(.b, 100, 420, radius: 50, rpm: 24)
        l.bumper(.a, 60, 520, r: 16); l.block(.b, 20, 600, 90, 630)
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
