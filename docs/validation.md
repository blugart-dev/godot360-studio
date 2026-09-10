# Validation record — updated 2026-09-10

## Complex particles and LUMEN — 2026-09-10

The interrupted native trail review is complete on Windows 11 / RTX 3060 Ti,
Godot 4.7.2: Forward+/Vulkan, Mobile/Vulkan with 12.5% borders, and
Compatibility/OpenGL. Each method exports tube, cross-ribbon, paused tube and
disabled-trail controls: **12 exports / 864 source and decoded frames**. Every
frame is compared with a simultaneous native perspective reference across a
cube edge. Geometry coverage, centroids, process timing, unchanged particle
settings and all six camera transforms pass. The paused case includes a camera
cut. Delayed-reference controls are rejected.

Native trail history is visibly different from the disabled control on
Forward+/Mobile (maximum full-panorama MAE 0.5923/0.5901). Compatibility's enabled
and disabled frames are exactly equal: its passing review establishes the
documented exclusion, not native trail support. Across the twelve jobs, maximum
source-view MAE is 0.3211 and decoded MAE is 0.4799. Existing thresholds are
unchanged. See [native trails](trail-capture.md).

The retained [moving-smoke matrix](smoke-capture.md) passes **48 exports / 3,456
source and decoded frames** across the same three methods, including nine
rejected orientation/position/opacity controls and six zero-warmup observations
outside acceptance. CPU/GPU world/local motion, recycling, warmup and early
pausing match analytic mesh references. Its fixture, reviewer and shader hashes
match current source. The capture runtime differs solely by the two-line
Compatibility trail warning added afterward; the audit checks that exact diff.
The new trail matrix matches current runtime/fixture/reviewer hashes exactly.

The frozen addon ZIP is `.godot360/particles-complete/package/candidate.zip`,
**163 entries / 1,165,026 bytes**, SHA256
`2f4482e7da16d46ec89682d0d96a63b4e6510b2c6cea8b57f2bc5d6b67be1162`.
Its extracted source reproduces identical bytes and passes **3,018 headless and
injected-failure checks** on 4.5.1/4.6.3/4.7.2 (1,006 each). This includes the new
eleven material/scene-note checks per engine. `.godot360/particles-complete/audit.json`
records the evidence boundaries and hashes. The new Complex particles hosted
workflow covers the three software-rendered Linux methods; hosted execution is
recorded separately after the private checkpoint.

[LUMEN](lumen.md) adds a complete 24-second 4K Forward+ film using native trails,
point-facing vapor, moving geometry, authored exposure, capture borders and an
original stereo score. Its final job and review live under
`renders/lumen-4k-final/`; documentation stills and the flat tour are derived from
that delivery. The final render took 232.48 seconds and retained 2,900,935,272
bytes (2.70 GiB). All 722 source images are present in order, all 13 delivery
checks pass, and decoded audio matches the original at 3/11/20 seconds with
zero sample lag and correlations above 0.9998. The audit confirms current
source (apart from trailing blank-line cleanup in three new files) and unchanged
protected project/settings hashes. The browser player
passes playback, seeking, mute and drag-to-look review. The demo is compositional evidence, distinct from the analytic
particle fixtures and the still-open heavy-production endurance gate.

This remains private development on 0.8.0. Advanced temporal/GI/compositor
coverage, representative 4K/8K pressure/endurance, native Linux/Mac hardware and
the final private installation/delivery review remain open.

## Head-look and nested attachment validation — 2026-09-09

The next bounded scene milestone passes on native Windows 11 / RTX 3060 Ti.
The [illustrated setup](modifier-capture.md) adds a stateless custom
`SkeletonModifier3D` head look to the pinned imported character, plus a nested
skeleton and camera mount. Independent raw-glTF/CPU skin references match the
modified character, source camera, six cube cameras and viewpoint cut. There was
no capture runtime discrepancy to fix for this setup.

| Case | Engine / renderer | FPS / warmup / border | Exports |
| --- | --- | --- | --- |
| Nested head look + three delayed controls | 4.5.1 Compatibility / OpenGL | 30 / 2 / 0% | 6 |
| Nested head look, opening without warmup | 4.6.3 Compatibility / OpenGL | 30 / 0 / 0% | 3 |
| Nested head look + three delayed controls | 4.7.2 Forward+ / Vulkan | 30 / 2 / 0% | 6 |
| Nested head look with borders | 4.7.2 Mobile / Vulkan | 30 / 2 / 12.5% | 3 |
| Textured head look | 4.7.2 Forward+ / Vulkan | 60 / 0 / 12.5% | 2 |
| Original animation, frozen package | 4.7.2 Compatibility / OpenGL | 30 / 2 / 0% | 3 |
| Head look without nesting, frozen package | 4.7.2 Compatibility / OpenGL | 30 / 2 / 0% | 3 |

**26 exports / 1,560 source frames and 1,560 decoded frames**, including six
intentional negative controls. Every source and decoded frame is compared, with
the original acceptance thresholds unchanged. Accepted comparisons reach maximum
source MAE **0.000184**, foreground MAE **0.02394**, decoded MAE **0.03861** and
bone/camera matrix-element error below **0.000002**. Final bones are observed in
`skeleton_updated`; restored base bones, nested transforms and all six camera
transforms are checked after drawing, including every warmup sample. The audit
also verifies exactly one modifier evaluation between successive draw samples.

Each negative trio delays the CPU skin, direct reference camera or modifier target
by one frame. All six image controls fail. The late head target reaches final-bone
error **0.0530** and foreground MAE **0.609–0.611**, while the restored base pose
continues to match. This distinguishes modifier timing from animation sampling.
Initial exploratory 4.7.2 Compatibility head/nested runs also passed; those six
exports are excluded from the accepted counts above.

The frozen development ZIP is `.godot360/modifier-review/package/candidate.zip`,
SHA256 `8f0a2dd5a4b0cf6906fe41a6eb5c8ad10dcd51aace4c27a3a949b016d416b788`:
154 files, 1,147,928 bytes, identical rebuild and exact current packaged-source
matching. The package passes **2,985 headless/failure checks** across
4.5.1/4.6.3/4.7.2 (995 each, including 384 skeletal checks each). Those skeletal
checks cover parent/external attachments at zero, one and two nested levels,
repeated samples/backward wrap and source removal. The six package character
exports above supply rendered evidence separately from the headless matrix.

Evidence: `.godot360/modifier-review/audit.json`, `native/`, `package/headless/`,
`package/animation-472/` and `package/head-472/`. The audit confirms current
runtime/fixture/reviewer hashes, the immutable licensed asset, and prior creative
scene/recipe/settings/master hashes. The contact sheet is retained in Git with
Cesium attribution. The expanded Imported characters workflow covers animation
and nested head look on three renderers and passes actionlint (ShellCheck disabled).
Implementation `2f4448f` is pushed to private `origin/main`. Hosted
[Imported characters 34371376287](https://github.com/blugart-dev/godot360-studio/actions/runs/34371376287),
[Desktop platforms 34371375916](https://github.com/blugart-dev/godot360-studio/actions/runs/34371375916)
and [Combined appearance 34371376090](https://github.com/blugart-dev/godot360-studio/actions/runs/34371376090)
all pass on the first attempt. The six character lanes add **33 exports / 1,980
source and decoded frames**, including 15 rejected timing controls. Both appearance
lanes pass nine clips / 810 decoded frames plus re-encoding. Desktop platforms
passes **1131 Linux checks / 997 Mac headless checks**, three skeletal exports,
eight renderer cases and 14 particle exports. All ten hosted candidate records
match the exact local ZIP hash above. Reports and assertions are retained in
`.godot360/modifier-review/hosted/verified.json`. Software Linux rendering and Mac
headless contracts remain distinct from the native GPU testing still on the roadmap.

Supported scope: Manual sampling of this unit-scale, full-influence, stateless
head look and nested mounts with attachment pose overrides disabled. General
built-in solver chains, damping, partial influence, ragdolls, physics interpolation
and retargeting remain separate cases. The next engineering target is complex
particles: smoke, billboards, trails and moving emitters. This remains private
development on the 0.8.0 baseline; no 1.0 release or publication is implied.

## Imported animated character — 2026-09-09

The [illustrated imported-character review](imported-characters.md) uses the
licensed, pinned CesiumMan GLB: 19 joints, 57 LINEAR TRS channels, 3,273 vertices
and 4,672 triangles. Godot's scene importer, AnimationPlayer, weighted skin and
external head attachment are compared with independently evaluated raw glTF data.
No addon runtime change was necessary. The fixture adds a camera boom and a
31.5-degree cut at frame 30, plus late-skin and late-camera negative controls.

### Native evidence

Windows 11 / RTX 3060 Ti / FFmpeg 9.0.1. All clips are 2048×1024 with 512-pixel
face cores and 60 delivered frames. The import bake rate matches the export rate;
the raw-source reference disables animation optimization, immutable-track removal,
mesh compression and generated LODs only in the disposable project.

| Godot / renderer | FPS | Warmup | Border | Exports | Scope |
| --- | ---: | ---: | ---: | ---: | --- |
| 4.5.1 / Compatibility | 30 | 2 | 0% | 3 | Camera and weighted skin |
| 4.6.3 / Compatibility | 30 | 0 | 0% | 3 | Camera and weighted skin |
| 4.7.2 / Forward+ Vulkan | 30 | 2 | 0% | 5 | Camera, skin and both negative controls |
| 4.7.2 / Mobile Vulkan | 30 | 2 | 12.5% | 3 | Camera and weighted skin |
| 4.7.2 / Forward+ Vulkan | 60 | 0 | 12.5% | 2 | Original textured material, camera pair |
| 4.7.2 / Compatibility, final unpacked ZIP | 30 | 2 | 0% | 5 | Camera, skin and both negative controls |

**21 exports / 1,260 unique source and decoded video frames**: 17 accepted
reference/capture clips and four deliberately incorrect control clips. Eleven
accepted image pairs pass. The largest accepted source RGB MAE is 0.0001282,
foreground MAE 0.01666 and decoded MAE 0.03267; existing skeletal comparison limits
remain 0.03 / 0.25 / 0.1. At least 5,284 orange character pixels are present in
every unlit reference frame. Maximum joint-matrix error is 0.00000160 and camera
matrix error 0.00000134, below the 0.00005 requirement.

Both renderer runs with negative controls reject them. Forward+ late skin reaches
3.805 foreground MAE while whole-frame MAE is only 0.0252, demonstrating why the
foreground condition matters. Its late camera reaches 114.46 foreground MAE,
including the missed cut. The final Compatibility ZIP rejects the same errors.

Exploratory failures remain under `initial/` (default import optimization) and
`native/textured-472/` (60 FPS export versus a 30 FPS import bake). Maximum bone
matrix errors were 0.0194 and 0.0269 respectively. Precise import settings and a
matching bake rate resolve them without a capture-runtime change. The initial
`exact-import/` success is separate exploratory evidence, not counted above.

### Package and preservation

Accepted ZIP: `.godot360/imported-character/final/candidate.zip`, **153 entries,
1,144,980 bytes**, SHA256
`3a66b1f853e6f0494a56020b63731da1c7717f3af02b38183ea8feecf558bf31`.
Rebuilding its extracted source gives identical bytes. Its Compatibility review
is the five-export row above. The earlier package passes **739 headless checks**,
including injected capture/storage failures, at SHA256
`304ba7d3243147c8bf104efb2c967a8bbf54c5dcb38c88f201c36aec51c65c50`.
Only authoring/asset notes, the Python reviewer (explicit import bake FPS), and
the manifest differ from that headless snapshot. Runtime, fixture and reference
evaluator bytes match across all six accepted native datasets.

`.godot360/imported-character/audit.json` verifies the reports, exact package,
native runtime/fixture matching and the protected project/settings/recipe/master
hashes. All three workflows pass actionlint (ShellCheck disabled). The new
Imported characters hosted workflow passes on this increment, as detailed below. IK/modifiers,
nested skeleton attachments, other import/retarget pipelines, complex particles,
production workloads and native Linux/Mac GPU reviews remain open.

### Hosted validation of the exact character package

Source commit `1a23a0c` is pushed privately. All three workflows pass:

- [Imported characters, run 34366471485](https://github.com/blugart-dev/godot360-studio/actions/runs/34366471485):
  five exports per renderer on Linux Mesa Compatibility, Forward+ and Mobile.
  All 15 clips / 900 source and decoded frames are checked, including six
  deliberately incorrect controls that are rejected as required.
- [Desktop platforms, run 34366473025](https://github.com/blugart-dev/godot360-studio/actions/runs/34366473025):
  875 Linux package/workflow checks, three skeletal exports, eight renderer cases
  and 14 particle exports; 741 macOS headless checks.
- [Combined appearance, run 34366471526](https://github.com/blugart-dev/godot360-studio/actions/runs/34366471526):
  nine clips / 810 decoded frames and a re-encode on each renderer.

All seven hosted package records match the final `3a66b1f8…` ZIP above. Downloaded
reports, full run records and the aggregate audit are under
`.godot360/imported-character/final/hosted/`; `verified.json` confirms outcomes,
source revision, package hashes and negative controls.

The Mobile character job was canceled during extremely slow Ubuntu package
downloads, before package building or tests began. Only that job was rerun on
unchanged source; Compatibility and Forward+ retained their first successful
attempts. The canceled setup log is retained as `final/mobile-install-cancelled.log`.
Desktop platforms and Combined appearance passed without retries. These software
Linux and headless Mac jobs do not replace the remaining native GPU reviews.

## Appearance/particle checkpoint hosted validation — 2026-09-09

Checkpoint `d37a786` preserves the previously uncommitted appearance and particle
startup work and is pushed to private `origin/main`. Both hosted workflows passed
without a retry: [Desktop platforms, run 34363716312](https://github.com/blugart-dev/godot360-studio/actions/runs/34363716312)
and [Combined appearance, run 34363715991](https://github.com/blugart-dev/godot360-studio/actions/runs/34363715991).

Linux passed 875 package/workflow checks, three skeletal exports, eight renderer
cases and 14 particle exports (nine appearance comparisons and 14 processing
checks). macOS passed 741 headless checks. Each appearance renderer passed nine
clips, 810 fully decoded video frames and its re-encode; source/authored-oracle
and decoded-oracle differences are zero on both Mesa Vulkan lanes.

Linux/macOS package reports reproduce the prior accepted ZIP SHA256
`ad97a690a17c6859894c676b49437c4c53ee6b50a28c35f1d29d6d9273bdc2e7`.
The downloaded reports and run records are retained under
`.godot360/imported-character/checkpoint-ci/`. This closes the hosted-CI follow-up
in the earlier entries; it is private development evidence, not publication.

## Particle startup and fixed capture clock — 2026-09-09

Continued the ordered private 1.0 work after the combined appearance pass, retaining
its local changes. This increment changes `capture.gd`: the worker disables realtime
physics jitter compensation before startup and refreshes Compatibility CPU automatic
bounds after buffer submission. The [particle guide](particle-capture.md) documents
the causes, actual before/after frames and the remaining zero-warmup GPU limit.
Particle FPS, interpolation, speed, seeds, emission and authored bounds are preserved.

### Reproduction and negative controls

With two warmup frames at 30 FPS, the old clock delivered opening deltas of
41.6667, 29.1667, 30 and 32.5 ms before settling to 33.3333 ms. Disabling OS delta
smoothing did not fix this; setting `Engine.physics_jitter_fix = 0` did. Three/four
warmup frames could leave a lasting position offset, so extra warmup alone was not
a clock correction. A fixed 30 Hz GPU emitter repeated a step at frame 3.

The old Compatibility CPU automatic-bounds opening was empty even with eight
warmup frames. Querying the MultiMesh's bounds in `frame_pre_draw`, after the CPU
buffer update, fixed it. General GPU synchronization and ignoring culling did not.
The final implementation queries automatic bounds without assigning new ones.

Retained negative controls exceed the unchanged 0.25 foreground-MAE limit:
**149.509** for missing automatic-bound particles, **9.195** for two-frame warmup
with variable steps, and **37.239** for the repeated fixed step. Explorations are
under `.godot360/particle-startup/{bounds,timing-forward,clock-forward}/`; the audit
records their metrics. These failures are not counted as accepted captures.

### Accepted native particle matrix

Windows 11 / RTX 3060 Ti / FFmpeg 9.0.1. Each clip has 60 delivered frames at
2048×1024, with 512-pixel cube-face cores. Fixed particle rates match the export
rate; continuous-step emitters use Fixed FPS 0 with GPU interpolation disabled.

| Engine / renderer | Export FPS | Border | Clips | Appearance pairs | Unique decoded MP4 frames |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4.5.1 / Compatibility OpenGL | 30 | 0% | 10 | 9 | 600 |
| 4.6.3 / Compatibility OpenGL | 30 | 0% | 10 | 9 | 600 |
| 4.7.2 / Compatibility OpenGL | 30 | 0% | 16 | 9 | 720 |
| 4.7.2 / Forward+ Vulkan | 30 | 0% | 14 | 7 | 600 |
| 4.7.2 / Mobile Vulkan | 24 | 12.5% | 8 | 7 | 480 |
| 4.7.2 / Forward+ Vulkan | 60 | 0% | 8 | 7 | 480 |

**66 clips / 3,960 delivered frames**, with 48 accepted analytic appearance pairs
and **3,480 unique MP4 frames decoded**. The latter includes zero-warmup observations;
eight lifecycle clips instead check processing and stable retained PNGs. The two
4.7.2/30 FPS renderer runs cover disabled, when-paused, `ALWAYS` and mid-capture
pause behavior. All jobs pass delivery verification, process-delta checks and
authored emitter-setting preservation. The tested simple effects pass with the
default two warmup frames. GPU zero-warmup observations still fail appearance;
they are explicitly outside acceptance, while their processing checks pass.

Compatibility CPU automatic bounds pass with **two and eight warmup frames on all
three engines**, with exact source and decoded matches. The two-frame follow-up
jobs reuse the same disposable projects and references; their additional reports
are in `candidate/automatic-bounds-short.json`. The reviewer and Linux CI now
include both warmup counts as required cases. Across accepted comparisons, maximum
source MAE is 0.000206, foreground MAE 0.0905 and decoded MAE 0.0111, on a 0–255
scale. Existing limits remain <0.03, <0.25 and <0.1 respectively. The eight-emitter
4.7.2 Compatibility automatic-bounds case records 1,174 microseconds of bounds
refresh over 68 draws (about 0.0173 ms/draw); this is a small-fixture measurement.

Reports, sources, requests and isolated profiles are under
`.godot360/particle-startup/candidate/`. The first 4.7.2 Compatibility reviewer used
the older `gpu-fixed-30` / `cpu-fixed-30` names; later reviews use `*-fixed-rate`
and support 24/30/60 FPS. Runtime and particle fixture bytes match throughout.

### Clock regressions, package and preservation

Three six-second Forward+ Motion fixture exports pass source/decoded geometry,
seam/pole crossings and exact flash frames: 30 FPS/two warmup, 60 FPS/zero warmup,
and 24 FPS/two warmup. All **684 delivered frames** are checked as source PNGs and
decoded video. Maximum
source/encoded audio onset errors are 0.709, 2.042 and 7.938 ms respectively,
within the existing 10 ms acceptance. See `motion/motion-summary.json`.

The unpacked package passes **1,875 headless contract checks**, 625 on each of
Godot 4.5.1, 4.6.3 and 4.7.2, including import, renderer, timeline, skeletal,
audio, storage, diagnostics and playback contracts. This run does not repeat the
prior increment's injected process/storage-failure suites. Report:
`package/contracts/compatibility-review.json`; reviewed package SHA256:
`8388dfe100ffa04f22ec78d8cf28124b822f28721cef2c472d7c7dca68e6db68`.

Accepted package: `.godot360/particle-startup/accepted/candidate.zip`, **144 entries,
847,343 bytes**, SHA256
`ad97a690a17c6859894c676b49437c4c53ee6b50a28c35f1d29d6d9273bdc2e7`.
Its only differences from the headless package are the renderer troubleshooting
guide, Python reviewer (additional two-frame automatic-bounds case and GPU-only
filter) and manifest. Rebuilding from its unpacked source is byte-identical;
runtime and fixture hashes match the rendered projects. The three added
automatic-bounds cases pass using the final review functions. `audit.json`
records package inventory, dataset scope, negative controls and preserved hashes.

The user's main project, studio settings, Threshold 8K recipe and existing master
remain byte-identical. No version bump, commit, push or publication was performed.
Both workflow files pass the installed actionlint; the expanded particle CI and
new appearance workflow have not run hosted for this local snapshot. Native Linux
GPU/Mac graphical review, complex effects and final 1.0 delivery remain open.

## Combined appearance and 1.0 exposure boundary — 2026-09-09

Continued from clean `2cc9aa8`. The new portable `appearance_review.py` and
`appearance_scene` fixture combine camera motion, moving emissive geometry and
point lighting, directional/point shadows, PBR materials, alpha transparency,
camera/world exposure handoffs, an attribute replacement and a lighting cut.
The [illustrated guide](combined-appearance.md) explains both the comparisons and
the support decision: consistent 1.0 brightness uses authored exposure, including
animation. Shared automatic spherical adaptation is deferred beyond 1.0.

### Native appearance evidence

Windows 11 / RTX 3060 Ti / Godot 4.7.2 / Vulkan / FFmpeg 9.0.1. Each renderer has
nine 2048×1024/30 FPS jobs, 90 delivered frames each, 512-pixel face cores and eight
warmup frames, plus a source-preserving re-encode. All 810 MP4 frames per renderer
are fully decoded and counted. Two source/decoded oracle pairs per renderer cover
fixed exposure with zero and 12.5% borders; unlit controls isolate projection and
glow-disabled lit captures separate halo contributions from geometry/shadow edges.

| Measurement | Forward+ | Mobile |
| --- | ---: | ---: |
| Front/right glow boundary reduction | 96.8% | 95.1% |
| Three-face corner with lighting cut | 95.5% | 94.0% |
| Rear/left glow boundary reduction | 97.0% | 95.6% |
| Maximum unlit border frame MAE, RGB 0–255 | 0.0021 | 0.0021 |
| Maximum fixed/authored-oracle source MAE | <0.000004 | 0 |
| Maximum fixed/authored-oracle decoded RMSE | <0.863 | 0 |

Accepted rendered evidence is under `.godot360/appearance-review/final/forward/`
and `mobile/`. Both use the final fixture and runtime bytes. The initial
`forward-initial/` investigation has another 810 frames and exact oracle matches;
it is separate evidence, not counted again in the two-renderer totals above.
The checked-in sheets come from that initial Forward+ review and the Mobile review.
Borders still alter halo shape, and lit glow-disabled frames differ by up to
0.056 mean RGB as the frusta change. The unlit controls separate that observation
from a projection/color defect. Boundary scores describe these fixtures, not all
scene appearance. The scene is silent, so audio cue timing is not newly established.

The repeated Forward+ run exposed a **reviewer acceptance problem**. At most a few
source channels per frame differ by one RGB level, while decoded CRF output
differs by up to 0.191 mean RGB / 0.863 RMS. The original decoded-MAE limit of 0.1
rejected it. The reviewer now requires source MAE <0.02 **and source maximum ≤1**,
plus decoded RMS <1 RGB level. It retains both decoded metrics and every frame's
source maximum. This strengthens the source constraint while allowing small
lossy-encoding differences. The original failed report remains at
`final/forward/appearance-review-rejected-decoded-mae.json`; the revised reviewer
reanalyzes the original files without re-rendering or altering the delivered media.
The deliberately incorrect Scene-versus-authored-oracle control is rejected
(source MAE up to 61.08), so the revised source constraint still detects the
brightness defect. See `negative-control.json` and `codec-observation.json`.

### Package and checks

The full three-engine headless package review is
`.godot360/appearance-review/final/package-headless/package-review.json`:
**2,217 passing checks**, 739 each on Godot 4.5.1, 4.6.3 and 4.7.2. It verifies
imports, contracts, actual process/storage failures, manifest contents, source
preservation and byte-identical rebuilding. That snapshot's SHA256 is
`514dedf780c20c40504967870aef1a0cf1e5ff24981d39f21bccae7836322015`.
Its unpacked source also supplies the nine-job repeated Forward+ render above.

The accepted package is `.godot360/appearance-review/accepted/candidate.zip`,
144 entries, 845,995 bytes; SHA256
`401e5c6c202c6d9fc33464295d7f91545ec9edae3ce12106c492e729a84ce130`.
It differs from the full-matrix snapshot **only in `tests/appearance_review.py`
and the manifest**, incorporating the reviewed source/decoded acceptance change.
Its own unpacked builder reproduces identical bytes. Its reviewer rechecks both
native datasets; the original Mobile runtime and fixture files match the accepted
package. See `accepted/package-diff.json` and `audit.json` for the inventory audit.
No addon runtime GDScript or shader changes were needed for this increment.

The new `.github/workflows/appearance.yml` prepares separate Forward+/Mobile
Linux software-Vulkan jobs against an unpacked candidate. Its actionlint check
passes; a hosted execution of this new workflow has **not** been recorded yet.
This does not extend the existing native hardware claims. Native Mac graphical,
Linux hardware-GPU, production 4K/8K endurance and private final workflow/delivery
reviews remain open. Next local development is particle startup and fixed-step
timing, followed by the broader animated/effect scene matrix.

## CPU visibility bounds follow-up — 2026-09-08

The initial particle comparison below used an automatic CPU Visibility AABB and
an explicit GPU AABB. A targeted follow-up to `8b16092` sets the same conservative
local bounds on CPU emitters. In Windows 4.7.2 Compatibility, that removes the
first-frame gap: **all 60 source and decoded MP4 frames match the analytic mesh
reference exactly**. The authored workaround is now in the fixture and
[guide](particle-capture.md); the addon changes no particle bounds itself.

The scene note now applies specifically to Compatibility CPU emitters with
automatic bounds and recommends an authored Visibility AABB. The reviewer checks
that explicit bounds suppress this note, while `--automatic-bounds` retains the
known failing case as an observation. Linux CI now tests both CPU and GPU
appearance with explicit bounds, all four processing modes and the automatic-
bounds observation. It no longer needs the earlier `--gpu-only` restriction.

The final follow-up package is `.godot360/particle-review/bounds-final/candidate.zip`,
SHA256 `d396af57e4ae9002d3831e88c32874b43cdd1e9622073f5739620a77c93d7c22`.
Its exact unpacked source passes nine Windows 4.7.2 Compatibility exports:
four settled CPU/GPU/reference jobs, four mode cases and one automatic-bounds
observation. All accepted comparisons and modes pass; the observation still fails
on frame zero. This adds 240 settled source/decoded frames and 60 observed
source/decoded frames. Full earlier package results below remain applicable to
capture outside inspection: this follow-up changes the note, fixture, reviewer,
authoring/changelog text and CI selection, with no further capture-clock change.
Two additional CPU exports on Windows Godot **4.5.1 and 4.6.3** also match their
retained analytic references exactly in all 60 source/decoded frames each. Their
diagnostics correctly omit the automatic-bounds note. The first 4.5.1 invocation
failed before scene startup because the standalone helper omitted its disposable
profile; restoring the isolated profile fixed that test invocation, with no addon
change. It is retained as a harness failure, not counted as a passed export.

Hosted run [34255433218](https://github.com/blugart-dev/godot360-studio/actions/runs/34255433218)
passes on implementation `17d0abc`: **875 Linux package/workflow checks**, the
three-export skeletal comparison, eight Forward+/Mobile software-Vulkan appearance
cases, and the nine-export particle review; **741 Mac headless checks** pass too.
Both platforms reproduce the exact final package hash above. Hosted Linux's
explicit-bounds CPU comparison also matches all source/decoded frames exactly;
the automatic-bounds observation reproduces the first-frame gap. All four mode
cases pass. Artifacts are retained locally in `bounds-final/ci-linux` and `ci-mac`.
The earlier `8b16092` run `34254377349` was superseded/cancelled by this follow-up
after Mac passed, while Linux was still in its software-Vulkan stage. Final CI
passes without a retry. Mac evidence remains headless, and Linux uses Mesa software
rendering; native Mac graphical and Linux hardware-GPU coverage remain open.

The initial `8b16092` validation and narrower particle lanes are historical
evidence, retained below. Zero/short-warmup behavior, arbitrary fixed particle
steps, automatic-bound startup and complex particle effects remain open.

## Particle capture and processing modes — 2026-09-08

Continued privately from clean `f5d9198`. The [particle fixture](particle-capture.md)
found that capture overwrote the root's authored processing mode at startup and
after every rendered frame. The fix saves that mode and restores it once after
warmup; zero warmup and later scene changes are preserved. The old worker fails
all four new mode cases, while the corrected worker passes them in Forward+,
Mobile and Compatibility. Static disabled pictures and a mid-capture CPU pause
are checked as well as scene ticks. Strengthened metrics were rerun against
retained frames in `particle-review-hardened.json`; the original reports remain.

### Native particle evidence

Windows / RTX 3060 Ti / FFmpeg 9.0.1; 2048×1024, 512-pixel face cores, 30 FPS,
60 delivered frames per job. Eight opaque sphere particles move at constant
velocity across face boundaries, using particle Fixed FPS 0, no gravity/collisions,
GPU interpolation off and fixed GPU seeds. Ordinary meshes provide an independent
position reference. The normal/long warmup cases use eight/ten frames.

| Godot / renderer | Appearance comparison | Other coverage | Result |
| --- | --- | --- | --- |
| 4.7.2 Forward+ / Vulkan | CPU and GPU vs. analytic meshes | Four processing-mode cases; short/zero warmup and fixed-30-Hz observations | Settled motion and modes pass; startup observations retain failures. |
| 4.7.2 Mobile / Vulkan | CPU and GPU vs. analytic meshes | 12.5% border; four mode cases | Pass. |
| 4.7.2 Compatibility / OpenGL | GPU vs. analytic meshes | Four mode cases; separate CPU comparison | GPU/modes pass; CPU first delivered frame is missing, remaining 59 match. |
| 4.5.1 Compatibility / OpenGL | GPU vs. analytic meshes | Eight/ten warmup | Pass. |
| 4.6.3 Compatibility / OpenGL | GPU vs. analytic meshes | Eight/ten warmup | Pass. |

The settled accepted comparisons inspect **1,020 unique source and 1,020 decoded
frames** across 17 exports. An additional 360 of each cover startup observations
and the failed Compatibility CPU appearance case. Twelve mode exports inspect
scene state and retained frames; four old-worker exports supply the negative
control. The initial exploratory runs are retained separately and are not added
to these counts. All accepted pairs meet source MAE <0.03, decoded MAE <0.1,
foreground MAE <0.25 and >200 foreground pixels on a 0–255 scale. The largest
accepted foreground error is below 0.06.

**Open defects and limits:** zero/two-frame warmup can omit or partially initialize
particles. Compatibility CPU startup remains wrong at eight warmup frames; the
`--gpu-only` lane explicitly excludes that appearance claim, while retaining CPU
pause tests. In an initial two-warmup Forward+ trial, a fixed-30-Hz GPU emitter
repeated a step; the later eight-warmup observation matched. No general fixed-step
or arbitrary particle determinism is claimed. Scene notes identify short warmup
and Compatibility CPU startup. Native simulation, seeds and particle settings
remain authored. Transparent/billboard effects, collisions, trails, preprocessed
or moving emitters, subemitters, long histories and cross-GPU repeatability are open.

### Package and regression evidence

The full regression snapshot is `.godot360/particle-review/final/candidate.zip`,
SHA256 `f1771a365247c0ef7ed3fdd8195a544200e16eeba567a1c5386de0a17f07f1ca`.
It passes **2,217 headless package checks** across Windows Godot 4.5.1, 4.6.3 and
4.7.2, plus **872 Forward+ package/workflow checks**, including actual exports,
playback, cancellation, recovery and storage failures. An additional Forward+
color/lit/motion review passes all 180 source and decoded motion frames, with
audio cues within 0.71 ms. These jobs use disposable projects and profiles.

The final candidate is `.godot360/particle-review/accepted/candidate.zip`, SHA256
`ce1c961448fde190d16785dd5292e8a26534d67315b7480730ff75d84cc37f6f`.
Its changes from the full snapshot are scene-inspection notes, authoring/changelog
text and Python reviewer coverage/metrics; capture code outside inspection is
identical. Both packages have 141 entries and reproduce byte-for-byte from their
unpacked source. The final package passes another **739 Windows 4.7.2 checks**
and eight Compatibility particle exports: GPU appearance at eight/ten warmup,
four processing-mode cases and the short-warmup observation. These verify the
final notes and strengthened static-frame metrics. Three settled clips add 180
source and decoded frames; the short-warmup observation adds 60 of each. Local
package checks total **3,828** across the two explicitly identified snapshots.
Its first hosted run was superseded by the bounds follow-up; the final successful
hosted evidence is recorded above.

Source scene/settings/recipe/master hashes remain unchanged. Evidence lives under
`.godot360/particle-review/`, including the failed Compatibility CPU report and
the explicitly narrowed `particle-review-gpu.json`. The repository stays private
and the version remains the internal 0.8 baseline. This does not close the complex
particle, production-performance, native Mac/Linux hardware or final usability
workstreams.

## Skeletal camera timing review — 2026-09-08

Private development continues from `0a86e29`, whose preceding implementation CI
run is green. The new [rendered comparison](skeletal-capture.md) found and corrected
a one-frame camera delay when a selected Camera3D follows BoneAttachment3D.
The skin was already at its sampled pose; the rig copied the attachment too early.
Sampling remains at priority 1000, followed by deferred camera synchronization
before the engine flushes transforms for drawing. No additional simulation step,
skeleton evaluation, viewport, shader pass or GPU readback is introduced.

### Native rendered comparisons

Windows 11, RTX 3060 Ti, FFmpeg 9.0.1; 2048×1024, 512-pixel face cores, 30 FPS,
60 delivered frames per job. The fixture includes camera translation, a discrete
31.5° viewpoint cut at frame 30, surrounding colored markers and a two-bone
weighted strip. Independently calculated camera transforms and CPU-deformed
vertices supply the references.

| Godot / renderer | Warmup | Border | Additional coverage | Result |
| --- | ---: | ---: | --- | --- |
| 4.5.1 Compatibility / OpenGL | 0 | 0% | Parent attachment | Pass |
| 4.6.3 Compatibility / OpenGL | 8 | 12.5% | Parent attachment | Pass |
| 4.7.2 Compatibility / OpenGL | 8 | 0% | Parent attachment | Pass |
| 4.7.2 Forward+ / Vulkan | 8 | 0% | Old rig versus corrected rig and both references | Pass; old rig fails as expected |
| 4.7.2 Forward+ / Vulkan | 8 | 0% | TAA, identical native skin on both camera paths | Pass |
| 4.7.2 Mobile / Vulkan | 0 | 12.5% | External skeleton attachment | Pass |

The accepted matrix contains **1,080 source and 1,080 decoded MP4 frames**, including
the 60-frame old-rig comparison. The initial investigation retained another 180 of
each and exposes the same delay. Every corrected frame passes source MAE <0.03,
decoded MAE <0.1, and visible-foreground source MAE <0.25 on a 0–255 scale. A minimum
of 200 foreground pixels rejects empty-image comparisons. Foreground analysis was
added after rendering and rerun on all retained source pairs; the original JSON
and the stricter `skeletal-review-foreground.json` reports are both preserved.

The old Forward+ camera reaches 0.977643 whole-frame / 114.390816 foreground MAE
at the cut. Corrected Forward+ reaches 0.000023 source / 0.017935 decoded MAE;
its weighted skin reaches 0.000026 source / 0.019595 decoded MAE against the CPU
reference. Across the accepted cases, foreground MAE stays below 0.00465. TAA
uses identical native skinning on both sides because a rebuilt CPU reference mesh
has different motion-vector history. This validates viewpoint timing under TAA,
without claiming that the cut resets temporal history or eliminates ghosting.

The 128 headless skeletal checks test all six views across 63 samples for each of
parent/external attachments, including cut, repeated and backward samples. They
pass with the corrected rig and fail 124 checks with the old rig; the negative
control log is retained. The test also removes the source after scheduling a sync
to check that a pending callback cannot access a freed camera.

A separate rendered negative control delays only the CPU skin by one frame.
Its whole-frame MAE reaches just 0.010434, which would pass the original broad
threshold, but foreground MAE reaches 2.142772 and correctly fails the strengthened
0.25 limit. Its 60 source frames and metrics are retained under `cost/late-skin`.

### Workflow, motion and package regression

- **4,360 checks pass** in the full frozen-package matrix: 872 each on 4.5.1,
  4.6.3 and 4.7.2 Compatibility, plus 4.7.2 Forward+ and Mobile. This includes
  actual exports, playback, audio, cancellation, failures, recovery and storage.
- The existing analytic Motion Lab passes on 4.5.1 Compatibility and 4.7.2
  Forward+/Mobile: **540 source and 540 decoded frames**, marker error below 0.297°
  against a 0.45° limit, correct flash frames, and audio cue offsets below 0.71 ms.
- Six color/lit-material groups pass native-face and panorama-assembly checks at
  three sampled timestamps per group. These are sampled appearance checks, not
  an exhaustive decoded-frame comparison of those six additional exports.
- Protected project/settings/THRESHOLD recipe/master hashes match the earlier
  preservation record. All new jobs live under `.godot360/skeletal-review`.

The full matrix uses `.godot360/skeletal-review/candidate.zip` (138 members,
831,936 bytes), SHA256
`165145dfadf1e02fdbffa8d9f63d2199d79ec4e196d5356504e915778d08dcb4`.
The final package at `final/candidate.zip` differs only in the Python reviewer's
stronger foreground metric; all capture, authoring, planning and encoding code is
identical. It has 138 members, 832,080 bytes, SHA256
`103f44f37b570a6038f090ce4e0e9f87ef34fae27465eb36c263478253303e87`.
An additional **739 final-package headless checks pass** and verify manifest, source
inventory and identical rebuild. Local `final-review.json` aggregates the evidence.

### Backward compatibility and measured cost

Four separate Forward+ runs use the same independently positioned direct camera
and native skin, in old/new/new/old order, after all other test jobs finish.
Each submits 68 frames, including eight warmup frames. Capture elapsed times are
5.703665 / 4.405480 / 4.726263 / 4.411110 seconds. The two-run means are 5.057388 s
old and 4.565872 s new (9.7% lower in these short trials), but the first old trial
is slower than all later ones. This is insufficient evidence for a speedup or a
production overhead estimate. Peak VRAM and long-run costs remain unmeasured.
The implementation adds one deferred call per process frame and no extra viewport
or GPU pass.

All **240 delivered source and 240 decoded frames** in this comparison match
exactly across old/new capture. Re-encoding a corrected capture to CRF 22 passes
all delivery checks while preserving every source-file hash and the original
capture settings. This brings inspected motion/skeletal/direct-camera evidence
to 2,040 source and 2,040 decoded frames when the initial investigation is included,
plus the separate 60 source frames of the deliberately delayed skin control.

### Hosted CI

Private implementation `f9e72f4` passes [hosted run 34246410434](https://github.com/blugart-dev/godot360-studio/actions/runs/34246410434).
Linux passes **875 package/workflow checks**, three skeletal exports (180 source
and 180 decoded frames, external attachment, zero warmup, Mesa llvmpipe), and all
eight Forward+/Mobile color/lit/glow/compositor cases under software Vulkan. The
skeletal foreground errors remain below 0.0042. Mac passes **741 headless checks**.
Both platforms rebuild the exact final package hash above; reports and the Linux
comparison sheet were downloaded and inspected under `ci-linux` and `ci-mac`.

Attempt 1 was cancelled during slow downloads from the Ubuntu package mirror,
before any addon tests started. Its log is retained as `linux-attempt1.log`.
Retrying only the Linux job on a fresh runner completed successfully with unchanged
source (attempt 2). This is not a native Mac graphical or hardware-GPU Linux review.

### Remaining scope

This remains private 0.8 development. The selected camera's transform defines a
cut; changing another camera's `current` flag does not select it for capture.
Particles, imported character pipelines, IK/modifier chains, ragdolls, nested
attachments, physics interpolation, long temporal histories, FSR, GI and stateful
compositors remain outside this fixture's coverage. Shared adaptive exposure,
production 4K/8K Forward+/Mobile endurance/VRAM, native Mac graphical and Linux
hardware-GPU workflows, and the private final delivery review remain 1.0 work.
No public release or upload is authorized by this increment.

## Consistent authored exposure — 2026-09-08

This increment adds explicit **Fixed (authored)** capture exposure. Scene remains
the default. The worker copies effective camera/world attributes, disables automatic
metering on its copy, and follows authored exposure, physical settings and DOF each
frame without modifying the source. This is an authored-exposure workflow; shared
adaptive spherical metering remains open. See the [illustrated result](exposure-consistency.md)
and [supported behavior](../addons/godot360/RENDERERS.md#capture-exposure).

### Rendered comparisons and motion

Windows 11 / RTX 3060 Ti / Godot 4.7.2 was used for eight comparison groups. Each
group renders Scene, Fixed, an independently authored no-auto-exposure oracle, and
a legacy request without the new field. Every job delivers 90 frames at
2048×1024 / 30 FPS, with a 512 core, eight warmup frames, Fast PNG and CRF 16.

| Comparison | Backend | Measured boundary discontinuity reduction |
| --- | --- | ---: |
| Moving emitter, camera-level practical attributes | Forward+ / Vulkan | 99.73% |
| Same fixture, WorldEnvironment attributes | Forward+ / Vulkan | 99.73% |
| Same fixture, physical camera attributes | Forward+ / Vulkan | 99.68% |
| Same fixture, 12.5% borders in both versions | Forward+ / Vulkan | 57.41% additional reduction |
| Lit/metallic spheres, transparency and shadow maps | Forward+ / Vulkan | 98.18% |
| Moving emitter with world attributes; lit-material fixture | Mobile / Vulkan | No appearance change; native auto exposure is absent |
| Moving emitter with physical attributes | Compatibility / OpenGL | No appearance change; native auto exposure is absent |

The metric measures excess gradient at cube boundaries, including geometry/effect
residuals; it is not a general appearance score. Borders already soften the metering
cut, which explains their smaller additional percentage. The moving fixture includes
camera rotation, an emitter crossing faces, a lighting cut, an exposure curve and a
runtime attribute replacement. The lit fixture adds camera motion, an ambient-light
cut and animated exposure to the existing material laboratory. Native perspective
views of retained frames were visually inspected; the documentation sheets are
unmodified copies of the accepted results. Other lighting/effect seams remain.

All **2,880 source and 2,880 decoded frames** were checked. Fixed matches the authored
oracle exactly in every group, including the delivered decoded video. Default Scene
and legacy output also match exactly except for one Mobile repeat: source mean RGB
difference is at most 0.00000144/255, and decoded mean RGB difference at most
0.025318/255 per frame. Frame counts and timing match. Small native rounding changes
can change CRF encoder decisions beyond the original pixels; a maximum decoded
channel difference of 59 was recorded in that repeat, so byte equality is not a
general repeated-render guarantee. The reviewer retains exact hashes and falls back
to decoded pixel comparison with a 0.1/255 maximum frame-mean tolerance. Source
comparisons retain their 0.02/255 frame-mean tolerance. Fixed versus oracle still
matches exactly, without using the decoded-pixel fallback.

The original Mobile strict-hash rejection remains in `appearance-mobile/exposure-review.json`;
the accepted pixel analysis of those same retained deliveries is
`appearance-mobile/exposure-review-pixel.json`. There was no capture-code change
or replacement of that failed evidence. Each of the eight comparison groups also
passes a real re-encode at CRF 22, retaining all original file hashes and the complete
capture-settings dictionary. All 40 comparison/re-encode deliveries pass 13 checks.

Five additional six-second analytic motion jobs use **Fixed** and **12.5% borders**
with source attributes explicitly enabling auto exposure: Compatibility on Godot
4.5.1/4.6.3/4.7.2, and Forward+/Mobile Vulkan on 4.7.2. All **900 source and 900 decoded
frames** pass marker geometry, rear seam, pole and flash timing. Maximum angular
error is below 0.298°, within the 0.45° tolerance; all source/encoded audio cues are
within 0.71 ms. All five re-encodes retain source hashes and capture settings.
These runs shared the machine with regression work and are not timing benchmarks.

### Cost

A separate Forward+ timing run used the moving fixture with no other test jobs
running: two trials each, ordered Fixed / oracle / oracle / Fixed. The oracle is
the same scene authored without auto exposure. Each trial captures 98 submitted
frames including warmup. Fixed attribute synchronization averages **0.0238–0.0246 ms
per submitted frame**, versus about 0.0057 ms for the existing attribute-reference
path. It adds no viewports, render passes or image readbacks.

Measured whole-capture times, including readback/writer completion and excluding
worker startup, were **14.134 / 13.679 s for Fixed** and **13.446 / 11.792 s for the
oracle**. The Fixed average is **10.2% slower in these short trials**. Report this
observed cost alongside the small CPU measurement; two trials with visible timing
variation do not establish a production overhead or explain the full elapsed-time
difference. These are 2K fixtures, with no new peak-VRAM or 4K/8K endurance claim.
Production profiling remains a 1.0 workstream. Evidence: `cost/review.json`.

### Package, compatibility and preservation

The frozen implementation passes the complete package workflow, including rendered
export/playback, audio, cancellation, recovery, storage failures and clean-project
release checks:

| Windows engine / renderer | Checks passed |
| --- | ---: |
| Godot 4.5.1 / Compatibility | 744 |
| Godot 4.6.3 / Compatibility | 744 |
| Godot 4.7.2 / Compatibility | 744 |
| Godot 4.7.2 / Forward+ / Vulkan | 744 |
| Godot 4.7.2 / Mobile / Vulkan | 744 |

The **3,720-check** matrix package SHA-256 is
`55422d47a9db310529e743a17c2320a2fad4f0fa5389b62a3af5fba017945282`.
The new 57-check exposure suite covers camera/world precedence, animation,
replacement/removal, physical projection, source resource preservation, legacy
defaults, portable recipes, estimates and malformed re-encode input.

Visual QA found and corrected a stale border hint. The final panel then passed
**43 usability checks per engine, 129 total**, and was visually checked at 1100×600.
The first standalone panel harness omitted FFmpeg paths; its four setup failures
are retained separately. The corrected harness passes with the real tool paths.
Final-package differences from the full matrix are exactly the panel hint, the
Python reviewer's decoded-pixel fallback described above, and changelog wording.
Capture, projection, exposure, planning and encoding code are identical. Final ZIP:
**134 members, 824,216 bytes**, SHA-256
`0f91481aa7cab55bca4cb048f6ee42f0e5dc3d6914c1aa493a77a7d921fd8f6d`.
Its manifest matches source and its extracted source rebuilds it byte-for-byte.

All evidence is under `.godot360/exposure-review/`: `final-review.json`, the three
`package-*` reviews, six `appearance-*` groups, `lit-forward` / `lit-mobile`,
`motion-fixed`, `cost`, and `final/candidate.zip`. `run_lit.py` retains the disposable
wrapper around the checked-in material laboratory; `run_motion.py` records the
analytic fixture's source-attribute injection. The default exposure fixture and
reviewer are packaged. No accepted capture contains a script/parse error; expected
sandbox certificate-store warnings are separate from rendering failures.

Original project configuration, local settings, THRESHOLD recipe and film master
match their prior recorded hashes. The initial pre-change/default PNG comparison
has at most 0.00000159/255 frame-mean difference and one-level channel rounding.
The predecessor `bef3b9e` has a green [Linux/Mac hosted run](https://github.com/blugart-dev/godot360-studio/actions/runs/34235851891).
This remains private 0.8 development. Shared adaptive exposure, complex temporal
scenes, native Mac graphical / Linux hardware-GPU workflows, production endurance
and the final private delivery walkthrough remain open; no public release occurred.

The implementation was pushed privately as `afcfbc5`. Its
[hosted Linux/Mac run](https://github.com/blugart-dev/godot360-studio/actions/runs/34241199252)
also passes: **747 Linux package/workflow checks**, eight additional Forward+/Mobile
software-Vulkan appearance cases, and **613 macOS headless checks**. Both platform
packages have the exact final SHA-256 above and verify reproducible rebuilds. The
new 57-check exposure contract suite passes on both hosts. Evidence is retained in
`ci-linux`, `ci-mac` and `hosted-ci.json` under the same local review folder. This
adds final-package cross-platform regression evidence, with the same headless/
software limitations; it does not validate native Mac graphical or Linux GPU capture.

## Capture borders and private 1.0 development — 2026-09-08

The owner clarified that the addon stays private until 1.0 is implemented, tested
and ready. The historical independent-beta gate no longer blocks development.
[Release readiness](release-readiness.md) lists the remaining work and scope.
This increment adds optional capture borders and smooth overlap blending,
including three-face corners. Defaults remain zero; recipes/settings persist the
choice, estimates become stale after a change, and re-encoding retains the
original capture settings and pixels.

### Rendered glow comparisons

`tests/border_review.py` runs four actual export jobs per renderer: glow on/off,
each with zero and 12.5% borders. Every job delivers 90 frames at 2048×1024 / 30 FPS,
with a 512 core, eight warmup frames, Fast PNG and CRF 16. Windows 11 / RTX 3060 Ti /
Godot 4.7.2 / Vulkan was used for Forward+ and Mobile. All eight deliveries pass
their 13 media checks. The review measures every frame across an equatorial edge,
three-face corner and top edge, with a fixed-count excess-gradient score at cube
boundaries. It excludes the emitter core and compares no-glow controls separately.

| Crossing | Forward+ reduction | Mobile reduction |
| --- | ---: | ---: |
| Equatorial edge | 99.60% | 98.77% |
| Three-face corner | 99.19% | 98.20% |
| Top edge | 99.47% | 98.81% |

Maximum whole-frame mean RGB difference in no-glow controls is 0.000893 for
Forward+ and 0.000806 for Mobile, on the 0–255 scale. Before/after perspective
sheets were visually inspected; [the illustrated comparison](capture-borders.md)
uses unmodified copies. The cuts are reduced, but the corner halo still changes
shape and Mobile's glow differs from Forward+'s. The metric is not a general
appearance score. At 12.5%, face pixel count grows 56.25%; these short runs do not
establish production VRAM or timing overhead.

Evidence is under `.godot360/seam-review/forward-blended/` and `mobile-blended/`,
including `border-review.json`, per-frame scores, capture settings, images and
pipeline logs. Earlier border-only experiments left a visible three-face cut;
the accepted shader blends valid overlaps instead. Those experiments are not the
accepted result. Shared exposure and arbitrary view-dependent effects remain open.

### Package and workflow regression

The frozen border implementation passed the following full local package reviews,
including contracts, rendered playback/export, audio, cancellation, recovery,
storage failures and the clean-project release workflow:

| Windows engine / renderer | Checks passed |
| --- | ---: |
| Godot 4.5.1 / Compatibility | 669 |
| Godot 4.6.3 / Compatibility | 669 |
| Godot 4.7.2 / Compatibility | 669 |
| Godot 4.7.2 / Forward+ / Vulkan | 669 |
| Godot 4.7.2 / Mobile / Vulkan | 669 |

The 3,345-check matrix and reproducible-package reports are under
`.godot360/seam-review/final-validation/`. This snapshot's package SHA-256 is
`fc9e7b81c030cac9baf3f48bfc25271feba11298ed17834a0dd39da5ce6ad055`.

A subsequent review hardened malformed saved-border data in estimate/re-encode
handling and corrected FOV warning/reference wording. Final package checks pass
**177 per engine, 531 total** across 4.5.1/4.6.3/4.7.2: 54 renderer/projection,
42 planning/re-encode, 41 export validation and 40 usability/persistence checks.
The comparison against the full-matrix package records exactly five changed
files: the planner, its two test files, capture warning text and addon README.
The capture rig, shader and remaining runtime are identical. Final package:
129 members, 813,525 bytes, SHA-256
`3943c6475e76d009f798642b3df2be7abf54124f69c6e40ac8519758268220a3`.
Its manifest matches source and it rebuilds byte-for-byte from its extracted
source with the same Python/zlib runtime. Evidence:
`.godot360/seam-review/accepted-final/review.json` and `candidate.json`.

### Final-package motion, audio and panel review

The final package then rendered the six-second analytic motion fixture at
2048×1024 / 30 FPS, a 1024 core, two warmup frames and **12.5% borders** on all
five combinations in the table above. All **900 source and 900 decoded frames**
pass marker position/area, rear-seam, pole and flash-timing checks. Maximum marker
position error stays below 0.31°, within the test's 0.45° tolerance. Every source
and encoded audio cue stays within 10 ms, with no unexpected cue windows.

Each capture was also re-encoded at a different CRF. All five new deliveries pass,
retain exactly the original capture-settings dictionary and leave every source
file hash unchanged. Evidence is under `.godot360/seam-review/motion-blended/`,
with `summary.json` and per-case motion/re-encode reports. The final expanded
Advanced panel was captured at 1100×600 and visually inspected: the border control,
2560-pixel target and 56% extra-pixel hint are visible and wrap within the panel.

Local documentation links/anchors, Python syntax and Git whitespace checks pass.
The user's original project configuration, studio settings, THRESHOLD recipe and
film master match the earlier recorded hashes. The expected sandbox certificate
store warning appeared; the accepted runs contain no capture script error.

The preceding documentation commit `0c3cb24` also has a green
[hosted Linux/Mac run](https://github.com/blugart-dev/godot360-studio/actions/runs/34230197618).
That hosted run predates capture borders and is not new-border CI evidence.
No public release or upload was performed.

## Visual documentation — 2026-09-08

The README and guides now show actual film output and the current panel before
installation details. [Media provenance](media/README.md) records source hashes,
excerpt timestamps and regeneration. Preview assets total about 11 MB including
the portable PNG; full renders remain ignored. No capture, renderer, playback or
other addon runtime code changed. The only packaging change includes guide PNGs
and their `.gdignore` from `addons/godot360/media/`.

Verification under `.godot360/docs-review/` includes:

- All 140 local links across the initial 12 edited/new user guides resolve,
  including Markdown anchors; screenshot references also resolve in the addon ZIP.
- The GIF has 80 frames, eight seconds and an infinite loop; a decoded contact
  sheet of all four excerpts was inspected. All JPEG/PNG assets decode successfully.
- The full preview MP4 decodes without errors: 60 seconds, 960×540, 30 FPS,
  H.264/AAC stereo, BT.709, and no spherical side data. It is labeled as a flat
  perspective preview throughout the documentation.
- The real panel was captured graphically on Godot 4.7.2 / Windows / RTX 3060 Ti
  with the THRESHOLD recipe and native review paused at 35 seconds. Source project,
  studio settings, recipe and original delivery hashes remain unchanged.
- A local Markdown browser preview was visually inspected for the README's first
  screen and the tour's image gallery/captions. It is a local rendering, not a
  claim of GitHub-hosted rendering or public video playback.
- The 124-member package verifies against source and rebuilds byte-for-byte from
  its extracted source with the same bundled Python/zlib runtime. Final package:
  `.godot360/docs-review/review-candidate.zip`, 804,112 bytes, SHA-256
  `45efd85cb651722759ad24d22bcab020ad7dfb34b4fe5b07dc9e3d1df288e06b`.
  An initial comparison across two Python/zlib runtimes differed in compressed
  bytes; matching the build/rebuild runtime resolves that comparison.
- Python syntax and Git whitespace checks pass. The known sandbox certificate-store
  warning appeared during Godot capture; there was no capture script error.

The existing backend validation remains applicable; a full export matrix was not
rerun for documentation and package media. The new local screenshot is not new
platform support evidence. No release was published.

## Hosted macOS playback codec fix — 2026-09-08

GitHub Actions runs for `a037209` and `85a924a` failed in the Mac playback suite;
their Linux jobs passed. The retained encoder log reports
`Unknown encoder 'libtheora'`. Homebrew's basic FFmpeg build could produce the
H.264/AAC test MP4 but could not prepare its Theora review copy. This was not a
recent-exports regression. The earlier Windows check counts did not cover hosted
CI, and the failed Mac jobs are not counted as successful validation.

Commit `203cd56` installs [Homebrew's full FFmpeg formula](https://formulae.brew.sh/formula/ffmpeg-full)
and prepends its keg-only `bin` directory to the runner PATH. Both CI lanes now
encode and probe a one-second Theora/Vorbis clip before package review. Mac user
setup instructions select the explicit full-build tool paths. Addon runtime and
test contracts are unchanged. All six workflow Bash blocks pass syntax checks;
the exact new codec step also passes locally on Windows FFmpeg 9.0.1.

The [corrected hosted run](https://github.com/blugart-dev/godot360-studio/actions/runs/34169487525)
passes the Mac lane with **505 checks** on macOS 15.7.9 / arm64, Godot 4.7.2 and
FFmpeg/FFprobe 9.0.1. This includes 35 playback, 32 history, 58 capture-lifecycle
and 56 storage-failure checks. The package report confirms verified manifest,
identical rebuild and unchanged payload/package. Mac package SHA-256:
`b265667746bb24ead9fbe9534a40672da08908fab8ad04368b82aa12eb4d3adf`.
The codec probe identifies both Theora video and Vorbis audio. Reports/logs are
retained locally under `.godot360/ci-fix/hosted-macos/`; local shell/codec evidence
is in `.godot360/ci-fix/local-review.json`.

The same run's **Ubuntu 24.04 lane passes 639 checks**, including rendered export,
native playback, history, recovery and storage workflows with Mesa software OpenGL.
It also passes eight appearance cases: color, lighting, glow and a compute
compositor under each of Forward+ and Mobile with software Vulkan. Both renderer
reports have `ok: true`. Linux's package has the same SHA-256 as Mac and passes
the same manifest/rebuild/preservation assertions. Evidence is under
`.godot360/ci-fix/hosted-linux/`. The overall Actions run is **successful**, with
1,144 package/workflow checks across both platforms; the eight renderer cases
are separate. These hosted results supersede earlier notes that CI was only
prepared or unobserved. Software rendering does not establish Linux hardware-GPU
compatibility or production performance.

Mac evidence is headless: conversion, native playback clocks/audio and control
behavior are tested, but no graphical export, rendered-pixel review or Mac GPU
compatibility is claimed. Independent beta and hardware-platform gaps remain.
No release was published. Later root documentation edits do not change tested code.

## Recent exports — 2026-09-08

The unreleased panel remembers up to 12 launched/opened export folders, displays
job type, saved state and scene/video details, and opens selections through the
existing recovery/playback flow. Forget removes only the history entry. Listing
reads at most 1 MiB per job/status/report file and never scans capture frames or
contacts coordinators. No capture, renderer, encoding or playback implementation
changed. See the [quick start](../addons/godot360/QUICKSTART.md).

**201 focused checks pass** on Windows / RTX 3060 Ti:

| Scope | Checks | Evidence under `.godot360/recent-validation/` |
| --- | ---: | --- |
| Godot 4.5.1 / 4.6.3 headless history, clean imports of frozen ZIP | 33 each | `package-engines/review.json` |
| Godot 4.7.2 headless history and separate graphical history | 33 each | `dev4/review.json` |
| Godot 4.7.2 existing graphical first-export usability | 37 | `dev4/review.json` |
| Godot 4.7.2 actual calibration/Motion Lab export, review and diagnostics workflow | 32 | `dev4/review.json` |

History cases cover migration, persistence, bounded/deduplicated paths, Windows
case/slash aliases, spaces/Unicode, missing drives, malformed/oversized metadata,
unconfirmed progress, missing delivery artifacts, active-job/session guards,
selection stability, and forgotten entries remaining forgotten after restart.
The real workflow verifies a completed sample appears in history and a reopened
Motion Lab delivery reuses its native playback cache. The expanded 1100×600 panel
screenshot under `dev4/4.7.2/.godot360/recent-*/recent-panel.png` was inspected.
Both review reports confirm source project/settings hashes remain unchanged.

`candidate.zip` has 121 members, 241,298 bytes, SHA-256
`38426a27f628268d49b9ba00e673413a09882a06793b5d521443fe11e32f04b8`.
It verifies against current source and rebuilds byte-for-byte from a fresh
unpacked copy using Python 3.14. `summary.json` records exact equivalence of all
93 packaged Godot code/resource files with the already-tested 4.7.2 copy, avoiding
duplicate renders. Python packaging/reviewer syntax and Git whitespace checks pass.

Early development caught an unsupported numeric format and corrected it before
acceptance. Import uses isolated editor-data directories; the known sandbox root
certificate-store message is excluded from runtime failure detection. Earlier
development attempts are not counted. The accepted 1,800-check playback matrix
below remains backend regression evidence; this was not another full matrix run.
No new Linux/macOS, renderer endurance, YouTube or independent beta evidence was
gathered. Glow/auto-exposure seams and arbitrary capture resume remain unresolved.
No release was published. Subsequent root documentation edits require no rerun.

## Native playback and scene notes — 2026-09-08

The current unreleased addon plays a completed delivery through a cached native
Theora/Vorbis review copy up to 2K / 30 FPS. It adds seeking, pause, replay, mute,
asynchronous preparation and cancellation, visible capture warnings and broader
saved-scene advice. Capture, encoding and spherical delivery code remain unchanged.
See [Playback](../addons/godot360/PLAYBACK.md) for user-facing limits.

### Exact-package workflow

The final package is `.godot360/playback-validation/final-candidate.zip`, SHA-256
`863eb98bb340ca030e3f6f44b1d6d8a82d074f4e92015687ac9db1d6ab155d45`.
It contains 118 members, is 233,478 bytes, verifies against source and rebuilds
byte-for-byte with the bundled Python/zlib runtime. The three final package
reports under `.godot360/playback-validation/` each have `ok: true`, verified
manifest, identical rebuild and unchanged payload/package:

| Windows / RTX 3060 Ti / Compatibility | Checks | Report folder |
| --- | ---: | --- |
| Godot 4.5.1 | 600 | `final-4.5.1/` |
| Godot 4.6.3 | 600 | `final-4.6.3/` |
| Godot 4.7.2 | 600 | `final-4.7.2/` |

The **1,800 checks** include existing capture/audio/recovery/storage workflows,
35 headless playback checks and 41 native visual playback checks per engine, and
actual playback of the verified Motion Lab export. Tests verify native audio
reaches the mix bus, pause holds the clock, forward/backward seeks show the right
decoded intervals, a color patch returns to authored sRGB values, end/replay,
cache reuse, cancellation, failed codecs, injected low space, hidden-panel behavior,
source preservation and the 1100×600 completed-job layout.

Separate native Godot 4.7.2 Forward+/Vulkan and Mobile/Vulkan playback runs each
pass 41 checks (`native-forward_plus/driver.log` and `native-mobile/driver.log`).
These are playback checks, not additional production-resolution renderer claims.

### THRESHOLD and actual editor

The unchanged 60-second 8K delivery produced a 2048×1024 review copy in **204.980 s**,
occupying **38,906,694 bytes (37.10 MiB)**. Six native seeks at 10, 22, 36, 50, 59
and 3 seconds reached the requested clock positions and decoded 2K images. A short
playback observation advanced 4.864 seconds during 4.846 seconds of wall time;
this is clock evidence, not a measured no-dropped-frames guarantee. The delivery
MP4's SHA-256 stayed unchanged.

Four native decoded snapshots compared against independently converted/scaled
master references have mean absolute channel errors of **1.64–1.78 / 255**;
99th-percentile errors are 7–10 code values. The first prototype omitted the
required transfer conversion and differed by 9.80–15.07 / 255 on these snapshots.
The corrected path explicitly converts BT.709 delivery pixels to sRGB transfer
and the BT.601 matrix used by Godot's native Theora decoder. The color-patch
regression covers this conversion in each native engine check.

Decoded audio has 2,880,000 stereo frames in both source and review copy.
Independent four-second windows beginning at 0.5, 28 and 55 seconds have zero
measured added lag. Mono-sum SNR measurements are 24.72–31.84 dB; the review is
lossy and no perceptual-quality certification is inferred from these measurements.

A separate **actual Godot editor** run, with `Engine.is_editor_hint() == true`,
finds and opens the installed bottom panel, reuses the copy, advances playback,
captures nonzero native audio and seeks to 36 seconds with a decoded 2048×1024
texture. Reports, native PNGs, reference comparisons and an editor screenshot are
under `threshold/.godot360/` (`threshold-review.json`, `pixel-review-corrected.json`,
`audio-review.json`, `actual-editor.json` and `actual-editor.png`).

### Findings and remaining scope

Development artifacts are retained separately. An initial package built with
system Python had different compressed ZIP bytes from the bundled-runtime rebuild;
building and reviewing with the same runtime resolved that expected zlib boundary.
The first full matrix passed all individual stages but its aggregate check still
counted only one graphical stage. The reviewer now compares the exact expected
stage names, and the final package was rerun successfully on all three engines.
No failed development package is counted as final acceptance.

This pass has no new Linux/macOS playback, hosted CI, YouTube or headset evidence.
Review copies are additional local storage, require libtheora/libvorbis and do
not replace full-resolution/final-frame-rate review. Existing glow, auto-exposure,
temporal-effect and partial-capture-resume limitations remain. No public release
was published. Subsequent documentation-only changes do not require repeating
this matrix while runtime and test behavior stay unchanged.

## Project renderer preservation — 2026-09-07

The old worker always forced Compatibility. The current worker uses the saved
project renderer/driver or explicit recipe overrides, records requested/resolved
and actual selection, and refuses a fallback before submitting frame zero.
Camera offset, animated clipping/cull/environment/attributes and camera compositor
now follow the source; AA, scaling, LOD, occlusion and shadow-atlas settings are
copied to the faces. The SDR sRGB PNG / BT.709 limited-range MP4 contract is retained.
See [the packaged renderer guide](../addons/godot360/RENDERERS.md) for user guidance.

### Accepted complete-package matrix

All seven engine/renderer combinations passed clean package import, contracts,
actual calibration and Motion Lab exports, audio/re-encoding, cancellation,
worker/encoder failure, recovery, storage-fault and editor-panel workflows.
These **3,662 checks** are separate from the appearance, motion and lock probes
below. Reports live under `.godot360/renderer-review/`:

| Host | Godot / renderer / backend | Checks | Report folder |
| --- | --- | ---: | --- |
| Windows 11 / RTX 3060 Ti | 4.5.1 / Forward+ / Vulkan | 522 | `final-forward/` |
| Same Windows host | 4.6.3 / Forward+ / Vulkan | 522 | `final-forward/` |
| Same Windows host | 4.7.2 / Forward+ / Vulkan | 522 | `final-forward/` |
| Same Windows host | 4.7.2 / Mobile / Vulkan | 522 | `final-mobile/` |
| Same Windows host | 4.7.2 / Compatibility / OpenGL 3 | 522 | `final-compatibility/` |
| Ubuntu / WSLg / llvmpipe | 4.7.2 / Forward+ / software Vulkan | 526 | `linux-final-forward_plus/` |
| Same Linux host | 4.7.2 / Mobile / software Vulkan | 526 | `linux-mobile-confirmed/` |

Every `package-review.json` above has `ok: true`, verified manifest, identical
rebuild and unchanged unpacked payload/package. Linux has four additional Unix
platform checks. The first six combinations use `final-candidate.zip`, SHA-256
`034915faa5d40d36721f7e75a65adae23771f0b36d1af2b9709a48f8692037da`.
Linux Mobile uses `documented-candidate.zip`, SHA-256
`858f08bbb480fdfdc653df16fad821e0d63953b456acf967423f649e4595e04c`:
the same addon runtime, with documentation updates and the lifecycle assertion
accepting the exact broken-pipe failure described below. Later documentation
edits do not imply another complete matrix run; source/package equivalence is
recorded in `summary.json`. These are local unreleased snapshots, not published
release artifacts.

### Native appearance evidence

All appearance exports below use Godot 4.7.2, 1024×512 output, 512-pixel faces,
30 delivered frames and eight warmup frames. Every successful export passes the
13 delivery checks. Three times (0, 15 and 29) have independent ordinary 90°
perspective renders plus six retained faces. Python maps panorama pixels back to
those faces and compares smooth regions to distinguish sampling/gamma errors
from the renderer's own view-dependent effects.

| Native host/backend | Cases and evidence under `.godot360/renderer-review/` |
| --- | --- |
| Windows 11, NVIDIA RTX 3060 Ti, Vulkan | `forward-vulkan/`: 12 cases; `mobile-vulkan/`: eight. Color patches, Filmic tone mapping, exposure, lighting/shadows, PBR, alpha transparency, glow, fog, physical camera attributes and compute compositors. Forward+ additionally exercises volumetric fog, combined SSAO/SSIL/SSR, SDFGI and TAA. |
| Same Windows host, D3D12 | `forward-d3d12/`: six cases; `mobile-d3d12/`: four. Actual driver identity recorded in every capture. |
| Same Windows host, ANGLE/D3D11 | `compatibility-angle/`: two color/lighting appearance exports with actual `opengl3_angle` identity. |
| Ubuntu 26.04, WSLg/X11, llvmpipe LLVM 21.1.8, Vulkan | `linux-forward_plus/` and `linux-mobile/`: four cases each, including glow and a compute compositor. Native Linux Godot and FFmpeg; hardware GPU/Wayland performance remains untested. |
| HDR reference comparison | `hdr-comparison/`: lit/glow compared to a native HDR 2D viewport; floating-point reference pixels receive independent sRGB transfer before comparison. |
| Additional GI/exposure fixture | `gi-exposure/`: matching darker-room SDFGI off/on captures and an auto-exposure capture. |

These are **45 appearance exports**, separate from repeated development jobs and
motion/package checks. Most SDR native/front-face pairs are exactly equal.
SDFGI's maximum measured native/front mean channel error is below 0.004/255;
HDR-reference lit/glow mean error is below 0.014/255 with 99th-percentile error
of one code value. Smooth-region panorama reconstruction has 99th-percentile
error at or below the three-code-value acceptance limit. `feature-differences.json`
also proves enabled effects change pixels; the darker GI room changes 99,478
pixels by more than three levels compared to its matching GI-off scene.

Images and motion strips were inspected, including Linux contact sheets.
`edge-motion.png` visibly shows glow halos cut off at cube boundaries. Auto
exposure produces large brightness changes between faces, visible in
`gi-exposure/auto_exposure/preview.png`. These artifacts are already in the
native face images; sampling/gamma fixes cannot supply off-face screen data or
shared exposure metering. They remain limitations of the current six 90° views.
TAA showed no large trailing artifact in the inspected simple motion sequence;
particles, skinned meshes, camera cuts and FSR reconstruction remain untested.

### Complete motion, sound and retained pixels

`forward-motion/motion/motion-review.json` and
`mobile-motion/motion/motion-review.json` pass every source and decoded frame:
180 PNGs plus 180 decoded MP4 frames per renderer, at 2048×1024, 1024-pixel faces,
30 FPS, six seconds and two warmup frames. Analytic markers cross cube edges,
the rear seam and both poles; flash frames match exactly. All three audio cues
are within 0.71 ms of their expected time in source/decoded audio, with no
unexpected loud intervals. This is fixture evidence, not universal scene sync.

`storage-override-review.json` verifies a real Forward+/Vulkan override from this
Compatibility project, identical decoded Fast/Compact PNG pixels, source hashes
unchanged after re-encoding at another CRF, original renderer evidence retained,
no capture child for re-encoding, and unchanged project/studio settings.
`startup-review.json` contains actual worker method/driver mismatches: both stop
at zero submitted frames with specific fallback diagnostics.

The renderer contracts add 21 checks for default/explicit selection, fallback,
stale estimates, camera offsets, animated settings, compositor propagation and
90° physical-camera projection. Two planning checks reject renderer relabeling
on re-encode. A new lifecycle case rejects a scene that instantiates with a broken
script, invalidating its misleading complete PNG count before delivery.

### Reliability findings and remaining scope

A concurrent Windows run hit a progress-JSON replacement failure beyond the old
50 ms retry window. `job_io.gd` now retries for roughly 500 ms, retaining the
previous complete file on failure. `json-lock/json-lock-review.json` verifies a
real native delete-sharing lock: a 180 ms transient lock recovered in 189 ms;
a permanent lock failed in 546 ms with the original JSON unchanged. Scheduling
can extend elapsed time slightly beyond the nominal retry delays.

Development package failures are retained, not counted as accepted evidence:
an old audio test expected pre-renderer estimates to remain usable; another
asserted every diagnostics renderer was Compatibility. Linux inherited the
intentional malformed-script stderr; the harness now recognizes that specific
fixture only. A killed Linux encoder can report either process exit or broken
pipe depending on timing; both require terminal failure and no final video.
An initial appearance fixture had a GDScript type error, and one ANGLE attempt
selected FFprobe as FFmpeg. Those failed attempts establish no renderer support.

No native Mac/Metal, Linux hardware GPU, Linux ARM, Windows Mobile 4.5.1/4.6.3,
baked LightmapGI/VoxelGI, stateful compositor histories or new Forward+/Mobile
4K/8K endurance result is claimed. CI adds Linux software-Vulkan appearance
exports and still separates Mac headless contracts; actionlint 1.7.12 passes,
but hosted Actions were not run. No release or commit was published.

The previous uncommitted portability/onboarding changes remain in the working
tree. A baseline patch is saved locally at `renderer-review/baseline.patch` under
`.godot360`; the original project configuration, scene selection, saved recipe
and existing captures were preserved.

## Desktop platforms — 2026-09-07

The same frozen addon ZIP passed **1,968 checks** across Windows and Linux:

| Host | Godot | Checks | Export coverage |
| --- | --- | --- | --- |
| Windows 11 x86_64, RTX 3060 Ti, FFmpeg/FFprobe 9.0.1 | 4.5.1 | 491 passed | Complete package review |
| Same Windows host | 4.6.3 | 491 passed | Complete package review |
| Same Windows host | 4.7.2 | 491 passed | Complete package review |
| Ubuntu 26.04 x86_64, WSL2/WSLg, Mesa 26.0.3 llvmpipe, FFmpeg/FFprobe 8.0.1 | 4.7.2 | 495 passed | Complete package review on a case-sensitive Linux filesystem |

Each full run includes fresh editor import, all contracts, actual calibration and
Motion Lab capture, audio mixing and re-encoding, interrupted capture cleanup,
reopening/recovery, storage failures, diagnostics and preview directions. All
thirteen delivery checks pass on completed outputs. The new platform suite checks
native child exit codes, literal arguments, Unicode paths/output and discovery;
Linux additionally checks execute permissions, symlinks and filename case.

Both platforms verify the ZIP manifest, reproduce identical ZIP bytes and leave
the package, extracted payload, source project and saved settings unchanged.
The Linux preview was visually inspected. Package evidence stays local:

- `.godot360/platform-review/candidate.zip`: **106 members, 198,494 bytes**;
  SHA-256 `be93e21515594d4613176da5846841b14587b3ade80fafa829eebce44e680359`.
- `.godot360/platform-review/windows/package-review.json` and its
  `engines/compatibility-review.json`: all three Windows engine results.
- `.godot360/platform-review/linux/package-review.json` and its
  `engines/compatibility-review.json`: copied Linux reports; corresponding logs
  and preview screenshots are preserved under the same directory.
- Original Linux projects and retained captures remain under
  `/var/tmp/godot360-platform-w0t720ix/package-review` in the existing Ubuntu WSL
  distribution. They use the native Linux Godot executable and `/usr/bin/ffmpeg`.
- A separate Linux `--headless-only` package run passed **408 checks** under
  `/var/tmp/godot360-platform-w0t720ix/headless-review`. Its report explicitly says
  `headless contracts only; no rendered export`. These repeated checks are not
  included in the 1,968 total and do not constitute Mac validation.

The [CI workflow](../.github/workflows/platforms.yml) passes **actionlint 1.7.12**.
It prepares a Linux/Xvfb/Mesa full-review lane and a macOS 15 headless lane. Hosted
runs have not been executed in this pass. Documentation checks found no broken
local file/heading links across the five setup/testing guides (58 checked).

Linux results establish functional exports with software rendering under WSLg.
They do not establish Linux hardware-GPU performance, standalone Wayland behavior,
ARM support or new Linux 4K/8K endurance evidence. **Native macOS editor/capture
validation remains pending on Apple Silicon and Intel.** Independent beta feedback
is still separate from these local automated checks. No release was published.

## First-export usability pass — 2026-09-07

The exact working-source package passed **1,443 checks: 481 per engine** on Godot
4.5.1, 4.6.3 and 4.7.2, Windows / Compatibility / RTX 3060 Ti / FFmpeg 9.0.1.
Each engine imported the addon in a separate clean project and passed its contracts,
37 new usability checks, actual audio/capture workflows, controlled interruption,
saved-job recovery, storage failures and the documented calibration/Motion Lab
workflow. Every delivered output passed all thirteen delivery checks.

Local evidence:

- `.godot360/usability-review/candidate.zip`: 102 members, 189,172 bytes; SHA-256
  `11bee63ee2893186ac2c4684d08a11d9d295b249701152e4105331248f9fb787`.
- `.godot360/usability-review/review/package-review.json`: manifest verified,
  identical extracted-source rebuild, unchanged package and unpacked payload.
- `.godot360/usability-review/review/engines/compatibility-review.json`: all three
  engine runs, individual counts and logs. Isolated-project settings are restored.
- `.godot360/usability-checks-final2.log` and `.godot360/usability-panel.png`: a
  separate 37-check GPU panel run and visual review at 1100×600. The existing
  quality/preset suite also passed eight checks at 1400×520 during this pass.
- `.godot360/usability-editor-check/editor-review.json`: six additional checks
  inside the actual Godot 4.7.2 editor confirm plugin hookup, current-scene selection,
  real scene-file saves before setup/render, and tool readiness. The disposable
  headless editor emits thumbnail/cache diagnostics; scene changes were read back
  from disk to verify saving. It does not use the user's open project.

The capture/encoding backend is unchanged. These checks validate the new interface
and its integration with existing export/recovery contracts; they do not broaden
hardware/renderer support or replace independent usability and YouTube review.
The package retains the 0.8 baseline version with explicitly unreleased changes.
Previous accepted packages remain unchanged; nothing was published in this pass.

## Environment

- Windows, Godot **4.7.2 stable**, Compatibility / OpenGL 3.3.
- The 0.6.1 addon-only matrix also exercises Godot **4.5.1** and **4.6.3** stable
  in separate projects; this does not broaden the interactive UMBRAL demo's coverage.
- NVIDIA GeForce RTX 3060 Ti.
- FFmpeg / FFprobe **9.0.1**, gyan.dev essentials build, libx264 and AAC enabled.
- Download SHA-256 verified against the publisher's checksum:
  `fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9`.
- Code, UI, and documentation are English. No external Godot addon source is included.

## Completed checks

| Check | Result |
| --- | --- |
| 0.8 exact-package installation | 1,332 checks pass on the actual ZIP: 444 each on Godot 4.5.1/4.6.3/4.7.2; enabled plugin import, 251 headless, 19 audio panel, 50 capture-failure, 41 reopening, 56 storage-failure and 27 release-workflow checks per engine |
| 0.8 diagnostics | Failed/completed/setup jobs; bounded log tails, empty stderr, malformed/oversized JSON, included byte hashes, existing ZIP/staging refusal, unavailable destinations, unchanged source bytes and real GPU/environment collection |
| 0.8 documented workflow | Draft 2K calibration, six distinct preview directions, actual save dialog, recipe save/reload, one-second Motion Lab sample and full six-second film at 512×256 on each engine; all 13 delivery checks; compact panel screenshots inspected |
| 0.8 package/source history | 84 ZIP members, 169,418 bytes; manifest/source/extracted inventory verified and byte-identical rebuild; local Git baseline at 23759d4 / v0.7.0 with the 0.8 work recorded separately |
| 0.8 YouTube review candidate | 12-second 7680×3840/30 FPS film re-encoded from the accepted capture; encoded MP4 identical to original, all 360 decoded frames/audio preserved, 719 offsets and 924 packet hashes/timestamps verified; V2-only recognition/decode passes; original source/settings unchanged; no specific YouTube review of this file recorded |
| THRESHOLD production and YouTube feedback | 60-second 7680×3840/30 FPS film with the unchanged 0.8 addon; 1,800 frames decoded, 60 source comparisons, all 13 delivery checks and 60 authoring checks pass; user reports it looks amazing in YouTube on 2026-09-07; detailed playback/device checklist not supplied; see [film record](threshold.md) |
| 0.7 storage and regressions | 1,143 checks in the three-engine matrix, plus six additional cancellation/log-write contracts per engine; 1,161 unique checks across Godot 4.5.1/4.6.3/4.7.2 |
| 0.7 controlled storage failures | Nine injected capacity/blocked-write cases per engine; preserve the last status on blocked replacement, publish no final video, retain eligible sources, and re-encode after a report-write failure with identical source hashes |
| 0.7 production capture | 60 seconds at 4096×2048/2048-pixel faces and 30 seconds at 7680×3840/3072-pixel faces, both 30 FPS; all 1,800/900 source and decoded frame codes/flash states pass; all thirteen delivery checks pass |
| 0.7 production audio | Five 4K and three 8K cues spanning beginning/middle/end share a +2-sample (+0.0417 ms) offset, zero measured drift and zero added AAC cue lag; AAC SNR 55.59/55.46 dB |
| 0.7 portable package | 78 members; two builds produce identical ZIP bytes; every archived byte matches source and the extracted package inventory |
| 0.6.3 compatibility and reopening | 306 checks per engine on 4.5.1/4.6.3/4.7.2, 918 total; 199 contracts, 16 audio panel, 50 capture-failure and 41 saved-job recovery checks per engine |
| 0.6.3 actual editor/coordinator loss | Reconnect after the launcher's exit, cancel the running GPU export, diagnose killed coordinator without altering stale status, reject unrelated live PID/stale reply, and re-encode the original completed source with unchanged hashes |
| 0.6.2 sustained GPU capture | 90 seconds at 1024×512, 512-pixel faces, 60 FPS, two warmup frames; all 5,400 PNG and decoded MP4 frame numbers/flash states correct; 13 output checks pass |
| 0.6.2 sustained scene audio | Seven cues from 0.5 to 88 seconds share a −222-sample (−4.625 ms) offset, with zero measured drift; encoded AAC adds zero cue lag and has 55.81 dB SNR against the recorded WAV |
| 0.6.2 compatibility and failure recovery | 265 checks per engine on 4.5.1/4.6.3/4.7.2: 199 headless contracts, 16 panel checks, 50 controlled-failure checks; six successful outputs pass all 13 checks |
| 0.6.1 engine compatibility | 208 checks each on Godot 4.5.1, 4.6.3 and 4.7.2: editor import, 195 headless contracts, 13 actual panel checks; six verified capture/re-encode outputs; isolated imports and unchanged original project/settings |
| 0.6.1 soundtrack formats | Eight PCM/MP3/Vorbis/Opus/FLAC/M4A/ADTS cases at selected mono/stereo rates from 22.05 to 96 kHz; 13 output checks each; zero measured cue lag, 53.2–55.6 dB decoded SNR |
| 0.6.1 longer mix | 90 seconds, 2,250 synthetic frames, 25 FPS, AAC/44.1 kHz soundtrack, independent offsets/levels and scene warmup; all 13 output checks, zero measured cue lag and 52.8 dB SNR |
| 0.6.1 delivery regressions | Limiter, byte-identical old encoded MP4 and source-mutation rejection pass with an explicit historical baseline path |
| 0.6 audio contracts | 31 checks, 0 failures; recipe persistence, trim/offset semantics, validation, file changes and stable planning signatures |
| 0.6 regressions | 37 export, 27 planning and 50 metadata checks, 0 failures |
| 0.6 audio panel | 13 checks, 0 failures; actual one-second mixed capture, planning, recipe/settings restoration, re-encode with new levels/offsets, unchanged source hashes and compact UI |
| 0.6 decoded audio | Ten successful six-second re-encodes; independent cue placement has zero measured sample lag and 53.7–57.9 dB SNR in non-silent cases; video packet payloads/timestamps unchanged across audio variants |
| 0.6 resampling | 44.1 kHz mono FLAC converted to 48 kHz stereo at 24/60 video FPS; zero measured cue lag; synthetic retained images, not new timeline motion captures |
| 0.6 early audio rejection | Corrupt and non-audio files fail before GPU capture and produce no final video |
| 0.6 limiter and legacy audio | Strong coincident sources produce a decoded peak of 0.950368 with no unexpected cue shift; default re-encode of the old three-frame capture matches its encoded MP4 byte-for-byte |
| 0.6 changing soundtrack | File modified during encoding is rejected without a final video; terminal failure status survives active file polling |
| 0.6 addon-only audio | Inherited mixed audio re-encoded in a minimal project with the original scene removed; all 13 output checks pass |
| 0.5 metadata contracts | 50 checks, 0 failures; V2 placement/fields, exact media preservation, stco/co64 relocation, cascading 4 GiB promotion, malformed-input rejection and copy cancellation |
| 0.5 export and planning regressions | 36 export checks and 27 planning checks, 0 failures |
| 0.5 complete headless re-encode | Three 512×256 frames from the retained 0.4 capture; all 12 output checks pass; source-folder hashes and saved studio settings unchanged |
| 0.5 addon-only re-encode | Same retained capture in a minimal project with only the addon; all 12 checks pass without the original scene installed |
| 0.5 Motion Lab delivery | All 358 chunk offsets and 463 packet hashes/timestamps match; 180 decoded frames and non-silent audio are exact; FFprobe recognizes V2 with V1 disabled |
| 0.5 full 8K delivery | All 719 chunk offsets and 924 packet hashes/timestamps match; all 360 decoded frames and stereo audio are exact; V2-only recognition and decoding also pass |
| Interactive scene regression suite | 48 checks, 0 failures |
| Export validation, quality advice, and MP4 metadata contracts | 36 checks, 0 failures |
| Quality/storage controls and compact panel layout | 8 checks, 0 failures |
| 0.3 planning and source validation contracts | 27 checks, 0 failures; estimates, stale settings, partial progress, frame/WAV validation, and re-encode storage |
| 0.3 planning panel integration | 21 checks, 0 failures; test render, estimates, re-encode at CRF 25, unchanged source hashes, and live 8K encoding cancellation |
| 0.3 addon-only headless re-encode | No original scene installed; full 12-second 8K source passes all 8 checks in 54.863 s, with matching encoded MP4 SHA-256 |
| 0.3 production planning sample | One second at 4096×2048, 2048-pixel faces, 30 fps, Fast PNG, CRF 16; all 8 checks pass in 13.304 s |
| 0.4 timeline contracts | 24 checks, 0 failures; absolute seeking, discrete state, camera motion, invalid duration/track handling |
| 0.4 Motion Lab panel export | 8 checks, 0 failures; six seconds at 4096×2048, 2048-pixel faces, 30 fps, CRF 16; all MP4 checks pass in 36.395 s |
| 0.4 motion and audio, 30 FPS | All 180 source and 180 decoded MP4 frames checked; two warmup frames; exact flash timing, marker errors below 0.30°, encoded cue onsets within 0.71 ms |
| 0.4 motion and audio, 24 FPS | All 144 source and 144 decoded MP4 frames checked; zero warmup; exact flash timing, marker errors below 0.30°, encoded cue onsets within 2.05 ms |
| 0.4 addon-only authored capture | Timeline example in a minimal project, three delivered frames at 512×256; all 8 MP4 checks pass |
| 0.4 invalid timeline integration | A recipe longer than its animation stops with the expected capture error and no final video |
| Fast PNG writer | 26 checks, 0 failures; actual RGB/RGBA round trips, ordering, interruption, and cleanup |
| Storage comparison | All 6 decoded 8K frames match exactly between Compact and Fast PNG |
| Compact PNG fallback in 0.2 | 3 delivered frames at 512×256; all 8 MP4 checks pass |
| Addon-only installation in 0.2 | 6-frame Fast PNG export in a separate minimal project; all 8 MP4 checks pass |
| Quality report pipeline smoke test | 512×256, 3 frames; warnings recorded and all 8 MP4 checks pass |
| Studio panel end-to-end test | 7 checks, 0 failures, including preview drag and cancellation |
| UMBRAL film | 2048×1024, 30 fps, 360 decoded frames, 12 seconds; all 8 MP4 checks pass |
| UMBRAL quality replacement | 7680×3840, 3072-pixel faces, 4× MSAA, CRF 16, 30 fps, 360 decoded frames, 12 seconds; all 8 MP4 checks pass |
| UMBRAL Fast PNG replacement | Same 8K settings and delivered frames; 166.656 s capture, 220.257 s full pipeline; all 8 MP4 checks pass |
| Full-film media preservation | Old and new `encoded.mp4` SHA-256 match; source WAV SHA-256 also matches |
| Calibration audio preservation | Old and new non-silent source WAV SHA-256 match |
| 4K calibration smoke test | 4096×2048, 30 fps, 3 delivered frames; all 8 MP4 checks pass |
| Calibration export through panel | 2048×1024, 30 fps, 60 decoded frames, 2 seconds; all 8 checks pass |
| Clean-project installation | Only the addon copied into a minimal project; editor import and a 6-frame 512×256 export pass |
| Audio content | Calibration tone survives AAC encoding; 96,000 samples per channel over 2 seconds, peak about −26.25 dBFS |
| Projection review | FFmpeg independently reprojects the panorama into six cube faces; all directional labels, poles, and asymmetric markers have the expected orientation |
| Visual review | Studio UI, calibration cube views, and UMBRAL panoramic output inspected |

Through 0.4, the pipeline's 8 MP4 checks were resolution, decoded frame count, FPS, video duration,
H.264/yuv420p, BT.709 tags/range, AAC stereo/48 kHz, and spherical mapping recognized
by FFprobe. The tests intentionally reject incomplete or incorrectly tagged output.
Version 0.5 adds four container checks: V1 presence, the full mono V2 profile,
moov before media, and chunk-offset bounds. Version 0.6 adds audio duration within
one 48 kHz sample of the video duration. All thirteen must pass before the staged
file receives its final name. The historical eight/twelve-check results remain
evidence for their original versions.

The clean-project test has no dependency on UMBRAL scenes, scripts, global class
names, or assets. Its only source is `addons/godot360` plus a minimal `project.godot`.
The FFmpeg executable remains an external dependency in both projects.

## Local evidence

- `.godot360/audio-checks-06.log`, `audio-studio-06.log`, `export-checks-06.log`,
  `planning-checks-06.log`, `metadata-checks-06.log` and `audio-panel-06.png`.
- `renders/audio-06-timed/audio-review.json`: offsets, trims, levels, padding,
  silence, mixed audio, mono resampling, 24/30/60 FPS and preflight failures.
- `renders/audio-06-delivery-complete/audio-delivery-review.json`: limiter,
  exact legacy encoded bytes, and source mutation rejection.
- `renders/audio-studio-06/test-2026-09-06T23-09-15-1789555/` and
  `reencode-2026-09-06T23-09-22-9341312/`: successful actual panel jobs.
- `.godot360/portable-06/output/report.json`: inherited mixed audio without the original scene.
- `dist/umbral360-studio-0.6.0.zip`: portable addon, audio guide and tests.
- `.godot360/metadata-checks-05.log`, `export-checks-05.log`, and `planning-checks-05.log`.
- `renders/delivery-05-motion/metadata-review.json`: independent media, timestamps,
  decoded video/audio and V2-only recognition checks on the six-second motion film.
- `renders/delivery-05-8k/metadata-review.json` and `video-360.mp4`: the 12-second
  8K film with V1/V2 and fast-start; original encoded SHA-256 still matches the
  earlier recorded `AA65D1E53BB6B7C07FDE82CD4F2ACD68BDE5C94609F2989D0A1A52BA1F103C2D`.
- `renders/delivery-05-reencode/report.json`: complete pipeline with all 12 checks.
- `.godot360/portable-05/output/report.json`: minimal-project re-encode with all 12 checks.
- `dist/umbral360-studio-0.5.0.zip`: portable addon, guides, examples and tests.
- `renders/umbral-first-film/video-360.mp4` and `report.json`.
- `renders/calibration-4k-check/`.
- `renders/studio-checks/` (successful and cancelled integration jobs).
- `.godot360/runtime-checks.log`, `export-checks.log`, and `studio-checks.log`.
- `.godot360/studio-preview.png` and `calibration-cube-later.png`.
- `.godot360/portable-project/output/report.json`.
- `.godot360/export-checks-quality.log`, `quality-panel-checks.log`, and `quality-panel.png`.
- `renders/quality-report-check/report.json`.
- `renders/umbral-quality-8k/`: final MP4, report, capture settings, and local quality review.
- `.godot360/quality-before.png` and `quality-after.png`: the same animation frame
  and 90-degree view, independently reprojected by FFmpeg from 2K and 8K source PNGs.
- `.godot360/quality-after-encoded.png`: a matching frame decoded from the final
  8K MP4; sharper text and outlines remain visible after encoding.
- `.godot360/quality-eight-k-cube.png`: a later 8K frame reprojected into all six directions.
- `renders/performance-baseline-8k/` and `renders/performance-fast-8k/`.
- `renders/umbral-fast-8k/report.json` and `performance-review.json`.
- `.godot360/frame-writer-checks.log`, `export-checks-02.log`, `quality-panel-02.log`, and `studio-02.log`.
- `.godot360/portable-02/output/report.json` and `renders/compact-02-check/report.json`.
- `.godot360/planning-checks.log` and `planning-studio-checks.log`.
- `.godot360/studio-03.log`, `quality-panel-03.log`, and `export-checks-03.log`.
- `renders/planning-studio-checks/`: sample, re-encode, and active-encoding cancellation evidence.
- `.godot360/portable-03-reencode/output/report.json` and `encoded.mp4`.
- `renders/test-2026-09-06T21-52-29-2066321/`: actual 4K planning sample and estimate.
- `.godot360/production-plan.png`: the completed sample and compact panel layout.
- `.godot360/timeline-checks.log`, `timeline-studio-checks.log`, and `studio-04.log`.
- `renders/timeline-studio-checks/render-2026-09-06T22-18-00-1693637/`: full 4K authored film.
- `.godot360/motion-lab-panel.png`: actual panel with the completed 4K example.
- `renders/motion-04-timed/motion-review.json`: 30 FPS source/encoded geometry and audio.
- `renders/motion-04-24fps-final/motion-review.json`: 24 FPS, zero warmup, source/encoded geometry and audio.
- `.godot360/portable-04/output/report.json`: addon-only authored capture.
- `.godot360/portable-04/invalid-duration/capture-result.json`: expected duration rejection.
- `.godot360/quality-panel-04.log` and `export-checks-04.log`: final regression checks.

The final 0.2 studio cancellation test waits for at least 10 captured frames before
cancelling, so it exercises a running encoder. Cancellation keeps its original
status even if the engine emits another frame callback while shutting down.
See [performance results](performance.md) for the larger temporary-file tradeoff.

The 0.3 panel integration snapshots every source file's SHA-256 before and after
re-encoding at another CRF. All hashes remain unchanged. It separately waits for
reported H.264 frame progress during an 8K re-encode, cancels through the panel,
and verifies that the child exits in under 10 seconds without a final video.
The addon-only 8K re-encode launches no scene capture and retains no copied sequence.
Its intermediate MP4 SHA-256 is
`AA65D1E53BB6B7C07FDE82CD4F2ACD68BDE5C94609F2989D0A1A52BA1F103C2D`,
matching the original. An initial storage query logged a missing frames-directory
error despite successful output; the query now handles re-encode folders explicitly
and has a passing regression check.

See [job planning](job-planning.md) for the 4K sample's measured and estimated
figures. The estimated full 4K duration has not been benchmarked against a full job.

The 0.4 motion fixture supplies a simple camera trajectory, two colored spheres,
and authored flash/tone cues. Python independently converts segmented PNG/decoded
MP4 pixels to spherical directions and weights them by spherical pixel area. It
checks marker centers within 0.45° and visible solid angle within 20%, including
cube edges, both poles, and the rear seam. Encoded marker areas remain within
about 9.2% of the ideal sphere area in the tested jobs. Flash visibility matches
the exact expected frames at both frame rates; each audio cue is within 10 ms and
one video frame, with no unexpected loud intervals.

This test first rejected a one-frame transform delay when sampling occurred in
`frame_pre_draw`. Moving sampling to the rig's process step fixed it. It also
exposed separate startup audio offsets with and without warmup. The example now
compensates for those measured cases. Earlier `motion-04-check`, `motion-04-verified`,
and `motion-04-24fps` folders are development evidence, not the final accepted runs.
The tests exercise the included fixtures; they do not certify arbitrary scenes.

The 8K replacement's 362 retained PNGs occupy 2,382,647,316 bytes (about 2.22 GiB).
The interval between first and last completed PNG writes was about 19 minutes
53 seconds; encoding and metadata finished about 39 seconds later. The final
MP4 is 9,849,143 bytes. These measurements apply to this sparse 12-second scene
on the listed machine; they are not a general performance or file-size promise.
The render began before the report-format update, so its quality review is a
separate record; the updated pipeline's embedded quality report was verified in
the smaller `quality-report-check` job.

Generated files are excluded from version control. Early smoke jobs are retained
with failure reports; only jobs whose `report.json` says `ok: true` are validated.

## Limits of this evidence

- On 2026-09-07, the user reported positive visual quality for THRESHOLD in
  YouTube. This is user-reported platform feedback. No URL, selected resolution,
  device or individual navigation/seam/audio checks were supplied; it does not
  establish independent beta installation success or headset comfort.

- The user subsequently uploaded the initial 2K clip to
  YouTube and confirmed that 360 playback works,
  while reporting blurry/pixelated/jagged imagery. This is user-reported evidence;
  the agent's signed-out browser showed a private-video message and could not
  play the upload or verify its quality setting.
- The user described the sharper 8K replacement as looking amazing. Its local
  checks pass; independent playback after YouTube transcoding remains unverified.
- At this historical milestone, only Windows and Compatibility had been exercised. Addon-only checks covered
  Godot 4.5.1/4.6.3/4.7.2; detailed 4K/8K and motion image/audio evidence remains
  specific to 4.7.2 and the listed GPU.
- The original 4K smoke test verifies dimensions and format, not long-duration stability.
- Scene warnings are heuristic; they do not prove that every seam or screen-space effect is correct.
- UMBRAL has no authored soundtrack; its stereo track is silent. The calibration scene tests non-silent audio.
- Audio is ordinary stereo, not head-tracked ambisonic audio. Stereo 3D capture is absent.
- Current output includes equivalent mono V1/V2 metadata and fast-start layout.
  The writer only accepts the pipeline's conventional H.264/AAC files with a
  trailing moov; fragmented/encrypted media, external references and fast-start
  inputs remain unsupported. The 4 GiB/co64 promotion cases use synthetic logical
  offsets, not a physical multi-gigabyte production export.
- PNG readback and Movie Maker scratch output add overhead. Frames remain on disk and can be large.
- Rendering and active H.264 encoding cancellation are tested. Verification uses
  the same cancellable process runner; cancellation in that stage has no separate integration test.
- Planning uses a short first-second sample and does not fingerprint referenced assets.
- The timeline helper supports property tracks. Method, audio, and nested playback
  tracks are rejected. Encoding now supports attached soundtracks and explicit
  offsets, but it does not edit timeline audio tracks or automatically establish
  sync for arbitrary scene audio; the measured startup compensation applies to the example.
- Attached audio files remain external dependencies. Selected WAV, FLAC, MP3,
  Ogg Vorbis/Opus, M4A and ADTS AAC cases have actual export evidence. The longest
  mixed-audio check is 90 seconds using synthetic retained frames, not a long GPU
  capture. See the exact [format matrix](../addons/godot360/BETA.md). Loops, fades,
  arbitrary multichannel sources, loudness mastering and spatial audio are absent.
- Actual timeline motion/audio has been exercised at 24 and 30 FPS. Unit sampling
  also covers 60 FPS. The 0.6.2 endurance fixture verifies actual 60 FPS property
  sampling, frame order, flash timing and audio across 90 seconds. Detailed moving
  sphere/path geometry at 60 FPS and sustained high-resolution capture remain untested.
- Fixed timing does not establish reproducibility across engine versions, hardware, shader clocks, or external scene logic.

The sandbox prevented Godot from writing its normal user/editor cache directories
and reading the Windows certificate store. Those environment messages appear in
logs; explicit project-local output paths worked, and there were no remaining
GDScript parse errors or failing checks in the final test runs.

The 0.5 independent reviewer is Python standard-library code, separate from the
GDScript writer. It parses box structure, checks all non-moov bytes exactly, maps
every original chunk offset to its relocated position, compares packet SHA-256
and timestamps, and hashes complete raw decoded video and PCM audio with FFmpeg.
A separate copy changes only the V1 UUID box type to `free`, keeping lengths and
offsets fixed, so successful spherical recognition must come from V2. The original
MP4 remains untouched. No new scene rendering was needed for these delivery tests.

The 0.6 audio reviewer builds its expected waveform independently in Python from
the original PCM samples, then compares decoded AAC signal quality and cue lag.
It covers scene warmup separately from soundtrack trim. The first implementation
was rejected for non-monotonic timestamps after trim plus delay; deriving output
PTS from emitted sample count fixed the discontinuity. A panel test also caught
insignificant SpinBox/JSON rounding making an estimate stale; signatures now use
the actual sample/gain precision. Source-mutation testing exposed a Windows
file-sharing race during atomic status replacement; bounded rename retries keep
terminal state visible. Earlier audio development folders retain intentional
failed evidence; only the accepted reports listed above establish success.

The 0.6.1 compatibility run caught Motion Lab's missing animation on Godot 4.5.1:
the newer `libraries/` resource property was read as an empty library dictionary.
Saving the example with the older `libraries` dictionary fixes all three tested
engines. The existing timeline tests catch this regression; they now stop promptly
if initialization fails. `.godot360/compatibility-061/` retains the failed original
run. Accepted evidence is `.godot360/compatibility-061-fixed/compatibility-review.json`.
All six final outputs pass thirteen checks. The 4.5.1 panel screenshot also shows
the rendered calibration preview and correctly fitting audio controls.

`renders/audio-formats-061/audio-formats-review.json` records the eight format
cases and the longer mix, with probes/hashes for each compressed input. Expectations
are built after decoding the input, so codec delay is not silently auto-corrected.
The output's declared duration stays exact; cues near the beginning, middle and end
show no measured drift. `renders/audio-delivery-061/audio-delivery-review.json`
repeats limiter, source-mutation and exact legacy encoding evidence on 0.6.1.

The 63-member `dist/umbral360-studio-0.6.1.zip` was rebuilt to a second destination
with identical bytes, extracted, and verified against every payload's source.
Its unpacked reviewer then passed all 208 checks plus both verified outputs on
Godot 4.5.1, without the source project installed. Evidence:
`.godot360/package-061-review.json` and
`.godot360/package-061-compatibility/compatibility-review.json`. ZIP SHA-256:
`7886819d3451c898d08f6c8181ad8c6b4bfc861cccdb397ea0159206e95ba4ae`.

The accepted 0.6.2 endurance result is
`renders/endurance-062-full/endurance-review.json`. Its actual GPU capture retained
5,402 images including warmup. All 5,400 delivered PNGs and fully decoded video
frames carry their expected thirteen-bit frame identifier and exact flash state.
Seven audio cues have identical measured startup offsets in the source WAV and AAC;
the report distinguishes that constant offset from drift and encoding-induced lag.
Movie Maker scratch PNGs are gone after completion, and saved settings are unchanged.
The pipeline took 301.888 seconds, including 285.993 seconds in capture, during a
shared test workload; these are not isolated performance benchmark measurements.

`.godot360/compatibility-062-fixed/compatibility-review.json` records 795 passing
checks across the three engines. Each suite includes malformed scene loading,
injected frame-hook failure, graceful early shutdown, user cancellation, worker
termination and PNG encoder termination. All six cases retain a terminal failure
state and recovery guidance, publish no final video, and leave the observed worker
and encoder stopped. The panel additionally fails a re-encode deliberately, points
back to its usable original capture, and verifies unchanged source hashes.

Capture failures now retain submitted counts and timing samples. A killed process
cannot write final diagnostics, so the coordinator separately records its reported
exit code and requires both successful capture evidence and finalized WAV audio.
The accepted standalone failure run is `.godot360/lifecycle-062-final/`.
Earlier `lifecycle-062-before/` records the original missing diagnostic fields;
`compatibility-062/` records a test-fixture path-escaping error, fixed by normalizing
Windows paths before embedding them in scene text. These failed development runs
are not accepted release evidence. Recovery validates sequence/WAV headers and
does not claim to resume an arbitrary scene or fully decode the saved sources.

The 0.6.2 ZIP contains 68 members and is 130,480 bytes. Every member matches the
checked source, rebuilding produces identical ZIP bytes, and verification from the
extracted package also passes. See `.godot360/package-062-review.json`; SHA-256:
`115403ae460818a9395e3f8567acd76a7e7050a36bb3d87158ae192902026bd0`.

## 0.7 storage reliability

.godot360/compatibility-070-final/compatibility-review.json records the complete
1,143-check matrix. .godot360/storage-control-070-final/review.json records 24
storage contracts per engine, including six new cancellation/log-write cases;
combined current coverage is 1,161 unique checks. These changes check cancellation
write results and preserve process startup errors without changing the protocol,
successful encoding, frame sampling or capture timing. The 4K/8K reviews use the
same successful media path; the later startup-error adjustment affects failures.

Each isolated project's .godot360/storage-failures/storage-failure-review.json
contains nine controlled pipeline faults and an actual recovered-source re-encode.
Tests inject available-space values instead of filling the real drive. Blocked
paths exercise actual JSON open/rename, preview, and PNG output errors. The
capacity guard rejects zero/unavailable reports and records measured thresholds.
Capture stops before submitting another frame when its reader reports insufficient
headroom; active encoding and metadata-copy faults retain their sources.

The initial development run's capture-space fixture attempted to access get_tree()
before its scene entered the tree; moving injection to _ready fixed the fixture.
All 53 original failure checks then passed, and the final suite adds three checks
for successful source-preserving recovery after a report-write failure.
No physical full-disk, unplugged-drive, or whole-system power-loss test is claimed.

## 0.7 production resolution

The independent reports are renders/production-070-4k-full/endurance-review.json
and renders/production-070-8k-full/endurance-review.json. Both are accepted with
ok: true, zero source/decoded frame failures, matching flash timing, cleaned
scratch images and unchanged saved studio settings. Each capture has two warmup
frames in addition to the delivered 1,800 or 900 frames.

The 4K cues occur at 0.5, 15, 30, 45 and 58 seconds; 8K cues at 0.5, 15 and
28 seconds. Every recorded/encoded cue is two 48 kHz samples after its nominal
time, a constant +0.0417 ms offset with zero measured drift. AAC adds zero measured
cue lag; independent comparison gives 55.5878 dB SNR at 4K and 55.4635 dB at 8K.
This fixture result is not a universal startup correction for user scenes.

The pipeline takes 261.018 s at 4K and 397.924 s at 8K, excluding the subsequent
Python source/decode/audio review. Retained review folders measure 631,474,043 and
1,067,788,420 bytes respectively. The frame-code scene is intentionally simple
and very compressible. See [performance](performance.md) for stage measurements;
neither time nor size predicts complex scenes, other hardware or longer durations.
The two-second 4K sample at renders/production-070-4k-sample also passes, but is
only preliminary fixture validation. Earlier geometry/seam tests remain separate.

## 0.7 package

dist/umbral360-studio-0.7.0.zip contains 78 members and is 153,141 bytes.
SHA-256: c506621e64531d02934397eecd0e37cde4551b7956484f7672090d1f4418050c.
The adjacent JSON records its manifest/hash; .godot360/package-070-review.json
records identical repeat-build bytes, verification against the extracted source,
the exact changed-file inventory since 0.6.3 and both accepted production runs.
Local settings, media and FFmpeg binaries are excluded. Exact-package installation
and documented workflow review remain explicit 0.8 acceptance work.

## 0.6.3 reopening and recovery

`.godot360/compatibility-063-final/compatibility-review.json` records all 918
passing checks. Each isolated project retains a recovery-review.json, panel image,
actual capture/re-encode outputs, launcher evidence, and coordinator-loss logs in
its `.godot360/recovery/` directory. The reviewer confirms the source addon,
original project.godot and studio settings are unchanged by tests.

Fresh session/PID/action/challenge replies are required to reconnect. Independent
clients do not overwrite each other's requests; expired cancellation and obsolete
replies are rejected. A completed job reopens without writing to its source; a
successful report and delivered media can recover completion when status is stale,
while an old Complete status without media does not establish success.

An actual launcher process exits before the new panel connects and cancels GPU
capture. Another test kills its own coordinator during capture, then cooperatively
stops the disposable worker and checks that reopening retains the stale status.
This is not evidence that reopening automatically stops orphan workers. A synthetic
interrupted re-encode points at the current test process as an unrelated live PID;
the panel refuses control and still finds the real completed source for re-encoding.

The first development run exposed a test constant shadowing Godot's native Panel
class. The standalone run1 then found that the child-process query incorrectly
ended a confirmed reconnection. Reconnected jobs now use fresh responses and
terminal files; run2 and the final three-engine matrix pass. Failed development
folders are retained as diagnostics, not release evidence. The final UI wording
was shortened after the matrix; behavior and assertions are unchanged.

The 0.6.3 package has 71 members and is 140,231 bytes. Rebuilding gives identical
bytes and verification against the extracted source passes. The package review
lists the exact changes from 0.6.2, with no removed members. See
`.godot360/package-063-review.json`; SHA-256:
`c4bedc440de20229e91bad0c60aeed9859f6906e0abf191e600ec55932873988`.
