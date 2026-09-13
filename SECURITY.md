# Security policy

Godot360 Studio is validating its private 1.0 release candidate. Fixes target the current development
branch; historical 0.x snapshots do not have a separate security maintenance policy.

## Report a vulnerability privately

Use the repository's **Security → Report a vulnerability** option when available:
[start a private report](https://github.com/blugart-dev/godot360-studio/security/advisories/new).
If private reporting is unavailable, open an issue asking for a private reporting
channel, without exploit details, credentials or affected private files.

Include the affected version or commit, OS and tool versions, minimal reproduction,
expected impact and any suggested fix. Do not include personal projects or render
masters when a small synthetic fixture demonstrates the problem. There is no
guaranteed response time or bounty program.

## Local execution and diagnostics

Godot360 loads and executes the selected Godot scene and launches the configured
Godot, FFmpeg and FFprobe executables. Use trusted projects and tool binaries.
The addon does not download tools or automatically upload scenes, diagnostics or
finished videos. Its settings and jobs remain on the local machine.

The optional browser players bind to loopback and serve a fixed list of preview
files. They are development helpers, not public hosting servers. Stop them with
Ctrl+C after playback. Inspect diagnostics before sharing: paths, scene names,
tool output and project details may identify local work. See the
[diagnostics guide](addons/godot360/DIAGNOSTICS.md).
