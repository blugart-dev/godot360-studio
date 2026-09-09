# Cesium Man test asset

Cesium Man, copyright 2017 Cesium, licensed under
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).
The original Cesium logo remains subject to the separate upstream mark notice.
This asset is a test fixture; it is not Godot360 branding or an endorsement.

- Source: [Khronos glTF Sample Assets](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/81e8b567643b5166e6ff40024e4ff71ad4b18676/Models/CesiumMan).
- Original file: `Models/CesiumMan/glTF-Binary/CesiumMan.glb`.
- Pinned revision: `81e8b567643b5166e6ff40024e4ff71ad4b18676`.
- SHA256: `b7001eaeea8254bd44773bcd247e78696d94169388fbb2a1800fc69434e777d9`.
- The GLB and upstream `LICENSE.md`, `metadata.json`, and
  `LicenseRef-LegalMark-Cesium.txt` are unmodified. The license's relative mark
  link resolves to the notice included here as `LicenseRef-LegalMark-Cesium.txt`.

The review uses the normal Godot scene importer. Only its disposable project
disables animation optimization, immutable-track removal, mesh compression and
LOD generation to compare directly with the raw glTF animation/vertex data.
Its animation import bake FPS matches the compared export FPS (30 or 60).
It adds a head-attached camera boom, surrounding markers and a cut at frame 30.
The primary comparison overrides the material with an unlit orange material;
the `--textured` camera comparison retains the original material and texture.
CPU reference geometry and documentation images are derived from this asset.

The independent evaluator in `tests/gltf_reference.py` covers the source's
19 joints, 57 LINEAR TRS channels, 3,273 vertices and weighted triangle mesh.
It is fixture-specific, not a general glTF loader.
