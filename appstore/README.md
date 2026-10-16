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
python3 appstore/push.py testflight --app double-putt --build 1 --dry-run           # and build 1's What to Test
python3 appstore/push.py testflight --app double-putt --build 1 --submit --dry-run  # to Friends, beta review
python3 appstore/push.py testflight --app double-putt --invite EMAIL --dry-run      # a tester, to Friends
python3 appstore/push.py media --app double-putt --screenshots DIR DIR --creative FILE --dry-run
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

## Credentials

Nothing secret is in a file. The App Store Connect API key (App Manager role) is in the 1Password Environment
**App Store Connect**, shared with Bigger Fish, which 1Password mounts at `~/.appstoreconnect/.env`: a pipe it feeds
when the script reads it, never plaintext on disk. It holds `ASCC_KEY_ID`, `ASCC_ISSUER_ID`, `ASCC_PRIVATE_KEY` (the
`.p8` file's contents, concealed), and `ASCC_APP_ID_DOUBLE_PUTT` (the app's numeric Apple ID, from `check`). Set
`ASCC_ENV_FILE` to read another path, or set the variables in the environment.

Talking to the API needs the `cryptography` package (`python3 -m pip install --user cryptography`, or a virtual
environment); `validate` needs nothing.
