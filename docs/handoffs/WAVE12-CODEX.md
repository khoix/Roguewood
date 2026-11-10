# Wave 12 — Codex checkpoint index

Wave IN_PROGRESS. UI-A3 is DONE; E21-R05, E21-R06,
E21-R07 and E22-L02-ART remain pending. No Wave 13 work started.

## Branch

`codex/roguewood-build`. Coordinator Wave 12 claims at `a5114b6` merged with
merge commit `b32ab1e`; setup checkpoint `a6e9d45`. No rebase, force-push,
main push or pull request. The UI-A3 commit follows this setup checkpoint.

## UI-A3

See [UI-A3.md](UI-A3.md) for the implementation, validation and provenance.
Original curved 2/5 replace ambiguous pixel glyphs in the shared bundled font.
No UI integration is needed. Source metrics and other glyphs are unchanged.

Owner capture index (local, deliberately untracked):
- `artifacts/ui-a3/{before,after}/18_frame_done.png`: small score slip,
  `140 × 5 = 700`, full review and rack numbers.
- `artifacts/ui-a3/{before,after}/17_scoring.png`: score reveal.
- `artifacts/ui-a3/{before,after}/19_shop.png`: prices and money slot.
- `artifacts/ui-a3/{before,after}/22_shop_after_buy.png`: money after purchase.
- `artifacts/ui-a3/{before,after}/14_tuning.png`: throw tuning.
- `artifacts/ui-a3/{before,after}/15_aim_assist.png`: power percentage.
- `artifacts/ui-a3/uia3-type.png` and `uia3-type-3x.png`: source/patch at
  16, 20, 24, 30 and 36 px, at 2× and 3× respectively.
Both native phone tours completed 26 captures at 780×1688.

## Exact next session

1. Fetch origin. Before editing journeys that open Options, finish a reveal,
   buy or return to the Clubhouse, merge the latest coordinator branch with a
   merge commit to receive UI-5's navigation changes.
2. Start E21-R05 (High), reading its existing rival renderer and art contracts.
   List IDs/slots, source/provenance, journeys and captures before authoring.
   Slick needs portrait, idle, entrance, six reactions, defeat, reduced-motion
   versions, `boss_rule.oil_slick` badge and `plaque.slick`. Include the missing
   `plaque.proprietor`, `plaque.old_lou`, `plaque.custodian_champion` in this batch.
3. Exercise Slick through `--content=neon_c13` and J03C13; add art checks without
   deleting existing ones, with every new CI art step guarded by the art shard.
   Run unit/content and affected journeys in both modes, write E21-R05.md,
   push, verify SHA and clean tree, and report to the coordinator.
4. Then E21-R06, E21-R07 (including champion) and two E22-L02-ART sessions.
   No AV-N1 or AV-N2. Missing hooks go into the scoped handoff for Claude.

Runtime: pinned Godot 4.5.2 lives under `/tmp/roguewood-godot/`; checksum was
verified. See UI-A3.md for writable XDG paths and local Xvfb setup. Reinstall
these untracked tools if this execution environment is replaced.
