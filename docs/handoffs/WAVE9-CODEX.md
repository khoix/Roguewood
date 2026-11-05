# Wave 9 — Codex delivery index

Branch: `codex/roguewood-build`. All four assigned implementation batches are
DONE, and closing headless/rendered regression verification is complete.
This index records Codex work only. Claude owns integration, the central
checkpoint and the eventual `Wave 9 closed` commit. No main merge is claimed.

## Delivered checkpoints

| Batch | Checkpoint | Handoff |
|---|---|---|
| UI-A1-A — playing-card face, back, rarity/category treatment, Value/Mult/$ icons | `fdacb63` | [UI-A1-A.md](UI-A1-A.md) |
| UI-A1-B — House nine-slice frame kit, licensed pixel font, portrait/landscape screen compositions | `b874f02` (implementation `9c9e1a3`) | [UI-A1-B.md](UI-A1-B.md) |
| UI-A1 footer correction — rarity labels clear the bottom border in all five frames | `f4acab7` | [UI-A1-B-footer.md](UI-A1-B-footer.md) |
| AV-H3-A — Spare Ball, Workhorse, Oak Pin | `0b9f3a4` | [AV-H3-A.md](AV-H3-A.md) |
| AV-H3-B — Tin Pin, Spare Jar, Consolation Prize | `4d0fb91` | [AV-H3-B.md](AV-H3-B.md) |

Claude claims/web work were merged with merge commits `ef903a0` and `ad8b948`;
the latter includes `1f1f34d`. No rebase or force-push. No PR to main.

UI-A1 remains a standalone visual target. The specification is
[UI-A1.md](../art/ui/UI-A1.md): card proportions, safe areas, rarity/category
marks, text placement, states, motion notes, frame margins and font provenance.
The owner's reported rarity overlap is fixed in the shared card factory,
generated frames and composition scenes, with native bounds assertions.
Existing production UI scripts were not changed or integrated as UI-1/UI-2.

All six E17-D09 items have their required slots and both artwork/effects_audio
flags. Workhorse tallies read resolver counts; Oak follow-through affects only a
child mesh; Spare Jar displays the pre-bank snapshot until its growth reveal,
then updates the exact count. Native Skip, reduced motion and sale/repurchase
checks are included. E17-D10's five flags and all House theme bindings are
unchanged. No AV-H4, AV-T01, UI-A2 or other Wave 10 work started.

## Verification

Pinned Godot 4.5.2, Linux Compatibility / Mesa llvmpipe. `qa.py unit`, `content`
and `physics` PASS. Final unit/content checks include the enabled B flags.
Physics digest remains
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
J03 remains 560/240/70 and J05 remains 21060, headless and rendered.

The full required headless matrix PASS: J06, J22L01, J03C01–C11,
JAVC03A/B, JAVC04A/B/C, JAVH1AC/BC, JAVH2AC/BC, J22L01ART,
J21R03/R04/RC, J03C06 and J03C07 (AV-C06/C07 native journeys),
JAVC07AC/BC, J11ART, J12V08, J19A16, JAVH3AC/BC and JUIA1.
The same full matrix PASS rendered, including all required captures. This is
36 journeys in each mode: the 34 closing regression entries plus the separately
verified J03C10 and JAVH3BC. No script errors or failed checks were found.
Refreshed portrait cards and landscape rarity studies were inspected; the
reported footer overlap remains fixed, including the Legendary bottom ornament.
Per-command logs and results: `artifacts/wave9-codex/validation/`.
Batch logs: `artifacts/av-h3-a/validation/`, `artifacts/av-h3-b/validation/`.
All captures remain ignored output, never committed.

Remote Bootstrap run for `4d0fb9135d32c7817bf11ea56e59c34b16a969a2`:
https://github.com/khoix/Roguewood/actions/runs/41896062128
**PASS** on that implementation SHA, both game and art shards. The same SHA
also passed [E12 motion review](https://github.com/khoix/Roguewood/actions/runs/41896062053)
and [E11 still review](https://github.com/khoix/Roguewood/actions/runs/41896062216).
The final index commit changes documentation only. The coordinator must still
validate its eventual integration tree; this does not claim a main-branch merge.

## UI-A1 captures for owner review

All ten are generated under `artifacts/ui-a1/rendered/` and uploaded by JUIA1 in
the art shard. Review the revised rarity footer as part of the card target.

1. `portrait_throw.png`, `landscape_throw.png` — lane, hand and HUD hierarchy;
   landscape also shows the score slip.
2. `portrait_shop.png`, `landscape_shop.png` — stock cards, prices, frame groups,
   typography and primary actions.
3. `portrait_kit.png`, `landscape_kit.png` — five frame roles and ornaments.
4. `portrait_cards.png`, `landscape_cards.png` — catalogue examples and card back.
5. `portrait_studies.png`, `landscape_studies.png` — all five rarity materials,
   explicitly labelled studies rather than invented item rarities.

The preview compositions use sample data. UI-1/UI-2 integration remains Claude's
Wave 10 work after the owner's UI-A1 review. Physical-phone readability, held-ball
feel, subjective audio mix and platform certification are not claimed here.

## Resume exactly here

Codex Wave 9 is complete. Claude can integrate `codex/roguewood-build`, run
integration CI, and update the central progress/closure record. No Codex PR to
main. All four batch handoffs and the owner capture list above are ready.

Do not start Wave 10 until its claims are assigned. Next planned Codex work is
UI-A2 (High recommended), followed by the claimed AV-H4/AV-T01 scopes. Fetch and
merge the coordinator checkpoint with a merge commit when that wave begins;
never rebase or force-push.
