"""Verify, extract and exercise the exact release ZIP in fresh addon-only projects.

Requires the same Godot/GPU/FFmpeg/numpy/Pillow setup as compatibility_review.py.
The package is never modified. Use a fresh --output directory for each review.
"""
import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def extract(package, destination):
    with ZipFile(package) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)), "Duplicate ZIP member"
        assert sum(info.file_size for info in archive.infolist()) < 32 * 1024 * 1024, "Unexpected package size"
        for info in archive.infolist():
            path = PurePosixPath(info.filename)
            assert not path.is_absolute() and ".." not in path.parts and "\\" not in info.filename and ":" not in info.filename, "Unsafe ZIP path"
            assert info.external_attr >> 16 & 0o170000 in (0, 0o100000), "Non-file ZIP member"
        assert archive.testzip() is None, "ZIP CRC failed"
        manifest = json.loads(archive.read("manifest.json"))
        assert set(names) == set(manifest["files"]) | {"manifest.json"}, "Manifest inventory differs"
        for name, record in manifest["files"].items():
            data = archive.read(name)
            assert len(data) == record["bytes"] and digest(data) == record["sha256"], name
        destination.mkdir()
        for name in names:
            target = destination.joinpath(*PurePosixPath(name).parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("xb") as file:
                file.write(archive.read(name))
    return manifest


def main(args):
    package = args.package.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True)
    before = digest(package.read_bytes())
    extracted = output / "unpacked"
    manifest = extract(package, extracted)
    # Verify the unpacked builder's complete inventory against its own exact ZIP.
    subprocess.run([sys.executable, str(extracted / "tools/package_addon.py"), "--root", str(extracted),
                    "--verify", str(package)], check=True)
    repeat = output / "repeat.zip"
    subprocess.run([sys.executable, str(extracted / "tools/package_addon.py"), "--root", str(extracted),
                    "--output", str(repeat)], check=True)
    assert repeat.read_bytes() == package.read_bytes(), "Rebuilding extracted package changed ZIP bytes"
    command = [sys.executable, str(extracted / "tests/compatibility_review.py"), "--project", str(extracted),
               "--capture-failures", "--job-recovery", "--storage-failures", "--release-workflow",
               "--ffmpeg", str(args.ffmpeg.resolve()), "--ffprobe", str(args.ffprobe.resolve()),
               "--output", str(output / "engines")]
    for engine in args.godot:
        command += ["--godot", str(engine.resolve())]
    completed = subprocess.run(command, check=False)
    matrix_path = output / "engines/compatibility-review.json"
    matrix = json.loads(matrix_path.read_text()) if matrix_path.exists() else {"ok": False}
    payload_unchanged = all((extracted / name).is_file() and digest((extracted / name).read_bytes()) == record["sha256"]
                            for name, record in manifest["files"].items())
    report = {"ok": completed.returncode == 0 and matrix["ok"] and payload_unchanged and digest(package.read_bytes()) == before,
              "version": manifest["version"], "package": str(package), "package_sha256": before,
              "manifest_verified": True, "identical_rebuild": True, "unpacked_payload_unchanged": payload_unchanged,
              "package_unchanged": digest(package.read_bytes()) == before,
              "check_count": sum(stage.get("checks") or 0 for engine in matrix.get("engines", []) for stage in engine["stages"].values()),
              "compatibility_report": str(matrix_path),
              "independent_beta_feedback": "pending; automated checks use the local machine",
              "youtube_playback": "pending; no upload performed"}
    (output / "package-review.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2), flush=True)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--godot", type=Path, action="append", required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--ffprobe", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    raise SystemExit(main(parser.parse_args()))
