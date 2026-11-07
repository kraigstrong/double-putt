#!/bin/bash
# The App Store's product page header and search results art: one 5244x2950 PNG for both, from the simulator.
#
#   Tools/capture/creative.sh
#
# Plays the shot named in screenshots.json's "creative" (its clip, at its moment) on the iPhone's capture simulator
# (lib.sh), laid out turned with -canvas, as an iPad on its side or an iPhone Duo opened shows the course, then
# frames.py --creative sets it under the shot's caption at 16:9. Apple crops that to 21:9 for the header and to 3:2 in
# search results, so the caption and the screen sit in the middle both crops keep.
#
# Output goes to build/capture/creative/ (ignored by git):
#   still.png                   the screen as laid out, HUD and all, at 3x the canvas
#   double-putt-creative.png    5244x2950, no alpha: `appstore/push.py media --creative` uploads it for both
#
# CAPTURE_NO_BUILD=1 reuses the last build, already installed.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
DIR="$OUT/creative"

# "<clip> <seconds> <canvas> <size>", from the shot the creative names.
read -r clip at canvas want < <(python3 - "$ROOT/Tools/capture/screenshots.json" <<'EOF'
import json, sys
config = json.load(open(sys.argv[1]))
creative = config["creative"]
shot = next((s for s in config["shots"] if s["name"] == creative["shot"]), None)
if shot is None:
    sys.exit(f"creative: no shot called {creative['shot']}")
print(shot["clip"], shot["at"], creative["canvas"], creative["size"])
EOF
)

use_device iphone
build_and_install
play_clip "$clip" -captureNoFrames -captureStills "$at" -canvas "$canvas" < /dev/null
mkdir -p "$DIR"
cp "$FRAMES/still-0.png" "$DIR/still.png"
size="$(sips -g pixelWidth -g pixelHeight "$DIR/still.png" | awk '/pixel/ { printf "%s%s", sep, $2; sep = "x" }')"
[ "$size" = "$want" ] || echo "still.png: $size, not $want; is \"$DEVICE_NAME\" the right simulator, as it boots?" >&2
echo "captured creative/still.png ($size)"
python3 Tools/capture/frames.py --creative "$DIR/still.png" "$DIR/double-putt-creative.png"
