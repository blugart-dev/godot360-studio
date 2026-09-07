# Save diagnostics

Use **Open saved job…** to select a completed, failed or unconfirmed export, then
click **Save diagnostics…**. Choose a new `.zip` name in an existing writable
folder outside the selected job. The panel reports success or a save error below
the button; the job's status and recipe stay in place. Existing ZIPs and `.partial`
files are never overwritten. No job is needed for an environment-only setup report.

The ZIP is local. Nothing is uploaded or sent. Review its contents before sharing:
reports and logs can contain local paths, project names, media tags and arbitrary
text printed by scene scripts. Automatic removal of private text is not provided.

## Contents

- `environment.json`: addon and collecting Godot version, OS and CPU; renderer and
  GPU when collected with a display. This describes the collector, which may differ
  from the engine or hardware used by an older saved export. A headless collector
  explicitly marks renderer information unavailable.
- `job/`: fixed diagnostic filenames from the selected folder, including job,
  status, report, recovery, capture results/settings/timings, storage, scene/quality
  checks, probe output, process logs and live stderr/progress excerpts when present.
- `manifest.json`: included byte sizes and SHA-256 hashes, missing/unreadable files,
  oversized omissions and the starting byte offset for truncated logs.
- `READ-ME.txt`: what was collected and what to include in a beta report.

Each JSON file is limited to 1 MiB. Larger JSON files are omitted and named in the
manifest; malformed JSON within that limit is retained as original evidence.
Each log keeps at most its last 512 KiB, which may begin within a line. The fixed
inventory bounds collection to less than 25 MiB of job data. ZIP members are read
back and compared before the `.partial` file receives its final ZIP name.

No frames, preview images, video, audio, scenes, executables, studio settings,
session files or cancellation requests are collected. The collector does not walk
subfolders or follow source/soundtrack paths from job files. For a failed re-encode,
its recovery report points to the original capture; select that capture separately
if its diagnostics are also needed. Original job files are only read.

An active job can change between reads, so the bundle is a snapshot rather than an
atomic record of a single moment. Missing files are normal for setup failures and
interrupted jobs. Save another ZIP after completion when needed. An unavailable
selected job folder produces an error instead of an environment-only success.

`capture.log` identifies the exporting engine/GPU when available;
`ffprobe-check.log` includes the probe version. Collection does not execute external
programs. Include `ffmpeg -version` separately if the FFmpeg version is needed.

## Repeat verification

```sh
godot --headless --path . --script res://tests/diagnostics_checks.gd
```

The suite uses disposable fixtures under `.umbral360`. It covers failed and setup
jobs, valid ZIP contents/hashes, bounded logs, empty stderr, malformed/oversized
JSON, missing destinations, overwrite refusal and original file preservation.
The exact-package reviewer also tests the real save dialog, successful/failed
exports, GPU information and compact panel layout; see [BETA.md](BETA.md).

The implementation uses Godot's [ZIPPacker](https://docs.godotengine.org/en/4.5/classes/class_zippacker.html)
and [RenderingServer](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html)
APIs. It requires no extra archive executable.
