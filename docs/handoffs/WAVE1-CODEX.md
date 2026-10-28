# Codex Wave 1 — final delivery

Implementation and native verification: **DONE**. Owner: Codex.
Branch: `codex/roguewood-build`. Final executable fix: `8a131a0`.
This records the agent's work; there is no pending-owner review state.
The containing commit identifies this documentation delivery. Coordinator owns
updates to AI-HANDOFF.md; this file supersedes the older Codex checkpoint there.

## Delivered scope

| Batches | Result | Evidence commits |
|---|---|---|
| E19-A01…A07 | All 25 E13-S01 identities: original card/icon, in-play look, rarity and reduced-motion slots, hand/shop/inspect/rack/equipment/binder bindings | Batch handoffs; final A07 `a46c5ed` |
| E21-R01, E21-R02 | Surveyor and Custodian: six portrait states each, intro/reaction/result/reward identity, cosmetic lane treatment, Dead Straight/Clean Sweep glyphs and original audio | `c73799b`, `cecd4d6` |
| E20-V01…V07 | All 23 assigned ability/rule effect and audio sets, causal event bindings, reduced-motion/flash variants, priorities and session sound controls | `8e2c3f2`, `35c073a`, `8c560d9`, `6166ee8`, `61f4b99`, `431a769`, `2add1fd` |
| Dense effects journey J12 | Real Echo strike with five Charms, native mute/volume/effect controls, silent Skip, unchanged score/inventory, actual Investor shop settlement, portrait/landscape/reduced captures | `2add1fd` |

`artwork=true` for all 25 items; `effects_audio=true` for the 23 assigned abilities.
House Ball and House Kit remain false for effects/audio because no ability was
assigned to them. The `integrated` flags remain coordinator-owned; this delivery
does not claim completion of the entire E19/E20/E21 families or the final release.
Sources, prompts, recipes, SHA hashes and provenance are in docs/art/ASSET-LEDGER.md.
Original PCM foley uses no external samples. Gameplay state is never written by
presentation, and the campaign's provisional rival IDs are not art aliases.

## Verification

Godot 4.5.2.stable.official.6ce3de25a; Linux x86-64; Xvfb/llvmpipe for rendered checks.

- Unit, content, integration, physics, smoke and Linux export/boot: PASS.
- J01–J11, J12, J12R02 and J12V01…V07: headless and rendered PASS in the final
  combined matrix. Earlier batch-specific J08A01…A07, J08A06R and J12R01 also
  passed both modes; their native-size contact sheets and live captures were inspected.
- J03 retains 560/240/70; J05 retains 21060; J06 retains its original targets and
  awards. Physics digest is unchanged:
  `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
- Initial fixed-fps headless runs exposed a WAV playback teardown leak. `8a131a0`
  stops/releases voices and, for Dummy audio, waits for an actual completed mixer
  pass (bounded to one second). A 4096-frame Dummy buffer outlasted the former
  50 ms delay. Three consecutive fresh J02 runs plus J03/J05/J06/J07/J10/J12
  headless and a fresh rendered dense J12 pass with the fix.
- Claude's `5ecc1f0` corrected the obsolete E13 no-art assertion, merged with a
  merge commit `1173592`. The owner's separately authorized two Clubhouse art
  assertions were updated in `92ce404`; all other Clubhouse checks are preserved.
- Scope audit against coordinator `5ecc1f0`: only allowed asset/completeness
  fields changed for the 25 catalogue entries; every referenced resource exists.
  Rules/simulation/persistence/Career/procedural/throw_lab/clubhouse_model unchanged.
  qa.py, run_tests.gd and the shared workflow changes are add-only.

Local logs: `artifacts/wave1/validation/`. `final-results.json` consolidates the
original matrix with the export and audio-fix reruns; `initial-failures/` retains
historical diagnostics. Batch captures are in artifacts/e19-a01…a07,
artifacts/e21-r01/r02, artifacts/e20-v01…v07 and artifacts/e20-dense.
Screenshots are ignored, never committed; the Bootstrap CI journeys artifact
regenerates and uploads them. CI on executable commit `8a131a0`:
[Bootstrap run 40633591372](https://github.com/khoix/Roguewood/actions/runs/40633591372).
Its completion is recorded separately from the native verification above.

## Density and practical limits

Four fixed world glyphs and at most four prioritized audio voices bound activation
density. All 23 authored WAVs are mono 22,050 Hz 16-bit, peak at most 0.48; at the
0.35 voice gain the four-voice full-volume peak bound is 0.672. This is a digital
level check, not speaker/listening certification.

The final rendered dense run records 735 monitor samples, 95 p95 draw calls,
49.901 ms p50 / 205.3 ms p95 Godot CPU process time under llvmpipe, including cold
startup. These CPU monitors are repeated at game-frame sampling, not GPU timing.
This software-renderer result does not establish 60 FPS. Physical-phone performance,
readability, audio latency and speaker checks remain E26; no device pass is claimed.
The dense bank remains 4800 with four fixed glyphs and at most three simultaneous
voices in this run (other runs reached the tested four-voice limit).

## Next hand-off

All claimed Wave 1 batches above are complete. The requested follow-on is
E17-D01-ART: eleven written visual briefs using the authored trigger, tags,
presentation needs and exact asset IDs; see its separate handoff when delivered.
E16-ART remains a separate READY follow-on with exclusive presentation paths and
its asset drop list in E16.md. It was not one of the claimed Wave 1 batches and
no E16 art completion is claimed. Proposed effort: Medium for E16-ART and ordinary
E19 identity batches; High for complex Spark/Ghost/Splitter presentation.
