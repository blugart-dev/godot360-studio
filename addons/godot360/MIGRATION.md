# Upgrading Godot360 Studio

Fresh installations use `addons/godot360` and `.godot360/settings.cfg`.

## Updating an existing Godot360 installation

The current release is **1.0.0**, with Windows support. These
instructions cover upgrades from earlier 0.x and 1.0 release-candidate packages.
Recipes, settings and job formats are unchanged from RC2.

1. Finish or cancel active exports and close the editor before replacing addon
   files. Back up the project, saved `.tres` recipes and local `.godot360` settings.
   Keep original export folders and delivered MP4s outside the addon folder.
2. Replace `addons/godot360` with the folder from the reviewed package, keeping
   every script's `.uid` file. Do not overlay a second copy under the old addon
   name. Reopen the project, enable the plugin if necessary, and save the scene.
3. Open **Tools → Tool setup**, check the selected FFmpeg/FFprobe pair and run
   **Check setup**. Tool paths are local to the machine and project. Explicitly
   selected tools remain selected when using **Find missing tools**.
4. Run a short test before a full export. The current **Current recipe**, **Tools**
   and **Library** tabs separate the next recipe from the **Opened export**.
   Opening an earlier job does not replace the recipe being edited.
5. Reopen one complete retained job from **Library** and try playback and
   re-encoding into a fresh folder. Keep the original capture and delivery until
   the new result has been reviewed. See [recovery](RECOVERY.md).

## Behavior to check after upgrading

- New captures use the saved project's renderer/driver unless the recipe has an
  explicit override. Early addon versions forced Compatibility. Check the
  recorded actual renderer after upgrading a Forward+/Mobile project; appearance
  can change when the authored renderer is finally preserved.
- Legacy recipes without a border use **0%**. Recipes without an exposure policy
  use **Scene**, including native per-face metering where available. Choose
  **Fixed (authored)** explicitly for consistent authored exposure; migration does
  not silently rewrite the scene or recipe. See [renderers](RENDERERS.md).
- Older playback cache entries are rebuilt before reuse. The new copy is fully
  decoded before playback is accepted. A bad encoder build can require choosing
  another tool pair and using **Retry playback**; the delivered MP4 is preserved.
- New export folders contain `.gdignore`, keeping retained PNG/WAV captures out
  of Godot's asset import. Older folders are left as they were. Use **Open folder**
  to inspect job files even when they do not appear in Godot's FileSystem panel.
- Live reconnection requires a coordinator started with 0.6.3 or later. Older
  saved jobs can be inspected; complete compatible PNG/WAV captures can be
  re-encoded after validation. Partial captures cannot resume, and re-encoding
  cannot change the original renderer, border, exposure or captured scene.

Existing delivered videos retain their original contents and metadata. A
re-encode creates a new delivery; historical reports keep the versions and
capture settings they originally recorded. Review the
[Windows support contract](SUPPORT.md) before changing engine or graphics driver.

## Migrating the earlier Umbral360 folder name

When upgrading a checkout from the previous Umbral360 name:

1. Stop exports and close the Godot editor.
2. Rename `addons/umbral360` to `addons/godot360`, then replace that old addon
   prefix in `project.godot`, custom scripts, scenes and saved `.tres` recipes.
   Enable the plugin at `res://addons/godot360/plugin.cfg`. Keep each script's
   `.uid` file with it when moving it.
3. Rename `.umbral360` to `.godot360`. Update any absolute tool, soundtrack,
   output and saved-job paths in `settings.cfg` if their containing folder moved.
   Keep both data folder names ignored by Git for older checkouts.
4. Reopen the project in Godot so its import cache and resource paths refresh.
   Select FFmpeg/FFprobe again if the panel still shows their old locations.

This repository has already migrated its tracked resources and tests. Existing
external recipes must receive the same path replacement. Previously rendered
videos retain their contents and metadata; historical reports and packages retain
the names and paths they recorded at the time.

The original copyright attribution in `LICENSE` is preserved. UMBRAL is the
creative installation's title; THRESHOLD is the four-world film's title.
