"""Render bone-attached camera motion/cuts and weighted skin against CPU oracles.

Runs in a fresh disposable project. Requires NumPy, Pillow, Godot and FFmpeg.
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

ROOT = Path(__file__).resolve().parents[1]


def source_difference(a, b):
    delta = abs(a - b)
    foreground = np.maximum(a, b).max(axis=2) > 100
    count = int(foreground.sum())
    return {"source_mae": float(delta.mean()), "source_max": float(delta.max()),
            "foreground_pixels": count,
            "foreground_mae": float(delta[foreground].mean()) if count else 255.0}


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
config/name="Godot360 skeletal review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
anti_aliasing/quality/use_taa={str(args.taa).lower()}
''', encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    evidence = {"method": args.method, "driver": args.driver, "taa": args.taa,
                "warmup": args.warmup, "border": args.border, "external_skeleton": args.external_skeleton,
                "jobs": {}, "comparisons": {}}
    # Rebuilding the CPU mesh has different motion-vector history from GPU skin.
    # Use the same skin on both sides when isolating camera timing under TAA.
    modes = ["capture", "camera-oracle"] if args.taa else ["capture", "camera-oracle", "full-oracle"]
    rig = project / "addons/godot360/capture_rig.gd"
    current = rig.read_bytes()
    if args.baseline_rig:
        modes.insert(0, "baseline")
    for mode in modes:
        rig.write_bytes(args.baseline_rig.read_bytes() if mode == "baseline" else current)
        oracle = mode in ["camera-oracle", "full-oracle"]
        job = {"scene_path": "res://tests/fixtures/skeletal_scene.tscn",
               "camera_path": "Camera3D" if oracle else ("Attachment/Camera3D" if args.external_skeleton else "Skeleton3D/Attachment/Camera3D"),
               "width": 2048, "height": 1024, "face_size": 512, "fps": 30, "frames": 60,
               "warmup_frames": args.warmup, "capture_border_percent": args.border,
               "oracle_camera": oracle, "oracle_skin": mode == "full-oracle", "external_skeleton": args.external_skeleton,
               "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(output / mode),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
        request = output / (mode + ".json")
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / (mode + ".log"))
        report = read(output / mode / "report.json")
        assert report["ok"] and all(report["checks"].values()), mode
        evidence["jobs"][mode] = {"checks": report["checks"], "settings": report["capture_settings"],
                                  "timings": {k: v for k, v in report["capture_timings"].items() if k != "samples"}}
        print(mode, "DELIVERY PASS", flush=True)
    pairs = [(m, "camera-oracle") for m in modes if m in ["capture", "baseline"]]
    if "full-oracle" in modes:
        pairs.append(("camera-oracle", "full-oracle"))
    for a, b in pairs:
        rows = []
        for frame, (x, y) in enumerate(zip(decoded_frames(args.ffmpeg, output / a / "video-360.mp4", 2048, 1024),
                                            decoded_frames(args.ffmpeg, output / b / "video-360.mp4", 2048, 1024), strict=True)):
            filename = f"frames/frame{frame + args.warmup:08d}.png"
            decoded_delta = abs(x.astype(np.float32) - y.astype(np.float32))
            rows.append({"frame": frame, **source_difference(pixels(output / a / filename), pixels(output / b / filename)),
                         "decoded_mae": float(decoded_delta.mean())})
        evidence["comparisons"][a] = {"frames": rows, "max_source_mae": max(r["source_mae"] for r in rows),
                                       "max_decoded_mae": max(r["decoded_mae"] for r in rows),
                                       "max_foreground_mae": max(r["foreground_mae"] for r in rows),
                                       "ok": len(rows) == 60 and all(r["source_mae"] < .03 and r["decoded_mae"] < .1
                                                                    and r["foreground_pixels"] > 200 and r["foreground_mae"] < .25 for r in rows)}
    evidence["ok"] = all(value["ok"] for key, value in evidence["comparisons"].items() if key != "baseline")
    sheet = Image.new("RGB", (960, len(modes) * 190), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, mode in enumerate(modes):
        for col, frame in enumerate([15, 30, 31]):
            source = output / mode / f"frames/frame{frame + args.warmup:08d}.png"
            picture = output / f"{mode}-{frame}.png"
            run([args.ffmpeg, "-v", "error", "-nostdin", "-i", source, "-vf",
                 "v360=equirect:flat:yaw=45:h_fov=100:v_fov=55:w=320:h=160", "-frames:v", 1, "-update", 1, picture], output / f"view-{mode}-{frame}.log")
            sheet.paste(Image.open(picture).convert("RGB"), (col * 320, row * 190 + 30))
            draw.text((col * 320 + 8, row * 190 + 8), f"{mode} - frame {frame}", fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "skeletal-review.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": evidence["ok"], "comparisons": {k: {n:v for n,v in r.items() if n != "frames"} for k,r in evidence["comparisons"].items()}}, indent=2), flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--warmup", type=int, default=8)
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--taa", action="store_true")
    parser.add_argument("--external-skeleton", action="store_true")
    parser.add_argument("--baseline-rig", type=Path)
    raise SystemExit(main(parser.parse_args()))
