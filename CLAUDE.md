# Double Putt — working notes

See README.md for the game, layout, solver and debug launch args.

## Workflow
- Every change goes on its own branch and lands on `main` through a pull request, merged with a merge commit once CI
  is green. Never commit or push to `main` directly.
- Codex reviews every pull request. Before merging, address each of its comments, or have its 👍 reaction on the PR.
  Reply on every comment's thread saying what was done ("Fixed in <sha>: …", or why no change is needed), even when
  the answer is a no-op, then resolve the thread, so the PR shows how each point was handled.
- Name branches by kind: `feat/…`, `fix/…`, `ci/…`, `docs/…`.
- Keep commits small and focused: one logical change each (e.g. model, then screens, then docs), with a subject line
  saying what changed and a body saying why. Don't fold unrelated fixes into a feature commit.

## Checks (CI runs both on every PR)
- Build: `xcodebuild -project MiniGolf.xcodeproj -scheme MiniGolf -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build`
- Solver: `Tools/solve.sh --verify` after touching physics, `Tuning` or level geometry.
