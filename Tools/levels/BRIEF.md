# Level design brief — Double Putt

You are designing hole **pairs** for Double Putt, an iOS mini golf puzzle game.

## The game
- Each screen is a **pair**: hole A (left, x 0–200) and hole B (right, x 200–400), side by side in a 400 × 800 course (y up). Tees sit near the bottom (y ≈ 100–130), cups toward the top.
- **One swing moves both balls.** The player sets one angle + power. Per swing they choose **Same** (both balls get the identical velocity) or **Mirror** (ball B gets it flipped left↔right: vx → −vx).
- **Any ball can drop in any cup** (one ball per cup). A ball that crosses into the other hole (gap, tunnel, shared green) is fine.
- Scoring is per hole: every swing counts as a stroke on each hole whose ball is still out. Par per hole is 2 or 3. A **double ace** (both in on the first swing) is the jackpot.
- The aim guide only shows each ball's direction and first bounce — never where it stops. So the puzzle is reasoning about angles, banks, power and mechanics.

## Read these first
- `MiniGolf/Core/Levels.swift` — the `Level` builder API and the 8 existing pairs (good examples: `reflection`, `backboard`, `moat`, `carom`, `crossover`).
- `MiniGolf/Core/Physics.swift` — the exact simulation (don't change it).

## Builder API (x/y are local to the side's hole: 0–200 wide; `.a` or `.b`)
```swift
var l = Level("Name", par: [2, 3], hint: "One short teasing sentence.")
l.setting = "desert"                 // meadow garden moat seaside autumn desert winter night
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
l.rotor(.a, x, y, blades: 4, length: 45, rpm: 30, phase: 0)       // windmill; resets to phase every swing
l.slider(.b, minX, minY, maxX, maxY, dx: 90, dy: 0, period: 2.5)  // block glides by (dx,dy) and back; resets every swing
l.solution = Shot(angle: 72.5, power: 0.81, mirrored: true)       // from the solver
```
Useful physics numbers: ball radius 7, cup radius 12 (fast balls > 330 u/s lip out), rails radius 4, max shot speed 1050 (power 1.0) travels roughly 1600 units on flat green, wall restitution 0.72, tunnel mouth radius 11. Movers only move while balls roll and restart from their start pose every swing — so the puzzle stays deterministic and power = timing.

## Your file
The shipped pairs live in `MiniGolf/Core/Levels.swift` and `MiniGolf/Core/Course/*.swift`, with the round order in `Levels.course`.
Draft new pairs in a scratch file under `Tools/levels/` (then move them into `Course/` and add them to `Levels.course`):
```swift
extension Levels {
    static let drafts: [Level] = [pairOne(), pairTwo()]

    static func pairOne() -> Level { ... }
}
```
Use exactly the function and level names you were assigned. **Do not edit any other file.**

## Solver (your main tool)
```bash
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts            # all your pairs
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts dunes      # name filter
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts dunes --probe 85   # outcome per power at one angle
LEVELS=Tools/levels/<yourfile>.swift Tools/solve.sh --drafts --verify   # check every l.solution double-aces
```
It brute-forces every first swing (1440 angles × 100 powers × Same/Mirror) with the real physics and prints: double-ace %, A-only / B-only %, water %, ball-hit / tunnel aces, per-hole ace % with a suggested par, double-ace regions, and the most robust double ace (`level.solution = ...`). ~1–3 s per pair.

## Design targets (check every pair with the solver)
1. **A double ace exists**, and the best window is at least **~1.0° × 5% power** (players fine-tune in 0.25° and 1% steps).
2. **Not trivial:** double-ace share of all shots within the target range in your assignment (the tutorial pairs are ~0.6%; hard pairs ~0.03%).
3. **The featured mechanic matters:** the double ace should depend on it (e.g. `tunnel aces > 0` for a tunnel pair; or temporarily remove the mechanic and confirm the double ace disappears or changes a lot).
4. **A real decision:** Same vs Mirror should matter, or "ace one now vs set both up". A pair where one obvious straight shot aces both is too easy.
5. **Par:** use the solver's per-hole suggestion (hole ace ≥ 0.25% → 2, else 3), but sanity-check that each hole is playable in that many strokes.
6. **Readable layout:** don't clutter. Keep y < 95 empty (a hint banner sits there), cups at y ≤ 745 (flags draw ~40 units upward), nothing overlapping tees or cups, tunnel mouths ≥ 20 units from walls and each other. Both holes should look like holes (not a maze of rails).
7. **Hint:** one sentence ≤ 70 characters that sets up the idea without giving away the answer.

## Report back
For each pair: name, setting, the idea / "aha", par, double-ace %, best window, Same or Mirror, whether the mechanic is used by the double aces, and anything you're unsure about.
