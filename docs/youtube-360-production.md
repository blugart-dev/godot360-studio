# A reproducible Godot → YouTube 360 workflow

The first standard is intentionally narrow: **mono equirectangular video, a 2:1
frame, SDR BT.709, and ordinary stereo audio**. This is the implemented v0.4 path.
An equirectangular frame stores every viewing direction at one instant; the player
lets viewers choose which part to see. The scene timeline is shared by all viewers.

## 1. Author a film

Choose a fixed observation point or a carefully authored camera path. Keep important
events visible long enough to find, distribute attention cues across the environment,
and avoid essential text at the poles or directly on the rear seam.

Replace gaze-dependent events with an authored timeline for the video. UMBRAL's
`prepare_360_capture` and `begin_360_capture` hooks show how the same scene can have
interactive and film behaviors. A recorded video does not retain executable Godot
scripts, free movement, dynamic branching, or per-viewer state.

For an editable camera path and keyed property timeline, start from **Motion lab**.
The [authoring guide](../addons/godot360/AUTHORING.md) explains the AnimationPlayer
helper, frame-zero timing, warmup, supported tracks, and synchronization cues.

Use a square 90° cubemap capture from one origin. Avoid camera-facing geometry and
screen-space effects unless specifically validated across cube boundaries. A single
`World3D` must advance once per output timestep while all six views render that state.

## 2. Calibrate

Render the included calibration scene before committing to a long job. Confirm:

- Front at image center; right at 75% of image width; left at 25%; back at the edges.
- Up and down are correctly oriented, with asymmetric labels readable when reprojected.
- Grid lines and moving objects remain continuous across cube boundaries.
- The generated tone is audible, stable, and matches the requested duration.

The studio includes a drag-to-look still viewer. Inspect later frames and full
motion in a spherical video player as well. Check the rear seam and both poles.

## 3. Save the recipe and render

Save a `.tres` recipe with scene, camera path, resolution, face size, frame rate,
duration, seed, warmup, and quality. Use 2048×1024 with 512-pixel faces only for
draft compatibility checks. The Production preset uses 4096×2048 with 2048-pixel
faces; Detail uses 7680×3840 with 3072-pixel faces. A 90-degree view uses roughly
one quarter of the panorama's source columns, so a 2K panorama is not a 2K view.

Use **Test 1 second** on the actual film at those settings. Inspect the sample and
the estimated full-export time, retained storage, and free-space advice before
selecting **Render 360 video**. The estimate is based on the first second, so later
events can change its accuracy. Re-test after scene or asset edits. See
[job planning](job-planning.md) for details.

Offline rendering separates production time from playback time. A frame can take
longer than 1/30 s to render and still belong to a 30 fps video. The pipeline saves
exactly the requested number of delivered frames, retaining warmup frames in the
source sequence and trimming the same duration from audio when encoding.

Keep the job recipe, engine version, source scene, and output report together.
Select Fast PNG for speed or Compact PNG for smaller retained frames. Both are
lossless. Use `capture-timings.json` and the pipeline timings in `report.json`
to measure production cost; an 8K file need not require real-time capture hardware.
Fixed FPS and a seed help repeatability but do not guarantee identical results
across engine versions, GPUs, global shader time, or nondeterministic scene scripts.

## 4. Encode and mark the video

The integrated encoder converts sRGB viewport output to SDR BT.709, encodes H.264
with 4:2:0 chroma, and writes AAC stereo at 48 kHz into MP4. It then adds spherical
metadata using the published V2 boxes and matching V1 UUID/XML. The original
encoded media stays intact.

Metadata describes how to interpret pixels; it cannot turn an ordinary camera
recording into a complete panorama. Both projection and metadata must be correct.

Version 0.5 places `moov` before media for fast-start and adjusts every video/audio
chunk offset, using 64-bit tables when needed. Current output checks include full
mono V2 metadata, V1 compatibility, fast-start layout and chunk-offset bounds.
Version 0.6 adds an audio-duration check, for thirteen checks in total.
Do not remux the final file without rechecking that its metadata survives.

To try a different H.264 quality, set CRF and choose **Re-encode saved…**. Select
the original completed capture folder. The pipeline reads its PNG/WAV source,
preserves captured dimensions and timing, and produces a new validated video without
rendering the scene. It leaves every source file in place. Live encoding progress
and cancellation are available for both new captures and re-encodes.
The **Audio and synchronization** controls can also attach a soundtrack, mix it
with scene audio, or adjust levels and timing during re-encoding. See the
[audio guide](../addons/godot360/AUDIO.md) for the frame-zero contract and file retention.

## 5. Validate before upload

`report.json` must pass dimensions, decoded frame count, FPS, duration, video format,
color tags, audio format, and spherical mapping checks. Inspect `scene-checks.json`
for potential seams. A green technical report does not replace visual/audio review.

Upload a short private or unlisted calibration clip manually, allow YouTube's 360
processing to finish, and check navigation, orientation, resolution, sound, seam
continuity, and duration on the intended devices. The local tool does not upload
anything. A user has confirmed basic 360 playback for the initial 2K UMBRAL clip,
but reported blurry/pixelated imagery. Broader device and quality checks remain.

Follow [YouTube's spherical upload instructions](https://support.google.com/youtube/answer/6178631?hl=en)
and [encoding guidance](https://support.google.com/youtube/answer/1722171?hl=en).

## Community scope

The contribution is an integrated, reproducible workflow with a small original
addon, rather than a new projection standard. It includes calibration, portable
recipes, a documented scene hook, retained evidence, and explicit validation limits.

Before an Asset Library release: validate installation in a clean project, test
more machines and Godot versions, include the license and examples, and report
the actual tested compatibility. The present work creates a local prototype and
documentation; no community announcement or publication has been made.

Stereo 360 is a separate milestone. Two offset ordinary cubemaps are not sufficient
for correct omnidirectional stereo. Spatial audio likewise needs an ambisonic capture
and metadata design; Godot's ordinary stereo mix is not an AmbiX master.

See the [addon reference survey](../addons/godot360/REFERENCES.md) for existing
projects and the official documentation used to design this implementation.
