# Godot360 folder migration

Fresh installations use `addons/godot360` and `.godot360/settings.cfg`.

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
