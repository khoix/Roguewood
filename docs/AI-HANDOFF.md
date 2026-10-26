# Roguewood — agent checkpoint

Updated: 2026-10-26. State: E01–E04 DONE (integrated on main); E05 REVIEW (implemented, CI green, real-phone gate open); E06 IN_PROGRESS (claimed).

## Read first

1. ../AGENTS.md
2. EXECUTION-PLAN.md (assigned execution only after overview)
3. ../Roguewood-Game-Plan.md (relevant sections)
4. handoffs/<assigned-task-id>.md when it exists

Source baseline: main commit `22fa7bde901677411f8a2c84a2ef02a34e235093`; design blob `b08b1cd0e2444a7e4759159f74d1f1f7b3544cde`. This is the pre-planning baseline, not a claim about the checkpoint's containing commit. Determine that with `git log -1 -- docs/AI-HANDOFF.md` after syncing.

## Current state

- Integration: `main`. The repository owner merges task branches by pull request: PR #1 (`codex/roguewood-build`, E01–E03) and PR #2 (`claude/roguewood-build` at `7ddb8af`, E04) were merged by the owner on 2026-10-26, and the `main` head `d9fda660a35f5e298733d059c210120efa62e03e` has a tree identical to `7ddb8af`.
- Claude's work branch: `claude/roguewood-build`, restarted from `main` `d9fda66` for E05 (after PR #2 merged). `codex/roguewood-build` is historical.
- E01 DONE: implementation, independent review, clean-checkout export, and remote CI passed. No gameplay implemented.
- Source baseline: main 30d76547ec2f49fa3b1be609f146cdd7b913695d; claim commit f63ea6ca6f08357f6b2c32587811ad49ff5f17d9.
- E02 DONE: implementation cdb48595fe28d08e9c1bf20333b63061dcc49412; independent review and CI40245188289 PASS. See handoffs/E02.md and CONTRACTS.md.
- E03 DONE: implementation78b1740159ee7c458fa9c36629ed6360009b0142, independent review and CI40256553911 PASS, rendered artifacts inspected. See handoffs/E03.md.
- E04 DONE: implementation `44bbd7e7bad2d41ddb9e062b29e1733dae1a9bfe`, CI 40262418442 PASS. Accepted by the repository owner through the PR #2 merge, which had no review comments; no separate agent reviewer was run. See handoffs/E04.md and decisions/002-throw-lab-physics.md.
- E05 REVIEW: implementation `0ad08c299f0f478eeed846bf9513853cff63006d` on `claude/roguewood-build`; local suites and CI 40324357857 PASS; the physics digest `75d1a3c0…` and J02 curve outcomes are identical locally and in CI. Real-phone trials are NOT RUN (no device or mobile build); the protocol is in playtests/E05-device-trials.md. See handoffs/E05.md and decisions/003-spin-curve-input.md.
- Next action: the owner reviews and merges E05. E06 is claimed below at the user's direction. E11 (High) is READY.
- See handoffs/E01.md for exact evidence, decisions and remaining gates.

## Decisions and invariants

Title Roguewood; no subtitle. Premium dynamic pixel artwork is mandatory. Behind-ball perspective; hold/spin/flick with curved roll. Named rivals set visible score/rule challenges, never simulated opponent turns. Career persists unlocks and records; Leagues contain eight Divisions. The full catalogue and six themes are release scope, not prototype scope.

Godot 4.5.2 stable / GDScript / Compatibility renderer pinned for bootstrap in decisions/001-foundation.md. E04 physics: Jolt at 120 Hz, a fresh World3D per roll, regulation lane and pins, a gutter-void rule and impulse-based attribution, per decisions/002-throw-lab-physics.md. Primary iOS 16+/iPhone 13 Pro class; secondary Android 10+ and Windows 11; Linux x86-64 development/CI. Device testing remains outstanding. Same-build physics repeatability is shown on x86-64 Linux (E04); device feel, hook, the final deck-loop experiment, item definitions/values/unlocks and visual target remain later decisions. Resolve through assigned executions; do not repeatedly redesign settled decisions.

## Execution ledger

All NOT_STARTED tasks are dependency-ineligible until their prerequisites are accepted. Batch family status aggregates child statuses; only the coordinator updates this table.

| Family | State | Owner | Worker branch | Evidence / blocker |
|---|---|---|---|---|
| E01 — Architecture and project bootstrap | DONE | Codex | codex/roguewood-build | f50f916; CI 40230415594 PASS; E01 handoff |
| E02 — Headless rules and content contracts | DONE | Codex | codex/roguewood-build | cdb4859; CI40245188289 PASS; E02 handoff |
| E03 — Application shell and E2E harness | DONE | Codex | codex/roguewood-build | 78b1740; CI40256553911 PASS; E03 handoff |
| E04 — Straight throw and pin collision lab | DONE | Claude | claude/roguewood-build → main (PR #2) | 44bbd7e; CI 40262418442 PASS; owner merge |
| E05 — Spin, curve, and mobile gesture feel | REVIEW | Claude | claude/roguewood-build | 0ad08c2; CI 40324357857 PASS; real-phone trials open gate |
| E06 — Frame scoring and readable resolution | IN_PROGRESS | Claude | claude/roguewood-build | Claimed 2026-10-26 from 4b7ce12 (stacked on unmerged E05) |
| E07 — Deck draw and cycle experiment | NOT_STARTED | unassigned | — | See dependency graph |
| E08 — Shop and match economy | NOT_STARTED | unassigned | — | See dependency graph |
| E09 — Single Division loop and rival | NOT_STARTED | unassigned | — | See dependency graph |
| E10 — Attempt saves and recovery | NOT_STARTED | unassigned | — | See dependency graph |
| E11 — Art bible and representative still scene | READY | unassigned | — | E01/E04 accepted; proposed effort High |
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

E06 claim (2026-10-26):
- Owner/coordinator: Claude (single-agent session). Reviewer: the repository owner by PR, unless an agent reviewer is requested.
- Branch: `claude/roguewood-build`; base SHA `4b7ce12a4d5947ff67dae027164a37294b780acc`. Dependencies: E02 and E04 (DONE). This is stacked on unmerged E05 because the same branch carries it; E06 does not depend on E05's behaviour.
- Scope:
  - Assemble completed frames (strike on roll 1, otherwise two rolls) from live roll reports, hydrating item effects from a lab catalogue fixture (Wood pin, House ball).
  - Resolve frames with the E02 `FrameRules`; one accuracy award per frame.
  - Readable resolution: Value × Mult counters, sequential highlights on a flat ten-slot rack diagram with per-roll attribution, distinct add and multiply symbols, a persistent ordered calculation log, 1×/2×/4× speed and skip. Presentation never changes the score.
  - Frame and session totals; J03 strike/spare/open journey; retrigger-bound and overflow tests.
- Exclusive paths: src/rules/ (new files), src/presentation/, tests/{rules,scoring}_test.gd, tests/scoring_journey.gd, content/fixtures/lab_catalogue.json, docs/handoffs/E06.md.
- Shared files (coordinator-owned this session): src/bootstrap/*, tests/run_tests.gd, tools/qa.py, the CI workflow, docs/CONTRACTS.md, docs/DEVELOPMENT.md, AGENTS.md, README.md and this checkpoint.
- Out of scope: production catalogue items or Charms (E17/E18), match targets and payout (E08/E09), final VFX and audio (E12/E20), balance claims.


E05 claim (2026-10-26T12:20Z):
- Owner/coordinator: Claude (single-agent session). Reviewer: the repository owner by PR, unless an agent reviewer is requested.
- Branch: `claude/roguewood-build`; base SHA `d9fda660a35f5e298733d059c210120efa62e03e` (main). Dependency: E04 (DONE).
- Scope:
  - Circular spin charge separated from the final forward flick, with a capped readable spin meter and a documented spin sign and curve threshold.
  - Physical hook response: side rotation and a lane oil profile, so faster throws hook less.
  - Speed caps.
  - A contracting target ring that can be moved before holding and freezes at release.
  - A short directional guide.
  - Sensitivity, handedness, larger touch targets and reduced motion settings.
  - Mouse input.
  - Accessible aim/power/spin controls that emit identical launch records.
  - Resize handling.
  - A device-trial protocol and an in-game trial log.
  - J02 extended with curves both ways, a short flick, target movement, mouse input, assist controls and resize.
- Exclusive paths: src/input/, src/simulation/, src/presentation/, tests/{input,simulation,physics}_test.gd, tests/throw_journey.gd, content/fixtures/throws/, docs/decisions/003-*.md, docs/playtests/, docs/handoffs/E05.md.
- Shared files changed under this claim (coordinator-owned this session): project.godot (stretch aspect), src/bootstrap/*, tools/qa.py, the CI workflow, docs/CONTRACTS.md, docs/DEVELOPMENT.md, AGENTS.md, README.md and this checkpoint.
- Out of scope: catalogue balls (the Hook ball and others), scoring and curved-shot effects (E06/E18), final VFX and art (E11/E12), settings persistence and onboarding (E25), device exports (E26). Real-phone trials need hardware this Linux session lacks; they remain an open gate with a written protocol.
- Status: implementation pushed (`0ad08c2`) with handoffs/E05.md, and CI passed. The claim stays open until the owner reviews and merges.

Standing user preferences:
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
- Native iOS/Android/Windows, physical device feel (E05 trials NOT RUN), visual review and balance: NOT VALIDATED. E04/E05 throw thresholds and physics tuning are provisional (ADR 002/003).

## Blockers and limitations

No local blocker. The native Apple toolchain, signing, the Android SDK and mobile hardware are not available in this Linux execution, so E05's real-phone trials stay open until a device build exists. E04 provides a straight-throw lab with developmental geometry. Spin and hook, real-device feel, scoring presentation, production visuals and content remain unfinished, and pure frame rules and contracts exist. E04 independent review needs a reviewer: none was spawned, because this session ran a single agent. Current UI is functional developmental scaffolding only. E03 has one House League/House Kit fixture, not the full release selection system.

## Session handoff protocol

Workers copy AGENT-TASK-TEMPLATE.md to docs/handoffs/<task-id>.md on their own branch. Push code and handoff together; send coordinator branch/SHA and validation summary. Coordinator reviews and integrates, records the integrated code SHA and relevant test evidence, clears stale claims, updates the next action, and pushes checkpoint. Preserve unfinished tasks honestly; no running diary.

Do not insert the checkpoint's own future commit SHA. Record already-known implementation commits; the Git history identifies the checkpoint commit. On resume inspect remote changes before accepting an old ownership claim. Stop after the assigned execution is durably saved.
