# Agent task handoff — UI-5 (the session menu, a leaner frame review and a shop that reads)

## Assignment
- **Objective:** Wave 12, Claude's first claim, from the owner's decisions of 2026-11-10 after UI-4: one menu button in place of the session buttons; no Speed or Skip on the frame review; a shop whose offers open large to read and confirm, with one Sell control and fewer words.
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (see "Limitations and choices").
- **Branch:** `claude/roguewood-build`, after the "Wave 12 claims" commits. UI-5a is `985e956`, UI-5b `34a84bf`.
- **Paths:** src/bootstrap/bootstrap.gd, src/presentation/match_panels.gd, throw_lab.gd, division_hud.gd, score_panel.gd, shop_panel.gd, throw_settings_panel.gd (one default removed); the journeys' shared helpers and J01, J03, J05; tools/capture_phone_tour.gd.

## UI-5a: the match screen
- **One menu button** sits at the top right, beside the top bar, on every match screen. It opens a sheet over a dimmed match: Resume, Options, Clubhouse, Restart attempt.
  - `add_menu_entry(label, node_name, action, closes)` in bootstrap.gd adds an entry; the owner expects more later.
  - Restart asks once: the first press changes its words to "Discard this attempt? Press again"; the second restarts. Opening the menu again disarms it. (The coordinator's proposal; one line to drop.)
  - The lab ignores touches while the sheet is open, and never throws through the button. Escape, or a tap outside the sheet, closes it.
  - The button is three bars drawn in code. An icon from Codex can replace the drawing by asset.
- **The top bar moved up** into the row the three buttons took, in both orientations, so the lane is 56 px taller in portrait and 72 px in landscape. The introduction and result sheets start below the button, which stays in reach over them.
- **The frame review has no Speed or Skip.** While the chain is still counting, a tap anywhere on the review, or the accept key, finishes it at once; a small "Tap to finish" line says so and fades when the reveal is done. The reveal keeps one pace, and the `score_speed` setting is gone.

## UI-5b: the shop
- **A tapped offer opens in a sheet:** the card large, its kind and rarity, its full rule text with any tradeoff, "Costs $4 · you have $11", and Buy and Back. Nothing is bought until Buy. A purchase that needs a choice (a slot, a pin, a replacement) goes on to the choice sheet as before.
  - An offer that cannot be bought still opens, with Buy off and the reason ("Can't buy: insufficient funds."). A sold offer does not open.
- **One Sell control:** a "Sell · 6" button opens a sheet of rows ("Card Hook Ball  +$2"). A tap sells that one and the sheet stays open for the next; it closes itself when nothing is left. The Charm-order moves are in the same sheet, and the button then reads "Sell · 6 · order".
- **The preview is one line:** "Next: Division 1 Feature · target 500", with the rival's name when the next match is the boss and the lane when it is not House Oil. The boss's rule stays behind the ⓘ on the bar. `preview` keeps the full sentences, unshown, for tools and tests.
- **The rack summary** names the commonest pin once: "all 10 Wood Pin", or "1 Glass Pin, the other 9 Wood Pin".
- Both sheets sit over a dimmed layer; a tap on it, or Escape, closes them.

## How journeys changed
The journeys do what a player now does, through three small helpers in each base journey:
- `_reach(control)`: before pressing a control, open the session menu or the Sell sheet if the control is inside one, and close a sheet that is in the way.
- `_confirm(control)`: after pressing an offer, press Buy (or Back when Buy is off).
- A reveal is finished through the review itself (`_focus_accept(lab.score_panel)`), not a button.

`_focus_accept` and `_tap` call the first two, so Codex's art journeys needed no edits beyond the eleven places that named the Skip button.

## Validation evidence
| Command | Outcome |
|---|---|
| `qa.py unit` | PASS |
| J01 | PASS: the menu button has focus; the menu opens on Resume; the first Restart press only asks; the second restarts and closes the menu; Clubhouse through the menu. |
| J03 | PASS: no Speed or Skip node; a tap on the review finishes the reveal; the accept key does too. Scores 560/240/70 unchanged. |
| J05 | PASS: the one-line preview; opening an offer buys nothing; the sheet shows the card, text, price and Buy and fits the screen; Back changes nothing; an unaffordable offer opens with Buy off and the reason; one Sell control with the right count; the sheet stays open across a sale and fits the screen. |
| J04, J06, J07, J09, J10, J11, J03C04, C06–C11 headless | PASS |
| Tour captures, portrait and landscape | Shared with the owner; not committed. |
| Full local matrix | the full CI command list (194 commands) PASS locally: 135 on `34a84bf`, and on `86ef216` the 59 that had failed or not run. The first run caught J12 and J12V01–V06 hanging (they replay a frame and still passed a speed to the frame review); `86ef216` fixes that by accepting the argument. The physics digest `75d1a3c0…` and J03 560/240/70 are unchanged. CI: Bootstrap run 42791634165 runs on `86ef216`. |

## Limitations and choices
- **Sell rows are one per item, not grouped.** Two Hook Balls are two rows. Cards differ by their modifications and each row sells one particular card, so grouping would hide which one goes. The claim proposed grouping; this is the simpler, safer reading of the owner's request.
- **The reveal has one pace.** If the owner wants a faster default, `STEP_SEC` in score_panel.gd is the one number.
- **The menu button is drawn, not illustrated**, and the two shop sheets use the House menu frame. Codex may give them art; they bind by node, with no code change needed for a frame swap.
- **No phone has played this build yet.**

## Follow-up (owner's screenshot, 2026-11-11)
| Found | Change |
|---|---|
| In the Neon champion's match the top bar ran under the session menu button: a long score, the frame count and a two-rule badge were wider than the bar's region, so the bar grew to the right. | The bar never grows past its region. Its second row steps its text down until it fits (measured directly, since a Label's minimum size lags a font change), and cuts the frame count short as a last resort. Two empty 32 px slots for rule seals that have no art yet (Neon's) no longer take room. |
| The stacked two-rule badge made portrait's bar taller than its region, over the info row. | Portrait's bar is a line taller under a two-rule badge (`MatchPanels.compute(…, bar_extra)`, 18 px) and everything below moves down with it. Landscape shows the two rules on one line. |
| Next Rack sat in the middle of the screen, between the hand and the frame review. | The frame review stops above an action row at the bottom edge, and Next Rack (or Collect & Shop, Division Result) fills that row: full width in portrait, centred in landscape. The review keeps its height; it starts 80 px higher. The prompt is hidden when the frame is done (in landscape it showed behind the button). |
| A rival's speech bubble covered the top line of the hand under it. | In portrait the bubble is sized to the info row it covers (a 44 px portrait, 18 px text). |

Validation: all 200 CI commands PASS locally on `71247f7`. Checks added: J03C13 (the Neon champion, portrait): the bar stays inside its region, clear of the menu button and above the info row. J08: Next Rack is below the hand and the review, inside the screen.
