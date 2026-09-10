# Third-party notices

All original Godot360 Studio code, documentation, scenes, shaders, artwork, musical
compositions and rendered example media are covered by the root [MIT license](LICENSE).
The addon retains its original [MIT notice](addons/godot360/LICENSE).
The following third-party materials retain their own terms and attribution.

| Material | Location and use | Attribution and terms |
| --- | --- | --- |
| Cesium Man model and metadata | `tests/fixtures/cesium_man/`; derived images `docs/media/imported-character.jpg`, `docs/media/imported-character-textured.jpg` and `docs/media/modifier-capture.jpg` | Copyright 2017 Cesium; CC BY 4.0, with a separate Cesium mark notice. [Source, pinned revision, changes and notices](tests/fixtures/cesium_man/README.md). The model is a test fixture; its branding does not imply endorsement. |
| GeneralUser GS instrument samples | Instruments heard in `assets/audio/afterglow-score.wav` and `docs/media/afterglow-tour.mp4` | GeneralUser GS 2.0.3 by S. Christian Collins. The bank is not distributed here. Retained [license text](assets/audio/afterglow-sources/GeneralUser-GS-LICENSE.txt), [source project](https://github.com/mrbumpy409/GeneralUser-GS) and [music regeneration details](docs/afterglow.md#music-credits-and-regeneration). The original composition and mix use the project MIT license; that does not relicense the underlying samples. |

The GeneralUser notice permits private and commercial music creation and explains
uncertainty about the provenance of some historical samples. Preserve that notice
and review it when assessing the sample source for a distribution. This inventory
records the supplied terms; it is not independent verification of every sample's origin.

Godot, FFmpeg/FFprobe, Python, NumPy, Pillow and TinySoundFont are external tools.
Their binaries and package sources are not included in this repository or addon ZIP.
Obtain them from their respective projects and follow their licenses when
redistributing them. TinySoundFont is used only to regenerate AFTERGLOW's included
recording; ordinary playback and addon exports do not need it.

Other documentation stills and films are rendered from original project scenes.
[Media provenance](docs/media/README.md) records the sources and regeneration commands.
Technical reference projects are listed in the addon's [references](addons/godot360/REFERENCES.md).
