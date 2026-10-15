import Foundation

// Midway (course 4), the first Funfair course: a daytime fairground that introduces kicker pads (pair 2) and
// carousels (pair 3). Designed with Tools/solver against Tools/levels/BRIEF.md.
extension Levels {

    /// Pair 1. Each cup sits in a ring of balloons with one way in. A's ring opens toward its tee, so A is a straight
    /// putt; B's opens at the back, so B's ball goes up past its ring and drops in off the back fence. A goes up-right
    /// and B up-left: Mirror, at the pace of A's long putt.
    static func ringToss() -> Level {
        var l = Level("Ring Toss", par: [2, 3], hint: "Each ring has one way in, and they face different ways.")
        l.setting = "midway"
        l.frame()
        // A: a long putt; the ring's opening faces back down toward the tee.
        l.tee(.a, 40, 115)
        l.cup(.a, 130, 640)
        for a in [321.0, 21, 81, 141, 201] {
            l.bumper(.a, 130 + 38 * cos(a * .pi / 180), 640 + 38 * sin(a * .pi / 180), r: 13)
        }
        // B: a short hole up on a booth; the ring opens at the back, toward the top fence. A duck pond along the
        // right fence closes the way round that side.
        l.block(.b, 0, 95, 200, 440)
        l.tee(.b, 150, 470)
        l.water(.b, 165, 510, 200, 800)
        l.cup(.b, 58, 640)
        for a in [130.0, 180, 230, 280, 330, 20] {
            l.bumper(.b, 58 + 38 * cos(a * .pi / 180), 640 + 38 * sin(a * .pi / 180), r: 13)
        }
        l.solution = Shot(angle: 80.00, power: 0.680, mirrored: true)
        return l
    }

    /// Pair 2. A's long lane starts at a springboard that launches whatever reaches it up to the cup, so A only needs a
    /// soft putt that gets to the pad. That soft putt is just what B's short hop across the duck pond wants: aim A at
    /// the pad and B at its cup, which is Mirror.
    static func springboard() -> Level {
        var l = Level("Springboard", par: [2, 3], hint: "The springboard does the long part. Mind the pond.")
        l.setting = "midway"
        l.frame()
        // A: a long lane between two booths; the pad at its mouth launches the ball up it.
        l.tee(.a, 40, 120)
        l.block(.a, 0, 430, 75, 800)
        l.block(.a, 155, 430, 200, 800)
        l.kicker(.a, 115, 375, toward: 90, speed: 560)
        l.cup(.a, 115, 740)
        // B: a short putt on an island in the duck pond.
        l.tee(.b, 150, 200)
        l.cup(.b, 91, 400)
        l.water(.b, 0, 95, 200, 165)
        l.water(.b, 0, 165, 55, 440)
        l.water(.b, 135, 290, 200, 440)
        l.water(.b, 0, 440, 200, 800)
        l.solution = Shot(angle: 73.25, power: 0.430, mirrored: true)
        return l
    }

    /// Pair 3. B's teacups slow a crossing ball and curl it the way they spin, so B aims a little right of its cup,
    /// across the side turning its way, and the spin brings it round. A's awning hides its cup: bank off the middle
    /// wall. Both go up-right, so Same, firm enough for A's bank; the teacups soak up the extra for B.
    static func teacups() -> Level {
        var l = Level("Teacups", par: [3, 2], hint: "Teacups bend a ball the way they spin. The awning needs a bank.")
        l.setting = "midway"
        l.frame()
        // A: a bank shot round an awning.
        l.tee(.a, 85, 115)
        l.block(.a, 0, 280, 135, 320)
        l.cup(.a, 127, 526)
        // B: the teacups turn between the tee and the cup.
        l.tee(.b, 25, 115)
        l.carousel(.b, 107, 308, radius: 65, rpm: 50)
        l.cup(.b, 138, 384)
        l.solution = Shot(angle: 65.00, power: 0.610, mirrored: false)
        l.solutionTime = 0
        return l
    }

    /// Pair 4. Only A's ball has to time the ducks: its cup is a straight putt up through both rows. B's balloons leave
    /// one way, a long bank off the left fence, and A's line makes it with Mirror. Then wait for both rows to open at
    /// once; that comes round twice every three seconds.
    static func shootingGallery() -> Level {
        var l = Level("Shooting Gallery", par: [2, 3],
                      hint: "Two rows of ducks, one ball to thread. The balloons stay put.")
        l.setting = "midway"
        l.frame()
        // A: the gallery. Two rows of ducks glide across the lane in opposite directions.
        l.tee(.a, 40, 115)
        l.cup(.a, 141, 690)
        l.slider(.a, 130, 330, 190, 346, dx: -120, dy: 0, period: 3.0)
        l.slider(.a, 10, 500, 70, 516, dx: 120, dy: 0, period: 1.5)
        // B: a bunch of balloons leaves only the left fence.
        l.tee(.b, 60, 115)
        l.cup(.b, 53, 690)
        l.bumper(.b, 60, 400, r: 18)
        l.bumper(.b, 120, 420, r: 18)
        l.bumper(.b, 165, 450, r: 16)
        l.solution = Shot(angle: 80.00, power: 0.680, mirrored: true)
        l.solutionTime = 2.30
        return l
    }

    /// Pair 5. Short vs long, turned round: the long lane is the easy one, since the striker launches whatever reaches
    /// it up to the bell and back down into the cup, if it meets the pad in the right spot. The chip is the test: round
    /// the booth off the left fence, soft enough not to run off the back, and that same line (Same) finds the striker.
    static func highStriker() -> Level {
        var l = Level("High Striker", par: [3, 2], hint: "The striker does the heavy lifting. Ring the bell.")
        l.setting = "midway"
        l.frame()
        // A: a short chip from high up; a booth stands in front of the cup, and behind it the green falls away.
        l.tee(.a, 75, 420)
        l.block(.a, 55, 490, 200, 515)
        l.cup(.a, 120, 605)
        l.slope(.a, 0, 620, 200, 800, downhill: 90, strength: 200)
        // B: the striker launches the ball up the long lane to ring the bell (the top fence).
        l.tee(.b, 165, 115)
        l.kicker(.b, 38, 227, toward: 90, speed: 800)
        l.cup(.b, 48, 700)
        l.solution = Shot(angle: 137.50, power: 0.470, mirrored: false)
        return l
    }

    /// Pair 6. A's pond leaves one way round, off the left fence, and it is a long way, so A needs a firm putt. B is a
    /// short hop that pace would race past, but its carousel drags the pace off: Mirror sends B's ball up across the
    /// disk and it comes off slow enough to drop.
    static func duckPond() -> Level {
        var l = Level("Duck Pond", par: [3, 2], hint: "A long way round the pond, a short hop over the carousel.")
        l.setting = "midway"
        l.frame()
        // A: the pond leaves a narrow way round by the left fence.
        l.tee(.a, 110, 115)
        l.cup(.a, 70, 690)
        l.water(.a, 50, 360, 200, 540)
        l.water(.a, 110, 540, 200, 640)
        // B: a short hole, the carousel between tee and cup.
        l.tee(.b, 40, 235)
        l.carousel(.b, 92, 410, radius: 60, rpm: 40)
        l.cup(.b, 134, 562)
        l.solution = Shot(angle: 107.50, power: 0.710, mirrored: true)
        return l
    }

    /// Pair 7. A's cup hides behind the merry-go-round's pole: putt right of it, with the spin, and the ride curls the
    /// ball in behind. B's springboard fires through the prize booth's door, but only a firm putt off the left fence,
    /// past the duck pond, gets there. Mirror, as firm as B needs and as gentle as A's ride allows.
    static func merryGoRound() -> Level {
        var l = Level("Merry-Go-Round", par: [3, 3],
                      hint: "Ride the merry-go-round round its pole. The springboard is far off.")
        l.setting = "midway"
        l.frame()
        // A: the merry-go-round fills the gap between two booths, and its pole hides the cup.
        l.tee(.a, 40, 115)
        l.block(.a, 0, 230, 50, 290)
        l.block(.a, 0, 410, 38, 470)
        l.block(.a, 162, 410, 200, 470)
        l.carousel(.a, 100, 440, radius: 60, rpm: 36)
        l.bumper(.a, 100, 440, r: 12)
        l.cup(.a, 115, 550)
        // B: the prize booth's one door faces a springboard, reached off the left fence past the duck pond.
        l.tee(.b, 140, 115)
        l.block(.b, 125, 280, 200, 320)
        l.water(.b, 55, 470, 200, 640)
        l.block(.b, 120, 640, 200, 652)
        l.block(.b, 120, 738, 200, 750)
        l.block(.b, 120, 652, 132, 675)
        l.block(.b, 120, 715, 132, 738)
        l.cup(.b, 165, 695)
        l.kicker(.b, 68, 702, toward: 0, speed: 290)
        l.solution = Shot(angle: 70.75, power: 0.710, mirrored: true)
        return l
    }

    /// Pair 8. A balloon blocks A's cup from the front, so A's ball has to run past it and bounce back in off the car
    /// patrolling the duck pond. B's car weaves across the way to the prize booth's door. Mirror, struck when A's car
    /// will be behind the cup and B's car out of the way.
    static func bumperCars() -> Level {
        var l = Level("Bumper Cars", par: [2, 3], hint: "Bump one car, dodge the other.")
        l.setting = "midway"
        l.frame()
        // A: balloons fill the floor; a car runs along the edge of the duck pond, behind the cup.
        l.tee(.a, 60, 115)
        l.block(.a, 0, 200, 40, 300)
        l.bumper(.a, 150, 260, r: 16)
        l.bumper(.a, 70, 380, r: 14)
        l.bumper(.a, 175, 400, r: 14)
        l.bumper(.a, 35, 500, r: 14)
        l.bumper(.a, 146, 443, r: 12)
        l.cup(.a, 146, 480)
        l.slider(.a, 20, 530, 70, 546, dx: 110, dy: 0, period: 1.6)
        l.water(.a, 0, 560, 200, 800)
        // B: the prize booth has one door, and a car weaves back and forth in front of it.
        l.tee(.b, 150, 115)
        l.bumper(.b, 60, 420, r: 14)
        l.bumper(.b, 165, 320, r: 14)
        l.bumper(.b, 160, 470, r: 14)
        l.bumper(.b, 25, 545, r: 12)
        l.slider(.b, 15, 480, 45, 500, dx: 90, dy: 80, period: 2.4)
        l.block(.b, 10, 620, 35, 632)
        l.block(.b, 75, 620, 100, 632)
        l.block(.b, 10, 632, 22, 690)
        l.block(.b, 88, 632, 100, 690)
        l.block(.b, 10, 690, 100, 702)
        l.cup(.b, 52, 666)
        l.solution = Shot(angle: 79.25, power: 0.650, mirrored: true)
        l.solutionTime = 0.12
        return l
    }

    /// Pair 9. The finale: neither ball can reach its own cup. B's ball slips past the duck pond onto the springboard,
    /// which fires it across B, through the gap and into A's prize booth. A's ball takes the pipe over to B, where the
    /// merry-go-round brakes it and curls it into B's cup. Same, at a pace the merry-go-round can tame.
    static func grandPrize() -> Level {
        var l = Level("Grand Prize", par: [3, 3], hint: "Neither ball can win its own prize.")
        l.setting = "midway"
        l.frame(gaps: [610...700])
        // A: a turnstile leads to the pipe over to B; the prize booth opens only onto the gap.
        l.tee(.a, 50, 115)
        l.block(.a, 0, 250, 54, 265)
        l.block(.a, 82, 250, 200, 265)
        l.tunnel(.a, 75, 313, .b, 30, 398, exitB: 70)
        l.block(.a, 100, 598, 200, 610)
        l.block(.a, 100, 610, 112, 740)
        l.block(.a, 100, 740, 200, 752)
        l.cup(.a, 150, 652)
        // B: one channel through the duck pond to the springboard, which fires across to the gap; the pipe comes up
        // by the merry-go-round.
        l.tee(.b, 100, 115)
        l.water(.b, 0, 300, 120, 370)
        l.water(.b, 135, 300, 200, 370)
        l.kicker(.b, 170, 660, toward: 180, speed: 450)
        l.carousel(.b, 65, 480, radius: 50, rpm: -40)
        l.cup(.b, 112, 580)
        l.solution = Shot(angle: 82.75, power: 0.710, mirrored: false)
        return l
    }
}
