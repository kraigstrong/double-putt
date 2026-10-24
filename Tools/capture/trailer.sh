#!/bin/bash
# Double Putt's trailer and App Store preview, rebuilt from the game.
#
#   Tools/capture/trailer.sh [--music <file>]      # or TRAILER_MUSIC=<file>
#
# Records the clips the edit (Tools/capture/trailer/edl.json) uses that aren't in build/capture/footage/ yet
# (footage.sh), then composes both cuts over the music, with each shot's own game sounds under it
# (trailer/compose.py). Without a track, the game's sounds play alone. Output goes to build/capture/trailer/ (ignored
# by git):
#   double-putt-trailer.mp4       1080x1920, 60 fps, with the edit's release line, if any: for the site
#   double-putt-app-preview.mp4   886x1920, 30 fps, no release line: the App Store preview (the 6.9" iPhone's size)
#
# Needs ffmpeg and Python 3 with Pillow and NumPy. Recordings are deterministic, but a hole that's changed plays
# differently: delete its build/capture/footage/<clip>.mp4 to record it again, and check its shots still show what
# they should. To change the cut, edit edl.json. The music isn't kept in the repo (it's licensed, and the repo is
# public): keep it outside, or in build/.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
EDL="$ROOT/Tools/capture/trailer/edl.json"
FOOTAGE="$OUT/footage"
TRAILER="$OUT/trailer"

music="${TRAILER_MUSIC:-}"
if [ "${1:-}" = --music ]; then music="${2:?--music needs a file}"; shift 2; fi
[ $# -eq 0 ] || { sed -n '2,4p' "$0"; exit 1; }
command -v ffmpeg >/dev/null || { echo "needs ffmpeg: brew install ffmpeg" >&2; exit 1; }
python3 -c 'import PIL, numpy' 2>/dev/null || { echo "needs Pillow and NumPy: python3 -m pip install pillow numpy" >&2; exit 1; }

missing=$(python3 -c '
import json, os, sys
edl, footage = sys.argv[1:3]
for clip in dict.fromkeys(shot["clip"] for shot in json.load(open(edl))["shots"]):
    if not os.path.exists(os.path.join(footage, clip + ".mp4")):
        print(clip)' "$EDL" "$FOOTAGE")
built=0
for clip in $missing; do
    echo "recording $clip"
    CAPTURE_NO_BUILD=$built Tools/capture/footage.sh "$clip" >/dev/null </dev/null
    built=1
done

mkdir -p "$TRAILER"
args=()
[ -n "$music" ] && args+=(--music "$music")
python3 Tools/capture/trailer/compose.py "$EDL" "$FOOTAGE" "$TRAILER/double-putt-trailer.mp4" --site ${args[@]+"${args[@]}"}
python3 Tools/capture/trailer/compose.py "$EDL" "$FOOTAGE" "$TRAILER/double-putt-app-preview.mp4" --store ${args[@]+"${args[@]}"}
