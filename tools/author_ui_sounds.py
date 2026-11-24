#!/usr/bin/env python3
"""AV-UI1 (Claude, 2026-11-24; the owner moved it from Codex): the final button
sounds. Original and procedural, no recordings or samples.

Rebuild: python3 tools/author_ui_sounds.py
Mono signed 16-bit PCM, 22.05 kHz (as the foley), 30-80 ms, levelled to UI-12's
loudness (-25 dBFS RMS, peak at most -6.4 dBFS) so they sit under the foley;
deterministic (a seeded noise source per sound).

House (the default; assets/audio/ui_{tap,select,back}.wav, same paths as UI-12's
provisional set, so nothing else changes): the wood-and-brass hall.
  tap     a light, dry wooden press: a short knock, two wood modes and a felt thump;
  select  a brighter tick for toggles and tabs: the knock with a small brass ting;
  back    a softer, lower close: a lower knock, a slower attack, the pitch easing down.
Neon (ui_{tap,select,back}.neon.wav, played during a Neon match): a synthetic click.
  tap     a short pulse blip with a quick pitch drop;
  select  two rising blips;
  back    one falling blip, darker.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio"
RATE = 22050
PEAK = 15500  # about -6.4 dBFS, the ceiling
RMS = 10 ** (-25 / 20) * 32768  # UI-12's provisional set measured -25.3 to -25.4 dBFS


def knock(t, f, decay, rng_value, damp):
    # Wood: an inharmonic pair of modes (1 : 2.73), damped, over a short noise thump.
    tone = (0.55 * math.sin(math.tau * f * t) + 0.28 * math.sin(math.tau * f * 2.73 * t)) * math.exp(-t * decay)
    return tone + 0.4 * rng_value * math.exp(-t * damp)


def house(name, seconds, f, decay, attack, glide=0.0, ting=0.0):
    rng = random.Random("roguewood.av-ui1." + name)
    low = 0.0
    out = []
    for i in range(round(seconds * RATE)):
        t = i / RATE
        n = rng.uniform(-1, 1)
        low = low * 0.7 + n * 0.3  # a darker, felt-like thump
        freq = f * (1.0 - glide * min(t / seconds, 1.0))
        v = knock(t, freq, decay, low, 260.0)
        if ting:
            v += ting * (math.sin(math.tau * 3150 * t) + 0.4 * math.sin(math.tau * 7420 * t)) * math.exp(-t * 90.0)
        out.append(v * min(1.0, t / attack))
    return out


def blip(t, f, drop, length):
    if t < 0 or t > length: return 0.0
    freq = f * (1.0 - drop * t / length)
    phase = freq * t - 0.5 * f * drop * t * t / length
    square = sum(math.sin(math.tau * k * phase) / k for k in (1, 3, 5)) * 0.8
    return square * math.exp(-t / length * 4.0) * min(1.0, t / 0.0015)


def neon(name, seconds, notes):
    out = []
    for i in range(round(seconds * RATE)):
        t = i / RATE
        out.append(sum(gain * blip(t - onset, f, drop, length) for onset, f, drop, length, gain in notes))
    return out


SOUNDS = {
    "ui_tap": lambda: house("ui_tap", 0.045, 1050.0, 95.0, 0.0008),
    "ui_select": lambda: house("ui_select", 0.040, 1350.0, 110.0, 0.0006, ting=0.22),
    "ui_back": lambda: house("ui_back", 0.065, 640.0, 60.0, 0.004, glide=0.18),
    "ui_tap.neon": lambda: neon("ui_tap.neon", 0.040, [(0.0, 1500.0, 0.35, 0.030, 1.0)]),
    "ui_select.neon": lambda: neon("ui_select.neon", 0.050, [(0.0, 1300.0, 0.0, 0.016, 0.8), (0.020, 1950.0, 0.0, 0.026, 1.0)]),
    "ui_back.neon": lambda: neon("ui_back.neon", 0.060, [(0.0, 900.0, 0.45, 0.052, 1.0)]),
}


def write(name, samples):
    fade = round(0.004 * RATE)
    for i in range(fade):
        samples[-1 - i] *= i / fade
    rms_now = math.sqrt(sum(x * x for x in samples) / len(samples))
    gain = min(RMS / rms_now, PEAK / max(abs(x) for x in samples))
    pcm = b"".join(struct.pack("<h", round(x * gain)) for x in samples)
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    values = [x * gain for x in samples]
    rms = math.sqrt(sum(v * v for v in values) / len(values)) / 32768
    return {"path": str(path.relative_to(ROOT)), "ms": round(len(samples) / RATE * 1000),
            "rms_dbfs": round(20 * math.log10(rms), 1), "peak_dbfs": round(20 * math.log10(max(abs(v) for v in values) / 32768), 1), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


if __name__ == "__main__":
    print(json.dumps([write(name, make()) for name, make in SOUNDS.items()], indent=2))
