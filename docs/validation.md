# Validation record — updated 2026-09-08

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
