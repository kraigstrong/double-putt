#!/bin/bash
# Double Putt's trailer and App Store preview, rebuilt from the game.
#
#   Tools/capture/trailer.sh [--music <file>]                  # or TRAILER_MUSIC=<file>
#   Tools/capture/trailer.sh --device ipad [--music <file>]    # the iPad's App Store preview
#
# Records the clips the edit (Tools/capture/trailer/edl.json) uses that aren't in build/capture/footage/ yet
# (footage.sh; footage-ipad/ for the iPad), then composes the cuts over the music, with each shot's own game sounds
# under it (trailer/compose.py). Without a track, the game's sounds play alone. Output goes to build/capture/trailer/
# (ignored by git):
#   double-putt-trailer.mp4            1080x1920, 60 fps, with the edit's release line, if any: for the site
#   double-putt-app-preview.mp4        886x1920, 30 fps, no release line: the App Store preview for the iPhones (the
#                                      6.9" and 6.5" sizes) and the iPhone Duo
#   double-putt-app-preview-ipad.mp4   with --device ipad: 1200x1600, 30 fps, upright, the iPad 13"'s preview
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
device=iphone
while [ $# -gt 0 ]; do
    case "$1" in
        --music) music="${2:?--music needs a file}"; shift 2 ;;
        --device) device="${2:?--device iphone or ipad}"; shift 2 ;;
        *) sed -n '2,5p' "$0"; exit 1 ;;
    esac
done
case "$device" in
    iphone) ;;
    ipad) FOOTAGE="$OUT/footage-ipad" ;;
    *) echo "the trailer is cut for the iphone or the ipad, not $device" >&2; exit 1 ;;
esac
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
    CAPTURE_NO_BUILD=$built Tools/capture/footage.sh --device "$device" "$clip" >/dev/null </dev/null
    built=1
done

mkdir -p "$TRAILER"
args=()
[ -n "$music" ] && args+=(--music "$music")
if [ "$device" = ipad ]; then
    python3 Tools/capture/trailer/compose.py "$EDL" "$FOOTAGE" "$TRAILER/double-putt-app-preview-ipad.mp4" --store --ipad ${args[@]+"${args[@]}"}
    exit
fi
python3 Tools/capture/trailer/compose.py "$EDL" "$FOOTAGE" "$TRAILER/double-putt-trailer.mp4" --site ${args[@]+"${args[@]}"}
python3 Tools/capture/trailer/compose.py "$EDL" "$FOOTAGE" "$TRAILER/double-putt-app-preview.mp4" --store ${args[@]+"${args[@]}"}
