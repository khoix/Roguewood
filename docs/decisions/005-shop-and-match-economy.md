# ADR 005 — E08 shop and match economy

Status: accepted for E08 on 2026-10-27, pending the owner's review. **Every price, rate and weight is provisional**: they are the design's §10/§15 starting inputs, not tuned values. E24 owns balance. Items are lab fixtures (`content/fixtures/lab_catalogue.json`, completeness false); production items are E17.

## Money and its scope

- **Run-scoped wallet** (`RunInventory.money`). A new League attempt starts a new inventory with $6 (§4). Nothing here is Career-scoped.
- **Ledger:** every change is a ledger row `{match, kind, amount, item_id}`, with these kinds: start, payout, interest, item_income, purchase, sale, reroll, removal.
  - `stats()` reports gross income (payout, interest and item income), sales, spend (purchases, rerolls and removal), net, savings, rerolls and purchases, for the run or for one match.
  - The wallet always equals the start plus net. A fuzz test and J05 check this.
- **No negative balance:** `pay` refuses rather than going below zero.
  - A purchase must be affordable from the balance alone. Proceeds from a replacement sale cannot fund it.
  - Every refusal leaves the state unchanged.

## Income (`src/rules/economy.gd`)

- **Match settlement** (`settle_match`): interest of $1 per $5 held, capped at $3. It is computed on the balance at match end, **before** the payout is added. Then the $3 payout plus $1 per unused frame.
  - The lab plays both frames of every match (match targets are E09), so it always pays $3.
  - The pure rule and its unit tests cover unused frames.
- **Item income:** an item's payout effects are credited after each scored frame, from `FrameRules.future_effects`.
  - FrameRules defers payouts until after the bank and never retriggers them, so a retriggered Gold pin pays once (unit-tested).
  - A future boss rule that stops item income (Frugal House) belongs to E09/E21, as a flag on this credit step.

## Prices, sales and loops

- **Prices:** the catalogue's `purchase_price`. Rerolls start at $2 and rise by $1 within one shop visit; each visit resets to $2. Removal costs $3 per card.
- **Sales:** half the price **actually paid**, rounded down. A modified item sells together with its modification.
  - Items that cost nothing (the starting kit, future rewards) sell for the catalogue's explicit `resale_price`.
  - Because the paid price is recorded per copy, discounts and later price changes cannot create profit.
  - Buying and immediately selling always loses money, or breaks even at $0. This is checked for every offerable item, by a random 60-session fuzz, and in J05.
- **What cannot be sold:** rack pins (the rack must keep ten), and the House ball (it is never an owned item).

## Ownership and slots (`src/rules/run_inventory.gd`)

- **Rack and reserves:** ten rack positions and two reserves.
  - Buying a pin always asks where to place it. If a reserve is free, the displaced rack pin moves there. If not, every placement is an explicit replacement that sells the old pin.
  - `swap_pins` is the pure rack-editing operation; its UI is E09/E13 work.
- **Charms:** five ordered slots. When they are full, a purchase offers each slot as a replacement (showing its sale value) or Cancel.
- **Equipment deck:** the card collection behind the E07 deck.
  - Capacity is 16 cards, with two copies per card identity: `min(max_owned, 2)`. A full deck likewise requires a replacement or Cancel.
  - Bought ball and tactical cards join the deck at the next match start. `CardDeck.sync` keeps the deck's own RNG stream.
  - **Tactical cards are deck cards** (§15). Played ones leave the run at match end (`drop_consumed`) and cannot be sold. The two "consumable slots" in §4 belong to the superseded direct-selection rules. The lab's direct-selection option shows the run's first two ball types plus its unused tactical cards.
- **Modifications:** at most one per pin or ball card, as §15 says initially.
  - A purchase lists every eligible host and attaches to the chosen one.
  - Incompatibility is checked against the **host**, so a Gilded modification excludes a Gold pin host only, not every purchase of a Gold pin.
  - Pin modifications join the pin's effects. A ball card's modification joins its roll's effects when that card is thrown. The score log credits each effect to the item that supplied it.
- **Nothing is dropped silently.** Every purchase into a full slot goes through a choice sheet with Cancel. A replaced item is sold for the sale value shown on its button.

## Shop generation (`src/rules/shop.gd`)

- **Slots:** Charm, Charm, Equipment (ball or pin), Tactical and Workshop (pin or ball modification).
  - Technique lessons need new effect vocabulary (frame-category base Value and Mult), and shop upgrades need capacity rules. Both are deferred to E17/E18, not faked.
- **Generation:** each slot chooses a category uniformly among those with eligible items, then rolls an eligible rarity, then picks an item by pool weight.
  - Rarity weights are common 55, uncommon 30, rare 12, epic 3 and legendary 0. Rarities with nothing eligible are dropped and the rest renormalized (unit-tested at Division 1 and 2).
- **Eligibility** is schema-driven and checked before sampling. An item is excluded if any of these apply:
  - zero pool weight, or legendary (reward-only);
  - an unmet unlock prerequisite (E15 supplies `unlocked`);
  - `earliest_division` above the current Division;
  - owned copies at `copy_limit`;
  - incompatible with an owned item;
  - a modification with no eligible host;
  - already offered in this shop.
- **Rerolls** regenerate all five slots and avoid the previous offers wherever the pool allows (unit-tested across 20 seeds).
- **Affordability:** if no offer is affordable but an eligible affordable item exists, one slot is replaced with it. This follows §15's guarantee. "Broadly usable" currently means eligible: every eligible offer has somewhere to go.
- **RNG:** a dedicated seeded stream (`hash([session seed, "shop"])`). Physics, the deck and animation never consume it. Its state is saved, and a restored shop rerolls identically.
- **Selection log:** every pick records visit, reroll, slot, category, rarity, eligible-pool size and item, plus `guarantee` when the affordability rule fired. It is for debugging pool dilution and dead shops.

## Lab flow

After the second frame of a match, Next Rack opens the Pro Shop:
- It shows the settlement explained: payout, interest on the held balance, and item income.
- Offers show slot, rarity, name, effect and price. Sold, unaffordable or blocked offers are disabled with a short reason.
- Reroll, removal service, Sell buttons and an owned-items summary sit below.
- Next Match recombines the deck with the purchases.
- Money is always on screen in the status line, and the session fixture tracks it.

## Open questions

- **Removal against selling:** selling also removes a card and pays money, so the $3 removal service is currently dominated. It only makes sense if starting-kit or reward cards sell for $0, or if removal gains another role (for example removing an unsellable curse). Decide during E17/E24.
- **Starting-kit sale values:** the lab's starter cards sell for $2 each and Wood pins for $1. Selling the kit early may be too strong. This needs E24 measurement.
- **Interest timing:** interest is on the balance before payout (Balatro-like). Paying it after payout would make saving more dominant. E24 should measure saving against investing.
- **Placement funding:** a purchase cannot be funded by the replacement's own sale proceeds. This is conservative; reconsider if players find it confusing.
- **Category choice:** the Equipment and Workshop slots pick a category uniformly. Per-category slot weights may be needed once the catalogue is larger.
