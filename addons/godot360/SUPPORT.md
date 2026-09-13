# Windows 1.0 support contract

This is the support contract for **1.0.0**, prepared privately for release.
Windows is the supported launch platform; Linux and macOS remain experimental.
Public distribution awaits the owner's explicit instruction.

## Engine and graphics combinations

The Windows launch matrix is deliberately tied to tested engine versions and
drivers. Use the Standard x86_64 editor and a saved, authored 3D scene.

| Godot | Renderer | Driver | 1.0 coverage |
| --- | --- | --- | --- |
| 4.7.2 | Compatibility | OpenGL 3 | Baseline scene, export, audio, playback and recovery workflow. |
| 4.7.2 | Forward+ | Vulkan | Baseline workflow plus the bounded advanced cases below. |
| 4.7.2 | Mobile | Vulkan | Baseline workflow plus the renderer-specific advanced cases below. |
| 4.6.3 | Compatibility | OpenGL 3 | Baseline workflow; advanced Vulkan cases are not established by this row. |
| 4.5.1 | Compatibility | OpenGL 3 | Baseline workflow; advanced Vulkan cases are not established by this row. |

The five-lane reference environment is Windows 11 and an RTX 3060 Ti. This is
the reference environment, not a claim that every Windows GPU has been tested.
FFmpeg/FFprobe 9.0.1 essentials is the tested Windows tool pair. See
[platform setup](PLATFORMS.md) for installation and required codecs.

D3D12, ANGLE, older-engine Forward+/Mobile combinations, other engine versions,
and native Linux/Mac graphical workflows retain their narrower or experimental
status. Earlier successful appearance clips do not establish a complete launch
workflow for those combinations. The dated [renderer evidence](RENDERERS.md)
remains useful without broadening this matrix.

## Scene and delivery boundary

| Area | Included workflow | Limit or required setup |
| --- | --- | --- |
| Delivery | Monoscopic equirectangular H.264 MP4, SDR BT.709, stereo AAC and spherical metadata; 2K/4K/8K recipes. | No stereoscopic ODS, HDR delivery, ambisonics or automatic uploads. Target-service playback remains a separate delivery review. |
| Scene timing | A saved scene and camera, authored animation, frame-clock capture hooks, camera motion and cuts. | Save assets first. Arbitrary interactive gameplay, nondeterministic simulation and every custom script are not certified. See [authoring](AUTHORING.md). |
| Lighting and materials | Native renderer lighting, shadows, PBR and transparency; selected saved LightmapGI/probe and Forward+ VoxelGI fixtures. | Keep bake files and import settings with the scene. Larger GI layouts and arbitrary combinations need their own review. |
| Exposure and borders | Fixed authored exposure, including animation; optional 0–25% capture borders. | Scene mode preserves native per-face metering. Shared automatic spherical exposure is outside 1.0. Borders reduce glow cuts but do not remove all projection-dependent halo differences. |
| Characters | Keyed skinning, the documented imported GLB, bone-mounted cameras, and the bounded head-look/nested-skeleton fixture. | General stateful IK, retargeting and other import pipelines are outside the established evidence. |
| Particles and smoke | Documented CPU/GPU processing, warmup, world/local motion and the point-facing smoke material. Native GPU trails on Forward+/Mobile. | Use at least two GPU warmup frames; warmup is not simulation pre-roll. Native GPU trails are unsupported in Compatibility. Arbitrary billboard/screen-space materials need visual review. |
| Temporal effects | Selected Forward+ TAA/FSR1/FSR2 and persistent camera/world compositor fixtures on 4.7.2. | History must be owned per view. The Mobile compositor fixture requires authored 4× MSAA and a writable intermediate texture; arbitrary compositors are not certified. |
| Audio and playback | Scene audio or an attached soundtrack, stereo export, still/spherical playback, seeking and mute. | Playback is a generated copy limited to 2K/30 FPS. Review the delivered MP4 for final resolution and sound; see [playback](PLAYBACK.md). |
| Recovery | Reopen saved jobs, reconnect to a live coordinator, cancel, and re-encode complete retained PNG/WAV captures. | Partial captures restart from the beginning; re-encoding preserves original captured pixels. See [recovery](RECOVERY.md). |

Preserving an effect does not guarantee identical appearance across cube edges.
Glow, reflections, fog, depth of field, screen-space effects and temporal
histories can remain view-dependent. Inspect moving content at edges, poles and
camera cuts using the intended settings. [Renderers](RENDERERS.md) explains the
known limits and [authoring](AUTHORING.md) explains the tested scene setups.

## Production envelope

Four one-minute 4K/8K Forward+/Mobile workloads passed on the Windows reference
machine with 32 GiB RAM and 8 GiB VRAM. Forward+ 8K used disabled MSAA; the other
three profiles used 4× MSAA. These are measured profiles, not minimum hardware
requirements or a guarantee for every scene or duration. Longer jobs, heavier
effects, larger borders and other hardware can change memory and storage needs.

Run a short sample to estimate time and retained storage. A short sample does
not establish peak RAM for a long export. Keep working disk headroom and review
the [storage guidance](STORAGE.md). The source repository's
`docs/production-performance.md` records the measurements and exact settings.

## Evidence and acceptance

The source repository's `docs/validation.md` maps each result to its exact
package and commit. RC2 passed all five Windows package lanes and native editor
integration. The owner reported no errors and authorized 1.0 preparation; the
1.0 artifact receives its own recorded package acceptance.

Linux software-Mobile history failed again on RC2 despite intervening passing
runs. Its opening five frames exceed the unchanged face-comparison limit; the
cause remains unresolved. The separate exact-RC2 Windows Mobile temporal review
passes. Linux/Mac hardware testing is required before promoting those platforms
to supported, and does not block the Windows launch. YouTube and other external
services require separate review after upload; local validation does not certify
their processing or playback. Publication remains on hold.
