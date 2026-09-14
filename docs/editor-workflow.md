# Clean native editor workflow

This review starts with an addon-only ZIP, an empty settings profile and an
ordinary saved scene outside `addons/`. The scene uses standard Godot nodes:
six direction labels, a moving sphere driven by AnimationPlayer, lighting and
an imported stereo WAV. It has no capture hooks or addon script dependency.

The native integration driver exercises the real plugin in two separate Godot
editor processes. It selects and saves the scene, discovers its camera, selects
FFmpeg through the file-dialog callback, checks setup, exports a one-second
4K test and a four-second 4K video, prepares native playback, checks pause and
forward/backward seeking, measures both audio channels at the mix bus, restarts
the editor, reopens history, cancels capture and encoding, and recovers the
completed source. Every delivered job must pass all thirteen product checks.
Original capture files and the authored scene are hashed around recovery.

This is an **automated native editor integration review**, using panel signals
and editor APIs. It does not certify mouse navigation, tool installation by a
new user, subjective listening, headset comfort or native Linux/Mac operation.
The owner subsequently reported no errors with RC2 and authorized the 1.0 release;
the [release acceptance](release-readiness.md) records that feedback without
inferring an itemized device or listening review.

## Findings from the 2026-09-11 review

The clean-project pass found two defects that earlier reviews under ignored
scratch directories did not expose:

- A progress-file read could briefly return unavailable JSON and emit an editor
  parser error while an otherwise successful render continued. Reads now use
  the non-logging parser and return an unavailable checkpoint on read/parse
  failure. Polling remains nonblocking; corrupt data cannot establish success.
- Restarting a project with exports under its default `renders/` destination
  imported the retained PNG/WAV files. The baseline produced 158 `.import`
  sidecars across its sample and full export. New job folders now receive
  `.gdignore` before their files are written, through both panel and direct
  coordinator entry points. Parent folders and older captures are untouched.

The corrected native run passes 44 editor checks across two processes, with
zero import sidecars after restart and unchanged original source hashes after
playback and recovery. It covers Windows 11, Godot 4.7.2, Forward+/Vulkan and
the RTX 3060 Ti. Native stereo mix peaks exceed 0.18 on both channels; forward
and backward paused seeks check actual decoded images. These are objective
delivery checks, not a subjective listening assessment.

The development driver initially had a type error and overly strict path/number
string comparisons. It also attempted editor saving from a timer callback,
which reentered Godot's timer list; waiting for the next process frame fixed
that test-driver error. Those pilot runs are excluded. The baseline import
regression is retained under `.godot360/editor-workflow-pilot5/`; accepted
evidence and final package mapping are recorded in [validation](validation.md).

## Reproduce

Use the Python setup in [developer verification](testing.md) and absolute tool
paths. The reviewer refuses to reuse an existing output folder. It installs the
provided package without replacing its runtime with the working checkout.

```powershell
python tools/package_addon.py --output .godot360/editor-candidate.zip
python tests/editor_review.py --package .godot360/editor-candidate.zip --output .godot360/editor-review --godot GODOT --ffmpeg FFMPEG --ffprobe FFPROBE
```

A native graphical session is required. The headless package checks do not run
this driver. Retain `editor-review.json`, both editor logs, the prepared project,
the exact package and the reviewer snapshots together. A nonzero exit or any
unexpected engine error fails acceptance; merely preparing the project is not a
passing walkthrough. Reports distinguish automated checks from human feedback.

To prepare the same scene for a manual walkthrough, without the integration
driver or an enabled plugin:

```powershell
python tests/prepare_walkthrough.py --package .godot360/editor-candidate.zip --output .godot360/manual-walkthrough --godot GODOT
```

Follow the [quick start](../addons/godot360/QUICKSTART.md) in that editor. Tool
paths, history, settings and outputs are isolated from the development project.
Omit `--godot` to prepare files without opening the editor.

[Release criteria](release-readiness.md) · [Validation records](validation.md)
