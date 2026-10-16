// Thunderhead (course 3): asymmetric pairs, ramping from about Nightfall's middle to its hardest.
// Designed with Tools/solver against Tools/levels/BRIEF.md.
extension Levels {

    /// Pair 1. Short vs long: A is a chip from halfway up, B a long haul whose straight line the buoys block, so
    /// B banks off its left fence into a shallow hollow round the cup, which takes a firm putt. That pace races
    /// past A's cup, but the breakwater and the middle wall make a corner that hands it straight back: aim A at
    /// its cup, swing for B, and Mirror.
    static func breakwater() -> Level {
        var l = Level("Breakwater", par: [2, 3], hint: "One short, one long. The breakwater helps.")
        l.setting = "seaside"
        l.frame()
        l.tee(.a, 80, 400)
        l.cup(.a, 140, 560)
        l.block(.a, 0, 700, 200, 800)
        l.tee(.b, 157, 110)
        l.cup(.b, 56, 640)
        l.bumper(.b, 113, 320, r: 16)
        l.bumper(.b, 80, 520, r: 16)
        l.bowl(.b, 56, 640, radius: 30, strength: 120)
        l.solution = Shot(angle: 68.50, power: 0.670, mirrored: true)
        return l
    }

    /// Pair 2. One-sided mechanics: A's pools leave one channel, a few degrees left of straight, to a cup under a
    /// rock (rock and fence send firm putts back). B has no water, only a dune just past its tee that pushes right,
    /// and its cup is dead ahead. So B must start left too: Same lets the dune carry it back to the cup, while
    /// Mirror starts B right and the dune pushes it further off.
    static func tidePools() -> Level {
        var l = Level("Tide Pools", par: [3, 2], hint: "Only one hole has a dune. Read which way it leans.")
        l.setting = "seaside"
        l.frame()
        l.tee(.a, 140, 110)
        l.cup(.a, 100, 720)
        l.block(.a, 0, 690, 82, 800)
        l.water(.a, 0, 300, 100, 360); l.water(.a, 152, 300, 200, 360)
        l.water(.a, 0, 520, 85, 580); l.water(.a, 137, 520, 200, 580)
        l.tee(.b, 100, 120)
        l.cup(.b, 97, 745)
        l.slope(.b, 0, 140, 200, 330, downhill: 0, strength: 200)
        l.solution = Shot(angle: 93.25, power: 0.820, mirrored: false)
        return l
    }

    /// Pair 3. Only A has a sundial, so only A's ball cares when you swing. A's door is up-left of its tee;
    /// Mirror sends B's ball up-right, off the fence and in under B's hedge. Find that one line, then wait
    /// for the sundial's hand to clear A's door.
    static func sundial() -> Level {
        var l = Level("Sundial", par: [3, 2], hint: "Only one ball has to wait for the sundial.")
        l.setting = "garden"
        l.frame()
        // A: a hedge across the lane; the sundial's hand sweeps its door.
        l.block(.a, 0, 400, 60, 440)
        l.block(.a, 160, 400, 200, 440)
        l.rotor(.a, 160, 420, blades: 2, length: 80, rpm: 14, phase: 58)
        l.tee(.a, 175, 115)
        l.cup(.a, 45, 620)
        // B: a hedge stub blocks the straight line; bank off the right fence, with a hedge behind the cup.
        l.block(.b, 90, 290, 150, 320)
        l.block(.b, 100, 640, 200, 670)
        l.tee(.b, 120, 115)
        l.cup(.b, 152, 600)
        l.solution = Shot(angle: 104.25, power: 0.640, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Pair 4. Unrelated layouts: A's cup hides behind a planter, so A banks off its left fence. B is an open green
    /// with its cup dead ahead and a hill guarding the front-left. B could bank off either fence, but the hill
    /// spoils the left bank (Same), so it is the right bank, and Mirror, that matches A.
    static func topiary() -> Level {
        var l = Level("Topiary", par: [3, 2], hint: "Hedges hide one cup. A hill guards the other.")
        l.setting = "garden"
        l.frame()
        l.tee(.a, 120, 110)
        l.cup(.a, 83, 690)
        l.block(.a, 60, 330, 200, 480)
        l.tee(.b, 100, 110)
        l.cup(.b, 100, 700)
        l.hill(.b, 50, 600, radius: 65, strength: 200)
        l.solution = Shot(angle: 109.75, power: 0.710, mirrored: true)
        return l
    }

    /// Pair 5. One long putt, one short chip, one power. A's ramp carries its ball most of the way and leans
    /// it left, so A aims up the pass on the right, right of its cup; B's cup is just left of straight up, which
    /// makes it a Mirror swing. The rock behind B's hollow soaks up the extra pace.
    static func plateau() -> Level {
        var l = Level("Plateau", par: [3, 2], hint: "The ramp carries the long putt, but it leans.")
        l.setting = "desert"
        l.frame()
        // A: a long ramp that leans left; a ledge leaves one pass, on the right.
        l.slope(.a, 0, 150, 200, 560, downhill: 115, strength: 200)
        l.block(.a, 0, 290, 165, 340)
        l.tee(.a, 172, 110)
        l.cup(.a, 138, 698)
        l.block(.a, 70, 718, 190, 748)
        // B: the tee sits up on the plateau, a short chip from a cup in a hollow under a rock.
        l.block(.b, 0, 95, 200, 400)
        l.tee(.b, 100, 420)
        l.bowl(.b, 90, 700, radius: 55, strength: 140)
        l.cup(.b, 90, 700)
        l.block(.b, 20, 725, 170, 755)
        l.solution = Shot(angle: 87.00, power: 0.540, mirrored: true)
        return l
    }

    /// Pair 6. Neither ball can reach its own cup. A's mine pipe comes up inside B's box canyon, so A's ball
    /// plays B's cup; B's ball has to get into A's cave, and the arroyo drains toward its mouth. The pipe and
    /// the arroyo both take banks, so Same and Mirror each have a line.
    static func arroyo() -> Level {
        var l = Level("Arroyo", par: [2, 3], hint: "Each cup has one way in. Find both.")
        l.setting = "desert"
        l.frame(gaps: [400...480])
        // A: the mesa fills the lane above the tee, but for a cave that opens onto B. A ball that comes back
        // through the pipe drops out below the mesa, heading away from it.
        l.block(.a, 0, 300, 200, 380)
        l.block(.a, 0, 380, 50, 560)
        l.block(.a, 0, 560, 200, 800)
        l.tee(.a, 40, 115)
        l.tunnel(.a, 118, 275, .b, 90, 600, exitA: 270, exitB: 59)
        l.cup(.a, 140, 480)
        // B: the arroyo tilts toward the cave; B's cup is walled into a box canyon with the pipe's far end.
        l.tee(.b, 150, 115)
        l.slope(.b, 0, 280, 200, 480, downhill: 180, strength: 140)
        l.block(.b, 40, 540, 60, 800)
        l.block(.b, 60, 540, 200, 560)
        l.cup(.b, 150, 700)
        l.solution = Shot(angle: 132.25, power: 0.610, mirrored: true)
        return l
    }

    /// Pair 7. A's icy pond leaves one way to its cup: bank off the left fence by the tee and skim past the pond's
    /// corner. B's left is snowed in, so Mirror sends B's ball up-right, where the plough running up and down the fence
    /// banks it back to the cup. Only while the plough is low, though: miss it and the fence banks the ball too late,
    /// wide of the cup.
    static func avalanche() -> Level {
        var l = Level("Avalanche", par: [3, 3], hint: "Both holes need a bank. One bank keeps moving.")
        l.setting = "winter"
        l.frame()
        // A: an icy pond fills the right of the lane; the cup is beyond it.
        l.tee(.a, 40, 115)
        l.water(.a, 60, 200, 200, 290)
        l.cup(.a, 150, 520)
        // B: a snowbank closes the left of the lane; a plough runs up and down the right fence.
        l.tee(.b, 60, 115)
        l.block(.b, 0, 300, 95, 340)
        l.slider(.b, 150, 230, 190, 270, dx: 0, dy: 180, period: 2.4)
        l.cup(.b, 55, 541)
        l.solution = Shot(angle: 118.00, power: 0.620, mirrored: true)
        l.solutionTime = 2.11
        return l
    }

    /// Pair 8. A is the long haul, and its ice bridge is the obvious way over the river, but going round by the bridge
    /// takes a firm putt while B is a short chip into a snow house with a windmill in the door. The pipe under the
    /// river makes A short too: aim the same way (A's ball at the pipe, B's at the door) at B's soft pace, when the
    /// door is clear.
    static func iceBridge() -> Level {
        var l = Level("Ice Bridge", par: [3, 3], hint: "Two ways over the river. Only one suits both holes.")
        l.setting = "winter"
        l.frame()
        // A: a long hole. A narrow ice bridge crosses the river on the left; a pipe runs under it on the right.
        l.tee(.a, 100, 115)
        l.water(.a, 0, 400, 40, 460)
        l.water(.a, 66, 400, 200, 460)
        l.tunnel(.a, 150, 290, .a, 134, 496)
        l.cup(.a, 175, 661)
        // B: a short hole up top; a windmill turns in the door of the cup's snow house.
        l.tee(.b, 52, 388)
        l.block(.b, 0, 560, 84, 590)
        l.block(.b, 120, 560, 200, 590)
        l.rotor(.b, 70, 575, blades: 2, length: 48, rpm: 20, phase: 0)
        l.cup(.b, 130, 690)
        l.solution = Shot(angle: 75.00, power: 0.530, mirrored: false)
        l.solutionTime = 0.23
        return l
    }

    /// Pair 9. The finale. A's ball has to slip through the one gap in a row of storm-cloud bumpers that leads to the
    /// hollow, which curls it into the cup. B's cup is on an island: the only way on is the pipe, and a windmill keeps
    /// sweeping its mouth. The gap leans right and the pipe left, so Mirror, at a pace both cups accept, between
    /// blades.
    static func thunderclap() -> Level {
        var l = Level("Thunderclap", par: [3, 3], hint: "One gap in the clouds. One pipe to the island. One swing.")
        l.setting = "winter"
        l.frame()
        // A: a row of storm-cloud bumpers between the tee and the cup's hollow.
        l.tee(.a, 40, 130)
        l.bumper(.a, 50, 380, r: 19)
        l.bumper(.a, 110, 380, r: 19)
        l.bumper(.a, 170, 380, r: 19)
        l.cup(.a, 121, 599)
        l.bowl(.a, 121, 599, radius: 55, strength: 160)
        // B: the cup is on an island in a frozen lake; a pipe runs under the ice, and a windmill sweeps its mouth.
        l.tee(.b, 140, 115)
        l.water(.b, 0, 450, 200, 540)
        l.water(.b, 0, 540, 45, 800)
        l.water(.b, 155, 540, 200, 800)
        l.water(.b, 45, 750, 155, 800)
        l.tunnel(.b, 110, 320, .b, 118, 566)
        l.rotor(.b, 142, 330, blades: 3, length: 42, rpm: 20, phase: 0)
        l.cup(.b, 94, 696)
        l.solution = Shot(angle: 80.75, power: 0.560, mirrored: true)
        l.solutionTime = 2.95
        return l
    }
}
