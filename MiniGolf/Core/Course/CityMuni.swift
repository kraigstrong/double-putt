import Foundation

// City Muni (course 8): an everyday city course, and a putting course like The Links. Greens shaped by fringe,
// rough, sand and water, with steep contours to read, and black cart paths that run faster than the green and wind
// between them. Every double ace needs one ball to ride a path: steered round a bend by the slope, two mounds or a
// hollow, or banked off the chain-link fence. Designed with Tools/solver against Tools/levels/BRIEF.md (course 8
// targets).
extension Levels {
    /// Pair 1, the warm-up. A's tee box sits at the bottom left, and a cart path bows out to the left and sweeps up
    /// and round to the right, past a bunker, to a green at the top right. The whole side leans hard right (170) and
    /// the path is laid along the curve that lean puts on a putt: aim up the path, about 14° left of the cup, and the
    /// slope carries the ball round the bend and onto the green, where a big, steep bowl gathers it into the cup. Off
    /// the path it dies in the rough. B is a long, thin green that climbs to its cup, with a bank just behind the cup
    /// that turns a firm putt back: a straight putt whose pace the climb decides. Same, up and a little left. Paint the
    /// path rough or green, or take the lean away, and there's no double ace.
    static func clubhouse() -> Level {
        var l = Level("Clubhouse", par: [3, 2], hint: "The path bends with the slope. The other green climbs.")
        l.setting = "muni"
        l.frame()
        // A: a tee box at the bottom left; a cart path curving up and right with the lean to a green at the top right.
        l.ground(.rough, .a)
        l.green(.a, [(42, 112), (82, 112), (90, 133), (80, 152), (45, 152), (36, 133)])
        l.cartPath(.a, [(60, 150), (44, 260), (39, 370), (46, 460), (58, 525), (72, 575)], width: 26)
        l.green(.a, [(95, 545), (150, 560), (162, 640), (150, 720), (110, 742), (72, 722), (66, 650), (76, 575)])
        l.paint(.sand, .a, [(130, 330), (162, 345), (168, 420), (150, 460), (128, 430), (122, 370)], smooth: true)
        l.tilt(.a, downhill: 0, strength: 170)
        l.hollow(.a, 103.02, 700, radius: 40, strength: 375)
        l.tee(.a, 60, 132)
        l.cup(.a, 110, 700)
        // B: a long, thin green climbing to the cup, with a bank just behind it.
        l.ground(.rough, .b)
        l.green(.b, [(85, 108), (130, 110), (150, 220), (148, 350), (135, 460), (100, 500), (55, 495), (38, 420), (42, 300),
                     (60, 200)])
        l.tilt(.b, downhill: 280, strength: 80)
        l.hollow(.b, 59.57, 432.43, radius: 12, strength: 150)
        l.tier(.b, 60, 470, downhill: 270, strength: 250, width: 15)
        l.tee(.b, 110, 125)
        l.cup(.b, 60, 430)
        l.solution = Shot(angle: 99.25, power: 0.550, mirrored: false)
        return l
    }

    /// Pair 2. B's cart path winds up from the tee box between two grassy mounds, the first on its left and the second
    /// on its right, so it bends right and then back left; each mound sheds the ball the way the path goes, and it
    /// rolls off the end onto the top green and into a big bowl round the cup. Off the path it dies in the rough. A is
    /// a long green leaning hard down and to the left (180): its ball starts about 8° right of the cup and curls back
    /// into a dish. Mirror: A up and a little right, B up and a little left along the path. Paint the path rough and
    /// there's no double ace; paint it green and it drops to 0.010% (a 0.75° window); flatten the mounds and it drops to
    /// 0.008% (a 2% power window).
    static func cartPath() -> Level {
        var l = Level("Cart Path", par: [2, 2], hint: "The path winds between two mounds. Ride it.")
        l.setting = "muni"
        l.frame()
        // A: a long green leaning down and to the left; the cup in a dish.
        l.ground(.rough, .a)
        l.green(.a, [(70, 108), (125, 108), (150, 220), (160, 460), (150, 580), (110, 620), (60, 610), (40, 530), (45, 300),
                     (55, 200)])
        l.tilt(.a, downhill: 210, strength: 180)
        l.hollow(.a, 87.71, 554.45, radius: 45, strength: 350)
        l.tee(.a, 110, 125)
        l.cup(.a, 80, 550)
        // B: a tee box, then a cart path winding up between two mounds to a green at the top, the cup in a bowl.
        l.ground(.rough, .b)
        l.green(.b, [(80, 112), (120, 112), (128, 135), (118, 152), (82, 152), (72, 135)])
        l.cartPath(.b, [(100, 150), (96, 260), (110, 370), (128, 450), (133, 510), (124, 568)], width: 28)
        l.green(.b, [(60, 590), (120, 585), (155, 640), (150, 715), (105, 742), (55, 735), (38, 680), (42, 620)])
        l.hump(.b, 10, 300, radius: 170, strength: 350)
        l.hump(.b, 190, 500, radius: 170, strength: 350)
        l.hollow(.b, 90, 620, radius: 60, strength: 400)
        l.tee(.b, 100, 132)
        l.cup(.b, 90, 620)
        l.solution = Shot(angle: 86.50, power: 0.630, mirrored: true)
        return l
    }

    /// Pair 3. A's cart path runs from the tee box up and right to the middle fence, touches it, and doubles back up
    /// and left to a green at the top: A's ball rides it to the fence, banks off the chain link and rides the second
    /// leg onto the green and into a dish round the cup, about 15° off the straight line. Off the path it dies in the
    /// rough. B is a long green running up and right, leaning left (200), with a false front: a broad bank (400, too
    /// steep for the green to hold a ball) across it just below the cup's tier. Its ball starts about 8° right of the
    /// cup and needs the pace to climb the bank, then the lean curls it in; come up short and it rolls back down. Same:
    /// both up and to the right. Paint the path rough, or take the bank away, and there's no double ace; paint the path
    /// green and it drops to 0.010%, with a 0.75° × 2% window.
    static func ballWasher() -> Level {
        var l = Level("Ball Washer", par: [2, 3], hint: "Bank it off the fence. Come up short and it rolls back.")
        l.setting = "muni"
        l.frame()
        // A: a tee box, a cart path up to the middle fence and back off it, to a green at the top.
        l.ground(.rough, .a)
        l.green(.a, [(78, 112), (122, 112), (130, 132), (120, 152), (80, 152), (70, 132)])
        l.cartPath(.a, [(102, 150), (133, 220), (162, 290), (185, 348), (170, 410), (150, 480), (124, 575)], width: 24)
        l.green(.a, [(70, 590), (130, 580), (160, 640), (150, 715), (105, 742), (55, 730), (38, 670), (45, 615)])
        l.hollow(.a, 130, 615, radius: 45, strength: 250)
        l.tee(.a, 100, 132)
        l.cup(.a, 130, 615)
        // B: a long green running up and right, leaning left, with a false front just below the cup's tier.
        l.ground(.rough, .b)
        l.green(.b, [(40, 114), (75, 108), (100, 200), (110, 330), (125, 420), (160, 500), (165, 600), (145, 690), (95, 700),
                     (75, 620), (70, 480), (48, 380), (40, 250), (37, 180)])
        l.tilt(.b, downhill: 170, strength: 200)
        l.tier(.b, 100, 480, downhill: 270, strength: 400, width: 80)
        l.hollow(.b, 135, 580, radius: 25, strength: 125)
        l.tee(.b, 45, 130)
        l.cup(.b, 135, 580)
        l.solution = Shot(angle: 71.00, power: 0.670, mirrored: false)
        return l
    }

    /// Pair 4. B's cart path sweeps up from the tee box and bends right round a hollow, a broad dip with a bunker in
    /// its bottom, to a green at the top. The ball rides it the whole way: the hollow's slope carries it round the
    /// bend, the path's pace gets it to the green, and a steep bank behind the cup sends a firm one back. Off the
    /// path it dies in the rough. A is a hog's back: a long green along a ridge, so the putt has to run straight
    /// down the spine; a little off line and it falls away into the rough. Same, up and a little left, along the
    /// spine, which starts B's ball about 12° left of its cup. Take the path away (rough or green) or flatten the
    /// hollow and there's no double ace.
    static func waterTower() -> Level {
        var l = Level("Water Tower", par: [2, 2], hint: "The path bends with the hollow. One green is a ridge.")
        l.setting = "muni"
        l.frame()
        // A: a hog's back, a long green along a ridge that falls away either side; a bank behind the cup.
        l.ground(.rough, .a)
        l.green(.a, [(101, 117), (78, 146), (56, 227), (43, 338), (41, 451), (50, 534), (69, 565), (92, 537),
                     (113, 456), (127, 344), (129, 232), (119, 149)])
        l.tier(.a, 74, 123, downhill: 184, strength: 238, width: 26)
        l.tier(.a, 126, 127, downhill: 4, strength: 238, width: 26)
        l.tier(.a, 70, 553.5, downhill: 274, strength: 317.5, width: 34)
        l.hollow(.a, 72.5, 515.5, radius: 25.5, strength: 82)
        l.tee(.a, 100, 125)
        l.cup(.a, 72.5, 515.5)
        // B: a tee box, a cart path sweeping up and round a hollow with a bunker in it, and a green at the top.
        l.ground(.rough, .b)
        l.green(.b, [(40, 112), (85, 112), (92, 140), (80, 165), (45, 165), (38, 140)])
        l.cartPath(.b, [(78, 140), (60, 200), (56, 270), (60, 340), (70, 414), (84, 487), (97, 550)], width: 24)
        l.green(.b, [(100, 520), (150, 540), (165, 620), (160, 700), (130, 740), (85, 735), (70, 670), (75, 580)])
        l.paint(.sand, .b, [(128, 285), (137.5, 305.5), (157, 310), (176, 294.5), (171, 270.5), (152, 262), (135, 268)],
                smooth: true)
        l.hollow(.b, 169.5, 278, radius: 193, strength: 244)
        l.tier(.b, 135, 681, downhill: 280, strength: 376.5, width: 30)
        l.hollow(.b, 139.5, 655, radius: 31, strength: 251)
        l.tee(.b, 62, 128)
        l.cup(.b, 139.5, 655)
        l.solution = Shot(angle: 93.75, power: 0.51, mirrored: false)
        return l
    }

    /// Pair 5, the showpiece. A's cart path winds out of the tee box, across the rough to the left fence, up beside the
    /// chain link and round behind the top green. A's ball rides it: along the path to the fence, a glancing bank off
    /// the chain link, then on up beside the fence until it rolls off onto the top green and into the cup, about 11°
    /// off the straight line. Off the path it dies in the rough. B's ball stays on its green, which leans hard left,
    /// so it starts about 9° right of the cup and curls back into a dish. Mirror: A up and to the left, B up and to
    /// the right. Paint the path rough or green and the double ace is gone.
    static func chainLink() -> Level {
        var l = Level("Chain Link", par: [2, 2], hint: "Ride the path along the fence. The other green leans.")
        l.setting = "muni"
        l.frame()
        // A: a tee green and a top green with rough between; a cart path from the tee to the left fence, up beside it
        // and round behind the top green.
        l.ground(.rough, .a)
        l.green(.a, [(105, 112), (150, 112), (160, 140), (140, 165), (105, 165), (95, 140)])
        l.green(.a, [(60, 520), (120, 540), (150, 620), (140, 710), (100, 742), (55, 740), (36, 690), (38, 580)])
        l.cartPath(.a, [(152, 150), (108, 200), (62, 330), (24, 470), (14, 560), (16, 640), (40, 728), (100, 776),
                        (165, 772)], width: 23)
        l.hollow(.a, 61.5, 684.5, radius: 30.5, strength: 268.5)
        l.tee(.a, 125, 135)
        l.cup(.a, 61.5, 684.5)
        // B: a green leaning hard left, the cup in a dish.
        l.ground(.rough, .b)
        l.green(.b, [(40, 112), (90, 112), (130, 200), (160, 330), (165, 450), (140, 520), (95, 530), (60, 450),
                     (40, 300), (34, 180)])
        l.tilt(.b, downhill: 180, strength: 161.5)
        l.hollow(.b, 105, 485.5, radius: 32, strength: 204)
        l.tee(.b, 50, 125)
        l.cup(.b, 105, 485.5)
        l.solution = Shot(angle: 107.75, power: 0.53, mirrored: true)
        return l
    }

    /// Pair 6. B is two greens, one above the other, with a false front between them: a fringe bank too steep to
    /// hold a ball, so a putt that runs out of pace on it rolls back down. The cart path is the way up. B's green
    /// leans left, so its ball starts up the right side about 12° right of the cup; at the bank it rides the path,
    /// which climbs and bends left with the slope, and comes off the top onto the upper green and into a dish, a bank
    /// behind the cup sending a firm one back. On the turf beside the path the same putt stalls on the bank. A is a
    /// broad green with a knob in it: the ball has to run past the knob's left shoulder, which turns it into the cup.
    /// Same, up and a little right. Take the path away and there's no double ace; flatten the false front and it moves
    /// somewhere else entirely.
    static func twilightRate() -> Level {
        var l = Level("Twilight Rate", par: [2, 2], hint: "The bank won't hold a putt, but the cart path climbs it.")
        l.setting = "muni"
        l.frame()
        // A: a broad green with a knob in it; the cup in a dish beyond, a gentle rise behind.
        l.ground(.rough, .a)
        l.green(.a, [(80, 112), (140, 115), (165, 220), (162, 380), (150, 520), (120, 620), (80, 640), (45, 610),
                     (34, 480), (40, 300), (60, 180)])
        l.hump(.a, 125, 280.5, radius: 69, strength: 235.5)
        l.tier(.a, 122, 611.5, downhill: 259, strength: 142.5, width: 30)
        l.hollow(.a, 113, 566, radius: 27, strength: 273)
        l.tee(.a, 100.5, 125)
        l.cup(.a, 113, 566)
        // B: a lower green, a fringe bank (the false front) and an upper green; the cart path climbs the bank.
        l.ground(.rough, .b)
        l.paint(.fringe, .b, [(60, 380), (100, 372), (170, 380), (172, 450), (170, 520), (100, 528), (60, 520),
                              (58, 450)], smooth: true)
        l.cartPath(.b, [(159, 290), (160, 350), (155, 415), (143, 460), (124, 510)], width: 22)
        l.green(.b, [(85, 112), (150, 112), (165, 160), (166, 300), (160, 365), (110, 375), (90, 370), (76, 300),
                     (76, 180)])
        l.green(.b, [(65, 525), (110, 520), (160, 540), (165, 640), (150, 710), (100, 740), (70, 725), (54, 640)])
        l.tilt(.b, downhill: 180, strength: 90)
        l.tier(.b, 100, 443, downhill: 227.5, strength: 392, width: 57.5)
        l.tier(.b, 62.5, 645.5, downhill: 300, strength: 369.5, width: 30)
        l.hollow(.b, 80, 615, radius: 34.5, strength: 220)
        l.tee(.b, 150, 125)
        l.cup(.b, 80, 615)
        l.solution = Shot(angle: 86.25, power: 0.59, mirrored: false)
        return l
    }

    /// Pair 7. A is a long, thin green toward the skyline, leaning hard right: its ball starts well left of the cup,
    /// about 17° off the line, and curls back into a dish. B tees off a high green; its cart path winds down a bank
    /// and swings out to the right fence, then curls back left across the lower green, which falls away left. B's
    /// ball rides it: the bank speeds it up (the asphalt can't hold it on that slope), the chain link turns it, and
    /// the fall of the lower green brings it round into the cup. Mirror: A up and to the left, B up and to the right.
    static func skyline() -> Level {
        var l = Level("Skyline", par: [2, 2], hint: "Ride the path down the bank. It bends off the fence.")
        l.setting = "muni"
        l.frame()
        // A: a long, thin green leaning hard right; a tee green at its foot.
        l.ground(.rough, .a)
        l.green(.a, [(60, 105), (130, 110), (150, 250), (160, 450), (165, 620), (145, 725), (95, 740), (60, 700), (50, 520),
                     (40, 300)])
        l.green(.a, [(168, 135), (165.6, 144), (159, 150.6), (150, 153), (141, 150.6), (134.4, 144), (132, 135),
                     (134.4, 126), (141, 119.4), (150, 117), (159, 119.4), (165.6, 126)])
        l.tilt(.a, downhill: 0, strength: 180)
        l.hollow(.a, 114, 680, radius: 35, strength: 280)
        l.tee(.a, 150, 130)
        l.cup(.a, 114, 680)
        // B: a high tee green, a bank falling away toward the skyline, and a lower green falling away left; the cart
        // path winds down the bank, out to the right fence and back across.
        l.ground(.rough, .b)
        l.green(.b, [(135, 137), (131, 148), (120, 156.1), (105, 159), (90, 156.1), (79, 148), (75, 137), (79, 126),
                     (90, 117.9), (105, 115), (120, 117.9), (131, 126)])
        l.green(.b, [(40, 470), (110, 450), (165, 490), (165, 620), (150, 710), (100, 742), (50, 735), (35, 620)])
        l.cartPath(.b, [(112.7, 164), (146.8, 269), (166.5, 331.4), (187, 421.1), (167.7, 517.6), (145.7, 613.6)], width: 22)
        l.tier(.b, 100, 330, downhill: 90, strength: 200, width: 70)
        l.hollow(.b, -30, 650, radius: 210, strength: 200)
        l.hollow(.b, 95, 672, radius: 35, strength: 280)
        l.tee(.b, 100, 125)
        l.cup(.b, 95, 672)
        l.solution = Shot(angle: 110.50, power: 0.650, mirrored: true)
        return l
    }

    /// Pair 8. A's cart path leaves the tee green and runs up and right between two bunkers to the middle fence,
    /// touches it, and swings back up and left to the top green. A's ball rides it: a bank off the chain link turns it
    /// about 28° and sends it back across onto the green and into the cup, about 14° off the straight line. Off the
    /// path it dies in the rough or a bunker. B is the practice green, a long, narrow green that climbs gently from
    /// the tee to the cup: a straight putt whose pace the climb decides. Paint the path rough or green and there's no
    /// double ace; flatten B's climb and it doubles. Same: both balls go up and to the right, A's along its path and
    /// B's along its green.
    static func practiceGreen() -> Level {
        var l = Level("Practice Green", par: [3, 2], hint: "Ride the path to the fence. The practice green climbs.")
        l.setting = "muni"
        l.frame()
        // A: a tee green bottom middle, a cart path up to the middle fence and back across to the top green, a bunker
        // either side of its first leg; the cup in a small dish.
        l.ground(.rough, .a)
        l.cartPath(.a, [(109, 142.3), (138, 243), (170.3, 355.1), (184, 420), (161.6, 528), (138.1, 641)], width: 24)
        l.green(.a, [(130, 131), (126.5, 141), (117, 148.3), (104, 151), (91, 148.3), (81.5, 141), (78, 131), (81.5, 121),
                     (91, 113.7), (104, 111), (117, 113.7), (126.5, 121)])
        l.green(.a, [(168, 700), (162.5, 726), (147.5, 745), (127, 752), (106.5, 745), (91.5, 726), (86, 700), (91.5, 674),
                     (106.5, 655), (127, 648), (147.5, 655), (162.5, 674)])
        l.paint(.sand, .a, [(119.6, 280.3), (122, 298.3), (118.6, 313), (110.3, 320.4), (99.4, 318.5), (88.7, 307.9),
                            (81.2, 291.3), (78.7, 273.3), (82.1, 258.6), (90.4, 251.2), (101.4, 253.1), (112, 263.7)], smooth: true)
        l.paint(.sand, .a, [(181.1, 196.3), (183.5, 213.3), (180.6, 227.1), (173.2, 234), (163.3, 232.1), (153.5, 222),
                            (146.5, 206.3), (144.1, 189.3), (147, 175.5), (154.4, 168.6), (164.3, 170.5), (174.1, 180.7)], smooth: true)
        l.hollow(.a, 133, 690, radius: 19, strength: 220)
        l.tee(.a, 104, 125)
        l.cup(.a, 133, 690)
        // B: the practice green, long and narrow, climbing gently from the tee to the cup, which sits in a dish.
        l.ground(.rough, .b)
        l.green(.b, [(42, 170), (68, 178), (98, 262), (130, 365), (156, 468), (166, 540), (162, 598), (140, 624), (112, 612),
                     (96, 560), (74, 450), (46, 330), (34, 245), (34, 192)])
        l.tilt(.b, downhill: 252.05, strength: 70)
        l.hollow(.b, 154, 562, radius: 25, strength: 150)
        l.tee(.b, 40, 210)
        l.cup(.b, 154, 562)
        l.solution = Shot(angle: 73.25, power: 0.540, mirrored: false)
        return l
    }

    /// Pair 9, the finale. A is a long, narrow green that climbs gently from the tee to a false front: a steep bank
    /// across the green just below the cup, too steep to hold a ball, with the cup on the shelf above it. A short putt
    /// stalls on the bank and rolls back down; a firm one tops it and dies in the dish round the cup. B's cart path
    /// leaves the tee green and runs up and left past a fairway bunker to the middle fence, touches it and swings
    /// back up and right to the top green. B's ball rides it: a bank off the chain link turns it and sends it back
    /// across onto the green and into the cup, about 14° off the straight line. Off the path it dies in the rough.
    /// Paint the path rough or green and there's no double ace; take the false front away and the double ace is 2.6
    /// times as common, at a softer putt. Mirror: A up and to the right along its green, B up and to the left along
    /// the path; the pace that just tops A's bank is the pace B's bank needs.
    static func lastCall() -> Level {
        var l = Level("Last Call", par: [2, 3], hint: "Short putts roll back. Bank the path off the fence.")
        l.setting = "muni"
        l.frame()
        // A: a long, narrow green climbing to a false front, the cup on the shelf above it in a dish.
        l.ground(.rough, .a)
        l.green(.a, [(42, 170), (68, 178), (98, 262), (130, 365), (156, 468), (166, 540), (162, 598), (138, 632), (106, 628),
                     (88, 575), (74, 450), (46, 330), (34, 245), (34, 192)])
        l.tilt(.a, downhill: 252.05, strength: 30)
        l.tier(.a, 138.56, 514.44, downhill: 252.05, strength: 360, width: 48)
        l.hollow(.a, 154, 562, radius: 25, strength: 150)
        l.tee(.a, 40, 210)
        l.cup(.a, 154, 562)
        // B: a tee green bottom middle, a cart path up to the middle fence and back across to the top green, a
        // fairway bunker right of its first leg and a greenside bunker; the cup in a small dish.
        l.ground(.rough, .b)
        l.cartPath(.b, [(91, 142.3), (62, 243), (29.7, 355.1), (16, 420), (38.4, 528), (61.9, 641)], width: 24)
        l.green(.b, [(70, 131), (73.5, 141), (83, 148.3), (96, 151), (109, 148.3), (118.5, 141), (122, 131), (118.5, 121),
                     (109, 113.7), (96, 111), (83, 113.7), (73.5, 121)])
        l.green(.b, [(32, 700), (37.5, 726), (52.5, 745), (73, 752), (93.5, 745), (108.5, 726), (114, 700), (108.5, 674),
                     (93.5, 655), (73, 648), (52.5, 655), (37.5, 674)])
        l.paint(.sand, .b, [(150, 300), (152, 325), (146, 350), (133, 366), (118, 362), (108, 342), (106, 316), (112, 292),
                            (125, 280), (139, 282)], smooth: true)
        l.paint(.sand, .b, [(152, 690), (150, 712), (141, 724), (131, 716), (128, 694), (132, 672), (142, 666)], smooth: true)
        l.hollow(.b, 67, 690, radius: 19, strength: 220)
        l.tee(.b, 96, 125)
        l.cup(.b, 67, 690)
        l.solution = Shot(angle: 73.25, power: 0.550, mirrored: true)
        return l
    }
}
