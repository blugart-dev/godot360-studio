"""Compose the original sixty-second THRESHOLD score using NumPy and PCM synthesis.

No recordings, external music, sample libraries or network services are used.
80 BPM; evolving D-minor/F-major harmony, bowed pads, glass motif and transition swells.
"""
from pathlib import Path
import argparse
import hashlib
import json
import wave

import numpy as np

RATE = 48000
DURATION = 60


def compose(destination):
    rng = np.random.default_rng(731904)
    music = np.zeros((RATE * DURATION, 2), dtype=np.float64)

    def place(sound, start, gain, pan=0.0):
        at = round(start * RATE)
        first = max(0, -at)
        last = min(len(sound), len(music) - at)
        if last <= first:
            return
        left, right = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        music[at + first:at + last, 0] += sound[first:last] * gain * left
        music[at + first:at + last, 1] += sound[first:last] * gain * right

    def note(start, duration, midi, gain, pan, kind):
        t = np.arange(round(duration * RATE), dtype=np.float64) / RATE
        frequency = 440 * 2 ** ((midi - 69) / 12)
        if kind == "pad":
            envelope = np.minimum(1, t / 2.8) ** 1.3 * np.minimum(1, (duration - t) / 3.6) ** 1.4
            sound = np.zeros_like(t)
            for detune, phase in [(0.9981, 0.7), (1.0, 0), (1.0017, 1.5)]:
                for harmonic, level in [(1, 1), (2, 0.23), (3, 0.095), (5, 0.035)]:
                    sound += np.sin(2 * np.pi * frequency * detune * harmonic * t + phase) * level / 3
            sound *= envelope * (0.9 + 0.1 * np.sin(2 * np.pi * 0.14 * (start + t)))
        elif kind == "bell":
            envelope = (1 - np.exp(-t * 115)) * np.exp(-t * 1.7) * np.minimum(1, (duration - t) / 0.15)
            sound = (np.sin(2 * np.pi * frequency * t) + 0.38 * np.sin(2 * np.pi * frequency * 2.002 * t) * np.exp(-t * 2)
                     + 0.12 * np.sin(2 * np.pi * frequency * 4.01 * t) * np.exp(-t * 4)) * envelope
        else:
            envelope = (1 - np.exp(-t * 170)) * np.exp(-t * 4.8) * np.minimum(1, (duration - t) / 0.04)
            sound = (np.sin(2 * np.pi * frequency * t) + 0.15 * np.sin(2 * np.pi * frequency * 2 * t)) * envelope
        place(sound, start, gain, pan)

    chords = [(0, [38, 45, 50, 57, 64]), (12.2, [34, 41, 50, 57, 60]),
              (27.2, [41, 48, 52, 57, 62]), (42.2, [38, 45, 50, 57, 65]), (52.5, [38, 45, 54, 61, 66])]
    for start, chord in chords:
        length = 20 if start < 50 else 9
        for index, pitch in enumerate(chord):
            note(start, length, pitch, 0.095 if index < 2 else 0.053, (index - 2) * 0.30, "pad")

    # A recurring six-note thread makes the four sound worlds one continuous piece.
    motifs = [[74, 81, 76, 77, 72, 74], [74, 77, 81, 84, 81, 77],
              [76, 79, 81, 86, 84, 81], [74, 81, 86, 89, 88, 86]]
    for chapter, start in enumerate([1.5, 15.0, 30.0, 45.0]):
        for step in range(16):
            position = start + step * 0.75
            if position > 56.5:
                break
            pitch = motifs[chapter][step % 6]
            strength = (0.035 if step % 2 else 0.064) * [0.75, 0.9, 1.0, 1.1][chapter]
            note(position, 3.8, pitch, strength, np.sin(step * 1.2 + chapter) * 0.65, "bell")
            if chapter in [1, 3] and step % 2 == 0:
                note(position, 1.4, pitch - 24, 0.08, -0.1, "pluck")

    for start in np.arange(3, 54, 3):
        t = np.arange(int(RATE * 0.8)) / RATE
        phase = 2 * np.pi * (43 * t + 3.8 * (1 - np.exp(-t * 20)))
        pulse = np.sin(phase) * (1 - np.exp(-t * 150)) * np.exp(-t * 9)
        place(pulse, start, 0.067)

    def air(length, low, high):
        count = round(length * RATE)
        source = rng.standard_normal(count)
        frequency = np.fft.rfftfreq(count, 1 / RATE)
        curve = np.exp(-((frequency - (high + low) / 2) / ((high - low) / 2)) ** 4)
        sound = np.fft.irfft(np.fft.rfft(source) * curve, n=count)
        return sound / max(0.01, np.max(np.abs(sound)))

    for index, cut in enumerate([14, 29, 44]):
        length = 4.0
        t = np.arange(int(length * RATE)) / RATE
        envelope = np.exp(-((t - 1.55) / 0.95) ** 2)
        swell = air(length, 220, 2200 + index * 500) * envelope
        place(swell, cut - 1.6, 0.14, -0.5)
        place(swell, cut - 1.53, 0.10, 0.5)
        note(cut + 0.08, 5.0, [86, 88, 93][index], 0.08, 0, "bell")

    ambience = air(60, 90, 620)
    envelope = 0.3 + 0.7 * np.sin(np.linspace(0, np.pi, len(ambience))) ** 2
    place(ambience * envelope, 0, 0.027, -0.35)
    place(ambience * envelope, 0.037, 0.022, 0.35)

    dry = music.copy()
    for index, (delay, gain) in enumerate([(0.173, 0.15), (0.289, 0.12), (0.431, 0.11),
                                         (0.677, 0.09), (0.919, 0.075), (1.277, 0.06), (1.733, 0.042), (2.371, 0.025)]):
        offset = round(delay * RATE)
        music[offset:] += dry[:-offset, ::-1 if index % 2 == 0 else 1] * gain
    timeline = np.arange(len(music)) / RATE
    master_fade = np.minimum(1, timeline / 1.3) * np.clip((60 - timeline) / 3.0, 0, 1) ** 1.4
    music *= master_fade[:, None]
    music = np.tanh(music * 1.15)
    music *= 0.85 / np.max(np.abs(music))
    pcm = np.round(music * 32767).astype("<i2")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    result = {"title": "Threshold — Original score", "duration_seconds": 60, "sample_rate": RATE,
              "channels": 2, "tempo_bpm": 80, "transition_centers_seconds": [14, 29, 44],
              "peak": float(np.max(np.abs(music))), "rms": float(np.sqrt(np.mean(music ** 2))),
              "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
              "provenance": "Original deterministic PCM synthesis; no recordings or external samples."}
    destination.with_suffix(".json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent.parent / "assets/audio/threshold-score.wav")
    compose(parser.parse_args().output)
