# Roguewood — agent checkpoint

Updated: 2026-10-25. State: E01 IN_PROGRESS.

## Read first

1. ../AGENTS.md
2. EXECUTION-PLAN.md (assigned execution only after overview)
3. ../Roguewood-Game-Plan.md (relevant sections)
4. handoffs/<assigned-task-id>.md when it exists

Source baseline: main commit `22fa7bde901677411f8a2c84a2ef02a34e235093`; design blob `b08b1cd0e2444a7e4759159f74d1f1f7b3544cde`. This is the pre-planning baseline, not a claim about the checkpoint's containing commit. Determine that with `git log -1 -- docs/AI-HANDOFF.md` after syncing.

## Current state

- Planning documents created; repository previously contained README.md and game design only.
- Integration branch: `codex/roguewood-build`.
- Coordinator/owner: Codex. E01 claimed; review by independent agent after changes. Exclusive paths: project.godot, src/bootstrap/, tools/, .github/workflows/, .gitignore, docs/decisions/, docs/DEVELOPMENT.md, docs/handoffs/E01.md, README.md, AGENTS.md, and this checkpoint. Base SHA: 30d76547ec2f49fa3b1be609f146cdd7b913695d. No item catalogue scope. Start: 2026-10-25T20:17:20Z. Save cutoff: 20:24:08Z; hard stop: 20:28:08Z.
- Last integrated implementation SHA: none. Last verified test SHA: none.
- Next executable task: **E01 — Architecture and project bootstrap**, High effort.
- Exact next action: fetch main; read AGENTS.md and E01; inspect working tree; claim E01; establish integration branch and pin engine/export/test contracts.
- Do not start all workers before E01/E02 contracts exist.

## Decisions and invariants

Title Roguewood; no subtitle. Premium dynamic pixel artwork is mandatory. Behind-ball perspective; hold/spin/flick with curved roll. Named rivals set visible score/rule challenges, never simulated opponent turns. Career persists unlocks and records; Leagues contain eight Divisions. The full catalogue and six themes are release scope, not prototype scope.

Godot 4 is provisional. Still unresolved: exact engine version and renderer, supported platform/device matrix, physics fidelity/replay strategy, final draw/cycle versus direct-equipment experiment, exact item definitions/values/unlocks, and concrete visual target review. Resolve through assigned executions; do not repeatedly redesign settled decisions.

## Execution ledger

All NOT_STARTED tasks are dependency-ineligible until their prerequisites are accepted. Batch family status aggregates child statuses; only the coordinator updates this table.

| Family | State | Owner | Worker branch | Evidence / blocker |
|---|---|---|---|---|
| E01 — Architecture and project bootstrap | IN_PROGRESS | Codex | codex/roguewood-build | Bootstrap and ADRs; no predecessors |
| E02 — Headless rules and content contracts | NOT_STARTED | unassigned | — | See dependency graph |
| E03 — Application shell and E2E harness | NOT_STARTED | unassigned | — | See dependency graph |
| E04 — Straight throw and pin collision lab | NOT_STARTED | unassigned | — | See dependency graph |
| E05 — Spin, curve, and mobile gesture feel | NOT_STARTED | unassigned | — | See dependency graph |
| E06 — Frame scoring and readable resolution | NOT_STARTED | unassigned | — | See dependency graph |
| E07 — Deck draw and cycle experiment | NOT_STARTED | unassigned | — | See dependency graph |
| E08 — Shop and match economy | NOT_STARTED | unassigned | — | See dependency graph |
| E09 — Single Division loop and rival | NOT_STARTED | unassigned | — | See dependency graph |
| E10 — Attempt saves and recovery | NOT_STARTED | unassigned | — | See dependency graph |
| E11 — Art bible and representative still scene | NOT_STARTED | unassigned | — | See dependency graph |
| E12 — Representative motion and visual review | NOT_STARTED | unassigned | — | See dependency graph |
| E13 — Vertical-slice integration | NOT_STARTED | unassigned | — | See dependency graph |
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

None. Before dispatch add: task/child ID; owner; reviewer; exact branch/worktree; base SHA; explicit item IDs; exclusive files/directories; shared-file requests; dependency child IDs; start timestamp; next checkpoint; state. Commit/push the claim first. Concurrent workers must not edit this central file.

## Batch queue and content completeness

No batches allocated yet. Coordinator allocates E17-Dxx / E18-Cxx / E19-Axx / E20-Vxx / E21-Rxx / E22-Lxx / E26-Pxx with explicit scopes. Expected content totals: 24 balls, 32 pins, 16 ball modifications, 16 pin modifications, 100 Charms, 24 consumables, 16 shop upgrades, 12 lane conditions, 20 boss rules, 10 kits; six League specs separate.

Content manifest: not created; E02 defines schema, E17 populates it. All production counts currently unverified/not implemented. Track authored, mechanics, tests, artwork, VFX/audio, unlocks, and integration independently. Do not count examples in the design as finished content.

## Validation

- Planning: source convention read in full; repository design and structure inspected; dependency IDs, DAG, prompt coverage, source scope, and internal links checked during planning publication.
- Unit/integration: NOT RUN; no implementation or harness exists.
- E2E: NOT RUN; E03 establishes J01–J14 harness. Intended qa.py commands in plan are proposed, not executable today.
- Mobile/native export: NOT RUN; target matrix and available hardware/toolchains unresolved.
- Visual-quality review: NOT PRESENTED; E11/E12 produce the concrete scene and motion sequence.
- Balance: NOT VALIDATED; E24 uses simulation plus human tests.

Replace this section with exact commands, outcomes, commit SHAs, environments, and artifact links as evidence becomes available. Never change NOT RUN to PASS on inference.

## Blockers and limitations

No planning blocker. Full named catalogue, artwork, effects/audio, mechanics, automated tests, exports, and all game systems remain to be produced. Hardware/signing may block specific platform gates later; record concrete availability when checked. Do not infer access to user devices from a profile.

## Session handoff protocol

Workers copy AGENT-TASK-TEMPLATE.md to docs/handoffs/<task-id>.md on their own branch. Push code and handoff together; send coordinator branch/SHA and validation summary. Coordinator reviews and integrates, records the integrated code SHA and relevant test evidence, clears stale claims, updates the next action, and pushes checkpoint. Preserve unfinished tasks honestly; no running diary.

Do not insert the checkpoint's own future commit SHA. Record already-known implementation commits; the Git history identifies the checkpoint commit. On resume inspect remote changes before accepting an old ownership claim. Stop after the assigned execution is durably saved.
