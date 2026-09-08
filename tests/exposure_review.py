"""Compare scene metering with fixed capture and an independently authored oracle.

Fresh disposable project; actual delivered PNG/MP4 sequences, per-frame metrics,
re-encode source preservation and timings. Requires NumPy/Pillow and a native GPU.
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
from motion_review import decoded_frames

ROOT = Path(__file__).resolve().parents[1]


def snapshot(folder):
    return {p.relative_to(folder).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in folder.rglob("*") if p.is_file()}


def compare_decoded(ffmpeg, output, decoded):
    comparisons = {}
    for a, b in [("fixed", "oracle"), ("scene", "legacy")]:
        same_hashes = decoded[a] == decoded[b]
        # One-level GPU rounding can change CRF encoder decisions beyond the
        # original pixels. Compare the actual decoded frames when hashes differ.
        timing_matches = [line.rsplit(",", 1)[0] for line in decoded[a]] == [line.rsplit(",", 1)[0] for line in decoded[b]]
        values = []
        if not same_hashes:
            for index, (x, y) in enumerate(zip(decoded_frames(ffmpeg, output / a / "video-360.mp4", 2048, 1024),
                                                decoded_frames(ffmpeg, output / b / "video-360.mp4", 2048, 1024), strict=True)):
                delta = abs(x.astype(np.float32) - y.astype(np.float32))
                values.append({"frame": index, "mae": float(delta.mean()), "max": float(delta.max())})
        maximum = max((v["mae"] for v in values), default=0.0)
        comparisons[a + "_" + b] = {"identical_hashes": same_hashes, "timing_matches": timing_matches,
                                      "max_frame_mae": maximum, "frames": values,
                                      "ok": len(decoded[a]) == len(decoded[b]) == 90 and timing_matches and maximum < .1}
    return comparisons


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
config/name="Godot360 exposure review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    evidence = {"method": args.method, "driver": args.driver, "border": args.border,
                "physical": args.physical, "world_attributes": args.world_attributes, "jobs": {}}
    modes = ["scene", "oracle"] if args.baseline_only else ["scene", "fixed", "oracle", "legacy"]
    for mode in modes:
        job = {"scene_path": "res://tests/fixtures/exposure_scene.tscn", "camera_path": "Camera3D",
               "width": 2048, "height": 1024, "face_size": 512, "fps": 30, "frames": 90,
               "warmup_frames": 8, "capture_border_percent": args.border,
               "capture_exposure_mode": "fixed" if mode == "fixed" else "scene",
               "oracle": mode == "oracle", "physical": args.physical, "world_attributes": args.world_attributes,
               "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(output / mode),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
        if mode == "legacy":
            job.pop("capture_exposure_mode")
        request = output / (mode + ".json")
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / (mode + ".log"))
        report = read(output / mode / "report.json")
        assert report["ok"] and all(report["checks"].values()), mode
        evidence["jobs"][mode] = {"checks": report["checks"], "capture_settings": report["capture_settings"],
                                  "pipeline_timings": report["pipeline_timings"],
                                  "capture_timings": {k: v for k, v in report["capture_timings"].items() if k != "samples"}}
        print(mode, "DELIVERY PASS", flush=True)
    ids = face_ids(2048, 1024)
    scores = []
    for index in range(90):
        filename = f"frames/frame{index + 8:08d}.png"
        pictures = {mode: pixels(output / mode / filename) for mode in modes}
        row = {"frame": index, "scene_seam": seam_score(pictures["scene"], ids),
               "oracle_seam": seam_score(pictures["oracle"], ids)}
        if not args.baseline_only:
            row.update(fixed_seam=seam_score(pictures["fixed"], ids),
                       fixed_oracle_mae=float(abs(pictures["fixed"] - pictures["oracle"]).mean()),
                       fixed_oracle_max=float(abs(pictures["fixed"] - pictures["oracle"]).max()),
                       legacy_mae=float(abs(pictures["scene"] - pictures["legacy"]).mean()))
        scores.append(row)
    evidence["frames"] = scores
    evidence["mean_scene_seam"] = float(np.mean([s["scene_seam"] for s in scores]))
    evidence["mean_oracle_seam"] = float(np.mean([s["oracle_seam"] for s in scores]))
    if not args.baseline_only:
        evidence["max_fixed_oracle_mae"] = max(s["fixed_oracle_mae"] for s in scores)
        evidence["max_legacy_mae"] = max(s["legacy_mae"] for s in scores)
        decoded = {}
        for mode in modes:
            path = output / (mode + "-decoded.md5")
            run([args.ffmpeg, "-v", "error", "-nostdin", "-i", output / mode / "video-360.mp4",
                 "-map", "0:v:0", "-f", "framemd5", path], output / (mode + "-decode.log"))
            decoded[mode] = [line for line in path.read_text().splitlines() if line and not line.startswith("#")]
        evidence["decoded_frames_per_job"] = {mode: len(rows) for mode, rows in decoded.items()}
        evidence["decoded_oracle_and_legacy_match"] = all(len(rows) == 90 for rows in decoded.values()) and decoded["fixed"] == decoded["oracle"] and decoded["scene"] == decoded["legacy"]
        evidence["decoded_comparisons"] = compare_decoded(args.ffmpeg, output, decoded)
        evidence["reduction_percent"] = float(100 * (1 - np.mean([s["fixed_seam"] for s in scores]) / max(evidence["mean_scene_seam"], 1e-8)))
        source = output / "fixed"
        before = snapshot(source)
        request = output / "reencode.json"
        request.write_text(json.dumps({"mode": "reencode", "source_dir": str(source), "output_dir": str(output / "reencoded"),
                                      "crf": 22, "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / "reencode.log")
        report = read(output / "reencoded/report.json")
        evidence["reencode_ok"] = report["ok"] and all(report["checks"].values()) and before == snapshot(source) and report["capture_settings"] == evidence["jobs"]["fixed"]["capture_settings"]
        evidence["ok"] = evidence["max_fixed_oracle_mae"] < .02 and evidence["max_legacy_mae"] < .02 and evidence["reencode_ok"] and all(c["ok"] for c in evidence["decoded_comparisons"].values())
        if args.method == "forward_plus" and args.border == 0:
            evidence["ok"] = evidence["ok"] and evidence["mean_scene_seam"] > 1 and evidence["reduction_percent"] > 90
    else:
        evidence["ok"] = True
    sheet = Image.new("RGB", (960, 570), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for column, index in enumerate([0, 44, 75]):
        for row, mode in enumerate(["scene", "oracle" if args.baseline_only else "fixed"]):
            picture = output / f"view-{mode}-{index}.png"
            run([args.ffmpeg, "-v", "error", "-nostdin", "-i", output / mode / f"frames/frame{index+8:08d}.png",
                 "-vf", "v360=equirect:flat:yaw=45:h_fov=100:v_fov=80:w=320:h=255", "-frames:v", 1, "-update", 1, picture], output / f"view-{mode}-{index}.log")
            sheet.paste(Image.open(picture).convert("RGB"), (column*320, row*285+30))
            draw.text((column*320+6, row*285+9), f"{mode} - frame {index}", fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "exposure-review.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in evidence.items() if k not in ["jobs", "frames"]}, indent=2), flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--physical", action="store_true")
    parser.add_argument("--world-attributes", action="store_true")
    parser.add_argument("--baseline-only", action="store_true")
    raise SystemExit(main(parser.parse_args()))
