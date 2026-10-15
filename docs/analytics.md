# Double Putt analytics

Anonymous gameplay counts, modeled on Bigger Fish's (`bigger-fish/BiggerFish/ArcadeAnalytics.swift` and
BrightBench's `apps/marketing/src/lib/bigger-fish-analytics.ts`). They answer two questions: **which pairs are too
hard or too easy** for real players (strokes against par, attempts, double aces), and **how players move through
the courses** (rounds started and finished, medals, unlocks, where they stop).

No user, install, session or device IDs and no client timestamps are ever sent. Per-install facts (first launch,
which pairs this install has finished, attempt counts) are kept on the device only, to decide what to send.

This file is the contract between the app (`MiniGolf/Game/Analytics.swift`) and the server
(`brightbench.app/api/double-putt/events`). Change both together, and bump `schema` for any breaking change.

## Transport
- `POST https://brightbench.app/api/double-putt/events`, `Content-Type: application/json`,
  header `X-App-Key: double-putt-gameplay-v1` (a public noise filter, not authentication; strict validation is
  the protection).
- Body: one batch, at most 64 KB. A batch the server can't fully validate is rejected whole (400), so the app
  must never send a field or value this file doesn't allow.
- Events are queued on the device (at most 100) and sent at most 25 per batch, after a pair or round ends and
  when the app goes to the background. Delivery is at most once: the queue is cleared before sending and failed
  batches are dropped, never retried.

```json
{ "schema": 1, "appVersion": "0.1", "build": "1", "channel": "testflight", "events": [ ... ] }
```

| Field | Rule |
|---|---|
| `schema` | `1` |
| `appVersion` | `^\d{1,3}\.\d{1,3}(\.\d{1,3})?$` |
| `build` | `^\d{1,9}$` |
| `channel` | `debug` (an Xcode build), `testflight` or `appstore` |
| `events` | 1–25 events, each one of the kinds below, with exactly the listed fields (optional ones may be absent) |

## Shared values
- **`revision`**: the course content's revision, `^[a-zA-Z0-9.-]{1,48}$` (e.g. `2026-10-15.1`). Bumped whenever
  any pair's layout, par or order changes, so counts never mix two versions of a pair.
- **`course`**: a course id, `^[a-z][a-z0-9-]{0,31}$` (`daybreak`, `nightfall`, `thunderhead`, `midway`, `bigtop`,
  `fireworks`, and future ones). Not a fixed list on the server.
- **Pair context** `{ course, pair, slug, revision }`: `pair` is its number in the course, integer 1–9; `slug` is
  its name in kebab case, `^[a-z][a-z0-9-]{0,47}$` (`twins`, `human-cannonball`).
- **`mode`**: `round` (played in a course round) or `single` (Single Hole).

## Events

### `milestone` (once per install each)
```json
{ "kind": "milestone", "name": "first_launch" }
{ "kind": "milestone", "name": "course_unlocked", "course": "thunderhead", "revision": "2026-10-15.1" }
{ "kind": "milestone", "name": "pair_finished", "context": { ... } }
{ "kind": "milestone", "name": "trophy_won", "context": { ... } }
```
- `first_launch`: no other fields.
- `course_unlocked`: `course` and `revision`; sent when a medal opens the next course (not for dev mode, and not
  for Daybreak or Nightfall, which are open from the start).
- `pair_finished`: `context`; the first time this install finishes the pair, in either mode.
- `trophy_won`: `context`; the first double ace on the pair (its trophy).

### `pair` (one per attempt at a pair)
An attempt starts when a pair loads (fresh, Retry or Restart Pair) and counts once a swing is taken: loading a pair
and leaving without swinging sends nothing and isn't numbered.
```json
{ "kind": "pair", "context": { "course": "midway", "pair": 2, "slug": "springboard", "revision": "2026-10-15.1" },
  "mode": "round", "outcome": "finished", "replay": false, "attempt": 1,
  "strokes": [2, 3], "par": 5, "swings": 3, "mirrorSwings": 1, "water": 0, "aces": 0, "doubleAce": false,
  "seconds": 84 }
```
| Field | Rule |
|---|---|
| `outcome` | `finished` (both balls in), `quit` (Restart Pair, leaving the round or Single Hole, or moving on), `abandoned` (the app was closed mid-pair; sent on the next launch) |
| `replay` | `true` if this install had already finished the pair before this attempt |
| `attempt` | integer 0–1000: `0` on a replay; otherwise this attempt's number among this install's attempts at the pair before its first finish (1 = first try); always `0` exactly when `replay` |
| `strokes` | two integers 0–99, hole A then hole B (each includes water penalties); both ≥ 1 when `finished` |
| `par` | integer 2–12, the pair's par |
| `swings` | integer 0–200, swings taken |
| `mirrorSwings` | integer 0–`swings`, swings taken in Mirror |
| `water` | integer 0–200, water penalties across both holes |
| `aces` | integer 0–2, holes made in one stroke |
| `doubleAce` | boolean, `true` only if `finished` with strokes `[1, 1]` |
| `seconds` | integer 0–3600, time on the pair, rounded and capped |

### `round` (course rounds)
```json
{ "kind": "round", "action": "started", "course": "daybreak", "revision": "2026-10-15.1", "first": true }
{ "kind": "round", "action": "left", "course": "daybreak", "revision": "2026-10-15.1", "pair": 4 }
{ "kind": "round", "action": "finished", "course": "daybreak", "revision": "2026-10-15.1",
  "strokes": 41, "par": 40, "medal": "none", "best": true }
```
| Field | Rule |
|---|---|
| `action` | `started` (a new round), `left` (Leave Round, or a new round replacing an unfinished one), `finished` (the scorecard) |
| `first` | `started` only: `true` the first time this install starts a round of this course |
| `pair` | `left` only: integer 1–9, the pair the round was on |
| `strokes` | `finished` only: integer 9–999, the round's total |
| `par` | `finished` only: integer 18–108, the course par |
| `medal` | `finished` only: `none`, `bronze`, `silver` or `gold` |
| `best` | `finished` only: `true` if it's this install's best round of the course |

## What the stats page should show
Per build and channel, for the chosen days (counters kept 90 days):
- **Pairs**, by course and pair: attempts, finishes (first-time and replays), mean strokes over par, the share
  finished at or under par, double aces, mean attempts before a first finish, water per attempt, the share of
  swings in Mirror, and quits. Sort by "strokes over par" to spot the hardest pairs.
- **Courses:** rounds started (and first-time starts), left (by pair, to see where players stop), finished,
  medals, and unlocks.
- **Installs:** first launches.
