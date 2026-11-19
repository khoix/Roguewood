#!/usr/bin/env python3
"""UI-22 (owner, 2026-11-19): the award ceremony's sound effects, synthesized.

Original sounds made from oscillators and filtered noise with fixed seeds, so the
files rebuild byte for byte: python3 tools/author_award_sounds.py
Writes assets/audio/awards/*.wav (44.1 kHz, mono, 16-bit). Requires numpy.
"""
from __future__ import annotations

import pathlib
import wave

import numpy as np

RATE = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "audio" / "awards"


def t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * RATE)) / RATE


def env(n: int, attack: float, release: float) -> np.ndarray:
    """A linear attack then an exponential release, over n samples."""
    a = max(1, int(attack * RATE))
    out = np.ones(n)
    out[:a] = np.linspace(0.0, 1.0, a)
    tail = np.arange(n - a) / RATE
    out[a:] = np.exp(-tail / max(release, 1e-4))
    return out


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    """A one-pole low-pass; cutoff may be an array (a sweep)."""
    cut = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1.0 - np.exp(-2.0 * np.pi * cut / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    return x - lowpass(x, cutoff)


def chirp(start: float, end: float, seconds: float, shape: str = "sine") -> np.ndarray:
    tt = t(seconds)
    freq = start * (end / start) ** (tt / seconds)
    phase = 2.0 * np.pi * np.cumsum(freq) / RATE
    return np.sin(phase) if shape == "sine" else np.sign(np.sin(phase)) * 0.6


def bell(freq: float, seconds: float, decay: float) -> np.ndarray:
    tt = t(seconds)
    partials = [(1.0, 1.0), (2.76, 0.45), (5.4, 0.25), (8.93, 0.12)]
    out = sum(a * np.sin(2 * np.pi * freq * m * tt) * np.exp(-tt * (1.0 + m * 0.6) / decay) for m, a in partials)
    return out * env(len(tt), 0.002, decay * 2)


def place(buffer: np.ndarray, sound: np.ndarray, at: float) -> None:
    start = int(at * RATE)
    end = min(len(buffer), start + len(sound))
    buffer[start:end] += sound[: end - start]


def write(name: str, samples: np.ndarray, peak: float = 0.7) -> None:
    samples = samples / max(1e-9, np.max(np.abs(samples))) * peak
    fade = min(len(samples), int(0.01 * RATE))
    samples[-fade:] *= np.linspace(1.0, 0.0, fade)
    data = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    print(f"{name}: {len(samples) / RATE:.2f} s")


def main() -> None:
    rng = np.random.default_rng(20261119)

    # A whoosh: noise swept through a rising then falling low-pass.
    n = int(0.55 * RATE)
    sweep = 400 + 5200 * np.sin(np.linspace(0, np.pi, n)) ** 2
    write("award_whoosh.wav", lowpass(rng.standard_normal(n), sweep) * env(n, 0.18, 0.12), 0.55)

    # A drumroll: dense snare taps that swell, for the moment before a trophy.
    roll = np.zeros(int(1.1 * RATE))
    for i in range(44):
        at = i * 0.024 + rng.uniform(-0.003, 0.003)
        tap = highpass(rng.standard_normal(int(0.05 * RATE)), 1800) * env(int(0.05 * RATE), 0.001, 0.012)
        place(roll, tap * (0.35 + 0.65 * i / 43), max(0.0, at))
    write("award_drumroll.wav", roll, 0.55)

    # The trophy reveal: a bright bell arpeggio (C, E, G, C, E) over a shimmer.
    reveal = np.zeros(int(1.6 * RATE))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5]):
        place(reveal, bell(f, 1.2, 0.35) * 0.6, i * 0.07)
    shimmer = highpass(rng.standard_normal(len(reveal)), 6000) * env(len(reveal), 0.05, 0.4) * 0.12
    write("award_reveal.wav", reveal + shimmer, 0.7)

    # A firework's launch: a rising whistle with a hiss under it.
    launch = chirp(700, 2600, 0.8) * env(int(0.8 * RATE), 0.05, 0.5) * 0.5
    launch += lowpass(rng.standard_normal(len(launch)), 3000) * env(len(launch), 0.01, 0.25) * 0.25
    write("firework_launch.wav", launch, 0.45)

    # A firework's burst: a low thump that drops in pitch, then a crackling tail.
    burst = np.zeros(int(1.6 * RATE))
    tt = t(0.6)
    place(burst, np.sin(2 * np.pi * np.cumsum(90 * np.exp(-tt * 4) + 40) / RATE) * np.exp(-tt * 6), 0)
    place(burst, lowpass(rng.standard_normal(int(0.5 * RATE)), 900) * env(int(0.5 * RATE), 0.002, 0.12) * 0.9, 0)
    for _ in range(70):
        at = 0.12 + rng.exponential(0.35)
        if at < 1.5:
            click = highpass(rng.standard_normal(int(0.006 * RATE)), 3000) * np.exp(-np.arange(int(0.006 * RATE)) / 60)
            place(burst, click * rng.uniform(0.2, 0.7) * np.exp(-at * 1.5), at)
    write("firework_burst.wav", burst, 0.75)

    # A bottle rocket: a quick, wavering whistle, then a small pop.
    rocket = np.zeros(int(0.85 * RATE))
    whistle = chirp(1200, 3200, 0.55) * (1 + 0.15 * np.sin(2 * np.pi * 18 * t(0.55))) * env(int(0.55 * RATE), 0.01, 0.4) * 0.45
    place(rocket, whistle, 0)
    pop = highpass(rng.standard_normal(int(0.08 * RATE)), 700) * env(int(0.08 * RATE), 0.001, 0.02)
    place(rocket, pop, 0.56)
    write("bottle_rocket.wav", rocket, 0.6)

    # A confetti popper: a sharp pop, then paper fluttering down.
    confetti = np.zeros(int(1.0 * RATE))
    place(confetti, highpass(rng.standard_normal(int(0.05 * RATE)), 400) * env(int(0.05 * RATE), 0.0005, 0.012), 0)
    flutter = highpass(rng.standard_normal(int(0.9 * RATE)), 2500)
    flutter *= (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 9 * t(0.9) + rng.uniform(0, 3)))) * env(len(flutter), 0.05, 0.3) * 0.22
    place(confetti, flutter, 0.04)
    write("confetti_pop.wav", confetti, 0.6)

    # A goal's tick: a short soft blip (its pitch rises in play as the bar fills).
    tick = np.sin(2 * np.pi * 880 * t(0.07)) * env(int(0.07 * RATE), 0.002, 0.018)
    write("goal_tick.wav", tick, 0.45)

    # A goal completed: a stamp's thump and a bright major chord.
    done = np.zeros(int(1.2 * RATE))
    tt = t(0.25)
    place(done, np.sin(2 * np.pi * 70 * tt) * np.exp(-tt * 18) + lowpass(rng.standard_normal(len(tt)), 600) * np.exp(-tt * 30) * 0.6, 0)
    for f in (659.25, 830.61, 987.77, 1318.5):
        place(done, bell(f, 1.0, 0.3) * 0.35, 0.05)
    write("goal_complete.wav", done, 0.75)


if __name__ == "__main__":
    main()
