# Agent task handoff — UI-3 (the phone pass)

## Assignment
- **Objective:** Wave 11, Claude's first claim. Fix what the owner found playing the web build on a phone (2026-11-08), with a minimal redesign so every screen still works once the text is larger (owner: "not simply make the text bigger").
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (see "Limitations").
- **Branch:** `claude/roguewood-build`, after the "Wave 11 claims" commit `328d6a6`.

## The owner's findings, and what changed
| Finding | Change |
|---|---|
| The swing is stiff, almost non-functional | E05-R3 (ADR 011, "Revision: the phone trial"). Full charge drops to 3.5 turns a second (owner's pick). Swirls are told from flicks by three steady turns rather than a finger-speed cap, so brisk, larger circles count. |
| The swirl is confined above the red line | Below its start point the held ball follows the finger back over the approach (up to 1.3 m). J02 checks it. |
| Fonts too small on mobile | Portrait lays out 540 wide instead of 720, so all text is about a third larger on a phone. The screens below are re-fitted for it. |
| Top HUD covers the pins | The session buttons are smaller ("Restart"); the top bar is two rows: the match title and money, then the score against target (large), frames left and the rule badge. The slip, rival and Charms share one row below it. The ball line sits lower in portrait (0.76 of the lane region) so the pins clear that row. |
| The House Kit badge sits in the lane | Codex's kit and Charm strip is seated in the Charms row as small icons. |
| Deck and top HUD stay up during the animation | The roll view: once the ball is away, the hand and the info row leave, the bar slims to the match and score, and Restart and Clubhouse step aside. Options stays reachable at the top right. |
| The deck takes too much space | Cycle and Inspect move into the hand's header, so the fan of four uses the full width (cards about 157 wide, with their short rule). The header reads "Draw 2 · Discard 0 · Used 0". |
| The prompt sits in the lane | The prompt shows only the hint lines, just above the hand. The match line is the bar's job, and the armed card shows the ball. `status` keeps the full sentence for tools and tests. |
| Frame review not centred, empty space | The review is centred: header, rack with the counters beside it, the chain at full width, and centred buttons. It is shorter in portrait, so when a frame is done the raised hand (keep a card), Next Rack and the score all fit. |
| Shop art too small, too much text | Portrait offers are three columns of cards up to 150 wide, sized so every row shows. Reroll, Remove and Next Match are pinned below the scrolling shop. The payout breakdown and rack list fold behind "Payout & rack details". Title and money share a line. |

Also: the assist controls put each label beside its slider, so the panel fits beside the ball above the hand (it covered the hand's header before, and J08 could not reach Inspect).

## Validation evidence
| Command | Outcome |
|---|---|
| `qa.py unit` | PASS (held-ball cases at the new scale, a wide brisk circle reaching full charge) |
| J02 headless and rendered | PASS, with the new below-the-start check |
| The journeys the redesign touches (J01, J03–J11, J03C01–C11, J22L01) | PASS after three fixes: Options stays reachable during the roll view (J06, J11, J03C08 and J03C10 open Options while the ball rolls), journey taps scroll a control into view first, as a player would (J03C07), and the compact assist panel (J08). |
| Phone-shaped captures (not committed) | Aim, assist, rolling, scoring and frame done, shared with the owner. |
| Full local matrix | See docs/AI-HANDOFF.md, "Wave 11 progress". |

## Limitations and follow-ups
- **Landscape phones** still lay out 1280 wide; a phone held sideways gets the old text size. Desktop landscape is unchanged.
- **No phone has played this build yet.** The owner's next trial decides the swing feel (tunable in Options → Throw tuning; Reset brings back the new defaults).
- **The Clubhouse and menus** inherit the larger scale but were not re-laid out beyond fitting.
- Captures are not committed (AGENTS.md).
