// Front nine additions: pairs 5, 7, 9 (designed with Tools/solver).
extension Levels {

    /// Pair 5. Each hole has one hedgerow with a gap at one end: A's low on the left, B's high on the right.
    /// Straight shots are hedged off, so both balls bank off a side fence: A's off the left, B's off the right,
    /// which makes it a Mirror swing even though the tees and cups don't mirror. B's hedge clips the top of
    /// A's bank window, so the angle has to thread both gaps. Angled hedges behind the cups catch firm putts.
    static func hedgerow() -> Level {
        var l = Level("Hedgerow", par: [2, 2], hint: "Find one line through both hedge gaps.")
        l.setting = "garden"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 60, 110)
        l.cup(.a, 100, 620); l.cup(.b, 129, 620)
        l.block(.a, 66, 240, 200, 262)
        l.block(.b, 0, 500, 146, 522)
        l.rail(.a, 89, 670, 137, 656)
        l.rail(.b, 92, 656, 140, 670)
        l.solution = Shot(angle: 111.75, power: 0.76, mirrored: true)
        return l
    }

    /// Pair 7. A is a long putt over the moat to a cup under a tower wall. B's cup sits in front of the castle
    /// gate, which a drawbridge block keeps sliding open and shut. A needs more pace than B can take, so B's ball
    /// must reach the gate while it is shut and bounce back into the cup: putt while the gate is open and the
    /// ball arrives as it closes. Too soft and A falls short; too firm (the "A has a backboard, just hit it"
    /// instinct) and B's ball beats the gate into the courtyard.
    static func drawbridge() -> Level {
        var l = Level("Drawbridge", par: [3, 2], hint: "The gate never stops. Time it, then pick your pace.")
        l.setting = "moat"
        l.frame()
        l.tee(.a, 60, 110); l.cup(.a, 110, 610)
        l.block(.a, 75, 650, 145, 680)
        l.water(.a, 0, 360, 68, 420); l.water(.a, 108, 360, 200, 420)
        l.tee(.b, 140, 110); l.cup(.b, 106, 450)
        l.water(.b, 0, 300, 98, 350); l.water(.b, 139, 300, 200, 350)
        l.block(.b, 0, 495, 64, 530); l.block(.b, 125, 495, 200, 530)
        l.slider(.b, 135, 475, 193, 488, dx: -75, dy: 0, period: 3.1)
        l.solution = Shot(angle: 84.25, power: 0.62, mirrored: true)
        return l
    }

    /// Pair 9. Identical tees; A's dune slopes right, B's slopes left. The cups are not mirror images
    /// (A's well right, B's just right of centre), so Mirror can't work: swing Same, aim a little right of
    /// both, and let the dunes split the balls — A's carried further right, B's pulled back left. Softer
    /// putts curve more, so angle and pace have to agree.
    static func dunes() -> Level {
        var l = Level("Dunes", par: [2, 2], hint: "The dunes lean opposite ways.")
        l.setting = "seaside"
        l.frame()
        l.tee(.a, 100, 110); l.tee(.b, 100, 110)
        l.cup(.a, 160, 640); l.cup(.b, 110, 640)
        l.slope(.a, 0, 260, 200, 440, downhill: 0, strength: 120)
        l.slope(.b, 0, 260, 200, 440, downhill: 180, strength: 120)
        l.solution = Shot(angle: 86, power: 0.64)
        return l
    }
}
