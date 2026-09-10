"""Render moving transparent CPU/GPU smoke against independent mesh references.

Runs in a fresh disposable project through the actual PNG/MP4 pipeline.
Requires NumPy, Pillow, Godot and FFmpeg/FFprobe with a graphics backend.
"""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from border_review import pixels, read, run
from motion_review import decoded_frames

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT, FRAMES = 2048, 1024, 72
CASES = {
    "oracle": {"smoke_oracle": True},
    "gpu": {},
    "cpu": {"smoke_kind": "cpu"},
    "gpu-warm": {"warmup_frames": 8},
    "cpu-warm": {"smoke_kind": "cpu", "warmup_frames": 8},
    "local-oracle": {"smoke_oracle": True, "smoke_local": True},
    "gpu-local": {"smoke_local": True},
    "cpu-local": {"smoke_kind": "cpu", "smoke_local": True},
    "pause-oracle": {"smoke_oracle": True, "smoke_pause": 24},
    "gpu-pause": {"smoke_pause": 24},
    "cpu-pause": {"smoke_kind": "cpu", "smoke_pause": 24},
    "face-billboard": {"smoke_face_billboard": True},
    "wrong-position": {"smoke_oracle": True, "smoke_late": True},
    "wrong-alpha": {"smoke_oracle": True, "smoke_wrong_alpha": True},
    "gpu-zero": {"warmup_frames": 0},
    "cpu-zero": {"smoke_kind": "cpu", "warmup_frames": 0},
}


def source(output, name, index, jobs):
    return pixels(output / name / f"frames/frame{index + jobs[name]['warmup_frames']:08d}.png")


def compare(output, ffmpeg, a, b, jobs):
    rows = []
    for i, (x, y) in enumerate(zip(
            decoded_frames(ffmpeg, output / a / "video-360.mp4", WIDTH, HEIGHT),
            decoded_frames(ffmpeg, output / b / "video-360.mp4", WIDTH, HEIGHT), strict=True)):
        left, right = source(output, a, i, jobs), source(output, b, i, jobs)
        # Foreground includes either picture, rejecting missing/shifted smoke.
        mask = np.maximum(left.max(axis=2), right.max(axis=2)) > 85
        error = abs(left - right)
        decoded = abs(x.astype(np.float32) - y.astype(np.float32))
        rows.append({"frame": i, "source_mae": float(error.mean()),
                     "foreground_pixels": int(mask.sum()),
                     "foreground_mae": float(error[mask].mean()) if mask.any() else 255,
                     "decoded_mae": float(decoded.mean())})
    return {"frames": rows, **{"max_" + key: max(r[key] for r in rows) for key in
                              ["source_mae", "foreground_mae", "decoded_mae"]},
            "ok": len(rows) == FRAMES and all(r["source_mae"] < .03 and r["foreground_mae"] < .25
                and r["foreground_pixels"] > 200 and r["decoded_mae"] < .1 for r in rows)}


def processing(output, name, job):
    data = read(output / name / "smoke-samples.json")
    rows = {s["frame"]: s for s in data["samples"]}
    pause = job.get("smoke_pause", FRAMES)
    ticks = [rows[i]["ticks"] for i in range(FRAMES)]
    tick_ok = all(ticks[i] == ticks[0] + min(i, pause - 1) for i in range(FRAMES))
    clock_ok = all(abs(d - 1 / job["fps"]) < 1e-10 for d in data["deltas"])
    camera_ok = len(data["draw_samples"]) == FRAMES + job["warmup_frames"] and all(
        s["faces"] == 6 and s["camera_error"] < .00001 for s in data["draw_samples"])
    frozen = []
    if pause < FRAMES:
        for start, end in [(pause + 1, job.get("smoke_cut", 36)), (job.get("smoke_cut", 36) + 1, FRAMES)]:
            first = source(output, name, start, {name: job})
            frozen += [float(abs(source(output, name, i, {name: job}) - first).mean()) for i in range(start + 1, end)]
    return {"ok": tick_ok and clock_ok and camera_ok and data["initial"] == data["final"] and not any(frozen),
            "camera_ok": camera_ok, "max_camera_error": max(s["camera_error"] for s in data["draw_samples"]),
            "tick_ok": tick_ok, "clock_ok": clock_ok, "settings_unchanged": data["initial"] == data["final"],
            "max_frozen_mae": max(frozen, default=0), "samples": list(rows.values())}


def analyze(args, output, evidence, jobs):
    for name in jobs:
        reference = "local-oracle" if jobs[name].get("smoke_local") else "pause-oracle" if "smoke_pause" in jobs[name] else "oracle"
        if name == reference or reference not in jobs:
            continue
        result = compare(output, args.ffmpeg, name, reference, jobs)
        category = "controls" if name in ["face-billboard", "wrong-position", "wrong-alpha"] else "startup" if name.endswith("-zero") else "comparisons"
        evidence[category][name] = result
        print(name, category, {k: v for k, v in result.items() if k != "frames"}, flush=True)
    evidence["ok"] = (all(c["ok"] for c in evidence["comparisons"].values())
        and all(c["ok"] for c in evidence["processing"].values())
        and all(not c["ok"] for c in evidence["controls"].values()))
    if "oracle" in jobs:
        names = [n for n in ["face-billboard", "gpu", "cpu", "oracle"] if n in jobs]
        sheet = Image.new("RGB", (960, 270 * len(names)), "#141a22")
        draw = ImageDraw.Draw(sheet)
        for row, name in enumerate(names):
            for col, i in enumerate([0, 30, 48]):
                view = output / f"view-{name}-{i}.png"
                run([args.ffmpeg, "-v", "error", "-y", "-i", output / name / f"frames/frame{i + jobs[name]['warmup_frames']:08d}.png",
                     "-vf", "v360=equirect:flat:yaw=45:h_fov=60:v_fov=45:w=320:h=240", "-frames:v", 1, "-update", 1, view],
                    output / "contact.log")
                sheet.paste(Image.open(view).convert("RGB"), (320 * col, 270 * row + 30))
                draw.text((col * 320 + 8, row * 270 + 8), f"{name} / frame {i}", fill="white")
        sheet.save(output / "comparison.jpg")
    (output / "smoke-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return 0 if evidence["ok"] else 1


def main(args):
    output = args.output.resolve()
    if args.analyze:
        evidence = read(output / "smoke-review.json")
        return analyze(args, output, evidence, evidence["jobs"])
    output.mkdir(parents=True)
    for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        path = output / "profile" / key
        path.mkdir(parents=True)
        os.environ[key] = str(path)
    project = output / "project"
    for name in ["addons/godot360", "tests"]:
        shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__"))
    (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 smoke review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''')
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    names = args.cases.split(",") if args.cases else list(CASES)
    evidence = {"method": args.method, "driver": args.driver, "border": args.border,
                "jobs": {}, "delivery": {}, "processing": {}, "comparisons": {}, "controls": {}, "startup": {},
                "hashes": {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in
                           [ROOT / "tests/fixtures/smoke_scene.gd", ROOT / "tests/smoke_review.py",
                            ROOT / "addons/godot360/examples/spherical_smoke.gdshader", ROOT / "addons/godot360/capture.gd"]}}
    jobs = evidence["jobs"]
    for name in names:
        job = {"scene_path": "res://tests/fixtures/smoke_scene.tscn", "camera_path": "Camera3D",
               "width": WIDTH, "height": HEIGHT, "face_size": 512, "fps": 30, "frames": FRAMES,
               "warmup_frames": 2, "capture_border_percent": args.border, "crf": 16,
               "frame_writer": "fast_png", "rendering_method": args.method, "rendering_driver": args.driver,
               "output_dir": str(output / name), "ffmpeg": str(args.ffmpeg.resolve()),
               "ffprobe": str(args.ffprobe.resolve()), **CASES[name]}
        jobs[name] = job
        request = output / (name + ".json")
        request.write_text(json.dumps(job))
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
             "--", "--job=" + str(request)], output / (name + ".log"))
        report = read(output / name / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        evidence["delivery"][name] = {"checks": report["checks"], "settings": report["capture_settings"]}
        evidence["processing"][name] = processing(output, name, job)
        (output / "smoke-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
        print(name, "DELIVERY PASS", "PROCESSING", evidence["processing"][name]["ok"], flush=True)
    return analyze(args, output, evidence, jobs)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--cases", help="Comma-separated subset for focused development runs.")
    parser.add_argument("--analyze", action="store_true", help="Reanalyze retained evidence without rendering.")
    raise SystemExit(main(parser.parse_args()))
