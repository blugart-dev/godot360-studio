# Godot360 Studio 1.0 release draft

**Unreleased.** This is the proposed release description for review. The current
package identifies itself as **1.0.0-rc.1**; human walkthrough and stable candidate
acceptance remain pending. Do not attach an RC ZIP to a stable 1.0 release.

## Private RC1 artifact

Candidate source: **`b323a92e1b74b749a32adb6d5d4b1f7669874f9b`** on
`codex/windows-1.0-stabilization`. The addon ZIP has 243 members and 875,471 bytes;
SHA-256 **`78f850256fb956f8d9365eaa03df7f4cdb0b3f1ab9f968b8b8e27044d7ff6e79`**.
The source ZIP has 495 members and 75,847,196 bytes, including its manifest and
no Git history; SHA-256
**`76ff9055d0ef59c2ed0cb65132e4e69d5e83aae180bb7df038bee418d62b50a9`**.
Both rebuild identically. Repository CI passes and produces the identical addon
ZIP. Local archives and exact review reports are retained under
`.godot360/rc1-review-20260913/`; no release assets have been uploaded.

RC1 updates the plugin, panel and spherical metadata release strings and adds
numbered-candidate support to the package builder. The comparison against the
preceding reviewed package confirms unchanged capture/rendering behavior.
All five native Windows package lanes pass **5,930 checks**, and the two-process
native editor review passes **44 checks**, against that exact ZIP. The
[validation record](validation.md#private-windows-rc1-acceptance-evidence--2026-09-13)
maps these results and the six release-identity regression tests. The
prepared `owner-walkthrough/` in the RC1 evidence folder installs this exact ZIP.

## Proposed stable release description

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
  generated package README; replace this draft's candidate status and refresh
  legacy compatibility-guide intros while retaining their historical evidence.
- [ ] Record the final commit, exact addon/source ZIP names, SHA-256 values,
  manifests, native Windows acceptance and required CI results.
- [ ] Complete the public-history choice and verify issue/security settings.
- [ ] Obtain final publication authorization for the exact source and artifacts.

Follow [release readiness](release-readiness.md), [validation](validation.md) and
[publishing](publishing.md). This draft prepares the release and does not publish it.
