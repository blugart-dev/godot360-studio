# Godot360 Studio

An original **Godot addon for producing mono 360° video**, with deterministic
capture, soundtracks, spherical MP4 metadata and export validation. Includes the
UMBRAL interactive installation and THRESHOLD, a sixty-second film through four
procedural worlds.

Previously named **Umbral360 Studio**. The internal `addons/umbral360` and
`.umbral360` paths are retained so existing recipes, scenes and local settings
continue to work. Historical release records use the original name. Godot360
Studio is an independent project.

See [repository contents and privacy preparation](docs/repository.md) for what is
versioned and what remains local. Exported videos and local tools are not included.

All project code, comments, interface text, and documentation are in English.
Development conversation may be in Spanish or English.

**THRESHOLD** is the original sixty-second, four-world film experiment. Open
`scenes/films/Threshold.tscn` with F6, or load `export_profiles/threshold-8k.tres` to
export it. See the [film guide and measured limitations](docs/threshold.md).

## Produce a 360 video

Open `project.godot` in **Godot 4.7.2** and use the **Godot360** bottom panel.
The plugin is already enabled in this project.

1. Select FFmpeg and FFprobe executables. FFmpeg needs libx264 and AAC.
   Paths are stored locally, outside the shareable addon.
2. Load `export_profiles/umbral-film.tres` for a 12-second, 4096×2048, 30 fps clip,
   or use **Calibration defaults** to check the six directions and generated audio.
3. Choose an output parent folder and click **Test 1 second** to estimate the
   full export's time and retained storage, then **Render 360 video**.
   **Fast PNG** speeds up capture using more temporary disk space; **Compact PNG**
   retains the smaller-file option. Both preserve the same source pixels.
4. Inspect the spherical still preview, `video-360.mp4`, and `report.json`.

Each job produces its own folder, with retained PNG frames, WAV, recipe, and logs.
Version 0.8 adds **Save diagnostics…** for reviewed local support ZIPs, an
[independent beta report](addons/umbral360/BETA-REPORT.md), and an exact-package
installation/workflow reviewer. See the [diagnostics guide](addons/umbral360/DIAGNOSTICS.md)
and [beta instructions](addons/umbral360/BETA.md). Source history starts at the
validated 0.7 baseline in local Git; renders, settings and tool binaries are excluded.
Version 0.7 adds working disk-space checks and required file-write checks. Captures
retained after a storage failure can be re-encoded in a fresh folder; partial
captures need a new render. See the [storage guide](addons/umbral360/STORAGE.md)
and the revised [route to 1.0](docs/roadmap.md).
Version 0.6.3 restores the last job when the panel opens. **Open saved job…** can
reconnect to an ongoing export or inspect a stopped job; **Re-encode this capture**
reuses a finalized source in a fresh job. Read the [recovery guide](addons/umbral360/RECOVERY.md).
The addon handles capture, encoding, spherical metadata, and FFprobe verification.
Version 0.6 adds soundtrack attachment, mixing, levels and synchronization offsets
for renders and re-encodes. Read the [audio guide](addons/umbral360/AUDIO.md).
It also delivers fast-start MP4 with equivalent Spherical Video V1/V2 metadata,
alongside measured job planning, live encoding progress and cancellation,
**Re-encode saved…**, and the **Motion lab** camera/timeline example. Read the
[job planning guide](docs/job-planning.md) and [authoring guide](addons/umbral360/AUTHORING.md).
It exports mono 360 and ordinary stereo audio. Stereo 3D, ambisonics, and YouTube
upload are not implemented. A user confirmed basic YouTube 360 playback of the
initial 2K clip, but found it blurry. Use **Production · 4K** or **Detail · 8K**
for greater viewing detail; 2K is a draft preset. The 12-second Detail recipe is
`export_profiles/umbral-film-8k.tres`.

Read the [addon guide](addons/umbral360/README.md) for setup, recipes, CLI use,
capture hooks, known limitations, and architecture. The
[production workflow](docs/youtube-360-production.md) explains release checks.

## Play the interactive installation

Press **F5**, or open `scenes/Main.tscn` and press **F6**.

| Control | Action |
| --- | --- |
| Mouse | Look around, with smoothing and pitch limited to ±85° |
| Esc | Release/capture the mouse |
| Click with mouse released | Capture the mouse |
| R | Smoothly recenter |
| F3 | Toggle FPS, target name, and gaze duration |

Mouse sensitivity is exposed on `Player` in degrees per pixel. Smoothing and pitch
limits are also configurable. Releasing the mouse or losing focus cancels gaze
interaction while environmental animation continues. Restart to reset discoveries.

- **Front — The core:** appears at 2 seconds. A one-second gaze changes its
  appearance and animation, once per playthrough.
- **Right — The echo:** sends a cue at 5 seconds. Look away and back to repeat its pulse.
- **Behind — The reverse:** a light trail appears at 8 seconds. Gaze opens and
  raises the bloom with its collision shape.
- **Left — The witness:** moves along an arc while the camera points at the core,
  then stops when you look elsewhere. Its reaction depends on whether it has moved.
- **Above:** an animated orbital mobile; original SVG cutouts decorate the space.

The crosshair shows dwell progress. There are four discoveries, and exploration
can continue after finding them all. These interactions belong to Godot. A YouTube
video cannot execute the gaze logic: its events happen at the same time for everyone.

## Scene architecture

```text
scenes/Main.tscn
├── World
│   ├── Environment             Procedural sky or a panorama texture
│   ├── Props                   Floor, arches, sprites, and ceiling mobile
│   └── GazeTargets             Four independently instanced targets
├── Player
│   ├── Camera3D
│   └── GazeDetector
├── SequenceController
└── UI/HUD
```

| File | Responsibility |
| --- | --- |
| `scripts/player_look.gd` | Mouse input, capture, smoothing, recentering |
| `scripts/gaze_detector.gd` | Physics ray, target changes, dwell timer |
| `scripts/gaze_target.gd` | Reusable target properties and interaction signals |
| `scripts/props/*.gd` | Target behavior and Tween animation |
| `scripts/sequence_controller.gd` | Timed cues at 2, 5, and 8 seconds |
| `scripts/main.gd` | Narrative wiring, discovery count, optional film hooks |
| `scripts/ui/*.gd` | Crosshair, messages, compass, debugging |
| `scripts/world/*.gd` | Background and generated geometry |
| `addons/umbral360/` | Independent export tool, calibration scene, and preview |

Decorative meshes are generated in `_ready()`, so they appear when running the
scene. Gaze targets and their collision shapes are edited in their `.tscn` scenes.
The film hook disables live gaze, awakens the core at 3.5 s, pulses the echo at 6 s,
opens the rear bloom at 9 s, and moves the witness along a scripted arc. It also
orients cutouts toward the shared capture origin instead of per-camera billboards.

## Add a gaze target

1. Create an `Area3D` scene using `scripts/gaze_target.gd`.
2. Set collision layer 2 and collision mask 0, then add a suitable `CollisionShape3D`.
3. Add a visual node and instance the scene under `World/GazeTargets`.
4. Set `display_name`, `dwell_time`, `accent_color`, `enabled`, and `activate_once`.
5. Connect `gaze_activated` to its behavior. `gaze_entered` and `gaze_exited` are
   also available; all three signals have no arguments.

With `activate_once = false`, a target activates once per visit: look away to rearm
it. `reset_activation()` clears the completed state. Looking away, disabling or
removing a target, or releasing input resets detection. The four-discovery narrative
in `main.gd` is specific to this demo; adapt it when adding targets.

The detector queries layers 1 and 2. Occluding objects require a `StaticBody3D` and
collision on layer 1. A visual mesh alone does not block a physics ray.

## Use a panorama background

Copy a 2:1 equirectangular image into `assets/panoramas/`, select
`World/Environment`, and assign **Panorama Texture**. Adjust **Panorama Rotation
Degrees** to align it. Leaving the texture empty restores the procedural sky.
This is a static spherical background, with no video playback or positional parallax.

## Verification

The interactive regression suite covers 48 checks: real input events, camera
smoothing, physics rays, occlusion, target removal, repeatable events, narrative,
and background selection. Export tests cover validation, metadata structure,
source-byte preservation, unsupported inputs, and failure detection.

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/runtime_checks.gd
godot --headless --path . --script res://tests/export_checks.gd
godot --headless --path . --script res://tests/metadata_checks.gd
godot --headless --path . --script res://tests/audio_checks.gd
godot --headless --path . --script res://tests/planning_checks.gd
godot --headless --path . --script res://tests/timeline_checks.gd
godot --headless --path . --script res://tests/frame_writer_checks.gd -- --ffmpeg=/path/to/ffmpeg
```

The quality preset buttons, sampling warnings, and compact panel layout are checked
with `godot --path . --script res://tests/quality_panel_checks.gd` (GPU required).

A GUI/GPU integration test exercises the actual studio panel, full export, and
drag preview. Pass your tool paths after `--`:

```sh
godot --path . --script res://tests/studio_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe
godot --path . --script res://tests/planning_studio_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe --cancel-source=/path/to/completed-capture
```

It saves `.umbral360/studio-preview.png` and a two-second calibration export under
`renders/studio-checks/`. The optional legacy `tests/capture_preview.gd` records six
perspective views of the interactive installation; it is not the 360 exporter.
The planning integration test also checks duration rescaling, stale estimates,
re-encoding at another CRF, and source-file hashes. An optional `--cancel-source`
with a longer capture exercises cancellation during an active H.264 encode.

The metadata suite covers V2 structure, media relocation, 32/64-bit offset tables,
cascading promotion across 4 GiB, invalid inputs and copy cancellation. Review a
real encoded/final MP4 pair independently with:

```sh
python tests/metadata_review.py /path/to/encoded.mp4 /path/to/video-360.mp4 --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe
```

The reviewer compares media bytes, packet hashes/timestamps and all decoded video
and audio, and checks V2 recognition with the V1 UUID disabled in a separate copy.

`tests/audio_review.py` generates short cues, runs complete re-encodes, and compares
AAC decoding against independently placed source samples. Pass `--godot`, `--ffmpeg`,
`--ffprobe`, and a fresh `--output` folder. `tests/audio_delivery_checks.py` accepts
those arguments plus `--source-review` pointing to the completed audio review and
`--legacy-source` pointing to a pre-0.6 CRF-16 capture with its encoded MP4.
It checks limiting, legacy media preservation and soundtrack mutation rejection.

Version 0.6.1 fixes Motion Lab on Godot 4.5.1 and adds isolated compatibility checks
on 4.5.1/4.6.3/4.7.2, eight soundtrack format cases and a 90-second mix. The
[beta guide](addons/umbral360/BETA.md) gives exact coverage, clean-project steps,
reviewer commands and reproducible packaging with `tools/package_addon.py`.
Version 0.6.2 adds [failure recovery guidance](addons/umbral360/RECOVERY.md),
controlled worker/encoder interruption tests, and a real 90-second GPU capture at
60 FPS with all 5,400 delivered frames and audio cues checked. The compatibility
reviewer accepts `--capture-failures`; `tests/endurance_review.py` runs the long
fixture with the same tool arguments and a fresh `--output` directory.
Add `--job-recovery` to exercise reopened panels, editor/coordinator loss,
fresh identity checks, stale PID rejection and recovered-source re-encoding.
`tests/audio_studio_checks.gd` exercises the real panel with `--soundtrack`,
`--ffmpeg` and `--ffprobe`; it restores local studio settings afterward.

The Motion Lab button and complete authored export are checked by
`tests/timeline_studio_checks.gd` with the same executable arguments. Render
`tests/fixtures/motion.tscn` for six seconds, then run `tests/motion_review.py`
against its folder to inspect actual PNG/MP4 motion and tone alignment. See the
[authoring guide](addons/umbral360/AUTHORING.md#verification) for dependencies.

See [validation results](docs/validation.md) for the tested environment and known
gaps. The addon carries its own MIT license and reference notes, so it can be
copied into another project. It has not been published to the Asset Library.

See the [performance record](docs/performance.md) for measurements and the
[roadmap](docs/roadmap.md) for the next production milestones.
The [development handoff](docs/HANDOFF.md) records the current state and constraints
for continuing in a fresh session.
