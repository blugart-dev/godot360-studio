"""Render a sustained GPU capture, then inspect every source/decoded frame.

The visual bit code detects omissions, duplication and delayed frame sampling.
Sparse audio cues measure absolute alignment and drift across the whole clip.
Requires numpy, Pillow, Godot, FFmpeg/FFprobe and a display/GPU. Fresh outputs only.
"""
import argparse
import json
import math
import subprocess
import time
from pathlib import Path

import numpy as np
from PIL import Image
from audio_review import RATE, compare, decode, sha, tones
from motion_review import decoded_frames

CUES = (0.5, 15, 30, 45, 60, 75, 88)


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def retained_bytes(folder):
    total = 0
    for path in folder.rglob("*"):
        try:
            if path.is_file():
                total += path.stat().st_size
        except FileNotFoundError:
            # Movie Maker scratch images are removed while capture is running.
            continue
    return total


def cue_times(duration):
    cues = [cue for cue in CUES if cue + 0.1 < duration]
    if duration > 2.5:
        cues.append(duration - 2)
    return sorted(set(cues))


def inspect_images(images, count, fps, width, height, cues, label):
    columns = [round((0.5 + math.radians(-60 + bit * 10) / math.tau) * width - 0.5) for bit in range(13)]
    row = round(height * 0.5 - 0.5)
    flash_row = round((0.5 - math.atan(0.25) / math.pi) * height - 0.5)
    failures, flashes, seen = [], [], 0
    for index, pixels in enumerate(images):
        seen += 1
        bits = [int(np.mean(pixels[row - 1:row + 2, column - 1:column + 2]) > 150) for column in columns]
        number = sum(value << bit for bit, value in enumerate(bits))
        if number != index:
            failures.append({"frame": index, "visible_number": number})
        if np.mean(pixels[flash_row - 1:flash_row + 2, width // 2 - 1:width // 2 + 2]) > 150:
            flashes.append(index)
        if seen % (fps * 10) == 0:
            print(label, "inspected", seen, "/", count, flush=True)
    expected = [index for index in range(count) if any(cue <= index / fps < cue + 0.1 - 1e-6 for cue in cues)]
    result = {"ok": seen == count and not failures and flashes == expected, "frames": seen,
              "frame_number_failures": failures[:100], "failure_count": len(failures),
              "flash_frames": flashes, "flash_timing_ok": flashes == expected}
    return result


def audio_clock(samples, duration, fps, cues):
    reference = tones([0], duration=0.1)[:, 0]
    results = []
    for cue in cues:
        if cue + 0.1 >= duration:
            continue
        start = round(cue * RATE)
        candidate = samples[start - 2048:start + len(reference) + 2048, 0]
        lag = int(np.argmax(np.correlate(candidate, reference, "valid")) - 2048)
        results.append({"cue_seconds": cue, "lag_samples": lag, "lag_ms": lag * 1000 / RATE})
    lags = [cue["lag_samples"] for cue in results]
    assert lags
    span = max(lags) - min(lags)
    return {"ok": max(abs(lag) for lag in lags) <= RATE / fps and span <= 48,
            "cues": results, "drift_span_samples": span, "within_one_frame": all(abs(lag) <= RATE / fps for lag in lags)}


def review(args):
    for key in ("project", "godot", "ffmpeg", "ffprobe", "output"):
        setattr(args, key, getattr(args, key).resolve())
    args.output.mkdir(parents=True)
    folder = args.output / "capture"
    folder.mkdir()
    settings = args.project / ".umbral360/settings.cfg"
    before = sha(settings) if settings.exists() else None
    count, fps, warmup, width, height = args.seconds * args.fps, args.fps, 2, args.width, args.width // 2
    assert 1 <= args.seconds <= 90 and count < 8192, "The thirteen-bit fixture supports runs up to 90 seconds"
    assert 128 <= args.face_size <= 4096
    cues = cue_times(args.seconds)
    job = {"scene_path": "res://tests/fixtures/endurance.tscn", "camera_path": "Camera3D", "width": width, "height": height,
           "face_size": args.face_size, "fps": fps, "frames": count, "warmup_frames": warmup, "frame_writer": "fast_png",
           "crf": 18, "output_dir": str(folder), "ffmpeg": str(args.ffmpeg), "ffprobe": str(args.ffprobe)}
    (folder / "job.json").write_text(json.dumps(job))
    started = time.monotonic()
    observations = []
    with (args.output / "driver.log").open("wb") as log:
        child = subprocess.Popen([str(args.godot), "--headless", "--path", str(args.project), "--log-file", str(folder / "pipeline.log"),
                                  "--script", "res://addons/umbral360/pipeline.gd", "--", "--job=" + str(folder / "job.json")], stdout=log, stderr=log)
        try:
            last_print = 0
            while child.poll() is None:
                progress = read_json(folder / "render-progress.json")
                state = read_json(folder / "status.json")
                elapsed = time.monotonic() - started
                if elapsed - last_print > 10:
                    retained = retained_bytes(folder)
                    sample = {"elapsed_seconds": round(elapsed, 2), "stage": state.get("stage"), "frame": progress.get("frame", 0),
                              "scratch_images": len(list((folder / "movie").glob("*.png"))), "retained_bytes": retained}
                    observations.append(sample)
                    print(json.dumps(sample), flush=True)
                    last_print = elapsed
                    assert retained < args.max_storage_gib * 1024 ** 3, "Test exceeded its retained-storage budget"
                assert elapsed < args.timeout, "Capture exceeded the configured test timeout"
                time.sleep(0.1)
            assert child.returncode == 0, (args.output / "driver.log").read_text()
        finally:
            if child.poll() is None:
                (folder / "cancel.request").write_text("Endurance test cleanup")
                try:
                    child.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
    report = read_json(folder / "report.json")
    assert report.get("ok") and len(report["checks"]) == 13 and all(report["checks"].values()), report
    capture = read_json(folder / "capture-result.json")
    assert capture.get("ok") and capture["rendered"] == count + warmup
    assert len(list((folder / "frames").glob("*.png"))) == count + warmup
    assert not list((folder / "movie").glob("*.png")), "Scratch PNGs were not cleaned up"

    def pngs():
        for index in range(count):
            with Image.open(folder / "frames" / f"frame{index + warmup:08d}.png") as frame:
                yield np.array(frame.convert("RGB"))

    source = inspect_images(pngs(), count, fps, width, height, cues, "Source")
    print("Source frames", source["frames"], "failures", source["failure_count"], flush=True)
    encoded = inspect_images(decoded_frames(str(args.ffmpeg), folder / "video-360.mp4", width, height), count, fps, width, height, cues, "Decoded")
    print("Decoded frames", encoded["frames"], "failures", encoded["failure_count"], flush=True)
    original_audio = decode(folder / "frames/frame.wav", args.ffmpeg)[round(warmup * RATE / fps):][:args.seconds * RATE]
    final_audio = decode(folder / "video-360.mp4", args.ffmpeg)
    source_clock = audio_clock(original_audio, args.seconds, fps, cues)
    final_clock = audio_clock(final_audio, args.seconds, fps, cues)
    audio_preserved = compare(final_audio, original_audio)
    unchanged = (sha(settings) if settings.exists() else None) == before
    result = {"ok": source["ok"] and encoded["ok"] and source_clock["ok"] and final_clock["ok"] and unchanged,
              "seconds": args.seconds, "fps": fps, "width": width, "height": height,
              "face_size": args.face_size, "cue_times": cues, "max_storage_gib": args.max_storage_gib,
              "retained_bytes": retained_bytes(folder),
              "source_images": source, "encoded_images": encoded, "source_audio_clock": source_clock,
              "encoded_audio_clock": final_clock, "encoded_audio_preservation": audio_preserved,
              "pipeline_timings": report["pipeline_timings"], "observations": observations,
              "scratch_cleaned": True, "settings_unchanged": unchanged}
    (args.output / "endurance-review.json").write_text(json.dumps(result, indent=2))
    print(json.dumps({key: value for key, value in result.items() if key not in ("source_images", "encoded_images", "observations")}, indent=2), flush=True)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--seconds", type=int, default=90)
    parser.add_argument("--fps", type=int, choices=[24, 25, 30, 50, 60], default=60)
    parser.add_argument("--width", type=int, choices=[512, 1024, 2048, 4096, 7680], default=1024)
    parser.add_argument("--face-size", type=int, default=512)
    parser.add_argument("--timeout", type=int, default=900, help="Pipeline timeout in seconds")
    parser.add_argument("--max-storage-gib", type=float, default=16, help="Stop disposable capture if retained files exceed this budget")
    parser.add_argument("--output", type=Path, required=True)
    raise SystemExit(review(parser.parse_args()))
