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
Click **Play video** for a local review copy with native seeking and sound.
Use the delivery MP4 in an external spherical player for final detail; see
[playback quality and limits](PLAYBACK.md).

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

The rig invokes sampling at process priority **1000**, then defers synchronization
of all six cameras until Godot has applied queued skeleton/attachment updates.
Camera transforms still reach the renderer before this frame draws. Competing
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

## Particle simulation and processing modes

CPU and GPU particles belong to the scene's single World3D. The six views share
that simulation. A sampling hook sets authored properties; it does not seek or
restart particle simulation. Godot's Movie Maker clock drives ordinary processing.
The capture worker disables realtime physics jitter compensation so the opening
process deltas follow that fixed clock too. At normal time scale, each process
step is `1 / export_fps`. Authored physics tick rate and time scale remain in effect.
This is local to the worker; it does not change the project's settings or editor.

Capture now preserves the scene root's authored `process_mode`, including changes
made by its setup hook. Warmup temporarily disables root processing and restores
the saved mode once before delivery begins. Zero warmup leaves the mode alone.
Later changes made by the scene remain in effect, so a deliberately disabled scene
or a scene that pauses itself stays paused. Explicit child processing modes and
autoloads still follow Godot's normal rules; warmup is not a global simulation pause.

Use **at least two warmup frames** for particle scenes and inspect the opening.
The simple fixture now matches its reference with the default two frames. More
complex effects may need additional warmup. Zero warmup can omit GPU particles or
show them in only some directions at first. Warmup holds
the ordinary scene clock; it does not simulate several seconds of particle history.
Author an emitter's `preprocess` or a deliberate scene pre-roll when a mature effect
is needed, and validate that separately. Compatibility CPU emitters present at
capture setup now have automatic bounds refreshed before drawing, removing the
measured first-frame gap. Authored **Visibility AABB** and custom bounds remain
unchanged. If you author bounds, include the mesh extent and full motion, and
recheck them after changing the effect. Dynamically created or reactivated effects
need their own review.

The regression fixture uses opaque sphere meshes, constant velocity, no collisions,
explicit visibility bounds and particle **Fixed FPS = 0**, with GPU interpolation disabled. In Movie Maker,
this lets the emitter follow the export frame clock. Matching-rate fixed CPU/GPU
steps are also checked against the same reference. Different particle/export rates
can legitimately quantize motion; interpolation, preprocess and effect history
need separate references. The old repeated 30 Hz step at 30 FPS was caused by
startup clock compensation, which capture now disables.
Choose the authored timing that suits the effect and inspect the result. The addon
does not override particle FPS, speed, seed, interpolation or emission settings.
Previously retained PNG sequences keep their original timing during re-encoding;
render the scene again to apply the corrected clock.

Set a GPU emitter's `use_fixed_seed` and `seed` for repeatable random emission on
the same configuration. The job's global random seed does not set GPU emitter
seeds. Neither setting promises identical particles across engines or GPUs.
Transparent/billboard particles, trails, collisions, subemitters, animated emission,
moving emitters and long histories still require representative validation.

See Godot's [GPUParticles3D reference](https://docs.godotengine.org/en/4.5/classes/class_gpuparticles3d.html)
for fixed FPS, seeds and preprocessing. The repository's `docs/particle-capture.md`
records the rendered fixture and exact evidence.

## Skeletal animation and viewpoint cuts

Keyed Skeleton3D bone position/rotation tracks and weighted meshes can use the
same timeline helper. A selected Camera3D below a BoneAttachment3D follows the
sampled bone pose in the same delivered frame, including a discrete viewpoint
change. Parent and external skeleton attachments are covered by the regression
fixture; the camera's own local transform is preserved.

Earlier internal builds copied the camera before the deferred attachment update,
making the viewpoint one frame late while the skinned mesh was already current.
The fix lets Godot finish its queued updates; it does not force a second skeleton
evaluation, advance animation again, or change the authored bone poses.

A cut means changing the transform of the **selected export camera**. Switching
another camera's `current` property does not change the selected capture source.
TAA and other temporal effects keep their per-face histories across cuts. A correct
cut timestamp does not guarantee freedom from ghosting; inspect the cut and the
following frames, and disable TAA if its appearance is unsuitable.

The rendered fixtures include a small constructed skeleton and the imported
CesiumMan GLB: 19 joints, 57 TRS animation channels and a weighted character mesh,
with an external head attachment, camera boom and viewpoint cut. Its raw-glTF
reference uses precise import settings: animation optimization, immutable-track
removal, mesh compression and generated LODs are disabled in the disposable test
project, and the import bake FPS matches the compared export FPS. These are
reference-test settings, not changes applied by the addon.
Godot's default import optimization may approximate source curves; inspect the
imported animation itself when comparing with a DCC/source-file reference.

Use the imported AnimationPlayer's actual path and clip name with the timeline
helper, and ensure the capture clip does not loop or end before the requested
film. The helper samples imported position/rotation/scale tracks normally.
The imported fixture also covers a stateless custom SkeletonModifier3D head look
and a nested skeleton/camera mount. For this setup, use Manual modifier processing:
sample animation, set the target from absolute sample time, then call
`skeleton.advance(0.0)` in `sample_360_frame`, including repeated warmup samples.
The final modifier pass is deferred. Observe final bones in `skeleton_updated`;
Godot restores the base animation pose after submitting the modified skin.
Downstream skeleton poses can be set from that callback. Parent/external
attachments with `override_pose = false`, local camera offsets and cuts are covered.
This is a unit-scale, full-influence, undamped custom head look. Built-in IK/LookAt
chains, partial influence, stateful/damped modifiers, ragdolls, physics interpolation,
other import/retarget pipelines and long temporal histories still need validation.
Custom deferred code that changes bones after camera synchronization is outside
this sampling contract. See the repository's `docs/modifier-capture.md` and
`docs/imported-characters.md` for the fixtures, commands and evidence.

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

`tests/skeletal_checks.gd` checks all six camera transforms over moving, cut and
repeated samples, including external attachments. `tests/skeletal_review.py`
compares actual PNG and decoded MP4 frames against an independently positioned
camera and CPU-deformed mesh in a disposable project. Under TAA it compares the
camera paths using identical native skinning on both sides, because rebuilding a
CPU mesh has a different motion-vector history.

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
