#!/usr/bin/env python3
"""Captions Double Putt's App Store screenshots, and sets the header and search results art.

    Tools/capture/frames.py [--only one-swing,windmill] <screenshots dir> <out dir>
    Tools/capture/frames.py --creative <still> <out dir>

The screenshots are one device's whole set from Tools/capture/screenshots.sh (NN-<name>[-<pose>].png, at any App Store
size, upright or sideways), as screenshots.json lists it: a set with shots missing is refused, since uploading it
would replace the device's listing with just those. The captions are screenshots.json's. Each screen, HUD and all, is
shrunk under its caption, in the game's typeface (SF Rounded Black, as the title's wordmark), over a soft, darkened
blur of itself: no device frame. Output keeps the screenshots' names and size, with no alpha, as App Store Connect
wants.

With --creative, the still is Tools/capture/creative.sh's (screenshots.json's "creative"), set the same way under each
placement's caption: double-putt-header.png (3840x1646, 21:9) for the product page header, laid out inside the middle an
iPhone shows, and double-putt-search.png (3840x2560, 3:2) for search results.
"""
import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = "/System/Library/Fonts/SFNSRounded.ttf"
INK = (16, 35, 26)  # Palette.ink


def font(size, weight="Black"):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def lines_for(caption, size, width):
    """The caption at `size` in one line, or two split where they come out most even (or at its own "\\n"), shrinking
    until it fits `width`."""
    while True:
        f = font(size)
        if "\n" in caption:
            lines = caption.split("\n")
        elif f.getlength(caption) <= width:
            lines = [caption]
        else:
            words = caption.split()
            splits = [[" ".join(words[:i]), " ".join(words[i:])] for i in range(1, len(words))] or [[caption]]
            lines = min(splits, key=lambda pair: max(f.getlength(line) for line in pair))
        if all(f.getlength(line) <= width for line in lines):
            return f, lines
        size -= 4


def place(canvas, screen, x, y, sw, sh, radius, lift, blur):
    """The screen shrunk to sw x sh at (x, y), its corners rounded, over a soft shadow `lift` below it."""
    w, h = canvas.size
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius, fill=255)
    shadow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((x, y + lift, x + sw, y + sh + lift), radius, fill=150)
    canvas.paste(Image.new("RGB", (w, h), (0, 0, 0)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.paste(screen.resize((sw, sh), Image.LANCZOS), (x, y), mask)


def words(canvas, rows, f, anchor, lift, blur):
    """Each (line, y) in white, centred across the canvas, over a soft shadow `lift` below it."""
    w, h = canvas.size
    glow = Image.new("L", (w, h), 0)
    for line, y in rows:
        ImageDraw.Draw(glow).text((w / 2, y + lift), line, font=f, fill=170, anchor=anchor)
    canvas.paste(Image.new("RGB", (w, h), (4, 10, 8)), (0, 0), glow.filter(ImageFilter.GaussianBlur(blur)))
    draw = ImageDraw.Draw(canvas)
    for line, y in rows:
        draw.text((w / 2, y), line, font=f, fill=(255, 255, 255), anchor=anchor)


def framed(shot, caption):
    """The screen shrunk under its caption, over a darkened blur of itself."""
    w, h = shot.size
    # Sized to the width, as on the 6.9" iPhone; a sideways screen (a Duo opened) to its height instead.
    unit = min(w / 1320, h / 1800)
    full = shot.convert("RGB")
    canvas = full.resize((w // 8, h // 8), Image.BILINEAR).filter(ImageFilter.GaussianBlur(6)).resize((w, h), Image.BICUBIC)
    canvas = Image.blend(canvas, Image.new("RGB", (w, h), INK), 0.45)

    top, bottom = round(h * 0.17), round(h * 0.035)
    sh = h - top - bottom
    sw = round(sh * w / h)
    place(canvas, full, (w - sw) // 2, top, sw, sh, round(56 * unit), round(14 * unit), 30 * unit)

    f, lines = lines_for(caption, round(112 * unit), w * 0.88)
    ascent, descent = f.getmetrics()
    step = ascent + descent + round(10 * unit)
    first = (top - (len(lines) * step - round(10 * unit))) / 2 + round(6 * unit)
    words(canvas, [(line, first + i * step) for i, line in enumerate(lines)], f, "ma", round(6 * unit), 12 * unit)
    return canvas


# The header and search results art: an image of each. Apple publishes no crops, only templates, so these come from
# App Store Connect's preview (November 2026). An iPhone shows only the middle of a 21:9 header, about 54% of its width
# (x 881-2959 of 3840), and only its top two-thirds (to y 1112) above the app's info card, with the back and share
# buttons over its top corners. Search results show a 3:2 image whole, its corners rounded. (A single 16:9 image for
# both, which Apple also takes, comes out cropped far tighter in each, cutting through the caption and the screen.)
HEADER = (3840, 1646)
SEARCH = (3840, 2560)
# The part of the header an iPhone shows, less a margin for narrower phones, and the buttons' band at its top: the
# back button over x 964-1193 and share over 2627-2876, both y 62-306.
HEADER_SAFE = (960, 2880, 1050)
HEADER_BUTTONS = (1193, 2627, 62, 306)


def backdrop(full, w, h):
    """A darkened blur of the screen's middle, clear of the bars and buttons round its edges, so none of them ghosts
    through beside it."""
    middle = full.crop((round(full.width * 0.12), round(full.height * 0.14), round(full.width * 0.88), round(full.height * 0.84)))
    scale = max(w / middle.width, h / middle.height)
    canvas = middle.resize((round(middle.width * scale), round(middle.height * scale)), Image.BICUBIC)
    x0, y0 = (canvas.width - w) // 2, (canvas.height - h) // 2
    canvas = canvas.crop((x0, y0, x0 + w, y0 + h))
    canvas = canvas.resize((w // 8, h // 8), Image.BILINEAR).filter(ImageFilter.GaussianBlur(12)).resize((w, h), Image.BICUBIC)
    return Image.blend(canvas, Image.new("RGB", (w, h), INK), 0.45)


def header(shot, caption):
    """The whole screen under its caption, both inside the part of the header an iPhone shows: the caption between the
    back and share buttons, the screen below it as big as fits above the info card."""
    w, h = HEADER
    left, right, bottom = HEADER_SAFE
    back, share, band_top, band_bottom = HEADER_BUTTONS
    full = shot.convert("RGB")
    canvas = backdrop(full, w, h)
    size = 120
    while font(size).getlength(caption) > share - back - 2 * 70:
        size -= 2
    f = font(size)
    cap = -f.getbbox(caption, anchor="ls")[1]
    baseline = round((band_top + band_bottom + cap) / 2)
    y = baseline + 60
    sh = bottom - y
    sw = round(sh * full.width / full.height)
    if sw > right - left:
        sw = right - left
        sh = round(sw * full.height / full.width)
    place(canvas, full, (w - sw) // 2, y, sw, sh, 28, 8, 18)
    words(canvas, [(caption, baseline)], f, "ms", 6, 12)
    return canvas


def search(shot, caption):
    """The whole screen under its caption, the two as big as fit and centred, clear of the rounded corners."""
    w, h = SEARCH
    margin, gap = 150, 110
    full = shot.convert("RGB")
    canvas = backdrop(full, w, h)
    size = 250
    while font(size).getlength(caption) > w - 2 * margin:
        size -= 5
    f = font(size)
    cap = -f.getbbox(caption, anchor="ls")[1]
    sh = h - 2 * margin - cap - gap
    sw = round(sh * full.width / full.height)
    if sw > w - 2 * margin:
        sw = w - 2 * margin
        sh = round(sw * full.height / full.width)
    top = (h - (cap + gap + sh)) // 2
    baseline = top + cap
    place(canvas, full, (w - sw) // 2, baseline + gap, sw, sh, 64, 16, 36)
    words(canvas, [(caption, baseline)], f, "ms", 14, 28)
    return canvas


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--only", help="comma-separated shots to caption (one-swing,windmill,...)")
    parser.add_argument("--creative", action="store_true",
                        help="set creative.sh's still as the header and search results art: <still> <out dir>")
    parser.add_argument("screenshots", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    config = json.load(open(ROOT / "Tools/capture/screenshots.json"))
    captions = {s["name"]: s["caption"] for s in config["shots"]}
    if args.creative:
        if not args.screenshots.is_file():
            sys.exit(f"no still at {args.screenshots} (Tools/capture/creative.sh)")
        args.out.mkdir(parents=True, exist_ok=True)
        with Image.open(args.screenshots) as image:
            for name, make, (w, h) in (("header", header, HEADER), ("search", search, SEARCH)):
                path = args.out / f"double-putt-{name}.png"
                make(image, config["creative"]["captions"][name]).save(path)
                print(f"{path}: {w}x{h}")
        return
    # Each device's set, as screenshots.sh names it: NN-<shot>[-<pose>] -> the shot.
    sets = {}
    for device, listing in config["devices"].items():
        if device == "about":
            continue
        entries = [entry.partition("@") for entry in listing["shots"]]
        sets[device] = {f"{n:02d}-{name}" + (f"-{pose}" if pose else ""): name for n, (name, _, pose) in enumerate(entries, 1)}
    files = sorted(args.screenshots.glob("[0-9][0-9]-*.png"))
    if not files:
        sys.exit(f"no screenshots in {args.screenshots} (Tools/capture/screenshots.sh)")
    # A whole set, as uploading replaces a device's screenshots with the folder's: none missing, none left over.
    stems = [p.stem for p in files]
    device = next((d for d, stems_of in sets.items() if list(stems_of) == stems), None)
    if device is None:
        fits = [d for d, stems_of in sets.items() if set(stems) <= set(stems_of)]
        if not fits:
            sys.exit(f"{args.screenshots}: {', '.join(s for s in stems if all(s not in v for v in sets.values()))} "
                     "in no device's set in screenshots.json (Tools/capture/screenshots.sh)")
        missing = [s for s in sets[fits[0]] if s not in stems]
        sys.exit(f"{args.screenshots}: missing {', '.join(missing)} of the {fits[0]} set "
                 f"(Tools/capture/screenshots.sh --device {fits[0]})")
    shots = {path: sets[device][path.stem] for path in files}
    only = set(args.only.split(",")) if args.only else None
    args.out.mkdir(parents=True, exist_ok=True)
    done = 0
    for path, name in shots.items():
        if only and name not in only:
            continue
        with Image.open(path) as image:
            framed(image, captions[name]).save(args.out / path.name)
        done += 1
    print(f"{args.out}: {done} screenshots")


main()
