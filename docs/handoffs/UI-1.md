# Agent task handoff — UI-1 (one card component everywhere)

## Assignment
- **Objective:** Wave 10, first of Claude's three claims. UI-A1's playing card replaces the box buttons in the hand, shop, binder and inspector, with its states and motion (docs/ROADMAP.md, "Art-forward interface: UI-R1").
- **Owner:** Claude. Reviewer: the repository owner, by PR.
- **State:** DONE.
- **Branch:** `claude/roguewood-build`. Base: the "Wave 10 claims" commit `2864889`.

## What was built
- **`CardView`** (src/presentation/card_view.gd):
  - It is a `Button`, so touch, mouse and keyboard/gamepad focus all work, and journeys keep tapping and focusing cards by their existing node names.
  - It draws docs/art/ui/UI-A1.md's card from the 210×300 coordinates at the card's real size. Text is laid out at real pixel sizes, never scaled as a bitmap.
  - Layers: the rarity face (`face-<rarity>.svg`), the art window (the item's `card` art), the name banner, the category badge, the rule icon with a short rule and qualifier, and the rarity seal and label.
  - Below 62% of native size a card is compact: name, art, category and rarity only, with the rule in inspection (UI-A1: small hand cards keep name, category and rarity).
  - **Short rules:** bound to the catalogue rules, not samples. `CardView.summary(item, names)` picks the headline effect (×Mult, +Mult, +$, repeat, +Value) and its qualifier (per…, condition, when down, if standing, after each match). Tactical cards use their play text, upgrades their shop effect, physics-only balls hook and mass. A unit test checks every catalogue item gets a short rule and a known icon.
  - **States:**
    - armed and tactic: lift 8 px, sea-glass outline and a tab;
    - keep: brass outline and tab;
    - sold and locked: hatch and stamp;
    - unaffordable or blocked: light hatch, with the reason in the tab;
    - shop price: a removable overlay, never part of the face;
    - selected (binder): brass outline.
  - **Motion:**
    - deal: 180 ms ease-out, with a 35 ms stagger;
    - flip: 180 ms, swapping face and back at the edge-on midpoint;
    - press: down 2 px;
    - tilt: up to 6°, settling in 150 ms;
    - reduced motion: no lift, tilt or flip.
    - UI state never waits for motion.
  - **Long press** (450 ms, on the frame clock so a slow frame never turns a tap into one) opens inspection, and the release that follows is not a play.
  - **Accessible text:** the card's text label stays in `text`, drawn invisibly, so status words such as SOLD and the binder state stay readable to tools and tests. `icon` stays set to the production icon (the binder's to its card art), also invisible, because Codex's art journeys check it. `expand_icon` keeps that hidden icon from growing the card.
- **Hand** (card_hand.gd):
  - Cards are CardViews; the whole hand shows at once at playing-card proportions.
  - Cards are capped at 150 px tall in portrait, so the hand stays clear of the ball until UI-2 reframes the camera, and 230 px in the landscape side panel.
  - Cycle and Inspect stay.
  - Lab fixture items, which are not in the catalogue, fall back to their title and the old placeholder art.
- **Shop** (shop_panel.gd): offers are CardViews.
  - The price is an overlay.
  - SOLD, CAN'T AFFORD, OWNED MAX and similar show as stamps or tabs.
  - An empty slot shows the card back.
  - The offer label keeps the old text, so "SOLD" and "can't afford" are still in `text`.
- **Shop in portrait (stopgap until UI-2):** offers render as compact 105×150 cards (name, art, rarity, price), the same height as the old buttons. Full-size cards pushed Reroll, Next Match and the Sell list off the screen, and J03C07–C09 tap real screen positions (CI run 42148336118). UI-2 lays the shop out properly.
- **Inspector** (card_inspector.gd):
  - Shows the whole card at inspection size: 240×344 in portrait, 210×300 in landscape.
  - Foil, tilt and the legendary reveal act on the card's illustration. `inspector.art` is that illustration, so Codex's modification badge still attaches to it.
  - The full rules (`ScoreLog.item_text`) show under the card.
- **Binder** (clubhouse.gd): every entry is a 150×214 card.
  - Locked entries are hatched and stamped.
  - Discovered and Mastered entries carry a tab.
  - The selected card has a brass outline.
  - The state words stay in the label.
- **Options:** direct selection is removed (ADR 004 chose the deck). `settings_panel.use_equipment()` remains as a test fixture. Four journeys that test direct-model mechanics use it and log it: J04 (deck_journey), J03C06, J03C10 and J03C11.

## Validation evidence
| Command | Outcome |
|---|---|
| `qa.py unit` (card_view_test.gd) | PASS. Short rules for nine representative items; every catalogue item has a short rule and icon; sold, armed, reduced-motion, price and compact states. |
| J04, J05 and J11, headless and rendered | PASS. Captures were inspected: the hand, shop (portrait and landscape) and binder show the cards. Portrait shop captures taken right after a reroll catch the deal animation mid-way, which is expected. |
| Full CI matrix (local, on `a1a9d0b`) | 150/152. J03C11 armed the wrong card: new hand cards started at zero size and grew a frame later. Fixed in `6fb9c44` (cards are sized as they are created). J03C11 then passes headless and rendered, and J02, J04, J06, J03C06 and J03C10 pass. |
| CI | Run 42163465370 PASS on `6fb9c44` (game and art shards) |

## Decisions and open question
- **Hand size:** in UI-1 the whole hand of four always shows; the cards are smaller in portrait.
- **Open question for the owner:** the owner asked for "2 cards in portrait", but a deck hand holds 4. How portrait shows four is a UI-2 layout question for the owner:
  - paging two at a time;
  - a fanned hand where the touched card rises;
  - four smaller cards, as now.

## Resume exactly here
- Next for Claude: E05-R2 (tethered swing), then UI-2 after the owner approves UI-A1-C.
