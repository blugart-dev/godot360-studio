# Godot360 Studio

**Turn your Godot 3D scene into a 360° video, from the editor.**
Choose a camera, test a second, and export an MP4 with sound that viewers can look
around in. Make animated worlds, immersive music films and camera walkthroughs.

**[Download 1.0.0](https://github.com/blugart-dev/godot360-studio/releases/tag/v1.0.0)**
· **[Your first export](addons/godot360/QUICKSTART.md)**
· **[Watch the 360° films on YouTube](https://www.youtube.com/playlist?list=PLUjBgihWYNpQ)**
· [Documentation](docs/README.md)

[![Watch THRESHOLD in 360° on YouTube: an underwater cathedral, glass desert, floating gardens and celestial machine.](docs/media/threshold-tour.gif)](https://www.youtube.com/watch?v=zntHEAhrnWQ)

**[THRESHOLD — watch the full 360° film with sound ↗](https://www.youtube.com/watch?v=zntHEAhrnWQ)**
· 60 seconds · rendered at 8K · original score.
The GIF is a silent, flat excerpt. On YouTube, drag to look around on desktop or
swipe in the mobile app, and choose the highest available playback quality.
[Flat preview](docs/media/threshold-tour.mp4) · [Still gallery](docs/showcase.md#four-worlds-one-film)

## From your scene to a video people can explore

**Godot scene + Camera3D → Test 1 second → Render 360 video → Look around and listen**

![Godot360 Studio: the current recipe on the left and a completed spherical export on the right.](addons/godot360/media/studio.png)

| What you can do | How it helps |
| --- | --- |
| Export mono 360° at **2K, 4K or 8K** | Choose a quick draft or a detailed delivery, with 24, 25, 30, 50 and 60 FPS presets. |
| Capture scene audio, attach music, or mix both | Set timing and levels alongside the video recipe. |
| **Test 1 second** before a full render | Inspect a real sample and get measured time/storage estimates. |
| Review a complete clip inside Godot | Drag to look around, play, pause, seek and listen. |
| Reopen exports and re-encode retained frames | Recover saved work or change compression/audio without rendering again. |
| Produce a verified delivery MP4 | Encoding, spherical metadata and technical checks run as part of the export. |

You author the camera movement and timeline; each viewer chooses where to look.
The editor playback copy is limited to **2K / 30 FPS**. The delivery keeps your
chosen resolution. [See the workflow](docs/showcase.md#the-workflow-inside-godot).

[Browse every panel and workflow state](#screenshot-tour)
· [Four example films](#watch-the-films-then-make-them-your-own)
· [Rendering feature gallery](#rendering-feature-gallery)

## Try it in your project

Use **Godot 4.7.2 Standard**, **FFmpeg** and **FFprobe** as the recommended setup.
Windows is supported; Linux/macOS are experimental. Keep your project's renderer.
[Platform setup](addons/godot360/PLATFORMS.md) covers the tools; the addon needs no
Python, .NET runtime, compiler or Godot export templates.

1. Download the **[addon ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0.zip)**
   and copy its `addons/godot360` folder beside your `project.godot`.
2. Enable **Godot360 Studio** under **Project → Project Settings → Plugins**,
   then open the **Godot360** bottom panel.
3. In **Tools → Tool setup**, choose **Find missing tools**, or select FFmpeg and
   FFprobe. In **Current recipe**, select your saved scene, camera and output folder.
4. Choose quality, duration and audio. Click **Check setup**, then **Test 1 second**.
   Inspect the sample and its estimates.
5. Click **Render 360 video**. Use **Play video** to review it and **Open folder**
   to find the verified `video-360.mp4`.

**[Step-by-step quick start](addons/godot360/QUICKSTART.md)**
· [Upgrading an existing installation](addons/godot360/MIGRATION.md)
· [Common questions](docs/faq.md)

## Screenshot tour

**Refreshed 2026-09-14 against the current 1.0.0 source.** Expand a section to
see the actual controls. These are unmodified native Godot captures on Windows,
Godot 4.7.2 / Forward+ Vulkan. The editor view includes Godot's dark theme;
standalone panel views use its default control theme. All **44 panel checks**
and **52 editor checks** passed. [Capture sources and regeneration](docs/media/README.md#refresh-the-panel-screenshots).

<details>
<summary><strong>Editor, setup, scene selection and a first export</strong></summary>

**Inside the editor.** The bottom panel reviews a completed four-second 4K export
of an ordinary authored scene. **Use current scene** is available here.

![Godot editor with the Godot360 bottom panel and a verified authored-scene export.](docs/media/ui-native-editor.png)

**Start with a saved scene.** The empty view keeps delivery and playback actions
unavailable until a real export exists.

![Empty panel with scene selection, recipe settings and no opened export.](docs/media/ui-empty-1100.png)

**Check the tools.** Tool setup shows the selected FFmpeg/FFprobe versions,
playback capabilities and current recipe checks.

![Tools tab with executable selection, discovery and setup results.](docs/media/ui-tools-1100.png)

**Choose the recipe.** Scene, camera, resolution, duration, FPS, audio source and
destination sit beside the preview. Calibration is included with the addon.

![Ready calibration recipe with Draft, Production and Detail presets.](docs/media/ui-ready-1100.png)

**Test 1 second.** Progress and cancellation appear while the real sample renders.

![Active sample export with progress and the cancel action.](docs/media/ui-running-1100.png)

**Review the result.** The opened one-second sample keeps its own metadata when
the next editable recipe is changed to eight seconds. Time and storage estimates
describe that next recipe.

![Completed one-second calibration sample beside the next eight-second recipe.](docs/media/ui-completed-1440.png)

</details>

<details>
<summary><strong>Sound, capture quality, video playback and export details</strong></summary>

**Audio timing and levels.** Choose scene sound, an attached soundtrack or both;
adjust trimming, offsets and levels. This controls view attaches the sample's
recorded WAV to demonstrate the mixing fields. [Audio guide](addons/godot360/AUDIO.md).

![Expanded audio controls with scene and soundtrack mixing, trim, offsets and levels.](docs/media/ui-audio-1440.png)

**Advanced capture and encoding.** Set manual cameras, output/cube detail,
borders, exposure, renderer, graphics driver, frame storage and H.264 compression.
The support note follows the selected renderer/driver.

![Expanded capture and encoding controls with the Windows support note.](docs/media/ui-encoding-1440.png)

**Video review.** Play, pause, seek, mute and drag to look around. **Show still**
returns to the opening frame. The playback copy is capped at 2K / 30 FPS;
**Open delivery MP4** opens the exported resolution. [Playback guide](addons/godot360/PLAYBACK.md).

![Native playback of the sample with its video source label and timeline.](docs/media/ui-playback-1440.png)

**Export details.** A separate window identifies the saved job, scene, camera,
status and recovery guidance; scroll for capture settings and scene notes.

![Export details dialog showing the actual sample metadata and completed status.](docs/media/ui-export-details.png)

</details>

<details>
<summary><strong>Library, recipes, help, cancellation and recovery</strong></summary>

**Library.** Reopen recent exports, load/save recipes, try Calibration or Motion
lab, re-encode retained captures and save diagnostics. **Forget** removes a history
entry while its files stay on disk. [Recovery](addons/godot360/RECOVERY.md) · [Storage](addons/godot360/STORAGE.md).

![Library with recent exports, both example recipes, saved jobs, re-encoding and diagnostics.](docs/media/ui-library-1440.png)

**Help inside Godot.** Quick start includes four selectable topics, available offline.

| First export | Tool installation |
| --- | --- |
| ![Native help for the first export.](docs/media/ui-help-start.png) | ![Native help for installing and checking tools.](docs/media/ui-help-setup.png) |
| **Quality and support** | **Files and recovery** |
| ![Native help for resolution, renderer support and scene testing.](docs/media/ui-help-quality.png) | ![Native help for files, storage and recovery.](docs/media/ui-help-files.png) |

**Cancel an export.** The request stays visible while the worker stops. The
cancelled job retains its files for inspection.

![Cancellation request while the native capture worker is stopping.](docs/media/ui-cancelling-1100.png)

![Cancelled export with retained-job status.](docs/media/ui-cancelled-1100.png)

**Playback recovery.** This deliberately triggered error demonstrates retry,
tool-setup and log actions while the verified delivery remains available.

![Controlled playback-copy error with retry and log actions.](docs/media/ui-playback-failed-1100.png)

**Export failure.** This deliberately failed saved job demonstrates the capture
error message and unavailable delivery actions. Both error images are controlled
presentation states; the normal sample passed delivery verification.

![Controlled failed-export state with guidance to reconnect the output drive.](docs/media/ui-export-failed-1100.png)

</details>

<details>
<summary><strong>Compact panel and 125% window scaling</strong></summary>

**1100×600 panel.** Current recipe and opened-export metadata remain separate.

![Completed sample in the compact 1100 by 600 panel.](docs/media/ui-completed-1100.png)

**125% window scale.** This checks the standalone panel's layout at this scale;
the native editor screenshot above shows its actual dock layout.

![Completed panel at 125 percent window scale.](docs/media/ui-scaled-125-percent.png)

</details>

## Watch the films, then make them your own

Every example includes its Godot scene and export recipe. Get the
**[source and examples ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0-source.zip)**
or clone this repository and open `project.godot`. The addon is already enabled.

| THRESHOLD · four worlds | AFTERGLOW · a disco ritual |
| --- | --- |
| [![Watch THRESHOLD in 360° on YouTube.](docs/media/threshold-worlds.jpg)](https://www.youtube.com/watch?v=zntHEAhrnWQ) | [![Watch AFTERGLOW in 360° on YouTube.](docs/media/afterglow.jpg)](https://www.youtube.com/watch?v=TK2PuQ3n_XU) |
| **[Watch in 360° ↗](https://www.youtube.com/watch?v=zntHEAhrnWQ)** · 60 s · 8K source · original score. [Open, edit and export](docs/threshold.md). | **[Watch in 360° ↗](https://www.youtube.com/watch?v=TK2PuQ3n_XU)** · 60 s · 4K source · original disco-funk. [Scene, recipe and music credits](docs/afterglow.md). |
| **LUMEN · an orbital observatory** | **UMBRAL · an immersive installation** |
| [![Watch LUMEN in 360° on YouTube.](docs/media/lumen.jpg)](https://www.youtube.com/watch?v=Xy5PmSpqY7s) | [![Watch UMBRAL in 360° on YouTube.](docs/media/umbral.jpg)](https://www.youtube.com/watch?v=zWUyKH0Q31I) |
| **[Watch in 360° ↗](https://www.youtube.com/watch?v=Xy5PmSpqY7s)** · 24 s · 4K source · original score. [Scene, effects and recipe](docs/lumen.md). | **[Watch in 360° ↗](https://www.youtube.com/watch?v=zWUyKH0Q31I)** · 12 s · silent. [Play the interactive scene or export its film](docs/umbral.md). |

[Watch the complete playlist](https://www.youtube.com/playlist?list=PLUjBgihWYNpQ)
· [Visual tour and local previews](docs/showcase.md)
· [Example scenes and recipes](docs/README.md#explore-the-examples)

For a small first test, open **Library → Recipes and examples → Calibration defaults**
in the panel. **Motion lab** provides an editable camera path and animation timeline.

## Rendering feature gallery

The films above show finished scenes. These comparison sheets show the smaller
fixtures used to inspect capture behavior. Each guide includes the full image
set, reproduction commands and tested renderer scope. Some rows deliberately
disable or break an effect to check that the reviewer detects it.

<details>
<summary><strong>Lighting, particles, smoke, trails, animated characters and temporal effects</strong></summary>

| Feature and complete comparison | Example capture |
| --- | --- |
| [Capture borders](docs/capture-borders.md): moving effects near cube edges | ![Capture-border comparison with the moving-emitter fixture.](docs/media/capture-borders-forward.jpg) |
| [Exposure consistency](docs/exposure-consistency.md): scene exposure and fixed authored exposure | ![Scene and fixed authored exposure comparison.](docs/media/exposure-consistency.jpg) |
| [Combined appearance](docs/combined-appearance.md): moving lights, materials and borders | ![Combined lighting and material comparison.](docs/media/combined-appearance-forward.jpg) |
| [CPU/GPU particles](docs/particle-capture.md): motion and opening-frame bounds | ![CPU, GPU and analytic particle references.](docs/media/particle-capture.jpg) |
| [Smoke](docs/smoke-capture.md): spherical-facing transparent billboards | ![GPU and CPU smoke compared with the analytic reference.](docs/media/smoke-capture.jpg) |
| [Particle trails](docs/trail-capture.md): tubes and ribbons | ![Tube and ribbon trails beside native perspective references.](docs/media/trail-capture.jpg) |
| [Skeletal capture](docs/skeletal-capture.md): animated camera and skin timing | ![Skeletal camera and CPU skin timing reference.](docs/media/skeletal-camera.jpg) |
| [Imported characters](docs/imported-characters.md): native glTF animation and textures | ![Textured CesiumMan character and independent skin references.](docs/media/imported-character-textured.jpg) |
| [Skeleton modifiers](docs/modifier-capture.md): head look and nested skeleton mounts | ![Head-look modifier, nested skeleton and delayed controls.](docs/media/modifier-capture.jpg) |
| [Saved LightmapGI](docs/lightmap-capture.md): baked maps and dynamic probes | ![Saved-lightmap and dynamic-probe comparison.](docs/media/lightmap-forward.jpg) |
| [Temporal rendering](docs/temporal-capture.md): TAA, FSR, compositor history and VoxelGI | ![Temporal effects with independent and intentionally corrupted history controls.](docs/media/temporal-forward.jpg) |
| [Combined effects](docs/combined-effects.md): GI, lit transparency, history and camera cuts | ![Combined-effects comparison with enabled, disabled and incorrect controls.](docs/media/combined-forward.jpg) |

The imported-character and modifier images derive from **CesiumMan, © 2017
Cesium, CC BY 4.0**. [Attribution and upstream mark notice](tests/fixtures/cesium_man/README.md).
These retained, dated comparison captures are not a new renderer-matrix run.
[Media provenance](docs/media/README.md) · [Validation record](docs/validation.md).

</details>

## Where the project stands

**1.0.0 — Windows supported; Linux/macOS experimental.**

| Platform | Tested scope |
| --- | --- |
| Windows | Compatibility exports/review on Godot 4.5.1, 4.6.3 and 4.7.2; Forward+ and Mobile on 4.7.2 Vulkan. Additional Windows D3D12 visual evidence is documented separately. |
| Linux · experimental | Export/review and software-rendering evidence. A recurring software-Mobile opening-history mismatch remains unresolved; native GPU acceptance is open. |
| macOS · experimental | Apple Silicon headless CI. Graphical export and Mac GPU acceptance are open. |

The release runtime passed **6,070 checks across five Windows package lanes**
and **52 native editor checks**. See the [support contract](addons/godot360/SUPPORT.md),
[release notes](docs/release-1.0.md) and [exact validation evidence](docs/validation.md)
for the tested archives, rendering features and remaining work.

Scope is **mono 360°, SDR BT.709 and stereo sound**. Six-face capture can show
seams with glow, auto exposure and other screen-space effects; inspect a sample
before a long export. Stereoscopic 3D, ambisonics and automatic uploads are outside
the current scope. [Renderer limits](addons/godot360/RENDERERS.md) · [Roadmap](docs/roadmap.md)

## Download the dependencies

| Platform | Godot | FFmpeg + FFprobe | Setup |
| --- | --- | --- | --- |
| Windows x86_64 | [4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/) | [gyan.dev essentials ZIP](https://www.gyan.dev/ffmpeg/builds/); both tools are in `bin/` | [Windows](addons/godot360/PLATFORMS.md#windows) |
| Linux | [4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/) | Ubuntu/Debian: `sudo apt install ffmpeg` | [Linux](addons/godot360/PLATFORMS.md#linux) |
| macOS | [4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/) | [Homebrew](https://docs.brew.sh/Installation): [`brew install ffmpeg-full`](https://formulae.brew.sh/formula/ffmpeg-full) | [macOS](addons/godot360/PLATFORMS.md#macos) |

Nothing is downloaded by the addon. Tool paths stay local in `.godot360/settings.cfg`.
[VLC](https://www.videolan.org/vlc/) is optional for [full-resolution 360° playback](https://docs.videolan.me/vlc-user/desktop/3.0/en/advanced/player/360_video.html).

## Find the right guide

| I want to… | Read |
| --- | --- |
| Export my first scene or resolve a common question | [Quick start](addons/godot360/QUICKSTART.md) · [FAQ](docs/faq.md) |
| Animate a camera or prepare interactive content | [Authoring](addons/godot360/AUTHORING.md) |
| Add music or adjust synchronization | [Audio](addons/godot360/AUDIO.md) |
| Understand quality, effects or command-line exports | [Addon reference](addons/godot360/README.md) · [Renderer limits](addons/godot360/RENDERERS.md) |
| Play a clip, recover an export or manage disk space | [Playback](addons/godot360/PLAYBACK.md) · [Recovery](addons/godot360/RECOVERY.md) · [Storage](addons/godot360/STORAGE.md) |
| Prepare a YouTube delivery or describe the example films | [Production workflow](docs/youtube-360-production.md) · [Publication kit](docs/youtube-publication.md) |
| Develop, contribute or inspect the evidence | [Contributing](CONTRIBUTING.md) · [Developer verification](docs/testing.md) · [All documentation](docs/README.md) |

## License and feedback

All original project content is [MIT licensed](LICENSE), including the addon,
examples, documentation, artwork and music. Separately sourced materials retain
their [third-party notices](THIRD_PARTY_NOTICES.md), including AFTERGLOW's instrument
samples. Full renders, settings and tool binaries stay local; see
[repository contents](docs/repository.md) and [media sources](docs/media/README.md).

[Report a bug or propose a feature](https://github.com/blugart-dev/godot360-studio/issues/new/choose).
For sensitive reports, follow the [security policy](SECURITY.md).
Code, interface text and documentation are in English.
