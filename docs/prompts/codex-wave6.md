Roguewood — Codex Wave 6: AV-C04 (the eight landed modifications) and E22-L01-ART (House League theme).
Recommended effort: Medium for AV-C04, three sessions of up to three items each (High for the session with Echo Charge); High for E22-L01-ART.

Begin (only after the owner has merged Wave 5 into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 5 closed" commit) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, docs/ROADMAP.md, then docs/AI-HANDOFF.md: "Wave 6 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E18-C04.md, docs/handoffs/E17-L01.md, docs/art/briefs/E17-D04.md, content/leagues/house.json and content/leagues/rivals.json.

Objective:
- **AV-C04:** Chalk Grip, Spin Wax, Coin Slot, Echo Charge, Brass Cap, Gilt Leaf, Lantern and Keystone are in content/catalogue.json with mechanics.
  - From your E17-D04 briefs, make each one's identity art: badge, card and overlay on its host. Badges and overlays never hide the host's identity.
  - Add effects and sound. Read the counts and conditions from the resolver, never from animation state.
  - Check each natively, then set `artwork` and `effects_audio`.
  - J03C04 attaches all eight to known hosts (Chalk Grip and Spin Wax on Hook cards, Coin Slot and Echo Charge on Hammer cards, Brass Cap at rack 1, Gilt Leaf at 3, Keystone at 5, Lantern at 6). It gives deterministic shop, strike and open-frame captures.
- **E22-L01-ART:** the House League theme for eight Divisions, from content/leagues/house.json.
  - Show Division progression in the environment and signage.
  - Give the Championship match its own look.
  - Make the two lane conditions (House Oil, Dry Backend) readable as lane visuals.
  - Give the League its music identity.
  - Assets bind by ID. Claude's House integration (E22-L01, Wave 8) wires them into the live League, so record the IDs and drop paths in your hand-off. Until then, verify them with preview captures and an inspector or contact sheet.

Ownership and limits:
- Edit content/catalogue.json only for these eight items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files or edit League specs.
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/, throw_lab.gd scoring and flow, clubhouse_model.gd, content/leagues/ or Claude's E17/E18 paths.
- Claude's concurrent E18-C05…C07 land House Rules, House Pins, the lane conditions, tactical cards and shop upgrades. Do not set flags on them this wave; The Proprietor and Old Lou (E21-R03, R04) are Wave 7.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- Physics digest `75d1a3c0…`, J03 560/240/70, J05 21060 and J06 must stay identical. J03C01–C04, J11ART, J12V08, J19A16 and JAVC03A/B must keep passing.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md;
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator.

Stop after the Wave 6 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 7 work (House rivals, tactical-card and upgrade art), other Leagues' themes or E26.
