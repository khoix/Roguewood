Roguewood — Codex Wave 5: AV-C03 (art checks, effects and sound for the six C03 items) and E17-D04-ART (modification briefs).
Recommended effort: High for AV-C03 (two sessions of three items); Medium for E17-D04-ART.

Begin:
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, docs/ROADMAP.md, then docs/AI-HANDOFF.md: "Wave 5 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E18-C03.md, docs/handoffs/E17-D04.md and content/catalogue/batches/E17-D04.json.

What changed in the plan (docs/ROADMAP.md):
- **AV sessions.** For items that are already playable, you now do the brief, identity art, effects, sound, native check and both completeness flags in one session per three items. This wave's AV-C03 replaces the separate E19-A17 and E20-V09 claims.
- **Boss-rule art (E19-A18) is dropped.** Each boss rule gets its badge art in its rival's E21 session. If you already made D03 identity art, keep it in place; it becomes input to those sessions.
- **E22 is split.** E22 League configuration and integration and all of E26 move to Claude. You keep every art component, including each League's theme art (E22-Lxx-ART), rivals (E21), the asset audit and art-budget fixes.

Objective:
- **AV-C03:** Crown Pin, Split Specialist, Sweet Spot, Back Row, Underdog and Crown Jewel are in content/catalogue.json with your identity paths (Crown Pin's from D01, the Charms' from Wave 3).
  - Check each natively: shop, inventory or rack, binder; Crown Pin's in-play scene on the real pin body, cosmetic only. Then set `artwork`.
  - Add activation and sound:
    - Crown Pin's cue distinguishes +40 (it fell last) from the explained 0, and Crown Jewel shares it.
    - Split Specialist shows the first-roll leave.
    - Underdog shows the score-versus-half-target check.
    - Back Row highlights the back row.
    - Sweet Spot shows the counted grades.
  - Read counts and checks from the resolver (`result.facts`, event `count`), never from animation state. J03C03 gives deterministic shots for a converted split and for each Crown falling last.
  - Set `effects_audio` only after a native check of each item.
- **E17-D04-ART:** briefs in `docs/art/briefs/E17-D04.md` for the twelve modifications, from each `design.asset_ids` and `presentation_needs`.
  - A modification is a badge on the host card and an overlay on the host in play; it never hides the host's identity (design §15).
  - Flag look-alikes: Echo Charge / Echo Ball, Lead Core / Hammer Ball, Gilt Leaf / Gold Pin, Lead Weight / Anchor Pin, Spearhead / Crown Pin.
  - Claude lands eight of them this wave (E18-C04); your AV-C04 in Wave 6 makes their art and effects from these briefs.

Ownership and limits:
- Edit content/catalogue.json only for these six items' `assets` slots and their `artwork` and `effects_audio` flags. Never set flags in batch files.
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/, throw_lab.gd scoring and flow, clubhouse_model.gd, or Claude's E17/E18 paths.
- Do not set flags on the eight modifications Claude lands this wave; they are Wave 6 work.
- tools/qa.py, the CI workflow and run_tests.gd are add-only. Keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- Physics digest `75d1a3c0…`, J03 560/240/70, J05 21060 and J06 must stay identical. J03C01, J03C02, J03C03, J11ART, J12V08 and J19A16 must keep passing.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per batch:
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md;
  - push, then verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator. Physical-phone readability stays with E26.

Stop after the Wave 5 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start Wave 6 work (AV-C04, House theme art, House rivals), E21 rivals or E22.
