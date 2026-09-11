# Baked lighting, intersecting transparency and persistent history

This bounded review combines the saved LightmapGI room, a moving dynamic probe
receiver, eight lit alpha surfaces arranged in four intersecting pairs, and a
camera compositor with independent history for each view. It extends the
individual [lightmap](lightmap-capture.md) and [temporal](temporal-capture.md)
fixtures. Dated acceptance and package mappings belong in [validation](validation.md).

Native Windows / Godot 4.7.2 / RTX 3060 Ti / Vulkan acceptance passes on
Forward+ and Mobile: **16 clips / 2,304 source and decoded frames**, including
four correctly rejected lighting/history controls. The exact package passes
1,025 headless/failure checks and rebuilds identically. See [validation](validation.md)
for its hash, source mapping and remaining release gates.

![Forward+ combined scene, disabled effects and intentionally incorrect lighting/history controls.](media/combined-forward.jpg)

*Frames 0, 71, 72 and 143. The last two rows are deliberately incorrect and are
rejected; [Mobile comparison](media/combined-mobile.jpg) and
[sheet provenance](media/combined-provenance.json) are retained too. The visible
afterimage at the cut is intentional authored compositor behavior.*

## Contract and controls

Each clip delivers 144 frames at 1024×512 / 30 FPS, with 256-pixel face cores,
12.5% borders and eight warmup draws. The camera moves continuously in position
and rotation, with a cut at frame 72. The moving sphere crosses side faces and
the rear seam. Both worlds use authored exposure 1.0. The compositor retains
95% of the preceding result on every draw, extending its visible history well
beyond the earlier 65% fixture. Its history intentionally persists across the
cut, matching the independent native effect's behavior.

The reference instantiates the same immutable saved bake in a second World3D.
Six independent perspective cameras have their own compositor resources and
histories. A seventh view straddles the front/right edge. Every draw records
world isolation, camera poses, viewport settings, static lightmap users, dynamic
GI modes, panel transforms, authored exposure and actual compositor call counts.

| Case | Required result |
| --- | --- |
| All effects enabled | Match the independent native references and decoded delivery. |
| Lightmaps disabled | Match a correspondingly disabled reference and visibly differ from the enabled room. |
| Sphere probes disabled | Isolate the moving receiver's indirect lighting. |
| Transparency disabled | Demonstrate visible contribution from the intersecting surfaces. |
| Transparency unlit | Demonstrate that those surfaces receive lighting. |
| History disabled | Demonstrate visible afterimages during motion and around the cut. |
| Captured lightmap missing | Reject against the intact independently lit reference. |
| Captured history shared between faces | Reject against independent per-view histories. |

All source faces and source panoramas are checked. A CPU projector constructs
the reference panorama, which is independently encoded and fully decoded against
the delivered MP4. The existing thresholds remain: face MAE below 0.15 and p99
at most 2, panorama MAE below 0.2 and p99 at most 2, decoded RMS below 2, all on
the 0–255 RGB scale. Every clip must pass all thirteen pipeline delivery checks,
retain every frame, reject a delayed reference and contain no graphics/script
errors. Incorrect controls must fail images while satisfying the other contracts.

Feature-presence thresholds were fixed before acceptance. Every enabled/disabled
panorama pair must differ by more than 1.0 levels for static lighting, 0.01 for
sphere probes, and 0.1 for transparent geometry and its shading. History must
differ by more than 0.02 in every moving frame after the opening. These whole-image
contribution measures do not measure artistic quality. The probe case changes
only the sphere's GI mode; the other geometry keeps its lighting.

## Reproduce

Use the [developer dependencies](testing.md), a native graphics device and a
fresh output directory:

```sh
python tests/combined_review.py --godot PATH_TO_GODOT --ffmpeg PATH_TO_FFMPEG --ffprobe PATH_TO_FFPROBE --output .godot360/combined-forward
python tests/combined_review.py --godot PATH_TO_GODOT --ffmpeg PATH_TO_FFMPEG --ffprobe PATH_TO_FFPROBE --method mobile --baked-from .godot360/combined-forward/project/generated --output .godot360/combined-mobile
```

The first command creates a saved editor bake unless `--baked-from` points to an
existing LightmapGI review's `project/generated` directory. Mobile uses authored
4x MSAA and sampled-input/writable-texture/copy-back compositing. The default
per-export deadline is 600 seconds; software workers can use 1200 or 1800.

`--analyze` verifies captured source/bake hashes and recomputes measurements
without rendering or rebuilding the oracle. Keep the original output and its
source snapshot. Each case retains native views, cube faces, sources, reference
video, delivery, per-frame measurements, capture settings and logs, including
failed attempts. `comparison.jpg` shows frames 0, 71, 72 and 143 for every case.

The manual **Combined rendering** workflow runs both methods from an unpacked
package on Linux software Vulkan. It has a longer budget for this eight-case
matrix and retains reports, bake assets and failure progress. A prepared workflow
does not establish a hosted result or native Linux GPU support.

## Appearance boundary

This tests capture preservation for one small scene and this authored effect.
Independent perspective views can sort intersecting alpha surfaces differently;
per-face histories can also differ across a join. The diagonal-view and boundary
strip errors are observations, not seamlessness thresholds. Borders blend the
overlap; they cannot make all view-dependent histories or alpha ordering agree.
Inspect the sphere during motion and cuts, and adjust intersecting geometry,
material strategy or the effect's view/history behavior when artifacts matter.

The warmup draws settle the stationary opening; they do not simulate a long
particle pre-roll or reset arbitrary custom histories at camera cuts. Bake and
save static lighting before capture, cover dynamic paths with probes, keep
exposure authored and use a compositor that owns history per view. This review
does not add general shader/IK compatibility, larger GI layouts, glow/SSR/fog/DOF
acceptance, production 4K/8K budgets, or native Linux/Mac GPU coverage.
