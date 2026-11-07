# Wave 10 — Codex delivery index

State: DONE (Codex implementation and verification). All four assigned children are complete.
Branch: codex/roguewood-build. Latest implementation: 9986f6710c6453267f2080f9ce5df78e7cda2d3b.

| Child | Checkpoint | Handoff |
|---|---|---|
| UI-A1-C — layout and backdrop options | 5fb5cecc178811b236605fb29872f82a4d8ee0a8 | [UI-A1-C.md](UI-A1-C.md) |
| UI-A2 — House materials and icons; denser, distinct sky patterns | dc5877e88e768ac9512c52534c73ecca7cfbe290 | [UI-A2.md](UI-A2.md) |
| UI-A1-C — faint lines and verified motion | 47bf589 | [UI-A1-C-motion.md](UI-A1-C-motion.md) |
| AV-H4-A — Double Take, Called Shot, Pin Count | bd44d9cfb1942e9791fdd624965889f48e8485ad | [AV-H4-A.md](AV-H4-A.md) |
| AV-H4-B — Cleanup Crew, Lucky Seven | 9986f6710c6453267f2080f9ce5df78e7cda2d3b | [AV-H4-B.md](AV-H4-B.md) |

Coordinator merges were preserved: Wave 10 claims 2864889, UI-1 via d51149c,
and E05-R2 through ec9cabc via a83baff. No rebase, force push or PR to main.

## Delivered

The standalone layout target has a full-width landscape lane, 19% side panels,
four-card hand, narrow-screen folds and three-column shop. Portrait follows the
approved hierarchy, with separate money cell, slip/rival and Charm strips,
ball at two-thirds height, two-card hand and mirrored thumb controls. Spec:
[UI-A1.md](../art/ui/UI-A1.md). No production UI scripts were edited by Codex.

Both House backdrop options now have 240 mostly dim stars. Constellations uses
four distinct schematic figures (Orion, Cassiopeia, Cygnus and Ursa Major's Big
Dipper), each once. Their lines use 18% alpha; bounded constellation drift is
about 1 px/s at 1280 wide, slower than the surrounding starfield. Normal mode
moves; reduced motion/flash is static. These are decorative recognizable
patterns, not a map of astronomical coordinates. House theme bindings are stable.

UI-A2 delivers five House rarity overlays, five reduced resources, a League-keyed
frame manifest with explicit House fallback, and nine action/state icons beside
the eight stable category/score icons. Integration contract:
[UI-A2.md](../art/ui/UI-A2.md). Explicit progress, no autonomous TIME animation;
protect live text and category badges. Compact layouts need mapped masks.

All five E17-D10 items have six authored asset slots and both completion flags.
Counted feedback reads resolver events/facts and committed frame snapshots.
Double Take attributes stacked repeats exactly; Called Shot has a silent grey
miss; Pin Count ticks the paid count; Cleanup Crew shows the actual leave versus
2; Lucky Seven lands on 7 only for the eligible exact-seven open frame. All have
original identity art, activation, procedural sound and reduced states.

## Verification

Closing matrix PASS on the implementation SHA above: all 39 journeys in both
headless and rendered modes (78 runs), plus unit/content/physics. Repository
qa.py commands only, pinned Godot 4.5.2, Compatibility/Mesa llvmpipe. Results and logs:
artifacts/wave10-codex/validation/. Batch checks are in the neighboring av-h4-a,
av-h4-b and ui-a2 directories. No screenshots or rendered captures are committed.

The required matrix has 39 journeys in each mode: J03, J05, J06, J22L01,
J03C01–C11, JAVC03A/B, JAVC04A/B/C, JAVH1AC/BC, JAVH2AC/BC, JAVH3AC/BC,
JAVH4AC/BC, JUIA1, JUIA2, J22L01ART, J21R03/R04/RC, JAVC07AC/BC, J11ART,
J12V08 and J19A16. J03C06/07 are the AV-C06/C07 native journeys.
Unit/content/physics passed the closing gate. Verified invariants: physics digest
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f;
J03 560/240/70; J05 21060. qa.py, run_tests.gd and CI changes are add-only.
Every new art step has the art-shard condition and a valid artifact upload path.

One local JAVC04B rendered run hit the unchanged 900-second timeout while
three journeys ran concurrently. Its log is retained as
JAVC04B-rendered-parallel-timeout.log. The isolated rerun passed in 443.2 seconds
without a code or timeout change; results.json records all 78 final passes.
The same journey also passed in remote CI. No failing assertion was suppressed.

Remote CI on implementation 9986f6710c6453267f2080f9ce5df78e7cda2d3b:
- [Bootstrap](https://github.com/khoix/Roguewood/actions/runs/42272019619): PASS,
  both game and art shards.
- [E11 still review](https://github.com/khoix/Roguewood/actions/runs/42272019516): PASS.
- [E12 motion review](https://github.com/khoix/Roguewood/actions/runs/42272019789): PASS.
The final index/spec clarification commit changes documentation only; the
coordinator still validates its eventual integration tree.

## UI-A1-C captures for owner review

All under artifacts/ui-a1/rendered/, produced by JUIA1 and uploaded by its
existing art-shard step. Options: **0 Slow stars**, **1 Constellations**.
Each has **motion** and **still** states.

| Layout | Throw and shop capture pattern |
|---|---|
| Landscape 16:9 | 1280x720_{0,1}_{motion,still}_{throw,shop}.png |
| Landscape 4:3 | 1024x768_{0,1}_{motion,still}_{throw,shop}.png |
| Portrait | 720x1280_{0,1}_{motion,still}_{throw,shop}.png |

Also review folded_hand.png, folded_details.png and left_handed.png. The ten
original card/frame/composition captures remain. That is 37 still compositions
plus sky_motion_00.png through sky_motion_23.png: 61 required captures total.
The local sky_motion.mp4 plays those actual native frames at 12 fps; five engine
frames separate samples at fixed 60 fps. The test verifies changed normal pixels
and pixel-identical reduced pixels after a second. No synthetic motion was added.

For UI-A2, review artifacts/ui-a2/rendered/{phase_a,phase_b,base}.png. Material
studies are explicitly labelled; no catalogue rarity was invented. For AV-H4,
review artifacts/av-h4-{a,b}/contact/rendered/ and the h4_ captures in
artifacts/e18-c11/rendered/. Phone readability, physical throw feel and subjective
audio mix remain device/owner checks; no certification is claimed here.

## Coordinator hand-off and resume

Codex Wave 10 is complete. Claude integrates these commits through claude/roguewood-build and runs its
integration CI before the Wave 10 closure merge. The UI-A1-C owner decision is
the dependency for UI-2; UI-A2's asset integration contract is ready for UI-1.

One pre-existing rules-text issue remains for Claude: score_log.gd _cause chooses
the first non-ball retrigger owner for every repeat on that roll. With stacked
Echo Ball/Echo Charge/Double Take, text can share a label across different causes.
Art attribution is exact; scores are unchanged. Reproduction and ownership are
recorded in AV-H4-A.md. Codex did not edit the owned rules path.

Do not start Wave 11 here. Next planned Codex work is AV-T01 after its claims,
High recommended, using the now-landed tethered swing. No Neon/future League art
or throw effects were started in this wave.
