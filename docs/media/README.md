# Documentation media

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

Check image legibility at README width, all four GIF excerpts, video duration and
audio, relative Markdown links and the packaged screenshot. Keep the GIF below
4 MB and the MP4 below 7 MB. The PNG is the only binary media included in the addon
package; the repository previews total about 11 MB including that PNG.
Run the packager's verification and rebuild comparison after changing packaged
guides or their assets. See [developer verification](../testing.md).
