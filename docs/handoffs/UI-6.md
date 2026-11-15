# Agent task handoff — UI-6 (the owner's play notes of 2026-11-14)

## Assignment
- **Objective:** fix the five things the owner found playing the Neon League on a phone after Wave 12 merged (PR #30).
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (see "Limitations and choices").
- **Branch:** `claude/roguewood-build`, on main `cd1cfc9`.
- **Paths:** assets/ui/fonts/PixelifySans.ttf, docs/art/ui/patch_symbols.py, docs/art/ASSET-LEDGER.md; src/presentation/card_view.gd, match_panels.gd, equipment_art_strip.gd, motion_director.gd (one type), throw_lab.gd (two lines); src/clubhouse/clubhouse.gd; tests/card_view_test.gd.

## The notes and what changed
1. **Symbols drawn as boxes.** The bundled font had no glyph for 18 characters the interface uses: the five rarity seals (■ Ⅱ ◆ ✦ ♛), the rule badge's ⓘ, ○, → ↓ ▶ ◀, ✕ ✗ ✓, ↻ ↺ and ⌊ ⌋. A desktop borrows them from a system font. A browser has none to borrow, so the phone drew a box for each.
   - The 18 glyphs are now in the font, drawn on its own pixel grid by `docs/art/ui/patch_symbols.py` (run it again to add one). No other glyph, width or mapping changed.
   - `card_view_test.gd` (`_font_covers_text`) reads every `.gd`, `.json` and `.tscn` under src/ and content/ and fails on a character the font lacks.
   - A side effect: the rule badge is the same size on every machine now (Codex's machine measured it differently in Wave 12 because its ⓘ came from another font).
2. **The Charms ran off the right edge** (portrait). The row had 150 px for them, room for three icons; the Spare Jar's counter under its icon also made every slot in the row twice as tall.
   - The Charms are now a rail down the lane's right flank, below the info row: "Charms", the count, then the kit and each Charm in slot order. Six fit; the rail is as tall as what it holds.
   - The info row is the score slip and the rival, wider: a slip such as "140 × 300 = 42000" no longer ends in an ellipsis.
   - Hosted in the rail or the landscape panel, a slot shows the identity only (no name, no counter). The strip is a flow container, so landscape's panel wraps to a second row instead of overflowing.
   - A Charm whose art is still to come keeps its slot, with the Charm mark dimmed. Before, it was missing from the display altogether.
   - The rail leaves while a frame is reviewed (portrait): the hand and the review take the whole screen below the info row then.
3. **The highlight did not turn with a fanned card.** The focus ring was the button's own box, which stays upright as the touch area. Both rings are now drawn on the face itself, so they lift, turn and tilt with it: the sea-glass or brass selection ring on the card's edge, and a thin focus ring just outside it.
4. **Binder.**
   - The selection border sat outside the card, where the scrolling page clipped it at the screen's edge. It is the ring above now, on the card's edge.
   - The chosen item's description is a footer below the scrolling page. It stays in view wherever the grid is scrolled (before, choosing a card far down changed text that was off the screen), and it is as tall as the longest description on show, so choosing a card never moves the grid.
   - Rows are further apart, so a state tab (DISCOVERED, MASTERED) no longer covers the card above.
5. **Cards with no picture.** These are the twelve Neon items of DC-N1 and DC-N2: their art is Codex's AV-N1 and AV-N2 in Wave 13. Until it lands, a card shows its category mark, dimmed, over "ART TO COME" (`art_pending` on the card), not an empty panel.

## Limitations and choices
- **The Charm rail is the coordinator's choice**, in place of the row in the approved UI-A1 layout; the owner asked for the display to be fixed and left the way open. It uses lane flank that was empty. To go back to a row, the rival chip would have to shrink to its portrait.
- **The Binder footer is also the coordinator's choice**; the owner asked only that the page not shift. On a phone it takes about 200 px at the bottom of the Binder tab. Its text is 18 px there (22 px before) to keep it that short.
- The symbols are plain pixel drawings by the coordinator, in Codex's lane (the font). Codex may redraw any of them in `patch_symbols.py`; the test only needs each character to exist.
- A lab fixture's Charm (no icon at all) shows as a name cut to the rail's width in portrait. Production Charms are not affected.
- No phone trial: checked with the phone tour at 780×1688 and the web journey in headless Chromium.

## Validation
See docs/AI-HANDOFF.md, "Wave 13 progress".
