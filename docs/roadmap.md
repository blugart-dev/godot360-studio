# Godot360 Studio roadmap

The user authorized the Godot360 name and private GitHub source hosting on
2026-09-07; that is separate from a public 1.0 release.
See [repository/privacy notes](repository.md).

The 1.0 target is dependable mono 360 production from a documented Godot scene
contract: repeatable recipes, predictable jobs, useful failure reports, and a
validated YouTube delivery file. It does not include stereoscopic ODS or ambisonic audio.

## Current priority — first successful export

On 2026-09-07 the user chose **Godot creators exporting their existing scenes** as
the primary audience and authorized the first usability pass. The working tree
adds current-scene selection with saving, a camera picker, grouped advanced controls,
tool/output readiness checks and a portable [quick start](../addons/godot360/QUICKSTART.md).
This work follows the historical 0.8 candidate; it is not a new published release.

The next product improvement discussed is full spherical playback, followed by a
recent-export view. The panel still previews only the first delivered frame. Test
the new first-export workflow with an independent Godot creator and use observed
dead ends to choose subsequent changes. Historical release gates below retain
their original scope and evidence.

## 0.2 — Capture performance

- Fast and Compact lossless PNG storage, with explicit disk-space tradeoffs.
- Capture and export timings, approximate capture ETA, and encoder cleanup.
- Pixel comparisons and a full 8K production benchmark.

## 0.3 — Short test renders and job planning

- A one-action short test render using the intended production settings.
- Estimate total render time and temporary disk needs from that actual sample.
- Clear encoding progress and cancellation throughout each stage.
- Re-encode a completed retained sequence without rendering the scene again.

Implemented and locally tested. Estimates extrapolate the first second; re-encoding
preserves the original capture and creates a fresh output. See the
[job planning guide](job-planning.md) for the workflow and its limits.

## 0.4 — Camera and timeline authoring

- Reusable AnimationPlayer property timeline with absolute frame sampling.
- Editable Path3D camera example and a Motion lab recipe in the panel.
- Image-based checks for moving objects across cube edges, the rear seam, and poles.
- Exact visual cue frames and measured source/encoded audio synchronization.

Implemented and locally tested. Method/audio/nested-playback animation tracks are
outside this helper's scope. See the [authoring guide](../addons/godot360/AUTHORING.md).

## 0.5 — Spherical delivery

- Spherical Video V2 plus matching V1 compatibility metadata.
- MP4 fast-start with 32/64-bit chunk relocation and cascading promotion tests.
- Independent exact media, packet/timestamp and decoded audio/video comparisons.
- Output verification of V2, fast-start and chunk-offset bounds.

Implemented and locally tested. Inputs remain the pipeline's conventional
unfragmented H.264/AAC MP4s with trailing moov. See [validation](validation.md).

## 0.6 — Soundtracks and synchronization

- Soundtrack attachment and explicit synchronization controls.
- Scene-only, replacement and mixed audio, independent levels, trim and offsets.
- Audio edits during re-encoding, with preserved capture sources.
- Real sample placement, resampling, limiter, preflight and source-change tests.

Implemented and locally tested. Attached files remain external dependencies;
read the [audio guide](../addons/godot360/AUDIO.md).

## Completed — Release reliability through 0.6.3

- 0.6.1 adds clean addon-only projects on Godot 4.5.1, 4.6.3 and 4.7.2, fixes the
  older engine's Motion Lab library loading, and supplies beta instructions plus
  reproducible packaging with content verification.
- Eight selected codec/rate fixtures and a 90-second mixed-audio job now pass.
- 0.6.2 validates actual 90-second/60 FPS capture at 1024×512, adds capture failure
  diagnostics and recovery actions, and checks worker/encoder interruption across
  all three engines. Completed captures can be reused; partial capture resume is absent.
- 0.6.3 reopens saved jobs and reconnects after editor loss through fresh identity
  challenges. Coordinator loss leaves original status intact and completed captures
  can be recovered without a recovery file. Old PIDs never authorize cancellation.

## Revised route to 1.0 — 2026-09-07

Freeze feature scope around mono equirectangular video, SDR BT.709, stereo audio,
portable recipes and recoverable jobs. The initial support target is Windows with
Godot 4.5.1/4.6.3/4.7.2 and Compatibility, external FFmpeg/FFprobe, and local storage.
These engine versions have evidence; this is not a claim about every later patch.
Linux/macOS, other renderers, stereo ODS, ambisonics, uploads, arbitrary capture
resume and a native backend are outside the first release's support claim.

| Gate | Acceptance evidence | State |
| --- | --- | --- |
| 0.7 — Storage and production runs | Check writable job files and operating headroom; stop on low space/write failures with no unverified final output; preserve reusable sources; pass injected failure and engine regressions | Passed locally: 1,161 checks across three engines |
| 0.7 — Production resolution | Inspect every source/decoded frame and beginning/middle/end audio cues in a 60-second 4096×2048/30 FPS run and a 30-second 7680×3840/30 FPS run; record storage, timings and limitations | Passed locally: all 1,800/900 frames and audio cues; see [validation](validation.md) |
| 0.8 — Local candidate | Install the exact packaged addon in a clean project, complete the documented workflow, establish versioned source history and provide useful diagnostics bundles | Passed locally: 1,332 checks on the exact ZIP across three engines; reproducible build and Git history; see [candidate record](release-0.8.md) |
| 0.8 — Independent beta | Gather at least one independent Windows/GPU beta report and resolve blocking defects | Pending external feedback; [report form](../addons/godot360/BETA-REPORT.md) and tested candidate are ready |
| 1.0 — Delivery review | User-reviewed YouTube navigation, orientation, detail, seams and audio on a current candidate | Positive user visual review of THRESHOLD on YouTube, 2026-09-07; individual playback checks are not yet recorded |
| 1.0 — Release | Final reproducible package/manifest, accurate supported limits and release notes; explicit approval before public publication | Pending independent beta, findings and final release preparation |

The original [12-second candidate film](../renders/delivery-080-8k/video-360.mp4)
remains verified local evidence. The subsequent [THRESHOLD film](threshold.md),
produced with the unchanged 0.8 addon, adds 60 seconds at 8K and positive user
feedback on its appearance in YouTube. See its guide for the exact report and
scope; no playback device/resolution or itemized checklist was supplied. Independent
Windows/GPU beta feedback remains the main outstanding external validation.

The 4K/8K runs establish these durations/settings on the measured machine. They do
not certify one-hour exports, arbitrary scene complexity, or every GPU. The existing
90-second/60 FPS low-resolution capture remains separate evidence. If a planned run
fails, fix and repeat the affected case before expanding duration or hardware.

Do local implementation and tests before requesting user verification. Independent
beta feedback and YouTube review can proceed alongside development, but cannot be
replaced by another local unit test. Do not add features solely to fill version
numbers, or postpone a Windows release until unclaimed operating systems are tested.

## GDExtension decision

Keep GDScript for editor controls, recipes, capture coordination, and diagnostics.
The original Compact PNG baseline identified compression as the dominant bottleneck;
FFmpeg already supplies a faster native encoder without adding addon binaries.
The current production runs validate sustained output but do not isolate a new
native-backend speedup. Use profiling before choosing the next performance change.

Prototype a native MovieWriter only when measurements justify removing Movie Maker's
duplicate image readback and scratch PNG, or when direct audio/image delivery is
needed. A native backend must preserve the same frame and audio contracts and ship
tested builds for each supported platform. A broad C++ rewrite is not a prerequisite
for 1.0; a small replaceable backend is the intended boundary.
