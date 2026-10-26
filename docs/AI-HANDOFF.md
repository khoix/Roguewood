# Roguewood — agent checkpoint

Updated: 2026-10-25. State: E01/E02 DONE; E03 IN_PROGRESS.

## Read first

1. ../AGENTS.md
2. EXECUTION-PLAN.md (assigned execution only after overview)
3. ../Roguewood-Game-Plan.md (relevant sections)
4. handoffs/<assigned-task-id>.md when it exists

Source baseline: main commit `22fa7bde901677411f8a2c84a2ef02a34e235093`; design blob `b08b1cd0e2444a7e4759159f74d1f1f7b3544cde`. This is the pre-planning baseline, not a claim about the checkpoint's containing commit. Determine that with `git log -1 -- docs/AI-HANDOFF.md` after syncing.

## Current state

- Integration branch: `codex/roguewood-build`; coordinator: Codex.
- E01 DONE: implementation, independent review, clean-checkout export, and remote CI passed. No gameplay implemented.
- Source baseline: main 30d76547ec2f49fa3b1be609f146cdd7b913695d; claim commit f63ea6ca6f08357f6b2c32587811ad49ff5f17d9.
- E02 DONE: implementation cdb48595fe28d08e9c1bf20333b63061dcc49412; independent review and CI40245188289 PASS. See handoffs/E02.md and CONTRACTS.md.
- E03 IN_PROGRESS: menu/test-session/reset and native button-input smoke implemented; see handoffs/E03.md. J01 harness, rendered capture support, failure/timeout logs and CI integration now implemented; rendered CI reached all checkpoints/screenshots but failed audio initialization; next fix is explicit Dummy audio for automated J01. See E03 continuation evidence.
- Next execution: continue E03; proposed effort High. Reuse current shell/contracts/qa runner.
- See handoffs/E01.md for exact evidence, decisions and remaining gates.

## Decisions and invariants

Title Roguewood; no subtitle. Premium dynamic pixel artwork is mandatory. Behind-ball perspective; hold/spin/flick with curved roll. Named rivals set visible score/rule challenges, never simulated opponent turns. Career persists unlocks and records; Leagues contain eight Divisions. The full catalogue and six themes are release scope, not prototype scope.

Godot 4.5.2 stable / GDScript / Compatibility renderer pinned for bootstrap in decisions/001-foundation.md. Primary iOS 16+/iPhone 13 Pro class; secondary Android 10+ and Windows 11; Linux x86-64 development/CI. Device testing remains outstanding. Physics repeatability, final deck-loop experiment, item definitions/values/unlocks and visual target remain later decisions. Resolve through assigned executions; do not repeatedly redesign settled decisions.

## Execution ledger

All NOT_STARTED tasks are dependency-ineligible until their prerequisites are accepted. Batch family status aggregates child statuses; only the coordinator updates this table.

| Family | State | Owner | Worker branch | Evidence / blocker |
|---|---|---|---|---|
| E01 — Architecture and project bootstrap | DONE | Codex | codex/roguewood-build | f50f916; CI 40230415594 PASS; E01 handoff |
| E02 — Headless rules and content contracts | DONE | Codex | codex/roguewood-build | cdb4859; CI40245188289 PASS; E02 handoff |
| E03 — Application shell and E2E harness | IN_PROGRESS | Codex | codex/roguewood-build | Shell increment; E2E completion pending |
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

E03 checkpointed claim (released on save; no worker edits): Codex owned src/bootstrap, tests/shell_smoke.gd, tools/qa.py, docs/AI-HANDOFF.md and docs/handoffs/E03.md on codex/roguewood-build; base a639d41540abd23c4e1d002f1af653c507b81930. Scope boot/menu/test-session/reset only this increment; no physics or scoring changes. Independent reviewer e02_review accepted this partial increment and reran shell smoke; full milestone acceptance remains required before DONE. Budget20%=4min, user overrides save reserve to2min; start23:39:37Z, cutoff23:41:37Z, hard stop23:43:37Z. No worker dispatched. E02 coordinator Codex and rules worker e02_rules completed their scopes; e02_review independently accepted the implementation. Rules branch `codex/roguewood-e02-rules` is published at `95d46c59ca4d5381d3309d309d1bf32d4e11a266` and integrated in the persistent build branch. E02 claim base `f3cf20513906e0bec534fde84df25538969b3ac7`; accepted code `cdb48595fe28d08e9c1bf20333b63061dcc49412`. Claims released after CI success.

Budgets: original75% ×20=15min; continuation user35% ×20=7min, start23:29:35Z/save cutoff23:32:35Z/hard stop23:36:35Z. Finalization stayed within continuation budget. E03 requires a new claim, not an implicit continuation.

Standing reporting preference: at the end of each milestone, state the proposed effort level for the next pending milestone. E03 proposed effort: High.

## Batch queue and content completeness

No batches allocated yet. Coordinator allocates E17-Dxx / E18-Cxx / E19-Axx / E20-Vxx / E21-Rxx / E22-Lxx / E26-Pxx with explicit scopes. Expected content totals: 24 balls, 32 pins, 16 ball modifications, 16 pin modifications, 100 Charms, 24 consumables, 16 shop upgrades, 12 lane conditions, 20 boss rules, 10 kits; six League specs separate.

Content registry: content/catalogue.json is empty by design; E02 defines validated schema/completeness fields, E17 populates production items. Fixtures are excluded from release counts. All production counts currently unverified/not implemented. Track authored, mechanics, tests, artwork, VFX/audio, unlocks, and integration independently. Do not count examples in the design as finished content.

## Validation

- PASS: official editor/export-template SHA512 verification.
- PASS: `python3 tools/qa.py doctor`, `smoke`, and `export` under Godot 4.5.2.stable.official.6ce3de25a / Python 3.12.14 / Linux x86-64. Source and exported scene emit ROGUEWOOD_BOOT_OK.
- PASS: Python compile and git diff --check; independent read-only review.
- E01 implementation/tested code SHA: `f50f91627ae7fa5e088ebcadbca1c8a9f8a5eee6`. CI PASS: https://github.com/khoix/Roguewood/actions/runs/40230415594 (Ubuntu 24.04; doctor, source smoke, Linux export/startup).
- Clean detached checkout of identical implementation tree: export/startup PASS. `qa.py e2e` correctly returns failure rather than claiming a nonexistent suite.
- Saved through GitHub connector after local Git HTTPS push lacked credentials; local branch synchronized to verified remote with identical tree.
- E02 PASS: unit, content, contract integration, smoke, Python compile, diff checks; reviewer independently reran unit/integration and accepted final numeric-identity fix. Code cdb48595fe28d08e9c1bf20333b63061dcc49412; CI PASS https://github.com/khoix/Roguewood/actions/runs/40245188289 (includes Linux debug export/startup).
- E03 partial native shell-input smoke and startup smoke PASS. Full J01/gameplay E2E: NOT RUN; E03 continues it. Contract tests and startup smoke are not gameplay E2E.
- Native iOS/Android/Windows, physical device feel, visual review and balance: NOT VALIDATED; assigned later.

## Blockers and limitations

No local bootstrap blocker. Native Apple toolchain/signing and mobile hardware not available in this Linux execution. Gameplay interaction, production visuals and content remain unfinished; pure frame rules/contracts now exist. Current title fixture is developer scaffolding only.

## Session handoff protocol

Workers copy AGENT-TASK-TEMPLATE.md to docs/handoffs/<task-id>.md on their own branch. Push code and handoff together; send coordinator branch/SHA and validation summary. Coordinator reviews and integrates, records the integrated code SHA and relevant test evidence, clears stale claims, updates the next action, and pushes checkpoint. Preserve unfinished tasks honestly; no running diary.

Do not insert the checkpoint's own future commit SHA. Record already-known implementation commits; the Git history identifies the checkpoint commit. On resume inspect remote changes before accepting an old ownership claim. Stop after the assigned execution is durably saved.

## E03 continuation claim

Codex owns src/bootstrap, tests/shell_smoke.gd, tools/qa.py, .github/workflows/bootstrap.yml and E03 documentation. Base6091a74db102fcf4b89982d6ff65106b8b656bcc, branch codex/roguewood-build; reviewer e02_review independently accepted code/headless J01 and timeout logs. Claim released at checkpoint; no worker edits. Scope J01 fixture entry/reset, bounded native input automation, logs/screenshots/CI; no physics. Budget40%=8min; start01:21:24Z, implementation cutoff01:25:24Z, hard stop01:29:24Z.

E03 latest evidence: implementation185cff41e4d2b647d50e794581419daee9d7ba19; CI40254112572 unit/content/integration/export/headless PASS, rendered J01 writes screenshots but strict runner fails ALSA ERR_CANT_OPEN. Artifact12621363909 inspected (menu/session readable). Exact continuation in handoffs/E03.md: test-only --audio-driver Dummy, rendered success/failure checks, green CI and final acceptance. E03 remains IN_PROGRESS; next proposed effort High.

## E03 final repair claim

Codex owns tools/qa.py, tools/verify_diagnostics.py, CI and E03 handoff/checkpoint docs; basee5f224166df8e3c05526fc7c46aa66dbc67d6ba6 on codex/roguewood-build. Reviewer e02_review read-only. Scope explicit test audio driver and automated rendered success/failure evidence, no gameplay changes. Budget40%=8min; start01:53:36Z, cutoff01:57:36Z, hard stop02:01:36Z.
