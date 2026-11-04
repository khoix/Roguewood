Roguewood — Codex Wave 9: UI-A1, the interface visual target, and AV-H3, art and effects for E17-D09's six House items.
Recommended effort: High for both UI-A1 sessions. Medium for the two AV-H3 sessions, or High for a session whose items need counted displays.

Begin (Wave 8 is merged into main by PR #19):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 9 claims" commit) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/ROADMAP.md: "Art-forward interface: UI-R1", "Throw rework" and "Web target".
3. Then read docs/AI-HANDOFF.md: "Wave 9 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. Read Roguewood-Game-Plan.md §17 (visual quality), §15 "Card presentation and rarity", and docs/art (the art bible and ledger).
5. For AV-H3, read docs/handoffs/E18-C10.md and the `landed` design blocks (presentation needs, asset ids) in content/catalogue/batches/E17-D09.json.

Why UI-A1 exists (owner, 2026-11-04):
- The game's first impression is a wall of text with tiny art icons, plain borders, and cards that look like boxes rather than playing cards.
- The owner wants it art-forward: the artwork showcased, clean animation, real card faces, and framing that ties the screen together.
- UI-A1 sets that target. The owner must approve it before Claude builds it into the game (UI-1 and UI-2, Wave 10).

UI-A1 (2 sessions):
- **Session A: the card.**
  - A playing-card face at card proportions, with rounded corners. The art window takes most of the face.
  - It also carries a name banner, a rarity frame (common to legendary), a category mark, and short rule text led by icons.
  - A card back, and Value, Mult and $ icons.
  - Show existing item art in real faces across rarities and categories: ball, pin, Charm, tactical card, upgrade.
- **Session B: the frame kit.**
  - Borders, corners and ornaments that tile or nine-slice, for the HUD, shop, score slip, menus and panels. House-themed first.
  - A pixel font with a licence recorded in the ledger.
  - A portrait and a landscape composition of the throw screen and the shop, using the kit.
- **Show and check it:**
  - Build a standalone preview scene (like house_theme_preview.tscn).
  - Add an art-shard journey, JUIA1, that captures it at actual size in portrait and landscape and checks the text stays readable at native size.
  - Rendered captures go to the CI artifacts and to the owner, never into git.
- **Write up:** the specification (sizes, safe areas, layer order, nine-slice margins, states such as pressed, armed, sold and locked, and motion notes for deal, flip, tilt and cycle) goes in docs/art/ui/UI-A1.md, so UI-1 can build it without guessing.
- **Paths:** assets/ui/, docs/art/ui/, the preview scene and JUIA1. Do not edit existing UI scripts: card_hand.gd, shop_panel.gd, the HUD, the score panel, the Clubhouse, and so on. UI-1 integrates.

AV-H3 (2 sessions, three items each):
- **AV-H3-A:** Spare Ball, Workhorse, Oak Pin.
- **AV-H3-B:** Tin Pin, Spare Jar, Consolation Prize.
- **For each item:**
  - write its brief in docs/art/briefs/E17-D09.md;
  - make its identity art (icon, card, rarity treatment, reduced motion);
  - add activation and sound;
  - meet the presentation need its design block names.
- Read counts and conditions from resolver events and facts, never from animation state.
- Check each natively, then set `artwork` and `effects_audio` and fill the asset slots.
- J03C10 plays all six. Extend it add-only for captures and presentation checks.
- Card art you make now goes into today's card UI. Keep the illustrations at a resolution that also fills UI-A1's larger art window.

Ownership and limits:
- Edit content/catalogue.json only for these six items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files.
- Never edit:
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/;
  - throw_lab.gd (Claude's E05-R1b changes its hold and input code this wave);
  - export_presets.cfg or project.godot (Claude's E26-W01 web export);
  - clubhouse_model.gd, content/leagues/ or Claude's E17/E18 paths.
- Presentation hooks may read lab and shop state and connect to signals. A hook that needs a new signal or field goes to the coordinator as a request.
- Claude's concurrent work this wave:
  - E26-W01: a Web export with a browser journey in CI.
  - E05-R1a/R1b: the held-ball throw. The ball follows the finger, swinging builds spin, and sparkles show when the curve is ready.
  - R1b fires the cue ids `throw.charge`, `throw.curve_ready` and `throw.full_charge`. Their effects and sounds are your AV-T01 in Wave 10, not this wave.
- Keep the House theme's asset ids and bindings stable.
- tools/qa.py, the CI workflow and run_tests.gd are add-only.
  - Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
  - Give every new art or effects step `if: matrix.shard == 'art'`, and add new art journeys to the art shard, never to the gameplay step.
- These must stay identical:
  - the physics digest `75d1a3c0…`;
  - J03 560/240/70 and J05 21060.
- These must keep passing: J06, J22L01, J03C01–C11, JAVC03A/B, JAVC04A/B/C, JAVH1AC/BC, JAVH2AC/BC, J22L01ART, the E21-R03/R04 and AV-C06/C07 journeys, J11ART, J12V08 and J19A16.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md (UI-A1-A, UI-A1-B, AV-H3-A, AV-H3-B);
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator.
- At the end of the wave, write docs/handoffs/WAVE9-CODEX.md as an index. In it, list the UI-A1 captures the owner should review.

Stop after the Wave 9 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 10 work: UI-A2, AV-H4 for E17-D10's five items, AV-T01, or the Neon theme or rivals.
