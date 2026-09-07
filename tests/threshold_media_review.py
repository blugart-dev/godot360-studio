"""Decode every delivered film frame, check the score and prepare local playback.

Visual checks cover counts, freezes, cut coverage, unexpected black frames and
sampled source correspondence. They do not claim semantic/artistic correctness.
"""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from audio_review import compare, decode
from metadata_review import hash_region, layout, movie, packet_hashes, projection, tracks


def main(args):
    folder = args.folder.resolve()
    project = Path(__file__).resolve().parents[1]
    ffmpeg, ffprobe = str(args.ffmpeg.resolve()), str(args.ffprobe.resolve())
    final = folder / "video-360.mp4"
    original = folder / "encoded.mp4"
    report = json.loads((folder / "report.json").read_text())
    assert report["ok"] and all(report["checks"].values())
    evidence = project / ".godot360" / (folder.name + "-media-review")
    evidence.mkdir(exist_ok=args.inspect_only)
    raw = evidence / "decoded-srgb.rgb"
    filters = ("[0:v]split=3[p][f][q];"
               "[p]scale=4096:2048:flags=lanczos[pano];"
               "[f]v360=input=equirect:output=flat:h_fov=100:v_fov=68:w=1920:h=1080[flat];"
               "[q]scale=320:160:flags=area,colorspace=all=bt709:trc=srgb:range=pc:format=yuv444p,format=rgb24[qa]")
    # Source payload is the same as the tagged master; avoid carrying spherical
    # display metadata onto the ordinary perspective preview.
    command = [ffmpeg, "-v", "warning", "-nostdin", "-i", str(original), "-filter_complex_threads", "4", "-filter_complex", filters,
               "-map", "[pano]", "-map", "0:a:0", "-c:v", "libx264", "-threads", "4", "-preset", "fast", "-crf", "18",
               "-pix_fmt", "yuv420p", "-c:a", "copy", "-map_metadata", "-1", "-movflags", "+faststart", str(folder / "threshold-browser.mp4"),
               "-map", "[flat]", "-map", "0:a:0", "-c:v", "libx264", "-threads", "4", "-preset", "fast", "-crf", "18",
               "-pix_fmt", "yuv420p", "-c:a", "copy", "-map_metadata", "-1", "-movflags", "+faststart", str(folder / "threshold-preview.mp4"),
               "-map", "[qa]", "-c:v", "rawvideo", "-threads", "1", "-f", "rawvideo", str(raw)]
    print("Decoding all 1,800 frames and creating both playback versions", flush=True)
    if not args.inspect_only:
        with (evidence / "preview-encode.log").open("wb") as log:
            subprocess.run(command, stdout=log, stderr=log, check=True, timeout=1200)
    assert raw.stat().st_size == 1800 * 320 * 160 * 3, "Wrong decoded frame count"
    frames = np.memmap(raw, dtype=np.uint8, mode="r", shape=(1800, 160, 320, 3))
    means, duplicates, black = [], [], []
    for i, frame in enumerate(frames):
        means.append(float(np.mean(frame)))
        if i and np.array_equal(frame, frames[i - 1]):
            duplicates.append(i)
        if i < 1764 and np.mean(frame) < 2:
            black.append(i)
    assert not black, ("Unexpected blank frames", black)
    unexpected_duplicates = [i for i in duplicates if i < 1764 and all(abs(i - cut * 30) > 2 for cut in (14, 29, 44))]
    assert not unexpected_duplicates, ("Potential frozen frames", unexpected_duplicates)
    cut_checks = []
    for cut in (14, 29, 44):
        pixels = frames[cut * 30]
        result = {"seconds": cut, "mean": float(pixels.mean()), "spatial_stddev": float(pixels.reshape(-1, 3).std(axis=0).max())}
        assert result["mean"] > 245 and result["spatial_stddev"] < 2, ("Map cut not fully concealed", result)
        cut_checks.append(result)
    assert means[-1] < 15, "Ending failed to fade"
    comparisons = []
    sheet = Image.new("RGB", (1280, 12 * 108), (5, 11, 23))
    draw = ImageDraw.Draw(sheet)
    for second in range(60):
        with Image.open(folder / "frames" / f"frame{second * 30 + 2:08d}.png") as source:
            assert source.size == (7680, 3840)
            thumb = np.array(source.convert("RGB").resize((320, 160), Image.Resampling.BOX))
        error = np.abs(thumb.astype(float) - frames[second * 30].astype(float))
        comparisons.append({"seconds": second, "mean_error_8bit": float(error.mean()), "p99_error_8bit": float(np.percentile(error, 99))})
        assert error.mean() < 5, ("Source correspondence failed", comparisons[-1])
        if second % 1 == 0:
            x, y = (second % 5) * 256, (second // 5) * 108
            sheet.paste(Image.fromarray(frames[second * 30]).resize((250, 86)), (x, y + 18))
            draw.text((x + 4, y + 2), f"{second:02d}s", fill=(237, 211, 168))
    sheet.save(evidence / "every-second.jpg", quality=92)
    print("Frame count, transitions, freezes and 60 source comparisons passed", flush=True)
    expected_audio = decode(project / "assets/audio/threshold-score.wav", ffmpeg)
    audio = compare(decode(final, ffmpeg), expected_audio)
    old_layout, new_layout = layout(original), layout(final)
    moov, _ = movie(final, new_layout)
    video_track = next(track for track in tracks(moov) if track["handler"] == b"vide")
    software = projection(video_track)
    assert next(b["offset"] for b in new_layout if b["kind"] == "moov") < next(b["offset"] for b in new_layout if b["kind"] == "mdat")
    old_media = [b for b in old_layout if b["kind"] == "mdat"]
    new_media = [b for b in new_layout if b["kind"] == "mdat"]
    assert len(old_media) == len(new_media)
    for old, new in zip(old_media, new_media):
        assert old["size"] == new["size"] and hash_region(original, old["offset"], old["size"]) == hash_region(final, new["offset"], new["size"])
    packets = packet_hashes(final, ffprobe)
    assert packets == packet_hashes(original, ffprobe), "Tagged master changed media or timestamps"
    shutil.copyfile(project / "tools/threshold_player.html", folder / "index.html")
    result = {"ok": True, "decoded_frames": 1800, "seconds": 60, "source_frames_compared": comparisons,
              "cut_coverage": cut_checks, "unexpected_blank_frames": black, "duplicate_thumbnail_frames": duplicates,
              "ending_mean_8bit": means[-1], "audio": audio, "metadata_source": software,
              "metadata_v1_v2": True, "fast_start": True, "media_bytes_preserved": True,
              "packet_payloads_and_timestamps_compared": len(packets), "master_sha256": hash_region(final),
              "master_bytes": final.stat().st_size, "browser_bytes": (folder / "threshold-browser.mp4").stat().st_size,
              "preview_bytes": (folder / "threshold-preview.mp4").stat().st_size,
              "limits": "No headset comfort or external platform playback assessment; visual correspondence is sampled at one-second intervals."}
    (evidence / "review.json").write_text(json.dumps(result, indent=2))
    print(json.dumps({k: v for k, v in result.items() if k not in ("source_frames_compared", "audio")}, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--ffmpeg", required=True, type=Path)
    parser.add_argument("--ffprobe", required=True, type=Path)
    parser.add_argument("--inspect-only", action="store_true", help="Reinspect previously decoded review artifacts")
    main(parser.parse_args())
