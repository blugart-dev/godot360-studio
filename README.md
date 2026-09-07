# Godot360 Studio

**Export your Godot 3D scene as a 360° video.** Select a camera, choose quality
and duration, test a short sample, and render a verified MP4 from the Godot editor.
The addon handles capture, sound, encoding and spherical metadata.

**[Start here: your first 360° export](addons/godot360/QUICKSTART.md)**

## Use it in your project

1. Copy `addons/godot360` into your Godot project and enable **Godot360 Studio**
   under **Project > Project Settings > Plugins**.
2. Open the **Godot360** bottom panel. Select FFmpeg and FFprobe under **Tool setup**
   if they were not found on PATH.
3. Click **Use current scene** and pick a **Camera**. This saves the current named
   scene; new scenes must first be saved in Godot. **Choose scene…** selects another
   saved scene. Runtime-created cameras can use a manual path under Advanced.
4. Choose **Production · 4K**, duration, audio and an output folder. **Check setup**
   shows configuration issues, tool capabilities and saved-scene notes.
5. Click **Test 1 second** to inspect a sample and estimate render time/storage,
   then **Render 360 video**. Use **Open output** for the verified `video-360.mp4`.

The panel previews the first frame as a draggable sphere. Review the full video
in a spherical player. A video preserves the authored sequence; viewers can look
around, while interactive gameplay and gaze events need to be prepared for capture.

The current usability work adds scene/camera discovery, setup checks and grouped
controls to the 0.8 codebase. Historical beta evidence is recorded separately;
this working source has not been published as a new release.

## What it supports

- Mono 360° video, SDR BT.709, and ordinary stereo sound.
- Draft 2K, Production 4K and Detail 8K presets; 24, 25, 30, 50 or 60 FPS.
- Scene audio, an attached soundtrack, or a mix.
- Measured short-test estimates, progress, cancellation and saved-job recovery.
- Re-encoding retained captures to change quality or sound without rendering again.

Initial support targets **Windows and Compatibility**, with recorded checks on
Godot **4.5.1, 4.6.3 and 4.7.2**. FFmpeg and FFprobe are external dependencies.
See [compatibility and limitations](addons/godot360/BETA.md) for the exact evidence.
Stereoscopic 3D, ambisonics and automatic uploads are outside the current scope.

## Try the included examples

Open this repository's `project.godot` in **Godot 4.7.2**; the plugin is enabled.

| Example | How to try it |
| --- | --- |
| Calibration | Panel → Recipes and examples → Calibration defaults. Checks six directions and a tone. |
| Motion lab | Panel → Recipes and examples → Motion lab. An editable animated camera and timeline. |
| UMBRAL | F5 for the interactive installation; load `export_profiles/umbral-film.tres` for its 12-second film. [Scene guide](docs/umbral.md). |
| THRESHOLD | Open `scenes/films/Threshold.tscn` with F6; load `export_profiles/threshold-8k.tres` to export the four-world film. [Film guide](docs/threshold.md). |

Godot360 Studio is the tool. UMBRAL and THRESHOLD are creative examples.

## Find the right guide

| I want to… | Read |
| --- | --- |
| Export my first scene | [Quick start](addons/godot360/QUICKSTART.md) |
| Animate a camera or prepare interactive content | [Authoring](addons/godot360/AUTHORING.md) |
| Add music or adjust synchronization | [Audio](addons/godot360/AUDIO.md) |
| Understand quality, recipes or command-line exports | [Addon reference](addons/godot360/README.md) |
| Recover an export or manage disk space | [Recovery](addons/godot360/RECOVERY.md) · [Storage](addons/godot360/STORAGE.md) |
| Review delivery for YouTube | [Production workflow](docs/youtube-360-production.md) |
| Develop or contribute | [Tests](docs/testing.md) · [Validation record](docs/validation.md) · [Roadmap](docs/roadmap.md) |

The addon is [MIT licensed](addons/godot360/LICENSE). Settings, generated checks,
tool binaries and renders stay local; see [repository contents](docs/repository.md).
Project code, interface text and documentation are in English.
