"""Render moving glow edges with/without capture borders and measure discontinuities.

Uses the actual capture/encode/verification pipeline in a fresh isolated project.
Requires Godot, FFmpeg/FFprobe, NumPy and Pillow. No user's settings are opened.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def run(command, log, timeout=600):
    with log.open("wb") as output:
        result = subprocess.run([str(x) for x in command], stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {log}")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def pixels(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def face_ids(width, height):
    y, x = np.mgrid[:height, :width]
    lon, lat = ((x + .5) / width - .5) * 2 * np.pi, (.5 - (y + .5) / height) * np.pi
    d = np.stack([np.sin(lon) * np.cos(lat), np.sin(lat), -np.cos(lon) * np.cos(lat)])
    axis = np.argmax(abs(d), axis=0)
    sign = np.take_along_axis(d, axis[None], axis=0)[0] > 0
    return axis * 2 + sign


def seam_score(picture, ids):
    # Excess edge gradient over the neighboring gradient distinguishes a hard
    # face cut from the emitter's ordinary smooth halo. Ignore the emitter core.
    luma = picture.mean(axis=2)
    values = []
    for image, faces in [(luma, ids), (luma.T, ids.T)]:
        jumps = abs(image[:, 1:] - image[:, :-1])
        excess = np.maximum(jumps[:, 1:-1] - .5 * (jumps[:, :-2] + jumps[:, 2:]), 0)
        boundary = faces[:, 1:-2] != faces[:, 2:-1]
        core = np.maximum(image[:, 1:-2], image[:, 2:-1]) >= 240
        values.extend(excess[boundary & ~core].tolist())
    # Fixed count keeps a border from winning simply by spreading the same cut.
    return float(np.sort(values)[-128:].mean())


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True)
    for name in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        directory = output / "profile" / name
        directory.mkdir(parents=True)
        os.environ[name] = str(directory)
    project = output / "project"
    for name in ["addons/godot360", "tests"]:
        shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__"))
    (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 capture border review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    evidence = {"method": args.method, "driver": args.driver, "jobs": {}, "comparisons": []}
    for name, percent, glow in [("baseline", 0.0, True), ("border", 12.5, True), ("plain-baseline", 0.0, False), ("plain-border", 12.5, False)]:
        folder = output / name
        job = {"scene_path": "res://tests/fixtures/border_scene.tscn", "camera_path": "Camera3D",
               "width": 2048, "height": 1024, "face_size": 512, "fps": 30, "frames": 90,
               "warmup_frames": 8, "glow": glow, "capture_border_percent": percent,
               "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(folder),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
        request = output / (name + ".json")
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], output / (name + ".log"))
        report = read(folder / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        settings = read(folder / "capture-settings.json")
        assert settings["face_texture_size"] == (640 if percent else 512)
        assert settings["face_border_pixels"] == (64 if percent else 0)
        assert settings["capture_border_percent"] == percent
        evidence["jobs"][name] = {"checks": report["checks"], "capture_settings": settings,
                                   "pipeline_timings": report.get("pipeline_timings"),
                                   "capture_timings": {k:v for k,v in report.get("capture_timings", {}).items() if k != "frames"}}
        print(name, "DELIVERY PASS", flush=True)
    ids = face_ids(2048, 1024)
    plain_deltas = []
    scores = []
    for index in range(90):
        filename = f"frames/frame{index + 8:08d}.png"
        baseline, border = [pixels(output / name / filename) for name in ["baseline", "border"]]
        scores.append({"frame": index, "baseline": seam_score(baseline, ids), "border": seam_score(border, ids)})
        plain_a, plain_b = [pixels(output / name / filename) for name in ["plain-baseline", "plain-border"]]
        plain_deltas.append(float(abs(plain_a - plain_b).mean()))
    for start, end, label in [(0,30,"equatorial edge"), (30,60,"three-face corner"), (60,90,"top edge")]:
        before = np.mean([s["baseline"] for s in scores[start:end]])
        after = np.mean([s["border"] for s in scores[start:end]])
        result = {"location": label, "baseline_score": float(before), "border_score": float(after),
                  "reduction_percent": float((1 - after / before) * 100) if before else 0}
        evidence["comparisons"].append(result)
    evidence["frame_scores"] = scores
    evidence["plain_frame_max_mae"] = max(plain_deltas)
    evidence["ok"] = all(c["baseline_score"] > 1 and c["reduction_percent"] > 50 for c in evidence["comparisons"]) and max(plain_deltas) < .1
    sheet = Image.new("RGB", (900, 660), "#141a22")
    draw = ImageDraw.Draw(sheet)
    # Reproject the same retained frames to a normal view centered on each edge.
    for column, (index, yaw, pitch) in enumerate([(0,45,0),(30,45,35.264),(60,0,45)]):
        for row, name in enumerate(["baseline","border"]):
            source = output / name / f"frames/frame{index+8:08d}.png"
            picture = output / f"{name}-{index}.png"
            run([args.ffmpeg,"-v","error","-nostdin","-i",source,"-vf",f"v360=equirect:flat:yaw={yaw}:pitch={pitch}:h_fov=45:v_fov=45:w=300:h=300","-frames:v",1,"-update",1,picture], output / f"view-{name}-{index}.log")
            sheet.paste(Image.open(picture).convert("RGB"),(column*300,row*330+30))
            draw.text((column*300+6,row*330+8),f"{name}: {evidence['comparisons'][column]['location']}",fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "border-review.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k:v for k,v in evidence.items() if k not in ["jobs","frame_scores"]}, indent=2),flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot","ffmpeg","ffprobe","output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus","mobile"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    raise SystemExit(main(parser.parse_args()))
