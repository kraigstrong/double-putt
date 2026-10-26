#!/bin/bash
# App Store screenshots: the stills listed in Tools/capture/screenshots.json, from the simulator.
#
#   Tools/capture/screenshots.sh [--device iphone|ipad|duo] [name ...]   # default: the iPhone's, every shot in order
#
# Builds Debug, installs it on the device's capture simulator (lib.sh), and plays each shot's clip with -storeCapture,
# saving just the stills it needs (MiniGolf/Game/StoreCapture.swift): the screen as a player sees it, HUD and all,
# with nothing over it (no Dynamic Island, no camera). A rerun gives the same stills. Each device's listing, and the
# poses a shot can take on it, are screenshots.json's.
#
# Output goes to build/capture/ (ignored by git), as PNGs with no alpha:
#   iphone  screenshots/NN-<name>.png      1320x2868: the 6.9" size, which App Store Connect scales down for smaller
#                                          iPhones
#           screenshots-6.5/NN-<name>.png  1284x2778, scaled and trimmed from those, for the 6.5" slot
#   ipad    screenshots-ipad/NN-<name>.png 2064x2752, upright, beside the scorecard and the setting's landmark: the 13"
#                                          size, which App Store Connect requires for an iPad app
#   duo     screenshots-duo/NN-<name>[-open].png   one set for App Store Connect's iPhone Duo slot: opened like a book
#                                          (-open, the inner screen held sideways, laid out with -canvas 951x669 and
#                                          saved at its 2853x2007), then closed (the outer screen, 1398x2034)
# Then caption them with Tools/capture/frames.py.
#
# CAPTURE_NO_BUILD=1 reuses the last build, already installed.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
SHOTS="$ROOT/Tools/capture/screenshots.json"

device=iphone
if [ "${1:-}" = --device ]; then
    device="${2:?--device iphone, ipad or duo}"
    shift 2
fi
use_device "$device"
case "$device" in
    iphone) DIR="$OUT/screenshots" ;;
    *) DIR="$OUT/screenshots-$device" ;;
esac

# "<file> <clip> <seconds> <canvas or -> <size>" per shot asked for (all by default), in the device's listing order.
plan=$(python3 - "$SHOTS" "$device" "$@" <<'EOF'
import json, sys
config = json.load(open(sys.argv[1]))
device, names = sys.argv[2], sys.argv[3:]
shots = {s["name"]: s for s in config["shots"]}
listing = config["devices"][device]
unknown = set(names) - set(shots)
if unknown:
    sys.exit(f"unknown shots: {', '.join(sorted(unknown))} (one of: {', '.join(shots)})")
for number, entry in enumerate(listing["shots"], 1):
    name, _, pose = entry.partition("@")
    if names and name not in names:
        continue
    if pose and pose not in listing.get("poses", {}):
        sys.exit(f"{device}: {entry} has no pose called {pose}")
    laid = listing["poses"][pose] if pose else {}
    print(f"{number:02d}-{name}" + (f"-{pose}" if pose else ""), shots[name]["clip"], shots[name]["at"],
          laid.get("canvas", "-"), laid.get("size", listing["size"]))
EOF
)
[ -n "$plan" ] || { echo "$device's listing has none of those shots" >&2; exit 1; }
mkdir -p "$DIR"
[ "$device" = iphone ] && mkdir -p "$OUT/screenshots-6.5"
# The whole listing: stills of shots it no longer has go, so the folder is exactly the listing (frames.py and
# push.py take a folder as one device's set).
if [ $# -eq 0 ]; then
    keep=$(awk '{ print $1 ".png" }' <<< "$plan")
    dirs=("$DIR")
    [ "$device" = iphone ] && dirs+=("$OUT/screenshots-6.5")
    for dir in "${dirs[@]}"; do
        for file in "$dir"/*.png; do
            [ -e "$file" ] || continue
            grep -qxF "$(basename "$file")" <<< "$keep" && continue
            rm -f "$file"
            echo "removed ${file#"$OUT/"}: not in $device's listing"
        done
    done
fi
build_and_install
failed=0
# One launch per clip and pose, saving all of its stills.
while read -r clip canvas; do
    times=$(awk -v c="$clip" -v k="$canvas" '$2 == c && $4 == k { printf "%s%s", sep, $3; sep = "," }' <<< "$plan")
    args=(-captureNoFrames -captureStills "$times")
    [ "$canvas" != - ] && args+=(-canvas "$canvas")
    # Not from this loop's input, which simctl would read.
    play_clip "$clip" "${args[@]}" < /dev/null || { failed=1; continue; }
    index=0
    while read -r stem _ _ _ want; do
        file="$stem.png"
        # The same shot under its old number goes (?? is the number).
        rm -f "$DIR"/??-"${stem#??-}".png
        [ "$device" = iphone ] && rm -f "$OUT"/screenshots-6.5/??-"${stem#??-}".png
        cp "$FRAMES/still-$index.png" "$DIR/$file"
        size="$(sips -g pixelWidth -g pixelHeight "$DIR/$file" | awk '/pixel/ { printf "%s%s", sep, $2; sep = "x" }')"
        [ "$size" = "$want" ] || echo "$stem: $size, not $want; is \"$DEVICE_NAME\" the right simulator, as it boots?" >&2
        if [ "$device" = iphone ]; then
            # 6.5": scaled to its width, then trimmed to its height (a few pixels off the top and bottom).
            sips --resampleWidth 1284 "$DIR/$file" --out "$OUT/screenshots-6.5/$file" >/dev/null
            sips --cropToHeightWidth 2778 1284 "$OUT/screenshots-6.5/$file" >/dev/null
        fi
        echo "captured ${DIR#"$OUT/"}/$file ($size)"
        index=$((index + 1))
    done < <(awk -v c="$clip" -v k="$canvas" '$2 == c && $4 == k' <<< "$plan")
done < <(awk '!seen[$2 " " $4]++ { print $2, $4 }' <<< "$plan")
exit $failed
