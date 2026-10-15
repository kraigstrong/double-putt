import Foundation

// Fireworks (course 6), the last Funfair course: the fair at night. Designed with Tools/solver against
// Tools/levels/BRIEF.md (course 6 targets).
extension Levels {

    /// Pair 1. A's springboard fires whatever reaches it at the back fence, which drops it in the cup, so A only has to
    /// reach the pad: straight through the booth door, or off the left fence. B's booths leave one way round, off its
    /// right fence, and only A's fence line mirrors it: Mirror, firm enough for the pad and soft enough for B.
    static func sparkler() -> Level {
        var l = Level("Sparkler", par: [2, 3], hint: "Any way onto the springboard will do. B has only one way round.")
        l.setting = "fireworks"
        l.frame()
        // A: a row of booths with one door; the springboard in it fires at the back fence, which drops the ball in.
        l.tee(.a, 48, 115)
        l.block(.a, 0, 485, 66, 545)
        l.block(.a, 114, 485, 200, 545)
        l.kicker(.a, 90, 515, toward: 84, speed: 715)
        l.cup(.a, 134, 716)
        // B: a dogleg round a row of booths that leaves a gap by the right fence.
        l.tee(.b, 140, 115)
        l.block(.b, 0, 260, 70, 320)
        l.block(.b, 70, 260, 145, 320)
        l.cup(.b, 125, 467)
        l.solution = Shot(angle: 111.25, power: 0.570, mirrored: true)
        return l
    }

    /// Pair 2. The ferris wheel fills A's lane, and the only way past is the strip by the fence, between two cars: bank
    /// off the left fence beside it just as a gap comes round. B is a short hop from the duck pond's bank, off the back
    /// fence past a balloon. Both go up and a little left: Same, timed for the wheel.
    static func ferrisWheel() -> Level {
        var l = Level("Ferris Wheel", par: [3, 2], hint: "The wheel turns slowly. Slip past it between two spokes.")
        l.setting = "fireworks"
        l.frame()
        // A: the wheel fills the lane; its cars sweep the strip by each fence.
        l.tee(.a, 60, 115)
        l.rotor(.a, 100, 440, blades: 6, length: 81, rpm: -10, phase: 303)
        l.cup(.a, 42, 677)
        // B: the tee is on the duck pond's bank; a balloon guards the cup from the front.
        l.water(.b, 0, 95, 200, 375)
        l.tee(.b, 140, 400)
        l.bumper(.b, 78, 615, r: 14)
        l.cup(.b, 51, 668)
        l.solution = Shot(angle: 99.25, power: 0.690, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Pair 3. The halls look like mirror images, but B's cup sits higher. A banks off its right fence and back to its
    /// cup; Mirror sends B's ball round the same bank, which runs wide of the higher cup. Same sends B's ball off its
    /// near fence instead, and that steeper climb is the one that reaches it.
    static func hallOfMirrors() -> Level {
        var l = Level("Hall of Mirrors", par: [2, 3], hint: "Not quite mirror images. Check where each cup sits.")
        l.setting = "fireworks"
        l.frame()
        // A: a booth blocks the straight line; the duck pond lines the far end.
        l.tee(.a, 40, 115)
        l.block(.a, 96, 370, 127, 420)
        l.cup(.a, 153, 597)
        l.water(.a, 0, 705, 200, 800)
        // B: A's mirror image, but for the cup, which sits higher.
        l.tee(.b, 160, 115)
        l.block(.b, 73, 370, 104, 420)
        l.cup(.b, 41, 660)
        l.water(.b, 0, 705, 200, 800)
        l.solution = Shot(angle: 67.25, power: 0.660, mirrored: false)
        return l
    }

    /// Pair 4. A booth hides A's springboard: bank in off the left fence and it fires the ball up the lane into the
    /// bowl. Reaching it takes a firm putt, far too firm for B's short hop, but B's carousel turns against the ball and
    /// takes the pace off. A goes up-left and B up-right: Mirror.
    static func romanCandle() -> Level {
        var l = Level("Roman Candle", par: [3, 2],
                      hint: "Find a way round to the candle. The carousel can take the pace.")
        l.setting = "fireworks"
        l.frame()
        // A: a long haul. A booth hides the springboard at the foot of a lane between a booth and the duck pond; it
        // fires the ball up the lane into the bowl round the cup.
        l.tee(.a, 80, 125)
        l.block(.a, 105, 240, 200, 330)
        l.block(.a, 0, 480, 125, 670)
        l.water(.a, 182, 480, 200, 670)
        l.kicker(.a, 160, 505, toward: 90, speed: 480)
        l.cup(.a, 160, 700)
        l.bowl(.a, 160, 700, radius: 45, strength: 140)
        // B: a short hop on an island in the duck pond, across a carousel whose near side turns back toward the tee.
        l.water(.b, 0, 95, 200, 445)
        l.water(.b, 0, 445, 20, 650)
        l.water(.b, 180, 445, 200, 650)
        l.water(.b, 0, 650, 200, 800)
        l.tee(.b, 45, 475)
        l.carousel(.b, 121, 524, radius: 50, rpm: 30)
        l.cup(.b, 150, 610)
        l.solution = Shot(angle: 126.50, power: 0.610, mirrored: true)
        return l
    }

    /// Pair 5. A dark ride: A's first pipe keeps the ball's heading, so it has to go in on the line that carries it on
    /// into the second pipe, which lets it out by the cup. B's cup is up-left too, through a door a ghost glides
    /// across: Same, struck so B's ball reaches the door while the ghost is away.
    static func ghostTrain() -> Level {
        var l = Level("Ghost Train", par: [3, 3], hint: "The first ride keeps your heading. The ghost never stops.")
        l.setting = "fireworks"
        l.frame()
        // A: the ride, three rooms split by two booths. Each pipe runs under a booth: the first keeps the ball's
        // heading, the second always lets it out toward the cup.
        l.tee(.a, 100, 115)
        l.block(.a, 0, 300, 200, 340)
        l.tunnel(.a, 55, 255, .a, 150, 380)
        l.block(.a, 0, 560, 200, 600)
        l.tunnel(.a, 120, 502, .a, 60, 640, exitB: 20)
        l.cup(.a, 150, 680)
        // B: the cup is just through a booth's door, and a ghost glides back and forth across it.
        l.tee(.b, 165, 115)
        l.block(.b, 0, 380, 50, 400)
        l.block(.b, 100, 380, 200, 400)
        l.slider(.b, 45, 405, 105, 421, dx: 50, dy: 0, period: 1.2)
        l.cup(.b, 44, 470)
        l.solution = Shot(angle: 107.75, power: 0.550, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Pair 6. A's wheel turns anticlockwise and carries the ball left as it crosses, so A aims a touch right of
    /// straight up, and the little rotor by the way off has to be clear. B's springboard waits through a narrow door a
    /// touch left of straight up and fires the ball round to the cup: Mirror, timed for the blades.
    static func catherineWheel() -> Level {
        var l = Level("Catherine Wheel", par: [3, 3],
                      hint: "The wheel bends every putt. The blades guard the way off.")
        l.setting = "fireworks"
        l.frame()
        // A: the wheel fills the gap between two booths; a little rotor turns by the way off it to the cup.
        l.tee(.a, 100, 115)
        l.block(.a, 0, 330, 34, 470)
        l.block(.a, 166, 330, 200, 470)
        l.carousel(.a, 100, 400, radius: 65, rpm: 45)
        l.rotor(.a, 84, 505, blades: 3, length: 24, rpm: 20, phase: 90)
        l.cup(.a, 100, 545)
        // B: a long putt between two ponds to the springboard just through a booth's door; it fires the ball round to
        // the cup.
        l.tee(.b, 111, 115)
        l.water(.b, 0, 160, 30, 540)
        l.water(.b, 170, 160, 200, 540)
        l.block(.b, 0, 540, 85, 560)
        l.block(.b, 115, 540, 200, 560)
        l.kicker(.b, 100, 590, toward: 0, speed: 330)
        l.cup(.b, 165, 582)
        l.solution = Shot(angle: 88.00, power: 0.760, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Pair 7. A's rocket flies itself: on the launch pad, stage one fires the ball up the tube and stage two fires it
    /// across to the cup. Getting in is the puzzle: a booth roof hides the tube's door, so bank in off the left fence.
    /// B banks off its left fence into the booth too, so Same, at B's pace, struck when both sliders are clear.
    static func rocket() -> Level {
        var l = Level("Rocket", par: [3, 3], hint: "Two stages to fly, two sliders to dodge.")
        l.setting = "fireworks"
        l.frame()
        // A: the launch tube runs up the right side; its only door is low down, under a booth roof that hides it from
        // the tee. The pad inside fires up the tube to stage two, which fires along the top to the cup.
        l.tee(.a, 71, 120)
        l.block(.a, 110, 215, 200, 245)
        l.block(.a, 130, 345, 145, 680)
        l.block(.a, 174, 345, 200, 357)
        l.block(.a, 0, 680, 145, 695)
        l.kicker(.a, 166, 382, toward: 90, speed: 640)
        l.kicker(.a, 163, 745, toward: 180, speed: 420)
        l.cup(.a, 40, 734)
        // B: a short hole from the edge of the duck pond. The cup's booth opens to the left, one slider runs across
        // the way there and another slides up and down in the door.
        l.water(.b, 0, 95, 200, 280)
        l.tee(.b, 150, 320)
        l.block(.b, 100, 500, 200, 512)
        l.block(.b, 90, 618, 200, 630)
        l.block(.b, 90, 562, 102, 618)
        l.cup(.b, 125, 570)
        l.slider(.b, 20, 456, 56, 468, dx: 70, dy: 0, period: 1.2)
        l.slider(.b, 74, 512, 86, 552, dx: 0, dy: 52, period: 0.96)
        l.solution = Shot(angle: 140.50, power: 0.630, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Pair 8. One pipe, both ways. A's ball goes in heading up-right and comes out in B still heading up-right, on
    /// line for B's jetty; B's ball goes in up-left and comes out in A up-left, through the one wide gap in the burst
    /// and into its bowl. The balls swap cups: Mirror, at a pace both cups accept.
    static func starburst() -> Level {
        var l = Level("Starburst", par: [3, 3], hint: "The pipe runs both ways.")
        l.setting = "fireworks"
        l.frame()
        // A: the burst, a ring of balloons round a bowl with the cup in the middle; its widest gap faces the pipe.
        // Booth roofs keep banks off the fences out of it.
        l.tee(.a, 107, 120)
        l.tunnel(.a, 130, 250, .b, 67, 280)
        l.block(.a, 0, 390, 88, 410)
        l.block(.a, 160, 330, 200, 350)
        let burst = Vec(60, 647), gap = 280.0, open = 26.5
        l.cup(.a, burst.x, burst.y)
        l.bowl(.a, burst.x, burst.y, radius: 34, strength: 80)
        for k in 0..<8 {
            let a = (gap + open + (360 - 2 * open) * Double(k) / 7) * .pi / 180
            l.bumper(.a, burst.x + 46 * cos(a), burst.y + 46 * sin(a), r: 9)
        }
        // B: the cup sits at the end of a jetty in the duck pond; a booth roof hides it from the tee.
        l.tee(.b, 95, 120)
        l.block(.b, 112, 380, 146, 400)
        l.cup(.b, 121.5, 612)
        l.water(.b, 0, 520, 98, 800)
        l.water(.b, 142, 520, 200, 800)
        l.water(.b, 98, 670, 142, 800)
        l.solution = Shot(angle: 79.75, power: 0.670, mirrored: true)
        return l
    }

    /// Pair 9. The finale. A's cup is sealed in the grandstand: A's ball threads the door into the pipe to B's launch
    /// bay, where the carousel swings it into the return pipe, which drops it on the pad that fires it into the cup, if
    /// the pace was right. B's ball runs straight up through the door the pinwheel sweeps. Mirror, between blades.
    static func grandFinale() -> Level {
        var l = Level("Grand Finale", par: [3, 3], hint: "A takes the long way home. B waits for the pinwheel.")
        l.setting = "fireworks"
        l.frame()
        // A: a wall with one door; past it, the pipe over to B. The cup is sealed in the grandstand, where the return
        // pipe drops the ball on a launch pad.
        l.tee(.a, 156, 120)
        l.rail(.a, 0, 380, 117, 380)
        l.rail(.a, 147, 380, 200, 380)
        l.tunnel(.a, 125, 460, .b, 135, 290, exitB: 85)
        l.block(.a, 0, 560, 200, 575)
        l.kicker(.a, 69, 651, toward: 0, speed: 360)
        l.cup(.a, 150, 644)
        // B: the pipe from A comes up in the walled launch bay, and only a ball at the right pace rides the carousel
        // round to the return pipe. B's own ball has a straight run to its cup, through a door the pinwheel sweeps
        // and up to the booth roof behind the cup.
        l.block(.b, 102, 250, 200, 262)
        l.block(.b, 102, 262, 110, 720)
        l.block(.b, 110, 708, 200, 720)
        l.carousel(.b, 153, 400, radius: 42, rpm: -50)
        l.tunnel(.b, 165, 480, .a, 50, 640, exitB: 29)
        l.tee(.b, 30, 120)
        l.water(.b, 0, 150, 18, 370)
        l.rail(.b, 0, 380, 38, 380)
        l.rail(.b, 67, 380, 102, 380)
        l.rotor(.b, 13, 380, blades: 2, length: 40, rpm: 30, phase: 0)
        l.block(.b, 40, 708, 102, 720)
        l.cup(.b, 80, 690)
        l.water(.b, 0, 720, 200, 800)
        l.solution = Shot(angle: 95.00, power: 0.740, mirrored: true)
        l.solutionTime = 0
        return l
    }
}
