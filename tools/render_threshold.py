"""Render the original Threshold film through the unchanged Umbral360 pipeline.

Requires explicit Godot/FFmpeg paths. Always creates a fresh output folder and
records time, storage and saved-settings preservation outside the job folder.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
from pathlib import Path


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def folder_size(folder):
    total = 0
    for file in folder.rglob("*"):
        try:
            if file.is_file():
                total += file.stat().st_size
        except FileNotFoundError:
            pass  # Pipeline removes its previous scratch frame.
    return total


def render(args):
    project = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    assert not output.exists(), "Choose a fresh output folder"
    assert args.offset >= 0 and 0 < args.seconds <= 60 and args.offset + args.seconds <= 60
    settings = project / ".umbral360/settings.cfg"
    before = hashlib.sha256(settings.read_bytes()).hexdigest() if settings.exists() else None
    output.mkdir(parents=True)
    job = {"scene_path": "res://scenes/films/Threshold.tscn", "camera_path": "Camera3D",
           "width": args.width, "height": args.width // 2, "face_size": args.face_size,
           "fps": 30, "frames": round(args.seconds * 30), "warmup_frames": 2,
           "frame_writer": "fast_png", "crf": 16, "random_seed": 731904,
           "audio_mode": "soundtrack", "soundtrack_path": "res://assets/audio/threshold-score.wav",
           "soundtrack_trim_seconds": args.offset, "threshold_offset": args.offset,
           "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()), "output_dir": str(output)}
    (output / "job.json").write_text(json.dumps(job, indent=2), encoding="utf-8")
    logs = project / ".umbral360" / (output.name + "-run")
    logs.mkdir()
    started = time.monotonic()
    observations = []
    with (logs / "driver.log").open("wb") as log:
        process = subprocess.Popen([str(args.godot.resolve()), "--headless", "--path", str(project),
                                    "--log-file", str(output / "pipeline.log"), "--script",
                                    "res://addons/umbral360/pipeline.gd", "--", "--job=" + str(output / "job.json")],
                                   stdout=log, stderr=log)
        try:
            last = -15
            while process.poll() is None:
                elapsed = time.monotonic() - started
                if elapsed - last >= 15:
                    progress = read_json(output / "render-progress.json")
                    state = read_json(output / "status.json")
                    retained = folder_size(output)
                    free = shutil.disk_usage(output).free
                    observation = {"elapsed_seconds": round(elapsed, 2), "stage": state.get("stage"),
                                   "frame": progress.get("frame", 0), "retained_gib": round(retained / 2**30, 3),
                                   "free_gib": round(free / 2**30, 2)}
                    observations.append(observation)
                    print(json.dumps(observation), flush=True)
                    assert retained < args.max_storage_gib * 2**30, "Configured storage budget exceeded"
                    assert free > 12 * 2**30, "Configured 12 GiB free-space floor reached"
                    last = elapsed
                assert elapsed < args.timeout, "Configured render timeout exceeded"
                time.sleep(0.2)
            assert process.returncode == 0, (logs / "driver.log").read_text(errors="replace")
        finally:
            if process.poll() is None:
                (output / "cancel.request").write_text("Threshold monitor stopped the render")
                try:
                    process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
    report = read_json(output / "report.json")
    capture = read_json(output / "capture-result.json")
    assert report.get("ok") and all(report["checks"].values()), report
    assert capture.get("ok") and capture["rendered"] == job["frames"] + 2, capture
    assert len(list((output / "frames").glob("*.png"))) == job["frames"] + 2
    after = hashlib.sha256(settings.read_bytes()).hexdigest() if settings.exists() else None
    assert after == before, "Saved studio settings changed"
    result = {"ok": True, "wall_seconds": time.monotonic() - started, "job": job,
              "retained_bytes": folder_size(output), "settings_unchanged": True, "settings_sha256": before,
              "pipeline_timings": report.get("pipeline_timings"), "observations": observations}
    (logs / "render-review.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k not in ("observations", "job")}, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("godot", "ffmpeg", "ffprobe", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--width", type=int, choices=[2048, 4096, 7680], default=7680)
    parser.add_argument("--face-size", type=int, default=3072)
    parser.add_argument("--seconds", type=float, default=60)
    parser.add_argument("--offset", type=float, default=0)
    parser.add_argument("--max-storage-gib", type=float, default=96)
    parser.add_argument("--timeout", type=float, default=5400)
    render(parser.parse_args())
