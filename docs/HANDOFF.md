# Godot360 Studio development handoff

## Private RC1 validated on the Windows launch matrix — 2026-09-13

**1.0.0-rc.1** at `b323a92` is pushed privately. The packager now supports numbered
RC identifiers and correct development/candidate/stable installation labels,
with six drift/invalid-version regression tests. Product release strings identify
RC1; capture/rendering behavior is unchanged.

The exact 243-member ZIP passes **5,930 checks across all five Windows lanes**
and **44 native editor checks** across export/playback/restart/cancel/recovery.
Both distributions rebuild identically; repository CI passes and builds the same
addon bytes. [The validation record](validation.md#private-windows-rc1-acceptance-evidence--2026-09-13)
maps the commit, hashes, immutable packages, native reports and CI evidence.

Use `.godot360/rc1-review-20260913/owner-walkthrough/` for the remaining human
review of this exact candidate. Its plugin starts disabled; human acceptance is
pending. After feedback, fix findings and prepare the stable version/artifact.
The repository remains private. Public-history choice and final authorization
remain open; enable GitHub private vulnerability reporting during authorized
publication, since the feature is scoped to public repositories. The older
0.8.0 preparation below retains its historical package identities.

## Windows release content and distributions prepared — 2026-09-13

Commit `da96a39` adds the [Windows support contract](../addons/godot360/SUPPORT.md),
expanded upgrade instructions and [1.0 release draft](release-1.0.md). The addon
and complete source archives rebuild identically from Git bytes; only six addon
Markdown files differ from the tested stabilization ZIP. Runtime, tests, fixtures
and assets are unchanged. Fresh source import/startup and 247 native/example
checks pass with unchanged source payloads. See
[the exact package/source evidence](validation.md#windows-release-content-and-source-distribution--2026-09-13).

Fresh scans find no credentials across all 41 local commits or the exact source.
Six historical brief blobs retain workstation paths; the prepared source archive
contains no Git history. GitHub stays private, Issues/Actions are enabled, and
private vulnerability reporting is unconfirmed after HTTP 404. No settings or
history were changed. The prepared human walkthrough still uses identical runtime.
Next: human delivery acceptance, final stable version/artifact, public-history
choice and final publication authorization. Keep version 0.8.0 until acceptance.

## Windows and hosted stabilization complete — 2026-09-13

Repaired the obsolete audio/recovery/release-test panel lookups. Five complete
Windows package lanes pass **5,930 checks** against one reproducible ZIP; fresh
Mobile temporal references also pass locally on Windows and in a narrower WSL
software case. No runtime or tolerance change was made.

The approved private branch `codex/windows-1.0-stabilization` is pushed with
tested commit `b69b427`. Repository hygiene, Desktop platforms and Temporal
rendering all pass there. Linux completes 1,189 package checks and its rendered
reviews; Mac passes 1,045 headless checks. Both temporal lanes pass 936 decoded
frames with the expected negative controls. The exact Git/CI ZIP also passes
1,186 full Windows Forward+/Vulkan checks. See
[hosted evidence](validation.md#hosted-stabilization-checkpoint--2026-09-13)
and [the latest brief](next-session.md) for hashes and the prepared walkthrough.

The earlier Mobile history mismatch remains unexplained despite fresh passing
Windows and hosted runs with unchanged thresholds. Retain it as an experimental
Linux observation for final candidate review. Next: owner walkthrough and delivery
acceptance, then the exact Windows 1.0 candidate and public-history review.
Version stays 0.8.0 and the repo stays private. The older status below describes
the main checkpoint; the stabilization evidence above supersedes its next steps.

## Windows 1.0 launch scope and current CI — 2026-09-13

The owner chose **Windows supported; Linux/macOS experimental**. Native Linux/Mac
hardware acceptance no longer blocks Windows 1.0. The private repository's local
and remote `main` match `a3ff0ec`; version remains 0.8.0.

The [fresh status review](validation.md#release-status-review--2026-09-13) found
five passing hosted workflows and two failures: an obsolete audio-test UI lookup
halts the Linux package review, and Mobile temporal-history image references
exceed tolerance. Mac headless and Forward+ temporal pass. Next: repair the stale
test, investigate the mismatch and its Windows relevance, finish the owner
walkthrough, and freeze the exact Windows candidate. The status review updates
documentation only; failures remain unresolved. Follow the revised
[release checklist](release-readiness.md) over older platform-gate statements below.

## Studio UI/UX audit — 2026-09-13

Implemented the [complete workflow audit](ui-ux-audit.md), including before/after
screenshots and Blugart's short verification walkthrough. Current recipe, Tools
and Library are separate from Opened export; tool choices persist; still/video
and verified delivery are explicit; preview errors have their own retry/logs;
keyboard review and compact layout are improved. The prior uncommitted playback
fix remains intact. Author Blugart and private development version 0.8.0 remain.

See [validation](validation.md#studio-uiux-audit--2026-09-13) for packaged headless,
native playback/UI/editor evidence, source mappings and failed test-development
attempts. This private checkpoint includes the prior playback fix. Preserve the
evidence under `.godot360/ui-ux-review/`; no public release or version bump was made.
Next owner action is the short human walkthrough; automated integration and
screenshots do not close subjective delivery, accessibility or platform gates.

For a fresh session, start with the [current recap and difficulty assessment](next-session.md).
It identifies the completed checkpoint, remaining work, support decisions,
and the next bounded engineering task. The detailed records below remain the evidence.

## Private walkthrough playback corruption — 2026-09-12

The owner found colored corruption around the moving sphere during in-editor
playback, with a visually correct delivery MP4. The existing Gyan 8.0.1 full
build produced an invalid Theora cache; strict decoding rejects it. The tested
Gyan 9.0.1 essentials build regenerates clean playback from the same MP4.
`playback_review.gd` now decodes the entire copy before loading/caching it and
invalidates older unvalidated cache formats. Failure guidance directs the user
to select another tool build and retry. No capture or shader changes.

The targeted suite passes 50 native and 44 headless checks, including a malformed
packet control, decode-stage cancellation, cleanup and retry. Native screenshots
of the actual clip are clean and its delivery hash is unchanged. See the newest
[validation entry](validation.md) for the exact candidate and local evidence.
The owner has confirmed that playback works perfectly with the updated walkthrough
and tested FFmpeg build. Continue the remaining manual checks. Do not mark the
whole walkthrough or platform/release acceptance complete from this fix.

## Clean editor integration and two runtime fixes — 2026-09-11

The combined/production checkpoint was reviewed and committed as `9779e38`.
The next [native editor integration pass](editor-workflow.md) then found and fixed
progress JSON parser noise and unwanted import of retained captures inside the
project. New job folders receive `.gdignore`; unavailable JSON remains pending
without parser errors. Runtime changes are limited to `job_io.gd`, `pipeline.gd`
and the panel's output preparation.

The final 0.8.0 package at
`.godot360/clean-editor-fixes/final-reviewed/candidate.zip` has SHA256
`e3ed1dc5053a91e9645d4796702516f67b23ba892c4f469685be5648ea5982bc`.
It rebuilds identically, passes 1,033 headless/failure checks, 44 actual-editor
checks across two processes and three real Windows sharing-lock controls. Full
decoding checks 270 delivery frames and the 440/660 Hz stereo channels. All 154
original capture files remain unchanged after restart and recovery; zero import
sidecars replace the baseline's 158. See [validation](validation.md) for exact
source mapping and excluded development pilots. Creative scenes and recipes
were not edited.

Continue with actual UI navigation and subjective delivery review when the
desktop helper can bind Godot, and native Linux/Mac GPU coverage when hardware
is available. The automated pass does not close those acceptance requirements.
The reusable preparation command can open an isolated scene for the private
walkthrough. The source/package audit and all large evidence remain under
`.godot360/clean-editor-fixes/`. No public publication or version bump was made.

## Production workload milestone — 2026-09-11

Checkpoint review on 2026-09-11 confirms the current package inventory matches
the retained production candidate (236 members, SHA256 below). Repository
hygiene passes for 467 files, 566 local links and 30 media hashes; all seven
guard tests and `git diff --check` pass. The combined and production increments
are checkpointed together. Next work is the clean private editor walkthrough.

Completed the [Forward+/Mobile 4K/8K review](production-performance.md): four
one-minute native Windows / 4.7.2 / RTX 3060 Ti exports, 7,200 source and decoded
frames, all delivery/frame/audio/history checks passing. Five short probes,
sampled CPU/GPU/system memory, time/storage forecasts and controlled capacity
failures establish practical budgets. The full 8K encodes reach about 13 GiB of
resident process memory; short-probe RAM cannot establish a longer job's budget.
Forward+ 8K uses disabled MSAA after a 4× probe showed substantial shared GPU
memory use. Other sustained profiles retain 4×. These settings and the single
machine/one-minute scope are explicit in the guide.

Capture/encode capacity failures behave correctly, and a full 4K recovery passes
all 1,800 decoded frames and audio without changing any original capture file.
The existing 150-frame endurance regression passes. The 236-member package
rebuilds identically and passes 1,025 headless/failure checks; SHA256
`0c5bc4da8b41cf16030317ba4dd44d0c68a6cf0ab130a9a19db18497d94cbdda`.
The source/asset/package audit is `.godot360/production-review/audit.json`.
Runtime, user settings, recipes and creative scenes remain unchanged.

These and the preceding combined-effects changes are checkpointed locally,
with version 0.8.0. Next: a private clean-installation walkthrough through
existing-scene export, delivery review, reopening and recovery. Native Linux/Mac
GPU coverage and final support/candidate decisions remain open. Preserve the
large retained evidence; do not rerun the completed matrices without cause.

## Combined-effects milestone — 2026-09-11

Closed the successful LightmapGI hosted evidence record, retaining all three
artifacts and matching the bake/source/package hashes. Then completed the
[combined-effects review](combined-effects.md): 16 native Forward+/Mobile clips,
2,304 source and decoded frames, twelve accepted normal cases and four rejected
lighting/history controls. Continuous camera motion, the frame-72 cut, lit
intersecting transparency, probe lighting and long per-view history all pass.
The capture runtime needed no change. The exact 230-member package rebuilds
identically and passes 1,025 4.7.2 headless/failure checks; its hash is
`c5b6a7dd1dfddcc9a085da05c27f107c7f4b924610010c456e13f4e6f114845f`.
See [validation](validation.md) for source mappings and limits.

These new changes are local and uncommitted; the Combined rendering workflow is
prepared but has not run remotely. Next: representative Forward+/Mobile 4K/8K
workloads with GPU/system memory, timing, storage and audio measurements. The
native platform and final delivery/1.0 gates remain open.

## Temporal and LightmapGI checkpoint review — 2026-09-10

Reviewed both previously uncommitted milestones, including the retained native
reports, package manifests, comparison images and runtime changes. A fresh package
rebuild matches the LightmapGI ZIP exactly:
`9308a68209faede3a7444148bc42bb6b25a1eac4a5f6bf40f107f71a176a3802`.
The saved 3,075 LightmapGI and 3,208 temporal package checks remain valid for their
recorded snapshots; no large native matrix was rerun for documentation/CI changes.

Previous commit `3fbac56` had an overlooked Combined appearance failure:
run `34498588684` lost its Godot download connection before package/tests began.
The appearance and new temporal/lightmap workflows now retry connection errors
with bounded connection and transfer timeouts. Local actionlint passes. Work is
pushed through `739cf95`; repository, temporal, appearance, characters, particles
and desktop-platform CI pass on their recorded commits. LightmapGI's full hosted
rerun also passed; its three artifacts were retained and source/package-matched
on 2026-09-11 (12 clips / 864 decoded frames, three rejected controls). See the
latest validation entry. Earlier "uncommitted" notes below record the state at those sessions.

The new graphics-error guard also exposed the old Mobile tint fixture's invalid
storage-image binding. Its earlier tint-preservation claim is withdrawn. The
corrected fixture uses sampled input/copy-back and proves visible red/blue tint
against a baseline on all six faces. Nine native exports pass; desktop CI includes
both camera and world compositors. The current package is
`.godot360/checkpoint-review/ci-timeout.zip`, hash
`d2f4a810c722927a35e4f7189c2b151d3de7b87412877ada2bc93ca3a840f89b`.
See [validation](validation.md) for the tested package hashes and failed attempts.

The next work at this checkpoint was the [bounded combined-effects fixture](combined-effects.md),
then measured Forward+/Mobile 4K/8K workloads. Native Linux/Mac GPU coverage,
private usability/delivery review and the exact 1.0 candidate remain open.

## Saved LightmapGI — 2026-09-10

Completed the next bounded rendering milestone: sixteen 72-frame clips on native
Windows / RTX 3060 Ti / Godot 4.7.2, with Forward+ at zero/12.5% borders, Mobile
at 12.5%, and Compatibility at zero. Twelve normal clips pass; four missing-map
controls are correctly rejected. All 1,152 source and decoded frames are reviewed.
A real saved editor bake covers ten static receivers and 396 probes;
independent-world references check the moving object, camera cut and delivery.
The negative control caught an early reference-world wiring error, now corrected.
The addon capture runtime needed no change. See [the guide](lightmap-capture.md)
and the newest [validation entry](validation.md).

Final ZIP: `.godot360/lightmap-review/package/reviewed.zip`, SHA256
`9308a68209faede3a7444148bc42bb6b25a1eac4a5f6bf40f107f71a176a3802`.
The 227-member package rebuilds identically and passes 3,075 headless/failure
checks across 4.5.1/4.6.3/4.7.2. Native LightmapGI evidence is limited to 4.7.2.
The audit maps every final review to the package; failed development attempts are
retained. New CI passes local actionlint but has not run remotely. All changes,
including the previous temporal milestone, remain local and uncommitted.
Next: selected combined rendering cases, then representative heavy 4K/8K workloads.
Preserve creative scenes, masters, saved settings and the existing local changes.

## Temporal rendering and graphics failures — 2026-09-10

Completed selected TAA/FSR, persistent camera/world history and VoxelGI reviews:
22 complete clips, 1,584 source/decoded delivery frames, three rejected history
controls, and one additional graphics-error job correctly stopped before encoding.
The pipeline now rejects engine rendering/backend errors despite a complete frame
count. Mobile's tested compositor authors 4x MSAA and uses a writable per-view
texture with sampled input/copy-back. See [the guide](temporal-capture.md) and
[the newest validation record](validation.md) for limits and failed experiments.

Final local ZIP: `.godot360/temporal-review/package/reviewed.zip`, SHA256
`ef7aeb5e57113032a382c5e7f9c4372d84e75b76590c6efaf5d55b41b5c27a77`.
It rebuilds identically and passes 3,208 checks (1,158 full 4.7.2; 1,025 each
4.5.1/4.6.3 headless/failure). The audit verifies the native source mapping.
Work remains uncommitted; no hosted execution or publication is claimed. The
new Temporal rendering workflow passes local actionlint. Preserve these changes.
Next bounded target is baked LightmapGI, followed by remaining combined cases
and heavy production workloads; the other 1.0 acceptance work remains open.

## Complex particles and LUMEN — 2026-09-10

Completed the previously interrupted smoke/trail increment and added the
[LUMEN orbital-observatory demo](lumen.md), following the owner's request to
continue development and build useful creative demonstrations.

Native trails: all four cases on three renderers pass (12 exports, 864 frames),
including pause/camera cuts and disabled-feature controls. Compatibility is
explicitly unsupported for trail history. The 48 retained smoke exports pass;
their runtime differs only by the later two-line trail warning, verified by the
audit. The exact 163-file addon package rebuilds identically and passes 3,018
headless/failure checks across Godot 4.5.1/4.6.3/4.7.2. Package SHA256:
`2f4482e7da16d46ec89682d0d96a63b4e6510b2c6cea8b57f2bc5d6b67be1162`.
See `.godot360/particles-complete/audit.json` and the newest validation entry.

LUMEN supplies a 24-second Forward+ 4K recipe, procedural observatory, native
light trails, point-facing vapor, original shaders/music, isolated render helper,
curated preview generator and an allowlisted loopback spherical player. The
final output is `renders/lumen-4k-final/`. Initial drafts remain separate; the
visual review replaced the first sky background before final delivery. Existing
UMBRAL/THRESHOLD scenes, masters and saved studio settings are preserved.

Next: advanced rendering support boundaries (temporal effects, GI, compositors),
then representative heavy 4K/8K workloads and remaining native/private reviews.
The demo is a useful composed scene, not completion of the production endurance
gate. Hosted complex-particle validation belongs to the private checkpoint;
no public publication or version bump is authorized by this increment.

## Head-look modifier and nested attachments — 2026-09-09

Completed the requested bounded head-look/nested milestone. See
[the supported setup and image](modifier-capture.md) and the newest
[validation entry](validation.md). A custom stateless SkeletonModifier3D uses
Manual sampling after the imported animation, including warmup. A nested mount
is updated from the upstream final-pose signal. The native skin and all six
capture cameras match independent raw-glTF/CPU references, including the cut;
the existing addon synchronization needed no runtime fix.

Native Windows 4.5.1/4.6.3/4.7.2, Compatibility/Forward+/Mobile: 26 exports and
1,560 source/decoded frames, including six rejected timing controls. Zero warmup,
12.5% borders and a textured 60 FPS case pass. Package checks pass 2,985 contracts
across three engines, including two nested levels and external attachments.
`.godot360/modifier-review/audit.json` records exact source matching and protected
hashes. The 154-file package rebuilds identically; SHA256
`8f0a2dd5a4b0cf6906fe41a6eb5c8ad10dcd51aace4c27a3a949b016d416b788`.

The Imported characters CI matrix now covers base animation and nested head look
on all three renderers. Implementation `2f4448f` is pushed privately. Hosted
characters `34371376287`, platforms `34371375916` and appearance `34371376090` all
pass without retry. Characters adds 33 exports and 15 rejected timing controls;
Linux passes 1131 package/workflow checks, Mac 997 headless checks, and the
existing appearance/renderer/particle suites pass. All ten hosted package records
match the local ZIP; `hosted/verified.json` retains the audit. Actionlint passes.
Earlier hosted evidence below remains valid for its own source revision.

Next: complex particles (smoke, billboards, trails and moving emitters), advanced
rendering, heavy 4K/8K workloads, native Linux/Mac, clean installation-to-delivery
review, then freeze/validate 1.0. General/stateful solver chains remain outside
the newly tested bounded setup. Continue privately; no public release is authorized.

## Imported animated character — 2026-09-09

Completed the local imported-character milestone after checkpointing the prior
work. See [the illustrated guide](imported-characters.md). A licensed CesiumMan
GLB exercises normal scene import, 19-joint animation, weighted skin, an external
head-attached camera with a boom and a frame-30 cut. Raw-glTF CPU references do
not read Godot's resulting poses. No addon runtime correction was needed.

Native Windows evidence covers 4.5.1/4.6.3/4.7.2 Compatibility and 4.7.2 Forward+
and Mobile: 21 exports / 1,260 source and decoded frames, including four controls
that are required to fail. A textured 60 FPS case passes too. Reference imports
disable lossy optimization/compression/LODs and match the import bake rate to
export FPS; both choices resolved measured source-vs-import discrepancies.

Final ZIP `.godot360/imported-character/final/candidate.zip` has SHA256
`3a66b1f853e6f0494a56020b63731da1c7717f3af02b38183ea8feecf558bf31` and rebuilds
identically. It passes five rendered Compatibility jobs. The preceding package
passed 739 headless/failure checks; the exact difference is documented in
validation. `audit.json` records native source matching and protected hashes.

Implementation `1a23a0c` is pushed privately. Hosted Imported characters
`34366471485`, Desktop platforms `34366473025` and Combined appearance
`34366471526` all pass. The character suite adds 15 hosted exports with six
rejected timing controls. Desktop platforms passes 875 Linux / 741 Mac checks,
three skeletal exports, eight renderer cases and 14 particle exports; both
appearance lanes pass nine clips plus re-encoding. All seven hosted package
records match the exact final ZIP. Mobile's character job alone was restarted
after very slow Ubuntu downloads, before tests; source stayed unchanged.
`final/hosted/verified.json` records the evidence. Actionlint passes for all three.

Next bounded engineering task: a common skeleton modifier/IK case and nested
skeleton attachments, using the imported fixture now established. Then complex
particles and the remaining rendering/production/hardware reviews. Keep the
support boundary explicit and continue privately; no public release is authorized.

## Appearance/particle checkpoint — 2026-09-09

The appearance and particle startup changes are committed as `d37a786` and pushed
to private `origin/main`. Hosted Desktop platforms `34363716312` and Combined
appearance `34363715991` both pass without retry. Linux passes 875 package/workflow
checks, three skeletal exports, eight renderer cases and 14 particle exports;
macOS passes 741 headless checks. Each new appearance lane passes nine clips and
its re-encode. Both platforms rebuild the prior accepted `ad97a690…` package.
Reports are under `.godot360/imported-character/checkpoint-ci/`; see validation.
The earlier "uncommitted/unpushed/hosted pending" notes below are historical.

## Particle startup and timing — 2026-09-09

Completed the next ordered local increment. `capture.gd` disables realtime physics
jitter compensation in the worker, fixing incorrect opening simulation deltas and
the repeated matching-rate particle step. It also queries Compatibility CPU
automatic bounds after buffer submission, fixing the missing opening without
overwriting authored bounds or stepping the effect. All earlier appearance work
remains in the working tree. See [particle capture](particle-capture.md) and the
latest [validation entry](validation.md) for exact scope and negative controls.

The native matrix passes 66 particle exports across Windows Godot 4.5.1/4.6.3/4.7.2,
Compatibility, Forward+ and Mobile, including selected 24/30/60 FPS combinations.
Automatic CPU bounds match exactly at both two and eight warmup frames on all
three engines. Source/decoded references, fixed process deltas and authored
particle settings are checked; existing image thresholds are unchanged. Three
Motion exports at 24/30/60 FPS pass geometry, flash timing and audio cues. Headless
contracts pass 1,875 checks. Zero-warmup GPU startup remains a documented exclusion;
the simple-effect contract uses at least two warmup frames.

All evidence is under `.godot360/particle-startup/`; `audit.json` records package,
runtime/fixture matching and protected user-file hashes. Accepted ZIP:
`accepted/candidate.zip`, SHA256
`ad97a690a17c6859894c676b49437c4c53ee6b50a28c35f1d29d6d9273bdc2e7`.
The headless package differs only in the reviewer, renderer guide and manifest;
both rebuild identically. No version bump, commit, push or publication was done.
The expanded Linux particle CI passes actionlint but has not run hosted.

Next: representative imported characters, modifiers/IK, nested attachments and
complex particles/effects. Continue toward the production workloads and remaining
native hardware/private workflow reviews after those fixtures. Keep the declared
scene contract explicit rather than claiming arbitrary effect determinism.

## Combined appearance review — 2026-09-09

The user approved starting the ordered 1.0 roadmap. This increment completes the
local combined exposure/border pass and defines consistent 1.0 exposure as authored
values, including animation. Shared automatic spherical adaptation is deferred
beyond 1.0; Scene defaults and native per-face metering remain unchanged. See
[the illustrated guide](combined-appearance.md) and the new [validation](validation.md)
entry for metrics, exact package snapshots and limitations.

The new portable reviewer covers nine clips per renderer plus re-encoding, with
full decoded-frame counts, authored exposure oracles, glow-disabled observations,
and unlit geometry/color controls. Forward+ and Mobile pass natively on Windows
4.7.2 / RTX 3060 Ti / Vulkan. Borders reduce the measured glow discontinuity by
94–97% across the tested crossings; halo shape and other view-dependent effects
remain documented limits. Source scenes, recipes, main project and addon runtime
code are unchanged by this work.

The repeated Forward+ export exposed overly strict decoded-MAE acceptance in the
new reviewer. Isolated one-level source rounding changes coexist with decoded
CRF differences up to 0.863 RMS. The revised test adds a maximum-one-level source
constraint and uses a maximum-one-level decoded RMS bound, retaining the rejected
report and the original media. The incorrect automatic-exposure control fails.

Accepted package: `.godot360/appearance-review/accepted/candidate.zip`, SHA256
`401e5c6c202c6d9fc33464295d7f91545ec9edae3ce12106c492e729a84ce130`.
The earlier full package matrix passes 2,217 checks across three engines; only the
Python reviewer's acceptance calculation and manifest differ in the accepted ZIP.
Rebuilds are identical. Native datasets, reviews, profiles and audits remain under
`.godot360/appearance-review/`. The new separate software-Vulkan CI workflow passes
actionlint but has not yet run on hosted CI. Changes remain local; no commit,
push or public publication was performed during this increment.

Next work is the known particle opening/fixed-step behavior, then imported
characters, complex particles and the remaining temporal/GI/compositor coverage.
The authored Visibility AABB workaround remains the accepted Compatibility CPU
particle guidance; it is not an automatic-bounds fix. Continue privately toward
1.0, with native hardware and final delivery review still open.

## CPU visibility bounds follow-up — 2026-09-08

Implementation `17d0abc` is pushed to private `origin/main`, following `8b16092`.
Hosted run `34255433218` passes: 875 Linux package/workflow checks, three skeletal
exports, eight software-Vulkan appearance cases, nine particle exports and 741
Mac headless checks. Both platforms reproduce the exact package hash below.
The initial run was superseded during Linux software-Vulkan checks; final CI
passed without retry. The follow-up found an authored workaround for the measured
Compatibility CPU first-frame gap: set a
conservative **Visibility AABB** covering the full effect. All 60 frames then
match the analytic mesh reference exactly on Windows 4.7.2. The fixture now uses
explicit bounds for both CPU and GPU emitters; `--automatic-bounds` preserves the
failing case as a visible observation. The addon preserves authored bounds and
narrows the Compatibility note to automatic bounds, with concrete guidance.

The final follow-up ZIP is `.godot360/particle-review/bounds-final/candidate.zip`,
SHA256 `d396af57e4ae9002d3831e88c32874b43cdd1e9622073f5739620a77c93d7c22`.
Its exact unpacked source passes nine Compatibility exports, including CPU/GPU
appearance and the four mode cases. CI now covers both particle types with
explicit bounds. The earlier `--gpu-only` limitation below describes the initial
investigation, not the current fixture. See [validation](validation.md) for all
snapshots and [particle capture](particle-capture.md) for the authoring contract.
The explicit-bounds CPU case also matches all source/decoded frames exactly on
4.5.1 and 4.6.3. Keep per-review APPDATA/LOCALAPPDATA isolation in standalone
Windows helpers; omitting it caused a 4.5.1 startup/log-directory harness failure.
Automatic-bound startup remains open; this is an authored workaround, not an
automatic rewrite of an arbitrary effect's culling bounds.

## Particle capture and authored processing modes — 2026-09-08

Continued privately from clean `f5d9198`. `capture.gd` now preserves the authored
scene root process mode through warmup and honors later mode changes. Previously
it forced `INHERIT` on every frame, activating disabled scenes and undoing pauses.
Four rendered mode tests fail against the old worker and pass with the fix.
Read [particle capture](particle-capture.md) and the new [validation](validation.md)
entry for precise coverage and package snapshots.

CPU/GPU constant-velocity particles pass analytic PNG/decoded MP4 comparisons in
Forward+/Mobile; GPU particles pass Compatibility on 4.5.1/4.6.3/4.7.2. Use eight/
ten warmup, Fixed FPS 0 and the other documented fixture settings for that claim.
**Compatibility CPU particles still miss the first delivered frame**, even at
eight warmup. The failed report is retained. `--gpu-only` explicitly narrows the
appearance lane and keeps CPU processing-mode cases. Zero/two warmup and separate
fixed-step timing have further observed startup differences. Scene notes flag
short warmup and Compatibility CPU startup; authored particle settings stay intact.

`tests/particle_review.py` and its fixture ship in the package. Linux CI adds the
GPU Compatibility comparison and four processing-mode cases. Final package is
`.godot360/particle-review/accepted/candidate.zip`; its SHA and the distinction
from the 3,089-check full regression snapshot are in validation. Local evidence,
negative controls and helper scripts remain under `.godot360/particle-review/`.
The authored scenes/settings/recipes/master hashes remain preserved.
That package passes 739 further checks plus eight rendered Compatibility jobs,
including its scene notes. Local package checks total 3,828. Its initial hosted run
was superseded; the successful final follow-up CI is recorded at the top.

Next work includes resolving the measured particle startup behavior, broader
particle/character/temporal fixtures, shared adaptive exposure policy, representative
Forward+/Mobile 4K/8K cost and endurance, native Mac/Linux hardware workflows and
the final private walkthrough. No public release is authorized.

## Skeletal camera synchronization — 2026-09-08

Implementation `f9e72f4` is pushed to private `origin/main`, following clean
`0a86e29`. Local validation and hosted run `34246410434` pass: 875 Linux package/
workflow checks, a three-export skeletal comparison, eight software-Vulkan
appearance cases, and 741 Mac headless checks. The Linux retry used unchanged
source after the first attempt was cancelled during slow Ubuntu mirror downloads;
no addon tests had started in that attempt. Both hosted platforms rebuild the
exact final package at `.godot360/skeletal-review/final/candidate.zip`, SHA256
`103f44f37b570a6038f090ce4e0e9f87ef34fae27465eb36c263478253303e87`.

The new fixture found a real one-frame delay for a Camera3D under BoneAttachment3D:
the skin reached the sampled pose before capture copied the updated attachment.
`capture_rig.gd` now queues camera synchronization after frame sampling, allowing
Godot's pending skeleton updates to finish before transform notifications/drawing.
Initial build still synchronizes immediately for its callers. Sampling, authored
poses, saved recipes, six views and the renderer remain unchanged.

Read [the illustrated result](skeletal-capture.md) and the expanded
[authoring contract](../addons/godot360/AUTHORING.md). Cuts mean changing the selected
camera transform; switching `current` cameras does not change capture selection.
TAA histories are retained. Particles, imported character pipelines, modifier/IK
chains, ragdolls, nested attachments and long temporal histories remain open.

All six native rendered skeletal cases pass: Compatibility on 4.5.1/4.6.3/4.7.2,
4.7.2 Forward+ with/without TAA, and 4.7.2 Mobile. They include parent/external
attachments, zero/eight warmup and zero/12.5% borders. The 128 new headless checks
pass with the fix and fail 124 checks against the old rig. The reviewer compares
all PNG/decoded MP4 frames with independent camera and CPU-skin references.
The Python reviewer, headless checks and fixture are in the candidate package;
CI now includes an actual Linux external-attachment render as well.

Evidence and helper scripts live in `.godot360/skeletal-review/`. The full package
matrix passes 4,360 checks; the final package passes another 739 headless checks.
All three ordinary motion/color/audio reviews pass. Old/new direct-camera images
match exactly in 240 source/decoded frames, and re-encoding preserves source
hashes/settings. Four isolated short captures take 4.4–5.7 s; they do not establish
a speedup or production overhead. A deliberately one-frame-late skin fails the
strengthened foreground metric, while all six accepted cases pass it. The final
ZIP differs from the full-matrix ZIP only in that Python metric; runtime code is
identical. See [validation](validation.md) for exact counts and limitations.
Run `audit.py` to recheck protected hashes, links and rendered summaries. No local
test jobs remain after this validation. Publication still requires separate
authorization. The next work remains complex scene fixtures, shared adaptive
exposure policy, production Forward+/Mobile 4K/8K cost
and endurance, native Mac/Linux hardware workflows and the final private review.

## Consistent authored exposure — 2026-09-08

Implementation commit `afcfbc5` is pushed to private `origin/main`. Its hosted run
`34241199252` passes 747 Linux package/workflow checks plus eight software-Vulkan
appearance cases and 613 Mac headless checks. Both rebuild the exact final package
hash recorded in validation. The documentation follow-up records this result;
it changes no packaged code or assets.

Continue private development toward 1.0. The starting tree was clean at `bef3b9e`;
its hosted Linux/Mac run `34235851891` has now passed. This increment adds
**Advanced → Capture exposure → Fixed (authored)**. Scene remains the default for
new and legacy recipes. The worker disables auto exposure on its own copy of the
effective camera/world attributes, follows authored exposure/DOF/physical settings
and runtime attribute replacements each frame, and leaves source resources intact.

The [illustrated comparison](exposure-consistency.md) shows the reason: independent
Forward+ metering produces large brightness blocks. Fixed matches a scene authored
with auto exposure disabled. It does not freeze the editor's metered brightness or
provide shared automatic spherical adaptation. Lighting cuts remain authored cuts.
Read the [supported behavior](../addons/godot360/RENDERERS.md#capture-exposure) and
the new [validation entry](validation.md) for accepted combinations and limitations.

Recipes/settings persist `capture_exposure_mode`; changed modes invalidate sample
estimates. Re-encoding retains original policy/evidence and source hashes and rejects
conflicting requests. The capture adds no viewports or readbacks and records CPU
attribute synchronization time. `tests/exposure_checks.gd` joins every package/CI
contract run; `tests/exposure_review.py` supplies rendered before/after, oracle,
legacy, decoded-frame and re-encode comparisons from disposable projects.

Evidence is under `.godot360/exposure-review/`, with the final frozen package at
`final/candidate.zip`. The full matrix passes 3,720 checks; the final panel adds
129 checks. Appearance reviews inspect 2,880 source/decoded frames, and motion
reviews inspect another 900 of each. Fixed matches its authored oracle exactly;
the accepted Mobile legacy repeat uses the documented decoded-pixel tolerance.
The final package differs from the full matrix only in a panel hint, the Python
reviewer's pixel fallback and changelog text; capture code is identical.
Standalone CPU synchronization is about 0.024 ms/frame, but two short timing pairs
average 10.2% more whole-capture time than the authored oracle. Keep that measured
cost and timing variation visible when planning production profiling. Authored
scenes, saved settings, the THRESHOLD recipe and film master remain preserved.
Next 1.0 work is broader animated/temporal scenes, representative Forward+/Mobile
4K/8K endurance, native Mac graphical and Linux hardware-GPU workflows, and a
private final workflow/delivery review. Define the automatic-exposure support
boundary explicitly; shared HDR metering remains open. No public release is authorized.

## Private 1.0 development and capture borders — 2026-09-08

The owner explicitly rejected pausing at a beta gate: keep building and testing
privately, with no public release until 1.0 is ready. Use
[release readiness](release-readiness.md) for current priorities. Earlier beta
milestones and test records are historical; independent feedback is useful but
does not block local work. The previous visual documentation commit was pushed
as `0c3cb24`; both hosted Linux and Mac jobs passed.

This increment implements **Advanced → Capture border per edge (%)** (0–25%,
default zero), expanded face projections with unchanged core pixel density, and
smooth blending of valid overlaps at edges and three-face corners. Settings and
recipes persist the choice, estimates invalidate on change, and retained captures
keep their original projection on re-encode. Invalid saved values fail safely.
The shader's zero-border branch retains the original projection/assembly path.

[Before/after images](capture-borders.md) show actual Forward+/Mobile tests.
The moving-glow fixture measures 98–99.6% less boundary discontinuity, while
no-glow frame differences remain below 0.001 mean RGB on the 0–255 scale.
Borders cost 56.25% more face pixels at 12.5%. Halo shape, separate auto-exposure
metering and arbitrary screen/temporal effects remain limits.

The [validation record](validation.md) distinguishes the 3,345-check full Windows
matrix snapshot from 531 focused checks on the final package after saved-input
hardening and FOV wording corrections. All packaged render code except the
planner validation and warning text matches that full matrix. The final ZIP is
under `.godot360/seam-review/accepted-final/`; all evidence remains local.
That exact final package also passes five nonzero-border analytic motion exports:
900 source and 900 decoded frames, cue timing within 10 ms and all five re-encodes
with unchanged source hashes/settings. The expanded Advanced control was visually
checked at 1100×600. Source project/settings, recipe and film master are unchanged.

Next implementation priorities are exposure consistency, complex animated scene
fixtures and representative Forward+/Mobile 4K/8K endurance. Native Mac graphical
exports and Linux hardware-GPU validation still require the target machines;
continue independent local work while those remain open. This is still internal
0.8 development, not a public release or a claim that all 1.0 gates are complete.

## Visual documentation — 2026-09-08

The user asked for current project status and documentation that shows what the
tool can do immediately. The root README now opens with a real eight-second
THRESHOLD GIF, a small complete film with sound, and a current panel screenshot.
[Visual tour](showcase.md) explains the four worlds, panorama versus viewing
direction, editor workflow and UMBRAL's interactive-to-film distinction.
[Documentation index](README.md) groups the existing guides by user task.
The quick start, addon reference, playback and example guides are illustrated.

`tools/build_docs_media.py` derives repository previews from existing films;
`tools/capture_docs_panel.gd` captures the actual panel in a disposable project.
Read [media provenance and regeneration](media/README.md). The packager now includes
the portable screenshot and its `.gdignore`; GIF/MP4 previews stay in root docs.
Mac platform wording and the addon reference's FFmpeg install command now match
the recorded headless CI evidence and full-codec playback requirement.

Docs/media/package verification passes; see the new [validation entry](validation.md).
Addon runtime code, original film, user project/settings and selected recipes are
unchanged. Work remains on the unreleased 0.8 baseline. This pass prepares local
changes and does not publish a release. Independent creator feedback, graphical
Mac/Linux hardware validation and glow/exposure seams remain the next product work.

## CI follow-up — 2026-09-08

The user noticed failed GitHub Actions runs and authorized fixing them. The Mac
runner's basic Homebrew FFmpeg lacked `libtheora`; Linux passed on both `a037209`
and `85a924a`. Commit `203cd56` installs `ffmpeg-full`, puts its keg-only `bin`
first on CI PATH, and checks an actual Theora/Vorbis encode before package review.
Mac setup/playback documentation now tells users to select the full tool paths.
No addon runtime or test contracts changed. The corrected hosted Mac lane passes
505 checks on macOS 15.7.9 / Apple Silicon / Godot 4.7.2, including playback and
recent exports. Linux passes 639 package/workflow checks plus eight software-Vulkan
appearance cases. Both jobs in run `34169487525` are green. Mac evidence remains
headless, not graphical Mac capture validation.
See the latest [validation entry](validation.md) for the complete hosted result.

## Current pass — 2026-09-08

The user authorized another autonomous increment, verification, commit and push
to `origin/main`, without publishing a release. Starting tree was clean at
`a037209`. The chosen increment is **Recent exports**: a project-local history
of up to 12 launched/opened jobs, with saved state, scene/video details, Open and
Forget. `recent_exports.gd` owns the list and bounded metadata reads; the panel
persists it in settings and uses the existing playback/recovery flow when opening.
The previous last-folder preference migrates once. Forget never deletes files or
resurrects an entry on startup. See the [quick start](../addons/godot360/QUICKSTART.md).

Focused validation passes **201 checks**: 33 history checks on each Windows
engine (4.5.1/4.6.3/4.7.2), another 33 in graphical 4.7.2, 37 existing usability
checks and 32 actual export/playback workflow checks. The 4.7.2 tested runtime
matches the frozen package byte-for-byte; its fresh unpacked source rebuilds the
same ZIP. See `.godot360/recent-validation/summary.json` and the new entry in
[validation](validation.md). The user's project, Main / 4K / 12-second settings
and saved planning sample remain unchanged. Full pipeline checks reuse the
accepted 1,800-check playback baseline below; they were not rerun for this UI change.

History does not scan older export folders, relocate moved jobs, confirm live
coordinators while browsing, or resume partial capture. Independent beta feedback,
native Mac/Linux hardware validation, glow/exposure seams and representative
Forward+/Mobile endurance remain open. This pass adds no renderer, platform or
YouTube evidence and retains the unreleased 0.8 version baseline.

## Previous pass — native playback, 2026-09-08

The user authorized continued experimental work and delegated the next priorities.
Native spherical video playback and visible scene notes are the chosen increment.
`playback_review.gd` owns cancellable local review-copy preparation, cache reuse,
native Theora playback, seeking, pause/replay and audio. It reads the verified MP4;
capture and delivery behavior are unchanged. Read
[Playback](../addons/godot360/PLAYBACK.md) for the new optional codec dependencies,
2K / 30 FPS review limit and cache behavior. Independent beta and full-resolution
delivery review remain outstanding. Recent exports and rendering experiments are
subsequent work, not implemented by this pass. See the latest validation entry.

The final exact package passed 1,800 checks (600 each on Windows Godot 4.5.1,
4.6.3 and 4.7.2). Separate Forward+/Mobile playback checks and an actual-editor
playback/audio/seek run pass. THRESHOLD's corrected 2K review copy takes about
3 minutes 25 seconds to prepare and occupies 37.10 MiB; later reviews reuse it.
Pixel tests caught and fixed a BT.709-to-sRGB preview conversion error. All evidence
is under `.godot360/playback-validation/`; the final package hash and exact limits
are in `docs/validation.md`. Work remains unreleased on the 0.8 version baseline.

Updated 2026-09-07 for project renderer preservation and native renderer validation,
following Linux/macOS preparation, dependency onboarding and first-export usability. A fresh session can begin by
reading this file, the linked guides, and the relevant current source/tests.

## Latest product direction

The latest pass implements **project renderer/driver by default**, with explicit
recipe/UI overrides and strict requested/actual worker checks. Older source
always forced Compatibility; describing Forward+/Mobile as merely unvalidated
was misleading. Read [renderer behavior](../addons/godot360/RENDERERS.md) and the
new top entry in [validation](validation.md) before relying on historical counts.
`renderer_policy.gd` owns resolution, fallback diagnostics and planning signatures.
Capture settings are carried into delivery reports and preserved for re-encodes.
Native Windows Vulkan/D3D12 and Linux software-Vulkan visual tests exist; native
Mac and Linux hardware GPU validation remain pending. The user's uncommitted
platform/onboarding work and local scene/recipe/settings have been preserved.

The accepted workflow matrix totals 3,662 checks: Windows Forward+/Vulkan on
4.5.1/4.6.3/4.7.2, Windows Mobile/Vulkan and Compatibility/OpenGL on 4.7.2, and
Linux 4.7.2 Forward+/Mobile with WSLg software Vulkan. Separate evidence includes
45 appearance exports and all 180 source/decoded motion frames per renderer with
audio onset within 0.71 ms. See `.godot360/renderer-review/summary.json` and the
validation record for exact frozen packages and limits. A real Windows file-lock
failure led to a 500 ms JSON replacement retry, verified with transient and
permanent locks. Failed development packages are retained but not counted.

Visible glow cuts and large auto-exposure differences across faces remain.
Prioritize shared exposure/guard-band investigation, Mac/Metal and Linux hardware
GPU validation, then representative Forward+/Mobile 4K/8K endurance, complex
temporal scenes and stateful compositors. No new GDExtension is justified by these
results. Runtime changes require appropriate new checks; final documentation-only
edits do not require repeating the accepted matrix.

Before this renderer pass, the user requested native Linux support and ideally macOS. This
supersedes the older Windows-only platform boundary below. The same addon now
resolves native tool paths consistently for setup/coordinator/capture, checks Unix
execute bits and finds Homebrew/MacPorts installs from GUI-launched editors.
The README and packaged [Platform setup](../addons/godot360/PLATFORMS.md) cover
downloads and installation for all three platforms. `tests/platform_checks.gd`
tests native child processes and Unix filesystem behavior. CI prepares a full Linux
software-rendered review and a Mac headless lane; hosted runs and Mac captures are
not yet claimed. See the latest [validation record](validation.md) for exact evidence.

The user chose Godot creators exporting their existing 3D scenes as the initial
audience and explicitly approved implementing the proposed first usability pass.
This supersedes the older instruction below to hold feature work while awaiting
beta feedback. The agreed pass covers current-scene selection, camera discovery,
simplified controls, readiness checks and onboarding documentation.

`studio_layout.gd` builds the grouped panel; `studio_panel.gd` retains job/recipe
coordination. `scene_inspector.gd` reads inherited/instanced saved-scene metadata
without instantiating nodes. `setup_check.gd` runs bounded asynchronous FFmpeg and
FFprobe checks. The editor plugin supplies current-scene and save callbacks.
Use current scene saves a named scene, and check/render save it again if selected.
Runtime-created cameras retain the manual path escape hatch. The capture pipeline
and source-frame contracts are unchanged. Read the portable
[quick start](../addons/godot360/QUICKSTART.md) for the current interface.

The README now directs users to their first export. Interactive installation
details are in [umbral.md](umbral.md) and developer commands in [testing.md](testing.md).
The version remains the 0.8 baseline with unreleased source changes; original
candidate ZIPs are unchanged. At that point full spherical playback and a
recent-export view were subsequent work; the 2026-09-08 pass above adds playback.

The earlier usability package passed 1,443 checks (481 per engine) on 4.5.1/4.6.3/4.7.2,
including clean imports, 37 usability checks, actual exports and full recovery/
storage workflows. It reproduced byte-for-byte from its own unpacked source.
See `.godot360/usability-review/review/package-review.json` and the latest
[validation record](validation.md) for hashes, screenshots and six additional
actual-editor save checks. The user's Main / 4K / 12-second recipe and planning
sample remain selected. No further backend regression run is needed without new
changes or a concrete unresolved concern.

## Purpose and working agreement

Build an original, integrated Godot-to-YouTube mono 360 addon with portable recipes,
documented authoring, reliable export, and eventual community use. Conversation may
be English or Spanish; all code, comments, UI, and docs must be English. The user
authorized continued development and a GDExtension if measurements justify it.
The user reports viewing THRESHOLD in YouTube and explicitly authorized the project
rename and private GitHub hosting under `blugart-dev/godot360-studio`. This does not
authorize a public release. See [repository/privacy notes](repository.md) and check
the current Git remote/status. The private upload uses a noreply commit identity
and removes an older private-video URL from history. Original commit IDs quoted
below refer to the verified local history backup; the release tags retain their
source chronology. Generated renders, settings/tools and release ZIPs remain local.

Godot project and plugin branding is now Godot360 Studio. The addon now lives at
`addons/godot360`, with `.godot360/settings.cfg` for local settings. Scenes,
recipes, tools, tests and package contents use these paths. Follow the
[migration guide](../addons/godot360/MIGRATION.md) for older installations.
Pre-rename ZIPs and their evidence remain historical artifacts. The earlier
display-name-only rename passed 270 checks; folder migration has separate evidence.

Folder migration passed a full project import, 60 film checks and the 444-check
exact-package workflow on 4.7.2. See `.godot360/naming-review/` for evidence.
The outer local checkout still awaits renaming after the workspace is closed;
the checked local helper is documented in [repository notes](repository.md).

## Current creative production exercise

The user requested a one-minute experience with full creative freedom to explore
the tool's limits. **THRESHOLD** adds four original procedural worlds, spherical
light transitions and a deterministic synthesized stereo score. Read
[the film guide](threshold.md). Open `scenes/films/Threshold.tscn` with F6; F5 still
opens the original installation. The portable recipe is
`export_profiles/threshold-8k.tres`.

The local production job is `renders/threshold-8k/`; inspect its `report.json` and
`.godot360/threshold-8k-media-review/review.json` for acceptance, and
`.godot360/threshold-8k-run/render-review.json` for measured time/storage. The film
source passes 60 absolute-time checks. No addon source or 0.8 release ZIP changed.
The scenes preload together and switch visibility under an opaque veil; this is
not disk streaming or a newly implemented map sequencer. The film remains mono
360, SDR and stereo audio. On 2026-09-07 the user reported that it looks amazing in
YouTube. Record this as positive visual feedback after platform processing, not
as an independently observed test or an itemized navigation/seam/audio/VR checklist.

After media review, the job also contains a 4K browser copy, a 1080p ordinary
perspective preview and a local drag-to-look player. `tools/play_threshold.py`
serves only playback files on localhost:8360. The server is a local preview helper,
not a published site. Source frames and previous exports are retained.

## Implemented milestones

The revised 1.0 route is in docs/roadmap.md: Windows/Compatibility first, storage
and production-resolution evidence, then a clean packaged release candidate,
diagnostics and independent beta feedback, then current YouTube playback review
and explicitly approved publication. Local versioned history is established.
Broader OS support and native code
are not prerequisites for the initial supported release.

- 0.1: six synchronized views, original equirectangular shader, fixed-frame capture,
  Movie Maker audio, FFmpeg H.264/AAC, Spherical Video V1, and verification.
- 0.2: bounded Fast PNG pipe. Full 12-second 8K capture took 166.656 s, whole export
  220.257 s. Encoded video and source audio matched the slower path byte for byte.
- 0.3: one-second samples, time/disk estimates, encoding progress/cancellation,
  and re-encoding saved PNG/WAV sources without rendering or modifying originals.
- 0.4: optional absolute-frame hook, AnimationPlayer property timeline helper,
  editable Path3D Motion Lab example/recipe, and actual seam/pole/audio tests.
- 0.5: equivalent mono Spherical Video V1/V2, fast-start MP4, relocated video/audio
  chunk tables, cascading stco-to-co64 promotion, copy cancellation and twelve
  output checks. Independent media/packet/decode tests also isolate V2 from V1.
- 0.6: attached soundtracks, scene/replacement/mix modes, trim, offsets and levels;
  audio edits during re-encoding; input probing/hashing and thirteen output checks.
  Real decoded-audio and panel tests cover timing, limiting, source preservation
  and source mutation. Bounded JSON rename retries fix a Windows status race.
- 0.6.1: fix Motion Lab library loading on 4.5.1 using compatible dictionary
  serialization; isolated 4.5.1/4.6.3/4.7.2 addon checks; eight soundtrack formats,
  a 90-second mix, beta documentation and reproducible content-verified packaging.
- 0.6.2: sustained real GPU capture at 60 FPS; guarded scene loading, explicit
  early-exit diagnostics, submitted-frame counts and worker exit evidence; recovery
  guidance in the job folder and panel. Six controlled failures and recovery UI
  pass across all three tested engines. Partial capture resume remains absent.
- 0.6.3: reopen the last/selected job, reconnect through a fresh per-client
  challenge, cancel through the confirmed coordinator, and recover completed
  sources even without recovery.json. Preserve stale status/logs and reject old
  replies or unrelated live PIDs. Restore verified completion from report/media.
- 0.7: output-drive working headroom, required checkpoint/preview/report writes,
  logged storage failures and source-preserving recovery. Current three-engine
  coverage is 1,161 unique checks, including targeted cancellation/log-write checks.
  Production-resolution frame/audio reviews are described under local evidence.
- 0.8: local diagnostics ZIPs with bounded reports/logs, environment details,
  verified payloads and per-file hashes; retain source bytes, status and recipe.
  Exact-package reviewer installs the ZIP, verifies its inventory/reproducible
  bytes and runs the complete matrix plus documented panel workflows. Independent
  beta feedback remains pending. THRESHOLD later received positive YouTube visual
  feedback from the user; individual playback checks are not recorded.

The addon remains GDScript plus external FFmpeg. A native rewrite is not currently
justified by the measured bottleneck. Read [performance](performance.md),
[planning](job-planning.md), [authoring](../addons/godot360/AUTHORING.md),
[audio](../addons/godot360/AUDIO.md), [validation](validation.md), and the [roadmap](roadmap.md).

## Preserve these contracts

- Diagnostics reads only fixed filenames in the selected job folder, never media
  subfolders or referenced source/soundtrack paths. JSON is capped at 1 MiB, log
  tails at 512 KiB; manifest discloses omissions. Preserve malformed JSON as evidence.
  Environment describes the collector, not necessarily the saved export. ZIP and
  .partial destinations must be new and outside the source. Verify files before
  renaming; Godot 4.7's ZIPReader also exposes `job/`, which is not a payload file.
  Never hash an empty buffer with HashingContext.update; finish the started context.
  Bundles contain local paths/scene messages and must be reviewed before sharing.

- The storage guard keeps 256 MiB plus capture image/PCM allowance, and separately
  budgets the second MP4 copy. Its query cache is at most 250 ms; it is not a disk
  reservation or a guarantee against removal, quotas or another writer.
- Check required JSON flush/rename and capture-result writes. Preserve a previous
  complete checkpoint when replacement fails. Save a successful report before the
  verified media rename. Status can still fail after that rename; valid report and
  media remain the completion evidence. Log-reader failures must not stop pipe
  draining. Never acknowledge cancellation unless its marker write succeeds.

- Authored frame `n` samples `n / FPS`; warmup repeats zero. Sampling runs at the
  rig's process priority 1000 before camera sync/transform flushing. Sampling in
  `frame_pre_draw` caused a measured one-frame transform lag and was removed.
- Discrete keys are reapplied explicitly. The helper rejects method/audio/nested
  playback tracks, loops, and Capture update mode. Ordinary scene processing and
  legacy void-returning capture hooks still work.
- Keep Motion Lab's `libraries` dictionary syntax if supporting 4.5.1. A newer
  editor can rewrite it to `libraries/`, which silently loses the animation on
  that older engine. Run the isolated compatibility reviewer after scene re-saves.
- Motion Lab's AudioStreamPlayer uses measured startup compensation. It is an
  example, not a correction to all user audio. Actual tests cover 30 FPS with two
  warmup frames and 24 FPS without warmup; only unit sampling covers 60 FPS.
- The coordinator is headless; capture needs a graphics device/display and uses
  the saved project renderer/driver unless explicitly overridden. Unexpected
  renderer/driver fallback fails before capture; headless success proves no pixels.
  Re-encoding requires no GPU scene capture. Only verified output receives the
  final `video-360.mp4` filename. Source PNG/WAV and diagnostics remain on disk.
- Failure counts describe submitted frames, not necessarily finalized PNGs. A
  forcefully killed worker cannot save its final result. Keep worker-exit evidence
  separate and require a complete capture result, zero worker exit code, and WAV
  finalization before using the capture. Recovery checks sequence/WAV headers;
  they do not promise a full decode or restore arbitrary scene state.
- `recovery.json` points to the original capture for a failed re-encode. The panel
  displays its next action. Keep completed sources unchanged and create fresh job
  folders. Coordinator termination/power loss may still leave stale state and no
  recovery file; reopening now checks retained sources. Capture resume and WAV
  promotion from a stranded worker's movie folder are not implemented.
- `job_session.gd` writes a random per-run identity and serves unique client
  challenges. Reopened clients require matching session/PID/action/nonce replies;
  cancellation is a request to the coordinator, never a signal to a saved PID.
  Replies are checked every ten seconds, UI requests wait five seconds, and the
  coordinator rejects requests after ten seconds. Timeout means unconfirmed,
  not known dead. Do not replace the protocol with OS.is_process_running: that
  child-process query incorrectly ended reconnection in the actual launcher-exit
  test. Newly launched jobs still use the editor's own process handle.
- A successful report plus video-360.mp4 restores saved completion even with stale
  status. Complete status alone is insufficient if either artifact is missing.
  Opening a job preserves current recipe/audio controls and completed source bytes.
- Metadata is now equivalent V1/V2, with `moov` before media. Preserve exact media
  bytes and relocate every chunk offset by the final moov size, including after
  co64 promotion. Only the pipeline's conventional trailing-moov H.264/AAC input
  is supported. Reject unknown structural/offset boxes before opening output.
- Audio offsets use delivered frame zero: positive delays, negative advances.
  Remove scene warmup before the scene offset; never trim soundtrack warmup.
  Edited audio uses `asetpts=N/SR/TB` after sample placement to keep AAC timestamps
  monotonic. Default scene audio keeps its old filter and encoded-byte behavior.
- Soundtracks remain external files. Keep resolved paths and SHA-256 evidence;
  reject changes during jobs. Panel re-encodes use current audio controls; CLI
  re-encodes inherit saved fields unless overridden. Mixing uses a 0.95 limiter
  with latency compensation; source levels are never automatically normalized.
- Stereo ODS, ambisonics, automatic upload, and a community release are not implemented.

## Local evidence

- `.godot360/package-080-accepted/package-review.json`: exact current 0.8 ZIP
  installed and reviewed on Godot 4.5.1/4.6.3/4.7.2; 444 checks per engine,
  1,332 total. Headless contracts 251, audio panel 19, capture failures 50,
  reopening 41, storage failures 56, release workflow 27. Rebuilt ZIP bytes and
  extracted inventory are identical. Original settings/capture remain unchanged.
- `dist/umbral360-studio-0.8.0.zip`: 84 members, 169,418 bytes; SHA-256
  `16e41c52c4ef7e0e3c62783a3ae8bc79b93bb676dbd93e5e071daae3ead33961`.
  `docs/release-0.8.md` records the candidate, source history and remaining gates.
- `.godot360/package-080-final/` is REJECTED development evidence, despite its
  name. Godot 4.7's extra ZIP directory entry exposed the inventory mismatch.
  The rejected ZIP is retained there. Only `package-080-accepted` establishes success.
- `renders/delivery-080-8k/candidate-review.json` and `metadata-review.json`:
  current 0.8 exporter, 12-second 7680×3840/30 FPS UMBRAL film, all 13 checks,
  encoded MP4 identical to the original. All 360 decoded frames/audio, 719 offsets,
  924 packet hashes/timestamps and V2-only recognition pass. Original capture and
  saved settings are unchanged; no YouTube upload/review was performed. The 14
  exporter payload files are identical across the candidate's diagnostics fix.
- `.godot360/delivery-080-diagnostics.zip`: actual 8K job support bundle, created
  headlessly using 0.8. Review paths/scene-written text before sharing.

- .godot360/compatibility-070-final/compatibility-review.json: 1,143 checks pass,
  with 218 headless, 16 panel, 50 capture-failure, 41 reopening and 56 storage-failure
  checks per engine. Original project/settings were unchanged.
- .godot360/storage-control-070-final/review.json: updated 24-check storage
  contracts pass on each engine, adding three cancellation-write and three blocked
  process-log startup checks per engine. Combined current coverage is 1,161 checks.
- The initial 070 capture-space fixture ran get_tree() too early; _ready fixes it.
  The final nine cases and actual recovered-source re-encode pass across engines.
- renders/production-070-4k-sample/endurance-review.json: two seconds at 4096×2048,
  2048-pixel faces, 30 FPS; all 60 source/decoded frame codes pass, +2 sample source
  cue offset and zero added AAC cue lag. This is fixture validation, not endurance.
- renders/production-070-4k-full/endurance-review.json: accepted 60-second
  4096×2048/2048-face/30 FPS capture, all 1,800 source and decoded frame codes and
  flashes pass. Five cues through 58 seconds: +2 samples, zero drift/added AAC lag,
  55.59 dB AAC SNR. Pipeline 261.018 s; retained review folder 631,474,043 bytes.
- renders/production-070-8k-full/endurance-review.json: accepted 30-second
  7680×3840/3072-face/30 FPS capture, all 900 source and decoded frame codes and
  flashes pass. Three cues through 28 seconds: +2 samples, zero drift/added AAC lag,
  55.46 dB AAC SNR. Pipeline 397.924 s; retained review folder 1,067,788,420 bytes.
  Both have two extra warmup frames, all thirteen delivery checks, cleaned scratch
  images and unchanged settings. Timing excludes subsequent Python media review.
  The frame-code fixture is very compressible; do not extrapolate its storage to
  complex scenes. These durations/settings do not certify hour-long output.

- `renders/umbral-fast-8k/video-360.mp4`: the 12-second UMBRAL film the user liked.
- `renders/test-2026-09-06T21-52-29-2066321/`: saved Main / 4K planning sample.
- `renders/timeline-studio-checks/render-2026-09-06T22-18-00-1693637/`: full 4K Motion Lab.
- `renders/motion-04-timed/motion-review.json`: 180 PNG and decoded MP4 frames at 30 FPS.
- `renders/motion-04-24fps-final/motion-review.json`: 144 frames without warmup.
- `.godot360/portable-04/output/report.json`: addon-only authored capture.
- `renders/delivery-05-motion/metadata-review.json`: 180 decoded motion frames,
  non-silent audio, packet timestamps and V2-only recognition preserved exactly.
- `renders/delivery-05-8k/video-360.mp4` and `metadata-review.json`: updated 8K
  film with V1/V2 and fast-start; 719 offsets, 924 packet hashes/timestamps and
  all 360 decoded frames/audio checked, including a V2-only test copy.
- `renders/delivery-05-reencode/report.json`: complete headless pipeline, 12 checks.
- `.godot360/portable-05/output/report.json`: addon-only headless pipeline, 12 checks.
- `renders/audio-06-timed/audio-review.json`: ten successful audio exports and
  two early input rejections; zero sample cue lag in tested non-silent outputs.
- `renders/audio-06-delivery-complete/audio-delivery-review.json`: limiter,
  exact legacy encoded bytes and source-mutation rejection.
- `renders/audio-studio-06/test-2026-09-06T23-09-15-1789555/` and
  `reencode-2026-09-06T23-09-22-9341312/`: accepted panel capture/re-encode.
- `.godot360/portable-06/output/report.json`: mixed re-encode with the source scene removed.
- `dist/umbral360-studio-0.6.0.zip`: portable addon, audio guide, examples and tests.
- `.godot360/compatibility-061-fixed/compatibility-review.json`: 208 checks on
  each of Godot 4.5.1/4.6.3/4.7.2; actual calibration capture and mixed re-encode.
  The original `compatibility-061/` folder contains the intentional 4.5.1 failure.
- `renders/audio-formats-061/audio-formats-review.json`: eight codec/rate cases
  and 90-second/2,250-frame mixed audio; zero measured cue lag, all output checks.
- `renders/audio-delivery-061/audio-delivery-review.json`: limiter, legacy bytes
  and source-mutation rejection, now with an explicit historical baseline argument.
- `dist/umbral360-studio-0.6.1.zip`: 63 members, 118,423 bytes; reliability update
  with BETA.md, repeatable reviewers and `tools/package_addon.py`; adjacent JSON hash.
  SHA-256: `7886819d3451c898d08f6c8181ad8c6b4bfc861cccdb397ea0159206e95ba4ae`.
  `.godot360/package-061-review.json` proves identical repeat-build bytes and
  verification after extraction. `.godot360/package-061-compatibility/` runs
  the actual unpacked package's complete reviewer on 4.5.1.
- `renders/endurance-062-full/endurance-review.json`: 90-second actual GPU capture,
  1024×512, 512-pixel faces, 60 FPS. All 5,400 delivered PNG and MP4 frame codes
  and flash states match; seven audio cues have zero drift and a constant −4.625 ms
  startup offset. AAC preserves their placement (zero added lag), 55.81 dB SNR.
  Pipeline elapsed 301.888 s with other tests sharing the machine; not a clean
  performance benchmark. The earlier two-second `endurance-062-sample` also passes.
- `.godot360/compatibility-062-fixed/compatibility-review.json`: 265 checks per
  engine on 4.5.1/4.6.3/4.7.2 (795 total), including 50 lifecycle checks and 16
  panel checks. Each engine produces a verified capture/re-encode and rejects six
  disposable capture failures. Original `compatibility-062/` failures were from
  backslashes embedded in generated test scenes; normalized fixture paths fix it.
- `.godot360/lifecycle-062-final/lifecycle-review.json`: standalone 50-check pass;
  malformed scene, sample hook, early quit, cancellation, killed worker and writer.
- `dist/umbral360-studio-0.6.2.zip`: 68 members, 130,480 bytes, includes RECOVERY.md
  and sustained/failure tests. SHA-256:
  `115403ae460818a9395e3f8567acd76a7e7050a36bb3d87158ae192902026bd0`.
  `.godot360/package-062-review.json` verifies repeat-build bytes and extraction.

The user confirmed YouTube 360 playback of the original 2K film but found it blurry.
They later praised the 8K replacement. Independent verification after YouTube
transcoding remains unavailable; do not claim that it was checked.

- `dist/umbral360-studio-0.6.3.zip`: 71 members, 140,231 bytes. SHA-256:
  `c4bedc440de20229e91bad0c60aeed9859f6906e0abf191e600ec55932873988`.
  `.godot360/package-063-review.json` proves identical repeat-build bytes,
  verification against the extracted source, and the exact changed-file inventory.

## Tools and tests

Historical 0.7 package: dist/umbral360-studio-0.7.0.zip, 78 members, 153,141 bytes.
SHA-256: c506621e64531d02934397eecd0e37cde4551b7956484f7672090d1f4418050c.
.godot360/package-070-review.json proves identical repeat-build bytes,
source/extracted-inventory verification, and both accepted production results.
The package includes storage tests/fixtures and STORAGE.md. Exact-package clean
installation/workflow review is now implemented by tests/package_review.py.
Do not overwrite accepted ZIPs. See docs/release-0.8.md for the current candidate.

0.6.3 evidence: `.godot360/compatibility-063-final/compatibility-review.json`
records 306 passing checks per engine, 918 total, on 4.5.1/4.6.3/4.7.2.
Each isolated project's `.godot360/recovery/recovery-review.json` records the
41-check reopening suite, actual launcher exit/coordinator loss and source hashes.
The source project/settings remain unchanged. `--job-recovery` enables that suite
in `tests/compatibility_review.py`; combine it with `--capture-failures` for the
full matrix. `tests/recovery_studio_checks.gd` needs GPU/FFmpeg/FFprobe and a fresh
absolute output folder. `.godot360/recovery-063-dev/.umbral360/run1` caught the
child-process-query issue; run2 passes. The final panel wording is shorter than
the matrix screenshot, with unchanged behavior and test assertions.

Tested Windows, Compatibility, RTX 3060 Ti, FFmpeg 9.0.1. Addon-only 0.6.1 tests
cover Godot 4.5.1/4.6.3/4.7.2 stable. Full 4K/8K and detailed motion tests remain
specific to 4.7.2; the UMBRAL demo's project.godot still targets that engine.
The 0.6.2 suite repeats compatibility with 199 headless contracts, 16 panel checks
and 50 controlled-failure checks per engine. `planning_checks.gd` now has 31 checks;
other existing headless counts are unchanged. `--capture-failures` adds the six
disposable interruption cases to `tests/compatibility_review.py`.
FFmpeg/FFprobe paths are in `.godot360/settings.cfg`. The Godot console executable
is under the user's `Game Development/Godot/Versions` directory. Bundled Python
with numpy/Pillow is in the Codex runtime cache. Use project-local Godot log paths.

In 0.6, `audio_checks.gd` has 31 passing contracts, `audio_studio_checks.gd` has 13,
`metadata_checks.gd` has 50, `export_checks.gd` has 37 and `planning_checks.gd` has 27.
The audio Python reviewers require numpy/Pillow plus Godot/FFmpeg/FFprobe and
create fresh output folders. Actual WAV and mono FLAC cases cover audio encoding
at 24/30/60 FPS, not new timeline motion capture at 60 FPS. See the audio guide
and validation record for commands, accepted results and format/duration limits.

0.6.1 adds `tests/audio_formats_review.py` and `tests/compatibility_review.py`.
The latter accepts repeatable `--godot` arguments and works from an unpacked ZIP
without a project.godot, creating a separate minimal project for each engine.
It runs 195 headless checks plus 13 actual panel checks per engine. Fixture
generation requires numpy/Pillow; package creation only needs Python's standard
library. `audio_delivery_checks.py` now requires `--legacy-source`; the accepted
local baseline is `.godot360/portable-04/output` with CRF 16.

`tests/endurance_review.py` defaults to 90 seconds at 60 FPS and 1024×512; use
`--seconds 2` for a quick fixture check. It needs the same tools/numpy/Pillow and
an actual GPU/display. All source PNGs and decoded frames are inspected, with
audio timing measured against generated chirps. It records the fixture's startup
offset rather than applying a global correction to unrelated user scenes.

`tools/package_addon.py` reads current source, checks version consistency, includes
only addon/docs/tests/tools, writes a per-file manifest and refuses overwriting a
package. Use `--verify` against current source or an unpacked release. It does not
depend on old ZIPs. Keep plugin.cfg, metadata SOFTWARE, panel title, README and
changelog versions consistent. BETA.md has reproducible commands and the matrix.

`metadata_review.py` uses Python's standard library
plus FFmpeg/FFprobe; it writes a new V2-only copy and JSON report, so use a fresh
output folder. The >4 GiB offset cases are synthetic, not a large physical render.
The full re-encode preserved all source-folder hashes and the user's settings.

From 0.4, `timeline_checks.gd` has 24 passing contracts; `timeline_studio_checks.gd` has 8
passing panel/export checks. The motion reviewer inspects all actual source and
encoded images/audio. The legacy panel export/preview/cancellation test also passes.
Other tests and commands are listed in the root README and validation record.
Repeat checks when changes or unresolved findings justify it; avoid unnecessary
large renders just to re-establish existing evidence.

Tests that change studio settings restore them afterward. Keep the user's Main /
4K / 12-second recipe and saved planning sample available. Earlier render folders
retain intentional failed development evidence; only accepted reports establish
success. Sandbox cache/certificate messages in logs are separate from test failures.

## Next work

The local 0.8 engineering gate passes; see docs/release-0.8.md and its accepted report.
The main remaining external validation is an independent Windows/GPU beta report.
THRESHOLD has positive user-reported YouTube visual feedback; individual playback
checks were not supplied. addons/godot360/BETA-REPORT.md provides the specific
checks. Do not infer an independent beta or a complete itemized playback review
from this feedback or from automated local tests.
Fix any reported blocking defect and repeat the affected checks before replacing
the candidate. Keep arbitrary capture resume and untested platform claims outside
the initial 1.0 scope. Do not repeat large renders or add unrelated features while
waiting for feedback. Publication still needs the user's explicit authorization.
