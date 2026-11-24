# Agent task handoff — PACK-A, the Web build's art compressed (owner, 2026-11-24)

## Assignment
- **Owner:** Claude. The owner approved PACK-A from the PACK-1 proposal (docs/ideas/PACK-1.md) and moved it from Codex's asset-audit lane: "Go ahead with PACK-A, you take it from Codex."
- **State:** DONE (implementation and checks). Not tried on a phone.
- **Paths:**
  - `tools/web_textures.py` (new);
  - `assets/**/*.png.import` (94 files, written by the tool);
  - `export_presets.cfg` (the Web preset's exclude filter);
  - `tools/qa.py` (the budget, and `content` runs the rule check).

## Result
| | Before | After |
|---|---|---|
| `index.pck` (Web) | 124.7 MB | **46.4 MB** (−63%) |
| Whole download (pck + `index.wasm` 38.0 MB + small files) | ~163 MB | **~85 MB** |
| Imported image data | 100.6 MB | 35.4 MB, of which ~13 MB is excluded from the Web build |

The Web build holds its pack in memory, so phones also carry ~78 MB less for the session.

## Change
- **Lossy WebP:** every painted sheet imports as lossy WebP (`compress/mode=1`) at quality 0.9.
  - The tool's `LOSSLESS` set keeps the two small brand images lossless: the 512 px icon and the 720 × 560 splash.
  - Native builds get the same import (they shrink too).
- **The Web export leaves out art the game never loads** (`WEB_EXCLUDE`; the files stay in the repo):
  - the brand and Clubhouse source sheets;
  - three item sheets read only by tools (`d09/source.AV-H3-B`, `d10/source.AV-H4-A`, `d10/source.AV-H4-B`);
  - the three `ribbon.mastery.*` files. These are byte-identical copies of the ribbons the Clubhouse loads, because `clubhouse_model.gd` `asset_id` drops "mastery.".
  - Each was found unreferenced by path, by UID, and against the names the Clubhouse builds from content (trophies, plaques, ribbons, decos).
- **The rule holds:** `python3 tools/web_textures.py --check` names any image off the rule, or a preset that differs from the tool's list. `qa.py content` runs it. New art is handled by running `python3 tools/web_textures.py`.
- **The budget:**
  - `qa.py web` (JW01) fails when `index.pck` is over `WEB_PCK_BUDGET_MB` (55 MB, about 18% above today's size).
  - A League's art (Salvage, Wave 15) raises it on purpose, in the same change.

## The look (review gate)
- **In game:** 134 rendered captures before and after (J05, J06, J11, J22L01, J22L02, JUIA1).
  - Median PSNR 49 dB; every capture of still art is 44 dB or more, which is visually identical.
  - The seven lower ones are the award and celebration screens, whose confetti and fireworks differ between runs.
- **Close-ups:** the imported textures at 100% (2× magnified) beside their sources: Slick, Laser Lena, a ball, a ribbon, a Neon item sheet and the Neon environment. Only a slight softening of fine grain shows. In play the art is drawn at half size or less.
- **For the owner:** review captures and close-ups were sent (not committed).

## Checks
- `content` (with the rule check; it fails when an image is set back to lossless, confirmed), `unit`.
- `qa.py web` (JW01 in headless Chromium): PASS at 46.4 MB. It fails when the budget is set below the size (confirmed with 40 MB).
- **Rendered:** J05, J06, J11, J22L01, J22L02, JUIA1, J02, J11ART, JUIA9N, JAVN5. **Both modes:** J22L01ART, J22L02ART, JAVH4AC. All PASS.
- CI runs the rest of the art shard.
