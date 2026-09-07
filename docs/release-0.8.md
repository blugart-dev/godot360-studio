# Umbral360 0.8 beta candidate

Prepared locally on 2026-09-07 for Windows, Godot 4.5.1/4.6.3/4.7.2 and
Compatibility. THRESHOLD later received positive user-reported YouTube visual
feedback; see [the film record](threshold.md). Independent beta feedback, detailed
playback checks and final release preparation remain outstanding. The agent has
not published the addon or uploaded video.

## Candidate

- [Addon ZIP](../dist/umbral360-studio-0.8.0.zip): 84 members, 169,418 bytes.
- SHA-256: `16e41c52c4ef7e0e3c62783a3ae8bc79b93bb676dbd93e5e071daae3ead33961`.
- [Package manifest record](../dist/umbral360-studio-0.8.0.json).
- [Exact-package review](../.umbral360/package-080-accepted/package-review.json)
  and [engine results](../.umbral360/package-080-accepted/engines/compatibility-review.json).
- [Diagnostics guide](../addons/umbral360/DIAGNOSTICS.md) and
  [independent feedback form](../addons/umbral360/BETA-REPORT.md).

The reviewer verifies the manifest, extracts the exact ZIP, checks the extracted
inventory, rebuilds identical bytes and installs it in separate minimal projects.
It tests the existing export/audio/planning/metadata/timeline/storage contracts,
controlled process and storage failures, reopened jobs and recovered-source
re-encoding. It also runs the documented Draft 2K calibration, six preview
directions, recipe persistence, support ZIPs and the six-second Motion Lab film
at 512×256. Screenshots and original logs are retained under each engine's
`.umbral360` directory. Source and settings are checked for preservation.

The exact-package review **passed all 1,332 checks**: 444 per engine on Godot
4.5.1, 4.6.3 and 4.7.2. Each runs 251 headless contracts, 19 audio panel checks,
50 capture-failure checks, 41 reopening/recovery checks, 56 storage-failure checks
and 27 release-workflow checks. All three import the enabled plugin successfully.
The extracted payload and original ZIP remain unchanged; its rebuild is identical.
All six labeled preview directions were also inspected visually, along with the
final 4.7.2 compact scrolling panel. Known sandbox certificate/shader-cache warnings
are separate from addon failures; no unresolved addon error was found.

## Current-candidate YouTube file

Use [video-360.mp4](../renders/delivery-080-8k/video-360.mp4): the accepted 12-second
UMBRAL film, re-encoded by the 0.8 exporter from its retained 8K capture. It is
7680×3840 at 30 FPS with matching V1/V2 metadata and fast-start layout. The pipeline
took 48.129 seconds; no new GPU scene capture was needed. All thirteen delivery
checks pass. Video SHA-256:
`7078358d81df34e17a360e79ba6c25adf732f381faffcdd5dfc07e85cc95fcb1`.

The [independent media review](../renders/delivery-080-8k/metadata-review.json)
checks 719 chunk offsets, 924 packet hashes/timestamps, all 360 decoded frames and
decoded audio against the accepted original encoded MP4. A separate copy with V1
disabled confirms V2 recognition and identical decoding. The newly encoded MP4
matches the original byte for byte. The [candidate record](../renders/delivery-080-8k/candidate-review.json)
confirms unchanged original capture files and saved settings. No specific YouTube
review of this 12-second file is recorded. The subsequent 60-second THRESHOLD film,
using the unchanged 0.8 exporter, received positive user visual feedback in YouTube
on 2026-09-07. Its [review record](threshold.md) distinguishes that feedback from
an itemized playback checklist. Use the main `video-360.mp4` for delivery.

The [local delivery diagnostics ZIP](../.umbral360/delivery-080-diagnostics.zip)
contains the candidate's job reports and logs. Its headless environment describes
the collector; the original capture is referenced, not copied into the bundle.

## Local source history

The validated 0.7 baseline is commit `23759d4`, tagged `v0.7.0`. The 0.8 work is
recorded separately on `main`. Git excludes renders, local settings/tool binaries,
Godot caches, Python caches and distribution ZIPs. No remote is configured.

## Remaining release gates

1. Have at least one independent Windows/GPU tester follow the included beta form
   and record the candidate hash, environment, results and reviewed diagnostics ZIP.
2. Retain the positive THRESHOLD YouTube visual feedback and record any remaining
   detailed delivery checks: navigation, initial orientation, all directions,
   selected playback quality, seams during motion, and beginning/end audio.
3. Resolve blocking findings, repeat affected checks, then obtain explicit approval
   before public publication. Continue to state the measured support limits.

Existing 0.7 production evidence remains 60 seconds at 4K/30 FPS and 30 seconds at
8K/30 FPS on the development RTX 3060 Ti. This release workflow does not extend
those durations, certify hour-long exports, or establish another hardware/OS result.

## Rejected development evidence

`.umbral360/package-080-final/` is the first rejected candidate review, despite
its directory name. Its ZIP is retained there as `rejected-0.8.0.zip` with SHA-256
`23fbdadea3436ae0f87bf5f52294915d76b47a3aeed495ea96d347c1730eedf3`.
Godot 4.7 lists the ZIP's parent directory as an additional entry; treating it as
a payload count mismatch rejected otherwise valid diagnostics. The corrected
collector handles that directory while still verifying all payload bytes.
The earlier source-workflow test also exposed empty-buffer hashing, now corrected.
Only the current candidate hash and accepted report above establish release evidence.
