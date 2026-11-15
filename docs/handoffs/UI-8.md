# Agent task handoff — UI-8 (the owner's play notes of 2026-11-15)

## Assignment
- **Objective:** the owner's play notes of 2026-11-15 on the merged build, before Wave 13 closes.
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE.
- **Branch:** `claude/roguewood-build`, after the merge of Codex's Wave 13 checkpoint (`debb5e6`).
- **Paths:**
  - Source: src/clubhouse/clubhouse.gd; src/presentation/card_hand.gd, card_view.gd, division_hud.gd, match_panels.gd, score_panel.gd and throw_lab.gd.
  - Tests: tests/clubhouse_journey.gd (J11), division_journey.gd (J06), neon_c13_journey.gd (J03C13), neon_c17_journey.gd (J03C17) and neon_league_journey.gd (J22L02).

## The notes and what changed
1. **The main page changed width with the League chosen.**
   - The board's column sat in a CenterContainer at its minimum width, which came from the widest kit name: House lists "Tournament Kit · win the House League title"; Neon lists only "Neon Kit".
   - The column is now the page's width, at most 720 px, whatever is chosen, and the League and kit choices cut a long name rather than widening the column.
2. **The "keep a card?" section.**
   - **No buttons:** choosing a card to keep after a frame, the hand has no Cycle or Inspect button (`keep_mode`).
   - **Card size:** the cards are as tall as the section allows, and a fan with room to spare spreads out and centres across the section.
   - **Inspecting:** a long press inspects, as before. In the keep section, a double tap on the same card within 0.35 s also inspects; the second tap undoes the first, so the keep choice is as it was.
     - **Not while aiming:** there a quick tap-tap arms and disarms a card. The full matrix caught a double tap breaking that (J04), so only a long press inspects while aiming.
   - **The header** reads "Keep a card? (optional) · hold or double-tap to inspect".
3. **The frame log** is sized to the review's width. The frame's longest line, measured at 21 px, is scaled to fill the room beside its icon, between 21 and 32 px; the icons scale with it. Lines too long for the minimum still wrap.
4. **The menu button is inside the top bar.**
   - The bar spans the screen in both orientations.
   - The session menu button sits in its top-right corner, and the bar's top row keeps that corner clear (`MenuRoom`).
   - Portrait's roll-view bar is 60 px tall, up from 52, to hold the button.
5. **The Binder.**
   - **Tabs:** the categories are a strip of tabs (a brass underline on the chosen one) under the Clubhouse tabs. They stay in place while the grid scrolls, and the strip slides sideways when it is wider than the screen.
   - **Preview:** a tapped card opens a preview over the page, with its picture at 220 px (260 on a wide screen), its Career state and history, and Close. A tap outside, Close or Escape closes it, and focus returns to the card. This replaces UI-6's footer.
   - **Scrolling:** a finger that lands on a card and drags scrolls the page. The cards pass the drag on and no longer tilt in the Binder. A press that ended in a scroll of more than 12 px opens nothing.
   - The "Collection binder" heading is gone; the tab names the page.
6. **The boss introduction waits for the player.** It no longer advances on its own after 6 seconds (2 for a rival already met). The repeat introduction stays shorter.
7. **The end-game screen** reads as sections:
   - a short headline ("Neon League cleared!", "Attempt over") and a one-line outcome in green or red;
   - four tiles: Total, Reached, $ left and Attempt;
   - rewards and unlocks, marked ◆ in brass;
   - goals with progress bars;
   - every match as a green or red chip, one row per Division under a header row (Opener · Feature · Boss);
   - small grey notes: the rule in force, practice, the campaign seed.

   The full sentence stays in `result_title` and `result_body` for tools and tests, hidden. A save written before UI-8 has no sections and shows the old text. The sections are saved with the result, so a resumed attempt shows them.

## Limitations and choices
- **Coordinator choices**, where the owner left the design open:
  - The end screen's sections and their order.
  - The tab strip's look.
  - The preview's content, which is the binder picture, not the full playing card.
  - The double-tap window (0.35 s).
  - The fan's spread when the cards are height-limited.
- **Not checked natively:**
  - **Binder scroll:** headless Godot has no touchscreen, so the scroll-through can't be dragged in a journey. J11 checks the parts: the cards pass input on and don't tilt, and a press that ended in a scroll opens nothing. Checking it on the phone is the owner's.
  - **Double tap:** J03C17 checks it with two quick journey taps.
- The aim hand keeps its Cycle and Inspect buttons; only the keep section drops them, as the note asked.
- No phone trial; checked with the phone tour (780×1688 portrait and landscape) and the journeys' rendered captures.

## Validation
See docs/AI-HANDOFF.md, "Wave 13 progress".
