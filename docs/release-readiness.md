# Godot360 Studio 1.0 release acceptance

**Windows supported; Linux/macOS experimental.** The owner authorized public
release on 2026-09-13 after the final private acceptance checks and explicitly
selected **preserve the reviewed history**. This supersedes earlier publication
holds. [Release notes](release-1.0.md) describe installation, scope and limits;
[publication review](publication-review.md) records the distribution steps.

## Accepted product scope

Godot360 exports a saved, authored 3D scene as mono 360° SDR BT.709 video with
stereo audio, then verifies and reviews it. The [support contract](../addons/godot360/SUPPORT.md)
defines five Windows engine/renderer combinations and bounded scene/effect setups.
Native Linux/Mac hardware acceptance is required before promoting those platforms.

| Gate | Evidence |
| --- | --- |
| Windows workflow | Exact private stable addon: 6,070 checks across five native package lanes, plus 52 native editor checks covering first launch and restart. |
| Source examples | Clean stable source import/startup and 247 scene/rendered-workflow checks; 101 protected creative/project/fixture files unchanged. |
| Release identity | Plugin, panel, metadata, guides and installation README agree on 1.0.0; six package-identity regression tests pass. |
| Archives | Manifest verification and byte-identical rebuilds. Public guides require fresh archives and exact runtime/fixture mapping; see the dated validation record. |
| Repository and credentials | Repository guard and its seven regression tests pass. Redacted source/all-ref credential scans are clean. Licenses and media provenance are retained. |
| Human feedback | The owner reported “I did not get any errors” after RC2. No itemized listening, headset or current YouTube acceptance was supplied or claimed. |
| History and publication | Owner explicitly authorized publication and preserving reviewed history, including six historical planning-document blobs containing workstation paths. No history rewrite is needed. |

The [validation record](validation.md) retains exact commits, archive identities,
native results and hosted results. Older private/RC checkpoints are historical;
they do not override the current authorization or silently certify changed bytes.
Public documentation changes preserve runtime/tests/fixtures; any runtime change
requires applicable fresh acceptance checks.

## Follow-up work and continuing limits

- Investigate the recurring experimental Linux software-Mobile first-five-frame
  history mismatch. Keep its original limits and negative controls; no renderer
  fix or all-green hosted matrix is claimed. Windows Mobile passes separately.
- Test native Linux GPUs and Mac graphical exports before offering platform support.
- Gather broader Windows/GPU and real-project feedback. Measured production
  budgets cover four one-minute 4K/8K workloads on the reference machine.
- Review each external-service upload and playback device before making specific
  processing, audio or headset claims.
- Preserve authored exposure, view-dependent effect limits, particle warmup and
  per-view compositor history requirements. Shared automatic spherical exposure,
  arbitrary IK/shader stacks, stereoscopic ODS, HDR and ambisonics remain extensions.

Publication is complete: `main` was fast-forwarded, `v1.0.0` tags the tested
source, the release is public with four verified downloads, and private
vulnerability reporting is enabled. Anonymous downloads match the accepted bytes.
[Publication review](publication-review.md) records exact hashes and CI status.
The [publishing checklist](publishing.md) applies to subsequent releases too.
