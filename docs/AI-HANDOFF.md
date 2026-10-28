# Roguewood — agent checkpoint

Updated: 2026-10-27. Agent work: E01–E13 DONE (owner merge is approval; see AGENTS.md). E10 and E13 are complete on `claude/roguewood-build` (not yet merged); E12 merged to main by PR #8. E14 DONE (Codex, implementation 71b2bd2; merged to main by PR #9, `fd1d466`, which also carried E10 and E13). E15 DONE (Claude, `claude/roguewood-build`; not yet merged to main). Provisional decisions: E07 equipment model (waits for the blocked E13 device play session), E08 prices, E09/E13 targets and E13 item numbers (E24). Device gates: E05 real-phone trials, phone readability and the E13 play session (E26).

## Read first

1. ../AGENTS.md
2. EXECUTION-PLAN.md (assigned execution only after overview)
3. ../Roguewood-Game-Plan.md (relevant sections)
4. handoffs/<assigned-task-id>.md when it exists

Source baseline: main commit `22fa7bde901677411f8a2c84a2ef02a34e235093`; design blob `b08b1cd0e2444a7e4759159f74d1f1f7b3544cde`. This is the pre-planning baseline, not a claim about the checkpoint's containing commit. Determine that with `git log -1 -- docs/AI-HANDOFF.md` after syncing.

## Current state

- Integration: `main`. The repository owner merges task branches by pull request: PR #1 (`codex/roguewood-build`, E01–E03) and PR #2 (`claude/roguewood-build` at `7ddb8af`, E04) were merged by the owner on 2026-10-26, and the `main` head `d9fda660a35f5e298733d059c210120efa62e03e` has a tree identical to `7ddb8af`.
- Claude's work branch: `claude/roguewood-build`, restarted from `main` after each owner merge; for E10 from `1132fca` (PR #7). `codex/roguewood-build` and `codex/roguewood-e11-art` are historical.
- E01 DONE: implementation, independent review, clean-checkout export, and remote CI passed. No gameplay implemented.
- Source baseline: main 30d76547ec2f49fa3b1be609f146cdd7b913695d; claim commit f63ea6ca6f08357f6b2c32587811ad49ff5f17d9.
- E02 DONE: implementation cdb48595fe28d08e9c1bf20333b63061dcc49412; independent review and CI40245188289 PASS. See handoffs/E02.md and CONTRACTS.md.
- E03 DONE: implementation78b1740159ee7c458fa9c36629ed6360009b0142, independent review and CI40256553911 PASS, rendered artifacts inspected. See handoffs/E03.md.
- E04 DONE: implementation `44bbd7e7bad2d41ddb9e062b29e1733dae1a9bfe`, CI 40262418442 PASS. Accepted by the repository owner through the PR #2 merge, which had no review comments; no separate agent reviewer was run. See handoffs/E04.md and decisions/002-throw-lab-physics.md.
- E05 (accepted, below): implementation `0ad08c299f0f478eeed846bf9513853cff63006d` on `claude/roguewood-build`; local suites and CI 40324357857 PASS; the physics digest `75d1a3c0…` and J02 curve outcomes are identical locally and in CI. Real-phone trials are NOT RUN (no device or mobile build); the protocol is in playtests/E05-device-trials.md. See handoffs/E05.md and decisions/003-spin-curve-input.md.
- E06 (accepted, below): implementation `b325c5641e10a3cbb160d4199d4384fcfa647ef2` on `claude/roguewood-build` (stacked on E05); local suites and CI 40375789785 PASS. J03 strike 560, spare 240 and open 70 are identical locally and in CI. See handoffs/E06.md.
- E05 and E06 were accepted by the repository owner through the PR #3 merge (main `4af230b`); no review comments. E05's real-phone trials remain an open gate (NOT RUN).
- E11 (Codex): `codex/roguewood-e11-art` (head `2882483`) was merged by the owner through PR #4 (main `cbca3c0`). E11 DONE: the owner confirmed on 2026-10-27 that merging PR #4 is the visual approval its handoff was waiting for. Physical-phone readability remains a device gate for E12/E26, as for E05. It only touches docs/art, assets/art_direction and its own workflow.
- E07 DONE: accepted by the owner through the PR #5 merge (main `1d2ea35`), no review comments. Implementation `bec334158db1ec743b7cb3e476d9b47224a7d950` on `claude/roguewood-build`. The deck and direct models, the lab card row, scoring of played cards, the structural experiment and J04 pass locally; CI 40435623701 PASS (run on `e1c8f9b`, which adds only the checkpoint; artifact `journeys` 12704037055); J04 and experiment output identical to local. The equipment decision is **provisional** (decisions/004-deck-draw-cycle-experiment.md): the deck stays the default and direct selection stays a lab option until the E13 vertical-slice playtest. See handoffs/E07.md.
- E08 DONE: accepted by the owner through the PR #6 merge (main `121b74f`), no review comments. Implementation `7b57919bad1b789f8ef18db48289f40cceb52029` on `claude/roguewood-build`. The run wallet and ledger, inventory slots and limits, the seeded Pro Shop with explicit replacement or cancel, modifications, removal, and purchases scoring in play all pass locally (unit with mutation checks, J01–J05 headless and rendered); CI 40442532881 PASS (run on `38d9c75`, which adds only the checkpoint; artifact `journeys` 12706493183); J04 and J05 output identical to local. Prices and rates are provisional (decisions/005-shop-and-match-economy.md). See handoffs/E08.md.
- E09 DONE: accepted by the owner through the PR #7 merge (main `1132fca`), no review comments. Implementation `fcea7f3b36f40077628c5a33bab89c819baaa1b7` on `claude/roguewood-build` (E09 commit `c427fad` plus the J05 scroll fix). The opener, feature and boss with fixed targets, The Custodian's Clean Sweep, previews before every shop, the skippable introduction, non-blocking reactions, win/loss/retry and the in-memory first-clear record pass locally (unit with mutation checks, J01–J06 headless and rendered); CI 40451844709 PASS (run on `90b9270`, which adds only the checkpoint; artifact `journeys` 12711515136); J06 output identical to local. Targets are provisional (decisions/006-division-loop-and-rival.md). See handoffs/E09.md.
- E10 DONE (owner policy: completed implementation and verification; not yet merged to main): implementation `8e4edd5fa99651f5b5d91cde5fb5c8ab1ab0bb6d` on `claude/roguewood-build`. Checksummed atomic saves with backup and quarantine, versioned attempt snapshots at every committed step, committed-throw re-simulation, no double banking, purchases or rerolls by reload, a separate idempotent Career file, Continue and save notices, golden v1 saves, and J07 across ten real process restarts all pass locally; CI 40460928513 PASS on `8e4edd5` (artifact `journeys` 12715071786; J07's ten stages ran in both modes with values identical to local). See decisions/007-attempt-saves-and-recovery.md and handoffs/E10.md.
- E13 DONE (owner policy: completed implementation and verification; not yet merged to main): on `claude/roguewood-build` (implementation `98cc2aa`, building on `5aac9d2` and `aea54e0`; CI 40524506207 PASS, artifact `journeys` 12744012079; see handoffs/E13.md). Catalogue/frame contract v2, production batch E13-S01, the two-Division House League with The Surveyor and The Custodian, content sets, attempt saves v2, J06 across both Divisions, and the seeded strategy simulation. The real-device play session is BLOCKED (docs/playtests/E13-slice-playtest.md). See decisions/008-vertical-slice.md.
- E15 DONE (owner policy: completed implementation and verification; not yet merged to main): on `claude/roguewood-build` (implementation `2cdedb1` plus the result-line follow-up; base main `fd1d466`). Career schema 2 with a v1 migration and a golden v2 file; the unlock registry and validated graph (IDs, kinds, sources, loops, reachability, self-unlocks, starting counters); immediate idempotent banking of first clears, titles, mastery, records and discoveries; attempt pool snapshots; the practice policy; the menu summary and League access; J10 across three real processes. See decisions/010-career-and-unlock-graph.md and handoffs/E15.md.
- Integration: the owner merged `claude/roguewood-build` at `06abb88` (E15 and the ownership plan) into main by PR #10 (`a65ed24`).
- E16 core DONE: `b01fb4d` on `claude/roguewood-build`; full local matrix (J01–J11 headless and rendered) and CI 40616441249 PASS; see handoffs/E16.md. E16-ART is READY for Codex.
- Active (Wave 1): Codex on E19-A01 (IN_PROGRESS, checkpoint `96ba030`); E19-A02…A07, E20-V01…V07, E21-R01/R02 and E16-ART are queued for Codex. Next for Claude: E17-D01.
- See handoffs/E01.md for exact evidence, decisions and remaining gates.

## Decisions and invariants

Title Roguewood; no subtitle. Premium dynamic pixel artwork is mandatory. Behind-ball perspective; hold/spin/flick with curved roll. Named rivals set visible score/rule challenges, never simulated opponent turns. Career persists unlocks and records; Leagues contain eight Divisions. The full catalogue and six themes are release scope, not prototype scope.

Godot 4.5.2 stable / GDScript / Compatibility renderer pinned for bootstrap in decisions/001-foundation.md. E04 physics: Jolt at 120 Hz, a fresh World3D per roll, regulation lane and pins, a gutter-void rule and impulse-based attribution, per decisions/002-throw-lab-physics.md. Primary iOS 16+/iPhone 13 Pro class; secondary Android 10+ and Windows 11; Linux x86-64 development/CI. Device testing remains outstanding. Same-build physics repeatability is shown on x86-64 Linux (E04); device feel, hook, the final deck-loop decision (ADR 004 is provisional; E13 playtest decides), item definitions/values/unlocks and visual target remain later decisions. Resolve through assigned executions; do not repeatedly redesign settled decisions.

## Execution ledger

All NOT_STARTED tasks are dependency-ineligible until their prerequisites are accepted. Batch family status aggregates child statuses; only the coordinator updates this table.

| Family | State | Owner | Worker branch | Evidence / blocker |
|---|---|---|---|---|
| E01 — Architecture and project bootstrap | DONE | Codex | codex/roguewood-build | f50f916; CI 40230415594 PASS; E01 handoff |
| E02 — Headless rules and content contracts | DONE | Codex | codex/roguewood-build | cdb4859; CI40245188289 PASS; E02 handoff |
| E03 — Application shell and E2E harness | DONE | Codex | codex/roguewood-build | 78b1740; CI40256553911 PASS; E03 handoff |
| E04 — Straight throw and pin collision lab | DONE | Claude | claude/roguewood-build → main (PR #2) | 44bbd7e; CI 40262418442 PASS; owner merge |
| E05 — Spin, curve, and mobile gesture feel | DONE (device gate open) | Claude | main (PR #3) | 0ad08c2; CI 40324357857 PASS; owner merge; real-phone trials NOT RUN |
| E06 — Frame scoring and readable resolution | DONE | Claude | main (PR #3) | b325c56; CI 40375789785 PASS; owner merge |
| E07 — Deck draw and cycle experiment | DONE (decision provisional) | Claude | main (PR #5) | bec3341; owner merge; CI 40435623701 PASS (run on `e1c8f9b`, which adds only the checkpoint; artifact `journeys` 12704037055); J04 and experiment output identical to local; ADR 004 provisional; E07 handoff |
| E08 — Shop and match economy | DONE (prices provisional) | Claude | main (PR #6) | 7b57919; owner merge; CI 40442532881 PASS; ADR 005 provisional; E08 handoff |
| E09 — Single Division loop and rival | DONE (targets provisional) | Claude | main (PR #7) | fcea7f3; CI 40451844709 PASS; ADR 006 provisional; E09 handoff |
| E10 — Attempt saves and recovery | DONE | Claude | claude/roguewood-build (not yet merged) | 8e4edd5; CI 40460928513 PASS; ADR 007; E10 handoff |
| E11 — Art bible and representative still scene | DONE | Codex | main (PR #4) | 2882483; E11 CI 40428621822 PASS; owner approval by merge (confirmed 2026-10-27) |
| E12 — Representative motion and visual review | DONE | Codex | main (PR #8) | Implementation 90f5690; handoff 046d109; CI 40444945503 + 40444945245 PASS; merged by PR #8 (main 9225f7c) |
| E13 — Vertical-slice integration | DONE (device play session blocked) | Claude | claude/roguewood-build (not yet merged) | 98cc2aa (with 5aac9d2, aea54e0); CI 40524506207 PASS; ADR 008; E13 handoff |
| E14 — Seeded eight-Division progression | DONE | Codex | codex/roguewood-build | 71b2bd2; local unit/content/integration/physics, J01/J06/J07 and native J09 headless/rendered PASS; handoffs/E14.md |
| E15 — Career persistence and unlock graph | DONE | Claude | claude/roguewood-build (not yet merged) | 2cdedb1 (+ 8c19905); local suites and J01–J10 headless/rendered PASS; CI 40577363221 and 40581437392 PASS; ADR 010; E15 handoff |
| E16 — Clubhouse and collection UI | Core DONE · E16-ART READY | Claude core · Codex E16-ART | claude/roguewood-build · codex/roguewood-build | Core b01fb4d; CI 40616441249 PASS; J11; handoffs/E16.md (Art hand-off) |
| E17 — Catalogue and unlock authoring batches | NOT_STARTED (READY) | Claude definitions · Codex visual briefs | claude/roguewood-build · codex/roguewood-build | Split per batch; see Ownership |
| E18 — Content mechanics batches | NOT_STARTED | Claude | claude/roguewood-build | Per E17 batch |
| E19 — Final item artwork batches | CLAIMED for Codex (A01–A07) | Codex | codex/roguewood-build | Wave 1 claim; later batches wait for E17 briefs |
| E20 — Ability effects and audio batches | CLAIMED for Codex (V01–V07) | Codex | codex/roguewood-build | Wave 1 claim; each after its E19 art |
| E21 — Rival presentation batches | CLAIMED for Codex (R01, R02) | Codex | codex/roguewood-build | Wave 1 claim; later rivals after E17 |
| E22 — League theme integration batches | NOT_STARTED | Codex (whole: art and integration) | codex/roguewood-build | Per League; needs E16 core and the League's content |
| E23 — Starting kits, mastery, difficulty, and endless | NOT_STARTED | Claude | claude/roguewood-build | See Ownership |
| E24 — Economy and procedural balance study | NOT_STARTED | Claude | claude/roguewood-build | See Ownership |
| E25 — Onboarding and accessibility completion | NOT_STARTED | Claude core · Codex E25-ART | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E26 — Platform packaging and performance | NOT_STARTED (BLOCKED: hardware) | Codex | codex/roguewood-build | Claude assists on E10 save/suspend defects |
| E27 — Content and asset completeness audit | NOT_STARTED | Claude content audit · Codex asset audit | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E28 — Cross-system release candidate | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |
| E29 — Delivery and final handoff | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |

## Ownership, lanes and hand-offs (owner directive, 2026-10-28)

### Art rule
**Codex owns every remaining art component.** That means artwork, illustration, iconography, portraits, environment art, VFX, animation, audio, trophy and cosmetic art, visual briefs and visual review. Claude owns the rules, data, UI logic, persistence, tests and integration code for the milestones in its lane.
- Codex never changes scoring, economy or Career rules.
- Claude never produces final art.
- A rule hook Codex needs that does not exist is requested from Claude through this checkpoint.

### Lanes (grouped by the code each agent already owns, to avoid re-learning and hand-offs)
| Lane | Milestones in order | Why the same agent |
|---|---|---|
| **Claude: content and rules** | E17 definitions → E18 → E23 → E24 | Item definitions are implemented in Claude's frame and effect rules (E06, E13); unlocks go through E15's graph; kits, objectives and medals extend E13 and E15; balance tunes E08's economy with E13's simulation. One agent writes, implements and tunes each item. |
| **Claude: menus and player UI** | E16 core → E25 core | Both read E15 Career data and E05 input and assist; E25's tutorial and settings live in the menus E16 rebuilds. |
| **Codex: presentation** | E17 visual briefs → E19 → E20; E21; E22 (whole); E26 | Codex's E12 card and motion system carries E19/E20. E21 rivals and E22 themes sit on Codex's E14 generator and lane conditions. Phone performance risk is mostly art budgets, and Codex built the E01 export pipeline. |
| **Claude: release** | E27 content audit → E28 → E29 | The coordinator integrates and diagnoses across systems; most journeys (J02–J07, J10) are Claude's. |

- **E22 whole goes to Codex**, with theme art and integration in the same session per League. Codex edits unlock data in `content/career/unlocks.json`; `qa.py content` refuses unreachable, circular or self-unlocking entries.
- **E26 goes to Codex,** which brings Claude in for device suspend/resume or save-location defects (E10 code).

### Split milestones (two parts, separate states; the family is DONE only when both are)
| Milestone | Claude part | Codex part (`<id>-ART`) |
|---|---|---|
| E16 | League board, binder states, goals, records, unlock results, navigation, J11, placeholders | Trophy, medal and club-decoration art; binder card look (E12 card and foil); phone-readability pass |
| E17 (per batch `E17-Dxx`) | Definitions, triggers, prices, pools, compatibility, unlocks, asset IDs | The batch's visual briefs |
| E25 | Tutorial, alternate controls, safe areas, touch cancellation, settings persistence, J14 | Readable symbol set, reduced-effects visuals, tutorial visual review |
| E27 | Count, ID, unlock and integration audit | Weakest-asset review, placeholders, licences, provenance |

### Hand-off protocol (every split part and every cross-lane dependency)
1. **Before:** the starting agent's claim names its inputs (milestones or batches and their SHAs) and, for a split, the art part's scope:
   - asset IDs and slots (icon, card, in_play, activation, sound, reduced_motion, trophy…);
   - Codex's drop paths: `assets/` and `docs/art/ASSET-LEDGER.md`, Codex-exclusive;
   - the journeys and capture names showing each slot.
2. **During:** Claude wires every visual slot to a marked placeholder by asset ID, so art needs no code edit. Art completeness flags stay false until Codex sets them.
3. **After:** the finishing agent's handoff ends with a "Hand-off" checklist: what is now ready, for whom, the IDs, and the captures to compare. The coordinator then marks the dependent part READY here.
4. Codex finishing art re-runs the named journeys and records contact sheets, captures and provenance. Code the art reveals as necessary returns to Claude as a scoped follow-up.
5. Claude works on `claude/roguewood-build`, Codex on `codex/roguewood-build`. Neither edits the other's exclusive paths without a recorded claim. Each starts from current `main` after the owner's merges.

### Hand-offs before and after each remaining milestone
| Milestone (owner) | Needs before starting | Hands off when done |
|---|---|---|
| E16 core (Claude) | E15 (done) | E16-ART READY for Codex (trophy, decoration and binder IDs); League board for E22 |
| E16-ART (Codex) | E16 core hand-off | E16 DONE; Clubhouse visuals for E22/E25 |
| E17-Dxx (Claude) | E15 graph (done); previous batch | Its visual-brief part READY for Codex; definitions READY for E18-Cxx |
| E17-Dxx briefs (Codex) | That batch's definitions | E19-Axx READY for the batch; E21-Rxx READY for any rival it defines |
| E18-Cxx (Claude) | Its E17 batch | E20-Vxx READY once the matching E19 art exists; mechanics flags for E22/E23 |
| E19-Axx (Codex) | Its briefs (or, for E13-S01, briefs written in the batch) | E20-Vxx READY with E18; art flags for E27 |
| E20-Vxx (Codex) | Its E18 mechanics and E19 art | Effects and audio flags; dense-effect cases for E24/E26 |
| E21-Rxx (Codex) | The rival's rule implemented (E13 or E18) and defined (E17) | Rival identity for E22; J06/J12 checks |
| E22-Lxx (Codex, whole) | E16 core; the League's E17/E18 content, E19/E20 art and E21 rivals | A playable themed League; branch unlocks for E23; League for E24 |
| E23 (Claude) | E15, E17, E18, E22 | Kits, medals and endless for E24/E25 |
| E24 (Claude) | E18, E20, E21, E22, E23 | Tuned data; exploit fixtures for E28 |
| E25 core (Claude) | E13, E16, E22 | E25-ART READY (symbol and reduced-effects IDs); J14 for E26 |
| E25-ART (Codex) | E25 core hand-off | E25 DONE |
| E26-Pxx (Codex) | E20, E21, E22, E25; hardware and toolchains (BLOCKED today) | Installed-build evidence for E28 |
| E27 (Claude audit + Codex asset audit) | E17–E23 | Audit report for E28 |
| E28 → E29 (Claude) | E24–E27; then E28 | Release candidate; then delivery |

### What Codex can do in parallel now (no Claude dependency)
Production batch E13-S01 is fully authored and implemented, so its presentation work is READY today. Briefs are written inside each art batch, because that batch predates E17. These batches are allocated:
- **E19-A01** balls: house, hook, hammer, echo.
- **E19-A02** pins: wood, ruby, gold, anchor.
- **E19-A03** pins grower, rubber; Charms flat_bonus, finisher.
- **E19-A04** Charms: spare_change, lone_survivor, hook_artist, house_favorite.
- **E19-A05** Charms: gold_rush, turkey_club, patient_investor, last_chance.
- **E19-A06** Charms encore, standing_order; rule badges dead_straight, clean_sweep.
- **E19-A07** kit.house.
- **E20-V01…** the E13-S01 abilities (Echo retrigger, growth, strike streak and so on), each batch after its E19 art.
- **E21-R01** The Surveyor; **E21-R02** The Custodian. These are the slice rivals, whose rules are final. The campaign's provisional encounter IDs are not art targets.

Further parallel work as Claude's lane delivers:
- E16-ART after E16 core.
- Each E17 batch's briefs, then its E19-A and E21-R work.
- E22 Leagues once E16 core and the League's content exist.

Claude's next step: E16 core (it unblocks E16-ART and E22), then E17-D01 onward. Codex has the E13-S01 batches above in the meantime.

## Wave 1 claims (coordinator: Claude, 2026-10-28)

Base for both agents: `claude/roguewood-build` at the commit containing this claim (main `fd1d466` plus E15 and the ownership plan). Codex first merges `origin/claude/roguewood-build` into `codex/roguewood-build` with a merge commit; no rebase or force-push. Each agent then works only on its own branch and paths.

**Claude: E16 core (Medium), IN_PROGRESS on `claude/roguewood-build`.**
- Scope: League board, binder (Locked, Available, Discovered and Mastered), trophy shelf, three tracked goals, records, unlock results, direct resume and retry, J11.
- Every visual slot gets a marked placeholder wired by asset ID. The trophy, medal, decoration and binder asset IDs are recorded in its hand-off for E16-ART.
- Exclusive paths:
  - src/clubhouse/, src/bootstrap/bootstrap.gd;
  - src/persistence/career_profile.gd, src/career/, content/career/;
  - tests/clubhouse_*.gd, docs/handoffs/E16.md.
- Add-only edits: tools/qa.py (the J11 entry), the CI workflow (J11 lines), run_tests.gd.
- Claude does not edit any Codex path below during Wave 1. A presentation change E16 needs in a Codex file is requested here instead.

**Codex: Wave 1 presentation for production batch E13-S01, on `codex/roguewood-build`.**
- **E19-A01…A07 item art**, each set covering the card illustration, icon, in-play look, rarity treatment and reduced-motion variant. Each batch first writes its own visual briefs (E13-S01 predates E17):
  - A01 balls: house, hook, hammer, echo;
  - A02 pins: wood, ruby, gold, anchor;
  - A03 pins grower, rubber; Charms flat_bonus, finisher;
  - A04 Charms: spare_change, lone_survivor, hook_artist, house_favorite;
  - A05 Charms: gold_rush, turkey_club, patient_investor, last_chance;
  - A06 Charms encore, standing_order; rule badges dead_straight, clean_sweep;
  - A07 kit.house.
- **E20-V01…V07 ability effects and audio**, each after its items' E19 art:
  - V01 retrigger: Echo Ball, Encore;
  - V02 growth: Grower, Patient Investor;
  - V03 gold: Gold pin payout, Gold Rush;
  - V04 standing: Anchor, Standing Order, Lone Survivor;
  - V05 conditional multipliers: Finisher, Turkey Club, Last Chance;
  - V06 flat bonuses: Flat Bonus, Spare Change, House Favorite;
  - V07 roll feel: Hook Ball curve with Hook Artist, Hammer impact, Rubber bounce, and Wood and Ruby knockdowns (split it if it does not fit one session).
- **E21-R01 The Surveyor and E21-R02 The Custodian:**
  - portrait states, intro, lane treatment, rule badge, reactions, defeat and reward identity;
  - the Dead Straight and Clean Sweep rule effects.
  - The campaign's provisional encounter IDs are not art targets.
- Exclusive paths:
  - assets/ (new subfolders such as assets/items/, assets/rivals/, assets/effects/, assets/audio/), docs/art/;
  - src/presentation/: card_hand.gd, card_inspector.gd, shop_panel.gd, score_panel.gd, division_hud.gd, rival_reactions.gd, motion_director.gd, live_dressing.gd, lane_dressing.gd, and new presentation files (an asset loader);
  - its own tests and journeys (J08 extensions, J12), docs/handoffs/E19-A0x.md, E20-V0x.md, E21-R0x.md (one file per batch).
- Restricted edits:
  - content/catalogue.json: only the `assets` slots and the `completeness.artwork` and `completeness.effects_audio` flags of the 25 E13-S01 entries. Nothing else; Claude appends E17 items at the end of the file.
  - Rival art references go in an assets-side manifest keyed by rival ID, not in League or profile specs.
  - tools/qa.py, the CI workflow and run_tests.gd: add-only (J12 and its lines).
- Off-limits:
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, throw_lab.gd scoring and flow, and content specs other than the fields above.
  - No animation or effect may change a score, a result or saved state. J03 (560/240/70), J05 (21060), J06 and the physics digest `75d1a3c0…` must stay identical.
  - A needed rule or flow hook is requested here.
- **Before each batch:** list the IDs and slots, the source and provenance plan, and the journeys and captures that show them.
- **After each batch:**
  - contact sheet at actual size, in-play and reduced-motion captures, provenance rows in ASSET-LEDGER.md;
  - the affected journeys re-run headless and rendered;
  - completeness flags set only for slots delivered at final quality.
  - Push, then report the branch SHA and the batch IDs to the coordinator.

### Wave 1 coordination log
- 2026-10-28, Codex request (E19-A01): add `item_id` to the hand-card view and the shop-offer view in throw_lab.gd. **Done by the coordinator** on `claude/roguewood-build`, in the commit that adds this entry. `_refresh_hand` cards carry `item_id`; `_refresh_shop` offers carry `item_id` ("" for empty slots). Purely additive: J04, J05, J06 and unit re-run PASS. Codex merges `origin/claude/roguewood-build` to pick it up, then resumes A01 shop binding.
- 2026-10-28, **E16-ART READY for Codex.** The scope, asset IDs, drop path and captures are in handoffs/E16.md, "Art hand-off". On hand-off, `src/clubhouse/clubhouse.gd` and `src/clubhouse/clubhouse_art.gd` become Codex-exclusive presentation paths. `clubhouse_model.gd`, Career code and the registry stay Claude's. J11's node names must be kept.

## Active claims and ownership

No active claim. E15 (Claude) is complete on `claude/roguewood-build`; E14 (Codex) is complete and merged.

E15 → E16/E17 coordination:
- E16 reads `career.records`, `championships`, `items` (`CareerProfile.collection_state`: Locked/Available/Discovered/Mastered) and `CareerProfile.goals`; the menu's `CareerSummary` label is a placeholder for the Clubhouse.
- E17 assigns items to `gate.house_champion`, `gate.house_campaign_champion` and the three `gate.mastery_*` gates (or adds gates and objectives in content/career/unlocks.json); `qa.py content` refuses unreachable, circular or self-unlocking assignments and prints availability against the §16 targets.

E13 → E14 coordination:
- `src/rules/league_run.gd` (LeagueRun) chains DivisionRun-format specs and is ready for generated schedules; a Division with `championship: true` may bring back a boss already met (the validator mismatch Codex's probe reported is fixed). Distinct bosses may share a rule.
- `src/rules/content_set.gd` loads a catalogue, League and kit; attempt saves (schema 2) store the League as `{index, practice, done, current}` with `content_set`.
- Live wiring of generated schedules into the lab, shell and saves is complete in E14 (71b2bd2). See handoffs/E14.md and ADR 009 for provisional content/target limits.

Standing user preferences:
- Log agent work only; owner merge means approval. Do not mark completed milestones pending the owner. Integration facts are separate.
- Codex uses codex/roguewood-build across milestones, not new milestone branches.
- At the end of each milestone, state the proposed effort level for the next pending milestone.
- At the end of every session, share newly produced screenshots with the user (as files in chat). Never commit screenshots or other rendered captures to the repository; CI's uploaded artifact is their durable copy.

## Batch queue and content completeness

Batch E13-S01 (E13, delivered): 25 production definitions in content/catalogue.json — balls house, hook, hammer, echo; pins wood, ruby, gold, anchor, grower, rubber; Charms flat_bonus, finisher, spare_change, lone_survivor, hook_artist, house_favorite, gold_rush, turkey_club, patient_investor, last_chance, encore, standing_order; boss rules dead_straight, clean_sweep; kit house. Flags: authored, mechanics, automated_validation, unlock_assigned true; artwork, effects_audio, integrated false. Production counts against release targets: balls 4/24, pins 6/32, Charms 12/100, boss rules 2/20, kits 1/10; modifications, consumables, upgrades and lane conditions 0. No further batches allocated. Coordinator allocates E17-Dxx / E18-Cxx / E19-Axx / E20-Vxx / E21-Rxx / E22-Lxx / E26-Pxx with explicit scopes. Expected content totals: 24 balls, 32 pins, 16 ball modifications, 16 pin modifications, 100 Charms, 24 consumables, 16 shop upgrades, 12 lane conditions, 20 boss rules, 10 kits; six League specs separate.

Content registry: content/catalogue.json holds batch E13-S01 (catalogue v2); E02 defines validated schema/completeness fields, E17 populates further production items. Fixtures are excluded from release counts. All production counts currently unverified/not implemented. Track authored, mechanics, tests, artwork, VFX/audio, unlocks, and integration independently. Do not count examples in the design as finished content.

## Validation

- PASS: official editor/export-template SHA512 verification.
- PASS: `python3 tools/qa.py doctor`, `smoke`, and `export` under Godot 4.5.2.stable.official.6ce3de25a / Python 3.12.14 / Linux x86-64. Source and exported scene emit ROGUEWOOD_BOOT_OK.
- PASS: Python compile and git diff --check; independent read-only review.
- E01 implementation/tested code SHA: `f50f91627ae7fa5e088ebcadbca1c8a9f8a5eee6`. CI PASS: https://github.com/khoix/Roguewood/actions/runs/40230415594 (Ubuntu 24.04; doctor, source smoke, Linux export/startup).
- Clean detached checkout of identical implementation tree: export/startup PASS. At E01, unimplemented E2E failed explicitly; E03 now supplies J01.
- Saved through GitHub connector after local Git HTTPS push lacked credentials; local branch synchronized to verified remote with identical tree.
- E02 PASS: unit, content, contract integration, smoke, Python compile, diff checks; reviewer independently reran unit/integration and accepted final numeric-identity fix. Code cdb48595fe28d08e9c1bf20333b63061dcc49412; CI PASS https://github.com/khoix/Roguewood/actions/runs/40245188289 (includes Linux debug export/startup).
- E03 PASS: native headless and rendered J01, deterministic reset, intentional-failure screenshots/logs and timeout/error probes. CI40256553911 on78b1740; artifact12622383032 inspected. Full bowling/device journeys remain later work.
- E04 PASS (local, Godot 4.5.2.stable.official.6ce3de25a, Linux x86-64): unit (contracts, rules, lane geometry, knockdown tracker, gesture), content, integration, physics, smoke, Linux export plus exported boot, J01 headless and rendered, diagnostics, J02 headless and rendered, J02 injected failure exiting 1, py_compile and diff check. CI PASS https://github.com/khoix/Roguewood/actions/runs/40262418442 on `44bbd7e`; artifact `journeys` 12625271435. The physics outcome digest `d80a9fa440a2cc13b186509b7fc35b589cd49b7e42c0f0314908c62a6fc33cce` is identical locally, in separate processes and in CI. J02 covers real-touch straight throws, cancellation consuming nothing, no duplicate knockdowns, respotted survivors, a gutter void, and live play equal to a replay of the committed records.
- E05 PASS (local and CI): unit (spin phases, ring, assist equivalence, oil zones), content, integration, physics (23 fixtures, 92 simulations; hook grows with spin, mirrors exactly, shrinks with speed; E04 straight outcomes unchanged), smoke, Linux export, J01 headless and rendered, diagnostics, J02 headless and rendered (curves both ways from real circle gestures at ±0.618 spin and ±0.282 m hook, target move, short flick, mouse, keyboard assist, landscape, trial log), and J02 injected failure exiting 1. CI https://github.com/khoix/Roguewood/actions/runs/40324357857 on `0ad08c2`; artifact `journeys` 12650896331.
- E06 PASS (local and CI): unit (frame assembly, calculation log, 560/240/90, 3360/2800 logs, retrigger 8/9 bound, exact large score and overflow refusal), every earlier suite, and J03 headless and rendered (strike, spare and open through real input, checked against an independent resolution; log order; roll attribution; speed and skip; totals). CI https://github.com/khoix/Roguewood/actions/runs/40375789785 on `b325c56`; artifact `journeys` 12674518848.
- E07 PASS (local): unit (deck_test: draw, keep, cycle, reshuffle, exhaustion, recombine, House fallback, JSON continuation, direct uses, card and tactical scoring, payout attribution, experiment repeatability), every earlier suite with the physics digest unchanged, the `experiment` (1000 seeded runs; results in ADR 004), J01–J04 headless and rendered, diagnostics, and J04 injected failure exiting 1. CI 40435623701 PASS (run on `e1c8f9b`, which adds only the checkpoint; artifact `journeys` 12704037055); J04 and experiment output identical to local.
- E08 PASS (local): unit (economy_test: payout, interest, sale and reroll tables; no buy/sell profit; slots, placements, replacement and cancel; modifications; removal; shop eligibility, rarity renormalization, rerolls and the affordability guarantee across seeds; currency scopes; JSON round trips; a 60-run fuzz), mutation checks, every earlier suite with the physics digest unchanged and J03 at 560/240/70, J01–J05 headless and rendered (J05 match-2 score 21060 identical), diagnostics, and J05 injected failure exiting 1. CI 40442532881 PASS (run on `38d9c75`, which adds only the checkpoint; artifact `journeys` 12706493183); J04 and J05 output identical to local.
- E09 PASS (local): unit (division_test: spec validation and refusals, match flow with early wins, exact targets, losses, boss win, practice, Clean Sweep, reaction precedence and cooldown, JSON round trips), mutation checks, every earlier suite with the physics digest unchanged, J03 at 560/240/70 and J05 at 21060, J01–J06 headless and rendered (J06 lines identical in both modes), diagnostics, and J06 injected failure exiting 1. CI 40451844709 PASS (run on `90b9270`, which adds only the checkpoint; artifact `journeys` 12711515136); J06 output identical to local.
- E10 PASS (local): unit (save_test: atomic replace and backup, four corruption kinds with quarantine and fallback, version and migration rules, snapshot round trips for both equipment models with identical rerolls and draws, removed-item and phase refusals, golden v1 saves, Career idempotence and separation), mutation checks, every earlier suite with the physics digest unchanged, J03 at 560/240/70, J05 at 21060, J06 identical in both modes, J01–J07 headless and rendered (with per-journey save directories), diagnostics, and J07 injected failure exiting 1. CI 40460928513 PASS on `8e4edd5` (artifact `journeys` 12715071786; J07's ten stages ran in both modes with values identical to local).
- E16 core PASS (local and CI 40616441249 on `b01fb4d`): doctor, unit (clubhouse_test), content, integration, physics (digest unchanged), smoke, export, experiment, slice, J01–J11 headless and rendered, diagnostics, and J11 injected failure exiting 1.
- E15 PASS (local, `2cdedb1`): doctor, unit (career_test with mutation checks), content (both unlock graphs), integration, physics (digest unchanged), smoke, export, experiment, slice, J01–J10 headless and rendered, diagnostics, and J10 injected failure exiting 1; unit, J06, J09 and J10 re-run after the result-line follow-up. CI PASS: 40577363221 on `2cdedb1` and 40581437392 on `8c19905` (J01–J10 both modes; artifact `journeys`).
- E13 PASS (local and CI 40524506207 on `98cc2aa`): unit (slice_test: every slice item against hand-computed scores, catalogue and frame v2 refusals, League continuation and championship repeats, Dead Straight, physics profiles, content sets, slice saves, item texts; condition and retrigger mutations caught), content for both sets, every earlier suite with the physics digest unchanged, J03 at 560/240/70, J05 at 21060, J01–J08 headless and rendered (J06 stage 1 plays both slice Divisions, identical in both modes), diagnostics, J06 injected failure exiting 1, and the 400-run strategy simulation (ADR 008). The device play session is BLOCKED.
- Native iOS/Android/Windows, physical device feel (E05 trials NOT RUN), visual review and balance: NOT VALIDATED. E04/E05 throw thresholds and physics tuning are provisional (ADR 002/003).

## Blockers and limitations

No local blocker. The native Apple toolchain, signing, the Android SDK and mobile hardware are not available in this Linux execution, so E05's real-phone trials stay open until a device build exists. E04 provides a straight-throw lab with developmental geometry. Spin and hook, real-device feel, scoring presentation, production visuals and content remain unfinished, and pure frame rules and contracts exist. E04 independent review needs a reviewer: none was spawned, because this session ran a single agent. Current UI is functional developmental scaffolding only. E03 has one House League/House Kit fixture, not the full release selection system.

## Session handoff protocol

Workers copy AGENT-TASK-TEMPLATE.md to docs/handoffs/<task-id>.md on their own branch. Push code and handoff together; send coordinator branch/SHA and validation summary. Coordinator reviews and integrates, records the integrated code SHA and relevant test evidence, clears stale claims, updates the next action, and pushes checkpoint. Preserve unfinished tasks honestly; no running diary.

Do not insert the checkpoint's own future commit SHA. Record already-known implementation commits; the Git history identifies the checkpoint commit. On resume inspect remote changes before accepting an old ownership claim. Stop after the assigned execution is durably saved.

## Current Codex coordination

The owner's completion policy in AGENTS.md supersedes historical REVIEW wording above and in older documents: completed agent work is DONE, and the owner's merge is approval.
- E11 and E12 are DONE and merged; E12 reached main by PR #8 (`9225f7c`), consolidated on `codex/roguewood-build`.
- E10 is DONE on `claude/roguewood-build` and not yet merged. Claude's branch merged main `9225f7c` on 2026-10-27 to integrate E12 with E10 for E13.
- Codex uses `codex/roguewood-build` across milestones (now E14). Claude uses `claude/roguewood-build`.

## E14 integration claim
Codex owns E14 on codex/roguewood-build, integrating completed E13 b6c95ab. Shared LeagueRun, content selection, throw flow, persistence, HUD, lane condition application and J09/CI are now claimed for E14. Generator v2 at a104b36 is retained. E14 implementation and verification are complete at 71b2bd2. Native J09 passes in three processes headless and rendered, including menu selection, 24 matches, saves and endless/loss. No pending owner action. E15 next, High.
