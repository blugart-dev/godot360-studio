# Godot360 Studio development handoff

Updated 2026-09-07 for the Godot360 Studio rename and private GitHub hosting. A fresh session can begin by
reading this file, the linked guides, and the relevant current source/tests.

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
- The coordinator is headless; capture needs a GPU/display and Compatibility.
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
