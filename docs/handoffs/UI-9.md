# Agent task handoff — UI-9 (the owner's Wave 13 play notes, 2026-11-15)

## Assignment
- **Objective:** the owner's play notes on the merged Wave 13 build.
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (the pin deck is Codex's UI-A6; see "Limitations").
- **Branch:** `claude/roguewood-build`, after E18-C20 (`a21a92f`).
- **Paths:**
  - Source: src/clubhouse/clubhouse.gd and clubhouse_model.gd; src/bootstrap/bootstrap.gd; src/presentation/division_hud.gd, card_hand.gd, score_panel.gd and throw_lab.gd.
  - Tests: tests/clubhouse_journey.gd (J11), division_journey.gd (J06) and neon_c17_journey.gd (J03C17).

## The notes and what changed
1. **"Some pin areas still don't have any thematic decoration."**
   - **Cause:** the capture is the House League. Its kickbacks and cushion are the lane's plain walls, because `LeagueTheme._dress_pin_deck` dresses them only for the Neon League.
   - **Owner:** this is art, so it went to Codex as UI-A6 (docs/prompts/codex-wave14-ui-a6.md). The pin-deck finish becomes a manifest entry per League, and the House League gets its own.
2. **The boss introduction was a wall of text.** It now reads as parts:
   - **Who:** a kicker ("BOSS MATCH · DIVISION 1 OF 8", or "CHAMPIONSHIP"), the rival's name, the portrait, and their entrance line in a speech bubble.
   - **What:**
     - one card per rule, with its seal, its name and what it does (the champion shows two);
     - the match's figures (Target, Frames, and the Lane when it is not House Oil);
     - the first-clear reward;
     - the rival's story behind "Scouting report +", which opens and closes in place.
   - **Layout:** portrait stacks the parts. Landscape sets who and what side by side, so it fits a phone on its side without scrolling. The body scrolls if a screen is ever too short, and Begin stays at the bottom.
   - The full sentence stays in `intro_body` (hidden) for tools and tests, so the seal on Begin, the names the journeys read and the landscape-fit checks are unchanged.
3. **Keep section and frame log.**
   - **Bigger keep cards:**
     - The cards take the section's height, less only its own chrome (padding, the header as it reads now, the fan's drop: `CardHand.keep_reserve`). Before, a fixed 96 px was reserved.
     - A full hand of four overlaps more (up to half a card) so the cards grow toward that height instead of leaving it half empty.
     - On a tall phone the review starts 620 px from the bottom (was 680), giving the section about 60 px more; the log scrolls.
   - **The log "scaled, then reverted":** the fit reserved a fixed 24 px for each line's icon, but the icon grows with the font (1.15 × size). A log scaled up therefore ran past the room, and its longest lines wrapped at the big size.
     - The size is now solved with the icon: size × (longest ÷ 21 + 1.15) plus the separation and a little slack.
     - A scaled log wraps nothing. A line too long even at the 21 px minimum still wraps, as before.
4. **Trophies and Goals scroll from anywhere.** Their rows were panels that stopped a drag, the reason the Binder's cards had before UI-8.
   - Every row, picture, bar and button now passes the drag to the page (`Clubhouse.drag_through`).
   - A Follow press that ended in a scroll of more than 12 px follows nothing.
5. **The main page is redesigned.**
   - **Logo:** the game's logo heads the Clubhouse in place of the club sign and "THE CLUBHOUSE"; the board's own "Roguewood" heading is hidden.
   - **Tabs:** a segmented strip; the chosen tab is a lit plate with brass words.
   - **The Career:** one scoreboard plate, four figures divided by thin rules, so they no longer look like buttons. The followed goals sit under a "FOLLOWING" caption on the same plate.
   - **Choices and action:** the League and kit choices are inset fields with a brass edge under small captions, on a play card. The action to take is a brass button: Continue when an attempt is saved, otherwise Enter League or Try Again. The other action is outlined.
   - **The wall of text** is now cards:
     - each League is a card with its trophy (lit once won), its name, its titles and four figures (attempts, best Division, top total, top frame), or "Not played yet", or what opens it;
     - each unlock is a row with the item's picture, its name, and how it was won.

     The full sentences stay in `records_label` and `latest_label` (hidden) for tools and tests.
   - **Scroll bars** are hidden on every page; a finger or the wheel still scrolls.
   - A phone on its side shows a smaller logo, so the play card fits.

## Coordinator choices
The owner left the design open, so these are mine:
- the colours and the order of the parts;
- "Scouting report" closed by default;
- the keep fan's 0.5 overlap;
- the review's new top;
- Continue taking the brass style when an attempt is saved.

## Validation
- **Journeys:**
  - **J11:** the logo above the tabs; no page shows a scroll bar; the play card holds the choices and the action; the action is brass; one card per League. No trophy row, goal row or button stops a drag, and a Follow press that ended in a scroll follows nothing.
  - **J06:** the kicker, the name, the rival's line, one rule card for Clean Sweep, the target 800 and its frames, the reward, and Scouting report opening and closing the rival's story.
  - **J03C17:** the keep cards fill the section's height or its width, and a log scaled above its minimum wraps no line.
- **Full local matrix:** see AI-HANDOFF, Wave 14 progress.

## Captures for the owner (not committed)
- The board (fresh and with a Career), Trophies and Goals.
- The introduction for Slick and the Neon champion, in portrait (with the story open) and landscape.
- The phone tour's frame review in both orientations.

## Limitations
- **Not checked natively:** a real finger drag (headless Godot has no touchscreen). J11 checks the parts, as for the Binder; checking it on the phone is the owner's.
- **Pin deck:** the House pin deck stays plain until Codex's UI-A6 lands.
