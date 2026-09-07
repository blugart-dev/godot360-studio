"""Inspect actual motion-fixture PNG/MP4 pixels and audio against analytic geometry.

Requires Python, numpy, Pillow, and FFmpeg. Render tests/fixtures/motion.tscn for
six seconds through pipeline.gd, then pass its folder and --ffmpeg executable.
"""
import argparse
import json
import math
from pathlib import Path
import subprocess
import tempfile

import numpy as np
from PIL import Image


def geometry(pixels, time_seconds):
    height, width = pixels.shape[:2]
    red, green, blue = pixels[:, :, 0], pixels[:, :, 1], pixels[:, :, 2]
    masks = {
        "horizontal": (red > 200) & (green > 70) & (green < 200) & (blue < 60),
        "vertical": (red < 70) & (green > 150) & (blue > 200),
    }
    phase = time_seconds * math.tau / 6.0
    segment = (time_seconds / 0.75) % 2
    camera_x = 0.4 * (segment if segment <= 1 else 2 - segment)
    positions = {
        "horizontal": np.array([4 * math.sin(phase) - camera_x, 0, -4 * math.cos(phase)]),
        "vertical": np.array([-camera_x, 3 * math.cos(phase), 3 * math.sin(phase)]),
    }
    results = {}
    for name, mask in masks.items():
        rows, columns = np.nonzero(mask)
        if len(rows) == 0:
            results[name] = {"error_degrees": 180.0, "area_ratio": 0.0}
            continue
        longitude = ((columns + 0.5) / width - 0.5) * math.tau
        latitude = (0.5 - (rows + 0.5) / height) * math.pi
        # Pixel area shrinks toward the poles. A spherical centroid also handles
        # the rear seam without treating the image edges as distant points.
        weights = np.cos(latitude)
        rays = np.stack([weights * np.sin(longitude), np.sin(latitude), -weights * np.cos(longitude)], axis=1)
        measured = np.sum(rays * weights[:, None], axis=0)
        measured /= np.linalg.norm(measured)
        position = positions[name]
        distance = np.linalg.norm(position)
        expected = position / distance
        error = math.degrees(math.acos(np.clip(np.dot(measured, expected), -1, 1)))
        solid_angle = np.sum(weights) * math.tau / width * math.pi / height
        expected_area = math.tau * (1 - math.sqrt(1 - (0.18 / distance) ** 2))
        results[name] = {"error_degrees": error, "area_ratio": float(solid_angle / expected_area)}
    results["flash"] = int(np.count_nonzero((red > 180) & (green < 60) & (blue > 180))) > 30
    return results


def inspect_frames(frames, fps):
    summaries = {name: {"max_error_degrees": 0.0, "min_area_ratio": 10.0, "max_area_ratio": 0.0} for name in ["horizontal", "vertical"]}
    flash_frames = []
    failures = []
    count = 0
    for index, pixels in enumerate(frames):
        count += 1
        result = geometry(pixels, index / fps)
        if result["flash"]:
            flash_frames.append(index)
        for name in summaries:
            current = result[name]
            summary = summaries[name]
            summary["max_error_degrees"] = max(summary["max_error_degrees"], current["error_degrees"])
            summary["min_area_ratio"] = min(summary["min_area_ratio"], current["area_ratio"])
            summary["max_area_ratio"] = max(summary["max_area_ratio"], current["area_ratio"])
            if current["error_degrees"] > 0.45 or not 0.8 <= current["area_ratio"] <= 1.2:
                failures.append({"frame": index, "marker": name, **current})
    expected_flash = [i for i in range(count) if any(start <= i / fps < start + 0.1 - 1e-8 for start in [1, 3, 5])]
    return {"frames": count, "markers": summaries, "flash_frames": flash_frames,
            "flash_timing_ok": flash_frames == expected_flash, "geometry_failures": failures}


def decoded_frames(ffmpeg, path, width, height):
    with tempfile.TemporaryFile() as diagnostics:
        child = subprocess.Popen([ffmpeg, "-v", "error", "-nostdin", "-i", str(path), "-map", "0:v:0", "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1"],
                                 stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=diagnostics)
        try:
            size = width * height * 3
            while True:
                data = child.stdout.read(size)
                if not data:
                    break
                if len(data) != size:
                    raise RuntimeError("Incomplete decoded video frame")
                yield np.frombuffer(data, np.uint8).reshape(height, width, 3)
            if child.wait() != 0:
                diagnostics.seek(0)
                raise RuntimeError(diagnostics.read().decode(errors="replace"))
        finally:
            child.stdout.close()
            if child.poll() is None:
                child.kill()
                child.wait()


def inspect_audio(ffmpeg, path, fps, trim=0):
    args = [ffmpeg, "-v", "error", "-nostdin", "-i", str(path), "-map", "0:a:0"]
    if trim:
        args += ["-af", f"atrim=start={trim:.9f},asetpts=PTS-STARTPTS"]
    args += ["-ar", "48000", "-ac", "2", "-f", "f32le", "pipe:1"]
    data = subprocess.run(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
    samples = np.frombuffer(data, dtype="<f4").reshape(-1, 2)
    active = np.max(np.abs(samples), axis=1) > 0.015
    windows = [float(np.sqrt(np.mean(samples[i:i + 480] ** 2))) for i in range(0, len(samples), 480)]
    cues = []
    for second in [1, 3, 5]:
        start = round((second - 0.1) * 48000)
        end = round((second + 0.2) * 48000)
        offsets = np.flatnonzero(active[start:end])
        onset = float((start + offsets[0]) / 48000) if len(offsets) else None
        cues.append({"expected_seconds": second, "onset_seconds": onset,
                     "within_one_frame": onset is not None and abs(onset - second) <= 1 / fps,
                     "within_10_ms": onset is not None and abs(onset - second) <= 0.01})
    unexpected = [i / 100 for i, rms in enumerate(windows) if rms > 0.01 and not any(s - 0.04 <= i / 100 <= s + 0.14 for s in [1, 3, 5])]
    return {"samples_per_channel": len(samples), "cues": cues, "unexpected_audio_windows": unexpected,
            "ok": all(c["within_one_frame"] and c["within_10_ms"] for c in cues) and not unexpected}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--ffmpeg", required=True)
    args = parser.parse_args()
    job = json.loads((args.folder / "job.json").read_text())
    assert job["scene_path"] == "res://tests/fixtures/motion.tscn", "Use the analytic motion fixture"
    fps, count, warmup = int(job["fps"]), int(job["frames"]), int(job["warmup_frames"])
    assert count == 6 * fps, "Render the whole six-second fixture"
    def pngs():
        for index in range(count):
            with Image.open(args.folder / "frames" / f"frame{index + warmup:08d}.png") as frame:
                yield np.array(frame.convert("RGB"))
    source = inspect_frames(pngs(), fps)
    encoded = inspect_frames(decoded_frames(args.ffmpeg, args.folder / "video-360.mp4", int(job["width"]), int(job["height"])), fps)
    source_audio = inspect_audio(args.ffmpeg, args.folder / "frames/frame.wav", fps, warmup / fps)
    encoded_audio = inspect_audio(args.ffmpeg, args.folder / "video-360.mp4", fps)
    report = {"source_images": source, "encoded_images": encoded, "source_audio": source_audio, "encoded_audio": encoded_audio}
    report["ok"] = all(result["frames"] == count and result["flash_timing_ok"] and not result["geometry_failures"] for result in [source, encoded]) and source_audio["ok"] and encoded_audio["ok"]
    (args.folder / "motion-review.json").write_text(json.dumps(report, indent=2) + "\n")
    compact = {key: {k: v for k, v in value.items() if k != "geometry_failures"} if isinstance(value, dict) else value for key, value in report.items()}
    print(json.dumps(compact, indent=2))
    if not report["ok"]:
        print("See motion-review.json for failed frame details.")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
