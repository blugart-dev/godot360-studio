"""Compose AFTERGLOW: original 116 BPM disco-funk, with shared visual note cues.

Requires NumPy and tinysoundfont==0.3.7. The optional --deps directory is added
to sys.path. Supply GeneralUser GS 2.0.3 separately; see docs/afterglow.md.
No song recordings, melodies, or MIDI files are used as source material.
"""
import argparse
import hashlib
import json
import math
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE, DURATION, BPM = 48000, 60, 116
BEAT = 60 / BPM
RNG = np.random.default_rng(116360)
# Two bars each: Dm9 / G13 / Cmaj9 / A7(b9). MIDI numbers, root in the bass.
HARMONY = [(38, [65, 69, 72, 76], [62, 65, 69, 72, 76], 10),
           (31, [65, 69, 71, 76], [59, 65, 69, 71, 76], 10),
           (36, [64, 67, 71, 74], [60, 64, 67, 71, 74], 11),
           (33, [61, 67, 70, 76], [57, 61, 67, 70, 76], 10)]
PRESETS = {'bass': 33, 'guitar': 27, 'muted_guitar': 28, 'keys': 4,
           'strings': 48, 'brass': 61, 'drums': 0, 'percussion': 0}
MIX = {'bass': (1.0, 0), 'guitar': (.56, -.38), 'muted_guitar': (.38, .48),
       'keys': (1.05, .20), 'strings': (1.0, -.08), 'brass': (.72, .12),
       'drums': (.93, 0), 'percussion': (.46, -.24)}


def arrangement():
    tracks = {name: [] for name in PRESETS}

    def note(part, beat, pitch, length, velocity=90, human=0.0):
        # Musical time is the source of truth; persist the performed onset too.
        start = max(0., beat * BEAT + human)
        tracks[part].append({'time': round(start, 6), 'duration': round(length * BEAT, 6),
                             'note': pitch, 'velocity': velocity})

    for bar in range(28):
        root, guitar, keys, seventh = HARMONY[(bar // 2) % 4]
        b = bar * 4
        breakdown = 20 <= bar < 22
        # A two-bar bass conversation, with sixteenth-note pickups and rests.
        pattern = [(0, 0, .62, 110), (.75, 12, .24, 87), (1.5, 0, .28, 103),
                   (1.875, 7, .18, 77), (2.5, seventh, .31, 98),
                   (3, 12, .35, 102), (3.5, 7, .18, 83), (3.75, 0, .20, 94)]
        if bar % 2:
            pattern = [(0, 0, .70, 110), (1, 7, .31, 86), (1.5, 12, .34, 104),
                       (2.25, seventh, .28, 96), (2.75, 7, .20, 81),
                       (3.25, 3 if (bar // 2) % 4 == 0 else 4, .18, 92), (3.5, 2, .16, 80), (3.75, 0, .20, 95)]
        if breakdown:
            pattern = [(0, 12, 1.5, 76), (2.5, 7, .8, 69)]
        for offset, interval, length, vel in pattern:
            note('bass', b + offset, root + interval, length, vel,
                 0 if offset == 0 else float(RNG.uniform(-.003, .006)))
        for q in range(4):
            if not breakdown:
                note('drums', b + q, 36, .18, 102 if q % 2 == 0 else 93)
                if q % 2 and bar >= 2:
                    note('drums', b + q, 38, .16, 88 + bar % 3, .008)
                    if bar >= 8:
                        note('percussion', b + q, 39, .16, 65, .016)
            if bar >= 2:
                for h in range(2 if bar < 8 else 4):
                    div = 2 if bar < 8 else 4
                    off = h / div
                    open_hat = h == div // 2 and not breakdown
                    pitch = 46 if open_hat else 42
                    vel = (64 if open_hat else 40) + (8 if h == 0 else 0) + int(RNG.integers(-6, 6))
                    note('drums', b + q + off, pitch, .12 if open_hat else .07, vel,
                         .006 if h % 2 else 0)
            if bar >= 10 and not breakdown:
                note('percussion', b + q + .5, 54, .12, 57 + q * 3, .003)
                for off, pitch, vel in [(.25, 62, 47), (.75, 64, 56)]:
                    note('percussion', b + q + off, pitch, .15, vel, .007)
        if bar in [4, 8, 12, 16, 22, 26]:
            note('drums', b, 49, 1.5, 73)
        if bar in [7, 15, 21, 25, 27]:
            for n, pitch in enumerate([45, 47, 50, 38]):
                note('drums', b + 3 + n * .25, pitch, .16, 65 + n * 8)
        if bar >= 4:
            offsets = [.5, 1.25, 1.5, 2.5, 2.75, 3.5]
            if breakdown:
                offsets = [.5, 2.5]
            for j, off in enumerate(offsets):
                for k, pitch in enumerate(guitar):
                    note('guitar', b + off, pitch, .13 if j % 3 else .23,
                         66 + (j % 3) * 9 + int(RNG.integers(-4, 5)), k * .003 + .005)
            if bar >= 8 and not breakdown:
                for off in [.25, 1.75, 2.25, 3.75]:
                    for k, pitch in enumerate(guitar[1:]):
                        note('muted_guitar', b + off, pitch, .09, 59, k * .002)
        if bar >= 8:
            for off, length in [(0, 1.15), (1.75, .6), (3, .55)]:
                for k, pitch in enumerate(keys):
                    note('keys', b + off, pitch, length, 65 if off == 0 else 56, k * .006 + .013)
        if bar >= 12 and bar % 2 == 0:
            for k, pitch in enumerate(keys[1:]):
                note('strings', b, pitch + 12, 7.7, 53 if bar < 22 else 66, k * .012)
        if bar >= 16 and not breakdown:
            # Original short brass call; let the rhythm section breathe between calls.
            hook = [(0, guitar[2], .4), (.75, guitar[3], .22), (1.5, guitar[1] + 12, .55)] if bar % 2 == 0 else [(2.5, guitar[3], .28), (3.25, guitar[2], .5)]
            for off, pitch, length in hook:
                note('brass', b + off, pitch, length, 84 if bar >= 22 else 73)
                note('brass', b + off, pitch - 12, length, 66)
    # Resolve to Dm9; the remaining two seconds carry the room's afterglow.
    note('bass', 112, 38, 1.5, 110)
    note('drums', 112, 36, .2, 100)
    note('drums', 112, 49, 2, 78)
    for part, pitches, velocity in [('guitar', HARMONY[0][1], 72), ('keys', HARMONY[0][2], 70),
                                      ('strings', [77, 81, 84, 88], 64), ('brass', [62, 74, 81], 79)]:
        for pitch in pitches:
            note(part, 112, pitch, 1.35, velocity)
    return tracks


def render_stem(events, part, bank):
    import tinysoundfont
    synth = tinysoundfont.Synth(samplerate=RATE, gain=-8)
    sfid = synth.sfload(str(bank))
    synth.program_select(0, sfid, 0, PRESETS[part], is_drums=part in ['drums', 'percussion'])
    timeline = []
    for n in events:
        at = round(n['time'] * RATE)
        timeline.append((at, 1, n['note'], n['velocity']))
        timeline.append((at + round(n['duration'] * RATE), 0, n['note'], 0))
    timeline.sort()
    result = np.zeros((RATE * DURATION, 2), np.float32)
    cursor = 0
    for at, kind, pitch, velocity in timeline + [(len(result), 0, 0, 0)]:
        at = min(at, len(result))
        if at > cursor:
            result[cursor:at] = np.frombuffer(synth.generate(at - cursor), np.float32).reshape(-1, 2)
            cursor = at
        if kind:
            synth.noteon(0, pitch, velocity)
        else:
            synth.noteoff(0, pitch)
    return result


def write_wave(path, audio):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(np.round(np.clip(audio, -.999, .999) * 32767).astype('<i2').tobytes())


def compose(args):
    if args.deps:
        sys.path.insert(0, str(args.deps.resolve()))
    assert not args.output.exists(), 'Choose a fresh output WAV'
    tracks = arrangement()
    mix = np.zeros((RATE * DURATION, 2), np.float32)
    wet = np.zeros_like(mix)
    for part, notes in tracks.items():
        stem = render_stem(notes, part, args.soundfont)
        gain, pan = MIX[part]
        stem *= gain * np.array([math.sqrt(1 - pan), math.sqrt(1 + pan)], np.float32)
        # Keep the bass centered, soften sampled brass, and give strings stereo breadth.
        if part == 'bass':
            stem[:] = np.mean(stem, axis=1)[:, None]
            stem = np.tanh(stem * 1.4) / 1.4
        mix += stem
        if part not in ['bass', 'drums']:
            wet += stem * (.40 if part in ['strings', 'brass'] else .22)
        print(f'{part}: {len(notes)} notes, peak {np.max(np.abs(stem)):.3f}', flush=True)
    # A short stereo room. Preserve dry transients and the bass/drum pocket.
    for i, (delay, gain) in enumerate([(.029, .33), (.047, .29), (.083, .22), (.137, .18),
                                      (.211, .13), (.307, .10), (.419, .07), (.577, .045)]):
        offset = round(delay * RATE)
        mix[offset:] += wet[:-offset, ::-1 if i % 2 else 1] * gain
    # Gentle parallel saturation, with adequate peak room for AAC encoding.
    mix = .82 * mix + .18 * np.tanh(mix * 1.7) / 1.7
    t = np.arange(len(mix)) / RATE
    mix *= (np.clip(t / .012, 0, 1) * np.clip((DURATION - t) / 1.25, 0, 1) ** 1.2)[:, None]
    mix *= .89 / max(.001, float(np.max(np.abs(mix))))
    write_wave(args.output, mix)
    cues = {'title': 'AFTERGLOW', 'bpm': BPM, 'duration': DURATION, 'beats_per_bar': 4,
            'sections': [{'bar': bar, 'time': round(bar * 4 * BEAT, 6), 'name': name}
                         for bar, name in [(0, 'Heartbeat'), (4, 'Find the pocket'), (8, 'Colour'),
                                           (12, 'Ascend'), (16, 'The room sings'), (20, 'Suspended'),
                                           (22, 'All together'), (28, 'Afterglow')]],
            'tracks': tracks}
    args.output.with_suffix('.cues.json').write_text(json.dumps(cues, separators=(',', ':')) + '\n')
    report = {'duration': DURATION, 'sample_rate': RATE, 'channels': 2, 'bpm': BPM,
              'peak': float(np.max(np.abs(mix))), 'rms_dbfs': float(20 * np.log10(np.sqrt(np.mean(mix ** 2)))),
              'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest(),
              'soundfont_sha256': hashlib.sha256(args.soundfont.read_bytes()).hexdigest(),
              'soundfont': 'GeneralUser GS 2.0.3, S. Christian Collins',
              'original_composition': True, 'note_counts': {k: len(v) for k, v in tracks.items()}}
    args.output.with_suffix('.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--soundfont', type=Path, required=True)
    parser.add_argument('--deps', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/audio/afterglow-score.wav')
    compose(parser.parse_args())
