"""Demanding native 4K/8K exports with sampled memory, storage and delivery checks.

Prepare a disposable project once, then use fresh output directories for each
renderer/resolution. Current system telemetry is Windows PDH; it does not imply
native Linux/Mac validation. No creative scene, saved recipe or master is edited.
"""
import argparse
import hashlib
import json
import math
import os
import platform
import shutil
import subprocess
import threading
import time
from pathlib import Path

import numpy as np
from PIL import Image
from audio_review import decode, tones, compare as compare_audio
from endurance_review import read_json, cue_times, retained_bytes
from production_metrics import WindowsMemory

ROOT = Path(__file__).resolve().parents[1]
FLAGS = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
FILES = ["production_scene.gd", "production_scene.tscn", "production_estimate.gd", "endurance.gd", "temporal_history.gd"]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(project):
    paths = [project / "project.godot"]
    paths += [p for folder in ["addons/godot360", "tests", "generated"] for p in (project / folder).rglob("*")
              if p.is_file() and "__pycache__" not in p.parts]
    return {p.relative_to(project).as_posix(): sha(p) for p in paths}


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def environment(folder):
    env = os.environ.copy()
    for name in ["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]:
        target = folder / "profile" / name
        target.mkdir(parents=True, exist_ok=True)
        env[name] = str(target)
    return env


def textures(folder):
    folder.mkdir(parents=True)
    size = 2048
    y, x = np.mgrid[:size, :size].astype(np.float32) / size
    rng = np.random.default_rng(3602026)
    records = {}
    for i in range(12):
        grain = rng.random((size, size), dtype=np.float32) * .16
        veins = .5 + .24 * np.sin(x * (31 + i) + np.sin(y * 37) * 3) + .12 * np.cos(y * 61 + x * 23)
        base = np.stack([veins * (.7 + i / 40) + grain, veins * (.5 + (11 - i) / 30) + grain, veins * .65 + grain], axis=-1)
        normal_x = .15 * np.sin(x * (31 + i))
        normal_y = .15 * np.cos(y * 61 + x * 23)
        normal = np.stack([normal_x, normal_y, np.sqrt(1 - normal_x ** 2 - normal_y ** 2)], axis=-1) * .5 + .5
        for kind, values in [("albedo", base), ("normal", normal)]:
            file = folder / f"{kind}-{i:02d}.png"
            Image.fromarray((values.clip(0, 1) * 255).astype(np.uint8)).save(file)
            records[file.name] = {"sha256": sha(file), "bytes": file.stat().st_size, "width": size, "height": size}
    return records


def prepare(args, output):
    project = output / "project"
    shutil.copytree(ROOT / "addons/godot360", project / "addons/godot360")
    (project / "tests/fixtures").mkdir(parents=True)
    for name in FILES:
        shutil.copy2(ROOT / "tests/fixtures" / name, project / "tests/fixtures" / name)
    for name in ["production_review.py", "production_metrics.py", "endurance_review.py", "audio_review.py", "motion_review.py"]:
        shutil.copy2(ROOT / "tests" / name, project / "tests" / name)
    (project / "project.godot").write_text('''config_version=5
[application]
config/name="Godot360 production benchmark"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="vulkan"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    assets = textures(project / "generated/textures")
    with (output / "import.log").open("wb") as log:
        result = subprocess.run([str(args.godot), "--headless", "--path", str(project), "--editor", "--import", "--quit"],
                                env=environment(output), stdout=log, stderr=log, timeout=300, creationflags=FLAGS)
    errors = [line for line in (output / "import.log").read_text(errors="replace").splitlines()
              if line.startswith(("ERROR:", "SCRIPT ERROR:")) and line != "ERROR: Failed to read the root certificate store."]
    assert result.returncode == 0 and not errors, errors[:10]
    save(output / "prepared.json", {"ok": True, "textures": assets, "hashes": snapshot(project)})
    print("Prepared production fixture:", project, flush=True)
    return project


class Monitor:
    def __init__(self, folder, root_pid, max_gib, timeout):
        self.folder, self.root_pid = folder, root_pid
        self.max_gib, self.timeout = max_gib, timeout
        self.phase = "Pipeline"
        self.started = time.monotonic()
        self.stop = threading.Event()
        self.error = None
        self.rows = []
        self.api = WindowsMemory()
        self.baseline = self.api.sample()
        self.thread = threading.Thread(target=self.collect, daemon=True)

    def collect(self):
        try:
            with (self.folder.parent / "memory-samples.jsonl").open("w", encoding="utf-8") as log:
                while not self.stop.is_set():
                    t = time.monotonic() - self.started
                    state = read_json(self.folder / "status.json")
                    progress = read_json(self.folder / "render-progress.json")
                    # The Windows console launcher is distinct from the real
                    # coordinator. Read this fresh job's diagnostic identities.
                    extra = [read_json(self.folder / "session.json").get("pid")]
                    if state.get("stage") == "Rendering":
                        extra += [read_json(self.folder / "production-worker.json").get("pid"), progress.get("writer_pid")]
                    sample = self.api.sample(self.root_pid, extra if self.phase == "Pipeline" else ())
                    sample.update(seconds=round(t, 3), stage=state.get("stage", "Starting") if self.phase == "Pipeline" else self.phase,
                                  frame=progress.get("frame", 0), disk_free_bytes=shutil.disk_usage(self.folder).free,
                                  retained_bytes=retained_bytes(self.folder), scratch_bytes=retained_bytes(self.folder / "movie"))
                    self.rows.append(sample)
                    log.write(json.dumps(sample) + "\n")
                    log.flush()
                    if len(self.rows) % 10 == 0:
                        print(json.dumps({k: sample[k] for k in ["seconds", "stage", "frame", "retained_bytes", "process_private_bytes", "process_gpu_dedicated_bytes", "process_gpu_shared_bytes"]}), flush=True)
                    if t > self.timeout or sample["retained_bytes"] > self.max_gib * 2**30 or sample["disk_free_bytes"] < 16 * 2**30 or sample["system_available_bytes"] < 3 * 2**30:
                        raise RuntimeError("Benchmark limit reached: elapsed time, storage budget, disk floor or system-memory floor; see memory-samples.jsonl")
                    self.stop.wait(2.0)
        except BaseException as error:
            self.error = str(error)
            (self.folder / "cancel.request").write_text(self.error)
        finally:
            self.api.close()

    def finish(self):
        self.stop.set()
        self.thread.join(timeout=15)
        if self.thread.is_alive():
            raise RuntimeError("Memory monitor did not stop")

    def summary(self):
        def peaks(rows):
            keys = ["retained_bytes", "scratch_bytes", "system_used_bytes", "process_private_bytes", "process_working_set_bytes", "process_gpu_dedicated_bytes", "process_gpu_shared_bytes"]
            result = {k: max((r[k] for r in rows if r.get(k) is not None), default=None) for k in keys}
            result["all_adapters_dedicated_bytes"] = max((sum(r["adapter_dedicated_bytes"].values()) for r in rows), default=None)
            return result
        stages = sorted({r["stage"] for r in self.rows})
        return {"sample_interval_seconds": 2.0, "samples": len(self.rows), "baseline": self.baseline,
                "sampled_peaks": peaks(self.rows), "by_stage": {s: peaks([r for r in self.rows if r["stage"] == s]) for s in stages},
                "counter_errors": [r["counter_errors"] for r in self.rows if r["counter_errors"]], "monitor_error": self.error}


def roi(width, height):
    columns = [round((.5 + math.radians(-60 + bit * 10) / math.tau) * width - .5) for bit in range(13)]
    row = round(height * .5 - .5)
    flash_row = round((.5 - math.atan(.25) / math.pi) * height - .5)
    left, top = (columns[0] - 4) // 2 * 2, (flash_row - 4) // 2 * 2
    right, bottom = (columns[-1] + 6) // 2 * 2, (row + 6) // 2 * 2
    return (left, top, right, bottom), [c - left for c in columns], row - top, flash_row - top


def inspect(images, job, box, columns, row, flash_row):
    seen, failures, flashes = 0, [], []
    for index, pixels in enumerate(images):
        seen += 1
        number = sum((int(pixels[row-1:row+2, col-1:col+2].mean() > 150) << bit) for bit, col in enumerate(columns))
        if number != index:
            failures.append({"frame": index, "number": number})
        center = job["width"] // 2 - box[0]
        if pixels[flash_row-1:flash_row+2, center-1:center+2].mean() > 150:
            flashes.append(index)
    cues = cue_times(job["frames"] / job["fps"])
    expected = [i for i in range(job["frames"]) if any(c <= i / job["fps"] < c + .1 - 1e-6 for c in cues)]
    return {"ok": seen == job["frames"] and not failures and flashes == expected, "frames": seen,
            "failure_count": len(failures), "failures": failures[:50], "flashes": flashes, "flash_timing_ok": flashes == expected}


def decode_roi(ffmpeg, file, box, diagnostics):
    x, y, right, bottom = box
    width, height = right-x, bottom-y
    with diagnostics.open("wb") as log:
        process = subprocess.Popen([str(ffmpeg), "-v", "error", "-nostdin", "-i", str(file), "-map", "0:v:0",
                                    "-vf", f"crop={width}:{height}:{x}:{y}", "-pix_fmt", "rgb24", "-f", "rawvideo", "pipe:1"],
                                   stdout=subprocess.PIPE, stderr=log, creationflags=FLAGS)
        try:
            size = width * height * 3
            while True:
                data = process.stdout.read(size)
                if not data:
                    break
                assert len(data) == size, "Truncated decoded frame"
                yield np.frombuffer(data, np.uint8).reshape(height, width, 3)
            assert process.wait() == 0, diagnostics
        finally:
            process.stdout.close()
            if process.poll() is None:
                process.kill()
                process.wait()


def audio_clock(samples, duration, fps, cues):
    reference = tones([0], duration=.1)[:, 0]
    energy = float(np.dot(reference, reference))
    rows = []
    # Search broadly enough to diagnose startup offsets rather than reporting
    # the boundary of the old narrow correlation window as a measured lag.
    radius = round(.4 * 48000)
    for cue in cues:
        expected = round(cue * 48000)
        left = max(0, expected - radius)
        candidate = samples[left:min(len(samples), expected + radius + len(reference)), 0]
        correlation = np.correlate(candidate, reference, "valid")
        at = int(np.argmax(correlation))
        lag = at + left - expected
        window = candidate[at:at + len(reference)]
        similarity = float(correlation[at]) / max(1e-12, math.sqrt(float(np.dot(window, window)) * energy))
        rows.append({"cue_seconds": cue, "lag_samples": lag, "lag_ms": lag / 48,
                     "match_gain": float(correlation[at]) / energy, "similarity": similarity})
    lags = [r["lag_samples"] for r in rows]
    span = max(lags) - min(lags)
    within = all(abs(lag) <= 48000 / fps for lag in lags)
    return {"ok": within and span <= 48 and all(r["similarity"] > .98 and r["match_gain"] > .1 for r in rows),
            "cues": rows, "drift_span_samples": span, "within_one_frame": within}


def review(args, output):
    project = args.project.resolve()
    hashes = snapshot(project)
    for name in hashes:
        if name.startswith("generated/"):
            continue  # Large immutable generated assets are retained in project.
        target = output / "source-snapshot" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(project / name, target)
    for name in ["production_review.py", "production_metrics.py", "endurance_review.py", "audio_review.py", "motion_review.py"]:
        target = output / "reviewer-snapshot" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(Path(__file__).parent / name, target)
    folder = output / "capture"
    folder.mkdir()
    protected_paths = [ROOT / "project.godot", ROOT / ".godot360/settings.cfg"] + list((ROOT / "export_profiles").glob("*.tres"))
    protected = {str(p): sha(p) for p in protected_paths if p.exists()}
    count = args.seconds * 30
    job = {"scene_path": "res://tests/fixtures/production_scene.tscn", "camera_path": "Camera3D", "width": args.width,
           "height": args.width // 2, "face_size": args.face_size, "fps": 30, "frames": count, "warmup_frames": 8,
           "frame_writer": "fast_png", "capture_border_percent": 12.5, "crf": 18, "random_seed": 3602026,
           "rendering_method": args.method, "rendering_driver": "vulkan", "benchmark_msaa": args.msaa, "output_dir": str(folder),
           "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
    if args.seconds == 1:
        job.update(mode="test", target_frames=1800)
    if args.storage_fault_after:
        job["storage_fault_after"] = args.storage_fault_after
    request = output / "request.json"
    save(request, job)
    evidence = {"ok": False, "platform": platform.platform(), "job": job, "hashes": hashes, "protected_hashes": protected,
                "reviewer_sha256": sha(Path(__file__)), "analysis_scope": "Full source PNG/video decoding; frame identifiers and flashes checked in a cropped region, not a whole-scene appearance oracle."}
    save(output / "production-review.json", evidence)
    monitor = None
    started = time.monotonic()
    try:
        with (output / "pipeline.log").open("wb") as log:
            process = subprocess.Popen([str(args.godot), "--headless", "--path", str(project), "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)],
                                       stdout=log, stderr=log, env=environment(output), creationflags=FLAGS)
            monitor = Monitor(folder, process.pid, args.max_storage_gib, args.timeout)
            monitor.thread.start()
            try:
                while process.poll() is None:
                    if monitor.error:
                        (folder / "cancel.request").write_text(monitor.error)
                        process.wait(timeout=30)
                        raise RuntimeError(monitor.error)
                    time.sleep(.2)
            finally:
                if process.poll() is None:
                    (folder / "cancel.request").write_text("Benchmark interrupted")
                    try:
                        process.wait(timeout=30)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
        evidence["pipeline_wall_seconds"] = time.monotonic() - started
        report = read_json(folder / "report.json")
        evidence["report"] = report
        if args.storage_fault_after:
            state, recovery = read_json(folder / "status.json"), read_json(folder / "recovery.json")
            evidence.update(expected_failure=True, state=state, recovery=recovery)
            evidence["ok"] = process.returncode != 0 and state.get("stage") == "Failed" and "disk space" in state.get("error", "").lower() and not recovery.get("can_reencode") and not (folder / "video-360.mp4").exists()
            assert read_json(folder / "capture-result.json").get("rendered") == args.storage_fault_after
            return evidence
        assert process.returncode == 0 and report.get("ok") and len(report["checks"]) == 13 and all(report["checks"].values()), read_json(folder / "status.json")
        settings = report["capture_settings"]
        worker = str(read_json(folder / "production-worker.json")["pid"])
        coordinator = str(read_json(folder / "session.json")["pid"])
        assert any(worker in r["processes"] and coordinator in r["processes"] and r["process_gpu_dedicated_bytes"] is not None for r in monitor.rows), "Incomplete worker/coordinator memory accounting"
        assert settings["renderer"] == args.method and settings["rendering_driver"] == "vulkan" and settings["msaa_3d"] == args.msaa
        assert len(list((folder / "frames").glob("*.png"))) == count + 8
        assert not list((folder / "movie").glob("*.png"))
        scene = read_json(folder / "production-scene.json")
        assert scene["instances"] == 768 and scene["texture_maps"] == 24 and scene["gpu_particles"] == 1536
        assert len(scene["history_counts"]) >= 6 and all(c == count + 8 for c in scene["history_counts"].values())
        assert max(r["engine_texture_bytes"] for r in scene["samples"]) > 256 * 2**20
        assert max(r["primitives"] for r in scene["samples"]) > 1_000_000
        evidence["scene"] = scene
        monitor.root_pid = os.getpid()
        monitor.phase = "Source image review"
        phase = time.monotonic()
        box, columns, row, flash_row = roi(args.width, args.width // 2)
        def pngs():
            for i in range(count):
                with Image.open(folder / "frames" / f"frame{i+8:08d}.png") as frame:
                    assert frame.size == (args.width, args.width // 2)
                    yield np.array(frame.crop(box).convert("RGB"))
        evidence["source_images"] = inspect(pngs(), job, box, columns, row, flash_row)
        evidence["source_review_seconds"] = time.monotonic() - phase
        monitor.phase = "Decoded video review"
        phase = time.monotonic()
        evidence["decoded_images"] = inspect(decode_roi(args.ffmpeg, folder / "video-360.mp4", box, output / "decode.log"), job, box, columns, row, flash_row)
        evidence["decoded_review_seconds"] = time.monotonic() - phase
        monitor.phase = "Audio review"
        phase = time.monotonic()
        source_audio = decode(folder / "frames/frame.wav", args.ffmpeg)[12800:][:args.seconds * 48000]
        final_audio = decode(folder / "video-360.mp4", args.ffmpeg)
        cues = cue_times(args.seconds)
        evidence["source_audio"] = audio_clock(source_audio, args.seconds, 30, cues)
        evidence["decoded_audio"] = audio_clock(final_audio, args.seconds, 30, cues)
        evidence["audio_preservation"] = compare_audio(final_audio, source_audio)
        evidence["audio_review_seconds"] = time.monotonic() - phase
        evidence["ok"] = all(evidence[k]["ok"] for k in ["source_images", "decoded_images", "source_audio", "decoded_audio"])
        return evidence
    except BaseException as error:
        evidence["error"] = str(error)
        raise
    finally:
        if monitor:
            monitor.finish()
            evidence["memory"] = monitor.summary()
            evidence["ok"] &= not monitor.error and not evidence["memory"]["counter_errors"]
        evidence["source_unchanged"] = hashes == snapshot(project)
        evidence["protected_unchanged"] = all(p.exists() and sha(p) == h for name, h in protected.items() for p in [Path(name)])
        evidence["ok"] &= evidence["source_unchanged"] and evidence["protected_unchanged"]
        evidence["retained_bytes"] = retained_bytes(folder)
        evidence["wall_seconds_including_review"] = time.monotonic() - started
        save(output / "production-review.json", evidence)
        print(json.dumps({k: evidence.get(k) for k in ["ok", "error", "pipeline_wall_seconds", "source_review_seconds", "decoded_review_seconds", "retained_bytes"]}), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--project", type=Path)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--method", choices=["forward_plus", "mobile"], default="forward_plus")
    parser.add_argument("--seconds", type=int, choices=[1, 5, 60, 90, 120], default=60)
    parser.add_argument("--width", type=int, choices=[1024, 4096, 7680], default=4096)
    parser.add_argument("--face-size", type=int, choices=[256, 1536, 2048, 3072, 4096], default=1536)
    parser.add_argument("--msaa", type=int, choices=[0, 1, 2], default=2, help="Godot MSAA enum: 0 disabled, 1 two samples, 2 four samples")
    parser.add_argument("--storage-fault-after", type=int, default=0)
    parser.add_argument("--max-storage-gib", type=float, default=80)
    parser.add_argument("--timeout", type=int, default=7200)
    args = parser.parse_args()
    args.godot = args.godot.resolve()
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=False)
    if args.prepare_only:
        prepare(args, args.output)
    else:
        assert args.project is not None, "Prepare a disposable project first"
        raise SystemExit(0 if review(args, args.output)["ok"] else 1)
