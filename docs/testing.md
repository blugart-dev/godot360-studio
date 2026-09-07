# Developer verification

Run these commands from the repository root. For the user workflow, see the [quick start](../addons/godot360/QUICKSTART.md).

## First-export workflow

`tests/usability_checks.gd` exercises saved-scene camera discovery, inheritance and
instances without scene instantiation, camera ambiguity, editor save callbacks,
recipe restoration, malformed inputs, tool capabilities, stale readiness and output
write checks. It restores the previous local settings when finished.

```sh
godot --path . --script res://tests/usability_checks.gd -- --ffmpeg=/path/to/ffmpeg --ffprobe=/path/to/ffprobe
```

With a GPU it also saves `.godot360/usability-panel.png` for layout review. The same
checks run headlessly inside `tests/compatibility_review.py` and the exact-package
reviewer. `tests/release_workflow_checks.gd` covers actual calibration/Motion Lab
exports, recipes, preview directions and diagnostics. Use a fresh review folder.

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

It saves `.godot360/studio-preview.png` and a two-second calibration export under
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
[beta guide](../addons/godot360/BETA.md) gives exact coverage, clean-project steps,
reviewer commands and reproducible packaging with `tools/package_addon.py`.
Version 0.6.2 adds [failure recovery guidance](../addons/godot360/RECOVERY.md),
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
[authoring guide](../addons/godot360/AUTHORING.md#verification) for dependencies.

See [validation results](validation.md) for the tested environment and known
gaps. The addon carries its own MIT license and reference notes, so it can be
copied into another project. It has not been published to the Asset Library.

See the [performance record](performance.md) for measurements and the
[roadmap](roadmap.md) for the next production milestones.
The [development handoff](HANDOFF.md) records the current state and constraints
for continuing in a fresh session.
