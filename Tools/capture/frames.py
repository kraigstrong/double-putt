#!/usr/bin/env python3
"""Captions Double Putt's App Store screenshots.

    Tools/capture/frames.py [--only one-swing,windmill] <screenshots dir> <out dir>

The screenshots are one device's whole set from Tools/capture/screenshots.sh (NN-<name>[-<pose>].png, at any App Store
size, upright or sideways), as screenshots.json lists it: a set with shots missing is refused, since uploading it
would replace the device's listing with just those. The captions are screenshots.json's. Each screen, HUD and all, is
shrunk under its caption, in the game's typeface (SF Rounded Black, as the title's wordmark), over a soft, darkened
blur of itself: no device frame. Output keeps the screenshots' names and size, with no alpha, as App Store Connect
wants.
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
    x = (w - sw) // 2
    radius = round(56 * unit)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius, fill=255)
    shadow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((x, top + round(14 * unit), x + sw, top + sh + round(14 * unit)), radius, fill=150)
    canvas.paste(Image.new("RGB", (w, h), (0, 0, 0)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(30 * unit)))
    canvas.paste(full.resize((sw, sh), Image.LANCZOS), (x, top), mask)

    f, lines = lines_for(caption, round(112 * unit), w * 0.88)
    ascent, descent = f.getmetrics()
    step = ascent + descent + round(10 * unit)
    first = (top - (len(lines) * step - round(10 * unit))) / 2 + round(6 * unit)
    rows = [(line, first + i * step) for i, line in enumerate(lines)]
    # A soft shadow under the words, then the words.
    glow = Image.new("L", (w, h), 0)
    for line, y in rows:
        ImageDraw.Draw(glow).text((w / 2, y + round(6 * unit)), line, font=f, fill=170, anchor="ma")
    canvas.paste(Image.new("RGB", (w, h), (4, 10, 8)), (0, 0), glow.filter(ImageFilter.GaussianBlur(12 * unit)))
    draw = ImageDraw.Draw(canvas)
    for line, y in rows:
        draw.text((w / 2, y), line, font=f, fill=(255, 255, 255), anchor="ma")
    return canvas


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--only", help="comma-separated shots to caption (one-swing,windmill,...)")
    parser.add_argument("screenshots", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    config = json.load(open(ROOT / "Tools/capture/screenshots.json"))
    captions = {s["name"]: s["caption"] for s in config["shots"]}
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
