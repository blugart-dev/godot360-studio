"""Verify bounded JSON replacement with real Windows delete-sharing locks.

Requires Windows and Godot; generated fixtures live in a fresh output directory
inside the chosen project. No user files are locked or overwritten.
"""
import argparse
import ctypes
import json
import os
import subprocess
import time
from pathlib import Path


def main(args):
    if os.name != "nt":
        raise SystemExit("This review requires native Windows file sharing.")
    project, output = args.project.resolve(), args.output.resolve()
    output.relative_to(project)
    output.mkdir(parents=True)
    script = output / "writer.gd"
    script.write_text('''extends SceneTree
const IO = preload("res://addons/godot360/job_io.gd")
func _initialize():
    var folder = IO.argument("folder")
    IO.write_text(folder.path_join("started"), "ready")
    var start = Time.get_ticks_msec()
    var ok = IO.write_json(folder.path_join("target.json"), {"new": true})
    IO.write_json(folder.path_join("result.json"), {"ok": ok, "elapsed_ms": Time.get_ticks_msec() - start})
    quit()
''', encoding="utf-8")
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.CreateFileW.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p]
    kernel.CreateFileW.restype = ctypes.c_void_p
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]
    results = []
    for permanent in (False, True):
        folder = output / ("permanent" if permanent else "transient")
        folder.mkdir()
        target = folder / "target.json"
        original = b'{"old":true}'
        target.write_bytes(original)
        # GENERIC_READ, FILE_SHARE_READ (deliberately omits FILE_SHARE_DELETE).
        handle = kernel.CreateFileW(str(target), 0x80000000, 1, None, 3, 0, None)
        assert handle not in (None, ctypes.c_void_p(-1).value), ctypes.get_last_error()
        try:
            with (folder / "godot.log").open("wb") as log:
                child = subprocess.Popen([str(args.godot.resolve()), "--headless", "--path", str(project), "--log-file", str(folder / "engine.log"), "--script", "res://" + script.relative_to(project).as_posix(), "--", "--folder=" + str(folder)], stdout=log, stderr=subprocess.STDOUT)
                started = time.monotonic()
                while not (folder / "started").exists() and child.poll() is None and time.monotonic() - started < 15:
                    time.sleep(.005)
                assert (folder / "started").exists(), (folder / "godot.log").read_text()
                if not permanent:
                    time.sleep(.18)
                    kernel.CloseHandle(handle)
                    handle = None
                assert child.wait(timeout=15) == 0
        finally:
            if handle is not None:
                kernel.CloseHandle(handle)
        result = json.loads((folder / "result.json").read_text())
        if permanent:
            assert not result["ok"] and target.read_bytes() == original and 450 <= result["elapsed_ms"] < 2000
        else:
            assert result["ok"] and json.loads(target.read_text()) == {"new": True} and 150 <= result["elapsed_ms"] < 1500
        results.append({"case": folder.name, **result, "accepted": True})
    (output / "json-lock-review.json").write_text(json.dumps(results, indent=2))
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    main(parser.parse_args())
