# Private development toward 1.0

Godot360 stays private until the supported 1.0 workflow is implemented, tested and
ready. The current `1.0.0` addon passes its private Windows acceptance matrix.
The owner explicitly instructed that publication must wait for further approval. Earlier
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

The [Windows support contract](../addons/godot360/SUPPORT.md) now consolidates
the five launch combinations, tested scene setups, production envelope and
explicit exclusions. [Upgrade instructions](../addons/godot360/MIGRATION.md)
cover existing 0.x installations, and [the 1.0 release draft](release-1.0.md)
provides the description and final acceptance record. Stable labels are set;
the exact 1.0 addon passes 6,070 package and 52 native editor checks. RC2 includes the later usability and
early-cancellation fixes and passes the complete Windows package/editor matrix.

## Current private 1.0 acceptance — 2026-09-13

After the prepared RC2 walkthrough, the owner reported **"I did not get any
errors"** and authorized proceeding with thorough 1.0 preparation. This records
the feedback actually provided, without inventing itemized listening, headset or
YouTube results. No supported-workflow blocker was reported. Public release is
explicitly on hold until the owner instructs otherwise.

The final build changes release identifiers and documentation only. Rendering,
capture, encoding, recipes and saved jobs retain RC2 behavior. The exact addon
passes all five Windows lanes, native editor restart, manifests, metadata,
reproducibility and repository CI. Source/download and credential evidence are
recorded in [validation](validation.md); final archive identities accompany the
local `release/` folder. Preserve source-matched RC2 advanced-renderer evidence
and the failed experimental Linux Mobile result. Further work concerns final
source packaging and the deliberately withheld public-release steps.

## Frozen RC2 checkpoint — 2026-09-13

RC2 at `f1329c1c6478ccc942eacddd35247b4e9bf318f2` includes native offline help,
clearer setup/support/storage guidance and the coordinator startup-cancellation
fix. Its exact addon ZIP passes **6,070 package checks across all five Windows
lanes** and **52 native editor checks across first launch and restart**. Both
distributions rebuild identically; repository CI builds the same addon bytes.
The extracted source imports/starts cleanly and passes its scene checks. Current
guides and migration instructions are refreshed. See [RC2 validation](validation.md).

The experimental Linux Mobile temporal test reproduces its earlier first-five-
frame history mismatch. Its thresholds remain unchanged and its cause is still
unresolved; the [temporal record](temporal-capture.md) retains the exact evidence.
A fresh exact-RC2 Windows Mobile temporal review passes with unchanged limits.
Desktop and Forward+ temporal CI pass. Linux/macOS remain experimental under the
agreed Windows launch scope.

The remaining stable-release gates are the actual private walkthrough and
subjective delivery review, resolving applicable findings, then stable versioning
and final artifact acceptance. The public-history choice and final publication
authorization follow. A fresh RC2 walkthrough is prepared locally; automated
checks do not mark the human steps accepted.

## Frozen RC1 checkpoint — 2026-09-13

The exact **1.0.0-rc.1** ZIP passes all five Windows lanes (**5,930 checks**) and
the two-process native editor workflow (**44 checks**). Both addon/source archives
rebuild identically; repository CI passes and builds the same addon bytes. The
plugin, panel, generated README and delivered spherical metadata agree on RC1.
See [candidate evidence](validation.md#private-windows-rc1-acceptance-evidence--2026-09-13)
and [the release draft](release-1.0.md) for exact artifacts and source mapping.

Remaining stable-release work is human walkthrough/delivery feedback, resolving
any findings, updating stable labels and validating the resulting final artifact.
Public-history choice and authorized publication follow separately. The private
reporting feature is enabled when the repository becomes public, not as a private
RC prerequisite. The repository remains private and `main` is unchanged.

## Stabilization evidence before RC1 — checked 2026-09-13

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

GitHub remains private and `main` stays at `a3ff0ec`. This stabilization evidence
was recorded at version `0.8.0`; RC1 retains it as historical evidence.
The [original main status](validation.md#release-status-review--2026-09-13)
records five passing workflows and two failures before stabilization. The three
fresh runs cover the affected checks; other established matrices were not rerun.
The manual Combined rendering workflow has no hosted runs; its bounded native
evidence remains valid for its recorded snapshot.

## Remaining work

| Workstream | Remaining work | Completion evidence |
| --- | --- | --- |
| Capture appearance | The [combined moving-light/material review](combined-appearance.md) establishes authored exposure and capture borders. Residual halo-shape and view-dependent effects are documented in [the support contract](../addons/godot360/SUPPORT.md); shared automatic exposure is outside 1.0. Preserve this bounded evidence and include edges/poles/cuts in the final delivery review. | Before/after fixtures, unchanged projection/color/geometry and measured cost are retained. The known residual limits are explicit; human delivery acceptance remains open. |
| Complex animated scenes | [Keyed skin/cameras](skeletal-capture.md), [imported GLB](imported-characters.md), [head look/nested skeletons](modifier-capture.md), [particles](particle-capture.md), [smoke](smoke-capture.md), [trails](trail-capture.md), [temporal effects](temporal-capture.md), [saved LightmapGI](lightmap-capture.md) and [combined effects](combined-effects.md) now have a consolidated [support boundary](../addons/godot360/SUPPORT.md). Preserve the tested setups and resolve applicable regressions; further GI, stateful IK and import pipelines remain extensions. | Deterministic fixture results and negative controls are retained, with explicit setup requirements and exclusions. |
| Production performance | [Four one-minute Forward+/Mobile 4K/8K workloads](production-performance.md) now pass on native Windows / 4.7.2 / RTX 3060 Ti, with sampled process/GPU/system memory, timing, storage, frame/audio checks and controlled capacity failures. Forward+ 8K uses disabled MSAA; other profiles use 4×. Broader hardware, longer durations and heavier GI remain unmeasured. | Preserve the measured budgets and explicit limits; extend only the profiles selected for the final supported matrix. Short probes do not certify full-job RAM needs. |
| Regression follow-up | The obsolete panel tests and startup-cancellation defect are repaired. The experimental Linux Mobile history mismatch recurs in RC2, with the same first-five-frame measurements. Preserve the failure and opening-frame evidence; the cause remains unresolved. | Current Windows acceptance is recorded separately. Keep original thresholds and negative controls; do not report all hosted checks green or claim a renderer fix. Linux support remains experimental. |
| Windows matrix | All five [target combinations](../addons/godot360/SUPPORT.md) pass against the exact 1.0.0 addon, together with native editor integration. Further changes require applicable verification. Linux/macOS remain experimental. | 1.0.0 has 6,070 native package checks and 52 editor checks, reproducible package identity and unchanged sources. Native Linux/Mac hardware checks do not block Windows launch. |
| Private end-to-end usability and delivery | The owner reports no errors with RC2 and authorizes final preparation. The exact 1.0 editor workflow passes saving, 4K test/export, stereo playback/seek, restart, cancellation and recovery. No new supported-workflow blocker is reported. | Keep the owner's actual feedback and automated evidence distinct. No itemized subjective, headset or current-service results were supplied; complete service-specific review before making those claims. |
| Final package | The 1.0.0 addon, refreshed guides, migration notes and release description are ready. Final source/archive verification and the local release manifest accompany the prepared downloads. | Reproducible ZIP/manifest, green repository CI and native Windows reviews, retained experimental failure, accurate support limits and recorded source identities. |
| Public repository preparation | Source/all-ref credential scans pass; six historical brief blobs retain personal paths. A reviewed source-only ZIP is prepared. Choose the public-history approach and approve the exact artifacts. GitHub private vulnerability reporting is a public-repository feature; enable and verify it during authorized publication. | Follow the [publication checklist](publishing.md), retain licenses/notices, and obtain final publication authorization after candidate acceptance. Reporting activation is not a private RC prerequisite. |

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

1. Preserve the accepted Windows source/package identity and owner feedback.
   Verify the final source snapshot and record both archive checksums. Fix any
   newly reported reproducible supported-workflow blocker before distributing.
2. Keep publication on hold. When authorized, choose the public history, align
   the default branch/tag and public status text, and verify security reporting
   and final artifact identity. External-service uploads need separate approval.
3. Native Linux/Mac support and broader hardware/effect acceptance can follow
   separately. Do not close the known Linux Mobile issue based on Windows success.

Stereoscopic ODS, ambisonics, automatic uploads and resuming arbitrary partially
captured scene state are outside the defined 1.0 scope. A native backend is an
implementation option if profiling justifies it, not a release requirement.

[Roadmap and historical milestones](roadmap.md) · [Renderer evidence](../addons/godot360/RENDERERS.md)
