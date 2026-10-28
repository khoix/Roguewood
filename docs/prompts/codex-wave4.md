Roguewood — Codex Wave 4: E17-D03-ART, E19-A16 (Glass Pin) and E20-V08 (effects for the eight landed E18 items).
Recommended effort: Medium for E17-D03-ART and E19-A16; High for E20-V08.

Begin (only after the owner has merged Wave 3 into main):
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 3 closed" commit, with your Wave 3 integrated) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/AI-HANDOFF.md: "Wave 3 closed", "Wave 4 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read content/catalogue/batches/E17-D03.json, docs/handoffs/E17-D03.md, docs/handoffs/E18-C01.md and docs/handoffs/E18-C02.md.

Objective:
- **E17-D03-ART:** briefs in `docs/art/briefs/E17-D03.md` for the nine boss rules (Oil Slick, Heavy Set, Frugal House, House Rules, Charm Freeze, Narrow Lane, One and Done, Mult Cap, Dull Pins), using each `design.asset_ids`, `counterplay` and `presentation_needs`. A boss rule appears on the rival preview card and the 48px HUD boss chip; brief both. Flag look-alikes: Oil Slick / Narrow Lane, Mult Cap / Dull Pins, Frugal House / House Rules, and each against Dead Straight and Clean Sweep.
- **E19-A16:** Glass Pin. Its identity paths are already on its catalogue entry. Attach `in_play.pin.glass` to the real pin body as a cosmetic scene (never collision, mass or score). Check it natively in the rack, shop, inventory and binder, and after a break (J03C02 turns a fallen Glass pin into Wood in place). Then set its `artwork` flag.
- **E20-V08:** activation and sound for Pin Counter, Hot Streak, Last Stand, Tip Jar, Banana Ball, Plumb Line, Glass Cutter, and Glass Pin's crack. The crack plays after the bank, in the order the frame explanation names breaks. Reduced motion follows E12. Set `effects_audio` only after a native check of each.

Ownership and limits:
- Edit content/catalogue.json only for these items' `assets` slots and their `artwork` / `effects_audio` flags. Never set flags in batch files.
- Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/, throw_lab.gd scoring and flow, clubhouse_model.gd, or Claude's E17/E18 paths. Claude's concurrent E18-C03 lands Split Specialist, Sweet Spot, Back Row, Underdog, Crown Jewel and Crown Pin; do not set their flags this wave.
- tools/qa.py, the CI workflow and run_tests.gd are add-only; keep new upload folders inside the existing `path` list, before `if-no-files-found`.
- Physics digest `75d1a3c0…`, J03 560/240/70, J05 21060 and J06 must stay identical. J03C01, J03C02 and J11ART must keep passing.
- Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per batch:
- **Before:** IDs and slots, the source and provenance plan, the journeys and captures.
- **After:** re-run `qa.py unit`, `content` and the affected journeys headless and `--rendered`; write docs/handoffs/<batch-id>.md; push, verify the remote SHA and a clean tree; report the SHA and batch IDs to the coordinator. Physical-phone readability stays E26.

Stop after the Wave 4 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start D03 identity art (it follows these briefs in Wave 5), E21 rivals not yet defined, or E22.
