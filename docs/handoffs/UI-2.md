# Agent task handoff — UI-2 (every screen in the approved layout)

## Assignment
- **Objective:** Wave 10, the last of Claude's three claims. Build the match, shop and menu screens in the layout the owner approved (docs/ROADMAP.md, "Art-forward interface: UI-R1"; docs/art/ui/UI-A1.md, "Wave 10 layout revision — UI-A1-C").
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (see "Limitations" for what stays open).
- **Branch:** `claude/roguewood-build`, on top of Codex's Wave 10 work (`9986f67`).

## What was built
- **One House theme** (src/presentation/house_ui_theme.gd):
  - Codex's UI-A1 frame kit (assets/ui/house/) and Pixelify Sans, set once on the shell, so every panel, button and label shares the kit.
  - `frame(kind, margin_x, margin_y)` gives callers a kit frame with their own padding; the kit textures nine-slice and are never stretched as pictures.
  - The match bar, rule panel, reaction bubble, sheets, shop, choice sheet, hand, score panel, inspector and tactic sheet all use kit frames. The Clubhouse keeps Codex's own E16 art styling, with the kit under it.
- **Backdrop:** the lane renders on a transparent viewport over UI-A1-C's House night sky (option 1, Constellations, as the coordinator's default; no backdrop was picked, and Slow stars is a one-line switch). Reduced motion or reduced flash holds it still.
- **Card materials (UI-A2):** every CardView carries its rarity material from assets/ui/materials/manifest.json (League → rarity, unprovided Leagues fall back to House).
  - It is a mouse-ignoring overlay over the whole face, above the illustration and below every badge and label, with its own duplicated material per card.
  - It is off on compact cards (their art recess differs from the canonical mask) and on Common (matte).
  - Inspection drives its phase from tilt (0.42 + 0.25·x + 0.15·y) and settles to 0.42 off the art; the old illustration foil is off, so the two never double up. A press sweeps once over 180 ms. Reduced motion uses the reduced material.
  - J08 now checks the new mapping (`inspector.tilt`, the material's `progress` and `reduced`, and no foil on the art).
- **Match screen regions** (src/presentation/match_panels.gd, `MatchPanels.compute`):
  - **Landscape:** a one-row top bar (24, 88, w−48, 68); a hand flank and a details flank, each 19% wide, mirrored for left-handed play; the lane full width behind them.
    - The details flank holds the last-frame slip, the rival panel (portrait, name, rule and the rival's latest line) and the Charms row.
    - Under 1.5:1, or with a flank under 240 px, the screen folds: a second bar row with **Hand** and **Slip · Rival · Charms** toggles, each opening its panel and closing the other.
  - **Portrait:** a two-row top bar (24, 88, w−48, 136) with the rule badge and a dedicated money slot stacked at the right; the slip and rival chips at y 238; the Charms row at y 298; the lane; and the hand panel at the thumbs.
  - **Hand:** landscape lays four cards two by two in the flank with Cycle and Inspect below. Portrait **fans four cards** (owner, 2026-11-07): each overlaps the next by 30%, turns out up to 6° and drops along a gentle arc, with Cycle and Inspect on a thumb rail (mirrored for left hands). Only the face turns, so each card's touch area stays its upright rect and a tap on a card's centre lands on that card. When a frame is done, portrait raises the hand under the Charms row (to keep a card) with Next Rack between it and the score.
  - **Money:** its own slot on the top bar (`hud.money`). The status line keeps it too, for the journeys that read it.
  - **Prompt:** the match line, the ball and the hint sit over the lane top, between the flanks in landscape.
  - **Assist controls:** over the details flank in landscape; beside the ball, above the hand, in portrait.
  - The E12 floating rival portrait stays hidden while the rival panel shows; its lines go to the rival panel.
- **Camera framing:** the aim camera keeps its position and field of view and is pitched (solved by bisection on the real projection) so the ball sits at 0.667 of the lane region's height: y 749 of 1280 in portrait, y 521 of 720 in landscape. The rolling camera carries the same pitch, so there is no jump at release. Measured at the lane's ball depth, landscape keeps the lane at 0.35–0.65 of the width, inside UI-A1-C's 36% corridor. Portrait has no side panels, so the lane stays wide for touch (0.21–0.79) and the ball's radius is 44 px (it was 46.5).
- **Shop:** landscape puts the offers on a three-column shelf, sized so every row fits on screen, beside a scrolling pane with the shop text, actions and sales. Portrait keeps its single scrolling column. The shop reflows when the orientation changes. J05 checks three columns with every offer on screen (it checked five in one row before).
- **Score chain:** each step of the ordered chain carries its icon (pin, Value, Mult or $) from the card icon set, in the kit colours. Each line is a flat, untouchable Button, so its `text` is still the step's words for the journeys that read the log.

## Validation evidence
| Command | Outcome |
|---|---|
| `qa.py unit` | PASS |
| J02, J03, J05, J06 (two stages), J08 and J11, rendered | PASS. Captures inspected: portrait aim with the fan, the frame-done raised hand, landscape rolling with both flanks, the landscape shop shelf, the boss screen with the rival's line, the Clubhouse binder and the score chain icons. |
| 4:3 fold probe (1280×960, not committed) | Folded; Hand and Slip · Rival · Charms open their panels and close each other. |
| Camera probe (not committed) | Ball at y 749/1280 portrait, 521.5/720 landscape, 705.6/960 at 4:3, each 0.667 of its lane region. |
| Full local matrix (all CI commands, three journeys at a time) | See the Wave 10 progress entry in docs/AI-HANDOFF.md. |

## Limitations and follow-ups
- **Text still carries the match bar and the prompt.** The money slot, Charms icons, rule seals, chain icons and card materials replace text where they could. The top bar line and the prompt are still words, because many journeys read them; an icon-led bar needs those checks rewritten.
- **The Clubhouse** keeps Codex's E16 styling under the kit; a kit pass over its tabs is Codex's to make.
- **Device feel:** no phone has played the fan, the folds or the new ball line. The ball's portrait radius changed slightly (46.5 → 44 px), which the swing's tether follows.
- **Captures are not committed** (AGENTS.md); they were shared with the owner.

## Resume
Nothing is pending in UI-2. Wave 10 closes once Codex's closing record (docs/WAVE10-CODEX.md) is in and the full matrix passes.
