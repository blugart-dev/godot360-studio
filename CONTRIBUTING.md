# Contributing to Godot360 Studio

Godot360 Studio 1.0.0 is released, with Windows supported and Linux/macOS
experimental. Start with [release acceptance and follow-up work](docs/release-readiness.md), [renderer limits](addons/godot360/RENDERERS.md)
and [developer setup](docs/testing.md). Discuss broad features before implementing
them so the supported scene and platform scope stays clear.

## Set up a checkout

1. Install Godot 4.7.2 Standard, FFmpeg and FFprobe using the
   [platform guide](addons/godot360/PLATFORMS.md).
2. Open `project.godot` and let the editor import the assets. The plugin is enabled.
3. For Python media checks, create the virtual environment described in
   [testing](docs/testing.md) and install `requirements-dev.txt`.
4. Run `python tools/repository_review.py` for source, links, resources and media hashes.

Keep settings, downloaded tools, render masters and test output in the ignored
`.godot360/` or `renders/` directories. Never commit credentials, local diagnostics
or personal absolute paths. Source `.uid` and `.import` sidecars belong in Git;
the generated `.godot/` cache does not.

## Make a focused change

Follow the surrounding GDScript/Python style and `.editorconfig`. Use English for
code, interface text and documentation. Keep public guides accurate about the
current behavior and retain third-party attribution. Avoid unrelated formatting,
new dependencies or changes to the creative examples when fixing addon behavior.

Use a minimal reproducible scene for a bug. Cover meaningful failure behavior and
run the tests relevant to the change; a documentation correction normally needs
the repository check, while capture changes need actual rendered evidence.
Headless tests cannot establish visual quality or native GPU support.

Before submitting:

- Run `git diff --check` and `python tools/repository_review.py`.
- Run the applicable checks in [testing](docs/testing.md), using fresh output folders.
- Build the addon with `python tools/package_addon.py --output .godot360/candidate.zip`
  when changing packaged files. Review the exact ZIP for runtime or release changes.
- Describe the problem, resulting behavior, checks run and any remaining limits.
  Include Godot version, OS, renderer and driver for rendering fixes.

The pull request template prompts for this information. Small, reproducible changes
are easier to review than a broad rewrite. Treat contributors respectfully and
keep discussion focused on the project and evidence.

## Reports and licensing

Use the issue forms for reproducible bugs and feature proposals. Review logs before
sharing them: render paths and scene names can be private. Follow
[SECURITY.md](SECURITY.md) for sensitive reports.

Original contributions are accepted under the repository's [MIT license](LICENSE).
Contribute only content you have the right to share; document separately licensed
material in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and retain its notices.
