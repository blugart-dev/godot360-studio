# Godot360 Studio

**Export your Godot 3D scene as a 360° video.** Select a camera, choose quality
and duration, test a short sample, and render a verified MP4 from the Godot editor.
The addon handles capture, sound, encoding and spherical metadata.

**[Start here: your first 360° export](addons/godot360/QUICKSTART.md)**

## Download the dependencies

Use **Godot 4.7.2 Standard** with your project's renderer. Install the
native tools for your operating system, then use the same addon folder everywhere.

| Platform | Godot | FFmpeg + FFprobe | Installation steps |
| --- | --- | --- | --- |
| Windows x86_64 | [Official download](https://godotengine.org/download/archive/4.7.2-stable/) → Windows Standard | [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) → release essentials ZIP; both tools are in `bin/` | [Windows setup](addons/godot360/PLATFORMS.md#windows) |
| Linux | [Official download](https://godotengine.org/download/archive/4.7.2-stable/) → Linux Standard for your CPU | Ubuntu/Debian: `sudo apt install ffmpeg`; other builds via [FFmpeg](https://ffmpeg.org/download.html) | [Linux setup](addons/godot360/PLATFORMS.md#linux) |
| macOS | [Official download](https://godotengine.org/download/archive/4.7.2-stable/) → macOS Universal | [Install Homebrew](https://docs.brew.sh/Installation), then [`brew install ffmpeg-full`](https://formulae.brew.sh/formula/ffmpeg-full); select its tool paths as described in setup | [macOS setup](addons/godot360/PLATFORMS.md#macos) |

**[Platform setup: downloads, installation and troubleshooting](addons/godot360/PLATFORMS.md)**
includes executable permissions, macOS app paths, optional PATH configuration and
the exact support status. Native macOS export validation is still pending.

The addon needs no .NET runtime, compiler, Python or Godot export templates.
[Python setup](docs/testing.md#developer-dependencies) is only for developer/media
review scripts. [VLC](https://www.videolan.org/vlc/) is optional for full 360° playback.

After enabling the addon, open **Godot360 → Tool setup → Find installed tools**.
You can also select **FFmpeg…** and **FFprobe…** by their full paths. FFprobe is
filled in when beside FFmpeg. Selecting files is enough; changing PATH is optional.
Choose an output folder and click **Check setup** before your first test.

Nothing is downloaded by the addon. Tool paths stay local in
`.godot360/settings.cfg`; select them again after moving to another computer.

## Use it in your project

1. Copy this repository's `addons/godot360` folder into the folder containing your
   `project.godot`. The result should be `your-project/addons/godot360/plugin.cfg`.
   Enable **Godot360 Studio**
   under **Project > Project Settings > Plugins**.
2. Open the **Godot360** bottom panel. Select FFmpeg and FFprobe under **Tool setup**
   if they were not found automatically.
3. Click **Use current scene** and pick a **Camera**. This saves the current named
   scene; new scenes must first be saved in Godot. **Choose scene…** selects another
   saved scene. Runtime-created cameras can use a manual path under Advanced.
4. Choose **Production · 4K**, duration, audio and an output folder. **Check setup**
   shows configuration issues, tool capabilities and saved-scene notes.
5. Click **Test 1 second** to inspect a sample and estimate render time/storage,
   then **Render 360 video**. Use **Open output** for the verified `video-360.mp4`.

The panel previews the first frame as a draggable sphere. **Play video** prepares
a cached copy up to 2K / 30 FPS, then plays the entire clip with seeking and sound
inside Godot. Scene-effect warnings are displayed beside playback. See
[playback requirements and limits](addons/godot360/PLAYBACK.md).
To review the original full-resolution MP4, install VLC from VideoLAN's download above, use **File/Media → Open File**, and
hold the left mouse button while dragging to look around. VideoLAN documents this
in its [360° playback guide](https://docs.videolan.me/vlc-user/desktop/3.0/en/advanced/player/360_video.html).
A video preserves the authored sequence; viewers can look
around, while interactive gameplay and gaze events need to be prepared for capture.

The current usability work adds scene/camera discovery, setup checks and grouped
controls to the 0.8 codebase. Historical beta evidence is recorded separately;
this working source has not been published as a new release.

## Setup troubleshooting

| Problem | Fix |
| --- | --- |
| The plugin is missing from Project Settings | Check that the file is exactly at `your-project/addons/godot360/plugin.cfg`, with no extra repository folder between them. Let Godot finish importing. |
| No FFmpeg executable in the download | Follow the [setup steps for your OS](addons/godot360/PLATFORMS.md). A source-code archive is not an executable package. |
| FFmpeg works but FFprobe is missing | Select FFprobe from the same package; it is a separate executable. |
| Tools are not found after changing PATH | Restart Godot, then use **Find installed tools**, or select the executables directly. |
| Check setup reports missing encoders or filters | Select a native build with the capabilities listed by the check. |
| Output looks like a stretched flat image | Open the final `video-360.mp4` in a 360-capable player; `preview.png` is the flat panorama and `encoded.mp4` is the intermediate file. |

## What it supports

- Mono 360° video, SDR BT.709, and ordinary stereo sound.
- Draft 2K, Production 4K and Detail 8K presets; 24, 25, 30, 50 or 60 FPS.
- Scene audio, an attached soundtrack, or a mix.
- Measured short-test estimates, progress, cancellation and saved-job recovery.
- Re-encoding retained captures to change quality or sound without rendering again.

**Captures use the saved project's renderer and graphics driver.** Forward+ and
Mobile have actual visual export evidence on Windows with Vulkan and Direct3D 12,
and on Linux/WSLg with Mesa software Vulkan. Compatibility remains covered.
Advanced offers explicit overrides; unexpected fallback stops capture.
**macOS is prepared for testing**;
native Mac exports remain unvalidated. See [platform status](addons/godot360/PLATFORMS.md#support-status).
FFmpeg and FFprobe are external dependencies.
Read [renderer support and scene effects](addons/godot360/RENDERERS.md) before
exporting glow, fog, GI, screen-space effects, TAA or custom compositors. Six-face
capture cannot make every screen-space effect seamless.
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
| Review motion and sound inside Godot | [Playback and review copies](addons/godot360/PLAYBACK.md) |
| Review delivery for YouTube | [Production workflow](docs/youtube-360-production.md) |
| Develop or contribute | [Tests](docs/testing.md) · [Validation record](docs/validation.md) · [Roadmap](docs/roadmap.md) |

The addon is [MIT licensed](addons/godot360/LICENSE). Settings, generated checks,
tool binaries and renders stay local; see [repository contents](docs/repository.md).
Project code, interface text and documentation are in English.
