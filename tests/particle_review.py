"""Compare CPU/GPU particle capture with analytic motion and authored pause states.

Uses a disposable project and the real PNG/MP4 delivery pipeline. Requires Godot,
FFmpeg/FFprobe, NumPy and Pillow. Zero-warmup startup is an observation, not a
promise of complete first-frame particle visibility.
"""
import argparse
import json
import os
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from border_review import pixels, read, run
from motion_review import decoded_frames
from skeletal_review import source_difference

ROOT = Path(__file__).resolve().parents[1]


def compare(output, a, b, jobs, ffmpeg):
    rows = []
    for index, (x, y) in enumerate(zip(
            decoded_frames(ffmpeg, output / a / "video-360.mp4", 2048, 1024),
            decoded_frames(ffmpeg, output / b / "video-360.mp4", 2048, 1024), strict=True)):
        left = pixels(output / a / f"frames/frame{index + jobs[a]['warmup_frames']:08d}.png")
        right = pixels(output / b / f"frames/frame{index + jobs[b]['warmup_frames']:08d}.png")
        rows.append({"frame": index, **source_difference(left, right),
                     "decoded_mae": float(abs(x.astype(np.float32) - y.astype(np.float32)).mean())})
    return {"frames": rows, "max_source_mae": max(r["source_mae"] for r in rows),
            "max_foreground_mae": max(r["foreground_mae"] for r in rows),
            "max_decoded_mae": max(r["decoded_mae"] for r in rows),
            "ok": len(rows) == 60 and all(r["source_mae"] < .03 and r["foreground_pixels"] > 200
                                           and r["foreground_mae"] < .25 and r["decoded_mae"] < .1 for r in rows)}


def processing_check(output, name, job):
    evidence = read(output / name / "particle-samples.json")
    samples = evidence["samples"]
    # Frame zero is sampled more than once during build/warmup. Keep its last
    # observation, which is made before the first delivered draw.
    by_frame = {s["frame"]: s for s in samples}
    rows = [by_frame[i] for i in range(60)]
    pause = job.get("particle_pause_frame", -1)
    mode = job.get("particle_root_mode", 0)
    if mode in (2, 4):  # WHEN_PAUSED in an unpaused tree, or DISABLED.
        ok = all(s["mode"] == mode and s["process_ticks"] == 0 for s in rows)
    elif pause >= 0:
        ok = all(s["mode"] == 4 and s["process_ticks"] == rows[pause]["process_ticks"] for s in rows[pause:])
        ok = ok and rows[pause]["process_ticks"] > rows[0]["process_ticks"]
    else:
        ok = all(s["mode"] == mode and s["process_ticks"] == rows[0]["process_ticks"] + s["frame"] for s in rows)
    if mode in (2, 4):
        # Disabled emitters legitimately have no visible particles. Require a
        # stable picture after startup as well as zero scene processing ticks.
        first = pixels(output / name / f"frames/frame{8 + job['warmup_frames']:08d}.png")
        frozen = [float(abs(pixels(output / name / f"frames/frame{i + job['warmup_frames']:08d}.png") - first).mean())
                  for i in range(9, 60)]
        ok = ok and max(frozen) == 0
    elif pause >= 0:
        # Particle simulation must also stop visually, not just the root script.
        first = pixels(output / name / f"frames/frame{pause + job['warmup_frames'] + 1:08d}.png")
        frozen = [float(abs(pixels(output / name / f"frames/frame{i + job['warmup_frames']:08d}.png") - first).mean())
                  for i in range(pause + 2, 60)]
        ok = ok and max(frozen) == 0 and int((first.max(axis=2) > 100).sum()) > 200
    else:
        frozen = []
    settings_unchanged = evidence["authored_emitters"] == evidence["final_emitters"]
    deltas = evidence["process_deltas"]
    clock_ok = all(abs(delta - 1 / job["fps"]) < 1e-10 for delta in deltas)
    return {"ok": ok and settings_unchanged and clock_ok, "samples": rows,
            "authored_particle_settings_unchanged": settings_unchanged,
            "fixed_frame_deltas": clock_ok, "process_deltas": deltas,
            "max_frozen_frame_mae": max(frozen) if frozen else None}


def main(args):
    output = args.output.resolve()
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
config/name="Godot360 particle review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    if args.baseline_worker:
        (project / "addons/godot360/capture.gd").write_bytes(args.baseline_worker.read_bytes())
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    variants = {"gpu": {}, "cpu": {"particle_kind": "cpu"},
                "oracle": {"particle_oracle": True, "warmup_frames": 8},
                "gpu-long-warmup": {"warmup_frames": 10, "particle_root_mode": 3}}
    if args.gpu_only:
        variants.pop("cpu")
    if args.lifecycle_only:
        variants.clear()
    if args.lifecycle or args.lifecycle_only:
        variants.update({"cpu-disabled": {"particle_kind": "cpu", "particle_root_mode": 4},
                         "gpu-disabled-zero-warmup": {"particle_root_mode": 4, "warmup_frames": 0},
                         "cpu-when-paused": {"particle_kind": "cpu", "particle_root_mode": 2, "warmup_frames": 0},
                         "cpu-pause-during-capture": {"particle_kind": "cpu", "particle_pause_frame": 15}})
    if args.zero_warmup:
        variants.update({"gpu-zero-warmup": {"warmup_frames": 0},
                         "cpu-zero-warmup": {"particle_kind": "cpu", "warmup_frames": 0}})
    if args.fixed_step:
        variants.update({"gpu-fixed-rate": {"particle_fps": args.fps, "warmup_frames": 2},
                         "cpu-fixed-rate": {"particle_kind": "cpu", "particle_fps": args.fps, "warmup_frames": 2}})
    if args.automatic_bounds:
        variants.update({"cpu-automatic-bounds": {"particle_kind": "cpu", "particle_auto_bounds": True},
                         "cpu-automatic-bounds-short": {"particle_kind": "cpu", "particle_auto_bounds": True, "warmup_frames": 2}})
    if args.short_warmup:
        variants.update({"gpu-short-warmup": {"warmup_frames": 2},
                         "cpu-short-warmup": {"particle_kind": "cpu", "warmup_frames": 2}})
    if args.gpu_only:
        variants.pop("cpu-zero-warmup", None)
        variants.pop("cpu-short-warmup", None)
        variants.pop("cpu-fixed-rate", None)
    evidence = {"method": args.method, "driver": args.driver, "border": args.border, "fps": args.fps,
                "gpu_only_appearance": args.gpu_only,
                "jobs": {}, "comparisons": {}, "processing": {}, "startup": {}}
    jobs = {}
    for name, extra in variants.items():
        job = {"scene_path": "res://tests/fixtures/particle_scene.tscn", "camera_path": "Camera3D",
               "width": 2048, "height": 1024, "face_size": 512, "fps": args.fps, "frames": 60,
               "warmup_frames": 8, "capture_border_percent": args.border,
               "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(output / name),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()), **extra}
        jobs[name] = job
        request = output / (name + ".json")
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
             "--", "--job=" + str(request)], output / (name + ".log"))
        report = read(output / name / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        if job["warmup_frames"] < 2 and not args.baseline_worker:
            assert any("Particles may be missing" in warning for warning in report["capture_settings"]["warnings"]), name
        if args.method == "gl_compatibility" and job.get("particle_kind") == "cpu" and not args.baseline_worker:
            has_note = any("Compatibility CPU particles" in warning for warning in report["capture_settings"]["warnings"])
            assert not has_note, name
        evidence["jobs"][name] = {"checks": report["checks"], "settings": report["capture_settings"],
                                  "timings": {k: v for k, v in report["capture_timings"].items() if k != "samples"}}
        evidence["processing"][name] = processing_check(output, name, job)
        print(name, "DELIVERY PASS", "PROCESSING", evidence["processing"][name]["ok"], flush=True)
    for a in ["gpu", "cpu", "gpu-long-warmup", "gpu-fixed-rate", "cpu-fixed-rate", "gpu-short-warmup", "cpu-short-warmup", "cpu-automatic-bounds", "cpu-automatic-bounds-short"]:
        if a in jobs:
            evidence["comparisons"][a] = compare(output, a, "oracle", jobs, args.ffmpeg)
    for name in ["gpu-zero-warmup", "cpu-zero-warmup"]:
        if name in jobs:
            evidence["startup"][name] = compare(output, name, "oracle", jobs, args.ffmpeg)
    evidence["ok"] = all(r["ok"] for r in evidence["comparisons"].values()) and all(r["ok"] for r in evidence["processing"].values())
    names = [name for name in ["gpu", "cpu", "oracle"] if name in jobs] if "oracle" in jobs else ["cpu-pause-during-capture"]
    sheet = Image.new("RGB", (960, len(names) * 270), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(names):
        for col, frame in enumerate([0, 24, 59]):
            source = output / name / f"frames/frame{frame + jobs[name]['warmup_frames']:08d}.png"
            view = output / f"view-{name}-{frame}.png"
            run([args.ffmpeg, "-v", "error", "-nostdin", "-i", source, "-vf",
                 "v360=equirect:flat:yaw=45:h_fov=50:v_fov=38:w=320:h=240", "-frames:v", 1, "-update", 1, view], output / f"view-{name}-{frame}.log")
            sheet.paste(Image.open(view).convert("RGB"), (col * 320, row * 270 + 30))
            draw.text((col * 320 + 8, row * 270 + 8), f"{name} - frame {frame}", fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "particle-review.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": evidence["ok"], "comparisons": {k: {n: v for n, v in r.items() if n != "frames"}
                                                               for k, r in evidence["comparisons"].items()}}, indent=2), flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--fps", type=int, choices=[24, 30, 60], default=30)
    parser.add_argument("--lifecycle", action="store_true")
    parser.add_argument("--lifecycle-only", action="store_true")
    parser.add_argument("--gpu-only", action="store_true", help="Compare GPU appearance only; lifecycle mode still checks CPU pause behavior.")
    parser.add_argument("--automatic-bounds", action="store_true", help="Require CPU automatic bounds to match the reference, including the first delivered frame.")
    parser.add_argument("--zero-warmup", action="store_true")
    parser.add_argument("--short-warmup", action="store_true", help="Require the default two-frame warmup to match the settled reference.")
    parser.add_argument("--fixed-step", action="store_true", help="Require CPU/GPU fixed steps matching the export FPS, with two warmup frames, to match the reference.")
    parser.add_argument("--baseline-worker", type=Path)
    raise SystemExit(main(parser.parse_args()))
