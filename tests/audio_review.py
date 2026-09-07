"""Exercise complete audio exports and measure decoded timing against source samples.

Requires numpy, Pillow, Godot, FFmpeg and FFprobe. Creates fresh fixtures and job
folders; verifies all source hashes and the user's saved studio settings.
"""
import argparse
import hashlib
import json
import subprocess
import time
import wave
from pathlib import Path

import numpy as np
from PIL import Image

RATE = 48000
DURATION = 6
SAMPLES = RATE * DURATION


def run(args, timeout=90, check=True):
    return subprocess.run([str(arg) for arg in args], capture_output=True, timeout=timeout, check=check)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(path):
    return {str(file.relative_to(path)): sha(file) for file in path.rglob("*") if file.is_file()}


def tones(times, amplitude=0.25, rate=RATE, duration=DURATION):
    result = np.zeros((round(duration * rate), 2), dtype=np.float64)
    count = round(0.1 * rate)
    t = np.arange(count) / rate
    # Chirps give a unique correlation peak, unlike a repeating pure tone.
    pulse = amplitude * np.sin(2 * np.pi * (400 * t + 3500 * t * t)) * np.sin(np.pi * np.arange(count) / count) ** 2
    for seconds in times:
        start = round(seconds * rate)
        if start + count <= len(result):
            result[start:start + count, 0] = pulse
            result[start:start + count, 1] = pulse * 0.8
    return result


def write_wav(path, samples, rate=RATE):
    pcm = np.round(np.clip(samples, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as file:
        file.setnchannels(samples.shape[1])
        file.setsampwidth(2)
        file.setframerate(rate)
        file.writeframes(pcm.tobytes())
    return pcm.astype(np.float64) / 32768


def fixture(folder, fps=30, warmup=2, amplitude=0.25, duration=DURATION, cue_times=(0.5, 2, 5)):
    folder.mkdir()
    frames = folder / "frames"
    frames.mkdir()
    for index in range(round(fps * duration) + warmup):
        n = max(0, index - warmup)
        flash = n in [round(fps * value) for value in cue_times]
        Image.new("RGB", (256, 128), (230, 220, 150) if flash else (12, 25, 40)).save(frames / f"frame{index:08d}.png")
    scene = tones(cue_times, amplitude, duration=duration)
    prefix = np.zeros((round(warmup * RATE / fps), 2))
    recorded = write_wav(frames / "frame.wav", np.concatenate([prefix, scene]))
    job = {"scene_path": "res://scene-not-installed.tscn", "camera_path": "Camera3D", "width": 256, "height": 128,
           "face_size": 128, "fps": fps, "frames": round(fps * duration), "warmup_frames": warmup, "crf": 18,
           "frame_writer": "fast_png", "output_dir": str(folder)}
    (folder / "job.json").write_text(json.dumps(job), encoding="utf-8")
    (folder / "capture-result.json").write_text('{"ok":true}', encoding="utf-8")
    return recorded[len(prefix):], job


def place(samples, trim=0, offset=0, gain=0, duration=DURATION):
    skip = round(trim * RATE) + max(0, -round(offset * RATE))
    delay = max(0, round(offset * RATE))
    result = np.zeros((round(duration * RATE), 2), dtype=np.float64)
    samples = samples[skip:]
    count = max(0, min(len(samples), len(result) - delay))
    if count:
        result[delay:delay + count] = samples[:count] * 10 ** (gain / 20)
    return result


def decode(path, ffmpeg):
    data = run([ffmpeg, "-v", "error", "-i", path, "-map", "0:a:0", "-f", "f32le", "-ac", "2", "-ar", RATE, "-"]).stdout
    return np.frombuffer(data, dtype="<f4").reshape(-1, 2).astype(np.float64)


def compare(decoded, expected):
    samples = len(expected)
    assert samples <= len(decoded) < samples + 1024, "Unexpected decoded AAC duration"
    decoded = decoded[:samples]
    energy = np.sum(expected ** 2)
    if energy == 0:
        peak = float(np.max(np.abs(decoded)))
        assert peak < 0.0001, ("Expected silence", peak)
        return {"silent": True, "peak": peak}
    error = np.sum((decoded - expected) ** 2)
    snr = float(10 * np.log10(energy / max(error, 1e-20)))
    assert snr > 20, ("Decoded audio differs from independently placed source", snr)
    active = np.abs(expected[:, 0]) > 0.005
    boundaries = np.flatnonzero(active & ~np.roll(active, 1))
    starts = []
    for boundary in boundaries:
        if not starts or boundary - starts[-1] > RATE // 4:
            starts.append(int(boundary))
    lags = []
    for start in starts:
        left, right = max(256, start - 100), min(samples - 256, start + 5000)
        if left >= right:
            continue
        reference = expected[left:right, 0]
        candidate = decoded[left - 256:right + 256, 0]
        lag = int(np.argmax(np.correlate(candidate, reference, "valid")) - 256)
        assert abs(lag) <= 48, ("Cue offset exceeds 1 ms", lag)
        lags.append(lag)
    return {"snr_db": snr, "cue_lags_samples": lags, "peak": float(np.max(np.abs(decoded)))}


def export(args, folder, source, audio, render=False, timeout=90):
    folder.mkdir()
    request = {"mode": "reencode", "source_dir": str(source), "output_dir": str(folder),
               "ffmpeg": str(args.ffmpeg), "ffprobe": str(args.ffprobe), "crf": 18, **audio}
    if render:
        request.update(json.loads((source / "job.json").read_text()))
        request.update(mode="render", scene_path="res://addons/godot360/examples/calibration.tscn", output_dir=str(folder))
    job = folder / "job.json"
    job.write_text(json.dumps(request), encoding="utf-8")
    completed = run([args.godot, "--headless", "--path", args.project, "--log-file", folder / "pipeline.log",
                     "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(job)], check=False, timeout=timeout)
    (folder / "driver.log").write_bytes(completed.stdout + completed.stderr)
    return completed


def review(args):
    args.project, args.ffmpeg, args.ffprobe, args.godot = [path.resolve() for path in (args.project, args.ffmpeg, args.ffprobe, args.godot)]
    root = args.output.resolve()
    root.mkdir(parents=True)
    settings = args.project / ".godot360/settings.cfg"
    settings_hash = sha(settings)
    scene, recipe = fixture(root / "source")
    soundtrack_path = root / "sound ' & [cue].wav"
    soundtrack = write_wav(soundtrack_path, tones([0.8, 2.5, 4.7]))
    short_path = root / "short.wav"
    short = write_wav(short_path, tones([0.8], duration=1.5))
    before = snapshot(root / "source")
    soundtrack_hash = sha(soundtrack_path)
    cases = [
        ("scene-later", {"scene_audio_offset_seconds": 0.15, "scene_audio_gain_db": -6}, place(scene, offset=0.15, gain=-6)),
        ("scene-earlier", {"scene_audio_offset_seconds": -0.25}, place(scene, offset=-0.25)),
        ("soundtrack-trim-delay", {"audio_mode": "soundtrack", "soundtrack_trim_seconds": 0.2, "soundtrack_offset_seconds": 0.3}, place(soundtrack, trim=0.2, offset=0.3)),
        ("soundtrack-earlier", {"audio_mode": "soundtrack", "soundtrack_trim_seconds": 0.2, "soundtrack_offset_seconds": -0.15}, place(soundtrack, trim=0.2, offset=-0.15)),
        ("short-padded", {"audio_mode": "soundtrack", "soundtrack_path": str(short_path)}, place(short)),
        ("later-than-film", {"audio_mode": "soundtrack", "soundtrack_offset_seconds": 8}, np.zeros_like(scene)),
        ("advanced-past-end", {"audio_mode": "soundtrack", "soundtrack_offset_seconds": -30}, np.zeros_like(scene)),
        ("mix", {"audio_mode": "mix", "scene_audio_offset_seconds": 0.1, "scene_audio_gain_db": -6, "soundtrack_trim_seconds": 0.2,
                 "soundtrack_offset_seconds": 0.3, "soundtrack_gain_db": -6}, place(scene, offset=0.1, gain=-6) + place(soundtrack, trim=0.2, offset=0.3, gain=-6)),
    ]
    results = {}
    video_packets = None
    for name, controls, expected in cases:
        controls.setdefault("soundtrack_path", str(soundtrack_path))
        folder = root / name
        completed = export(args, folder, root / "source", controls)
        assert completed.returncode == 0, (name, (folder / "driver.log").read_text())
        report = json.loads((folder / "report.json").read_text())
        assert report["ok"] and len(report["checks"]) == 13 and all(report["checks"].values()), name
        measured = compare(decode(folder / "video-360.mp4", args.ffmpeg), expected)
        packets = run([args.ffprobe, "-v", "error", "-select_streams", "v:0", "-show_packets", "-show_data_hash", "sha256",
                       "-show_entries", "packet=pts,dts,duration,data_hash", "-of", "json", folder / "video-360.mp4"]).stdout
        if video_packets is None:
            video_packets = packets
        assert packets == video_packets, (name, "Video payload/timestamps changed with audio settings")
        results[name] = {"ok": True, "checks": 13, "video_packets_unchanged": True, **measured}
        print(name, json.dumps(results[name]), flush=True)
    # Resampling/mono conversion and an exact cue clock at 24 and 60 FPS.
    mono_path = root / "mono-44100.flac"
    mono_wav = root / "mono-44100.wav"
    write_wav(mono_wav, tones([0.8, 2.5, 4.7], rate=44100)[:, :1], rate=44100)
    run([args.ffmpeg, "-v", "error", "-n", "-i", mono_wav, mono_path])
    mono_reference = decode(mono_path, args.ffmpeg)[:SAMPLES]
    for fps in (24, 60):
        source = root / f"source-{fps}"
        fixture(source, fps=fps, warmup=0)
        source_hashes = snapshot(source)
        folder = root / f"mono-{fps}"
        completed = export(args, folder, source, {"audio_mode": "soundtrack", "soundtrack_path": str(mono_path), "soundtrack_offset_seconds": 0.125})
        assert completed.returncode == 0, (folder / "driver.log").read_text()
        report = json.loads((folder / "report.json").read_text())
        assert report["ok"] and all(report["checks"].values())
        results[f"mono-{fps}"] = {"ok": True, **compare(decode(folder / "video-360.mp4", args.ffmpeg), place(mono_reference, offset=0.125))}
        assert snapshot(source) == source_hashes
        print(f"mono-{fps}", json.dumps(results[f"mono-{fps}"]), flush=True)
    # Preflight rejects existing non-audio/corrupt files before launching capture.
    invalid = root / "invalid.wav"
    invalid.write_bytes(b"not an audio file")
    for name, path in [("corrupt", invalid), ("no-audio", root / "source/frames/frame00000000.png")]:
        folder = root / name
        completed = export(args, folder, root / "source", {"audio_mode": "soundtrack", "soundtrack_path": str(path)}, render=True)
        assert completed.returncode != 0 and not (folder / "capture.log").exists() and not (folder / "video-360.mp4").exists()
        results[name] = {"ok": True, "rejected_before_capture": True}
    assert snapshot(root / "source") == before and sha(soundtrack_path) == soundtrack_hash
    assert sha(settings) == settings_hash
    summary = {"ok": True, "source_files_unchanged": True, "settings_unchanged": True, "cases": results}
    (root / "audio-review.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("renders") / ("audio-06-" + time.strftime("%Y%m%d-%H%M%S")))
    review(parser.parse_args())
