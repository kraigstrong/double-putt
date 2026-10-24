"""The trailer's words, drawn for compose.py: captions, and the end card's wordmark like the title screen's.

Everything is a transparent W x H layer in the game's typeface (SF Rounded), drawn once and laid over the frames.
"""
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

FONT = "/System/Library/Fonts/SFNSRounded.ttf"
WHITE = (255, 255, 255, 255)
PUTT = (255, 201, 74, 255)  # Color.putt
INK = (16, 35, 26)  # Palette.ink
SIDES = [(255, 138, 61), (143, 107, 255)]  # Palette.sideA, sideB


def font(size, weight="Black"):
    f = ImageFont.truetype(FONT, round(size))
    f.set_variation_by_name(weight)
    return f


def shadowed(layer, unit, blur=14, opacity=170, drop=6):
    """The layer over a soft dark shadow of itself."""
    shadow = Image.new("RGBA", layer.size, (6, 14, 10, 0))
    shadow.putalpha(layer.split()[3].point(lambda a: a * opacity // 255))
    out = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur * unit)), (0, round(drop * unit)))
    out.alpha_composite(layer)
    return out


def band(size, top, height, strength=0.6):
    """A soft dark band from `top`, darkest at the top edge of the frame (or the bottom one for a low caption)."""
    w, h = size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ramp = Image.linear_gradient("L").resize((w, height))
    if top == 0:
        ramp = ramp.rotate(180)
    tint = Image.new("RGBA", (w, height), (4, 12, 8, 0))
    tint.putalpha(ramp.point(lambda v: round(v * strength * v / 255)))
    layer.alpha_composite(tint, (0, top))
    return layer


def caption(size, text, position="top"):
    """`text` (a "\\n" breaks a line) big and centred: near the top of the frame over a dark band, or low over one."""
    w, h = size
    unit = w / 1080
    f = font(128 * unit)
    lines = text.split("\n")
    while max(f.getlength(line) for line in lines) > w * 0.9:
        f = font(f.size - 4)
    ascent, descent = f.getmetrics()
    step = ascent + descent + round(8 * unit)
    block = len(lines) * step
    if position == "bottom":
        out = band(size, h - round(h * 0.3), round(h * 0.3))
        y = h - round(h * 0.13) - block
    else:
        out = band(size, 0, round(h * 0.3))
        y = round(h * 0.085)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for line in lines:
        draw.text((w / 2, y), line, font=f, fill=WHITE, anchor="ma")
        y += step
    out.alpha_composite(shadowed(layer, unit))
    return out


def ball(diameter, side):
    """A ball as the title draws it (BallGlyph): white, its stripe in the side's color, lit from the top left."""
    k = 4
    d = round(diameter * k)
    image = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.ellipse((0, 0, d - 1, d - 1), fill=(232, 235, 239, 255))
    stripe = round(d * 0.32)
    draw.rectangle(((d - stripe) // 2, 0, (d + stripe) // 2, d), fill=SIDES[side] + (255,))
    shade = Image.radial_gradient("L").resize((d * 2, d * 2)).crop((round(d * 0.3), round(d * 0.4), round(d * 1.3), round(d * 1.4)))
    dark = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    dark.putalpha(shade.point(lambda v: max(0, v - 150) // 2))
    image.alpha_composite(dark)
    draw = ImageDraw.Draw(image)
    draw.ellipse((round(d * 0.19), round(d * 0.2), round(d * 0.47), round(d * 0.4)), fill=(255, 255, 255, 215))
    draw.ellipse((0, 0, d - 1, d - 1), outline=(0, 0, 0, 56), width=max(1, round(d * 0.04)))
    mask = Image.new("L", (d, d), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, d - 1, d - 1), fill=255)
    image.putalpha(ImageChops.multiply(image.split()[3], mask))
    return image.resize((round(diameter), round(diameter)), Image.LANCZOS)


def end_card(size, release_line=""):
    """The wordmark as the title screen draws it, its tagline, and the release line if there is one."""
    w, h = size
    unit = w / 1080 * 2.4  # the title's points, scaled up for the card
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    double, putt = font(58 * unit), font(86 * unit)
    tagline = font(17 * unit * 1.25, "Semibold")
    balls = 30 * unit
    rows = [("balls", balls), ("DOUBLE", sum(double.getmetrics()) * 0.78), ("PUTT", sum(putt.getmetrics()) * 0.78),
            ("tagline", sum(tagline.getmetrics()))]
    total = sum(height for _, height in rows) + 6 * unit * 3
    if release_line:
        total += 60 * unit
    y = (h - total) / 2 - h * 0.04
    wordmark = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(wordmark)
    for side in (0, 1):
        b = ball(balls, side)
        wordmark.alpha_composite(b, (round(w / 2 + (side - 1) * balls - (5 if side == 0 else -5) * unit), round(y)))
    y += balls + 6 * unit
    draw.text((w / 2, y), "DOUBLE", font=double, fill=WHITE, anchor="ma")
    y += rows[1][1] + 6 * unit - 8 * unit
    draw.text((w / 2, y), "PUTT", font=putt, fill=WHITE, anchor="ma")
    y += rows[2][1] + 6 * unit + 4 * unit
    # The wordmark's hard drop, its 3D edge, in ink.
    edge = Image.new("RGBA", size, INK + (0,))
    edge.putalpha(wordmark.split()[3].point(lambda a: a * 150 // 255))
    layer.alpha_composite(edge, (0, round(5 * unit)))
    layer.alpha_composite(wordmark)
    draw = ImageDraw.Draw(layer)
    draw.text((w / 2, y), "One swing. Two greens.", font=tagline, fill=(255, 255, 255, 220), anchor="ma")
    if release_line:
        y += rows[3][1] + 24 * unit
        draw.text((w / 2, y), release_line, font=font(19 * unit), fill=PUTT, anchor="ma")
    return shadowed(layer, w / 1080, blur=18, opacity=140, drop=8)
