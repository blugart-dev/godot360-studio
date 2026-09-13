# Godot360 Studio 1.0.0

**Windows supported; Linux/macOS experimental.** Released September 13, 2026.

Godot360 Studio turns a saved, authored Godot 3D scene into a monoscopic 360° SDR
video with stereo sound. Choose a scene and camera, test a second, render a fixed
frame sequence, then inspect the spherical video, audio and delivery report in
the editor. Completed captures can be reopened and re-encoded without rendering
the scene again.

## Downloads

- [Release and checksums](https://github.com/blugart-dev/godot360-studio/releases/tag/v1.0.0)
- [Addon ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0.zip): install `addons/godot360` in your project; includes offline guides, calibration and Motion lab.
- [Source and examples](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0-source.zip): open `project.godot` to try UMBRAL, THRESHOLD, LUMEN and AFTERGLOW, with their scenes, music and recipes.

The release includes `SHA256SUMS.txt` and a portable `release-manifest.json`.
The dedicated source ZIP contains a verified source manifest and no Git history.
GitHub's automatically generated source archives are separate downloads.

## What is included

- Mono equirectangular 2K/4K/8K recipes, fixed-frame capture, authored animation,
  camera paths and cuts, and 24/25/30/50/60 FPS presets.
- Scene stereo audio, an attached soundtrack or both, with timing and levels.
- H.264/AAC MP4 delivery, SDR BT.709, V1/V2 spherical metadata and technical checks.
- A one-second test with measured time/storage estimates before a long export.
- Spherical still preview and video playback with drag, keyboard look, seeking
  and sound. The editor video copy is limited to 2K/30 FPS; delivery is unchanged.
- Saved recipes, recent exports, cancellation, diagnostics, job recovery and
  re-encoding of complete retained PNG/WAV captures.
- Native offline help and installation, authoring, audio, renderer, storage,
  recovery and upgrade guides. The addon uses Godot's editor controls and requires
  no custom engine, .NET runtime, compiler or Python installation.

## Installation and upgrade

1. Install Godot Standard and native FFmpeg/FFprobe using [platform setup](../addons/godot360/PLATFORMS.md).
2. Extract the addon ZIP and copy `addons/godot360` beside your `project.godot`.
3. Enable **Godot360 Studio** under **Project > Project Settings > Plugins**.
4. Open the **Godot360** bottom panel, configure **Tools → Tool setup**, choose a
   saved scene and camera, then run **Check setup** and **Test 1 second**.
5. Inspect the test before selecting **Render 360 video**.

Follow the [quick start](../addons/godot360/QUICKSTART.md). Existing users should
finish or cancel exports, close Godot, back up recipes/settings and follow
[upgrading Godot360](../addons/godot360/MIGRATION.md). Recipes, settings and saved
jobs retain RC2 formats. FFmpeg/FFprobe and Godot are installed separately; the
addon does not download tools or upload scenes, diagnostics or videos.

## Supported Windows launch

| Godot Standard | Renderer | Driver |
| --- | --- | --- |
| 4.7.2 | Compatibility | OpenGL 3 |
| 4.7.2 | Forward+ | Vulkan |
| 4.7.2 | Mobile | Vulkan |
| 4.6.3 | Compatibility | OpenGL 3 |
| 4.5.1 | Compatibility | OpenGL 3 |

Windows 11 / RTX 3060 Ti and FFmpeg/FFprobe 9.0.1 essentials are the native
reference environment. This does not establish every GPU or driver. Read the
[support contract](../addons/godot360/SUPPORT.md) for the exact scene/effect boundary.
The 1.0 runtime passes 6,070 package checks across these five lanes and 52 native
editor checks. Public archives refresh Markdown guides; [validation](validation.md)
maps unchanged code/fixtures to those results and records fresh archive checks.

Linux/macOS remain experimental. Linux software-Mobile temporal history has an
unresolved mismatch in its first five frames; its original thresholds and failed
evidence remain recorded. Windows Mobile temporal checks pass separately.
Mac headless CI does not establish graphical Mac export support. See
[platform coverage](../addons/godot360/PLATFORMS.md#support-status).

## Known limits

- Use authored exposure for consistent brightness. Per-face automatic metering
  remains available with seam risk; shared spherical adaptation is deferred.
- Capture borders can reduce glow cuts. Halo shape, screen-space effects,
  reflections and temporal history can still differ at cube boundaries.
- Custom compositors need history per view. The tested Mobile history path needs
  authored 4× MSAA and its writable intermediate texture.
- GPU particles need documented warmup. Compatibility does not support native
  GPU trails. General IK/retargeting and arbitrary shader stacks are outside the
  established scene evidence.
- Partial captures restart from the beginning. Re-encoding requires complete
  retained source frames/audio and does not alter their captured pixels.
- Four one-minute 4K/8K workloads establish performance on one Windows machine;
  longer exports and heavier scenes need their own measurements and disk headroom.
- Stereoscopic ODS, HDR, ambisonics and automatic uploads are outside 1.0.
  YouTube/headset processing and playback require separate review after delivery;
  local technical checks do not certify an external service or device.

## Help, licenses and development

Use [the documentation index](README.md) and repository
[issue forms](https://github.com/blugart-dev/godot360-studio/issues/new/choose).
Follow the [security policy](../SECURITY.md) for sensitive reports.
Original addon, examples, music and documentation use the [MIT license](../LICENSE);
separately sourced material retains [third-party notices](../THIRD_PARTY_NOTICES.md).

[Changelog](../addons/godot360/CHANGELOG.md) · [Contributing](../CONTRIBUTING.md)
· [Release acceptance](release-readiness.md) · [Publication record](publication-review.md)
