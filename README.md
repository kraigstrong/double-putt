# Double Putt

Two mini golf holes, one swing. Every swing hits both balls with the same shot — or, with **Mirror**,
hole B's ball gets the shot flipped left-to-right.

## Run it

Open `MiniGolf.xcodeproj` in Xcode and run, or from the terminal:

```bash
xcodebuild -project MiniGolf.xcodeproj -scheme MiniGolf -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath .build/DerivedData build
```

## How to play

- **Play Round** plays all 18 pairs in order with a running score vs par and a scorecard at the end
  (best round saved; a round in progress survives relaunches). **Course Map** replays any single pair for medals.
- **Drag anywhere** and pull back to aim. The aim stays when you let go — re-drag as often as you like.
- **‹ ›** nudge the aim (hold to repeat). Drag the **power bar** or use its **+ / −**.
- **Same / Mirror** picks how the swing maps onto hole B's ball. **Putt** fires — nothing fires by accident.
- The guide shows each ball's direction and first bounce (or tunnel) only — never where it stops.
- Any ball can drop in any cup (one ball per cup). Water = +1 and the ball goes back.
- Per-hole scoring; each pair's par is the sum of its two holes (2 or 3 each). Medals: gold = double ace,
  silver = under par, bronze = par.

Mechanics: walls and planters, bumpers, water, gaps/shared greens, two-way **tunnels** (color-coded mouths,
optional exit direction), **slopes** and round **hills / bowls**, and **movers** (windmill rotors, sliding blocks)
that never stop, so when you putt matters as much as how. A ball that stops in a mover's path slides to the nearest
clear spot that's no nearer a cup.

Long-press the title logo to toggle **dev mode** (pause menu gets a full-path guide toggle, Show Ace and Reset).
Show Ace waits (fast-forwarding a long wait) for the movers to reach the stored solution's timing.

Tap the pair name (the 💡) to bring the pair's hint back; Pause → **How to Play** replays the tips on the pair you're on.

## Layout

| Path | What |
| --- | --- |
| `MiniGolf/Core/` | Deterministic physics (fixed 1/480 s step) and level geometry. Shared with the solver. |
| `MiniGolf/Art/` | Themes and procedural art: every course, tree, ball and the menu art is drawn in code. |
| `MiniGolf/Game/` | SpriteKit scene (camera fit around the HUD, aim, guide, effects) and the SwiftUI HUD. |
| `MiniGolf/Screens/` | Title, pair select, shared components. |
| `MiniGolf/Audio/Sound.swift` | Synthesized sound effects (no audio assets). |
| `Tools/solver/` | Headless brute-force solver. |
| `Tools/icon/make_icon.swift` | Generates the app icon. |

## The course

| # | Pair | Setting | Par | Double ace needs | Featured |
| --- | --- | --- | --- | --- | --- |
| 1 | Twins | Spring Meadow | 4 | Same | warm-up (tutorial) |
| 2 | Reflection | Spring Meadow | 4 | Mirror | mirror lesson |
| 3 | Bank Shot | Spring Meadow | 5 | Same | banks |
| 4 | Backboard | Walled Garden | 4 | Same | power |
| 5 | Hedgerow | Walled Garden | 4 | Mirror | gaps |
| 6 | Moat | Castle Moat | 6 | Mirror | water |
| 7 | Drawbridge | Castle Moat | 5 | Mirror | slider (gate) |
| 8 | Buoys | Seaside Boardwalk | 4 | Mirror | bumpers |
| 9 | Dunes | Seaside Boardwalk | 4 | Same | slopes |
| 10 | Carom | Autumn Grove | 4 | Mirror | shared green |
| 11 | Hollow | Autumn Grove | 4 | Same | hill + bowl |
| 12 | Canyon Pipe | Desert Canyon | 5 | Mirror | tunnel swap |
| 13 | Mesa | Desert Canyon | 4 | Mirror | slopes + tunnels |
| 14 | Windmill | Winter Village | 6 | Mirror | rotors |
| 15 | Sled Run | Winter Village | 6 | Same | slope + slider |
| 16 | Crossover | Night Garden | 5 | Mirror | gap |
| 17 | Lanterns | Night Garden | 6 | Same | tunnels + sliders |
| 18 | Midnight | Night Garden | 6 | Mirror | finale: tunnels, bowls, clock rotor |

Course par 86. Pairs 1–4, 6, 8, 10 and 16 are in `Levels.swift`; the rest are in `MiniGolf/Core/Course/`.
`Tools/levels/BRIEF.md` is the design brief used to make pairs 5, 7, 9 and 11–18.

## Solver

```bash
Tools/solve.sh              # double-ace / single-ace / water stats for every pair
Tools/solve.sh moat         # one pair
Tools/solve.sh --verify     # every pair's stored solution still double-aces
Tools/solve.sh twins --probe 90         # outcome at every power for one angle
Tools/solve.sh --timing                 # mover pairs: how exact the putt's timing must be
LEVELS=Tools/levels/draft.swift Tools/solve.sh --drafts   # a scratch file defining `Levels.drafts`
```

Run `--verify` after touching `Tuning` or level geometry. The solver strikes every shot at mover clock 0 (the pose
the movers load in); a level's `solutionTime` says when its stored solution is struck.

## Debug launch args (Debug builds)

```bash
xcrun simctl launch booted com.kraig.minigolf -level 3 -aim 70.25,0.71,mirror -guide full
xcrun simctl launch booted com.kraig.minigolf -dumpArt 1   # writes course PNGs to the app's Documents/art
```

## License

The source code is under the [PolyForm Noncommercial License 1.0.0](LICENSE): free to read, learn from, and use
for noncommercial purposes, but not in anything commercial. (The license also permits any use by charities,
schools, and public and government institutions; see its Noncommercial Organizations section.) The name
"Double Putt", its logo, and its app icon are all rights reserved.
