"""Every-frame temporal/GI capture preservation against native perspective views.

References share the scene, but own their viewports, cameras and compositor state.
The independent CPU projection and full MP4 decode also check delivered output.
This measures preservation, not equivalence of different view histories at seams.
"""
import argparse
import hashlib
import json
import os
import platform
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from border_review import pixels, read, run
from motion_review import decoded_frames

ROOT = Path(__file__).resolve().parents[1]
NAMES = ["right", "left", "up", "down", "front", "back"]
WIDTH, HEIGHT, FRAMES = 1024, 512, 72
SOURCE_MAE, SOURCE_P99, DECODED_RMS = 0.15, 2.0, 2.0
CASES = {"baseline": {"feature": "baseline"}, "taa": {"feature": "taa"},
         "fsr1": {"feature": "fsr1"}, "fsr2": {"feature": "fsr2"},
         "history": {"feature": "history"}, "history-world": {"feature": "history_world"},
         "shared-history-control": {"feature": "history", "wrong_shared_history": True},
         "mobile-buffer-control": {"feature": "history", "temporal_msaa": 0, "expect_render_failure": True},
         "voxel-off": {"feature": "voxel_off"}, "voxel": {"feature": "voxel"}}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(project):
    files = list((project / "addons/godot360").rglob("*"))
    files += [project / "tests/fixtures" / name for name in
              ["renderer_lab.gd", "temporal_scene.gd", "temporal_scene.tscn", "temporal_history.gd", "temporal_probe.gd"]]
    return {p.relative_to(project).as_posix(): digest(p) for p in files if p.is_file()}


def projection(size, border):
    """Pinhole coordinates from camera bases, independently of capture's shader."""
    y, x = np.mgrid[:HEIGHT, :WIDTH]
    longitude = (x + .5) * 2 * np.pi / WIDTH - np.pi
    latitude = np.pi / 2 - (y + .5) * np.pi / HEIGHT
    rays = np.stack([np.sin(longitude) * np.cos(latitude), np.sin(latitude),
                     -np.cos(longitude) * np.cos(latitude)], axis=-1)
    directions = np.array([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, -1], [0, 0, 1]])
    ups = np.array([[0, 1, 0], [0, 1, 0], [0, 0, 1], [0, 0, -1], [0, 1, 0], [0, 1, 0]])
    extent = size + 2 * int(np.ceil(size * border / 100))
    scale = size / extent
    depths = rays @ directions.T
    largest = depths.max(axis=-1)
    raw = np.clip((depths / largest[..., None] - scale) / max(1 - scale, 1e-10), 0, 1)
    weights = raw * raw * (3 - 2 * raw) if border else (depths == largest[..., None]).astype(float)
    weights /= weights.sum(axis=-1)[..., None]
    maps = []
    for i, (direction, up) in enumerate(zip(directions, ups)):
        mask = weights[..., i] > 0
        forward = depths[..., i][mask]
        right = np.cross(direction, up)
        u = (rays[mask] @ right) / forward
        v = -(rays[mask] @ up) / forward
        sx, sy = (u * scale + 1) * extent / 2 - .5, (v * scale + 1) * extent / 2 - .5
        sx, sy = np.clip(sx, 0, extent - 1), np.clip(sy, 0, extent - 1)
        ix, iy = np.floor(sx).astype(int), np.floor(sy).astype(int)
        maps.append((mask, ix, iy, np.minimum(ix + 1, extent - 1), np.minimum(iy + 1, extent - 1),
                     (sx - ix)[:, None], (sy - iy)[:, None], weights[..., i][mask, None]))
    return maps


def assemble(faces, maps):
    panorama = np.zeros((HEIGHT, WIDTH, 3), dtype=np.float32)
    for face, (mask, ix, iy, jx, jy, fx, fy, weight) in zip(faces, maps):
        panorama[mask] += (((1 - fy) * ((1 - fx) * face[iy, ix] + fx * face[iy, jx])
                          + fy * ((1 - fx) * face[jy, ix] + fx * face[jy, jx])) * weight).astype(np.float32)
    return panorama


def diagonal_view(panorama):
    # Separate 60-degree pinhole straddling the front/right cube boundary.
    y, x = np.mgrid[:256, :256]
    u, v = (2 * (x + .5) / 256 - 1) / np.sqrt(3), (1 - 2 * (y + .5) / 256) / np.sqrt(3)
    dx, dy, dz = (1 + u) / np.sqrt(2), v, (-1 + u) / np.sqrt(2)
    sx = (np.arctan2(dx, -dz) / (2 * np.pi) + .5) * WIDTH - .5
    sy = (.5 - np.arctan2(dy, np.hypot(dx, dz)) / np.pi) * HEIGHT - .5
    ix, iy = np.floor(sx).astype(int), np.floor(sy).astype(int)
    fx, fy = (sx - ix)[..., None], (sy - iy)[..., None]
    return (1 - fy) * ((1 - fx) * panorama[iy, ix] + fx * panorama[iy, ix + 1]) + fy * (
        (1 - fx) * panorama[iy + 1, ix] + fx * panorama[iy + 1, ix + 1])


def compare(folder, job, ffmpeg, analyze, *, require_render_buffers=True):
    rows, previous = [], None
    maps = projection(job["face_size"], job["capture_border_percent"])
    oracle = folder / "oracle"
    oracle.mkdir(exist_ok=True)
    for i in range(FRAMES):
        native = [pixels(folder / f"native/{name}-{i:03d}.png") for name in NAMES]
        faces = [pixels(folder / f"faces/{name}-{i:03d}.png") for name in NAMES]
        errors = [np.abs(a - b) for a, b in zip(native, faces)]
        expected = assemble(native, maps)
        source = pixels(folder / f"frames/frame{i + job['warmup_frames']:08d}.png")
        error = abs(source - expected)
        diagonal_error = abs(diagonal_view(source) - pixels(folder / f"native/diagonal-{i:03d}.png"))
        rows.append({"frame": i, "face_mae": max(float(e.mean()) for e in errors),
                     "face_p99": max(float(np.percentile(e, 99)) for e in errors),
                     "assembly_mae": float(error.mean()), "assembly_p99": float(np.percentile(error, 99)),
                     "delayed_face_mae": max(float(abs(a - b).mean()) for a, b in zip(faces, previous)) if previous else 0,
                     "diagonal_mae_observation": float(diagonal_error.mean()),
                     "seam_strip_mae_observation": float(diagonal_error[:, 120:136].mean())})
        if not analyze:
            Image.fromarray(np.rint(expected).clip(0, 255).astype(np.uint8)).save(oracle / f"frame{i:08d}.png")
        previous = native
    if not analyze:
        color_filter = "scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv444p,colorspace=iall=bt709:itrc=srgb:irange=tv:all=bt709:range=tv:format=yuv420p"
        run([ffmpeg, "-v", "error", "-y", "-framerate", 30, "-i", oracle / "frame%08d.png",
             "-vf", color_filter, "-c:v", "libx264", "-crf", 16, "-pix_fmt", "yuv420p",
             "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
             "-color_range", "tv", oracle / "reference.mp4"], folder / "oracle-encode.log")
    decoded_count = 0
    for i, (actual, expected) in enumerate(zip(decoded_frames(ffmpeg, folder / "video-360.mp4", WIDTH, HEIGHT),
            decoded_frames(ffmpeg, oracle / "reference.mp4", WIDTH, HEIGHT), strict=True)):
        rows[i]["decoded_rms"] = float(np.sqrt(np.square(actual.astype(np.float32) - expected).mean()))
        decoded_count += 1
    samples = read(folder / "temporal-samples.json")
    processing = (len(samples["samples"]) == FRAMES + job["warmup_frames"]
                  and samples["initial"] == samples["final"]
                  and all(s["frame"] == max(0, n - job["warmup_frames"]) and s["settings_unchanged"] and len(s["faces"]) == 6 and all(
                      f["pose_error"] < 1e-5 and f["settings"] == samples["initial"] for f in s["faces"])
                      for n, s in enumerate(samples["samples"])))
    history = samples["history_counts"]
    history_ok = not job["feature"].startswith("history") or (
        len(history) >= 6 and all(count == FRAMES + job["warmup_frames"] for count in history.values()))
    voxel_ok = not job["feature"].startswith("voxel") or samples["voxel_baked"]
    buffers = samples["render_buffers"]
    face_size = job["face_size"] + 2 * int(np.ceil(job["face_size"] * job["capture_border_percent"] / 100))
    face_buffers = [r for r in buffers.values() if r["target_width"] == face_size]
    mode = {"fsr1": 1, "fsr2": 2}.get(job["feature"], 0)
    buffer_ok = not require_render_buffers or job["feature"].startswith("history") or (len(face_buffers) == 6 and all(
        r["count"] == FRAMES + job["warmup_frames"]
        # At native resolution this engine reports its internal disabled-scaler
        # sentinel (255), not the requested bilinear enum. FSR must be exact.
        and r["scaling_mode"] in ([mode] if mode else [0, 255])
        and r["taa"] == (job["feature"] == "taa")
        and abs(r["internal_width"] - face_size * (.67 if mode else 1)) <= 1 for r in face_buffers))
    control_rejected = max(r["delayed_face_mae"] for r in rows) > SOURCE_MAE
    return {"ok": decoded_count == FRAMES and processing and history_ok and voxel_ok and buffer_ok and control_rejected and all(
                r["face_mae"] < SOURCE_MAE and r["face_p99"] <= SOURCE_P99
                and r["assembly_mae"] < .2 and r["assembly_p99"] <= 2 and r["decoded_rms"] < DECODED_RMS for r in rows),
            "processing_ok": processing, "history_ok": history_ok, "history_counts": history,
            "render_buffers_ok": buffer_ok, "render_buffers": buffers, "decoded_frames": decoded_count,
            "voxel_baked": samples["voxel_baked"], "delayed_control_rejected": control_rejected,
            "maxima": {key: max(r[key] for r in rows) for key in rows[0] if key != "frame"}, "frames": rows}


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=args.analyze)
    project = output / "project"
    if args.analyze:
        evidence = read(output / "temporal-review.json")
        assert evidence["hashes"] == snapshot(project), "Captured source changed"
        evidence["analysis_reviewer_sha256"] = digest(Path(__file__))
    else:
        for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
            path = output / "profile" / key
            path.mkdir(parents=True)
            os.environ[key] = str(path)
        for name in ["addons/godot360", "tests"]:
            shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__"))
        (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 temporal review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
''')
        run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
        names = args.cases.split(",")
        evidence = {"ok": False, "platform": platform.platform(), "method": args.method, "driver": args.driver,
                    "hashes": snapshot(project), "reviewer_sha256": digest(Path(__file__)), "jobs": {}, "results": {}}
        for name in names:
            assert name in CASES, name
            job = {"scene_path": "res://tests/fixtures/temporal_scene.tscn", "camera_path": "Camera3D",
                   "width": WIDTH, "height": HEIGHT, "face_size": 256, "frames": FRAMES, "fps": 30,
                   "warmup_frames": args.warmup, "capture_border_percent": args.border, "frame_writer": "fast_png",
                   "temporal_msaa": 2 if args.method == "mobile" else 0,
                   "rendering_method": args.method, "rendering_driver": args.driver, "crf": 16,
                   "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()),
                   "output_dir": str(output / name), **CASES[name]}
            evidence["jobs"][name] = job
        (output / "temporal-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    for name, job in evidence["jobs"].items():
        if not args.analyze:
            request = output / (name + ".json")
            request.write_text(json.dumps(job))
            try:
                run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
                     "--", "--job=" + str(request)], output / (name + ".log"))
            except RuntimeError:
                if not job.get("expect_render_failure"):
                    raise
        log_text = (output / name / "capture.log").read_text(encoding="utf-8")
        errors = [line.strip() for line in log_text.splitlines() if line.strip().startswith(("ERROR:", "SCRIPT ERROR:"))
                  and line.strip() != "ERROR: Failed to read the root certificate store."]
        if job.get("expect_render_failure"):
            state = read(output / name / "status.json")
            capture = read(output / name / "capture-result.json")
            recovery = read(output / name / "recovery.json")
            result = {"ok": state.get("stage") == "Failed" and capture.get("ok") is False
                      and "Renderer failed during capture" in capture.get("error", "")
                      and any("TEXTURE_USAGE_STORAGE_BIT" in error for error in errors)
                      and capture.get("rendered") == FRAMES + job["warmup_frames"]
                      and recovery.get("can_reencode") is False
                      and not (output / name / "video-360.mp4").exists(),
                      "expected_failure": False, "render_failure_control": True,
                      "state": state, "capture": capture, "recovery": recovery, "error_count": len(errors)}
            evidence["results"][name] = result
            print(name, "PASS" if result["ok"] else "FAIL", "rendering failure is diagnosed before encoding", flush=True)
            (output / "temporal-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
            continue
        assert not errors, f"{name}: engine errors in capture.log: {errors[:3]}"
        report = read(output / name / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        result = compare(output / name, job, args.ffmpeg, args.analyze)
        result["capture_settings"] = report["capture_settings"]
        result["delivery_checks"] = report["checks"]
        result["expected_failure"] = bool(job.get("wrong_shared_history", False))
        evidence["results"][name] = result
        print(name, "PASS" if result["ok"] else "FAIL", result["maxima"], flush=True)
        (output / "temporal-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    evidence["feature_presence"] = {}
    for name, baseline in [(n, "baseline") for n in ["taa", "fsr1", "fsr2", "history", "history-world"]] + [("voxel", "voxel-off")]:
        if name not in evidence["jobs"] or baseline not in evidence["jobs"]:
            continue
        values = []
        for i in range(FRAMES):
            frame = lambda n: output / n / f"frames/frame{i + evidence['jobs'][n]['warmup_frames']:08d}.png"
            values.append(float(abs(pixels(frame(name)) - pixels(frame(baseline))).mean()))
        evidence["feature_presence"][name] = {"ok": max(values) > .02, "max_mae": max(values)}
    evidence["source_unchanged"] = evidence["hashes"] == snapshot(project)
    evidence["ok"] = evidence["source_unchanged"] and all(
        (not r["ok"] and r["processing_ok"] and r["history_ok"] and r["decoded_frames"] == FRAMES
         and r["maxima"]["face_mae"] > SOURCE_MAE) if r["expected_failure"] else r["ok"]
        for r in evidence["results"].values()) and all(
        r["ok"] for r in evidence["feature_presence"].values())
    sheet = Image.new("RGB", (1024, len(evidence["jobs"]) * 160), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(evidence["jobs"]):
        for col, i in enumerate([0, 18, 36, 60]):
            sheet.paste(Image.open(output / name / f"frames/frame{i + evidence['jobs'][name]['warmup_frames']:08d}.png").resize((256, 128)), (col * 256, row * 160 + 28))
            draw.text((col * 256 + 4, row * 160 + 5), f"{name} / {i}", fill="white")
    sheet.save(output / "comparison.jpg")
    (output / "temporal-review.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--cases", default=",".join(n for n in CASES if n != "mobile-buffer-control"))
    parser.add_argument("--warmup", type=int, choices=range(11), default=8)
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--analyze", action="store_true")
    raise SystemExit(main(parser.parse_args()))
