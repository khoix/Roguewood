Roguewood — Codex Wave 2: E16-ART and E19 art for E17-D01 (E19-A08…A12).
Recommended effort: Medium for E16-ART, A08 and A09; High for A10 (Spark), A11 (Ghost) and A12 (Splitter).

Begin:
1. Fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the coordinator's integration of your Wave 1, plus the Wave 2 claims) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/AI-HANDOFF.md: "Wave 1 result", "Wave 2 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
3. Read docs/handoffs/E16.md ("Art hand-off"), docs/art/briefs/E17-D01.md, content/catalogue/batches/E17-D01.json and docs/handoffs/E17-D01.md.

Objective:
- **E16-ART:** final Clubhouse art and presentation.
  - Trophies `trophy.house` and `trophy.house_campaign`; ribbons `ribbon.spare_hand`, `ribbon.true_curve` and `ribbon.mixed_rack`; plaques `plaque.surveyor` and `plaque.custodian`; decorations `deco.club_sign`, `deco.lane_trim` and `deco.trophy_case`. Files go in `assets/clubhouse/<id>.png`.
  - The binder card look, with the four states readable without colour and Mastered using the E12 foil.
  - The tab bar and shelf layout, and an optional Clubhouse backdrop.
  - A phone-readability pass at 720×1280 and 1280×720.
- **E19-A08…A12:** identity sets for the 11 D01 definitions, following the briefs:
  - A08: Gold Ball, Glass, Fuse, Crown;
  - A09: Echo Pin, Nudge, Reserve Call, Rule Waiver;
  - A10: Spark Ball;
  - A11: Ghost Ball;
  - A12: Splitter Ball.
  Use the exact `design.asset_ids` from the batch file. Apply each brief's separation checks against the items it names.

Ownership and limits:
- **E16-ART exclusive paths:** `src/clubhouse/clubhouse.gd`, `src/clubhouse/clubhouse_art.gd`, `assets/clubhouse/`.
  - Keep every node name J11 uses: `Tab*`, `Binder_*`, `Filter*`, `Trophy_*`, `Goal_*/Track`, `BinderText`, `BinderArt`, `LeagueRecords`, `LatestUnlocks`.
  - Never change `clubhouse_model.gd`, Career code, the unlock registry or bootstrap.gd. Request any data the screen needs through docs/AI-HANDOFF.md.
- **D01 art:**
  - Edit only `definitions[].item.assets` paths in `content/catalogue/batches/E17-D01.json`. Never set completeness flags there; the validator refuses art flags on authored items.
  - These items are not playable until E18-Cxx moves them into the catalogue, so verify with briefs, actual-size, grayscale and silhouette contact sheets and inspector or binder-style previews. Do not claim in-play or activation verification.
  - Record which slots are final, so E18 can set the flags after native checks.
- **All work:**
  - Never edit src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, throw_lab.gd scoring and flow, or Claude's E17/E18 paths.
  - tools/qa.py, the CI workflow and run_tests.gd are add-only.
  - Physics digest `75d1a3c0…`, J03 560/240/70, J05 21060 and J06 must stay identical.
  - Provenance goes in docs/art/ASSET-LEDGER.md. Never commit screenshots.

Per batch:
- **Before:** IDs and slots, the source and provenance plan, the journeys and captures.
- **After:**
  - re-run `qa.py unit`, `content` and J11 (E16-ART), or the art-preview checks (D01), headless and `--rendered`;
  - write docs/handoffs/<batch-id>.md;
  - push, verify the remote SHA and a clean tree;
  - report the SHA and batch IDs to the coordinator. Physical-phone readability stays E26.

Stop after the Wave 2 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded. Do not start E20 effects for D01 items (they wait for E18), E21 rivals not yet defined, or E22.
