# Soundtracks and synchronization

Audio controls are available in the studio panel, portable recipes and CLI jobs.
They apply during encoding, so you can adjust a completed capture without running
its scene again. Recipes without audio fields default to scene audio.

## Choose the audio source

- **Scene audio** uses the stereo WAV recorded by Godot Movie Maker.
- **Soundtrack only** replaces that mix with the first audio stream in the selected file.
- **Scene + soundtrack** combines both sources with independent levels and offsets.

Use **Soundtrack…** to select a WAV, FLAC, MP3, Ogg, M4A or AAC file. Actual support
depends on the installed FFmpeg decoders; the file must contain mono or stereo
audio. Mono is converted to stereo and other sample rates are converted to 48 kHz.
The pipeline probes the file before scene capture, so corrupt or non-audio inputs
fail early. Multichannel audio must be downmixed explicitly outside the addon.

The 0.6.1 format review covers PCM WAV, MP3, Ogg Vorbis, Ogg Opus, FLAC, AAC in M4A
and raw ADTS AAC, with selected mono/stereo inputs from 22.05 to 96 kHz. It also
checks a 90-second mix with cues distributed through the film. See [BETA.md](BETA.md)
for the precise matrix. These are tested fixtures, not every profile of each codec.

Timing starts from the samples FFmpeg decodes. Container delay/padding information
can affect those samples, especially when the same music is supplied in different
formats. The addon does not infer or remove an extra musical startup offset. Check
alignment against the selected file and use the explicit offset when needed.

## Timing and level controls

All offsets are relative to **delivered video frame zero**. Scene warmup is removed
before applying the scene offset; it is never removed from an attached soundtrack.

| Control | Meaning |
| --- | --- |
| Soundtrack trim (s) | Skip this amount from the beginning of the attached file. |
| Soundtrack offset (s) | Place the trimmed soundtrack later with a positive value; advance it with a negative value. |
| Scene offset (s) | Delay or advance the recorded scene mix after warmup removal. |
| Level (dB) | 0 preserves the source level; negative values reduce it, down to −60 dB. |

For example, a cue at 2.0 seconds in an attached file, with trim 0.5 and offset
+0.25, appears at video time **1.75 seconds**. A scene cue at delivered time 1.0
with scene offset −0.1 appears at **0.9 seconds**. Negative offsets discard audio
that falls before frame zero; they cannot recover sound missing from the recording.

Trim and offsets use the nearest 48 kHz sample. The panel provides millisecond
steps; CLI recipes may use finer values. Short sources are padded with silence,
and long sources are trimmed to the delivered video duration. An offset can place
the entire source outside the film, producing silence. Source files do not loop.
Trimming at or beyond a known soundtrack duration is rejected as a likely mistake.

Mixing adds the chosen levels without automatic loudness normalization. A peak
limiter at 0.95 controls the combined signal, with lookahead latency compensated.
It can change dynamics when loud sources overlap; reduce their levels for more
headroom. AAC encoding can produce small reconstructed peaks above the limiter's
PCM ceiling. Single-source modes do not apply the mix limiter.

The resulting mix is ordinary stereo, not spatial or head-tracked audio. These
controls do not infer synchronization automatically or edit AnimationPlayer audio
tracks. The included Motion Lab's measured startup compensation remains local to
that example; adjust scene offsets from your own observed cue alignment.

## Re-encode and share recipes

Set the audio controls and CRF, then choose **Re-encode saved…** and select the
original completed capture folder. The panel uses the current audio controls;
the saved capture supplies video dimensions, frame rate and warmup. It preserves
every original PNG/WAV and creates a fresh output folder. A complete original
capture, including its WAV, is still required even in soundtrack-only mode.

An attached file is an external input: it is **not copied into the capture folder
or embedded in the recipe**. Keep it available. Project-relative `res://` paths
travel with a project when you copy that asset too; absolute paths are machine
specific. Jobs record the resolved path and the soundtrack's SHA-256 in the audio
report. A source change detected during capture/encoding rejects the job before
the final filename is assigned.

CLI re-encodes inherit the saved audio settings when those fields are omitted.
Supplying any audio field overrides it. An explicit `soundtrack_path` replaces
the saved resolved path. This example replaces scene audio without capturing again:

```json
{
  "mode": "reencode",
  "source_dir": "/absolute/path/to/original-capture",
  "output_dir": "/absolute/path/to/new-output",
  "ffmpeg": "/absolute/path/to/ffmpeg",
  "ffprobe": "/absolute/path/to/ffprobe",
  "crf": 16,
  "audio_mode": "soundtrack",
  "soundtrack_path": "/absolute/path/to/music.wav",
  "soundtrack_trim_seconds": 0.5,
  "soundtrack_offset_seconds": 0.25,
  "soundtrack_gain_db": -6.0
}
```

The other fields are `scene_audio_offset_seconds` and `scene_audio_gain_db`.
`audio_mode` accepts `scene`, `soundtrack`, or `mix`. Offsets are limited to ±3600
seconds, trim to 0–3600 seconds, and gains to −60–0 dB. All values must be finite.

## Planning and verification

**Test 1 second** uses the same audio timing as the full film. It does not move a
later musical cue into the opening sample. Changing active audio settings or the
attached file's path, size or modification time invalidates the saved estimate.
Retained-storage estimates exclude the external soundtrack because it is not copied.
The panel signature is a quick file check; execution separately uses SHA-256.

Every output must pass thirteen checks, including audio duration within one sample
of video duration. AAC decoding may expose a final partial codec block of padding;
the MP4's declared duration stays tied to the film.

`tests/audio_checks.gd` covers recipe/settings contracts. `audio_studio_checks.gd`
exercises real panel capture, planning and re-encoding. `audio_review.py` generates
independent source cues and compares the fully decoded AAC against the expected
sample placement, including 24/30/60 FPS, mono resampling, offsets, trim, silence
padding and mixing. `audio_delivery_checks.py` checks the limiter, unchanged legacy
encoding, and rejection when an attached file changes during a job.
`audio_formats_review.py` adds compressed formats and the 90-second mixed export.

Primary filter documentation: [FFmpeg audio filters](https://ffmpeg.org/ffmpeg-filters.html),
including sample-count delay/trim, mixing and limiter latency compensation.
