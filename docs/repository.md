# Repository contents

Godot360 Studio is the editor addon in `addons/godot360/`. UMBRAL, THRESHOLD,
LUMEN and AFTERGLOW are creative examples made with it. The checkout folder can
have any name; no machine-specific location is required.

## Source layout

| Location | Purpose |
| --- | --- |
| `addons/godot360/` | Self-contained addon, user guides, example scenes, original MIT notice and panel screenshot. Copy this folder into another Godot project. |
| `assets/` | Original SVG artwork, film shaders and included WAV soundtracks. AFTERGLOW's sample-source notice is retained beside its score. |
| `scenes/` | Main UMBRAL installation, UI/target scenes and three film scenes. |
| `scripts/` | Installation behavior, procedural geometry, gaze interaction and film choreography. |
| `export_profiles/` | Portable editor recipes. Select local tool paths and output folders after loading one. |
| `tests/` | Contract checks, media reviewers and isolated scene fixtures. Cesium Man carries its own attribution and license notices. |
| `tools/` | Packaging, repository checks, original score generators, rendering/media helpers and loopback preview players. |
| `docs/` | Illustrated guides, validation evidence, development records and release preparation. |
| `.github/` | CI workflows, issue forms and the pull request template. |
| Root files | Godot project configuration, MIT license, third-party notices, contributor/security guidance, development dependencies and formatting rules. |

Godot source `.uid` and `.import` sidecars are versioned so resource identity and
import settings survive a fresh checkout. `.godot/` is a generated cache and must
not be committed. Documentation media uses `.gdignore` to keep previews out of
Godot's asset importer.

## Media and dependencies

The original THRESHOLD, LUMEN and AFTERGLOW stereo WAVs belong in source because
the examples use them directly. Curated stills and compact video previews belong
in `docs/media/`; the addon carries only its small illustrated-guide screenshot.
[Media provenance](media/README.md) describes sources, hashes and regeneration.
The source-file budget is 25 MiB per asset. Full film masters and frame sequences
are generated locally rather than distributed in Git.

The addon requires external Godot, FFmpeg and FFprobe executables. Python with
`requirements-dev.txt` is only for development/media review. AFTERGLOW's optional
score regeneration has additional dependencies documented in its [guide](afterglow.md).
Tools and their binaries are not bundled in the addon or source archives.

All original project content is [MIT licensed](../LICENSE). Preserve the separate
[third-party notices](../THIRD_PARTY_NOTICES.md), including those for the test model
and instrument samples.

## Local-only folders

- `.godot360/`: settings, downloaded tools, diagnostic reports and disposable reviews.
- `renders/`: full film masters, frame sequences, player copies and export jobs.
- `.godot/`: generated Godot import/editor data.
- `dist/`: locally built archives and checksum records.
- `.agents/`, `.codex/`, virtual environments, Python caches, logs and editor state.

These locations are ignored. Empty editor-template folders are also local until
actual templates are intentionally added; Git does not preserve empty folders.
Never force-add credentials, local evidence bundles or downloaded executable files.
Ignoring a file does not remove older committed versions.

## Verification and distribution

Run `python tools/repository_review.py` to inspect every tracked or non-ignored
file, including newly created source. The optional JSON output contains a
per-file SHA-256, size, folder inventory and findings. CI runs the same check,
its regression tests and a reproducible addon build.

`tools/package_addon.py` creates a ZIP with installation instructions, the addon,
license, developer dependencies, optional test sources and an exact manifest.
`tools/package_source.py` creates a checked source snapshot with the examples
and no Git history. Neither command publishes anything.

The [publication checklist](publishing.md) covers the final candidate, native
validation, history/privacy review and repository settings. Historical development
records identify local evidence by relative path; those files are not downloadable
from this source tree. Original pre-rename commit references may identify archived
local history. Use the [migration guide](../addons/godot360/MIGRATION.md) when upgrading
an addon that still uses the old Umbral360 folder name.
