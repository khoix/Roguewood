Roguewood — Codex Wave 8: AV-H1 and AV-H2, art and effects for the twelve House Charms of E17-D07 and E17-D08.
Recommended effort: Medium; four sessions of three items each. Use High for a session whose items need counted or growing displays: Trophy Case's trophies, Late Rally's score against half the target, or Corner Pockets' and Front Line's lit rack spots.

Begin (only after the owner has merged Wave 7 into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 7 closed" commit) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, docs/ROADMAP.md, then docs/AI-HANDOFF.md: "Wave 8 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E18-C08.md and E18-C09.md, and the design blocks (presentation needs, asset ids) under `landed` in content/catalogue/batches/E17-D07.json and E17-D08.json.

Objective, three items per session:
- AV-H1-A: Head Pin, Wood Grain, Opening Act.
- AV-H1-B: Open House, Strike Fund, Holdouts.
- AV-H2-A: Trophy Case, Corner Pockets, Late Rally.
- AV-H2-B: Clean Pickup, House Special, Front Line.

For each item:
- write its brief in docs/art/briefs/E17-D07.md or E17-D08.md;
- make its identity art (icon, card, rarity treatment, reduced motion);
- add activation and sound;
- meet the presentation need its design block names.
- Read counts and conditions from resolver events and facts, never from animation state.
- Check each natively, then set `artwork` and `effects_audio` and fill the asset slots.
- J03C08 and J03C09 buy and score all twelve in real frames. Extend them add-only for captures and presentation checks.

Ownership and limits:
- Edit content/catalogue.json only for these twelve items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files.
- Never edit:
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/ or src/content/;
  - throw_lab.gd's scoring and flow, or the shop rules;
  - clubhouse_model.gd, content/leagues/ or Claude's E17/E18 paths.
- Presentation hooks may read lab and shop state and connect to signals. A hook that needs a new signal or field goes to the coordinator as a request.
- Claude's concurrent work this wave:
  - DC-H4 lands the last five House items (two Charms, three tactical cards). Do not set flags on them; their art is AV-H3/H4 in Wave 9.
  - E22-L01 integrates the House League's eight Divisions and your E22-L01-ART theme.
  - Keep the theme's asset ids and bindings stable.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- These must stay identical:
  - the physics digest `75d1a3c0…`;
  - J03 560/240/70 and J05 21060.
- These must keep passing: J06, J03C01–C10, JAVC03A/B, JAVC04A/B/C, J22L01ART, the E21-R03/R04 and AV-C06/C07 journeys, J11ART, J12V08 and J19A16.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md;
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator.

Stop after the Wave 8 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 9 work (AV-H3/H4 for E17-D09 and DC-H4's items), other Leagues' themes or rivals, or E26.
