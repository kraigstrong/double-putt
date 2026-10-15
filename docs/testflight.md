# Double Putt on TestFlight

How to get a Double Putt beta to friends, and what each build was. Modeled on Bigger Fish's TestFlight doc.

## Before the first build

### In this repo
- [ ] **App icon without an alpha channel.** App Store Connect rejects icons that have one.
- [ ] **Privacy manifest** (`MiniGolf/PrivacyInfo.xcprivacy`): UserDefaults for saved progress and settings
  (reason CA92.1), and anonymous gameplay counts (product interaction, not linked to the player, not tracking).
- [ ] **`ITSAppUsesNonExemptEncryption = NO`**: the only encryption is the system's HTTPS, so App Store Connect
  won't ask the export-compliance question on each upload.
- [ ] **Bundle ID `com.kraigstrong.doubleputt`** (team `MKACSCQ588`, automatic signing). Permanent once the App
  Store Connect record exists. A phone that ran the old `com.kraig.minigolf` builds gets this as a separate app,
  so its local progress doesn't carry over.
- [ ] **Debug tools in Debug builds only**: dev mode (long-press the logo: every course open, Show Ace, full-path
  guide, Reset), the debug launch arguments and the mechanic test pairs. TestFlight and App Store builds play the
  real unlock flow.
- [ ] **The screen stays awake while playing** (aiming can take longer than auto-lock), and sleeps normally on
  the menus.
- [ ] **Coming back to the app shows the pause menu** if a pair was in play.
- [ ] **Settings screen** from the title: Sound, How to Play, Privacy Policy, Support, and the version.
- [ ] **Anonymous gameplay counts** (see `docs/analytics.md`): per-pair difficulty and the course funnel, no
  names or device IDs, tagged `debug` / `testflight` / `appstore`.
- [ ] **CI builds the Release configuration**, so an archive can't fail on code only Debug builds hide.
- Version 0.1, build 1 (Xcode's "Manage Version and Build Number" bumps the build on each upload).
- iPhone only, portrait, full screen. Sound follows the silent switch (ambient), so it never surprises anyone.

### In BrightBench (a separate session)
- [ ] `brightbench.app/api/double-putt/events`: validates batches against `docs/analytics.md` and keeps daily
  counters, like Bigger Fish's endpoint.
- [ ] `brightbench.app/double-putt/stats`: the counts, by build and channel.
- [ ] `brightbench.app/double-putt/privacy`: the privacy policy (no account, progress stays on the device,
  anonymous gameplay counts).

### In App Store Connect (you)
- [ ] **App record.** Apps, + New App: iOS, name Double Putt (pick a fallback in case it's taken, e.g. "Double
  Putt Mini Golf"), bundle ID `com.kraigstrong.doubleputt` (archiving once with automatic signing registers it),
  SKU `doubleputt`, category Games > Puzzle (or Sports).
- [ ] **Privacy:** the policy URL above, and App Privacy: Product Interaction, used for Analytics, not linked to
  the user, not used for tracking.

## Uploading a build
1. Check out `main` at the commit you want and tag it (`double-putt-v0.1-beta.1`).
2. In Xcode, choose the MiniGolf scheme and Any iOS Device (arm64), then Product > Archive.
3. In the Organizer: Distribute App > App Store Connect > Upload, with "Manage Version and Build Number" on.
4. When it finishes processing, add yourself to an internal group, install from TestFlight, and run the smoke
   check below.
5. Create an external group (Friends), fill in Test Information (below), add the build and submit it for beta
   review (the first build of a version is reviewed). Then invite by email or public link.
6. Record it in the build log at the end of this file.

## Smoke check on the TestFlight build
On a physical iPhone, with a fresh install (and later, as an update over the previous build):
- The title shows; How to Play runs on Twins for a first-time player.
- Courses lists six courses; Daybreak and Nightfall are open, Thunderhead to Fireworks locked until the previous
  course has a medal. Long-pressing the logo does nothing (no dev mode).
- Play a few pairs in a round: strokes show as numbers when balls drop; the result card shows the pair's verdict;
  finishing a round shows the scorecard and medal, and a medal on Nightfall unlocks Thunderhead.
- Single Hole plays any open pair; a double ace shows NEW TROPHY and lands on the Trophy Shelf.
- Progress survives force-quitting and reopening.
- The screen doesn't dim while aiming; it sleeps normally on the title screen.
- Background the app mid-pair: on return the pause menu is up and nothing moved while away.
- Sound off in Settings and the pause menu is remembered; with the phone on silent there's no sound.
- Settings shows the version, and Privacy Policy and Support open in Safari.

## Test Information (paste into App Store Connect)

**Beta App Description**

> Double Putt is mini golf with a twist: every swing plays two holes at once. Line up one putt, and both balls
> roll. Choose Same to send them the same way, or Mirror to flip the second ball's shot. Each pair of holes is a
> little puzzle: find the one swing that drops both balls for a double ace. Six courses of nine pairs take you
> from a spring meadow to a castle moat, a desert canyon, a winter village, and a funfair with springboards,
> carousels and fireworks.

**What to Test**

> Thanks for playing! We'd love to hear which pairs felt too hard or too easy (and roughly how many tries they
> took), whether any hint or mechanic was confusing, and any bugs, crashes or sound problems. To send feedback,
> take a screenshot while playing and share it with TestFlight, or use Send Beta Feedback in the TestFlight app.
> The beta sends anonymous gameplay counts, like which pairs were finished and in how many strokes, with no names
> or device IDs.

**Beta App Review notes:** No account or sign-in. Tap Courses, pick Daybreak, drag back to aim, then tap Putt.

## Build log

| Build | Date | Source commit | Notes |
|---|---|---|---|
