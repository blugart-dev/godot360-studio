"""Synthesize LUMEN's original 24-second stereo score; no recordings or samples."""
import argparse
import hashlib
import json
import wave
from pathlib import Path

import numpy as np

RATE, DURATION = 48000, 24


def compose(destination):
    destination = destination.resolve()
    assert not destination.exists(), 'Use a fresh score destination'
    audio = np.zeros((RATE * DURATION, 2), dtype=np.float64)

    def place(signal, start, gain, pan=0):
        at = round(start * RATE)
        count = min(len(signal), len(audio) - at)
        if count > 0:
            audio[at:at + count] += signal[:count, None] * gain * np.array([np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)])

    for start, pitches in [(0, [38, 45, 52, 57, 64]), (7, [41, 48, 55, 60, 67]), (14, [43, 50, 57, 62, 69]), (20, [38, 45, 54, 61, 66])]:
        t = np.arange(10 * RATE) / RATE
        envelope = np.minimum(1, t / 1.8) * np.minimum(1, (10 - t) / 3) ** 2
        for index, pitch in enumerate(pitches):
            frequency = 440 * 2 ** ((pitch - 69) / 12)
            signal = (np.sin(2 * np.pi * frequency * t) + 0.35 * np.sin(2 * np.pi * frequency * 1.0018 * t + 0.8) + 0.13 * np.sin(2 * np.pi * frequency * 2 * t)) * envelope
            place(signal, start, 0.095 if index < 2 else 0.055, (index - 2) * 0.32)
    motif = [74, 81, 76, 83, 81, 78, 76, 73]
    for step in range(39):
        t = np.arange(3 * RATE) / RATE
        frequency = 440 * 2 ** ((motif[step % 8] - 69) / 12)
        envelope = (1 - np.exp(-t * 100)) * np.exp(-t * 2) * np.minimum(1, (3 - t) / 0.1)
        signal = (np.sin(2 * np.pi * frequency * t) + .25 * np.sin(2 * np.pi * frequency * 2.003 * t) * np.exp(-t * 4)) * envelope
        place(signal, 1 + step * .5, .095 if step % 2 == 0 else .055, np.sin(step * .8) * .65)
    for beat in range(10):
        t = np.arange(RATE) / RATE
        signal = np.sin(2 * np.pi * (42 * t + 2.4 * (1 - np.exp(-t * 18)))) * (1 - np.exp(-t * 160)) * np.exp(-t * 7)
        place(signal, 2 + beat * 2, .1)
    dry = audio.copy()
    for index, (delay, gain) in enumerate([(.233, .20), (.417, .14), (.733, .10), (1.13, .075), (1.67, .045)]):
        offset = round(delay * RATE)
        audio[offset:] += dry[:-offset, ::-1 if index % 2 == 0 else 1] * gain
    time = np.arange(len(audio)) / RATE
    audio *= (np.minimum(1, time / 1.1) * np.clip((24 - time) / 2.5, 0, 1) ** 1.5)[:, None]
    audio = np.tanh(audio)
    audio *= .8 / np.max(np.abs(audio))
    pcm = np.round(audio * 32767).astype('<i2')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), 'wb') as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(pcm.tobytes())
    report = {'duration': DURATION, 'sample_rate': RATE, 'channels': 2, 'peak': float(np.max(np.abs(audio))), 'sha256': hashlib.sha256(destination.read_bytes()).hexdigest(), 'original_synthesis': True}
    print(json.dumps(report, indent=2))
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1] / 'assets/audio/lumen-score.wav')
    compose(parser.parse_args().output)
