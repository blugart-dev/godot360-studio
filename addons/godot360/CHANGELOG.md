# Changelog

## 1.0.0 — 2026-09-13

- First stable Windows release for authored mono 360° SDR video with stereo audio.
- Export 2K/4K/8K recipes with camera animation and cuts, scene audio, attached
  music, H.264/AAC encoding, spherical metadata and delivery checks.
- Test one second, estimate time/storage, then look around, seek and listen in
  Godot. Reopen recent exports, recover jobs and re-encode retained captures.
- Use native offline help, clear tool/setup guidance and documented storage,
  upgrade, renderer and scene limits. Honor cancellation during export startup.
- Support five Windows engine/renderer combinations. Linux/macOS remain
  experimental, including the unresolved Linux software-Mobile history mismatch.
- Align plugin, panel, spherical metadata and package labels at 1.0.0. Runtime,
  recipes, settings and saved-job formats retain the accepted RC2 behavior.
- Public installation/support guides accompany reproducible downloads; the source
  repository's `docs/validation.md` maps exact artifacts to their evidence.

## 1.0.0-rc.2 — 2026-09-13 — private candidate

- Read concise offline task guides inside Godot, with a topic picker and a direct
  return to Tool setup. Detailed bundled references remain available externally.
- Explain setup failures using the current button names and concrete next steps.
- Show the launch support boundary for the resolved engine/renderer/driver;
  explain capture detail and final compression beside the advanced controls.
- Add guidance for retaining source captures, attached soundtracks, dependent
  re-encodes and removable playback copies. No automatic deletion is introduced.
- Honor cancellation requested before coordinator initialization, with a saved
  Cancelled state and recovery guidance; retain occupied-output protection.
- These changes follow the frozen RC1 artifact and have a distinct candidate
  identity; RC1's acceptance results do not automatically cover RC2. Capture pixels and encoding
  settings are unchanged; the coordinator also fixes the early-cancel race.
- Refresh current support/status guidance while preserving dated historical
  evidence. Stable acceptance and public publication remain pending.

## 1.0.0-rc.1 — 2026-09-13 — private candidate

- Freeze the five-combination Windows launch target with experimental Linux/macOS
  and the documented scene/effect limits. See [support](SUPPORT.md) and
  [upgrading](MIGRATION.md).
- Carry the completed Studio workflow, playback, capture, audio, recovery and
  validation work listed below into the first versioned release candidate.
- Identify the candidate consistently in the plugin, panel and spherical metadata.
  The package builder now accepts numbered `-rc.N` identifiers and generates
  channel-appropriate installation text, rejecting mismatched version labels.
- Keep stable acceptance and publication pending. This version changes release
  identity and packaging; capture/rendering behavior remains unchanged.

### Windows 1.0 preparation

- Define the intended five Windows engine/renderer/driver combinations and
  consolidate tested scene, effect, production and recovery limits in
  [the support contract](SUPPORT.md). Linux/macOS remain experimental.
- Expand [upgrade instructions](MIGRATION.md) for existing recipes, renderer
  selection, playback-cache rebuilding and retained jobs.
- Repair audio, recovery and release-workflow tests for the tabbed Studio layout.
  Retain opening temporal reference images in CI. Fresh affected workflows pass;
  the earlier experimental Mobile history mismatch remains unexplained.
- The preceding preparation used version 0.8.0 while human acceptance remained
  pending. This candidate retains its capture/runtime behavior.

### studio workflow and interface

- Separate Current recipe, Tools and Library from the Opened export review.
  Saved export metadata stays visible while editing the next recipe. Keep setup,
  sample and render actions together, and cancellation beside job progress.
- Remove nested preview scrolling; show complete status, paths and scene notes
  in Export details. Add direct delivery opening, still/video identification,
  return to the original still, keyboard sphere controls and visible focus.
- Keep deliberate executable selections through discovery and restarts. Show
  tool versions, separate delivery/playback capabilities and accessible logs.
- Keep full-copy decoding and corrupt-copy rejection. Playback errors offer
  Tool setup, logs and Retry playback while verified delivery remains available.
- Keep cancellation visible until acknowledged; preserve previous export status
  when recipe validation or opening a different job fails.
- Add native UI state/screenshot checks and refresh the guides. Author remains
  Blugart; the preceding UI checkpoint used the private 0.8.0 baseline.

### reject corrupt playback copies

- Decode the complete review video and audio before making it playable or caching
  it. Some Windows Theora encoder builds return success but write corrupt motion
  packets; format and duration checks alone previously accepted these copies.
- Explain how to select another FFmpeg build and rebuild playback while preserving
  the delivered MP4. Existing copies from before this check are rebuilt on first use.
- Add a malformed-video-packet regression that retains valid Ogg checksums and
  passes the earlier format checks, then verifies rejection, cleanup and retry.

### clean editor export and recovery

- Exclude each new export folder from Godot asset import before writing media.
  Reopening a project with exports inside it no longer imports retained PNG/WAV
  files or adds import sidecars to those captures. Parent folders and older jobs
  are not changed; use Open output to find delivery files.
- Treat unavailable, empty or malformed progress JSON as an unavailable
  checkpoint without emitting editor parser errors. Polling retries normally;
  invalid saved data still cannot establish a completed export.
- Add an addon-only native editor integration review across two editor processes:
  authored scene saving, 4K sample/export, stereo playback and seeking, history,
  cancellation, diagnostics and recovery with source preservation.

### saved LightmapGI validation

- Add a disposable editor bake and saved-scene review for static lightmaps and
  a moving dynamic probe receiver, with camera cuts and capture borders.
- Compare every face, source panorama and decoded MP4 frame with independent
  native cameras in a second world. Require disabled-lighting contribution tests,
  delayed references and a missing-map negative control.
- Package the reproducible reviewer and prepare a separate Baked LightmapGI
  workflow. This adds bounded validation and authoring guidance; the capture
  runtime is unchanged.

### temporal rendering and graphics failure detection

- Reject completed captures when the worker log records an engine rendering or
  graphics-backend error. Keep the failed capture result and diagnostics, require
  a new render, and do not encode or publish a final video with a missing effect.
  Existing script-error handling is retained; unrelated certificate-store
  diagnostics, optional shader-cache unavailability and renderer warnings do not
  trigger this failure.
- Add every-frame native references for TAA, FSR1/FSR2, persistent camera/world
  compositor history and a bounded baked VoxelGI scene, with camera cuts,
  enabled/disabled comparisons and deliberately failing controls.
- Inspect actual render buffers and every decoded MP4 frame. Document the
  distinction between effect preservation and view-dependent boundary artifacts.
- Include the reviewer in reproducible addon packages and add a separate
  Temporal rendering workflow. Native and hosted evidence remain distinct.

### moving smoke and particle material guidance

- Add an optional point-facing smoke shader that keeps particle orientation
  consistent across the six cube views. Existing authored materials are preserved.
- Flag native particle billboard materials in saved-scene notes and capture
  reports, including draw passes, overrides, overlays and chained materials.
- Compare continuous moving CPU/GPU smoke with analytic mesh references through
  recycling, local/world motion, opaque occlusion, warmup, pausing and camera cuts.
  Require incorrect orientation, position and opacity controls to fail.
- Document emission-boundary precision and early/late pause ordering, alongside
  the existing two-frame particle warmup contract.
- Add tube/cross-ribbon trail fixtures with native diagonal-view references,
  pause/cut checks and enabled/disabled controls. Explain that native trail
  history requires Forward+ or Mobile in scene notes and Compatibility reports.

### head-look and nested attachment validation

- Add a stateless custom head-look modifier to the imported character fixture,
  independent modified-skin references, and a nested skeleton/camera mount.
- Check final and restored base bones, all six capture cameras, repeated warmup
  samples and viewpoint cuts. Require delayed skin, camera and modifier controls
  to fail, and extend headless attachment checks to two nested skeletons.
- Document Manual modifier sampling and the supported setup. The tested cases
  use the existing deferred capture synchronization without a runtime change.

### imported character validation

- Add a pinned, licensed CesiumMan GLB and normal scene-import fixture with a
  head-attached export camera, camera boom and a frame-30 viewpoint cut.
- Independently evaluate raw glTF animation, hierarchy and weighted skin in
  Python; compare joint/camera transforms and every source/decoded video frame.
- Include delayed-camera and delayed-skin negative controls, precise import
  settings and a textured camera comparison. Document default import optimization
  separately from capture timing. The addon runtime is unchanged by this review.

### particle startup and fixed capture clock

- Disable realtime physics jitter compensation in the capture worker so Movie
  Maker's fixed FPS also produces fixed opening simulation deltas. This fixes the
  measured two-frame warmup mismatch and repeated matching-rate particle step.
- Refresh Compatibility CPU particle automatic bounds after buffer submission,
  fixing the measured missing first delivered frame without replacing bounds or
  advancing simulation. Record the bounds refresh cost in capture timings.
- Gate particle reviews on opening frames, matching-rate fixed steps, unchanged
  authored emitter settings and actual process deltas. Keep zero-warmup GPU
  startup outside the validated contract; scene notes request at least two frames.
- Earlier retained captures keep their original timing when re-encoded. Render
  again to apply the corrected clock; project and particle settings are preserved.

### combined appearance validation

- Add a portable combined material/light fixture and reviewer for camera motion,
  lighting cuts, camera/world exposure handoffs, glow and capture borders.
- Compare source and decoded frames with independently authored fixed-exposure
  scenes; isolate projection with unlit controls and glow with disabled baselines.
- Define consistent 1.0 exposure as authored values, including animation. Shared
  automatic spherical adaptation is deferred beyond 1.0; Scene defaults and saved
  recipes keep their existing behavior.

### particle capture and authored processing modes

- Preserve the scene root's processing mode through warmup and honor later scene
  changes. Disabled scenes and scenes that pause themselves stay paused during export.
- Report short-warmup and Compatibility CPU particle startup in scene notes. Document startup, fixed-step
  timing and seed limitations without changing authored particle settings.
- Identify automatic CPU visibility bounds as a startup risk in Compatibility;
  explicit authored bounds remove the measured first-frame gap. Narrow the note
  to automatic bounds and add the authored workaround to the fixture and guide.
- Add CPU/GPU particle motion against an analytic mesh reference, decoded MP4
  comparisons and rendered processing-mode regressions in the portable test suite.

### skeletal camera timing

- Synchronize capture cameras after queued skeleton/attachment updates, fixing
  a one-frame delay when the selected camera follows a BoneAttachment3D.
- Preserve frame sampling, local camera offsets, authored poses and six-view
  rendering. Add moving/cut camera, weighted-skin and external-attachment
  regressions with independent rendered references and decoded MP4 comparisons.
- Document that cuts apply to the selected export camera; temporal histories are
  retained. Complex modifiers, particles and imported character workflows remain
  outside the validated fixture scope.

### explicit consistent exposure

- Add Advanced capture exposure: Scene (default) or Fixed (authored). Fixed uses
  worker-owned camera attributes with automatic metering disabled; authored
  exposure, physical settings and DOF animation stay synchronized across faces.
- Follow camera/world attribute replacements without changing authored resources.
  Keep legacy behavior, persist recipes/settings, invalidate changed estimates,
  reject malformed modes and preserve original capture evidence on re-encode.
- Add rendered exposure/oracle comparisons, decoded-frame comparisons, source hash
  checks and exposure synchronization timings. Shared automatic spherical
  adaptation remains open; this option uses authored exposure.

### capture borders and private 1.0 development

- Add optional capture borders with smooth overlap blending at face edges and
  three-face corners. Preserve the 90° core's pixel density and final panorama
  dimensions; the default zero border keeps the original capture path.
- Save the setting in recipes and local preferences, show the additional face
  pixel cost, invalidate stale estimates and retain capture evidence on re-encode.
- Add moving glow/no-glow comparisons and projection, validation, persistence
  and re-encode checks. Glow shape and independent auto-exposure remain limits.
- Clarify that 0.8 is an internal development baseline. Work continues privately
  until the supported 1.0 workflow is implemented and validated.

### recent exports

- Add a project-local list of the last 12 launched or opened jobs, with scene,
  video settings, saved state and folder details. Open through the existing
  playback/recovery flow; Forget removes the entry without deleting files.
- Migrate the previous last-job preference, deduplicate normalized paths, retain
  unavailable folders, and recheck files when opening. Listing reads bounded
  metadata only; saved progress does not establish coordinator liveness.
- Keep job switching disabled during exports and coordinator checks. Add focused
  persistence, malformed-input, layout and actual export/playback workflow checks.

### native playback and scene notes

- Play completed exports in the editor with spherical navigation, pause, seeking,
  replay and stereo sound. Prepare a local Theora/Vorbis copy up to 2K / 30 FPS
  using the existing external FFmpeg/FFprobe tools; reuse it on later reviews.
- Keep conversion asynchronous and cancellable, check disk headroom and output,
  stop its child on plugin shutdown, and preserve delivered media and captures.
- Show actual capture warnings in the panel. Expand saved-scene advice to glow,
  auto exposure, fog, SDFGI, depth of field and compositors.
- Add native pixel/audio playback checks and exact-package workflow coverage.
  Playback is a review aid; full-resolution delivery and renderer limitations remain.

### renderer preservation

- Default capture to the saved project renderer/driver; explicit recipe/UI/CLI
  overrides, actual GPU/backend evidence and a fail-on-fallback worker handshake.
- Preserve camera offsets, animated camera settings and compositors; copy viewport
  AA, scaling, LOD, occlusion and shadow-atlas configuration. Keep SDR sRGB assembly
  and existing BT.709 delivery, with explicit HDR readback rejection.
- Invalidate old and renderer/engine/project-dependent estimates; preserve original
  renderer evidence on re-encode. Reject scene script errors before delivery.
- Add native renderer fixtures, perspective/panorama comparisons, motion review,
  renderer-selectable package tests and a Linux software-Vulkan CI lane.
- Retry transient JSON replacement locks for roughly 500 ms; preserve the previous
  complete checkpoint on permanent failure. Verify both with native Windows locks.
- Document measured renderer/backend combinations and visible glow/auto-exposure
  seams, distinguishing native face effects from panorama sampling defects.

### desktop platforms

- Add Windows, Linux and macOS dependency downloads, install steps and a shared
  Platform setup guide, available from the editor's Tool setup section.
- Resolve tool names to absolute paths for setup, capture and encoding; search
  Homebrew/MacPorts locations when the editor has a limited PATH. Check Unix
  execute bits and explain missing permissions/native builds.
- Release the panel during plugin shutdown while editor services are still alive.
  Use Cmd+S in macOS scene-save guidance.
- Add real native-process, Unicode-path, Unix permission and symlink checks.
  Record OS, architecture, tool versions and rendered/headless coverage in reviews.
- Prepare Linux rendered-export and macOS headless CI lanes. Keep Mac capture
  support provisional until native validation; see [platform status](PLATFORMS.md).

### first-export workflow

- Add Use current scene with a save boundary, saved-scene camera discovery and a
  picker for inherited/instanced cameras. Keep manual paths for runtime cameras.
- Group advanced capture, audio timing, tool setup, recipes and recovery controls.
  Keep the basic scene/video/audio workflow and test/render actions prominent.
- Discover tools on PATH and check FFmpeg/FFprobe capabilities asynchronously.
  Check output writes and display scene risks before capture; invalidate readiness
  after path changes. Keep authoritative job validation and recovery in the pipeline.
- Reject malformed numeric input before launch and clear the previous still preview
  when starting a new job. Expand recovery controls when a saved job needs attention.
- Add a portable quick start, shorten the repository landing page, and move demo
  architecture and developer commands into their own guides.

### folder naming

- Use `addons/godot360` for the addon and `.godot360` for local settings/output.
- Update scene/script references, recipes, CLI tools, tests and package contents
  together; retain script resource UIDs.
- Rename the Motion Lab's in-scene label to Godot360 and document migration for
  existing installations. Historical release artifacts retain their original names.

## 0.8.0 — 2026-09-07

- Add **Save diagnostics…** for successful, failed, unconfirmed and setup jobs.
  Collect bounded reports/log tails and environment information into a locally
  verified ZIP, with per-file hashes and explicit omissions. Preserve original
  job files, current status/recipe and existing ZIPs; do not collect source media.
- Distinguish collecting hardware from saved export hardware and include live
  stderr logs. Support empty logs without invoking an invalid zero-length hash update.
- Accept the explicit parent directory exposed by Godot 4.7's ZIP reader while
  still verifying every payload against the exact allowed inventory and bytes.
- Add diagnostics guidance and a reusable independent beta/YouTube feedback form.
- Add an exact-package reviewer: verify/extract the release manifest, reproduce the
  same ZIP bytes, and run the complete compatibility/failure/recovery suite plus
  documented calibration, preview, recipe, diagnostics and Motion Lab workflows.
- Establish local Git history from the validated 0.7 source baseline. Generated
  media, local settings, tools and release ZIPs remain outside source history.

This is a beta candidate. Independent Windows/GPU feedback, current-candidate
YouTube playback review and approval for public publication remain release gates.

## 0.7.0 — 2026-09-07

- Check output-drive working headroom before jobs, during capture/encoding and
  metadata copying. Capture includes image/PCM allowance; metadata budgets the
  second MP4 copy. Keep a 256 MiB reserve without claiming to reserve disk space.
- Make planning suggestions include the working allowance as well as retained
  files and 25% headroom.
- Check required checkpoint flush/rename, preview and capture-result writes.
  Save the successful report before committing the final video filename.
- Detect process-log writes that fail and reject unwritable cancellation markers.
  Keep draining child pipes so log errors do not deadlock shutdown.
- Add controlled low-space/blocked-write fixtures and actual Fast/Compact PNG
  failures. A source retained after report failure re-encodes with unchanged hashes.
- Pass the three-engine regression matrix and additional cancellation-write checks:
  1,161 unique checks across 4.5.1, 4.6.3 and 4.7.2.
- Preserve the actual process/log startup error in the terminal status rather
  than misreporting a codec capability failure.
- Extend the endurance reviewer to explicit resolution, face size, FPS, timeout
  and storage limits, including audio cues near the end of the selected duration.
- Validate 60 seconds at 4096×2048 and 30 seconds at 7680×3840, both at 30 FPS:
  all 1,800/900 source and decoded frame codes/flash states pass, all thirteen
  delivery checks pass, and beginning/middle/end cues have zero measured drift.
  Record the fixture's +2-sample audio offset, timings, storage and hardware limits.

The initial 1.0 plan targets Windows/Compatibility and documented production test
limits. Independent beta and current YouTube playback review remain release gates.

## 0.6.3 — 2026-09-07

- Reopen the last saved job at panel startup and add an Open saved job action.
- Reconnect only after a fresh per-client challenge matches the coordinator's
  session, process ID and action. Cancel through that coordinator without signaling
  saved process IDs. Recheck connected jobs and reject expired/stale requests.
- Inspect retained captures after coordinator loss without overwriting status/logs
  or requiring an existing recovery file. Offer a direct re-encode action using
  the original source folder and current audio/CRF settings.
- Require the delivered file and successful report before showing saved completion.
- Add real panel/editor-loss/coordinator-loss tests, concurrent-client challenges,
  obsolete-reply and reused-PID rejection, and source-preserving recovery/re-encode.

Reopened coordinators use fresh replies and terminal files for liveness. The
child-process query used for newly launched jobs cannot determine that state after
the original editor has exited. Partial capture and arbitrary scene/audio state
restoration remain outside this update.

## 0.6.2 — 2026-09-06

- Guard scene loading/instantiation and report early worker closure explicitly.
- Retain submitted-frame counts and timing diagnostics after capture failures;
  count a frame only after successful writer submission.
- Record worker exit codes and require a successful exit plus the complete frame
  count before using the recorded capture.
- Save recovery guidance after pipeline failures and show it in the panel.
  Completed PNG/WAV captures can be re-encoded; partial captures cannot resume.
- Add six controlled failure cases: malformed scene, frame hook error, graceful
  early exit, cancellation, killed worker and killed PNG encoder.
- Validate a real 90-second, 60 FPS GPU capture: all 5,400 delivered PNG and MP4
  frames have the correct frame code and flash timing; seven audio cues show no
  measured drift. The fixture's constant 4.625 ms startup offset is documented.
- Pass 265 checks on each of Godot 4.5.1, 4.6.3 and 4.7.2, including recovery UI
  and process cleanup. Normalize generated fixture paths before embedding them.

The sustained capture uses 1024×512 output on the existing Windows/NVIDIA machine.
It does not establish long 4K/8K performance, other hardware, or arbitrary-scene sync.

## 0.6.1 — 2026-09-06

- Fix Motion Lab's missing animation on Godot 4.5.1 by storing its library in the
  dictionary format also read by the tested newer engines. Fail the timeline test
  promptly if its initial animation is missing.
- Add isolated addon-only compatibility checks for editor import, contracts,
  actual GPU panel capture and headless re-encoding. All 208 checks pass on each
  of Godot 4.5.1, 4.6.3 and 4.7.2 on the tested Windows/NVIDIA machine.
- Add eight soundtrack format/rate cases and a 90-second, 25 FPS mixed export;
  decoded output matches independently placed input cues with zero measured lag.
- Add a beta/compatibility guide and a reproducible ZIP builder with a per-file
  SHA-256 manifest, source verification and version consistency checks.
- Make the historical audio regression fixture an explicit command-line input.

This is a local reliability update, not a community release. Other operating
systems/GPUs and current YouTube processing remain unverified.

## 0.6.0 — 2026-09-06

- Add scene audio, attached soundtrack and mixed output modes with independent
  levels, source trim and positive/negative synchronization offsets.
- Persist audio controls in portable recipes and local settings; apply current
  panel controls or explicit CLI overrides when re-encoding retained captures.
- Probe external audio before capture, record its resolved path and SHA-256,
  and reject source changes before publishing the final output.
- Convert selected audio to 48 kHz stereo, pad/trim to film duration, and apply
  a latency-compensated peak limiter when mixing. Preserve default scene encoding.
- Add an audio-duration output check and regenerate edited audio timestamps from
  emitted samples to prevent discontinuities after trimming and delay.
- Invalidate planning estimates for active audio edits or soundtrack file changes,
  while preserving existing default-audio samples and tolerating insignificant rounding.
- Retry atomic JSON replacement briefly when Windows readers hold the status file.
- Add actual decoded-audio, source-preservation, limiter, panel and failure tests;
  correct the panel's stale version label.

Attached files remain external dependencies. Looping, fades, automatic alignment,
multichannel mixing and spatial audio are outside this milestone. See `AUDIO.md`.

## 0.5.0 — 2026-09-06

- Add full-panorama, zero-pose mono Spherical Video V2 metadata in the H.264
  sample entry, retaining equivalent V1 metadata for older readers.
- Deliver fast-start MP4s with moov before media. Relocate every video/audio
  chunk offset and promote stco tables to co64 when required by the final size.
- Validate the supported container structure before opening output and reject
  malformed tables, external media, duplicate metadata, and unsupported layouts.
- Check V1, V2, fast-start layout and chunk-offset bounds before assigning the
  final video filename. Observe cancellation while copying media in bounded blocks.
- Add large-offset and malformed-input contracts, plus independent real-file
  media/packet hashes, full decoded video/audio comparisons and V2-only recognition.

Input remains the pipeline's conventional H.264/AAC MP4 with a trailing moov.
Fast-start input, fragmented/encrypted media and general MP4 editing are unsupported.
Capture timing, authored animation and scene audio behavior are unchanged.

## 0.4.0 — 2026-09-06

- Add an optional frame-index sampling hook before camera synchronization, keeping
  authored properties aligned with delivered frame timestamps after warmup.
- Add a reusable AnimationPlayer scene base with absolute property sampling,
  explicit discrete-key state, and validation for duration and unsupported tracks.
- Add the editable Motion Lab scene and a one-click six-second 4K recipe: Path3D
  camera motion, horizon/pole markers, world-space titles, and flash/tone cues.
- Record the timeline sampling mode in capture settings and propagate explicit
  begin/sample hook errors through the capture result.
- Add actual PNG/MP4 geometry and audio checks across rear/cube seams and poles,
  including 24 FPS without warmup and 30 FPS with two warmup frames.
- Document the authoring contract, supported property tracks, and audio limits.

Timeline method/audio/nested-playback tracks are deliberately rejected. Ordinary
scene audio remains supported. Existing scenes can keep their current hooks.

## 0.3.0 — 2026-09-06

- Add Test 1 second using the full recipe's production settings, with measured
  export-time and retained-storage estimates, free-space advice, and stale checks.
- Rescale planning estimates when duration changes and remember the last sample.
- Show live H.264 encoding progress and an approximate remaining time.
- Run tools through concurrently drained process pipes so encoding and verification
  can be cancelled promptly, with diagnostic logs retained.
- Re-encode completed PNG/WAV captures into fresh folders at a selected CRF,
  preserving source files and using their recorded dimensions and timing.
- Publish the final video filename only after all output checks pass.
- Test planning contracts, the complete panel workflow, source-file preservation,
  and cancellation during an actual 8K encode.

Estimates extrapolate the first second; later content and asset edits require
judgment and further tests. Re-encoding works in a headless addon-only project
without the original scene. The tool remains GDScript plus external FFmpeg.

## 0.2.0 — 2026-09-06

- Add Fast PNG storage using a persistent FFmpeg pipe. It preserves every RGB
  or RGBA byte and keeps the existing retained-frame workflow. Compact PNG remains
  available when smaller temporary files matter more than capture time.
- Record GPU readback, image submission/storage, and pipeline stage timings.
- Show completed capture frames and an approximate remaining capture time.
- Keep render, cancel, and output actions visible below the scrolling settings.
- Handle encoder failures, drain error output concurrently, and close the writer
  on cancellation or normal worker shutdown.
- Preserve cancellation results if Godot draws another frame while quitting.
- Add real encoder round trips, pixel/order checks, and process cleanup tests.

New editor recipes default to Fast PNG. Legacy JSON jobs without `frame_writer`
retain Compact PNG behavior. Fast PNG requires the PNG encoder in FFmpeg and
uses more temporary disk space. No GDExtension or custom engine is required.

## 0.1.1 — 2026-09-06

- Add Draft / 2K, Production / 4K, and Detail / 8K buttons that set both panorama
  and cube-face resolution, plus appropriate H.264 quality.
- Explain the limited detail of a 2K spherical viewing window. Warn when cube
  faces cannot supply the selected panorama's sampling density near face centers.
- Record sampling advice and actual capture settings for diagnosis.
- Preserve CRF, random seed, and warmup settings between editor sessions.
- Keep settings scrollable within a compact editor bottom panel.
- Add contract and actual-panel checks for quality presets and warnings.

## 0.1.0 — 2026-09-06

- Initial experimental mono 360 capture, encoding, metadata, validation, recipes,
  calibration scene, and spherical still preview.
