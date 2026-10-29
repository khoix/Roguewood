# Roguewood — agent checkpoint

Updated: 2026-10-29. E01–E16 DONE and merged to main (owner merge is approval; see AGENTS.md). E17–E21 IN_PROGRESS; E22–E29 NOT_STARTED. Waves 1–4 are merged (PRs #11, #13, #14, #15); Wave 5 is open. The plan to release is docs/ROADMAP.md. Provisional decisions: the E07 equipment model, E08 prices, targets (E24). Device gates (E05, E12, E13) and E26 need phone hardware.

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
- Integration: the owner merged PR #11 (Codex Wave 1, E16 core, E17-D01, the test fix) into main (`492f9f4`). Codex Wave 2 (`fcdb494`: E16-ART, E19-A08…A12) is reviewed and merged into `claude/roguewood-build`, along with main.
- Wave 2 MERGED to main by PR #13 (`1d44302`).
- Wave 3 MERGED to main by PR #14 (`3a7e938`; CI 40736417912 PASS on `afe5852`): Codex E17-D02-ART and E19-A13…A15; Claude E18-C02 and E17-D03.
- Wave 4 MERGED to main by PR #15 (CI 40760480791 PASS on `e72051b`): Claude E18-C03 and E17-D04; Codex E17-D03-ART, E19-A16 and E20-V08. 
- **Wave 5 closing** (see "Wave 5 closed"): Claude E18-C04 and E17-L01; Codex AV-C03 and E17-D04-ART. The owner merges `claude/roguewood-build` into main after the CI of the "Wave 5 closed" commit. Wave 6 claims are recorded; Wave 6 pushes wait for that merge.
- **Roadmap (2026-10-28):** docs/ROADMAP.md maps every remaining milestone to phases (one per League group) and waves, with ownership, the content split per League and the owner's decisions. Waves 5–8 complete the House League.
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
| E10 — Attempt saves and recovery | DONE | Claude | main (PR #9) | 8e4edd5; CI 40460928513 PASS; ADR 007; E10 handoff |
| E11 — Art bible and representative still scene | DONE | Codex | main (PR #4) | 2882483; E11 CI 40428621822 PASS; owner approval by merge (confirmed 2026-10-27) |
| E12 — Representative motion and visual review | DONE | Codex | main (PR #8) | Implementation 90f5690; handoff 046d109; CI 40444945503 + 40444945245 PASS; merged by PR #8 (main 9225f7c) |
| E13 — Vertical-slice integration | DONE (device play session blocked) | Claude | main (PR #9) | 98cc2aa (with 5aac9d2, aea54e0); CI 40524506207 PASS; ADR 008; E13 handoff |
| E14 — Seeded eight-Division progression | DONE | Codex | codex/roguewood-build | 71b2bd2; local unit/content/integration/physics, J01/J06/J07 and native J09 headless/rendered PASS; handoffs/E14.md |
| E15 — Career persistence and unlock graph | DONE | Claude | main (PR #10) | 2cdedb1 (+ 8c19905); local suites and J01–J10 headless/rendered PASS; CI 40577363221 and 40581437392 PASS; ADR 010; E15 handoff |
| E16 — Clubhouse and collection UI | DONE (core and E16-ART) | Claude core · Codex E16-ART | claude/roguewood-build · codex/roguewood-build | Core b01fb4d; CI 40616441249 PASS; J11; handoffs/E16.md (Art hand-off) |
| E17 — Catalogue and unlock authoring batches | IN_PROGRESS (D01–D05 and L01 DONE; D01-ART to D04-ART DONE) | Claude definitions · Codex visual briefs | claude/roguewood-build · codex/roguewood-build | Split per batch; see Ownership |
| E18 — Content mechanics batches | IN_PROGRESS (C01–C04 DONE) | Claude | claude/roguewood-build | C01: six D02 Charms; C02: transform primitive, Glass Pin and Glass Cutter; C03: five primitives, Crown Pin and the last five D02 Charms; handoffs/E18-C0x.md |
| E19 — Final item artwork batches | IN_PROGRESS (A01–A16 and AV-C03 DONE) | Codex | codex/roguewood-build | E13-S01, E17-D01 and E17-D02 identities; artwork set on the seven C01/C02 Charms and Glass Pin; C03 flags (A17) and D03 identities (A18) in Wave 5 |
| E20 — Ability effects and audio batches | IN_PROGRESS (V01–V08 and AV-C03 DONE) | Codex | codex/roguewood-build | E13-S01's 23 abilities; V08: the eight C01/C02 items; C03's six in Wave 5 (V09) |
| E21 — Rival presentation batches | IN_PROGRESS (R01, R02 DONE) | Codex | codex/roguewood-build | Later rivals after E17 defines them |
| E22 — League theme integration batches | NOT_STARTED | Claude configuration and integration · Codex theme art | claude/roguewood-build · codex/roguewood-build | One League per roadmap step (docs/ROADMAP.md); L01 House in Waves 6–8 |
| E23 — Starting kits, mastery, difficulty, and endless | NOT_STARTED | Claude · Codex E23-ART | claude/roguewood-build · codex/roguewood-build | Kits per League bundle; tiers, medals and endless in Phase 4 |
| E24 — Economy and procedural balance study | NOT_STARTED | Claude | claude/roguewood-build | See Ownership |
| E25 — Onboarding and accessibility completion | NOT_STARTED | Claude core · Codex E25-ART | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E26 — Platform packaging and performance | NOT_STARTED (BLOCKED: hardware) | Claude · Codex art-budget fixes | claude/roguewood-build | Phase 5; needs phones and toolchains (owner decision in docs/ROADMAP.md) |
| E27 — Content and asset completeness audit | NOT_STARTED | Claude content audit · Codex asset audit | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E28 — Cross-system release candidate | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |
| E29 — Delivery and final handoff | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |

## Ownership, lanes and hand-offs (owner directive, 2026-10-28)

### Waves and merges (owner directive, 2026-10-28)
- **A wave is a fixed set of claims** for both agents, listed under "Wave N claims". Nothing outside it is pushed as part of that wave.
- **One merge path:** `claude/roguewood-build`. Codex pushes `codex/roguewood-build` and reports. The coordinator reviews and integrates it into `claude/roguewood-build`. Codex does not open PRs to main.
- **A wave closes** with a commit titled "Wave N closed" on `claude/roguewood-build`. It records the closing state and the next wave's claims. The owner merges `claude/roguewood-build` into main once that commit's CI passes.
- **Between closure and the owner's merge,** the coordinator does not push next-wave work to `claude/roguewood-build`. That work stays committed locally until the merge, so the PR contains exactly one wave.
- **Codex starts the next wave** from the "Wave N closed" commit (merging it into its branch). It pushes to `codex/roguewood-build` as usual; that branch is never the merge path.

### Art rule
**Codex owns every remaining art component.** That means artwork, illustration, iconography, portraits, environment art, VFX, animation, audio, trophy and cosmetic art, visual briefs and visual review. Claude owns the rules, data, UI logic, persistence, tests and integration code for the milestones in its lane.
- Codex never changes scoring, economy or Career rules.
- Claude never produces final art.
- A rule hook Codex needs that does not exist is requested from Claude through this checkpoint.

### Lanes (revised 2026-10-28; the plan to release is docs/ROADMAP.md)
| Lane | Milestones | Why the same agent |
|---|---|---|
| **Claude: Leagues, content and rules** | E17 (League specs, rival roster, definitions) and E18 (mechanics), written and landed together per League bundle; E22 League configuration and integration; E23; E24 | One agent writes, implements, integrates and tunes each League's rules and items in its own rules code. |
| **Claude: menus, platforms and release** | E25 core; E26 platform packaging and device evidence; E27 content audit; E28; E29 | The coordinator owns cross-system integration; E26's blockers are export, save and suspend code Claude maintains. |
| **Codex: all art** | E19 + E20 as one AV session per 3 landed items (brief, identity art, effects, sound, native check, flags); E21 rivals with their rule badges; E22-Lxx-ART League themes; E23-ART; E25-ART; E27 asset audit; art-budget fixes from E26/E28 | Codex owns the card, motion, effect and audio systems; one session per item set removes repeated native checks. |

- **Changed from the first plan** (coordinator, 2026-10-28, at the owner's request to re-plan): E22's configuration and integration and all of E26 move from Codex to Claude, because Codex's art and effects already made its lane about twice Claude's. Codex keeps every art component, including each League's theme art.
- **Boss-rule art** is made in the rival's E21 session (its rule badge), not as a separate E19 batch.

### Split milestones (two parts, separate states; the family is DONE only when both are)
| Milestone | Claude part | Codex part (`<id>-ART`) |
|---|---|---|
| E16 | DONE | DONE |
| E17/E18 (per League bundle) | League spec, rival roster, definitions and mechanics | Briefs inside each AV session (E17-D04-ART is the last standalone brief batch) |
| E22 (per League `E22-Lxx`) | Configuration: 8 Divisions, rivals, lane pool, weights, kit, branch unlock, full-League journey | Theme: environment, signage, lane-condition visuals, music identity |
| E23 | Kits, difficulty tiers, medals, endless | Kit, medal and cosmetic art |
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
| Work (owner) | Needs before starting | Hands off when done |
|---|---|---|
| E17-Lxx League spec (Claude) | The previous League's spec | Rival identities READY for E21; theme brief READY for E22-Lxx-ART; the bundle's item list for E18 |
| E18 primitive session (Claude) | Its League spec | The items that use it, for the next item batch |
| E18 item batch (Claude) | Its primitives | AV batch READY for Codex (item IDs, asset IDs, journeys and captures) |
| AV batch (Codex) | Its items landed | Artwork and effects flags; items count as finished content |
| E21-Rxx (Codex) | The rival's rule landed and its identity in the League spec | Rival presentation for the League integration |
| E22-Lxx-ART (Codex) | Its League spec | Theme assets by ID for the League integration |
| E22-Lxx integration (Claude) | Its spec, rules and items; Codex's theme and rivals bind by ID and can follow | A playable League; the next League's branch unlock |
| E23 (Claude) / E23-ART (Codex) | Six Leagues | Kits, medals and endless for E24 and E25 |
| E24 (Claude) | E18–E23 | Tuned data; exploit fixtures for E28 |
| E25 core (Claude) / E25-ART (Codex) | E16, E22 | J14 for E26 |
| E26-Pxx (Claude) | E25; hardware and toolchains (BLOCKED today) | Installed-build evidence for E28 |
| E27 (both) | E17–E23 | Audit report for E28 |
| E28 → E29 (Claude) | E24–E27 | Release candidate; then delivery |

### Earlier parallel batches (historical)
The E13-S01 presentation batches (E19-A01…A07, E20-V01…V07, E21-R01/R02) were Codex's Wave 1 work and are DONE.

## Wave 1 result (integrated by the coordinator, 2026-10-28)
- **Codex delivered:**
  - E19-A01…A07: all 25 E13-S01 identities, artwork true.
  - E21-R01/R02: The Surveyor and The Custodian.
  - E20-V01…V07: 23 ability and rule effect and audio sets, effects_audio true. House Ball and House Kit have no ability.
  - J12 dense-effects journeys.
  - E17-D01-ART: briefs in docs/art/briefs/E17-D01.md, with 11 identity-confusion checks.
  - Details in handoffs/WAVE1-CODEX.md and E17-D01-ART.md. Codex CI 40633591372 PASS on `8a131a0`.
- **Coordinator review:**
  - Codex's diff against `5ecc1f0` touches no rules, simulation, persistence, Career, procedural or throw_lab code.
  - Catalogue changes are only the `assets` slots and the artwork and effects_audio flags of the 25 entries.
  - The two Clubhouse test assertions it changed now check real art where the placeholder used to be; accepted.
  - Merged into `claude/roguewood-build` as `be3b3e6`, and every CI workflow command was re-run locally (recorded under Validation).
- **Open PR #11** (`codex/roguewood-build` → main, mergeable) carries all of this plus Claude's E16 core, E17-D01 and the test fix. It is the owner's merge.

## Wave 2 result (integrated by the coordinator, 2026-10-28)
- **Codex delivered** (`fcdb494`, handoffs/WAVE2-CODEX.md):
  - E16-ART: ten trophy, ribbon, plaque and decoration PNGs, the Clubhouse look, explicit binder states and a static E12 foil for Mastered. **E16 is DONE.**
  - E19-A08…A12: identity art for the 11 D01 definitions. Their asset paths are in E17-D01.json; flags stay false until E18 lands each item and checks it in-game. D01 in-play assets are cosmetic scenes to attach to E18's real bodies; they never change collision, mass or score.
- **Coordinator review:**
  - Diff against `8322457`: E17-D01.json changes only the 52 asset paths.
  - The clubhouse_test edit moves the missing-art fixture off `trophy.house`, which is now real art; accepted.
  - No rules, catalogue, Career, bootstrap or clubhouse_model changes. qa.py and workflow edits are add-only.
- **Re-run on the merged tree** (identical to Codex's head): unit, content, integration, J01, J03, J05, J11, J11ART (headless and rendered), J19A08 and J19A12 — PASS.

## Wave 2 closed (coordinator, 2026-10-28)
- **Contents** (all on `claude/roguewood-build` at the "Wave 2 closed" commit; main has Wave 1 via PR #11):
  - Codex: E16-ART and E19-A08…A12 (`fcdb494`), integrated in `c2003f2` (recorded in `147f137`).
  - Claude: E17-D02 (`0c97ad0`), E18-C01 (`002590e`), and the CI upload-step fix for Wave 2's workflow edit (`973ba00`).
- **Validation:**
  - The full CI command list was re-run locally on the C01 tree: 98/98, and J03C01 injected failure exits 1.
  - CI 40699664160 PASS on `973ba00`. Every later Wave 2 commit is documentation.
- **Merge:** `claude/roguewood-build` into main after the CI of the "Wave 2 closed" commit. It supersedes Codex's PR #12, which lacks the CI fix and Claude's Wave 2 work.

## Wave 6 claims (coordinator: Claude, 2026-10-29)
Pushes for Wave 6 wait until the owner merges Wave 5. Codex merges `origin/claude/roguewood-build` (the "Wave 5 closed" commit) with a merge commit before starting (prompt: docs/prompts/codex-wave6.md). Phase 1, House League.
- **Codex:**
  - AV-C04 (3 sessions, Medium; High for Echo Charge): from the E17-D04 briefs, identity art, effects, sound, native checks and both flags for the eight landed modifications (Chalk Grip, Spin Wax, Coin Slot, Echo Charge, Brass Cap, Gilt Leaf, Lantern, Keystone). Badges and overlays never hide the host. J03C04 attaches all eight on known hosts.
  - E22-L01-ART (High): the House theme for eight Divisions from content/leagues/house.json: Division progression in the environment and signage, the Championship match, the two lane conditions (House Oil, Dry Backend) as lane visuals, and the League's music identity. Assets bind by ID; the integration (E22-L01, Wave 8) wires them.
- **Claude:**
  - E18-C05 (High): land House Rules, House Pins, House Oil and Dry Backend, and two-rule champions in rival_rules.gd (the House champion's Clean Sweep plus House Rules).
  - E18-C06 (High): tactical-card primitives (relocate a pin, swap with a reserve, waive a rule for one roll), landing Nudge, Reserve Call and Rule Waiver.
  - E18-C07 (High): the shop-upgrade system (Pro Shop licences that last the attempt) with its first six upgrades, written and landed together.

## Wave 5 closed (coordinator, 2026-10-29)
- **Contents** (all on `claude/roguewood-build` at the "Wave 5 closed" commit):
  - Claude: E18-C04 (`aa1be20`) and E17-L01 with E17-D05 (`2299a3a`).
  - Codex: AV-C03 (`53ae250`, `e6246bc`) and E17-D04-ART (`b15371d`; handoffs/WAVE5-CODEX.md, AV-C03-A.md, AV-C03-B.md, E17-D04-ART.md), merged by the coordinator without conflicts (`cf784af`).
- **Coordinator review:** Codex's diff against `2299a3a` changes exactly six artwork flags, six effects_audio flags and twelve activation and sound paths in content/catalogue.json. Its source changes are presentation only (glyphs and score rows read resolver events and facts). qa.py, run_tests.gd and the workflow are add-only; upload folders stay inside `path`. Batch files are unchanged.
- **Validation:** in progress (full local CI command list on the merged tree, then CI on this branch).
- **Merge:** `claude/roguewood-build` into main after the CI of the "Wave 5 closed" commit.

## Wave 5 claims (coordinator: Claude, 2026-10-28; revised the same day with docs/ROADMAP.md)
Wave 4 is merged (PR #15). Codex merges `origin/claude/roguewood-build` with a merge commit before starting (prompt: docs/prompts/codex-wave5.md). Wave 5 opens Phase 1 (House League complete).
- **Codex:**
  - AV-C03 (High, 2 sessions; replaces E19-A17 and E20-V09): native checks, `artwork` flags, activation, sound and `effects_audio` flags for Crown Pin, Split Specialist, Sweet Spot, Back Row, Underdog and Crown Jewel. Crown Pin's cue distinguishes +40 (fell last) from the explained 0, and Crown Jewel shares it; Split Specialist shows the first-roll leave, Underdog the score-versus-half-target check, Back Row the back row and Sweet Spot the counted grades.
  - E17-D04-ART (Medium): briefs in `docs/art/briefs/E17-D04.md` for the twelve modifications. They feed AV-C04 in Wave 6. Flag look-alikes: Echo Charge / Echo Ball, Lead Core / Hammer Ball, Gilt Leaf / Gold Pin, Lead Weight / Anchor Pin, Spearhead / Crown Pin.
  - Dropped: E19-A18. The nine D03 boss rules get their badge art in their rivals' E21 sessions. If Codex already made it, it is kept as rule-badge input.
- **Claude:**
  - E18-C04 (Medium): land the eight modifications that need no new primitive (Chalk Grip, Spin Wax, Coin Slot, Echo Charge, Brass Cap, Gilt Leaf, Lantern, Keystone), with shop, attachment and native evidence. Lead Weight, Lead Core, Bumper Guard and Spearhead wait for their primitives in the Neon, Royal and Foundry bundles.
  - E17-L01 (High): the House League spec (8 Divisions of opener, feature and boss; 4 rivals and a champion; lane pool; second kit; unlock assignments; provisional targets) and the roster of all 20 rivals (name, rule, League, signature), replacing the slice's two Divisions and the campaign's provisional encounters.

## Wave 4 closed (coordinator, 2026-10-28)
- **Contents** (all on `claude/roguewood-build` at the "Wave 4 closed" commit):
  - Claude: E18-C03 (`313b8a0`, `2bd7ae7`) and E17-D04 (`076a1b1`).
  - Codex: E17-D03-ART (`52c5455`), E19-A16 (`a6fc939`) and E20-V08 (`25f6995`; handoffs/WAVE4-CODEX.md, E17-D03-ART.md, E19-A16.md, E20-V08.md), merged by the coordinator without conflicts.
- **Coordinator review:** Codex's diff against `0993250` changes exactly one artwork flag (Glass Pin), eight effects_audio flags and their sixteen activation and sound paths in content/catalogue.json. Its source changes are presentation only (Glass dressing on the real pin body, a saved-break observer that never rolls or writes, glyph counts read from resolver events). qa.py, run_tests.gd and the workflow are add-only; upload folders stay inside `path`. Batch files and every authored flag are unchanged.
- **Validation:** the full CI command list (118 commands, every journey headless and rendered, including J03C03, J19A16, J12V08 and J12V08C) PASS locally on the merged tree; the J03C03 injected failure exits 1. CI 40747075594 PASS on `076a1b1` (Claude's Wave 4); CI runs on this commit.
- **Merge:** MERGED to main by PR #15 after CI 40760480791 PASS on `e72051b`.

## Wave 4 claims (coordinator: Claude, 2026-10-28)
Wave 3 is merged (PR #14). Codex merges `origin/claude/roguewood-build` (with a merge commit) before starting.
- **Codex** (prompt: docs/prompts/codex-wave4.md):
  - E17-D03-ART (Medium): briefs in `docs/art/briefs/E17-D03.md` for the nine boss rules in `content/catalogue/batches/E17-D03.json`, from `design.asset_ids`, `counterplay` and `presentation_needs`. A boss rule is shown on the rival's preview and the HUD boss chip, so the brief covers the 48px chip and the preview card. Flag look-alikes: Oil Slick / Narrow Lane, Mult Cap / Dull Pins, Frugal House / House Rules, and each against Dead Straight and Clean Sweep.
  - E19-A16 (Medium): Glass Pin. Attach `in_play.pin.glass` to the real pin body as a cosmetic scene (no collision, mass or score change), check it natively in the rack, shop, inventory and binder, including a cracked-to-Wood frame from J03C02, then set its `artwork` flag in content/catalogue.json.
  - E20-V08 (High): activation and sound for the eight landed E18 items: Pin Counter, Hot Streak, Last Stand, Tip Jar, Banana Ball, Plumb Line, Glass Cutter, and Glass Pin's crack (shown after the bank, in the order the explanation names breaks). Set `effects_audio` only after a native check; reduced motion follows E12.
- **Claude:**
  - E18-C03 (High): land the five remaining D02 Charms and Crown Pin, with the primitives `condition.first_roll_standing` (Split Specialist), `scaling.accurate_rolls` (Sweet Spot), `scaling.positions` (Back Row), `condition.match_behind` (Underdog) and `condition.last_fallen` (Crown Pin, Crown Jewel). Rules, validation, explanation text, tests and native evidence; their Wave 3 art paths come with them, flags false until Codex's native check.
  - Then E17-D04 (Medium): the next definitions (ball and pin modifications, which are 0 of 16 each), so Codex has briefs for Wave 5.

## Wave 3 closed (coordinator, 2026-10-28)
- **Contents** (all on `claude/roguewood-build` at the "Wave 3 closed" commit):
  - Claude: E18-C02 (`d3391f5`) and E17-D03 (`20703ee`).
  - Codex: E17-D02-ART (`7101689`) and E19-A13…A15 (`a78354c`; handoffs/WAVE3-CODEX.md, E17-D02-ART.md, E19-A13…A15.md), merged by the coordinator.
- **Coordinator review and integration:**
  - Codex's diff against `fede206` changes only 24 identity paths and six artwork flags in content/catalogue.json, 24 identity paths in E17-D02.json, and add-only qa.py and workflow entries (the upload folders are inside `path`; `if-no-files-found: warn` stays last). The one source change, EquipmentArtStrip's icon fallback for Charms without an in-play texture, is presentation only.
  - Conflict: Codex worked from the Wave 2 base, before E18-C02 landed Glass Cutter. The batch keeps Glass Cutter under `landed`; its four identity paths moved onto its catalogue entry.
  - Glass Cutter's native check: J19A14N (headless and rendered) now buys it from a real offer and shows it in the inventory and binder; captures inspected. Its `artwork` flag is set, so seven landed D02 Charms have final identity art.
- **Validation:** the full CI command list (110 commands: doctor, unit, content, integration, physics, smoke, export, experiment, slice, every journey headless and rendered, including J03C02 and the five new D02 art checks) PASS locally on the merged tree with Glass Cutter's flag set; the J03C02 injected failure exits 1. CI runs on this commit.
- **Merge:** MERGED to main by PR #14 (`3a7e938`) after CI 40736417912 PASS on `afe5852`.

## Wave 3 claims (coordinator: Claude, 2026-10-28)
- **Codex:**
  - E17-D02-ART (Medium): briefs in `docs/art/briefs/E17-D02.md` for all 12 D02 Charms. Asset IDs are under `definitions` and `landed` in `content/catalogue/batches/E17-D02.json`. Flag look-alikes: Banana Ball / Hook Artist, Plumb Line / House Favorite, Hot Streak / Turkey Club, Pin Counter / Flat Bonus.
  - Then E19-A13…A15 (four Charms each, Medium).
  - The six landed Charms are in content/catalogue.json. Set their `completeness.artwork` only after a native shop, inventory and binder check; J11ART then requires their icons. For the six still authored, put paths in the batch file only.
- **Claude:**
  - E18-C02 (High): primitive `pin.break_chance`, the after-banking Glass-to-Wood roll on the attempt's effects stream. Saved, deterministic and shown, with no reroll by reload. It lands Glass Pin and Glass Cutter, and ends with native evidence.
  - Then E17-D03 (Medium): the next 12 definitions, so Codex has briefs for Wave 4.

## Wave 2 work recorded under the earlier "Wave 3" heading (historical)
- **Codex: E17-D02-ART** (Medium). Briefs in `docs/art/briefs/E17-D02.md` for the 12 Charms in `content/catalogue/batches/E17-D02.json`, using `design.asset_ids`. Flag look-alikes: Banana Ball / Hook Artist, Plumb Line / House Favorite, Hot Streak / Turkey Club, Pin Counter / Flat Bonus. Then E19 art for these 12 (A13–A15, four Charms each) is READY; it may follow in the same session with paths in E17-D02.json only.
- **Claude: E18-C01** (Medium). Land the seven expressible D02 Charms (pin_counter, hot_streak, last_stand, tip_jar, banana_ball, plumb_line, glass_cutter) into content/catalogue.json with mechanics, tests and in-game evidence. Glass Cutter depends on Glass Pin (D01, which needs a new primitive), so it stays in its batch until Glass lands; C01 lands six.

## Wave 2 claims (coordinator: Claude, 2026-10-28)
**Codex** (on `codex/roguewood-build`, from its own head; merge `origin/claude/roguewood-build` first):
- **E16-ART** (Medium):
  - scope, IDs and drop path in handoffs/E16.md, "Art hand-off";
  - exclusive paths: `src/clubhouse/clubhouse.gd`, `src/clubhouse/clubhouse_art.gd`, `assets/clubhouse/`;
  - keep J11 node names; never change `clubhouse_model.gd` or Career code.
- **E19 art for E17-D01** (identity sets from docs/art/briefs/E17-D01.md):
  - A08: Gold Ball, Glass, Fuse, Crown (Medium);
  - A09: Echo Pin, Nudge, Reserve Call, Rule Waiver (Medium);
  - A10: Spark Ball (High);
  - A11: Ghost Ball (High);
  - A12: Splitter Ball (High).
- Restricted edit for D01 art: only `definitions[].item.assets` paths in `content/catalogue/batches/E17-D01.json`. No completeness flags there; the validator keeps artwork false until E18 moves an item into the catalogue. After that, art flags are set on the catalogue entry after native verification.
- Verify with the brief's actual-size, grayscale and silhouette checks and the E19 contact sheets. In-play and activation slots are verified in-game after E18. E20 effects for D01 wait for E18-Cxx.

**Claude** (on `claude/roguewood-build`): next E17-D02 or E18-C01, the owner's choice; see the checkpoint's Active line.

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

### E17-D01 claim (Claude, 2026-10-28)
- **Branch** `claude/roguewood-build`, base `c611dea`. Medium.
- **Scope:** 11 definitions from the design's starter tables (§7, §8, §10) not yet authored:
  - balls Spark, Ghost, Splitter, Gold;
  - pins Glass, Echo, Fuse, Crown;
  - tactical cards Nudge, Reserve Call, Rule Waiver.
  Each has exact triggers, tradeoffs, prices, pools, compatibility, unlocks and asset IDs.
- **Decision:** authored definitions live in a content manifest, `content/catalogue/batches/E17-Dxx.json`, not in `content/catalogue.json`. So nothing unimplemented reaches a shop, the binder or a save. E18 moves each item into the catalogue when its mechanics land.
- **Exclusive paths:** content/catalogue/batches/, src/content/, tests/authored_test.gd, docs/handoffs/E17-D01.md.
- **Shared edits:**
  - content_set.gd: a prospective graph including the batches;
  - run_tests.gd: content mode;
  - clubhouse_model.gd: the `shop_upgrade` category name.
- **After:** the batch's visual briefs become READY for Codex (`E17-D01-ART`), and its definitions READY for E18-C01.

- **E17-D01 delivered:** 11 definitions in `content/catalogue/batches/E17-D01.json`, validated against the catalogue and the prospective unlock graph by `qa.py content`. **E17-D01-ART is READY for Codex:** visual briefs into `docs/art/briefs/E17-D01.md` from each definition's presentation needs and asset IDs, flagging any pair that does not read as distinct. **E18-C01 is READY for Claude:** eleven new primitives, listed in the handoff.

### Wave 1 coordination log
- 2026-10-28, CI fix (coordinator): Wave 2's workflow edit put six artifact folders (e16-art, e19-a08…a12) after `if-no-files-found: warn`, so that input became invalid and the "Preserve journey diagnostics" upload step failed. Every test step had passed (runs 40692363979 and 40693964676). The folders are moved into the `path` list. Codex: keep shared workflow edits inside the existing lists.
- 2026-10-28, coordinator scope fix (E18-C01) in Codex's `tests/art_club_journey.gd`: the binder-icon check now covers items whose catalogue `artwork` flag is set, instead of every card. The six newly landed Charms have no art until E19-A13…A15. The intent is unchanged; once their art lands and the flags are set, the check covers them.
- 2026-10-28, Codex request (A01/A02, `tests/slice_test.gd`): the blanket "no art or effects yet" assertion is replaced. **Done by the coordinator** on `claude/roguewood-build`, in the commit adding this entry. Every E13-S01 item must be authored and implemented and not integrated. A set `artwork` flag needs existing icon, card, rarity_treatment and reduced_motion resources, plus in_play for balls and pins. A set `effects_audio` flag needs existing activation and sound resources. Counts and scoring assertions are unchanged. Verified: `qa.py unit` PASS here, and on Codex's `f26ab50` (A01 and A02 final flags) with this test; a broken Ruby card path is caught. Codex merges `origin/claude/roguewood-build` to pick it up.
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

Batch E17-D03 (authored): boss_rule.oil_slick, heavy_set, frugal_house, house_rules, charm_freeze, narrow_lane, one_and_done, mult_cap, dull_pins (boss rules 2 implemented + 9 authored of 20).

Batch E19-A16 / E20-V08 (Codex, Wave 4): Glass Pin artwork; activation and sound for Pin Counter, Hot Streak, Last Stand, Tip Jar, Banana Ball, Plumb Line, Glass Cutter and Glass Pin's crack (effects_audio true on all eight).

Batch E17-D04 (authored): ball_mod.chalk_grip, spin_wax, coin_slot, echo_charge, lead_core, bumper_guard; pin_mod.brass_cap, gilt_leaf, lantern, keystone, lead_weight, spearhead. Nine expressible; three need primitives (physics.mod_mass_scale, physics.gutter_rebound, condition.first_fallen). Authored counts: ball and pin modifications 6/16 each.

Batch E18-C03 (landed): pin.crown, charm.split_specialist, sweet_spot, back_row, underdog, crown_jewel (primitives leave_min, behind, last_fallen, per accurate, per fallen_at). E17-D02 is fully landed. Production counts: pins 8/32, Charms 24/100. Artwork false until Codex's native checks (Wave 5).

Batch E19-A13…A15 (Codex, Wave 3): identity art for all 12 D02 Charms. Artwork true on the seven landed (pin_counter, hot_streak, last_stand, tip_jar, banana_ball, plumb_line, glass_cutter); the five still authored have paths in E17-D02.json only.

Batch E18-C02 (landed): pin.glass (transform primitive) and charm.glass_cutter. Production counts: pins 7/32, Charms 19/100.

Batch E18-C01 (landed): charm.pin_counter, hot_streak, last_stand, tip_jar, banana_ball, plumb_line are in content/catalogue.json (mechanics and automated validation true; artwork pending). Production counts: Charms 18/100.

Batch E17-D02 (E17, authored; six now landed by E18-C01): charm.pin_counter, hot_streak, last_stand, tip_jar, banana_ball, plumb_line, glass_cutter, split_specialist, sweet_spot, back_row, underdog, crown_jewel. Seven are expressible with existing frame rules and are already scored in authored_test.

Batch E17-D01 (E17, authored, not implemented): ball.spark, ball.ghost, ball.splitter, ball.gold; pin.glass, pin.echo, pin.fuse, pin.crown; consumable.nudge, consumable.reserve_call, consumable.rule_waiver. Flags: authored and unlock_assigned true; everything else false. Not in the catalogue or any pool until E18. Authored (not implemented) counts: balls 4, pins 4, tactical 3.

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
- Wave 1 integration PASS (`be3b3e6`, tree identical to PR #11's head): every command in the CI workflow re-run locally, 83 of 83 (unit, content, integration, physics, smoke, export, J01–J12 and the J08Axx/J12Rxx/J12Vxx art and effect journeys, headless and rendered, diagnostics, experiment, slice), plus J11 injected failure exiting 1. Codex CI 40633591372 PASS.
- E18-C01 PASS: the full CI command list re-run locally, 98 of 98 (including J03C01 and every art/effects journey), J03C01 injected failure exiting 1; CI 40699664160 PASS on `973ba00` (after the upload-step fix).
- E17-D02 PASS: content and unit (seven Charms scored); CI 40641583767 PASS on `0c97ad0`.
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

### Codex Wave 1 presentation contract request (E19-A01)

The presentation loader is now using production assets for the four ball IDs.
Please add `item_id: option.item_id` to `_refresh_hand`'s card view and
`item_id: offer.item_id` to `_refresh_shop`'s offer view (empty string for empty
slots) in throw_lab.gd. No rules or behavior change is needed. Current cards have
only UID/title and shop offers have only formatted text/state. Card presentation
has a temporary exact unique-title lookup; shop art will not parse formatted text.
Codex has not edited the restricted throw flow. Resume A01 shop binding after this
additive contract lands; keep artwork completeness false until that evidence and
remaining actual-size refinements are complete. This is a technical handoff, not
an owner-review wait.
