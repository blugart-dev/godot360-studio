"""Create small documentation previews from existing, locally rendered films.

Requires FFmpeg with libx264 and v360. No scene is rendered or uploaded.
Run from the repository root; see docs/media/README.md for sources and commands.
"""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def main(args):
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    film = args.threshold.resolve()
    umbral = args.umbral.resolve()
    for source in (film, umbral):
        if not source.is_file():
            raise FileNotFoundError(source)
    ffmpeg = str(args.ffmpeg.resolve())

    def run(*options):
        subprocess.run(
            [ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin", "-y", *map(str, options)],
            check=True, timeout=300,
        )

    view = "v360=input=equirect:output=flat:h_fov=100:v_fov=68:w=960:h=540"
    # Use the untagged encoded MP4: these ordinary perspective views must not
    # inherit spherical side data from the tagged delivery master.
    print("Creating the 60-second perspective video with its original score", flush=True)
    run("-i", film, "-vf", view, "-c:v", "libx264", "-preset", "fast", "-crf", 24,
        "-threads", 4, "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "96k",
        "-map_metadata", -1, "-movflags", "+faststart", output / "threshold-tour.mp4")
    scenes = [(8, "tidal-archive"), (20, "glass-desert"), (35, "sky-garden"), (49, "star-engine")]
    for seconds, name in scenes:
        run("-ss", seconds, "-i", film, "-vf", view, "-frames:v", 1,
            "-q:v", 3, "-update", 1, output / f"{name}.jpg")

    print("Creating an eight-second silent GIF and a four-world contact sheet", flush=True)
    # Take two seconds per world; reduce size/rate before palette quantization.
    clips = []
    for seconds, _ in scenes:
        clips += ["-ss", seconds, "-t", 2, "-i", output / "threshold-tour.mp4"]
    graph = ";".join(f"[{i}:v]fps=10,scale=720:406:flags=lanczos,setsar=1,setpts=PTS-STARTPTS[v{i}]" for i in range(4))
    graph += ";[v0][v1][v2][v3]concat=n=4:v=1:a=0,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3"
    run(*clips, "-filter_complex_threads", 2, "-filter_complex", graph,
        "-an", "-loop", 0, output / "threshold-tour.gif")
    inputs = []
    for _, name in scenes:
        inputs += ["-i", output / f"{name}.jpg"]
    graph = ";".join(f"[{i}:v]scale=640:360[v{i}]" for i in range(4))
    graph += ";[v0][v1][v2][v3]xstack=inputs=4:layout=0_0|640_0|0_360|640_360"
    run(*inputs, "-filter_complex", graph, "-frames:v", 1, "-q:v", 3,
        "-update", 1, output / "threshold-worlds.jpg")
    run("-ss", 35, "-i", film, "-vf", "scale=1280:640:flags=lanczos",
        "-frames:v", 1, "-q:v", 3, "-update", 1, output / "sky-garden-panorama.jpg")
    run("-ss", 3, "-i", umbral, "-vf", view, "-frames:v", 1,
        "-q:v", 3, "-update", 1, output / "umbral.jpg")

    def source_record(path):
        try:
            name = path.relative_to(root).as_posix()
        except ValueError:
            name = path.name
        with path.open("rb") as source:
            return {"file": name, "sha256": hashlib.file_digest(source, "sha256").hexdigest()}

    record = {"sources": [source_record(film), source_record(umbral)],
              "perspective": {"horizontal_fov": 100, "vertical_fov": 68, "yaw": 0, "pitch": 0},
              "excerpt_starts_seconds": [seconds for seconds, _ in scenes],
              "excerpt_duration_seconds": 2,
              "video": "60-second flat perspective view; original stereo score; no spherical metadata",
              "gif": "8-second silent montage; 720 x 406; 10 FPS; not interactive",
              "still_seconds": {**{name: seconds for seconds, name in scenes}, "umbral": 3},
              "outputs": {path.name: {"bytes": path.stat().st_size,
                                      "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                          for path in sorted(output.iterdir()) if path.suffix in {".jpg", ".gif", ".mp4"}}}
    (output / "provenance.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({name: info["bytes"] for name, info in record["outputs"].items()}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ffmpeg", required=True, type=Path)
    parser.add_argument("--threshold", type=Path, default=Path("renders/threshold-8k/encoded.mp4"))
    parser.add_argument("--umbral", type=Path, default=Path("renders/umbral-quality-8k/encoded.mp4"))
    parser.add_argument("--output", type=Path, default=Path("docs/media"))
    main(parser.parse_args())
