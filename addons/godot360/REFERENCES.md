# Architecture and interoperability references

Reviewed on 2026-09-06. These are references, not runtime addon dependencies.
No source code from the following Godot projects is incorporated in Godot360.

| Project | What its documentation contributes | Difference in this implementation |
| --- | --- | --- |
| [Godot360](https://github.com/Cykyrios/Godot360) | Six viewport cameras and shader-based projections; MIT | Original capture rig/shader, with an integrated movie pipeline, metadata, and validation |
| [godotPanoRenderer](https://github.com/revpriest/godotPanoRenderer) | C# panoramic/stereo capture by angular slices; CC0 | GDScript mono capture, six simultaneous views; no slice-based stereo |
| [FMGodot ODS article](https://www.frozenmist.com/blog/20260808-FMGodot-Real-Time-360-Stereoscopic-Omni-Directional-Panorama/) | A modified-engine approach to stereo panorama rendering | Runs on an unmodified engine; stereo is outside v0.1 |

Their documentation was reviewed; their implementations and performance were not
benchmarked in this project. This is not an exhaustive survey of available tools.

Primary specifications used for interoperability:

- [Godot Movie Maker](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html): offline timing and audio capture.
- [OS.execute_with_pipe](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe): native process I/O and child process lifecycle.
- [ZIPPacker](https://docs.godotengine.org/en/4.5/classes/class_zippacker.html): local diagnostics archives, verified by reading their members back before final naming.
- [FFmpeg PNG encoder](https://ffmpeg.org/ffmpeg-codecs.html#png): lossless compression level and prediction options.
- [FFmpeg progress output](https://ffmpeg.org/ffmpeg.html#Generic-options): machine-readable progress blocks and their update period.
- [DirAccess free space](https://docs.godotengine.org/en/stable/classes/class_diraccess.html#class-diraccess-method-get-space-left): available-space reporting for job planning.
- [MovieWriter](https://docs.godotengine.org/en/stable/classes/class_moviewriter.html): the possible future GDExtension boundary for direct image/audio delivery.
- [Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html) and [SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html): the six-view capture rig.
- [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html), [Animation tracks](https://docs.godotengine.org/en/stable/classes/class_animation.html), and [PathFollow3D](https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html): native property timelines and camera paths.
- [Node3D](https://docs.godotengine.org/en/stable/classes/class_node3d.html#class-node3d-method-force-update-transform) and [RenderingServer signals](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#signals): transform notifications and render timing, checked against actual captured frames.
- [FFmpeg filters](https://ffmpeg.org/ffmpeg-filters.html#colorspace): actual color conversion before encoding.
- [FFmpeg audio filters](https://ffmpeg.org/ffmpeg-filters.html): sample-based trim/delay, timestamp generation from sample count, stereo resampling, amix and alimiter latency compensation, tested with actual encoded audio in 0.6.
- [Spherical Video V1 RFC](https://github.com/google/spatial-media/blob/master/docs/spherical-video-rfc.md): track UUID and RDF/XML retained for compatibility.
- [Spherical Video V2 RFC](https://github.com/google/spatial-media/blob/master/docs/spherical-video-v2-rfc.md): sample-entry placement of `st3d`/`sv3d`, mono layout, zero pose and uncropped equirectangular bounds. V1 and V2 can coexist with equivalent semantics. Version 0.5 tests V2 recognition with V1 disabled.
- [FFmpeg MOV/MP4 muxer](https://ffmpeg.org/ffmpeg-formats.html#mov_002c-mp4_002c-ismv): conventional MP4 and fast-start layout. Godot360 performs its own bounded metadata/offset rewrite to preserve the original encoded media bytes.
- [YouTube 360 upload instructions](https://support.google.com/youtube/answer/6178631?hl=en): spherical metadata and playback checks.
- [YouTube upload encoding settings](https://support.google.com/youtube/answer/1722171?hl=en): codec, audio, and SDR color guidance.

FFmpeg builds for Windows are linked from its [official download page](https://ffmpeg.org/download.html).
The local test installation used a gyan.dev essentials ZIP with its published
SHA-256 verified. Executables are excluded from the addon and source package.
