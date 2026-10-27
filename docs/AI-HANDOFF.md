# Roguewood — agent checkpoint

Updated: 2026-10-27. Agent work: E01–E12 DONE (owner merge is approval; see AGENTS.md). E10 is complete on `claude/roguewood-build` (not yet merged); E12 merged to main by PR #8. E13 IN_PROGRESS (Claude, claimed); E14 is being assigned to Codex by the owner. Provisional decisions: E07 equipment model (E13 playtest), E08 prices and E09 targets (E24). Device gates: E05 real-phone trials and phone readability (E26).

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
- Active: E13 (Claude), claimed below; E14 is being assigned to Codex by the owner.
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
| E13 — Vertical-slice integration | IN_PROGRESS | Claude | claude/roguewood-build | Claimed 2026-10-27 at 0d32a32 (main 9225f7c merged with unmerged E10) |
| E14 — Seeded eight-Division progression | NOT_STARTED | unassigned | — | See dependency graph |
| E15 — Career persistence and unlock graph | NOT_STARTED | unassigned | — | See dependency graph |
| E16 — Clubhouse and collection UI | NOT_STARTED | unassigned | — | See dependency graph |
| E17 — Catalogue and unlock authoring batches | NOT_STARTED | unassigned | — | See dependency graph |
| E18 — Content mechanics batches | NOT_STARTED | unassigned | — | See dependency graph |
| E19 — Final item artwork batches | NOT_STARTED | unassigned | — | See dependency graph |
| E20 — Ability effects and audio batches | NOT_STARTED | unassigned | — | See dependency graph |
| E21 — Rival presentation batches | NOT_STARTED | unassigned | — | See dependency graph |
| E22 — League theme integration batches | NOT_STARTED | unassigned | — | See dependency graph |
| E23 — Starting kits, mastery, difficulty, and endless | NOT_STARTED | unassigned | — | See dependency graph |
| E24 — Economy and procedural balance study | NOT_STARTED | unassigned | — | See dependency graph |
| E25 — Onboarding and accessibility completion | NOT_STARTED | unassigned | — | See dependency graph |
| E26 — Platform packaging and performance | NOT_STARTED | unassigned | — | See dependency graph |
| E27 — Content and asset completeness audit | NOT_STARTED | unassigned | — | See dependency graph |
| E28 — Cross-system release candidate | NOT_STARTED | unassigned | — | See dependency graph |
| E29 — Delivery and final handoff | NOT_STARTED | unassigned | — | See dependency graph |

## Active claims and ownership

E13 claim (2026-10-27):
- Owner/coordinator: Claude. Owner merge is approval (AGENTS.md).
- Branch: `claude/roguewood-build` at `0d32a32`: main `9225f7c` (E12 merged) plus E10 (DONE, unmerged). Dependencies: E09, E10 and E12 (DONE).
- Scope: the design's stage-3 roguelike slice (§13):
  - Two Divisions (six matches) with two bosses: The Surveyor (Dead Straight: charged spin disabled) and The Custodian (Clean Sweep).
  - Four balls: House, Hook, Hammer, Echo.
  - Six pins: Wood, Ruby, Gold, Anchor, Grower, Rubber.
  - Twelve Charms: the ten in §9 plus two authored.
  - A slice starting kit, shop pools and save/resume, with representative E12 presentation.
- Items are authored as production catalogue batch E13-S01 (stable IDs) in content/catalogue.json. Completeness flags are honest: artwork and effects/audio stay false (E19/E20).
- Missing mechanics, added as a closed, versioned contract extension:
  - effect conditions (frame category, frame in match, standing count, curved shot, all-House);
  - per-count scaling;
  - a first-ball-pin retrigger;
  - pin growth persisted in the run;
  - per-item physics profiles for balls (spin response, mass) and pins (mass, restitution);
  - a run streak and match growth for Turkey Club and Patient Investor.
- Validation:
  - J01–J08 integrated pass. Mechanism journeys keep the lab fixtures through a `--content=lab` content set; J06 plays the slice's two Divisions.
  - A seeded slice simulation demonstrating three intentional build strategies.
  - Real-device play session: blocked (no device in this environment), recorded as a gate with outstanding defects.
- Exclusive paths: content/slice/, src/rules/league_run.gd, src/rules/conditions in frame_rules.gd (contract extension), src/simulation/item_physics.gd, tools/slice_strategies.gd, tests/slice_test.gd, docs/decisions/008-*.md, docs/handoffs/E13.md, and production entries of content/catalogue.json for batch E13-S01.
- Shared files (coordinator-owned this session): content/schemas/catalogue.schema.json and contracts.gd (versioned extension), frame_rules.gd, frame_builder.gd, lane_spec.gd, lane_world.gd, throw_lab.gd, bootstrap.gd, division_run.gd, run_inventory.gd, the journeys (content set), qa.py, the CI workflow, CONTRACTS, DEVELOPMENT, AGENTS, README and this checkpoint.
- Coordination with E14 (Codex, `codex/roguewood-build`): E14 owns seeded eight-Division generation in its own paths. It should produce Division specs in the DivisionRun format; LeagueRun will chain them. Edits to division_run.gd, throw_lab.gd or bootstrap.gd should be coordinated through this checkpoint.
- Out of scope: a declaration of full release or a validated economy; final item art and effects (E19/E20); further rivals' art (E21); device play (blocked).

Standing user preferences:
- Log agent work only; owner merge means approval. Do not mark completed milestones pending the owner. Integration facts are separate.
- Codex uses codex/roguewood-build across milestones, not new milestone branches.
- At the end of each milestone, state the proposed effort level for the next pending milestone.
- At the end of every session, share newly produced screenshots with the user (as files in chat). Never commit screenshots or other rendered captures to the repository; CI's uploaded artifact is their durable copy.

## Batch queue and content completeness

No batches allocated yet. Coordinator allocates E17-Dxx / E18-Cxx / E19-Axx / E20-Vxx / E21-Rxx / E22-Lxx / E26-Pxx with explicit scopes. Expected content totals: 24 balls, 32 pins, 16 ball modifications, 16 pin modifications, 100 Charms, 24 consumables, 16 shop upgrades, 12 lane conditions, 20 boss rules, 10 kits; six League specs separate.

Content registry: content/catalogue.json is empty by design; E02 defines validated schema/completeness fields, E17 populates production items. Fixtures are excluded from release counts. All production counts currently unverified/not implemented. Track authored, mechanics, tests, artwork, VFX/audio, unlocks, and integration independently. Do not count examples in the design as finished content.

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
