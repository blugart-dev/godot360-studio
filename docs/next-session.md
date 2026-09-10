# Engineering brief — development toward 1.0

Updated on 2026-09-10. This is a development recap; the
[publication preparation review](publication-review.md) records repository cleanup.
The canonical completion criteria remain in [release readiness](release-readiness.md).

## Current position

Godot360 Studio is a working editor addon for exporting a saved, authored Godot
scene to mono 360 SDR video with stereo audio. Scene/camera selection, recipes,
short-test estimates, timeline capture, audio, spherical MP4 metadata, verification,
cancellation, diagnostics, re-encoding, recovery, storage guards, spherical playback
and recent exports are implemented. The internal version remains 0.8.0.

Recent increments establish:

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
| 2 | Extend the advanced rendering boundary — selected temporal/compositor/GI cases complete | High for remaining general cases | Selected saved LightmapGI now passes too. Larger GI layouts, combined effects and longer histories still need bounded references. | The temporal guide records 23 native jobs and explicit Mobile buffer requirements; the LightmapGI guide adds 16 clips. Complete further selected cases with clear setup guidance. Full support for every combination is not a prerequisite implied by this plan. |
| 3 | Representative 4K/8K Forward+/Mobile workloads | Medium to measure; potentially high to optimize | Existing 4K/8K runs establish reliability for simpler Compatibility scenes. Heavy lighting, effects and texture content can change memory, time and storage needs substantially. | Sustained jobs with measured GPU memory, time, retained storage and audio alignment; practical budgets and failure behavior. |
| 4 | Native Linux GPU and Mac graphical review | Medium technically; dependent on hardware access | Software/headless CI cannot establish a native GPU installation, export and playback workflow. | Actual install/export/review/cancel/recovery on each claimed platform. If hardware is unavailable, the supported release matrix requires an explicit scope decision. |
| 5 | Private walkthrough from clean setup through delivery | Low to medium | A technically valid file can still be hard to produce or wrong in orientation, sound or spherical presentation. | Follow the published instructions with an existing scene, review the sphere and audio, reopen a job and recover a failure; resolve observed friction. |
| 6 | Freeze and validate the exact 1.0 package | Medium, after earlier work | A release needs one consistent supported matrix, code snapshot, documentation set and reproducible artifact. | Version and migration notes updated, exact package checks pass, known supported-workflow blockers resolved. Public publication remains a separate action. |

Hardware checks can proceed alongside independent local work when machines become
available. Final package work should follow the scene and production reviews.
The bounded smoke/trail cases in item 1 are now complete. The next engineering
target is item 2's selected combined rendering cases. Saved LightmapGI now has
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
The next bounded engineering milestone is a saved LightmapGI room with a moving
probe receiver, lit intersecting transparency and persistent compositor history.
Start with Forward+ using authored exposure, eight warmup draws and 12.5% borders;
include a camera cut and a longer history than the existing 72-frame fixture.
Use independent reference worlds, disabled-feature baselines and deliberately
incorrect history/lightmap controls. Check every source and decoded delivery
frame, feature contribution, graphics errors and behavior at the cut. Then review
the corresponding Mobile setup with its documented 4x MSAA/writable-texture
requirements. Establish thresholds before accepting results and document any
remaining boundary artifacts. This is planned work, not completed evidence.

After that milestone, use a representative Forward+/Mobile scene for sustained
4K/8K exports, measuring peak GPU memory, elapsed time, retained disk use and
audio alignment. Reproduce discrepancies and make the smallest supported
corrections. Do not rerun completed large matrices without a code
change, failure or unresolved concern that justifies them.

`tests/fixtures/cesium_man/` now contains a pinned licensed GLB with its attribution
and original notices; the reviewer verifies its SHA256. Use disposable projects and output
folders; preserve the user's creative scenes, recipes, settings and existing masters.

## Local evidence and tools

- Latest package: `.godot360/lightmap-review/package/reviewed.zip`, SHA256
  `9308a68209faede3a7444148bc42bb6b25a1eac4a5f6bf40f107f71a176a3802`.
  Its identical rebuild and 3,075 headless/failure checks pass. The audit maps
  all sixteen native LightmapGI clips to current runtime/fixture/reviewer source.
  Detailed results and excluded development attempts are in [validation](validation.md).

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
