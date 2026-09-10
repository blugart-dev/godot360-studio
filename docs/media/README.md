# Documentation media

## AFTERGLOW

The complete documentation tour is 1280×720 with the original encoded stereo
audio, approximately 20 MB. Its 900p local preview and 4K spherical master stay
in the render folder. `tools/build_afterglow_media.py` applies the smaller
documentation encoding and updates the provenance hash when regenerating it.

`afterglow.jpg`, `afterglow-suspended.jpg`, `afterglow-rear.jpg`,
`afterglow-crown.jpg`, `afterglow-panorama.jpg` and `afterglow-tour.mp4` come from
the one-minute Forward+ 4K delivery in `renders/afterglow-clearance-4k/`.
The documentation tour is a 1280×720 fixed forward view with the original disco-funk score.
The 3K browser sphere and full master remain local. `tools/build_afterglow_media.py`
regenerates the previews and [records their provenance](afterglow-provenance.json).
See [the film guide](../afterglow.md) for score credits, source and playback.

## LUMEN

`lumen.jpg`, `lumen-orbits.jpg`, `lumen-rear.jpg`, `lumen-panorama.jpg` and
`lumen-tour.mp4` come from the verified 24-second Forward+ 4K delivery under
`renders/lumen-4k-final/`. The tour is a 1080p edit of four viewing directions
with the original soundtrack. `tools/build_lumen_media.py` regenerates these
files and records exact hashes and view angles in the render folder's
`media-provenance.json`; the accepted copy is [lumen-provenance.json](lumen-provenance.json).
The 2K browser sphere and full master remain local.
See [the film guide](../lumen.md) for source files and commands.

## Repository previews

These curated previews are part of the documentation. Full render jobs, source
frames and delivery masters stay in the ignored `renders/` directory. No remote
video service is needed to read the illustrated guides.

## What each asset shows

| Asset | Content | Approximate size |
| --- | --- | ---: |
| `threshold-tour.gif` | Two seconds per world, starting at 8, 20, 35 and 49 s; silent; 720×406 / 10 FPS | 3.7 MB |
| `threshold-tour.mp4` | Complete 60-second film in a fixed forward view; original stereo score; 960×540 / 30 FPS | 6.2 MB |
| `threshold-worlds.jpg` | Four stills from those same timestamps, arranged in film order | 119 KB |
| `tidal-archive.jpg`, `glass-desert.jpg`, `sky-garden.jpg`, `star-engine.jpg` | Individual forward views at 8, 20, 35 and 49 s | 41–87 KB each |
| `sky-garden-panorama.jpg` | The entire sphere at 35 s, flattened to 1280×640 | 70 KB |
| `umbral.jpg` | A forward view at 3 s from UMBRAL's rendered film | 29 KB |
| `../../addons/godot360/media/studio.png` | Actual current panel, THRESHOLD 8K recipe, native playback paused at 35 s | 567 KB |
| `capture-borders-forward.jpg`, `capture-borders-mobile.jpg` | Unmodified before/after sheets from the moving-emitter capture-border fixture; see [test and regeneration](../capture-borders.md) | Under 40 KB each |
| `exposure-consistency.jpg` | Unmodified Scene / Fixed (authored) comparison sheet from the moving-light exposure fixture; see [test and regeneration](../exposure-consistency.md) | Under 40 KB |
| `exposure-lit.jpg` | Unmodified Scene / Fixed (authored) sheet from the lit-material exposure experiment; see [comparison](../exposure-consistency.md) and [evidence](../validation.md) | Under 50 KB |
| `combined-appearance-forward.jpg`, `combined-appearance-mobile.jpg` | Unmodified Scene / Fixed / Fixed with borders sheets from the combined light/material lab; see [test and regeneration](../combined-appearance.md) | Under 80 KB each |
| `skeletal-camera.jpg` | Unmodified baseline/fixed camera and CPU skin reference sheet at frames 15/30/31; see [test and regeneration](../skeletal-capture.md) | Under 40 KB |

The film previews are **ordinary perspective views**, not interactive 360 players.
They have no spherical metadata. This distinction is repeated beside the media
in the guides. The original THRESHOLD delivery is 7680×3840, 30 FPS, 60 seconds;
the original UMBRAL source for this still is the `umbral-quality-8k` render.
All scene visuals and the THRESHOLD score are original project assets.

Use Markdown images for stills/GIFs and an explicit watch/download link for the
MP4. Repository Markdown renderers do not all embed a raw `<video>` element.
The visual tour offers stills for readers who prefer to avoid a looping GIF.
Do not add personal paths, private player links or full render-job folders to media.

## Regenerate the film previews

Requires Python's standard library and FFmpeg with `v360` and `libx264`.
From the repository root, after creating the original films:

```powershell
python tools/build_docs_media.py --ffmpeg PATH_TO_FFMPEG
```

Defaults read `renders/threshold-8k/encoded.mp4` and
`renders/umbral-quality-8k/encoded.mp4`. Override `--threshold`, `--umbral` or
`--output` to use other paths. The command overwrites the named documentation
previews, leaving its source videos unchanged. It records source SHA-256 hashes,
timestamps, projection settings and output hashes in [provenance.json](provenance.json).
It reads the untagged encoded source so spherical side data does not leak into
the flat previews. It resizes and projects the existing frames, preserving their
scene content. See [THRESHOLD's guide](../threshold.md) to reproduce that source film.

## Refresh the panel screenshot

`tools/capture_docs_panel.gd` renders the real panel in a **disposable project**.
It opens a successfully verified THRESHOLD export, loads its recipe, prepares or
reuses the normal playback cache and seeks to 35 seconds. It refuses to run in
a project whose name is not `Godot360 documentation capture`.

1. Create a fresh folder under `.godot360/` and copy `addons`, `assets`, `scenes`,
   `scripts`, `export_profiles` and `tools` into it. Do not copy user settings.
2. Create the following `project.godot` in that disposable folder:

   ```ini
   config_version=5
   [application]
   config/name="Godot360 documentation capture"
   [rendering]
   renderer/rendering_method="gl_compatibility"
   environment/defaults/default_clear_color=Color(0.12, 0.13, 0.16, 1)
   ```

3. Import that project, then capture with a graphical Godot 4.7.2 session. Replace
   the uppercase placeholders with absolute paths; quote paths containing spaces:

   ```powershell
   & GODOT --headless --editor --path DISPOSABLE_PROJECT --import --quit
   & GODOT --path DISPOSABLE_PROJECT --audio-driver Dummy --script res://tools/capture_docs_panel.gd -- --source=THRESHOLD_EXPORT_FOLDER --ffmpeg=FFMPEG --ffprobe=FFPROBE --output=SCREENSHOT_PNG
   ```

4. Inspect the result, then use it as `addons/godot360/media/studio.png`. The first
   playback preparation can take several minutes. Playback codecs and limits are
   documented in [Playback](../../addons/godot360/PLAYBACK.md).

This is a standalone rendering of the panel, with the normal Godot control theme;
the editor chrome is outside the image. **Use current scene** is disabled because
there is no editor scene callback in this capture. The example recipe and source
film are genuine. Source settings, recipe and master hashes were checked unchanged
for the 2026-09-08 capture; local evidence is under `.godot360/docs-review/`.

## Before committing refreshed media

`particle-capture.jpg` is the CPU/GPU/analytic comparison from
`tests/particle_review.py`, Godot 4.7.2 Forward+ / Vulkan on Windows, 8-frame
warmup and zero borders. It uses delivered frames 0, 24 and 59 at 45° yaw,
50° horizontal / 38° vertical FOV, with a 320×240 flat view per cell. The accepted
source is `.godot360/particle-review/4.7.2-forward_plus/`; the final reviewer
reproduces the 960×810 contact sheet. See [particle capture](../particle-capture.md).

`particle-startup.jpg` shows the Compatibility automatic CPU bounds fix on the same
Windows engine/GPU. Before: `.godot360/particle-startup/bounds/baseline/`. After and
reference: `.godot360/particle-startup/candidate/compatibility-472/`. It shows frames
0, 1 and 11 with eight warmup frames, the same yaw/FOV and 400×280 cells. The
1200×948 sheet is generated by `.godot360/particle-startup/sheet.py` from actual
retained PNGs; the opening is empty only in the old worker.

Check image legibility at README width, all four GIF excerpts, video duration and
audio, relative Markdown links and the packaged screenshot. Keep the GIF below
4 MB and THRESHOLD's MP4 below 7 MB; all source assets must stay below the
repository's 25 MiB per-file budget. The panel PNG and the licensed CesiumMan GLB test
asset are the binary media included in the development package.
Run the packager's verification and rebuild comparison after changing packaged
guides or their assets. See [developer verification](../testing.md).

`imported-character.jpg` is the unaltered contact sheet from
`.godot360/imported-character/native/forward-472/`: native imported character,
direct-camera oracle, CPU skin oracle, late-skin control and late-camera control.
Windows Godot 4.7.2 / RTX 3060 Ti / Forward+ Vulkan, two warmup frames, zero
borders, 30 FPS; delivered frames 15, 30 and 31. Every cell uses an 85×70-degree
flat view at 320×240; only text/panel layout is added by the reviewer. The original
GLB and these derived views are © 2017 Cesium, CC BY 4.0; see
[attribution and upstream mark notice](../../tests/fixtures/cesium_man/README.md).

`imported-character-textured.jpg` is the unaltered two-row contact sheet from
`.godot360/imported-character/native/textured-60-bake/`, retaining the GLB's
original material/texture. The same Windows engine/GPU uses Forward+ Vulkan,
60 FPS, zero warmup and 12.5% borders, with a matching 60 FPS import bake.
The projection, sample frame numbers and Cesium attribution are the same as above.

`modifier-capture.jpg` is the unaltered six-row contact sheet from
`.godot360/modifier-review/native/nested-472-forward/`, showing the custom head
look, nested skeleton mount and independent camera/skin references. The last
three rows intentionally delay skin, camera and head-look target by one frame.
Windows Godot 4.7.2 / RTX 3060 Ti / Forward+ Vulkan, 30 FPS, two warmup frames,
zero border; frames 15, 30 and 31, with the same 85×70-degree 320×240 views and
Cesium attribution as above. Reproduce it with the command in
[modifier capture](../modifier-capture.md).

`smoke-capture.jpg` is the unaltered contact sheet from
`.godot360/smoke-review/final/mobile/`, with face-aligned control, point-facing
GPU/CPU smoke and analytic mesh reference. Windows / Godot 4.7.2 / RTX 3060 Ti /
Mobile Vulkan, 30 FPS, two warmup frames and 12.5% borders. Frames 0, 30 and 48
use 60×45-degree flat views at 320×240, yaw 45 degrees. The procedural test
material and geometry are generated by repository code; no external art is used.

`trail-capture.jpg` is the unaltered contact sheet from
`.godot360/smoke-review/trails/final/forward/`: tube and cross-ribbon spherical
views beside direct native perspective references at frame 48. Same engine/GPU,
Forward+ Vulkan, 30 FPS, two warmup frames, zero borders, 60-degree 512×512 views.
