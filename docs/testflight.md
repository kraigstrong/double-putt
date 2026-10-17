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
  guide, Reset), the debug launch arguments and the mechanic test pairs. TestFlight and App Store builds play the
  real unlock flow.
- [x] **The screen stays awake while playing** (aiming can take longer than auto-lock), and sleeps normally on
  the menus.
- [x] **Coming back to the app shows the pause menu** if a pair was in play.
- [x] **Settings screen** from the title's gear: Sound, Privacy Policy, Support, and the version.
- [x] **Anonymous gameplay counts** (see `docs/analytics.md`): per-pair difficulty and the course funnel, no
  names or device IDs, tagged `debug` / `testflight` / `appstore`.
- [x] **CI builds the Release configuration**, so an archive can't fail on code only Debug builds hide.
- Version 0.1, build 1 (Xcode's "Manage Version and Build Number" bumps the build on each upload).
- iPhone only, portrait, full screen. Sound follows the silent switch (ambient), so it never surprises anyone.

### In BrightBench (a separate session)
- [ ] `brightbench.app/api/double-putt/events`: validates batches against `docs/analytics.md` and keeps daily
  counters, like Bigger Fish's endpoint.
- [ ] `brightbench.app/double-putt/stats`: the counts, by build and channel.
- [ ] `brightbench.app/double-putt/privacy`: the privacy policy (no account, progress stays on the device,
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
1. Check out `main` at the commit you want and tag it (`double-putt-v0.1-beta.1`).
2. Archive and upload: in Xcode, the MiniGolf scheme and Any iOS Device (arm64), Product > Archive, then in the
   Organizer, Distribute App > App Store Connect > Upload. Or from the command line, with the Apple ID Xcode is
   signed in with:
   ```bash
   xcodebuild archive -project MiniGolf.xcodeproj -scheme MiniGolf -configuration Release \
     -destination 'generic/platform=iOS' -archivePath .build/archives/DoublePutt-0.1-1.xcarchive
   xcodebuild -exportArchive -archivePath .build/archives/DoublePutt-0.1-1.xcarchive \
     -exportOptionsPlist .build/ExportOptions.plist -exportPath .build/export -allowProvisioningUpdates
   ```
   where `ExportOptions.plist` has `method` `app-store-connect`, `destination` `upload` and `teamID` `MKACSCQ588`.
   Bump the build number (`CURRENT_PROJECT_VERSION`) for each upload.
3. Set the test information and the build's What to Test from `appstore/double-putt/testflight/` (see
   [appstore/README.md](../appstore/README.md)); dry-run first:
   ```bash
   python3 appstore/push.py testflight --app double-putt --build 1 --dry-run
   ```
   The first run also creates the Internal group (every build) and the Friends group.
4. When it finishes processing, install from TestFlight as an internal tester and run the smoke check below.
5. Send it to Friends: `--build 1 --submit` adds it to the group and submits it for Beta App Review (the first
   build of each version is reviewed), and turns on Friends' public link, which it prints. Share the link, or
   invite with `--invite EMAIL`. Anyone who opens the link before the build is approved is told to wait.
6. Record it in the build log at the end of this file.

## Smoke check on the TestFlight build
On a physical iPhone, with a fresh install (and later, as an update over the previous build):
- The title shows; How to Play runs on Twins for a first-time player.
- Courses lists six courses; Daybreak and Nightfall are open, Thunderhead to Fireworks locked until the previous
  course has a medal. Long-pressing the logo does nothing (no dev mode).
- Play a few pairs in a round: strokes show as numbers when balls drop; the result card shows the pair's verdict;
  finishing a round shows the scorecard and medal, and a medal on Nightfall unlocks Thunderhead.
- Free Play plays any open pair; a double ace shows NEW TROPHY and lands on the Trophy Shelf.
- Progress survives force-quitting and reopening.
- The screen doesn't dim while aiming; it sleeps normally on the title screen.
- Background the app mid-pair: on return the pause menu is up and nothing moved while away.
- Sound off in Settings and the pause menu is remembered; with the phone on silent there's no sound.
- Settings shows the version, and Privacy Policy and Support open in Safari.
- The Links: the slope grid and its dots show on green and fringe only; on Two Tiers a soft putt up the false
  front rolls back down; Bandon naps beside Fescue.

## Test Information
The Beta App Description and What to Test are in `appstore/double-putt/testflight/en-US/`, and the Beta App Review
notes in `appstore/double-putt/testflight/review_notes.txt`. Edit them there and push them with `push.py testflight`.
The feedback email and the review contact are personal, so they come from the 1Password Environment, not the repo.

## Build log

| Build | Date | Source commit | Notes |
|---|---|---|---|
| 0.1 (1) | 2026-10-15 | `d146919` | First upload: six courses, analytics. Uploaded with `xcodebuild -exportArchive`. Internal testing, then submitted for external beta review with Friends' public link on (2026-10-15). |
