# Wave 12 — Codex completion index

Status: DONE — all five Codex Wave 12 batches complete.
All assigned assets are delivered and Claude's required hooks are merged.
No Wave 13 AV-N1/AV-N2 work started.

## Branch and integration

Branch: `codex/roguewood-build`. Initial claims a5114b6 merged at b32ab1e.
Final coordinator prerequisites through a034d61 merged with commit ede1f02.
No rebase, force-push, main push or pull request.

Claude's d19f9f7 binds the live Neon theme and fixes the two-rule bar height;
a034d61 fixes the hand placement and portrait bubble. The prior Codex blockers
are resolved. Final Codex changes enable Strobe, register J21R07/J21R07DJ and
J22L02RULEART, and add J22L02LIVEART with all parent League checks retained.
Only presentation binding, art tests/registration, manifest status and scoped
documentation change. QA/CI additions are add-only and art-shard guarded.

After this checkpoint, Claude merges the final Codex branch, runs the full
integration matrix and records Wave 12 closed. Those coordinator actions are
separate from completion of Codex's assignments. No remaining Codex hook request.

## Delivered batches

| Batch | Delivery | Asset checkpoint |
|---|---|---|
| [UI-A3](UI-A3.md) | Distinct curved 2/5 in bundled font, internal family Roguewood Numerals; original metrics/other glyphs preserved, OFL and reserved-name record | 05ff30d |
| [E21-R05](E21-R05.md) | Slick identity/motion/reactions/reduction, Oil Slick seal, Slick plaque and three missing House plaques | 27548ff |
| [E21-R06](E21-R06.md) | Laser Lena identity/motion/reactions/reduction, Narrow Lane seal and plaque | e4b91bf |
| [E21-R07](E21-R07.md) | Regular DJ and Champion identities, motion/reactions/reduction, Strobe seal, paired Champion seals, both plaques | 5566b6b plus final binding |
| [E22-L02-ART](E22-L02-ART.md) | Nine environments/signs/backdrops; lane finishes, rail/ring art, music, five frames, two ornaments, flank/reduction, trophy | 9e91b31 and 2671841 plus final validation |

The optional corner/divider kit resources have no live consumer, matching House.
All required live room/lane/music/frame/flank hooks are bound. Provenance and
sources are recorded in docs/art/ASSET-LEDGER.md and each batch's brief.

## Final validation

Evidence: `artifacts/wave12/final/results.json` and individual command logs.
Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, Xvfb :106, LP_NUM_THREADS=2,
writable XDG configuration/cache/data under /tmp.

All 34 final QA commands PASS (3 base checks, 11 affected journeys in both
modes, 9 additional headless regressions).

- Unit, content and physics: PASS.
- Headless and rendered: J21R07DJ, J21R07, J22L02RULEART, J22L02LIVEART,
  J21R07C, J03C13, J21R05, J21R06, J11ART, J22L02ENV and J22L02ART: PASS.
- Physics digest unchanged:
  `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
- J03 remains 560/240/70; J05 remains 21060. Both headless reruns PASS.
- Additional headless regressions J02, JAVT01, J06, J22L01, J11, JUIA1 and
  JUIA2: PASS. Their earlier rendered validation remains in the batch handoffs;
  this final run does not claim to have rerun those seven rendered variants.
- Workflow YAML and all eight added art-guarded commands checked; diff passes
  whitespace validation and no captures or prohibited ownership paths are added.

The original J03C13 passed both modes on the coordinator merge before Strobe
was enabled. No layout, bank, progression, geometry or motion assertion was
removed. The prior coordinator baseline was all 214 CI commands passing on
d19f9f7, with affected checks rerun after a034d61. This Codex run is scoped to
affected journeys and requested regressions; Claude runs the full post-merge
matrix. No physical-phone or hardware audio validation is claimed.

Final visual inspection includes regular DJ's introduction, the Champion's
paired seals, Narrow Lane portrait, Strobe landscape, both live feature lane
finishes and live Championship portrait/landscape. The two-rule bar and hand
have clear separation; authored seals, frames, flank and room identity are
present. Native live captures complement the earlier full-room inspectors and
actual-size rival contact-sheet review.

## Owner capture index

Captures are local, ignored and never committed. Regenerate using the named
journeys through tools/qa.py with --rendered.

UI-A3, both full 26-screen tours at 780x1688:

- `artifacts/ui-a3/{before,after}/18_frame_done.png`: score slip,
  140 × 5 = 700, frame review and rack numbers.
- Same folders: 17_scoring.png, 19_shop.png, 22_shop_after_buy.png,
  14_tuning.png and 15_aim_assist.png: reveal, prices, money and tuning.
- `artifacts/ui-a3/uia3-type.png` and uia3-type-3x.png: 16/20/24/30/36px,
  source versus patch at 2× and 3×.

Rivals and plaques:

- `artifacts/e21-r05/contact/rendered/{normal,reduced}.png`: Slick and four
  plaques, including Proprietor, Old Lou and Custodian Champion.
- `artifacts/e21-r05/native/rendered/slick_{intro,landscape,normal,reduced,reaction,defeated}.png`.
- `artifacts/e21-r06/contact/rendered/{normal,reduced}.png` and
  `artifacts/e21-r06/native/rendered/laser_lena_{intro,landscape,normal,reduced,reaction,defeated}.png`.
- `artifacts/e21-r07/contact/rendered/{normal,reduced,champion_normal,champion_reduced}.png`.
- `artifacts/e21-r07/regular/rendered/dj_flicker_{intro,landscape,normal,reduced,reaction,defeated}.png`.
- `artifacts/e21-r07/champion/rendered/dj_flicker_champion_{intro,landscape,normal,reduced,reaction,defeated}.png`
  and champion_seals.png: now passing the bar/hand layout checks.

Neon theme:

- `artifacts/e22-l02-art/environment/rendered/`: contact.png, division_01.png
  through division_08.png, championship.png/reduced.png at 780x1688,
  landscape.png at 1688x780.
- `artifacts/e22-l02-art/theme/rendered/{long_oil,two_tone,lane_reduced,lane_landscape}.png`:
  oil boundaries, matte cross-grain dry regions and non-colour markers.
- Same folder: kit_normal.png, kit_drift.png, kit_reduced.png,
  kit_reduced_later.png, kit_landscape.png: frames, backdrop and trophy.
- `artifacts/e22-l02-art/rules/rendered/c13_{narrow_lane,champion}_art_{normal,reduced,landscape}.png`.
- `artifacts/e22-l02-art/live/rendered/`: live_d01_opener.png through
  live_d08_opener.png; live_d02_feature.png and live_d03_feature.png;
  live_d08_boss.png, live_champion_normal.png, live_champion_landscape.png;
  j22n_champion.png, j22n_title.png, j22n_attempt2.png.
- `artifacts/e16-art/native/rendered/neon_trophy_shelf_{720,1280}.png`.
- Audio to audition: `assets/leagues/neon/music.league.neon.circuit.wav`.

## Stop point

Stop after Wave 12. No further Codex implementation is waiting on Claude.
Coordinator: merge the final checkpoint and run the full matrix before closing
the wave. A future wave needs its own claims; AV-N1/AV-N2 are not started here.

Owner preference: flag any mismatch with the proposed effort before proceeding.
Rival/theme sessions and this final integration use High; UI-A3 used Medium.
