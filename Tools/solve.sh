#!/bin/zsh
# Build and run the headless level solver against the game's own physics + levels.
#   Tools/solve.sh            # all levels
#   Tools/solve.sh moat       # one level (name filter)
#   Tools/solve.sh moat --fine
#   LEVELS=Tools/levels/desert.swift Tools/solve.sh --drafts   # a scratch level file defining `Levels.drafts`
set -e
cd "$(dirname "$0")/.."
mkdir -p .build/tmp .build/ModuleCache
extra=()
out=.build/solver
if [[ -n "$LEVELS" ]]; then
  extra=("$LEVELS" -D HAS_DRAFTS)
  out=.build/solver-${LEVELS:t:r}
fi
TMPDIR="$PWD/.build/tmp" swiftc -O -module-cache-path .build/ModuleCache \
  MiniGolf/Core/*.swift MiniGolf/Core/Course/*.swift Tools/solver/*.swift "${extra[@]}" -o "$out"
"$out" "$@"
