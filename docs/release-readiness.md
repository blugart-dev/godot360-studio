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

**Local stabilization update:** three stale panel tests are repaired. The exact
development package passes **5,930 checks** across five full Windows lanes:
Compatibility on 4.5.1/4.6.3/4.7.2, and Forward+/Mobile Vulkan on 4.7.2. Fresh
Windows Mobile temporal cases and a local Linux software-history case also pass,
without changing the fixture or tolerance. Hosted temporal failure remains
unexplained; the owner has explicitly approved the private branch push and CI
dispatch following the earlier approval rejection. The clean owner walkthrough is
prepared. See [local stabilization evidence](validation.md#local-release-stabilization--2026-09-13).

The following remote checkpoint remains unchanged:

GitHub remains private. Local and remote `main` match `a3ff0ec`; the working tree
was clean before this documentation update. Version remains `0.8.0`. The reviewed
241-member UI package matches that checkout. Source hygiene passes for 491 files,
606 local links and 46 media hashes; all seven repository-guard tests pass.

The latest hosted checkpoint has **five passing workflows and two failures**,
not the all-green result of the earlier checkpoint. Desktop platforms stops in
an audio-panel test that assumes the old UI hierarchy; Mobile temporal history
exceeds its image-reference tolerance. Mac headless and Forward+ temporal lanes
pass. The manual Combined rendering workflow has no hosted runs. See the
[exact status and failure evidence](validation.md#release-status-review--2026-09-13).

## Remaining work

| Workstream | Remaining work | Completion evidence |
| --- | --- | --- |
| Capture appearance | [Capture borders](capture-borders.md) and [fixed authored exposure](exposure-consistency.md) now have a [combined moving-light/material review](combined-appearance.md). Consistent 1.0 exposure uses authored values; shared automatic spherical adaptation is deferred beyond 1.0. Remaining: document and review residual glow shape and other view-dependent effects in the supported scene matrix. | Before/after rendered fixtures, unchanged projection/color/geometry, measured cost, and documented residual limits. |
| Complex animated scenes | [Keyed skin and bone-camera cuts](skeletal-capture.md), [an imported GLB character](imported-characters.md), [a custom head look and nested skeleton mounts](modifier-capture.md), [simple particles](particle-capture.md), [moving smoke](smoke-capture.md) and [native trails](trail-capture.md) have rendered references. [Temporal rendering](temporal-capture.md), [saved LightmapGI](lightmap-capture.md) and [combined effects](combined-effects.md) establish selected GI, transparency and history cases. Consolidate these tested setups and exclusions in the final support matrix and resolve applicable regressions. Other GI/temporal stacks, general/stateful IK and other import/retarget pipelines remain extensions outside this evidence. | Deterministic fixtures with expected motion and visual comparisons; supported cases pass and exclusions are explicit. |
| Production performance | [Four one-minute Forward+/Mobile 4K/8K workloads](production-performance.md) now pass on native Windows / 4.7.2 / RTX 3060 Ti, with sampled process/GPU/system memory, timing, storage, frame/audio checks and controlled capacity failures. Forward+ 8K uses disabled MSAA; other profiles use 4×. Broader hardware, longer durations and heavier GI remain unmeasured. | Preserve the measured budgets and explicit limits; extend only the profiles selected for the final supported matrix. Short probes do not certify full-job RAM needs. |
| Current regression failures | Three obsolete panel lookups are repaired and all five Windows package lanes pass, including previously skipped suites. Run the authorized hosted verification. Diagnose the hosted Mobile history mismatch; the unchanged fixture passes fresh Windows and local Linux software runs. Keep experimental failures visible and explicitly account for them in candidate acceptance. | Source-matched passing affected tests and current Windows evidence; any experimental-only exception has a documented cause and scope. Do not simply loosen image thresholds or count a timeout as a pass. |
| Windows candidate matrix | Complete the declared Windows Godot/renderer/driver combinations. Linux/macOS remain experimental under the owner's launch decision. | Clean native installation, capture, frame/audio inspection, playback, cancellation and recovery on supported combinations. Retain experimental CI and its narrower evidence; native Linux/Mac hardware checks do not block Windows launch. |
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

1. Verify the repaired panel tests in hosted CI and investigate the hosted Mobile
   temporal mismatch. Preserve the five passing Windows package lanes; review
   experimental failures explicitly rather than inheriting old green results.
2. Finish the [short owner walkthrough](ui-ux-audit.md#blugarts-short-verification-walkthrough)
   and itemized delivery review: orientation, seams/detail, sound, seeking,
   reopening, re-encoding and cancellation/recovery. Fix reproducible blockers.
3. Freeze the supported scene/Windows matrix and validate the exact 1.0 candidate,
   including package reproducibility, migration notes and support labels.
4. Complete the source/history and repository-settings review, then publish only
   after final authorization. Native Linux/Mac support can follow separately.

Stereoscopic ODS, ambisonics, automatic uploads and resuming arbitrary partially
captured scene state are outside the defined 1.0 scope. A native backend is an
implementation option if profiling justifies it, not a release requirement.

[Roadmap and historical milestones](roadmap.md) · [Renderer evidence](../addons/godot360/RENDERERS.md)
