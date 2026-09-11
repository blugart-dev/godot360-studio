# Engineering brief — development toward 1.0

Updated on 2026-09-11. This is a development recap; the
[publication preparation review](publication-review.md) records repository cleanup.
The canonical completion criteria remain in [release readiness](release-readiness.md).

The earlier checkpoint is committed and pushed privately: runtime/fixture checkpoint
`12e8872`, silent bake-editor fix `c26c919`, corrected Mobile tint validation
`0cde68f`, and bounded software-CI timeouts `739cf95`. All seven hosted workflows
pass. The LightmapGI artifacts are retained and audited: 12 clips / 864 decoded
frames, with all three missing-map controls rejected. See [validation](validation.md)
for exact runs, package mappings and the corrected historical compositor claim.

## Current position

Godot360 Studio is a working editor addon for exporting a saved, authored Godot
scene to mono 360 SDR video with stereo audio. Scene/camera selection, recipes,
short-test estimates, timeline capture, audio, spherical MP4 metadata, verification,
cancellation, diagnostics, re-encoding, recovery, storage guards, spherical playback
and recent exports are implemented. The internal version remains 0.8.0.

Recent increments establish:

- [Clean native editor integration](editor-workflow.md): a fresh addon-only
  project and two actual editor processes validate authored scene saving, 4K
  sample/export, stereo playback/seek, history, cancellation and recovery.
  Forty-four editor checks pass. Two runtime fixes prevent transient progress
  JSON parser errors and exclude new job folders from Godot asset import.
  Original source hashes remain unchanged after restart and recovery. Actual
  click-through navigation and subjective delivery review remain open: the
  desktop automation helper could not bind to the Godot window in this session.

- [Production workloads](production-performance.md): four one-minute native
  Forward+/Mobile 4K/8K exports, 7,200 source frames and 7,200 decoded frames,
  all delivery/frame/audio/history checks passing. Measured CPU/GPU/system
  memory, storage and time establish bounded budgets on Windows / 4.7.2 /
  RTX 3060 Ti. Forward+ 8K uses disabled MSAA after a 4× probe showed much
  higher shared GPU memory. Full 8K encoding reaches about 13 GiB of resident
  process memory; a one-second probe does not establish full-job RAM needs.
  Capture/encode capacity controls and recovery pass, retaining unchanged source
  hashes. The package rebuilds identically and passes 1,025 headless/failure
  checks. The addon runtime is unchanged. This work is checkpointed locally.

- [Combined GI/transparency/history](combined-effects.md): 16 native 4.7.2
  Forward+/Mobile clips / 2,304 source and decoded frames. Twelve normal cases
  pass; four wrong lighting/history controls are rejected. The 144-frame clips
  use continuous camera motion, a cut, eight warmup draws and 12.5% borders.
  The exact package passes 1,025 headless/failure checks and rebuilds identically.
  Addon runtime is unchanged. This increment is checkpointed locally; its manual
  CI is prepared but has not run remotely. The production results above follow it.

- [Saved LightmapGI](lightmap-capture.md): 16 clips / 1,152 source and decoded
  frames on native 4.7.2 Forward+/Mobile/Compatibility. Twelve clips pass; four
  missing-map controls are rejected. A saved bake covers static surfaces and a
  moving dynamic probe receiver, with cuts and borders. The reproducible package
  passes 3,075 headless/failure checks across three engines. No capture-runtime
  change was needed. Hosted checkpoint results belong in the latest validation
  entry; local native evidence and hosted software rendering have separate scope.

- [Temporal rendering](temporal-capture.md): 22 completed clips (19 accepted and
  three deliberately corrupted controls), plus a correctly rejected graphics-error
  job. TAA/FSR, camera/world history and VoxelGI have bounded native evidence.
  Mobile uses authored 4x MSAA and a writable per-view compositor texture.
  Engine rendering errors now prevent encoding even after a complete capture.
  The exact package passes 3,208 checks; source mapping and failed development
  attempts are recorded in the newest [validation entry](validation.md).
  The checkpoint includes this increment together with the saved LightmapGI work.

- Moving CPU/GPU smoke and native tube/ribbon trails with bounded rendered
  references. All twelve completed trail jobs pass, including pause/camera cuts
  and enabled/disabled controls; Compatibility lacks trail history. The 48
  retained smoke jobs pass, with nine rejected controls and six separately
  recorded zero-warmup observations. The exact package passes 3,018 headless and
  failure checks. See the newest [validation entry](validation.md).
- [LUMEN](lumen.md): a complete 24-second 4K Forward+ orbital-observatory film,
  original score, portable recipe, source scene and local spherical player. It
  demonstrates native trails and point-facing vapor in an immersive music or
  installation setting. Final outputs live in `renders/lumen-4k-final/`.

- [AFTERGLOW](afterglow.md): a one-minute Forward+ 4K film with an original
  disco-funk score, choreography, portable recipe, seeking checks and GPU pedestal
  clearance regression. Preserve its scene, score/cues, shaders and render masters.

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
| 1 | Representative complex particles — bounded smoke/trail cases complete | High for remaining general cases | Moving transparent smoke and native trails now have rendered references. Lit/intersecting transparency, preprocessing and arbitrary temporal histories remain separate cases. | Completed native matrices and package checks are in the latest validation record. |
| 2 | Extend the advanced rendering boundary — selected temporal/compositor/GI cases complete | High for remaining general cases | Selected saved LightmapGI now passes too. The selected combined GI/transparency/long-history case now passes; larger GI layouts and other stacks remain outside that evidence. | The temporal guide records 23 native jobs and explicit Mobile buffer requirements; the LightmapGI guide adds 16 clips. Complete further selected cases with clear setup guidance. Full support for every combination is not a prerequisite implied by this plan. |
| 3 | Representative 4K/8K Forward+/Mobile workloads — bounded profiles complete | Medium for further profiles; potentially high to optimize | Four one-minute textured/effects exports now establish measured budgets on one native Windows GPU. Other hardware, longer durations and heavier GI can change requirements. | The production guide records 7,200 source/decoded frames, sampled CPU/GPU/system memory, storage/time forecasts and capacity-failure recovery. |
| 4 | Native Linux GPU and Mac graphical review | Medium technically; dependent on hardware access | Software/headless CI cannot establish a native GPU installation, export and playback workflow. | Actual install/export/review/cancel/recovery on each claimed platform. If hardware is unavailable, the supported release matrix requires an explicit scope decision. |
| 5 | Private walkthrough from clean setup through delivery | Low to medium | A technically valid file can still be hard to produce or wrong in orientation, sound or spherical presentation. | Follow the published instructions with an existing scene, review the sphere and audio, reopen a job and recover a failure; resolve observed friction. |
| 6 | Freeze and validate the exact 1.0 package | Medium, after earlier work | A release needs one consistent supported matrix, code snapshot, documentation set and reproducible artifact. | Version and migration notes updated, exact package checks pass, known supported-workflow blockers resolved. Public publication remains a separate action. |

Hardware checks can proceed alongside independent local work when machines become
available. Final package work should follow the scene and production reviews.
The bounded smoke/trail cases in item 1 are now complete. The selected combined
rendering case in item 2 and the four production profiles in item 3 now pass.
The next independent local target is item 5's clean private walkthrough.
Saved LightmapGI now has
its own bounded review; selected TAA/FSR, persistent compositors and VoxelGI are
established in the temporal guide. The LUMEN demo adds a
composed 4K scene; it does not establish heavy production endurance.

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
The [combined-effects milestone](combined-effects.md) is complete within its
bounded native 4.7.2 Forward+/Mobile setup. It includes the saved LightmapGI room,
moving probe receiver, lit intersecting transparency, 144-frame history, camera
motion/cut, independent worlds and rejected lighting/history controls. See the
latest [validation record](validation.md) before extending this evidence.

Next, perform a private clean-installation walkthrough against the documented
existing-scene workflow: install, select/save a scene and camera, configure
tools, run a short test, export, review orientation/seams/detail/sound, reopen
and recover an interrupted job. Record concrete usability or delivery findings
and fix reproducible blockers. Native Linux/Mac coverage and final support
decisions remain open. Do not rerun completed large matrices without a code
change, failure or unresolved concern that justifies them.

`tests/fixtures/cesium_man/` now contains a pinned licensed GLB with its attribution
and original notices; the reviewer verifies its SHA256. Use disposable projects and output
folders; preserve the user's creative scenes, recipes, settings and existing masters.

## Local evidence and tools

- Latest package: `.godot360/clean-editor-fixes/final-reviewed/candidate.zip`,
  SHA256 `e3ed1dc5053a91e9645d4796702516f67b23ba892c4f469685be5648ea5982bc`.
  The exact package and native editor records are mapped in [validation](validation.md).
  The earlier combined/production work is checkpointed at `9779e38`.

- Previous production package: `.godot360/production-review/package/candidate.zip`, SHA256
  `0c5bc4da8b41cf16030317ba4dd44d0c68a6cf0ab130a9a19db18497d94cbdda`.
  It rebuilds identically and passes 1,025 4.7.2 headless/failure checks.
  `.godot360/production-review/audit.json` maps all four full workloads,
  five probes, controls, recovery and source hashes; `hardware.json` records
  exact tools and hardware. No addon runtime change. Preserve the snapshots,
  prepared generated textures and all original captures together.

- Previous combined-effects package: `.godot360/combined-review/package/candidate.zip`, SHA256
  `c5b6a7dd1dfddcc9a085da05c27f107c7f4b924610010c456e13f4e6f114845f`.
  It rebuilds identically and passes 1,025
  4.7.2 headless/failure checks. Native matrices and their exact source mapping
  are retained in `.godot360/combined-review/audit.json`. No addon runtime change.

- Previous hosted checkpoint: `.godot360/checkpoint-review/ci-timeout.zip`, SHA256
  `d2f4a810c722927a35e4f7189c2b151d3de7b87412877ada2bc93ca3a840f89b`.
  It adds only the reviewer's optional timeout to the corrected compositor package
  `46eb3cc45721e41ef20d23869fe08cfff0514f0e311d0ac5a810f97ee9d3b685`,
  which rebuilds identically and passes 3,075 local checks, 1,161 Linux checks and
  1,027 Mac headless checks. Nine native tint exports pass on Forward+/Vulkan,
  Mobile/Vulkan and Mobile/D3D12. All addon runtime files remain identical to
  `12e8872`; the [validation record](validation.md) maps the different test snapshots.
  Earlier LightmapGI archive `9308a68209faede3a7444148bc42bb6b25a1eac4a5f6bf40f107f71a176a3802`
  retains the original sixteen native clips and its own 3,075 package checks.

- Current complex-particle package: `.godot360/particles-complete/package/candidate.zip`,
  SHA256 `2f4482e7da16d46ec89682d0d96a63b4e6510b2c6cea8b57f2bc5d6b67be1162`.
  It rebuilds identically and passes 3,018 headless/failure checks; all twelve
  native trail exports match its runtime/fixture/reviewer source. The audit
  explains the sole two-line warning difference from the earlier smoke matrix.
- Current creative demo: `scenes/films/Lumen.tscn`,
  `export_profiles/lumen-4k.tres`, and `docs/lumen.md`. Run
  `python tools/play_lumen.py` after building its local browser copy.

- Previous head-look/nested package: `.godot360/modifier-review/package/candidate.zip`,
  SHA256 `8f0a2dd5a4b0cf6906fe41a6eb5c8ad10dcd51aace4c27a3a949b016d416b788`.
  Its identical rebuild, 2,985 package checks and 26 rendered exports pass locally.
  `.godot360/modifier-review/audit.json` records source matching and protected
  hashes. Checkpoint `2f4448f` is pushed privately; characters `34371376287`,
  platforms `34371375916` and appearance `34371376090` all pass without retry.
  `.godot360/modifier-review/hosted/verified.json` verifies all ten hosted package
  records against the local ZIP. Earlier results below describe the previous
  imported-character snapshot.

- Previous accepted package: `.godot360/imported-character/final/candidate.zip`, SHA256
  `3a66b1f853e6f0494a56020b63731da1c7717f3af02b38183ea8feecf558bf31`.
  It is a private development snapshot, not a 1.0 release.
- Previous imported-character audit: `.godot360/imported-character/audit.json`; full outputs and negative
  controls are retained under that directory. The appearance evidence remains
  under `.godot360/appearance-review/`. These large outputs are ignored by Git.
- Install the tools using [platform setup](../addons/godot360/PLATFORMS.md).
  Pass absolute executable paths to the reviewers; keep machine-specific locations
  in local settings rather than committed documentation.
- Create a Python environment using [developer setup](testing.md) and install
  `requirements-dev.txt` for NumPy/Pillow. Packaging and repository hygiene checks
  use the standard library only.
- Isolate APPDATA/LOCALAPPDATA per disposable Windows review, as the existing
  particle reviewer does. Native graphics workers are required for rendered
  evidence; headless coordinator/contracts have narrower coverage.

The evidence folders above are maintainer-local archives, not downloadable source
assets. Follow the linked test guides to produce equivalent reports in a fresh
checkout. Historical package hashes identify their original snapshots and do not
certify later changes.
