"""Native rendered appearance review; headless contracts do not replace this test.

Creates a fresh addon-only project, full MP4s, cube/perspective references and
independent image measurements. Requires Godot, FFmpeg, numpy and Pillow.
"""
import argparse
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def run(command, log, timeout=300):
    with log.open("wb") as output:
        result = subprocess.run([str(x) for x in command], stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"Command exited {result.returncode}: {log}")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def pixels(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def measure(folder):
    job = read(folder / "job.json")
    captures = []
    for index in (0, int(job["frames"]) // 2, int(job["frames"]) - 1):
        hdr_path = folder / f"references/native-{index:03d}.rgba32f"
        if hdr_path.exists():
            linear = np.fromfile(hdr_path, dtype="<f4").reshape(int(job["face_size"]), int(job["face_size"]), 4)[:, :, :3].clip(0, 1)
            srgb = np.where(linear <= .0031308, 12.92 * linear, 1.055 * linear ** (1 / 2.4) - .055)
            Image.fromarray(np.rint(srgb * 255).clip(0, 255).astype(np.uint8)).save(folder / f"references/native-{index:03d}.png")
        native = pixels(folder / f"references/native-{index:03d}.png")
        face = pixels(folder / f"references/front-{index:03d}.png")
        delta = np.abs(native - face)
        pano = pixels(folder / f"frames/frame{index + int(job['warmup_frames']):08d}.png")
        # Independent angular mapping at panorama pixel centers. Compare to the
        # nearest face texel, excluding steep edges where filtering differs.
        h, w = pano.shape[:2]
        y, x = np.mgrid[:h, :w]
        lon = ((x + .5) / w - .5) * 2 * np.pi
        lat = (.5 - (y + .5) / h) * np.pi
        dx, dy, dz = np.sin(lon) * np.cos(lat), np.sin(lat), -np.cos(lon) * np.cos(lat)
        expected = np.zeros_like(pano)
        smooth = np.zeros((h, w), dtype=bool)
        axes = np.argmax(np.stack([np.abs(dx), np.abs(dy), np.abs(dz)]), axis=0)
        for name, mask, u, v in [
            ("right", (axes == 0) & (dx > 0), dz / np.abs(dx), -dy / np.abs(dx)),
            ("left", (axes == 0) & (dx < 0), -dz / np.abs(dx), -dy / np.abs(dx)),
            ("up", (axes == 1) & (dy > 0), dx / np.abs(dy), -dz / np.abs(dy)),
            ("down", (axes == 1) & (dy < 0), dx / np.abs(dy), dz / np.abs(dy)),
            ("front", (axes == 2) & (dz < 0), dx / np.abs(dz), -dy / np.abs(dz)),
            ("back", (axes == 2) & (dz > 0), -dx / np.abs(dz), -dy / np.abs(dz)),
        ]:
            cube = pixels(folder / f"references/{name}-{index:03d}.png")
            size = cube.shape[0]
            cx = np.clip(((u[mask] + 1) * .5 * size).astype(int), 1, size - 2)
            cy = np.clip(((v[mask] + 1) * .5 * size).astype(int), 1, size - 2)
            expected[mask] = cube[cy, cx]
            neighbors = np.stack([cube[cy + a, cx + b] for a, b in [(-1, 0), (1, 0), (0, -1), (0, 1)]])
            smooth[mask] = np.max(np.abs(neighbors - cube[cy, cx]), axis=(0, 2)) < 3
        assembly = np.abs(expected - pano)[smooth]
        captures.append({"frame": index, "native_face_mae": float(delta.mean()),
                         "native_face_p99": float(np.percentile(delta, 99)),
                         "assembly_smooth_mae": float(assembly.mean()),
                         "assembly_smooth_p99": float(np.percentile(assembly, 99)),
                         "smooth_pixels": int(smooth.sum())})
    return captures


def main(args):
    args.output = args.output.resolve()
    args.output.mkdir(parents=True)
    project = args.output / "project"
    project.mkdir()
    shutil.copytree(ROOT / "addons/godot360", project / "addons/godot360")
    shutil.copytree(ROOT / "tests", project / "tests", ignore=shutil.ignore_patterns("__pycache__"))
    (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Renderer appearance review"
[display]
window/size/viewport_width=1024
window/size/viewport_height=512
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
viewport/hdr_2d=true
''', encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], args.output / "import.log")
    results = []
    features = args.features.split(",")
    if any(feature in features for feature in ["compositor", "world_compositor"]):
        # A matching native/face pair can otherwise pass with the effect missing
        # in both. Always establish the otherwise-identical untinted scene first.
        features = ["lit"] + [feature for feature in features if feature != "lit"]
    for feature in features:
        folder = args.output / feature
        request = args.output / (feature + "-request.json")
        job = {"scene_path": "res://tests/fixtures/renderer_lab.tscn", "camera_path": "Camera3D",
               "width": 1024, "height": 512, "face_size": 512, "frames": 30, "fps": 30,
               "warmup_frames": 8, "crf": 16, "feature": feature, "frame_writer": "fast_png",
               "reference_hdr": args.reference_hdr,
               "rendering_method": "project", "rendering_driver": "project",
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()), "output_dir": str(folder)}
        request.write_text(json.dumps(job), encoding="utf-8")
        try:
            run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], args.output / (feature + "-pipeline.log"))
            report = read(folder / "report.json")
            measurements = measure(folder)
            settings = read(folder / "capture-settings.json")
            # Temporal histories / GI may depend on each viewport's initialization.
            native_limit = 0.1
            ok = report["ok"] and all(report["checks"].values()) and all(m["native_face_mae"] < native_limit and m["native_face_p99"] <= 2 and m["assembly_smooth_p99"] <= 3 for m in measurements)
            result = {"feature": feature, "ok": ok, "capture_settings": settings, "measurements": measurements, "delivery_checks": report["checks"]}
            if feature in ["compositor", "world_compositor"]:
                presence = []
                for index in (0, job["frames"] // 2, job["frames"] - 1):
                    for face in ["right", "left", "up", "down", "front", "back"]:
                        filename = f"references/{face}-{index:03d}.png"
                        baseline = pixels(args.output / "lit" / filename)
                        tinted = pixels(folder / filename)
                        delta = baseline - tinted
                        presence.append({"frame": index, "face": face,
                                         "red_reduction": float(delta[:, :, 0].mean()),
                                         "blue_reduction": float(delta[:, :, 2].mean()),
                                         "green_mae": float(abs(delta[:, :, 1]).mean())})
                result["tint_presence"] = presence
                result["tint_presence_ok"] = all(p["red_reduction"] > .5 and p["blue_reduction"] > .5
                                                 and p["green_mae"] < .2 for p in presence)
                result["ok"] &= result["tint_presence_ok"]
        except (RuntimeError, OSError, KeyError, subprocess.TimeoutExpired) as error:
            result = {"feature": feature, "ok": False, "error": str(error)}
        results.append(result)
        print(feature, "PASS" if result["ok"] else "FAIL", result.get("error", ""), flush=True)
        (args.output / "renderer-review.json").write_text(json.dumps({"ok": all(r["ok"] for r in results), "platform": platform.platform(), "method": args.method, "driver": args.driver, "results": results}, indent=2), encoding="utf-8")
    if args.motion:
        folder = args.output / "motion"
        request = args.output / "motion-request.json"
        job.update({"scene_path": "res://tests/fixtures/motion.tscn", "camera_path": "CameraPath/Follow/Camera3D", "width": 2048, "height": 1024, "face_size": 1024, "frames": 180, "warmup_frames": 2, "output_dir": str(folder)})
        request.write_text(json.dumps(job), encoding="utf-8")
        try:
            run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(request)], args.output / "motion-pipeline.log", timeout=600)
            run([sys.executable, ROOT / "tests/motion_review.py", folder, "--ffmpeg", args.ffmpeg.resolve()], args.output / "motion-review.log", timeout=300)
            result = {"feature": "motion", "ok": read(folder / "motion-review.json")["ok"], "review": str(folder / "motion-review.json")}
        except (RuntimeError, OSError, KeyError, subprocess.TimeoutExpired) as error:
            result = {"feature": "motion", "ok": False, "error": str(error)}
        results.append(result)
        print("motion", "PASS" if result["ok"] else "FAIL", result.get("error", ""), flush=True)
        (args.output / "renderer-review.json").write_text(json.dumps({"ok": all(r["ok"] for r in results), "platform": platform.platform(), "method": args.method, "driver": args.driver, "results": results}, indent=2), encoding="utf-8")
    rows = []
    for result in results:
        path = args.output / result["feature"] / "preview.png"
        if path.exists():
            row = Image.new("RGB", (1024, 294), "#182027")
            row.paste(Image.open(path).convert("RGB").resize((512, 256)), (0, 30))
            ref = args.output / result["feature"] / "references/native-000.png"
            if ref.exists():
                row.paste(Image.open(ref).convert("RGB").resize((256, 256)), (520, 30))
            ImageDraw.Draw(row).text((8, 8), f"{args.method} / {args.driver} - {result['feature']} | panorama + native perspective", fill="white")
            rows.append(row)
    if rows:
        sheet = Image.new("RGB", (1024, 294 * len(rows)))
        for n, row in enumerate(rows):
            sheet.paste(row, (0, n * 294))
        sheet.save(args.output / "contact-sheet.jpg")
    return 0 if all(r["ok"] for r in results) else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], required=True)
    parser.add_argument("--driver", required=True)
    parser.add_argument("--features", default="color,lit,exposure,glow,fog,volumetric,screen,gi,taa,physical,compositor,world_compositor")
    parser.add_argument("--reference-hdr", action="store_true", help="Compare against native HDR 2D viewport after sRGB transfer")
    parser.add_argument("--motion", action="store_true", help="Also check every frame, seam/pole marker and audio cue in a six-second export")
    raise SystemExit(main(parser.parse_args()))
