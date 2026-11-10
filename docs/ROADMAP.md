# Roguewood roadmap: Wave 5 to release

Coordinator: Claude. Written 2026-10-28, after Wave 4 merged (PR #15). This is the plan for every remaining milestone. docs/AI-HANDOFF.md records live state and the claims of the current wave; where the two disagree, the checkpoint wins and this file is corrected.

## Words used here
- **Phase:** a stage of the roadmap with an exit test. Phases are built around Leagues, because a League is what a player plays.
- **Wave:** one merge batch: a fixed set of claims for both agents, closed by a "Wave N closed" commit and merged by one PR. Waves are numbered in order and only ever mean that.
- **Session:** one bounded execution by one agent (one claim). A wave holds about **3 Claude sessions and 4 Codex sessions**.
- Wave numbers past the current phase are estimates. They are re-estimated at the end of every phase, from measured sessions per wave.

## Where we are
- **Done and on main (E01–E16):** throw, scoring, deck, shop, Division loop, saves, art bible and motion, vertical slice, eight-Division campaign generator, Career and unlocks, Clubhouse.
- **Content pipeline (E17–E21), in progress (counts last updated in Wave 6; Waves 7–8 added House's remaining 23 items):**
  - Playable: 60 items. That is 4 balls, 8 pins, 24 Charms, 8 modifications, 3 tactical cards, 6 shop upgrades, 4 boss rules, 2 lane conditions and 1 kit.
  - Written but not yet playable: 27. That is 4 balls, 2 pins, 4 modifications, 16 boss rules and 1 kit.
  - Codex's art and effects counts are in each AV handoff.
- **League content:** the House spec (8 Divisions) and the roster of all 20 rivals are written; the other five League specs are not. The House League is playable with all 8 Divisions and all 40 of its items (Wave 8, E22-L01); Codex's art for its last 11 items is AV-H3/H4 (Wave 9).
- **Not started:** lane conditions beyond House (2 of 12), shop upgrades beyond House (6 of 16; the system exists), kits beyond House.

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
Estimated sessions: Claude about 75, Codex about 97. At 3 and 4 sessions per wave, that is about **28 waves (Waves 5–32)**, including the throw rework (E05-R1, Wave 9) and the art-forward interface (UI-R1, Waves 9–10), which together moved every later wave back by two. Codex's work on each League trails Claude's by about one wave.

| Phase | Waves (est.) | Claude | Codex | Exit test |
|---|---|---|---|---|
| **1. House League complete** | 5–8 (Codex to 9) | 8 modifications; House spec and the 20-rival roster; House rules and lane conditions; tactical-card primitives; shop-upgrade system; 4 item batches; House integration | C03 effects and flags; D04 briefs; AV for every House item; House rivals R03–R04; House theme art | 8-Division House League playable end to end with final art and effects for all its content; full-League journey passes |
| **2. Neon and Salvage** | 11–17 (Codex to 18) | Per League: spec; rules and lanes; primitives; 5–6 item batches; integration | Per League: AV batches; 3 rivals; theme art | All three starting Leagues playable and winnable with their initial content |
| **3. Royal, Spectral, Foundry** | 18–28 (Codex to 29) | The same template; branch unlocks (win House → Royal, Neon → Spectral, Salvage → Foundry); remaining D01/D04 primitives (phasing, splitting, mass) | The same template | Six Leagues; every planned definition implemented, illustrated and animated |
| **4. Progression and onboarding** | 28–29 (Codex 30) | E23: difficulty tiers, medals, endless with large-score handling, remaining kit work; E25 core: tutorial, alternate controls, safe areas, J14 | E25-ART symbols and reduced effects; medal, kit and cosmetic art | J13 and J14 pass; every kit starts legally |
| **5. Balance and release** | 30–32 | E24 balance (Extra High, 2–3 sessions); E27 content audit; E26 platform builds (one per platform, needs hardware); E28 release candidate; E29 delivery | E27 asset audit; fixes from E26 and E28 | E28's full matrix on the frozen candidate, then delivery |

### Phase 1 waves (concrete)
| Wave | Claude | Codex |
|---|---|---|
| **5** (open) | E18-C04: land Chalk Grip, Spin Wax, Coin Slot, Echo Charge, Brass Cap, Gilt Leaf, Lantern, Keystone (Medium). E17-L01: House League spec (8 Divisions, 4 rivals, champion, lane pool, kit, unlocks) and the 20-rival roster (High). | AV-C03: native checks, artwork flags, effects and sound for Crown Pin, Split Specialist, Sweet Spot, Back Row, Underdog, Crown Jewel (2 sessions, High). E17-D04-ART briefs (Medium). |
| **6** | E18-C05: House Rules plus the new House rule, and lane conditions as catalogue items (High). E18-C06: tactical-card primitives, landing Nudge, Reserve Call, Rule Waiver (High). E18-C07: shop-upgrade system and 6 upgrades (High). | AV-C04: the 8 modifications (3 sessions). E22-L01-ART: House theme for 8 Divisions (High). |
| **7** | DC-H1 to DC-H3: 18 House items (3 sessions, Medium). | E21-R03, R04: House's new rivals with their rule badges. AV-C06: the 3 tactical cards. AV-C07: the 6 upgrades (2 sessions). |
| **8** | DC-H4: the last 5 House items. E22-L01: House League integration and its full-League journey (High). | AV-H1, AV-H2: the first 12 House items (4 sessions). |
| **9** | In this order: E26-W01 Web export (High), then E05-R1a and E05-R1b, the held-ball throw (2 sessions, High). All owner-approved 2026-11-03/04. W01 is the claim that carries into Wave 10 if it overruns. | UI-A1: the interface visual target for the owner's approval (2 sessions, High). AV-H3: House item art (2 sessions, Medium; High for counted effects). |
| **10** | UI-1: one real card everywhere (High). UI-2: every screen in the approved layout, score-chain choreography (High; after UI-A1-C). E05-R2: the tethered swing (High; owner-approved 2026-11-05). | UI-A1-C: the layout revision and side-space backdrop options (Medium; first). UI-A2: foil, rarity and theme on the card and frames (Medium–High). AV-H4: the last House item art (2 sessions). |
| **11** (Phase 2 starts) | In this order: UI-3, the phone pass (High; owner, 2026-11-08: first, ahead of Neon), the ordinal retrigger labels (Low), then E17-L02: the Neon spec (High; carries into Wave 12 if UI-3 runs long). Added by the owner (2026-11-09): UI-4, the GUI review after the phone pass (Medium). | AV-T01: throw charge and sparkle effects and sounds for the tethered swing (Medium; done). The Neon rivals and theme moved to Wave 12. |
| **12** (claimed) | League template wave b, ending with the League live (owner, 2026-11-09): E18-C14, the Neon primitives (High); DC-N1 and DC-N2, the first twelve Neon items (2 sessions, Medium); E22-L02, the Neon League live with its full-League journey (High; carries into Wave 13 if the wave runs long). | UI-A3: numerals that cannot be read as letters (Medium; first). E21-R05 to R07: Slick, Laser Lena and DJ Flicker with rule badges and plaques, plus the three missing House plaques (3 sessions). E22-L02-ART: the Neon theme (High, 2 sessions). |
| **13** (estimate) | DC-N3 to DC-N5: the other sixteen Neon items, with any primitives they still need; then E17-L03, the Salvage spec. | AV-N1 and AV-N2 (the first twelve items); the tail of the Neon theme. |

### Phone pass: UI-3 (owner trial, 2026-11-08)
The owner played the web build on a phone. Findings: the swing was stiff to the point of barely working; a held ball could not swirl below the foul line; the House Kit badge sat in the lane; the top HUD covered the pins; the frame review was pinned left with empty space; shop art was small and text-heavy; the hand and top HUD stayed up while the ball rolled; most text was too small to read.
- **Decided:** full charge at 3.5 turns a second (was 6), still tunable; the phone pass runs first in Wave 11.
- **Owner's direction:** not just bigger text. A minimal redesign so every screen still works with the larger text.
- **Scope (Claude, High):**
  - **Swing (E05-R3):** swirls are told from flicks by a steady turn over three steps (not a finger-speed cap), so brisk, larger circles count; the held ball follows the finger below its start point, back over the approach.
  - **Readable scale:** portrait lays out for a narrower logical width on phones, so all text is about a third larger, and every screen is re-fitted for it: fewer words, icons where a word was, and content that moves behind a tap instead of shrinking.
  - **Roll view:** while the ball rolls and the frame scores, the hand leaves and the top HUD collapses to one slim line.
  - **Top chrome:** one row for the slip, rival and Charms; the prompt and kit badge leave the lane so the pins show.
  - **Frame review:** centered, numbers large, the chain full width.
  - **Shop (portrait):** two columns of large cards; payout, rack and sales behind tabs.

### GUI review: UI-4 (owner request, 2026-11-09)
After the phone pass the owner asked for what it had missed. Claude reviewed every screen at an iPhone's shape with a new capture tour (tools/capture_phone_tour.gd) and fixed what the layout owned: the Clubhouse's four pages (which UI-3 had only fitted), the aim hint, the roll view's title, the shop running past the screen's edge, and the result sheet. See docs/handoffs/UI-4.md.
- **For Codex (Wave 12, UI-A3):** the font's 5 reads as S and its 2 as Z, so scores read "140 × S = 700". This is the largest legibility problem left on the phone.
- **Open owner decisions:** a shorter shop preview with a compact sell list; one menu button in place of Restart, Clubhouse and Options.
- **The Neon League goes live in Wave 12** (owner, 2026-11-09), with its first twelve items, instead of after its last batch. The League template below is otherwise unchanged; later Leagues can follow either order.

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
| ~~After Wave 8~~ | **Decided 2026-11-04: the draw-and-cycle deck** (ADR 004). | Phase 2's tactical cards and deck items are written for the deck. |
| By the end of Phase 2 | Provide phone hardware (and an iOS toolchain if iOS stays a target), or decide that desktop evidence is acceptable for now. | Real-phone feel (E05), readability (E12), the play session (E13) and all of E26 are blocked without it. Finding feel problems before four more Leagues of content is much cheaper. |
| Phase 5 | Human playtests to corroborate the balance study. | E24 may not present simulation alone as proof of fun. |

### Tethered swing: E05-R2 (owner decision, 2026-11-05)
The owner asked for the PoGo-style ragdoll fling: while held, the ball swings around the touch point like a hula hoop around a waist, not just following the finger.
- **The finger stays inside the ball:** the ball's centre orbits the touch point on a soft, low-damping tether capped at about 0.8 of the ball's on-screen radius.
- **Orbit speed sets the charge, not loop count:** the curve charge is the orbit's current angular speed, slightly smoothed. Faster swirling gives more curve, and no rotation has to be completed.
- **Momentum:** the swirl winds down on its own damping when the finger stops, and the charge falls with it. Clockwise hooks right; reversing must slow the orbit before it builds the other way.
- **Release:** the flick dominates. The orbit is smaller than the ball, so its sideways nudge is small.
- **Unchanged:** the sparkle threshold, cues, vibration and the launch contract all stay as they are.
- **Tuning page additions:** orbit cap, swing rate, damping and the speed for full charge.
- **Deliverables:** a short animated clip of the swirl for the owner. ADR 011 is updated, replacing R1's charge-per-radian rule.
- **Schedule:** Claude, Wave 10, High. AV-T01 moves to Wave 11 so its effects follow the orbit.

### Art-forward interface: UI-R1 (owner decision, 2026-11-04)
First impression (owner): the game reads as a wall of text with tiny art icons, plain borders and cards that look like boxes. Design §17 already requires premium collectible cards, framing that fits the art, tactile card handling and no generic panels, but no milestone owned the card faces, frame kit or interface motion. UI-R1 is a split milestone (art: Codex; integration and UI: Claude):
- **UI-A1** (Codex, Wave 9, High, 2 sessions): the visual target at actual size, portrait and landscape: a playing-card face (card proportions and corners, an art window taking most of the face, name banner, rarity frame, category mark, short icon-led rule text), a card back, a frame and border kit for the HUD, shop, score slip and panels (House first), a pixel font, and Value, Mult and $ icons. **Owner approval gates UI-1.**
- **UI-1** (Claude, Wave 10, High): one card component used in the hand, shop, binder and inspector (frame, art, rarity and foil layers); deal, draw, flip, cycle and discard motion with press and tilt; full rule text moves to long-press inspect; direct selection leaves Options (ADR 004 decided the deck).
- **UI-2** (Claude, Wave 10, High): HUD, shop, score resolution, menus and Clubhouse in the frame kit; text cut to icons and numbers; the score chain resolves in order.
- **UI-A2** (Codex, Wave 10, Medium–High): foil and rarity treatments on the card, per-League frame variants, the final icon pass.
- **Owner review:** UI-A1 mockups before UI-1; screenshots and a phone play-through after UI-2.
- **Owner decisions on UI-A1 (2026-11-05):**
  - **Landscape throw screen:** the lane renders full width. A framed top-bar HUD spans the width (League and Division, score, target, money, Options). Framed panels sit over the empty flanks: the hand on the left (with deck count, Cycle and Inspect); the score slip, rival and rule, and Charm slots on the right. Each panel is about 19% of the width, and never covers the lane corridor; on narrow landscape (4:3) the panels shrink, then fold into the top bar. The shop keeps a three-column grid. (Approved from a coordinator mockup of the real game with the kit overlaid.)
  - **Hand size:** four cards in landscape, two in portrait (rule text by long-press Inspect).
  - **Empty flanks:** not wider League environment art. The space gets an ambient backdrop of its own, for example a slow star field for House that matches the night sky in its windows. It must stay behind the panels and lane, respect reduced motion, and vary by League.
  - **Portrait (phone) approved (2026-11-05):** from a coordinator mockup on the real game. Top to bottom: a two-row top bar (League and Division with Options; score, target and money, with money in its own slot); a strip with the score slip and rival chip side by side; a Charms row; the full-width lane, with the camera raised so the ball sits about two-thirds down; and a hand panel of two cards, with deck counts, Cycle and Inspect at the thumb side (mirrored for left-handed play).
  - **Owner decisions (2026-11-07):** UI-A1-C is approved. The portrait hand is a **fan of four** at the thumbs (replacing two cards). The swing demo with the 6 turns-a-second full charge is good. No backdrop was picked: UI-2 uses option 1, Constellations, as the coordinator's default; Slow stars (option 0) is a one-line switch in throw_lab.gd.
  - **Wave 10 work:** Codex's UI-A1-C revision (Medium) re-renders the landscape throw and shop to this layout, adds the narrow-landscape case and the backdrop treatment, and updates docs/art/ui/UI-A1.md, before UI-2 builds the screens. UI-1 (the card component) can start in parallel.

### Throw rework: the held ball (owner decision, 2026-11-03)
The E05 gesture counts path turning abstractly and locks the ball once circling starts, so it reads as drawing a circle rather than handling a ball. The owner approved a held-ball model, built before Neon:
- **Model:** while held, the ball follows the finger on a spring (slight lag, overshoot, lean). Spin charges from how sharply the ball's path turns, scaled by its speed (brisk circles about 1.5 loops to full, lazy circles slower). Reversing bleeds spin off first. The spin persists while held and fades slowly (starting half-life about 2.5 s), and the ball's visible rotation matches it. The release point sets the start position.
- **Approved design changes** (they amend design §5 and ADR 003; ADR 011 records them):
  - The release direction and power come from the held ball's velocity over the last 80–120 ms, so letting go mid-circle flings along that motion, within the existing ±60° forward limit; slow or backward releases still cancel safely.
  - Below the curve threshold (spin 0.25, where the sparkles start), a throw is exactly straight: no sparkle, no curve.
- **Feedback:** sparkles, a sound and a vibration at the threshold, stronger at full charge; a lab-only tuning panel for charge rate, fade, spring and thresholds, for tuning on a phone through the web build.
- **Unchanged:** the launch contract (start_x, angle, power, spin), physics, scoring, saves, the ring, assist controls and reduced motion. Most journeys throw through the assist controls; only the input unit tests, J01/J02, J08 and the slice journey drive gestures.
- **Claims:** E05-R1a (Claude, High): the input model, unit tests, ADR 011. E05-R1b (Claude, High): lab presentation, vibration and sound hooks, trial-log fields, the tuning panel, J01/J02/J08/slice journeys. AV-T01 (Codex, Medium, Wave 10): charge and sparkle effects in two levels with a reduced-motion version, and the charge and full-charge sounds. A hold-to-spin accessibility option is proposed for E25.
- **Owner gate:** play it on a phone through the hosted web build (E26-W01), then tune with the panel.

### Web target (owner decision, 2026-11-03)
The owner wants Roguewood playable as a web app. It stays a Godot project; a Web export is added rather than a rewrite.
- **E26-W01** (Claude, Wave 9, High): Web export preset and templates in CI; a single-threaded build (no SharedArrayBuffer, so no COOP/COEP headers needed) checked with Jolt; saves in IndexedDB with J07's atomic-write and backup guarantees re-checked; a tap-to-start audio gate; mouse and touch in desktop and phone browsers; load size and frame rate measured; a headless-Chromium browser journey (load, throw, score, save, reload) in CI; the build is kept as a CI artifact (`web-build`) that the owner can host themselves, and a GitHub Pages test deployment of main (owner, 2026-11-04; removable by deleting .github/workflows/web-preview.yml).
- Native physics digests may differ under WebAssembly; a web-specific baseline is allowed, gameplay results are not.
- Open owner decision: whether web replaces the phone builds as the primary platform or ships alongside them. Until then E26 keeps its phone children and the web build is added to it.

## Risks to watch
- **Throughput:** Waves 1–4 held 2 Claude claims each, and between 3 and 17 Codex batch claims. This plan raises Claude to 3 claims per wave; at 2 per wave Claude's lane alone would run to about Wave 40. If a phase runs long, re-plan the wave numbers at its end; batch limits are never raised to compensate.
- **Codex trails Claude:** the AV pipeline is one wave behind by design. If it falls two waves behind, Claude's next wave takes Phase 4 systems work instead of new items.
- **Physics-heavy items** (Ghost, Splitter, Spark, Fuse, mass modifications) sit in Spectral and Foundry and need their own High primitive sessions; they are the most likely to run over.
- **Balance** is provisional until E24. Each League integration sets provisional targets from the slice simulation, so E24 tunes a working game rather than rescuing a broken one.
