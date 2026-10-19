import Foundation

// The Stadium (course 9): a Florida tournament course, and the last and hardest of the putting courses. Island and
// peninsula greens in water walled with railroad ties, waste bunkers, spectator mounds, and on a few pairs grandstands
// the ball banks off like any mini golf wall. Designed with Tools/solver against Tools/levels/BRIEF.md (course 9
// targets); the pairs run in order of their double-ace odds, with Island Green as the finale.
extension Levels {
    /// Pair 1, the opener. A is a peninsula green: a lane runs up the right from the tee and opens into a round green
    /// with a lake along its left and behind it, and the whole green leans left into the lake (150). Its ball has to
    /// start well right of the cup and curl in; a steep little hollow just below and right of the cup gathers a ball
    /// that arrives on that line. B is a long two-tier green: a bank falls back toward the tee halfway up, so a short
    /// putt rolls back off it, and the upper tier leans gently right into a dish round the cup, with a lake behind.
    /// Same, up and a little right: A's ball starts about 9° right of its cup, B's about 3° left of its. Take A's lean
    /// away and the Same double ace is gone. The water keeps both holes honest: drain it and each hole aces three to
    /// five times as often, off the fences. A burn down the middle swallows banks off the wall between the holes.
    static func firstTee() -> Level {
        var l = Level("First Tee", par: [3, 3], hint: "One green falls toward the lake. The other has a ledge.")
        l.setting = "stadium"
        l.frame()
        // A: a lane up the right opening into a peninsula green, a lake along its left and behind; leans into it.
        l.ground(.rough, .a)
        l.paint(.water, .a, [(0, 330), (30, 340), (42, 420), (40, 560), (40, 700), (60, 760), (120, 768), (200, 772),
                             (200, 800), (0, 800)])
        l.green(.a, [(115, 108), (160, 110), (165, 250), (162, 420), (165, 560), (160, 680), (135, 735), (95, 740),
                     (68, 715), (62, 640), (70, 540), (110, 470), (118, 350), (110, 200)])
        l.tilt(.a, downhill: 180, strength: 150)
        l.hollow(.a, 105, 625, radius: 30, strength: 400)
        l.tee(.a, 140, 125)
        l.cup(.a, 95, 650)
        // B: a long green in two tiers, a pond along its right and a lake behind; the upper tier leans right into a
        // dish round the cup.
        l.ground(.rough, .b)
        l.paint(.water, .b, [(200, 300), (172, 320), (160, 420), (172, 520), (200, 540)], smooth: true)
        l.paint(.water, .b, [(0, 772), (60, 766), (140, 762), (200, 760), (200, 800), (0, 800)])
        l.green(.b, [(40, 108), (90, 108), (110, 250), (125, 400), (135, 520), (150, 640), (135, 720), (90, 735),
                     (50, 700), (40, 560), (45, 400), (38, 250)])
        l.tier(.b, 100, 450, downhill: 270, strength: 300, width: 40)
        l.tilt(.b, downhill: 0, strength: 48)
        l.hollow(.b, 120, 640, radius: 30, strength: 220)
        l.tee(.b, 60, 125)
        l.cup(.b, 120, 640)
        // A burn either side of the wall between the holes.
        l.paint(.water, nil, [(183, 170), (217, 170), (217, 480), (183, 480)])
        l.solution = Shot(angle: 86.25, power: 0.630, mirrored: false)
        return l
    }

    /// Pair 2. Short vs long, round two Florida waste areas. A is a long green leaning hard right (150) toward a big
    /// waste area beside the right of its lane; its ball starts well left of the cup, about 9° off the straight line,
    /// and curls into a steep hollow below and left of the cup (break too much and it finishes in the sand). B is
    /// short: its tee box sits beside a big waste area that sweeps across the front of the green, up its right side
    /// and round behind it. The waste area's front edge runs on a slant, deeper on the right, and B's ball has to
    /// carry through it: the sand eats all the extra pace of a putt firm enough for A, and the green beyond leans
    /// right into a dish round the cup. Both greens lean right, but the balls start out opposite ways: Mirror. Paint
    /// B's waste area green and there's no double ace at all.
    static func pineStraw() -> Level {
        var l = Level("Pine Straw", par: [3, 3], hint: "Sand eats the pace. Hit it firm enough for the long one.")
        l.setting = "stadium"
        l.frame()
        // A: a long green leaning right toward a waste area beside the right of its lane.
        l.ground(.rough, .a)
        l.paint(.sand, .a, [(138, 210), (165, 235), (178, 330), (176, 450), (160, 540), (140, 520), (128, 430), (126, 320)],
                smooth: true)
        l.green(.a, [(40, 108), (95, 108), (110, 250), (120, 400), (150, 520), (165, 640), (150, 725), (100, 740),
                     (60, 700), (45, 560), (40, 400), (35, 250)])
        l.tilt(.a, downhill: 0, strength: 150)
        l.hollow(.a, 110, 655, radius: 30, strength: 350)
        l.tee(.a, 60, 125)
        l.cup(.a, 120, 680)
        // B: a round tee box beside a big waste area that sweeps across the front of the green, up its right and round
        // behind it; the green leans right into a dish round the cup.
        l.ground(.rough, .b)
        l.paint(.sand, .b, [(28, 425), (70, 395), (115, 355), (140, 292), (168, 300), (178, 420), (176, 600), (168, 715),
                            (140, 762), (90, 770), (45, 760), (40, 700), (60, 600), (40, 470)], smooth: true)
        l.green(.b, [(52, 258), (92, 252), (112, 275), (108, 312), (75, 326), (46, 306)])
        l.green(.b, [(48, 448), (105, 442), (135, 475), (142, 600), (130, 690), (90, 722), (48, 708), (34, 640),
                     (34, 520)])
        l.tilt(.b, downhill: 0, strength: 90)
        l.hollow(.b, 119, 650, radius: 30, strength: 180)
        l.tee(.b, 75, 290)
        l.cup(.b, 119, 650)
        l.solution = Shot(angle: 92.50, power: 0.650, mirrored: true)
        return l
    }

    /// Pair 3 introduces the grandstand. B is short, and a pond sits right in front of its cup, with a grandstand
    /// behind the green angled a little toward the left, and the green falls gently back toward the tee. No putt
    /// can get over the pond, so the only way in is off the stand: up the right of the pond, off the stand's front
    /// and back down the slope into a dish round the cup. A is long: its green leans left (150) all the way up to a
    /// cup on the left with a lake behind, and a spectator mound on the right of the lane holds the ball up early,
    /// so its ball starts about 10° right of the cup and curls in. A firm putt for A is far too firm for B, which is
    /// what the stand is for: it soaks up the pace. Same, up and a little right. Take the stand away and B can't be
    /// aced at all.
    static func grandstand() -> Level {
        var l = Level("Grandstand", par: [3, 3], hint: "The pond guards one cup. The grandstand plays like a wall.")
        l.setting = "stadium"
        l.frame()
        // A: a long green leaning left, water either side and behind; a spectator mound on the right of the lane.
        l.ground(.rough, .a)
        l.paint(.water, .a, [(0, 775), (80, 768), (160, 770), (200, 778), (200, 800), (0, 800)])
        l.paint(.water, .a, [(200, 200), (182, 210), (180, 600), (182, 800), (200, 800)])
        l.paint(.water, .a, [(0, 200), (18, 210), (22, 600), (20, 800), (0, 800)])
        l.green(.a, [(160, 108), (100, 108), (70, 250), (40, 420), (35, 600), (50, 720), (100, 740), (145, 715),
                     (160, 600), (165, 420), (165, 250)])
        l.tilt(.a, downhill: 180, strength: 150)
        l.hump(.a, 130, 420, radius: 90, strength: 250)
        l.hollow(.a, 80, 660, radius: 30, strength: 350)
        l.tee(.a, 140, 125)
        l.cup(.a, 70, 680)
        // B: short, water either side and behind; a pond in front of the cup and a grandstand behind the green,
        // which falls gently back toward the tee into a dish round the cup.
        l.ground(.rough, .b)
        l.paint(.water, .b, [(0, 775), (200, 775), (200, 800), (0, 800)])
        l.paint(.water, .b, [(0, 400), (18, 410), (22, 600), (20, 800), (0, 800)])
        l.paint(.water, .b, [(200, 400), (182, 410), (178, 600), (180, 800), (200, 800)])
        l.green(.b, [(70, 270), (140, 270), (165, 450), (166, 600), (165, 700), (120, 735), (60, 735), (35, 690),
                     (35, 520), (45, 380)])
        l.paint(.water, .b, [(50, 520), (82, 546), (114, 520), (82, 494)], smooth: true)
        l.stand(.b, 110, 750, width: 120, depth: 30, facing: 259)
        l.tilt(.b, downhill: 270, strength: 50)
        l.hollow(.b, 72, 625, radius: 30, strength: 300)
        l.tee(.b, 110, 350)
        l.cup(.b, 72, 625)
        l.solution = Shot(angle: 87.50, power: 0.640, mirrored: false)
        return l
    }

    /// Pair 4. A is a long green with two spectator mounds: a big, steep one off its left side and another behind the
    /// cup. The ball starts up the left, about 12° left of the cup; the side mound's flank kicks it right, and the back
    /// mound turns a firm putt back down to the cup. B's green sits up on a plateau behind a false front, a bank too
    /// steep to hold a ball, so a short putt rolls back down to the apron; past it the green leans hard right and the
    /// ball curls into the cup. Both balls are pushed right, so Mirror: A up and a little left, B up and a little
    /// right (Same never double-aces). Flatten the side mound and the double ace is gone; flatten the back mound and
    /// the window shrinks to 3% of power.
    static func gallery() -> Level {
        var l = Level("Gallery", par: [2, 2], hint: "Play off the gallery mounds. Short of the bank rolls back.")
        l.setting = "stadium"
        l.frame()
        // A: a long green with a spectator mound off its left side and another behind the cup.
        l.ground(.rough, .a)
        l.green(.a, [(60, 105), (150, 105), (160, 300), (162, 500), (160, 690), (130, 728), (75, 725), (50, 650),
                     (48, 450), (52, 250)])
        l.hump(.a, 10, 400, radius: 160, strength: 400)
        l.hump(.a, 140, 730, radius: 100, strength: 400)
        l.tee(.a, 80, 125)
        l.cup(.a, 150, 640)
        // B: a fringe apron up to a false front, then a green on a plateau leaning hard right.
        l.ground(.rough, .b)
        l.paint(.fringe, .b, [(70, 105), (130, 105), (140, 250), (130, 420), (70, 420), (60, 250)], smooth: true)
        l.green(.b, [(70, 420), (140, 415), (160, 520), (160, 680), (120, 730), (60, 725), (40, 640), (42, 500)])
        l.tier(.b, 100, 440, downhill: 270, strength: 380, width: 30)
        l.tilt(.b, downhill: 0, strength: 150)
        l.tee(.b, 75, 125)
        l.cup(.b, 145, 480)
        l.solution = Shot(angle: 94.00, power: 0.600, mirrored: true)
        return l
    }

    /// Pair 5. A is a peninsula green: a lane runs up the right side and the green hooks left into a lake that wraps
    /// round its left, its back and the bay below it, right up to the ties. The whole green leans down toward the bay
    /// and back toward the tee (210, 173), and the cup sits in a dish at the tip. Aim straight up the lane, about 13°
    /// right of the cup: the lean hooks the ball onto the peninsula, it climbs past the cup toward the ties and the dish
    /// brings it back in. A little firmer and it's in the lake. Paint the lake green and there are more than twice as
    /// many double aces, including a direct line across the bay (rough instead: half as many again). B is a long, near
    /// straight putt past a spectator mound, with a waste bunker down its left. Mirror.
    static func railroadTies() -> Level {
        var l = Level("Railroad Ties", par: [3, 3], hint: "The peninsula leans to the lake. Play the high side.")
        l.setting = "stadium"
        l.frame()
        // A: a lane up the right to a peninsula green reaching left into the lake; the lake wraps round its left, its
        // back and the bay below it, up to the green's edge. The green leans toward the bay and the tee.
        l.ground(.rough, .a)
        l.green(.a, [(115, 105), (160, 110), (165, 300), (165, 480), (162, 620), (150, 700), (110, 728), (60, 720),
                     (40, 680), (42, 610), (70, 575), (110, 540), (125, 470), (118, 300), (110, 160)])
        l.paint(.water, .a, [(0, 260), (60, 265), (100, 300), (112, 440), (100, 520), (62, 560), (30, 600), (26, 690),
                             (55, 735), (110, 742), (160, 715), (178, 745), (200, 760), (200, 800), (0, 800)], smooth: true)
        l.tilt(.a, downhill: 210, strength: 173)
        l.hollow(.a, 67.7, 674.7, radius: 39.7, strength: 400)
        l.tee(.a, 140, 125)
        l.cup(.a, 62, 671.4)
        // B: a long green with a spectator mound on its right and a waste bunker down its left.
        l.ground(.rough, .b)
        l.green(.b, [(120, 105), (165, 115), (168, 300), (165, 500), (150, 650), (110, 700), (60, 690), (40, 600),
                     (50, 450), (90, 300), (100, 160)])
        l.paint(.sand, .b, [(40, 250), (75, 270), (70, 420), (40, 520), (25, 400)], smooth: true)
        l.hump(.b, 163.6, 391.7, radius: 97, strength: 250)
        l.tee(.b, 150, 125)
        l.cup(.b, 79.7, 670)
        l.solution = Shot(angle: 85.25, power: 0.670, mirrored: true)
        return l
    }

    /// Pair 6. B is the amphitheater: a lane up to a bowl of green with a long grandstand down its left, another
    /// across the back, and a lagoon on its right. The cup sits on the bowl's right bank, a few yards off the lagoon.
    /// A straight putt falls into the bowl; the ace runs up the bowl's left side, banks off the back stand and comes
    /// down across the bank into the cup. Too firm and it carries on into the lagoon. A climbs a long bank (leaning
    /// back toward the tee) to a dish on the upper tier, its ball banking off the wall between the holes on the way.
    /// Mirror: A up and to the right, B up and to the left. Take the back stand away and there's no double ace.
    static func amphitheater() -> Level {
        var l = Level("Amphitheater", par: [2, 2], hint: "The bowl swallows a straight putt. Play off the stands.")
        l.setting = "stadium"
        l.frame()
        // A: a long green leaning back toward the tee, climbing a bank to an upper tier; the cup is in a dish on top.
        l.ground(.rough, .a)
        l.green(.a, [(115, 105), (165, 110), (166, 300), (160, 450), (150, 600), (120, 690), (65, 700), (35, 640),
                     (40, 520), (80, 420), (110, 300), (105, 150)])
        l.tilt(.a, downhill: 270, strength: 80)
        l.tier(.a, 100, 540, downhill: 270, strength: 146, width: 57)
        l.hollow(.a, 75, 668.5, radius: 50, strength: 277)
        l.tee(.a, 152, 125)
        l.cup(.a, 75, 668.5)
        // B: a lane up to a bowl of green, grandstands down its left and across its back, a lagoon on its right.
        l.ground(.rough, .b)
        l.green(.b, [(60, 105), (125, 105), (135, 300), (150, 420), (165, 520), (165, 660), (140, 712), (90, 718),
                     (38, 690), (35, 560), (40, 420), (55, 300)])
        l.hollow(.b, 95, 560, radius: 110, strength: 281)
        l.paint(.water, .b, [(160, 300), (200, 280), (200, 760), (126, 760), (141, 700), (146, 440)])
        l.stand(.b, 18, 520, width: 320, depth: 30, facing: 0)
        l.stand(.b, 90, 748, width: 150, depth: 30, facing: 270)
        l.tee(.b, 121, 224)
        l.cup(.b, 128, 598)
        l.solution = Shot(angle: 74.75, power: 0.800, mirrored: true)
        return l
    }

    /// Pair 7. A creek winds across both holes in a gentle S, under the wall between them (open there, inside the
    /// water), and stops short of each outer fence, so the straight line to either cup is wet: each ball has to go round
    /// the creek's end on its own side. Both balls start up and a little left. A's tee is by its end of the creek: its
    /// ball slips past it up the left, and the green, leaning right, curls it back across above the creek into a dish
    /// round the cup, about 14° right of where it was aimed; a bank behind the cup turns a firm putt back. B's ball
    /// starts from the far right, runs past the other end of the creek, and B's green, leaning left, curls it into a
    /// dish round its cup. Same: the leans curl the balls opposite ways (Mirror never double-aces). Paint the creek green
    /// or rough and the straight lines open: the double ace is five or six times as common.
    static func creek() -> Level {
        var l = Level("Creek", par: [3, 2], hint: "The creek blocks both lines. Go round its ends.")
        l.setting = "stadium"
        // The creek: a ribbon 48 wide along a gentle S-curve through these points, tapering to rounded ends.
        let spine = [Vec(60, 355), Vec(100, 352), Vec(150, 372), Vec(200, 398), Vec(240, 414), Vec(280, 410)]
        let half = 24.0, taper = 38.4
        let ends = [spine[0] * 2 - spine[1]] + spine + [spine[spine.count - 1] * 2 - spine[spine.count - 2]]
        var line: [Vec] = []
        for i in 1..<(ends.count - 2) {
            let p0 = ends[i - 1], p1 = ends[i], p2 = ends[i + 1], p3 = ends[i + 2]
            let steps = max(2, Int(((p2 - p1).length / 4).rounded(.up)))
            for k in 0..<steps {
                let t = Double(k) / Double(steps), t2 = t * t, t3 = t2 * t
                let a = p1 * 2, b = (p2 - p0) * t, c = (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2, d = (p1 * 3 - p0 - p2 * 3 + p3) * t3
                line.append((a + b + c + d) * 0.5)
            }
        }
        line.append(spine[spine.count - 1])
        var run = [0.0]
        for i in 1..<line.count { run.append(run[i - 1] + (line[i] - line[i - 1]).length) }
        var left: [(Double, Double)] = [], right: [(Double, Double)] = []
        for i in line.indices {
            let along = (line[min(i + 1, line.count - 1)] - line[max(i - 1, 0)]).normalized
            let normal = Vec(-along.y, along.x)
            let fromEnd = min(run[i], run[run.count - 1] - run[i])
            let h = fromEnd >= taper ? half : half * (1 - (taper - fromEnd) * (taper - fromEnd) / (taper * taper)).squareRoot()
            let p = line[i] + normal * h, q = line[i] - normal * h
            left.append((p.x, p.y)); right.append((q.x, q.y))
        }
        // The wall between the holes is open where the creek crosses it (wet from y 371.5 to 424.5 on the wall's
        // line), so its rounded ends stop at the banks; a ball has to clear an end by its own radius to get through,
        // which keeps it in the water.
        l.frame(gaps: [367.5...428.5])
        l.ground(.rough, nil)
        // A long green in each hole, then the creek across both.
        l.green(.a, [(60, 105), (150, 105), (166, 250), (166, 500), (164, 690), (130, 735), (60, 735), (36, 650),
                     (34, 400), (40, 200)])
        l.green(.b, [(50, 105), (140, 105), (160, 200), (166, 400), (166, 650), (140, 735), (70, 735), (36, 690),
                     (31, 520), (34, 250)])
        l.paint(.water, nil, left + right.reversed().dropFirst().dropLast(), smooth: true)
        // A leans right, with a dish round the cup and a bank behind it.
        l.tilt(.a, downhill: 0, strength: 130)
        l.hollow(.a, 130, 580, radius: 40, strength: 62.5)
        l.tier(.a, 136.95, 619.39, downhill: 260, strength: 350, width: 40)
        l.tee(.a, 72.5, 125)
        l.cup(.a, 130, 580)
        // B leans left, with a dish round the cup.
        l.tilt(.b, downhill: 180, strength: 135)
        l.hollow(.b, 45, 527.5, radius: 25, strength: 150)
        l.tee(.b, 147.5, 125)
        l.cup(.b, 45, 527.5)
        l.solution = Shot(angle: 96.75, power: 0.550, mirrored: false)
        return l
    }

    /// Pair 8. Short against long. B is a short, two-tier green with a false front: a bank across it too steep to hold
    /// a ball (400 against the green's 240), with the cup in a dish just over the crest. The whole green leans left
    /// (142), so B's ball starts about 13° right of the cup, runs up the right side and has to reach the crest slowly:
    /// too soft and the bank rolls it back, too firm and it runs through the dish. A is a long, slim green bending
    /// right, with a pond off its left side, a steep spectator mound in the middle and a curved bunker behind the cup.
    /// The ace rides the mound's right shoulder, which throws off any putt that isn't on line. The putt that crests B's
    /// bank slowly is just firm enough to reach A's cup, so without the false front there is no double ace. The pond
    /// swallows banks off the fence beside it, and the bunker stops putts that would come back off the back fence.
    /// Same, up and a little right.
    static func palmRow() -> Level {
        var l = Level("Palm Row", par: [3, 2], hint: "Come up short and the bank sends it back. Mind the mound.")
        l.setting = "stadium"
        l.frame()
        // A: a long, slim green bending right, a pond off its left side, a steep spectator mound in the middle and a
        // curved bunker behind the cup.
        l.ground(.rough, .a)
        l.green(.a, [(60, 105), (110, 105), (125, 250), (150, 430), (165, 600), (150, 700), (115, 728), (80, 715),
                     (70, 620), (55, 430), (45, 250)])
        l.paint(.water, .a, [(38, 215), (56, 240), (62, 300), (58, 360), (64, 410), (50, 460), (32, 476), (24, 440),
                             (22, 380), (28, 300), (30, 245)], smooth: true)
        l.paint(.sand, .a, [(85, 742), (125, 744), (156, 722), (170, 690), (177, 708), (166, 746), (130, 768), (88, 762)],
                smooth: true)
        l.tilt(.a, downhill: 70, strength: 65.4)
        l.hump(.a, 91.27, 432.83, radius: 80, strength: 357.89)
        l.tee(.a, 70, 125)
        l.cup(.a, 137.23, 674.66)
        // B: a short green, narrow below and round on top, with a false front across it and the cup in a dish just
        // over the crest; the whole green leans left. A waste area below it and a pot bunker off its left.
        l.ground(.rough, .b)
        l.paint(.sand, .b, [(35, 117), (90, 105), (150, 113), (172, 140), (158, 173), (115, 165), (70, 177), (38, 155)],
                smooth: true)
        l.green(.b, [(112, 205), (160, 213), (168, 360), (168, 560), (165, 675), (150, 730), (110, 737), (60, 730),
                     (35, 700), (35, 620), (85, 520), (93, 360), (100, 255)])
        l.paint(.sand, .b, [(52, 440), (72, 458), (66, 488), (46, 480), (42, 454)], smooth: true)
        l.tilt(.b, downhill: 180, strength: 141.55)
        l.tier(.b, 100, 590.41, downhill: 270, strength: 400, width: 54.58)
        l.hollow(.b, 86.84, 626.1, radius: 42.71, strength: 387.63)
        l.tee(.b, 140.8, 230)
        l.cup(.b, 80.84, 626.1)
        l.solution = Shot(angle: 85.50, power: 0.550, mirrored: false)
        return l
    }

    /// Pair 9, the finale. B is the island green: a lake right across the hole, a wide walkway out to the island, and
    /// a grandstand at the back right of it, angled toward the cup on the island's far left. The island falls gently
    /// toward the walkway. The ball runs up the walkway and across the island, banks off the stand and comes back
    /// across to the cup: it starts about 17° right of the cup. A is a long uphill green leaning hard right, so its
    /// ball starts left of the cup and curls in. Mirror: A up and a little left, B up and a little right (Same never
    /// double-aces). Take the stand away and the double ace is gone.
    static func islandGreen() -> Level {
        var l = Level("Island Green", par: [3, 3], hint: "Stay on the walkway. The grandstand is in play.")
        l.setting = "stadium"
        l.frame()
        // A: a long green, uphill and leaning right.
        l.ground(.rough, .a)
        l.green(.a, [(45, 100), (155, 100), (166, 200), (166, 400), (166, 600), (160, 700), (130, 740), (70, 740),
                     (40, 700), (34, 600), (34, 400), (34, 200)])
        l.tilt(.a, downhill: 310, strength: 210)
        l.tee(.a, 80, 125)
        l.cup(.a, 103, 695)
        // B: the island green in a lake, a walkway out to it from the tee, and a grandstand behind it.
        l.ground(.rough, .b)
        l.green(.b, [(70, 105), (150, 105), (150, 170), (70, 170)], smooth: false)
        l.paint(.water, .b, [(6, 320), (194, 320), (194, 630), (6, 630)])
        l.green(.b, [(99, 165), (149, 165), (175, 380), (125, 380)], smooth: false, fringe: 0)
        l.green(.b, [(45, 380), (110, 360), (160, 380), (168, 460), (150, 550), (90, 565), (40, 540), (32, 460)])
        l.stand(.b, 163, 543, width: 60, depth: 26, facing: 243)
        l.tilt(.b, downhill: 295, strength: 70)
        l.tee(.b, 125, 125)
        l.cup(.b, 51, 435)
        l.solution = Shot(angle: 94.00, power: 0.780, mirrored: true)
        return l
    }
}
