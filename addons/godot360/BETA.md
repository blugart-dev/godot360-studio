# Compatibility and private validation

Godot360 Studio 1.0 is prepared privately for Windows release. The
[main guide](README.md) identifies the current version and the
[support contract](SUPPORT.md) defines its exact launch scope. Independent beta
feedback is not a prerequisite for continuing work. This filename and its dated
tables are retained as historical evidence. Use the [main guide](README.md)
for installation and export, [AUTHORING.md](AUTHORING.md) for timelines, and
[AUDIO.md](AUDIO.md) for music and synchronization. This package has not been
published to a community registry.

## Platform scope and historical evidence

The renderer pass supersedes the old forced-Compatibility capture behavior.
Captures now preserve the saved project renderer/driver by default. Windows has
native Vulkan and D3D12 Forward+/Mobile visual exports; Linux/WSLg has software
Vulkan visual exports. [Renderers and scene appearance](RENDERERS.md) records
precise combinations, preservation behavior and observed six-face limitations.
The repository's `docs/validation.md` holds dated workflow counts and evidence.
The historical Compatibility tables below remain historical; they do not certify
all features or all GPUs of another renderer.

Windows is the supported launch target; Linux and macOS remain experimental.
See [Platform setup](PLATFORMS.md) for downloads and installation. The older
results below do not certify the current candidate's bytes or expand its scope.

Linux source workflows passed **495 checks** on Godot 4.7.2, Ubuntu 26.04 x86_64
under WSL2/WSLg, Mesa 26.0.3 llvmpipe software OpenGL, FFmpeg/FFprobe 8.0.1.
This includes real calibration and Motion Lab exports, audio mixing/re-encoding,
capture failure cleanup, reopening/recovery, storage failures and diagnostics.
Tests ran on a case-sensitive Linux filesystem. These are functional checks;
they do not establish Linux 4K/8K speed, bare-metal GPU compatibility or Wayland
coverage. The repository's validation record tracks exact-package reruns separately.

macOS has native tool resolution and Homebrew setup instructions. Its CI lane
checks headless contracts; even a passing lane does not establish rendered export
support. Native Mac editor/capture/recovery and Intel/Apple Silicon validation
remain pending. Hosted Mac headless CI passes; see the repository's validation
record for the exact runs and counts.

## Historical Windows environment

All rows below use Windows, an NVIDIA RTX 3060 Ti, Compatibility/OpenGL, and
FFmpeg/FFprobe 9.0.1. Every engine ran in its own fresh project containing the addon
and test fixtures. The original UMBRAL scene and its project configuration were
not installed in those projects.

The table records the validated **0.7 baseline**. Version 0.8 additionally supplies
diagnostics contracts, actual successful/failed-job bundle checks and the documented
release workflow. The exact-package command below writes the current candidate's
per-engine counts and logs; those results remain separate from this historical table.

| Godot stable | Headless contracts | Panel workflow | Capture failures | Reopening/recovery | Storage failures |
| --- | --- | --- | --- | --- | --- |
| 4.5.1 | 224 passed | 16 passed | 50 passed | 41 passed | 56 passed |
| 4.6.3 | 224 passed | 16 passed | 50 passed | 41 passed | 56 passed |
| 4.7.2 | 224 passed | 16 passed | 50 passed | 41 passed | 56 passed |

Contracts cover export validation, MP4 metadata, planning, timeline sampling,
audio settings and real Fast PNG pipe round trips/failure cleanup. The panel test
captures one second of calibration at 512×256, 30 FPS, mixes an attached cue file,
re-encodes with changed levels/offsets and verifies unchanged source hashes.
It also checks the recovery action after an intentionally failed re-encode.
The six controlled capture failures are described in [RECOVERY.md](RECOVERY.md).
Version 0.6.3 adds 41 checks per engine for panel restart, an exporter whose launcher
exited, cancellation after reconnection, actual coordinator loss, stale replies
and an unrelated live PID, missing delivery files, and recovered-source re-encoding.
The 0.7 matrix passed 1,143 checks; an updated 24-check storage contract suite also
passed on all three engines, adding cancellation-write and process-log startup
checks (six per engine). That historical coverage totals 1,161 checks.
Nine disposable pipeline cases cover low
space and blocked writes, followed by a successful re-encode with unchanged source
hashes. Capacity readings are injected; the real drive is not filled. See [STORAGE.md](STORAGE.md).
A reconnection timeout leaves the job unconfirmed and preserves its
original status. Source hashes and the original project/settings remain unchanged.
These short captures establish basic compatibility, not performance equivalence.
Detailed 4K/8K and frame-by-frame motion evidence remains specific to Godot 4.7.2.
That historical run did not test Linux, macOS, other GPUs or Forward+/Mobile.
Current Linux and renderer evidence is recorded above; Mac and other GPU gaps remain.

Version 0.6.1 fixes the Motion Lab example's library binding on 4.5.1. Its saved
`libraries` dictionary is supported by the tested engines; the newer `libraries/`
form was not read correctly on 4.5.1. See the upstream
[4.5 AnimationMixer reader](https://github.com/godotengine/godot/blob/4.5/scene/animation/animation_mixer.cpp)
and [current compatibility reader](https://github.com/godotengine/godot/blob/master/scene/animation/animation_mixer.cpp).
Re-saving the scene in a newer editor may rewrite the format. Run the compatibility
check before redistributing edited examples for older engines.

## Soundtrack evidence

| Encoded input fixture | Rate | Channels |
| --- | --- | --- |
| PCM WAV | 22.05 kHz | Mono |
| MP3 | 32 kHz / 44.1 kHz | Stereo / mono |
| Ogg Vorbis | 44.1 kHz | Stereo |
| Ogg Opus | 48 kHz | Stereo |
| FLAC | 96 kHz | Stereo |
| AAC in M4A | 44.1 kHz | Stereo |
| Raw ADTS AAC | 48 kHz | Mono |

Each six-second export applies trim, positive offset and attenuation, then passes
all thirteen output checks. Decoded AAC is compared with independently placed
decoded input samples: measured cue lag is zero, and signal-to-error ratios are
53.2–55.6 dB. Previous tests also cover negative offsets, short files and silence.

A separate 90-second mix uses 2,250 retained synthetic frames at 25 FPS, scene
warmup, separate positive/negative offsets, and an AAC/44.1 kHz soundtrack. Cues
span the beginning, middle and end. All output checks pass, measured cue lag is
zero, and signal-to-error ratio is 52.8 dB. This tests encoding/timing across a
longer clip; it is not a 90-second GPU capture benchmark. Original fixtures and
settings are hash-checked for preservation.

## Sustained capture

Version 0.6.2 also tests an actual 90-second GPU capture on Godot 4.7.2 at
1024×512, 512-pixel cube faces and 60 FPS. Every one of the 5,400 delivered source
and decoded MP4 frames has the correct visible frame number and flash timing.
Seven recorded/encoded audio cues have a constant −4.625 ms offset and zero measured
drift; encoding adds no measured cue shift. All thirteen output checks pass.
Version 0.7 adds these actual GPU captures on the same Godot 4.7.2 machine:

| Output | Cube faces | Duration/rate | Source and decoded frames | Pipeline elapsed | Retained review bytes |
| --- | --- | --- | --- | --- | --- |
| 4096×2048 | 2048 pixels | 60 seconds / 30 FPS | 1,800 each, all pass | 261.018 s | 631,474,043 |
| 7680×3840 | 3072 pixels | 30 seconds / 30 FPS | 900 each, all pass | 397.924 s | 1,067,788,420 |

Both include two additional warmup frames. Every delivered visible frame number
and flash state passes independent inspection. Five 4K cues from 0.5 to 58 seconds
and three 8K cues from 0.5 to 28 seconds have a constant +2-sample (+0.0417 ms)
source/encoded offset, zero measured drift and zero added AAC cue lag. AAC SNR is
55.59/55.46 dB respectively. All thirteen output checks pass; scratch images are
removed and saved studio settings are unchanged.

Pipeline time excludes the additional Python review. These simple frame-code
fixtures compress unusually well; storage and speed are not forecasts for a
complex scene. They establish the listed durations/settings, not hour-long jobs,
arbitrary-scene synchronization or other hardware. Geometry/seam tests remain
separate evidence from the shorter Motion Lab and calibration fixtures.

## Check a clean project

1. Create an empty Godot project using **Compatibility**. Copy `addons/godot360`
   into it and enable the plugin in Project Settings.
2. Select FFmpeg and FFprobe. Keep **Calibration defaults**, use Draft, and click
   **Test 1 second**. Confirm the preview shows the front face with upright text.
3. Drag the preview through the left/right, back, top and bottom directions.
   Open the output folder and confirm `report.json` says `ok: true`.
4. Attach a short mono/stereo soundtrack, select **Scene + soundtrack**, and
   re-encode the completed capture with an audible level/offset change.
5. Load **Motion lab** for an authored six-second film. Start with a short test,
   then render at a suitable resolution and inspect motion and audio cues.
6. Save and reload a recipe, then close/reopen the editor and inspect its saved job.
7. Click **Save diagnostics…**, choose a new ZIP outside the job folder, and inspect
   its manifest and reports. Fill in [BETA-REPORT.md](BETA-REPORT.md) for independent
   feedback; [DIAGNOSTICS.md](DIAGNOSTICS.md) explains the collected information.

For a later YouTube check, use the verified `video-360.mp4`, allow high-resolution
processing to complete, and inspect navigation, orientation, detail, seams and
audio near both ends. Current V1/V2 outputs have not been independently checked
after YouTube processing. Uploading is a separate user action.

If reporting a failure, fill in the beta form and attach the reviewed diagnostics
ZIP. Reports and logs can contain local paths and scene-written text. Keep the
failed folder and original capture for diagnosis. Independent feedback from at
least one other Windows/GPU setup is useful before extending the support matrix;
another local automated run does not replace independent feedback. External
YouTube playback requires its own upload/review before making service-specific
acceptance claims. The [support contract](SUPPORT.md) defines the Windows launch
boundary; these historical beta requirements do not expand it.

## Repeat the automated checks

The ZIP includes `tests/` and `tools/` beside `addons/`. The reviewers require Python
with numpy/Pillow, Godot, FFmpeg and FFprobe. Replace the paths below with local
executables. Use a new output directory for every run.

For the release gate, test the **exact ZIP**:

```sh
python tests/package_review.py --package dist/godot360-studio-0.8.0.zip --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/new-package-review
```

Repeat `--godot` for each engine. The reviewer validates the manifest, extracts into
a fresh folder, verifies the unpacked inventory and rebuilds identical ZIP bytes.
It then runs all compatibility, capture-failure, recovery and storage tests from
the extracted package in separate minimal projects. It also exercises the real
panel's Draft 2K calibration, six preview directions, recipe save/reload, local
diagnostics and Motion Lab sample/full six-second export at 512×256. Existing audio
panel tests cover soundtrack mixing/re-encoding and unchanged original sources.
It records `package-review.json`, engine reports, full logs and preview screenshots.
Low-resolution Motion Lab checks here establish workflow, not new 4K/8K endurance.

To work on source changes before packaging:

```sh
python tests/compatibility_review.py --capture-failures --job-recovery --storage-failures --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/new-compatibility-run
```

Run that command from an unpacked package or checkout. Repeat `--godot` for each
engine to test. It creates its own projects, needs a GPU/display for capture, and
writes `compatibility-review.json` with stage results and paths to full logs.

Run the audio reviewer from a Godot project with the addon and tests installed:

```sh
python tests/audio_formats_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/new-audio-run
```

It writes `audio-formats-review.json`. Encoders used to create fixtures include
libmp3lame, libvorbis, libopus, FLAC and AAC; a missing fixture encoder fails the
review and is not evidence that the addon's input decoder is broken.

Add `--capture-failures` to the compatibility command for the six controlled failure
cases. To repeat the sustained GPU capture and every-frame media review, run:

```sh
python tests/endurance_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/new-endurance-run
```

The default is 90 seconds at 60 FPS and 1024×512 with 512-pixel faces.
`--seconds 2` checks the fixture quickly first. For the production settings, add
`--seconds 60 --fps 30 --width 4096 --face-size 2048 --timeout 1800` or
`--seconds 30 --fps 30 --width 7680 --face-size 3072 --timeout 1800`.
Use a separate output folder for each. The default retained-storage limit is
16 GiB; `--max-storage-gib` changes that review budget. The reviewer cancels its
own running job if the pipeline exceeds its timeout or sampled storage limit.
It writes `endurance-review.json` and retains the capture. Frame-code, flash and
audio measurements are independent Python checks of the actual rendered media;
their completion takes additional time after the pipeline finishes.

`audio_delivery_checks.py` additionally needs `--source-review` from a completed
`audio_review.py` run and `--legacy-source` pointing to a pre-0.6 capture encoded
at CRF 16 with the same FFmpeg build. That historical baseline is not bundled.

Build or verify a package using Python's standard library:

```sh
python tools/package_addon.py
python tools/package_addon.py --verify dist/godot360-studio-1.0.0.zip
```

The builder reads current files, checks version labels, refuses to overwrite a
package, and verifies each ZIP member against its source bytes. Fixed ZIP timestamps
and sorted members make unchanged builds reproducible with the same Python/zlib
runtime. `manifest.json` records each payload's size and SHA-256; the adjacent
package JSON records the ZIP hash. Local settings, imports, rendered media and
FFmpeg executables are excluded.
