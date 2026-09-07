# Test, plan, render, and re-encode

Umbral360 Studio 0.3 keeps the expensive scene capture separate from encoding.
Use a short sample to plan a new capture and reuse retained frames when only
the H.264 quality needs changing.

## Before a full render

1. Save your scene and select its camera, intended resolution, face size, FPS,
   duration, frame storage, and H.264 CRF in the Umbral360 panel.
2. Choose the output parent folder and click **Test 1 second**. The full recipe
   stays intact. The sample renders at most one second plus warmup, encodes it,
adds spherical metadata, and runs the same output checks as a full export
(thirteen since 0.6, including V2, fast-start and audio duration).
3. Inspect the sample and review the estimated full-export time, retained files,
   suggested free space, and available space above the spherical still preview.
4. Click **Render 360 video** for the full recipe. It starts a new job; the sample
   is not stitched into the full capture.

Capture and encoding show frame counts and approximate remaining time for their
own stage. Encoding ETA waits until at least ten frames and 10% of the clip have
completed, reducing the influence of encoder startup. Cancel stops capture at a
frame boundary or stops the active encoding/verification process. Logs and partial
files remain available for diagnosis. Only verified output is named `video-360.mp4`.

## What the estimate measures

The sample records real capture, encoding, and verification times and retained
PNG, WAV, and MP4 sizes. Capture time scales by delivered frames plus warmup;
measured render startup remains fixed. Encoding and verification scale by delivered
frame count. Storage includes source PNG/WAV, a preview, and both MP4 copies.
Suggested free space adds 25%, a 256 MiB reserve, and the capture working allowance
for images and audio. No disk space is reserved. Version 0.7 also checks operating
headroom during jobs and fails explicitly if required output files cannot be
written. See the [storage guide](../addons/umbral360/STORAGE.md).

Duration changes rescale an existing sample. Changes to scene/camera selection,
resolution, face size, FPS, seed, warmup, frame storage, CRF, executable paths, the
saved scene's modification time, or the output parent require a new sample.
Referenced scripts, textures, and other assets are not fingerprinted. Re-test
after editing them or changing engine, hardware, or rendering configuration.
Active audio settings and the attached soundtrack's path, size and modification
time are included since 0.6. The soundtrack stays external and is not counted as
new retained storage. See the [audio guide](../addons/umbral360/AUDIO.md).

These are first-second extrapolations. A quiet opening cannot predict the cost or
compressed size of a busy later scene. Encoder startup also affects short samples.
The figures help plan work; they are not deadlines or guaranteed disk bounds.

### Local 4K sample

On 2026-09-06, the 12-second UMBRAL recipe was sampled at 4096×2048, 2048-pixel
faces, 30 FPS, Fast PNG, and CRF 16 on the machine listed in [validation](validation.md).
The one-second sample passed all eight checks in **13.30 seconds**. It estimated
**2 minutes 3 seconds** and **1.77 GiB retained** for the full recipe, with
**2.27 GiB suggested free space**. The full 4K export was not timed against this
estimate. The first second precedes several authored events, so later costs can differ.

The evidence is in `renders/test-2026-09-06T21-52-29-2066321/`: `job.json`,
`report.json`, `storage.json`, and `planning.json`. The panel remembers this sample
through local settings; changing duration recalculates the displayed estimate.

## Change encoding quality without rendering again

1. Set **H.264 CRF** and the **Audio and synchronization** controls in the panel.
   Lower CRF values preserve more detail and usually increase the encoded file size.
2. Choose **Re-encode saved…**, then select an original completed capture folder.
   Alternatively, open the job with **Open saved job…** and use **Re-encode this
   capture** when the retained PNG/WAV source is eligible. This also finds the
   original capture behind a failed re-encode.
   It must contain its saved job, successful capture result, complete consecutive
   PNG sequence, and finalized WAV.
3. Watch encoding progress and inspect the new video and report when complete.

The saved capture supplies dimensions, FPS, frame count, and warmup trimming.
The current panel's audio source, levels, trim and synchronization offsets apply
to the new output. CLI requests inherit saved audio unless explicitly overridden.
The panel's current scene and resolution fields do not alter it. Source files are
read without modification, and the new job must be outside the source folder.
Each re-encode gets fresh MP4s, a preview, logs, and `capture_source` in its report.
It does not duplicate the PNG/WAV source, so retain the original capture folder.
Incomplete captures cannot be resumed through this action.

Re-encoding needs FFmpeg/FFprobe and the addon but no installed scene or GPU capture.
The 12-second 8K UMBRAL capture was re-encoded successfully in a minimal headless
project in **54.86 seconds**, passing all eight checks. Its intermediate
`encoded.mp4` matched the original SHA-256 exactly at the same CRF and tool version.
This result does not imply byte-identical encoding across different tool versions.

See the [addon guide](../addons/umbral360/README.md#command-line) for JSON jobs and
CLI commands. For the following milestone, see the [roadmap](roadmap.md).
