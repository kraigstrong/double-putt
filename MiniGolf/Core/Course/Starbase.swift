import Foundation

// Starbase (course 10): a space station deck, and the last course. Back to mechanical mini golf after the putting
// courses: patrol robots (moving bumpers on a loop) and force fields (walls while lit, open while dark), with
// teleporter pads, gravity wells, conveyors, boost pads, machinery and open hatches to space. The holes run in order
// of their double-ace odds, with Mothership as the finale. Designed with Tools/solver against Tools/levels/BRIEF.md.
extension Levels {
    /// Hole 1. The warm-up. A cargo drone crosses A's bay slowly, back and forth, just short of the cup, so A's putt
    /// is straight at the cup but has to cross the drone's line while it's clear: ahead of it or behind it. B's cup is
    /// nearly straight up from its tee, which matches nothing in A; but bank up-right off the machinery block and B's
    /// ball comes back up-left into the cup, the mirror of A's line. Mirror. When the hole loads the drone is heading
    /// for A's line and takes the softer putts (0.058% without it, 0.030% with it); it blocks A's line for about a
    /// second of every four.
    static func dockingBay() -> Level {
        var l = Level("Docking Bay", par: [2, 2], hint: "Time the drone. One ball banks off the machinery.")
        l.setting = "starbase"
        l.frame()
        // A: the bay. A cargo drone crosses it, back and forth, short of the cup.
        l.tee(.a, 150, 120)
        l.robot(.a, [(175, 560), (25, 560)], period: 4)
        l.cup(.a, 70, 640)
        // B: a machinery block stands right of the way up; bank off it into the cup.
        l.tee(.b, 60, 120)
        l.block(.b, 120, 380, 200, 520)
        l.cup(.b, 87, 640)
        l.solution = Shot(angle: 99.00, power: 0.650, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 2. The force field. B's cup hides behind a bulkhead, under the airlock door, a force field across the gap
    /// between a bulkhead and the fence, with an open hatch to space beyond it. The only way in is up past the
    /// bulkhead and off the door, which works only while it's lit: while it's dark the ball sails out into space. A's
    /// long putt runs through a hatchway in a bulkhead to a cup near the far wall, on the same line as B's: Same, firm
    /// enough for A, struck so B's ball reaches the door while it's lit. Take the field away and no double ace is left.
    static func airlock() -> Level {
        var l = Level("Airlock", par: [3, 2], hint: "The airlock door is a wall while it's lit.")
        l.setting = "starbase"
        l.frame()
        // A: a long putt through a hatchway in a bulkhead.
        l.tee(.a, 30, 120)
        l.block(.a, 0, 440, 67, 470)
        l.block(.a, 107, 440, 200, 470)
        l.cup(.a, 133, 730)
        // B: the cup hides behind a bulkhead, under the airlock; the door opens onto space.
        l.tee(.b, 40, 120)
        l.block(.b, 120, 470, 170, 500)
        l.cup(.b, 142.5, 560)
        l.block(.b, 0, 640, 100, 660)
        l.field(.b, 100, 650, 200, 650, period: 3, on: 1.5, start: 0)
        l.water(.b, 0, 660, 200, 800)
        l.solution = Shot(angle: 80.25, power: 0.730, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Hole 3. Robots on loops. A machinery pillar hides A's cup from the tee, and a robot circles it: A's ball banks
    /// off the middle wall, past the pillar's right side, while the robot is round the far side. B's cup
    /// sits off-centre inside the ring a guard robot drives round it, every three seconds; B's ball banks off the
    /// left fence and slips into the ring ahead of the guard. A goes up-right and B up-left: Mirror. When the hole
    /// loads the guard cuts the double ace from 0.056% to 0.022%; A's robot is clear of A's line then, but blocks it
    /// for over two seconds of every six, and keeps a full-power bank off the far wall shut.
    static func patrolRoute() -> Level {
        var l = Level("Patrol Route", par: [3, 2], hint: "One robot circles the pillar, one the cup. Slip past both.")
        l.setting = "starbase"
        l.frame()
        // A: a robot circles a machinery pillar that hides the cup from the tee.
        l.tee(.a, 60, 150)
        l.block(.a, 60, 410, 140, 470)
        l.robot(.a, [(25, 440), (47, 497), (100, 520), (153, 497), (175, 440), (153, 383), (100, 360), (47, 383)],
                period: 6)
        l.cup(.a, 120, 630)
        // B: a guard robot circles the cup.
        l.tee(.b, 170, 150)
        l.robot(.b, [(80, 705), (40, 692), (20, 655), (33, 615), (70, 595), (110, 608), (130, 645), (117, 685)],
                period: 3)
        l.cup(.b, 62, 650)
        l.solution = Shot(angle: 64.75, power: 0.670, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 4. A's cup is sealed in the bay behind a bulkhead, and the only way in is the teleporter pad, behind a door
    /// a force field shuts for most of every two seconds. The pad in the bay fires the ball straight up at the cup, so
    /// A only has to reach the pad while the field is dark, at a pace the cup will take. B banks off the middle wall
    /// round a machinery block. Both go up-left: Same.
    static func teleporter() -> Level {
        var l = Level("Teleporter", par: [2, 3], hint: "The pad is the only way into the bay. Time the field.")
        l.setting = "starbase"
        l.frame()
        // A: a row of machinery with one door, a force field across it, and the pad behind it. The bulkhead seals the
        // bay; the pad there fires the ball up at the cup, with an open hatch beyond.
        l.tee(.a, 165, 115)
        l.block(.a, 0, 280, 56, 310)
        l.block(.a, 106, 280, 200, 310)
        l.field(.a, 56, 295, 106, 295, period: 2, on: 1.25, start: 0.75)
        l.block(.a, 0, 430, 200, 460)
        l.tunnel(.a, 55, 360, .a, 100, 520, exitB: 90)
        l.cup(.a, 100, 680)
        l.water(.a, 0, 720, 200, 800)
        // B: a machinery block hides the cup; bank in off the middle wall.
        l.tee(.b, 150, 115)
        l.block(.b, 90, 290, 140, 330)
        l.cup(.b, 60, 615)
        l.solution = Shot(angle: 113.00, power: 0.630, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Hole 5. A's ball goes through a hatch in the bulkhead and up a conveyor belt that runs back toward the tee, so
    /// only a firm putt climbs it; the firmest run past the cup, come back off the back wall and drop. B's belt runs
    /// with the ball, up to a force field across the gap in B's bulkhead: it's lit as the hole starts and goes dark a
    /// moment later, so a putt that firm reaches it too soon and bounces back. Mirror: A a touch right of straight up,
    /// B a touch left, firm enough for A's belt and just late enough for B's field. Take the field away and the double
    /// ace is twice as common.
    static func conveyorDeck() -> Level {
        var l = Level("Conveyor Deck", par: [3, 3], hint: "One belt fights you. Wait for the field to drop.")
        l.setting = "starbase"
        l.frame()
        // A: a hatch in the bulkhead, then a belt running back down toward the tee; the cup waits at the top.
        l.tee(.a, 116, 120)
        l.block(.a, 0, 300, 100, 330)
        l.block(.a, 146, 300, 200, 330)
        l.slope(.a, 0, 400, 200, 580, downhill: 270, strength: 134)
        l.cup(.a, 132, 663)
        // B: a belt runs up toward a bulkhead; a force field spans the gap, and the cup sits beyond it.
        l.tee(.b, 43, 120)
        l.slope(.b, 0, 220, 200, 420, downhill: 90, strength: 90)
        l.block(.b, 0, 435, 15, 455)
        l.block(.b, 69, 435, 200, 455)
        l.field(.b, 15, 445, 69, 445, period: 2, on: 1, start: 1.37)
        l.cup(.b, 30, 636)
        l.solution = Shot(angle: 87.75, power: 0.870, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 6. Short vs long, both soft. B's tee sits high on a ledge above the machinery, and its cup sits in a gravity
    /// well that only catches a slow ball: putt just hard enough to creep through the door and the well pulls it in,
    /// if the robot driving across in front of it isn't in the way. A's boost pad fires anything that reaches it up to
    /// the cup, so A just has to find it through a narrow door. A goes up-right and B up-left: Mirror.
    static func tractorBeam() -> Level {
        var l = Level("Tractor Beam", par: [2, 2], hint: "The well only catches a slow ball. Mind the robot.")
        l.setting = "starbase"
        l.frame()
        // A: a narrow door, then the boost pad, which fires the ball up the deck to the cup.
        l.tee(.a, 60, 115)
        l.rail(.a, 0, 265, 80.5, 265)
        l.rail(.a, 106, 265, 200, 265)
        l.kicker(.a, 105, 310, toward: 90, speed: 600)
        l.cup(.a, 105, 680)
        // B: a short chip from a ledge above the machinery, through a door and past a patrol robot into the gravity
        // well round the cup; an open hatch beyond takes a ball the well can't hold.
        l.block(.b, 0, 95, 200, 340)
        l.tee(.b, 150, 380)
        l.block(.b, 0, 460, 104, 472)
        l.block(.b, 144, 460, 200, 472)
        l.robot(.b, [(180, 515), (100, 515)], period: 3)
        l.cup(.b, 78, 620)
        l.bowl(.b, 78, 620, radius: 80, strength: 165)
        l.water(.b, 0, 730, 200, 800)
        l.solution = Shot(angle: 77.00, power: 0.350, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 7. A's reactor core spins in the middle of the deck, ringed by four repulsors, with the cup beyond it and a
    /// machinery shelf closing the way round its left side: the ball goes up its right side, between the blades, and
    /// the repulsors steer it back toward the cup. B's cup hides behind machinery, and the only way in is a bank off
    /// the force field across the gap in the left-hand bulkhead, over an open hatch; it lights just after the putt, so
    /// a putt that gets there too soon sails through. Mirror: A up and right, B up and left. Without the field there is
    /// no double ace; without the reactor it is more than twice as common.
    static func reactorCore() -> Level {
        var l = Level("Reactor Core", par: [3, 2], hint: "The reactor never stops. Bank off the force field.")
        l.setting = "starbase"
        l.frame()
        // A: the reactor core spins in the middle of the deck, ringed by repulsors; a shelf closes the way round its
        // left side.
        l.tee(.a, 80, 120)
        l.rotor(.a, 100, 420, blades: 3, length: 44, rpm: 15, phase: 60)
        l.hill(.a, 40, 360, radius: 34, strength: 160)
        l.hill(.a, 160, 360, radius: 34, strength: 160)
        l.hill(.a, 40, 480, radius: 34, strength: 160)
        l.hill(.a, 160, 480, radius: 34, strength: 160)
        l.block(.a, 0, 525, 88, 550)
        l.cup(.a, 112, 650)
        // B: machinery hides the cup; the only bank is a force field across a gap in the side bulkhead, over an open
        // hatch.
        l.tee(.b, 147, 120)
        l.block(.b, 0, 95, 30, 360)
        l.block(.b, 0, 440, 30, 800)
        l.field(.b, 30, 360, 30, 440, period: 4, on: 2, start: 0.44)
        l.water(.b, 0, 360, 30, 440)
        l.block(.b, 95, 480, 200, 520)
        l.cup(.b, 137, 700)
        l.solution = Shot(angle: 68.00, power: 0.690, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 8. A's ball runs a straight line through three doors, each shut by a force field on its own beat: lit for
    /// one second in two, each a little later than the one below, so only a putt struck as the wave of dark doors
    /// starts gets through all three. B's cup sits just above a machinery block that hides it from the tee: its ball
    /// has to bank down off the field across the top while it's lit, or it sails on into the open hatch. Mirror.
    static func laserGrid() -> Level {
        var l = Level("Laser Grid", par: [3, 2], hint: "Slip through the dark gates. A lit one makes a wall.")
        l.setting = "starbase"
        l.frame()
        // A: three bulkheads, each with a door a force field shuts, out of step with each other.
        l.tee(.a, 50, 115)
        l.block(.a, 0, 280, 59, 296)
        l.block(.a, 91, 280, 200, 296)
        l.field(.a, 59, 288, 91, 288, period: 2, on: 1, start: 0.75)
        l.block(.a, 0, 440, 84, 456)
        l.block(.a, 116, 440, 200, 456)
        l.field(.a, 84, 448, 116, 448, period: 2, on: 1, start: 1.05)
        l.block(.a, 0, 600, 109, 616)
        l.block(.a, 141, 600, 200, 616)
        l.field(.a, 109, 608, 141, 608, period: 2, on: 1, start: 1.6)
        l.cup(.a, 140, 700)
        // B: the cup sits above a machinery block; a force field spans the deck above it, with an open hatch beyond.
        l.tee(.b, 170, 115)
        l.block(.b, 40, 380, 110, 420)
        l.cup(.b, 75, 494)
        l.field(.b, 0, 610, 200, 610, period: 3, on: 1.5, start: 0.5)
        l.water(.b, 0, 630, 200, 800)
        l.solution = Shot(angle: 81.00, power: 0.700, mirrored: true)
        l.solutionTime = 0
        return l
    }

    /// Hole 9. The finale. A's teleporter waits in a bay behind a narrow door; it lifts the ball through the hangar
    /// bulkhead to the bridge, where a belt runs back against it and a patrol robot crosses its way to the cup, so only
    /// a few putts are both firm enough and on time. B is a short putt: machinery hides its cup, and the only way in is
    /// a bank off the force field across a gap in the ceiling, over an open airlock. Same, a touch left of straight up,
    /// struck as the robot clears the bridge. Without the field or the teleporter there is no double ace; without the
    /// robot it is twice as common.
    static func mothership() -> Level {
        var l = Level("Mothership", par: [3, 2], hint: "Time the patrol robot. Bank off the force field.")
        l.setting = "starbase"
        l.frame()
        // A: the hangar. The teleporter waits in a bay behind a narrow door; it lifts the ball through the bulkhead to
        // the bridge, where a belt runs back against it and a patrol robot crosses its way to the cup.
        l.tee(.a, 108.5, 120)
        l.rail(.a, 60, 300, 77.75, 300)
        l.rail(.a, 102.25, 300, 120, 300)
        l.rail(.a, 60, 300, 60, 362)
        l.rail(.a, 120, 300, 120, 362)
        l.rail(.a, 60, 362, 120, 362)
        l.tunnel(.a, 90, 330, .a, 30, 470, exitB: 62)
        l.block(.a, 0, 400, 200, 430)
        l.slope(.a, 0, 440, 200, 760, downhill: 242, strength: 160)
        l.robot(.a, [(132, 563), (26, 619)], period: 2)
        l.cup(.a, 152, 700)
        // B: a short putt. Machinery hides the cup; the only bank is a force field across a gap in the ceiling, over an
        // open airlock.
        l.tee(.b, 124, 430)
        l.block(.b, 30, 470, 100, 500)
        l.cup(.b, 75, 560)
        l.block(.b, 0, 740, 60, 800)
        l.block(.b, 120, 740, 200, 800)
        l.field(.b, 60, 740, 120, 740, period: 3, on: 1.5, start: 0)
        l.water(.b, 60, 745, 120, 800)
        l.solution = Shot(angle: 95.50, power: 0.680, mirrored: false)
        l.solutionTime = 0
        return l
    }
}
