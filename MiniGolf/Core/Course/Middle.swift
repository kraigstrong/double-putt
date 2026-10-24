// Middle stretch: holes 11–13 (designed with Tools/solver).
extension Levels {

    /// Hole 11. Looks like a Mirror hole (hollow by A's cup, hill by B's), but both
    /// mounds shove the ball the same way, so both balls need the same correction: Same.
    static func hollow() -> Level {
        var l = Level("Hollow", par: [2, 2], hint: "Hills push, hollows pull.")
        l.setting = "autumn"
        l.frame()
        l.tee(.a, 55, 110); l.tee(.b, 145, 110)
        l.bowl(.a, 105, 500, radius: 80, strength: 200)
        l.hill(.b, 95, 500, radius: 80, strength: 200)
        l.cup(.a, 55, 540); l.cup(.b, 145, 540)
        l.solution = Shot(angle: 91.5, power: 0.59)
        return l
    }

    /// Hole 12. A's cup sits in a walled canyon; the only way in is the pipe that starts in B.
    /// So the balls swap: B's ball takes the pipe to A's cup, A's ball crosses the gap to B's cup.
    static func canyonPipe() -> Level {
        var l = Level("Canyon Pipe", par: [3, 2], hint: "The way into one canyon starts on the other green.")
        l.setting = "desert"
        l.frame(gaps: [420...520])
        l.tee(.a, 40, 110); l.tee(.b, 160, 110)
        l.block(.a, 0, 620, 200, 645)
        l.cup(.a, 100, 740)
        l.tunnel(.b, 58, 338, .a, 100, 685, exitB: 90)
        l.cup(.b, 40, 560)
        l.solution = Shot(angle: 66, power: 0.61, mirrored: true)
        return l
    }

    /// Hole 13. A's left apron tilts into a pipe mouth (and the mesa backs it up);
    /// B's pipe comes up onto a tilted top that curls the ball toward the cup — power decides.
    static func mesa() -> Level {
        var l = Level("Mesa", par: [2, 2], hint: "Both pipes sit on tilted ground.")
        l.setting = "desert"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.slope(.a, 0, 160, 100, 440, downhill: 180, strength: 160)
        l.tunnel(.a, 20, 400, .a, 40, 580, exitB: 70)
        l.block(.a, 0, 460, 140, 540)
        l.cup(.a, 84, 700)
        l.tunnel(.b, 150, 330, .b, 160, 560, exitB: 90)
        l.block(.b, 60, 420, 200, 500)
        l.slope(.b, 0, 520, 200, 780, downhill: 180, strength: 160)
        l.cup(.b, 135, 680)
        l.solution = Shot(angle: 97.25, power: 0.72, mirrored: true)
        return l
    }
}
