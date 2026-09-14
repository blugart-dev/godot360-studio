# Publication review

## Public films and completed CI — 2026-09-14

The owner published **THRESHOLD, AFTERGLOW, LUMEN and UMBRAL** on YouTube.
All four watch pages and the [playlist](https://www.youtube.com/playlist?list=PLUjBgihWYNpQ)
open in a signed-out browser, with matching film titles and spherical navigation
controls. [Public links and viewing-check scope](youtube-publication.md#public-films)
are now linked from the README, showcase and film guides. No YouTube edits were
performed by the project sweep.

All seven tagged-source workflows in the publication table below have now
completed successfully. This includes both **Mobile and Forward+** in
[Temporal rendering](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801707),
and the Linux rendered/Mac headless jobs in
[Desktop platforms](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801683).
The later [main documentation check](https://github.com/blugart-dev/godot360-studio/actions/runs/34781126364)
also passes. These results do not explain or erase the recurring earlier Linux
Mobile history mismatch, or establish native Linux/Mac GPU support.
The original publication-time table below retains its dated in-progress states.

## Published 1.0.0 — 2026-09-13

**[Repository](https://github.com/blugart-dev/godot360-studio) public; [1.0.0 release](https://github.com/blugart-dev/godot360-studio/releases/tag/v1.0.0) published.**
Publication time: **2026-09-13T20:28:46Z**. The release is stable, marked latest,
and has four verified uploaded assets. `main` was fast-forwarded to the tested
source; annotated tag **`v1.0.0`** points to
**`d2a687d1d30d8fe8a7375ee27b64eb5f50179c93`**. This completion receipt follows that frozen
artifact commit and does not move the release tag or rebuild published downloads.

The owner explicitly authorized publication and chose **preserve the reviewed
history**. Existing commits and tags are retained; no force-push or history
rewrite was performed. Six historical planning-document blobs contain reviewed
workstation paths. Redacted Gitleaks scans found no credentials in all **50
commits** at the release source or in the exact extracted public source archive.
The prepublication Git bundle was verified and retained locally.

### Published downloads

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `godot360-studio-1.0.0-source.zip` | 75,865,372 | `2b5c7aa1e899069966397c879dfc20a1b9820c300416f3372d124e260ad85a61` |
| `godot360-studio-1.0.0.zip` | 884,590 | `e9ee8e602add276f8958ee738d57b3f6f688ffd1e495b6be0f2fa21426fe6020` |

`SHA256SUMS.txt` also verifies the portable `release-manifest.json`. The addon has
245 members; the dedicated source ZIP has 497 members, including its verified
source manifest and no Git history. GitHub's automatic source archives are separate.
Both dedicated archives come from the tagged source commit above.

### Verification and support

- Fresh public addon: **1,214** native Godot 4.7.2 Compatibility/OpenGL 3 package
  checks and **52** native editor checks across first launch/reopen, all passing.
- Fresh public source: clean import/startup and **247** scene/rendered-workflow
  checks; all **101** protected creative/project/fixture files unchanged.
- Both archives reproduce identical bytes. Compared with the private stable
  snapshots, 238 addon members and 478 source members are byte-identical; only
  Markdown and generated manifests changed. All runtime, tests and fixtures match
  the accepted five-lane Windows runtime (**6,070** package checks and 52 editor checks).
- All 13 packaging/repository regression tests pass. Repository hygiene passes
  on the [release preparation commit](https://github.com/blugart-dev/godot360-studio/actions/runs/34780450398)
  and [main push](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801697);
  hosted builds reproduce the public addon checksum.
- Anonymous access confirms the public repository, release, security policy and
  issue chooser. All four actual downloads were fetched without authentication
  and matched their tested local bytes, GitHub asset digests and checksum file.
- Private vulnerability reporting was enabled after the visibility change and
  verified through its API (`enabled: true`). Issues remain enabled; the repository
  description, homepage and topics now describe the released addon.

**Windows is supported; Linux/macOS remain experimental.** The unresolved Linux
software-Mobile first-five-frame history mismatch and unchanged test thresholds
remain documented. Windows Mobile temporal evidence passes separately. No new
YouTube/headset or broader hardware acceptance is inferred from publication.
See [support](../addons/godot360/SUPPORT.md) and [validation](validation.md).

### Hosted checks on the tagged main source

This is the publication-verification snapshot. Follow each run for its final
result; in-progress experimental renderer jobs are not reported as passed.
They supplement the completed native Windows and exact-download acceptance above.

| Workflow | Publication-verification status |
| --- | --- |
| [Baked LightmapGI](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801687) | In progress at publication verification |
| [Combined appearance](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801649) | In progress at publication verification |
| [Complex particles](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801634) | In progress at publication verification |
| [Imported characters](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801733) | success |
| [Desktop platforms](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801683) | In progress at publication verification |
| [Temporal rendering](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801707) | In progress at publication verification |
| [Repository hygiene](https://github.com/blugart-dev/godot360-studio/actions/runs/34780801697) | success |

Local detailed evidence is retained under `.godot360/publication-1.0-20260913/`;
diagnostic bundles, workstation-specific build reports and render masters were
not uploaded. Release assets contain portable checksums/metadata and licensed
source. Earlier preparation records below retain their original dates and scope.

## Frozen RC2 publication review — 2026-09-13

The reviewed source is **1.0.0-rc.2**, following the native-help and startup-cancel
fixes. A read-only GitHub check confirms the repository remains private, with
`main` as its default branch and no open issues or pull requests. RC2 repository
CI passes and reproduces the local addon bytes. Gitleaks finds no credentials
in the exact extracted source or **45 commits across all local refs**. The path
review covers **977 unique text blobs** and still finds personal workstation
paths in **six older versions of `docs/next-session.md`**. All author/committer
identities use GitHub noreply addresses; no history or refs were rewritten.

The RC2 source archive contains **497 members**, including its manifest and no
Git history. It rebuilds identically, imports/starts cleanly, passes scene checks
and preserves all **101 protected creative/project/fixture files**. Artifact
hashes and native Windows evidence are in [validation](validation.md).
The dated sections below retain their original versions and counts.

Human candidate acceptance, the public-history choice and final publication
authorization remain open. No visibility change or release upload is part of
the private candidate review.

## Windows release preparation — 2026-09-13

The private stabilization branch now has a consolidated
[Windows support contract](../addons/godot360/SUPPORT.md),
[upgrade guide](../addons/godot360/MIGRATION.md) and
[1.0 release draft](release-1.0.md). The five target Windows combinations and
scene/effect limits are explicit. Version remains 0.8.0 while human walkthrough
and final candidate acceptance remain open.

At preparation commit `da96a39763711e94114422c2263ed7efed48eaa7`, a fresh
Gitleaks scan of **41 commits across all local refs** finds no credentials.
A separate scan of the exact extracted source also finds no credentials.
All author/committer identities use GitHub noreply addresses. A bounded review
of **914 unique historical text blobs** finds personal workstation paths in
**six blobs**, all older versions of `docs/next-session.md`. The local report
maps their blobs and reachable commits; no history or refs were rewritten.

The canonical Git source produces an addon ZIP with **242 members**, including
the support contract, and a source ZIP with **494 members**, including its source
manifest. Both rebuild identically with the same Python/zlib runtime. The source
ZIP contains no Git history. Exact hashes, extracted-source checks and mapping to
the existing Windows runtime evidence are in the latest [validation record](validation.md).

Read-only GitHub inspection confirms private visibility, Issues enabled, Actions
enabled, Discussions disabled, and no protection on the two existing branches.
The private vulnerability-reporting endpoint returns **HTTP 404** and
`security_and_analysis` is unavailable; private reporting is **not confirmed**,
not assumed enabled or disabled. The existing security policy provides a fallback
request for a private channel without disclosing exploit details. Confirm the
actual private-report route during authorized publication. GitHub's
[current instructions](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)
scope the feature to public repositories. The 404 is consistent with that scope,
but is not by itself proof of the reason; activation and verification follow
the authorized visibility change. This does not block private RC validation.
No repository setting was changed.

Remaining publication decisions are the final accepted package, whether to expose
the reviewed historical paths or use a reviewed source-only public history, and
the final public issue/security settings. The source-only archive provides a
concrete option without altering the private repository. Publication still needs
the owner's final authorization after product acceptance.

Local reports, source snapshots and both archives are retained in
`.godot360/release-preparation-20260913/`. The following sections preserve the
earlier 2026-09-10 review and its original counts and package identities.

## Original publication cleanup — 2026-09-10

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
