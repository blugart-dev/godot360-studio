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
| Capture appearance | [Capture borders](capture-borders.md) and [fixed authored exposure](exposure-consistency.md) now have a [combined moving-light/material review](combined-appearance.md). Consistent 1.0 exposure uses authored values; shared automatic spherical adaptation is deferred beyond 1.0. Remaining: document and review residual glow shape and other view-dependent effects in the supported scene matrix. | Before/after rendered fixtures, unchanged projection/color/geometry, measured cost, and documented residual limits. |
| Complex animated scenes | [Keyed skin and bone-camera cuts](skeletal-capture.md), [an imported GLB character](imported-characters.md), [a custom head look and nested skeleton mounts](modifier-capture.md), [simple particles](particle-capture.md), [moving smoke](smoke-capture.md) and [native trails](trail-capture.md) have rendered references. [Temporal rendering](temporal-capture.md) now covers selected TAA/FSR, persistent camera/world compositors and VoxelGI cases, including cuts and explicit Mobile buffer requirements. [Saved LightmapGI](lightmap-capture.md) adds static receivers and a moving dynamic probe object, including a saved editor bake and missing-map controls. [Combined effects](combined-effects.md) adds lit intersecting transparency, 144-frame history and continuous camera motion/cut on native 4.7.2 Forward+/Mobile. Remaining: other GI/temporal stacks, general/stateful IK/modifier chains and other import/retarget pipelines. | Deterministic fixtures with expected motion and visual comparisons; supported cases pass and exclusions are explicit. |
| Production performance | [Four one-minute Forward+/Mobile 4K/8K workloads](production-performance.md) now pass on native Windows / 4.7.2 / RTX 3060 Ti, with sampled process/GPU/system memory, timing, storage, frame/audio checks and controlled capacity failures. Forward+ 8K uses disabled MSAA; other profiles use 4×. Broader hardware, longer durations and heavier GI remain unmeasured. | Preserve the measured budgets and explicit limits; extend only the profiles selected for the final supported matrix. Short probes do not certify full-job RAM needs. |
| Native platform coverage | Graphical Mac exports and hardware-GPU Linux workflows; complete the declared Godot/renderer/driver combinations. | Clean native installation, actual capture, frame/audio inspection, playback, cancellation and recovery on the target machines. Headless/software CI remains narrower evidence. |
| Private end-to-end usability and delivery | [Clean native editor integration](editor-workflow.md) now covers authored-scene saving, 4K test/export, stereo playback/seek, editor restart, cancellation and recovery. It fixes progress JSON errors and unwanted import of retained captures. Remaining: actual UI navigation and subjective delivery review from the published instructions. | Completed private walkthrough and itemized delivery review against the final candidate, with blocking findings resolved. Automated editor evidence does not close the click-through requirement. Independent feedback can help but is not a prerequisite for continuing implementation. |
| Final package | Freeze the supported matrix, finish documentation and migration notes, update the version, build the exact candidate and run the applicable regression suites. | Reproducible ZIP/manifest, green CI and native reviews, no known blocking defects in supported workflows, and accurate release notes. |

## Already working

The [2026-09-13 UI/UX audit](ui-ux-audit.md) separates current recipes from opened
exports, stabilizes tool selection, improves compact native layout and keyboard
review, and adds explicit playback recovery. Its state screenshots and automated
native/editor checks do not close the human click-through or other platform gates.

Scene/camera selection, grouped settings, setup checks, 2K/4K/8K recipes, short-test
estimates, authored camera/timeline capture, scene and attached audio, spherical
MP4 metadata, output verification, cancellation, saved-job recovery, re-encoding,
storage guards, diagnostics, native spherical review and recent exports are
implemented. The README and guides now show actual results before installation.
[Validation](validation.md) records what has been tested and on which snapshots.
The combined Forward+/Mobile exposure-and-border review now passes locally. The
consistent-exposure boundary for 1.0 is defined in [its guide](combined-appearance.md).

## Order of work

1. The [bounded combined-effects milestone](combined-effects.md) now passes:
   saved lightmaps, a moving probe receiver, lit intersecting transparency and
   persistent compositor history, with camera motion/cut and independent controls.
   Preserve this evidence when extending the supported appearance boundary.
   The bounded [saved LightmapGI](lightmap-capture.md) review now passes. Selected
   [TAA/FSR, persistent compositor and VoxelGI cases](temporal-capture.md) now pass;
   graphics-engine errors stop delivery with a useful failure report. The
   [moving smoke](smoke-capture.md) and [native trail](trail-capture.md) increments
   establish their documented particle settings, including renderer exclusions.
   [LUMEN](lumen.md) now demonstrates those effects in a complete 4K film.
   The custom head-look and nested attachment increment is validated within its
   documented setup. Fix reproducible defects found as coverage expands. The local combined
   exposure/border and simple particle startup passes have defined support limits;
   shared automatic spherical adaptation remains a future extension.
2. The bounded [production workload review](production-performance.md) now provides
   practical time, memory and disk budgets. Preserve its source-matched evidence
   and the reduced-AA tradeoff for Forward+ 8K on the tested 8 GiB GPU.
3. Complete native hardware and private usability/delivery reviews as the required
   machines become available, while continuing all independent development work.
4. Freeze and validate the 1.0 candidate. Publication is a separate final action;
   nothing is published publicly during this development phase.

Stereoscopic ODS, ambisonics, automatic uploads and resuming arbitrary partially
captured scene state are outside the defined 1.0 scope. A native backend is an
implementation option if profiling justifies it, not a release requirement.

[Roadmap and historical milestones](roadmap.md) · [Renderer evidence](../addons/godot360/RENDERERS.md)
