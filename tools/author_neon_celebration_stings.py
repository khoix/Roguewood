#!/usr/bin/env python3
"""UI-A9-N original synth stings for the Neon League's celebrations (Claude,
2026-11-24); no samples or third-party music.

Rebuild: python3 tools/author_neon_celebration_stings.py
Mono signed 16-bit PCM, 44.1 kHz, peak -6 dBFS, deterministic (no randomness but a
seeded noise source per event). Voices: a detuned pulse lead (two slightly apart
oscillators, so it shimmers like a synth), a soft sine bass and a filtered noise
"laser" sweep. Same loudness and lengths as the House stings (UI-A9-H).
"""
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/alley_screen/neon"
RATE = 44100
PEAK = 16422  # -6 dBFS

# (onset s, frequency Hz, length s, voice)
SCORES = {
    # A bright rising arpeggio (A major), the top note held, over a laser sweep up.
    "strike": (0.85, [(0.00, 440.00, .12, "lead"), (0.08, 554.37, .12, "lead"), (0.16, 659.25, .12, "lead"),
                      (0.24, 880.00, .55, "lead"), (0.00, 110.00, .80, "bass")], ("up", 0.0, 0.45)),
    # Two quick notes, a zap between them.
    "spare": (0.65, [(0.00, 659.25, .14, "lead"), (0.14, 987.77, .45, "lead"), (0.00, 164.81, .6, "bass")], ("up", 0.05, 0.25)),
    # A falling zap (the rival's light going out), then a held major chord that swells.
    "boss_defeated": (1.25, [(0.30, 293.66, .9, "lead"), (0.30, 369.99, .9, "lead"), (0.30, 440.00, .9, "lead"),
                             (0.30, 587.33, .9, "lead"), (0.30, 73.42, .9, "bass")], ("down", 0.0, 0.32)),
}


def pulse(phase, width=0.3):
    # A band-limited-ish pulse: a few odd harmonics of a square, shaped by width.
    return sum(math.sin(math.tau * k * phase) * math.sin(math.pi * k * width) / k for k in range(1, 8)) * 0.9


def render(event, length, notes, sweep):
    rng = random.Random("roguewood.ui-a9-n." + event)
    samples = [0.0] * round(length * RATE)
    for onset, frequency, note_len, voice in notes:
        start = round(onset * RATE)
        end = min(len(samples), start + round((note_len + 0.15) * RATE))
        for i in range(start, end):
            t = (i - start) / RATE
            attack = min(1.0, t / (0.006 if voice == "lead" else 0.02))
            release = 1.0 if t < note_len else math.exp(-(t - note_len) * 30.0)
            if voice == "lead":
                tone = 0.5 * (pulse(frequency * t) + pulse(frequency * 1.006 * t)) * 0.32
                body = math.exp(-t * 2.5) * 0.7 + 0.3
            else:
                tone = math.sin(math.tau * frequency * t) * 0.45
                body = math.exp(-t * 3.0)
            samples[i] += attack * release * body * tone
    direction, s_on, s_len = sweep
    start = round(s_on * RATE)
    low = 0.0
    for i in range(start, min(len(samples), start + round(s_len * RATE))):
        u = (i - start) / (s_len * RATE)
        # A one-pole low-pass on noise whose cutoff moves: an airy "laser" sweep.
        cutoff = 0.02 + 0.5 * (u if direction == "up" else 1.0 - u)
        low += cutoff * (rng.uniform(-1, 1) - low)
        tone = math.sin(math.tau * (300 + 2400 * (u if direction == "up" else 1.0 - u)) * (i - start) / RATE)
        samples[i] += (low * 0.35 + tone * 0.06) * math.sin(math.pi * u)
    for i in range(len(samples)):
        samples[i] *= min(1.0, (len(samples) - 1 - i) / (RATE * .06))
    peak = max(abs(x) for x in samples)
    pcm = b"".join(struct.pack("<h", round(x / peak * PEAK)) for x in samples)
    path = OUT / (event + ".wav")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    return {"id": "sound.celebration.neon." + event, "path": str(path.relative_to(ROOT)),
            "seconds": length, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "peak_dbfs": round(20 * math.log10(PEAK / 32768), 2)}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    print(json.dumps([render(event, *score) for event, score in SCORES.items()], indent=2))
