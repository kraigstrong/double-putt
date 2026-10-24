// Back nine additions: holes 14, 15, 17, 18 (designed with Tools/solver).
extension Levels {

    /// Hole 14. Mirror-image sides, each with a mill guarding its door, but the mills turn opposite ways and
    /// are never in step (always 15° off each other's mirror image): at a given moment a soft putt gets swatted in
    /// B, a firm one in A. Only a middle power, struck at the right moment, slips past both.
    static func windmill() -> Level {
        var l = Level("Windmill", par: [3, 3], hint: "Mirror-image mills, but they never turn in step.")
        l.setting = "winter"
        l.frame()
        // Snowbank at the top of both lanes.
        l.block(.a, 0, 655, 200, 800); l.block(.b, 0, 655, 200, 800)
        // Each mill house sits on the inside; its blades sweep the door on the open side of the lane.
        l.block(.a, 125, 400, 200, 460); l.block(.b, 0, 400, 75, 460)
        l.block(.a, 0, 400, 45, 460); l.block(.b, 155, 400, 200, 460)
        l.rotor(.a, 125, 430, blades: 2, length: 68, rpm: 24, phase: 195)
        l.rotor(.b, 75, 430, blades: 2, length: 68, rpm: -24, phase: 330)
        l.tee(.a, 95, 120); l.tee(.b, 105, 120)
        l.cup(.a, 55, 620); l.cup(.b, 145, 620)
        l.solution = Shot(angle: 95.00, power: 0.720, mirrored: true)
        return l
    }

    /// Hole 15. A's cup is dead ahead and B's is up to the right, which looks like no single swing fits.
    /// But the icy slope just past A's tee throws A's ball left: aim both at B's cup with Same and the hill
    /// brings A home. B's sled then decides the power.
    static func sledRun() -> Level {
        var l = Level("Sled Run", par: [3, 3], hint: "Ice by one tee pushes balls left. Mind the sled.")
        l.setting = "winter"
        l.frame()
        l.slope(.a, 0, 135, 200, 255, downhill: 180, strength: 200)
        // Open water along both edges of the run, a snowbank behind the cups.
        for s in [Side.a, .b] {
            l.water(s, 0, 280, 20, 610); l.water(s, 180, 280, 200, 610)
            l.block(s, 0, 685, 200, 800)
        }
        l.slider(.b, 22, 492, 52, 508, dx: 90, dy: 0, period: 2.4)
        l.tee(.a, 100, 120); l.tee(.b, 100, 120)
        l.cup(.a, 100, 650); l.cup(.b, 130, 650)
        l.solution = Shot(angle: 87.00, power: 0.720, mirrored: false)
        return l
    }

    /// Hole 17. Every lantern is a tunnel across the pond. A's lantern pops out on B's far bank and B's left
    /// lantern on A's, so the balls swap sides; B's right lantern only hops B's own pond (Mirror's trap, as
    /// both balls would end up in B). A lamplighter's cart patrols each far bank.
    static func lanterns() -> Level {
        var l = Level("Lanterns", par: [3, 3], hint: "Not every lantern leads to the other green.")
        l.setting = "night"
        l.frame()
        l.water(.a, 0, 380, 200, 450); l.water(.b, 0, 380, 200, 450)
        l.tunnel(.a, 80, 330, .b, 80, 500)
        l.tunnel(.b, 80, 330, .a, 80, 500)
        l.tunnel(.b, 120, 330, .b, 120, 500)
        l.slider(.a, 35, 580, 75, 596, dx: 80, dy: 0, period: 1.8)
        l.slider(.b, 30, 580, 70, 596, dx: 80, dy: 0, period: 1.4)
        l.tee(.a, 100, 120); l.tee(.b, 100, 120)
        l.cup(.a, 59, 720); l.cup(.b, 72, 720)
        l.solution = Shot(angle: 93.50, power: 0.590, mirrored: false)
        return l
    }

    /// Hole 18. Each lantern on its jetty crosses to the other side's far bank, right beside one shared clock
    /// whose hands never stop. They sweep down onto one ball and away from the other. The cups sit off
    /// the exit lines in hollows, so only a ball that is slow enough curls in. Two hands, not three, so both
    /// exit lines open at once (with three, one line was always closing as the other opened).
    static func midnight() -> Level {
        var l = Level("Midnight", par: [3, 3], hint: "The lanterns swap the balls. Mind the clock.")
        l.setting = "night"
        l.frame(gaps: [513...687])
        l.rotor(.a, 200, 600, blades: 2, length: 80, rpm: 17.5, phase: 30)
        for s in [Side.a, .b] {
            l.water(s, 0, 390, 200, 450)
            l.water(s, 0, 200, 20, 390); l.water(s, 180, 200, 200, 390)
        }
        l.tunnel(.a, 70, 350, .b, 70, 480, exitB: 90)
        l.tunnel(.b, 140, 350, .a, 122, 480, exitB: 90)
        l.cup(.a, 107, 735); l.cup(.b, 85, 735)
        l.bowl(.a, 107, 735, radius: 40, strength: 80)
        l.bowl(.b, 85, 735, radius: 40, strength: 80)
        l.tee(.a, 100, 120); l.tee(.b, 100, 120)
        l.solution = Shot(angle: 98.50, power: 0.730, mirrored: true)
        return l
    }
}
