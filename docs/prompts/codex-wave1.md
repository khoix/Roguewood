Roguewood — Codex Wave 1: presentation for production batch E13-S01 (E19-A01…A07, E20-V01…V07, E21-R01/R02).
Recommended effort: High for E21 and for any complex animated set; Medium for ordinary E19/E20 batches.

Begin:
1. Fetch origin. On your persistent branch `codex/roguewood-build`, merge `origin/claude/roguewood-build` at `06abb88` (or later) with a merge commit. Do not rebase or force-push.
   - The merge brings in E15 (Career and unlock graph) and the coordinator's ownership plan and Wave 1 claims.
   - Main does not have them yet.
2. Read AGENTS.md, then docs/AI-HANDOFF.md, especially "Ownership, lanes and hand-offs" and "Wave 1 claims". Those claims are your assignment, exclusive paths and restrictions. Repo state wins over this prompt if they differ.
3. Then read the E19, E20 and E21 sections of docs/EXECUTION-PLAN.md, the relevant Roguewood-Game-Plan.md sections (§11, §15 card presentation and the per-item art criteria, §17, §18), your own docs/art/ART-BIBLE.md and E12-MOTION.md, and the E13-S01 entries in content/catalogue.json.

Objective: final-quality presentation for the 25 production items and the two slice rivals, in bounded batches, in this order (adjust only if a dependency forces it):
- E19-A01…A07, item identity sets. Each set has the card illustration, icon, in-play appearance, rarity treatment and reduced-motion variant. Write each item's visual brief at the start of its batch; these items predate E17.
- E21-R01 The Surveyor and E21-R02 The Custodian:
  - portrait states, intro, lane treatment, rule badge, reactions, defeat and reward identity;
  - the visual and audio treatment of the Dead Straight and Clean Sweep rules.
- E20-V01…V07, ability effects and audio. Each batch comes after its items' E19 art:
  - V01 retrigger: Echo Ball, Encore;
  - V02 growth: Grower, Patient Investor;
  - V03 gold: Gold pin payout, Gold Rush;
  - V04 standing: Anchor, Standing Order, Lone Survivor;
  - V05 conditional multipliers: Finisher, Turkey Club, Last Chance;
  - V06 flat bonuses: Flat Bonus, Spare Change, House Favorite;
  - V07 roll feel: Hook Ball with Hook Artist, Hammer, Rubber, Wood and Ruby. Split it if it does not fit one session.
  - Include volume controls and activation priorities, and add J12 (dense effects, sound controls, skips) when E20 work first needs it.

Ownership and limits (details in the Wave 1 claims):
- Work only in your exclusive paths:
  - assets/, docs/art/;
  - the listed src/presentation/ files plus new presentation files (for example an asset loader that resolves the catalogue `assets` slots);
  - your tests and journeys, and one handoff file per batch.
- content/catalogue.json: edit only the `assets` slots and the `completeness.artwork` / `completeness.effects_audio` flags of the 25 E13-S01 entries. Rival art references go in an assets-side manifest keyed by rival ID.
- tools/qa.py, the CI workflow and tests/run_tests.gd: add-only.
- Never edit:
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/;
  - throw_lab.gd scoring and flow;
  - other content specs;
  - Claude's E16 paths (src/clubhouse/, bootstrap.gd, career_profile.gd, content/career/).
  If you need a rule or flow hook, request it in docs/AI-HANDOFF.md instead of implementing it.
- No effect or animation may change a score, a result or saved state. These must stay identical:
  - J03 560/240/70, J05 21060, J06;
  - the physics digest `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
- Do not use palette swaps as unique identity. Keep reduced-motion and reduced-flash variants. Record provenance and rights for every asset in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures; CI's journeys artifact is their durable copy.

Per-batch hand-off:
- Before: list the batch IDs, slots, source and provenance plan, and the journeys and captures that will show the work.
- After:
  - an actual-size contact sheet, category and rarity recognition, in-play silhouettes and reduced-motion appearance;
  - for E20, frame-time evidence on dense combinations;
  - affected journeys re-run headless and `--rendered`, plus `qa.py unit`, `content` and `physics`;
  - completeness flags set only for slots delivered at final quality;
  - docs/handoffs/<batch-id>.md updated;
  - push `codex/roguewood-build`, verify the remote SHA, confirm a clean tree;
  - report the SHA and the finished batch IDs to the coordinator.
  Real-phone readability stays a device gate (E26). Do not claim it.

Validation commands: `python3 tools/qa.py unit|content|integration|physics|smoke`, and `python3 tools/qa.py e2e --journey J0x [--rendered]` for J03, J04, J05, J06, J08, J09 and J10 as affected (rendered via `xvfb-run -a` on Linux). Add `--journey J12` when you create it.

Stop after the claimed Wave 1 batches, or earlier at a coherent pushed checkpoint, with the exact resume step recorded. Do not start E16-ART, E22 or new E17-dependent batches; the coordinator marks those READY after the matching hand-offs.
