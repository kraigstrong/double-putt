#!/usr/bin/env python3
"""Composes Double Putt's trailer from recorded clips, its words, the game's sounds and a music track.

    Tools/capture/trailer/compose.py <edl.json> <footage dir> <out.mp4> --site|--store [--music <file>] [--preview S]

The edit (edl.json) lists shots on one timeline: each is a stretch of a clip's footage (Tools/capture/footage.sh,
build/capture/footage/<clip>.mp4) from "in" seconds for "dur", with a slow camera move: "zoom" (1 shows the whole
screen, HUD and all) and "center" (fractions of the screen from the top left), eased from start to end. Where the
frame is wider than the screen, the screen sits over a blur of itself. "end_card" softens and darkens the shot behind
the wordmark from "blur_at" seconds into it. Captions show between two times, fading and popping in. "only" keeps a
shot or caption to one cut ("site" or "store"); each cut's shots fill the same timeline.

--site is the trailer for the site: 1080x1920, 60 fps, with the release line if the edit has one. --store is the App
Store preview: 886x1920 (the 6.9" iPhone's), 30 fps, no release line, 15-30 seconds. The sound is each shot's own (the
clip's .wav, rebuilt from the game's sounds) under the music, if there is a track (--music, or TRAILER_MUSIC); without
one it's the game's sounds alone.
"""
import json
import math
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import captions  # noqa: E402

FPS = 60
RATE = 48000
SIZES = {"site": (1080, 1920), "store": (886, 1920)}


def probe(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                          "-of", "json", path], capture_output=True, text=True, check=True).stdout
    stream = json.loads(out)["streams"][0]
    return stream["width"], stream["height"]


def frames_of(path, size, start, count):
    """Decoded RGB frames of a clip, from `start` seconds."""
    sw, sh = size
    proc = subprocess.Popen(["ffmpeg", "-v", "error", "-ss", f"{start:.4f}", "-i", path, "-frames:v", str(count),
                             "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    for _ in range(count):
        data = proc.stdout.read(sw * sh * 3)
        if len(data) < sw * sh * 3:
            break
        yield Image.frombuffer("RGB", (sw, sh), data, "raw", "RGB", 0, 1)
    proc.stdout.close()
    if proc.wait() != 0:
        sys.exit(f"ffmpeg could not decode {path}")


def ease(u):
    return u * u * (3 - 2 * u)


def framed(image, out, zoom, cx, cy):
    """The screen through a camera zoomed `zoom` times about (cx, cy), in fractions of it, at the output size. At zoom 1
    the whole screen's height shows; where that leaves the frame wider than the screen, a blur of it fills the sides."""
    sw, sh = image.size
    w, h = out
    vh = sh / zoom
    vw = vh * w / h
    y0 = min(max(cy * sh - vh / 2, 0), sh - vh)
    if vw <= sw:
        x0 = min(max(cx * sw - vw / 2, 0), sw - vw)
        return image.transform((w, h), Image.EXTENT, (x0, y0, x0 + vw, y0 + vh), Image.BICUBIC)
    shown = image.transform((round(sw * h / vh), h), Image.EXTENT, (0, y0, sw, y0 + vh), Image.BICUBIC)
    small = shown.resize((max(1, w // 10), max(1, h // 10)), Image.BILINEAR).filter(ImageFilter.GaussianBlur(4))
    back = Image.blend(small.resize((w, h), Image.BICUBIC), Image.new("RGB", (w, h), captions.INK), 0.35)
    back.paste(shown, ((w - shown.width) // 2, 0))
    return back


def decode_audio(path, start=0.0, length=None):
    cmd = ["ffmpeg", "-v", "error", "-ss", f"{start:.4f}", "-i", path]
    if length is not None:
        cmd += ["-t", f"{length:.4f}"]
    raw = subprocess.run(cmd + ["-f", "f32le", "-ac", "2", "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()


def soundtrack(edl, shots, footage, total, music_path):
    """The shots' own sounds where they fall on the timeline, under the music."""
    mix = np.zeros((round(total * RATE) + RATE, 2), dtype=np.float32)
    at = 0.0
    edge = round(0.008 * RATE)
    for shot in shots:
        wav = os.path.join(footage, shot["clip"] + ".wav")
        if shot.get("speed", 1) == 1 and os.path.exists(wav):
            sound = decode_audio(wav, shot["in"], shot["dur"])
            if len(sound) > 2 * edge:
                # A few milliseconds' fade at each cut, so a sound cut short doesn't click.
                ramp = np.linspace(0, 1, edge, dtype=np.float32)[:, None]
                sound[:edge] *= ramp
                sound[-edge:] *= ramp[::-1]
            i = round(at * RATE)
            n = min(len(sound), len(mix) - i)
            mix[i:i + n] += sound[:n] * edl.get("sfx_gain", 0.8)
        at += shot["dur"]
    if music_path:
        music = edl.get("music", {})
        track = decode_audio(music_path, music.get("offset", 0), total)
        n = min(len(track), len(mix), round(total * RATE))
        envelope = np.ones(n, dtype=np.float32)
        fade_in = min(n, round(music.get("fade_in", 0.05) * RATE))
        fade_out = min(n, round(music.get("fade_out", 1.5) * RATE))
        envelope[:fade_in] *= np.linspace(0, 1, fade_in, dtype=np.float32)
        envelope[n - fade_out:] *= np.linspace(1, 0, fade_out, dtype=np.float32)
        mix[:n] += track[:n] * envelope[:, None] * music.get("gain", 1.0)
    mix = mix[:round(total * RATE)]
    peak = float(np.abs(mix).max()) if len(mix) else 0
    if peak > 0.98:
        mix *= 0.98 / peak
    return mix


def main():
    edl_path, footage, out = sys.argv[1:4]
    variant = "store" if "--store" in sys.argv else "site"
    preview = float(sys.argv[sys.argv.index("--preview") + 1]) if "--preview" in sys.argv else None
    music_path = sys.argv[sys.argv.index("--music") + 1] if "--music" in sys.argv else os.environ.get("TRAILER_MUSIC")
    if music_path and not os.path.exists(music_path):
        sys.exit(f"no music track at {music_path}")
    W, H = SIZES[variant]
    out_fps = 30 if variant == "store" else FPS
    edl = json.load(open(edl_path))
    shots = [s for s in edl["shots"] if s.get("only", variant) == variant]
    total = sum(s["dur"] for s in shots)
    if variant == "store" and not 15 <= total <= 30:
        sys.exit(f"the App Store preview would be {total:.2f}s; it has to be 15-30")
    for shot in shots:
        shot["src"] = os.path.join(footage, shot["clip"] + ".mp4")
        if not os.path.exists(shot["src"]):
            sys.exit(f"no footage of {shot['clip']}: Tools/capture/footage.sh {shot['clip']}")
    source = probe(shots[0]["src"])
    words = []
    for c in edl["captions"]:
        if c.get("only", variant) != variant:
            continue
        if c.get("end_card"):
            layer = captions.end_card((W, H), edl.get("release_line", "") if variant == "site" else "")
        else:
            layer = captions.caption((W, H), c["text"], c.get("position", "top"))
        words.append((layer, c["in"], c["out"], c.get("fade", 0.12), c.get("pop", True)))

    sound = soundtrack(edl, shots, footage, total, music_path)
    if not music_path:
        print("no music track (--music or TRAILER_MUSIC): the game's sounds alone", file=sys.stderr)
    with tempfile.NamedTemporaryFile(suffix=".wav") as wav:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", "2", "-ar", str(RATE), "-i", "-", wav.name],
                       input=sound.astype(np.float32).tobytes(), check=True)
        encoder = subprocess.Popen(
            ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
             "-i", wav.name, "-map", "0:v", "-map", "1:a", "-r", str(out_fps),
             "-c:v", "libx264", "-preset", "slow", "-profile:v", "high", "-crf", str(edl.get("crf", 17)), "-pix_fmt", "yuv420p",
             "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
             "-t", f"{(preview or total):.3f}", out], stdin=subprocess.PIPE)
        written, limit = 0, round((preview or total) * FPS)
        last = len(shots) - 1
        for index, shot in enumerate(shots):
            n = round(shot["dur"] * FPS)
            z0, z1 = shot.get("zoom", [1, 1])
            c0, c1 = shot.get("center", [[0.5, 0.5], [0.5, 0.5]])
            speed = shot.get("speed", 1)
            decoded = frames_of(shot["src"], source, shot["in"], math.floor((n - 1) * speed) + 1)
            image, at = None, -1
            for i in range(n):
                # A clip that runs short holds its last frame rather than let the cuts drift.
                while at < math.floor(i * speed):
                    nxt = next(decoded, None)
                    if nxt is None:
                        print(f"{shot['clip']} runs short at {shot['in']}+{i / FPS:.2f}s", file=sys.stderr)
                        break
                    image, at = nxt, at + 1
                u = ease(i / max(n - 1, 1))
                frame = framed(image, (W, H), z0 + (z1 - z0) * u, c0[0] + (c1[0] - c0[0]) * u, c0[1] + (c1[1] - c0[1]) * u)
                if shot.get("end_card"):
                    k = min(1, max(0, i - shot.get("blur_at", 0) * FPS) / (0.5 * FPS))
                    if k > 0:
                        frame = Image.blend(frame, frame.filter(ImageFilter.GaussianBlur(20 * k)), k)
                        frame = Image.blend(frame, Image.new("RGB", (W, H), captions.INK), 0.55 * k)
                t = (written + 0.5) / FPS
                frame = frame.convert("RGBA")
                for layer, t_in, t_out, fade, pop in words:
                    if not t_in <= t < t_out:
                        continue
                    a = min(1, (t - t_in) / fade, (t_out - t) / fade) if fade > 0 else 1
                    shown = layer
                    if pop and t - t_in < 0.25:
                        s = 1.06 - 0.06 * ease((t - t_in) / 0.25)
                        big = layer.resize((round(W * s), round(H * s)), Image.BICUBIC)
                        shown = big.crop(((big.width - W) // 2, (big.height - H) // 2, (big.width - W) // 2 + W, (big.height - H) // 2 + H))
                    if a < 1:
                        shown = shown.copy()
                        shown.putalpha(shown.split()[3].point(lambda v: round(v * a)))
                    frame.alpha_composite(shown)
                frame = frame.convert("RGB")
                # In from black at the start, and out to it at the end.
                k = min(1, t / 0.3, (total - t) / 0.5) if index in (0, last) else 1
                if k < 1:
                    frame = Image.blend(Image.new("RGB", (W, H)), frame, max(0, k))
                encoder.stdin.write(frame.tobytes())
                written += 1
                if written >= limit:
                    break
            next(decoded, None)
            if written >= limit:
                break
        encoder.stdin.close()
        if encoder.wait() != 0:
            sys.exit(f"ffmpeg could not encode {out}")
    print(f"{out}: {W}x{H}, {out_fps} fps, {written / FPS:.2f}s{', with music' if music_path else ''}")


main()
