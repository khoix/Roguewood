# Roguewood agent operating rules

Read docs/AI-HANDOFF.md first, then docs/EXECUTION-PLAN.md and the relevant design sections. The design is Roguewood-Game-Plan.md; use repo state over conversation memory. Do not implement future milestones merely because a session has time remaining.

## Multi-agent coordination

- One coordinator owns docs/AI-HANDOFF.md, integration order, and shared contract changes. Workers own scoped task files and docs/handoffs/<task-id>.md only.
- Coordinator commits/pushes a claim before dispatch: owner, reviewer, dependencies, explicit item scope, exclusive paths, base SHA, and branch.
- E01 establishes <agent_name>/roguewood-build without inventing an agent name. Keep that integration branch across sessions. Worker branches/worktrees derive from a recorded integration SHA; resume their exact names later.
- Never share a mutable worktree or branch between concurrent workers. Coordinate shared schemas, project settings, global scenes, CI, and manifests explicitly.
- Review and integrate finished worker tasks; rerun affected integration checks. No force-pushing over other work. No reassigning stale claims without inspecting remote state and reconciling ownership.

## Completion discipline

Implement only the assigned execution/child. Respect the full-release content and premium visuals; a prototype does not fulfill final art or catalogue requirements. Use bounded batches, stable IDs, and independent content completeness flags.

Add meaningful unit/integration and targeted E2E coverage with user-visible features. Native game E2E must drive the real game, not just call rule functions. Device feel, visual review, and platform exports need actual evidence. Never report unrun tests as passed or missing assets as finished.

Before stopping: inspect status/diff, validate, commit intended work, push task branch, verify remote SHA, confirm clean status, and update task handoff. Report blockers and exact resume actions. Coordinator updates central state after integration. DONE requires reviewed acceptance and durable evidence, not a percentage estimate.

E01 provides doctor/import/smoke/export commands in tools/qa.py. E02 supplies unit/content/contract-integration commands; E03 supplies native J01 via e2e --journey J01, with --rendered captures; E04 adds `physics` and J02 (`e2e --journey J02`), which E05 extends with curves, target, mouse, assist controls and resize; later journeys remain unimplemented. Never commit screenshots or rendered captures; share new ones with the user at the end of each session. At milestone completion, report the proposed effort level for the next pending milestone. Follow the checkpoint for the active execution. Record engine/platform decisions once and reuse them unless a concrete failing case requires change. Keep gameplay source Git-backed; do not create duplicate external artifact copies of the repository.
