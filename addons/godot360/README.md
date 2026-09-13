# Godot360 Studio

An original Godot addon for producing **monoscopic 360 video** from a 3D scene.
Configure a scene and camera, render a fixed number of frames, encode an MP4,
write spherical metadata, and inspect the validation report from one editor panel.

![The current recipe and a completed calibration sample in Godot360 Studio.](media/studio.png)

*Select a scene and camera, test a second, render, then drag, seek and listen.
This is the actual panel with a completed calibration sample in the full-resolution
still view. Video playback uses a separate copy limited to 2K / 30 FPS.*

**[Start here: your first 360° export →](QUICKSTART.md)**

**Version 1.0.0-rc.1 — private Windows release candidate.** Final validation and
human acceptance remain pending before stable release. The addon has passed isolated project checks on
Windows with Godot 4.5.1, 4.6.3 and 4.7.2, Compatibility, and an NVIDIA RTX 3060 Ti.
Linux and macOS preparation and evidence are listed in [Platform setup](PLATFORMS.md).
Forward+ and Mobile have actual rendered evidence; see [renderers and scene appearance](RENDERERS.md).
Native Mac exports remain unvalidated. Read the
[compatibility guide](BETA.md) for the exact coverage and a clean-project
check. No custom engine or .NET runtime is needed.

The [Windows 1.0 support contract](SUPPORT.md) consolidates the intended launch
matrix, tested scene setups and limits. Existing installations should follow
[the upgrade guide](MIGRATION.md) before replacing the addon.

## Install

### Downloads

**[Platform setup](PLATFORMS.md)** has complete download and installation steps:

- **Godot:** [4.7.2 Standard, official archive](https://godotengine.org/download/archive/4.7.2-stable/), choosing Windows, Linux or macOS for your machine. Keep your project's renderer.
- **Windows FFmpeg/FFprobe:** [gyan.dev release essentials ZIP](https://www.gyan.dev/ffmpeg/builds/); extract both executables from its `bin` folder.
- **Linux FFmpeg/FFprobe:** Ubuntu/Debian `sudo apt install ffmpeg`; [Linux instructions](PLATFORMS.md#linux).
- **macOS FFmpeg/FFprobe:** [Install Homebrew](https://docs.brew.sh/Installation), then [`brew install ffmpeg-full`](https://formulae.brew.sh/formula/ffmpeg-full); [Mac instructions and explicit tool paths](PLATFORMS.md#macos).
- **VLC, optional:** [VideoLAN download](https://www.videolan.org/vlc/) for [360° playback](https://docs.videolan.me/vlc-user/desktop/3.0/en/advanced/player/360_video.html).

No Python, compiler, .NET runtime or Godot export templates are needed by the addon.
Native macOS export validation remains pending. Check setup and render a short test
after installing or changing tools.

### Enable the addon

1. Copy `addons/godot360` into a Godot project at the same path.
2. Enable **Godot360 Studio** under **Project > Project Settings > Plugins**.
3. Open the **Godot360** bottom panel.
4. Open **Tools → Tool setup** and choose **Find missing tools**, or use **FFmpeg…**
   to select the executable (`ffmpeg.exe` on Windows, `ffmpeg` on Linux/macOS).
   FFprobe is filled in when installed beside it unless you already selected a path;
   otherwise select it with **FFprobe…**. Selecting these files is enough; PATH
   configuration is optional. Click **Check setup** after choosing an output folder.
   FFmpeg must include **libx264**, **AAC**, `scale`, and `colorspace`.
   **Fast PNG** storage additionally requires its **PNG** encoder.
   Optional in-editor video playback requires **libtheora** and **libvorbis**.

FFmpeg is an external codec dependency. The addon does not bundle or silently
download executables. Selecting FFmpeg also locates FFprobe in the same directory
when present and no deliberate FFprobe selection exists. Clear a field to allow automatic discovery again. Machine paths are saved in `.godot360/settings.cfg`; exclude that
directory and your render directory from version control.

For an existing installation, follow the [folder migration guide](MIGRATION.md)
before replacing the addon or loading saved recipes.

## First export

**Current recipe** describes the next render. **Opened export** shows the saved job
you are reviewing; editing or loading a recipe does not change its metadata.
Tools and the export/recipe library have their own tabs. See the [quick start](QUICKSTART.md)
for playback retry, keyboard review and recovery.

For the complete walkthrough, use **[Your first 360° export](QUICKSTART.md)**.
The panel's **Quick start** button opens that guide locally.

1. Click **Use current scene** to save and select your open named scene, or
   **Choose scene…** for another saved scene. Pick a **Camera** from the list.
   For the included calibration room, open **Library → Recipes and examples** and choose
   **Calibration defaults**; its camera is selected automatically.
2. Choose **Production · 4K** for viewing or **Draft · 2K** for a quick compatibility
   check. Set duration, frame rate, audio and **Save exports in**.
3. Click **Check setup**. It verifies FFmpeg/FFprobe capabilities and output-folder
   writes, and displays saved-scene notes. Missing tools open **Tool setup**.
4. Click **Test 1 second** to inspect a sample and estimate the full export's time
   and retained storage. Then **Render 360 video** for the full duration.
5. Drag the spherical preview, then click **Play video** to review the whole clip
   with seeking and sound. A local copy is prepared on first use. Use **Open folder**
   for `video-360.mp4` and `report.json`; inspect the master in a full-resolution player.

**Advanced capture and encoding** contains the manual camera path, dimensions,
renderer/driver overrides, PNG storage and H.264 CRF. **Audio timing and levels** contains offsets, trim and
gain. **Library → Recipes and examples** contains recipe loading/saving and both examples.
**Library → Saved exports and recovery** contains job reopening, re-encoding and diagnostics.

Current-scene selection and export save the open named scene through Godot. Other
scenes use their saved versions. Save other scenes, scripts and assets before
exporting. Camera discovery reads saved metadata, including inherited and instanced
scenes, without instantiating their nodes. Runtime-created cameras require a manual
path and a short test. Setup checks do not certify scene behavior or visual quality.

Each export creates a fresh timestamped directory. The pipeline refuses to reuse
a previous job's directory. Cancel stops rendering at a frame boundary and stops
an active encoding or verification process. Partial files and logs are retained.
Only a successfully verified export receives the final `video-360.mp4` filename.
Closing the editor does not terminate the independent export job.

Jobs check available disk space before launch and while writing. Capture keeps
working headroom for images and audio plus a 256 MiB reserve; metadata checks that
the second MP4 copy will fit. A low-space or required checkpoint-write failure
stops the job and retains its sources. Read the [storage guide](STORAGE.md).

The panel reopens its last saved job at startup. **Library → Recent exports** remembers up
to 12 launched or opened jobs; choose an entry and click **Open** to review it.
**Forget** removes only the list entry. Use **Open saved job…** to locate another
export. A running 0.6.3 coordinator must answer a fresh request before the
panel reconnects and enables cancellation. Completed captures offer **Re-encode
this capture**, using the current CRF/audio settings and a fresh output folder.
Unconfirmed jobs show their last saved stage and available recovery action.

Use **Save diagnostics…** to save the selected job's reports, log excerpts and
environment information as a local ZIP. Choose a new filename outside the job
folder. Review the contents before sharing: local paths and scene-written text
can be included. Source media is excluded. The [diagnostics guide](DIAGNOSTICS.md)
explains limits and the [beta report form](BETA-REPORT.md) records feedback.
Independent Windows/GPU feedback and current YouTube review remain pending.

Failed jobs show a recovery action in the panel. A completed capture can usually
be re-encoded after fixing the reported issue; an interrupted capture needs a new
render. Read [recovering a failed export](RECOVERY.md) for the saved diagnostics
and the limits of partial files.

During capture and encoding the panel shows completed frames and approximate
time remaining in that stage. Encoding ETA appears after its initial startup.

The preview initially shows the first delivered frame. **Play video** prepares
a cached review copy up to 2K / 30 FPS for native playback, seeking and sound.
Actual scene-effect warnings appear beside playback. Read [Playback](PLAYBACK.md)
for codec requirements, cancellation, cache storage and quality limits. Check all
directions and the full-resolution delivery MP4 before publishing.

## Test before a long render

**Test 1 second** uses the scene, camera, resolution, face size, FPS, frame storage,
and CRF of your full recipe. It renders the first second, or the entire clip if
shorter, and runs encoding, metadata, and all output checks. Your full duration is
preserved. The test has its own folder, preview, and playable MP4.

The panel estimates total export time and retained storage from the measured test.
Storage includes the PNGs, WAV, preview, and both MP4 copies. Suggested free space
adds 25% plus 64 MiB of headroom; it does not reserve space or guarantee completion.
Available space is shown when the operating system can report it.

Changing duration rescales the estimate. Changing capture/encoding settings, tool
paths, renderer/driver, engine, OS, saved project configuration, the saved scene's modification time, or the output parent marks it stale.
Changes to referenced scripts, textures, or other assets are not detected: re-test
after editing them. Later scene complexity, startup costs, and compression can
differ from the first second. Treat these figures as planning estimates.

## Re-encode saved frames

Set **H.264 CRF**, then choose **Re-encode saved…** and select an original
completed capture folder containing `job.json`, `capture-result.json`, and `frames/`.
The panel validates the PNG sequence and WAV and creates a fresh output folder.
It reads the originals without modifying them or copying the frame sequence.

Resolution, FPS, frame count, and warmup come from the capture recipe; CRF controls
the new encode. Lower CRF means higher quality and usually a larger MP4. Changing
scene or capture settings requires rendering again. Re-encoding works without the
scene installed and needs no GPU capture, but still requires FFmpeg and FFprobe.
Keep the original capture folder for future re-encodes: a re-encode output contains
the new MP4s, preview, logs, and source reference, not another copy of the source.

## Export recipes

**Save recipe** writes a `.tres` resource that can be shared with the scene.
**Load recipe** restores it. Additional fields can be edited in Godot's Inspector:
random seed and warmup frames. H.264 CRF is also exposed in the panel. Duration is
rounded to whole frames.
Frame storage and the optional capture border are also saved with the recipe and
local editor settings.

**Capture border per edge (%)**, under Advanced, renders extra scene context
around each face, then smoothly blends overlapping views. Start with **12.5%** when testing
glow cuts; the default is **0%**. It retains the core's pixel density and increases
face pixel count by about 56% at 12.5%, so GPU memory and render cost can rise.
Output dimensions stay the same. Run a new short test after changing it.
It reduces some glow cuts but does not fix independent auto-exposure metering or
all view-dependent effects. See [capture borders and limits](RENDERERS.md#capture-borders).

| Use | Equirectangular output | Face size | FPS |
| --- | --- | --- | --- |
| Draft / compatibility check | 2048 × 1024 | 512 | 30 |
| Production | 4096 × 2048 | 2048 | 30 |
| Detail, hardware permitting | 7680 × 3840 | 3072 | 30 |

These dimensions cover the entire sphere. A 90-degree horizontal view spans
approximately 512 source columns in a 2K panorama, 1024 in a 4K panorama, and
1920 in a 7680-pixel panorama. Perspective reprojection distributes those samples
nonuniformly. The player's display resolution is not the panorama's resolution.
Draft output will look soft when enlarged into a desktop viewing window.

The studio shows quality advice before rendering and saves it in
`quality-checks.json`. A larger output cannot restore detail that was never
captured by the cube cameras. Production and Detail use CRF 16; Draft uses CRF 18.

Output width can be any multiple of four from 256 to 7680; height is half its
width. Supported frame rates are 24, 25, 30, 50, and 60. Higher resolution presets
are settings, not a performance guarantee. PNG compression varies by scene;
retained frames can consume gigabytes. There is no disk-space reservation.

## Use your scene

For camera paths and keyed timelines, use the **Motion lab** example and the
[authoring guide](AUTHORING.md). Version 0.4 includes a reusable AnimationPlayer
scene base, absolute frame sampling, editable Path3D example, and motion/audio checks.

Choose a saved `.tscn` and select its `Camera3D` from the camera picker. For a runtime-created camera, enter its path relative to the scene root under **Advanced capture and encoding**.
The rig follows that camera's position and orientation. FOV is replaced by six
square views with a 90° core and optional borders; near/far planes, cull mask, environment, camera attributes,
offsets and camera compositor follow the source each frame. See [renderer details](RENDERERS.md)
for viewport settings and effects that use independent face histories.
Keep the source camera's scale uniform. Avoid abrupt rotations and
translations when authoring a comfortable seated experience.

The capture worker hides the scene's CanvasLayers. Place titles in the world as
fixed 3D geometry if they should be visible in the panorama. Camera-facing sprites,
labels, and screen-space effects can differ across cube faces. The worker records
some of these risks in `scene-checks.json`; it is not an exhaustive visual audit.

Optional methods on the scene root let you prepare a film without changing its
normal interactive behavior:

```gdscript
func prepare_360_capture(job: Dictionary) -> void:
    # Called before the scene enters the tree; @onready fields are unavailable.
    $Player.auto_capture = false

func begin_360_capture(job: Dictionary) -> void:
    # Called after _ready, before rendering starts.
    # Disable live input and start your authored timeline here.
    pass

func sample_360_frame(frame_index: int, time_seconds: float, job: Dictionary) -> String:
    # Optional: called at the capture rig's process step, before camera sync.
    # Set authored state at frame_index / FPS; warmup repeats time zero.
    $MovingObject.position.x = sin(time_seconds) * 2.0
    return ""
```

Only define `sample_360_frame` when your scene uses absolute sampling. The helper
`timeline_scene.gd` supplies this hook for supported AnimationPlayer property tracks.
Begin/sample hooks can return an error string to stop capture; void hooks remain valid.

Only nodes under the selected scene are covered by these hooks. Project autoloads
still run. Disable any live input, network dependencies, or nondeterministic logic
in your own capture hook as needed. A fixed timestep and seed do not guarantee
identical physics, particles, or shader results across engine versions or GPUs.

## How it works

```text
Scene + source Camera3D
  → six SubViewports sharing one World3D, in the same rendered frame
  → original GPU shader mapping directions to a 2:1 equirectangular image
  → full-resolution PNG sequence (Fast or Compact) + Movie Maker's clock and WAV
  → FFmpeg: sRGB to BT.709, H.264/yuv420p + AAC stereo/48 kHz
  → original GDScript MP4 writer: spherical video UUID and XML
  → FFprobe: decode/count frames and inspect streams and spherical mapping
```

Front is the source camera's local **−Z** axis at the image center. Right is +X,
up is +Y, and the left/right image seam lies behind the camera. There is one
simulation and six views, not six independently advancing scene instances.

Movie Maker fixes its output dimensions before a script can configure a custom
viewport. This implementation therefore saves the viewport image itself and uses
Movie Maker for fixed-rate timing and lossless audio. Its scratch PNGs are removed
as rendering proceeds. This costs extra GPU readback/encoding work; a native
MovieWriter extension is a possible future optimization, not required to use the addon.

Fast PNG sends the original RGB8/RGBA8 bytes through a blocking OS pipe into a
persistent FFmpeg PNG encoder using compression level 1 and the Sub filter.
Backpressure limits pending data; GDScript does not accumulate a queue of images.
Error output is drained concurrently so a failing encoder cannot fill its error
pipe. The worker closes input and checks the encoder's exit code before accepting
the capture. Compact PNG uses Godot's built-in `Image.save_png()` instead.
The modes change storage compression only: resolution, antialiasing, frame timing,
color conversion, and final H.264 settings remain determined by the same recipe.

The first two frames are warmup by default: scene node processing is disabled,
then those images and the corresponding WAV duration are excluded from the MP4.
Global shader time, autoloads, and independent SceneTree timers are not frozen.
Use zero warmup if the scene specifically manages its own startup timing.

## Outputs and validation

The **Audio and synchronization** controls select scene audio, an attached
soundtrack, or a mix, with trim, offsets and levels. They apply to both rendering
and re-encoding. See the [audio guide](AUDIO.md) for timing, external-file retention
and CLI fields.

- `video-360.mp4`: fast-start final video with equivalent Spherical Video V1/V2 metadata.
- `report.json`: pass/fail checks, engine version, and scene/quality warnings.
- `capture-settings.json`: requested/resolved/actual renderer and graphics driver, GPU/OS/engine, capture dimensions, viewport/camera settings, SDR contract and timeline sampling mode. Also included in `report.json`.
- `capture-timings.json`: capture elapsed time and per-frame readback/storage times.
- `frame-writer.log`: Fast PNG encoder diagnostics, empty on a successful quiet run.
- `quality-checks.json`: sampling estimates and resolution warnings.
- `probe.json`: FFprobe's independent inspection of the final MP4.
- `preview.png`: first delivered equirectangular frame.
- `frames/`: lossless PNGs, including warmup, and the finalized source WAV.
- `job.json`, `status.json`, and logs: reproducible settings and diagnostics.
- `encoded.mp4`: intermediate MP4 before spherical metadata injection.
- `storage.json`: measured PNG, WAV, encoded MP4, and preview sizes.
- `planning.json`: full-recipe estimates from a successful test job.
- `encode-progress.txt`: live FFmpeg progress records.
- `worker-exit.json`: the capture worker's process ID and reported exit code.
- `recovery.json`: after a pipeline failure, source checks and the next action.
- `session.json` and `control/`: coordinator identity and temporary requests/replies
  used to reconnect. Old process IDs alone never authorize cancellation.

Capture-specific files are in the original source folder for re-encode jobs.
Their reports record `capture_reused` and `capture_source`. Process logs retain
diagnostics, with separate `.stderr` files. Failed or cancelled verification can
leave `staged-360.mp4`; it has not been accepted as the final output.

The report also includes pipeline stage timings. Fast PNG's image-write timing
measures submission and backpressure, while compression can overlap later rendering;
capture elapsed time includes the final writer flush. Use elapsed time when comparing
backends, rather than adding individual CPU and GPU timings.

Checks cover resolution, decoded frame count, frame rate, video duration, H.264,
pixel format, BT.709 tags, AAC stereo at 48 kHz, and equirectangular metadata.
Four container checks also require V1, full mono V2, moov before media, and valid
chunk-offset bounds. Version 0.6 also checks audio duration: thirteen checks in
total. See `delivery_checks` and `audio` in the report.
Passing these checks does **not** certify seamless imagery, spatial audio, or
successful YouTube processing. A user confirmed basic 360 playback of the initial
2K UMBRAL clip on YouTube, while reporting poor sharpness. This does not establish
playback quality for other exports, resolutions, or devices.

The metadata writer accepts the pipeline's conventional MP4 with one H.264 video
track, at most one AAC audio track, self-contained media, and a final `moov` after
`mdat`. It inserts mono `st3d` and full equirectangular `sv3d` metadata after `avcC`,
retains equivalent V1 UUID/XML, and places the rebuilt `moov` before the first
`mdat`. Media bytes stay exact; video/audio chunk offsets move by the final moov
size. Offset tables promote from `stco` to `co64` when needed, including cascading
promotion. Media is copied in bounded blocks with cancellation checks.

Unsupported structure, fragmented/encrypted files, external media references and
fast-start **inputs** are rejected before output creation. Existing destinations
are never overwritten. The writer is not a general-purpose MP4 editor. A partial
staged file can remain after cancellation or an I/O failure.

The source repository includes `tests/metadata_checks.gd` and the independent
`tests/metadata_review.py`. The latter compares all non-moov bytes, every chunk
offset, packet hashes/timestamps and fully decoded video/audio. It also tests a
V2-only copy with the V1 UUID disabled. It requires Python and FFmpeg/FFprobe and
creates fresh review files beside the supplied output.

## Command line

Save an absolute-path job JSON with these fields:

```json
{
  "scene_path": "res://addons/godot360/examples/calibration.tscn",
  "camera_path": "Camera3D",
  "rendering_method": "project",
  "rendering_driver": "project",
  "width": 2048,
  "height": 1024,
  "face_size": 512,
  "fps": 30,
  "frames": 300,
  "warmup_frames": 2,
  "random_seed": 360,
  "crf": 18,
  "frame_writer": "fast_png",
  "output_dir": "/absolute/path/to/new-render",
  "ffmpeg": "/absolute/path/to/ffmpeg",
  "ffprobe": "/absolute/path/to/ffprobe"
}
```

```sh
godot --headless --path /path/to/project --script res://addons/godot360/pipeline.gd -- --job=/absolute/path/job.json
```

On Windows use paths such as `C:/Tools/ffmpeg.exe` and quote shell arguments
containing spaces. The coordinator is headless; its capture child needs a real
GPU/display. Arguments are passed as arrays without constructing shell commands.
Use `"frame_writer": "png"` for Compact PNG. Omitting the field preserves the
Compact PNG behavior of older JSON jobs; new editor recipes select Fast PNG.

For a test job, add `"mode": "test"`, set `"frames"` to one second or less, and
set `"target_frames"` to the full recipe's frame count. Other settings stay the same.
For re-encoding, use the same coordinator command with a minimal job:

```json
{
  "mode": "reencode",
  "source_dir": "/absolute/path/to/completed-capture",
  "output_dir": "/absolute/path/to/new-reencode",
  "crf": 16,
  "ffmpeg": "/absolute/path/to/ffmpeg",
  "ffprobe": "/absolute/path/to/ffprobe"
}
```

The destination must be fresh and outside the source capture folder. The
coordinator obtains capture settings from the source and starts no rendering child.

## Scope and contributions

This is an original implementation. Existing projects were studied as architectural
references; their addon code is not incorporated. See `REFERENCES.md`.
The addon is MIT licensed; external tools keep their own licenses.

Useful next contributions: cross-platform runs, more demanding seam regression scenes,
broader soundtrack format tests, 8K checks on more hardware, and a native
audio/image writer if measurements justify it. Stereoscopic
ODS and ambisonic audio need separate designs and tests; they are not implemented.
All code, comments, UI, documentation, and issue/PR content should be in English.
