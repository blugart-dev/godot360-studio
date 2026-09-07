"""Additional actual-media audio checks: limiting, source mutation and legacy encoding.

Run after audio_review.py; --source-review identifies its accepted fixture folder.
--legacy-source identifies a pre-0.6 completed capture with encoded.mp4 and CRF 16.
Uses its helpers and only new output directories; no machine-specific fixture path.
"""
import argparse
import json
import subprocess
import time
from pathlib import Path

import numpy as np
from audio_review import RATE, SAMPLES, compare, decode, export, fixture, run, sha, snapshot, tones, write_wav


def review(args):
    for key in ("project", "ffmpeg", "ffprobe", "godot", "source_review", "legacy_source", "output"):
        setattr(args, key, getattr(args, key).resolve())
    args.output.mkdir(parents=True)
    results = {}
    source = args.source_review / "source"
    source_hashes = snapshot(source)
    settings_path = args.project / ".godot360/settings.cfg"
    settings_hash = sha(settings_path) if settings_path.exists() else None
    # Strong coincident signals exceed unity before the mixer limiter.
    loud_source = args.output / "loud-source"
    fixture(loud_source, amplitude=0.85)
    soundtrack = args.output / "loud.wav"
    write_wav(soundtrack, tones([0.5, 2, 5], amplitude=0.85))
    folder = args.output / "limited-mix"
    completed = export(args, folder, loud_source, {"audio_mode": "mix", "soundtrack_path": str(soundtrack)})
    assert completed.returncode == 0, (folder / "driver.log").read_text()
    report = json.loads((folder / "report.json").read_text())
    assert report["ok"]
    decoded = decode(folder / "video-360.mp4", args.ffmpeg)[:SAMPLES]
    peak = float(np.max(np.abs(decoded)))
    assert 0.85 < peak < 0.99, peak
    active = np.flatnonzero(np.abs(decoded[:, 0]) > 0.01)
    assert active[0] >= round(0.5 * RATE) - 48 and active[-1] < round(5.1 * RATE) + 48
    results["limited-mix"] = {"ok": True, "decoded_peak": peak, "no_unexpected_cue_shift": True}
    print("Limiter", results["limited-mix"], flush=True)
    # Re-encode an actual pre-0.6 capture; old scene/audio output remains exact.
    old_source = args.legacy_source
    old_hashes = snapshot(old_source)
    legacy = args.output / "legacy"
    completed = export(args, legacy, old_source, {"crf": 16})
    assert completed.returncode == 0, (legacy / "driver.log").read_text()
    assert sha(legacy / "encoded.mp4") == sha(old_source / "encoded.mp4")
    assert snapshot(old_source) == old_hashes
    results["legacy"] = {"ok": True, "encoded_mp4_byte_identical": True, "source_unchanged": True}
    print("Legacy media unchanged", flush=True)
    # Trigger source mutation while FFmpeg reads an attached soundtrack. The job
    # may observe it during pre-encode hashing or afterward; neither can publish.
    changing = args.output / "changing.wav"
    write_wav(changing, tones([0.8, 2.5, 4.7]))
    mutation = args.output / "changed-source"
    mutation.mkdir()
    job = {"mode": "reencode", "source_dir": str(source), "output_dir": str(mutation),
           "ffmpeg": str(args.ffmpeg), "ffprobe": str(args.ffprobe), "audio_mode": "soundtrack", "soundtrack_path": str(changing)}
    path = mutation / "job.json"
    path.write_text(json.dumps(job), encoding="utf-8")
    with (args.output / "mutation-driver.log").open("wb") as log:
        process = subprocess.Popen([str(args.godot), "--headless", "--path", str(args.project), "--log-file", str(mutation / "pipeline.log"),
                                    "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + str(path)], stdout=log, stderr=log)
        changed = False
        deadline = time.monotonic() + 30
        while process.poll() is None and time.monotonic() < deadline:
            status_path = mutation / "status.json"
            try:
                status = json.loads(status_path.read_text())
            except (OSError, json.JSONDecodeError):
                status = {}
            if status.get("stage") == "Encoding H.264 + AAC" and not changed:
                with changing.open("ab") as file:
                    file.write(b"changed after preflight")
                changed = True
            time.sleep(0.005)
        try:
            code = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            raise
    assert changed, "Mutation fixture did not reach encoding"
    status = json.loads((mutation / "status.json").read_text())
    assert code != 0 and "changed during" in status["error"] and not (mutation / "video-360.mp4").exists()
    results["source-mutation"] = {"ok": True, "rejected_without_final_video": True}
    assert snapshot(source) == source_hashes
    assert (sha(settings_path) if settings_path.exists() else None) == settings_hash
    summary = {"ok": True, "cases": results, "source_files_unchanged": True, "settings_unchanged": True}
    (args.output / "audio-delivery-review.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--source-review", type=Path, required=True)
    parser.add_argument("--legacy-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    review(parser.parse_args())
