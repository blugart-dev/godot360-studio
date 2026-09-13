# Storage checks and write failures

The addon checks the output drive before starting expensive work, during capture
and encoding, and while copying spherical metadata. Use local writable storage
for desktop exports. See [platform evidence](PLATFORMS.md#support-status). A one-second planning sample is still the
best estimate of the full render's file sizes and time.

## Space needed

New job folders contain `.gdignore`, so Godot does not import the exported
images and sound into its asset cache when the destination is inside your
project. Use **Open folder** to browse these files in the system file manager.
The marker applies only to that job folder; other project assets remain visible.

The guard keeps a 256 MiB reserve. Capture adds a conservative allowance for four
uncompressed RGBA images plus PNG overhead and stereo 32-bit PCM for the full
capture duration. The image allowance covers frame delivery and Movie Maker's
current/previous scratch images. Re-encoding does not reserve another PNG sequence.

Before metadata, available space must also cover the encoded MP4's size, up to
64 MiB for metadata, and a preview image. This is additional space: encoded.mp4
already exists and the delivery copy is a second file. The encoder and copy loop
continue checking the reserve. Free-space reads are cached for at most 250 ms.

The planning suggestion includes the estimated retained files plus 25%, the
reserve and capture working allowance. It is a forecast, not allocated storage.
Other applications, quotas, removable drives and filesystem failures can still
change what can be written between checks. A zero free-space response stops the
job; an unavailable drive/query produces an access diagnostic.

## Failure behavior

Insufficient space stops capture cooperatively or cancels the active codec process.
The error records the stage, available bytes and required working headroom.
Capture-side failure leaves partial frames; a finalized capture remains available
for a fresh re-encode. The original retained source is never modified by re-encoding.

Required JSON writes check open, flush and atomic rename. A failed update leaves
the previous JSON checkpoint intact. Capture settings, progress, timings, result,
worker-exit evidence, preview, planning, storage and verification report writes
are checked. Process-log writers report write failures while continuing to drain
their pipes, preventing a full stderr pipe from blocking shutdown.

The successful report is saved before staged-360.mp4 receives video-360.mp4. If a
required earlier write fails, the verified intermediate stays under its staged
name. A failure to save the final status after the media rename can still leave a
valid delivered video and successful report; reopening recovers that completion.
No single filesystem transaction spans the report, media rename and status file.

If the drive stops accepting all writes, new status/recovery files may be impossible.
Read the coordinator/capture console or retained logs, free space, and reopen the
job. The panel preserves the last complete status and rechecks retained sources.
Space checks do not promise to survive power loss or resume partial scene state.

## Evidence and repeatable tests

storage-checks.json records coordinator capacity checks at stage boundaries and
failures. render-progress.json and capture-timings.json include worker samples;
capture-storage.json is written on a worker-side low-space failure.

The compatibility reviewer accepts --storage-failures alongside --capture-failures
and --job-recovery. Its fixtures inject capacity readings and create blocked paths
inside disposable jobs. They do not fill the real drive or change its permissions.
Tests cover preflight, capture, active encoding, metadata copying, status/progress/
result/report/preview writes, real Fast/Compact PNG output failures, and a verified
re-encode from a source retained after failure. This is controlled failure evidence,
not a physical full-disk or unplugged-drive test.
