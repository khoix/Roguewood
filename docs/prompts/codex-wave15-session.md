Roguewood — Codex Wave 15, new session: Salvage's painted art.
Recommended effort: High for E21 (rivals); Medium–High for the Salvage environment and trophy.

Repository: https://github.com/khoix/Roguewood.
- **Your branch:** `codex/roguewood-build`.
- **The coordinator's:** `claude/roguewood-build`.
- Never push to `main` and open no pull requests.

## What changed while you were away (owner, 2026-11-24)
- **The owner moved to Claude every art piece that can be drawn in code or a shader, plus the audio.** That covers:
  - UI-A8 (the League backdrops, now Claude's next item);
  - UI-A9-N (the Neon celebrations, done and live);
  - AV-UI1 (the button sounds, done);
  - PACK-A (the Web art compression, done);
  - the code-drawn parts of Salvage's theme: its celebrations (UI-A9-S), stings, pin-deck finish, flank backdrop, music and any code-drawn rule badges.
- **You keep the painted raster art.** Do not start the moved items.
- **Image imports are lossy now (PACK-A).** After adding images, run `python3 tools/web_textures.py`. `qa.py content` fails (`--check`) on any image off the rule. Art the game never loads goes in its `WEB_EXCLUDE`. The Web pack has a 55 MB budget in `qa.py web`; a League's art raises it in the same change, with a note.
- **UI-A9-H:** recorded DONE at Wave 14's close (live since 2026-11-24). The owner reviews the stings in play and sends notes.

## Begin
1. **Get up to date:** fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the "Wave 14 closed" commit or later) with a merge commit. Do not rebase or force-push.
2. **The rules:** read AGENTS.md, then docs/ROADMAP.md (the Wave 15 row).
3. **Your assignment:** read docs/AI-HANDOFF.md, "Wave 15 claims" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. **The League:** docs/handoffs/E17-L03.md is Salvage's spec (Divisions, rivals, rules, lanes, rewards). content/leagues/salvage.json has the ids and names.

## Order
1. **E21, Salvage's rivals:** Miser Moll (`rival.miser_moll`), Grimewell (`rival.grimewell`), Scrapjack (`rival.scrapjack`) and Scrapjack, Salvage Champion (`rival.scrapjack_champion`).
   - Each needs a portrait sheet in the six moods (`assets/rivals/<id>.png`, the RivalArt layout and `assets/rivals/manifest.json`) and a Clubhouse plaque (`assets/clubhouse/plaque.<id>.png`).
   - Follow E21-R05 to E21-R07 (the Neon rivals) for layout, checks and captures.
2. **E22-L03-ART, Salvage's painted theme:**
   - the environment and its Division rooms, plus the Championship stage, as the House and Neon environments are;
   - the League trophy (`assets/clubhouse/trophy.salvage.png`).
   - Claude wires the manifest hooks and does the code-drawn parts (backdrop, pin deck, celebrations, music). Ask in your handoff for any hook you need.
3. **UI-A8 is done** (Claude, handoffs/UI-A8.md) and asks for no painted far view. The room picture is now the back wall of a 3D alley (`src/presentation/alley_interior.gd`), so a Salvage environment works the same way: its room picture (9 × 6 m at z -21) closes the T.
4. **Later (Wave 16 and on):** the AV-S item art for Salvage's batches, as Claude's DC-S batches land.

## Ownership and limits
As docs/prompts/codex-wave14-session.md, "Ownership and limits". In addition:
- `assets/ui/alley_screen/`, `assets/ui/backdrops/` and the League manifests' `celebrations`, `celebration_sounds` and `flank` entries are Claude's.

## Per item
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - Run `python3 tools/web_textures.py`, then `qa.py unit`, `content` and the affected journeys, headless and `--rendered`.
  - Write docs/handoffs/<item>.md.
  - Push, verify the remote SHA and a clean tree, and report the SHA and item to the coordinator.
- **At the end of the wave:** write docs/handoffs/WAVE15-CODEX.md as an index, listing the captures the owner should review.

Stop after the Wave 15 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded.
