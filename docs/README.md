# Godot360 documentation

**Export your Godot 3D scene as a video people can look around in.** Start with
the results, then follow the walkthrough using your own scene or an included example.

[![Four worlds from THRESHOLD, a 60-second film made with Godot360.](media/threshold-worlds.jpg)](showcase.md)

**[See what it can do →](showcase.md)**
· **[Export your first scene →](../addons/godot360/QUICKSTART.md)**
· **[Watch the 360° playlist ↗](https://www.youtube.com/playlist?list=PLUjBgihWYNpQ)**
· [Common questions](faq.md)
· [Current screenshot tour](../README.md#screenshot-tour)
· [Rendering feature gallery](../README.md#rendering-feature-gallery)

New here? Watch a film, install the [addon ZIP](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0.zip)
in your project, then follow the quick start. To edit the films themselves, open
the [source and examples download](https://github.com/blugart-dev/godot360-studio/releases/download/v1.0.0/godot360-studio-1.0.0-source.zip).

## Make a 360° video

| Your next step | Guide |
| --- | --- |
| Install the addon, Godot and native media tools | [Platform setup](../addons/godot360/PLATFORMS.md) |
| Select a scene, test it and render | [First export](../addons/godot360/QUICKSTART.md) |
| Animate a camera or prepare interactive events | [Authoring](../addons/godot360/AUTHORING.md) · [Skeletal camera timing](skeletal-capture.md) · [Imported characters](imported-characters.md) · [Head look and nested attachments](modifier-capture.md) · [Particle capture](particle-capture.md) · [Moving smoke](smoke-capture.md) |
| Add a soundtrack, mix audio and adjust timing | [Audio](../addons/godot360/AUDIO.md) |
| Understand quality, recipes and command-line use | [Addon reference](../addons/godot360/README.md) |
| Check glow, exposure and other scene effects | [Renderers](../addons/godot360/RENDERERS.md) · [Capture borders](capture-borders.md) · [Consistent exposure](exposure-consistency.md) · [Combined appearance](combined-appearance.md) · [Temporal effects](temporal-capture.md) · [Saved LightmapGI](lightmap-capture.md) · [Combined GI, transparency and history](combined-effects.md) |
| Play, seek and listen inside Godot | [Playback](../addons/godot360/PLAYBACK.md) |
| Reopen work, re-encode or reclaim space | [Recovery](../addons/godot360/RECOVERY.md) · [Storage](../addons/godot360/STORAGE.md) |
| Plan a larger render and final delivery | [Job planning](job-planning.md) · [Measured production budgets](production-performance.md) · [YouTube production](youtube-360-production.md) |
| Publish the example films with source links and credits | [YouTube titles, descriptions and checklist](youtube-publication.md) |
| Report a reproducible problem | [Contributing and issue reports](../CONTRIBUTING.md) · [Diagnostics](../addons/godot360/DIAGNOSTICS.md) |

## Explore the examples

| Example | Watch in 360° | Open or export it |
| --- | --- | --- |
| **THRESHOLD** · four worlds and an original score | [YouTube · 60 s](https://www.youtube.com/watch?v=zntHEAhrnWQ) | `scenes/films/Threshold.tscn` → F6; load `export_profiles/threshold-8k.tres`. [Film guide](threshold.md). |
| **AFTERGLOW** · a room dancing to disco-funk | [YouTube · 60 s](https://www.youtube.com/watch?v=TK2PuQ3n_XU) | Load `export_profiles/afterglow-4k.tres` for Forward+. [Film and music guide](afterglow.md). |
| **LUMEN** · an orbital observatory | [YouTube · 24 s](https://www.youtube.com/watch?v=Xy5PmSpqY7s) | Load `export_profiles/lumen-4k.tres` for Forward+. [Film guide](lumen.md). |
| **UMBRAL** · a gaze-driven installation | [YouTube · 12 s, silent](https://www.youtube.com/watch?v=zWUyKH0Q31I) | F5 to explore; load `export_profiles/umbral-film.tres` for its authored film. [Scene guide](umbral.md). |
| **Motion lab** · editable camera path and timeline | — | **Library → Recipes and examples → Motion lab**. [Authoring guide](../addons/godot360/AUTHORING.md). |
| **Calibration** · six labeled directions and a tone | — | **Library → Recipes and examples → Calibration defaults**. [Quick start](../addons/godot360/QUICKSTART.md). |

The film guides include local previews and reproduction steps. Source resolution
describes the render; YouTube's available playback quality depends on processing and device.

## Development and project status

**[Godot360 Studio 1.0.0](release-1.0.md) supports Windows; Linux/macOS are experimental.**
Start with the [release acceptance and follow-up work](release-readiness.md) and
the [roadmap](roadmap.md) for completed work; use the
[validation record](validation.md) for the exact evidence behind support claims.

| Topic | Reference |
| --- | --- |
| Developer setup and verification | [Testing](testing.md) |
| Clean native editor integration | [Editor workflow](editor-workflow.md) |
| Contribution guidelines and licensing | [Contributing](../CONTRIBUTING.md) · [Third-party notices](../THIRD_PARTY_NOTICES.md) |
| Publication preparation and checks | [Publishing](publishing.md) · [Preparation review](publication-review.md) |
| Development history and continuation notes | [Handoff](HANDOFF.md) · [Engineering brief](next-session.md) |
| Historical 0.8 candidate | [Candidate record](release-0.8.md) |
| Measured performance and capture costs | [Performance](performance.md) |
| Source, local artifacts and repository policy | [Repository contents](repository.md) |
| Screenshots, previews and their regeneration | [Documentation media](media/README.md) |
| Upgrade an older addon folder | [Migration](../addons/godot360/MIGRATION.md) |

[Back to the project](../README.md)
