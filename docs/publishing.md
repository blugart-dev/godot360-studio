# Preparing a public release

Repository preparation and product acceptance are separate checks. The current
source uses version **0.8.0** as a development baseline. Complete the
[1.0 acceptance criteria](release-readiness.md) before describing it as a stable
release. The [preparation review](publication-review.md) records the current cleanup.

## Source and rights

- Run `python tools/repository_review.py --output .godot360/publication-review/inventory.json`.
  It inventories tracked and non-ignored files, hashes every payload, checks
  portable Markdown links and scene references, parses Python/JSON/SVG, validates
  WAV data and compares documentation media with its provenance. It rejects
  private paths, common credential formats, local artifacts and assets over 25 MiB.
  This is a bounded check, not a full Markdown parser or a comprehensive secret scanner.
- Review `git status --short` and `git diff --check`. Include intended source and
  engine `.uid`/`.import` sidecars; exclude caches, tools, settings and full renders.
- Keep the root MIT license and [third-party notices](../THIRD_PARTY_NOTICES.md).
  Preserve Cesium's attribution/mark notice and the GeneralUser sample-source terms.
- Scan the exact source snapshot and intended Git history with Gitleaks, using
  `--redact`. Keep scan reports local. For example:

  ```sh
  gitleaks git . --redact --log-opts="main --tags" --report-format json --report-path .godot360/publication-review/history-secrets.json
  ```

  Review commit identities and personal paths separately: secret scanners do not
  treat every private filename, email address or video link as a credential.

Historical versions of `docs/next-session.md` contain personal workstation paths.
The current file is portable, but an ordinary commit does not remove its earlier
versions. Before changing the existing repository's visibility, explicitly review
those historical paths. Use a reviewed source-only snapshot for a new public
repository if history is not needed, or prepare and verify a sanitized history
with a backup and coordinated migration. Never force-push a history rewrite as
routine release housekeeping. Inspect every ref intended for publication.

## Candidate and verification

Use fresh output paths and the same Python environment for build and review;
different zlib versions can produce different compressed bytes from identical
payloads. Build the addon ZIP from the final source:

```sh
python tools/package_addon.py --output .godot360/publication-candidate.zip
python tests/package_review.py --package .godot360/publication-candidate.zip --godot PATH_TO_GODOT --ffmpeg PATH_TO_FFMPEG --ffprobe PATH_TO_FFPROBE --output .godot360/publication-candidate-review
```

The reviewer extracts the exact archive, verifies every manifest entry, rebuilds
identical bytes and tests clean projects. Run the native platform/renderer checks
required by the declared release matrix; retain the resulting logs and images.
Headless and software-rendered CI have the narrower scope recorded in
[testing](testing.md). The lightweight **Repository hygiene** workflow checks source
and package reproducibility on every pull request and main-branch push; it does
not establish native rendering support.

For a source distribution containing the creative examples, use:

```sh
python tools/package_source.py --output .godot360/publication-source.zip
```

This freezes the checked tracked/non-ignored files, including intentional new
files, with a manifest and no Git history. Review the inventory before sharing it.
Import its extracted `project.godot` in a clean Godot environment, then try the
main scene, example recipes and one short addon export. A source archive does not
clear the existing repository's historical privacy review.

## Final public-facing review

- Match version strings, changelog, package filename and release notes to the
  actual candidate. Keep older validation records labeled as historical evidence.
- Follow the quick start on a clean checkout. Check examples, relative links,
  preview playback, credits, issue forms and the security reporting route.
- Enable GitHub private vulnerability reporting before relying on the private
  report link in `SECURITY.md`. Confirm Issues and Actions settings suit the project.
- Attach the tested ZIP and its checksum/manifest. Keep source masters and local
  diagnostic bundles out of the release. Publish support claims only for the
  combinations actually reviewed.
- Obtain the owner's final publication authorization before changing repository
  visibility, uploading release assets or submitting the addon to an asset catalog.

The preparation tools build local artifacts only. They do not change repository
visibility, publish releases, upload videos or submit an Asset Library entry.
