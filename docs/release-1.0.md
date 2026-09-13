# Godot360 Studio 1.0 release draft

**Unreleased.** This is the proposed release description for review. The current
package still identifies itself as 0.8.0; human walkthrough and final candidate
acceptance remain pending. Do not attach a development ZIP to a stable 1.0 release.

Godot360 Studio turns a saved, authored Godot 3D scene into a monoscopic 360° SDR
video with stereo sound. Choose a scene and camera, test a second, render a fixed
frame sequence, then inspect the spherical video, audio and delivery report in
the editor. Completed captures can be reopened and re-encoded without rendering
the scene again.

## Planned Windows launch

The [support contract](../addons/godot360/SUPPORT.md) defines five combinations:
Godot 4.7.2 with Compatibility/OpenGL 3, Forward+/Vulkan or Mobile/Vulkan, plus
4.5.1/4.6.3 with Compatibility/OpenGL 3. Windows 11 / RTX 3060 Ti is the native
reference environment. Linux/macOS remain experimental; other engines and
drivers retain their separately recorded evidence.

The release includes 2K/4K/8K recipes, short-test forecasts, authored animation and
camera cuts, stereo scene/soundtrack audio, H.264/AAC MP4 delivery, spherical
metadata, full delivery checks, spherical preview/playback, cancellation,
diagnostics, saved-job recovery and re-encoding. Current recipe, Tools, Library
and Opened export separate setup from review of an existing delivery.

Selected character, particle, trail, temporal and GI setups have native rendered
references. Four one-minute 4K/8K Forward+/Mobile workloads establish measured
performance on one Windows machine; they do not establish general minimum
hardware requirements or unlimited-duration performance.

## Limits to include with the release

- Use authored exposure for consistent brightness. Per-face automatic metering
  remains available with seam risk; shared spherical adaptation is deferred.
- Capture borders can reduce glow cuts, while halo shape, screen-space effects,
  reflections and temporal history can still differ at cube boundaries.
- Custom compositors must maintain history per view. The tested Mobile history
  path needs authored 4× MSAA and its writable intermediate texture.
- GPU particles need documented warmup. Compatibility does not support native
  GPU trails. General IK/retargeting and arbitrary shader stacks are outside the
  established scene evidence.
- Partial captures restart from the beginning. Complete retained PNG/WAV captures
  can be re-encoded; original captured pixels and capture settings remain fixed.
- Delivery is mono 360 SDR with stereo audio. Stereoscopic ODS, HDR, ambisonics
  and automatic uploads are outside this release.

## Installation and upgrade

Use [platform setup](../addons/godot360/PLATFORMS.md), copy `addons/godot360` into
the project, enable the plugin, select the tested FFmpeg/FFprobe tools and follow
the [quick start](../addons/godot360/QUICKSTART.md). Existing users should close
active exports, back up recipes/settings and follow
[upgrading Godot360](../addons/godot360/MIGRATION.md).

## Final acceptance record

- [ ] Record the completed human walkthrough and itemized delivery review.
- [ ] Resolve any supported-workflow blocker; retain the unexplained historical
  Linux Mobile observation and its fresh passing evidence.
- [ ] Set consistent stable version labels in plugin, panel, metadata, guides and
  generated package README; replace this draft's development status.
- [ ] Record the final commit, exact addon/source ZIP names, SHA-256 values,
  manifests, native Windows acceptance and required CI results.
- [ ] Complete the public-history choice and verify issue/security settings.
- [ ] Obtain final publication authorization for the exact source and artifacts.

Follow [release readiness](release-readiness.md), [validation](validation.md) and
[publishing](publishing.md). This draft prepares the release and does not publish it.
