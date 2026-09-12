# Guide screenshot

`studio.png` is an unmodified 1440×900 viewport capture of the actual Godot360
Studio panel on native Windows / Godot 4.7.2 / Forward+ Vulkan / RTX 3060 Ti,
2026-09-13. It shows an eight-second editable Draft recipe beside a completed
one-second calibration sample, in the original full-resolution still view.
Calibration is included in addon-only installations.

The capture is automated in a fresh isolated project. It uses Godot's default
control theme; editor chrome is outside the image and Use current scene is
disabled because this standalone panel has no editor save callback. Actual
editor integration is validated separately. This is not a human walkthrough.

Regenerate with `tests/ui_review.py` from the full repository or development
package; copy its `.godot360/ui-evidence/completed-1440.png` after inspecting all
state images and its passing report. The repository's `docs/media/ui-provenance.json`
records source/runtime hashes and screenshots. Local evidence remains under
`.godot360/ui-ux-review/final-ui-verified/`. The PNG is included in the addon ZIP;
`.gdignore` prevents asset import. Render masters and user settings are untouched.
