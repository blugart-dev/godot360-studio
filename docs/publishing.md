# Preparing a public release

Version **1.0.0** has passed its Windows runtime acceptance. The owner authorized
publication and preserving the reviewed Git history on 2026-09-13. See
[release acceptance](release-readiness.md), [release notes](release-1.0.md) and
[publication review](publication-review.md) for the current record. Earlier
private-release holds are superseded by that explicit instruction.

Use the [support contract](../addons/godot360/SUPPORT.md) and
[upgrade guide](../addons/godot360/MIGRATION.md) with every release. The checklist
below also applies to subsequent versions; obtain authorization if a future
publication is outside the owner's instructions.

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

Six historical versions of `docs/next-session.md` contain personal workstation
paths. The current source is portable. The owner reviewed the history findings
and explicitly chose preservation for 1.0.0; retain existing commits and tags.
No force-push or history rewrite is part of this release. Review any newly added
refs and scan credentials before publication.

## Candidate and verification

Use fresh output paths and the same Python environment for build and review;
different zlib versions can produce different compressed bytes from identical
payloads. Build the addon ZIP from the final source:

The package builder accepts `M.m.p` and numbered `M.m.p-rc.N` identifiers. It
checks that plugin, panel, spherical metadata and addon README versions agree,
then derives the installation README's development/candidate/release label.
`python -m unittest discover -s tests -p package_addon_checks.py` verifies
candidate/stable labels and rejection of mismatched or malformed identities.

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

- Ensure the default branch and version tag contain the accepted source; use a
  fast-forward when bringing the stabilization branch to `main`.
- Update public-facing status and download links. If packaged guides change,
  rebuild and verify the archive, retain its new checksum, and map unchanged
  runtime/fixture hashes to recorded Windows evidence. Runtime changes require
  applicable fresh tests.
- Match version strings, changelog, package filename and release notes to the
  actual candidate. Keep older validation records labeled as historical evidence.
- Follow the quick start on a clean checkout. Check examples, relative links,
  preview playback, credits, issue forms and the security reporting route.
- Include private vulnerability reporting in the authorized publication steps:
  after the visibility change, enable it and verify the report route before
  announcing the release. Confirm Issues and Actions settings suit the project.
- Attach the tested ZIP and its checksum/manifest. Keep source masters and local
  diagnostic bundles out of the release. Publish support claims only for the
  combinations actually reviewed.
- Confirm publication is authorized before changing visibility or publishing a
  release. The owner explicitly authorized both for 1.0.0. Asset Library submission
  and external-service uploads are separate actions.

The preparation tools build local artifacts only. They do not change repository
visibility, publish releases, upload videos or submit an Asset Library entry.
