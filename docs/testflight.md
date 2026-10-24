# Double Putt on TestFlight

How to get a Double Putt beta to friends, and what each build was. Modeled on Bigger Fish's TestFlight doc.

## Before the first build

### In this repo
- [x] **App icon without an alpha channel.** App Store Connect rejects icons that have one.
- [x] **Privacy manifest** (`MiniGolf/PrivacyInfo.xcprivacy`): UserDefaults for saved progress and settings
  (reason CA92.1), and anonymous gameplay counts (product interaction, not linked to the player, not tracking).
- [x] **`ITSAppUsesNonExemptEncryption = NO`**: the only encryption is the system's HTTPS, so App Store Connect
  won't ask the export-compliance question on each upload.
- [x] **Bundle ID `com.kraigstrong.doubleputt`** (team `MKACSCQ588`, automatic signing). Permanent once the App
  Store Connect record exists. A phone that ran the old `com.kraig.minigolf` builds gets this as a separate app,
  so its local progress doesn't carry over.
- [x] **Debug tools in Debug builds only**: dev mode (long-press the logo: every course open, Show Ace, full-path
  guide, Reset), the debug launch arguments and the mechanic test holes. TestFlight and App Store builds don't
  have them.
- **Every course open in the beta** (`GameModel.betaOpensEveryCourse`), so testers can explore without earning
  medals first. Turn it off before the App Store release to bring the unlocks back.
- [x] **The screen stays awake while playing** (aiming can take longer than auto-lock), and sleeps normally on
  the menus.
- [x] **Coming back to the app shows the pause menu** if a hole was in play.
- [x] **Settings screen** from the title's gear: Sound, Privacy Policy, Support, and the version.
- [x] **Anonymous gameplay counts** (see `docs/analytics.md`): per-hole difficulty and the course funnel, no
  names or device IDs, tagged `debug` / `testflight` / `appstore`.
- [x] **CI builds the Release configuration**, so an archive can't fail on code only Debug builds hide.
- Version 0.1, build 3. Bump the build number (`CURRENT_PROJECT_VERSION`) by one for each upload.
- iPhone only, portrait, full screen. Sound follows the silent switch (ambient), so it never surprises anyone.

### In BrightBench (a separate session)
- [ ] `brightbench.app/api/double-putt/events`: validates batches against `docs/analytics.md` and keeps daily
  counters, like Bigger Fish's endpoint.
- [ ] `brightbench.app/doubleputt/stats`: the counts, by build and channel.
- [ ] `brightbench.app/doubleputt/privacy`: the privacy policy (no account, progress stays on the device,
  anonymous gameplay counts).

### In App Store Connect (you)
- [x] **Bundle ID** `com.kraigstrong.doubleputt`, registered through the API (2026-10-15).
- [ ] **App record.** Apps, + New App: iOS, name "Double Putt: Mini Golf", English (U.S.), bundle ID
  `com.kraigstrong.doubleputt`, SKU `doubleputt`, Full Access. Then category Games > Puzzle (or Sports), and add
  its Apple ID to the "App Store Connect" 1Password Environment as `ASCC_APP_ID_DOUBLE_PUTT` (`push.py check`
  lists it).
- [ ] **Privacy:** the policy URL above, and App Privacy: Product Interaction, used for Analytics, not linked to
  the user, not used for tracking.

## Uploading a build
Below, `B` is this upload's build number (`CURRENT_PROJECT_VERSION`, bumped by one in a PR first).

1. Check out `main` at the commit you want and tag it `double-putt-v0.1-beta.B` (`double-putt-v0.1-beta.3` for
   build 3).
2. Archive and upload: in Xcode, the MiniGolf scheme and Any iOS Device (arm64), Product > Archive, then in the
   Organizer, Distribute App > App Store Connect > Upload. Or from the command line, with the Apple ID Xcode is
   signed in with:
   ```bash
   B=3
   xcodebuild archive -project MiniGolf.xcodeproj -scheme MiniGolf -configuration Release \
     -destination 'generic/platform=iOS' -archivePath .build/archives/DoublePutt-0.1-$B.xcarchive
   xcodebuild -exportArchive -archivePath .build/archives/DoublePutt-0.1-$B.xcarchive \
     -exportOptionsPlist .build/ExportOptions.plist -exportPath .build/export -allowProvisioningUpdates
   ```
   where `ExportOptions.plist` has `method` `app-store-connect`, `destination` `upload` and `teamID` `MKACSCQ588`.
   Bump the build number (`CURRENT_PROJECT_VERSION`) for each upload.
3. Set the test information and the build's What to Test from `appstore/double-putt/testflight/` (see
   [appstore/README.md](../appstore/README.md)); dry-run first:
   ```bash
   python3 appstore/push.py testflight --app double-putt --build $B --dry-run
   ```
   The first run also creates the Internal group (every build) and the Friends group.
4. When it finishes processing, install from TestFlight as an internal tester and run the smoke check below.
5. Send it to Friends: `--build $B --submit` adds it to the group and submits it for Beta App Review (the first
   build of each version is reviewed), and turns on Friends' public link, which it prints. Share the link, or
   invite with `--invite EMAIL`. Anyone who opens the link before the build is approved is told to wait.
6. Record it in the build log at the end of this file.

## Smoke check on the TestFlight build
On a physical iPhone, with a fresh install (and later, as an update over the previous build):
- The home screen shows the app icon with the mallet behind two balls.
- The title shows; How to Play runs on Twins for a first-time player.
- Courses lists every course but City Muni (Debug builds only), all open while the beta switch is on. With it off, Daybreak and Nightfall are open
  and the rest locked until the previous course has a medal. Long-pressing the logo does nothing (no dev mode).
- Play a few holes in a round: strokes show as numbers when balls drop; the result card shows the hole's verdict;
  finishing a round shows the scorecard and medal, and (beta switch off) a medal on Nightfall unlocks Thunderhead.
- Free Play shows a row per course that swipes sideways, and keeps each row where you left it until the app quits.
  It plays any open hole; a double ace shows NEW TROPHY and lands on the Trophy Shelf.
- A round has no restart, in the top bar or the pause menu; Free Play still has Retry and Restart Hole.
- Progress survives force-quitting and reopening.
- The screen doesn't dim while aiming; it sleeps normally on the title screen.
- Background the app mid-hole: on return the pause menu is up and nothing moved while away.
- Sound off in Settings and the pause menu is remembered; with the phone on silent there's no sound.
- Settings shows the version, and Privacy Policy and Support open in Safari.
- The Links: the slope grid and its dots show on green and fringe only; on Two Tiers a soft putt up the false
  front rolls back down; Bandon naps beside Fescue.
- The Stadium: on Grandstand a ball banks off the stands like a wall.
- Starbase: a robot bounces the ball like a bumper; a lit force field is a wall and a dark one lets the ball
  through; robots and fields keep moving while you aim.

## Test Information
The Beta App Description and What to Test are in `appstore/double-putt/testflight/en-US/`, and the Beta App Review
notes in `appstore/double-putt/testflight/review_notes.txt`. Edit them there and push them with `push.py testflight`.
The feedback email and the review contact are personal, so they come from the 1Password Environment, not the repo.

## Build log

| Build | Date | Source commit | Notes |
|---|---|---|---|
| 0.1 (1) | 2026-10-15 | `d146919` | First upload: six courses, analytics. Uploaded with `xcodebuild -exportArchive`. Internal testing, then submitted for external beta review with Friends' public link on (2026-10-15). |
| 0.1 (2) | 2026-10-17 | `6a2cc8c` (tag `double-putt-v0.1-beta.2`) | The Links (course 7), every course open for the beta, rounds without restart. Uploaded with `xcodebuild -exportArchive`; What to Test set and submitted to Friends for beta review with `push.py testflight --build 2 --submit`. Fog Bank is the 2% window version. |
| 0.1 (3) | 2026-10-19 | `2229304` (tag `double-putt-v0.1-beta.3`) | The Stadium (course 9) and Starbase (course 10), the new app icon, Free Play's swipe rows, and Fog Bank reworked to a 5% window. City Muni stays Debug-only. `xcodebuild -exportArchive` failed with "Failed to Use Accounts" (no Xcode account with App Store Connect access for the team, even after signing in again), and the App Store Connect API key's App Manager role can't cloud-sign, so it was uploaded from Xcode's Organizer. What to Test set and submitted to Friends with `push.py testflight --build 3 --submit`; beta review approved right away. |
