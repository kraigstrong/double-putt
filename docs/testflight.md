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
- [x] **Debug tools in Debug builds only**: dev mode (long-press the logo: every hole playable, Show Ace,
  full-path guide, Reset), the debug launch arguments and the mechanic test holes. TestFlight and App Store builds don't
  have them.
- [x] **Free to try** (1.0): Daybreak and one hole of every other course are free, and one non-consumable, All
  Courses (`com.kraigstrong.doubleputt.fullgame`, $4.99, Family Sharing on), opens the rest. No medal locks: medals
  are a goal, not a key, and a finished round's scorecard offers the next course (after Daybreak, without All
  Courses, the Sampler: the free holes as a round). TestFlight purchases are in the
  sandbox, so testers aren't charged.
- [x] **The screen stays awake while playing** (aiming can take longer than auto-lock), and sleeps normally on
  the menus.
- [x] **Coming back to the app shows the pause menu** if a hole was in play.
- [x] **Settings screen** from the title's gear: Sound, Unlock All Holes and Restore Purchase, Privacy Policy,
  Support, and the version.
- [x] **Anonymous gameplay counts** (see `docs/analytics.md`): per-hole difficulty and the course funnel, no
  names or device IDs, tagged `debug` / `testflight` / `appstore`.
- [x] **CI builds the Release configuration**, so an archive can't fail on code only Debug builds hide.
- Version 1.0, build 8 (builds 1-5 were 0.1). Bump the build number (`CURRENT_PROJECT_VERSION`) by one for each
  upload.
- iPhone (portrait) and iPad (either way round), from build 5; archive with Xcode 27.1, whose SDK runs the app full
  screen on iPhone Duo. Sound follows the silent switch (ambient), so it never surprises anyone.

### In BrightBench (a separate session)
- [x] `brightbench.app/api/double-putt/events`: validates batches against `docs/analytics.md` and keeps daily
  counters, like Bigger Fish's endpoint.
- [x] `brightbench.app/doubleputt/stats`: the counts, by build and channel.
- [x] `brightbench.app/doubleputt/privacy`: the privacy policy (no account, progress stays on the device,
  anonymous gameplay counts).

### In App Store Connect (you)
- [x] **Bundle ID** `com.kraigstrong.doubleputt`, registered through the API (2026-10-15).
- [x] **App record.** Apps, + New App: iOS, name "Double Putt: Mini Golf", English (U.S.), bundle ID
  `com.kraigstrong.doubleputt`, SKU `doubleputt`, Full Access. Then category Games > Puzzle (or Sports), and add
  its Apple ID to the "App Store Connect" 1Password Environment as `ASCC_APP_ID_DOUBLE_PUTT` (`push.py check`
  lists it).
- [ ] **Privacy:** the policy URL above, and App Privacy: Product Interaction, used for Analytics, not linked to
  the user, not used for tracking.

## Uploading a build
Below, `B` is this upload's build number (`CURRENT_PROJECT_VERSION`, bumped by one in a PR first).

1. Check out `main` at the commit you want and tag it `double-putt-vV-beta.B`, with `V` the version
   (`MARKETING_VERSION`): `double-putt-v1.0-beta.8` for build 8.
2. Archive and upload: in Xcode, the MiniGolf scheme and Any iOS Device (arm64), Product > Archive, then in the
   Organizer, Distribute App > App Store Connect > Upload. Or from the command line, with the Apple ID Xcode is
   signed in with:
   ```bash
   V=1.0 B=8
   xcodebuild archive -project MiniGolf.xcodeproj -scheme MiniGolf -configuration Release \
     -destination 'generic/platform=iOS' -archivePath .build/archives/DoublePutt-$V-$B.xcarchive
   xcodebuild -exportArchive -archivePath .build/archives/DoublePutt-$V-$B.xcarchive \
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
- The home screen shows the app icon with the fang mallet behind two balls, a sight line behind each.
- The first launch of the build (fresh install or update) shows "Setting up the greens…" and a bar for a few
  seconds, then the title (How to Play, on a fresh install); the next launch goes straight there.
- A fresh install opens on How to Play's first lesson; ✕ skips to the title, and the last lesson's card offers Play
  Daybreak. Settings → How to Play replays it. The title says "One swing. Two greens."
- Courses lists every course but City Muni (Debug builds only), all open. Long-pressing the logo does nothing (no
  dev mode).
- Play a few holes in a round: strokes show as numbers when balls drop; the result card shows the hole's verdict;
  finishing a round shows the scorecard and medal, and its Up next starts a round of the next course.
- Free Play shows a row per course that swipes sideways, and keeps each row where you left it until the app quits.
  Every card is there when it opens, and scrolling doesn't stutter. It plays any open hole; a double ace shows
  NEW TROPHY and lands on the Trophy Shelf.
- A round has no restart, in the top bar or the pause menu; Free Play still has Retry and Restart Hole.
- Progress survives force-quitting and reopening.
- The rating prompt can't be checked here: Apple never shows it in TestFlight. (Debug builds show it after a round
  with two double aces, back on the title.)
- Free to try, before buying: Courses shows Daybreak open, then the Sampler, and the rest with a lock and "Unlock"; Free Play starts
  with "Try a hole from every course" (Windmill, Sundial, Springboard, Juggler, Sparkler, Two Tiers, Grandstand,
  Teleporter), and the course rows lock everything but each one's FREE hole. Tapping anything locked opens "Unlock
  all 81 holes". A free hole's result card offers "8 more holes like this in …", and Next goes on to the next free
  hole. Daybreak's scorecard has "Up next: Sampler", which plays the eight free holes as a round, numbered 1-8;
  the Sampler's scorecard has "Unlock All Holes", opening the purchase screen. Its whole-hole cards swipe, and show
  flags and moving parts.
- Buying (free in the TestFlight sandbox): Unlock for $4.99 shows the sandbox sheet; afterwards the screen says
  "Every course is open", every lock is gone, the free row disappears, and Settings shows All Courses · Unlocked.
  Bought from the Sampler's scorecard, "Unlock All Holes" becomes "Up next: Nightfall". Bought partway through a
  Sampler round, the Sampler stays on Courses (and Continue on the title) until the round ends, and then it's gone. On
  a second device signed in to the same Apple Account (or after deleting and reinstalling), Restore Purchase brings
  it back; in Airplane Mode it says it can't reach the App Store rather than "nothing to restore".
- The screen doesn't dim while aiming; it sleeps normally on the title screen.
- Background the app mid-hole: on return the pause menu is up and nothing moved while away.
- Sound off in Settings and the pause menu is remembered; with the phone on silent there's no sound.
- Settings shows the version, and Privacy Policy and Support open Double Putt's own pages
  (brightbench.app/doubleputt) in Safari.
- A lone hill or bowl has its own grid centred on it, with the dots riding its lines (Hollow and Midnight on
  Nightfall), and Topiary's hill (Thunderhead) draws nothing on the other green.
- The Links: the slope grid and its dots show on green and fringe only; on Two Tiers a soft putt up the false
  front rolls back down; Bandon naps beside Fescue.
- The Stadium: on Grandstand a ball banks off the stands like a wall.
- Starbase: a robot bounces the ball like a bumper; a lit force field is a wall and a dark one lets the ball
  through; robots and fields keep moving while you aim.

On an iPad, if there's one to hand:
- Held upright, the course is big, with the nine's scorecard in the left column (the hole you're on highlighted)
  and the setting's landmark on the right, below the power meter.
- On its side, the course turns: tees on the left, one green above the other. Dragging left aims right, Mirror
  flips the second green's shot top to bottom, and flags and "ACE!" stand upright.
- Turning it mid-hole (or resizing its window) fades the course, redraws it and carries on: a rolling ball and the
  movers pick up where they were.
- Free Play shows five or so cards across; Courses and the Trophy Shelf sit two side by side; the title's buttons
  stay phone-width.

On an iPhone Duo, if there's one to hand:
- Closed, it plays like a phone, the course clear of the camera.
- Opened like a book, the course turns and fills the screen; held upright, it stands up with the scorecard and
  landmark beside it if there's room.
- Opening or closing it mid-hole fades, redraws and carries on.
- Bent part way open, nothing you tap sits in the fold: the bars split either side of it, and held upright the
  power meter moves up out of it.

## Releasing on the App Store

Version 1.0 waits in App Store Connect (Prepare for Submission). Before submitting it:

**In App Store Connect (you).** These are agreements and declarations, so they're yours to make on the website:
- [ ] **Agreements, Tax, and Banking**: the Paid Apps Agreement, the tax forms and a bank account. Nothing can be
  bought until they're active, and they can take days to clear, so start early.
- [ ] **App Store Small Business Program**: apply, so Apple's commission is 15% rather than 30%.
- [ ] **Pricing and Availability**: the app free, in the countries it should be in. `push.py purchase` gives All
  Courses the app's own countries, so set these first.
- [ ] **App Information**: category Games > Puzzle (or Sports), the age rating questionnaire, and content rights
  (no third-party content).
- [ ] **App Privacy**: Product Interaction, used for Analytics, not linked to the user, not used for tracking.
- [ ] **The version**: copyright (`2026 Kraig Strong`), and the App Review contact (or add `ASCC_REVIEW_*` to the
  1Password Environment and let `push.py push` send it with the notes). Release: manually, so launch day is a
  choice.
- [ ] **EU**: the Digital Services Act trader status, under Business, if Bigger Fish hasn't set it already.

**From this repo, once the agreements are active:**
1. `python3 appstore/push.py purchase --app double-putt --dry-run`, then without `--dry-run`: creates All Courses
   ($4.99, Family Sharing on) with its name and description. Add `--screenshot FILE` with a still of the purchase
   screen for App Review.
2. `python3 appstore/push.py push --app double-putt --dry-run`, then for real: the listing (with "Free to try"
   first), the marketing URL, the purchase's text, and the App Review notes (`appstore/double-putt/review_notes.txt`).
3. Bump `MARKETING_VERSION` to 1.0 and the build number in a PR, archive and upload as above, and smoke-check it on
   TestFlight, buying All Courses in the sandbox.
4. In App Store Connect, attach that build to 1.0, add All Courses under In-App Purchases (the first purchase is
   reviewed with the version), and submit for review.

## App Store screenshots
TestFlight needs none, but the App Store listing does, one set per device. As a universal app, Double Putt needs the
iPhone's and the 13" iPad's. iPhone Duo screenshots earn the product page's optimized-for-iPhone-Duo badge, and from
April 2027 every app built with the iOS 27.1 SDK needs them. Apple's sizes are in its
[screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

1. Capture each device's set on its own simulator (made the first time; see the README's "Screenshots, footage and
   the trailer"):
   ```bash
   Tools/capture/screenshots.sh                 # iPhone: 1320x2868, and 1284x2778 from those
   Tools/capture/screenshots.sh --device ipad   # iPad, upright: 2064x2752
   Tools/capture/screenshots.sh --device duo    # iPhone Duo: nine opened (2853x2007), one closed (1398x2034)
   ```
   Each still's size is checked against the device's; a warning means the simulator isn't the one the set expects
   (the Duo's has to be closed, as it boots).
2. Caption them, then look them over in `build/capture/captioned*`:
   ```bash
   for set in "" -6.5 -ipad -duo; do Tools/capture/frames.py build/capture/screenshots$set build/capture/captioned$set; done
   ```
3. Upload them to the editable version, dry-run first: each folder should land on its device, the Duo's as one
   set of ten.
   ```bash
   python3 appstore/push.py media --app double-putt --dry-run --screenshots build/capture/captioned \
     build/capture/captioned-6.5 build/capture/captioned-ipad build/capture/captioned-duo
   ```
   Add `--preview build/capture/trailer/double-putt-app-preview.mp4 build/capture/trailer/double-putt-app-preview-ipad.mp4`
   (from `Tools/capture/trailer.sh`, and `--device ipad`) to put the app previews on the iPhones and the iPad too
   (not the iPhone Duo, whose slot only takes the iPhone's sizes). See [appstore/README.md](../appstore/README.md#media).

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
| 0.1 (4) | 2026-10-25 | `9feea13` (tag `double-putt-v0.1-beta.4`) | Holes and greens in place of pairs (analytics schema 2), Free Play's cached cards with a loading screen on a build's first launch, the slope grid centred on a lone hill or bowl, the fang-mallet icon, and Settings' Support on Double Putt's own page. `xcodebuild -exportArchive` failed again with "Failed to Use Accounts" (and this Mac has no distribution certificate for the API key to sign with), so it was uploaded from Xcode's Organizer. What to Test set and submitted to Friends with `push.py testflight --build 4 --submit`; beta review approved right away. |
| 0.1 (5) | 2026-10-25 | `5ffaa30` (tag `double-putt-v0.1-beta.5`) | The first universal build: iPad either way round and iPhone Duo (the course turned a quarter on wide screens, the nine's scorecard and a landmark per setting beside the course, roomier menus, a redraw when the screen resizes, controls kept out of a Duo's fold, one window). Archived with Xcode 27.1 and uploaded with `xcodebuild -exportArchive`: cloud signing worked from the command line this time. What to Test set and submitted to Friends with `push.py testflight --build 5 --submit`. |
| 1.0 (6) | 2026-10-26 | `d2ff046` (tag `double-putt-v1.0-beta.6`) | The free-to-try release candidate: Daybreak and a hole of every other course free, All Courses ($4.99) for the rest, no medal locks, purchase-screen analytics. Archived and uploaded with `xcodebuild -exportArchive`; What to Test set with `push.py testflight --build 6` (Internal only, not sent to Friends). Kraig's feedback on it led to build 7. |
| 1.0 (7) | 2026-10-26 | `844e707` (tag `double-putt-v1.0-beta.7`) | The 1.0 candidate after Kraig's feedback on build 6: the Sampler (the free holes as a round, Daybreak's Up next), How to Play's three lessons, the purchase screen's whole-hole cards, flags and movers in the menu art, and the rating prompt. Archived and uploaded with `xcodebuild -exportArchive`; What to Test set, added to Friends and submitted for Beta App Review (the first 1.0 build to go external) with `push.py testflight --build 7 --submit`. |
