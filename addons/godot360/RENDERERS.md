# Renderers and scene appearance

New captures use the **saved project's renderer and graphics driver**. Advanced
capture offers explicit Forward+, Mobile, Compatibility and driver overrides,
stored in recipes. These affect only the worker, not Project Settings. Save the
project and scene first. The headless coordinator never selects its own dummy
renderer for capture. Old recipes without these fields also use Project; older
addon versions always forced Compatibility, even for Forward+ projects.

`job.json` records requested and resolved selection. `capture-settings.json`
records the actual method, driver, GPU, OS, engine, viewport settings and color
contract; successful `report.json` includes those original capture settings.
If Godot starts a different renderer **or driver**, the worker stops before
capturing frames. Fix the driver or select the intended override and test again.
Missing graphics initialization is diagnosed in `capture.log`. A headless check
cannot establish rendering support.

## Measured combinations — 2026-09-07

| Machine / engine | Renderer and backend | Evidence |
| --- | --- | --- |
| Windows 11, RTX 3060 Ti, Godot 4.7.2 | Forward+ / Vulkan | Twelve appearance cases; additional SDFGI off/on room, auto exposure, HDR-reference comparison and six-second analytic motion/audio export. |
| Same Windows machine / 4.7.2 | Mobile / Vulkan | Eight appearance cases and the same six-second motion/audio review. |
| Same Windows machine / 4.7.2 | Forward+ / D3D12 | Color, lighting/transparency, glow, combined screen effects, TAA and camera compositor exports. |
| Same Windows machine / 4.7.2 | Mobile / D3D12 | Color, lighting/transparency, glow and camera compositor exports. |
| Same Windows machine / 4.7.2 | Compatibility / OpenGL 3 and ANGLE | Full existing calibration/Motion Lab workflow with OpenGL; two appearance exports through ANGLE/D3D11. |
| Ubuntu 26.04, WSLg/X11, llvmpipe, Godot 4.7.2 | Forward+ and Mobile / software Vulkan | Four appearance exports per renderer: color, lighting/transparency, glow and compute compositor. Functional software-rendered evidence, not GPU performance. |

Complete package workflows additionally pass on Windows Forward+/Vulkan with
Godot 4.5.1, 4.6.3 and 4.7.2 (522 checks each), Windows 4.7.2 Mobile/Vulkan and
Compatibility/OpenGL (522 each), and Linux 4.7.2 Forward+/Mobile software Vulkan
(526 each). They cover actual exports, audio, re-encoding, cancellation, recovery,
storage faults and panel controls. The repository validation record identifies
the exact snapshots and reports; these counts do not cover every graphics driver.

The visual lab compares three captured times with an independent native 90°
perspective viewport and reprojects retained face pixels independently. Most SDR
reference pairs were pixel-identical; SDFGI differed by less than 0.004/255 mean
absolute channel value. HDR 2D references differed by less than 0.014/255 on
average in the lit/glow comparisons. Exported effects also differ measurably from
disabled baselines, including the darker GI room. These tolerances establish
preservation in these fixtures, not identical output between different renderers.

The motion reviewer checks all 180 source and 180 decoded frames per renderer;
it covers cube edges, both poles, rear seam, exact flash frames and audio onset
within 0.71 ms. This is six seconds at 2K, not production endurance or headset
comfort certification. D3D12/ANGLE do not have the same long workflow evidence
as Vulkan. Windows Mobile on 4.5.1/4.6.3 and Linux 4.5.1/4.6.3 remain untested.

## SDR color pipeline

Each face uses the scene's World3D, environment, lighting and camera attributes.
Godot applies exposure and the authored tone mapper to the face's 3D HDR buffer.
The six face targets explicitly use `use_hdr_2d=false`, producing tone-mapped SDR
sRGB textures. The panorama assembler is also SDR 2D. Its texture samplers do not
use `source_color`: these pixels must not be decoded or tone-mapped a second time.
The assembly does not inherit the project's HDR 2D setting; scene CanvasLayers
are hidden. This does not disable HDR lighting, glow or the scene's tone mapper.

Both PNG modes retain RGB8/RGBA8 SDR pixels. FFmpeg performs the existing sRGB
transfer conversion to limited-range BT.709 H.264/yuv420p; it is not just a tag
change. No HDR/EXR/PQ/HLG delivery is offered. Clipped highlights from the authored
tone mapper cannot be recovered by increasing export quality. A scene that changes
the assembly target to HDR fails explicitly, including in Compact PNG mode.

## What the camera rig preserves

All six views share one World3D and simulation time. Camera position, rotation,
horizontal/vertical offset, clipping, cull mask, environment, attributes and camera
compositor follow the selected source each frame. WorldEnvironment compositors
remain active through the shared world. The face viewports inherit MSAA, screen
AA, TAA, debanding, 3D scaling/FSR, mip bias, LOD, occlusion and positional shadow
atlas settings at capture setup. Project-wide shader and rendering settings remain
under Godot's control. Save runtime-specific viewport changes before the rig is
built, using `begin_360_capture` if necessary.

Projection becomes six square perspective views with a retained 90° core: source FOV, orthographic
projection and frustum lens shift cannot describe a sphere. Physical camera
attributes retain exposure/DOF while their lens FOV is replaced. The output is
opaque. A panorama cannot preserve the composition of a single perspective frame.

## Effects that need a full-motion test

| Effect | Capture behavior and practical limitation |
| --- | --- |
| Lighting, shadow maps, PBR and alpha transparency | Use the selected renderer's native implementation. Specular reflections, transparency sorting and directional shadow cascades can depend on face direction. |
| Glow | Preserved where the renderer supports it; a face cannot bloom from an emitter just outside its view. Bright objects crossing cube edges can reveal a cut in the halo. |
| Depth/volumetric fog | Camera depth and temporal fog history differ per face. Inspect horizon, cube edges and moving lights. Volumetric fog requires Forward+. |
| SDFGI / other GI | Shared scene data is retained, but convergence and visibility are renderer-dependent. Give SDFGI time to settle. VoxelGI and baked LightmapGI require separate validation. |
| SSAO, SSIL, SSR | Forward+ features. Each face has a separate depth/color screen; missing information outside a face can produce edges and incomplete reflections. The rig cannot reconstruct that information. |
| TAA / FSR2 | Each face accumulates independent history. Moving objects can ghost and disocclusions restart history at boundaries. Increase warmup and compare an MSAA-only test if artifacts are objectionable. |
| Auto exposure | Forward+ meters each view separately, which can create brightness seams. Advanced offers explicit **Fixed (authored)** exposure; Scene remains the default. Mobile/Compatibility do not support native auto exposure. |
| Depth of field | Uses each face camera's depth; blur can change across an edge. Review before retaining it. |
| Custom compositor | The same effect resource can be called for multiple viewports. Store persistent history per view/render buffer, handle square targets and required attachments, and avoid assuming one call per scene frame. A stateless effect is much easier to verify. |
| Billboards and screen textures | Face-facing geometry and screen/depth shaders can change at cube edges. Prefer world-space geometry when practical. |

Warnings in `scene-checks.json` are heuristic. They do not automatically find every
material or custom shader dependency. Unsupported effects are not recreated when
you explicitly choose a renderer that lacks them. Follow the
[Godot renderer feature matrix](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
and [compositor contract](https://docs.godotengine.org/en/stable/tutorials/rendering/compositor.html).

Actual frame inspection found **hard glow-halo cuts at face boundaries** and
**large exposure differences between faces with auto exposure**. The optional
capture border below supplies surrounding pixels for glow. The fixed exposure
option below removes independent metering; shared adaptive spherical exposure
still requires a new metering strategy and remains open.
The [skeletal capture fixture](AUTHORING.md#skeletal-animation-and-viewpoint-cuts)
adds a keyed weighted mesh and a bone-attached camera cut. Camera synchronization
now waits for the queued attachment update, avoiding a one-frame viewpoint delay.
This does not establish arbitrary character, particle or temporal-effect support.
FSR output, VoxelGI, baked LightmapGI and stateful custom compositor histories
remain untested.

## Capture exposure

**Advanced → Capture exposure → Fixed (authored)** disables automatic exposure
on all six capture cameras. It uses the selected camera's authored attributes,
falling back to WorldEnvironment attributes. Exposure multiplier, sensitivity,
physical-camera settings and depth of field continue to follow the source every
frame, including animation and resource replacements. Camera attributes override
world attributes, as in Godot. The worker owns a copy and never edits the originals.

Use a short test to choose the authored exposure before a full render. **Fixed**
means no automatic metering; an authored exposure curve can still change brightness.
This does **not** freeze the editor view's auto-metered brightness. Switching to it
can make a scene brighter or darker, and a lighting cut will stay visible unless
you author an exposure change. Tune `CameraAttributes.exposure_multiplier` or
physical exposure in the scene; the original tone mapper and SDR pipeline remain.

**Scene (default)** preserves the previous behavior, including independent
Forward+ metering. Legacy recipes/settings/jobs use Scene. Mobile and Compatibility
already omit native auto exposure; Fixed is accepted there with the same authored
exposure behavior. See Godot's [CameraAttributes contract](https://docs.godotengine.org/en/stable/classes/class_cameraattributes.html).
Sharing attributes does not share metering: Godot's
[renderer keeps luminance history per render buffer](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/renderer_scene_render_rd.cpp).

`capture_exposure_mode` is `scene` or `fixed` in recipes, settings and jobs.
Capture settings and delivery reports record the original policy. A changed mode
invalidates the sample estimate. Re-encoding preserves the captured policy and
pixels; a conflicting explicit request is rejected. Legacy capture evidence is
left as recorded, without retroactively adding a policy claim.

The mode adds no viewports, render passes or image readbacks. A small CPU copy of
changed attribute values runs once per frame, and `capture-timings.json` records
total `exposure_sync_usec`. Fixed removes native auto-exposure work in Forward+;
short-test wall times are not a production speedup guarantee. Borders retain their
separate pixel cost. This does not repair other view-dependent lighting/effects,
clipped highlights, or implement automatic spherical light adaptation.

`tests/exposure_review.py` compares 90 frames of uneven lighting, moving geometry
and camera, a lighting cut, an authored exposure curve and an attribute replacement.
Its oracle is the same scene authored with automatic metering disabled. All source
frames are compared, all delivered video frames are decoded, and a re-encode checks
source hashes and capture evidence. Run in a fresh folder:

```shell
python tests/exposure_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/fresh-review --method forward_plus --driver vulkan
```

Repeat with `--world-attributes`, `--physical`, `--border 12.5`, or the appropriate
`--method mobile` / `--method gl_compatibility --driver opengl3`. Requires NumPy,
Pillow and a working graphical backend. Dated evidence and illustrated comparisons
are in the repository's `docs/validation.md` and `docs/exposure-consistency.md`.

## Capture borders

**Advanced → Capture border per edge (%)** adds context outside each face before
Godot applies glow and other effects. The assembler smoothly blends overlapping
views at face edges and corners. **0%** preserves the original capture path;
**12.5%** is a useful starting point for testing glow cuts. The allowed range is
0–25% per edge. This is an
explicit recipe setting; the addon does not silently change an existing scene.

For a core of `N` pixels and a border of `P` percent, each edge gets
`ceil(N * P / 100)` extra pixels. The target grows symmetrically and its FOV expands
to preserve the core's sampling density. At 12.5%, a 2048 core uses a 2560 target
and a 3072 core uses 3840; both render about **56% more face pixels**. GPU memory
and timing costs depend on the scene and effects. The panorama dimensions and
retained frame format do not change. A new measured sample is required.

Border capture can reduce an abrupt missing glow halo from a bright object just
outside a face. Residual differences remain because glow shape, reflections,
fog and other effects depend on projection and screen resolution. It does not
share auto-exposure metering, reconstruct an arbitrary screen shader, or make
stateful compositor histories interchangeable. Inspect motion and all directions.

Recipes, local settings and `job.json` store `capture_border_percent`.
`capture-settings.json` and the delivery report retain the percent, actual border
pixels, face target dimensions and FOV. Re-encoding keeps the captured border and
pixels; requesting a different border requires a new capture. Legacy recipes and
jobs with no border field use zero.

The repository's `tests/border_review.py` renders an emitter across an equatorial
edge, a three-face corner and a top edge. It compares every frame against a
zero-border render, measures edge discontinuity and checks no-glow geometry.
`tests/motion_review.py` separately checks moving marker positions, poles, rear
seam and audio. Current acceptance results are recorded in `docs/validation.md`.

From the repository or unpacked package, use a fresh output directory:

```shell
python tests/border_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/fresh-review --method forward_plus --driver vulkan
```

Repeat with `--method mobile`. The review requires NumPy, Pillow, a working native
GPU backend and enough disk space for four three-second 2K frame sequences.

## Estimates, retained captures and troubleshooting

A new sample is required after changing renderer/driver, engine, OS or saved
project configuration. Old Compatibility-era estimates are stale. Referenced
asset contents and GPU driver updates are not fingerprinted; re-test after those
changes too. Warmup defaults to two frames and is configurable in a recipe's
Inspector; complex temporal effects often need more (up to ten currently).

Re-encoding uses the original SDR frames and original renderer evidence, even on
another machine or without the scene. Renderer changes require a new capture.
An explicit conflicting renderer in a CLI re-encode request is rejected. Legacy
captures without renderer evidence remain usable but their renderer is unknown;
the current machine's renderer is never substituted into their report.

| Symptom | Action |
| --- | --- |
| Renderer fallback | Read requested/actual fields and `capture.log`; update/install native graphics drivers, or choose the intended method and backend explicitly. Run a new test. |
| Missing Forward+ effects | Check actual method; use Forward+ for SSAO/SSIL/SSR/SDFGI/volumetric fog. |
| Different exposure or washed-out colors | Check camera/environment overrides and auto exposure; compare the retained PNG to a normal view with the same renderer and tone mapper. PNGs are sRGB, MP4 is BT.709. |
| GPU memory exhaustion | Reduce face size, lower MSAA or reduce expensive effects, then re-test. Six views and temporal histories require more VRAM than one camera. Disk estimates do not estimate VRAM. |
| Scene script failure | Fix the `SCRIPT ERROR` in `capture.log` and start a new render. A complete PNG count alone does not prove authored scene behavior ran. |
| Missing or uneven particle motion at the opening | Test 8–10 warmup frames and inspect particle Fixed FPS/interpolation. Warmup does not pre-roll particle history. See [particle authoring](AUTHORING.md#particle-simulation-and-processing-modes). |

See the repository's `docs/validation.md` for dated measured combinations and
local evidence. Native macOS, Linux hardware-GPU rendering and combinations not
listed there remain untested. Software Vulkan evidence is not a performance claim.
