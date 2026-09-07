# Camera paths and frame-sampled timelines

Godot360 0.4 adds an optional authoring path built on Godot's own AnimationPlayer,
Path3D, and PathFollow3D. The capture driver samples property tracks at a precise
output timestamp. The existing scene-processing workflow remains available.

## Try Motion Lab

1. Expand **Recipes and examples** and click **Motion lab** in the Godot360 panel. It loads the included six-second
   4096×2048 / 30 FPS recipe and its camera path.
2. Open `addons/godot360/examples/timeline.tscn` in Godot. All meshes, labels,
   path points, and animation keys are saved in the scene and can be edited.
3. Select `AnimationPlayer`, open its **film** animation, and scrub its tracks.
   The camera follows `CameraPath`; its orientation stays level and fixed.
4. Press F6 to preview the scene normally, or **Render 360 video** for the complete
   panorama. **Test 1 second** estimates cost but does not cover the later cues.

The orange marker travels around the horizon through cube edges and the rear
seam. The cyan marker travels through the zenith and nadir. A magenta card flashes
with a short tone at 1, 3, and 5 seconds. The title disappears at 3 seconds.
The studio still viewer shows only the first delivered frame; review full motion
in a spherical video player.

## Author your own scene

Start with **Use current scene** and the camera picker in the panel. See the
[quick start](QUICKSTART.md) for saving, camera discovery and setup checks.
For an interactive scene, plan what happens without player input: the exporter
runs a separate copy, so mouse movement and gaze events are not a film timeline.
Use the helper below for keyed motion, or the capture hooks later in this guide
to prepare your existing scene script. Ordinary scene processing remains available.

Attach `timeline_scene.gd` to a Node3D scene root, or extend it in your scene script:

```gdscript
extends "res://addons/godot360/timeline_scene.gd"

func _ready() -> void:
    super._ready()
    # Add any normal scene initialization here.
```

Add an AnimationPlayer, create a non-looping animation named **film**, and keyframe
the properties that should change. Set the root's **Animation Player Path** and
**Animation Name** if your names differ. **Preview Autoplay** controls normal F6
playback; capture always uses explicit frame sampling.

For camera movement, add this hierarchy:

```text
Scene root
├── CameraPath (Path3D, with a Curve3D)
│   └── Follow (PathFollow3D)
│       └── Camera3D
└── AnimationPlayer
```

Keyframe `CameraPath/Follow:progress_ratio` from 0 to 1 over the animation.
Set Follow's **Loop** off and **Rotation Mode** to **None** to preserve a fixed
viewing orientation. The export camera path is `CameraPath/Follow/Camera3D`.
Use gentle motion and avoid forced rolls or abrupt turns. Viewers still choose
their looking direction inside the resulting video; they cannot move its origin.

Use world-space Label3D titles with billboarding disabled. The example keys
`Title:visible` as a discrete property. A discrete track must have a time-zero key
so every sample has a defined starting state. Capture explicitly reapplies the
last discrete key, including on backward seeks and repeated warmup samples.

Supported tracks are ordinary value, 3D transform, blend-shape, and Bezier property
tracks. Method, audio, and nested animation-playback tracks fail with an explanatory
message. Value tracks in **Capture** update mode are also rejected because they
depend on the live starting value. Disabled tracks are ignored. Keep target nodes
and resources alive throughout capture and author initial property values explicitly.

## The frame contract

Delivered frame `n` samples the animation at `n / FPS`. A six-second, 30 FPS film
contains 180 delivered frames, sampling 0 through 5.966667 seconds. An endpoint key
at 6 seconds shapes interpolation but is not itself an extra delivered frame.
The export fails if its last timestamp extends beyond the animation's length.

Warmup repeatedly samples time zero, then the first delivered frame samples zero
again. The hook must be idempotent: set state from the supplied timestamp instead
of adding delta or triggering one-time events on every invocation.

The rig invokes sampling at process priority **1000**, then synchronizes all six
camera transforms before Godot flushes transform notifications and draws. Competing
scripts that write the same properties must be disabled or run before this step.
Avoid writing authored transforms at priority 1000 or later. Sampling in
`RenderingServer.frame_pre_draw` is too late for the tested Node3D notification path
and produced a measurable one-frame transform delay.

For a custom scene that already has its own base script, implement the optional
hook directly instead of inheriting the helper:

```gdscript
func sample_360_frame(frame_index: int, time_seconds: float, job: Dictionary) -> String:
    $MovingObject.position.x = sin(time_seconds) * 2.0
    return ""
```

`begin_360_capture(job)` and `sample_360_frame(...)` may return a nonempty error
string to stop capture. Existing void-returning hooks continue to work. A custom
sampling hook owns its own validation and state; `timeline_scene.gd` supplies the
AnimationPlayer validation and discrete-state handling described above.

If you extend the helper and override its capture hooks, call the corresponding
`super` method and propagate its error before adding custom behavior. For example:

```gdscript
func begin_360_capture(job: Dictionary) -> String:
    var error := super.begin_360_capture(job)
    if not error.is_empty():
        return error
    # Disable input or prepare other scene state here.
    return ""
```

This contract defines authored properties, not every process in a project. Physics,
particles, autoloads, shader TIME, and external logic can still vary. It does not
establish reproducibility across engines or hardware.

## Audio and synchronization

Scene audio remains the ordinary stereo mix recorded by Movie Maker. It is not
reconstructed by seeking animation tracks. The Motion Lab script generates a WAV
with three timed cues and starts an AudioStreamPlayer in `_ready()`. **Play Sync
Audio** can disable that example sound.

The example compensates for the startup mix interval observed with scene warmup
in the tested engine. Zero warmup uses a separate start offset. This is a tested
example, not a universal audio-latency correction applied to user scenes. Review
your own flash/tone alignment after changing engine, warmup, or audio initialization.
Version 0.6 can replace or mix that recording with an attached soundtrack and apply
explicit scene/soundtrack offsets during encoding. See the [audio guide](AUDIO.md).
Audio-track timeline editing and ambisonics remain future work.

## Verification

`tests/timeline_checks.gd` verifies absolute seeking, camera movement, visibility,
duration limits, and unsupported-track errors. `tests/timeline_studio_checks.gd`
exercises the Motion lab button and a complete production export.

For geometric and audio checks, render `tests/fixtures/motion.tscn` for six seconds
at 2048×1024, 1024-pixel faces, and 24 or 30 FPS. The fixture substitutes a simple
camera path with an analytic reference. Then run:

```sh
python tests/motion_review.py /path/to/render-folder --ffmpeg /path/to/ffmpeg
```

The test requires numpy and Pillow in addition to FFmpeg. It independently reads
all retained and decoded MP4 frames, measures spherical marker direction and area,
checks exact flash frames, and measures source/encoded tone onsets. It writes
`motion-review.json`. This does not certify arbitrary scenes as seam-free.

Official references: [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html),
[PathFollow3D](https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html),
and [Node3D transform notifications](https://docs.godotengine.org/en/stable/classes/class_node3d.html#class-node3d-method-force-update-transform).
