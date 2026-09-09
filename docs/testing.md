# Developer verification

Run these commands from the repository root. For the user workflow, see the [quick start](../addons/godot360/QUICKSTART.md).

## Developer dependencies

Godot, FFmpeg and FFprobe are needed for export checks; follow the
[README's download and setup steps](../README.md#download-the-dependencies).
Using the addon in Godot requires no Python installation.

For the Python media reviewers, install [Python 3 for Windows](https://www.python.org/downloads/windows/)
using the [official Windows installation guide](https://docs.python.org/3/using/windows.html).
Open a new PowerShell window and confirm `py --version` works. From the repository
root, create an isolated environment and install [NumPy](https://numpy.org/install/)
and [Pillow](https://pillow.readthedocs.io/en/stable/installation/basic-installation.html):

```powershell
py -m venv .godot360/venv
& .\.godot360\venv\Scripts\python.exe -m pip install numpy pillow
& .\.godot360\venv\Scripts\python.exe -c "import numpy, PIL; print('Media-review dependencies ready')"
```

Use that environment's `python.exe` wherever a command below says `python`.
It lives in the already-ignored `.godot360` folder and requires no activation-script
or execution-policy changes. `tools/package_addon.py` and `tests/metadata_review.py`
use Python's standard library; NumPy/Pillow are for the other media reviewers and
their fixtures. The metadata reviewer also needs FFmpeg/FFprobe.

On **Linux/macOS**, use [Python 3](https://www.python.org/downloads/) and create
the equivalent virtual environment:

```sh
python3 -m venv .godot360/venv
.godot360/venv/bin/python -m pip install numpy pillow
.godot360/venv/bin/python -c "import numpy, PIL; print('Media-review dependencies ready')"
```

On Ubuntu/Debian, install `python3-venv` if Python reports that `ensurepip` is
unavailable. On macOS, the [official Python installer](https://www.python.org/downloads/macos/)
or Homebrew's `python` package supplies Python 3. Use the environment's `bin/python`
for commands below. Keep one environment per OS; Windows virtual environments
cannot be reused on Linux/macOS.

Where commands say `godot`, use your installed editor executable. In PowerShell,
quote a full path containing spaces and prefix it with `&`, for example
`& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --version` (replace the
example path with yours). See [Godot's command-line guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
The Godot script checks do not require Python. Tests that render scenes still need
a GPU/display; `--headless` only applies to the checks documented that way below.

On macOS the executable is normally `/Applications/Godot.app/Contents/MacOS/Godot`.
Pass that executable to `--godot`, not the outer `Godot.app` folder. On Linux,
pass the extracted executable and ensure it has execute permission. Reviewers take
**absolute executable paths**; `command -v ffmpeg` and `command -v ffprobe` locate
the installed tools. [Platform setup](../addons/godot360/PLATFORMS.md) covers both.

## Platform verification and CI

### Renderer appearance and motion

`tests/appearance_review.py` checks combined moving lights/materials, camera motion,
a lighting cut, camera/world exposure changes and capture borders. Nine rendered
clips provide fixed/authored-oracle comparisons, glow-disabled observations and
unlit geometry controls; a re-encode checks source preservation. Every MP4 is fully
decoded. See the [combined appearance guide](combined-appearance.md) for the native
Forward+/Mobile command and the distinction between acceptance and seam metrics.
The separate `Combined appearance` workflow runs both methods against an unpacked
candidate on Linux software Vulkan; this avoids extending the desktop-platform
workflow's timeout. Prepared CI coverage is not native hardware evidence; accepted
hosted runs must still be recorded in validation.

The [particle review](particle-capture.md) compares CPU/GPU particle motion across
cube boundaries with an analytic mesh reference. `tests/particle_review.py` checks
source and decoded MP4 frames plus authored processing modes. `--lifecycle` adds
disabled, when-paused and mid-capture pause cases; Linux CI includes them.
`--automatic-bounds`, `--short-warmup` and `--fixed-step` gate acceptance, including
the opening frame; Linux CI includes them. The reviewer also checks process deltas
and unchanged authored emitter settings. `--fps 24|30|60` selects the export and
matching particle step rate. Zero-warmup appearance remains a separate observation.

The [skeletal camera review](skeletal-capture.md) compares moving/cut bone cameras
and weighted skin against independent references, including decoded MP4 frames.
Run `tests/skeletal_review.py` with Godot, FFmpeg/FFprobe and a fresh `--output`;
the guide documents renderer and warmup/border/TAA variants. Package checks include
`skeletal_checks.gd`, and Linux CI runs an actual external-attachment comparison.

`tests/exposure_review.py` renders the moving-light exposure comparison from a
fresh disposable project. It checks all 90 source frames against a scene authored
with fixed exposure, decodes all video frames, compares legacy defaults, and
re-encodes while verifying original hashes/settings. See the
[command and variants](../addons/godot360/RENDERERS.md#capture-exposure) and
[illustrated result](exposure-consistency.md). `tests/exposure_checks.gd` runs in
every package/CI contract matrix and covers camera/world attribute animation,
resource replacement, physical projection, recipes, estimates and saved-input errors.

The package/compatibility reviewers accept `--rendering-method forward_plus`
or `--rendering-method mobile`, and `--rendering-driver vulkan` (or a native
backend such as `d3d12`). The isolated project's saved renderer drives actual
capture children; tests no longer hardcode Compatibility in their assertions.
The coordinator remains headless, and re-encoding starts no GPU worker.

For native visual comparisons, run:

```sh
python tests/renderer_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output .godot360/renderer-review-new --method forward_plus --driver vulkan --motion
```

Use `--method mobile --features color,lit,exposure,glow,fog,physical,compositor,world_compositor`
for Mobile, or select comma-separated features. `gi_off,gi` provides a darker
room with GI off/on; `auto_exposure` deliberately exposes separate face metering.
`--reference-hdr --features lit,glow` compares the SDR capture against a normal
HDR 2D viewport after an independent floating-point sRGB transfer.

Each one-second fixture exports 1024×512 from 512-pixel faces, 30 FPS and eight
warmup frames. It retains three native perspective/cube reference snapshots,
checks six-direction panorama sampling, and writes a contact sheet plus numeric
error metrics. These checks can pass while face-local effects still show seams:
the oracle verifies preservation, not a seamless substitute for screen-space data.
`--motion` additionally checks every PNG and decoded MP4 frame of a six-second,
2048×1024/1024-face sequence, including analytic poles/seam geometry and audio cues.

The renderer contracts run headlessly in every package review. On Windows,
`tests/json_lock_review.py --godot /path/to/godot --output .godot360/json-lock-new`
uses a real delete-sharing lock to check transient checkpoint retries and retention
of the previous JSON on permanent failure. It requires only Python's standard
library and Godot. Its output must be inside the chosen `--project`.

The Linux CI lane now also renders Forward+ and Mobile with Mesa software Vulkan,
including color, lighting, glow and a compute compositor. Its reports and contact
sheets are retained. Accepted hosted runs are recorded in [validation](validation.md).
Native macOS/Metal, Linux hardware GPUs and 4K/8K Forward+ endurance require
separate machine-specific validation.

`tests/platform_checks.gd` tests real child exit codes, literal arguments containing
shell punctuation/Unicode, log pipes, paths containing spaces, executable discovery,
and Unix permissions/symlinks. Linux runs must use a case-sensitive filesystem.
The compatibility and package reviewers include this suite automatically. Every
report names the OS, CPU architecture, tool versions and coverage.

For a complete local desktop run, build a fresh ZIP and review that frozen package:

```sh
python tools/package_addon.py --output .godot360/candidate.zip
python tests/package_review.py --package .godot360/candidate.zip --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output .godot360/package-review
```

Repeat `--godot` for additional engines. Use new destinations on each run. Avoid
editing source during source-mode reviews: the reviewer intentionally detects any
addon changes, including documentation. The package reviewer tests a frozen copy.

[Desktop platforms CI](../.github/workflows/platforms.yml) prepares Godot 4.7.2
on Ubuntu 24.04 and macOS 15, builds a candidate, verifies its manifest/rebuild,
and retains JSON reports, logs and preview screenshots for 14 days. It runs on
relevant pushes/PRs and can be started with **Actions → Desktop platforms → Run
workflow** after the workflow is pushed. It does not publish a release.

- **Linux:** complete package review using Xvfb and Mesa software OpenGL, including
  calibration/Motion Lab export, audio, re-encoding, recovery and failure paths.
  For local reproduction, install `xvfb` and Mesa, then prefix the package command
  with `LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s '-screen 0 1400x900x24'`.
- **macOS:** `--headless-only` verifies contracts, real FFmpeg processes/PNG pipes,
  capture failure handling and storage failures without requiring a GPU session.
  CI installs Homebrew's keg-only `ffmpeg-full` and puts its `bin` directory first
  on PATH. Both platform lanes perform a tiny Theora/Vorbis encode before package
  review so missing playback codecs fail in the dependency check with a clear log.
  The report explicitly says no rendered export was tested. It is not a release
  gate for Mac capture; run the full command on a Mac desktop before claiming that.
- **Windows:** the full local package matrix still covers 4.5.1, 4.6.3 and 4.7.2.

`--headless-only` is also available on the source compatibility reviewer; it rejects
`--job-recovery` and `--release-workflow` because those need a display. A green
headless report must not be counted as a successful end-to-end export. CI software
rendering does not establish GPU compatibility or production render performance.

## First-export workflow

`tests/recent_exports_checks.gd` exercises project-local history migration and
persistence, bounded metadata reads, stale/missing/malformed jobs, recipe and
file preservation, and active-job guards. Run with
`godot --headless --path . --script res://tests/recent_exports_checks.gd`;
omit `--headless` to also save a 1100×600 expanded-history screenshot in its
`.godot360/recent-*` fixture folder. No FFmpeg or new render is needed for these
metadata fixtures. The suite restores settings and runs in package reviews.
The release workflow additionally checks real launch/completion history and
reopening a delivery with native playback cache reuse.

`tests/playback_checks.gd` creates a real six-second MP4, prepares and probes its
review copy, checks native seeking/pause/replay/audio, cache reuse, cancellation,
source preservation and scene notes. Run it with the same FFmpeg/FFprobe arguments
as usability checks. A graphical run also validates decoded red/green/blue frame
intervals after forward/backward seeks and saves `playback-panel.png` in its test
job. Headless runs omit those pixel checks. Both lanes run in package review;
the release workflow additionally opens its actual Motion Lab export in playback.
Review tests require FFmpeg's optional libtheora and libvorbis encoders.

`tests/usability_checks.gd` exercises saved-scene camera discovery, inheritance and
instances without scene instantiation, camera ambiguity, editor save callbacks,
recipe restoration, malformed inputs, tool capabilities, stale readiness and output
write checks. It restores the previous local settings when finished.

```sh
godot --path . --script res://tests/usability_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe
```

With a GPU it also saves `.godot360/usability-panel.png` for layout review. The same
checks run headlessly inside `tests/compatibility_review.py` and the exact-package
reviewer. `tests/release_workflow_checks.gd` covers actual calibration/Motion Lab
exports, recipes, preview directions and diagnostics. Use a fresh review folder.

## Verification

The interactive regression suite covers 48 checks: real input events, camera
smoothing, physics rays, occlusion, target removal, repeatable events, narrative,
and background selection. Export tests cover validation, metadata structure,
source-byte preservation, unsupported inputs, and failure detection.

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/runtime_checks.gd
godot --headless --path . --script res://tests/export_checks.gd
godot --headless --path . --script res://tests/metadata_checks.gd
godot --headless --path . --script res://tests/audio_checks.gd
godot --headless --path . --script res://tests/planning_checks.gd
godot --headless --path . --script res://tests/timeline_checks.gd
godot --headless --path . --script res://tests/frame_writer_checks.gd -- --ffmpeg=/path/to/ffmpeg
```

The quality preset buttons, sampling warnings, and compact panel layout are checked
with `godot --path . --script res://tests/quality_panel_checks.gd` (GPU required).

A GUI/GPU integration test exercises the actual studio panel, full export, and
drag preview. Pass your tool paths after `--`:

```sh
godot --path . --script res://tests/studio_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe
godot --path . --script res://tests/planning_studio_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe --cancel-source=/path/to/completed-capture
```

It saves `.godot360/studio-preview.png` and a two-second calibration export under
`renders/studio-checks/`. The optional legacy `tests/capture_preview.gd` records six
perspective views of the interactive installation; it is not the 360 exporter.
The planning integration test also checks duration rescaling, stale estimates,
re-encoding at another CRF, and source-file hashes. An optional `--cancel-source`
with a longer capture exercises cancellation during an active H.264 encode.

The metadata suite covers V2 structure, media relocation, 32/64-bit offset tables,
cascading promotion across 4 GiB, invalid inputs and copy cancellation. Review a
real encoded/final MP4 pair independently with:

```sh
python tests/metadata_review.py /path/to/encoded.mp4 /path/to/video-360.mp4 --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe
```

The reviewer compares media bytes, packet hashes/timestamps and all decoded video
and audio, and checks V2 recognition with the V1 UUID disabled in a separate copy.

`tests/audio_review.py` generates short cues, runs complete re-encodes, and compares
AAC decoding against independently placed source samples. Pass `--godot`, `--ffmpeg`,
`--ffprobe`, and a fresh `--output` folder. `tests/audio_delivery_checks.py` accepts
those arguments plus `--source-review` pointing to the completed audio review and
`--legacy-source` pointing to a pre-0.6 CRF-16 capture with its encoded MP4.
It checks limiting, legacy media preservation and soundtrack mutation rejection.

Version 0.6.1 fixes Motion Lab on Godot 4.5.1 and adds isolated compatibility checks
on 4.5.1/4.6.3/4.7.2, eight soundtrack format cases and a 90-second mix. The
[beta guide](../addons/godot360/BETA.md) gives exact coverage, clean-project steps,
reviewer commands and reproducible packaging with `tools/package_addon.py`.
Version 0.6.2 adds [failure recovery guidance](../addons/godot360/RECOVERY.md),
controlled worker/encoder interruption tests, and a real 90-second GPU capture at
60 FPS with all 5,400 delivered frames and audio cues checked. The compatibility
reviewer accepts `--capture-failures`; `tests/endurance_review.py` runs the long
fixture with the same tool arguments and a fresh `--output` directory.
Add `--job-recovery` to exercise reopened panels, editor/coordinator loss,
fresh identity checks, stale PID rejection and recovered-source re-encoding.
`tests/audio_studio_checks.gd` exercises the real panel with `--soundtrack`,
`--ffmpeg` and `--ffprobe`; it restores local studio settings afterward.

The Motion Lab button and complete authored export are checked by
`tests/timeline_studio_checks.gd` with the same executable arguments. Render
`tests/fixtures/motion.tscn` for six seconds, then run `tests/motion_review.py`
against its folder to inspect actual PNG/MP4 motion and tone alignment. See the
[authoring guide](../addons/godot360/AUTHORING.md#verification) for dependencies.

See [validation results](validation.md) for the tested environment and known
gaps. The addon carries its own MIT license and reference notes, so it can be
copied into another project. It has not been published to the Asset Library.

`tests/border_review.py` renders moving glow and no-glow controls with 0% and 12.5%
capture borders. It measures discontinuities at an equatorial edge, three-face
corner and top edge, and writes a before/after sheet. Run separately for Forward+
and Mobile using a fresh output for each. See [capture borders](capture-borders.md)
for the images, measurement limits and command. Geometry and audio checks should
also use the six-second analytic motion fixture with a nonzero border.

See the [performance record](performance.md) for measurements and the
[roadmap](roadmap.md) for the next production milestones.
The [development handoff](HANDOFF.md) records the current state and constraints
for continuing in a fresh session.

`tests/imported_character_review.py` imports the pinned CesiumMan GLB in a fresh
project and compares native skin and a head-attached camera against raw-glTF CPU
references. Pass `--godot`, `--ffmpeg`, `--ffprobe` and a fresh `--output`, with
`--method` / `--driver` selecting the renderer. `--negative-control` requires late
skin/camera comparisons to fail; `--textured` isolates camera timing with the
original material. The package includes the binary asset and its separate CC BY
4.0 attribution/mark notices; the addon itself remains MIT. See
[the illustrated review and precise import settings](imported-characters.md).

Add `--head-look` for the stateless custom modifier and `--nested` for a second
skeleton below the head attachment. `--negative-control` also requires a delayed
modifier target to fail. Final bones, restored base poses, all six cube cameras
and warmup samples are checked. See [modifier capture](modifier-capture.md) for
the supported Manual callback setup and current evidence. The Imported characters
workflow covers both base animation and the nested head look on all three methods.
