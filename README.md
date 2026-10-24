# Double Putt

[![CI](https://github.com/kraigstrong/double-putt/actions/workflows/ci.yml/badge.svg)](https://github.com/kraigstrong/double-putt/actions/workflows/ci.yml)

Mini golf where one swing plays two greens. Every swing hits both balls with the same shot — or, with **Mirror**,
green B's ball gets the shot flipped left-to-right.

## Run it

Open `MiniGolf.xcodeproj` in Xcode and run, or from the terminal:

```bash
xcodebuild -project MiniGolf.xcodeproj -scheme MiniGolf -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath .build/DerivedData build
```

## How to play

- **Courses** lists the nine-hole courses: Daybreak, Nightfall, Thunderhead, then the Funfair set (Midway, Big Top,
  Fireworks), then the putting courses of slopes and surfaces (The Links, City Muni, The Stadium), then Starbase, a
  space station of patrol robots and force fields, each harder than the last. A round shows a running score vs par
  and ends with a scorecard and a medal: bronze at par or better, silver 4 under, gold 8 under (best round per course
  saved; a round in progress survives relaunches). A medal unlocks the next course; for now, in the beta, every course
  is open.
- **Free Play** plays any hole on its own: each course is a row you swipe to pick a hole. A double ace on a hole, in
  a round or not, wins its trophy on the **Trophy Shelf** (one per hole).
- **Drag anywhere** and pull back to aim. The aim stays when you let go — re-drag as often as you like.
- **‹ ›** nudge the aim (hold to repeat). Drag the **power bar** or use its **+ / −**.
- **Same / Mirror** picks how the swing maps onto green B's ball. **Putt** fires — nothing fires by accident.
- The guide shows each ball's direction and first bounce (or tunnel) only — never where it stops. It runs straight
  over slopes (reading them is your job) and reaches further the firmer you putt.
- Any ball can drop in any cup (one ball per cup). Water = +1 and the ball goes back.
- Each green is scored on its own; a hole's par is the sum of its two greens' pars (2 or 3 each).
- A round is played as it lies: there's no restarting a hole. Free Play has Retry and Restart Hole.

Mechanics: walls and planters, bumpers, water, gaps/shared greens, two-way **tunnels** (color-coded mouths,
optional exit direction), **slopes** and round **hills / bowls**, smooth **contours** (tilts, tiers, humps and
hollows that blend into one green), **surfaces** (curvy or angled greens shaped by fringe, rough, sand and ponds,
each slowing the ball differently, and **cart paths** that run faster than the green), **grandstands** you bank off
like a wall, **movers** (windmill rotors, sliding blocks, and on Starbase patrol **robots** you bounce off like
bumpers and **force fields** that are a wall while lit and open while dark) that
never stop, so when you putt matters as much as how, and from Midway on, **kicker pads** (springboards that launch the
ball a set way at a set speed) and **carousels** (spinning disks that drag the ball along with them). A ball that stops
in a mover's path or on a carousel slides to the nearest clear spot that's no nearer a cup. Sloped ground shows a grid
tinted from blue (low) to red (high), with dots gliding along it downhill, faster where it's steeper.

In Debug (Xcode) builds, long-press the title logo to toggle **dev mode** (every course unlocked; pause menu gets a
full-path guide toggle, Show Ace and Reset). TestFlight and App Store builds don't have it.

The title's gear opens **Settings**: sound, the privacy policy and support pages, and the version. The game sends
anonymous gameplay counts (hole difficulty and the course funnel; no names or device IDs) to brightbench.app, as
described in `docs/analytics.md`. `docs/testflight.md` is the beta checklist and upload guide.
Show Ace waits (fast-forwarding a long wait) for the movers to reach the stored solution's timing.

Tap the hole name (the 💡) to bring the hole's hint back; Pause → **How to Play** replays the tips on the hole you're on.

## Layout

| Path | What |
| --- | --- |
| `MiniGolf/Core/` | Deterministic physics (fixed 1/480 s step) and level geometry. Shared with the solver. |
| `MiniGolf/Art/` | Themes and procedural art: every course, tree, ball and the menu art is drawn in code. |
| `MiniGolf/Game/` | SpriteKit scene (camera fit around the HUD, aim, guide, effects) and the SwiftUI HUD. |
| `MiniGolf/Screens/` | Title, Courses, Free Play, Trophy Shelf, scorecard, shared components. |
| `MiniGolf/Audio/Sound.swift` | Synthesized sound effects (no audio assets). |
| `Tools/solver/` | Headless brute-force solver. |
| `Tools/icon/make_icon.swift` | Generates the app icon. |
| `appstore/` | App Store listing and TestFlight text, and `push.py` to send them to App Store Connect. |

## The courses

Each course is nine holes played as a round. Daybreak and Nightfall are open from the start; each later course unlocks
with a medal on the one before (during the beta, `GameModel.betaOpensEveryCourse` opens them all). In the app each course numbers its holes 1–9. The tables come from
`Tools/solve.sh --readme`.

City Muni is still in development: it's in the lineup and the solver checks it, but only Debug builds play it
(`Levels.inDevelopment`). TestFlight and App Store builds skip it.

### Daybreak (par 40)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Twins | Spring Meadow | 4 | Same | — |
| 2 | Reflection | Spring Meadow | 4 | Mirror | — |
| 3 | Bank Shot | Spring Meadow | 5 | Same | — |
| 4 | Backboard | Walled Garden | 4 | Same | — |
| 5 | Hedgerow | Walled Garden | 4 | Mirror | — |
| 6 | Moat | Castle Moat | 6 | Mirror | water |
| 7 | Drawbridge | Castle Moat | 5 | Mirror | water, sliders |
| 8 | Buoys | Seaside Boardwalk | 4 | Mirror | bumpers |
| 9 | Dunes | Seaside Boardwalk | 4 | Same | slopes |

### Nightfall (par 46)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Carom | Autumn Grove | 4 | Mirror | — |
| 2 | Hollow | Autumn Grove | 4 | Same | hills, bowls |
| 3 | Canyon Pipe | Desert Canyon | 5 | Mirror | tunnels |
| 4 | Mesa | Desert Canyon | 4 | Mirror | tunnels, slopes |
| 5 | Windmill | Winter Village | 6 | Mirror | rotors |
| 6 | Sled Run | Winter Village | 6 | Same | water, slopes, sliders |
| 7 | Crossover | Night Garden | 5 | Mirror | — |
| 8 | Lanterns | Night Garden | 6 | Same | water, tunnels, sliders |
| 9 | Midnight | Night Garden | 6 | Mirror | water, tunnels, bowls, rotors |

### Thunderhead (par 48)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Breakwater | Seaside Boardwalk | 5 | Mirror | bumpers, bowls |
| 2 | Tide Pools | Seaside Boardwalk | 5 | Same | water, slopes |
| 3 | Sundial | Walled Garden | 5 | Mirror | rotors |
| 4 | Topiary | Walled Garden | 5 | Mirror | hills |
| 5 | Plateau | Desert Canyon | 5 | Mirror | slopes, bowls |
| 6 | Arroyo | Desert Canyon | 5 | Mirror | tunnels, slopes |
| 7 | Avalanche | Winter Village | 6 | Mirror | water, sliders |
| 8 | Ice Bridge | Winter Village | 6 | Same | water, tunnels, rotors |
| 9 | Thunderclap | Winter Village | 6 | Mirror | water, bumpers, tunnels, bowls, rotors |

### Midway (par 47)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Ring Toss | Midway | 5 | Mirror | water, bumpers |
| 2 | Springboard | Midway | 5 | Mirror | water, kickers |
| 3 | Teacups | Midway | 5 | Same | carousels |
| 4 | Shooting Gallery | Midway | 5 | Mirror | bumpers, sliders |
| 5 | High Striker | Midway | 5 | Same | slopes, kickers |
| 6 | Duck Pond | Midway | 5 | Mirror | water, carousels |
| 7 | Merry-Go-Round | Midway | 6 | Mirror | water, bumpers, carousels, kickers |
| 8 | Bumper Cars | Midway | 5 | Mirror | water, bumpers, sliders |
| 9 | Grand Prize | Midway | 6 | Same | water, tunnels, carousels, kickers |

### Big Top (par 47)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Ringmaster | Big Top | 5 | Mirror | bowls, kickers |
| 2 | Juggler | Big Top | 5 | Same | bumpers, carousels |
| 3 | Trapeze | Big Top | 5 | Mirror | water, sliders |
| 4 | Human Cannonball | Big Top | 5 | Same | water, tunnels, bowls |
| 5 | Tightrope | Big Top | 5 | Mirror | water, slopes, hills |
| 6 | Spinning Plates | Big Top | 5 | Mirror | water, rotors, carousels |
| 7 | Fire Hoop | Big Top | 6 | Same | water, bumpers, sliders, kickers |
| 8 | Clown Car | Big Top | 5 | Mirror | water, tunnels, rotors, kickers |
| 9 | Showstopper | Big Top | 6 | Mirror | water, tunnels, rotors, carousels, kickers |

### Fireworks (par 50)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Sparkler | Fireworks | 5 | Mirror | kickers |
| 2 | Ferris Wheel | Fireworks | 5 | Same | water, bumpers, rotors |
| 3 | Hall of Mirrors | Fireworks | 5 | Same | water |
| 4 | Roman Candle | Fireworks | 5 | Mirror | water, bowls, carousels, kickers |
| 5 | Ghost Train | Fireworks | 6 | Same | tunnels, sliders |
| 6 | Catherine Wheel | Fireworks | 6 | Mirror | water, rotors, carousels, kickers |
| 7 | Rocket | Fireworks | 6 | Same | water, sliders, kickers |
| 8 | Starburst | Fireworks | 6 | Mirror | water, bumpers, tunnels, bowls |
| 9 | Grand Finale | Fireworks | 6 | Mirror | water, tunnels, rotors, carousels, kickers |

### The Links (par 40)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Fescue | Seaside Links | 4 | Same | contours, fringe, rough |
| 2 | Pot Bunker | Seaside Links | 4 | Same | contours, fringe, rough, sand |
| 3 | Punchbowl | Seaside Links | 6 | Same | contours, fringe, rough, ponds |
| 4 | Gorse Line | Seaside Links | 4 | Same | contours, fringe, rough |
| 5 | Two Tiers | Seaside Links | 4 | Mirror | contours, fringe, rough |
| 6 | Sea Wall | Seaside Links | 5 | Same | contours, fringe, rough, sand, ponds |
| 7 | Fog Bank | Seaside Links | 4 | Same | contours, fringe, rough, sand, ponds |
| 8 | Saddle | Seaside Links | 4 | Same | contours, fringe, rough, sand, ponds |
| 9 | Lighthouse | Seaside Links | 5 | Mirror | contours, fringe, rough, sand, ponds |

### City Muni (par 40)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Clubhouse | City Muni | 5 | Same | contours, fringe, rough, sand, cart paths |
| 2 | Cart Path | City Muni | 4 | Mirror | contours, fringe, rough, cart paths |
| 3 | Ball Washer | City Muni | 5 | Same | contours, fringe, rough, cart paths |
| 4 | Water Tower | City Muni | 4 | Same | contours, fringe, rough, sand, cart paths |
| 5 | Chain Link | City Muni | 4 | Mirror | contours, fringe, rough, cart paths |
| 6 | Twilight Rate | City Muni | 4 | Same | contours, fringe, rough, cart paths |
| 7 | Skyline | City Muni | 4 | Mirror | contours, fringe, rough, cart paths |
| 8 | Practice Green | City Muni | 5 | Same | contours, fringe, rough, sand, cart paths |
| 9 | Last Call | City Muni | 5 | Mirror | contours, fringe, rough, sand, cart paths |

### The Stadium (par 48)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | First Tee | Stadium Course | 6 | Same | contours, fringe, rough, ponds |
| 2 | Pine Straw | Stadium Course | 6 | Mirror | contours, fringe, rough, sand |
| 3 | Grandstand | Stadium Course | 6 | Same | stands, contours, fringe, rough, ponds |
| 4 | Gallery | Stadium Course | 4 | Mirror | contours, fringe, rough |
| 5 | Railroad Ties | Stadium Course | 6 | Mirror | contours, fringe, rough, sand, ponds |
| 6 | Amphitheater | Stadium Course | 4 | Mirror | stands, contours, fringe, rough, ponds |
| 7 | Creek | Stadium Course | 5 | Same | contours, fringe, rough, ponds |
| 8 | Palm Row | Stadium Course | 5 | Same | contours, fringe, rough, sand, ponds |
| 9 | Island Green | Stadium Course | 6 | Mirror | stands, contours, fringe, rough, ponds |

### Starbase (par 44)

| # | Hole | Setting | Par | Double ace needs | Mechanics |
| --- | --- | --- | --- | --- | --- |
| 1 | Docking Bay | Starbase | 4 | Mirror | robots |
| 2 | Airlock | Starbase | 5 | Same | water, force fields |
| 3 | Patrol Route | Starbase | 5 | Mirror | robots |
| 4 | Teleporter | Starbase | 5 | Same | water, tunnels, force fields |
| 5 | Conveyor Deck | Starbase | 6 | Mirror | slopes, force fields |
| 6 | Tractor Beam | Starbase | 4 | Mirror | water, bowls, robots, kickers |
| 7 | Reactor Core | Starbase | 5 | Mirror | water, hills, rotors, force fields |
| 8 | Laser Grid | Starbase | 5 | Mirror | water, force fields |
| 9 | Mothership | Starbase | 5 | Same | water, tunnels, slopes, robots, force fields |

The lineup is `Levels.lineup` in `MiniGolf/Core/Levels.swift`; holes live there and in `MiniGolf/Core/Course/`. To add a
course, follow `Tools/levels/BRIEF.md`, the course design playbook (difficulty targets, asymmetry, solver workflow).

## Solver

```bash
Tools/solve.sh              # double-ace / single-ace / water stats for every hole
Tools/solve.sh moat         # one hole
Tools/solve.sh --verify     # stored solutions still double-ace; tees clear; 9 holes per course; unique names
Tools/solve.sh --report --course thunderhead   # one line per hole: difficulty, window, par check, mechanics
Tools/solve.sh --readme     # the course tables below, as markdown
Tools/solve.sh twins --probe 90         # outcome at every power for one angle
Tools/solve.sh --timing                 # mover holes: how exact the putt's timing must be
LEVELS=Tools/levels/draft.swift Tools/solve.sh --drafts   # a scratch file defining `Levels.drafts`
```

Run `--verify` after touching `Tuning` or level geometry. The solver strikes every shot at mover clock 0 (the pose
the movers load in); a level's `solutionTime` says when its stored solution is struck.

## Debug launch args (Debug builds)

```bash
xcrun simctl launch booted com.kraigstrong.doubleputt -level 3 -aim 70.25,0.71,mirror -guide full
xcrun simctl launch booted com.kraigstrong.doubleputt -dumpArt 1   # writes course PNGs to the app's Documents/art
```

## Workflow

Changes land on `main` through pull requests, one branch per change, in small focused commits. CI (GitHub Actions,
`.github/workflows/ci.yml`) builds the app and runs `Tools/solve.sh --verify` on every pull request and every push
to `main`.

## License

The source code is under the [PolyForm Noncommercial License 1.0.0](LICENSE): free to read, learn from, and use
for noncommercial purposes, but not in anything commercial. (The license also permits any use by charities,
schools, and public and government institutions; see its Noncommercial Organizations section.) The name
"Double Putt", its logo, and its app icon are all rights reserved.
