Roguewood — Codex Wave 10: UI-A1-C (layout revision and backdrop options), UI-A2 (card material treatments) and AV-H4 (art and effects for E17-D10's five House items).
Recommended effort: Medium for UI-A1-C; Medium–High for UI-A2; Medium for the AV-H4 sessions, or High for a session whose items need counted displays.

Begin (Wave 9 and the CI fix are merged into main, PRs #20 and #21):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 10 claims" commit or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/ROADMAP.md: "Art-forward interface: UI-R1", including "Owner decisions on UI-A1", and "Tethered swing: E05-R2".
3. Then read docs/AI-HANDOFF.md: "Wave 10 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. Read your own Wave 9 delivery: docs/handoffs/WAVE9-CODEX.md, UI-A1-A.md, UI-A1-B.md and docs/art/ui/UI-A1.md.

UI-A1-C (Medium, first; the owner approves it before Claude builds the screens in UI-2):
- **Landscape throw screen:**
  - The lane renders full width. A framed top-bar HUD spans the width: League and Division, score, target, money and Options.
  - Framed panels sit over the empty flanks: on the left the hand of four cards, with deck count, Cycle and Inspect; on the right the score slip, the rival and their rule, and the Charm slots.
  - Each panel is about 19% of the width and never covers the lane corridor.
  - On narrow (4:3) landscape the panels shrink, then fold into the top bar.
- **Landscape shop:** keeps a three-column grid.
- **Portrait (phone) throw screen, top to bottom:**
  - a two-row top bar: League and Division with Options; then score, target and money, with money in its own slot, not under Options;
  - a strip with the score slip and the rival chip;
  - a Charms row;
  - the full-width lane, framed so the ball sits about two-thirds down;
  - a hand panel of two cards, with deck counts, Cycle and Inspect on the thumb side (mirrored for left-handed play).
- **Side-space backdrop:** offer 2–3 options for House, for example a slow star field that matches the night sky in its windows.
  - Not wider League environment art.
  - It sits behind the lane and panels, has a reduced-motion version, and varies by League.
- **Show it:** re-render JUIA1 to include landscape 16:9, landscape 4:3 and portrait, each with every backdrop option. Update docs/art/ui/UI-A1.md (layout, panel rules, safe areas, backdrop).
- **Reference:** the owner approved this from coordinator mockups of the real game with your kit overlaid. Those images were shared in chat and are not committed; the layout above is the spec.

UI-A2 (Medium–High):
- Foil and rarity treatments that the card component can apply, as a shader or as layers, with a reduced-motion or reduced-flash state.
- Per-League frame variants, House first.
- The final icon pass.
- Paths: assets/ui/ and docs/art/ui/.
- Claude's UI-1 builds the card component in src/presentation/card_view.gd this wave. Deliver your treatments as assets plus a short integration note in your handoff, not as edits to that file.

AV-H4 (2 sessions):
- **AV-H4-A:** Double Take, Called Shot, Pin Count.
- **AV-H4-B:** Cleanup Crew, Lucky Seven.
- **For each item:**
  - write its brief in docs/art/briefs/E17-D10.md;
  - make its identity art (icon, card, rarity treatment, reduced motion);
  - add activation and sound;
  - meet the presentation need its design block names (content/catalogue/batches/E17-D10.json, under `landed`; see docs/handoffs/E18-C11.md).
- Read counts and conditions from resolver events and facts, never from animation state.
- Check each natively, then set `artwork` and `effects_audio` and fill the asset slots.
- J03C11 plays all five. Extend it add-only.
- Keep the illustrations at a resolution that fills UI-A1's art window.

Ownership and limits:
- Edit content/catalogue.json only for these five items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files.
- Never edit:
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/;
  - throw_lab.gd, card_hand.gd, card_inspector.gd, shop_panel.gd, division_hud.gd or score_panel.gd (Claude's UI-1, UI-2 and E05-R2 this wave);
  - export_presets.cfg, project.godot, clubhouse_model.gd, content/leagues/ or Claude's E17/E18 paths.
- Presentation hooks may read lab and shop state and connect to signals. A hook that needs a new signal or field goes to the coordinator as a request.
- Claude's concurrent work this wave:
  - UI-1: the card component everywhere.
  - E05-R2: the tethered swing. The ball orbits the touch point inside its own radius, and orbit speed sets the charge. The cue ids `throw.charge`, `throw.curve_ready` and `throw.full_charge` remain.
  - UI-2: the screens in the approved layout, after your UI-A1-C is approved.
  - AV-T01 (throw effects) is yours in Wave 11, after the swing exists. Do not start it.
- tools/qa.py, the CI workflow and run_tests.gd are add-only.
  - Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
  - Give every new art or effects step `if: matrix.shard == 'art'`, and add new art journeys to the art shard.
- These must stay identical:
  - the physics digest `75d1a3c0…`;
  - J03 560/240/70 and J05 21060.
- These must keep passing: J06, J22L01, J03C01–C11, JAVC03A/B, JAVC04A/B/C, JAVH1AC/BC, JAVH2AC/BC, JAVH3AC/BC, JUIA1, J22L01ART, the E21-R03/R04 and AV-C06/C07 journeys, J11ART, J12V08 and J19A16.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md (UI-A1-C, UI-A2, AV-H4-A, AV-H4-B);
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator.
- At the end of the wave, write docs/handoffs/WAVE10-CODEX.md as an index, listing the UI-A1-C captures and the backdrop options the owner should review.

Stop after the Wave 10 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 11 work: AV-T01, or the Neon theme or rivals.
