# Next-session brief — private development toward 1.0

Prepared on 2026-09-09 after the appearance and particle startup increments.
This is a recap and recommended plan, not a new release or authorization to publish.
The canonical completion criteria remain in [release readiness](release-readiness.md).

## Current position

Godot360 Studio is a working editor addon for exporting a saved, authored Godot
scene to mono 360 SDR video with stereo audio. Scene/camera selection, recipes,
short-test estimates, timeline capture, audio, spherical MP4 metadata, verification,
cancellation, diagnostics, re-encoding, recovery, storage guards, spherical playback
and recent exports are implemented. The internal version remains 0.8.0.

The last two local increments establish:

- Combined moving lights/materials, exposure-source changes and borders on
  Forward+/Mobile. Consistent 1.0 exposure uses authored values. Shared automatic
  spherical adaptation is deferred beyond 1.0. Borders reduce the measured glow
  cuts by 94–97% in the tested fixture; residual effects remain documented.
- Correct opening simulation deltas and matching-rate particle steps, plus the
  Compatibility CPU automatic-bounds fix. The tested simple CPU/GPU effects work
  with two warmup frames. Evidence includes 66 particle exports, three motion/audio
  reviews at 24/30/60 FPS and 1,875 headless contract checks. Zero-warmup GPU capture
  remains outside the validated contract.

These increments are uncommitted and unpushed. Both workflow files pass actionlint,
but the new appearance workflow and expanded particle cases have not run hosted
on this snapshot. Preserve the current working tree, including untracked fixtures,
reviewers and documentation media. Inspect the diff before preparing a checkpoint.

## Recommended order and difficulty

Difficulty is a planning judgment about implementation uncertainty, not a calendar
estimate. The amount of corrective work depends on what the rendered tests reveal.

| Order | Work | Difficulty | Why it matters | Completion evidence |
| --- | --- | --- | --- | --- |
| 0 | Checkpoint the current changes and run private hosted CI | Low; medium if CI exposes platform differences | Preserve the fixes in a reproducible revision and confirm the expanded tests run outside this machine. | Reviewed source/media diff, reproducible package, green hosted jobs or a diagnosed and resolved failure. |
| 1 | Imported animated character, then a common IK/modifier and nested attachment case | Medium for basic import; high for modifier order | Existing skin/camera references use a small constructed skeleton. A real imported asset exercises the normal creator workflow and additional update-order risks. | Licensed, reproducible fixture; skin, motion, attached camera and cuts match an independent reference; any exclusions are recorded. |
| 2 | Representative complex particles | High | Current particle coverage is deliberately simple. Transparent/billboard effects, trails, preprocessing and moving emitters are much closer to typical production effects. | Bounded cases with meaningful references for startup, motion, pause and cube-edge crossings; fix supported cases and state limits. |
| 3 | Decide and validate the advanced rendering support boundary | High to very high for general support | Temporal upscaling, GI and custom compositors may depend on view direction or previous frames. Correct export cannot be assumed from basic geometry tests. | Selected TAA/FSR, GI and compositor cases have rendered evidence and clear setup guidance. Full support for every combination is not a prerequisite implied by this plan. |
| 4 | Representative 4K/8K Forward+/Mobile workloads | Medium to measure; potentially high to optimize | Existing 4K/8K runs establish reliability for simpler Compatibility scenes. Heavy lighting, effects and texture content can change memory, time and storage needs substantially. | Sustained jobs with measured GPU memory, time, retained storage and audio alignment; practical budgets and failure behavior. |
| 5 | Native Linux GPU and Mac graphical review | Medium technically; dependent on hardware access | Software/headless CI cannot establish a native GPU installation, export and playback workflow. | Actual install/export/review/cancel/recovery on each claimed platform. If hardware is unavailable, the supported release matrix requires an explicit scope decision. |
| 6 | Private walkthrough from clean setup through delivery | Low to medium | A technically valid file can still be hard to produce or wrong in orientation, sound or spherical presentation. | Follow the published instructions with an existing scene, review the sphere and audio, reopen a job and recover a failure; resolve observed friction. |
| 7 | Freeze and validate the exact 1.0 package | Medium, after earlier work | A release needs one consistent supported matrix, code snapshot, documentation set and reproducible artifact. | Version and migration notes updated, exact package checks pass, known supported-workflow blockers resolved. Public publication remains a separate action. |

Hardware checks can proceed alongside independent local work when machines become
available. Final package work should follow the scene and production reviews.
The next engineering target is item 1, after checkpointing the current work.

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
Begin with one imported animated character and a bone-attached export camera.
Establish a trustworthy reference, reproduce any discrepancy and make the smallest
supported correction. Add an IK/modifier or nested attachment only after the basic
imported case is understood. Do not rerun completed large matrices without a code
change, failure or unresolved concern that justifies them.

No imported GLB/GLTF/FBX/Blend/OBJ asset appeared in the project source inventory
checked for this recap. Asset choice and redistribution permission therefore need
to be established when building the fixture. Use disposable projects and output
folders; preserve the user's creative scenes, recipes, settings and existing masters.

## Local evidence and tools

- Accepted package: `.godot360/particle-startup/accepted/candidate.zip`, SHA256
  `ad97a690a17c6859894c676b49437c4c53ee6b50a28c35f1d29d6d9273bdc2e7`.
  It is a private development snapshot, not a 1.0 release.
- Latest audit: `.godot360/particle-startup/audit.json`; full outputs and negative
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
> existing uncommitted appearance and particle work. Review the checkpoint/CI
> status, then implement and validate the imported animated-character case with
> a bone-attached export camera. Keep the scope bounded and document the evidence.
