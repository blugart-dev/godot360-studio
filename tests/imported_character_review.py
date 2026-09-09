"""Import a licensed GLB and compare camera/skin with a raw-glTF CPU oracle.

Fresh disposable project; requires Godot, FFmpeg/FFprobe, NumPy and Pillow.
"""
import argparse
import json
import os
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from border_review import pixels, read, run
from gltf_reference import Character, ASSET_SHA256
from motion_review import decoded_frames
from skeletal_review import source_difference

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT, FRAMES = 2048, 1024, 60


def compare(output, a, b, args):
    rows = []
    for index, (x, y) in enumerate(zip(
            decoded_frames(args.ffmpeg, output / a / "video-360.mp4", WIDTH, HEIGHT),
            decoded_frames(args.ffmpeg, output / b / "video-360.mp4", WIDTH, HEIGHT), strict=True)):
        filename = f"frames/frame{index+args.warmup:08d}.png"
        source_a, source_b = pixels(output / a / filename), pixels(output / b / filename)
        # Isolate the orange character from the surrounding markers/background.
        mask = (source_b[:, :, 0] > 240) & (source_b[:, :, 1] > 65) & (source_b[:, :, 1] < 100) & (source_b[:, :, 2] < 25)
        rows.append({"frame": index, **source_difference(source_a, source_b),
                     "character_pixels": int(mask.sum()),
                     "decoded_mae": float(abs(x.astype(np.float32)-y.astype(np.float32)).mean())})
    return {"frames": rows, "max_source_mae": max(r["source_mae"] for r in rows),
            "max_foreground_mae": max(r["foreground_mae"] for r in rows),
            "max_decoded_mae": max(r["decoded_mae"] for r in rows),
            "min_character_pixels": min(r["character_pixels"] for r in rows),
            "ok": len(rows) == FRAMES and all(r["source_mae"] < .03 and r["foreground_mae"] < .25
                                              and r["foreground_pixels"] > 200 and r["decoded_mae"] < .1
                                              and (args.textured or r["character_pixels"] > 1000) for r in rows)}


def transforms(output, mode, reference):
    observations = read(output / mode / "character-samples.json")
    frames = {int(row["frame"]): row for row in observations["samples"]}
    rows = []
    for index, expected in enumerate(reference["frames"]):
        actual = frames[index]
        rows.append({"frame": index,
                     "camera_max": float(np.max(abs(np.array(actual["camera"])-expected["camera"]))),
                     "bone_max": max(float(np.max(abs(np.array(actual["bones"][name])-value)))
                                     for name, value in expected["bones"].items())})
    return {"frames": rows, "animation": observations["animation"], "bones": observations["bones"],
            "animation_tracks": observations["animation_tracks"],
            "max_camera_error": max(r["camera_max"] for r in rows),
            "max_bone_error": max(r["bone_max"] for r in rows),
            "ok": len(frames) == FRAMES and observations["bones"] == 19 and
                  all(r["camera_max"] < .00005 and r["bone_max"] < .00005 for r in rows)}


def checkpoint(output, evidence):
    (output / "imported-character-review.json").write_text(json.dumps(evidence, indent=2)+"\n", encoding="utf-8")


def main(args):
    output = args.output.resolve()
    output.mkdir(parents=True)
    for key in (["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]):
        profile = output / "profile" / key
        profile.mkdir(parents=True)
        os.environ[key] = str(profile)
    project = output / "project"
    for name in ["addons/godot360", "tests"]:
        shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns("__pycache__", "*.import"))
    (project / "project.godot").write_text(f'''config_version=5
[application]
config/name="Godot360 imported character review"
[rendering]
renderer/rendering_method="{args.method}"
rendering_device/driver.windows="{args.driver}"
rendering_device/driver.linuxbsd="{args.driver}"
gl_compatibility/driver.windows="{args.driver}"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    reference = Character(project / "tests/fixtures/cesium_man/CesiumMan.glb").write_reference(project / "reference", FRAMES, args.fps)
    # Keep the source reference exact: the usual lossy import optimizer, vertex
    # compression and generated LODs are independent of capture synchronization.
    import_settings = '''[remap]
importer="scene"
type="PackedScene"
[params]
meshes/generate_lods=false
meshes/force_disable_compression=true
animation/remove_immutable_tracks=false
_subresources={"nodes": {"PATH:AnimationPlayer": {"optimizer/enabled": false}}}
'''
    # glTF import bakes curves at this rate. Match the compared samples instead
    # of treating interpolation between a lower-rate bake as a capture error.
    import_settings += f"animation/fps={args.fps}\n"
    (project / "tests/fixtures/cesium_man/CesiumMan.glb.import").write_text(import_settings, encoding="utf-8")
    run([args.godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output / "import.log")
    evidence = {"method": args.method, "driver": args.driver, "warmup": args.warmup, "border": args.border,
                "fps": args.fps, "import_fps": args.fps, "textured": args.textured, "asset_sha256": ASSET_SHA256,
                "reference": {k: v for k, v in reference.items() if k not in ["frames", "boom"]},
                "jobs": {}, "transforms": {}, "comparisons": {}, "ok": False}
    modes = ["capture", "camera-oracle"] if args.textured else ["capture", "camera-oracle", "full-oracle"]
    if args.negative_control:
        assert not args.textured
        modes.extend(["late-skin", "late-camera"])
    checkpoint(output, evidence)
    for mode in modes:
        oracle = mode != "capture"
        job = {"scene_path": "res://tests/fixtures/imported_character.tscn",
               "camera_path": "Camera3D" if oracle else "HeadAttachment/Boom/Camera3D",
               "width": WIDTH, "height": HEIGHT, "face_size": 512, "fps": args.fps, "frames": FRAMES,
               "warmup_frames": args.warmup, "capture_border_percent": args.border,
               "oracle_camera": oracle, "oracle_skin": mode in ["full-oracle", "late-skin"],
               "skin_delay": 1 if mode == "late-skin" else 0, "textured": args.textured,
               "camera_delay": 1 if mode == "late-camera" else 0,
               "crf": 16, "frame_writer": "fast_png", "rendering_method": args.method,
               "rendering_driver": args.driver, "output_dir": str(output / mode),
               "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
        request = output / (mode+".json")
        request.write_text(json.dumps(job), encoding="utf-8")
        run([args.godot, "--headless", "--path", project, "--script", "res://addons/godot360/pipeline.gd", "--", "--job="+str(request)], output / (mode+".log"))
        report = read(output / mode / "report.json")
        assert report["ok"] and all(report["checks"].values()), mode
        evidence["jobs"][mode] = {"checks": report["checks"], "settings": report["capture_settings"],
                                  "timings": {k: v for k, v in report["capture_timings"].items() if k != "samples"}}
        evidence["transforms"][mode] = transforms(output, mode, reference)
        checkpoint(output, evidence)
        print(mode, "DELIVERY PASS", "TRANSFORMS", evidence["transforms"][mode]["ok"], flush=True)
    pairs = [("capture", "camera-oracle")]
    if not args.textured:
        pairs.append(("camera-oracle", "full-oracle"))
    if args.negative_control:
        pairs.extend([("late-skin", "full-oracle"), ("late-camera", "camera-oracle")])
    for a, b in pairs:
        evidence["comparisons"][a] = compare(output, a, b, args)
        checkpoint(output, evidence)
    evidence["ok"] = all(value["ok"] for key, value in evidence["transforms"].items() if key != "late-camera") and all(
        value["ok"] for key, value in evidence["comparisons"].items() if not key.startswith("late-"))
    if args.negative_control:
        evidence["negative_control_rejected"] = all(not evidence["comparisons"][name]["ok"] for name in ["late-skin", "late-camera"])
        evidence["ok"] &= evidence["negative_control_rejected"]
    sheet = Image.new("RGB", (960, len(modes)*270), "#141a22")
    draw = ImageDraw.Draw(sheet)
    for row, mode in enumerate(modes):
        for col, frame in enumerate([15, 30, 31]):
            picture = output / f"view-{mode}-{frame}.png"
            source = output / mode / f"frames/frame{frame+args.warmup:08d}.png"
            run([args.ffmpeg, "-v", "error", "-nostdin", "-i", source, "-vf",
                 "v360=equirect:flat:h_fov=85:v_fov=70:w=320:h=240", "-frames:v", 1, "-update", 1, picture], output / f"view-{mode}-{frame}.log")
            sheet.paste(Image.open(picture).convert("RGB"), (col*320, row*270+30))
            draw.text((col*320+8, row*270+8), f"{mode} - frame {frame}", fill="white")
    sheet.save(output / "comparison.jpg")
    checkpoint(output, evidence)
    print(json.dumps({"ok": evidence["ok"], "comparisons": {k: {n: v for n, v in r.items() if n != "frames"}
                                                            for k, r in evidence["comparisons"].items()}}, indent=2), flush=True)
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["godot", "ffmpeg", "ffprobe", "output"]:
        parser.add_argument("--"+name, type=Path, required=True)
    parser.add_argument("--method", choices=["forward_plus", "mobile", "gl_compatibility"], default="forward_plus")
    parser.add_argument("--driver", default="vulkan")
    parser.add_argument("--warmup", type=int, default=2)
    parser.add_argument("--border", type=float, default=0)
    parser.add_argument("--fps", type=int, choices=[30, 60], default=30)
    parser.add_argument("--textured", action="store_true")
    parser.add_argument("--negative-control", action="store_true")
    raise SystemExit(main(parser.parse_args()))
