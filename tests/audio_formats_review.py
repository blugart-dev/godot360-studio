"""Check compressed soundtrack formats and a 90-second mix against decoded sources.

Uses the full addon pipeline and fresh synthetic captures. Audio expectations use
independent NumPy placement after decoding each input (including its codec delay).
Requires numpy/Pillow; see audio_review.py for the shared fixture helpers.
"""
import argparse
import json
import time
from pathlib import Path

from audio_review import compare, decode, export, fixture, place, run, sha, snapshot, tones, write_wav


def checked_export(args, folder, source, controls, expected):
    completed = export(args, folder, source, controls, timeout=240)
    assert completed.returncode == 0, (folder, (folder / "driver.log").read_text())
    report = json.loads((folder / "report.json").read_text())
    assert report["ok"] and len(report["checks"]) == 13 and all(report["checks"].values()), report
    log = (folder / "encode.log").read_text()
    assert "non-monoton" not in log.lower(), log
    measurement = compare(decode(folder / "video-360.mp4", args.ffmpeg), expected)
    result = {"checks": report["checks"], "monotonic_encoder_timestamps": True, **measurement}
    print(folder.name, json.dumps(measurement), flush=True)
    return result


def review(args):
    for key in ("project", "godot", "ffmpeg", "ffprobe", "output"):
        setattr(args, key, getattr(args, key).resolve())
    root = args.output
    root.mkdir(parents=True)
    settings = args.project / ".godot360/settings.cfg"
    settings_before = sha(settings) if settings.exists() else None
    fixture(root / "source")
    sources_before = snapshot(root / "source")
    results, inputs = {}, {}
    # Cover every file-picker extension, mono/stereo, lossy/container delay and
    # up/downsampling. No claim is made about all possible codec/profile variants.
    formats = [
        ("pcm-22050", ".wav", "pcm_s16le", 22050, 1),
        ("mp3-32000", ".mp3", "libmp3lame", 32000, 2),
        ("mp3-44100", ".mp3", "libmp3lame", 44100, 1),
        ("vorbis-44100", ".ogg", "libvorbis", 44100, 2),
        ("opus-48000", ".ogg", "libopus", 48000, 2),
        ("flac-96000", ".flac", "flac", 96000, 2),
        ("aac-m4a-44100", ".m4a", "aac", 44100, 2),
        ("aac-adts-48000", ".aac", "aac", 48000, 1),
    ]
    input_dir = root / "inputs"
    input_dir.mkdir()
    for name, extension, codec, rate, channels in formats:
        wav = input_dir / (name + "-source.wav")
        path = input_dir / (name + extension)
        write_wav(wav, tones([0.8, 2.5, 4.7], rate=rate)[:, :channels], rate=rate)
        run([args.ffmpeg, "-v", "error", "-n", "-i", wav, "-c:a", codec, path])
        source_hash = sha(path)
        reference = decode(path, args.ffmpeg)
        probe = json.loads(run([args.ffprobe, "-v", "error", "-show_streams", "-show_format", "-of", "json", path]).stdout)
        controls = {"audio_mode": "soundtrack", "soundtrack_path": str(path), "soundtrack_trim_seconds": 0.213,
                    "soundtrack_offset_seconds": 0.137, "soundtrack_gain_db": -3}
        results[name] = checked_export(args, root / name, root / "source", controls,
                                       place(reference, trim=0.213, offset=0.137, gain=-3))
        inputs[name] = {"sha256": source_hash, "probe": probe, "decoded_samples_48k": len(reference)}
        assert sha(path) == source_hash
    duration = 90
    scene, _ = fixture(root / "long-source", fps=25, warmup=2, duration=duration,
                       cue_times=(0.5, 10, 30, 45, 60, 75, 88.5))
    long_before = snapshot(root / "long-source")
    wav, music = input_dir / "long.wav", input_dir / "long.m4a"
    write_wav(wav, tones([1, 10.5, 29.5, 45.5, 59.5, 75.5, 88], rate=44100, duration=duration), rate=44100)
    run([args.ffmpeg, "-v", "error", "-n", "-i", wav, "-c:a", "aac", "-b:a", "192k", music])
    music_hash = sha(music)
    controls = {"audio_mode": "mix", "soundtrack_path": str(music), "soundtrack_trim_seconds": 0.231,
                "soundtrack_offset_seconds": -0.173, "soundtrack_gain_db": -6,
                "scene_audio_offset_seconds": 0.127, "scene_audio_gain_db": -6}
    expected = place(scene, offset=0.127, gain=-6, duration=duration)
    expected += place(decode(music, args.ffmpeg), trim=0.231, offset=-0.173, gain=-6, duration=duration)
    results["mix-90-seconds"] = checked_export(args, root / "mix-90-seconds", root / "long-source", controls, expected)
    assert snapshot(root / "source") == sources_before
    assert snapshot(root / "long-source") == long_before and sha(music) == music_hash
    assert (sha(settings) if settings.exists() else None) == settings_before
    summary = {"ok": True, "source_files_unchanged": True, "settings_unchanged": True,
               "long_mix_seconds": duration, "long_mix_frames": duration * 25,
               "reference": "Decoded input, then independent sample placement; codec delay is not auto-corrected.",
               "inputs": inputs, "cases": results}
    (root / "audio-formats-review.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print("AUDIO FORMAT REVIEW: 8 formats and 90-second mix passed", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("renders") / ("audio-formats-" + time.strftime("%Y%m%d-%H%M%S")))
    review(parser.parse_args())
