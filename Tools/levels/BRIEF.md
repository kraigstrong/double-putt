# Course design brief — Double Putt

You are designing hole **pairs** for Double Putt, an iOS mini golf puzzle game. Pairs come in **courses** of nine,
played as a round. About ten courses are planned, each a little harder than the last.

## The game
- Each screen is a **pair**: hole A (left, x 0–200) and hole B (right, x 200–400), side by side in a 400 × 800 course
  (y up). Tees usually sit near the bottom (y ≈ 100–130), cups toward the top.
- **One swing moves both balls.** The player sets one angle + power. Per swing they choose **Same** (both balls get the
  identical velocity) or **Mirror** (ball B gets it flipped left↔right: vx → −vx).
- **Any ball can drop in any cup** (one ball per cup). A ball that crosses into the other hole (gap, tunnel, shared
  green) is fine.
- Scoring is per hole: every swing counts as a stroke on each hole whose ball is still out. Par per hole is 2 or 3.
  A **double ace** (both in on the first swing) is the jackpot and wins that pair's trophy.
- The aim guide only shows each ball's direction and first bounce — never where it stops. It runs straight (slopes
  and surfaces don't bend or slow it), ignores movers, and reaches further for a firmer putt. So
  the puzzle is reasoning about angles, banks, power, timing and mechanics.

## Read these first
- `MiniGolf/Core/Levels.swift` — the `Level` builder API, the course lineup, and the first pairs (good examples:
  `reflection`, `backboard`, `moat`, `carom`, `crossover`).
- `MiniGolf/Core/Course/*.swift` — the other shipped pairs (e.g. `windmill`, `lanterns`, `midnight`).
- `MiniGolf/Core/Physics.swift` — the exact simulation (don't change it).

## Builder API (x/y are local to the side's hole: 0–200 wide; `.a` or `.b`)
```swift
var l = Level("Name", par: [2, 3], hint: "One short teasing sentence.")
l.setting = "links"                  // meadow garden moat seaside autumn desert winter night midway bigtop fireworks links muni
l.bandon = true                      // Bandon the dachshund naps beside this pair (a few Links pairs)
l.frame(gaps: [380...460])          // outer fence + middle wall; gaps = y-ranges where the middle wall is open
l.tee(.a, x, y); l.cup(.a, x, y)    // and .b. Or l.cups = [Vec(..), Vec(..)] in global coords
l.rail(.a, x1, y1, x2, y2)          // 8-unit-thick wall
l.block(.b, minX, minY, maxX, maxY) // solid rect (drawn as a planter / rock / snowbank depending on setting)
l.bumper(.a, x, y, r: 16)           // round post, restitution 1.0
l.water(.a, minX, minY, maxX, maxY) // hazard: +1 stroke, ball returns to where it was hit from
l.tunnel(.a, x, y, .b, x, y, exitA: nil, exitB: 90)  // two-way pipe; exitX = degrees the ball leaves that mouth (nil = keep direction). Keeps 90% speed.
l.slope(.a, minX, minY, maxX, maxY, downhill: 0, strength: 140)  // constant push; strength ≤ 200
l.hill(.b, x, y, radius: 50, strength: 140)   // pushes outward
l.bowl(.b, x, y, radius: 50, strength: 140)   // pulls inward (great around a cup)
l.tilt(.a, downhill: 0, strength: 60)        // contours (smooth, they add up): the whole hole leans
l.tier(.a, x, y, downhill: 270, strength: 150, width: 40)  // a bank across the hole through (x, y), falling toward `downhill`°
l.hump(.b, x, y, radius: 60, strength: 120)  // a rounded rise that sheds balls; flat again at `radius`
l.hollow(.b, x, y, radius: 60, strength: 140) // a rounded dip that gathers them
l.hump(nil, 200, 400, radius: 90, strength: 110) // nil instead of a hole: course coordinates, across both holes
l.ground(.rough, .a)                         // surfaces, painted in order (later covers earlier): a hole's base
l.green(.a, [(100, 90), (160, 110), ...])    // a green in this shape (smooth by default) with a fringe collar
l.paint(.sand, .a, [(140, 380), ...], smooth: true)  // any surface in any shape: .green .fringe .rough .sand .water
l.cartPath(.a, [(60, 90), (40, 400), (90, 760)], width: 22)  // a concrete cart path along a curve (City Muni): runs fast
l.rotor(.a, x, y, blades: 4, length: 45, rpm: 30, phase: 0)       // windmill; blades at `phase` when the pair loads, then never stop
l.slider(.b, minX, minY, maxX, maxY, dx: 90, dy: 0, period: 2.5)  // block glides by (dx,dy) and back, forever
l.kicker(.a, x, y, toward: 90, speed: 520)    // springboard pad (radius 13): launches a ball rolling onto it toward `toward`° at `speed`
l.carousel(.b, x, y, radius: 45, rpm: 25)     // spinning disk, flush with the green: drags a ball on it along with its surface
l.solution = Shot(angle: 72.5, power: 0.81, mirrored: true)       // from the solver
l.solutionTime = 0                   // mover clock when `solution` is struck (movers only; 0 = the load pose)
```
Useful physics numbers: ball radius 7, cup radius 12 (fast balls > 330 u/s lip out), rails radius 4, max shot speed
1050 (power 1.0) travels roughly 1600 units on flat green, wall restitution 0.72, tunnel mouth radius 11. Movers never
stop: a swing starts wherever they are, so putt timing matters as well as power. A ball that stops in a mover's path
slides to the nearest clear spot (no nearer a cup), so tees must sit outside every mover's sweep.

Kickers and carousels (from course 4):
- A **kicker** replaces the ball's velocity, whatever it came in with, so everything after the pad is fixed: only
  reaching the pad (and the other ball) depends on the swing. Rough carry after the pad on flat green: speed 520 →
  ~360 units, 700 → ~620, 900 → ~1000. A ball ignores a pad again until it rolls clear of it.
- A **carousel** pulls a ball's velocity toward the disk's surface motion (grip 2.5/s; surface speed = rpm × 2π/60 ×
  distance from the centre). In practice it mostly *brakes* a fast crossing ball (handy for taking pace off a short
  hole) and only visibly *bends* slow ones; for a readable curve use a big, fast disk (radius 60+, 40–50 rpm) with
  the cup close beyond it. It turns at a steady rate, so its pull doesn't depend on when you swing (no timing
  window; `--report` leaves Timing blank), and the aim guide ignores it. A ball can't rest on a carousel; tees must
  be off the disk.

Contours (from course 7):
- **Tilt, tier, hump and hollow** add up into one smooth green per hole, unlike `slope` boxes, which switch on at their
  edges. `strength` is each one's strongest pull in units/s²: a tier's is on its line (fading out `width` either
  side), a hump's or hollow's a little over halfway out (flat again at `radius`). The total is capped at 400. Above
  what a surface can hold (green 240, fringe 330; rough holds up to 520) a stalled ball rolls back down: a false
  front. Keep tees and cups on ground that holds a ball (`--verify` checks tees). Each hole's contours stay in that
  hole unless the side is nil.
- Players read them from the slope grid on the green and fringe: blue is low, red is high, and the dots glide
  downhill, faster where it's steeper. Keep a hole to two or three shapes so it reads at a glance.
- **Make the break matter.** The aim guide runs straight and cups take any ball under 330 units/s, so gentle leans
  (under ~100) barely bend a firm putt and the answer is "aim at the cup". `--report`'s Aim off column shows how far
  each ball's stored double ace aims off the straight line to its cup: on a putting course, aim for at least 6° on
  one ball early on, rising to 15° or more by the end.
- **Surfaces** shape a green inside the usual `frame()`: paint a hole's base (`ground`, often rough), then greens,
  bunkers and ponds as curvy (`smooth: true`) or angled shapes; later paint covers earlier and a green gets a
  fringe collar (`apron: [3: 30]` widens it at point 3, easing back to the collar either side). Leave rough showing
  round every green: greens and fringe stay 12 units off every wall's face (`--verify` checks), and a smooth curve
  bulges past its points, so add points where it should hug a line. Balls roll across them: the same putt
  carries about 72% as far on fringe, 46% on rough and 19% in sand (a firm putt crosses several ball-lengths of
  bunker, a soft one dies in it), and painted water is a hazard. The best pairs make one ball cross fringe or sand while the other stays on the green. Cups go on green.

Cart paths (from course 8):
- A **cart path** (City Muni's feature) is a concrete strip laid along a smooth curve through the points, open at
  both ends. A putt runs 1.3–1.5 times as far along it as on the green (rolling resistance 130 against the green's
  240, less drag), and on any slope stronger than 130 it keeps rolling downhill until it reaches ground that holds
  it, so a path down a bank carries a ball a long way. It isn't turf, so no slope grid shows on it: keep contours
  under a path gentle, or make the run obvious from the green either side. Paint it after the ground it crosses
  and before any green that should cover it. Make the path matter: one ball needs its extra run to reach a far cup,
  or it carries one ball round a corner while the other stays on the green.

## Your file
Draft pairs in a scratch file under `Tools/levels/` (one per designer):
```swift
extension Levels {
    static let drafts: [Level] = [pairOne(), pairTwo()]

    static func pairOne() -> Level { ... }
}
```
Use exactly the function and level names you were assigned. **Do not edit any other file.** Pair names must be unique
across every course (bests and trophies are saved by name).

## Solver (your main tool)
```bash
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts            # full stats for all your pairs
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts --report   # one line per pair: the numbers below
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts gust       # name filter
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts gust --probe 85   # outcome per power at one angle
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts --verify   # every l.solution double-aces; tees clear
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts --timing   # mover pairs: how exact the timing must be
Tools/solve.sh --report --course nightfall                               # compare with a shipped course
```
It brute-forces every first swing (1440 angles × 100 powers × Same/Mirror) with the real physics: double-ace %,
A-only / B-only %, water %, ball-hit / tunnel aces, per-hole ace % with a suggested par, double-ace regions, and the
most robust double ace (`level.solution = ...`). A few seconds per pair (`--report` ~5 s; `--timing` longer).
Several designers share one laptop, so cap each run's threads and lower its priority:
`SOLVER_THREADS=2 nice -n 10 Tools/solve.sh ...` (the solver uses every core otherwise). Run one heavy search at a
time.

## Difficulty
Measure difficulty with `--report`: **Dbl ace** (share of all first swings that double-ace, better of Same/Mirror)
and **Window** (the most forgiving ace's angle × power window). Each course ramps up across its nine pairs, and opens
about where the previous course's middle sat. Shipped courses, measured:

| Course | Double ace % by pair | Windows | Par | Mover timing | Playtest |
| --- | --- | --- | --- | --- | --- |
| 1 Daybreak | 0.59 0.60 0.06 0.05 0.12 0.14 0.08 0.17 0.10 | 1.5–2.75° × 7–13% | 40 | ~1 s | |
| 2 Nightfall | 0.06 0.07 0.09 0.07 0.12 0.06 0.04 0.06 0.06 | 1.25–3° × 6–17% | 46 | 300 ms–1 s | |
| 3 Thunderhead | 0.096 0.087 0.067 0.061 0.059 0.056 0.043 0.039 0.033 | 1.5–2.5° × 7–13% | 48 | 570–685 ms | "hard, in a good way" |
| 4 Midway | 0.080 0.075 0.068 0.062 0.052 0.044 0.040 0.038 0.029 | 1.5–3.25° × 6–11% | 47 | 410–465 ms | fun, but played easier than Thunderhead |
| 5 Big Top | 0.065 0.051 0.049 0.047 0.042 0.037 0.033 0.029 0.024 | 1.0–1.75° × 5–10% | 47 | 245–400 ms | not yet playtested |
| 6 Fireworks | 0.043 0.042 0.037 0.033 0.031 0.028 0.026 0.021 0.018 | 1.25–1.75° × 5–8% | 50 | 230–595 ms | not yet playtested |
| 7 The Links | 0.041 0.035 0.028 0.025 0.022 0.021 0.024 0.013 0.010 | 1.0–1.5° × 5–7% | 40 | — (no movers) | first cut: slopes too gentle, routes obvious; retuned steeper |

Midway measured a touch harder than Thunderhead yet played easier. Likely causes: wide windows (several ≥ 2.5°), and
holes a player can ace almost at will (Springboard's A, High Striker's B and Teacups' B each ace 2.5–3% of all swings,
so only the other hole is really a puzzle). Use both as levers: keep windows near the floor in later pairs, and keep
each hole's own ace share (`--report` "Ace A/B %") under ~1.5% so both balls are a puzzle.

Targets for the rest of the plan (guides, not rules; the window floor matters most, since a player must be able to
find and repeat the shot):

| Courses | Opens → ends (double ace %) | Window | Mover timing at least | Hole ace at most | Par |
| --- | --- | --- | --- | --- | --- |
| 5 Big Top | ~0.060 → ~0.025 | 1.0–2.0° × 5–9% | 200 ms | ~1.5% | 48–52 |
| 6 Fireworks | ~0.050 → ~0.018 | 1.0–1.75° × 5–8% | 200 ms | ~1.5% | 50–54 |
| 7 The Links | ~0.04 → ~0.01 | 1.0–1.5° × 5–7% | — | ~1.2% | 50–54 |
| 8 City Muni | ~0.030 → ~0.009 | 1.0–1.5° × 5–7% | — | ~1.2% | the solver's |
| 10 | ~0.03 → ~0.005 | 0.75–1.25° × 4–6% | 150 ms | ~1.0% | 52–54 |

Harder isn't only a smaller double-ace share: more mechanics working together, more asymmetry between A and B, and
more 3-par holes all count.

The putting courses (7–9) have no movers. After The Links' first playtest (slopes too gentle, routes obvious), make
the slopes steep enough that the aim off grows from at least 6° early to 15° or more late, use a false front or two
per course, never tighten a cup, and mix Same and Mirror (about four of each per course).

## Asymmetry (from course 3 on)
The early courses lean on near-mirror layouts. Later ones should make the shared swing far from obvious:
- **Unrelated layouts:** A and B look nothing alike: different shapes, obstacles, tee and cup spots.
- **One-sided mechanics:** a mechanic on only one side (a windmill in A, a slope in B), so the balls behave
  differently.
- **Short vs long:** one hole a short chip (tee high up, e.g. y ≈ 400) beside a long haul, so one power must suit both
  distances (a backboard, bowl or slope usually makes that possible).
Keep each hole readable on its own: a player should see what it asks.

## Design targets (check every pair with the solver)
1. **A double ace exists**, inside the course's window and timing floors above.
2. **Difficulty fits its slot** in the course's ramp (see the table; compare with `--report` on a shipped course).
3. **The featured mechanic matters:** the double ace should depend on it (e.g. `tunnel aces > 0` for a tunnel pair; or
   temporarily remove the mechanic and confirm the double ace disappears or changes a lot).
4. **A real decision:** Same vs Mirror should matter, or "ace one now vs set both up". A pair where one obvious
   straight shot aces both is too easy.
5. **Par:** use the solver's per-hole suggestion (hole ace ≥ 0.25% → 2, else 3), but sanity-check that each hole is
   playable in that many strokes.
6. **Readable layout:** don't clutter. Keep y < 95 empty (a hint banner sits there), cups at y ≤ 745 (flags draw ~40
   units upward), nothing overlapping tees or cups, tunnel mouths ≥ 20 units from walls and each other, tees outside
   every mover's sweep.
7. **Hint:** one or two short, plain sentences (≤ 60 characters, so it fits the banner in two lines) that set up
   the idea without giving away the answer. Never call the holes A and B: say "one hole" and "the other", or name
   the feature.

## Shipping a course
1. Move the nine pairs into `MiniGolf/Core/Course/<Name>.swift` (an `extension Levels` of pair functions).
2. Add one line to `Levels.lineup` in `MiniGolf/Core/Levels.swift`: `("id", "Name", [pairOne(), ...])`. The course
   unlocks with a medal on the one before it (Daybreak and Nightfall are always open).
3. `Tools/solve.sh --verify` (CI runs it), then `Tools/solve.sh --readme --course <name>` and paste the table into
   README's course section.

## Report back
For each pair: name, setting, the idea / "aha", which asymmetry it uses, par, double-ace %, best window, Same or
Mirror, mover timing window (if any), whether the mechanic is used by the double aces, and anything you're unsure
about.
