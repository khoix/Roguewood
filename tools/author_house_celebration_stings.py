#!/usr/bin/env python3
"""UI-A9-H original wood/brass miniatures; no samples or third-party music.

Rebuild: python3 tools/author_house_celebration_stings.py
Mono signed 16-bit PCM, 44.1 kHz, peak -6 dBFS. Deterministic per-event seed.
These candidates remain out of the live manifest until the complete set passes.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/alley_screen/house"
RATE = 44100
SCORES = {
    "strike": (0.85, [(0.0, 523.25), (0.10, 659.25), (0.20, 783.99), (0.32, 1046.5)]),
    "spare": (0.65, [(0.0, 659.25), (0.16, 783.99)]),
    "boss_defeated": (1.25, [(0.0, 261.63), (0.16, 329.63), (0.32, 392.0),
                             (0.48, 523.25), (0.48, 659.25), (0.48, 783.99)]),
}


def render(event, length, notes):
    rng = random.Random("roguewood.ui-a9-h." + event)
    samples = [0.0] * round(length * RATE)
    for onset, frequency in notes:
        start = round(onset * RATE)
        for i in range(start, len(samples)):
            t = (i - start) / RATE
            attack = min(1.0, t / 0.004)
            # Warm struck-bar fundamental with restrained inharmonic brass partials.
            brass = sum(gain * math.sin(math.tau * frequency * partial * t)
                        * math.exp(-t * decay)
                        for partial, gain, decay in [(1, .55, 7), (2.01, .18, 12), (3.93, .08, 20)])
            wood = rng.uniform(-1, 1) * .10 * math.exp(-t * 95)
            samples[i] += attack * (brass + wood)
    for i in range(len(samples)):
        samples[i] *= min(1.0, (len(samples) - 1 - i) / (RATE * .06))
    peak = max(abs(x) for x in samples)
    pcm = b"".join(struct.pack("<h", round(x / peak * 16422)) for x in samples)
    path = OUT / (event + ".wav")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    return {"id": "sound.celebration.house." + event, "path": str(path.relative_to(ROOT)),
            "seconds": length, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "peak_dbfs": round(20 * math.log10(16422 / 32768), 2)}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    print(json.dumps([render(event, *score) for event, score in SCORES.items()], indent=2))
