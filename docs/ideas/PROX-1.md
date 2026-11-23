# PROX-1: Neighbour effects for Charms and pins (owner, 2026-11-23)

The owner's proposal, kept as sent; the coordinator's evaluation and the owner's decisions follow it.

## The owner's direction
- "I like the idea of a charm that mimics the one beside it (like Blueprint), or other charms with proximity effects/actions."
- "I like the idea of pins with effects and actions relative to the pin beside them. And this could be done by pin or by pin mod."
- "These ideas need to be reevaluated and properly balanced for gameplay. Some could even be introduced in the pending leagues."

## Settled with the owner (2026-11-23)
1. **The copy Charm copies the Charm to its right, at full strength** (as Balatro's Blueprint does). There is no copy-left Charm.
2. **The existing Leagues stay as they are.** House and Neon get no new items; this work goes only into the pending Leagues (Salvage, Royal, Spectral, Foundry).
3. **Spread (M2) stays in, with the player choosing.** When the player attaches Spread to a pin, they also choose which neighbouring pin it spreads to. The choice is part of placing it, on the rack map, and it stays until the modification is moved or replaced. The link stays with the spot if that pin is replaced or moved.
4. **Salvage takes C1, M2, P1 and M3** (coordinator's proposal, confirmed by the owner): C1 is Rare, at most one in the Charm row, and is Salvage's champion first-clear Charm; M2 Spread is an initial pin modification; P1 Chain pin is an initial pin; M3 Shared takes the place of one planned pin modification. Salvage's per-category totals stay as E17-L03 has them.
5. **Later Leagues** take the rest where suggested, each settled in that League's spec: Royal C3 and P4; Spectral C4, C5 and P3; Foundry M1 and P2. **C6 (Amplifier) is set aside** for now: it changes other Charms' amounts, the heaviest engine change; revisit in Phase 3 if a League needs it.

## Why
- **Today, order barely matters.** The only order a player arranges that changes a score is a ×Mult Charm relative to +Mult Charms. In content/catalogue.json:
  - Charms: 22 +Mult, 17 ×Mult, 8 +Value, 3 grow their own Value, 5 pay money;
  - no pin or pin modification multiplies Mult, so rack placement never changes the score.
- **Balatro, for comparison:** besides +Mult and ×Mult Jokers, its order-sensitive play includes copy Jokers (Blueprint copies the Joker to its right), the played cards' order, and the held-in-hand order.
- **Neighbour effects** would make the Charm row and the rack two real decisions, in line with the game's identity (a rack you build).

## What "beside" means
- **Charms:** the slot to the left and the slot to the right in the Charm row (5 slots, resolved left to right after pins, balls and the release grade).
- **Pins:** rack spots one pin-spacing apart in the triangle. Nudge (`consumable.nudge`, src/rules/tactics.gd, `ADJACENT`) already defines this; verify this table against that code:

  | Spot | Neighbours | Count |
  |---|---|---|
  | 1 | 2, 3 | 2 |
  | 2 | 1, 3, 4, 5 | 4 |
  | 3 | 1, 2, 5, 6 | 4 |
  | 4 | 2, 5, 7, 8 | 4 |
  | 5 | 2, 3, 4, 6, 8, 9 | 6 |
  | 6 | 3, 5, 9, 10 | 4 |
  | 7 | 4, 8 | 2 |
  | 8 | 4, 5, 7, 9 | 4 |
  | 9 | 5, 6, 8, 10 | 4 |
  | 10 | 6, 9 | 2 |

- **Pins resolve in rack order (1 → 10).** If any pin gains ×Mult, its spot number matters relative to +Mult pins, as Charm slots do now.

## Candidate concepts (working descriptions; names, rarities, prices and numbers are for the spec)

### Charms
| # | Concept | Effect (provisional) | Balance notes |
|---|---|---|---|
| C1 | Copy right (full strength) | Acts as a full copy of the Charm to its right, with that Charm's conditions and growth. | The strongest idea: it doubles the best ×Mult Charm. Balance with rarity (Rare), price, at most one per Charm row, and the targets of the Leagues it appears in. |
| C3 | Ends of the row | Stronger in the leftmost or rightmost slot, e.g. ×Mult only in the rightmost slot, +Value only in the leftmost. | Simple. Fits Royal. |
| C4 | Company | +Mult for each neighbouring Charm of a given kind (adds Mult, multiplies Mult, adds Value). | Needs Charm "kind" facts. |
| C5 | Lone | Bonus per empty neighbouring slot. | A counterweight to C4. |
| C6 | Amplifier | The neighbours' numbers count +50%. | Heaviest engine change. Set aside. |

### Pins and pin modifications
| # | Concept | Effect (provisional) | Balance notes |
|---|---|---|---|
| P1 | Chain pin | When it falls: +Value per fallen neighbour. | Best at the 5 spot (6 neighbours). |
| P2 | Cluster pin | When it falls with all its neighbours: ×Mult (small, e.g. ×1.25–1.5). | The first pin ×Mult; spot numbers matter. |
| P3 | Guard pin | Standing at the end of the frame: +Mult per standing neighbour. | Rewards leaves and splits. |
| P4 | Mimic pin | When it falls: copies the Value of its highest-Value neighbour. | Placement next to rich pins. |
| M1 | Linked (pin modification) | When its pin falls, each fallen neighbour's modification triggers once more. | A retrigger; the resolver caps retriggers at 8. |
| M2 | Spread (pin modification; the player chooses the neighbour) | The modification works on its own pin and on one chosen neighbouring pin. | No new scoring math; a second tap on the rack map; the choice is saved with the rack. |
| M3 | Shared (pin modification) | +Value to this pin per neighbour carrying any modification. | Rewards modified clusters. |

## Engine work (before any item uses it)
- **Neighbour facts:** for a pin owner, `fallen_neighbours` and `standing_neighbours` as `per` kinds and a condition `neighbours_fallen: all`; for a Charm owner, the left and right neighbours' kinds and whether the slot is first or last. Closed-vocabulary additions to FrameRules and CONTRACTS.md.
- **Copy op** (`copy_right`, full strength): resolves the right-hand neighbour's Charm effects as this Charm's, with its own source label. Settle: chains resolve to the first real Charm with no loops; whether growth, payouts and after-bank effects are copied (Blueprint copies most, money included); copying from the last or an empty slot does nothing.
- **Pin-to-pin effects:** each pin's spot and neighbour set as facts (pins already carry `position`).
- **Spread's placement:** a second step on the rack map with the pin's neighbours highlighted; the chosen spot saved with the modification in RunInventory and shown on the rack.
- **Presentation:** the Charm row shows what a copy Charm copies; the rack map highlights neighbours when inspecting or placing; the score log names the copy ("Copy of X").
- **Tests:** unit tests per fact and op (copy chains, empty slots, order), contract-rules cases, a native journey per item.

## Balance plan
- Every number is a placeholder. Compare win rates and score bands with and without each concept in the League simulations against the targets (E24).
- Copy Charm guardrails: Rare, a high price, at most one in the row, the Leagues and unlock tiers that carry it, and whether their targets absorb a doubled ×Mult Charm.
- Pin ×Mult (P2) stays small and conditional, so the rack does not outrank the Charm row.
- Each concept is explainable on its card in one line and shown in the score log.

## Schedule (coordinator, 2026-11-23; docs/AI-HANDOFF.md, Wave 15 queue)
1. **E17-L03b** (Claude, Medium): Salvage's item plan revised with C1, M2, P1 and M3, totals unchanged.
2. **E18-C21** (Claude, High): neighbour facts, the copy op, contracts and tests.
3. **Spread's placement** on the rack map (Claude, Medium).
4. Salvage's other rule pieces, then its item batches DC-S1… (Claude, Medium, at most 6 items each).
5. AV-S batches (Codex), with the copy link, neighbour highlights and "Copy of X".
6. A Salvage League simulation when it goes live (E22-L03), with and without the copy Charm, before Salvage closes.
