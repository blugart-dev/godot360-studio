# Next-session brief — private development toward 1.0

Updated on 2026-09-09 after the head-look/nested-attachment increment.
This is a recap and recommended plan, not a new release or authorization to publish.
The canonical completion criteria remain in [release readiness](release-readiness.md).

## Current position

Godot360 Studio is a working editor addon for exporting a saved, authored Godot
scene to mono 360 SDR video with stereo audio. Scene/camera selection, recipes,
short-test estimates, timeline capture, audio, spherical MP4 metadata, verification,
cancellation, diagnostics, re-encoding, recovery, storage guards, spherical playback
and recent exports are implemented. The internal version remains 0.8.0.

Recent increments establish:

- A stateless custom head-look modifier and nested skeleton camera mount, with
  independent modified skin, final/base bones and six-camera pose checks. The
  documented Manual setup uses the existing runtime synchronization. See
  [modifier capture](modifier-capture.md) and the latest validation entry.

- Combined moving lights/materials, exposure-source changes and borders on
  Forward+/Mobile. Consistent 1.0 exposure uses authored values. Shared automatic
  spherical adaptation is deferred beyond 1.0. Borders reduce the measured glow
  cuts by 94–97% in the tested fixture; residual effects remain documented.
- Correct opening simulation deltas and matching-rate particle steps, plus the
  Compatibility CPU automatic-bounds fix. The tested simple CPU/GPU effects work
  with two warmup frames. Evidence includes 66 particle exports, three motion/audio
  reviews at 24/30/60 FPS and 1,875 headless contract checks. Zero-warmup GPU capture
  remains outside the validated contract.
- Imported CesiumMan GLB animation, skin and a head-attached camera/cut against
  independent raw-glTF references. Native Windows: 21 exports, including four
  rejected timing controls, plus 739 headless package checks. Precise reference
  import settings and matching bake FPS matter; the addon runtime needed no fix.

Appearance/particle work is checkpointed at `d37a786` and pushed privately. Both
hosted workflows pass: Desktop platforms `34363716312` and Combined appearance
`34363715991`. Imported-character source is checkpointed at `1a23a0c`. Its three
hosted workflows are also green: characters `34366471485`, platforms `34366473025`
and appearance `34366471526`, all on the final package hash below. Only Mobile's
character setup was retried after slow Ubuntu downloads, with unchanged source.
Preserve any new working-tree changes when continuing.

## Recommended order and difficulty

Difficulty is a planning judgment about implementation uncertainty, not a calendar
estimate. The amount of corrective work depends on what the rendered tests reveal.

| Order | Work | Difficulty | Why it matters | Completion evidence |
| --- | --- | --- | --- | --- |
| 1 | Representative complex particles | High | Current particle coverage is deliberately simple. Transparent/billboard effects, trails, preprocessing and moving emitters are much closer to typical production effects. | Bounded cases with meaningful references for startup, motion, pause and cube-edge crossings; fix supported cases and state limits. |
| 2 | Decide and validate the advanced rendering support boundary | High to very high for general support | Temporal upscaling, GI and custom compositors may depend on view direction or previous frames. Correct export cannot be assumed from basic geometry tests. | Selected TAA/FSR, GI and compositor cases have rendered evidence and clear setup guidance. Full support for every combination is not a prerequisite implied by this plan. |
| 3 | Representative 4K/8K Forward+/Mobile workloads | Medium to measure; potentially high to optimize | Existing 4K/8K runs establish reliability for simpler Compatibility scenes. Heavy lighting, effects and texture content can change memory, time and storage needs substantially. | Sustained jobs with measured GPU memory, time, retained storage and audio alignment; practical budgets and failure behavior. |
| 4 | Native Linux GPU and Mac graphical review | Medium technically; dependent on hardware access | Software/headless CI cannot establish a native GPU installation, export and playback workflow. | Actual install/export/review/cancel/recovery on each claimed platform. If hardware is unavailable, the supported release matrix requires an explicit scope decision. |
| 5 | Private walkthrough from clean setup through delivery | Low to medium | A technically valid file can still be hard to produce or wrong in orientation, sound or spherical presentation. | Follow the published instructions with an existing scene, review the sphere and audio, reopen a job and recover a failure; resolve observed friction. |
| 6 | Freeze and validate the exact 1.0 package | Medium, after earlier work | A release needs one consistent supported matrix, code snapshot, documentation set and reproducible artifact. | Version and migration notes updated, exact package checks pass, known supported-workflow blockers resolved. Public publication remains a separate action. |

Hardware checks can proceed alongside independent local work when machines become
available. Final package work should follow the scene and production reviews.
The next engineering target is item 1: smoke, billboards, trails and moving emitters.

## Scope recommendations

The proposed 1.0 finish line is dependable export for a declared set of ordinary
authored scenes, with useful diagnostics and explicit limitations. The advanced
effect work should establish that boundary rather than expand indefinitely.
Specific newly discovered exclusions should be discussed before narrowing an
already promised capability.

Already outside the defined 1.0 scope: shared automatic spherical exposure,
stereoscopic ODS, ambisonics, automatic uploads, and resuming arbitrary partially
captured simulation state. Zero-warmup GPU particles remain unsupported; the
tested particle workflow uses at least two warmup frames. A native backend is an
option only if profiling establishes a reason to build it. Renaming the outer
local checkout is optional housekeeping and is not a release blocker.

## Starting the next engineering task

Read this brief, the latest entries in [HANDOFF](HANDOFF.md) and
[validation](validation.md), [release readiness](release-readiness.md), and
[skeletal capture](skeletal-capture.md). Verify the working tree before editing.
The basic imported case is established in [imported characters](imported-characters.md).
The [head-look/nested setup](modifier-capture.md) is now established too.
Begin with bounded complex particle fixtures: smoke, billboards, trails and moving
emitters. Establish references, reproduce discrepancies and make the smallest
supported corrections. Do not rerun completed large matrices without a code
change, failure or unresolved concern that justifies them.

`tests/fixtures/cesium_man/` now contains a pinned licensed GLB with its attribution
and original notices; the reviewer verifies its SHA256. Use disposable projects and output
folders; preserve the user's creative scenes, recipes, settings and existing masters.

## Local evidence and tools

- Latest head-look/nested package: `.godot360/modifier-review/package/candidate.zip`,
  SHA256 `8f0a2dd5a4b0cf6906fe41a6eb5c8ad10dcd51aace4c27a3a949b016d416b788`.
  Its identical rebuild, 2,985 package checks and 26 rendered exports pass locally.
  `.godot360/modifier-review/audit.json` records source matching and protected
  hashes. Hosted runs for this increment await push; the earlier results below
  describe the previous imported-character snapshot.

- Previous accepted package: `.godot360/imported-character/final/candidate.zip`, SHA256
  `3a66b1f853e6f0494a56020b63731da1c7717f3af02b38183ea8feecf558bf31`.
  It is a private development snapshot, not a 1.0 release.
- Latest audit: `.godot360/imported-character/audit.json`; full outputs and negative
  controls are retained under that directory. The appearance evidence remains
  under `.godot360/appearance-review/`. These large outputs are ignored by Git.
- Windows engines are under
  `C:/Users/ignac/Game Development/Godot/Versions/`, using the
  `Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe` layout,
  with corresponding 4.5.1 and 4.6.3 installations.
- FFmpeg/FFprobe are under
  `.godot360/tools/ffmpeg/ffmpeg-9.0.1-essentials_build/bin/`.
- Python with NumPy/Pillow:
  `C:/Users/ignac/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
  The default `C:/Python314/python.exe` lacks those review dependencies.
- Isolate APPDATA/LOCALAPPDATA per disposable Windows review, as the existing
  particle reviewer does. Native graphics workers are required for rendered
  evidence; headless coordinator/contracts have narrower coverage.

Suggested opening prompt:

> Continue private Godot360 Studio development toward 1.0. Read
> docs/next-session.md and the latest HANDOFF/validation entries. Preserve the
> existing work. Review the checkpoint/CI status, then implement and validate a
> bounded complex particle cases: smoke, billboards, trails and moving emitters.
> Preserve the validated head-look/nested attachment setup. Keep the scope bounded and document the evidence.
