# Godot360 Studio 1.0 release preparation

**Prepared privately; publication on hold.** The current package identifies itself
as **1.0.0**. The owner reported no errors after RC2 review and authorized final
preparation, explicitly requiring further instruction before public release.
The exact 1.0.0 addon passes its full Windows acceptance matrix.

## Validated private 1.0.0 addon

Addon source: **`cea9bae3b449974d70962d66e95cf653f7e8ff58`** on
`codex/windows-1.0-stabilization`. `godot360-studio-1.0.0.zip` has **245 members**,
**884,541 bytes**, and SHA-256
**`5ab5ea3589d4c32347890cd33daf5925b3c728eb385442d2f71ecbe3c38a9dde`**.

The exact ZIP passes **6,070 checks across five Windows engine/renderer lanes**
and **52 native editor checks**. It rebuilds identically; repository CI produces
the same bytes. Both V1 XML and V2 binary spherical metadata carry version 1.0.0
in all fifteen workflow deliveries. Runtime differences from RC2 are version
strings only; recipes, settings, capture/encoding and tests/fixtures are unchanged.

Evidence is retained under `.godot360/stable-1.0-review-20260913/`. The final
`release/` folder contains the addon, a source snapshot with current release
documentation and no Git history, `SHA256SUMS.txt` and `release-manifest.json`.
The manifest records each archive's source commit and exact checksum; final source
import/startup and rendered-workflow results accompany it. Root documentation
recording acceptance follows the frozen addon commit. See [validation](validation.md).

Final source snapshot: **`e4385b02c7ecb39a8e115393ae3940eeaa1cf8ce`**.
`godot360-studio-1.0.0-source.zip` has **497 members / 75,869,646 bytes**;
SHA-256 **`3abcbf64d393de29fc8c22975486ca559b9fc451f91dedcfdb97d7cc4ff450c4`**.
It rebuilds identically and passes clean import/startup plus **247 scene and
rendered-workflow checks**, with all source payloads unchanged and no credentials
found. Its manifest/archive identity is frozen; this completion entry follows
that snapshot. The local `release/READY.md` and manifest summarize the handoff.

The unresolved experimental Linux Mobile history result remains open. The fresh
RC2 Windows temporal review and other bounded rendering evidence remain mapped
to unchanged rendering code. Public visibility, default-branch/tag decisions,
history choice, release uploads and external-service review remain separate.

## Frozen private RC2

RC2 adds native offline help, clearer installation and quality/support guidance,
storage/source-retention explanations, and correct handling of cancellation
before coordinator startup. It keeps the existing Windows launch matrix and
capture/encoding settings. Current guides distinguish historical 0.x/RC1 evidence
from the new candidate.

Candidate source: **`f1329c1c6478ccc942eacddd35247b4e9bf318f2`**, on the private
`codex/windows-1.0-stabilization` branch. Evidence and distributions are retained
under `.godot360/rc2-review-20260913/`:

- `godot360-studio-1.0.0-rc.2.zip`: **245 members, 884,186 bytes**; SHA-256
  `d2693cf7d1f3c785868b7ed7d5f3f7d4e40ec5604477d0db0f9060e82c12d940`.
- `godot360-studio-1.0.0-rc.2-source.zip`: **497 members, 75,862,666 bytes**;
  SHA-256 `43e0745704a2de7777b6df4ea0b9a95d5cafb1633fa932a49468f8ff1a20442e`.
  It includes a source manifest and no Git history.

Both archives rebuild identically. The addon passes **6,070 native Windows
package checks** and **52 native editor checks** against that exact ZIP.
Repository CI builds the same addon bytes. The source archive freezes the
candidate commit; later root documentation records its acceptance evidence.
The experimental Linux Mobile temporal job repeats the known opening-history
mismatch and remains failed. See [validation](validation.md) for the full result
and the separate Windows evidence. The clean `owner-walkthrough/` uses RC2;
human navigation, listening and delivery acceptance remain pending.

## Frozen private RC1 artifact

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
diagnostics, saved-job recovery, re-encoding and offline in-editor help. Current recipe, Tools, Library
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

- [x] Record the owner's RC2 feedback: "I did not get any errors," followed by
  authorization to prepare 1.0. Individual subjective/device checks were not
  supplied and are not recorded as passed.
- [x] No supported-workflow blocker is reported or reproduced in final native
  checks; retain the recurring experimental Linux Mobile observation separately.
- [x] Set consistent stable version labels in plugin, panel, metadata, guides and
  generated package README; replace this draft's candidate status while retaining
  the separately identified historical evidence.
- [x] Record the exact addon commit/hash, manifest, native Windows acceptance and
  passing repository CI.
- [x] Complete the final source archive verification and local release manifest.
- [ ] Complete the public-history choice and verify issue/security settings.
- [ ] Obtain final publication authorization for the exact source and artifacts.

Follow [release readiness](release-readiness.md), [validation](validation.md) and
[publishing](publishing.md). This draft prepares the release and does not publish it.
