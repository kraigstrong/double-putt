# Double Putt analytics

Anonymous gameplay counts, modeled on Bigger Fish's (`bigger-fish/BiggerFish/ArcadeAnalytics.swift` and
BrightBench's `apps/marketing/src/lib/bigger-fish-analytics.ts`). They answer two questions: **which holes are too
hard or too easy** for real players (strokes against par, attempts, double aces), **how players move through
the courses** (rounds started and finished, medals, where they stop), and **where the purchase screen is seen**
(never whether anything was bought: App Store Connect counts sales).

No user, install, session or device IDs and no client timestamps are ever sent. Per-install facts (first launch,
which holes this install has finished, attempt counts) are kept on the device only, to decide what to send.

This file is the contract between the app (`MiniGolf/Game/Analytics.swift`) and the server
(`brightbench.app/api/double-putt/events`). Change both together, and bump `schema` for any breaking change.

## Transport
- `POST https://brightbench.app/api/double-putt/events`, `Content-Type: application/json`,
  header `X-App-Key: double-putt-gameplay-v1` (a public noise filter, not authentication; strict validation is
  the protection).
- Body: one batch, at most 64 KB. A batch the server can't fully validate is rejected whole (400), so the app
  must never send a field or value this file doesn't allow.
- Events are queued on the device (at most 100) and sent at most 25 per batch: when 25 are waiting, when the app
  goes to the background, and at launch, not after every hole (each send is a billed Redis write on the server, and
  the same counters in one batch are added up into one). Simulator builds never collect. Delivery is at most once:
  the queue is cleared before sending and failed batches are dropped, never retried.

```json
{ "schema": 2, "appVersion": "0.1", "build": "1", "channel": "testflight", "events": [ ... ] }
```

| Field | Rule |
|---|---|
| `schema` | `2` (or `1`, from older builds: see [Schema 1](#schema-1)) |
| `appVersion` | `^\d{1,3}\.\d{1,3}(\.\d{1,3})?$` |
| `build` | `^\d{1,9}$` |
| `channel` | `debug` (an Xcode build), `testflight` or `appstore` |
| `events` | 1–25 events, each one of the kinds below, with exactly the listed fields (optional ones may be absent) |

## Shared values
- **`revision`**: the course content's revision, `^[a-zA-Z0-9.-]{1,48}$` (e.g. `2026-10-15.1`). Bumped whenever
  any hole's layout, par or order changes, so counts never mix two versions of a hole.
- **`course`**: a course id, `^[a-z][a-z0-9-]{0,31}$` (`daybreak`, `nightfall`, `thunderhead`, `midway`, `bigtop`,
  `fireworks`, and future ones). Not a fixed list on the server.
- **Hole context** `{ course, hole, slug, revision }`: `hole` is its number in the course, integer 1–9; `slug` is
  its name in kebab case, `^[a-z][a-z0-9-]{0,47}$` (`twins`, `human-cannonball`).
- **`mode`**: `round` (played in a course round) or `single` (Free Play).

## Events

### `milestone` (once per install each)
```json
{ "kind": "milestone", "name": "first_launch" }
{ "kind": "milestone", "name": "course_unlocked", "course": "thunderhead", "revision": "2026-10-15.1" }
{ "kind": "milestone", "name": "hole_finished", "context": { ... } }
{ "kind": "milestone", "name": "trophy_won", "context": { ... } }
```
- `first_launch`: no other fields.
- `course_unlocked`: `course` and `revision`; sent by builds before 1.0 when a medal opened the next course, or would
  have in the beta, which opened every course. From 1.0 every course is open and it's never sent; the server still
  takes it from older builds.
- `hole_finished`: `context`; the first time this install finishes the hole, in either mode. A hole whose
  `pair_finished` an older build already sent isn't sent again.
- `trophy_won`: `context`; the first double ace on the hole (its trophy).

### `hole` (one per attempt at a hole)
An attempt starts when a hole loads (fresh, or Retry or Restart Hole in Free Play) and counts once a swing is taken: loading a hole
and leaving without swinging sends nothing and isn't numbered.
```json
{ "kind": "hole", "context": { "course": "midway", "hole": 2, "slug": "springboard", "revision": "2026-10-15.1" },
  "mode": "round", "outcome": "finished", "replay": false, "attempt": 1,
  "strokes": [2, 3], "par": 5, "swings": 3, "mirrorSwings": 1, "water": 0, "aces": 0, "doubleAce": false,
  "seconds": 84 }
```
| Field | Rule |
|---|---|
| `outcome` | `finished` (both balls in), `quit` (Restart Hole in Free Play, leaving the round or Free Play, or moving on), `abandoned` (the app was closed mid-hole; sent on the next launch) |
| `replay` | `true` if this install had already finished the hole before this attempt |
| `attempt` | integer 0–1000: `0` on a replay; otherwise this attempt's number among this install's attempts at the hole before its first finish (1 = first try); always `0` exactly when `replay` |
| `strokes` | two integers 0–99, green A then green B (each includes water penalties); both ≥ 1 when `finished` |
| `par` | integer 2–12, the hole's par |
| `swings` | integer 0–200, swings taken |
| `mirrorSwings` | integer 0–`swings`, swings taken in Mirror |
| `water` | integer 0–200, water penalties across both greens |
| `aces` | integer 0–2, greens made in one stroke: when `finished`, exactly the number of 1s in `strokes`; otherwise at most that number |
| `doubleAce` | boolean, `true` exactly when `finished` with strokes `[1, 1]` |
| `seconds` | integer 0–3600, time on the hole, rounded and capped |

### `round` (course rounds)
```json
{ "kind": "round", "action": "started", "course": "daybreak", "revision": "2026-10-15.1", "first": true }
{ "kind": "round", "action": "left", "course": "daybreak", "revision": "2026-10-15.1", "hole": 4 }
{ "kind": "round", "action": "finished", "course": "daybreak", "revision": "2026-10-15.1",
  "strokes": 41, "par": 40, "medal": "none", "best": true }
```
| Field | Rule |
|---|---|
| `action` | `started` (a new round), `left` (Leave Round, or a new round replacing an unfinished one), `finished` (the scorecard) |
| `first` | `started` only: `true` the first time this install starts a round of this course |
| `hole` | `left` only: integer 1–9, the hole the round was on |
| `strokes` | `finished` only: integer 9–999, the round's total |
| `par` | `finished` only: integer 18–108, the course par |
| `medal` | `finished` only: `none`, `bronze`, `silver` or `gold` |
| `best` | `finished` only: `true` if it's this install's best round of the course |

### `unlock` (the purchase screen opened)
```json
{ "kind": "unlock", "source": "free_hole", "course": "midway", "first": false }
{ "kind": "unlock", "source": "settings", "first": true }
```
| Field | Rule |
|---|---|
| `source` | what opened it: `scorecard` (a finished round's Up next), `free_hole` (a free hole's result card), `course` (a locked course on Courses), `hole` (a locked hole in Free Play), `trophy` (a locked hole on the Trophy Shelf), `settings` (Unlock All Holes), `round` (Continue on a round of a locked course) |
| `course` | the course it was opened about: present for every source but `settings`, and absent for `settings`. For `scorecard` it's the round just finished |
| `first` | `true` the first time this install sees the purchase screen, from anywhere |

Schema 2 only. Nothing about the purchase itself (bought, cancelled, restored) is ever sent, so the App Privacy label
stays Product Interaction only. An event whose `course` doesn't fit its `source` isn't sent, since the server would
turn away its whole batch.

## Schema 1
TestFlight builds 1–3 called a hole a pair, and send `"schema": 1` with every other rule the same:
`"kind": "pair"`, a context of `{ course, pair, slug, revision }`, `"name": "pair_finished"`, and `pair` on a
round's `left`. The server accepts both schemas, though not mixed in one batch, and counts them together. Events
an older build queued but hadn't sent when the app updated are dropped (delivery is at most once anyway).

## What the stats page should show
Per build and channel, for the chosen days (counters kept 90 days):
- **Holes**, by course and hole: attempts, finishes (first-time and replays), mean strokes over par, the share
  finished at or under par, double aces, mean attempts before a first finish, water per attempt, the share of
  swings in Mirror, and quits. Sort by "strokes over par" to spot the hardest holes.
- **Courses:** rounds started (and first-time starts), left (by hole, to see where players stop), finished,
  medals, and (from builds before 1.0) unlocks.
- **Purchase screen:** views and first views by source and by course, to set against App Store Connect's sales.
- **Installs:** first launches.
