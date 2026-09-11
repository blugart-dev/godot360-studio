# Demanding production exports

This review measures a procedural workload on native Windows 11, Godot 4.7.2,
Vulkan and an NVIDIA RTX 3060 Ti with 8 GiB of VRAM (driver 610.74), with an
Intel i9-11900K and 32 GiB of RAM. The exporter remains the 0.8.0 development
baseline. It does not establish native Linux/Mac performance or a minimum
hardware requirement.

Four one-minute exports pass, covering Forward+ and Mobile at 4K and 8K.
All 7,200 delivered source frames and 7,200 decoded video frames pass the
independent identifier, flash and audio checks. These are sequential runs on
an active desktop, with telemetry and occasional lightweight documentation
work alongside capture, rather than exclusive-machine measurements.

## Completed sustained results

| Renderer / output / MSAA | Capture including writer flush | Encoding | Product verification | Whole pipeline | Retained capture |
| --- | ---: | ---: | ---: | ---: | ---: |
| Forward+ / 4K / 4× | 575.94 s | 83.26 s | 40.65 s | 710.08 s | 13.96 GiB |
| Mobile / 4K / 4× | 573.22 s | 83.50 s | 42.60 s | 704.41 s | 14.33 GiB |
| Forward+ / 8K / Disabled | 1110.44 s | 290.73 s | 122.49 s | 1531.25 s | 41.64 GiB |
| Mobile / 8K / 4× | 1072.16 s | 289.38 s | 114.76 s | 1482.46 s | 42.37 GiB |

For the two 4K exports, additional review took 109.52–111.45 seconds per run to
read all 1,800 source PNGs, 5.55–5.69 seconds to decode and check all video frame
identifiers, and 0.56–0.58 seconds for audio. All frame IDs and flashes pass. Five audio cues have a constant
66-sample (1.375 ms) source offset and zero drift; AAC adds zero cue lag and
measures 55.37 dB against the retained WAV. All six histories contain 1,808 draws.
Forward+ 8K also passes all 1,800 source and decoded frames, all five flash events and
audio cues, and all six 1,808-draw histories. Its additional source review took
392.94 seconds and decoded video review 18.97 seconds.

Mobile 8K passes the same checks; its additional source review took 396.50
seconds and decoded video review 18.89 seconds. Each run captures 1,808 PNGs,
including eight warmup frames. The timing table excludes those independent
review stages. Whole-pipeline time includes startup, metadata and other checks.

Median process private commit decreased between submitted-frame windows
150–450 and 1350–1650: 45.7 MiB for Forward+ 4K, 29.2 MiB for Mobile 4K,
33.4 MiB for Forward+ 8K and 16.6 MiB for Mobile 8K. Dedicated GPU memory
decreased by 1.8 MiB in Forward+ 4K and stayed level in the other profiles;
shared GPU use stayed level in all four. Submitted frame numbers include
warmup. This bounded observation does not establish unlimited-duration memory
stability.

The actual product planner predicted 868.35 seconds and 13.76 GiB retained from
the first-second Forward+ 4K probe. The full result took 710.08 seconds and
13.96 GiB: time was overestimated by 22.3%, and retained storage underestimated
by 1.4%. Its 17.60 GiB suggested free-space allowance covered the run. Startup,
later scene changes and short encoder samples remain reasons to treat estimates
as forecasts. Across the four matched probe/full pairs, whole-pipeline time
was overestimated by 10.9–22.3% and retained storage differed by −1.4% to +1.5%.
All four suggested free-space allowances covered the measured retained output.
The planner itself is unchanged and does not reserve that space.

For this scene and these settings, budget roughly **14 GiB per minute of 4K
content** or **42 GiB per minute of 8K content**, plus working headroom. The
full pipelines take about 12 and 25 minutes respectively on this machine.
Image complexity, face resolution, borders, AA, encoding tools and other active
applications affect those figures. They are measured examples, not general
minimum requirements or guaranteed throughput.

## Workload and acceptance

`tests/fixtures/production_scene.gd` builds 768 textured sphere instances in
12 MultiMesh batches, 24 generated 2048×2048 albedo/normal maps, six dynamic
shadowed point lights, 24 lit alpha panels and capacity for 1,536 GPU particles. Geometry
is rendered repeatedly for six views and shadows; the engine's primitive
counter includes that repeated work and is not a unique triangle count.
Forward+ adds glow; Mobile uses its corresponding authored setup without glow.
Both retain a short previous-frame afterimage independently in all six views.

The camera moves continuously and cuts at 30 seconds. Lighting and geometry
continue moving through the cut. Runs use authored exposure 1.0, 30 FPS, eight
warmup draws, 12.5% borders, Fast PNG and CRF 18 H.264/AAC output. Particles
start naturally and ramp up; warmup is not simulation pre-roll. The fixture's
audio clock continues during warmup with matching leading silence.

Every delivered source PNG and every decoded video frame is read. Thirteen
camera-mounted binary markers identify the frame; separate flashes and chirps
test audiovisual timing at 0.5, 15, 30, 45 and 58 seconds. The reviewer checks
actual renderer/driver/MSAA, all thirteen delivery checks, all six compositor
histories, scene inventory, scratch cleanup and unchanged source/settings.
Reversed/duplicated frames and delayed/silent audio must fail the independent
reviewer. This is a load and delivery test; marker crops are not a whole-scene
appearance reference. See [combined effects](combined-effects.md) for that
separate bounded visual comparison.

## Completed one-second probes

Each probe captures 38 frames including warmup and delivers 30. Pipeline time
includes startup, capture, encoding, metadata and product verification, while
the additional Python frame/audio review is recorded separately.

| Renderer | Panorama / face core | MSAA | Pipeline | Retained capture |
| --- | --- | --- | ---: | ---: |
| Forward+ | 4096×2048 / 1536 | 4× | 22.49 s | 0.296 GiB |
| Mobile | 4096×2048 / 1536 | 4× | 19.58 s | 0.306 GiB |
| Forward+ | 7680×3840 / 3072 | 4× | 103.45 s | 0.901 GiB |
| Mobile | 7680×3840 / 3072 | 4× | 36.10 s | 0.924 GiB |
| Forward+ | 7680×3840 / 3072 | Disabled | 38.97 s | 0.900 GiB |

The 8K Forward+ 4× MSAA probe reaches about 6.32 GiB of dedicated GPU memory
and 4.43 GiB of shared GPU memory for its process tree. Its capture interval is
87.94 seconds, including the final writer flush. Disabling MSAA reduces the sampled dedicated allocation to about
5.44 GiB and shared allocation to 0.38 GiB. This supports choosing reduced AA
for the sustained Forward+ 8K run on this machine. MSAA also changes rendering
work, so this does not isolate the cost of memory paging. It trades antialiasing
for headroom; it does not promise equal image quality. The renderer settings differ,
so the table is not a controlled Forward+ versus Mobile speed comparison.
The 4× Forward+ 8K probe completed correctly, but that profile was not exercised
for a full minute. Mobile retains 4× MSAA for the compositor's tested writable
texture path; see [temporal rendering](temporal-capture.md).

## Reading the memory and storage results

The reviewer samples every two seconds and retains every observation in
`memory-samples.jsonl`. These are sampled peaks, not exact instantaneous maxima.
It records the actual worker and coordinator PIDs, their child processes,
process private commit and working sets, process GPU dedicated/shared usage,
whole-adapter usage, whole-system used/available RAM, elapsed time, progress,
retained capture files and Movie Maker scratch files. Analysis stages are
identified separately from the product pipeline.

| Sustained profile | Process private commit | Process working set | Process GPU dedicated | Process GPU shared | Whole-system used RAM |
| --- | ---: | ---: | ---: | ---: | ---: |
| Forward+ 4K, 4× | 4.63 GiB | 3.89 GiB | 3.40 GiB | 0.19 GiB | 15.98 GiB |
| Mobile 4K, 4× | 4.63 GiB | 3.88 GiB | 2.17 GiB | 0.19 GiB | 15.80 GiB |
| Forward+ 8K, disabled | 15.65 GiB | 12.91 GiB | 5.44 GiB | 0.38 GiB | 24.74 GiB |
| Mobile 8K, 4× | 15.66 GiB | 12.86 GiB | 5.87 GiB | 0.38 GiB | 24.64 GiB |

All columns are sampled peaks over the monitored pipeline and review; CPU
maxima in these runs occurred during encoding. The sampled Movie Maker scratch
peak was 22.4–22.6 MiB, separate from retained capture storage. Whole-adapter
dedicated peaks were 4.55, 3.31, 6.59 and 7.02 GiB in table order and include
other applications. Engine video allocation peaks were 3.02, 1.86, 5.11 and
5.40 GiB respectively; these counters describe engine allocations, not physical
GPU residency. Raw stage and engine samples remain in the reports.

The sustained 8K Forward+ encoding stage reached **12.91 GiB of process working
set** and **15.65 GiB of private commit**, compared with **5.53 GiB** and
**10.09 GiB** respectively in its one-second probe. The full PNG/video review
is recorded separately. The short clip's sampled RAM use therefore cannot
certify a longer job's memory budget. These measurements use this machine's default FFmpeg/x264 threading;
other CPUs, tools and active applications can change the requirement.
Only the 32 GiB machine was tested; these results do not validate a 16 GiB setup.

CPU accounting uses PID-based Windows process APIs. GPU accounting uses
language-neutral Windows PDH counters. Process GPU totals, whole-adapter totals,
private commit and resident memory are different measures. Shared GPU memory
uses system RAM, and summed working sets or process GPU allocations can include
shared pages; do not add these columns together as a physical-memory total.
Peaks from different stages need not occur at the same time.
The engine's texture/buffer/video allocation counters provide a separate view.
See Microsoft's [process memory definitions](https://learn.microsoft.com/en-us/windows/win32/api/psapi/ns-psapi-process_memory_counters_ex)
and [GPU accounting explanation](https://devblogs.microsoft.com/directx/gpus-in-the-task-manager/).

The monitor requests cancellation if its configured time/storage budget is
exceeded, free disk falls below 16 GiB, or available system RAM falls below
3 GiB. These are benchmark guardrails, not product minimum requirements.
The product retains its own independent disk-space guard.

## Reproduce

Use the Python environment from [developer setup](testing.md). Native memory
collection currently requires Windows. Preparation creates about 98 MB of
original procedural texture assets plus Godot's import cache in an isolated
project. Use fresh output folders; existing captures are never overwritten.

```powershell
python tests/production_review.py --prepare-only --godot GODOT --ffmpeg FFMPEG --ffprobe FFPROBE --output .godot360/production-fixture
python tests/production_review.py --project .godot360/production-fixture/project --seconds 1 --width 4096 --face-size 1536 --method forward_plus --msaa 2 --godot GODOT --ffmpeg FFMPEG --ffprobe FFPROBE --output .godot360/production-probe
python tests/production_review.py --project .godot360/production-fixture/project --seconds 60 --width 4096 --face-size 1536 --method forward_plus --msaa 2 --godot GODOT --ffmpeg FFMPEG --ffprobe FFPROBE --output .godot360/production-full
```

Replace executable placeholders with absolute paths. Repeat in fresh folders
for `--method mobile`; use `--width 7680 --face-size 3072` for 8K. `--msaa 0`
disables MSAA, `1` selects 2× and `2` selects 4×. Use `--max-storage-gib` and
`--timeout` to set explicit per-run budgets. First inspect the short probe's
memory/storage use before choosing a larger job. Default limits are 80 GiB
and two hours per run.

`production-review.json` retains exact source and reviewer hashes, job settings,
timing, delivery checks and memory summaries. `source-snapshot/` and
`reviewer-snapshot/` preserve the code used for each run; generated texture
hashes point to the retained prepared project. Preserve all of these together.
Large evidence stays under the ignored `.godot360/production-review/` directory.

For a controlled capture-space failure, use a five-second run with
`--storage-fault-after 45` in a fresh output folder. The fixture changes only the
test guard's capacity reading; it does not fill the disk. A correct failure
stops after 45 submitted frames, retains diagnostics, produces no final MP4 and
reports that partial scene state requires a fresh render.

After a full run passes, the companion recovery reviewer exercises an actual
encoder interruption and retry from the retained production frames:

```powershell
python tests/production_recovery.py --source .godot360/production-full/capture --godot GODOT --ffmpeg FFMPEG --ffprobe FFPROBE --output .godot360/production-recovery
```

It injects a zero-capacity reading after the encoder launches, requires an
explicit failure and eligible recovery source, then performs a normal re-encode
in a fresh minimal project. It checks every decoded frame ID/flash and the audio
again, and SHA-256 hashes every original capture file before and after recovery.
The finished recovery record, not the presence of this command, is acceptance
evidence. Physical disk exhaustion, allocation failure and device loss require
separate evidence; the injected capacity controls do not establish those cases.

## Capacity failures and retained evidence — 2026-09-11

The five-second Forward+ 4K capacity control stopped after 45 submitted frames,
reported insufficient space, retained diagnostics and produced no final MP4.
Its partial source correctly requires a fresh render. A second control launched
the actual encoder against the accepted full Forward+ 4K capture, then injected
zero capacity. It failed explicitly and identified the original capture as
re-encodable. A fresh retry completed in 130.03 seconds without GPU recapture;
all 1,800 decoded identifiers/flashes and all audio checks pass. SHA-256 hashes
of every original capture file are unchanged. The existing five-second
endurance fixture also passes all 150 source and decoded frames after its
audio-preroll expression was moved into an overridable helper; its default
behavior is unchanged.

The four full runs, five accepted probes, capacity controls and recovery records
are retained under `.godot360/production-review/`. Each `full-*/` directory has
its capture, source/reviewer snapshots, memory samples, planner estimate and
final review. `audit.json` maps used runtime/fixture/reviewer sources to the
package and checks generated assets and protected settings. `hardware.json`
records hardware, tool versions and executable hashes. The archive also retains
`oracle-controls.json`, cut spot checks, `failure-capture/`,
`recovery-full-4k/` and `legacy-regression/`.

Four early `pilot-forward*` attempts are excluded: they exposed an invalid
particle property, background interference with the flash detector, incomplete
legacy process-counter accounting, and audio startup/reference calibration.
The corrected fixture and PID-based collector were fixed before the accepted
probes and full matrix. The original preparation record predates these fixes;
the per-run snapshots and hashes identify the actual tested source.
The prepared project's renderer-guide text and unused estimate helper predate
the final package. All addon runtime and the fixture/reviewer code used for
the full matrix match that package. The four 4× probes precede the equivalent
fixed-to-configurable MSAA change; the audit checks those exact source
differences and the preparation list's unused helper addition. Planner comparisons run separately
with the final helper and the same product planner; their settings match each
probe/full pair.

This evidence covers one procedural workload and one-minute clips on one GPU.
It does not certify heavier GI, skinning stacks, longer durations, other native
platforms or every scene's appearance. The exporter runtime remains unchanged;
new code supplies fixtures, telemetry and independent validation. See
[validation](validation.md) for the exact package and final regression record.

[Historical performance](performance.md) · [Job planning](job-planning.md) ·
[Storage and recovery](../addons/godot360/STORAGE.md)
