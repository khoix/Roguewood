# UI-A1-B follow-up — rarity footer clearance

Owner-reported defect: the rarity line overlaps the card's lower border.
Base: `0b9f3a4`, branch `codex/roguewood-build`. Fetch found no newer Claude
checkpoint than the already merged `1f1f34d`.

Moved the rarity box from y274 to y268, narrowed it to the horizontal safe area,
and moved the divider from y273 to y266. Adjusted the rule/qualifier spacing.
Label size is now applied after font setup and tree insertion, so initial font
minimums cannot leave a taller-than-requested box behind. This shared preview
factory also fixes the throw/shop composition cards. All five generated frames
and their generator agree; the UI-A1 specification has the revised coordinates.

JUIA1 now asserts rarity bounds against the card's 14 px safe inset in both the
card studies and screen compositions. Headless and rendered JUIA1 PASS; refreshed
portrait cards and landscape rarity studies were inspected, including Legendary's
raised bottom ornament. Captures stay in `artifacts/ui-a1/rendered/`, never git.
Unit and content checks also PASS. No gameplay, catalogue flags or production
UI scripts changed.

Resume exactly here: AV-H3-A remains DONE; follow AV-H3-A.md for AV-H3-B (High),
then the full Wave 9 regression matrix and WAVE9-CODEX.md. This is a UI-A1-B
correction, not a new wave claim or wave closure.
