# AV-C03-A — Crown Pin, Crown Jewel, Split Specialist

Implementation and scoped verification: **DONE**. Codex, `codex/roguewood-build`, coordinator base
`2299a3a`; first of two three-item sessions in Wave 5's AV-C03 claim.

## Before: scope, provenance and evidence

- Exact IDs: `pin.crown`, `charm.crown_jewel`, `charm.split_specialist`.
- Retain all existing D01/D02 identity paths and original art. Native shop purchase,
  owned inventory/rack and binder must pass before artwork flags are set.
- Add the exact `activation.<id>` and `sound.<id>` slots from landed design blocks.
  Original procedural vector glyphs and deterministic PCM foley, no external samples.
- Crown: crown settling on the last-pin pedestal, slot number and +40; the explained
  zero uses an unlit crown and explicit 0, without a victory sound. Crown Jewel
  repeats the last-pin crown motif at its own resolver row and shows ×2.
- Split Specialist: first-roll leave pips and actual leave count with the ×3 result.
  Its caliper identity remains visible; no suggestion that every spare qualifies.
- E12 reduced motion/flash freezes the construction while keeping the outcome/count.
  Native controls, silent Skip and 4× replay must leave score and inventory unchanged.
- `JAVC03A`: real shop/placement/binder; J03C03 deterministic split/conversion and
  strike; both Crown +40/0 cases, quiet non-trigger frame, independent bank checks,
  cosmetic body invariants, portrait/landscape/reduced captures and audio starts.
- Unit projection checks must cover the explicit zero rows inserted by ScoreLog:
  they are not resolver events and cannot shift subsequent Charm activations.
- Re-run unit/content, affected native journeys in both modes, physics, J03/J05/J06
  invariants. Do not edit rules, simulation, persistence or coordinator-owned files.

## Delivered and verified

Three exact activation/sound pairs and all six completeness flags are set, after
native headless/rendered checks of real shop offers, purchases, rack/inventory,
binder and activations. Original identity resources remain unchanged. Crown uses
the existing cosmetic PackedScene support on the actual RigidBody3D; repeated
dressing and score effects preserve body IDs, mass, layers, masks and shapes.

The first actual split/conversion banks 1680: leave 4, Crown 8 +40, Crown 6 a
silent explicit 0, Split ×3 and Jewel ×2. The next strike banks 1280: Crown 6
+40 and Crown 8 zero, with no Split cue. A double gutter cues none of the three.
Every bank matches independent FrameBuilder/Rules resolution. Each native cue
is checked against its exact explanation row, including at 4× speed. Crown/Jewel
read result.facts.last_fallen; Split reads result.facts.leave. No animation state
is a scoring input. Effects controls, audio mute/volume, reduced motion/flash and
silent Skip leave bank, inventory and effects stream unchanged; max four voices.

ScoreLog's explicit zero rows are not resolver events. The new read-only
ability_score_rows projection accounts for those rows before accuracy so later
Charm effects stay aligned. It never parses displayed text, changes ScoreLog or
writes to rule state. Unit cases cover one/two zeros and all later events.

Validation: unit/content with final flags PASS; JAVC03A and JAVC03AC headless and
rendered PASS, inspected captures. Physics digest remains `75d1a3c0…`; J03 retains
560/240/70, J05 21060 and J06 its existing outcomes (headless PASS). Wave-wide
regressions are recorded in WAVE5-CODEX at closure. No full CI run is claimed here.

Evidence (ignored): `artifacts/av-c03-a/native/{headless,rendered}/metrics.json`,
individual shop/binder/activation captures, Crown zero, crown_rack_detail, reduced
and landscape; `contact/rendered/contact.png`. Tests use Godot 4.5.2, Xvfb/llvmpipe
and Dummy audio: actual AudioStreamPlayer starts and deterministic PCM are checked;
audible device mix, phone readability and platform performance remain Claude's E26.
Provenance and WAV hashes are in ASSET-LEDGER. Screenshots are not committed.

## Hand-off

The containing commit delivers AV-C03-A on codex/roguewood-build for coordinator
integration. Next is AV-C03-B (High): Sweet Spot, Back Row and Underdog; then the
E17-D04-ART briefs (Medium). No next-wave work or modification flags are included.
