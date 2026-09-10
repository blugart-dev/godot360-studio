"""Compare native tube/ribbon trails with simultaneous diagonal single-view renders.

This validates spherical capture against native appearance, not an independent
particle simulation. Compatibility feature availability is measured separately.
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
from smoke_review import processing, source, WIDTH, HEIGHT, FRAMES

ROOT = Path(__file__).resolve().parents[1]
CASES = {"tube": {}, "ribbon": {"trail_shape": "ribbon"},
         "tube-pause": {"smoke_pause": 24}, "tube-disabled": {"trail_disabled": True}}


def flat_view(panorama):
    # Independent pinhole rays, at 45 degrees across the front/right cube edge.
    y, x = np.mgrid[:512, :512]
    u, v = (2 * (x + .5) / 512 - 1) * np.tan(np.pi / 6), (1 - 2 * (y + .5) / 512) * np.tan(np.pi / 6)
    dx, dy, dz = (1 + u) / np.sqrt(2), v, (-1 + u) / np.sqrt(2)
    lon, lat = np.arctan2(dx, -dz), np.arctan2(dy, np.sqrt(dx * dx + dz * dz))
    sx, sy = (lon / (2 * np.pi) + .5) * WIDTH - .5, (.5 - lat / np.pi) * HEIGHT - .5
    ix, iy = np.floor(sx).astype(int), np.floor(sy).astype(int)
    fx, fy = (sx - ix)[..., None], (sy - iy)[..., None]
    return ((1 - fy) * ((1 - fx) * panorama[iy, ix] + fx * panorama[iy, ix + 1])
            + fy * ((1 - fx) * panorama[iy + 1, ix] + fx * panorama[iy + 1, ix + 1]))


def coverage(picture):
    # Continuous orange coverage makes the geometry check insensitive to the
    # extra resampling at a 360-to-flat reprojection's antialiased silhouette.
    weight = np.clip((picture[..., 0] - 30) / 180, 0, 1)
    y, x = np.mgrid[:512, :512]
    area = float(weight.sum())
    center = np.array([(weight * x).sum(), (weight * y).sum()]) / max(area, 1e-8)
    return area, center


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=args.analyze)
    for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        path = output / "profile" / key
        path.mkdir(parents=True, exist_ok=args.analyze)
        os.environ[key] = str(path)
    project = output / "project"
    for name in ["addons/godot360", "tests"]:
        if not args.analyze:
            shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__"))
    if not args.analyze:
        (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 trail review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''')
    if not args.analyze:
        run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    evidence = {"method": read(output / "tube.json")["rendering_method"] if args.analyze else args.method,
                "driver": read(output / "tube.json")["rendering_driver"] if args.analyze else args.driver,
                "jobs": {}, "processing": {}, "views": {}, "delivery": {},
                "reference_kind": "Simultaneous native single view; independent projection, shared simulation",
                "hashes": {p.relative_to(project).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in
                           [project / "tests/fixtures/trail_scene.gd", project / "tests/fixtures/smoke_scene.gd",
                            project / "addons/godot360/capture.gd", project / "addons/godot360/capture_rig.gd"]},
                "reviewer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    jobs = evidence["jobs"]
    for name, extra in CASES.items():
        job = read(output / (name + ".json")) if args.analyze else {"scene_path": "res://tests/fixtures/trail_scene.tscn", "camera_path": "Camera3D",
               "width": WIDTH, "height": HEIGHT, "face_size": 512, "fps": 30, "frames": FRAMES,
               "warmup_frames": 2, "capture_border_percent": args.border, "crf": 16,
               "frame_writer": "fast_png", "rendering_method": args.method, "rendering_driver": args.driver,
               "output_dir": str(output / name), "ffmpeg": str(args.ffmpeg.resolve()),
               "ffprobe": str(args.ffprobe.resolve()), **extra}
        jobs[name] = job
        request = output / (name + ".json")
        if not args.analyze:
            request.write_text(json.dumps(job))
            run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
                 "--", "--job=" + str(request)], output / (name + ".log"))
        report = read(output / name / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        evidence["delivery"][name] = {"checks": report["checks"], "settings": report["capture_settings"]}
        evidence["processing"][name] = processing(output, name, job)
        color_filter = "scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv444p,colorspace=iall=bt709:itrc=srgb:irange=tv:all=bt709:range=tv:format=yuv420p"
        run([args.ffmpeg, "-v", "error", "-y", "-framerate", 30, "-i", output / name / "direct/frame%08d.png",
             "-vf", color_filter, "-c:v", "libx264", "-crf", 16, "-pix_fmt", "yuv420p", "-color_primaries", "bt709",
             "-color_trc", "bt709", "-colorspace", "bt709", "-color_range", "tv", output / name / "direct.mp4"], output / (name + "-direct-encode.log"))
        rows = []
        delayed = []
        for i, (decoded, reference_decoded) in enumerate(zip(
                decoded_frames(args.ffmpeg, output / name / "video-360.mp4", WIDTH, HEIGHT),
                decoded_frames(args.ffmpeg, output / name / "direct.mp4", 512, 512), strict=True)):
            direct = pixels(output / name / f"direct/frame{i:08d}.png")
            view = flat_view(source(output, name, i, jobs))
            mask = np.maximum(direct[..., 0], view[..., 0]) > 100
            error = abs(view - direct)
            area, center = coverage(view)
            ref_area, ref_center = coverage(direct)
            if i > 0:
                late = pixels(output / name / f"direct/frame{i - 1:08d}.png")
                late_area, late_center = coverage(late)
                delayed.append(float(np.linalg.norm(center - late_center)))
            rows.append({"frame": i, "mae": float(error.mean()), "foreground": int(mask.sum()),
                         "area_ratio": area / max(ref_area, 1e-8), "reference_area": ref_area,
                         "centroid_error_pixels": float(np.linalg.norm(center - ref_center)),
                         "foreground_mae": float(error[mask].mean()) if mask.any() else 255,
                         "decoded_mae": float(abs(flat_view(decoded.astype(np.float32)) - reference_decoded).mean())})
        evidence["views"][name] = {"frames": rows, "max_mae": max(r["mae"] for r in rows),
            "max_foreground_mae": max(r["foreground_mae"] for r in rows),
            "max_centroid_error_pixels": max(r["centroid_error_pixels"] for r in rows),
            "max_delayed_centroid_error_pixels": max(delayed), "delayed_control_rejected": max(delayed) > 1.5,
            "max_decoded_mae": max(r["decoded_mae"] for r in rows),
            # Two rasterizations plus equirectangular resampling put hard edges
            # on different subpixels. Gate coverage and centroid as well as RGB.
            "ok": len(rows) == FRAMES and max(delayed) > 1.5 and all(r["mae"] < 1 and r["decoded_mae"] < 1.2
                and .9 < r["area_ratio"] < 1.1 and r["centroid_error_pixels"] < 1.5 and r["reference_area"] > 5 for r in rows)}
        print(name, "processing", evidence["processing"][name]["ok"], {k:v for k,v in evidence["views"][name].items() if k != "frames"}, flush=True)
        (output / "trail-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    effect = [float(abs(source(output, "tube", i, jobs) - source(output, "tube-disabled", i, jobs)).mean()) for i in range(FRAMES)]
    evidence["trail_effect_mae"] = effect
    supported = evidence["method"] != "gl_compatibility"
    evidence["native_trails_supported"] = supported
    evidence["feature_check_ok"] = max(effect) > .05 if supported else max(effect) == 0
    evidence["ok"] = evidence["feature_check_ok"] and all(r["ok"] for r in evidence["processing"].values()) and all(r["ok"] for r in evidence["views"].values())
    sheet = Image.new("RGB", (1024, 1084), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(["tube", "ribbon"]):
        source_view = Image.fromarray(np.clip(flat_view(source(output, name, 48, jobs)), 0, 255).astype(np.uint8))
        sheet.paste(source_view, (0, row * 542 + 30))
        sheet.paste(Image.open(output / name / "direct/frame00000048.png"), (512, row * 542 + 30))
        draw.text((8, row * 542 + 8), name + " / spherical capture", fill="white")
        draw.text((520, row * 542 + 8), name + " / direct perspective reference", fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "trail-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--analyze", action="store_true")
    raise SystemExit(main(parser.parse_args()))
