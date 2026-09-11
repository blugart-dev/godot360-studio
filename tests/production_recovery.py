"""Interrupt a real production re-encode, then recover without changing its sources.

Uses a completed production_review.py capture and the existing injected-capacity
pipeline. No physical disk filling or additional GPU rendering is performed.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
from pathlib import Path

from audio_review import compare, decode
from endurance_review import cue_times, read_json
from production_review import ROOT, FLAGS, audio_clock, decode_roi, environment, inspect, roi, save


def snapshot(folder):
    result = {}
    for path in sorted(folder.rglob("*")):
        if path.is_file():
            with path.open("rb") as stream:
                result[path.relative_to(folder).as_posix()] = hashlib.file_digest(stream, "sha256").hexdigest()
    return result


def review(args):
    output, source = args.output.resolve(), args.source.resolve()
    output.mkdir(parents=True, exist_ok=False)
    original = read_json(source.parent / "production-review.json")
    assert original.get("ok") and not original.get("expected_failure"), "Use an accepted production capture"
    project = output / "project"
    project.mkdir()
    shutil.copytree(ROOT / "addons/godot360", project / "addons/godot360")
    fixtures = project / "tests/fixtures"
    fixtures.mkdir(parents=True)
    shutil.copy2(ROOT / "tests/fixtures/storage_pipeline.gd", fixtures)
    (project / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Production recovery review"\n')
    runtime = {k: h for k, h in snapshot(project).items() if k.startswith("addons/") and k.endswith((".gd", ".gdshader"))}
    assert all(original["hashes"][k] == h for k, h in runtime.items()), "Capture and recovery runtime differ"
    before = snapshot(source)
    result = {"ok": False, "source": str(source), "source_hashes": before, "runtime_hashes": runtime,
              "capacity_values_injected": True, "physical_disk_filled": False}

    def run(name, injected):
        folder = output / name
        folder.mkdir()
        request = {"mode": "reencode", "source_dir": str(source), "output_dir": str(folder),
                   "ffmpeg": str(args.ffmpeg.resolve()), "ffprobe": str(args.ffprobe.resolve())}
        save(output / (name + "-request.json"), request)
        script = "res://tests/fixtures/storage_pipeline.gd" if injected else "res://addons/godot360/pipeline.gd"
        command = [str(args.godot.resolve()), "--headless", "--path", str(project), "--script", script,
                   "--", "--job=" + str(output / (name + "-request.json"))]
        if injected:
            command.append("--case=encode-space")
        started = time.monotonic()
        with (output / (name + ".log")).open("wb") as log:
            process = subprocess.Popen(command, stdout=log, stderr=log, env=environment(output), creationflags=FLAGS)
            try:
                code = process.wait(timeout=args.timeout)
            finally:
                if process.poll() is None:
                    (folder / "cancel.request").write_text("Production recovery test interrupted")
                    try:
                        process.wait(timeout=30)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
        return folder, code, time.monotonic() - started

    try:
        failed, code, elapsed = run("interrupted", True)
        state, recovery = read_json(failed / "status.json"), read_json(failed / "recovery.json")
        assert code != 0 and state.get("stage") == "Failed" and "disk space" in state.get("error", "").lower(), state
        assert (failed / "encode.log").is_file() and not (failed / "video-360.mp4").exists()
        assert recovery.get("can_reencode") and Path(recovery["source_dir"]).resolve() == source, recovery
        result.update(failure_state=state, recovery=recovery, interrupted_wall_seconds=elapsed)
        save(output / "production-recovery.json", result)
        print("Injected encoding failure retained a reusable production source", flush=True)
        recovered, code, elapsed = run("recovered", False)
        report = read_json(recovered / "report.json")
        assert code == 0 and report.get("ok") and len(report["checks"]) == 13 and all(report["checks"].values()), report
        assert not (recovered / "capture.log").exists() and not (recovered / "frames").exists(), "Recovery unexpectedly recaptured"
        job = original["job"]
        box, columns, row, flash_row = roi(job["width"], job["height"])
        result["decoded_images"] = inspect(decode_roi(args.ffmpeg, recovered / "video-360.mp4", box, output / "decode.log"), job, box, columns, row, flash_row)
        audio = decode(recovered / "video-360.mp4", args.ffmpeg)
        expected = decode(source / "frames/frame.wav", args.ffmpeg)[round(job["warmup_frames"] * 48000 / job["fps"]):][:round(job["frames"] * 48000 / job["fps"])]
        duration = job["frames"] / job["fps"]
        result["audio_preservation"] = compare(audio, expected)
        result["audio_clock"] = audio_clock(audio, duration, job["fps"], cue_times(duration))
        result.update(report=report, recovered_wall_seconds=elapsed)
        result["ok"] = result["decoded_images"]["ok"] and result["audio_clock"]["ok"]
    except BaseException as error:
        result["error"] = str(error)
        raise
    finally:
        result["source_unchanged"] = snapshot(source) == before
        result["ok"] &= result["source_unchanged"]
        save(output / "production-recovery.json", result)
        print(json.dumps({k: result.get(k) for k in ["ok", "error", "source_unchanged", "recovered_wall_seconds"]}), flush=True)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["source", "output", "godot", "ffmpeg", "ffprobe"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=900)
    raise SystemExit(review(parser.parse_args()))
