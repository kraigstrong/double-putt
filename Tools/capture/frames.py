#!/usr/bin/env python3
"""Captions Double Putt's App Store screenshots.

    Tools/capture/frames.py [--only one-swing,windmill] <screenshots dir> <out dir>

The screenshots are Tools/capture/screenshots.sh's (NN-<name>.png, at either App Store size); the captions and the
order are Tools/capture/screenshots.json's. Each screen, HUD and all, is shrunk under its caption, in the game's
typeface (SF Rounded Black, as the title's wordmark), over a soft, darkened blur of itself: no device frame. Output
keeps the screenshots' size, with no alpha, as App Store Connect wants.
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
    unit = w / 1320
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
    shots = json.load(open(ROOT / "Tools/capture/screenshots.json"))["shots"]
    found = {p.stem.split("-", 1)[1]: p for p in args.screenshots.glob("[0-9][0-9]-*.png")}
    missing = [s["name"] for s in shots if s["name"] not in found]
    if missing:
        sys.exit(f"missing screenshots: {', '.join(missing)} (Tools/capture/screenshots.sh)")
    only = set(args.only.split(",")) if args.only else None
    args.out.mkdir(parents=True, exist_ok=True)
    for number, shot in enumerate(shots, 1):
        if only and shot["name"] not in only:
            continue
        with Image.open(found[shot["name"]]) as image:
            framed(image, shot["caption"]).save(args.out / f"{number:02d}-{shot['name']}.png")
    print(f"{args.out}: {len(only) if only else len(shots)} screenshots")


main()
