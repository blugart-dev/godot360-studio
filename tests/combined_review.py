"""Every-frame saved-GI/transparency/history preservation in independent worlds.

Thresholds are fixed before native acceptance. Disabled effects must visibly
contribute; wrong captured lighting and cross-view history must fail images while
completing the full capture/delivery contract. This is a bounded appearance test.
"""
import argparse
import json
import platform
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
import lightmap_review as lightmap
from border_review import pixels, read
from temporal_review import compare, digest, WIDTH, HEIGHT, SOURCE_MAE, SOURCE_P99, DECODED_RMS

ROOT = Path(__file__).resolve().parents[1]
FRAMES = 144
CASES = {
    "combined": {},
    "lightmap-off": {"lighting": "lightmap_off"},
    "probes-off": {"lighting": "probes_off"},
    "transparency-off": {"transparency_off": True},
    "transparency-unlit": {"transparency_unlit": True},
    "history-off": {"feature": "baseline"},
    "missing-map-control": {"missing_lightmap_control": True},
    "shared-history-control": {"wrong_shared_history": True},
}
EXTRA = ["tests/combined_review.py", "tests/fixtures/combined_scene.gd", "tests/fixtures/combined_scene.tscn"]
# RGB levels on the 0-255 scale, across each complete panorama.
PRESENCE = {"lightmap-off": 1.0, "probes-off": .01, "transparency-off": .1, "transparency-unlit": .1}


def snapshot(project):
    return {**lightmap.snapshot(project), **{name: digest(project / name) for name in EXTRA}}


def contract(folder, job):
    data = read(folder / "combined-samples.json")
    lighting = read(folder / "lightmap-samples.json")["samples"]
    frames = job["frames"]
    count = frames + job["warmup_frames"]
    users = 0 if job["lighting"] == "lightmap_off" else 10
    captured = 0 if job.get("missing_lightmap_control") else users
    gi = 0 if job["lighting"] == "probes_off" else 2
    has_history = job["feature"].startswith("history")
    histories = data["oracle_histories"]
    return len(lighting) == len(data["samples"]) == count and all(
        r["frame"] == s["frame"] == max(0, n - job["warmup_frames"])
        and r["independent_worlds"] and s["independent_worlds"]
        and r["captured_users"] == captured and r["native_users"] == users
        and r["dynamic_gi_mode"] == r["native_dynamic_gi_mode"] == gi
        and r["ball_position_error"] < 1e-6 and s["panel_pose_error"] < 1e-6
        and s["panels"] == 8 and s["visible"] == (not job.get("transparency_off", False))
        and s["exposures"] == [1, 1] and s["history_weight"] == (.95 if has_history else 0)
        for n, (r, s) in enumerate(zip(lighting, data["samples"], strict=True))) and (
            len(histories) == 7 and all(len(h) == 1 and list(h.values()) == [count] for h in histories)
            if has_history else not histories)


def presence(output, jobs):
    values = {name: [] for name in [*PRESENCE, "history-off"]}
    for i in range(FRAMES):
        def frame(name):
            return pixels(output / name / f"frames/frame{i + jobs[name]['warmup_frames']:08d}.png")
        combined = frame("combined")
        for name in values:
            values[name].append(float(abs(combined - frame(name)).mean()))
    # A static warmup need not produce an afterimage. Require history throughout
    # motion, including both sides of the cut, after the opening frame.
    accepted = all(min(values[n]) > threshold for n, threshold in PRESENCE.items())
    accepted &= min(values["history-off"][1:]) > .02
    return {"ok": bool(accepted), "frames": values,
            "minima": {k: min(v) for k, v in values.items()},
            "maxima": {k: max(v) for k, v in values.items()}}


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=args.analyze)
    path = output / "combined-review.json"
    if args.analyze:
        evidence = read(path)
        project = output / "project"
        assert snapshot(project) == evidence["hashes"], "Captured sources/bake changed"
        evidence["analysis_reviewer_sha256"] = digest(Path(__file__))
    else:
        project, bake = lightmap.prepare(args, output)
        for name in EXTRA:
            shutil.copy2(ROOT / name, project / name)
        lightmap.run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "combined-import.log")
        evidence = {"ok": False, "platform": platform.platform(), "method": args.method,
                    "bake": bake, "hashes": snapshot(project), "jobs": {}, "results": {},
                    "thresholds": {"face_mae": SOURCE_MAE, "face_p99": SOURCE_P99,
                                   "assembly_mae": .2, "assembly_p99": 2, "decoded_rms": DECODED_RMS,
                                   "presence_minima": PRESENCE, "history_after_opening": .02}}
        for name, case in CASES.items():
            evidence["jobs"][name] = {"scene_path": "res://tests/fixtures/combined_scene.tscn", "camera_path": "Camera3D",
                "width": WIDTH, "height": HEIGHT, "face_size": 256, "frames": FRAMES, "fps": 30,
                "warmup_frames": 8, "capture_border_percent": 12.5, "frame_writer": "fast_png",
                "rendering_method": args.method, "rendering_driver": "vulkan", "crf": 16,
                "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()),
                "output_dir": str(output / name), "feature": "history", "lighting": "lightmap", **case}
        path.write_text(json.dumps(evidence, indent=2) + "\n")
    for name, job in evidence["jobs"].items():
        if not args.analyze:
            request = output / f"{name}.json"
            request.write_text(json.dumps(job))
            lightmap.run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
                          "--", "--job=" + str(request)], output / f"{name}.log", args.capture_timeout)
        folder = output / name
        report = read(folder / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        errors = [line.strip() for line in (folder / "capture.log").read_text(encoding="utf-8").splitlines()
                  if line.strip().startswith(("ERROR:", "SCRIPT ERROR:"))
                  and line.strip() != "ERROR: Failed to read the root certificate store."]
        assert not errors, f"{name}: {errors[:3]}"
        result = compare(folder, job, args.ffmpeg, args.analyze, require_render_buffers=False)
        result["combined_contract_ok"] = contract(folder, job)
        result["ok"] &= result["combined_contract_ok"]
        result["delivery_checks"] = report["checks"]
        result["capture_settings"] = report["capture_settings"]
        result["expected_failure"] = bool(job.get("missing_lightmap_control") or job.get("wrong_shared_history"))
        result["accepted"] = (not result["ok"] and result["maxima"]["face_mae"] > SOURCE_MAE
            and result["processing_ok"] and result["history_ok"] and result["combined_contract_ok"]
            and result["decoded_frames"] == FRAMES and result["delayed_control_rejected"]) if result["expected_failure"] else result["ok"]
        evidence["results"][name] = result
        path.write_text(json.dumps(evidence, indent=2) + "\n")
        print(name, "PASS" if result["accepted"] else "FAIL", result["maxima"], flush=True)
    evidence["feature_presence"] = presence(output, evidence["jobs"])
    evidence["source_unchanged"] = snapshot(project) == evidence["hashes"]
    evidence["ok"] = evidence["source_unchanged"] and evidence["feature_presence"]["ok"] and all(
        r["accepted"] for r in evidence["results"].values())
    sheet = Image.new("RGB", (1024, len(CASES) * 160), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(CASES):
        for col, i in enumerate([0, 71, 72, 143]):
            with Image.open(output / name / f"frames/frame{i + 8:08d}.png") as frame:
                sheet.paste(frame.resize((256, 128)), (col * 256, row * 160 + 28))
            draw.text((col * 256 + 4, row * 160 + 5), f"{name} / {i}", fill="white")
    sheet.save(output / "comparison.jpg")
    path.write_text(json.dumps(evidence, indent=2) + "\n")
    print("Combined review:", "PASS" if evidence["ok"] else "FAIL", evidence["feature_presence"]["minima"], flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile"], default="forward_plus")
    parser.add_argument("--capture-timeout", type=int, choices=[600, 1200, 1800], default=600)
    parser.add_argument("--baked-from", type=Path, help="Reuse a saved generated/ bake directory")
    parser.add_argument("--analyze", action="store_true")
    raise SystemExit(main(parser.parse_args()))
