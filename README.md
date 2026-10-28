# Roguewood

- [Game design and build plan](Roguewood-Game-Plan.md)
- [Execution milestones and copyable prompts](docs/EXECUTION-PLAN.md)
- [Current agent checkpoint](docs/AI-HANDOFF.md)
- [Agent working rules](AGENTS.md)
- [Per-task handoff template](docs/AGENT-TASK-TEMPLATE.md)

Status: E01–E14 are complete and merged (owner merge is approval); E15 (Career persistence and unlock graph) is on `claude/roguewood-build`. E13 delivered the vertical slice: catalogue/frame contract v2 (conditions, per-count scaling, Echo retriggers, run growth, strike streak, item physics), the first production batch E13-S01 (four balls, six pins, twelve Charms, two boss rules, House Kit), a two-Division House League with The Surveyor and The Custodian, content sets, saves v2, J06 across both Divisions and a seeded three-plus-build simulation (ADR 008). Open gates: real-device play and feel (no device in this environment), E07's final equipment model, balance (E24), and art/effects for the batch (E19–E21). See the checkpoint for status and CI, and [Development](docs/DEVELOPMENT.md) for setup and validation commands. The checkpoint is the durable source of execution state across agents and sessions.

The League menu also offers **House Campaign · 8 Divisions (provisional)**: a seeded 24-match run with save/resume and optional endless continuation. See [ADR 009](docs/decisions/009-seeded-campaign.md) for its provisional targets/content and [E14](docs/handoffs/E14.md) for verification.

The Career keeps unlocks, first clears, League titles, mastery goals, records and the collection across attempts, banked the moment they are earned and never duplicated; practice attempts grant no unlocks. See [ADR 010](docs/decisions/010-career-and-unlock-graph.md) and [E15](docs/handoffs/E15.md).
