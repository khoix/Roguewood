# UI-A3 — distinct numerals

The bundled font now has original curved outlines for `2` and `5`. A curved
shoulder and horizontal foot distinguish 2 from the angular Z; a straight upper
stem, open join and rounded lower bowl distinguish 5 from the stepped S.
All other glyphs are unchanged. The 586-unit advances and 60-unit left bearings
are preserved, so the score, rack, price and tuning text retain their layouts.
The two replacements are weight-invariant; their old variable-outline deltas
are removed rather than applied to unrelated contours.

The font's internal family/PostScript names are Roguewood Numerals /
RoguewoodNumerals. `assets/ui/fonts/PixelifySans.ttf` remains the resource path
for compatibility with existing preloads. No second face or coordinator wiring
is needed: the shared theme and direct font users receive the same numerals.

Source: the existing Pixelify Sans OFL font, SHA256
`9ba86cd010a4de309d263ceff8e8044092c9db7efda869620cb9ff1c4389e8a5`.
Original replacement contours and the reproducible fontTools script are in
`patch_numerals.py`. Run that script with the original font and an output path;
it must not be fed an already modified derivative as the source of provenance.
The full original OFL copyright/licence stays beside the font. The derivative
also remains under OFL 1.1. OFL forbids using any declared Reserved Font Name
for a modified font without permission; the supplied copyright header declares
none. Nevertheless, the internal family is renamed to identify the derivative.

Review evidence (untracked): `artifacts/ui-a3/uia3-type.png` compares the source and patch
at 16, 20, 24, 30 and 36 logical pixels, rendered at 2×. Native phone tours at
780×1688 are `artifacts/ui-a3/before/` and `artifacts/ui-a3/after/`. See the batch handoff for
validation status and the specific screens to inspect. These are desktop
renders, not a physical-phone trial.
