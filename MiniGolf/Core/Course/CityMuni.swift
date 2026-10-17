import Foundation

// City Muni (course 8): an everyday city course, and a putting course like The Links. Greens shaped by fringe,
// rough, sand and water, with steep contours to read, and cart paths that run faster than the green: several double
// aces need one ball to ride a path while the other stays on its green. Designed with Tools/solver against
// Tools/levels/BRIEF.md (course 8 targets).
extension Levels {
    /// Pair 1, the warm-up. A is a kidney green leaning hard right (170), with a big, steep bowl round the cup near
    /// the top and a bunker in the bend. Its ball has to start up the left side, about 16° left of the cup, and let
    /// the lean bring it round into the bowl, which gathers a range of paces. B is a long thin green that climbs to
    /// its cup and leans a little right, into a small dip round the cup: a near-straight putt whose pace the climb
    /// decides. The cart path up B's right side is only scenery here. Same, up and a little left. Take A's lean away
    /// and the Same double ace is gone (a 0.009% Mirror one is left); take B's lean away and it's gone too.
    static func clubhouse() -> Level {
        var l = Level("Clubhouse", par: [2, 2], hint: "One green leans hard. The other climbs to the cup.")
        l.setting = "muni"
        l.frame()
        // A: a kidney green leaning hard right, a bunker in its bend; a big bowl round the cup near the top.
        l.ground(.rough, .a)
        l.green(.a, [(50, 108), (95, 110), (110, 200), (105, 330), (125, 450), (158, 560), (162, 660), (140, 728), (95, 738),
                     (55, 690), (42, 560), (38, 400), (36, 250)])
        l.paint(.sand, .a, [(140, 300), (165, 320), (172, 420), (160, 470), (138, 420), (130, 350)], smooth: true)
        l.tilt(.a, downhill: 0, strength: 170)
        l.hollow(.a, 104.91, 680, radius: 70, strength: 350)
        l.tee(.a, 70, 125)
        l.cup(.a, 118, 680)
        // B: a long thin green climbing to the cup and leaning a little right; a cart path runs up the right side.
        l.ground(.rough, .b)
        l.cartPath(.b, [(172, 100), (166, 400), (160, 770)], width: 22)
        l.green(.b, [(85, 108), (130, 110), (135, 250), (125, 400), (118, 540), (98, 612), (55, 615), (38, 540), (52, 400),
                     (70, 250)])
        l.tilt(.b, downhill: 315, strength: 130)
        l.hollow(.b, 51.94, 553.06, radius: 22.5, strength: 260)
        l.tee(.b, 105, 125)
        l.cup(.b, 55, 550)
        l.solution = Shot(angle: 100.75, power: 0.630, mirrored: false)
        return l
    }

    /// Pair 2 introduces the cart path. A is long: a tee box, then a concrete path straight up through the rough to a
    /// green at the top, the cup in a dip on it. A putt runs much further on the path than on grass, so the ball
    /// rides it all the way up, rolls onto the green and drops. B is a long green leaning left (120) with no path on
    /// its line, so its ball has to start right, about 10° off the cup, and curl back into a bowl round it; its path
    /// runs up the right side, out of the way. The same power that carries A's ball up the path is just enough for
    /// B on grass. A goes up-left and B up-right: Mirror. Paint A's path as the rough it crosses and there is no
    /// double ace; paint it green and A's ball comes up short (the double ace drops to 0.010%, a 2% power window).
    static func cartPath() -> Level {
        var l = Level("Cart Path", par: [2, 2], hint: "The path runs fast. One ball needs it, one doesn't.")
        l.setting = "muni"
        l.frame()
        // A: a tee box at the bottom right, a cart path up through the rough to a green at the top.
        l.ground(.rough, .a)
        l.green(.a, [(132, 112), (160, 118), (164, 140), (150, 158), (128, 152), (122, 130)])
        l.cartPath(.a, [(140, 150), (98, 560)], width: 24)
        l.green(.a, [(70, 545), (120, 548), (152, 600), (150, 680), (115, 720), (60, 715), (40, 660), (45, 590)])
        l.hollow(.a, 92, 610, radius: 35, strength: 325)
        l.tee(.a, 145, 135)
        l.cup(.a, 92, 610)
        // B: a long green leaning left, the cup in a dip on its left side; a cart path up the right side.
        l.ground(.rough, .b)
        l.cartPath(.b, [(172, 100), (170, 400), (165, 770)], width: 22)
        l.green(.b, [(60, 108), (110, 108), (125, 250), (138, 420), (142, 560), (138, 670), (110, 728), (60, 725), (36, 650),
                     (36, 520), (50, 400), (55, 280), (50, 180)])
        l.tilt(.b, downhill: 180, strength: 120)
        l.hollow(.b, 61.5, 550, radius: 45, strength: 320)
        l.tee(.b, 80, 125)
        l.cup(.b, 55, 550)
        l.solution = Shot(angle: 96.25, power: 0.500, mirrored: true)
        return l
    }

    /// Pair 3. A has a false front: a long green leaning hard left (170), and two thirds of the way up a steep bank
    /// (400, too steep for the green to hold a ball) runs across it, falling toward the tee and to the right, with the
    /// cup's tier just above it. The ball has to start well right, about 8° off the cup, and arrive with pace enough to
    /// climb the bank, which kicks it right as it climbs; then the lean curls it back into a little dip round the cup.
    /// Come up short and the bank rolls it back down. B is short: its tee box sits halfway up the hole, a strip of rough
    /// to cross, then a green leaning right into a dip round the cup, with greenside bunkers either side (they catch
    /// some balls banked off the fences). Same: both up and a little right; the firm putt A's bank needs is the one that
    /// carries B's ball through the rough. Take the bank away and the double ace halves and its window shrinks to
    /// 0.75° × 3%.
    static func ballWasher() -> Level {
        var l = Level("Ball Washer", par: [3, 2], hint: "Come up short on the bank and it rolls back.")
        l.setting = "muni"
        l.frame()
        // A: a long green leaning left, with a false front: a steep bank across it below the cup's tier.
        l.ground(.rough, .a)
        l.green(.a, [(60, 108), (130, 108), (150, 250), (152, 420), (160, 560), (150, 690), (110, 735), (60, 725), (40, 620),
                     (45, 420), (45, 250)])
        l.tilt(.a, downhill: 180, strength: 170)
        l.tier(.a, 100, 520, downhill: 315, strength: 400, width: 55)
        l.hollow(.a, 90, 600, radius: 25, strength: 125)
        l.tee(.a, 120, 125)
        l.cup(.a, 90, 600)
        // B: short. A tee box halfway up, rough, then a green leaning right; bunkers either side of it.
        l.ground(.rough, .b)
        l.green(.b, [(40, 312), (80, 312), (87, 335), (77, 352), (43, 352), (33, 335)])
        l.green(.b, [(70, 430), (125, 430), (150, 520), (152, 640), (135, 715), (90, 730), (50, 710), (40, 620), (45, 510)])
        l.paint(.sand, .b, [(8, 400), (43, 410), (47, 490), (8, 500)], smooth: true)
        l.paint(.sand, .b, [(192, 400), (157, 410), (153, 490), (192, 500)], smooth: true)
        l.tilt(.b, downhill: 300, strength: 130)
        l.hollow(.b, 97.14, 634.95, radius: 20, strength: 175)
        l.tee(.b, 60, 332)
        l.cup(.b, 100, 630)
        l.solution = Shot(angle: 85.25, power: 0.600, mirrored: false)
        return l
    }

    /// Pair 4. Short vs long, and the cart path makes up the difference. A is a tee green and a top green with rough
    /// between them, joined by a straight cart path; the cup sits where the path's line meets the top green, so A's
    /// ball has to ride the whole path, and a putt soft enough for B still gets there because the path runs fast. B
    /// is a short kidney green leaning down and to the left, with a bank too steep to hold a ball just behind the
    /// cup: its ball starts about 12° right of the cup and curls in, and one that runs long climbs the bank and rolls
    /// back. Same, up and a little left, along the path. Paint the path rough or green, or take away B's lean or its
    /// bank, and there's no double ace.
    static func waterTower() -> Level {
        var l = Level("Water Tower", par: [2, 2], hint: "The cart path runs fast. The other green breaks hard.")
        l.setting = "muni"
        l.frame()
        // A: a tee green, a straight cart path up through the rough, and a green at the top; the cup in a dish there.
        l.ground(.rough, .a)
        l.green(.a, [(130, 112), (162, 114), (166, 140), (158, 165), (125, 165), (115, 140)])
        l.cartPath(.a, [(150, 135), (127, 330), (105, 520)], width: 20)
        l.green(.a, [(70, 490), (130, 505), (160, 580), (160, 690), (125, 740), (60, 735), (35, 650), (40, 540)])
        l.hollow(.a, 88, 662, radius: 32, strength: 240)
        l.tee(.a, 150, 125)
        l.cup(.a, 88, 662)
        // B: a kidney green leaning down and left; a steep bank behind the cup sends long putts back.
        l.ground(.rough, .b)
        l.green(.b, [(140, 112), (164, 120), (166, 220), (150, 330), (125, 440), (85, 520), (45, 530), (34, 460),
                     (45, 370), (90, 250), (120, 140)])
        l.tilt(.b, downhill: 200, strength: 103)
        l.tier(.b, 53, 485, downhill: 270, strength: 375, width: 30)
        l.hollow(.b, 53, 440, radius: 29, strength: 250)
        l.tee(.b, 150, 125)
        l.cup(.b, 53, 440)
        l.solution = Shot(angle: 95.50, power: 0.50, mirrored: false)
        return l
    }

    /// Pair 5. A's cart path runs from the tee box across the rough to the left fence and on up beside it. A's ball
    /// rides it the whole way: along the path to the fence, a glancing bank off the chain link, then on up the path
    /// beside the fence until it rolls off onto the top green and into the cup, about 11° off the straight line. Off
    /// the path it dies in the rough. B's ball stays on its green, which leans hard left, so it starts about 9° right
    /// of the cup and curls back into a dish. Mirror: A up and to the left, B up and to the right. Paint the path
    /// rough or green and the double ace is gone.
    static func chainLink() -> Level {
        var l = Level("Chain Link", par: [2, 2], hint: "Ride the path along the fence. The other green leans.")
        l.setting = "muni"
        l.frame()
        // A: a tee green and a top green with rough between; a cart path from the tee to the left fence, then up it.
        l.ground(.rough, .a)
        l.green(.a, [(105, 112), (150, 112), (160, 140), (140, 165), (105, 165), (95, 140)])
        l.green(.a, [(60, 520), (120, 540), (150, 620), (140, 710), (100, 742), (55, 740), (36, 690), (38, 580)])
        l.cartPath(.a, [(115, 145), (62, 330), (16, 520), (16, 700), (16, 790)], width: 23)
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

    /// Pair 6. A is a broad green leaning up and to the right, with a false front across it (a bank too steep to
    /// hold a ball) rising just past the cup and to its left, falling back toward it. The ace starts about 13° left
    /// of the cup and runs past it up the fringe onto the bank; short of the top, the false front sends it back down
    /// into the cup. Without the false front there's no double ace. B is a long, thin green leaning hard left: its
    /// ball starts about 12° right of the cup and curls back into a dish. Mirror: A up and to the left, B up and to
    /// the right. A bunker along the middle fence beside B's tee kills banks off it, which would otherwise make easy
    /// Same double aces.
    static func twilightRate() -> Level {
        var l = Level("Twilight Rate", par: [2, 2], hint: "A steep bank won't hold a short putt. It rolls back.")
        l.setting = "muni"
        l.frame()
        // A: a broad green leaning up and to the right; a false front across it just past the cup, falling back
        // toward the cup, which sits in a shallow dish at its foot.
        l.ground(.rough, .a)
        l.green(.a, [(110, 112), (160, 114), (165, 250), (155, 400), (150, 560), (125, 690), (80, 705), (40, 650),
                     (38, 500), (60, 350), (90, 200)])
        l.tilt(.a, downhill: 50.5, strength: 113)
        l.tier(.a, 67.5, 427.5, downhill: 298, strength: 345, width: 55)
        l.hollow(.a, 89.5, 387.5, radius: 24, strength: 40.5)
        l.tee(.a, 121, 125)
        l.cup(.a, 89.5, 387.5)
        // B: a long, thin green leaning hard left, the cup in a dish; a bunker along the middle fence beside the tee.
        l.ground(.rough, .b)
        l.green(.b, [(60, 112), (100, 114), (120, 250), (145, 420), (160, 560), (160, 680), (135, 735), (100, 720),
                     (90, 600), (70, 450), (45, 300), (40, 180)])
        l.tilt(.b, downhill: 157.5, strength: 133.5)
        l.paint(.sand, .b, [(0, 130), (18, 138), (30, 160), (32, 240), (30, 320), (18, 342), (0, 350)])
        l.hollow(.b, 127.5, 458, radius: 32, strength: 203.5)
        l.tee(.b, 80.5, 125)
        l.cup(.b, 127.5, 458)
        l.solution = Shot(angle: 110.00, power: 0.47, mirrored: true)
        return l
    }

    /// Pair 7. Two long greens that lean opposite ways, each with a bank behind its cup that turns a firm putt back
    /// toward it. A's tee box sits at the foot of a cart path that runs up and a little right; the whole hole leans
    /// left and a touch back toward the tee, so the ball keeps its pace on the concrete, then curls left up the green
    /// into a dish near the back, below a bank rising up and to the left. B is the practice green, a long oval leaning
    /// right: its ball starts well left of the cup and curls right into a dish below a bank rising up and to the right.
    /// Mirror: A goes up and right, B up and left; both banks forgive a putt that's a little firm.
    static func practiceGreen() -> Level {
        var l = Level("Practice Green", par: [2, 2], hint: "Firm putts come back off the banks. The path runs fast.")
        l.setting = "muni"
        l.frame()
        // A: a tee box, a cart path up and a little right, then a long green; the hole leans left and back, and a bank
        // behind the cup falls back toward it.
        l.ground(.rough, .a)
        l.green(.a, [(150, 130), (146.8, 140), (138, 147.3), (126, 150), (114, 147.3), (105.2, 140), (102, 130),
                     (105.2, 120), (114, 112.7), (126, 110), (138, 112.7), (146.8, 120)])
        l.cartPath(.a, [(126, 143), (136, 330)], width: 22)
        l.green(.a, [(110, 330), (160, 340), (165, 500), (160, 650), (130, 730), (70, 740), (35, 690), (36, 560), (70, 420)])
        l.tilt(.a, downhill: 195, strength: 140)
        l.hollow(.a, 86, 708, radius: 33, strength: 320)
        l.tier(.a, 70.6, 750.3, downhill: 290, strength: 210, width: 30)
        l.tee(.a, 126, 125)
        l.cup(.a, 86, 708)
        // B: the practice green, a long oval leaning right and a little back toward its tee box; a bank behind the
        // cup falls back toward it.
        l.ground(.rough, .b)
        l.green(.b, [(168, 420), (158.9, 575), (134, 688.5), (100, 730), (66, 688.5), (41.1, 575), (32, 420), (41.1, 265),
                     (66, 151.5), (100, 110), (134, 151.5), (158.9, 265)])
        l.green(.b, [(78, 145), (75.1, 155), (67, 162.3), (56, 165), (45, 162.3), (36.9, 155), (34, 145), (36.9, 135),
                     (45, 127.7), (56, 125), (67, 127.7), (75.1, 135)])
        l.tilt(.b, downhill: 345, strength: 140)
        l.hollow(.b, 120, 607, radius: 45, strength: 320)
        l.tier(.b, 142.5, 646, downhill: 240, strength: 185, width: 30)
        l.tee(.b, 56, 140)
        l.cup(.b, 120, 607)
        l.solution = Shot(angle: 82.00, power: 0.620, mirrored: true)
        return l
    }

    /// Pair 8. A is a long green toward the skyline, leaning hard left and a little back toward the tee, with a pond
    /// along the left fence: its ball starts well right of the cup and the lean brings it round into a dish. B's tee
    /// sits on a high tee green; a cart path runs straight down the bank to the lower green, which falls away left
    /// into a dish round the cup. On the concrete the bank speeds the ball up (it holds nothing steeper than 130), so
    /// a soft putt rides the path all the way down. Mirror: A goes up and right, B up and left along the path.
    static func skyline() -> Level {
        var l = Level("Skyline", par: [3, 2], hint: "Ride the cart path down the bank. One green leans left.")
        l.setting = "muni"
        l.frame()
        // A: a long green leaning left and back, a pond along the left fence, the cup in a dish.
        l.ground(.rough, .a)
        l.green(.a, [(110, 105), (165, 115), (165, 300), (160, 500), (150, 680), (110, 735), (60, 735), (35, 680), (35, 450),
                     (60, 250)])
        l.paint(.water, .a, [(0, 330), (14, 340), (22, 450), (14, 610), (0, 620)], smooth: true)
        l.tilt(.a, downhill: 200, strength: 175)
        l.hollow(.a, 80, 702, radius: 35, strength: 300)
        l.tee(.a, 145, 130)
        l.cup(.a, 80, 702)
        // B: a high tee green, a cart path down the bank, and a lower green falling away left to the cup.
        l.ground(.rough, .b)
        l.green(.b, [(93, 105), (163, 105), (168, 200), (88, 200)], smooth: false)
        l.green(.b, [(40, 420), (110, 405), (165, 430), (165, 600), (150, 700), (110, 740), (60, 735), (35, 650), (35, 500)])
        l.cartPath(.b, [(128, 143), (118, 430)], width: 22)
        l.tier(.b, 100, 320, downhill: 90, strength: 200, width: 60)
        l.hollow(.b, -20, 650, radius: 200, strength: 200)
        l.hollow(.b, 60, 650, radius: 30, strength: 240)
        l.tee(.b, 128, 125)
        l.cup(.b, 60, 650)
        l.solution = Shot(angle: 83.25, power: 0.680, mirrored: true)
        return l
    }

    /// Pair 9, the finale: long against short. A climbs to a shelf under the city side. A false front, a bank too
    /// steep to hold a ball, runs across the green below the cup, and a cart path climbs it straight up from the middle
    /// of the green; a putt that doesn't crest the bank rolls back down, and the concrete is the cheap way up. Behind
    /// the cup a gentler bank falls back toward it and turns a firm putt round. Ponds along both fences and a canal
    /// behind the green take the bank shots. B is short: its tee sits high on a green that leans hard right and back
    /// toward the tee, so its ball starts far left of the cup and curls across into a dish below a bank. Same: both go
    /// up and a touch left. Take the false front away and the double ace moves to a softer putt; take the path away and
    /// there isn't one.
    static func lastCall() -> Level {
        var l = Level("Last Call", par: [3, 2], hint: "Short putts roll back off the bank. Take the path up.")
        l.setting = "muni"
        l.frame()
        // A: a long green up to a shelf; a false front below the cup with a cart path climbing it; a bank behind the cup.
        l.ground(.rough, .a)
        l.green(.a, [(55, 105), (145, 105), (162, 300), (165, 550), (165, 680), (140, 735), (60, 740), (35, 680), (35, 550),
                     (40, 300)])
        l.cartPath(.a, [(65, 470), (65, 690)], width: 22)
        l.tier(.a, 100, 610, downhill: 270, strength: 400, width: 60)
        l.tilt(.a, downhill: 0, strength: 60)
        l.paint(.water, .a, [(0, 762), (200, 762), (200, 800), (0, 800)])
        l.paint(.water, .a, [(0, 300), (16, 315), (20, 430), (16, 545), (0, 560)], smooth: true)
        l.paint(.water, .a, [(200, 300), (184, 315), (180, 430), (184, 545), (200, 560)], smooth: true)
        l.hollow(.a, 91, 698.5, radius: 30, strength: 300)
        l.tier(.a, 102.65, 742, downhill: 255, strength: 200, width: 30)
        l.tee(.a, 70, 125)
        l.cup(.a, 91, 698.5)
        // B: short; the tee sits high on a green leaning hard right and back; a bank behind the cup; a canal behind.
        l.ground(.rough, .b)
        l.green(.b, [(70, 250), (140, 260), (165, 450), (160, 600), (165, 700), (130, 740), (60, 740), (35, 660), (35, 450),
                     (40, 290)])
        l.tilt(.b, downhill: 336, strength: 221)
        l.paint(.water, .b, [(0, 762), (200, 762), (200, 800), (0, 800)])
        l.hollow(.b, 146, 700, radius: 35, strength: 270)
        l.tier(.b, 168.5, 739, downhill: 240, strength: 200, width: 30)
        l.tee(.b, 34.5, 300)
        l.cup(.b, 146, 700)
        l.solution = Shot(angle: 93.75, power: 0.620, mirrored: false)
        return l
    }
}
