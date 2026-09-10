# Publication preparation review

Prepared on 2026-09-10 for the pre-1.0 source. This review prepares the repository
and local distributions; the [1.0 product acceptance criteria](release-readiness.md)
remain open. Nothing was published and repository visibility was not changed.

## Coverage and changes

Every tracked or non-ignored file is inventoried and hashed by
`tools/repository_review.py`, including the existing uncommitted AFTERGLOW work.
The review combines automated source/resource/link checks, a clean Godot import,
media inspection and the addon's existing regression suite. It is not a claim of
line-by-line formal verification or support for every possible scene and GPU.

| Area | Review and preparation |
| --- | --- |
| Root configuration | Preserved Godot project settings. Added the repository MIT license, third-party notices, contribution/security policies, `.editorconfig` and optional pinned Python review dependencies. Expanded binary attributes and local-file exclusions. |
| `addons/godot360/` | Preserved runtime behavior and the original MIT notice. Added generated missing UID sidecars. Packages now carry an installation README, root license, review dependency pins and test UID sidecars. |
| `assets/` | Validated the three stereo WAVs and SVG syntax; preserved original scores/cues, shaders and artwork. Documented the GeneralUser sample source and optional panorama attribution. |
| `scenes/`, `scripts/`, `export_profiles/` | Checked exact-case resource references and imported the complete project in a fresh Godot 4.7.2 environment. Added missing source UID sidecars without changing scene choreography or recipes. |
| `tests/` | Retained the existing fixture/review suites and upstream model/license bytes. Corrected the local Cesium notice link. Added regression tests for the new repository guard. |
| `tools/` | Added source hygiene and source-archive builders. Improved addon package contents and compression-runtime diagnostics. Updated the AFTERGLOW documentation encoder to enforce the source media budget. |
| `docs/` | Replaced links to ignored local artifacts with explicit local paths and usable guides. Removed personal workstation locations, rewrote the repository map and added the publication checklist. Historical evidence remains identified as historical. |
| `docs/media/` and addon guide image | Inspected image integrity and metadata and fully decoded source audio/video. Reduced AFTERGLOW's documentation video from 55,663,298 to 19,569,218 bytes, retaining the exact encoded audio. The 900p local preview and 4K master are preserved. |
| `.github/` | Added bug/feature forms, a pull request template and a repository hygiene workflow. Existing media workflows now install the same pinned development dependencies. No workflow publishes a release. |
| Local-only folders | Kept `.godot/`, `.godot360/`, `renders/`, `dist/`, caches, tools and settings excluded. Empty editor-template directories are preserved locally and add nothing to Git. |

## Verification evidence

Local evidence is retained under `.godot360/publication-review/`; it is not included
in source distributions. The final source archive contains `SOURCE-MANIFEST.json`
with per-file sizes and hashes. Run the commands in [publishing](publishing.md) to
produce equivalent evidence from a new checkout.

- The repository guard passes for **425 files**, **482 local Markdown links** and
  **21 recorded media hashes**. Its seven regression tests also pass.
- The final 213-member addon ZIP passes **1,139 checks** on Windows 11 / Godot
  4.7.2 / Compatibility, including rendered exports, audio, spherical playback,
  recovery, storage failures and the documented first-export workflow. Its
  manifest, identical rebuild and unchanged extracted payload pass. The archive
  is `dist/publication-preparation/godot360-studio-0.8.0.zip`, SHA-256
  `8e1f62e23c7ced5f64bf61192560bbfb1fb49c8e2fecbcc0a2c3dfff0e9e8697`.
- Additional source-scene checks pass: UMBRAL **48**, THRESHOLD **60** and
  AFTERGLOW **107**, all with zero failures. All three browser players' embedded
  JavaScript passes Node's syntax check; AFTERGLOW's duplicated carriage returns
  were normalized without changing its script.
- A complete clean Godot 4.7.2 headless import exits successfully without script
  errors; it generated 36 missing source UID sidecars. This Windows sandbox logs
  a system certificate-store warning, which is unrelated to scene/script parsing.
- All 38 repository raster-image/audio/video files pass integrity or full decode
  checks. The 32 raster images contain no EXIF metadata. All three documentation
  MP4s carry stereo AAC; the reduced AFTERGLOW preview retains all 1,800 frames.
- The history credential scan covers 28 commits reachable from `main` and tags
  with zero Gitleaks findings. Commit identities use a GitHub noreply address.
  History still contains personal paths, as described below; a credential scan
  does not establish complete privacy.
- Archive reproducibility is checked using the same Python/zlib runtime. A
  preliminary comparison across the two installed Python runtimes produced
  different compressed bytes but identical payloads; the build report now records
  the compression runtime and the instructions explain that requirement.

## Before public publication

1. Review personal paths in historical `docs/next-session.md` revisions before
   exposing the existing Git history. The current source has been cleaned. The
   prepared source-only archive avoids carrying that history; existing branches
   and tags have not been rewritten.
2. Retain the GeneralUser notice, which describes uncertainty about some historic
   sample origins, and the Cesium model's attribution and mark notice. MIT covers
   original project work; third-party source terms remain separate.
3. Complete the remaining native platform, rendering, endurance and final workflow
   acceptance in [release readiness](release-readiness.md). This cleanup does not
   promote the development baseline to 1.0.
4. Run the new workflow after pushing the final source, confirm the GitHub issue
   and private vulnerability-reporting settings, and approve the exact public
   candidate. No hosted CI result or repository setting change is claimed here.

[Publication checklist](publishing.md) · [Developer verification](testing.md)
