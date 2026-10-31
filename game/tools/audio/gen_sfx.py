#!/usr/bin/env python3
"""Procedurally synthesize all M6-5 SFX and the dungeon ambient loop.

Usage: python3 game/tools/audio/gen_sfx.py
Outputs 16-bit mono 22050 Hz WAV files to game/assets/audio/.
No external samples, no licensing issues.
"""
import math
import pathlib
import wave

import numpy as np

SR = 22050
OUT = pathlib.Path(__file__).resolve().parents[2] / "assets" / "audio"
RNG = np.random.default_rng(20261031)


def write_wav(name: str, samples: np.ndarray) -> None:
    data = np.clip(samples, -1.0, 1.0)
    pcm = (data * 32767.0).astype(np.int16)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("wrote", name, "%.2fs" % (len(data) / SR))


def env(n: int, attack: float, decay: float, power: float = 2.0) -> np.ndarray:
    a = max(1, int(SR * attack))
    d = max(1, int(SR * decay))
    e = np.ones(n)
    a_len = min(a, n)
    e[:a_len] = np.linspace(0, 1, a_len)
    tail = min(d, n - a_len)
    if tail > 0:
        e[a_len:a_len + tail] = np.linspace(1, 0, tail) ** power
    if a_len + tail < n:
        e[a_len + tail:] = 0
    return e


def noise(n: int) -> np.ndarray:
    return RNG.uniform(-1, 1, n)


def lowpass(x: np.ndarray, alpha: float) -> np.ndarray:
    out = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        out[i] = acc
    return out


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(SR * seconds)) / SR


def footstep(seed: int) -> np.ndarray:
    n = int(SR * 0.16)
    x = lowpass(noise(n), 0.18) * env(n, 0.005, 0.14, 3.0)
    thump = np.sin(2 * math.pi * RNG.uniform(60, 90) * np.arange(n) / SR) * env(n, 0.002, 0.08, 2)
    return 0.55 * x + 0.45 * thump


def slash() -> np.ndarray:
    n = int(SR * 0.22)
    t = np.arange(n) / SR
    sweep = np.sin(2 * math.pi * (900 - 600 * t / 0.22) * t) * env(n, 0.004, 0.2, 1.5)
    air = lowpass(noise(n), 0.5) * env(n, 0.01, 0.2, 1.2)
    return 0.5 * sweep + 0.5 * air


def hit() -> np.ndarray:
    n = int(SR * 0.25)
    t = np.arange(n) / SR
    thump = np.sin(2 * math.pi * 105 * t) * env(n, 0.002, 0.18, 2)
    crunch = lowpass(noise(n), 0.35) * env(n, 0.001, 0.09, 3)
    return 0.7 * thump + 0.35 * crunch


def explosion() -> np.ndarray:
    n = int(SR * 0.9)
    t = np.arange(n) / SR
    rumble = np.sin(2 * math.pi * (55 - 20 * t) * t) * env(n, 0.005, 0.85, 2)
    blast = lowpass(noise(n), 0.10) * env(n, 0.002, 0.7, 2)
    return 0.8 * blast + 0.5 * rumble


def electric() -> np.ndarray:
    n = int(SR * 0.35)
    t = np.arange(n) / SR
    buzz = np.sin(2 * math.pi * 220 * t + 6 * np.sin(2 * math.pi * 40 * t))
    crack = (RNG.random(n) > 0.985) * noise(n)
    return (0.5 * buzz + 0.6 * crack) * env(n, 0.002, 0.33, 1.5) * 0.7


def steam() -> np.ndarray:
    n = int(SR * 0.7)
    x = lowpass(noise(n), 0.12) * env(n, 0.01, 0.65, 1.4)
    return 0.7 * x


def door_open() -> np.ndarray:
    n = int(SR * 0.55)
    t = np.arange(n) / SR
    creak = np.sin(2 * math.pi * (140 + 60 * t / 0.55) * t + 3 * np.sin(2 * math.pi * 6 * t))
    return (0.4 * creak + 0.4 * lowpass(noise(n), 0.2)) * env(n, 0.01, 0.5, 1.2)


def build_sound() -> np.ndarray:
    n = int(SR * 0.45)
    t = np.arange(n) / SR
    thud = np.sin(2 * math.pi * 80 * t) * env(n, 0.002, 0.3, 2)
    chime = (np.sin(2 * math.pi * 660 * t) + 0.6 * np.sin(2 * math.pi * 990 * t)) * env(n, 0.01, 0.4, 2)
    return 0.7 * thud + 0.3 * chime


def coin() -> np.ndarray:
    n = int(SR * 0.32)
    t = np.arange(n) / SR
    x = np.sin(2 * math.pi * 1320 * t) * env(n, 0.002, 0.12, 2)
    x += 0.7 * np.sin(2 * math.pi * 1760 * t) * np.roll(env(n, 0.002, 0.12, 2), int(SR * 0.08))
    return 0.5 * x


def ui_click() -> np.ndarray:
    n = int(SR * 0.08)
    t = np.arange(n) / SR
    return np.sin(2 * math.pi * 520 * t) * env(n, 0.001, 0.07, 3) * 0.35


def ui_error() -> np.ndarray:
    n = int(SR * 0.22)
    t = np.arange(n) / SR
    return (np.sin(2 * math.pi * 180 * t) + 0.5 * np.sin(2 * math.pi * 140 * t)) * env(n, 0.002, 0.2, 2) * 0.5


def boss_roar() -> np.ndarray:
    n = int(SR * 1.2)
    t = np.arange(n) / SR
    growl = np.sin(2 * math.pi * (70 + 8 * np.sin(2 * math.pi * 3 * t)) * t)
    growl *= 0.6 + 0.4 * np.sin(2 * math.pi * 22 * t)
    return (0.6 * growl + 0.4 * lowpass(noise(n), 0.06)) * env(n, 0.02, 1.15, 1.6)


def arpeggio(up: bool) -> np.ndarray:
    notes = [523.25, 659.25, 783.99, 1046.5] if up else [659.25, 523.25, 392.0, 261.63]
    n = int(SR * 0.6)
    x = np.zeros(n)
    for i, f in enumerate(notes):
        start = int(SR * 0.12 * i)
        seg_n = n - start
        t = np.arange(seg_n) / SR
        x[start:] += np.sin(2 * math.pi * f * t) * env(seg_n, 0.005, 0.45, 2) * 0.35
    return x


def ambient_loop(seconds: int = 30) -> np.ndarray:
    n = int(SR * seconds)
    t = np.arange(n) / SR
    wind = lowpass(noise(n), 0.005) * (0.5 + 0.5 * np.sin(2 * math.pi * 0.07 * t))
    drone = 0.25 * np.sin(2 * math.pi * 55 * t) + 0.15 * np.sin(2 * math.pi * 82.5 * t)
    fire = np.zeros(n)
    for _ in range(38):
        pos = RNG.integers(0, n - int(SR * 0.2))
        length = int(SR * RNG.uniform(0.03, 0.12))
        crack = noise(length) * env(length, 0.001, 0.1, 3)
        fire[pos:pos + length] += crack * RNG.uniform(0.1, 0.3)
    drips = np.zeros(n)
    for _ in range(12):
        pos = RNG.integers(0, n - int(SR * 0.3))
        length = int(SR * 0.18)
        tt = np.arange(length) / SR
        drip = np.sin(2 * math.pi * (900 - 500 * tt / 0.18) * tt) * env(length, 0.002, 0.16, 2)
        drips[pos:pos + length] += drip * RNG.uniform(0.15, 0.3)
    # crossfade the loop seam (first/last 0.5s)
    xf = int(SR * 0.5)
    mix = np.linspace(0, 1, xf)
    head = wind[:xf].copy()
    wind[:xf] = wind[:xf] * mix + wind[-xf:] * (1 - mix)
    wind[-xf:] = wind[-xf:] * (1 - mix) + head * mix
    mix_all = 0.55 * wind + 0.18 * drone + fire + drips
    return np.tanh(mix_all * 1.1) * 0.55


def main() -> None:
    for i in range(3):
        write_wav(f"footstep_{i + 1}.wav", footstep(i))
    write_wav("slash.wav", slash())
    write_wav("hit.wav", hit())
    dn = int(SR * 0.55)
    dt = np.arange(dn) / SR
    death = np.sin(2 * math.pi * (140 - 60 * dt) * dt) * env(dn, 0.002, 0.5, 2)
    death += 0.5 * lowpass(noise(dn), 0.12) * env(dn, 0.002, 0.45, 2)
    write_wav("death.wav", death * 0.7)
    write_wav("explosion.wav", explosion())
    write_wav("electric.wav", electric())
    write_wav("steam.wav", steam())
    write_wav("door_open.wav", door_open())
    write_wav("build.wav", build_sound())
    write_wav("coin.wav", coin())
    write_wav("ui_click.wav", ui_click())
    write_wav("ui_error.wav", ui_error())
    write_wav("boss_roar.wav", boss_roar())
    write_wav("victory.wav", arpeggio(True))
    write_wav("defeat.wav", arpeggio(False))
    write_wav("ambient_dungeon.wav", ambient_loop(30))


if __name__ == "__main__":
    main()
