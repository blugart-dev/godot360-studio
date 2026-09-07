# Your first 360° export

Use a saved Godot 3D scene and a Camera3D to produce a video viewers can look
around in. You choose the camera's position and movement; viewers choose their
looking direction. Interactive gameplay and gaze-triggered events need a planned
sequence if they should appear in the film.

## 1. Install and check your tools

1. Copy `addons/godot360` into your project. Enable **Godot360 Studio** in
   **Project > Project Settings > Plugins**, then open the **Godot360** bottom panel.
   In this repository's demo project, the plugin is already enabled.
2. Expand **Tool setup** if FFmpeg and FFprobe were not found on PATH. Select
   **FFmpeg…** and locate the executable; FFprobe is filled in when it is beside it.
   Otherwise select **FFprobe…** separately. **Find on PATH** searches again.
3. If you need the tools, **Download help** opens
   [FFmpeg's official download page](https://ffmpeg.org/download.html). On Windows,
   extract a linked Windows build and locate `bin/ffmpeg.exe` and `bin/ffprobe.exe`.
   Keep that folder available for future exports. Nothing is downloaded by the addon.

The initial support target is Windows and Godot's **Compatibility** renderer.
See the [supported versions and validation scope](README.md). Forward+ and Mobile
show a note because they have not been validated; setup does not change your renderer.

## 2. Select your scene and camera

Open your scene and click **Use current scene**. This saves the named scene before
selecting it. A new, unnamed scene must first be saved in Godot with **Ctrl+S**.
You can also use **Choose scene…** to select another saved `.tscn`.

Pick a **Camera** from the list. The addon selects the only camera automatically,
or the uniquely marked current camera if there are several. Otherwise it asks you
to choose. Cameras in saved inherited and instanced scenes are included.

**Refresh cameras** rereads the saved scene. Discovery does not instantiate scene
nodes. If a script creates your camera at runtime, choose **Enter a runtime camera
path…** and enter its path relative to the scene root, such as `Player/Camera3D`.
That path can only be confirmed when the scene runs, so use a short test first.

The selected current scene is saved again before **Check setup**, **Test 1 second**,
or **Render 360 video**. Other scenes use their saved files. Save changes to other
scenes, scripts and assets before exporting. Camera forward (`-Z`) is the initial
viewing direction. 2D interface layers are hidden; use world-space 3D titles instead.

To check the addon before trying your own scene, expand **Recipes and examples**
and select **Calibration defaults**. It contains six labeled directions and a tone.
**Motion lab** supplies an editable animated-camera example.

## 3. Choose the video

| Setting | Start with |
| --- | --- |
| Quality | **Production · 4K** for viewing; **Draft · 2K** for a quick compatibility check |
| Duration | A few seconds for your first clip |
| Frames per second | 30 |
| Audio source | Scene audio, or select a soundtrack file |
| Save exports in | A local folder with enough free space |

The resolution covers the whole sphere, so 2K looks soft in a large viewing window.
**Detail · 8K** increases viewing detail and render/storage cost. Quality presets
set both output and capture resolution together.

You can leave **Advanced capture and encoding** and **Audio timing and levels**
collapsed. Their defaults work for a basic export. The [audio guide](AUDIO.md)
explains mixing, offsets and levels; the [reference guide](README.md#export-recipes)
explains quality and storage settings.

## 4. Check, test, render

Click **Check setup**. The panel verifies tool capabilities and checks that the
output folder can be written, while keeping the editor responsive. It also shows
saved-scene risks and configuration errors. Follow the guidance beside each issue.
Paths are remembered locally in `.godot360/settings.cfg`.

**Ready for a 1-second test** means the basic setup checks passed. A runtime camera,
scene behavior, soundtrack decoding, and the actual pictures still need a test.
Tool and output checks become stale when their paths change. The export pipeline
always repeats its own checks, including disk-space checks during the job.

Click **Test 1 second**. It renders the first second at your chosen quality, creates
a verified sample, and estimates the full export's time and storage. Your full
duration is preserved. Later content may cost more; a first-second estimate is not
a guarantee. Then click **Render 360 video** when the sample looks right.

The render runs separately from the editor. **Cancel** stops it and keeps the
partial files. Each job gets a new folder; existing exports are preserved.

## 5. Review your result

Drag the **360° still preview** to check the first frame's orientation. **Open output**
opens the selected job folder. `video-360.mp4` is the verified delivery file;
`report.json` records the technical checks. Watch the whole MP4 in a spherical
video player to check movement and sound. The panel preview is a still image.

Keep the capture folder if you may want to change quality or audio later.
Under **Saved exports and recovery**, **Re-encode this capture** uses retained
frames without rendering again. **Open saved job…** opens an earlier job, and
**Save diagnostics…** collects its reports and logs for troubleshooting.

## If something needs attention

| What you see | What to do |
| --- | --- |
| Save your scene first | Save the open scene with Ctrl+S, then use it again. |
| Choose a camera | Pick a listed Camera3D; for a generated camera, enter its runtime path under Advanced. |
| Missing tools or encoders | Select FFmpeg and FFprobe in Tool setup, then Check setup again. |
| FFmpeg has no PNG encoder | Choose Compact PNG under Advanced, or another FFmpeg build. |
| 2D UI or billboard notes | Use 3D titles and fixed geometry, or inspect a short test for seams. |
| Failed export | Expand Saved exports and recovery and follow the job's recovery action. See [recovery](RECOVERY.md). |
| Blurry playback | Use 4K or 8K and check the player's selected playback resolution. |

For camera animation and interactive scenes, continue with [authoring](AUTHORING.md).
For storage, see [retained captures and disk space](STORAGE.md). For a reproducible
problem report, use the [beta form](BETA-REPORT.md).
