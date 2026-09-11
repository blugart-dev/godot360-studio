"""Run the real editor across two processes using a fresh addon-only project.

This drives panel signals from an EditorPlugin. It verifies native integration,
exports, playback and recovery, but does not replace a human UI walkthrough.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
from types import SimpleNamespace

from prepare_walkthrough import prepare

ROOT = Path(__file__).resolve().parents[1]


def main(args):
    output = args.output.resolve()
    prepare(SimpleNamespace(output=output, package=args.package, godot=None))
    project = output / "project"
    driver = project / "addons/editor_review"
    driver.mkdir()
    shutil.copy2(ROOT / "tests/fixtures/editor_workflow.gd", driver / "plugin.gd")
    (driver / "plugin.cfg").write_text('[plugin]\nname="Editor integration reviewer"\ndescription="Disposable test driver"\nauthor="Godot360"\nversion="1.0"\nscript="plugin.gd"\n', encoding="utf-8")
    with (project / "project.godot").open("a", encoding="utf-8") as config:
        config.write('\n[editor_plugins]\nenabled=PackedStringArray("res://addons/godot360/plugin.cfg", "res://addons/editor_review/plugin.cfg")\n')
    env = os.environ.copy()
    for name in ["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]:
        env[name] = str(output / "profile" / name)
    hashes = {p.relative_to(project).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in (project / "addons/godot360").rglob("*") if p.is_file()}
    result = {"ok": False, "kind": "native editor integration; UI navigation not assessed",
              "package_sha256": hashlib.sha256(args.package.read_bytes()).hexdigest(),
              "addon_hashes": hashes, "phases": {}}
    shutil.copy2(Path(__file__), output / "editor_review.py")
    shutil.copy2(ROOT / "tests/prepare_walkthrough.py", output / "prepare_walkthrough.py")
    try:
        for phase in ["first", "reopen"]:
            started = time.monotonic()
            with (output / (phase + ".log")).open("wb") as log:
                process = subprocess.Popen([str(args.godot.resolve()), "--editor", "--path", str(project),
                    "res://room.tscn", "--", "--review-phase=" + phase,
                    "--ffmpeg=" + str(args.ffmpeg.resolve()), "--ffprobe=" + str(args.ffprobe.resolve())],
                    env=env, stdout=log, stderr=log,
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
                try:
                    code = process.wait(timeout=660)
                except subprocess.TimeoutExpired:
                    for job in (project / "renders").glob("*"):
                        if not (job / "report.json").exists():
                            (job / "cancel.request").write_text("Editor integration timeout", encoding="utf-8")
                    try:
                        process.wait(timeout=20)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    raise
            report = project / ("editor-" + phase + ".json")
            data = json.loads(report.read_text()) if report.exists() else {"ok": False, "error": "Editor did not write a result"}
            errors = [s for s in (output / (phase + ".log")).read_text(errors="replace").splitlines()
                      if s.startswith(("ERROR:", "SCRIPT ERROR:")) and s != "ERROR: Failed to read the root certificate store."]
            result["phases"][phase] = {"exit_code": code, "seconds": time.monotonic() - started, "errors": errors, **data}
            print(phase, "PASS" if code == 0 and data["ok"] and not errors else "FAIL", flush=True)
            failures = [name for name, ok in data.get("checks", {}).items() if not ok]
            assert code == 0 and data["ok"] and not errors, {
                "phase": phase, "exit_code": code, "failed_checks": failures,
                "errors": errors, "report": str(report)}
        result["ok"] = True
    finally:
        result["addon_unchanged"] = all((project / p).is_file() and hashlib.sha256((project / p).read_bytes()).hexdigest() == h for p, h in hashes.items())
        result["ok"] &= result["addon_unchanged"]
        (output / "editor-review.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["package", "output", "godot", "ffmpeg", "ffprobe"]:
        parser.add_argument("--" + name, type=Path, required=True)
    raise SystemExit(main(parser.parse_args()))
