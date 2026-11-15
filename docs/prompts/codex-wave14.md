Roguewood — Codex Wave 14: AV-N3, AV-N4 and AV-N5 (art for Neon's last sixteen items and three mastery ribbons).
Recommended effort: High for each batch.

Repository: https://github.com/khoix/Roguewood (your branch: `codex/roguewood-build`; the coordinator's: `claude/roguewood-build`; never push to `main` and open no pull requests).

Begin (start once Wave 13 is merged into main):
1. Clone the repository if this session has no checkout, then fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 13 closed" commit or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/ROADMAP.md: the Wave 14 row and "League template".
3. Then read docs/AI-HANDOFF.md: "Wave 14 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. Read docs/handoffs/E18-C17.md, E18-C18.md and E18-C19.md (the sixteen items, their journeys and captures), UI-8.md (the new Binder preview and end screen) and your own WAVE13-CODEX.md, AV-N1.md and AV-N2.md (the pattern to follow).

AV-N3 (High): DC-N3's six items: Dry Side, Lane Reader, Hook Shot, Line Call, Bounce Back and Straight Money. Native checks through J03C17.
AV-N4 (High): DC-N4's five items: Trade-In, Specialist Shelf, Comet Ball, Metronome and Steady Hand, plus the Controlled Curve ribbon (`ribbon.mastery.controlled_curve`). Native checks through J03C18.
AV-N5 (High): DC-N5's five items: Compass Pin, Split Pattern, Dry Run, Long Game and Second Chance, plus the Both Halves and Rebound Rescue ribbons (`ribbon.mastery.both_halves`, `ribbon.mastery.rebound_rescue`). Native checks through J03C19.
- For each item: art in its `assets` slots, its artwork and effects_audio flags, its scoring effect and sound, and reduced-motion versions, as AV-N1 and AV-N2 did. Asset ids and presentation needs are in the batches E17-D14, D15 and D16.
- Moments the play needs to show:
  - Dry Side's and Dry Run's side reading at 34 ft;
  - Lane Reader's, Split Pattern's, Long Game's and the Compass Pin's lane;
  - Hook Shot's stretched aim guide;
  - Bumper Guard's rescue paying Bounce Back and Second Chance;
  - Specialist Shelf's marked Specialist offer in the shop (slot 7, "Specialist").

Already changed by the coordinator, before you start:
- UI-8: the Binder opens a tapped card in a preview overlay (`binder_art` and `binder_detail` now live in it). Its categories are tabs, and its cards pass a drag on to the page. The keep section has no Cycle or Inspect button. The end screen is sections (`result_view`); `result_title` and `result_body` keep the full text, hidden. The session menu button sits inside the top bar.
- Boss introductions no longer advance on their own. A journey presses `lab.hud.intro_button`; the shared `_aim()` helpers do it already.

Ownership and limits:
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/; content/leagues/; content/catalogue.json outside your own items' `assets` slots and flags; content/career/; export_presets.cfg or project.godot.
- Claude's concurrent work this wave: E17-L03, the Salvage League spec (content/leagues/, content/catalogue/batches/, docs), then Salvage's rules and lane conditions (src/rules/, src/simulation/). Salvage's rivals and theme are Wave 15; do not start them.
- A hook you need that does not exist goes to the coordinator as a request in your handoff.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Every new art step has `if: matrix.shard == 'art'`.
- These must stay identical: the physics digest `75d1a3c0…`; J03 560/240/70 and J05 21060.
- These must keep passing: J02, JAVT01, J06, J22L01, J22L02, J03C13, J03C15 to J03C19, J11 and J11ART, JAVN1, JAVN2, JUIA1 and JUIA2, and every art journey in the art shard.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:** re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`; write docs/handoffs/<batch-id>.md (AV-N3, AV-N4, AV-N5); push; verify the remote SHA and a clean tree; report the SHA and batch IDs to the coordinator.
- At the end of the wave, write docs/handoffs/WAVE14-CODEX.md as an index, listing the captures the owner should review.

Stop after the Wave 14 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded.
