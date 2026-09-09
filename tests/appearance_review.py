"""Review combined moving lights/materials, authored exposure and capture borders.

Uses fresh isolated projects and the actual export pipeline. Source/decoded oracle
comparisons establish exposure preservation; unlit controls isolate projection.
Glow-only boundary scores are observations, not universal scene-quality scores.
Requires Godot, FFmpeg/FFprobe, NumPy and Pillow.
"""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from border_review import face_ids, pixels, read, run, seam_score
from exposure_review import snapshot
from motion_review import decoded_frames

ROOT = Path(__file__).resolve().parents[1]
FRAMES, WARMUP, WIDTH, HEIGHT = 90, 8, 2048, 1024
CASES = {
    "scene": {"capture_exposure_mode": "scene"},
    "fixed": {},
    "oracle": {"capture_exposure_mode": "scene", "oracle": True},
    "border": {"capture_border_percent": 12.5},
    "border-oracle": {"capture_border_percent": 12.5, "capture_exposure_mode": "scene", "oracle": True},
    "plain": {"glow": False},
    "plain-border": {"glow": False, "capture_border_percent": 12.5},
    "geometry": {"geometry_control": True},
    "geometry-border": {"geometry_control": True, "capture_border_percent": 12.5},
}


def checkpoint(output, evidence):
    (output / "appearance-review.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")


def source_frame(output, name, frame):
    return pixels(output / name / f"frames/frame{frame + WARMUP:08d}.png")


def compare(output, ffmpeg, a, b):
    rows = []
    for index, (x, y) in enumerate(zip(
            decoded_frames(ffmpeg, output / a / "video-360.mp4", WIDTH, HEIGHT),
            decoded_frames(ffmpeg, output / b / "video-360.mp4", WIDTH, HEIGHT), strict=True)):
        source = abs(source_frame(output, a, index) - source_frame(output, b, index))
        decoded = x.astype(np.float32) - y.astype(np.float32)
        rows.append({"frame": index, "source_mae": float(source.mean()), "source_max": float(source.max()),
                     "decoded_mae": float(abs(decoded).mean()), "decoded_rmse": float(np.sqrt(np.mean(decoded * decoded)))})
    # A few one-level GPU rounding changes can alter CRF's subsequent GOP
    # decisions. Bound decoded error to one RGB code value RMS, while requiring
    # source differences to stay within one level per channel and tiny on average.
    # This rejects actual exposure/geometry changes without demanding identical
    # lossy encoder decisions from almost-identical source frames.
    return {"frames": rows, "max_source_mae": max(r["source_mae"] for r in rows),
            "max_decoded_mae": max(r["decoded_mae"] for r in rows),
            "max_decoded_rmse": max(r["decoded_rmse"] for r in rows),
            "ok": len(rows) == FRAMES and all(r["source_mae"] < .02 and r["source_max"] <= 1
                                              and r["decoded_rmse"] < 1 for r in rows)}


def analyze(output, ffmpeg, evidence):
    evidence["decoded_frames"] = {}
    for name in CASES:
        path = output / (name + "-decoded.md5")
        run([ffmpeg, "-v", "error", "-nostdin", "-y", "-i", output / name / "video-360.mp4",
             "-map", "0:v:0", "-f", "framemd5", path], output / (name + "-decode.log"))
        rows = [line for line in path.read_text().splitlines() if line and not line.startswith("#")]
        evidence["decoded_frames"][name] = len(rows)
    evidence["comparisons"] = {a: compare(output, ffmpeg, a, b)
                               for a, b in [("fixed", "oracle"), ("border", "border-oracle")]}
    ids = face_ids(WIDTH, HEIGHT)
    rows = []
    for index in range(FRAMES):
        pictures = {name: source_frame(output, name, index) for name in CASES}
        rows.append({"frame": index,
                     "scene_seam": seam_score(pictures["scene"], ids),
                     "fixed_seam": seam_score(pictures["fixed"], ids),
                     "glow_seam": seam_score(pictures["fixed"] - pictures["plain"], ids),
                     "border_glow_seam": seam_score(pictures["border"] - pictures["plain-border"], ids),
                     "glow_mae": float(abs(pictures["fixed"] - pictures["plain"]).mean()),
                     "border_glow_mae": float(abs(pictures["border"] - pictures["plain-border"]).mean()),
                     "scene_fixed_mae": float(abs(pictures["scene"] - pictures["fixed"]).mean()),
                     "plain_border_mae": float(abs(pictures["plain"] - pictures["plain-border"]).mean()),
                     "geometry_border_mae": float(abs(pictures["geometry"] - pictures["geometry-border"]).mean())})
    evidence["frames"] = rows
    evidence["crossings"] = []
    for start, label in [(0, "front/right edge"), (30, "three-face corner and light cut"), (60, "rear/left edge")]:
        subset = rows[start:start + 30]
        before, after = [float(np.mean([row[key] for row in subset])) for key in ["glow_seam", "border_glow_seam"]]
        evidence["crossings"].append({"crossing": label, "glow_seam": before, "border_glow_seam": after,
                                      "reduction_percent": 100 * (1 - after / before) if before else None})
    evidence["max_geometry_border_mae"] = max(r["geometry_border_mae"] for r in rows)
    evidence["max_lit_plain_border_mae"] = max(r["plain_border_mae"] for r in rows)
    evidence["mean_scene_fixed_mae"] = float(np.mean([r["scene_fixed_mae"] for r in rows]))
    evidence["min_glow_mae"] = min(min(r["glow_mae"], r["border_glow_mae"]) for r in rows)
    # This mixed scene contains real geometry/shadow edges. Report seam metrics
    # without treating their reduction as proof that every view-dependent effect
    # is correct. The separate border fixture has a controlled halo acceptance.
    evidence["appearance_ok"] = (all(c["ok"] for c in evidence["comparisons"].values())
                                  and all(count == FRAMES for count in evidence["decoded_frames"].values())
                                  and evidence["max_geometry_border_mae"] < .1
                                  and evidence["min_glow_mae"] > .01
                                  and (evidence["mean_scene_fixed_mae"] > 1 if evidence["method"] == "forward_plus"
                                       else max(r["scene_fixed_mae"] for r in rows) < .02))
    sheet = Image.new("RGB", (960, 810), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for column, (index, yaw, pitch) in enumerate([(15, 45, 0), (45, 45, 35.264), (75, -135, 0)]):
        for row, name in enumerate(["scene", "fixed", "border"]):
            path = output / f"view-{name}-{index}.png"
            run([ffmpeg, "-v", "error", "-nostdin", "-y", "-i", output / name / f"frames/frame{index + WARMUP:08d}.png",
                 "-vf", f"v360=equirect:flat:yaw={yaw}:pitch={pitch}:h_fov=80:v_fov=65:w=320:h=240",
                 "-frames:v", 1, "-update", 1, path], output / f"view-{name}-{index}.log")
            sheet.paste(Image.open(path).convert("RGB"), (column * 320, row * 270 + 30))
            draw.text((column * 320 + 8, row * 270 + 9), f"{name} - frame {index}", fill="white")
    sheet.save(output / "comparison.jpg")


def main(args):
    output = args.output.resolve()
    if args.analyze:
        evidence = read(output / "appearance-review.json")
        analyze(output, args.ffmpeg, evidence)
        evidence["ok"] = (evidence["appearance_ok"] and evidence["reencode_ok"]
                          and evidence["addon_unchanged"] and evidence.get("scene_unchanged", False))
        checkpoint(output, evidence)
        print(json.dumps({k: v for k, v in evidence.items() if k not in ["jobs", "frames", "comparisons"]}, indent=2))
        return 0 if evidence["ok"] else 1
    output.mkdir(parents=True)
    evidence = {"method": args.method, "driver": args.driver, "jobs": {}, "ok": False}
    checkpoint(output, evidence)
    for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        path = output / "profile" / key
        path.mkdir(parents=True)
        os.environ[key] = str(path)
    project = output / "project"
    for name in ["addons/godot360", "tests"]:
        shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__"))
    (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 combined appearance review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    before_source = snapshot(project / "addons/godot360")
    evidence["source_hashes"] = {name: hashlib.sha256((project / name).read_bytes()).hexdigest()
                                for name in ["tests/fixtures/appearance_scene.gd", "tests/fixtures/renderer_lab.gd",
                                             "addons/godot360/capture.gd", "addons/godot360/capture_rig.gd",
                                             "addons/godot360/capture_exposure.gd", "addons/godot360/equirectangular.gdshader"]}
    scene_before = snapshot(project / "tests/fixtures")
    for name, settings in CASES.items():
        request = output / (name + ".json")
        job = {"scene_path": "res://tests/fixtures/appearance_scene.tscn", "camera_path": "Camera3D",
               "width": WIDTH, "height": HEIGHT, "face_size": 512, "fps": 30, "frames": FRAMES,
               "warmup_frames": WARMUP, "capture_exposure_mode": "fixed", "capture_border_percent": 0,
               "glow": True, "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(output / name),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()), **settings}
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / (name + ".log"))
        report = read(output / name / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        captured = report["capture_settings"]
        assert captured["capture_exposure_mode"] == job["capture_exposure_mode"]
        assert captured["capture_border_percent"] == job["capture_border_percent"]
        assert captured["renderer"] == args.method and captured["rendering_driver"] == args.driver
        evidence["jobs"][name] = {"checks": report["checks"], "capture_settings": captured,
                                  "pipeline_timings": report["pipeline_timings"],
                                  "capture_timings": {k: v for k, v in report["capture_timings"].items() if k != "samples"}}
        checkpoint(output, evidence)
        print(name, "DELIVERY PASS", flush=True)
    original = snapshot(output / "border")
    request = output / "reencode.json"
    request.write_text(json.dumps({"mode": "reencode", "source_dir": str(output / "border"),
                                  "output_dir": str(output / "reencoded"), "crf": 22,
                                  "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}), encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / "reencode.log")
    report = read(output / "reencoded/report.json")
    evidence["reencode_ok"] = (report["ok"] and all(report["checks"].values())
                               and report["capture_settings"] == evidence["jobs"]["border"]["capture_settings"]
                               and original == snapshot(output / "border"))
    evidence["addon_unchanged"] = before_source == snapshot(project / "addons/godot360")
    evidence["scene_unchanged"] = scene_before == snapshot(project / "tests/fixtures")
    checkpoint(output, evidence)
    analyze(output, args.ffmpeg, evidence)
    evidence["ok"] = (evidence["appearance_ok"] and evidence["reencode_ok"]
                      and evidence["addon_unchanged"] and evidence["scene_unchanged"])
    checkpoint(output, evidence)
    print(json.dumps({k: v for k, v in evidence.items() if k not in ["jobs", "frames", "comparisons"]}, indent=2), flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--analyze", action="store_true", help="Recompute metrics from a completed review without rendering")
    raise SystemExit(main(parser.parse_args()))
