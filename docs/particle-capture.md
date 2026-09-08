# Particle capture and authored pause states

Capture now preserves a scene's authored processing mode. Previously, it forced
the root to `INHERIT` at startup and after every captured frame: disabled scenes
began running, and scenes that paused themselves resumed on the next frame.
Warmup now restores the saved mode once. Zero warmup does not change it.
Scene notes flag short particle warmup and the known Compatibility CPU startup
defect so these limits are visible when reviewing an export.

The new fixture checks CPU and GPU particles in the shared 3D world, with eight
opaque colored spheres moving through cube-face boundaries. A separate scene
places ordinary meshes at the analytically expected positions. The reviewer
compares every retained PNG and every decoded MP4 frame.

![GPU particles, CPU particles and analytic mesh references at the opening, crossing and end.](media/particle-capture.jpg)

*Each column shows the same output frame. The flat view looks toward a cube edge
at 45° yaw. These are rendered views of the export, with no synthetic particle art.*

## Tested behavior

The reference uses constant unit velocity, one particle per emitter, opaque sphere
meshes, no gravity or collisions, **particle Fixed FPS = 0**, GPU interpolation off
and fixed GPU seeds. The scene runs once per movie frame; all six cameras see the
same simulation. The first delivered native simulation sample is one frame interval
after emission, followed by one interval per frame. This differs from a property's
absolute timeline sample at time zero.

The normal comparison uses eight warmup frames, with another GPU export at ten
frames and an authored `ALWAYS` root. Mode checks also cover a `DISABLED` root,
`WHEN_PAUSED` while the tree is unpaused, zero warmup, and a CPU scene that disables
itself at frame 15. The latter must stop both script ticks and visible particle
movement. The old worker fails all four mode cases, providing a negative control.

See [validation](validation.md) for the accepted native engine/renderer matrix,
exact counts, package hash and CI results. This small test establishes these
particle cases, not general particle-effect compatibility.

## Startup and fixed-step limits

Two exploratory runs exposed startup and timing differences. A zero-warmup export
could begin with missing particles or show them in only some directions. Two
warmup frames also produced an opening difference from the settled reference.
A GPU emitter with a separate fixed 30 Hz step repeated a particle step in a
30 FPS export, while the same constant-velocity CPU case matched its reference.
In Compatibility, the CPU emitter is missing from the first delivered frame even
with eight warmup frames, then matches the reference for the remaining 59 frames.
That startup defect remains open; Compatibility appearance coverage is limited
to GPU particles. These observations remain recorded; the tests do not silently
accept them as exact timeline matches.

For a particle scene, try **8–10 warmup frames** in the recipe Inspector and
review the opening and motion. Adjust particle Fixed FPS/interpolation in the
authored scene if needed. The addon preserves those choices. Warmup holds ordinary
scene processing and does not create a mature effect: emitter preprocessing or a
deliberate authored pre-roll requires its own review. Explicit child process modes
and autoloads follow Godot's normal rules.

GPU randomness needs the emitter's own fixed seed; the job's global random seed
does not configure it. Preprocessing, random emission, trails, transparency,
billboards, collisions, subemitters, moving/animated emitters, temporal antialiasing
and long histories remain outside this analytic fixture's coverage. Repeatability
across engines or GPUs is not claimed. See the portable
[authoring guidance](../addons/godot360/AUTHORING.md#particle-simulation-and-processing-modes)
and Godot's [particle property reference](https://docs.godotengine.org/en/4.5/classes/class_gpuparticles3d.html).

## Reproduce the review

From the checkout or unpacked addon package, with NumPy/Pillow installed and a
working graphics backend:

```sh
python tests/particle_review.py --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/fresh-review --method forward_plus --driver vulkan --lifecycle
```

Use `--method mobile --border 12.5` for the bordered Mobile case, or
`--method gl_compatibility --driver opengl3 --gpu-only`. The basic run exports four two-second
2K clips; `--lifecycle` adds four processing-mode clips. `--zero-warmup`,
`--short-warmup` and `--fixed-step` add observations against the settled reference.
`--gpu-only` omits CPU appearance comparison, retaining CPU processing-mode tests
when `--lifecycle` is selected. Omitting it in Compatibility reproduces the known
CPU startup failure. Those observations have their own `ok` fields under `startup` and do not gate the
eight/ten-frame continuous-step cases. `--lifecycle-only --baseline-worker PATH`
checks the old worker against the processing contract and must fail.

The reviewer uses foreground errors as well as whole-image errors so missing or
late small particles cannot pass by being surrounded by empty background. Source
and decoded comparisons accept <0.03 and <0.1 mean RGB error respectively, with
>200 foreground pixels and <0.25 foreground error, all on a 0–255 scale.

[Testing](testing.md) · [Remaining 1.0 work](release-readiness.md)
