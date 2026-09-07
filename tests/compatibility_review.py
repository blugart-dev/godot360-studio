"""Exercise each supplied Godot executable in a fresh addon-only project.

Requires a GPU/display for the panel's actual one-second capture, plus FFmpeg,
FFprobe, numpy and Pillow. Does not import or edit the source project. Each engine
gets its own import cache, settings, generated cues, logs and capture folders.
"""
import argparse
import json
import re
import shutil
import subprocess
import time
from pathlib import Path

from audio_review import run, sha, snapshot, tones, write_wav

CONTRACTS = ("export_checks", "planning_checks", "metadata_checks", "timeline_checks", "audio_checks", "frame_writer_checks", "storage_checks", "diagnostics_checks")


def command(args, engine, project, name, options, timeout=120):
    log = project / ".umbral360" / (name + ".log")
    started = time.monotonic()
    try:
        result = run([engine, "--path", project, "--log-file", log, *options], timeout=timeout, check=False)
        output = (result.stdout + result.stderr).decode("utf-8", errors="replace")
        code = result.returncode
    except subprocess.TimeoutExpired as error:
        output = ((error.stdout or b"") + (error.stderr or b"")).decode("utf-8", errors="replace")
        code = -1
        output += "\nTEST TIMEOUT: coordinator process terminated. Inspect job status/logs before retrying.\n"
    (project / ".umbral360" / (name + "-driver.log")).write_text(output, encoding="utf-8")
    success = code == 0 and "SCRIPT ERROR:" not in output
    match = re.search(r"CHECKS: (\d+) checks, (\d+) failures", output)
    if name in CONTRACTS or name in ("audio_studio_checks", "capture_lifecycle_checks", "recovery_studio_checks", "storage_failure_checks", "release_workflow_checks"):
        success = success and match is not None and int(match.group(2)) == 0
    result = {"ok": success, "exit_code": code, "seconds": round(time.monotonic() - started, 3),
              "checks": int(match.group(1)) if match else None, "log": str(log)}
    print(project.name, name, json.dumps(result), flush=True)
    return result


def review(args):
    for key in ("project", "ffmpeg", "ffprobe", "output"):
        setattr(args, key, getattr(args, key).resolve())
    args.output.mkdir(parents=True)
    addon_before = snapshot(args.project / "addons/umbral360")
    settings = args.project / ".umbral360/settings.cfg"
    settings_before = sha(settings) if settings.exists() else None
    project_config = args.project / "project.godot"
    project_before = sha(project_config) if project_config.exists() else None
    results = []
    for index, executable in enumerate(args.godot):
        engine = executable.resolve()
        version = run([engine, "--version"]).stdout.decode().strip()
        project = args.output / (str(index + 1) + "-godot-" + re.sub(r"[^a-zA-Z0-9.-]", "_", version))
        project.mkdir()
        (project / ".umbral360").mkdir()
        (project / "project.godot").write_text('''config_version=5
[application]
config/name="Godot360 isolated compatibility check"
[display]
window/size/viewport_width=1400
window/size/viewport_height=600
[editor_plugins]
enabled=PackedStringArray("res://addons/umbral360/plugin.cfg")
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
''', encoding="utf-8")
        shutil.copytree(args.project / "addons/umbral360", project / "addons/umbral360")
        (project / "tests").mkdir()
        shutil.copytree(args.project / "tests/fixtures", project / "tests/fixtures")
        for name in (*CONTRACTS, "audio_studio_checks", "capture_lifecycle_checks", "recovery_studio_checks", "storage_failure_checks", "release_workflow_checks"):
            shutil.copy2(args.project / "tests" / (name + ".gd"), project / "tests" / (name + ".gd"))
        cue = project / ".umbral360/cue.wav"
        write_wav(cue, tones([0.25, 0.65], duration=1))
        checks = {"editor-import": command(args, engine, project, "editor-import", ["--headless", "--editor", "--quit"])}
        if checks["editor-import"]["ok"]:
            for name in CONTRACTS:
                checks[name] = command(args, engine, project, name, ["--headless", "--script", "res://tests/" + name + ".gd",
                                      "--", "--ffmpeg=" + str(args.ffmpeg)])
                if not checks[name]["ok"]:
                    break
            if all(check["ok"] for check in checks.values()):
                checks["audio_studio_checks"] = command(args, engine, project, "audio_studio_checks",
                    ["--rendering-method", "gl_compatibility", "--script", "res://tests/audio_studio_checks.gd", "--",
                     "--ffmpeg=" + str(args.ffmpeg), "--ffprobe=" + str(args.ffprobe), "--soundtrack=" + str(cue)], timeout=240)
            if args.capture_failures and all(check["ok"] for check in checks.values()):
                checks["capture_lifecycle_checks"] = command(args, engine, project, "capture_lifecycle_checks",
                    ["--headless", "--script", "res://tests/capture_lifecycle_checks.gd", "--", "--writer-check=true",
                     "--output=" + str(project / ".umbral360/lifecycle"),
                     "--ffmpeg=" + str(args.ffmpeg), "--ffprobe=" + str(args.ffprobe)], timeout=240)
            if args.job_recovery and all(check["ok"] for check in checks.values()):
                checks["recovery_studio_checks"] = command(args, engine, project, "recovery_studio_checks",
                    ["--rendering-method", "gl_compatibility", "--script", "res://tests/recovery_studio_checks.gd", "--",
                     "--output=" + str(project / ".umbral360/recovery"),
                     "--ffmpeg=" + str(args.ffmpeg), "--ffprobe=" + str(args.ffprobe)], timeout=240)
            if args.storage_failures and all(check["ok"] for check in checks.values()):
                checks["storage_failure_checks"] = command(args, engine, project, "storage_failure_checks",
                    ["--headless", "--script", "res://tests/storage_failure_checks.gd", "--",
                     "--output=" + str(project / ".umbral360/storage-failures"),
                     "--ffmpeg=" + str(args.ffmpeg), "--ffprobe=" + str(args.ffprobe)], timeout=240)
            if args.release_workflow and all(check["ok"] for check in checks.values()):
                checks["release_workflow_checks"] = command(args, engine, project, "release_workflow_checks",
                    ["--rendering-method", "gl_compatibility", "--script", "res://tests/release_workflow_checks.gd", "--",
                     "--ffmpeg=" + str(args.ffmpeg), "--ffprobe=" + str(args.ffprobe)], timeout=360)
        outputs = []
        for path in sorted((project / "renders").rglob("report.json")):
            report = json.loads(path.read_text())
            assert report["ok"] and len(report["checks"]) == 13 and all(report["checks"].values()), path
            outputs.append({"report": str(path), "checks": report["checks"], "capture_reused": report["capture_reused"]})
        complete = len(checks) == len(CONTRACTS) + 2 + int(args.capture_failures) + int(args.job_recovery) + int(args.storage_failures) + int(args.release_workflow) and all(check["ok"] for check in checks.values()) and len(outputs) == 2
        results.append({"godot_version": version, "executable": str(engine), "project": str(project), "ok": complete,
                        "stages": checks, "outputs": outputs})
    assert snapshot(args.project / "addons/umbral360") == addon_before
    assert (sha(project_config) if project_config.exists() else None) == project_before
    assert (sha(settings) if settings.exists() else None) == settings_before
    report = {"ok": all(result["ok"] for result in results), "source_addon_unchanged": True,
              "source_project_and_settings_unchanged": True, "engines": results}
    (args.output / "compatibility-review.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("COMPATIBILITY REVIEW:", "PASS" if report["ok"] else "FAIL", flush=True)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, action="append", required=True, help="Repeat for each engine executable")
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--capture-failures", action="store_true", help="Also exercise six controlled capture failures in each isolated project")
    parser.add_argument("--job-recovery", action="store_true", help="Also reopen actual jobs after editor/coordinator loss and check stale identity rejection")
    parser.add_argument("--storage-failures", action="store_true", help="Inject low-space and real output-write failures in disposable jobs")
    parser.add_argument("--release-workflow", action="store_true", help="Also exercise documented Draft calibration, six preview directions, diagnostics and full Motion Lab")
    parser.add_argument("--output", type=Path, default=Path(".umbral360") / ("compatibility-" + time.strftime("%Y%m%d-%H%M%S")))
    raise SystemExit(review(parser.parse_args()))
