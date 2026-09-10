# Repository and local files

The project is **Godot360 Studio**. Its addon folder is `addons/godot360`; local
settings, tools and validation output live in `.godot360`. Project configuration,
scenes, recipes, tests, documentation and package contents use those paths.
UMBRAL, THRESHOLD and LUMEN are the names of the creative examples.

Older installations should follow the [folder migration guide](../addons/godot360/MIGRATION.md).
The original name remains only where needed for migration, original copyright
attribution, ignore rules and historical release/validation records. Old Git tags
preserve the source layout of their releases.

The outer local checkout is still named `Umbral360`: Windows refused to rename
it while the workspace was in use. Once Codex/Godot are closed, the local helper
`.godot360/naming-review/Rename-LocalCheckout.ps1` renames it to `Godot360Studio`
and updates saved absolute paths. Its syntax and `-WhatIf` preview were checked;
the actual outer-folder move remains pending. Reopen the new folder in Codex and
Godot afterward. This machine-local folder name is not part of GitHub's tree.

The private source repository is
[blugart-dev/godot360-studio](https://github.com/blugart-dev/godot360-studio), created
with GitHub CLI on 2026-09-07 after the user selected the name and authorized the
upload. GitHub confirmed the owner and private visibility before source upload.
Public addon/video releases require separate authorization. GitHub CLI is used
for account/repository operations and authentication.

## Upload contents

Source code, Godot scenes/resources, shaders, SVG artwork, documentation, tests,
portable export recipes and the original THRESHOLD/LUMEN WAVs and score generators
belong in Git. The WAVs are required original project assets, approximately
11.5 MB and 4.6 MB respectively.

Curated previews in `docs/media/` and the small panel screenshot in
`addons/godot360/media/` also belong in Git. They let readers see the tool and its
results without rendering first. The full film masters and source frames remain
local under `renders/`. [Media provenance and regeneration](media/README.md)
documents the selected excerpts, sizes and source hashes. Documentation media
folders use `.gdignore` to avoid importing promotional media as scene assets.
The addon package includes its illustrated-guide PNG; full video/GIF previews
are confined to repository documentation.

The following remain local and ignored:

- `renders/`: source frame sequences, MP4 deliveries, previews and job output.
- `.godot360/`: studio settings, tool executables, diagnostics, audit reports,
  local history backups and disposable validation projects.
- `.godot/`, `.agents/`, `.codex/`, Python caches and temporary files.
- `dist/`, downloaded archives, executable files and logs.
- Environment secrets, signing/private keys and export credentials.

Git ignore rules do not remove files already committed. The first-upload audit
therefore examines the complete histories of `main`, `v0.7.0` and `v0.8.0`, not
just the current directory. Only those branch/tag refs are intended for upload;
editor-owned auxiliary refs are local.

## First-upload privacy audit

The initial audit found no Gitleaks credential findings. Manual/history checks
identified personal commit emails and an older private-video URL in the validation
notes. The upload history replaces author/committer emails with the account's
GitHub noreply identity and removes that video URL from every historical revision.
Commit chronology, messages, branch/tag structure and all other file contents are
preserved. The prepared history's current source tree was verified identical to
the reviewed working source. The cleaned history passed Gitleaks with zero
findings and the full file/history inventory with no excluded paths, personal
commit identities, private-video links or unexpected binary assets.

A verified original-history bundle and the original-to-clean commit mapping remain
under `.godot360/github-publish/`. Privacy changes alter commit IDs; original IDs
quoted in historical development records refer to that local backup. Existing
release ZIPs remain local and unchanged. Tags preserve their historical source
versions and naming, while `main` contains the Godot360 branding change.

The scanner is the official Gitleaks 8.30.1 Windows release, checked against its
published SHA-256 manifest. Its reports and the additional file/history inventory
are local. Scans are detection evidence, not a guarantee against every possible
secret. Future uploads should review `git status`, staged changes and history;
never force-add local settings, audit bundles, renders or credential files.

## Rename validation

The initial display-name change passed 270 checks. The subsequent folder change
passed a full Godot 4.7.2 project import, all 60 THRESHOLD film checks and the
444-check exact-package suite, including exports, recovery, storage failures and
the documented calibration/Motion Lab workflow. Godot resource UIDs are retained
and newly generated source UIDs are versioned.

Evidence for folder migration lives in `.godot360/naming-review/`; the final
package review is under `final-package/review/`. The package is reproduced from
its own extracted source and verified against its manifest. Historical validation
paths now point into `.godot360`; archived projects retain their internal layout.
The older three-engine evidence remains in `release-0.8.md`; this folder-migration
run covers 4.7.2 and does not replace that historical certification.
