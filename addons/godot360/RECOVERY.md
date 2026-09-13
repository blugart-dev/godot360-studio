# Reopening and recovering an export

The addon reopens saved jobs, reconnects to running exports, and shows the next
action after failure or coordinator loss.
Keep the job folder: it contains the recipe, partial files and diagnostic logs.
Each new attempt uses a fresh output folder.

Exports also stop on insufficient working disk space and required write
failures. Free space or choose another output drive before retrying. A completely
unwritable drive may leave only the last complete checkpoint; reopening inspects
retained sources again. See [storage checks](STORAGE.md).

## Reopen a job

The panel inspects its last saved job when it starts. Choose an entry under
**Library → Recent exports** and click **Open**, or use **Open saved job…** for another
export folder. **Forget** only removes a history entry; it never deletes files.
Unavailable entries can be retried after reconnecting a drive. Locate moved
folders with Open saved job. This keeps the current recipe and audio controls; it
loads the selected job's status, available preview and recovery source.

- A running coordinator must answer a new request before the panel connects.
  After connecting, progress and **Cancel** work even if the original editor exited.
- Completed jobs restore the preview and, for test samples, the planning estimate.
  Completion requires both a successful report and `video-360.mp4`; an old Complete
  status alone is insufficient when those files are missing.
- **Re-encode this capture** selects the original completed PNG/WAV capture,
  including when reopening a failed re-encode. Current CRF/audio controls apply.
- If a coordinator cannot be confirmed within five seconds, cancellation remains
  disabled. The panel shows the last saved stage and inspects reusable sources,
  even when `recovery.json` was never written. Original status/logs remain intact.

A timeout means no live coordinator was confirmed; it does not prove the process
or its worker has exited. A busy coordinator or older addon may not answer. Reopen
the same folder to retry. An orphaned capture worker may still finish or require
attention in its original window. The panel never kills a saved process ID.

Live reconnection requires a coordinator started with 0.6.3 or later. Older jobs
can still be inspected and completed sources can be reused. Partial capture does
not resume, and Movie Maker audio left only in `movie/` is not promoted manually.

## How reconnection is established

Each coordinator writes a random per-run identity to `session.json`. Each client
uses its own random challenge in `control/`; replies must match the session, PID,
action and challenge. A saved reply cannot answer a new challenge. Connected
clients repeat the check every ten seconds and send cancellation through the
coordinator, which writes the existing cooperative cancellation marker.

Requests expire after ten seconds. The panel normally waits five seconds and
clears its request/reply pair. Concurrent panels use distinct files. A panel crash
may leave an unused reply; it is never accepted by a later client. This is a local
process-identity protocol, not an authentication boundary against writers with
access to the job folder. It adds no native process inspection dependency.

## Choose the next step

| What happened | Next step |
| --- | --- |
| Scene could not load, camera was missing, or a capture hook failed | Fix the scene/camera/hook and start a new render. |
| Capture was cancelled, closed early, or its worker/PNG encoder stopped | Start a new render after addressing the cause. Partial captures cannot resume. |
| Capture completed, but encoding, metadata or verification failed | Fix the reported issue and use **Re-encode saved…** with the original capture folder. |
| Re-encoding failed | Select the original completed capture again, using the corrected tools/audio settings. |

`recovery.json` contains `can_reencode`, `source_dir`, `source_error` and `next_step`.
For a failed re-encode, `source_dir` points to the original capture. Its PNG/WAV
files are not copied into the failed output folder and remain unchanged.

Re-encoding eligibility requires a successful capture result, the expected PNG
sequence with matching headers/dimensions, and a WAV header. These checks do not
fully decode every source file; FFmpeg and the final output checks still validate
the actual media. Restore damaged/missing sources from a complete backup or render
again. Soundtrack attachments remain separate files and must be available.

## Read the diagnostics

- `status.json` records the terminal state and primary error.
- `capture-result.json` records success/failure, the error when available, submitted
  frame count including warmup, expected total, and worker process ID.
- `capture-timings.json` retains timing samples even after a graceful failure.
- `render-progress.json` is a periodic snapshot, including the PNG writer process ID.
- `worker-exit.json` records the operating system's reported worker exit code.
- `capture.log`, `frame-writer.log`, `encode.log` and corresponding process logs
  explain the failing stage. `report.json` is available once verification runs.

On failure, a submitted-frame count does not prove that all those PNGs were fully
written. Fast PNG uses an external encoder and its last file can be incomplete.
A forcefully killed worker cannot write its final capture result; its last progress
snapshot can also lag behind. The coordinator reports the unexpected exit and
retains the available files. An exit code alone does not certify a capture: the
complete capture result and finalized WAV are also required.

Only an output that passes verification receives `video-360.mp4`. A remaining
`encoded.mp4` or `staged-360.mp4` is an intermediate file. Preserve the original
capture when retrying instead of manually renaming an intermediate file.

## What is not resumed

Capture does not restart at the last saved frame. Arbitrary scenes can depend on
physics, random state, particles, script history and Movie Maker's audio clock.
Even an absolute property timeline does not restore all of that state. A new render
starts the scene from its defined beginning and repeats its warmup.

Closing the editor leaves the independent pipeline running. Terminating the
coordinator itself or losing power can leave a stale status and no recovery file.
Reopening now inspects those retained sources and can offer a fresh re-encode when
the capture was finalized. It does not restart the coordinator, finish a stranded
worker's WAV, or restore arbitrary scene/audio state.

## Repeat the failure checks

The isolated compatibility reviewer can exercise all six disposable failure cases:

```sh
python tests/compatibility_review.py --capture-failures --job-recovery --godot /path/to/godot --ffmpeg /path/to/ffmpeg --ffprobe /path/to/ffprobe --output /path/to/new-run
```

Repeat `--godot` for multiple engines. The tests create their own scenes and jobs;
the termination cases target only worker/encoder IDs read from those jobs. They
check terminal states, retained diagnostics, recovery guidance, no final video,
and process exit. The panel test also fails a re-encode deliberately to verify its
recovery action and unchanged source hashes. Results appear in the compatibility
report and each isolated project's `lifecycle-review.json`.

`--job-recovery` also runs `recovery_studio_checks.gd`: actual panel restart,
an independent coordinator whose launcher exited, reconnected cancellation,
coordinator loss during GPU capture, a live unrelated PID with an obsolete reply,
and a verified re-encode from the recovered original source. The reviewer checks
source hashes and retained status and writes `recovery-review.json` and a panel PNG.
