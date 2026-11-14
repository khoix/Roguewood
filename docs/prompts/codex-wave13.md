Roguewood — Codex Wave 13: AV-N1 and AV-N2 (art for the first twelve Neon items) and the tail of the Neon theme.
Recommended effort: High for each item batch; Medium for the theme tail.

Repository: https://github.com/khoix/Roguewood (your branch: `codex/roguewood-build`; the coordinator's: `claude/roguewood-build`; never push to `main` and open no pull requests).

Begin (start once Wave 12 is merged into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 12 closed" commit or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/ROADMAP.md: the Wave 13 row and "League template".
3. Then read docs/AI-HANDOFF.md: "Wave 13 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. Read docs/handoffs/E18-C15.md and E18-C16.md (the twelve items and their journeys), E22-L02.md ("The Neon theme, bound live") and your own WAVE12-CODEX.md.

AV-N1 (High): DC-N1's six items: Oilskin Ball, Laser Ball, Tempo Pin, Neon Sign, Blacklight and Bumper Guard.
AV-N2 (High): DC-N2's six items: Glow Ball, Prism Pin, Grip Tape, Spotlight, Afterimage and Laser Level.
- For each: card art in the item's `assets` slots, its artwork flags, its scoring effect and sound, and native checks driven through J03C15 (AV-N1) and J03C16 (AV-N2) as earlier AV batches did.
- Bumper Guard's rebound and the Tempo Pin's sweet or perfect reward need a visible moment in play.

Neon theme tail (Medium): anything the live captures (J22L02LIVEART, J22L02 rendered) still show as developmental.

Ownership and limits:
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/; content/leagues/; content/catalogue.json outside your own items' `assets` slots and flags; export_presets.cfg or project.godot.
- Claude's concurrent work this wave: DC-N3 to DC-N5 (Neon's other sixteen items and the primitives they need: src/rules/, src/simulation/, content/catalogue.json, new journeys), then E17-L03 (the Salvage spec). Their art is Wave 14; do not start it.
- A hook you need that does not exist goes to the coordinator as a request in your handoff.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Every new art step has `if: matrix.shard == 'art'`.
- These must stay identical: the physics digest `75d1a3c0…`; J03 560/240/70 and J05 21060.
- These must keep passing: J02, JAVT01, J06, J22L01, J22L02, J03C13, J03C15, J03C16, J11 and J11ART, JUIA1 and JUIA2, and every art journey in the art shard.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:** re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`; write docs/handoffs/<batch-id>.md (AV-N1, AV-N2, and E22-L02-ART for the tail); push; verify the remote SHA and a clean tree; report the SHA and batch IDs to the coordinator.
- At the end of the wave, write docs/handoffs/WAVE13-CODEX.md as an index, listing the captures the owner should review.

Stop after the Wave 13 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded.
