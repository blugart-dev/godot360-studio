"""Bake a saved LightmapGI scene, then compare every exported frame to a second world.

The editor helper invokes the real Bake Lightmaps action in a disposable project.
No baking takes place in capture workers. All cases use the same saved bake.
"""
import argparse
import json
import os
import platform
import shutil
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from border_review import pixels, read
from temporal_review import compare, digest, snapshot as temporal_snapshot, WIDTH, HEIGHT, FRAMES, SOURCE_MAE

ROOT = Path(__file__).resolve().parents[1]
CASES = {"lightmap": {"feature": "lightmap"}, "lightmap-off": {"feature": "lightmap_off"},
         "probes-off": {"feature": "probes_off"},
         "missing-map-control": {"feature": "lightmap", "missing_lightmap_control": True}}


def run(command, log, timeout=600):
    with log.open("wb") as output:
        completed = subprocess.run([str(x) for x in command], stdout=output, stderr=subprocess.STDOUT,
                                   timeout=timeout, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    assert completed.returncode == 0, f"Command failed: {log}"
    errors = [line for line in log.read_text(encoding="utf-8", errors="replace").splitlines()
              if line.startswith(("ERROR:", "SCRIPT ERROR:"))
              and line != "ERROR: Failed to read the root certificate store."]
    assert not errors, f"Engine errors in {log}: {errors[:3]}"


def snapshot(project):
    result = temporal_snapshot(project)
    files = list((project / "generated").rglob("*"))
    files += [project / "tests/fixtures" / name for name in
              ["lightmap_bake.gd", "lightmap_scene.gd", "lightmap_scene.tscn", "renderer_tint.gd"]]
    files += [project / "tests" / name for name in
              ["lightmap_review.py", "temporal_review.py", "border_review.py", "motion_review.py"]]
    result.update({p.relative_to(project).as_posix(): digest(p) for p in files if p.is_file()})
    return result


def prepare(args, output):
    project = output / "project"
    for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        path = output / "profile" / key
        path.mkdir(parents=True)
        os.environ[key] = str(path)
    shutil.copytree(ROOT / "addons/godot360", project / "addons/godot360")
    (project / "tests/fixtures").mkdir(parents=True)
    for name in ["renderer_lab.gd", "renderer_tint.gd", "temporal_scene.gd", "temporal_scene.tscn", "temporal_history.gd", "temporal_probe.gd",
                 "lightmap_bake.gd", "lightmap_scene.gd", "lightmap_scene.tscn"]:
        shutil.copy2(ROOT / "tests/fixtures" / name, project / "tests/fixtures" / name)
    for name in ["lightmap_review.py", "temporal_review.py", "border_review.py", "motion_review.py"]:
        shutil.copy2(ROOT / "tests" / name, project / "tests" / name)
    config = '''config_version=5
[application]
config/name="Godot360 LightmapGI review"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="vulkan"
rendering_device/driver.linuxbsd="vulkan"
'''
    (project / "project.godot").write_text(config, encoding="utf-8")
    if args.baked_from:
        shutil.copytree(args.baked_from, project / "generated")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    if not args.baked_from:
        plugin = project / "addons/review_bake"
        plugin.mkdir()
        shutil.copy2(project / "tests/fixtures/lightmap_bake.gd", plugin / "plugin.gd")
        (plugin / "plugin.cfg").write_text('[plugin]\nname="Lightmap review bake"\ndescription="Disposable helper"\n'
                                           'author="Godot360"\nversion="1.0"\nscript="plugin.gd"\n')
        (project / "project.godot").write_text(config + '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/review_bake/plugin.cfg")\n')
        # Baking is silent; choose Dummy explicitly on workers without audio hardware.
        run([args.godot, "--editor", "--minimized", "--audio-driver", "Dummy",
             "--path", project, "--language", "en"], output / "bake.log", 300)
    bake = read(project / "generated/bake.json")
    assert bake["ok"] and bake["users"] == 10 and bake["textures"] > 0 and bake["probe_points"] > 0 and bake["directional"], bake
    (project / "project.godot").write_text(config.replace('"forward_plus"', f'"{args.method}"'))
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "baked-import.log")
    return project, bake


def lightmap_contract(folder, job):
    records = read(folder / "lightmap-samples.json")["samples"]
    users = 0 if job["feature"] == "lightmap_off" else 10
    captured_users = 0 if job.get("missing_lightmap_control") else users
    mode = 0 if job["feature"] == "probes_off" else 2
    return len(records) == FRAMES + job["warmup_frames"] and all(
        r["frame"] == max(0, n - job["warmup_frames"]) and r["independent_worlds"]
        and r["captured_users"] == captured_users and r["native_users"] == users
        and r["dynamic_gi_mode"] == r["native_dynamic_gi_mode"] == mode
        and r["ball_position_error"] < 1e-6 for n, r in enumerate(records))


def ball_mask(frame):
    """Analytic inner sphere silhouette, excluding the rasterized rim."""
    y, x = np.mgrid[:HEIGHT, :WIDTH]
    lon = (x + .5) * 2 * np.pi / WIDTH - np.pi
    lat = np.pi / 2 - (y + .5) * np.pi / HEIGHT
    rays = np.stack([np.sin(lon) * np.cos(lat), np.sin(lat), -np.cos(lon) * np.cos(lat)], axis=-1)
    phase = frame * 2 * np.pi / FRAMES
    ball = np.array([np.sin(phase) * 3, np.sin(phase * 2) * .6, -np.cos(phase) * 3])
    if frame >= FRAMES // 2:
        # Godot Basis.from_euler uses YXZ order: Ry * Rx * Rz.
        ax, ay, az = .08, .35, .1
        rx = np.array([[1, 0, 0], [0, np.cos(ax), -np.sin(ax)], [0, np.sin(ax), np.cos(ax)]])
        ry = np.array([[np.cos(ay), 0, np.sin(ay)], [0, 1, 0], [-np.sin(ay), 0, np.cos(ay)]])
        rz = np.array([[np.cos(az), -np.sin(az), 0], [np.sin(az), np.cos(az), 0], [0, 0, 1]])
        ball = (ry @ rx @ rz).T @ (ball - [.3, .1, -.2])
    distance = np.linalg.norm(ball)
    return rays @ (ball / distance) > np.sqrt(1 - (.55 * .9 / distance) ** 2)


def presence(output, jobs):
    metrics = {"static_lightmaps": [], "dynamic_probes": [], "probe_control_background": []}
    for i in range(FRAMES):
        frame = lambda name: pixels(output / name / f"frames/frame{i + jobs[name]['warmup_frames']:08d}.png")
        enabled, disabled, no_probes = [frame(n) for n in ["lightmap", "lightmap-off", "probes-off"]]
        mask = ball_mask(i)
        assert mask.sum() > 500
        metrics["static_lightmaps"].append(float(abs(enabled - disabled)[~mask].mean()))
        metrics["dynamic_probes"].append(float(abs(enabled - no_probes)[mask].mean()))
        metrics["probe_control_background"].append(float(abs(enabled - no_probes)[~mask].mean()))
    return {"ok": min(metrics["static_lightmaps"]) > 1 and min(metrics["dynamic_probes"]) > .5,
            "frames": metrics, "minima": {key: min(values) for key, values in metrics.items()},
            "maxima": {key: max(values) for key, values in metrics.items()}}


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=args.analyze)
    path = output / "lightmap-review.json"
    if args.analyze:
        project = output / "project"
        evidence = read(path)
        assert snapshot(project) == evidence["hashes"], "Captured sources/bake changed"
        evidence["analysis_reviewer_sha256"] = digest(Path(__file__))
    else:
        project, bake = prepare(args, output)
        evidence = {"ok": False, "platform": platform.platform(), "method": args.method,
                    "bake": bake, "hashes": snapshot(project), "jobs": {}, "results": {}}
        for name, case in CASES.items():
            evidence["jobs"][name] = {"scene_path": "res://tests/fixtures/lightmap_scene.tscn", "camera_path": "Camera3D",
                "width": WIDTH, "height": HEIGHT, "face_size": 256, "frames": FRAMES, "fps": 30,
                "warmup_frames": args.warmup, "capture_border_percent": args.border, "frame_writer": "fast_png",
                "rendering_method": args.method, "rendering_driver": "opengl3" if args.method == "gl_compatibility" else "vulkan",
                "crf": 16, "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve()),
                "output_dir": str(output / name), **case}
        path.write_text(json.dumps(evidence, indent=2) + "\n")
    for name, job in evidence["jobs"].items():
        if not args.analyze:
            request = output / f"{name}.json"
            request.write_text(json.dumps(job))
            run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd",
                 "--", "--job=" + str(request)], output / f"{name}.log", args.capture_timeout)
        folder = output / name
        report = read(folder / "report.json")
        assert report["ok"] and all(report["checks"].values()), name
        # No TAA/scaler/compositor in this fixture; Compatibility has no RD probe.
        result = compare(folder, job, args.ffmpeg, args.analyze, require_render_buffers=False)
        result["lightmap_contract_ok"] = lightmap_contract(folder, job)
        result["ok"] &= result["lightmap_contract_ok"]
        result["delivery_checks"] = report["checks"]
        result["capture_settings"] = report["capture_settings"]
        result["expected_failure"] = bool(job.get("missing_lightmap_control"))
        result["accepted"] = (not result["ok"] and result["maxima"]["face_mae"] > SOURCE_MAE
            and result["processing_ok"] and result["lightmap_contract_ok"] and result["decoded_frames"] == FRAMES
            and result["delayed_control_rejected"]) if result["expected_failure"] else result["ok"]
        evidence["results"][name] = result
        print(name, "PASS" if result["accepted"] else "FAIL", result["maxima"], flush=True)
        path.write_text(json.dumps(evidence, indent=2) + "\n")
    evidence["feature_presence"] = presence(output, evidence["jobs"])
    evidence["source_unchanged"] = snapshot(project) == evidence["hashes"]
    evidence["ok"] = evidence["source_unchanged"] and evidence["feature_presence"]["ok"] and all(
        r["accepted"] for r in evidence["results"].values())
    sheet = Image.new("RGB", (1024, len(CASES) * 160), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(CASES):
        for col, i in enumerate([0, 18, 36, 60]):
            file = output / name / f"frames/frame{i + evidence['jobs'][name]['warmup_frames']:08d}.png"
            sheet.paste(Image.open(file).resize((256, 128)), (col * 256, row * 160 + 28))
            draw.text((col * 256 + 4, row * 160 + 5), f"{name} / {i}", fill="white")
    sheet.save(output / "comparison.jpg")
    path.write_text(json.dumps(evidence, indent=2) + "\n")
    print("Lightmap review:", "PASS" if evidence["ok"] else "FAIL", evidence["feature_presence"]["minima"], flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--border", type=float, choices=[0, 12.5], default=0)
    parser.add_argument("--warmup", type=int, choices=range(11), default=8)
    parser.add_argument("--capture-timeout", type=int, choices=[600, 1200], default=600,
                        help="Per-export timeout in seconds; software CI allows 1200")
    parser.add_argument("--baked-from", type=Path, help="Reuse a generated/ directory from a previous review")
    parser.add_argument("--analyze", action="store_true")
    raise SystemExit(main(parser.parse_args()))
