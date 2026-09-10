"""Build or verify a reproducible addon ZIP without previous releases or local assets.

Python standard library only. Run from the checkout or an unpacked release:
    python tools/package_addon.py
    python tools/package_addon.py --verify dist/godot360-studio-VERSION.zip
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

TESTS = """gltf_reference.py imported_character_review.py appearance_review.py exposure_checks.gd exposure_review.py border_review.py audio_checks.gd audio_delivery_checks.py audio_formats_review.py
audio_review.py audio_studio_checks.gd capture_lifecycle_checks.gd compatibility_review.py diagnostics_checks.gd endurance_review.py export_checks.gd
frame_writer_checks.gd metadata_checks.gd metadata_integration.gd metadata_review.py
motion_review.py particle_review.py particle_checks.gd smoke_review.py trail_review.py planning_checks.gd planning_studio_checks.gd quality_panel_checks.gd recovery_studio_checks.gd
studio_checks.gd timeline_checks.gd skeletal_checks.gd skeletal_review.py timeline_studio_checks.gd storage_checks.gd storage_failure_checks.gd release_workflow_checks.gd usability_checks.gd platform_checks.gd renderer_checks.gd renderer_review.py json_lock_review.py package_review.py playback_checks.gd recent_exports_checks.gd""".split()
ADDON_SUFFIXES = {".md", ".gd", ".uid", ".gdshader", ".tscn", ".tres", ".cfg"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inventory(root):
    addon = root / "addons/godot360"
    match = re.search(r'^version="(\d+\.\d+\.\d+)"$', (addon / "plugin.cfg").read_text(), re.MULTILINE)
    assert match, "Missing addon version"
    version = match.group(1)
    assert 'const SOFTWARE = "Godot360 Studio ' + version + '"' in (addon / "spherical_metadata.gd").read_text()
    assert 'title.text = "GODOT360 STUDIO   /   ' + version + '"' in (addon / "studio_layout.gd").read_text()
    assert "**Version " + version + " " in (addon / "README.md").read_text(), "README version differs"
    paths = sorted(path for path in addon.rglob("*") if path.is_file() and
                   (path.suffix in ADDON_SUFFIXES or path.name == "LICENSE"))
    # Keep illustrated guides portable; full film previews stay in root docs.
    paths += sorted((addon / "media").glob("*.png"))
    paths += sorted((addon / "media").glob(".gdignore"))
    paths += [root / "tests" / name for name in TESTS]
    paths += sorted(path for path in (root / "tests/fixtures").rglob("*") if path.suffix in {".gd", ".tscn"})
    paths += [root / "tests/fixtures/cesium_man" / name for name in
              ["CesiumMan.glb", "LICENSE.md", "README.md", "metadata.json", "LicenseRef-LegalMark-Cesium.txt"]]
    paths += [root / "tools/package_addon.py"]
    files = {}
    for path in paths:
        assert path.is_file() and not path.is_symlink(), path
        name = path.relative_to(root).as_posix()
        assert name not in files, name
        files[name] = path.read_bytes()
    assert "addons/godot360/LICENSE" in files
    manifest = {"version": version, "files": {name: {"bytes": len(data), "sha256": digest(data)}
                                             for name, data in sorted(files.items())}}
    files["manifest.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
    return version, files


def verify(path, files):
    with ZipFile(path) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)) and set(names) == set(files), "Archive inventory differs"
        assert archive.testzip() is None, "Archive CRC check failed"
        for name, data in files.items():
            assert archive.read(name) == data, "Archive differs from source: " + name


def main(args):
    root = args.root.resolve()
    version, files = inventory(root)
    if args.verify:
        verify(args.verify, files)
        print(json.dumps({"verified": str(args.verify.resolve()), "files": len(files), "version": version}))
        return
    destination = args.output or root / "dist" / ("godot360-studio-" + version + ".zip")
    destination = destination.resolve()
    report_path = destination.with_suffix(".json")
    assert not destination.exists() and not report_path.exists(), "Use a fresh package destination"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, "x", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data, compress_type=ZIP_DEFLATED, compresslevel=9)
    verify(destination, files)
    report = {"path": str(destination), "version": version, "files": len(files),
              "bytes": destination.stat().st_size, "sha256": digest(destination.read_bytes()),
              "all_entries_match_source": True, "manifest": "manifest.json"}
    with report_path.open("x", encoding="utf-8") as file:
        file.write(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--verify", type=Path)
    main(parser.parse_args())
