# Guide screenshot

`studio.png` shows the actual Godot360 panel on Godot 4.7.2 / Windows,
captured on 2026-09-08 from the unreleased source following commit `91d0a9e`.
The source panel code is unchanged by this documentation pass.

The full repository's THRESHOLD 8K recipe is selected, with its completed film
open at 35 seconds through the native 2K / 30 FPS review copy. A disposable
project isolates capture settings from the user's project. The panel is rendered
standalone, so editor-provided **Use current scene** is disabled in this image.
In the editor, that button is connected to the current scene.

The screenshot is 1440×900 and contains project-relative display paths. It is
included in the addon ZIP so the README, quick start and playback guide remain
illustrated after extraction. `.gdignore` keeps it out of Godot's asset import.
In the full source repository, `docs/media/README.md` describes regeneration with
`tools/capture_docs_panel.gd`.
