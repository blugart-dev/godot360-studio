# Private development toward 1.0

Godot360 stays private until the supported 1.0 workflow is implemented, tested and
ready. The current `0.8.0` version identifies a development baseline. Earlier
"beta" milestones describe historical packages; they do not pause development or
require a public beta. This follows the owner's direction on 2026-09-08.

The supported product is a Godot editor addon that exports a saved, authored 3D
scene as a mono 360° SDR video with stereo audio, then verifies and reviews it.
Readiness applies to a declared scene/renderer/platform matrix, with explicit
limits. It cannot mean every arbitrary shader, GPU and interactive game works.

## 1.0 launch scope — agreed 2026-09-13

**Windows is the supported launch platform; Linux and macOS are experimental.**
The owner selected this scope during the release-status review. Native Linux GPU
and Mac graphical testing remain necessary before promoting those platforms to
supported, but are no longer prerequisites for the Windows 1.0 release.

Keep the existing bounded scene contract: mono 360, SDR BT.709, stereo audio,
authored exposure and documented renderer/effect settings. Godot 4.7.2 is the
primary candidate environment. Revalidate any older engine or additional Windows
renderer/driver combination included in the final support matrix; historical
coverage alone does not certify a changed package. Further GI stacks, arbitrary
IK/retargeting pipelines and longer/heavier production profiles are extensions,
unless a reproducible defect affects the declared supported workflow.

## Current checkpoint — checked 2026-09-13

**Stabilization complete:** three stale panel tests are repaired. The local
development package passes **5,930 checks** across five full Windows lanes:
Compatibility on 4.5.1/4.6.3/4.7.2, and Forward+/Mobile Vulkan on 4.7.2. Fresh
Windows Mobile temporal cases and a local Linux software-history case also pass,
without changing the fixture or tolerance. The approved private branch
`codex/windows-1.0-stabilization` is pushed: Repository hygiene, Desktop platforms
and Temporal rendering all pass at `b69b427`. Linux completes **1,189** package
checks and its rendered reviews; Mac passes **1,045** headless checks. Both
temporal lanes pass, covering **936** decoded frames with negative controls.

The exact Git/CI ZIP also passes **1,186** native Windows 4.7.2 Forward+/Vulkan
checks. Fresh hosted Mobile history passes with unchanged thresholds; the earlier
mismatch remains unexplained and must stay visible in final candidate review.
The clean owner walkthrough is prepared against that Git ZIP. See
[source-matched hosted evidence](validation.md#hosted-stabilization-checkpoint--2026-09-13)
and [the five local lanes](validation.md#local-release-stabilization--2026-09-13).

GitHub remains private and `main` stays at `a3ff0ec`; version remains `0.8.0`.
The [original main status](validation.md#release-status-review--2026-09-13)
records five passing workflows and two failures before stabilization. The three
fresh runs cover the affected checks; other established matrices were not rerun.
The manual Combined rendering workflow has no hosted runs; its bounded native
evidence remains valid for its recorded snapshot.

## Remaining work

| Workstream | Remaining work | Completion evidence |
| --- | --- | --- |
| Capture appearance | [Capture borders](capture-borders.md) and [fixed authored exposure](exposure-consistency.md) now have a [combined moving-light/material review](combined-appearance.md). Consistent 1.0 exposure uses authored values; shared automatic spherical adaptation is deferred beyond 1.0. Remaining: document and review residual glow shape and other view-dependent effects in the supported scene matrix. | Before/after rendered fixtures, unchanged projection/color/geometry, measured cost, and documented residual limits. |
| Complex animated scenes | [Keyed skin and bone-camera cuts](skeletal-capture.md), [an imported GLB character](imported-characters.md), [a custom head look and nested skeleton mounts](modifier-capture.md), [simple particles](particle-capture.md), [moving smoke](smoke-capture.md) and [native trails](trail-capture.md) have rendered references. [Temporal rendering](temporal-capture.md), [saved LightmapGI](lightmap-capture.md) and [combined effects](combined-effects.md) establish selected GI, transparency and history cases. Consolidate these tested setups and exclusions in the final support matrix and resolve applicable regressions. Other GI/temporal stacks, general/stateful IK and other import/retarget pipelines remain extensions outside this evidence. | Deterministic fixtures with expected motion and visual comparisons; supported cases pass and exclusions are explicit. |
| Production performance | [Four one-minute Forward+/Mobile 4K/8K workloads](production-performance.md) now pass on native Windows / 4.7.2 / RTX 3060 Ti, with sampled process/GPU/system memory, timing, storage, frame/audio checks and controlled capacity failures. Forward+ 8K uses disabled MSAA; other profiles use 4×. Broader hardware, longer durations and heavier GI remain unmeasured. | Preserve the measured budgets and explicit limits; extend only the profiles selected for the final supported matrix. Short probes do not certify full-job RAM needs. |
| Regression follow-up | The obsolete panel tests are repaired and all affected hosted workflows now pass. The earlier Linux Mobile history mismatch remains unexplained despite fresh passing Windows and hosted runs. Preserve the failure and opening-frame evidence; account for the uncertainty in candidate review and investigate if it recurs. | Source-matched passing affected tests and current Windows evidence are retained. Record the historical failure's observed scope without claiming a root cause or renderer fix. Keep the original thresholds and negative controls. |
| Windows candidate matrix | Five native Windows lanes pass on the development package, with an additional exact Git/CI ZIP review. Freeze the final Godot/renderer/driver claims and revalidate the 1.0 artifact as required by its changes. Linux/macOS remain experimental. | Clean native installation, capture, frame/audio inspection, playback, cancellation and recovery on supported combinations. Retain experimental CI and its narrower evidence; native Linux/Mac hardware checks do not block Windows launch. |
| Private end-to-end usability and delivery | [Clean native editor integration](editor-workflow.md) now covers authored-scene saving, 4K test/export, stereo playback/seek, editor restart, cancellation and recovery. It fixes progress JSON errors and unwanted import of retained captures. Remaining: actual UI navigation and subjective delivery review from the published instructions. | Completed private walkthrough and itemized delivery review against the final candidate, with blocking findings resolved. Automated editor evidence does not close the click-through requirement. Independent feedback can help but is not a prerequisite for continuing implementation. |
| Final package | Freeze the Windows support matrix and experimental labels, finish documentation and migration notes, update the version, build the exact candidate and run applicable regression suites. | Reproducible ZIP/manifest, green required checks and native Windows reviews, explicitly accounted-for experimental results, no known supported-workflow blockers, and accurate release notes. |
| Public repository preparation | Refresh the source/history scan, review known historical personal paths and choose whether to expose existing history or use a reviewed source snapshot. Confirm public issue/security settings and the exact release artifacts. | Follow the [publication checklist](publishing.md), retain licenses/notices, and obtain final publication authorization after candidate acceptance. |

## Already working

The [2026-09-13 UI/UX audit](ui-ux-audit.md) separates current recipes from opened
exports, stabilizes tool selection, improves compact native layout and keyboard
review, and adds explicit playback recovery. Its state screenshots and automated
native/editor checks do not close the human click-through or final Windows gates.

Scene/camera selection, grouped settings, setup checks, 2K/4K/8K recipes, short-test
estimates, authored camera/timeline capture, scene and attached audio, spherical
MP4 metadata, output verification, cancellation, saved-job recovery, re-encoding,
storage guards, diagnostics, native spherical review and recent exports are
implemented. The README and guides now show actual results before installation.
[Validation](validation.md) records what has been tested and on which snapshots.
The combined Forward+/Mobile exposure-and-border review now passes locally. The
consistent-exposure boundary for 1.0 is defined in [its guide](combined-appearance.md).

## Order of work

Preserve the established native appearance, animation and effect evidence above.
The [production workload review](production-performance.md) supplies measured
time, memory and disk budgets, including the reduced-AA tradeoff for Forward+
8K on the tested 8 GiB GPU. These bounded milestones do not need an ever-growing
scene matrix before 1.0; changes and failures determine which checks to repeat.

1. Finish the [short owner walkthrough](ui-ux-audit.md#blugarts-short-verification-walkthrough)
   and itemized delivery review: orientation, seams/detail, sound, seeking,
   reopening, re-encoding and cancellation/recovery. Fix reproducible blockers.
2. Freeze the supported scene/Windows matrix and validate the exact 1.0 candidate,
   including package reproducibility, migration notes and support labels. Preserve
   the passing stabilization evidence and explicitly review the unexplained
   experimental Mobile observation; investigate any recurrence.
3. Complete the source/history and repository-settings review, then publish only
   after final authorization. Native Linux/Mac support can follow separately.

Stereoscopic ODS, ambisonics, automatic uploads and resuming arbitrary partially
captured scene state are outside the defined 1.0 scope. A native backend is an
implementation option if profiling justifies it, not a release requirement.

[Roadmap and historical milestones](roadmap.md) · [Renderer evidence](../addons/godot360/RENDERERS.md)
