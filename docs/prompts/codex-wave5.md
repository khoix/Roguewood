Roguewood — Codex Wave 5: E17-D04-ART, E19-A17 (C03 identities), E20-V09 (C03 effects) and E19-A18 (D03 boss-rule identities).
Recommended effort: Medium for E17-D04-ART, E19-A17 and E19-A18; High for E20-V09.

Begin (only after the owner has merged Wave 4 into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 4 closed" commit, with your Wave 4 integrated) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/AI-HANDOFF.md: "Wave 4 closed", "Wave 5 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E18-C03.md, docs/handoffs/E17-D04.md, content/catalogue/batches/E17-D04.json and docs/art/briefs/E17-D03.md.

Objective:
- **E17-D04-ART:** briefs in `docs/art/briefs/E17-D04.md` for the twelve modifications, from each `design.asset_ids` and `presentation_needs`. A modification is a badge on the host card and an overlay on the host in play; it never hides the host's identity (design §15). Flag look-alikes: Echo Charge / Echo Ball, Lead Core / Hammer Ball, Gilt Leaf / Gold Pin, Lead Weight / Anchor Pin, Spearhead / Crown Pin.
- **E19-A17:** the six C03 items are in content/catalogue.json with Codex's identity paths (Crown Pin's from D01, the five Charms' from Wave 3). Check each natively (shop, inventory or rack, binder; Crown Pin's in-play scene on the real pin body, cosmetic only), then set its `artwork` flag.
- **E20-V09:** activation and sound for Crown Pin, Split Specialist, Sweet Spot, Back Row, Underdog and Crown Jewel. Crown Pin's cue distinguishes +40 (fell last) from the explained 0, and Crown Jewel shares it. Split Specialist shows the first-roll leave; Underdog the score-versus-half-target check; Back Row highlights the back row; Sweet Spot the counted grades. Read counts and checks from the resolver (`result.facts`, event `count`), never from animation state. J03C03 gives deterministic shots for a converted split and for each Crown falling last. Set `effects_audio` only after a native check of each.
- **E19-A18:** identity art for the nine D03 boss rules from your E17-D03 briefs, with paths in E17-D03.json only; they are not playable until E18 builds their rules.

Ownership and limits:
- Edit content/catalogue.json only for these items' `assets` slots and their `artwork` / `effects_audio` flags. In batch files, edit only asset paths; never set flags there.
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/, throw_lab.gd scoring and flow, clubhouse_model.gd, or Claude's E17/E18 paths. Claude's concurrent E18-C04 lands nine D04 modifications; do not set their flags this wave.
- tools/qa.py, the CI workflow and run_tests.gd are add-only; keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- Physics digest `75d1a3c0…`, J03 560/240/70, J05 21060 and J06 must stay identical. J03C01, J03C02, J03C03, J11ART, J12V08 and J19A16 must keep passing.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per batch:
- **Before:** IDs and slots, the source and provenance plan, the journeys and captures.
- **After:** re-run `qa.py unit`, `content` and the affected journeys headless and `--rendered`; write docs/handoffs/<batch-id>.md; push, verify the remote SHA and a clean tree; report the SHA and batch IDs to the coordinator. Physical-phone readability stays E26.

Stop after the Wave 5 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start D04 identity art (it follows these briefs in Wave 6), E21 rivals not yet defined, or E22.
