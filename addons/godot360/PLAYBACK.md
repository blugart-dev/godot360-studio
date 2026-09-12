# Review a complete 360 video in the editor

After a successful test or render, click **Play video** below the spherical
preview. The first use prepares a local review copy, then plays the whole clip
with the delivered audio mix. Drag the image to look around, use the position
slider to seek, pause to inspect a moment, or toggle **Mute / Unmute**.
The end of the clip offers **Replay**. Hiding the Godot360 panel pauses playback.

![Godot360 Studio with a completed calibration export and separate recipe settings.](media/studio.png)

*Drag the picture to look around. Use the slider beneath it to find a moment;
Play video / Pause and Mute / Unmute control the review. The screenshot shows
the included calibration scene in the full-resolution opening still.*

**Library → Saved exports and recovery → Open saved job…** also enables playback for an existing export with a successful
report and its delivery MP4. Retained PNGs are not needed for playback. Starting
another export or opening another job stops the current review.

## Review quality and dependencies

The copy is at most **2048×1024 and 30 FPS**, with Ogg Theora video and Vorbis
stereo audio. Godot plays it natively; no Python, browser server, .NET runtime or
additional Godot extension is needed. FFmpeg must include **libtheora** and
**libvorbis**. FFprobe checks the format and duration, then FFmpeg decodes the
entire video and audio before the copy becomes available. A successful encoder
exit and readable headers alone do not establish valid playback packets.
These codecs are only required for in-editor video playback. An FFmpeg build
without them can still export the usual H.264/AAC delivery MP4.

On macOS, install Homebrew's **ffmpeg-full** and select its explicit FFmpeg and
FFprobe paths using [Mac setup](PLATFORMS.md#macos). The basic Homebrew `ffmpeg`
package lacks `libtheora`; installing the separate Theora library does not add
that encoder to an already-built FFmpeg executable.

Review preparation converts the delivery's BT.709 pixels to sRGB transfer with
the BT.601 YUV matrix used by Godot's native Theora decoder. The spherical shader
then displays the resulting SDR texture. This is a pixel conversion, not a tag
change. The review copy remains lossy and is not a color-grading master.

Preparation is a separate, cancellable conversion and can take several minutes
for an 8K source. Its progress appears below the controls. The editor remains
available. Low disk space, failed processes, invalid output or a 15-minute timeout
stop preparation with an explanation; the original video and capture remain
unchanged. Closing the plugin also stops its preview conversion.

If the copy contains decoding errors, select another FFmpeg build in **Tool
setup**, click **Check setup**, then **Retry playback**. **Playback logs** opens the failed operation’s logs, while **Open delivery MP4** remains available for a verified export. Some Windows Theora
encoder builds can produce corrupt motion packets while still returning success.
The 2026-09-12 walkthrough reproduced this with the selected Gyan 8.0.1 full
build; rebuilding the same delivered MP4 with the tested Gyan 9.0.1 essentials
build passed a complete decode. This is build-specific evidence, not a claim
about every FFmpeg installation with those version numbers. No scene render is
needed to rebuild playback.

This is a motion, orientation and sound review, with approximate seeking. Check
the original `video-360.mp4` in an external 360 player for final resolution, fine
seams, 50/60 FPS motion and compression quality. The first-frame still preview
retains the original capture resolution. **Show still** pauses playback and returns to this opening frame; **Play video** restores the playback image. The review header identifies which image is displayed. Use arrow keys on the focused sphere and Home to reset its view.
Local playback does not certify YouTube processing or headset comfort.

## Cache and storage

Copies and conversion logs live in the project's ignored `.godot360/playback/`
folder. They do not change the export folder, recipe or delivery report. Opening
the same unchanged MP4 reuses its copy without another conversion. The cache key
includes the absolute source path, file size, modification time and review format.
Copies from before full-decode validation are rebuilt once on first use.
It does not fingerprint the source's full contents; replacing bytes while
preserving all of that metadata requires removing the corresponding cache folder.

Old copies are not automatically deleted. With playback stopped and preparation
finished, the local playback cache can be removed to reclaim space; the addon
rebuilds copies as needed. Cache storage is additional to the export's planning
estimate. Preparation maintains a 256 MiB reserve plus 16 MiB working headroom.

## Scene notes

Saved-scene checks now explain glow, auto exposure, fog, SDFGI, depth of field and
compositor risks before capture, alongside existing billboard and interface notes.
After a successful export, **Export details** shows the actual capture warnings
and signals their count beside its button. The details dialog includes selectable
paths and the full status, keeping long messages outside the review area. Inspect the relevant effects at several
times and viewing directions. These checks are heuristic; runtime changes and
custom materials can introduce effects that saved-scene inspection cannot see.

No rendering effect is automatically disabled or repaired. The optional
[capture border](RENDERERS.md#capture-borders) can soften glow cuts at face edges
and corners. Auto exposure still meters separate faces, and view-dependent effects
need inspection. See [renderer behavior and limits](RENDERERS.md).

## Validation scope

The development workflow tests real MP4-to-Ogg conversion, native paused seeks
using distinct decoded image intervals, playback and replay, audio reaching the
mix bus, cancellation, cache reuse, source preservation and missing tools.
Headless checks cannot validate rendered pixels. Native platform evidence is
recorded in the repository's `docs/validation.md`; existing Mac capture gaps remain.
