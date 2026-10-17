import Foundation

// The Links (course 7): a windswept seaside links in the Bandon Dunes mould, and a putting course. No obstacles: each
// green's shape comes from the fringe, rough, sand and water painted round it, and its contours do the rest. Several
// double aces send one ball through fringe or sand while the other stays on the green, and a few greens have banks
// too steep to hold a ball, so a short putt rolls back. Designed with Tools/solver against Tools/levels/BRIEF.md
// (course 7 targets).
extension Levels {
    /// Pair 1, the warm-up. Two leaning greens read two ways. A's long green leans hard right (170), so its ball has
    /// to start well left of the cup, about 11° off the straight line, and curl in; a small, steep hollow just below
    /// and left of the cup gathers a ball that arrives on that line. B's ball rolls off a tee green across a long
    /// fringe apron and up a main green that climbs toward the cup (it falls back toward the tee), into a little dip
    /// round the cup: a straight putt whose pace the fringe and the climb decide. Same, up and a little left. Paint
    /// the apron green and the double ace is gone; take A's lean away and the Same double ace is gone too.
    static func fescue() -> Level {
        var l = Level("Fescue", par: [2, 2], hint: "One green breaks hard. The other climbs through fringe.")
        l.setting = "links"
        l.bandon = true
        l.frame()
        // A: one long green leaning hard right; a little hollow just below and left of the cup.
        l.ground(.rough, .a)
        l.green(.a, [(55, 108), (85, 115), (105, 250), (130, 420), (160, 580), (165, 680), (140, 740), (90, 735),
                     (50, 640), (35, 470), (35, 300), (35, 150)])
        l.tilt(.a, downhill: 0, strength: 170)
        l.hollow(.a, 106, 695, radius: 29, strength: 400)
        l.tee(.a, 75, 125)
        l.cup(.a, 118, 722)
        // B: a tee green and the main green, which climbs toward the cup, joined by a long fringe apron.
        l.ground(.rough, .b)
        l.paint(.fringe, .b, [(125, 160), (168, 175), (165, 320), (150, 460), (70, 460), (95, 320)], smooth: true)
        l.green(.b, [(125, 108), (160, 112), (168, 140), (158, 170), (125, 172), (112, 145), (115, 118)])
        l.green(.b, [(110, 430), (150, 470), (160, 570), (150, 680), (110, 730), (55, 725), (38, 640), (45, 520), (75, 440)])
        l.tilt(.b, downhill: 270, strength: 120)
        l.hollow(.b, 101, 487, radius: 30, strength: 265)
        l.tee(.b, 145, 125)
        l.cup(.b, 101, 482)
        l.solution = Shot(angle: 96.75, power: 0.670, mirrored: false)
        return l
    }

    /// Pair 2. Short vs long: A is a short hole whose straight line runs through a round pot bunker in front of the
    /// cup; B is a long haul up a green leaning hard left (150), so B's ball starts out well right, about 8° off the
    /// straight line, and curls back; a small hollow below and right of B's cup catches it on that line. Same, up and
    /// to the right, firm enough for the long one: A's ball crosses the sand, which eats the extra pace and drops it in.
    /// Any softer and A's ball dies in the sand or stops short. Paint the bunker green and there's no double ace at all.
    static func potBunker() -> Level {
        var l = Level("Pot Bunker", par: [2, 2], hint: "A firm putt crosses sand. The long green leans hard.")
        l.setting = "links"
        l.frame()
        // A: short, with a round pot bunker on the line, in front of the cup.
        l.ground(.rough, .a)
        l.green(.a, [(80, 108), (125, 130), (150, 300), (155, 440), (130, 520), (80, 520), (55, 420), (50, 250),
                     (50, 130)])
        l.paint(.sand, .a, [(108, 336), (138, 366), (108, 396), (78, 366)], smooth: true)
        l.tee(.a, 75, 130)
        l.cup(.a, 120, 455)
        // B: long, leaning hard left, the cup in a little hollow.
        l.ground(.rough, .b)
        l.green(.b, [(110, 108), (140, 120), (155, 300), (160, 500), (150, 650), (130, 735), (85, 745), (55, 700),
                     (50, 560), (65, 400), (80, 250), (85, 125)])
        l.tilt(.b, downhill: 180, strength: 150)
        l.tee(.b, 110, 125)
        l.cup(.b, 108, 708)
        l.hollow(.b, 125, 669, radius: 54, strength: 270)
        l.solution = Shot(angle: 81.75, power: 0.680, mirrored: false)
        return l
    }

    /// Pair 3. Both greens are bowls. A's green leans right (95), toward a burn down the middle, and a big steep bowl
    /// (365) fills its top; the cup sits up the bowl's far bank, off the bottom. The ball has to start about 8° left
    /// of the cup and curl right with the lean into the bowl, crossing it to one side, then climb the bank, whose
    /// pull takes the pace off: without the bowl the same putt runs 40 units past. Come up short and the bank (over
    /// 240, more than the green holds) sends it back down into the bowl. B's cup is the low point of a shallow dish
    /// on a gentle lean: a near-straight putt. Same, up and a little left. The burn swallows banks off the middle
    /// wall, which would otherwise make both holes easy to ace.
    static func punchbowl() -> Level {
        var l = Level("Punchbowl", par: [3, 3], hint: "Two bowls. One cup sits up the bank: short putts roll back.")
        l.setting = "links"
        l.frame()
        // A: a lane up to a round green leaning right, a big steep bowl at its top; the cup is up its far bank.
        l.ground(.rough, .a)
        l.green(.a, [(47, 108), (103, 108), (122, 250), (156, 450), (164, 520), (164, 620), (150, 690), (100, 710),
                     (50, 690), (36, 620), (36, 520), (46, 450), (54, 250)])
        l.tilt(.a, downhill: 0, strength: 94.5)
        l.hollow(.a, 96, 553.5, radius: 86, strength: 363.5)
        l.tee(.a, 64.5, 125)
        l.cup(.a, 97.94, 627.69)
        // B: a long green on a gentle lean, a shallow dish whose low point is the cup.
        l.ground(.rough, .b)
        l.green(.b, [(112, 108), (164, 108), (162, 250), (164, 400), (164, 644), (145, 704), (100, 719), (55, 704),
                     (36, 644), (36, 400), (80, 250)])
        l.tilt(.b, downhill: 0, strength: 40)
        l.hollow(.b, 110.5, 604, radius: 45, strength: 70)
        l.tee(.b, 140, 125)
        l.cup(.b, 121, 604)
        // A burn down the middle, either side of the wall between the holes.
        l.paint(.water, nil, [(182, 180), (218, 180), (218, 480), (182, 480)])
        l.solution = Shot(angle: 94.25, power: 0.610, mirrored: false)
        return l
    }

    /// Pair 4. Both greens bend round gorse, and the fence between them is open beside the lower legs (shared rough,
    /// which also stops banks off it lining up into easy double aces). A doglegs left and leans left; its fringe swells
    /// into a wide apron along the gorse at the corner. The ace starts right of the cup and rides that apron, slowing as
    /// it curls into the upper leg. B bends right and leans right, a little harder, so its ball has to start left of its
    /// cup and stays on the green. The bends look like mirror images, but both balls start uphill of their cups at about
    /// 92°: Same.
    static func gorseLine() -> Level {
        var l = Level("Gorse Line", par: [2, 2], hint: "The dunes throw the ball sideways. Hug the gorse line.")
        l.setting = "links"
        l.frame(gaps: [180...440])
        // A: a dogleg left round a line of gorse; a steep dune right of the lower leg throws the ball left along the
        // gorse, where the fringe swells into an apron. The cup sits in a shallow dish.
        l.ground(.rough, .a)
        l.green(.a, [(95, 105), (150, 105), (162, 300), (160, 460), (154, 600), (136, 662), (90, 682), (45, 668),
                     (34, 622), (38, 560), (62, 525), (100, 505), (110, 440), (106, 300)], apron: [11: 38, 12: 42, 13: 34])
        l.hump(.a, 204, 280, radius: 190, strength: 370)
        l.hollow(.a, 70, 623, radius: 30, strength: 230)
        l.tee(.a, 118, 125)
        l.cup(.a, 70, 623)
        // B: a green bending right; a steep dune left of the lower leg throws the ball right.
        l.ground(.rough, .b)
        l.green(.b, [(38, 98), (98, 98), (100, 280), (102, 360), (130, 410), (162, 460), (165, 630), (140, 705),
                     (80, 715), (40, 680), (33, 450), (34, 280)])
        l.hump(.b, 14, 245, radius: 125, strength: 240)
        l.tee(.b, 45, 120)
        l.cup(.b, 123, 661)
        l.solution = Shot(angle: 86.00, power: 0.630, mirrored: false)
        return l
    }

    /// Pair 5. A climbs: the green leans back toward the tee, a big dune on its left throws the ball right, and a false
    /// front (a bank too steep to hold a ball) guards the upper tier, so a putt that doesn't crest it rolls back down.
    /// The ace starts about 10° left of the cup and lets the dune bring it round into the dish. B is short: it starts on
    /// the upper tier and steps down (the bank falls up and to the right), then runs to a cup near the back with a deep
    /// fringe apron behind it, up to the fence. A needs a firm putt to climb, far too firm for B, whose ball runs past
    /// its cup, through the apron to the back fence, and comes back through the apron into the cup. A goes up-left and B
    /// up-right: Mirror. The fence is open beside B's tee, which keeps banks off it from lining up.
    static func twoTiers() -> Level {
        var l = Level("Two Tiers", par: [2, 2], hint: "One has to climb. The other runs long: trust the apron.")
        l.setting = "links"
        l.bandon = true
        l.frame(gaps: [180...380])
        // A: an uphill green with a dune on its left, then a false front up to the cup: a steep bank facing the tee
        // that rolls a short putt back down. The cup sits in a shallow dish on the upper tier.
        l.ground(.rough, .a)
        l.green(.a, [(40, 100), (100, 100), (125, 250), (155, 420), (162, 600), (140, 680), (95, 690), (70, 600), (55, 420),
                     (35, 250)])
        l.tilt(.a, downhill: 270, strength: 110)
        l.hump(.a, -4, 315, radius: 205, strength: 400)
        l.tier(.a, 100, 450, downhill: 270, strength: 310, width: 45)
        l.hollow(.a, 131, 577, radius: 27, strength: 230)
        l.tee(.a, 78, 115)
        l.cup(.a, 131, 577)
        // B: a long steep bank falling up and to the right, then a run to a cup near the back; a fringe apron behind it
        // runs up to the fence.
        l.ground(.rough, .b)
        l.green(.b, [(35, 255), (85, 255), (110, 360), (135, 460), (148, 600), (148, 690), (135, 738), (90, 738),
                     (70, 600), (45, 380)], apron: [6: 38, 7: 38])
        l.tier(.b, 100, 455, downhill: 65, strength: 380, width: 95)
        l.tee(.b, 60, 280)
        l.cup(.b, 114, 710)
        l.solution = Shot(angle: 93.25, power: 0.680, mirrored: true)
        return l
    }

    /// Pair 6. A is a long green running up from the right to a pond along the outer fence, leaning hard into it: start
    /// right of the cup, ride the fringe up the high side, and let the slope bring the ball back down to the cup (soft
    /// putts break into the pond). B is a short green behind a cross bunker, leaning back toward the tee and left: a
    /// firm putt carries through the sand, then breaks left into the cup. Both lean left, so both balls start right of
    /// their cups, A's by about 11° and B's by about 5°: Same.
    static func seaWall() -> Level {
        var l = Level("Sea Wall", par: [3, 2], hint: "Don't feed the pond. Be firm through the bunker.")
        l.setting = "links"
        l.frame()
        // A: a long green running up from the right to a pond along the left, leaning hard into it; the cup sits in a
        // shallow dish.
        l.ground(.rough, .a)
        l.green(.a, [(130, 105), (164, 120), (164, 300), (150, 500), (130, 690), (95, 715), (68, 680), (72, 450),
                     (100, 250)])
        l.paint(.water, .a, [(20, 260), (55, 250), (62, 400), (58, 560), (60, 690), (35, 715), (15, 650), (12, 400)],
                smooth: true)
        l.tilt(.a, downhill: 190, strength: 170)
        l.hollow(.a, 96, 640, radius: 35, strength: 240)
        l.tee(.a, 157, 130)
        l.cup(.a, 96, 640)
        // B: a short green behind a cross bunker, leaning hard back toward the tee and left; the cup sits in a steep
        // little dish.
        l.ground(.rough, .b)
        l.green(.b, [(70, 285), (140, 285), (160, 450), (155, 650), (120, 700), (60, 690), (40, 500)])
        l.paint(.sand, .b, [(55, 470), (125, 455), (145, 480), (100, 505), (55, 500)], smooth: true)
        l.tilt(.b, downhill: 220, strength: 210)
        l.hollow(.b, 112, 615, radius: 29, strength: 260)
        l.tee(.b, 115, 316)
        l.cup(.b, 112, 615)
        l.solution = Shot(angle: 85.75, power: 0.660, mirrored: false)
        return l
    }

    /// Pair 7. One double green across the top of both holes, open through the middle wall, with the two cups close
    /// together near its middle. Each hole leans in toward the middle (A's right at 146.5, B's left at 102), and a
    /// big steep hump (380) stands on the outside of each lane where it opens onto the double green. A putt up either
    /// lane rides the inner flank of its hump, which sheds it in across the middle; the lean keeps it curling, so each
    /// ball crosses into the other hole's cup. B's cup sits in a dish that gathers A's ball as it arrives. Same: both
    /// start up and a little left, A's ball about 18° left of the cup it drops in, B's about 12° right of its; B's
    /// ball goes through first, so they cross without meeting. A pot bunker on the inside of A's lane catches the
    /// straighter line across, and a burn either side of the wall between the tee lanes swallows banks off it.
    static func fogBank() -> Level {
        var l = Level("Fog Bank", par: [2, 2], hint: "One green, two cups. Any ball can take either.")
        l.setting = "links"
        l.frame(gaps: [380...800])
        l.ground(.rough, nil)
        // One green: a lane up from each tee into a double green across the top, open through the middle wall.
        l.green(nil, [(42, 125), (60, 108), (135, 108), (152, 125), (158, 250), (160, 350), (182, 420), (218, 420),
                      (240, 350), (242, 250), (248, 125), (265, 108), (340, 108), (358, 125), (360, 300), (360, 560),
                      (352, 690), (310, 740), (200, 745), (90, 740), (48, 690), (40, 560), (40, 300)])
        // A pot bunker on the inside of A's lane, where it opens onto the double green.
        l.paint(.sand, nil, [(168, 387.5), (157.16, 413.66), (131, 424.5), (104.84, 413.66), (94, 387.5), (104.84, 361.34), (131, 350.5), (157.16, 361.34)],
                smooth: true)
        // Each hole leans in toward the middle; a steep hump on the outside of each lane sheds its ball across.
        l.tilt(.a, downhill: 0, strength: 146.5)
        l.tilt(.b, downhill: 180, strength: 102)
        l.hump(nil, 60, 439, radius: 144, strength: 380)
        l.hump(nil, 340, 440, radius: 144, strength: 380)
        // A dish round B's cup gathers A's ball.
        l.hollow(nil, 226.5, 663, radius: 53.5, strength: 237.5)
        l.tee(.a, 90, 125); l.tee(.b, 111.5, 159.5)
        l.cups = [Vec(169, 636), Vec(226.5, 663)]
        // A burn either side of the wall between the tee lanes.
        l.paint(.water, nil, [(184, 140), (216, 140), (216, 370), (184, 370)])
        l.solution = Shot(angle: 94.25, power: 0.600, mirrored: false)
        return l
    }

    /// Pair 8. Two saddles, turned opposite ways. A is high front and back (two humps just left of the line) and
    /// falls away to wet ground at its waist; the cup sits in a dish in the waist, with the back hump behind it, and
    /// the whole green leans right. Its ball starts well left of the cup, curls back right and runs past it, and the
    /// back hump (too steep to hold a ball) rolls it back down into the cup. B is high left and right: its ball leaves
    /// a fringe apron and skims the neck of fringe through the pass between the humps, which holds its line and takes
    /// the pace off, then the green beyond leans right and curls it into a dish round the cup. Same: both balls start
    /// up and to the left, B's a long way left of its cup.
    static func saddle() -> Level {
        var l = Level("Saddle", par: [2, 2], hint: "Both greens are saddles. Ride the fringe on one.")
        l.setting = "links"
        l.frame()
        // A: high front and back (two humps just left of the line), falling away to wet ground at its waist; the
        // whole green leans right, and the cup sits in a dish in the waist with the back hump behind it.
        l.ground(.rough, .a)
        l.green(.a, [(60, 100), (140, 100), (160, 250), (140, 450), (165, 640), (140, 728), (90, 737), (45, 722),
                     (35, 640), (60, 450), (40, 250)])
        l.hump(.a, 85, 320, radius: 95, strength: 150)
        l.hump(.a, 85, 610, radius: 95, strength: 300)
        l.paint(.water, .a, [(0, 340), (14, 344), (26, 367), (33, 407), (34, 440), (31, 476), (23, 513), (12, 535),
                             (0, 540)])
        l.paint(.water, .a, [(200, 340), (186, 344), (174, 367), (167, 407), (166, 440), (169, 476), (177, 513),
                             (188, 535), (200, 540)])
        l.tilt(.a, downhill: 0, strength: 140)
        l.hollow(.a, 95, 490, radius: 60, strength: 300)
        // B: high left and right. A fringe apron (the tee is on it) and a neck of fringe through the pass between the
        // humps lead to the green, which leans right into a dish round the cup; pot bunkers sit on the humps either
        // side of the neck and behind the green.
        l.ground(.rough, .b)
        l.paint(.fringe, .b, [(85, 320), (128, 330), (125, 400), (130, 480), (85, 472), (78, 400)], smooth: true)
        l.paint(.fringe, .b, [(40, 110), (100, 105), (130, 200), (118, 325), (78, 320), (40, 220)], smooth: true,
                pad: 14)
        l.green(.b, [(90, 470), (140, 470), (166, 600), (160, 688), (128, 718), (85, 712), (78, 600)])
        l.hump(.b, 45, 400, radius: 80, strength: 150)
        l.hump(.b, 160, 400, radius: 80, strength: 150)
        l.paint(.sand, .b, [(0, 345), (30, 346), (52, 352), (64, 372), (68, 400), (64, 428), (54, 450), (30, 459),
                            (0, 460)])
        l.paint(.sand, .b, [(200, 345), (170, 346), (150, 352), (139, 372), (136, 400), (140, 428), (150, 450),
                            (170, 459), (200, 460)])
        l.paint(.sand, .b, [(70, 748), (130, 740), (165, 760), (150, 790), (80, 792), (55, 772)], smooth: true)
        l.tilt(.b, downhill: 0, strength: 120)
        l.hollow(.b, 130, 560, radius: 60, strength: 300)
        l.tee(.a, 120, 125); l.tee(.b, 105, 252)
        l.cup(.a, 95, 490); l.cup(.b, 130, 560)
        l.solution = Shot(angle: 102.25, power: 0.520, mirrored: false)
        return l
    }

    /// Pair 9, the finale. A is the lighthouse: a narrow tower of green with the sea either side, leaning left all
    /// the way up. A false front climbs into the lantern room, a deep dish round the cup: come up short and the ball
    /// rolls back down off the lip. Its ball starts right of the cup and the lean brings it back. B's ball crosses a
    /// bunker that runs wall to wall, which takes most of its pace, then the green leans away to the right and the
    /// slow ball breaks hard into a dish round the cup: it starts far left of the cup. Mirror.
    static func lighthouse() -> Level {
        var l = Level("Lighthouse", par: [3, 2], hint: "Come up short and it rolls back. Sand takes the pace off.")
        l.setting = "links"
        l.bandon = true
        l.frame()
        // A: the lighthouse, a narrow tower of green with the sea either side; the ground leans left across it, a
        // false front climbs to the lantern room, and the cup sits in a deep dish there.
        l.ground(.rough, .a)
        l.green(.a, [(60, 100), (140, 100), (140, 300), (140, 520), (165, 560), (165, 680), (135, 735), (65, 735),
                     (35, 680), (35, 560), (60, 520), (60, 300)])
        l.paint(.water, .a, [(0, 140), (24, 150), (36, 210), (36, 460), (24, 520), (0, 530)], smooth: true)
        l.paint(.water, .a, [(200, 140), (176, 150), (164, 210), (164, 460), (176, 520), (200, 530)], smooth: true)
        l.tilt(.a, downhill: 180, strength: 120)
        l.tier(.a, 100, 550, downhill: 270, strength: 400, width: 40)
        l.hollow(.a, 101, 600, radius: 55, strength: 340)
        // B: a cross bunker wall to wall; past it the green leans away to the right, into a dish round the cup.
        l.ground(.rough, .b)
        l.green(.b, [(140, 105), (60, 105), (40, 300), (40, 500), (35, 680), (80, 735), (150, 730), (165, 560),
                     (160, 300)])
        l.paint(.sand, .b, [(0, 280), (200, 280), (200, 330), (0, 330)])
        l.tilt(.b, downhill: 20, strength: 130)
        l.hollow(.b, 120, 502, radius: 60, strength: 300)
        l.tee(.a, 100, 125); l.tee(.b, 55, 125)
        l.cup(.a, 101, 600); l.cup(.b, 120, 502)
        l.solution = Shot(angle: 83.00, power: 0.610, mirrored: true)
        return l
    }
}
