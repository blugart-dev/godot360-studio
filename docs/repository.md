# Repository and local files

The project is **Godot360 Studio**, previously Umbral360 Studio. The Godot project
name, editor plugin, bottom panel, rendering window, diagnostic label and metadata
producer now use Godot360. Existing `addons/umbral360` resource paths and
`.umbral360/settings.cfg` remain stable for compatibility with saved recipes.
UMBRAL and THRESHOLD remain the names of the two creative examples.

The user selected the name and authorized a private repository under
`blugart-dev/godot360-studio`. This is private source hosting, not a public addon
release or permission to publish a video. GitHub CLI is used for account/repository
operations and authentication. The working checkout keeps its existing disk path.

## Upload contents

Source code, Godot scenes/resources, shaders, SVG artwork, documentation, tests,
portable export recipes and the original THRESHOLD WAV/score generator belong in
Git. The WAV is a required original project asset, approximately 11.5 MB.

The following remain local and ignored:

- `renders/`: source frame sequences, MP4 deliveries, previews and job output.
- `.umbral360/`: studio settings, tool executables, diagnostics, audit reports,
  local history backups and disposable validation projects.
- `.godot/`, `.agents/`, `.codex/`, Python caches and temporary files.
- `dist/`, downloaded archives, executable files and logs.
- Environment secrets, signing/private keys and export credentials.

Git ignore rules do not remove files already committed. The first-upload audit
therefore examines the complete histories of `main`, `v0.7.0` and `v0.8.0`, not
just the current directory. Only those branch/tag refs are intended for upload;
editor-owned auxiliary refs are local.

## Privacy preparation

The initial audit found no Gitleaks credential findings. Manual/history checks
identified personal commit emails and an older private-video URL in the validation
notes. The upload history replaces author/committer emails with the account's
GitHub noreply identity and removes that video URL from every historical revision.
Commit chronology, messages, branch/tag structure and all other file contents are
preserved. The current reviewed source tree must match the prepared history exactly.

A verified original-history bundle and the original-to-clean commit mapping remain
under `.umbral360/github-publish/`. Privacy changes alter commit IDs; original IDs
quoted in historical development records refer to that local backup. Existing
release ZIPs remain local and unchanged. Tags preserve their historical source
versions and naming, while `main` contains the Godot360 branding change.

The scanner is the official Gitleaks 8.30.1 Windows release, checked against its
published SHA-256 manifest. Its reports and the additional file/history inventory
are local. Scans are detection evidence, not a guarantee against every possible
secret. Future uploads should review `git status`, staged changes and history;
never force-add local settings, audit bundles, renders or credential files.

## Rename validation

The renamed source passed an isolated Godot 4.7.2 plugin import, 251 existing
headless contract checks and 19 audio-panel checks, including two small exports.
The renamed addon package also passed inventory/content verification. The older
three-engine package evidence remains documented in `release-0.8.md`; the local
post-rename check does not claim a new complete three-engine release certification.
