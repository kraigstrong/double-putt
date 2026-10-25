#!/bin/bash
# The site's media (brightbench.app/doubleputt, in kraigstrong/BrightBench), cut from the capture tools' footage.
#
#   Tools/capture/site.sh <out dir>        # e.g. ~/code/BrightBench/apps/marketing/public/doubleputt
#
# Records any clip it needs that isn't in build/capture/footage/ yet (footage.sh), and the trailer if it isn't built
# (trailer.sh), then writes, web-sized:
#   hero.mp4, hero-poster.jpg              the hero's loop: a Mirror double ace on Reflection, the whole screen, through
#                                          its confetti to the Double Ace trophy card
#   courses/<course>.mp4, -poster.jpg      a loop on each course, cut to the course itself (no HUD), from just before
#                                          the putt through the double ace's confetti
#   beats/aim.jpg, mirror.jpg, double-ace.jpg   the three steps of a swing, the whole screen (the last, the trophy
#                                          card over the confetti)
#   trailer.mp4, trailer-poster.jpg        the site's trailer, smaller to stream
#   icon-1024.png                          the app icon
#   og.png                                 1200x630, for link previews: the wordmark beside the course
# Loops are silent H.264, faststart. Rerun it after re-recording, or once the trailer has its music.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
FOOTAGE="$OUT/footage"
[ $# -eq 1 ] || { sed -n '2,4p' "$0"; exit 1; }
DEST="$1"
mkdir -p "$DEST/courses" "$DEST/beats"

# Each course's loop: "<course slug> <clip>". The hero and beats come from reflection and grand-finale.
COURSES="daybreak:reflection nightfall:windmill thunderhead:sundial midway:springboard bigtop:human-cannonball
fireworks:grand-finale links:two-tiers stadium:island-green starbase:teleporter"

built=0
for clip in reflection grand-finale $(for c in $COURSES; do echo "${c#*:}"; done); do
    [ -f "$FOOTAGE/$clip.mp4" ] && continue
    echo "recording $clip"
    CAPTURE_NO_BUILD=$built Tools/capture/footage.sh "$clip" >/dev/null </dev/null
    built=1
done
[ -f "$OUT/trailer/double-putt-trailer.mp4" ] || Tools/capture/trailer.sh

# The second an event happened in a clip, from its footage log ("Putt", "both in").
when() { awk -v e="$2" 'index($0, e) && $1 ~ /^[0-9.]+$/ { print $1; exit }' "$FOOTAGE/$1.txt"; }

# loop <clip> <from> <to> <filter> <out>: a silent, small, faststart loop, and its first frame as a poster.
loop() {
    ffmpeg -v error -y -ss "$2" -to "$3" -i "$FOOTAGE/$1.mp4" -an -vf "$4" -c:v libx264 -preset slow -crf 26 \
        -profile:v high -pix_fmt yuv420p -movflags +faststart "$5.mp4"
    ffmpeg -v error -y -i "$5.mp4" -frames:v 1 -q:v 3 "$5-poster.jpg"
}

# The whole screen at 720 wide; the course alone (it sits at x 60-1146, y 390-2486 on the 1320x2868 screen) at 480.
SCREEN="scale=720:-2:flags=lanczos"
COURSE="crop=1146:2160:30:357,scale=480:-2:flags=lanczos"

loop reflection 0.6 7.3 "$SCREEN" "$DEST/hero"
for c in $COURSES; do
    slug="${c%%:*}" clip="${c#*:}"
    putt=$(when "$clip" Putt) done=$(when "$clip" "both in")
    loop "$clip" "$(python3 -c "print(max(0, $putt - 0.5))")" "$(python3 -c "print($done + 1.2)")" "$COURSE" "$DEST/courses/$slug"
done

still() { ffmpeg -v error -y -ss "$2" -i "$FOOTAGE/$1.mp4" -frames:v 1 -vf "$SCREEN" -q:v 3 "$3"; }
still reflection 1.45 "$DEST/beats/aim.jpg"
still reflection 2.6 "$DEST/beats/mirror.jpg"
still grand-finale "$(python3 -c "print($(when grand-finale "both in") + 1.8)")" "$DEST/beats/double-ace.jpg"

ffmpeg -v error -y -i "$OUT/trailer/double-putt-trailer.mp4" -c:v libx264 -preset slow -crf 24 -profile:v high \
    -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$DEST/trailer.mp4"
ffmpeg -v error -y -ss 3.4 -i "$DEST/trailer.mp4" -frames:v 1 -q:v 3 "$DEST/trailer-poster.jpg"

cp MiniGolf/Assets.xcassets/AppIcon.appiconset/icon-1024.png "$DEST/icon-1024.png"
python3 - "$DEST" "$FOOTAGE" <<'EOF'
# The link preview: the title's wordmark and tagline on the left, the game on the right, on the title's ink green.
import subprocess, sys
from io import BytesIO
from pathlib import Path
sys.path.insert(0, "Tools/capture/trailer")
from PIL import Image, ImageDraw, ImageFilter
import captions

dest, footage = Path(sys.argv[1]), Path(sys.argv[2])
W, H = 1200, 630
canvas = Image.new("RGB", (W, H), captions.INK)
glow = Image.radial_gradient("L").resize((W * 2, H * 2)).crop((W // 2, H // 2, W * 3 // 2, H * 3 // 2))
canvas.paste(Image.new("RGB", (W, H), (38, 92, 56)), (0, 0), glow.point(lambda v: (255 - v) // 2))
frame = subprocess.run(["ffmpeg", "-v", "error", "-ss", "2.6", "-i", str(footage / "reflection.mp4"), "-frames:v", "1",
                        "-f", "image2pipe", "-vcodec", "png", "-"], capture_output=True, check=True).stdout
# The course alone, as the course loops cut it.
screen = Image.open(BytesIO(frame)).convert("RGB").crop((30, 357, 1176, 2517))
sh = H - 60
sw = round(screen.width * sh / screen.height)
screen = screen.resize((sw, sh), Image.LANCZOS)
x, y = W - sw - 70, 30
mask = Image.new("L", (sw, sh), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), 26, fill=255)
shadow = Image.new("L", (W, H), 0)
ImageDraw.Draw(shadow).rounded_rectangle((x, y + 12, x + sw, y + sh + 12), 26, fill=170)
canvas.paste(Image.new("RGB", (W, H)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(18)))
canvas.paste(screen, (x, y), mask)
card = captions.end_card((1000, 1100))
card = card.crop(card.getbbox())
card.thumbnail((560, 520), Image.LANCZOS)
canvas.paste(card, ((W - sw - 70 - card.width) // 2, (H - card.height) // 2), card)
canvas.save(dest / "og.png", optimize=True)
EOF
du -sh "$DEST"
ls "$DEST" "$DEST/courses" "$DEST/beats"
