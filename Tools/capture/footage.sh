#!/bin/bash
# Footage of a clip from Tools/capture/clips.json, for the trailer, the App Store preview and the site.
#
#   Tools/capture/footage.sh <clip> [from to]      # 60 fps at the screen's full size, with its sound; from/to in seconds
#   Tools/capture/footage.sh --look <clip>          # a contact sheet: a frame every half second, a quarter size
#   Tools/capture/footage.sh --all                  # every clip that isn't recorded yet
#   Tools/capture/footage.sh --device ipad ...      # any of those on the iPad (or duo); the iPhone's is the default
#
# Builds Debug, installs it on the device's capture simulator (lib.sh), and launches it with -storeCapture: the app
# plays the clip's swings frame by frame and saves every frame, HUD included (MiniGolf/Game/StoreCapture.swift). A
# rerun plays the same, so a --look at a clip, then a recording of just the seconds wanted, gives what the look showed.
#
# Output goes to build/capture/footage/ for the iPhone, footage-<device>/ for another (ignored by git):
#   <clip>[-<from>-<to>].mp4   the screen's size (the iPhone's 1320x2868, the iPad's 2064x2752 upright), 60 fps H.264,
#                              with the game's sounds rebuilt (soundtrack.py) as AAC
#   <clip>[-<from>-<to>].wav   that sound on its own, for the trailer's mix
#   <clip>-look.jpg            with --look: the contact sheet, eight to a row
#   <clip>.txt                 how the clip went: each drag, Mirror tap, Putt and finish, in seconds
#
# Needs ffmpeg, and Python 3 with NumPy. CAPTURE_NO_BUILD=1 reuses the last build, already installed.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

usage() { sed -n '2,7p' "$0"; exit 1; }
device=iphone
if [ "${1:-}" = --device ]; then
    device="${2:-}"
    [ -n "$device" ] || usage
    shift 2
fi
use_device "$device"
case "$device" in
    iphone) FOOTAGE="$OUT/footage" ;;
    *) FOOTAGE="$OUT/footage-$device" ;;
esac
command -v ffmpeg >/dev/null || { echo "needs ffmpeg: brew install ffmpeg" >&2; exit 1; }
python3 -c 'import numpy' 2>/dev/null || { echo "needs NumPy: python3 -m pip install numpy" >&2; exit 1; }

# Records clip $1 (from $2 to $3 seconds, if given).
record() {
    local clip="$1" from="${2:-}" to="${3:-}" name="$1"
    local args=()
    [ -n "$from" ] && { args+=(-captureFrom "$from" -captureTo "$to"); name="$clip-$from-$to"; }
    play_clip "$clip" ${args[@]+"${args[@]}"} || return 1
    mkdir -p "$FOOTAGE"
    python3 Tools/capture/soundtrack.py "$FRAMES" "$FOOTAGE/$name.wav" --from "${from:-0}" \
        --length "$(python3 -c "import sys; print(int(sys.argv[1]) / 60)" "$(find "$FRAMES" -name '*.jpg' | wc -l)")" >/dev/null
    ffmpeg -v error -y -framerate 60 -i "$FRAMES/%05d.jpg" -i "$FOOTAGE/$name.wav" -map 0:v -map 1:a \
        -c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p -c:a aac -b:a 256k -shortest -movflags +faststart \
        "$FOOTAGE/$name.mp4"
    cp "$FRAMES/done.txt" "$FOOTAGE/$clip.txt"
    echo "$FOOTAGE/$name.mp4: $(head -1 "$FRAMES/done.txt")"
}

look() {
    local clip="$1"
    play_clip "$clip" -captureEvery 30 -captureScale 0.25 || return 1
    mkdir -p "$FOOTAGE"
    local count
    count=$(find "$FRAMES" -name '*.jpg' | wc -l | tr -d ' ')
    ffmpeg -v error -y -framerate 1 -i "$FRAMES/%05d.jpg" -vf "tile=8x$(( (count + 7) / 8 )):padding=4" -frames:v 1 \
        "$FOOTAGE/$clip-look.jpg"
    cp "$FRAMES/done.txt" "$FOOTAGE/$clip.txt"
    echo "$FOOTAGE/$clip-look.jpg (a frame every half second):"
    tail -n +2 "$FRAMES/done.txt"
}

case "${1:-}" in
    --look) [ $# -eq 2 ] || usage; clip_json "$2" >/dev/null; build_and_install; look "$2" ;;
    --all)
        build_and_install
        failed=0
        for clip in $(clip_names); do
            [ -f "$FOOTAGE/$clip.mp4" ] && continue
            record "$clip" || failed=1
        done
        exit $failed ;;
    ''|-*) usage ;;
    *) [ $# -eq 1 ] || [ $# -eq 3 ] || usage; clip_json "$1" >/dev/null; build_and_install; record "$@" ;;
esac
