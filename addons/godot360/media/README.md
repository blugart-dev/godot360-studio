# Guide screenshot

`studio.png` is an unmodified 1440×900 viewport capture of the actual Godot360
Studio panel on native Windows / Godot 4.7.2 / Forward+ Vulkan / RTX 3060 Ti,
2026-09-14. It shows an eight-second editable Draft recipe beside a completed
one-second calibration sample, in the original full-resolution still view.
Calibration is included in addon-only installations.

The capture is automated in a fresh isolated project. It uses Godot's default
control theme; editor chrome is outside the image and Use current scene is
disabled because this standalone panel has no editor save callback. Actual
editor integration is validated separately. This is not a human walkthrough.

Regenerate with `tests/ui_review.py` from the full repository or development
package. In the full repository, `tools/build_ui_media.py` copies the reviewed
panel/editor images and updates `docs/media/ui-provenance.json`, including source,
driver and screenshot hashes. Follow `docs/media/README.md` for both review commands.
The 2026-09-14 captures passed 44 panel and 52 native editor checks. Local evidence
is retained under `.godot360/readme-refresh-20260914/`; the panel was rendered in
a disposable Windows Temp project so visible paths contain no personal username.
The PNG is included in the addon ZIP;
`.gdignore` prevents asset import. Render masters and user settings are untouched.
