# Your first 360° export

Turn a saved Godot 3D scene into a video viewers can look around in. You author
the camera position and movement; viewers choose their looking direction.
Interactive gameplay needs a planned sequence to appear in the film.

![Current recipe beside a completed one-second calibration export in Godot360 Studio.](media/studio.png)

The **Current recipe** tab describes your next render. **Opened export**, on the
right, shows the saved scene, resolution, duration and audio of the job you are
reviewing. Editing the recipe or opening another export keeps these separate.

## 1. Install and select tools

1. Copy `addons/godot360` into your project. Enable **Godot360 Studio** in
   **Project → Project Settings → Plugins**, then open the **Godot360** bottom panel.
   Drag the top of the bottom panel upward for a larger preview.
2. Open **Tools → Tool setup**. Select **FFmpeg…** from an extracted installation.
   FFprobe is filled from that folder unless you deliberately selected it already.
   Select **FFprobe…** separately if needed. Windows files end in `.exe`.
3. **Find missing tools** fills empty/default fields from installed tools. It keeps
   selected paths, including unavailable paths. Clear a field to allow discovery
   again. No executable is downloaded. Selections are saved in this project.
4. Choose a writable folder in **Current recipe**, then **Check setup**. The Tools
   tab identifies both versions, delivery capabilities and optional playback
   codecs. **Open setup logs** opens the detailed results. Repeat this check after
   changing tools. Available playback codecs do not guarantee a clean copy; each
   generated playback copy is fully decoded before it can play.

Use [Platform setup](PLATFORMS.md) for installation and download instructions.
The recommended development baseline is Godot 4.7.2 Standard; the addon needs no
.NET, Python, compiler or export templates. Keep your scene's renderer. See the
[platform validation limits](PLATFORMS.md#support-status).

## 2. Select a scene and camera

In **Current recipe**, click **Use current scene**. This saves the named open
scene. Save a new unnamed scene in Godot first with Ctrl+S (Cmd+S on macOS).
**Choose scene…** selects another saved `.tscn`. Pick a **Camera**; a sole camera
or a unique current camera is selected automatically. Inherited and instanced
saved cameras are included. **Refresh cameras** rereads the saved scene.

For a script-created camera, choose **Enter a runtime camera path…** and enter
its path relative to the scene root under **Advanced capture and encoding**.
Only a render can confirm that path, so begin with a sample.

The selected open scene is saved again before checking setup, testing or rendering.
Other scenes use their saved files. Save other scenes, scripts and assets in Godot.
Camera forward (`-Z`) is the initial viewing direction. 2D interface layers are
hidden; use 3D titles. See [authoring](AUTHORING.md) for animation and scene limits.

To try an example, open **Library → Recipes and examples → Calibration defaults**
for six labeled directions and a tone, or **Motion lab** for an animated camera.
Return to **Current recipe** to edit it. Examples replace the recipe; they do not
change the opened export or your authored scene.

## 3. Choose video, audio and destination

- **Draft · 2K** gives a quick compatibility test; **Production · 4K** provides
  more viewing detail; **Detail · 8K** costs more time and memory. The displayed
  dimensions cover the entire sphere. Hover for detail and sampling limits.
- Set **Duration (s)** and **FPS**. 30 FPS is a useful starting point.
- **Audio source** can use scene audio, a soundtrack, or both. Soundtrack modes
  reveal the file picker. **Audio timing and levels** has offsets, trim and gain.
  Short audio ends in silence; mixing uses a peak limiter. See [audio](AUDIO.md).
- Set **Save exports in**, or **Choose folder…**. Each job gets a new folder;
  existing captures and deliveries are preserved.

**Advanced capture and encoding** contains custom dimensions, camera path,
renderer/driver, capture exposure/borders, PNG storage and H.264 quality (CRF).
Lower CRF means larger files with more detail; the presets choose it for you.
For glow cuts or brightness seams, consult [renderer guidance](RENDERERS.md)
before changing borders or exposure, then make another sample.

## 4. Check, test and render

**Check setup**, **Test 1 second**, and **Render 360 video** stay at the foot of
the recipe area. The readiness line shows the next setup issue; full details and
saved-scene warnings are in **Tools**. Readiness describes the current recipe,
independently of an opened export's completion or failure.

Run **Test 1 second** first. It preserves your chosen full duration and opens the
one-second sample on the right. Review its image and sound. The recipe then shows
estimated time, retained storage and suggested free space for the full duration.
Estimates become stale after relevant settings, assets or destination changes.
The first second cannot predict later complexity or full-job memory use.

Choose **Render 360 video** when satisfied. Progress and **Cancel export** appear
with the opened job. Capture and encoding show their own frame counts/estimates;
the percentage is overall job progress, not a frame count. Cancellation waits for
the worker to stop and retains its files. Edits during a render apply to the next
job; they do not alter the active export.

## 5. Review and find the delivery

The review header names the image you see:

| View | Purpose |
| --- | --- |
| **Full-resolution still** | The original opening frame; drag to inspect detail and orientation. **Show still** returns here after playback. |
| **Playback copy · up to 2K / 30 FPS** | **Play video** prepares a local checked copy. Play/pause, seek, replay and mute/unmute to review motion and audio. |
| **Open delivery MP4** | Opens verified `video-360.mp4` at the export's original resolution in your default player. Use a 360° player to look around. |

Tab to the sphere and use arrow keys to look; Home or **Reset view** recenters it.
The seek slider supports keyboard input and is approximate, not frame-accurate.
**Open folder** reveals the delivery, `report.json`, logs and retained captures.
**Export details** shows the complete saved context, status, scene notes and
recovery guidance. Long paths can be selected/copied there. A notes count signals
capture warnings without taking space from the preview.

Playback preparation has separate progress and **Cancel preview**. A playback
error does not revoke a verified delivery. For corrupt-copy errors, use **Tool
setup**, select another FFmpeg build, **Check setup**, then **Retry playback**.
**Playback logs** opens the failed operation's logs. No scene render is needed.
See [playback and cache](PLAYBACK.md). Inspect the delivery in a full-resolution
360° player for final seams, compression and 50/60 FPS motion; local review does
not establish YouTube processing or headset comfort.

## Reopen or recover an export

**Library → Recent exports** lists the last 12 jobs. Select an entry to inspect it,
then **Open**. Browsing keeps your current preview and recipe until Open; opening
also preserves your recipe. **Forget** removes only the entry, keeping its files.
Use **Saved exports and recovery → Open saved job…** for a moved or older folder.
Unavailable drives stay in history. **Unconfirmed** requires Open to check the
coordinator; a saved stage alone does not prove it is running.

**Re-encode this capture** uses retained frames with the current quality/audio
settings. The source capture's scene, dimensions, FPS and duration stay fixed.
It writes a new export and preserves the original. Partial captures require a
fresh render. **Save diagnostics…** creates a local ZIP of reports/logs; review
its contents before sharing. Read [recovery](RECOVERY.md) and [storage](STORAGE.md).

Recipes are portable settings saved/loaded under **Library → Recipes and examples**.
Executable paths, history and the last opened job remain project-local in
`.godot360/settings.cfg`. Quick start is always available above the review area.
