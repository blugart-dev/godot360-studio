# Capture performance

## Original 0.2 comparison

Windows, Godot 4.7.2, Compatibility / OpenGL, NVIDIA RTX 3060 Ti, and FFmpeg 9.0.1.
The scene, camera, seed, 7680×3840 panorama, 3072-pixel cube faces, 4× MSAA,
30 fps clock, and CRF 16 output are held constant.

The instrumented six-frame comparison includes two warmup frames:

| Measurement | Compact PNG | Fast PNG |
| --- | ---: | ---: |
| Capture elapsed, including final writer flush | 20.620 s | 3.691 s |
| Godot image write / pipe submission time | 17.237 s | 0.455 s |
| Explicit GPU readback time | 0.826 s | 0.528 s |
| Matching decoded source frames | 6 / 6 | 6 / 6 |

Capture was about **5.6× faster** in this short comparison. Every decoded byte
of all six RGBA images matched. Fast PNG's submission timing does not include
all encoder CPU work: compression can overlap later rendering. Compare elapsed
capture time, not the sum of overlapping stages.

The original single-frame storage probe took about 2.9 s with Godot PNG versus
0.26 s with FFmpeg's level-1 Sub predictor, including process startup. The retained
PNG grew from 6.54 MB to 17.00 MB. Both decoded to exactly the same RGBA bytes.
This is a storage-size tradeoff, not a reduction in image quality.

## Full 12-second 8K export

The replacement captured all 362 frames, including warmup, in **166.656 s**
(2 min 47 s). The whole pipeline took **220.257 s** (3 min 40 s), including
encoding and independent verification. The earlier Compact PNG run took roughly
20 minutes in capture alone (1,193.480 s between first and last PNG writes).
The full-run comparison is approximate because the older job predates instrumentation.

All eight MP4 checks pass: 7680×3840, 360 delivered frames, 30 fps, 12 seconds,
H.264/yuv420p, SDR BT.709, AAC stereo/48 kHz, and spherical mapping.
The encoded MP4 before metadata injection is **byte-for-byte identical** to the
earlier quality render. The source WAV files also match exactly. The final files
carry different addon version strings in the spherical metadata.

| Retained source storage | Bytes | Approximate GiB |
| --- | ---: | ---: |
| Original Compact PNG sequence | 2,382,647,316 | 2.22 |
| New Fast PNG sequence | 6,171,693,108 | 5.75 |

The final video remains 9,849,143 bytes. Faster storage used about 2.6× the PNG
disk space in this example. Select Compact PNG when that tradeoff is unsuitable.

The full run is recorded in `renders/umbral-fast-8k/report.json`; the original
quality render is retained in `renders/umbral-quality-8k/`. Generated evidence is
excluded from version control. These are measurements of this scene and machine,
not a general speed or disk-space guarantee.

## Why the addon still uses GDScript

PNG storage consumed about 84% of the measured baseline capture interval; explicit
GPU readback consumed about 4%. The slow call was already a native engine function.
Moving the surrounding coordination code to C++ would leave that work unchanged.

The new backend uses Godot's [native process pipes](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe)
and FFmpeg's [lossless PNG encoder](https://ffmpeg.org/ffmpeg-codecs.html#png).
A blocking pipe provides backpressure; there is no unbounded GDScript frame queue.
The existing FFmpeg dependency supplies native compression without an addon DLL.

The remaining capture interval includes scene rendering, Movie Maker's second
image readback and scratch PNG, synchronization, and other engine work. It is not
accurately labeled as GPU render time alone. A future native
[MovieWriter](https://docs.godotengine.org/en/stable/classes/class_moviewriter.html)
could address the duplicate image/audio path, provided new measurements justify
its build, distribution, and maintenance cost.

## Repeat the comparison

1. Use the same saved scene, camera, seed, render settings, and frame count.
2. Export once with Compact PNG and once with Fast PNG, in fresh output folders.
3. Compare `capture-timings.json` elapsed time and the stage timings in `report.json`.
4. Decode matching PNGs and compare their pixel bytes; compressed PNG bytes differ.
5. Verify the final MP4's frame count, dimensions, color tags, audio, and projection.

`tests/frame_writer_checks.gd` exercises actual RGB/RGBA round trips, ordering,
missing tools, stopped encoders, and cleanup. `tests/studio_checks.gd` covers an
actual editor-panel export, preview, and cancellation. These tests complement
visual review and do not certify every possible source scene.

## 0.7 production-resolution validation

The same Windows/Godot 4.7.2/RTX 3060 Ti/Compatibility environment now passes
longer actual GPU captures at 30 FPS with Fast PNG and two warmup frames:

| Measurement | 60-second 4096×2048 | 30-second 7680×3840 |
| --- | ---: | ---: |
| Cube face size | 2048 | 3072 |
| Delivered frames | 1,800 | 900 |
| Capture elapsed, including writer flush | 192.513 s | 279.628 s |
| Explicit readback, summed | 50.001 s | 77.981 s |
| Image write/pipe submission, summed | 6.001 s | 63.502 s |
| H.264/AAC encoding stage | 50.750 s | 95.969 s |
| Output verification stage | 14.960 s | 19.434 s |
| Whole pipeline | 261.018 s | 397.924 s |
| Retained PNG bytes, including warmup | 606,232,621 | 1,052,915,806 |
| Whole retained review folder, bytes | 631,474,043 | 1,067,788,420 |

All delivered source and decoded frame codes/flash states pass. All thirteen
output checks pass, and audio cues near the beginning, middle and end show zero
measured drift. AAC adds zero measured cue lag to the constant +2-sample source
offset. Saved settings remain unchanged and Movie Maker scratch images are cleaned.

The subsequent independent Python image/audio review is excluded from pipeline
time. Write/readback sums do not cover all capture work and must not be added to
the elapsed interval. This simple frame-code scene compresses unusually well;
these are duration/resolution reliability results, not a like-for-like comparison
with the original UMBRAL film or a forecast for complex production scenes.
They do not isolate the benefit of a native backend or certify longer exports.
Full reports are in renders/production-070-4k-full/endurance-review.json and
renders/production-070-8k-full/endurance-review.json, with capture stage details in
each capture/report.json and capture/capture-timings.json.
