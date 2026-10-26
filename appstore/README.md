# App Store listing text

Double Putt's App Store Connect listing and TestFlight text live here as plain text files, reviewed in pull requests
like code, and `push.py` sends them to App Store Connect through Apple's API. `push.py` is copied from Bigger Fish's
(itself adapted from a friend's App Store listing kit), with a `testflight` command added.

```
appstore/
├── push.py
└── double-putt/
    ├── app/<locale>/<field>.txt            # name, subtitle, promotional_text, description, keywords,
    │                                       # release_notes, support_url, marketing_url, privacy_policy_url
    ├── iap/all-courses/<locale>/           # the All Courses purchase: name.txt, description.txt
    └── testflight/
        ├── <locale>/description.txt        # the Beta App Description testers see
        ├── <locale>/what_to_test.txt       # each build's What to Test
        └── review_notes.txt                # notes for Beta App Review
```

```bash
python3 appstore/push.py validate                              # Apple's limits and a few house rules; no network
python3 appstore/push.py check                                 # the credentials work; lists each app's Apple ID
python3 appstore/push.py push --app double-putt --dry-run      # what would change, field by field
python3 appstore/push.py push --app double-putt                 # push only what differs
python3 appstore/push.py push --app double-putt --only promotional_text
python3 appstore/push.py testflight --app double-putt --dry-run                     # test information, groups
python3 appstore/push.py testflight --app double-putt --build 4 --dry-run           # and build 4's What to Test
python3 appstore/push.py testflight --app double-putt --build 4 --submit --dry-run  # to Friends, beta review
python3 appstore/push.py testflight --app double-putt --invite EMAIL --dry-run      # a tester, to Friends
python3 appstore/push.py media --app double-putt --screenshots DIR DIR --creative FILE --dry-run   # see Media
```

- **A push writes to the editable version** (Prepare for Submission and the like). Nothing goes public until that
  version is submitted and released. Always dry-run first.
- **Promotional text can change any time** without review. A new version can come up with it empty: push it again
  with `--only promotional_text`.
- **Edited something in App Store Connect's website?** Copy it back into the file, or the next push overwrites it.
- **An app's first version has no What's New**, so `release_notes.txt` waits for the second.
- **validate checks**: the character limits (name and subtitle 30, promotional text 170, keywords 100, description
  and What's New 4000), https links, no space after a keyword's comma, and no keyword that's already in the name or
  subtitle (those are searched anyway).

## TestFlight

`testflight` sets what testers and Beta App Review see, changing only what differs:

- **Test information**, per locale: the Beta App Description from `testflight/<locale>/description.txt`, the
  feedback email, and the listing's privacy policy (and marketing) links.
- **Beta App Review details**: the notes from `testflight/review_notes.txt`, the contact, and no sign-in needed.
- **Groups**: creates **Internal** (App Store Connect users, every build) and **Friends** (external) if they're
  missing, and turns on Friends' public link (printed on each run), so anyone with the link can join.
- **`--build N`**: the newest upload with that build number gets its What to Test from
  `testflight/<locale>/what_to_test.txt`. With `--submit`, once the build has finished processing, it's added to
  Friends and submitted for Beta App Review (the first build of each version is reviewed; later ones usually go out
  right away).
- **`--invite EMAIL`** (repeatable): invites a tester to Friends. Addresses come from the command line and are never
  kept in the repo. The public link works without an invite.

The feedback email and the review contact are personal and the repo is public, so they come from the 1Password
Environment: `ASCC_BETA_FEEDBACK_EMAIL`, and `ASCC_REVIEW_FIRST_NAME`, `ASCC_REVIEW_LAST_NAME`, `ASCC_REVIEW_PHONE`,
`ASCC_REVIEW_EMAIL`. Any that aren't set are left as they are, so filling them in on the website works too.
Double Putt's were copied from Bigger Fish's TestFlight settings on 2026-10-15.

Uploading builds isn't part of `push.py`; see [docs/testflight.md](../docs/testflight.md).

## Media

`media` replaces the editable version's screenshots, its product page header and search results asset (`--creative`,
or `--header` and `--search`), and its app previews (`--preview`, with `--poster` for the frame shown before one plays).
New files are uploaded and processed first, and the old ones swapped out only once every one is ready, so a failure
leaves the listing as it was.

Each `--screenshots` folder is one device's set, uploaded in name order. Which device a file goes to comes from its
size, checked against App Store Connect's own list of display types, so it takes any device Apple does; a folder whose
files fit different devices is refused. Apple takes up to 10 screenshots a device. Double Putt's sets come from
`Tools/capture/` (see the [README](../README.md#screenshots-footage-and-the-trailer)), captioned by `frames.py`:

| Folder (`build/capture/`) | Size | App Store Connect |
|---|---|---|
| `captioned` | 1320x2868 | iPhone 6.9" (Dynamic Island, large); scaled down for the smaller iPhones that have no set of their own |
| `captioned-6.5` | 1284x2778 | iPhone 6.5" (Face ID, large) |
| `captioned-ipad` | 2064x2752 | iPad 13", required for an iPad app; scaled down for the smaller iPads |
| `captioned-duo` | 2853x2007 opened, 1398x2034 closed | iPhone Duo: one set, either screen, upright or sideways. It earns the product page's optimized-for-iPhone-Duo badge, and from April 2027 every app built with the iOS 27.1 SDK needs it |

`--preview` takes one video per kind of device, and each goes where its size fits (from the same reference data),
among the devices with a set of their own:

| Video (`build/capture/trailer/`) | Size | App Store Connect |
|---|---|---|
| `double-putt-app-preview.mp4` | 886x1920 | iPhone 6.9", iPhone 6.5" and iPhone Duo. The 6.3" has no set of its own: it shows the 6.5"'s |
| `double-putt-app-preview-ipad.mp4` | 1200x1600 | iPad 13"; scaled down for the smaller iPads |

Both come from `Tools/capture/trailer.sh` (`--device ipad` for the iPad's), 15-30 seconds at 30 fps. The poster is a
timecode into the video, the same for both, since they share the edit: 00:00:02:00 is "ONE SWING." over Reflection,
both balls aimed and Putt lit.

```bash
Tools/capture/screenshots.sh && Tools/capture/screenshots.sh --device ipad && Tools/capture/screenshots.sh --device duo
for set in "" -6.5 -ipad -duo; do Tools/capture/frames.py build/capture/screenshots$set build/capture/captioned$set; done
python3 appstore/push.py media --app double-putt --dry-run --screenshots build/capture/captioned \
  build/capture/captioned-6.5 build/capture/captioned-ipad build/capture/captioned-duo
Tools/capture/trailer.sh && Tools/capture/trailer.sh --device ipad
python3 appstore/push.py media --app double-putt --dry-run --preview build/capture/trailer/double-putt-app-preview.mp4 \
  build/capture/trailer/double-putt-app-preview-ipad.mp4 --poster 00:00:02:00
```

The dry run lists each device's set, its sizes, and how many screenshots or previews it replaces. Run it again without
`--dry-run` to upload.

## The purchase

Double Putt is free to try, with one purchase, **All Courses** (`com.kraigstrong.doubleputt.fullgame`): a
non-consumable at $4.99 with Family Sharing on, that opens every hole past the free ones, courses added later
included. Its settings are `PURCHASE_SETUP` in `push.py`, and its display name and description are in
`double-putt/iap/all-courses/` (30 and 45 characters at most). The product ID is permanent once created, and Family
Sharing can't be turned off once it's on.

```bash
python3 appstore/push.py purchase --app double-putt --dry-run                        # what it would create or fill in
python3 appstore/push.py purchase --app double-putt --screenshot FILE                # the purchase screen, for App Review
```

`purchase` creates the purchase if App Store Connect doesn't have it, then fills in what's missing: its text, its
price, its availability (the app's own territories, so set the app's availability first), and the review
screenshot. It never changes a price or availability that's already set. Later text edits go out with `push`
(`--only iap` for just those). The first purchase is reviewed together with the app version it's submitted with,
and nothing can be bought until the Paid Apps Agreement, tax and banking are done in App Store Connect.
Xcode runs buy it from `DoublePutt.storekit` at the repo root (the scheme's StoreKit configuration) instead.

## Credentials

Nothing secret is in a file. The App Store Connect API key (App Manager role) is in the 1Password Environment
**App Store Connect**, shared with Bigger Fish, which 1Password mounts at `~/.appstoreconnect/.env`: a pipe it feeds
when the script reads it, never plaintext on disk. It holds `ASCC_KEY_ID`, `ASCC_ISSUER_ID`, `ASCC_PRIVATE_KEY` (the
`.p8` file's contents, concealed), and `ASCC_APP_ID_DOUBLE_PUTT` (the app's numeric Apple ID, from `check`). Set
`ASCC_ENV_FILE` to read another path, or set the variables in the environment.

Talking to the API needs the `cryptography` package (`python3 -m pip install --user cryptography`, or a virtual
environment); `validate` needs nothing.
