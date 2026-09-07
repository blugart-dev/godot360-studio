# Godot360 beta report

Copy this form for one independently tested Windows, Linux or macOS machine. Review any diagnostics
ZIP before attaching it. Leave untested steps marked **not tested**. Do not report
automated tests on the development machine as independent hardware feedback.

## Environment

- Addon version and package SHA-256:
- Godot version:
- OS/distribution version and CPU architecture (x86_64/arm64):
- GPU, driver and display/session (X11/Wayland/WSLg, if applicable):
- Godot install source (official download/package manager/sandboxed package):
- Renderer (the initial support target is Compatibility):
- FFmpeg / FFprobe versions:
- Different tester/machine from the development setup (Windows / RTX 3060 Ti):

## Clean installation

- Empty Compatibility project, addon copied, plugin enabled, panel opened:
- Draft calibration **Test 1 second**, verified MP4 and report:
- Preview front/right/back/left/up/down; labels upright and directions correct:
- Sample estimate appears; recipe save/reload restores the selected values:
- Attached mono/stereo soundtrack, mix mode, changed offset/level, re-encode:
- Original capture preserved; new video/audio play as expected:
- Motion Lab short sample and complete six-second film (include resolution):
- Close/reopen editor and inspect the saved completed job:
- **Save diagnostics…** produces a readable ZIP and preserves job/recipe:

For a failure, record exact steps, expected behavior, observed behavior and whether
it repeats. Attach the reviewed ZIP and keep the original job folder. State whether
the failure blocks normal exports or has a reliable workaround. No real disk-full
or power-loss experiment is needed for this feedback.

## Current-candidate YouTube review (separate release gate)

- Candidate version, package hash, export job and `video-360.mp4` hash:
- Upload and high-resolution processing complete:
- Browser/device and selected playback resolution:
- 360 navigation works; initial front, left/right and poles have correct orientation:
- Detail at highest processed quality; seams/poles acceptable during motion:
- Audio at beginning, middle and end; no unexpected drift or clipping:
- Observed issue, playback time and reproduction steps:

Uploading and sharing are separate user actions. A passing local container/media
report does not establish YouTube playback quality. Independent beta feedback and
current-candidate playback review are required before the 1.0 release gate closes.
