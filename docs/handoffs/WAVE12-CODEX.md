# Wave 12 — Codex checkpoint index

Wave IN_PROGRESS. UI-A3, E21-R05 and E21-R06 are DONE.
E21-R07 assets are delivered but integration is BLOCKED by the champion bar-height
issue; see its handoff. E22-L02-ART remains pending. This is not a passing wave close.
No Wave 13 work started. See [E21-R05.md](E21-R05.md) for its captures and results.
See [E21-R06.md](E21-R06.md) for Laser Lena's captures and validation.
See [E21-R07.md](E21-R07.md) for regular/champion DJ captures and paired seals.

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

First finish E21-R07's hook handoff: the two-rule bar is 136px high in an assigned
118px region and overlaps the info slip by 10px. J03C13 fails even with Strobe
disabled. Claude fixes the owned UI layout; Codex then enables the Strobe seal,
registers/validates the two pending native journeys, and completes R07. Exact
steps and evidence are in E21-R07.md. The theme steps below follow that completion.

1. Fetch origin. Before editing journeys that open Options, finish a reveal,
   buy or return to the Clubhouse, merge the latest coordinator branch with a
   merge commit to receive UI-5's navigation changes.
2. Start E22-L02-ART (High, two sessions), reading E17-L02/E22-L02 and the House
   theme/art contracts plus the live Neon registry.
   List IDs/slots, source/provenance, journeys and captures before authoring.
   Deliver Neon environment/signage across eight Divisions and Championship,
   Long Oil at 47 ft, Two-Tone left dry from 34 ft with non-colour cues, Narrow
   Lane edges/rail, Strobe rings, music identity, frame kit, flank/reduced backdrop
   and `trophy.neon`. Theme loading currently only serves House; request missing
   hooks from Claude rather than changing rules or shared content.
3. Exercise the theme through the live League and C13 fixture; add art checks without
   deleting existing ones, with every new CI art step guarded by the art shard.
   Run unit/content and affected journeys in both modes, write E22-L02-ART.md,
   push, verify SHA and clean tree, and report to the coordinator.
4. Finish the two theme sessions and update this index with owner captures.
   No AV-N1 or AV-N2. Missing hooks go into the scoped handoff for Claude.

Owner preference (2026-11-11): flag a mismatch with the proposed effort level
before proceeding, when the selected effort is visible. R06/R07 and theme
sessions are High.

Runtime: pinned Godot 4.5.2 lives under `/tmp/roguewood-godot/`; checksum was
verified. See UI-A3.md for writable XDG paths and local Xvfb setup. Reinstall
these untracked tools if this execution environment is replaced.
