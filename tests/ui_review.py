"""Render and exercise the actual panel in a fresh isolated Godot project.

Requires native Godot and FFmpeg/FFprobe with Theora/Vorbis. Reports automated
integration, never human UI acceptance. Original settings and captures are untouched.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def main(args):
    source = args.project.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    project = output / "project"
    project.mkdir()
    shutil.copytree(source / "addons/godot360", project / "addons/godot360")
    (project / "tests").mkdir()
    shutil.copy2(source / "tests/ui_workflow_checks.gd", project / "tests/ui_workflow_checks.gd")
    (project / "project.godot").write_text('''config_version=5
[application]
config/name="Godot360 UI review"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="vulkan"
''', encoding="utf-8")
    paths = [p for p in (project / "addons/godot360").rglob("*") if p.is_file()]
    hashes = {p.relative_to(project).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    env = os.environ.copy()
    for key in ["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]:
        location = output / "profile" / key
        location.mkdir(parents=True)
        env[key] = str(location)
    log = output / "ui.log"
    with log.open("wb") as stream:
        result = subprocess.run([str(args.godot.resolve()), "--path", str(project), "--audio-driver", "Dummy",
            "--script", "res://tests/ui_workflow_checks.gd", "--", "--ffmpeg=" + str(args.ffmpeg.resolve()),
            "--ffprobe=" + str(args.ffprobe.resolve())], env=env, stdout=stream, stderr=stream, timeout=600,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    report_path = project / ".godot360/ui-evidence/result.json"
    report = json.loads(report_path.read_text()) if report_path.exists() else {"failures": 1, "error": "No test result"}
    errors = [line for line in log.read_text(encoding="utf-8", errors="replace").splitlines()
              if line.startswith(("ERROR:", "SCRIPT ERROR:")) and line != "ERROR: Failed to read the root certificate store."]
    report.update(exit_code=result.returncode, errors=errors, source_hashes=hashes,
                  source_unchanged=all(hashlib.sha256((project / name).read_bytes()).hexdigest() == digest for name, digest in hashes.items()))
    report["ok"] = result.returncode == 0 and report["failures"] == 0 and not errors and report["source_unchanged"]
    (output / "ui-review.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ["ok", "failures", "errors", "source_unchanged"]}))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    for name in ["output", "godot", "ffmpeg", "ffprobe"]:
        parser.add_argument("--" + name, type=Path, required=True)
    raise SystemExit(main(parser.parse_args()))
