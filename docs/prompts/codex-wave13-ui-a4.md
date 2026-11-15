Roguewood — Codex Wave 13, UI-A4: Roguewood's brand art (logo, app icon, boot splash, optional title key art), in place of UI-7's provisional images.
Recommended effort: Medium (High if you make title key art).

Repository: https://github.com/khoix/Roguewood (your branch: `codex/roguewood-build`; the coordinator's: `claude/roguewood-build`; never push to `main` and open no pull requests).

Begin:
1. Clone the repository if this session has no checkout, then fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (the commit that adds this prompt, or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/AI-HANDOFF.md: "Wave 13 claims" (your item 3) and "Wave 13 progress" (UI-7).
3. Read docs/handoffs/UI-7.md (what the title screen, loading screen and icons are now, and "For Codex"), docs/art/ASSET-LEDGER.md ("UI-7"), tools/author_brand.py (how the provisional images are made) and src/bootstrap/title_screen.gd (how the art is placed).
4. Look at the provisional art first: run `python3 tools/qa.py e2e --journey J01 --rendered` (artifacts/e03/rendered/title.png) and `python3 tools/qa.py web` (artifacts/e26-w01/headless/web_loading.png, web_title.png).

The owner's decisions (2026-11-15):
- The title is "Roguewood", with no subtitle (Roguewood-Game-Plan.md: "Approved game title: Roguewood. No subtitle").
- The title screen has one action: a tap, click or key starts and opens the Clubhouse. Do not add buttons or menus to it.

Deliver, at fixed paths (the code already uses each when present, so no code changes are needed):
- **The logo:** `assets/brand/logo.png`, transparent background. While it exists, the title screen shows it in place of the lettered wordmark. It sits in a band about 86% of the width in portrait and 60% in landscape, and 2.2 × 76 px tall on a 540 × 960 canvas; it is fitted with its aspect kept. It must read at 360 px wide and over the hall's night window.
- **The app icon:** `assets/brand/icon.png`, 512 × 512, opaque and full-bleed (iOS fills transparency with black and rounds the corners itself). Godot's Web export makes the favicon and the 180 × 180 apple-touch-icon from it, and desktop builds use it as the window icon. It must read at 16 px in a browser tab. Keep it under about 150 KB, because the favicon is served at full size.
- **The boot splash:** `assets/brand/splash.png`, opaque, on #0b1116. It is shown centred and unstretched on the web loading page, scaled down to fit a phone's width, and again as the engine starts. A different background colour is the coordinator's change (project.godot and the page head); ask in your handoff.
- **Optional title key art:** `assets/brand/title_art.png`, in place of the House Division 1 backdrop. It fills the top 62% of a portrait screen and all of a landscape one, scaled to cover, with nearest-neighbour filtering. The ball, the logo and "Tap to start" sit over it, so leave their bands readable.
- **Retire the provisional script:** update tools/author_brand.py to produce your images, or remove it, so no one regenerates the provisional images over yours.

Ownership and limits:
- Paths: assets/brand/, tools/author_brand.py, docs/art/ (a brief docs/art/ui/UI-A4.md) and docs/art/ASSET-LEDGER.md (provenance and hashes).
- Do not edit src/, project.godot, export_presets.cfg or the tests. If the placement or a size needs a code change, request it from the coordinator in your handoff.
- Never commit screenshots or rendered captures.
- These must keep passing: J01 headless and rendered, the web journey (`python3 tools/qa.py web`; Node and Playwright required), unit, and the art shard.

After the session:
- Re-run `qa.py unit`, J01 headless and `--rendered`, `qa.py web`, and the phone tour's title (tools/capture_phone_tour.gd; see docs/DEVELOPMENT.md).
- Write docs/handoffs/UI-A4.md, listing the captures the owner should review: the title in portrait and landscape, the web loading page, and the icon at 180, 32 and 16 px.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
