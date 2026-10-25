# Roguewood execution plan

Status: planning baseline, 2026-10-25. No game implementation has started.

## Sources and completion definition

- Design: [Roguewood-Game-Plan.md](../Roguewood-Game-Plan.md), repository commit `22fa7bde901677411f8a2c84a2ef02a34e235093`, blob `b08b1cd0e2444a7e4759159f74d1f1f7b3544cde`.
- Planning convention: user-supplied **Multi-Execution-Task-Planning-Convention.md**, Library ID `libfile_3102b53ac4b88191b04ee6e2cc04acb4`, version 2; read in full. This document applies its session boundaries, work settings, E2E, and durable handoff rules, with an explicit multi-agent branch extension below.
- Current checkpoint: [AI-HANDOFF.md](AI-HANDOFF.md). Per-agent handoff template: [AGENT-TASK-TEMPLATE.md](AGENT-TASK-TEMPLATE.md). Repo operating rules: [AGENTS.md](../AGENTS.md).

Done means a playable, packaged Roguewood with the approved premium visual standard, reliable curved throws, score-based named rivals, complete declared catalogue and six thematic Leagues, balanced procedural economy, Career unlocks, accessible UI, save recovery, and passing end-to-end evidence on the agreed target platforms. This planning change is not the completion of E01.

Scope guards: title **Roguewood**, no subtitle; elevated behind-ball lane view; hold/spin/flick; eight Divisions with three matches each; two frames per match; no AI rival turns; persistent Career choices rather than universal stat grinding. Counts: 24 balls, 32 pins, 16 ball modifications, 16 pin modifications, 100 Charms, 24 consumables, 16 shop upgrades, 12 lane conditions, 20 boss rules, 10 kits (270 definitions), plus six themed League specifications. All item families require their applicable final artwork, iconography, effects, audio, and unlock integration. Starting kits, card cycling, physics, price constants, and camera tuning contain proposals to validate; do not accidentally treat provisional values as user-approved final balance.

Excluded unless separately requested: multiplayer, accounts, online leaderboards, store publication, real-money systems, and a large narrative campaign. Engine choice is provisionally Godot 4, not an excuse to skip export feasibility. E01 must pin primary and secondary device/OS targets, toolchains, and renderer choice. Unavailable Apple signing/hardware or other external dependencies become explicit blockers, not fabricated validation.

## Milestones versus individual executions

There are **29 execution families**, not a promise of 29 sessions for this entire game. E17–E22 and E26 expand into bounded child executions. A child is one coherent session with a frozen list of IDs and acceptance criteria. Child work never disappears behind a completed parent label.

More than six families is warranted because physics, input, deterministic rules, deck economy, persistence, Career, multiple content disciplines, six themes, and device validation are independent high-risk systems. Content size alone does not justify Max effort; split it into batches.

| ID | Objective | Dependencies | Effort | Primary role |
|---|---|---|---|---|
| E01 | Architecture and project bootstrap | — | High | Foundation |
| E02 | Headless rules and content contracts | E01 | High | Rules |
| E03 | Application shell and E2E harness | E01,E02 | High | UI/QA |
| E04 | Straight throw and pin collision lab | E02,E03 | High | Physics |
| E05 | Spin, curve, and mobile gesture feel | E04 | Extra High | Physics |
| E06 | Frame scoring and readable resolution | E02,E04 | High | Rules/UI |
| E07 | Deck draw and cycle experiment | E03,E06 | High | Gameplay |
| E08 | Shop and match economy | E02,E07 | High | Economy |
| E09 | Single Division loop and rival | E06,E08 | High | Gameplay |
| E10 | Attempt saves and recovery | E07,E09 | Extra High | Persistence |
| E11 | Art bible and representative still scene | E01,E04 | High | Art |
| E12 | Representative motion and visual review | E05,E06,E11 | High | VFX/UI |
| E13 | Vertical-slice integration | E09,E10,E12 | High | Integration |
| E14 | Seeded eight-Division progression | E09,E10 | High | Procedural |
| E15 | Career persistence and unlock graph | E10,E14 | High | Career |
| E16 | Clubhouse and collection UI | E03,E12,E15 | Medium | UI |
| E17 | Catalogue and unlock authoring batches | E02,E07,E08,E14,E15 | Medium | Content |
| E18 | Content mechanics batches | E13,E17 | Medium | Content/Rules |
| E19 | Final item artwork batches | E12,E17 | Medium | Art |
| E20 | Ability effects and audio batches | E12,E18,E19 | High | VFX/Audio |
| E21 | Rival presentation batches | E12,E14,E17 | Medium | Characters |
| E22 | League theme integration batches | E14,E15,E16,E17 | High | League Integration |
| E23 | Starting kits, mastery, difficulty, and endless | E15,E17,E18,E22 | High | Progression |
| E24 | Economy and procedural balance study | E18,E20,E21,E22,E23 | Extra High | Balance/QA |
| E25 | Onboarding and accessibility completion | E13,E16,E22 | High | UX |
| E26 | Platform packaging and performance | E20,E21,E22,E25 | High | Platform |
| E27 | Content and asset completeness audit | E17,E18,E19,E20,E21,E22,E23 | Medium | QA |
| E28 | Cross-system release candidate | E24,E25,E26,E27 | Extra High | Integration/QA |
| E29 | Delivery and final handoff | E28 | Medium | Coordinator |

## Dependencies, concurrency, and task sizing

E01 is the first executable task. After contracts settle, independent rules/UI work can proceed. E11 can run alongside gameplay after E04; E14–E15 can proceed while visual refinements are reviewed. Do not merge unreviewed shared-schema changes under content workers. E17 is unlocked incrementally after its prerequisites; then each authored batch can feed E18 and E19 independently. E20 waits for the corresponding implemented and illustrated items, not an unrelated whole-catalogue completion. E21 needs final rule implementations from E18 for its selected encounters. E22 waits for the exact assigned art, mechanics, effects, rival, and environment dependencies. E24/E27 require completion of all applicable children; E28 requires the complete matrix, not one passing platform.

Batch IDs: `E17-D01` definitions, `E18-C01` mechanics, `E19-A01` artwork, `E20-V01` effects/audio, `E21-R01` rival, `E22-L01` League, `E26-P01` platform. Allocate consecutive stable IDs in the checkpoint before starting. Each child records explicit item/asset IDs and predecessor child IDs. Limits are maxima, not productivity promises. Split a batch further if novel mechanics or final-quality artwork cannot fit a session. Never increase a batch merely to claim fewer executions.

E17 at 12 definitions per session requires at least 23 definition batches for 270 definitions; six League specs can occupy an additional batch or spare capacity where coherent. E19's maximum four assets sets is not four isolated files: a set includes its required icon, illustration, and in-play appearance. Legendary/complex sets get a dedicated child. E21 must map all 20 rules to authored rival identities; do not omit champions. E22 has six theme sessions; commission theme environment assets as separate A children before integration if necessary. E26 has one or more children per platform. Exact total sessions will be determined from measured representative-batch cost, never by silently shrinking content.

## Multi-agent operating model

One coordinator owns central checkpoint updates, shared contract integration, and merge order. Role labels above are assignments of responsibility, not assumed model identities. Separate reviewers validate acceptance evidence; they do not claim tests they have not executed or inspected.

E01 creates the persistent integration branch `<agent_name>/roguewood-build`, filling the prefix only when the executing agent is known. Record the exact branch; later sessions reuse it. This intentionally extends the convention for multiple agents: workers use separate worktrees and branches derived from the recorded integration commit, such as `<agent_name>/roguewood-e05`; continuation resumes the exact recorded worker branch. Do not have concurrent agents share a branch or working tree.

Coordinator claim protocol: fetch current checkpoint; confirm dependencies; assign owner, branch, base SHA, exclusive paths, scope IDs, reviewer, and exact next action; commit/push the claim before dispatch. Shared files (schemas, global scene, project settings, dependency manifests, CI, checkpoint) have one owner at a time. Workers request shared changes through the coordinator or a separate dependency task. No two agents edit the central checkpoint concurrently; workers write only their own `docs/handoffs/<task-id>.md` and send a concise report.

Workers push completed or safely checkpointed work on their task branch. Coordinator reviews, integrates in dependency order without force-pushing over other work, reruns integration checks, and commits the checkpoint. A worker reporting success is not sufficient to mark integration DONE. When idle ownership appears stale, check remote branches and contact/reconcile the owner before reassignment; elapsed time alone does not revoke ownership.

## Status and evidence

Use `NOT_STARTED`, `READY`, `IN_PROGRESS`, `BLOCKED`, `REVIEW`, and `DONE`. READY requires completed predecessors or explicit approved contract stubs. REVIEW means worker code is pushed and validation evidence is available, but integration/review is outstanding. DONE requires acceptance criteria, applicable tests, final assets, verified remote implementation SHA, and integration evidence. A family is DONE only when all required children are DONE.

Report completed gates and child counts rather than invented percentage completion. Maintain a content manifest with separate columns for authored, mechanics implemented, automated validation, final artwork, effects/audio, unlock assigned, and integrated. Missing final art cannot be hidden by a mechanics-complete flag.

If a session ends early: commit a coherent safe checkpoint on its worker branch (or explicitly isolate non-working WIP there), push, record what fails and the exact resume step, leave task IN_PROGRESS or BLOCKED, and do not merge broken WIP. Never call unfinished acceptance criteria complete. Do not begin the next execution after finishing the assigned one.

## E2E and validation contract

E03 establishes the harness early. Use engine-native automation capable of driving actual UI/input and observing game outcomes; direct calls to scoring functions are unit tests, not E2E. If a web export is selected, browser automation may supplement it, not substitute for native touch/export checks. Fixtures may seed content and reset profiles, but must not bypass the action under test. Use stable state waits, not arbitrary sleeps.

E01/E03 expose exact documented commands via a small test runner. Intended command interface (not yet implemented): `python tools/qa.py unit`, `integration`, `content`, `e2e --journey J02`, `e2e --all`, and `smoke-export --platform <target>`. If a different command interface is selected, update all documentation and checkpoint in the same execution. Until then, these are proposed commands, not runnable validation claims.

| Journey | Observable proof | First coverage / extension |
|---|---|---|
| J01 | Boot, offline start, menu, League/kit entry | E03; E26 |
| J02 | Straight/curve/cancel throws through real input; accessible equivalent controls | E04–E05; E25 |
| J03 | Strike/spare/open, pin attribution, effects, ordered score log | E06; E18 |
| J04 | Draw/retain/cycle/reshuffle/tactical exhaustion/House Ball fallback | E07 |
| J05 | Purchase/sell/reroll/replace/cancel/remove/insufficient funds | E08 |
| J06 | Match/Division progress, rival preview and win/loss/retry | E09; E21 |
| J07 | Suspend/restart in throw, scoring, purchase, and unlock; save recovery | E10; E15; E26 |
| J08 | Card inspection/foil/reveal and motion accessibility without obstructing input | E12 |
| J09 | Eight-Division campaign, theme rules, seeded reproducibility, championship | E14; E22 |
| J10 | Unlock now, lose later, persist; no duplicates or inaccessible dependencies | E15 |
| J11 | Clubhouse/binder/trophy/results and League unlock branches | E16; E22 |
| J12 | Rival/ability reactions under dense effects, sound controls, skips | E20–E21 |
| J13 | Extreme scores, economy loops, expanded pools, kits/difficulty/endless | E23–E24 |
| J14 | Onboarding, responsive layouts, phone safe areas, settings persistence | E25–E26 |

CI: import/build, schema, unit/integration, deterministic E2E critical loop, and failure artifacts on each integrated change. Full headless E2E on release candidates. Real-device touch feel, installation, signing, audio/haptics, visual judgment, and mobile frame pacing remain separate required device/manual gates where CI cannot supply hardware. Record exact commit, command, environment, result, and artifacts for every claim. Do not use a screenshot as proof of animation or a simulation as proof of balance enjoyment.

## Standalone execution prompts

Each block is a copyable execution prompt. For batch families, substitute the child ID, frozen scope list, and its exact dependencies from the checkpoint; the whole family is never assigned as one session. Read only relevant design sections after reading the checkpoint; retain settled architecture unless a concrete defect requires correction.

### E01 — Architecture and project bootstrap

```text
Roguewood — EXECUTION E01 of 29 execution families: Architecture and project bootstrap.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch main; inspect status, diff, recent history, and AGENTS.md. Create and record <agent_name>/roguewood-build only after the executing agent is identified; inspect any existing branch before reuse.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: —. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Pin engine/export targets; record ADRs for input, rules, rendering, saves, and deck-loop experiment. Bootstrap project, reproducible tooling, and smoke CI.
Do NOT: No full gameplay or catalogue.
Expected ownership: engine bootstrap, build configuration, docs/decisions; concrete paths are assigned at claim time.
Validation: Project starts from a clean checkout; CI imports/builds; documented tool versions and commands work.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E02 — Headless rules and content contracts

```text
Roguewood — EXECUTION E02 of 29 execution families: Headless rules and content contracts.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E01. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Define stable item IDs, event scopes, launch/result records, content schema, and fixed scoring order. Add schema lint and fixture-based rules tests.
Do NOT: No production physics or UI.
Expected ownership: rules, content schemas, unit fixtures; concrete paths are assigned at claim time.
Validation: Reject duplicate IDs and malformed effects; fixture records round-trip; deterministic event ordering.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E03 — Application shell and E2E harness

```text
Roguewood — EXECUTION E03 of 29 execution families: Application shell and E2E harness.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E01,E02. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement boot, menu, test-session entry, deterministic reset, and an engine-appropriate input-driving E2E harness with logs and screenshots. Establish command wrappers.
Do NOT: No web-only test framework unless the chosen runtime actually supports it.
Expected ownership: UI shell, E2E harness, CI; concrete paths are assigned at claim time.
Validation: J01 boot/menu and deterministic test reset pass headlessly; failures retain useful artifacts.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E04 — Straight throw and pin collision lab

```text
Roguewood — EXECUTION E04 of 29 execution families: Straight throw and pin collision lab.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E02,E03. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement elevated behind-ball camera, lane, ten Wood pins, straight flick, collision attribution, fall/settle rules, and gutters.
Do NOT: No effects catalogue or random bounce modifiers.
Expected ownership: physics scene, input, collision fixtures; concrete paths are assigned at claim time.
Validation: J02 straight throw via real input path; no duplicate knockdowns; cancellation consumes nothing; compare repeated launch fixtures.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E05 — Spin, curve, and mobile gesture feel

```text
Roguewood — EXECUTION E05 of 29 execution families: Spin, curve, and mobile gesture feel.
Recommended effort: Extra High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E04. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Separate circular spin sampling from final forward flick; add speed caps, hook response, target ring, sensitivity, mouse support, and equivalent accessible controls.
Do NOT: No arbitrary hidden accuracy RNG or content expansion.
Expected ownership: input, launch mapping, device evidence; concrete paths are assigned at claim time.
Validation: J02 curves both ways, cancellation, short flick, resize; real-phone straight/curve trials logged; inaccessible hardware remains an open gate.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E06 — Frame scoring and readable resolution

```text
Roguewood — EXECUTION E06 of 29 execution families: Frame scoring and readable resolution.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E02,E04. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement strike/spare/open classification, two-roll accounting, single accuracy award, ordered pin/ball/Charm resolution, and calculation log.
Do NOT: No balance claims based solely on fixture passes.
Expected ownership: rules, score presentation, fixtures; concrete paths are assigned at claim time.
Validation: J03 strike/spare/open; 560/240/90 baseline fixtures and 3360/2800 ordering examples; retrigger bounds and overflow tests.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E07 — Deck draw and cycle experiment

```text
Roguewood — EXECUTION E07 of 29 execution families: Deck draw and cycle experiment.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E03,E06. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement six-card starter deck, four-card hand, retain-one/cycle-one, discard reshuffle, tactical exhaustion, and always-available House Ball. Compare against direct selection in a controlled experiment; record decision.
Do NOT: Do not silently finalize a proposal without evidence; no production catalogue.
Expected ownership: deck subsystem, experiment ADR, E2E; concrete paths are assigned at claim time.
Validation: J04 draw/play/cycle/empty-pile/House fallback pass; input paths work; write decision with observations and unresolved questions.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E08 — Shop and match economy

```text
Roguewood — EXECUTION E08 of 29 execution families: Shop and match economy.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E02,E07. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement match payout, interest, item purchase/sale, rerolls, deck limits, replacement/cancel, modifications, and schema-driven eligibility.
Do NOT: No seeded League generation yet; prices remain provisional.
Expected ownership: shop, economy, eligibility tests; concrete paths are assigned at claim time.
Validation: J05 purchase/full-slot/cancel/reroll/removal; no negative balance or buy/sell loop; currency scopes tested.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E09 — Single Division loop and rival

```text
Roguewood — EXECUTION E09 of 29 execution families: Single Division loop and rival.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E06,E08. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Connect opener, feature, boss, shops, target victory/failure, and retry. Add one rival with announced rules and a fixed posted target.
Do NOT: No AI bowling turns or eight-Division campaign.
Expected ownership: match state machine, rival integration; concrete paths are assigned at claim time.
Validation: J06 start to boss win/loss/retry; restrictions previewed before preparation; reactions do not block input.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E10 — Attempt saves and recovery

```text
Roguewood — EXECUTION E10 of 29 execution families: Attempt saves and recovery.
Recommended effort: Extra High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E07,E09. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement versioned attempt snapshots, RNG/deck state, atomic transactions, committed-throw recovery, and corruption fallback.
Do NOT: No cross-platform bit-identical physics claim.
Expected ownership: save subsystem, migration fixtures, recovery E2E; concrete paths are assigned at claim time.
Validation: J07 restart before/during/after throw, purchase, and score resolution; no free rerolls, duplicated currency, or lost committed actions.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E11 — Art bible and representative still scene

```text
Roguewood — EXECUTION E11 of 29 execution families: Art bible and representative still scene.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E01,E04. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Create palette/pixel-scale/type/material/motion specifications and one finished-quality lane composition with representative ball, mixed rack, HUD, and common-to-legendary cards.
Do NOT: No claim of animated approval from a still image.
Expected ownership: art bible, representative assets, review evidence; concrete paths are assigned at claim time.
Validation: Actual-size portrait/landscape images meet Section 17; record asset sources/licenses and placeholder status; identify visual defects.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E12 — Representative motion and visual review

```text
Roguewood — EXECUTION E12 of 29 execution families: Representative motion and visual review.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E05,E06,E11. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Finish one throw-to-impact-to-score sequence, card tilt/foil/reveal, and rival reaction; implement reduced motion and scene-level performance measurement.
Do NOT: Do not scale final art production before the visual checkpoint is resolved; independent mechanics can continue.
Expected ownership: representative motion, shaders, visual review; concrete paths are assigned at claim time.
Validation: J08 interactions remain usable; capture video and stills on target viewports; user reviews concrete visual target; record requested changes or acceptance.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E13 — Vertical-slice integration

```text
Roguewood — EXECUTION E13 of 29 execution families: Vertical-slice integration.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E09,E10,E12. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Assemble two Divisions with four balls, six pins, twelve Charms, two bosses, and representative final presentation; complete any missing slice items using bounded batches.
Do NOT: No declaration of full release or validated full economy.
Expected ownership: slice content, integration fixes, evidence; concrete paths are assigned at claim time.
Validation: J01–J08 integrated pass; three intentional build strategies demonstrated; real-device play session and outstanding defects recorded.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E14 — Seeded eight-Division progression

```text
Roguewood — EXECUTION E14 of 29 execution families: Seeded eight-Division progression.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E09,E10. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Build eight-Division generation, independent RNG streams, boss/lane compatibility, target curves, reveal timing, and optional endless continuation.
Do NOT: No impossible constraint combinations or dynamic hidden targets.
Expected ownership: generator, constraints, campaign tests; concrete paths are assigned at claim time.
Validation: J09 seeded schedule repeats; different seeds vary; incompatible rules rejected; complete campaign win/fail/endless paths.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E15 — Career persistence and unlock graph

```text
Roguewood — EXECUTION E15 of 29 execution families: Career persistence and unlock graph.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E10,E14. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Separate profile from attempt; implement boss/mastery/championship unlocks, graph validation, immediate banking, pool snapshots, and practice-mode policy.
Do NOT: No permanent universal score/cash boosts.
Expected ownership: Career, unlock graph, migration tests; concrete paths are assigned at claim time.
Validation: J10 unlock then lose/restart retains reward; no duplicate award; locked prerequisites reachable; existing attempt pool unchanged.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E16 — Clubhouse and collection UI

```text
Roguewood — EXECUTION E16 of 29 execution families: Clubhouse and collection UI.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E03,E12,E15. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement League board, binder states, trophies, three tracked goals, records, unlock results, and direct resume/retry navigation.
Do NOT: No new progression currency or mandatory grind.
Expected ownership: Clubhouse UI, binder, E2E; concrete paths are assigned at claim time.
Validation: J11 inspect Locked/Available/Discovered/Mastered and return to play; rewards visible after loss; text readable on phone.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E17 — Catalogue and unlock authoring batches

```text
Roguewood — EXECUTION E17 of 29 execution families: Catalogue and unlock authoring batches.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E02,E07,E08,E14,E15. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Author D batches of at most 12 definitions each, covering all 270 planned definitions plus six League specifications; include exact triggers, tradeoffs, pricing, pools, compatibility, unlocks, visual briefs, and asset IDs.
Do NOT: No invented completion for unimplemented items; no recolors counted as types.
Expected ownership: catalogue data, content manifest, unlock assignments; concrete paths are assigned at claim time.
Validation: Schema, unique-ID, prerequisite, compatibility, and count checks; independent reviewer checks each batch for distinct choices and unreachable content.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E18 — Content mechanics batches

```text
Roguewood — EXECUTION E18 of 29 execution families: Content mechanics batches.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E13,E17. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement C batches of at most six ordinary item definitions using frozen contracts; isolate any novel effect primitive into a separate High-effort C session before dependents.
Do NOT: No wholesale catalogue in one session or unresolved trigger ambiguity.
Expected ownership: item handlers, mechanics fixtures, content manifest; concrete paths are assigned at claim time.
Validation: Per-effect unit/integration tests, related J03–J06 paths, chain-limit and economy exploit tests; mark mechanics status separately from art.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E19 — Final item artwork batches

```text
Roguewood — EXECUTION E19 of 29 execution families: Final item artwork batches.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E12,E17. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Produce A batches of at most four normal card/icon/in-play identity sets, or one complex animated legendary. Follow approved scene standard and asset manifest.
Do NOT: No palette swaps replacing promised unique identity; no logic edits.
Expected ownership: item art, asset manifest, visual evidence; concrete paths are assigned at claim time.
Validation: Actual-size contact sheet, category/rarity recognition, in-play silhouettes, reduced-motion appearance, and provenance review.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E20 — Ability effects and audio batches

```text
Roguewood — EXECUTION E20 of 29 execution families: Ability effects and audio batches.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E12,E18,E19. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Produce V batches of at most three related abilities, or one unusually complex effect, using final art and correct event hooks. Add material sound, volume controls, and activation priorities.
Do NOT: No identical recolored burst for every ability.
Expected ownership: VFX/audio assets, presentation bindings, evidence; concrete paths are assigned at claim time.
Validation: J08/J12 layered activations readable; no animation changes score; effects/audio toggle correctly; frame-time evidence for dense combinations.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E21 — Rival presentation batches

```text
Roguewood — EXECUTION E21 of 29 execution families: Rival presentation batches.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E12,E14,E17. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Implement R batches of one rival encounter each: portrait states, intro, lane treatment, rule badge, reactions, defeat, and reward identity. Cover every scheduled boss identity.
Do NOT: No automatic expansion from 20 boss rules to an unbudgeted larger roster.
Expected ownership: rival assets/configuration, encounter E2E; concrete paths are assigned at claim time.
Validation: J06/J10/J12 target stable, reactions rate-limited, scenes skippable, first-clear award correct; final-quality visuals checked.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E22 — League theme integration batches

```text
Roguewood — EXECUTION E22 of 29 execution families: League theme integration batches.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E14,E15,E16,E17. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Integrate L01–L06, one League per session: theme rules, lane pools, assigned final assets/rivals, specialist weights, starting access/branch unlock, champion, and compatible starter counters.
Do NOT: Only begin a theme when its selected C/A/V/R dependencies are complete; no background-recolor substitute.
Expected ownership: League configs, environment assets, theme evidence; concrete paths are assigned at claim time.
Validation: J09–J11 one full seeded attempt per theme; fresh-profile accessibility, unlock branch, visual/audio identity, pool usefulness.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E23 — Starting kits, mastery, difficulty, and endless

```text
Roguewood — EXECUTION E23 of 29 execution families: Starting kits, mastery, difficulty, and endless.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E15,E17,E18,E22. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Integrate ten kits, completed objective assignments, optional difficulty medals, and bounded endless progression with large-score handling.
Do NOT: No new story campaign or multiplayer.
Expected ownership: kits, mastery, difficulty, endless tests; concrete paths are assigned at claim time.
Validation: J10/J11/J13 each kit starts legally; unlock graph and tier records; no essential counters behind their own gates; extreme-score tests.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E24 — Economy and procedural balance study

```text
Roguewood — EXECUTION E24 of 29 execution families: Economy and procedural balance study.
Recommended effort: Extra High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E18,E20,E21,E22,E23. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Run reproducible seeded simulations with novice/average/accurate shot profiles; analyze acquisition-time-adjusted performance, pool dilution, farming, interest, and build viability. Tune through versioned data changes.
Do NOT: Do not present simulation alone as proof of fun or hide outlier failures.
Expected ownership: balance configs, reports, regression seeds; concrete paths are assigned at claim time.
Validation: J13 fixed seed reports and budgets documented; fresh/partial/full collection comparison; exploit fixtures; human tests corroborate intentional strategies.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E25 — Onboarding and accessibility completion

```text
Roguewood — EXECUTION E25 of 29 execution families: Onboarding and accessibility completion.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E13,E16,E22. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Teach straight/curve, card usage, scoring, shop, and rival rules through playable steps. Complete alternate controls, reduced effects, readable symbols, safe areas, and touch cancellation.
Do NOT: No accessibility unlock grind or exact score expectation tied to gesture timing.
Expected ownership: tutorial, settings, responsive UI, E2E; concrete paths are assigned at claim time.
Validation: J14 first-launch to first match; keyboard/mouse/touch alternatives and portrait/landscape checks; no unskippable tutorial trap.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E26 — Platform packaging and performance

```text
Roguewood — EXECUTION E26 of 29 execution families: Platform packaging and performance.
Recommended effort: High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E20,E21,E22,E25. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Execute P batches one confirmed target platform at a time: exports, installation, offline startup, device input, suspend/resume, memory/frame pacing, quality settings, and packaging prerequisites.
Do NOT: No claimed iOS/Android validation without hardware/toolchain evidence; no store publication.
Expected ownership: export presets, platform fixes, device evidence; concrete paths are assigned at claim time.
Validation: J01/J02/J07/J14 on installed build; record hardware/OS/settings and artifact hash; documented actual export commands succeed.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E27 — Content and asset completeness audit

```text
Roguewood — EXECUTION E27 of 29 execution families: Content and asset completeness audit.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E17,E18,E19,E20,E21,E22,E23. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Reconcile every planned count against authored, implemented, tested, final-art, VFX, unlock, and integration states; verify licenses and missing references.
Do NOT: Do not treat catalogue presence as implementation completion.
Expected ownership: content manifest, audit report, targeted repairs; concrete paths are assigned at claim time.
Validation: Machine count/ID/asset audit; weakest-asset visual review; no placeholders or dangling unlocks in release pools.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E28 — Cross-system release candidate

```text
Roguewood — EXECUTION E28 of 29 execution families: Cross-system release candidate.
Recommended effort: Extra High; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E24,E25,E26,E27. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Integrate all eligible work; run full unit/integration/schema/E2E suites and supported device matrix. Repair concrete regressions; freeze candidate and document blockers.
Do NOT: No new features, speculative refactors, or reopening settled design without a failing case.
Expected ownership: release evidence, regression fixes, checkpoint; concrete paths are assigned at claim time.
Validation: J01–J14 full pass; save migration/recovery, all League branches, fresh and full profiles; CI and installed build evidence tied to exact commit.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

### E29 — Delivery and final handoff

```text
Roguewood — EXECUTION E29 of 29 execution families: Delivery and final handoff.
Recommended effort: Medium; use the nearest available setting for the chosen executor.
Begin: Fetch and resume the exact recorded task/integration branch in docs/AI-HANDOFF.md; inspect status, diff, and history. Reuse accepted predecessor work.
Read docs/AI-HANDOFF.md, this execution, and relevant Roguewood-Game-Plan.md sections.
Prerequisites: E28. Coordinator must claim the task and exclusive paths before work.
Objective/scope: Verify candidate artifacts and clean checkout reproducibility; publish release notes and known limitations in repo, commit/push final handoff, and prepare requested PR/artifact delivery.
Do NOT: No app-store submission, paid service setup, or deployment without separate authorization.
Expected ownership: release notes, final handoff, artifact references; concrete paths are assigned at claim time.
Validation: Run the complete relevant unit/integration/E2E suite on the final delivery commit and supported platform matrix; verify artifacts/checksums, remote commit, and clean status. Record external blockers honestly.
Add/update affected unit/integration tests and targeted E2E when behavior is testable. For pure asset/document work use asset/schema/visual checks, not artificial unit tests. Repair caused regressions; record external blockers.
Handoff: update docs/handoffs/<task-id>.md with scope, changes, decisions, commands/results, artifact paths, limitations, and exact next step. Coordinator updates the central checkpoint after review/integration.
Completion: inspect git status/diff; commit intended work; push assigned branch; verify remote SHA and clean working tree. Record evidence SHA without pretending a file can contain its own containing commit hash. If blocked, persist safe work and status honestly. Stop; do not start another execution.
```

## Effort rationale and release gates

Medium is the default for bounded work using settled contracts. High covers core contracts, UI state, procedural rules, and visuals whose design affects later work. Extra High is justified for gesture interpretation across devices (E05), transactional recovery (E10), interacting economic effects (E24), and final cross-system diagnosis (E28). Light is suitable only for later purely mechanical child tasks after scope is inspected. Max was considered and is not assigned by default; escalate a narrowly scoped exceptionally difficult physics/replay or cross-system defect only when additional reasoning is useful. Extra effort never excuses an oversized session.

Gate G1: intentional throws and correct visible scores (E04–E06). G2: deck-loop decision and stable shop/Division/save loop (E07–E10). G3: user-reviewed concrete final visual target (E11–E12). G4: integrated vertical slice (E13). G5: all catalogue/theme/Career gates with complete asset evidence (E14–E23/E27). G6: balance, accessibility, platform evidence (E24–E26). G7: release integration and complete final E2E (E28–E29).

The visual review is already required by the game plan. Continue independent work while awaiting that concrete review; do not interpret it as a blanket permission gate for ordinary tasks. No date/cost commitment is implied. Re-estimate after G3 and the first complete content/art batch.
