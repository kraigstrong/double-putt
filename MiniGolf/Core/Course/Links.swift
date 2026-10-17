import Foundation

// The Links (course 7): a windswept seaside links in the Bandon Dunes mould, and a putting course. No obstacles: each
// green's shape comes from the fringe, rough, sand and water painted round it, and its contours do the rest. Several
// double aces send one ball through fringe or sand while the other stays on the green. Designed with Tools/solver
// against Tools/levels/BRIEF.md (course 7 targets).
extension Levels {
    /// Pair 1, the warm-up. Two leaning greens: A's leans right, B's leans left, so their aims mirror. B's cup sits
    /// well short of A's, but B's ball has to cross a long fringe apron from its tee green to the main green, and the
    /// fringe takes off just the pace that makes up the difference. Mirror, aimed a little left of A's cup, at A's
    /// pace. Paint the apron green and only a sliver of the double ace is left (the stored shot runs past B's cup).
    static func fescue() -> Level {
        var l = Level("Fescue", par: [2, 2], hint: "Both greens lean. The fringe takes pace off.")
        l.setting = "links"
        l.bandon = true
        l.frame()
        // A: one long green leaning right.
        l.ground(.rough, .a)
        l.green(.a, [(70, 108), (110, 115), (130, 200), (140, 350), (160, 520), (160, 660), (130, 735), (80, 730),
                     (50, 640), (45, 450), (40, 300), (40, 160)])
        l.tilt(.a, downhill: 0, strength: 35)
        l.tee(.a, 60, 125)
        l.cup(.a, 124, 670)
        // B: a tee green and the main green, leaning left, joined by a long fringe apron.
        l.ground(.rough, .b)
        l.paint(.fringe, .b, [(125, 160), (165, 170), (160, 300), (140, 470), (45, 475), (70, 300)], smooth: true)
        l.green(.b, [(125, 108), (160, 112), (168, 140), (158, 170), (125, 172), (112, 145), (115, 118)])
        l.green(.b, [(120, 440), (150, 500), (145, 620), (105, 670), (55, 655), (38, 560), (45, 470), (80, 435)])
        l.tilt(.b, downhill: 180, strength: 50)
        l.tee(.b, 145, 125)
        l.cup(.b, 104, 520)
        l.solution = Shot(angle: 86.25, power: 0.640, mirrored: true)
        return l
    }

    /// Pair 2. Short vs long: A is a short hole whose straight line runs through a round pot bunker in front of the
    /// cup; B is a long haul up a green leaning gently left. Both cups are up and to the right: Same. Putt for the long
    /// one, a touch right of A's cup; A's ball crosses the sand, which eats the extra pace and drops it in. Any softer
    /// and A's ball dies in the sand or stops short. Paint the bunker green and there's no double ace at all.
    static func potBunker() -> Level {
        var l = Level("Pot Bunker", par: [2, 3], hint: "Sand stops a soft putt. A firm one gets through.")
        l.setting = "links"
        l.frame()
        // A: short, with a round pot bunker on the line, in front of the cup.
        l.ground(.rough, .a)
        l.green(.a, [(80, 108), (125, 130), (150, 300), (155, 440), (130, 520), (80, 520), (55, 420), (50, 250),
                     (50, 130)])
        l.paint(.sand, .a, [(108, 336), (138, 366), (108, 396), (78, 366)], smooth: true)
        l.tee(.a, 75, 130)
        l.cup(.a, 120, 455)
        // B: long, leaning gently left.
        l.ground(.rough, .b)
        l.green(.b, [(60, 108), (40, 200), (50, 400), (80, 600), (90, 720), (130, 745), (160, 700), (155, 560),
                     (110, 400), (90, 200), (85, 120)])
        l.tilt(.b, downhill: 180, strength: 20)
        l.tee(.b, 60, 125)
        l.cup(.b, 136, 692)
        l.solution = Shot(angle: 81.00, power: 0.670, mirrored: false)
        return l
    }

    /// Pair 3. Both greens are bowls. B's cup sits near the bottom of its bowl, so B's ball rolls straight in. A's
    /// bowl sits off to the left of and below its cup, so A's ball curls left as it slows: aim right of the cup. The
    /// straight lines alone don't line up; A's curl is what makes Mirror work (take A's bowl away and the Mirror
    /// double ace is gone). Same reads differently: both balls bank off their left fences, firmer (a smaller,
    /// separate double ace).
    static func punchbowl() -> Level {
        var l = Level("Punchbowl", par: [3, 3], hint: "Both greens are bowls. Not every cup sits at the bottom.")
        l.setting = "links"
        l.frame()
        // A: a long green; its bowl sits left of and below the cup, so the cup is on the bowl's bank.
        l.ground(.rough, .a)
        l.green(.a, [(85, 108), (115, 115), (120, 300), (130, 430), (155, 560), (160, 650), (130, 690), (75, 680),
                     (45, 600), (65, 430), (82, 300), (68, 130)])
        l.hollow(.a, 69, 618, radius: 130, strength: 146)
        l.tee(.a, 90, 125)
        l.cup(.a, 131, 655)
        // B: a long green with the cup near the bottom of its bowl.
        l.ground(.rough, .b)
        l.green(.b, [(130, 108), (150, 125), (140, 300), (130, 430), (130, 560), (120, 660), (70, 685), (50, 655),
                     (50, 560), (75, 430), (100, 300), (115, 125)])
        l.hollow(.b, 80, 646, radius: 90, strength: 102)
        l.tee(.b, 140, 125)
        l.cup(.b, 83, 621)
        l.solution = Shot(angle: 83.50, power: 0.630, mirrored: true)
        return l
    }

    /// Pair 4. Both greens bend round gorse, and the fence between them is open beside the lower legs (shared rough,
    /// which also stops banks off it lining up into easy double aces). A doglegs left and leans left; its fringe swells
    /// into a wide apron along the gorse at the corner. The ace starts right of the cup and rides that apron, slowing as
    /// it curls into the upper leg. B bends right and leans right, a little harder, so its ball has to start left of its
    /// cup and stays on the green. The bends look like mirror images, but both balls start uphill of their cups at about
    /// 92°: Same.
    static func gorseLine() -> Level {
        var l = Level("Gorse Line", par: [3, 3], hint: "Hug the gorse line. Let each slope bring its ball round.")
        l.setting = "links"
        l.frame(gaps: [180...440])
        // A: a dogleg left round a line of gorse, leaning left; the fringe swells into an apron at the corner.
        l.ground(.rough, .a)
        l.green(.a, [(98, 105), (138, 105), (140, 300), (148, 460), (150, 575), (136, 645), (90, 660), (45, 648),
                     (34, 610), (38, 545), (62, 515), (104, 495), (114, 430), (112, 300)], apron: [11: 38, 12: 42, 13: 34])
        l.tilt(.a, downhill: 180, strength: 52)
        l.tee(.a, 108, 130)
        l.cup(.a, 68, 598)
        // B: a green bending right and leaning harder toward the bend; the cup sits on the high side.
        l.ground(.rough, .b)
        l.green(.b, [(38, 98), (98, 98), (100, 280), (102, 360), (130, 410), (162, 460), (165, 630), (140, 705),
                     (80, 715), (40, 680), (33, 450), (34, 280)])
        l.tilt(.b, downhill: 0, strength: 58)
        l.tee(.b, 75, 120)
        l.cup(.b, 84, 682)
        l.solution = Shot(angle: 92.00, power: 0.680, mirrored: false)
        return l
    }

    /// Pair 5. A is long: a broad step up, falling toward the tee and a little left, between the tee and the cup. B is
    /// short: it starts on the upper tier and steps down (the bank falls up and to the right), then runs to a cup near the
    /// back with a deep fringe apron behind it, up to the fence. A needs a firm putt to climb, far too firm for B, whose
    /// ball runs past its cup, through the apron to the back fence, and comes back through the apron into the cup. A
    /// goes up-left and B up-right: Mirror. The fence is open beside B's tee, which keeps banks off it from lining up.
    static func twoTiers() -> Level {
        var l = Level("Two Tiers", par: [3, 2], hint: "One has to climb. The other runs long: trust the apron.")
        l.setting = "links"
        l.bandon = true
        l.frame(gaps: [180...380])
        // A: a broad step up to the cup, falling toward the tee and a little left.
        l.ground(.rough, .a)
        l.green(.a, [(88, 100), (145, 100), (150, 300), (142, 520), (125, 675), (78, 702), (37, 655), (42, 400),
                     (72, 220)])
        l.tier(.a, 100, 430, downhill: 245, strength: 200, width: 95)
        l.tee(.a, 124, 110)
        l.cup(.a, 62, 666)
        // B: a step down, then a run to a cup near the back; a fringe apron behind it runs up to the fence.
        l.ground(.rough, .b)
        l.green(.b, [(35, 255), (85, 255), (110, 360), (135, 460), (148, 600), (148, 690), (135, 738), (90, 738),
                     (70, 600), (45, 380)], apron: [6: 38, 7: 38])
        l.tier(.b, 100, 440, downhill: 70, strength: 200, width: 80)
        l.tee(.b, 55, 280)
        l.cup(.b, 121, 712)
        l.solution = Shot(angle: 94.75, power: 0.710, mirrored: true)
        return l
    }

    /// Pair 6. A is a long green running up from the right to a pond along the outer fence, leaning hard into it: start
    /// right of the cup and let the slope bring the ball back down to it (soft putts break into the pond). B is a short
    /// green behind a cross bunker, leaning back toward the tee and left: a firm putt carries through the sand, then
    /// breaks left into the cup. Both lean left, but B's cup sits straight up its green and A's up-left: Mirror.
    static func seaWall() -> Level {
        var l = Level("Sea Wall", par: [3, 2], hint: "Don't feed the pond. Be firm through the bunker.")
        l.setting = "links"
        l.frame()
        // A: a long green running up from the right to a pond along the left, leaning into it.
        l.ground(.rough, .a)
        l.green(.a, [(130, 105), (164, 120), (164, 300), (150, 500), (130, 690), (95, 715), (68, 680), (72, 450),
                     (100, 250)])
        l.paint(.water, .a, [(20, 260), (55, 250), (62, 400), (58, 560), (60, 690), (35, 715), (15, 650), (12, 400)],
                smooth: true)
        l.tilt(.a, downhill: 180, strength: 75)
        l.tee(.a, 150, 130)
        l.cup(.a, 92, 650)
        // B: a short green behind a cross bunker, leaning back toward the tee and left.
        l.ground(.rough, .b)
        l.green(.b, [(70, 285), (140, 285), (160, 450), (155, 650), (120, 700), (60, 690), (40, 500)])
        l.paint(.sand, .b, [(55, 470), (125, 455), (145, 480), (100, 505), (55, 500)], smooth: true)
        l.tilt(.b, downhill: 210, strength: 125)
        l.tee(.b, 110, 315)
        l.cup(.b, 104, 640)
        l.solution = Shot(angle: 92.25, power: 0.650, mirrored: true)
        return l
    }

    /// Pair 7. One double green across the top of both holes, open through the middle wall. Each cup has a hump in
    /// front of it that sheds the straight putt up its own side, so the way in is the crossover: A's ball runs up its
    /// green and across into the far cup, B's ball comes off its fringe apron and across into A's cup, past the
    /// shoulder of A's hump. Mirror; the balls cross without meeting. Pot bunkers catch bank shots and anything long.
    static func fogBank() -> Level {
        var l = Level("Fog Bank", par: [3, 3], hint: "One green, two cups. Any ball can take either.")
        l.setting = "links"
        l.frame(gaps: [380...800])
        l.ground(.rough, nil)
        // B: a long apron of fringe up to the double green.
        l.paint(.fringe, .b, [(60, 105), (150, 105), (168, 250), (165, 400), (140, 470), (40, 470), (35, 300)],
                smooth: true)
        // One green: A's lane runs up into the double green across the gap in the middle wall.
        l.green(nil, [(40, 105), (95, 100), (138, 230), (164, 340), (171, 402), (200, 422), (240, 428), (330, 440),
                      (360, 560), (352, 690), (310, 738), (200, 742), (90, 738), (45, 690), (38, 560), (62, 470),
                      (82, 410), (62, 300), (40, 190)])
        // Pot bunkers: one in the rough left of A's lane, one behind each cup.
        l.paint(.sand, .a, [(0, 170), (25, 172), (42, 200), (48, 250), (44, 300), (30, 330), (0, 335)])
        l.paint(.sand, nil, [(70, 758), (150, 756), (165, 774), (140, 790), (75, 790), (58, 774)], smooth: true)
        l.paint(.sand, nil, [(250, 756), (330, 758), (342, 774), (325, 790), (260, 790), (235, 774)], smooth: true)
        // A hump in front of each cup.
        l.hump(nil, 110, 600, radius: 75, strength: 140)
        l.hump(nil, 310, 612, radius: 55, strength: 160)
        l.tee(.a, 50, 125); l.tee(.b, 106, 184)
        l.cups = [Vec(109, 693), Vec(283, 698)]
        l.solution = Shot(angle: 67.50, power: 0.710, mirrored: true)
        return l
    }

    /// Pair 8. Two saddles, turned opposite ways. A's green is high front and back (two humps just left of the line
    /// of play) and falls away to wet ground at its waist: its ball rides the ridge, which sheds it right, so it has to
    /// start left of the cup. B is high left and right: its ball runs up a fringe apron and through the pass between
    /// the humps on a neck of fringe, which holds it on line and takes the pace off, onto the green. Mirror.
    static func saddle() -> Level {
        var l = Level("Saddle", par: [3, 3], hint: "Both greens are saddles. Ride the fringe on one.")
        l.setting = "links"
        l.frame()
        // A: high front and back, falling away both sides into ponds at the waist.
        l.ground(.rough, .a)
        l.green(.a, [(60, 100), (140, 100), (160, 250), (140, 450), (165, 640), (140, 728), (90, 737), (45, 722),
                     (35, 640), (60, 450), (40, 250)])
        l.hump(.a, 85, 320, radius: 95, strength: 150)
        l.hump(.a, 85, 610, radius: 95, strength: 150)
        l.paint(.water, .a, [(0, 390), (14, 393), (26, 410), (33, 440), (34, 465), (31, 492), (23, 520), (12, 536),
                             (0, 540)])
        l.paint(.water, .a, [(200, 390), (186, 393), (174, 410), (167, 440), (166, 465), (169, 492), (177, 520),
                             (188, 536), (200, 540)])
        // B: high left and right. A fringe apron (the tee is on it) and a neck of fringe through the pass between the
        // humps lead to the green; pot bunkers sit on the humps either side of the neck and behind the green.
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
        l.tee(.a, 120, 125); l.tee(.b, 73, 252)
        l.cup(.a, 87, 708); l.cup(.b, 115, 690)
        l.solution = Shot(angle: 94.25, power: 0.660, mirrored: true)
        return l
    }

    /// Pair 9, the finale. A is the lighthouse: a narrow tower of green leaning right, climbing a slanted tier to the
    /// lantern room; its ball stays on the green and has to start left of the cup. B's ball has to cross a bunker that
    /// runs wall to wall, which takes most of its pace, then the green falls away up-left over a tier to the cup, with
    /// a pond behind. Mirror: one putt firm enough for A's climb and B's sand, soft enough to stop short of the pond.
    static func lighthouse() -> Level {
        var l = Level("Lighthouse", par: [3, 3], hint: "The sand takes the pace off. Then it's all downhill.")
        l.setting = "links"
        l.bandon = true
        l.frame()
        // A: the lighthouse. A narrow tower climbs to the gallery, a tier steps up to the lantern room and the cup;
        // the whole green leans right.
        l.ground(.rough, .a)
        l.green(.a, [(150, 100), (80, 100), (75, 200), (78, 330), (75, 460), (58, 520), (55, 565), (55, 610),
                     (44, 698), (98, 760), (152, 690), (150, 610), (165, 560), (165, 515), (125, 460), (128, 330),
                     (140, 200)])
        l.tier(.a, 100, 575, downhill: 250, strength: 200, width: 55)
        l.tilt(.a, downhill: 0, strength: 40)
        // B: a cross bunker wall to wall, then a tier falling away up-left to a cup above the pond.
        l.ground(.rough, .b)
        l.green(.b, [(140, 105), (50, 105), (35, 300), (40, 500), (35, 690), (80, 735), (150, 730), (165, 560),
                     (155, 300)])
        l.paint(.sand, .b, [(200, 318), (150, 330), (100, 344), (50, 356), (0, 368), (0, 415), (50, 405), (100, 393),
                            (150, 383), (200, 375)])
        l.tier(.b, 100, 540, downhill: 112, strength: 160, width: 45)
        l.paint(.water, .b, [(160, 668), (40, 668), (25, 730), (100, 770), (175, 730)], smooth: true)
        l.tee(.a, 130, 120); l.tee(.b, 50, 125)
        l.cup(.a, 74, 704); l.cup(.b, 96, 624)
        l.solution = Shot(angle: 96.50, power: 0.710, mirrored: true)
        return l
    }
}
