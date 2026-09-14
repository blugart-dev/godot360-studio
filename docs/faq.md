# Common questions

## Which download do I need?

Use the [addon ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0.zip)
to export your own project: copy `addons/godot360` beside your `project.godot`.
The archive's `tests/` and `tools/` folders are optional developer material.

Use the [source and examples ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0-source.zip)
to explore UMBRAL, THRESHOLD, LUMEN and AFTERGLOW. Extract it and open its
`project.godot`. The addon is already enabled. [Installation walkthrough](../addons/godot360/QUICKSTART.md).

## Can I watch the results without installing Godot?

Yes. [Watch all four films on YouTube](https://www.youtube.com/playlist?list=PLUjBgihWYNpQ).
Drag to look around on desktop or swipe in the YouTube mobile app. The
[visual tour](showcase.md) also includes flat previews and stills.
THRESHOLD, LUMEN and AFTERGLOW have stereo scores; UMBRAL's published demo is silent.

## Is this stereoscopic VR or an interactive game?

The output is **mono 360° video**: one spherical view, with no separate left/right
eye images. You can turn your view during a fixed timeline. You cannot walk freely
or trigger Godot gameplay from the video. UMBRAL's gaze interactions run when you
play its Godot scene; its film uses a prepared sequence. See [authoring](../addons/godot360/AUTHORING.md).

## Why does a 2K export look soft?

The resolution covers the entire sphere. A 90° view spans roughly one quarter of
its horizontal source pixels, so a 2K panorama is not a 2K viewing window. Use
2K to test compatibility and 4K/8K for more detail. Cube-face size also affects
sharpness; the panel's quality advice checks it. [Quality and renderer guidance](../addons/godot360/RENDERERS.md).

The in-editor **playback copy** is capped at 2K / 30 FPS. Inspect the full-resolution
still or final `video-360.mp4` for delivery detail. On YouTube, check the available
quality after processing. [Playback guide](../addons/godot360/PLAYBACK.md).

## Does it need Python, .NET or export templates?

The addon needs Godot Standard, FFmpeg and FFprobe. Python, NumPy and Pillow are
optional development/media-review tools; .NET, a compiler and Godot export
templates are not required. Tool downloads are manual. [Platform setup](../addons/godot360/PLATFORMS.md).

## Why do LUMEN and AFTERGLOW look different when I run them?

Their film recipes select **Forward+**. This repository's main project uses
Compatibility for UMBRAL. Load the film's recipe for export, or use its documented
Forward+ launch command for live preview. Loading a recipe does not change the
project's saved renderer. [LUMEN](lumen.md#open-and-export-it) · [AFTERGLOW](afterglow.md).

## What if glow or other effects show seams?

Six camera faces are captured from one origin. Effects that depend on a screen's
edges or separate exposure histories can disagree between faces. Start with
**Test 1 second**, inspect edges and poles, and consult the
[renderer limits](../addons/godot360/RENDERERS.md) and [capture-border examples](capture-borders.md).
Capture borders reduce tested glow cuts; they do not guarantee seamless arbitrary effects.

## Can I change the music or compression without rendering again?

Yes, if you retain the completed source capture. Use **Library → Saved exports
and recovery → Re-encode saved…**. Audio/compression changes can reuse the frames;
scene, camera or animation changes require a new render. The re-encode produces a
new job and preserves the source. [Audio](../addons/godot360/AUDIO.md) · [Recovery](../addons/godot360/RECOVERY.md).

## Which file do I upload or keep?

`video-360.mp4` is the verified delivery with spherical metadata. The browser/editor
review copies and documentation tours serve different purposes. Keep the full job
folder if you need re-encoding or recovery; retain the delivery separately before
reclaiming render data. [Storage](../addons/godot360/STORAGE.md) · [YouTube production](youtube-360-production.md).

## Where do I report a problem?

[Open an issue](https://github.com/blugart-dev/godot360-studio/issues/new/choose)
with the addon/Godot versions, OS, GPU, renderer, reproduction steps and a small
scene if possible. Note whether **Test 1 second** reproduces it. Inspect logs and
diagnostics for private paths before sharing. Use the [security policy](../SECURITY.md)
for sensitive reports. [Contributor guide](../CONTRIBUTING.md).

[All guides](README.md) · [Back to the project](../README.md)
