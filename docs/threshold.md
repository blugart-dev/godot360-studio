# THRESHOLD

An original sixty-second mono 360 film, authored as a practical production exercise
for Godot360 Studio. Four procedural worlds, a recurring light guide, three spherical
light transitions, original stereo music and an ending. The visuals use an
illustrated, geometric style; all geometry, shaders and music are generated locally.
No stock models, recordings, external music or network assets are required.

## Experience

| Film time | World | Events and composition |
| --- | --- | --- |
| 0–14 s | The Tidal Archive | An underwater cathedral, illuminated vaults, a suspended relic, moving schools and an enormous drifting archivist |
| 14–29 s | The Glass Desert | Copper dunes, obsidian shards, an eclipsed sun and moving celestial rings |
| 29–44 s | The Sky Garden | Thirteen floating islands, branching trees, thousands of leaves, animated waterfalls and a circling flock |
| 44–60 s | The Star Engine | A seven-ring celestial machine, orbiting satellites and planets, a contracting core and a final fade |

The three transitions occupy 2.5 seconds each, centered on 14, 29 and 44 seconds.
An opaque spherical veil conceals the actual world switch at its center. All four
worlds are built in advance; this exercises authored visibility changes, not loading
separate scene files from disk mid-capture. Only one world is visible at a time.

The viewer's default forward direction stays fixed. Camera translations are only a
few meters and ease into each world. The guide is a suggestion; scenery surrounds
the viewer, including overhead and behind. Headset comfort still needs human review.

## Play and edit

Open `scenes/films/Threshold.tscn` and press **F6** in Godot 4.7.2. Hold the left mouse
button and drag to look around; Esc closes this film. Restart the scene to replay.
The project's original F5 installation remains the main scene.

Load `export_profiles/threshold-8k.tres` in Godot360 to export 60 seconds at
7680×3840, 30 FPS, with six 3072-pixel faces, Fast PNG, CRF 16 and the attached score.
The source score is `assets/audio/threshold-score.wav`. Recreate it with:

```powershell
python tools/compose_threshold.py
```

The score uses deterministic PCM synthesis and NumPy: bowed detuned pads, glass
motifs, bass, a soft pulse, transition swells and cross-channel delay. Its 80 BPM
harmonic progression changes character with each map and resolves before the fade.
`assets/audio/threshold-score.json` records the source hash and audio measurements.

`tools/render_threshold.py` runs the unchanged addon pipeline in a fresh folder,
records timings/storage and verifies preservation of saved studio settings:

```powershell
python tools/render_threshold.py --godot PATH_TO_GODOT --ffmpeg PATH_TO_FFMPEG --ffprobe PATH_TO_FFPROBE --output renders/threshold-new
```

For a one-second sample of a later world, add `--seconds 1 --offset 36` and choose
another fresh output. The script aligns both scene time and soundtrack trim.
The monitor defaults to a 96 GiB retained-output budget, a 12 GiB free-space floor
and a 90-minute timeout. Those are limits, not predicted requirements.

After rendering, generate playback copies and review the delivered media:

```powershell
python tests/threshold_media_review.py renders/threshold-new --ffmpeg PATH_TO_FFMPEG --ffprobe PATH_TO_FFPROBE
python tools/play_threshold.py --directory renders/threshold-new
```

Open `http://127.0.0.1:8360`. The local player uses a 4096×2048 browser copy; drag,
recenter, scrub, mute or enter fullscreen. It also links to the ordinary 1080p
front-view preview and the tagged 8K master. This is local playback, not publishing.
The server binds only to localhost and serves only those playback files. Stop the
terminal process to stop serving. Review evidence is saved under
`.godot360/<output-folder-name>-media-review/`.

## Authoring contract

`scripts/films/threshold.gd` owns the sixty-second timeline. Each capture frame is
sampled at an absolute time; changing process speed does not change the animation.
The optional `threshold_offset` job field is for later-world test samples.

Every animated material receives the same explicit `clock`. No shader uses `TIME`.
The score is attached externally during export. Runtime preview audio is disabled
when the capture hook is active. A shared camera-facing halo is oriented once from
the capture camera; it does not billboard independently toward six cube cameras.
There are no screen-space reflection, bloom or ambient-occlusion effects.

`threshold_geometry.gd` builds the meshes and MultiMeshes. Leaves, fish, birds and
dust are instanced; static architecture and celestial markings use individual
meshes. The four worlds remain resident, so hidden worlds still consume memory.

## Validation and limits

The 2026-09-07 capture used Godot 4.7.2, Compatibility/OpenGL, an RTX 3060 Ti,
six 3072-pixel faces, 4× MSAA and FFmpeg 9.0.1. The 1,800 delivered frames plus two
warmup frames took **798.38 seconds** to capture (2.26 captured frames/second).
PNG sources occupy **18.52 GiB**. GPU readback took 162.34 seconds and image-writer
submission took 142.43 seconds. Submission does not include every overlapping PNG
encoder operation, so those counters are not a complete CPU/GPU bottleneck profile.

The full pipeline passed all 13 output checks and took **1,196.71 seconds** (about
20 minutes), including **274.04 seconds** of H.264/AAC encoding and **120.40 seconds**
of output verification. The tagged 8K master is **242.64 MB**. Retaining PNGs, PCM,
both encoded/master MP4s and job evidence used **19.01 GiB** before playback copies.
The source sequence is the same 60-second capture throughout; neither music nor
metadata required a second scene render. Saved studio settings and the 0.8 ZIP
hash were unchanged.

| Chapter | Delivered frames | Mean source PNG |
| --- | ---: | ---: |
| Tidal Archive | 420 | 12.26 MiB |
| Glass Desert | 450 | 10.41 MiB |
| Sky Garden | 450 | 12.35 MiB |
| Star Engine | 480 | 7.41 MiB |

One shared desktop GPU observation during the star chapter reported 3,735 MiB
used out of 8,192 MiB. It includes other desktop processes and is neither an
isolated allocation measurement nor a measured peak. Performance also reflects
ordinary concurrent desktop/review activity. A useful next workflow improvement
is sampling several chapter times, including the heaviest map, before extrapolating
duration and storage; the current panel samples only the opening second.

`tests/threshold_checks.gd` checks the absolute-time contract: permitted duration,
offset bounds, backwards-seek determinism, stable capture orientation, single-world
visibility, exact cut coverage and the ending. The final source passes 60 checks.

`tests/threshold_storyboard.gd` captures real GPU front/back views and panoramas at
chapter and transition times. The final storyboard contains 1,436 scene nodes.
Its measured six-view render statistics range from 132 to 657 draw calls and
roughly 0.31–1.37 million primitives for the sampled frames. Those counters describe
this scene on this machine; they are not universal addon limits.

`tests/threshold_media_review.py` decodes every frame, checks for unexpected black
frames and duplicate thumbnails, verifies the three concealed cuts and final fade,
compares sixty source PNGs to their corresponding decoded thumbnails in sRGB, and
compares the complete decoded soundtrack with its PCM source. It independently
checks V1/V2 structure, fast start, unchanged media bytes and packet timestamps.
This is bounded media validation, not proof of every pixel's artistic correctness.

The final local media review passed: all **1,800 decoded frames**, no unexpected
blank or duplicate thumbnails, all three fully concealed cuts, and all **60 source
frame comparisons**. The worst mean source/decoded error was 2.52 on an 8-bit RGB
scale after conversion to sRGB. The full soundtrack comparison measured 39.68 dB
SNR, a maximum local correlation offset of one sample (0.021 ms at 48 kHz) across
237 measured windows, and a decoded peak of 0.853. These windows are waveform
measurements, not independent perceptual listening tests. All **4,614 media packets**
and their timestamps matched before/after metadata insertion.

The final 4K browser copy is 65.40 MB; the 1080p front-view preview is 29.05 MB.
Local browser playback, dragging, seeking and the initial forward orientation were
visually checked. The master SHA-256 is
`0c434c261519e2bb41298765dcf855e7cf3c81dfabc7d8d36b0b044dac1c469c`.
The detailed machine-readable records are under `.godot360/threshold-8k-run/`,
`.godot360/threshold-8k-media-review/`, and `.godot360/threshold-capture-analysis.json`.

On 2026-09-07, after reviewing THRESHOLD, the user reported: "It looks amazing in
YouTube". This records positive user-reported visual quality after YouTube
processing. No upload URL, selected playback resolution, device or individual
navigation/seam/audio checks were supplied. It is not an agent-observed playback
test or an independent addon installation test.

The intended lessons are:

- **8K is still only 1,920 horizontal source pixels per 90° view.** Thin luminous
  lines and small text need careful sizing. A 4K browser copy has half that detail.
- **The pipeline is offline.** Six views, readback, PNG writing and H.264 encoding
  all contribute. A 30 FPS output does not imply a 30 FPS export rate.
- **Retained frames dominate disk use.** They allow re-encoding and audio changes
  without rendering again. Partial capture resume is still absent.
- **Scene changes are authored explicitly.** There is no automatic map sequencing
  or crossfade editor; this film implements visibility and transition logic.
- **Rich rendering needs seam-aware choices.** The film uses world-space geometry,
  directional sky shading and shared effect transforms. It does not validate
  arbitrary screen-space effects or per-camera billboards.
- **Delivery remains mono 360 with ordinary stereo audio.** There is no stereo
  depth, ambisonics or viewer-dependent story branching. Positive YouTube visual
  feedback is recorded above; a detailed platform/headset checklist is not recorded.

This film uses the existing 0.8 addon without changing its release package. It adds
production evidence, a reusable authored scene and positive YouTube visual feedback.
The main remaining external validation is an independent Windows/GPU beta; detailed
playback checks and final release preparation remain part of the 1.0 decision.
