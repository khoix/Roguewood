# Roguewood roadmap: Wave 5 to release

Coordinator: Claude. Written 2026-10-28, after Wave 4 merged (PR #15). This is the plan for every remaining milestone. docs/AI-HANDOFF.md records live state and the claims of the current wave; where the two disagree, the checkpoint wins and this file is corrected.

## Words used here
- **Phase:** a stage of the roadmap with an exit test. Phases are built around Leagues, because a League is what a player plays.
- **Wave:** one merge batch: a fixed set of claims for both agents, closed by a "Wave N closed" commit and merged by one PR. Waves are numbered in order and only ever mean that.
- **Session:** one bounded execution by one agent (one claim). A wave holds about **3 Claude sessions and 4 Codex sessions**.
- Wave numbers past the current phase are estimates. They are re-estimated at the end of every phase, from measured sessions per wave.

## Where we are
- **Done and on main (E01–E16):** throw, scoring, deck, shop, Division loop, saves, art bible and motion, vertical slice, eight-Division campaign generator, Career and unlocks, Clubhouse.
- **Content pipeline (E17–E21), started:** 36 items playable (4 balls, 8 pins, 24 Charms) plus 2 boss rules and 1 kit. 30 more are written but not playable (4 balls, 2 pins, 3 tactical cards, 9 boss rules, 12 modifications). 48 identity art sets exist; 31 items have effects and sound.
- **Not started:** League specs (0 of 6), the rival roster (2 of 20 rivals), lane conditions as content (0 of 12; two campaign fixtures exist), shop upgrades (0 of 16, and no system for them), kits (1 of 10). The House League has 2 of its 8 Divisions.

## What was wrong with the earlier plan, and what changes
| Problem | Fix |
|---|---|
| The old map's columns were called "waves" but meant dependency order, so it read as a schedule (E22 "by Wave 3"). | Phases and waves are separate words with separate numbers (above). |
| Content went category by category, so no League could be finished, and E22 (themes), E21 (rivals) and E23 (kits) had nothing to start from. | **Each phase completes whole Leagues.** A League bundle holds its spec, rivals, rules, lane conditions, kit and the items its theme favours. |
| Each item was handled 5 times across 4+ waves: definition, mechanics, visual brief, identity art, native check, effects. | **Claude writes and implements an item in one session** (when it uses existing rule pieces). **Codex does brief, identity art, effects, sound and the native check in one session** per batch of landed items. |
| Boss-rule identity art was scheduled before the rivals that present those rules. | A boss rule's badge and art are made in its rival's session (E21), which the plan already scopes to include the rule badge. |
| Codex's lane held about twice Claude's sessions, because League integration (E22) and platform packaging (E26) sat with Codex on top of all art. | **League configuration and integration move to Claude; Codex keeps each League's theme art. E26 moves to Claude;** Codex fixes art budgets it reveals. Codex still owns all art, effects and audio. |
| C02 and C03 built new rule primitives and landed their items in the same session; the plan asks for primitives first. | Novel primitives get their own High session before the items that use them. |
| The milestone ledger still said E10, E13 and E15 were "not yet merged". | Corrected in the checkpoint. |

## Ownership
- **Claude:**
  - League specs, rules, lane conditions, kits, unlocks, item definitions and mechanics (E17, E18).
  - League configuration and full-League journeys (the E22 integration part).
  - Kits, difficulty, endless (E23); balance (E24); onboarding and accessibility code (E25 core).
  - Platform packaging and device evidence (E26); content audit (E27); release candidate and delivery (E28, E29).
- **Codex:**
  - Every art component: briefs, identity art, effects and audio (E19, E20).
  - Rival presentation, including each rule's badge (E21).
  - Each League's theme art: environment, signage, lane-condition visuals, music identity (E22-Lxx-ART).
  - Symbols and reduced-effects art (E25-ART); kit, medal and cosmetic art (E23-ART).
  - The asset audit (E27-ART); art-budget fixes found by E26 and E28.
- Codex never changes scoring, economy or Career rules; Claude never produces final art.

## Working model
1. **Claude, item batches.** A batch writes and lands at most 6 items that use existing rule pieces: definition, mechanics, tests and native evidence, in one session (Medium). An item needing a new primitive waits for a primitive session (High) that builds and tests the primitive first. Items already written in E17-D01, D03 and D04 land in the League bundle that uses them.
2. **Codex, AV batches.** One session per 3 landed items (the E20 limit): brief, identity art, in-play appearance, activation, sound, reduced motion, native check, then both completeness flags (Medium, or High for complex effects). Items that already have identity art only need the native check, effects and flags.
3. **Pipeline.** Codex's AV batch for a set of items runs in the wave after Claude lands them. Rivals and theme art run in the wave after the League spec.
4. **League integration** (Claude, High) closes each League: its 8 Divisions, rivals, lane pool, specialist weights, starter kit and branch unlock. It passes one full seeded attempt through native input (a J09-style journey per League).
5. **Batch limits** stay as written in the execution plan: 12 definitions, 6 mechanics items, 4 identity sets, 3 abilities per session. They are never raised to save sessions.

## How the remaining content is split
The full release is 270 definitions plus 6 League specs (design §15–§16). The items still to finish are split into the League bundles below. Each League keeps its theme's specialist items; House carries the broad pool and the systems every League uses. Item counts are targets for the bundles; a League spec may move a few items between bundles, and the per-category totals must stay exact.

| Remaining | House | Neon | Salvage | Royal | Spectral | Foundry | Total |
|---|---|---|---|---|---|---|---|
| Balls (4 of 24 playable) | 2 | 4 | 2 (incl. Gold Ball) | 3 | 4 (incl. Ghost) | 5 (incl. Spark, Splitter) | 20 |
| Pins (8 of 32) | 2 | 3 | 5 | 5 | 4 (incl. Echo Pin) | 5 (incl. Fuse) | 24 |
| Ball modifications (0 of 16) | 4 (Chalk Grip, Spin Wax, Coin Slot, Echo Charge) | 3 (incl. Bumper Guard) | 3 | 0 | 2 | 4 (incl. Lead Core) | 16 |
| Pin modifications (0 of 16) | 4 (Brass Cap, Gilt Leaf, Lantern, Keystone) | 1 | 5 | 2 (incl. Spearhead) | 0 | 4 (incl. Lead Weight) | 16 |
| Charms (24 of 100) | 16 | 12 | 12 | 12 | 12 | 12 | 76 |
| Tactical cards (0 of 24) | 6 (incl. Nudge, Reserve Call, Rule Waiver) | 3 | 4 | 3 | 4 | 4 | 24 |
| Shop upgrades (0 of 16) | 6 (and the system) | 2 | 2 | 2 | 2 | 2 | 16 |
| **Items** | **40** | **28** | **33** | **27** | **28** | **36** | **192** |
| Boss rules and rivals (2 of 20) | 4: Dead Straight ✓, Clean Sweep ✓, House Rules, +1 new | 3: Oil Slick, Narrow Lane, +1 | 3: Frugal House, Dull Pins, +1 | 3: One and Done, Mult Cap, +1 | 3: Charm Freeze, +2 | 4: Heavy Set, +3 | 20 |
| Lane conditions (0 of 12) | 2 (House oil, Dry backend) | 2 | 2 | 2 | 2 | 2 | 12 |
| Kits (1 of 10) | 2 (House ✓, +1) | 1 | 2 | 2 | 1 | 2 | 10 |

- **Rivals:** each boss rule has one rival (20 in all, design §18). A League's champion is its final-Division boss: one of its own rivals with a compatible two-rule set, which adds no new mechanic. Wave 5 writes the full roster (names, rules, Leagues), so Codex can plan rival art early.
- **Unlocks:** each League spec assigns its items to initial, boss, championship and mastery unlocks. Across all bundles they must meet the design's availability targets (12/24 balls, 16/32 pins and 60/100 Charms available at the start). `qa.py content` checks the graph.

## Phases
Estimated sessions: Claude about 75, Codex about 97. At 3 and 4 sessions per wave, that is about **26 waves (Waves 5–30)**. Codex's work on each League trails Claude's by about one wave.

| Phase | Waves (est.) | Claude | Codex | Exit test |
|---|---|---|---|---|
| **1. House League complete** | 5–8 (Codex to 9) | 8 modifications; House spec and the 20-rival roster; House rules and lane conditions; tactical-card primitives; shop-upgrade system; 4 item batches; House integration | C03 effects and flags; D04 briefs; AV for every House item; House rivals R03–R04; House theme art | 8-Division House League playable end to end with final art and effects for all its content; full-League journey passes |
| **2. Neon and Salvage** | 9–15 (Codex to 16) | Per League: spec; rules and lanes; primitives; 5–6 item batches; integration | Per League: AV batches; 3 rivals; theme art | All three starting Leagues playable and winnable with their initial content |
| **3. Royal, Spectral, Foundry** | 16–25 (Codex to 27) | The same template; branch unlocks (win House → Royal, Neon → Spectral, Salvage → Foundry); remaining D01/D04 primitives (phasing, splitting, mass) | The same template | Six Leagues; every planned definition implemented, illustrated and animated |
| **4. Progression and onboarding** | 26–27 (Codex 28) | E23: difficulty tiers, medals, endless with large-score handling, remaining kit work; E25 core: tutorial, alternate controls, safe areas, J14 | E25-ART symbols and reduced effects; medal, kit and cosmetic art | J13 and J14 pass; every kit starts legally |
| **5. Balance and release** | 28–30 | E24 balance (Extra High, 2–3 sessions); E27 content audit; E26 platform builds (one per platform, needs hardware); E28 release candidate; E29 delivery | E27 asset audit; fixes from E26 and E28 | E28's full matrix on the frozen candidate, then delivery |

### Phase 1 waves (concrete)
| Wave | Claude | Codex |
|---|---|---|
| **5** (open) | E18-C04: land Chalk Grip, Spin Wax, Coin Slot, Echo Charge, Brass Cap, Gilt Leaf, Lantern, Keystone (Medium). E17-L01: House League spec (8 Divisions, 4 rivals, champion, lane pool, kit, unlocks) and the 20-rival roster (High). | AV-C03: native checks, artwork flags, effects and sound for Crown Pin, Split Specialist, Sweet Spot, Back Row, Underdog, Crown Jewel (2 sessions, High). E17-D04-ART briefs (Medium). |
| **6** | E18-C05: House Rules plus the new House rule, and lane conditions as catalogue items (High). E18-C06: tactical-card primitives, landing Nudge, Reserve Call, Rule Waiver (High). E18-C07: shop-upgrade system and 6 upgrades (High). | AV-C04: the 8 modifications (3 sessions). E22-L01-ART: House theme for 8 Divisions (High). |
| **7** | DC-H1 to DC-H3: 18 House items (3 sessions, Medium). | E21-R03, R04: House's new rivals with their rule badges. AV-C06: the 3 tactical cards. AV-C07: the 6 upgrades (2 sessions). |
| **8** | DC-H4: the last 5 House items. E22-L01: House League integration and its full-League journey (High). | AV-H1, AV-H2: the first 12 House items (4 sessions). |
| 9 (Phase 2 starts) | E17-L02: Neon spec; Neon rules and lanes. | AV-H3, AV-H4: the last 11 House items. |

### League template (Phases 2 and 3)
| Wave | Claude | Codex |
|---|---|---|
| a | League spec; its rules and lane conditions | AV tail of the previous League |
| b | New primitives; item batches 1–2 | Rivals; theme art |
| c | Item batches 3–5 | AV for batches 1–2 |
| d | Last item batch; League integration and journey | AV for batches 3–5 |

## Decisions only the owner can make
| When | What | Why it matters |
|---|---|---|
| After Wave 8 | Play the full House League (desktop is enough) and decide the equipment model (ADR 004: deck or direct). | Phase 2 multiplies tactical cards and deck items. Changing the model later means reworking them. |
| By the end of Phase 2 | Provide phone hardware (and an iOS toolchain if iOS stays a target), or decide that desktop evidence is acceptable for now. | Real-phone feel (E05), readability (E12), the play session (E13) and all of E26 are blocked without it. Finding feel problems before four more Leagues of content is much cheaper. |
| Phase 5 | Human playtests to corroborate the balance study. | E24 may not present simulation alone as proof of fun. |

## Risks to watch
- **Throughput:** Waves 1–4 held 2 Claude claims each, and between 3 and 17 Codex batch claims. This plan raises Claude to 3 claims per wave; at 2 per wave Claude's lane alone would run to about Wave 40. If a phase runs long, re-plan the wave numbers at its end; batch limits are never raised to compensate.
- **Codex trails Claude:** the AV pipeline is one wave behind by design. If it falls two waves behind, Claude's next wave takes Phase 4 systems work instead of new items.
- **Physics-heavy items** (Ghost, Splitter, Spark, Fuse, mass modifications) sit in Spectral and Foundry and need their own High primitive sessions; they are the most likely to run over.
- **Balance** is provisional until E24. Each League integration sets provisional targets from the slice simulation, so E24 tunes a working game rather than rescuing a broken one.
