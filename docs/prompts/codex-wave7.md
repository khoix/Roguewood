Roguewood — Codex Wave 7: E21-R03 and R04 (House's new rivals), AV-C06 (the three tactical cards) and AV-C07 (the six shop upgrades).
Recommended effort: High for E21-R03/R04 (one session); Medium for AV-C06 (one session); Medium for AV-C07 (two sessions of three upgrades each).

Begin (only after the owner has merged Wave 6 into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 6 closed" commit) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, docs/ROADMAP.md, then docs/AI-HANDOFF.md: "Wave 7 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E18-C05.md, E18-C06.md, E18-C07.md, E21-R01.md and E21-R02.md, content/leagues/rivals.json and content/leagues/house.json, and the design blocks in content/catalogue/batches/E17-D01.json (the three tactical cards) and E17-D06.json (the six upgrades).

Objective:
- **E21-R03 The Proprietor (House Rules) and E21-R04 Old Lou (House Pins):** follow the E21-R01/R02 template.
  - Portrait, reactions and an introduction look for each rival.
  - A rule badge for House Rules and one for House Pins. The House champion (The Custodian with Clean Sweep plus House Rules) shows both rule badges together.
  - Use the names, initials and signatures in rivals.json, and the intros and reactions in house.json.
  - J03C05 (`--content=house_c05`) reaches the champion and Old Lou natively. Capture each rival's introduction, the badge and a reaction there.
- **AV-C06, the tactical cards Nudge, Reserve Call and Rule Waiver:** icon, card, rarity and reduced-motion art already exist (E19 D01 batches).
  - Add activation and sound for each card.
  - Meet the presentation needs in E17-D01's design blocks:
    - a chooser on the flat rack diagram, with adjacent empty spots highlighted (Nudge);
    - a clear "this frame only" marker on the swap (Reserve Call);
    - the rule badge visibly waived for the frame (Rule Waiver).
  - The lab emits `tactic_played(action)` when a card is played, and its TacticSheet holds the choices. Keep the chooser's choices and their order: J03C06 taps them by index.
  - Check each natively, then set `artwork` and `effects_audio`.
- **AV-C07, the six upgrades** (Punch Card, Pin Caddy, Clearance Tag, Savings Book, Extra Shelf, Spotlight Sign):
  - Write briefs from E17-D06's presentation needs in docs/art/briefs/E17-D06.md.
  - Make identity art for each: icon, card, rarity treatment and reduced motion. Upgrades need their own category frame (design §8).
  - Add activation and sound, and the shop-screen treatments each brief names.
  - Check each natively in J03C07, then set `artwork` and `effects_audio` and fill the asset slots.

Ownership and limits:
- Edit content/catalogue.json only for these nine items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files.
- Rival art binds by rival id. Never edit content/leagues/.
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/, throw_lab.gd scoring and flow, the shop rules, clubhouse_model.gd or Claude's E17/E18 paths.
  - Presentation hooks may read lab and shop state and connect to signals.
  - A hook that needs a new signal or field goes to the coordinator as a request.
- Claude's concurrent DC-H1…H3 write and land 18 House items. Do not set flags on them this wave; their art is AV-H1…H4 in Waves 8 and 9.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- These must stay identical: physics digest `75d1a3c0…`, J03 560/240/70, J05 21060, and J06 on the Wave 6 head.
- These must keep passing: J03C01–C07, JAVC03A/B, JAVC04A/B/C, J22L01ART, J11ART, J12V08 and J19A16.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md;
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator.

Stop after the Wave 7 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 8 work (AV-H1…H4 for the 23 House items), other Leagues' themes or rivals, or E26.
