import Foundation

// Big Top (course 5), the second Funfair course: the circus ring. Designed with Tools/solver against
// Tools/levels/BRIEF.md (course 5 targets: narrower windows and no near-free sides, after Midway played easy).
extension Levels {

    /// Hole 1. A's cup sits in the centre ring, whose front door faces the middle wall: bank in off the wall, gently,
    /// or the ball runs straight out the back door. B's springboard waits behind the one gap in the booths, up-left of
    /// its tee, and fires whatever reaches it up to the cup. A goes up-right and B up-left: Mirror, at A's pace.
    static func ringmaster() -> Level {
        var l = Level("Ringmaster", par: [3, 2], hint: "Two doors into the ring, one gap in the booths.")
        l.setting = "bigtop"
        l.frame()
        // A: the centre ring, a low ring of rails round a shallow bowl, open at the front (facing the middle wall)
        // and at the back.
        l.tee(.a, 60, 115)
        l.cup(.a, 85, 470)
        l.bowl(.a, 85, 470, radius: 38, strength: 80)
        for a0 in Array(stride(from: 150.0, to: 285, by: 15)) + Array(stride(from: 330.0, to: 450, by: 15)) {
            let a = a0 * .pi / 180, b = (a0 + 15) * .pi / 180
            l.rail(.a, 85 + 44 * cos(a), 470 + 44 * sin(a), 85 + 44 * cos(b), 470 + 44 * sin(b))
        }
        // B: a row of booths with one gap; the springboard behind it fires up the lane to the cup.
        l.tee(.b, 172, 115)
        l.block(.b, 0, 233, 50, 247)
        l.block(.b, 100, 233, 200, 247)
        l.kicker(.b, 43, 290, toward: 79.7, speed: 520)
        l.cup(.b, 120, 660)
        l.solution = Shot(angle: 53.50, power: 0.590, mirrored: true)
        return l
    }

    /// Hole 2. The juggler's three balloons ring A's cup, and the bottom one blocks the straight putt: bank in off the
    /// left fence, through the gap on the lower left. B's cup hides behind a booth, but the spinning plate turns
    /// clockwise: send the ball up its left side and it curls round over the top into the cup. Both go up-left: Same.
    static func juggler() -> Level {
        var l = Level("Juggler", par: [2, 3],
                      hint: "Slip past the balloons. Let the plate do the turning.")
        l.setting = "bigtop"
        l.frame()
        // A: three balloons round the cup, gaps facing the middle wall, the top and the lower left.
        l.tee(.a, 150, 115)
        l.cup(.a, 127, 560)
        l.bumper(.a, 149, 596, r: 17)
        l.bumper(.a, 85, 561, r: 17)
        l.bumper(.a, 147, 523, r: 17)
        // B: the spinning plate, with the cup tucked behind a booth beyond it.
        l.tee(.b, 120, 115)
        l.carousel(.b, 70, 360, radius: 55, rpm: -50)
        l.block(.b, 115, 400, 200, 440)
        l.cup(.b, 120, 470)
        l.solution = Shot(angle: 124.25, power: 0.700, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Hole 3. Each ball passes a trapeze: A's swings past the one door in A's booths every two seconds, B's crosses
    /// B's lane every three, the other way. A's long putt through the door goes up-right and B's, to the net behind its
    /// cup, up-left: Mirror. Then wait for a moment when both trapezes will be clear.
    static func trapeze() -> Level {
        var l = Level("Trapeze", par: [3, 2], hint: "Two trapezes, two rhythms. Putt when both are clear.")
        l.setting = "bigtop"
        l.frame()
        // A: a long putt through the one door in a row of booths; a trapeze swings past the door. The duck pond
        // behind the cup takes anything too firm.
        l.tee(.a, 70, 115)
        l.slider(.a, 115, 470, 165, 484, dx: -80, dy: 0, period: 2.0)
        l.block(.a, 0, 520, 113, 540)
        l.block(.a, 161, 520, 200, 540)
        l.cup(.a, 155, 640)
        l.water(.a, 0, 705, 200, 800)
        // B: the other trapeze swings the other way, slower; booths on either side and a net behind the cup.
        l.tee(.b, 140, 120)
        l.slider(.b, 25, 300, 69, 314, dx: 80, dy: 0, period: 3.0)
        l.block(.b, 160, 420, 200, 500)
        l.block(.b, 0, 500, 40, 590)
        l.cup(.b, 57, 650)
        l.block(.b, 22, 680, 92, 700)
        l.solution = Shot(angle: 81.00, power: 0.650, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 4. Short vs long: A's booth closes the ring, so A's ball must go into the cannon, which fires it across at
    /// the pace it went in; only a gentle shot curls into the cup, a hot one skims past into the pond. B is a short
    /// chip on an island into a bowl. Both aim up-right (Same): A at the cannon, not its cup.
    static func humanCannonball() -> Level {
        var l = Level("Human Cannonball", par: [2, 3],
                      hint: "The cannon fires as hard as you putt. Mind the pond.")
        l.setting = "bigtop"
        l.frame()
        // A: the long side. A booth closes the ring; the cannon fires the ball over it, across to the cup.
        l.tee(.a, 76, 155)
        l.block(.a, 0, 380, 200, 420)
        l.tunnel(.a, 150, 330, .a, 170, 520, exitB: 180)
        l.cup(.a, 60, 527.5)
        l.water(.a, 0, 480, 36, 560)
        // B: a short chip on an island in the duck pond, into a bowl.
        l.block(.b, 0, 95, 200, 320)
        l.water(.b, 0, 320, 200, 385)
        l.water(.b, 0, 385, 20, 742)
        l.water(.b, 0, 742, 200, 800)
        l.water(.b, 180, 385, 200, 742)
        l.tee(.b, 42, 410)
        l.bowl(.b, 147, 707, radius: 32, strength: 150)
        l.cup(.b, 147, 707)
        l.solution = Shot(angle: 69.25, power: 0.480, mirrored: false)
        return l
    }

    /// Hole 5. A's causeway starts right of its tee and its cup sits right of the causeway, so A's ball walks it corner
    /// to corner, a hair right of straight. B's ring leans right and a hill stands in the way: go up its left flank and
    /// let the lean bring the ball back. Mirror, firm enough to cross A's pond.
    static func tightrope() -> Level {
        var l = Level("Tightrope", par: [3, 2], hint: "One ball walks the tightrope. The other curls past a hill.")
        l.setting = "bigtop"
        l.frame()
        // A: a narrow causeway over the duck pond, off to the right of the tee.
        l.tee(.a, 100, 115)
        l.water(.a, 0, 300, 115, 520)
        l.water(.a, 145, 300, 200, 520)
        l.cup(.a, 154, 680)
        // B: the ring leans right, and a hill stands in the way.
        l.tee(.b, 100, 115)
        l.slope(.b, 0, 180, 200, 560, downhill: 0, strength: 60)
        l.hill(.b, 105, 420, radius: 50, strength: 120)
        l.cup(.b, 60, 680)
        l.solution = Shot(angle: 84.00, power: 0.670, mirrored: true)
        return l
    }

    /// Hole 6. A's ball has one door to its cup, and it only gets through while both spinning plates turn edge-on,
    /// which comes round every 1.25 s. B's cup sits just past the carousel, whose near side turns upward: it takes the
    /// pace off B's ball and turns it up into the cup. A goes up-right, B up-left: Mirror, struck as the plates open.
    static func spinningPlates() -> Level {
        var l = Level("Spinning Plates", par: [3, 2], hint: "Time the spinning plates. The carousel slows the other ball.")
        l.setting = "bigtop"
        l.frame()
        // A: a row of booths with one door guards the cup, and two plates spin in the doorway.
        l.tee(.a, 40, 115)
        l.block(.a, 0, 330, 82, 370)
        l.block(.a, 138, 330, 200, 370)
        l.rotor(.a, 88, 350, blades: 2, length: 28, rpm: 24, phase: 0)
        l.rotor(.a, 132, 350, blades: 2, length: 28, rpm: -24, phase: 150)
        l.cup(.a, 143, 460)
        l.water(.a, 0, 540, 200, 800)
        // B: the cup sits just past a carousel that turns clockwise.
        l.tee(.b, 130, 115)
        l.carousel(.b, 93, 344, radius: 50, rpm: -45)
        l.cup(.b, 60.5, 409)
        l.solution = Shot(angle: 74.50, power: 0.500, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 7. A's springboard waits behind the one door in the booths, and the hoop keeps sliding across it: putt
    /// through the door while the hoop is clear and the springboard fires the ball to the cup. B's pond blocks the
    /// left, so B banks off the right fence. Both go up-right, so Same, firm enough for B's bank.
    static func fireHoop() -> Level {
        var l = Level("Fire Hoop", par: [3, 3], hint: "Go through the hoop while it's clear. Bank round the pond.")
        l.setting = "bigtop"
        l.frame()
        // A: a row of booths with one door; the hoop slides across in front of it, and a springboard waits behind.
        l.tee(.a, 45, 140)
        l.bumper(.a, 22, 185, r: 12)
        l.block(.a, 0, 335, 118, 355)
        l.block(.a, 158, 335, 200, 355)
        l.slider(.a, 100, 300, 145, 312, dx: 44, dy: 0, period: 0.75)
        l.kicker(.a, 167, 407, toward: 108, speed: 540)
        l.cup(.a, 66, 689)
        // B: the duck pond fills the left of the lane, so bank off the right fence.
        l.tee(.b, 60, 115)
        l.water(.b, 0, 320, 120, 540)
        l.cup(.b, 76, 740)
        l.solution = Shot(angle: 65.50, power: 0.750, mirrored: false)
        l.solutionTime = 0.11
        return l
    }

    /// Hole 8. Clowns pile out pad to pad: clip A's first springboard so it fires through the gap in the booths onto
    /// the second, which sends the ball up to the cup; any pace that reaches the pad will do. B's pipe keeps the ball's
    /// line, so aim through it at the cup, past the windmill. A goes up-right and B up-left: Mirror, at B's pace.
    static func clownCar() -> Level {
        var l = Level("Clown Car", par: [2, 3],
                      hint: "Springboards pass it along. The pipe keeps your line.")
        l.setting = "bigtop"
        l.frame()
        // A: pad to pad. The first springboard sends the ball up-left through a gap in the booths to the second, which
        // sends it up to the cup. A duck pond runs along the right fence.
        l.tee(.a, 40, 120)
        l.water(.a, 168, 150, 200, 390)
        l.kicker(.a, 140, 293, toward: 112, speed: 500)
        l.block(.a, 0, 390, 80, 405)
        l.block(.a, 115, 390, 200, 405)
        l.kicker(.a, 54, 506, toward: 90, speed: 450)
        l.cup(.a, 58, 720)
        // B: a row of booths shuts off the top; the pipe keeps the ball's line, and a windmill turns by the cup.
        l.tee(.b, 150, 115)
        l.block(.b, 0, 420, 200, 450)
        l.tunnel(.b, 36, 291, .b, 165, 500)
        l.rotor(.b, 140, 603, blades: 2, length: 42, rpm: 20, phase: 44)
        l.cup(.b, 63, 672)
        l.solution = Shot(angle: 56.75, power: 0.580, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 9. The finale: the carousel bends A's ball, the pipe keeps the bend, and the windmill by the cup lets it
    /// through only at the right moment. B's springboard sits behind one door, past the moat. Mirror, firm, on time.
    static func showstopper() -> Level {
        var l = Level("Showstopper", par: [3, 3],
                      hint: "The pipe keeps the carousel's bend. Mind the moat.")
        l.setting = "bigtop"
        l.frame()
        // A: the carousel bends the ball into the pipe, which keeps its line up past the booths; a windmill guards the
        // cup.
        l.tee(.a, 40, 115)
        l.carousel(.a, 100, 300, radius: 60, rpm: 40)
        l.block(.a, 0, 520, 200, 540)
        l.tunnel(.a, 145, 460, .a, 60, 600)
        l.rotor(.a, 103, 661, blades: 2, length: 30, rpm: 20, phase: 146)
        l.cup(.a, 96, 735)
        // B: the tee stands on a jetty in the duck pond; one door in the booths leads to the springboard.
        l.tee(.b, 150, 165)
        l.water(.b, 0, 95, 200, 135)
        l.water(.b, 0, 135, 30, 345)
        l.water(.b, 170, 135, 200, 345)
        l.block(.b, 0, 360, 71, 375)
        l.block(.b, 105, 360, 200, 375)
        l.kicker(.b, 67, 434, toward: 57, speed: 440)
        l.cup(.b, 160, 570)
        l.solution = Shot(angle: 72.25, power: 0.870, mirrored: true)
        l.solutionTime = 0.06
        return l
    }
}
