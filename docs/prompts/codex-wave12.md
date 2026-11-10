Roguewood — Codex Wave 12: UI-A3 (numerals that cannot be read as letters), E21-R05 to R07 (the Neon rivals, with three missing House plaques) and E22-L02-ART (the Neon theme).
Recommended effort: Medium for UI-A3; High for each rival session; High for the two theme sessions.

Begin (Wave 11 is merged into main by PR #29, `f65d16f`):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 12 claims" commit or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/ROADMAP.md: the Wave 12 row, "GUI review: UI-4" and "League template".
3. Then read docs/AI-HANDOFF.md: "Wave 12 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. Read docs/handoffs/UI-4.md ("Left for the owner or Codex"), docs/handoffs/E17-L02.md and content/leagues/neon.json, and your own docs/handoffs/WAVE11-CODEX.md.

UI-A3 (Medium, first):
- **The problem:** in Pixelify Sans the digit 5 is almost the letter S and 2 is close to Z. In play the score slip reads "140 × S = 700", a rack shows "Pin S", prices read "$S" and the assist panel reads "Power S0%". Rendered large, 5 and S differ by one pixel.
- **Deliver:** numerals no player can read as letters, at the sizes the game uses (16 to 36 px on a 540-wide portrait canvas, drawn at a phone's 2–3× scale). Either patched digits in the bundled font (it is OFL; record the change and the reserved-name rule in the ledger) or a second face used for numbers.
- **Show it:** the score slip, the frame review ("140 × 5 = 700", the rack numbers), a shop price, the money slot and the throw-tuning page, before and after, at 780×1688 (tools/capture_phone_tour.gd makes these screens; see docs/DEVELOPMENT.md).
- **Paths:** assets/ui/fonts/ and docs/art/ui/. If you choose a second face, deliver it and name where it applies; Claude wires it in src/presentation/house_ui_theme.gd.

E21-R05, R06, R07 (one session each):
- **R05 Slick** (`boss_rule.oil_slick`), **R06 Laser Lena** (`boss_rule.narrow_lane`), **R07 DJ Flicker** (`boss_rule.strobe`), and with R07 **DJ Flicker, Neon Champion**, who shows the Strobe and Oil Slick seals together.
- For each: portrait, idle, entrance, the six reactions, defeat, reduced-motion versions, the rule badge, and the Clubhouse plaque (`plaque.slick`, `plaque.laser_lena`, `plaque.dj_flicker`, `plaque.dj_flicker_champion`).
- Identities, intros and reaction lines are in content/leagues/neon.json and content/leagues/rivals.json.
- **Also, in the first of these sessions:** the three House plaques the Trophy shelf still shows as marked placeholders: `plaque.proprietor`, `plaque.old_lou`, `plaque.custodian_champion` (assets/clubhouse/<asset id>.png; no code edit is needed).
- Reach all three bosses with `--content=neon_c13` and J03C13. Add art coverage without deleting checks.

E22-L02-ART (High, 2 sessions):
- The Neon theme for eight Divisions and the Championship: environment and signage.
- Lane looks: Long Oil (the oil ends at 47 ft), Two-Tone (the left half dry from 34 ft, told apart by more than colour), Narrow Lane's edges and rail (replacing the developmental magenta guard lines in aim_overlay.gd) and Strobe's narrowed ring zones.
- The music identity, the Neon frame-kit variant, a flank backdrop with a reduced-motion version, and `trophy.neon`.
- Claude makes the Neon League live this wave (E22-L02). Your theme and rivals bind by ID and can land after it; until then the developmental presentation stays, marked.

Ownership and limits:
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/; content/leagues/; content/catalogue.json outside your own items' `assets` slots and flags; export_presets.cfg or project.godot.
- Claude's concurrent work this wave: UI-5 first (one session menu button in place of Restart, Clubhouse and Options, a frame review without Speed and Skip, and a shop whose offers open in an overlay to confirm a purchase: bootstrap.gd, throw_lab.gd, division_hud.gd, match_panels.gd, score_panel.gd, shop_panel.gd, card_inspector.gd, and the journeys' way of reaching Options and the Clubhouse, finishing a reveal and buying, your art journeys included; merge `origin/claude/roguewood-build` again before you add or edit a journey that opens Options, skips a reveal or buys in the shop), then E18-C14 (the Neon primitives, in src/rules/ and src/simulation/), DC-N1 and DC-N2 (the first twelve Neon items: E17-D12 and D13 with E18-C15 and C16) and E22-L02 (throw_lab.gd, bootstrap.gd, the League registry, a new J22L02). Their art is your Wave 13 (AV-N1, AV-N2); do not start it.
- A hook you need that does not exist goes to the coordinator as a request in your handoff.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Every new art step has `if: matrix.shard == 'art'`.
- These must stay identical: the physics digest `75d1a3c0…`; J03 560/240/70 and J05 21060.
- These must keep passing: J02, JAVT01, J06, J22L01, J03C13, J11 and J11ART, JUIA1 and JUIA2, and every art journey in the art shard.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.

Per session:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:** re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`; write docs/handoffs/<batch-id>.md (UI-A3, E21-R05, E21-R06, E21-R07, E22-L02-ART); push; verify the remote SHA and a clean tree; report the SHA and batch IDs to the coordinator.
- At the end of the wave, write docs/handoffs/WAVE12-CODEX.md as an index, listing the captures the owner should review.

Stop after the Wave 12 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 13 work: AV-N1 or AV-N2.
