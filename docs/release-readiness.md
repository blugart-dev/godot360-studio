# Private development toward 1.0

Godot360 stays private until the supported 1.0 workflow is implemented, tested and
ready. The current `0.8.0` version identifies a development baseline. Earlier
"beta" milestones describe historical packages; they do not pause development or
require a public beta. This follows the owner's direction on 2026-09-08.

The supported product is a Godot editor addon that exports a saved, authored 3D
scene as a mono 360° SDR video with stereo audio, then verifies and reviews it.
Readiness applies to a declared scene/renderer/platform matrix, with explicit
limits. It cannot mean every arbitrary shader, GPU and interactive game works.

## Remaining work

| Workstream | Remaining work | Completion evidence |
| --- | --- | --- |
| Capture appearance | Optional [capture borders](capture-borders.md) reduce tested glow cuts. [Fixed authored exposure](exposure-consistency.md) removes independent automatic metering while preserving exposure animation. Remaining: shared automatic spherical adaptation, glow shape and other view-dependent effects in representative scenes. | Before/after rendered fixtures, unchanged projection/color/geometry, measured cost, and documented residual limits. |
| Complex animated scenes | [Keyed skin and bone-camera cuts](skeletal-capture.md) now have rendered references and a corrected attachment delay. Remaining: particles, imported characters, modifiers/IK, nested attachments, longer temporal histories, FSR, VoxelGI/LightmapGI and stateful compositors. | Deterministic fixtures with expected motion and visual comparisons; supported cases pass and exclusions are explicit. |
| Production performance | Run representative Forward+/Mobile scenes at 4K/8K; measure render time, peak GPU memory, retained storage and behavior under pressure. | Sustained jobs complete without missing frames, audio drift or silent renderer fallback; practical budgets and limits are recorded. |
| Native platform coverage | Graphical Mac exports and hardware-GPU Linux workflows; complete the declared Godot/renderer/driver combinations. | Clean native installation, actual capture, frame/audio inspection, playback, cancellation and recovery on the target machines. Headless/software CI remains narrower evidence. |
| Private end-to-end usability and delivery | Follow the published instructions from a clean setup; export an existing scene, review it, reopen it and recover a failure. Review final orientation, seams, detail and sound. | Completed private walkthrough and itemized delivery review against the final candidate, with blocking findings resolved. Independent feedback can help but is not a prerequisite for continuing implementation. |
| Final package | Freeze the supported matrix, finish documentation and migration notes, update the version, build the exact candidate and run the applicable regression suites. | Reproducible ZIP/manifest, green CI and native reviews, no known blocking defects in supported workflows, and accurate release notes. |

## Already working

Scene/camera selection, grouped settings, setup checks, 2K/4K/8K recipes, short-test
estimates, authored camera/timeline capture, scene and attached audio, spherical
MP4 metadata, output verification, cancellation, saved-job recovery, re-encoding,
storage guards, diagnostics, native spherical review and recent exports are
implemented. The README and guides now show actual results before installation.
[Validation](validation.md) records what has been tested and on which snapshots.

## Order of work

1. Broaden fixed-exposure and capture-border evidence in representative scenes.
   Decide the supported 1.0 boundary for automatic spherical adaptation; it remains
   open and must not be claimed by the fixed authored-exposure option.
2. Broaden scene fixtures and resolve the resulting rendering/capture defects.
3. Measure production workloads and improve whichever resource limits are real.
4. Complete native hardware and private usability/delivery reviews as the required
   machines become available, while continuing all independent development work.
5. Freeze and validate the 1.0 candidate. Publication is a separate final action;
   nothing is published publicly during this development phase.

Stereoscopic ODS, ambisonics, automatic uploads and resuming arbitrary partially
captured scene state are outside the defined 1.0 scope. A native backend is an
implementation option if profiling justifies it, not a release requirement.

[Roadmap and historical milestones](roadmap.md) · [Renderer evidence](../addons/godot360/RENDERERS.md)
