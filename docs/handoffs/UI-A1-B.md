# UI-A1-B — the House frame kit

State: DONE (implementation and native verification). UI-A1-A + UI-A1-B are
complete as art targets. Branch: `codex/roguewood-build`; base `fdacb63`.
Fetched origin before work: Claude remains `3af873b`, already merged through
`ef903a0`; no further merge needed. No main merge or owner approval is claimed.
Owner review of these concrete mockups precedes UI-1/UI-2 integration.

## Delivery

- Five original 64×64 House frame masters and StyleBoxTexture nine-slice
  resources: `ui.house.hud`, `.shop`, `.slip`, `.menu`, `.panel`. Fixed corners,
  tiled rails, explicit content insets; two original corner/divider ornaments.
  Manifest and reproducible generator under `assets/ui/house/`.
- Pixelify Sans, unmodified, with its SIL OFL 1.1 licence under `assets/ui/fonts/`.
  Exact sources, copyright, licence and SHA256 recorded in the asset ledger.
- Standalone `src/presentation/ui_a1_composition.tscn`: native tabs select Throw,
  Shop and Frame kit. Independent portrait/landscape layouts, real existing House
  art in a cosmetic viewport, Session A cards with shared live typography.
- Original `ui_a1_preview.tscn` remains the card/material inspector, now using
  the bundled font. No existing production UI scripts or League bindings changed.
- `docs/art/ui/UI-A1.md`: card sizes and states, panel slice/content margins,
  typography, safe areas, layer order, motion notes and the full capture list.
- JUIA1 extended to ten captures. tools/qa.py changes are additions only; its
  existing art-only CI step and artifact folder already cover these additions.

## Verification

Godot 4.5.2 stable, Linux, Compatibility/Mesa llvmpipe:

| Check | Result |
|---|---|
| `python3 tools/qa.py unit` | PASS |
| `python3 tools/qa.py content` | PASS |
| `python3 tools/qa.py e2e --journey JUIA1` | PASS |
| Same JUIA1 with `--rendered`, under Xvfb | PASS; ten captures present |
| Native review | Six new composition captures inspected, both orientations |
| JUIA1 `--inject-failure` | Correctly exits 1 |
| Frame-kit regeneration | All 13 generated resources byte-identical |
| `git diff --check` | PASS |

JUIA1 retains Session A's card checks and adds native tab input, supported font
characters, slice/content margins, text fit, visible bounds and touch heights,
illustration containment, hand/lane separation, ball visibility with safe margin,
and byte-identical rendered corner pixels across panel sizes and orientations.
The first visual pass caught a cropped ball and misplaced shop category header;
both were corrected before delivery, with a camera-framing regression assertion.

This session does not rerun the full existing gameplay/art journey matrix or
physics suite; no gameplay source or catalogue data changed. UI-A1-A recorded
unchanged physics `75d1a3c0…`. The full Wave 9 matrix remains required after AV-H3.
Native phone readability and frame pacing are not claimed. Static compositions
are not evidence for E05-R1's held-ball interaction. The UI target uses sample
scores and wallet values; specimen action buttons do not purchase or play.

## Owner capture list / hand-off

All paths below are generated under `artifacts/ui-a1/rendered/`, ignored by git
and uploaded by the existing art-shard CI step:

1. `portrait_throw.png`, `landscape_throw.png`: lane/hand/HUD hierarchy; landscape
   includes the score slip. Review the card size and lane allocation.
2. `portrait_shop.png`, `landscape_shop.png`: card stock, price overlays, frame
   grouping, font readability and primary actions.
3. `portrait_kit.png`, `landscape_kit.png`: five frame roles, numerals and ornaments.
4. `portrait_cards.png`, `landscape_cards.png`: catalogue rarities and card back,
   regenerated with Pixelify Sans.
5. `portrait_studies.png`, `landscape_studies.png`: all five rarity materials,
   explicitly labelled as studies rather than actual item rarities.

For Claude: UI-A1's implementation is ready to inspect; UI-1/UI-2 remain Wave 10.
Use the specification rather than copying the static sample data into game UI.
Existing House League IDs, item slots and completeness flags are unchanged.
No screenshots or rendered captures were committed.

## Resume exactly here

1. Fetch origin, verify this pushed checkpoint and merge newer Claude work with
   a merge commit on `codex/roguewood-build` if present; never rebase/force-push.
2. Start **AV-H3-A**, High recommended because Workhorse needs counted feedback:
   Spare Ball, Workhorse, Oak Pin. Read E18-C10, E17-D09's landed design blocks
   and J03C10. Write briefs, identity/in-play art, activation and sound; meet the
   exact presentation needs using resolver events/facts. Check natively before
   setting either flag. No E17-D10 flags or AV-T01 work.
3. Then **AV-H3-B**, High recommended for Spare Jar's counted display: Tin Pin,
   Spare Jar, Consolation Prize. Same per-item completeness discipline.
4. Run the required Wave 9 regression matrix, write both AV handoffs and
   `WAVE9-CODEX.md` with the ten UI-A1 captures listed above, push and verify the
   remote SHA/clean tree. Wave 9 remains open at this UI-A1 completion checkpoint.
