# Agent task handoff — UI-4 (the GUI review after the phone pass)

## Assignment
- **Objective:** the owner's request of 2026-11-09: look for GUI improvements the phone pass (UI-3) missed. Wave 11, added to Claude's claims by the owner.
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE (see "Left for the owner or Codex").
- **Branch:** `claude/roguewood-build`, after `9d41f98`.
- **Paths:** src/clubhouse/clubhouse.gd, clubhouse_art.gd (one state style) and clubhouse_model.gd; src/bootstrap/bootstrap.gd; src/persistence/career_profile.gd (`stats`); src/presentation/throw_lab.gd (the prompt, the short title), division_hud.gd, shop_panel.gd, card_inspector.gd (one hint line); tests/clubhouse_journey.gd, career_journey.gd, division_journey.gd; tools/capture_phone_tour.gd (new).

## How the review was done
`tools/capture_phone_tour.gd` (new) walks the real game at a phone-shaped window and saves a capture of every screen of a first attempt: the four Clubhouse tabs, aim, the rule panel, the inspector, Options and throw tuning, assist controls, the roll view, scoring, frame done, the shop (folded, open, after a purchase), a second match, an open frame and the result. It asserts nothing; journeys do that.

Journeys capture at 450×800 (9:16). The tour ran at 780×1688, an iPhone 13 Pro's shape (the canvas is 540×1169), where several problems only show: a taller screen, and text at the size a phone draws it.

## Found and fixed
| Screen | Found | Change |
|---|---|---|
| Clubhouse | The four tabs wrapped three and one. A chosen tab looked different once the pointer rested on it (a tap leaves a phone's button hovered). | One row of four equal tabs; a phone shortens "League Board" to "Board". The chosen state is the same hovered or not. |
| League Board | The Career was two wrapped lines of small print. | Four tiles (rivals beaten, titles, mastery, attempts) and a progress bar for each followed goal. `career_line` keeps the sentence, unshown, for tools and tests (as the HUD's `info` does). |
| Binder | The counts wrapped; three cards left a gap at the right; every item repeated a sentence about history. | Four count tiles; three cards exactly fill a phone's width; the sentence shows once, under the grid. |
| Trophies | One column of tall boxes, about four to a screen, with wrapped names. | On a phone, a full-width row per trophy: art, name, how to earn it. About eight to a screen. The wide shelf is unchanged. |
| Goals | Each Follow button was as tall as its goal's text, which wrapped in a narrow column. | Each goal is a panel: its name beside a compact Follow button, what it asks, a progress bar with its count. A followed goal has a brass border. |
| Aim | The hint wrapped with one orphaned word. With assist controls on, their panel covered the hint. | A phone breaks the hint at its separator, in two balanced lines. With assist on, the "set position…" hint goes (the sliders are labelled) and other lines keep to the free side. |
| Roll view | The slim bar cut the match title to "D1/8 · Opene…". | The slim bar shows the short title ("Opener 1/3"). |
| Rule panel | Narrower than the row it covers, so chip edges showed at both sides. | It spans the bar's width. |
| Shop | The three pinned actions were wider than a phone, so the whole shop ran 15 px past the right edge and cut the money. A SOLD tab covered the last line of the preview. | The pinned actions fit (19 px text); the offers are centred; there is room above the first row for a tab. |
| Result | The text sat at the top of a full-height sheet with the buttons at the bottom. | One centred block; the body scrolls only when it cannot fit. |
| Inspector | "Escape to close" on a phone. | Shown only where there is a keyboard. |

## Left for the owner or Codex
- **Numerals (Codex, art):** in Pixelify Sans the digit 5 is almost the letter S, and 2 is close to Z. In play this reads "140 × S = 700", "Pin S", "$S", "S0%". It is the most damaging legibility problem on the phone, and it is the font's own design (rendered large, the two glyphs differ by one pixel). Proposed as Codex's first Wave 12 claim, UI-A3: a numeral set that cannot be mistaken for letters (patched digits or a second face for numbers; the font is OFL).
- **Missing plaques (Codex, art):** the Trophy shelf shows marked placeholders for The Proprietor, Old Lou and The Custodian, House Champion (`plaque.proprietor`, `plaque.old_lou`, `plaque.custodian_champion`). Proposed with the Neon rivals' plaques in Wave 12.
- **Shop words (owner's call):** the preview above the offers is five lines on a phone ("Next: Division 1 Feature — target 500 in two frames. Boss later: …"), and each owned card is its own full-width Sell button. A shorter preview (the boss's rule behind its ⓘ, as on the bar) and a compact sell list would bring the offers up. Journeys read these sentences, so it is a scoped change, not a tweak.
- **Session buttons (owner's call):** Restart, Clubhouse and Options take the top row of every match screen. They could fold into one menu button on the bar.
- **Phone held sideways:** still lays out 1280 wide (UI-3's limitation, unchanged).
- **Safe areas** (notch, home indicator) are E25.

## Validation evidence
| Command | Outcome |
|---|---|
| `qa.py unit` | PASS |
| J06 with the new checks, old source | FAIL as intended: "the shop and its pinned actions fit the phone's width" (543 wide on a 540 canvas) and "the assist panel never covers the prompt". |
| J06, J02, J05, J08, J10, J11, J11ART headless | PASS |
| New checks | J11: four tabs on one row inside the screen; the Career tiles; the binder tiles equal the counts sentence; three cards across. J10: each board goal has a bar and count. J06: the shop fits the width; the assist panel never covers the prompt. |
| Tour captures, before and after | Shared with the owner; not committed. |
| Full local matrix | See AI-HANDOFF, Wave 11 progress. |
