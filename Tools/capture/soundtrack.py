#!/usr/bin/env python3
"""Rebuilds a capture's sound, which the simulator doesn't record.

    Tools/capture/soundtrack.py <frames dir> <out.wav> [--from SECONDS] [--length SECONDS]

The capture (MiniGolf/Game/StoreCapture.swift) logs every sound the game plays in cues.txt, as "<seconds> <name>
<volume>" on the clip's clock, and saves each sound as sounds/<name>.wav. This mixes them as SoundFX plays them:
each at its volume, through the mixer's level (cues.txt's first line), from --from seconds into the clip for
--length seconds (default: to the last sound's end). 48 kHz stereo, 32-bit float.
"""
import argparse
import re
import subprocess
from pathlib import Path

import numpy as np

RATE = 48000


def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(RATE), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)


def mix(frames, start=0.0, length=None):
    """The clip's sound from `start` seconds, as a (samples, 2) float32 array."""
    frames = Path(frames)
    lines = (frames / "cues.txt").read_text().splitlines()
    mixer = float(re.search(r"at ([\d.]+)", lines[0]).group(1)) if lines and lines[0].startswith("#") else 1.0
    cues = [(float(t), name, float(volume)) for t, name, volume in (line.split() for line in lines if line and line[0] != "#")]
    sounds = {name: load(frames / "sounds" / f"{name}.wav") for name in {name for _, name, _ in cues}}
    if length is None:
        length = max([t + len(sounds[name]) / RATE - start for t, name, _ in cues] + [0])
    out = np.zeros((int(round(length * RATE)), 2), dtype=np.float32)
    for t, name, volume in cues:
        audio = sounds[name] * (volume * mixer)
        at = int(round((t - start) * RATE))
        if at < 0:
            audio, at = audio[-at:], 0
        n = min(len(audio), len(out) - at)
        if n > 0:
            out[at:at + n] += audio[:n]
    return out


def write(samples, path):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", "2", "-ar", str(RATE), "-i", "-", "-c:a", "pcm_f32le",
                    str(path)], input=samples.astype(np.float32).tobytes(), check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("frames")
    parser.add_argument("out")
    parser.add_argument("--from", dest="start", type=float, default=0.0)
    parser.add_argument("--length", type=float)
    args = parser.parse_args()
    samples = mix(args.frames, args.start, args.length)
    # Both cups and the double ace's fanfare land together, over full scale: brought down whole, rather than clipped.
    peak = float(np.abs(samples).max()) if len(samples) else 0.0
    if peak > 0.98:
        samples *= 0.98 / peak
    write(samples, args.out)
    print(f"{args.out}: {len(samples) / RATE:.2f}s, peak {peak:.2f}{' (scaled to 0.98)' if peak > 0.98 else ''}")


if __name__ == "__main__":
    main()
