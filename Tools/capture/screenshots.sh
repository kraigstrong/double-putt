#!/bin/bash
# App Store screenshots: the stills listed in Tools/capture/screenshots.json, from the simulator.
#
#   Tools/capture/screenshots.sh [name ...]      # default: every shot, in the listing's order
#
# Builds Debug, installs it on the capture simulator (lib.sh), and plays each shot's clip with -storeCapture,
# saving just the stills it needs (MiniGolf/Game/StoreCapture.swift): the screen as a player sees it, HUD and all,
# with nothing over it (no Dynamic Island). A rerun gives the same stills.
#
# Output goes to build/capture/ (ignored by git):
#   screenshots/NN-<name>.png      1320x2868 portrait PNGs with no alpha: the 6.9" size, which App Store Connect
#                                  scales down for smaller iPhones
#   screenshots-6.5/NN-<name>.png  1284x2778, scaled and trimmed from those, for the 6.5" slot
# Then caption them with Tools/capture/frames.py.
#
# CAPTURE_NO_BUILD=1 reuses the last build, already installed.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
SHOTS="$ROOT/Tools/capture/screenshots.json"

# "<number> <name> <clip> <seconds>" per shot asked for (all by default), in the listing's order.
plan=$(python3 - "$SHOTS" "$@" <<'EOF'
import json, sys
shots = json.load(open(sys.argv[1]))["shots"]
names = sys.argv[2:]
unknown = set(names) - {s["name"] for s in shots}
if unknown:
    sys.exit(f"unknown shots: {', '.join(sorted(unknown))} (one of: {', '.join(s['name'] for s in shots)})")
for number, shot in enumerate(shots, 1):
    if not names or shot["name"] in names:
        print(number, shot["name"], shot["clip"], shot["at"])
EOF
)
mkdir -p "$OUT/screenshots" "$OUT/screenshots-6.5"
build_and_install
failed=0
# One launch per clip, saving all of its stills.
for clip in $(awk '{ print $3 }' <<< "$plan" | awk '!seen[$0]++'); do
    times=$(awk -v c="$clip" '$3 == c { printf "%s%s", sep, $4; sep = "," }' <<< "$plan")
    play_clip "$clip" -captureNoFrames -captureStills "$times" || { failed=1; continue; }
    index=0
    while read -r number name _ _; do
        file="$(printf '%02d' "$number")-$name.png"
        rm -f "$OUT"/screenshots/??-"$name".png "$OUT"/screenshots-6.5/??-"$name".png
        cp "$FRAMES/still-$index.png" "$OUT/screenshots/$file"
        size="$(sips -g pixelWidth -g pixelHeight "$OUT/screenshots/$file" | awk '/pixel/ { printf "%s%s", sep, $2; sep = "x" }')"
        [ "$size" = 1320x2868 ] || echo "$name: $size, not the 6.9\" size (1320x2868); is the capture simulator an iPhone 17 Pro Max?" >&2
        # 6.5": scaled to its width, then trimmed to its height (a few pixels off the top and bottom).
        sips --resampleWidth 1284 "$OUT/screenshots/$file" --out "$OUT/screenshots-6.5/$file" >/dev/null
        sips --cropToHeightWidth 2778 1284 "$OUT/screenshots-6.5/$file" >/dev/null
        echo "captured screenshots/$file ($size)"
        index=$((index + 1))
    done < <(awk -v c="$clip" '$3 == c' <<< "$plan")
done
exit $failed
